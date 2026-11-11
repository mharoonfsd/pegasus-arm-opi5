#!/usr/bin/python3
import os
import sys
import time

import cairo
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GLib, Gtk


SCREEN_WIDTH = 360
SCREEN_HEIGHT = 106
SAMPLE_INTERVAL_MS = 1000


def read_memory():
    values = {}
    with open("/proc/meminfo", encoding="ascii") as meminfo:
        for line in meminfo:
            key, value = line.split(":", 1)
            if key in ("MemTotal", "MemAvailable"):
                values[key] = int(value.strip().split()[0])
    total = values["MemTotal"]
    available = values["MemAvailable"]
    return max(0, total - available), total


def read_process_rss(pid):
    try:
        with open(f"/proc/{pid}/status", encoding="ascii") as status:
            for line in status:
                if line.startswith("VmRSS:"):
                    return int(line.split()[1])
    except (FileNotFoundError, PermissionError, ProcessLookupError):
        return None
    return None


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
    for zone in ("/sys/class/thermal/" + name for name in os.listdir("/sys/class/thermal")
                 if name.startswith("thermal_zone")):
        try:
            with open(zone + "/type", encoding="ascii") as sensor_type:
                kind = sensor_type.read().strip().lower()
            with open(zone + "/temp", encoding="ascii") as sensor_value:
                temperature = int(sensor_value.read().strip()) / 1000
        except (FileNotFoundError, PermissionError, ValueError):
            continue
        if "gpu" in kind:
            gpu_values.append(temperature)
        elif any(token in kind for token in ("cpu", "core", "soc")):
            cpu_values.append(temperature)
    return max(cpu_values, default=None), max(gpu_values, default=None)


def process_is_running(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


class StatsOverlay:
    def __init__(self, pid):
        self.pid = pid
        self.previous_disk = None
        self.previous_time = None
        self.disk_rates = None
        self.lines = ["FPS: RetroArch OSD", "Reading system statistics...", "", "", ""]

        self.window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
        self.window.set_title("Pegasus performance statistics")
        self.window.set_decorated(False)
        self.window.set_resizable(False)
        self.window.set_keep_above(True)
        self.window.stick()
        self.window.set_skip_taskbar_hint(True)
        self.window.set_skip_pager_hint(True)
        self.window.set_accept_focus(False)
        self.window.set_focus_on_map(False)
        self.window.set_type_hint(Gdk.WindowTypeHint.UTILITY)
        self.window.set_app_paintable(True)
        self.window.set_default_size(SCREEN_WIDTH, SCREEN_HEIGHT)
        self.window.connect("realize", self.make_click_through)

        visual = self.window.get_screen().get_rgba_visual()
        if visual is not None:
            self.window.set_visual(visual)

        self.drawing_area = Gtk.DrawingArea()
        self.drawing_area.set_size_request(SCREEN_WIDTH, SCREEN_HEIGHT)
        self.drawing_area.set_app_paintable(True)
        self.drawing_area.connect("draw", self.draw)
        self.window.add(self.drawing_area)

        monitor = Gdk.Display.get_default().get_monitor(0)
        screen_height = monitor.get_geometry().height
        self.window.move(12, max(12, screen_height - SCREEN_HEIGHT - 12))
        self.window.show_all()

        self.update()
        GLib.timeout_add(SAMPLE_INTERVAL_MS, self.update)

    def make_click_through(self, window):
        window.get_window().input_shape_combine_region(cairo.Region(), 0, 0)

    def draw(self, _widget, context):
        context.set_operator(cairo.OPERATOR_CLEAR)
        context.paint()
        context.set_operator(cairo.OPERATOR_OVER)
        context.set_source_rgba(0.02, 0.02, 0.02, 0.78)
        context.rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        context.fill()

        context.select_font_face("Monospace", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
        context.set_font_size(12)
        context.set_source_rgb(0.92, 0.96, 1.0)
        for index, line in enumerate(self.lines):
            context.move_to(10, 19 + index * 18)
            context.show_text(line)
        return False

    def update(self):
        if not process_is_running(self.pid):
            Gtk.main_quit()
            return GLib.SOURCE_REMOVE

        try:
            used_kib, total_kib = read_memory()
            memory_line = (
                f"RAM {used_kib // 1024}/{total_kib // 1024} MiB"
            )
        except (FileNotFoundError, PermissionError, KeyError, ValueError):
            memory_line = "RAM unavailable"

        rss_kib = read_process_rss(self.pid)
        process_memory = f"RA {rss_kib // 1024} MiB" if rss_kib is not None else "RA --"

        try:
            current_disk = read_disk_counters()
            current_time = time.monotonic()
            if self.previous_disk is not None and self.previous_time is not None:
                elapsed = current_time - self.previous_time
                if elapsed > 0:
                    self.disk_rates = tuple(
                        max(0, current - previous) / elapsed / (1024 * 1024)
                        for current, previous in zip(current_disk, self.previous_disk)
                    )
            self.previous_disk = current_disk
            self.previous_time = current_time
        except (FileNotFoundError, PermissionError, ValueError):
            self.disk_rates = None

        if self.disk_rates is None:
            disk_line = "Disk R -- | W -- MiB/s"
        else:
            disk_line = f"Disk R {self.disk_rates[0]:.2f} | W {self.disk_rates[1]:.2f} MiB/s"

        try:
            cpu_temp, gpu_temp = read_temperatures()
            cpu_text = f"{cpu_temp:.0f}C" if cpu_temp is not None else "--"
            gpu_text = f"{gpu_temp:.0f}C" if gpu_temp is not None else "--"
            temperature_line = f"CPU {cpu_text} | GPU {gpu_text}"
        except (FileNotFoundError, PermissionError, OSError):
            temperature_line = "CPU -- | GPU --"

        self.lines = [
            "FPS: RetroArch OSD",
            f"{memory_line} | {process_memory}",
            disk_line,
            temperature_line,
            "F12 marks a slowdown for the session log",
        ]
        self.drawing_area.queue_draw()
        return GLib.SOURCE_CONTINUE


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} RETROARCH_PID", file=sys.stderr)
        return 2
    try:
        pid = int(sys.argv[1])
    except ValueError:
        print("RetroArch PID must be an integer.", file=sys.stderr)
        return 2
    Gtk.init([])
    StatsOverlay(pid)
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
