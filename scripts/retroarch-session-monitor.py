#!/usr/bin/python3
import csv
import datetime
import glob
import os
import queue
import re
import signal
import shutil
import subprocess
import sys
import threading
import time


SAMPLE_INTERVAL = 0.5
MARKER_KEY = "F12"
CSV_FIELDS = (
    "timestamp",
    "elapsed_seconds",
    "event",
    "detail",
    "marker_sample_age_ms",
    "system_cpu_percent",
    "retroarch_cpu_percent",
    "retroarch_top_thread_percent",
    "retroarch_fps",
    "ram_used_mib",
    "ram_total_mib",
    "swap_used_mib",
    "retroarch_rss_mib",
    "disk_read_mib_s",
    "disk_write_mib_s",
    "retroarch_read_mib_s",
    "retroarch_write_mib_s",
    "cpu_temp_c",
    "gpu_temp_c",
    "gpu_load_percent",
    "gpu_frequency_mhz",
)


def timestamp_for(epoch_seconds):
    return datetime.datetime.fromtimestamp(epoch_seconds).astimezone().isoformat(
        timespec="milliseconds"
    )


def process_is_running(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def read_memory():
    values = {}
    with open("/proc/meminfo", encoding="ascii") as meminfo:
        for line in meminfo:
            key, value = line.split(":", 1)
            if key in ("MemTotal", "MemAvailable", "SwapTotal", "SwapFree"):
                values[key] = int(value.strip().split()[0])
    total = values["MemTotal"]
    available = values["MemAvailable"]
    swap_used = values.get("SwapTotal", 0) - values.get("SwapFree", 0)
    return max(0, total - available), total, max(0, swap_used)


def read_process_rss(pid):
    try:
        with open(f"/proc/{pid}/status", encoding="ascii") as status:
            for line in status:
                if line.startswith("VmRSS:"):
                    return int(line.split()[1])
    except (FileNotFoundError, PermissionError, ProcessLookupError):
        return None
    return None


def read_thread_cpu_ticks(pid):
    ticks = {}
    for path in glob.glob(f"/proc/{pid}/task/*/stat"):
        try:
            with open(path, encoding="ascii") as stat_file:
                stat = stat_file.read()
            fields = stat[stat.rfind(")") + 2 :].split()
            thread_id = int(path.split("/")[-2])
            ticks[thread_id] = int(fields[11]) + int(fields[12])
        except (FileNotFoundError, PermissionError, IndexError, ValueError):
            continue
    return ticks


def read_system_cpu_ticks():
    with open("/proc/stat", encoding="ascii") as stat_file:
        fields = stat_file.readline().split()
    ticks = [int(value) for value in fields[1:]]
    idle_ticks = ticks[3] + (ticks[4] if len(ticks) > 4 else 0)
    return sum(ticks), idle_ticks


def read_process_io(pid):
    counters = {}
    try:
        with open(f"/proc/{pid}/io", encoding="ascii") as io_file:
            for line in io_file:
                key, value = line.split(":", 1)
                if key in ("read_bytes", "write_bytes"):
                    counters[key] = int(value.strip())
    except (FileNotFoundError, PermissionError, ProcessLookupError, ValueError):
        return None
    if "read_bytes" not in counters or "write_bytes" not in counters:
        return None
    return counters["read_bytes"], counters["write_bytes"]


def read_disk_counters():
    read_bytes = 0
    write_bytes = 0
    with open("/proc/diskstats", encoding="ascii") as diskstats:
        for line in diskstats:
            fields = line.split()
            if len(fields) < 10:
                continue
            major, minor, name = fields[:3]
            if name.startswith(("loop", "ram", "zram", "dm-", "md", "fd", "sr")):
                continue
            if os.path.exists(f"/sys/dev/block/{major}:{minor}/partition"):
                continue
            read_bytes += int(fields[5]) * 512
            write_bytes += int(fields[9]) * 512
    return read_bytes, write_bytes


def read_temperatures():
    cpu_values = []
    gpu_values = []
    thermal_root = "/sys/class/thermal"
    for zone in glob.glob(os.path.join(thermal_root, "thermal_zone*")):
        try:
            with open(os.path.join(zone, "type"), encoding="ascii") as sensor_type:
                kind = sensor_type.read().strip().lower()
            with open(os.path.join(zone, "temp"), encoding="ascii") as sensor_value:
                temperature = int(sensor_value.read().strip()) / 1000
        except (FileNotFoundError, PermissionError, ValueError):
            continue
        if "gpu" in kind:
            gpu_values.append(temperature)
        elif any(token in kind for token in ("cpu", "core", "soc")):
            cpu_values.append(temperature)
    return max(cpu_values, default=None), max(gpu_values, default=None)


def read_gpu_metrics():
    loads = []
    frequencies = []
    for device in glob.glob("/sys/class/devfreq/*"):
        if "gpu" not in os.path.basename(device).lower():
            continue
        try:
            with open(os.path.join(device, "load"), encoding="ascii") as load_file:
                match = re.match(r"\s*(\d+)", load_file.read())
                if match:
                    loads.append(float(match.group(1)))
        except (FileNotFoundError, PermissionError, ValueError):
            pass
        try:
            with open(os.path.join(device, "cur_freq"), encoding="ascii") as frequency_file:
                frequencies.append(int(frequency_file.read().strip()) / 1_000_000)
        except (FileNotFoundError, PermissionError, ValueError):
            pass
    return max(loads, default=None), max(frequencies, default=None)


def keycodes_for(keysym):
    xmodmap = shutil.which("xmodmap")
    if not xmodmap:
        return set()
    result = subprocess.run(
        [xmodmap, "-pke"],
        check=True,
        capture_output=True,
        text=True,
    )
    keycodes = set()
    for line in result.stdout.splitlines():
        match = re.match(r"\s*keycode\s+(\d+)\s*=\s*(.*)", line)
        if match and keysym in match.group(2).split():
            keycodes.add(int(match.group(1)))
    return keycodes


def read_retroarch_fps(xdotool, pid, window_id):
    if not xdotool:
        return None, window_id

    if window_id:
        window_ids = [window_id]
    else:
        try:
            result = subprocess.run(
                [xdotool, "search", "--onlyvisible", "--pid", str(pid)],
                capture_output=True,
                text=True,
                timeout=0.4,
                check=False,
            )
        except (OSError, subprocess.SubprocessError):
            return None, None
        window_ids = result.stdout.splitlines()

    for candidate in window_ids:
        try:
            result = subprocess.run(
                [xdotool, "getwindowname", candidate],
                capture_output=True,
                text=True,
                timeout=0.4,
                check=False,
            )
        except (OSError, subprocess.SubprocessError):
            return None, None
        match = re.search(r"\bFPS:\s*(\d+(?:\.\d+)?)", result.stdout)
        if result.returncode == 0 and match:
            return float(match.group(1)), candidate
    return None, None


class MarkerListener:
    def __init__(self):
        self.events = queue.Queue()
        self.process = None
        self.thread = None
        self.closed = threading.Event()
        self.keycodes = set()
        self.status = ""
        try:
            self.keycodes = keycodes_for(MARKER_KEY)
        except (OSError, subprocess.SubprocessError):
            self.status = "could not read the X11 keyboard map"
            return
        xinput = shutil.which("xinput")
        if not xinput or not self.keycodes:
            self.status = "F12 marker unavailable (xinput or key mapping missing)"
            return

        stdbuf = shutil.which("stdbuf")
        command = ([stdbuf, "-oL", xinput] if stdbuf else [xinput])
        command.extend(("test-xi2", "--root"))
        try:
            self.process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
            )
        except OSError as error:
            self.status = f"F12 marker unavailable ({error})"
            return
        self.thread = threading.Thread(target=self.read_events, daemon=True)
        self.thread.start()
        self.status = "F12 marker enabled"

    def read_events(self):
        raw_key_press = False
        for line in self.process.stdout:
            if line.startswith("EVENT"):
                raw_key_press = "(RawKeyPress)" in line
            elif raw_key_press and line.strip().startswith("detail:"):
                raw_key_press = False
                try:
                    keycode = int(line.split(":", 1)[1].strip())
                except ValueError:
                    continue
                if keycode in self.keycodes:
                    self.events.put((time.time(), time.monotonic()))
        if not self.closed.is_set():
            self.events.put(("error", f"xinput listener exited ({self.process.poll()})"))

    def drain(self):
        events = []
        while True:
            try:
                events.append(self.events.get_nowait())
            except queue.Empty:
                return events

    def close(self):
        self.closed.set()
        if self.process and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        if self.thread:
            self.thread.join(timeout=2)


class SessionMonitor:
    def __init__(self, pid):
        self.pid = pid
        self.started_wall = time.time()
        self.started_mono = time.monotonic()
        state_root = os.environ.get(
            "XDG_STATE_HOME", os.path.expanduser("~/.local/state")
        )
        session_dir = os.path.join(state_root, "pegasus-opi5-installer", "sessions")
        os.makedirs(session_dir, exist_ok=True)
        stamp = datetime.datetime.now().astimezone().strftime("%Y%m%d-%H%M%S")
        self.log_path = os.path.join(session_dir, f"retroarch-{stamp}-{pid}.csv")
        self.log_file = open(self.log_path, "x", newline="", encoding="utf-8")
        self.writer = csv.DictWriter(self.log_file, fieldnames=CSV_FIELDS)
        self.writer.writeheader()
        self.xdotool = shutil.which("xdotool")
        self.window_id = None
        self.listener = MarkerListener()
        self.previous = self.read_counters()
        self.previous_mono = time.monotonic()
        self.last_metrics = {}
        status = self.listener.status
        if not self.xdotool:
            status += "; FPS unavailable (xdotool not installed)"
        else:
            status += "; FPS sampled from RetroArch window title"
        self.write_row(
            self.started_wall,
            self.started_mono,
            "monitor_start",
            status,
            None,
            {},
        )

    def read_counters(self):
        return {
            "thread_ticks": read_thread_cpu_ticks(self.pid),
            "system_cpu": read_system_cpu_ticks(),
            "process_io": read_process_io(self.pid),
            "disk_io": read_disk_counters(),
        }

    def sample(self):
        now_mono = time.monotonic()
        now_wall = time.time()
        elapsed = max(0.001, now_mono - self.previous_mono)
        current = self.read_counters()
        clock_ticks = os.sysconf("SC_CLK_TCK")

        previous_threads = self.previous["thread_ticks"]
        current_threads = current["thread_ticks"]
        thread_deltas = {
            thread_id: max(0, ticks - previous_threads.get(thread_id, ticks))
            for thread_id, ticks in current_threads.items()
        }
        process_cpu = sum(thread_deltas.values()) / clock_ticks / elapsed * 100
        top_thread_cpu = max(thread_deltas.values(), default=0) / clock_ticks / elapsed * 100

        previous_total, previous_idle = self.previous["system_cpu"]
        current_total, current_idle = current["system_cpu"]
        total_delta = current_total - previous_total
        system_cpu = (
            max(0, total_delta - (current_idle - previous_idle)) / total_delta * 100
            if total_delta > 0
            else None
        )

        metrics = {}
        try:
            used_kib, total_kib, swap_kib = read_memory()
            metrics.update(
                ram_used_mib=used_kib / 1024,
                ram_total_mib=total_kib / 1024,
                swap_used_mib=swap_kib / 1024,
            )
        except (FileNotFoundError, PermissionError, KeyError, ValueError):
            pass

        rss_kib = read_process_rss(self.pid)
        metrics["retroarch_rss_mib"] = rss_kib / 1024 if rss_kib is not None else None
        metrics["system_cpu_percent"] = system_cpu
        metrics["retroarch_cpu_percent"] = process_cpu
        metrics["retroarch_top_thread_percent"] = top_thread_cpu
        fps, self.window_id = read_retroarch_fps(
            self.xdotool, self.pid, self.window_id
        )
        metrics["retroarch_fps"] = fps

        try:
            cpu_temp, gpu_temp = read_temperatures()
            metrics["cpu_temp_c"] = cpu_temp
            metrics["gpu_temp_c"] = gpu_temp
        except OSError:
            metrics["cpu_temp_c"] = None
            metrics["gpu_temp_c"] = None

        try:
            gpu_load, gpu_frequency = read_gpu_metrics()
            metrics["gpu_load_percent"] = gpu_load
            metrics["gpu_frequency_mhz"] = gpu_frequency
        except OSError:
            metrics["gpu_load_percent"] = None
            metrics["gpu_frequency_mhz"] = None

        previous_disk = self.previous["disk_io"]
        current_disk = current["disk_io"]
        metrics["disk_read_mib_s"] = max(0, current_disk[0] - previous_disk[0]) / elapsed / 1048576
        metrics["disk_write_mib_s"] = max(0, current_disk[1] - previous_disk[1]) / elapsed / 1048576

        previous_io = self.previous["process_io"]
        current_io = current["process_io"]
        if previous_io and current_io:
            metrics["retroarch_read_mib_s"] = max(0, current_io[0] - previous_io[0]) / elapsed / 1048576
            metrics["retroarch_write_mib_s"] = max(0, current_io[1] - previous_io[1]) / elapsed / 1048576
        else:
            metrics["retroarch_read_mib_s"] = None
            metrics["retroarch_write_mib_s"] = None

        for event in self.listener.drain():
            if event[0] == "error":
                self.write_row(now_wall, now_mono, "monitor_error", event[1], None, metrics)
            else:
                marker_wall, marker_mono = event
                age_ms = max(0, (now_mono - marker_mono) * 1000)
                self.write_row(
                    marker_wall,
                    marker_mono,
                    "slowdown_marker",
                    f"{MARKER_KEY} pressed",
                    age_ms,
                    metrics,
                )

        self.last_metrics = metrics
        self.write_row(now_wall, now_mono, "sample", "", None, metrics)
        self.previous = current
        self.previous_mono = now_mono

    def write_row(self, wall_time, mono_time, event, detail, marker_age, metrics):
        row = {field: "" for field in CSV_FIELDS}
        row.update(metrics)
        row.update(
            timestamp=timestamp_for(wall_time),
            elapsed_seconds=round(max(0, mono_time - self.started_mono), 3),
            event=event,
            detail=detail,
            marker_sample_age_ms=round(marker_age, 1) if marker_age is not None else "",
        )
        self.writer.writerow(row)
        self.log_file.flush()

    def close(self):
        self.listener.close()
        self.log_file.close()


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} RETROARCH_PID", file=sys.stderr)
        return 2
    try:
        pid = int(sys.argv[1])
    except ValueError:
        print("RetroArch PID must be an integer.", file=sys.stderr)
        return 2
    if not process_is_running(pid):
        print(f"RetroArch process {pid} is not running.", file=sys.stderr)
        return 2

    monitor = SessionMonitor(pid)
    print(f"Session telemetry: {monitor.log_path}", flush=True)
    stop_requested = threading.Event()
    signal.signal(signal.SIGTERM, lambda _signum, _frame: stop_requested.set())
    try:
        while process_is_running(pid) and not stop_requested.wait(SAMPLE_INTERVAL):
            if process_is_running(pid):
                monitor.sample()
    finally:
        monitor.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
