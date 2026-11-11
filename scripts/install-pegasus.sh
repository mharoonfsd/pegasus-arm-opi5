#!/usr/bin/env bash
set -Eeuo pipefail

readonly SOURCE_URL="https://github.com/mmatyas/pegasus-frontend.git"
readonly SOURCE_TAG="weekly_2024w38"
readonly SOURCE_COMMIT="c3462e68bf3a178420b44f356998255f8d82a113"
readonly BUILD_PACKAGES=(
    build-essential
    cmake
    git
    pkg-config
    qtbase5-dev
    qtdeclarative5-dev
    qtmultimedia5-dev
    libqt5svg5-dev
    libsdl2-dev
    qttools5-dev
    qttools5-dev-tools
    qml-module-qtgraphicaleffects
    qml-module-qtmultimedia
    qml-module-qt-labs-qmlmodels
    gstreamer1.0-libav
    gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad
    python3
)
readonly FBNEO_CORE_URL="https://buildbot.libretro.com/nightly/linux/aarch64/latest/fbneo_libretro.so.zip"
readonly SNES9X_CORE_URL="https://buildbot.libretro.com/nightly/linux/aarch64/latest/snes9x_libretro.so.zip"
readonly RETROARCH_PACKAGES=(
    retroarch
    libretro-core-info
)

INSTALL_DIR="${PEGASUS_INSTALL_DIR:-${HOME:?HOME must be set}/Applications/Pegasus}"
WORK_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/pegasus-opi5-installer"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/pegasus-opi5-installer"
JOBS=2
OPERATION=""
DRY_RUN=0
ASSUME_YES=0
LIBRARY_ROOT=""
BLOCKERS=0
EXISTING_PEGASUS=0
WITH_RETROARCH=0

usage() {
    cat <<'EOF'
Usage:
  install-pegasus.sh --check-only
  install-pegasus.sh --dry-run --install-frontend [--jobs N]
  install-pegasus.sh --install-frontend [--with-retroarch] [--jobs N] [--yes]
  install-pegasus.sh --install-retroarch [--dry-run] [--yes]
  install-pegasus.sh --install-fbneo [--dry-run] [--yes]
  install-pegasus.sh --install-snes9x [--dry-run] [--yes]
  install-pegasus.sh --configure-library PATH
  install-pegasus.sh --inspect-library PATH

Options:
  --check-only          Read-only system and build-dependency preflight.
  --install-frontend    Build and install the pinned Pegasus source natively.
  --with-retroarch      In addition, install native ARM64 RetroArch and available Ubuntu cores.
  --install-retroarch   Install native ARM64 RetroArch and available Ubuntu cores only.
  --install-fbneo       Install the official ARM64 FBNeo libretro core nightly.
  --install-snes9x      Install the official ARM64 Snes9x libretro core nightly.
  --configure-library P Generate native RetroArch launch metadata for supported ROM folders under a library root.
  --inspect-library P   Read-only inspection of a user-supplied library root.
  --dry-run             Print planned frontend changes without writing files.
  --jobs N              Parallel build jobs (default: 2).
  --yes                 Skip the install confirmation prompt. Explicit opt-in.
  --help                Show this help.

The default user install location is ~/Applications/Pegasus. Override it with
PEGASUS_INSTALL_DIR. The suggested ROM/library location is
~/Applications/Pegasus/roms, but this script never copies or moves library data.
EOF
}

say_status() {
    local level="$1"
    shift
    printf '[%s] %s\n' "$level" "$*"
    if [[ "$level" == "BLOCKER" ]]; then
        BLOCKERS=$((BLOCKERS + 1))
    fi
}

require_command() {
    local command_name="$1"
    local purpose="$2"
    if command -v "$command_name" >/dev/null 2>&1; then
        say_status "PASS" "$command_name is available ($purpose)."
    else
        say_status "WARNING" "$command_name is not available ($purpose)."
    fi
}

package_installed() {
    dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null | grep -qx "installed"
}

package_available() {
    apt-cache show "$1" >/dev/null 2>&1
}

available_retroarch_packages() {
    local package architecture
    {
        for package in "${RETROARCH_PACKAGES[@]}"; do
            if package_available "$package"; then
                printf '%s\n' "$package"
            fi
        done

        # Ubuntu may expose additional libretro packages as repository metadata changes.
        # Install all available, non-development core packages compatible with this host.
        while IFS= read -r package; do
            [[ "$package" =~ ^libretro- ]] || continue
            case "$package" in
                *-dev|libretro-gtk-*) continue ;;
            esac
            architecture="$(apt-cache show "$package" 2>/dev/null | sed -n 's/^Architecture: //p' | head -n 1)"
            if [[ "$architecture" == "arm64" || "$architecture" == "all" ]]; then
                printf '%s\n' "$package"
            fi
        done < <(apt-cache search '^libretro-[[:alnum:]_.+-]' 2>/dev/null | awk '{print $1}' | sort -u)
    } | awk '!seen[$0]++'
}

run_preflight() {
    local os_id="unknown"
    local os_version="unknown"
    local os_name="unknown"
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pegasus-frontend"
    local architecture kernel package

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        os_id="${ID:-unknown}"
        os_version="${VERSION_ID:-unknown}"
        os_name="${PRETTY_NAME:-unknown}"
        say_status "PASS" "Operating system: $os_name."
    else
        say_status "BLOCKER" "Cannot read /etc/os-release."
    fi

    architecture="$(uname -m)"
    kernel="$(uname -r)"
    printf 'System: architecture=%s kernel=%s user=%s home=%s\n' \
        "$architecture" "$kernel" "$(id -un)" "$HOME"

    if [[ "$architecture" == "aarch64" || "$architecture" == "arm64" ]]; then
        say_status "PASS" "Native ARM64 architecture detected ($architecture)."
    else
        say_status "BLOCKER" "This source-build workflow targets ARM64; detected $architecture."
    fi

    if [[ "$os_id" == "ubuntu" ]] && [[ "$os_version" =~ ^([0-9]+)\.([0-9]+) ]]; then
        if (( BASH_REMATCH[1] > 22 || (BASH_REMATCH[1] == 22 && BASH_REMATCH[2] >= 4) )); then
            say_status "PASS" "Ubuntu $os_version meets the documented Ubuntu 22.04+ baseline."
        else
            say_status "BLOCKER" "Ubuntu $os_version is older than the documented 22.04 baseline."
        fi
    else
        say_status "BLOCKER" "This workflow targets Ubuntu 22.04+; detected $os_id $os_version."
    fi

    if command -v df >/dev/null 2>&1; then
        printf 'Available space for home: '
        df -hP "$HOME" | awk 'NR == 2 { print $4 " (filesystem " $6 ")" }'
    else
        say_status "NOT CHECKED" "df is unavailable; free disk space was not measured."
    fi

    if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
        printf 'Desktop session: %s\n' "$XDG_SESSION_TYPE"
    elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        printf 'Desktop session: Wayland (inferred from WAYLAND_DISPLAY)\n'
    elif [[ -n "${DISPLAY:-}" ]]; then
        printf 'Desktop session: X11 (inferred from DISPLAY)\n'
    else
        say_status "NOT CHECKED" "No active desktop display session detected."
    fi

    require_command sudo "individual privileged dependency installation only"
    require_command git "pinned source checkout"
    require_command cmake "Qt source build"
    require_command make "Qt source build"
    require_command pkg-config "SDL2 build dependency detection"
    require_command dpkg-query "Ubuntu package-state checks"
    require_command apt-get "Ubuntu dependency installation"
    require_command python3 "launcher and manifest generation"

    if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && command -v glxinfo >/dev/null 2>&1; then
        if glxinfo -B 2>&1 | sed -n '1,12p'; then
            :
        else
            say_status "WARNING" "OpenGL query failed; this does not establish a Pegasus failure."
        fi
    else
        say_status "NOT CHECKED" "OpenGL details were not queried (glxinfo or desktop display unavailable)."
    fi

    if command -v pegasus-fe >/dev/null 2>&1; then
        printf 'Existing Pegasus command: %s\n' "$(command -v pegasus-fe)"
        EXISTING_PEGASUS=1
    elif [[ -x "$INSTALL_DIR/pegasus-fe" ]]; then
        printf 'Existing Pegasus executable: %s\n' "$INSTALL_DIR/pegasus-fe"
        EXISTING_PEGASUS=1
    else
        say_status "PASS" "No Pegasus executable found at the planned user install location."
    fi
    if [[ -d "$config_dir" ]]; then
        say_status "PASS" "Existing Pegasus configuration directory found; it will not be modified: $config_dir"
        if [[ -f "$config_dir/settings.txt" ]]; then
            printf 'Existing settings file: %s\n' "$config_dir/settings.txt"
        fi
        if [[ -f "$config_dir/lastrun.log" ]]; then
            printf 'Last-run version: '
            sed -n '1p' "$config_dir/lastrun.log"
        fi
    else
        say_status "PASS" "No Pegasus configuration directory found at $config_dir."
    fi
    printf 'Planned user install path: %s\n' "$INSTALL_DIR"
    printf 'Preferred library path (suggestion only): %s/roms\n' "$INSTALL_DIR"
    printf 'Pinned source: %s @ %s (%s)\n' "$SOURCE_URL" "$SOURCE_TAG" "$SOURCE_COMMIT"

    if command -v dpkg-query >/dev/null 2>&1; then
        for package in "${BUILD_PACKAGES[@]}"; do
            if package_installed "$package"; then
                say_status "PASS" "Build package is installed: $package."
            elif command -v apt-cache >/dev/null 2>&1 && apt-cache show "$package" >/dev/null 2>&1; then
                say_status "WARNING" "Build package is not installed: $package (available in current package index)."
            else
                say_status "WARNING" "Build package is not installed or absent from the current package index: $package."
            fi
        done

        if (( WITH_RETROARCH )) || [[ "$OPERATION" == "install-retroarch" ]]; then
            local retro_count=0
            local package
            for package in "$(available_retroarch_packages)"; do
                if package_installed "$package"; then
                    say_status "PASS" "RetroArch package is installed: $package."
                else
                    say_status "WARNING" "RetroArch package is available and will be installed: $package."
                fi
                retro_count=$((retro_count + 1))
            done
            if ! package_available retroarch; then
                say_status "BLOCKER" "The RetroArch package is unavailable in the configured Ubuntu package sources."
            elif (( retro_count == 0 )); then
                say_status "BLOCKER" "No native RetroArch packages were found."
            fi
        fi
    else
        say_status "NOT CHECKED" "Package state could not be queried."
    fi
}

configure_library_launchers() {
    local root="$1"
    [[ -d "$root" ]] || { printf 'Library root is not a directory: %s\n' "$root" >&2; return 1; }

    start_logging
    local retro_wrapper="$HOME/Applications/Pegasus/retroarch-pegasus.sh"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    mkdir -p "$(dirname "$retro_wrapper")"
    rm -f -- "$HOME/Applications/Pegasus/retroarch-stats-overlay.py" "$HOME/Applications/Pegasus/retroarch-session-monitor.py"
    cat > "$retro_wrapper" <<'WRAPPER'
#!/usr/bin/env bash
set -u
retroarch="$HOME/Applications/Pegasus/RetroArch/bin/retroarch"
[[ -x "$retroarch" ]] || retroarch="/usr/bin/retroarch"
mega_bezel_root="$HOME/.config/retroarch/shaders/Mega_Bezel_Packs/Duimon-Mega-Bezel"
arcade_shader="$mega_bezel_root/Presets/Lite/FB-Neo/FB-Neo-[STD]-[Guest-Mini][CABINET][NO TILT]-Pegasus-Reflections.slangp"
arcade_gameart_presets="$mega_bezel_root/Presets/Lite/FB-Neo/Pegasus-GameArt"
console_presets="$mega_bezel_root/Presets/Lite"
fallback_shader="$HOME/.config/retroarch/shaders/shaders_slang/bezel/Mega_Bezel/Presets/Base_CRT_Presets/Root_Presets/MBZ__PEGASUS__STD-REFLECTIONS.slangp"
shader="$fallback_shader"
select_console_shader() {
    local system="$1"
    local preset=""
    case "$system" in
        3ds) preset="$console_presets/Nintendo_3DS/3DS-[STD]-[Guest-Mini]-Pegasus-Reflections.slangp" ;;
        atari2600) preset="$console_presets/Atari_2600/2600-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        gb) preset="$console_presets/Nintendo_Game_Boy/Gameboy-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        gba) preset="$console_presets/Nintendo_GBA/GBA-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        megacd|segacd) preset="$console_presets/SEGA_CD/SEGACD_Alt-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        megadrive|genesis) preset="$console_presets/SEGA_Genesis/Genesis-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        mastersystem) preset="$console_presets/SEGA_Master_System/SMS_Alt-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        n64) preset="$console_presets/Nintendo_N64/N64-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        nds) preset="$console_presets/Nintendo_NDS/NDS-[STD]-[Guest-Mini]-Pegasus-Reflections.slangp" ;;
        nes) preset="$console_presets/Nintendo_NES/NES-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        ngc) preset="$console_presets/Nintendo_Gamecube/Gamecube-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        pcengine) preset="$console_presets/NEC_PC_Engine/PC_Engine-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        ps2) preset="$console_presets/SONY_Playstation_2/Playstation2-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        psx) preset="$console_presets/SONY_Playstation/Playstation_Alt-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        psp) preset="$console_presets/SONY_PSP/PSP-[STD]-[Guest-Mini]-Pegasus-Reflections.slangp" ;;
        sega32x) preset="$console_presets/SEGA_32X/SEGA32X_Alt-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        snes) preset="$console_presets/Nintendo_SNES/SNES-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        supergrafx) preset="$console_presets/NEC_SuperGrafx/SuperGrafx_Alt-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        dreamcast) preset="$console_presets/SEGA_Dreamcast/Dreamcast_Alt-[STD]-[Guest-Mini]-[Bezel]-Pegasus-Reflections.slangp" ;;
        *) return 0 ;;
    esac
    if [[ -s "$preset" ]]; then
        shader="$preset"
    else
        printf 'Duimon performance preset unavailable for console %s: %s\n' "$system" "$preset" >&2
    fi
}
arcade_core=false
arcade_content=""
core_name=""
content_path=""
for argument in "$@"; do
    case "$argument" in
        *fbneo_libretro.so|*fbneo_libretro.dll)
            core_name="${argument##*/}"
            arcade_core=true
            [[ -f "$arcade_shader" ]] && shader="$arcade_shader"
            ;;
        *_libretro.so|*_libretro.dll) core_name="${argument##*/}" ;;
    esac
    case "$argument" in
        *.zip)
            [[ -f "$argument" ]] && arcade_content="$argument"
            ;;
    esac
    if [[ -f "$argument" && "$argument" != *_libretro.so && "$argument" != *_libretro.dll ]]; then
        content_path="$argument"
    fi
done
console_system=""
case "$core_name" in
    *citra*|*azahar*) console_system=3ds ;;
    *stella*) console_system=atari2600 ;;
    *gambatte*|*sameboy*|*gearboy*|*tgbdual*) console_system=gb ;;
    *mgba*|*gpsp*|*vbam*|*vba_next*|*mednafen_gba*) console_system=gba ;;
    *genesis_plus_gx*|*picodrive*|*blastem*) console_system=megadrive ;;
    *mupen64plus*) console_system=n64 ;;
    *desmume*|*melonds*) console_system=nds ;;
    *dolphin*) console_system=ngc ;;
    *fceumm*|*nestopia*|*quicknes*|*mesen*) console_system=nes ;;
    *mednafen_pce*|*beetle_pce*) console_system=pcengine ;;
    *pcsx2*) console_system=ps2 ;;
    *pcsx_rearmed*|*mednafen_psx*|*beetle_psx*|*duckstation*) console_system=psx ;;
    *ppsspp*) console_system=psp ;;
    *snes9x*|*bsnes*|*mednafen_snes*) console_system=snes ;;
    *supergrafx*) console_system=supergrafx ;;
    *flycast*|*redream*) console_system=dreamcast ;;
esac
if [[ -n "$content_path" ]]; then
    content_path=$(realpath -e -- "$content_path" 2>/dev/null || printf '%s' "$content_path")
    content_path_lower="${content_path,,}"
    case "$content_path_lower" in
        */3ds/*) console_system=3ds ;;
        */atari2600/*) console_system=atari2600 ;;
        */dreamcast/*) console_system=dreamcast ;;
        */gb/*|*/gameboy/*) console_system=gb ;;
        */gba/*) console_system=gba ;;
        */megacd/*|*/segacd/*) console_system=megacd ;;
        */megadrive/*|*/genesis/*) console_system=megadrive ;;
        */mastersystem/*|*/master_system/*) console_system=mastersystem ;;
        */n64/*) console_system=n64 ;;
        */nds/*) console_system=nds ;;
        */nes/*) console_system=nes ;;
        */ngc/*|*/gamecube/*) console_system=ngc ;;
        */pcengine/*|*/pce/*) console_system=pcengine ;;
        */ps2/*) console_system=ps2 ;;
        */psx/*|*/playstation/*) console_system=psx ;;
        */psp/*) console_system=psp ;;
        */sega32x/*|*/32x/*) console_system=sega32x ;;
        */snes/*) console_system=snes ;;
        */supergrafx/*|*/sgx/*) console_system=supergrafx ;;
        */atomiswave/*) console_system="" ;;
    esac
fi
if [[ "$arcade_core" == true && -n "$arcade_content" ]]; then
    arcade_content=$(realpath -e -- "$arcade_content" 2>/dev/null || true)
    if [[ -n "$arcade_content" ]]; then
        arcade_game_key=$(printf '%s' "$arcade_content" | sha256sum | cut -c1-16)
        gameart_shader="$arcade_gameart_presets/$arcade_game_key.slangp"
        if [[ -s "$gameart_shader" ]]; then
            shader="$gameart_shader"
        fi
    fi
elif [[ -n "$console_system" ]]; then
    select_console_shader "$console_system"
fi

restore_1280_output() {
    command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface scaling-factor 1 2>/dev/null || true
    command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface text-scaling-factor 1.0 2>/dev/null || true
    command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.mutter experimental-features "[]" 2>/dev/null || true
    command -v xrandr >/dev/null 2>&1 || return 0
    local output
    output=$(xrandr --query 2>/dev/null | awk '$2 == "connected" {print $1; exit}')
    if [[ -n "$output" ]] && xrandr --query 2>/dev/null | grep -qE "^   1280x720.*60"; then
        xrandr --output "$output" --mode 1280x720 --rate 60 2>/dev/null || true
    fi
}

cleanup() {
    restore_1280_output
    rm -f -- "${shader_config:-}"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
shader_config=$(mktemp "${TMPDIR:-/tmp}/pegasus-shader.XXXXXX.cfg")
printf 'video_shader_enable = "true"\nfps_show = "false"\nframecount_show = "false"\ncontent_runtime_log = "false"\nlog_to_file = "false"\nlog_verbosity = "false"\n' > "$shader_config"
"$retroarch" --fullscreen --appendconfig "$HOME/.config/retroarch/pegasus-megabezel.cfg|$shader_config" --set-shader="$shader" "$@" >/dev/null 2>&1
status=$?
restore_1280_output
exit "$status"
WRAPPER
    chmod 0755 "$retro_wrapper"
    record_manifest "$retro_wrapper" "created_or_modified" "Pegasus RetroArch launcher enforces 1280x720 and selects Duimon Mega Bezel presets"

    python3 - "$root" "$HOME" <<'PY'
import os
import sys
import shutil
import hashlib
import re
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

try:
    from PIL import Image, ImageEnhance, ImageFilter
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

root = Path(sys.argv[1]).expanduser().resolve()
home = Path(sys.argv[2]).expanduser().resolve()
cores = home / '.config/retroarch/cores'
system_cores = Path('/usr/lib/aarch64-linux-gnu/libretro')
retroarch_native = home / 'Applications/Pegasus/RetroArch/bin/retroarch'
retroarch = home / 'Applications/Pegasus/retroarch-pegasus.sh'
if not retroarch.is_file():
    retroarch = retroarch_native if retroarch_native.is_file() else Path('/usr/bin/retroarch')

systems = (
    ('megadrive', 'Mega Drive', (cores / 'picodrive_libretro.so', system_cores / 'picodrive_libretro.so'), {'.zip', '.bin', '.smd', '.md', '.gen'}, 'megadrive', 'megadrive', 'Sega - Mega Drive - Genesis'),
    ('fbneo', 'FinalBurn Neo', (cores / 'fbneo_libretro.so',), {'.zip'}, 'arcade', 'arcade', 'FBNeo - Arcade Games'),
    ('nes', 'Nintendo Entertainment System', tuple(path / name for path in (cores, system_cores) for name in ('fceumm_libretro.so', 'nestopia_libretro.so', 'quicknes_libretro.so')), {'.nes', '.zip', '.7z'}, 'nes', 'nes', 'Nintendo - Nintendo Entertainment System'),
    ('snes', 'Super Nintendo Entertainment System', (cores / 'snes9x_libretro.so', system_cores / 'snes9x_libretro.so'), {'.smc', '.sfc', '.zip', '.7z'}, 'snes', 'snes', 'Nintendo - Super Nintendo Entertainment System'),
)

for folder, collection, core_candidates, extensions, shortname, scraper_platform, artwork_platform in systems:
    system_dir = root / folder
    if not system_dir.is_dir():
        print(f'Skip: {system_dir} does not exist')
        continue
    core = next((candidate for candidate in core_candidates if candidate.is_file()), core_candidates[0])
    if not core.is_file():
        print(f'Skip: {collection}: core not found at {core}')
        continue

    names = {}
    local_images = {}
    local_screenshots = {}
    local_videos = {}
    gamelist = system_dir / 'gamelist.xml'
    if gamelist.is_file():
        try:
            for game in ET.parse(gamelist).getroot().findall('.//game'):
                path_node = game.find('path')
                name_node = game.find('name')
                if path_node is None or name_node is None:
                    continue
                name = name_node.text or ''
                if name.startswith('ZZZ(notgame):'):
                    continue
                rel = path_node.text.lstrip('./\\')
                filename_key = Path(rel).name.lower()
                names[filename_key] = name.strip()
                image_node = game.find('image')
                if image_node is not None and image_node.text:
                    image_rel = image_node.text.lstrip('./\\')
                    image_path = system_dir / image_rel
                    if image_path.is_file():
                        local_images[filename_key] = image_path
        except ET.ParseError as exc:
            print(f'Warning: could not parse {gamelist}: {exc}')

    platform_cache = home / '.skyscraper/cache' / scraper_platform
    quickid_path = platform_cache / 'quickid.xml'
    db_path = platform_cache / 'db.xml'
    if quickid_path.is_file() and db_path.is_file():
        try:
            resource_titles = {}
            resource_covers = {}
            resource_screenshots = {}
            resource_videos = {}
            for resource in ET.parse(db_path).getroot().findall('.//resource'):
                resource_id = resource.get('id')
                resource_type = resource.get('type')
                if resource_id and resource_type == 'title':
                    resource_titles[resource_id] = (resource.text or '').strip()
                if resource_id and resource_type == 'cover':
                    resource_covers[resource_id] = platform_cache / resource.text.strip() if resource.text else None
                if resource_id and resource_type == 'screenshot':
                    resource_screenshots[resource_id] = platform_cache / resource.text.strip() if resource.text else None
                if resource_id and resource_type in ('video', 'video-normalized'):
                    resource_videos[resource_id] = platform_cache / resource.text.strip() if resource.text else None
            for quickid in ET.parse(quickid_path).getroot().findall('.//quickid'):
                rom_path = Path(quickid.get('filepath', '')).expanduser()
                resource_id = quickid.get('id')
                if rom_path.is_file() and rom_path.name.lower():
                    if resource_id in resource_titles:
                        names.setdefault(rom_path.name.lower(), resource_titles[resource_id])
                    cover_path = resource_covers.get(resource_id)
                    if cover_path and cover_path.is_file() and cover_path.stat().st_size > 100:
                        local_images[rom_path.name.lower()] = cover_path
                    screenshot_path = resource_screenshots.get(resource_id)
                    if screenshot_path and screenshot_path.is_file() and screenshot_path.stat().st_size > 100:
                        local_screenshots[rom_path.name.lower()] = screenshot_path
                    video_path = resource_videos.get(resource_id)
                    if video_path and video_path.is_file() and video_path.stat().st_size > 100:
                        local_videos[rom_path.name.lower()] = video_path
        except ET.ParseError as exc:
            print(f'Warning: could not parse Skyscraper cache: {exc}')

    files = sorted(
        p for p in system_dir.rglob('*')
        if p.is_file() and p.suffix.lower() in extensions
        and not p.name.lower().startswith('ZZZ'.lower())
        and (folder != 'fbneo' or p.name.lower() not in {'aes.zip', 'neogeo.zip'})
    )
    if not files:
        print(f'Skip: {collection}: no ROM files found')
        continue

    art_dir = root / '.media' / 'box2dfront'
    screenshot_dir = root / '.media' / 'screenshots'
    video_dir = root / '.media' / 'videos'
    arcade_pack = home / '.config/retroarch/shaders/Mega_Bezel_Packs/Duimon-Mega-Bezel'
    arcade_base_preset = arcade_pack / 'Presets/Lite/FB-Neo/FB-Neo-[STD]-[Guest-Mini].slangp'
    arcade_preset_dir = arcade_pack / 'Presets/Lite/FB-Neo/Pegasus-GameArt'
    arcade_bezelproject_dir = root / '.media' / 'bezelproject' / 'ArcadeBezels'
    arcade_background_dir = home / '.config/retroarch/pegasus-gameart/fbneo/backgrounds'
    arcade_background_layout_version = 'bezelproject-marquee-background-v1'
    arcade_background_layout_marker = arcade_background_dir / '.layout-version'
    try:
        current_background_layout_version = (
            arcade_background_layout_marker.read_text(encoding='ascii').strip()
            if arcade_background_layout_marker.is_file()
            else ''
        )
    except OSError as exc:
        print(f'Warning: could not read FBNeo artwork layout marker: {exc}')
        current_background_layout_version = ''
    rebuild_arcade_backgrounds = current_background_layout_version != arcade_background_layout_version
    arcade_background_layout_errors = []
    art_dir.mkdir(parents=True, exist_ok=True)
    screenshot_dir.mkdir(parents=True, exist_ok=True)
    video_dir.mkdir(parents=True, exist_ok=True)

    def remove_arcade_game_art(preset, background):
        if preset.is_file():
            preset.unlink()
        if background.is_file():
            background.unlink()

    def create_arcade_game_art(rom, bezel_art):
        if folder != 'fbneo':
            return None

        game_key = hashlib.sha256(str(rom.resolve()).encode('utf-8')).hexdigest()[:16]
        preset = arcade_preset_dir / (game_key + '.slangp')
        background = arcade_background_dir / (game_key + '.jpg')
        if not bezel_art or not bezel_art.is_file():
            remove_arcade_game_art(preset, background)
            return None
        if not arcade_base_preset.is_file():
            print(f'Warning: Duimon FBNeo base preset unavailable; using cabinet bezel for {rom.name}')
            remove_arcade_game_art(preset, background)
            return None
        needs_background = (
            rebuild_arcade_backgrounds
            or not background.is_file()
            or background.stat().st_size <= 100
        )
        if not PIL_AVAILABLE:
            print(f'Warning: Pillow unavailable; using cabinet bezel for {rom.name}')
            arcade_background_layout_errors.append(rom.name)
            remove_arcade_game_art(preset, background)
            return None

        arcade_preset_dir.mkdir(parents=True, exist_ok=True)
        if needs_background:
            arcade_background_dir.mkdir(parents=True, exist_ok=True)

        def fill(image, width, height):
            ratio = max(width / image.width, height / image.height)
            resized = image.resize(
                (max(width, round(image.width * ratio)), max(height, round(image.height * ratio))),
                Image.LANCZOS,
            )
            left = (resized.width - width) // 2
            top = (resized.height - height) // 2
            return resized.crop((left, top, left + width, top + height))

        try:
            with Image.open(bezel_art) as image:
                image.verify()
            if needs_background:
                art = Image.open(bezel_art).convert('RGBA')
                opaque_art = Image.new('RGBA', art.size, (8, 8, 8, 255))
                opaque_art.alpha_composite(art)
                canvas = fill(opaque_art.convert('RGB'), 1280, 720).filter(ImageFilter.GaussianBlur(24))
                canvas = ImageEnhance.Brightness(canvas).enhance(0.28)
                foreground = art.resize((1280, 720), Image.LANCZOS)
                canvas_rgba = canvas.convert('RGBA')
                canvas_rgba.alpha_composite(foreground)
                canvas = canvas_rgba.convert('RGB')
                temporary_background = background.with_suffix('.jpg.tmp')
                canvas.save(temporary_background, format='JPEG', quality=90, optimize=True)
                temporary_background.replace(background)

            preset_text = arcade_base_preset.read_text(encoding='utf-8')
            reference_lines = []
            for line in preset_text.splitlines():
                if line.startswith('#reference "') and '../../../' in line:
                    line = line.replace('../../../', '../../../../', 1)
                reference_lines.append(line)
            preset_text = '\n'.join(reference_lines).rstrip() + '\n'
            preset_text = preset_text.replace(
                '../../../../zzz_global_params/Base_Shader/LITE.slangp',
                '../../../../zzz_global_params/Base_Shader/PEGASUS_LITE_REFLECT.slangp',
            )
            preset_text += '\n# Pegasus per-game arcade artwork and display settings\n'
            preset_text += 'BackgroundImage = ' + json.dumps(str(background)) + '\n'
            preset_text += 'HSM_ASPECT_RATIO_MODE = "1.000000"\n'
            preset_text += 'HSM_ASPECT_RATIO_EXPLICIT = "1.431961"\n'
            preset_text += 'HSM_PEGASUS_SCREEN_WIDTH_OFFSET = "0.000000"\n'
            preset_text += 'HSM_NON_INTEGER_SCALE = "86.000000"\n'
            preset_text += 'HSM_SCANLINE_DIRECTION = "1.000000"\n'
            preset_text += 'HSM_CURVATURE_MODE = "1.000000"\n'
            preset_text += 'HSM_CRT_CURVATURE_SCALE = "100.000000"\n'
            preset_text += 'HSM_SCREEN_VIGNETTE_ON = "0.000000"\n'
            preset_text += 'shadowMask = "-1.000000"\n'
            preset_text += 'scanline = "8.000000"\n'
            preset_text += 'HSM_REFLECT_FULLSCREEN_GLOW = "0.000000"\n'
            preset_text += 'HSM_REFLECT_BEZEL_INNER_EDGE_FULLSCREEN_GLOW = "0.000000"\n'
            preset_text += 'HSM_REFLECT_CORNER_FADE = "0.000000"\n'
            preset_text += 'PR = "0.000000"\nPG = "0.000000"\nPB = "0.000000"\nAS = "0.000000"\n'
            temporary_preset = preset.with_suffix('.slangp.tmp')
            if not preset.is_file() or preset.read_text(encoding='utf-8') != preset_text:
                temporary_preset.write_text(preset_text, encoding='utf-8')
                temporary_preset.replace(preset)
            return preset
        except (OSError, ValueError) as exc:
            print(f'Warning: could not create Bezel Project background for {rom.name}: {exc}')
            arcade_background_layout_errors.append(rom.name)
            remove_arcade_game_art(preset, background)
            return None

    def download_box_art(rom, title):
        cache = art_dir / (hashlib.sha256(str(rom).encode('utf-8')).hexdigest()[:16] + '.png')
        if cache.is_file() and cache.stat().st_size > 100:
            return cache

        local_image = local_images.get(rom.name.lower())
        if local_image:
            shutil.copy2(local_image, cache)
            return cache

        platform = artwork_platform
        cleaned = re.sub(r'\s*\([^)]*\).*$', '', rom.stem).strip()
        cleaned = re.sub(r'\s*\[[^\]]*\].*$', '', cleaned).strip()
        candidates = []
        for value in (title, cleaned, rom.stem):
            value = re.sub(r'\s+', ' ', value).strip()
            if value and value not in candidates:
                candidates.append(value)
            transformed = value.replace(' : ', ' - ').replace(':', ' - ')
            transformed = re.sub(r'\s+', ' ', transformed).strip(' -')
            if transformed and transformed not in candidates:
                candidates.append(transformed)
        if folder == 'megadrive':
            for value in list(candidates):
                for suffix in (' (USA)', ' (Europe)', ' (World)', ' (USA, Europe)'):
                    candidate = value + suffix
                    if candidate not in candidates:
                        candidates.append(candidate)

        for candidate in candidates[:12]:
            url = 'https://thumbnails.libretro.com/' + urllib.parse.quote(platform, safe='-') + '/Named_Boxarts/' + urllib.parse.quote(candidate, safe="()[]_-.,&'") + '.png'
            try:
                with urllib.request.urlopen(url, timeout=8) as response:
                    data = response.read()
                if data.startswith(bytes((0x89,)) + b'PNG\r\n' + bytes((0x1A,)) + b'\n') and len(data) > 100:
                    cache.write_bytes(data)
                    print(f'Downloaded box art: {rom.name} -> {candidate}')
                    return cache
            except Exception:
                continue
        return None

    def download_screenshot(rom, title):
        cache = screenshot_dir / (hashlib.sha256(str(rom).encode('utf-8')).hexdigest()[:16] + '.png')
        if cache.is_file() and cache.stat().st_size > 100:
            return cache

        local_screenshot = local_screenshots.get(rom.name.lower())
        if local_screenshot:
            shutil.copy2(local_screenshot, cache)
            return cache

        platform = artwork_platform
        cleaned = re.sub(r'\s*\([^)]*\).*$', '', rom.stem).strip()
        cleaned = re.sub(r'\s*\[[^\]]*\].*$', '', cleaned).strip()
        candidates = []
        for value in (title, cleaned, rom.stem):
            value = re.sub(r'\s+', ' ', value).strip()
            if value and value not in candidates:
                candidates.append(value)
        if folder == 'megadrive':
            for value in list(candidates):
                for suffix in (' (USA)', ' (Europe)', ' (World)', ' (USA, Europe)'):
                    candidate = value + suffix
                    if candidate not in candidates:
                        candidates.append(candidate)
        for candidate in candidates[:12]:
            url = 'https://thumbnails.libretro.com/' + urllib.parse.quote(platform, safe='-') + '/Named_Snaps/' + urllib.parse.quote(candidate, safe="()[]_-.,&'") + '.png'
            try:
                with urllib.request.urlopen(url, timeout=8) as response:
                    data = response.read()
                if data.startswith(bytes((0x89,)) + b'PNG\r\n' + bytes((0x1A,)) + b'\n') and len(data) > 100:
                    cache.write_bytes(data)
                    print(f'Downloaded screenshot: {rom.name} -> {candidate}')
                    return cache
            except Exception:
                continue
        return None

    def download_bezel_project_art(rom):
        if folder != 'fbneo':
            return None

        arcade_bezelproject_dir.mkdir(parents=True, exist_ok=True)
        cache = arcade_bezelproject_dir / (rom.stem.lower() + '.png')
        if cache.is_file() and cache.stat().st_size > 100:
            return cache

        asset_name = urllib.parse.quote(rom.stem.lower(), safe='')
        url = (
            'https://raw.githubusercontent.com/thebezelproject/bezelprojectSA-MAME/'
            'master/retroarch/overlay/ArcadeBezels/' + asset_name + '.png'
        )
        try:
            with urllib.request.urlopen(url, timeout=15) as response:
                data = response.read()
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                print(f'Warning: Bezel Project marquee unavailable for {rom.name}; using cabinet bezel')
                return None
            print(f'Warning: could not download Bezel Project art for {rom.name}: HTTP {exc.code}')
            arcade_background_layout_errors.append(rom.name)
            return None
        except (urllib.error.URLError, OSError, TimeoutError) as exc:
            print(f'Warning: could not download Bezel Project art for {rom.name}: {exc}')
            arcade_background_layout_errors.append(rom.name)
            return None

        if not data.startswith(bytes((0x89,)) + b'PNG\r\n' + bytes((0x1A,)) + b'\n') or len(data) <= 100:
            print(f'Warning: invalid Bezel Project PNG received for {rom.name}')
            arcade_background_layout_errors.append(rom.name)
            return None

        temporary_cache = cache.with_suffix('.png.tmp')
        temporary_cache.write_bytes(data)
        temporary_cache.replace(cache)
        print(f'Downloaded Bezel Project art: {rom.name}')
        return cache

    def copy_video(rom):
        local_video = local_videos.get(rom.name.lower())
        if not local_video:
            return None
        suffix = local_video.suffix.lower() or '.mp4'
        cache = video_dir / (hashlib.sha256(str(rom).encode('utf-8')).hexdigest()[:16] + suffix)
        if cache.is_file() and cache.stat().st_size > 100:
            return cache
        shutil.copy2(local_video, cache)
        return cache

    artwork_tasks = []
    with ThreadPoolExecutor(max_workers=6) as executor:
        for rom in files:
            default_name = rom.stem.replace('_', ' ').replace('-', ' ').strip() or rom.stem
            title = names.get(rom.name.lower(), default_name)
            title = title.replace('\n', ' ').replace('\r', ' ').strip()
            artwork_tasks.append((
                rom,
                title,
                executor.submit(download_box_art, rom, title),
                executor.submit(download_screenshot, rom, title),
                executor.submit(copy_video, rom),
                executor.submit(download_bezel_project_art, rom),
            ))

    out = system_dir / 'metadata.pegasus.txt'
    backup = None
    if out.exists():
        backup_dir = home / '.local/state/pegasus-opi5-installer/backups'
        backup_dir.mkdir(parents=True, exist_ok=True)
        backup = backup_dir / ('metadata.pegasus.txt.' + folder + '.' + __import__('datetime').datetime.now().strftime('%Y%m%d-%H%M%S'))
        shutil.copy2(out, backup)
        print(f'Backed up: {out} -> {backup}')

    lines = [
        f'collection: {collection}',
        f'shortname: {shortname}',
        f'launch: {retroarch} --fullscreen -L "{core}" "{{file.path}}"',
        f'workdir: {home / "Applications/Pegasus"}',
        '',
    ]
    for rom, title, box_future, screenshot_future, video_future, bezel_future in artwork_tasks:
        lines.extend([f'game: {title}', f'file: {rom}'])
        artwork = None
        try:
            artwork = box_future.result()
            if artwork:
                lines.append(f'assets.boxFront: {artwork}')
        except Exception as exc:
            print(f'Warning: box art unavailable for {rom.name}: {exc}')
        if folder == 'fbneo':
            try:
                create_arcade_game_art(rom, bezel_future.result())
            except Exception as exc:
                print(f'Warning: Bezel Project art unavailable for {rom.name}: {exc}')
                arcade_background_layout_errors.append(rom.name)
                game_key = hashlib.sha256(str(rom.resolve()).encode('utf-8')).hexdigest()[:16]
                remove_arcade_game_art(
                    arcade_preset_dir / (game_key + '.slangp'),
                    arcade_background_dir / (game_key + '.jpg'),
                )
        try:
            screenshot = screenshot_future.result()
            if screenshot:
                lines.append(f'assets.screenshot: {screenshot}')
                lines.append(f'assets.background: {screenshot}')
        except Exception as exc:
            print(f'Warning: screenshot unavailable for {rom.name}: {exc}')
        try:
            video = video_future.result()
            if video:
                lines.append(f'assets.video: {video}')
        except Exception as exc:
            print(f'Warning: video unavailable for {rom.name}: {exc}')
        lines.append('')

    if folder == 'fbneo':
        if arcade_background_layout_errors:
            print(
                'FBNeo artwork layout was not fully regenerated; '
                'the next library configuration will retry.'
            )
        else:
            arcade_background_dir.mkdir(parents=True, exist_ok=True)
            arcade_background_layout_marker.write_text(
                arcade_background_layout_version + '\n',
                encoding='ascii',
            )

    out.write_text('\n'.join(lines), encoding='utf-8')
    print(f'Created: {out} ({len(files)} games)')
    if folder == 'fbneo':
        generated = len(list(arcade_preset_dir.glob('*.slangp'))) if arcade_preset_dir.is_dir() else 0
        print(f'FBNeo Duimon game-art presets available: {generated}; games without Bezel Project art use the cabinet bezel.')
PY
    local arcade_gameart_root="$HOME/.config/retroarch/pegasus-gameart/fbneo"
    local arcade_gameart_presets="$HOME/.config/retroarch/shaders/Mega_Bezel_Packs/Duimon-Mega-Bezel/Presets/Lite/FB-Neo/Pegasus-GameArt"
    local arcade_bezelproject_root="$root/.media/bezelproject/ArcadeBezels"
    if [[ -d "$arcade_gameart_root" || -d "$arcade_gameart_presets" || -d "$arcade_bezelproject_root" ]]; then
        while IFS= read -r -d '' artifact; do
            record_manifest "$artifact" "created_or_modified" "Bezel Project art, FBNeo background, or Duimon shader preset"
        done < <(find "$arcade_gameart_root" "$arcade_gameart_presets" "$arcade_bezelproject_root" -type f -print0 2>/dev/null)
    fi
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pegasus-frontend"
    local game_dirs="$config_dir/game_dirs.txt"
    mkdir -p "$config_dir"
    if [[ -f "$game_dirs" ]]; then
        local timestamp backup_file
        timestamp="$(date +%Y%m%d-%H%M%S)"
        backup_file="$STATE_ROOT/backups/game_dirs.txt.$timestamp"
        cp -a -- "$game_dirs" "$backup_file"
        record_manifest "$backup_file" "backed_up" "Pegasus game directories preserved before launch integration"
    fi
    python3 - "$game_dirs" "$root/megadrive" "$root/fbneo" "$root/nes" "$root/snes" <<'PY'
from pathlib import Path
import sys

config = Path(sys.argv[1])
extra_dirs = [Path(p) for p in sys.argv[2:]]
existing = []
if config.exists():
    existing = [line.rstrip('\n') for line in config.read_text(encoding='utf-8').splitlines() if line and not line.startswith('#')]
for directory in extra_dirs:
    if directory.is_dir():
        value = str(directory.resolve())
        if value not in existing:
            existing.append(value)
config.parent.mkdir(parents=True, exist_ok=True)
config.write_text('\n'.join(existing) + '\n', encoding='utf-8')
PY
    record_manifest "$game_dirs" "created_or_modified" "Pegasus metadata game directories for supported RetroArch libraries"
    printf '\nPegasus RetroArch launch metadata configured under %s.\n' "$root"
    printf 'Nested directories are included recursively; BIOS archives are not registered as games.\n'
    printf 'Log: %s\nManifest: %s\n' "$LOG_FILE" "$MANIFEST_FILE"
}

inspect_library() {
    local root="$1"
    local path

    if [[ ! -d "$root" ]]; then
        say_status "BLOCKER" "Library root is not an accessible directory: $root"
        return 1
    fi

    printf 'Read-only library inspection: %s\n' "$root"
    if [[ -r "$root" ]]; then
        say_status "PASS" "Library root is readable."
    else
        say_status "BLOCKER" "Library root is not readable."
        return 1
    fi
    if [[ -w "$root" ]]; then
        say_status "WARNING" "Library root is writable by this user; this inspection will not write to it."
    else
        say_status "PASS" "Library root is not writable by this user."
    fi

    printf 'Top-level entries:\n'
    find "$root" -mindepth 1 -maxdepth 1 -printf '  %f (%y)\n' | sort

    printf 'EmulationStation metadata candidates (maximum depth 5):\n'
    while IFS= read -r -d '' path; do
        printf '  %s\n' "$path"
    done < <(find "$root" -type f \( -iname 'es_systems.cfg' -o -iname 'gamelist.xml' \) -print0)

    printf 'Common folder candidates:\n'
    for path in roms bios saves media emulationstation; do
        if [[ -e "$root/$path" ]]; then
            printf '  found: %s\n' "$root/$path"
        fi
    done
    printf 'No files or directories were modified.\n'
}

print_plan() {
    printf '\nPegasus source-build plan\n'
    printf '  Source: %s\n  Tag: %s\n  Pinned commit: %s\n' \
        "$SOURCE_URL" "$SOURCE_TAG" "$SOURCE_COMMIT"
    printf '  Architecture: %s\n' "$(uname -m)"
    printf '  Build packages: %s\n' "${BUILD_PACKAGES[*]}"
    printf '  Install path: %s\n' "$INSTALL_DIR"
    printf '  Build/cache path: %s\n' "$WORK_ROOT"
    printf '  Logs/manifest/backups: %s\n' "$STATE_ROOT"
    printf '  Existing Pegasus configuration: not modified\n'
    printf '  RetroBat/library files: not copied, moved, or modified\n'
    if (( WITH_RETROARCH )); then
        printf '  RetroArch: native ARM64 packages and available curated Ubuntu core packages\n'
        printf '  RetroArch packages: %s\n' "$(available_retroarch_packages | tr '\n' ' ')"
    else
        printf '  RetroArch/emulators: none\n'
    fi
    printf '  Library directories: %s/roms and %s/bios (created only with RetroArch opt-in)\n' "$INSTALL_DIR" "$INSTALL_DIR"
    printf '  Exact build actions after approval:\n'
    local missing_packages=()
    local package
    for package in "${BUILD_PACKAGES[@]}"; do
        if ! package_installed "$package"; then
            missing_packages+=("$package")
        fi
    done
    if ((${#missing_packages[@]})); then
        if [[ -t 0 ]]; then
            printf '    sudo apt-get install --no-install-recommends %s\n' "${missing_packages[*]}"
        else
            printf '    pkexec apt-get install -y --no-install-recommends %s (if PolicyKit is available)\n' "${missing_packages[*]}"
        fi
    else
        printf '    no apt package installation (all required build packages are present)\n'
    fi
    printf '    git clone --depth 1 --branch %s %s %s/source-%s\n' \
        "$SOURCE_TAG" "$SOURCE_URL" "$WORK_ROOT" "$SOURCE_TAG"
    printf '    cmake -S %s/source-%s -B %s/cmake-build-%s -DPEGASUS_ON_X11=ON -DPEGASUS_USE_SDL2_GAMEPAD=ON\n' \
        "$WORK_ROOT" "$SOURCE_TAG" "$WORK_ROOT" "$SOURCE_TAG"
    printf '    cmake --build %s/cmake-build-%s --parallel %s && cmake --install %s/cmake-build-%s\n' \
        "$WORK_ROOT" "$SOURCE_TAG" "$JOBS" "$WORK_ROOT" "$SOURCE_TAG"
    printf '    install the per-user X11 desktop entry (back up any existing entry first)\n\n'
}

confirm_install() {
    if (( DRY_RUN )); then
        printf 'Dry run: no packages, files, or directories will be changed.\n'
        return 1
    fi

    if (( ASSUME_YES )); then
        printf 'Installation explicitly authorized by --yes.\n'
        return 0
    fi

    if [[ ! -t 0 ]]; then
        printf 'Refusing to install without an interactive confirmation or explicit --yes.\n' >&2
        return 1
    fi

    local answer
    read -r -p "Continue with the listed build and install actions? [y/N] " answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

record_manifest() {
    local filepath="$1"
    local action="$2"
    local reason="$3"
    python3 - "$MANIFEST_FILE" "$filepath" "$action" "$reason" <<'PY'
import csv
import os
import sys

manifest, path, action, reason = sys.argv[1:]
new_file = not os.path.exists(manifest)
with open(manifest, "a", encoding="utf-8", newline="") as stream:
    writer = csv.writer(stream)
    if new_file:
        writer.writerow(("path", "action", "reason"))
    writer.writerow((path, action, reason))
PY
}

start_logging() {
    mkdir -p "$STATE_ROOT/logs" "$STATE_ROOT/backups"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    LOG_FILE="$STATE_ROOT/logs/install-$timestamp.log"
    MANIFEST_FILE="$STATE_ROOT/manifest.csv"
    touch "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    trap 'on_error "$LINENO" "$?"' ERR
    printf 'Log: %s\n' "$LOG_FILE"
    printf 'Manifest: %s\n' "$MANIFEST_FILE"
    record_manifest "$LOG_FILE" "created" "Installation log for this run"
}

on_error() {
    local line="$1"
    local exit_code="$2"
    trap - ERR
    printf 'ERROR: command failed at script line %s (exit %s). Review log: %s\n' \
        "$line" "$exit_code" "${LOG_FILE:-not created}" >&2
    exit "$exit_code"
}

install_packages() {
    local packages=("$@")
    local missing=()
    local package
    for package in "${packages[@]}"; do
        if ! package_installed "$package"; then
            missing+=("$package")
        fi
    done
    if ((${#missing[@]} == 0)); then
        printf 'No package installation is required; all requested packages are installed.\n'
        return 0
    fi

    if [[ -t 0 ]]; then
        sudo apt-get install -y --no-install-recommends "${missing[@]}"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec apt-get install -y --no-install-recommends "${missing[@]}"
    else
        printf 'Missing packages require sudo in a terminal or a PolicyKit prompt via pkexec.\n' >&2
        return 1
    fi
}

set_gameos_default_settings() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pegasus-frontend"
    local theme_dir="${XDG_DATA_HOME:-$HOME/.local/share}/pegasus-frontend/themes/gameOS"
    local settings_file="$config_dir/settings.txt"
    local theme_settings="$config_dir/theme_settings/gameOS.json"

    mkdir -p "$config_dir/theme_settings"
    python3 - "$theme_settings" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except FileNotFoundError:
    data = {}
defaults = {
    "Always show titles": "Yes",
    "Always show titlesIndex": 1,
    "Game Background": "Screenshot",
    "Video preview": "Yes",
    "Allow video thumbnails": "Yes",
    "Play video thumbnail audio": "No",
    "Video preview audio": "No",
    "Game View": "Grid",
    "Game ViewIndex": 0,
    "Refresh library on startup": "Yes",
    "Refresh library on startupIndex": 0,
    "Default sort": "Title",
    "Default sortIndex": 0,
    "Default sort order": "Ascending",
    "Default sort orderIndex": 0,
    "Favorites only on startup": "No",
    "Favorites only on startupIndex": 0,
}
for key, value in defaults.items():
    data.setdefault(key, value)
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, ensure_ascii=False, indent=2)
PY
    if [[ -f "$settings_file" ]]; then
        if grep -q '^general.theme:' "$settings_file"; then
            sed -i "s|^general.theme:.*|general.theme: $theme_dir/|" "$settings_file"
        else
            printf 'general.theme: %s/\n' "$theme_dir" >> "$settings_file"
        fi
    else
        printf 'general.theme: %s/\n' "$theme_dir" > "$settings_file"
    fi
}

install_pegasus_themes() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local theme_dir="${XDG_DATA_HOME:-$HOME/.local/share}/pegasus-frontend/themes"
    local theme="gameOS"
    local repo="https://github.com/PlayingKarrde/gameOS.git"
    local target="$theme_dir/$theme"
    local customization_patch="$script_dir/../patches/gameos-settings.patch"

    mkdir -p "$theme_dir"
    for old_theme in neoretro es2-simple clean-covers nostalgia-grid slate-es-de; do
        if [[ -d "$theme_dir/$old_theme" ]]; then
            rm -rf -- "$theme_dir/$old_theme"
            record_manifest "$theme_dir/$old_theme" "removed" "Removed because gameOS is the selected default theme"
        fi
        local old_settings="${XDG_CONFIG_HOME:-$HOME/.config}/pegasus-frontend/theme_settings/$old_theme.json"
        if [[ -f "$old_settings" ]]; then
            rm -f -- "$old_settings"
            record_manifest "$old_settings" "removed" "Removed settings for an uninstalled theme"
        fi
    done

    if [[ -d "$target/.git" ]]; then
        if git -C "$target" pull --ff-only --quiet; then
            record_manifest "$target" "updated" "gameOS theme repository kept in sync"
        else
            printf 'gameOS theme update failed; keeping the existing installation.\n' >&2
        fi
    elif [[ -e "$target" ]]; then
        printf 'Unexpected theme path exists and will not be replaced: %s\n' "$target" >&2
    elif git clone --depth 1 --quiet "$repo" "$target"; then
        record_manifest "$target" "created" "gameOS Pegasus theme repository"
    else
        printf 'gameOS theme installation failed.\n' >&2
    fi

    if [[ -f "$target/theme.cfg" ]]; then
        if [[ -f "$customization_patch" ]]; then
            if git -C "$target" apply --check "$customization_patch" >/dev/null 2>&1; then
                git -C "$target" apply "$customization_patch"
            elif ! git -C "$target" apply --reverse --check "$customization_patch" >/dev/null 2>&1; then
                printf 'gameOS settings customization no longer applies cleanly: %s\n' "$customization_patch" >&2
                return 1
            fi
        else
            printf 'Missing gameOS settings customization: %s\n' "$customization_patch" >&2
            return 1
        fi
        printf 'Installed default Pegasus theme: gameOS (source: %s)\n' "$repo"
        set_gameos_default_settings
    else
        printf 'Theme verification failed: missing theme.cfg in %s\n' "$target" >&2
    fi
}

install_pegasus_auto_launcher() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local installer_script="$script_dir/install-pegasus.sh"
    local wrapper="$INSTALL_DIR/run-pegasus.sh"
    local desktop_file="${XDG_DATA_HOME:-$HOME/.local/share}/applications/org.pegasus_frontend.Pegasus.desktop"

    cat > "$wrapper" <<EOF
#!/usr/bin/env bash
set -e
force_display_1280() {
    command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface scaling-factor 1 2>/dev/null || true
    command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface text-scaling-factor 1.0 2>/dev/null || true
    command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.mutter experimental-features "[]" 2>/dev/null || true
    if command -v xrandr >/dev/null 2>&1; then
        connected_output=\$(xrandr --query 2>/dev/null | awk '\$2 == "connected" {print \$1; exit}')
        if [[ -n "\$connected_output" ]] && xrandr --query 2>/dev/null | grep -qE '^   1280x720.*60'; then
            xrandr --output "\$connected_output" --mode 1280x720 --rate 60 2>/dev/null || true
        fi
    fi
}
force_display_1280
trap force_display_1280 EXIT HUP INT TERM
if [[ -d "$INSTALL_DIR/roms" ]]; then
    refresh_log="\${XDG_STATE_HOME:-\$HOME/.local/state}/pegasus-opi5-installer/logs/pegasus-startup.log"
    mkdir -p "\$(dirname "\$refresh_log")"
    theme_settings="\${XDG_CONFIG_HOME:-\$HOME/.config}/pegasus-frontend/theme_settings/gameOS.json"
    refresh_library="Yes"
    if [[ -f "\$theme_settings" ]]; then
        if ! refresh_library="\$(python3 -c 'import json,sys; value=json.load(open(sys.argv[1], encoding="utf-8")).get("Refresh library on startup", "Yes"); print(value) if value in ("Yes", "No") else sys.exit(2)' "\$theme_settings" 2>>"\$refresh_log")"; then
            printf 'Could not read the theme library-refresh setting; refreshing by default.\\n' >>"\$refresh_log"
            refresh_library="Yes"
        fi
    fi
    if [[ "\$refresh_library" == "Yes" ]]; then
        bash "$installer_script" --configure-library "$INSTALL_DIR/roms" >>"\$refresh_log" 2>&1 || printf 'Library refresh failed; continuing to launch Pegasus.\\n' >>"\$refresh_log"
    else
        printf 'Library refresh skipped by gameOS setting.\\n' >>"\$refresh_log"
    fi
fi
pegasus_config="\${XDG_CONFIG_HOME:-\$HOME/.config}/pegasus-frontend"
pegasus_log="\$pegasus_config/lastrun.log"
mkdir -p "\$pegasus_config"
if [[ ! -L "\$pegasus_log" || "\$(readlink -- "\$pegasus_log")" != /dev/null ]]; then
    if [[ -e "\$pegasus_log" || -L "\$pegasus_log" ]]; then
        previous_log=\$(mktemp "\${pegasus_log}.previous.XXXXXX")
        mv -- "\$pegasus_log" "\$previous_log"
    fi
    ln -s /dev/null "\$pegasus_log"
fi
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_SCALE_FACTOR=1
"$INSTALL_DIR/pegasus-fe" --silent --disable-menu-reboot --disable-menu-shutdown --disable-menu-suspend "\$@" || status=\$?
status="\${status:-0}"
force_display_1280
exit "\$status"
EOF
    chmod 0755 "$wrapper"
    record_manifest "$wrapper" "created_or_modified" "Pegasus startup wrapper refreshes recursive ROM metadata and box art before launch"
    if [[ -f "$desktop_file" ]]; then
        sed -i "s|^Exec=.*|Exec=$wrapper|" "$desktop_file"
        record_manifest "$desktop_file" "modified" "Desktop launcher uses automatic library refresh wrapper"
    fi
}

install_pegasus_desktop_icon() {
    local icon_source="$WORK_ROOT/source-$SOURCE_TAG/src/app/platform/linux/icons/128/org.pegasus_frontend.Pegasus.png"
    local icon_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/128x128/apps"
    local icon_target="$icon_dir/org.pegasus_frontend.Pegasus.png"
    local desktop_file="${XDG_DATA_HOME:-$HOME/.local/share}/applications/org.pegasus_frontend.Pegasus.desktop"

    if [[ ! -f "$icon_source" ]]; then
        printf 'Pegasus icon asset was not found at %s; leaving launcher unchanged.\n' "$icon_source" >&2
        return 1
    fi
    mkdir -p "$icon_dir"
    cp -f -- "$icon_source" "$icon_target"
    record_manifest "$icon_target" "created_or_modified" "Native Pegasus launcher icon"

    for size in 16 32 48 64; do
        local sized_source="$WORK_ROOT/source-$SOURCE_TAG/src/app/platform/linux/icons/$size/org.pegasus_frontend.Pegasus.png"
        local sized_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/${size}x${size}/apps"
        if [[ -f "$sized_source" ]]; then
            mkdir -p "$sized_dir"
            cp -f -- "$sized_source" "$sized_dir/org.pegasus_frontend.Pegasus.png"
            record_manifest "$sized_dir/org.pegasus_frontend.Pegasus.png" "created_or_modified" "Native Pegasus launcher icon"
        fi
    done

    if [[ -f "$desktop_file" ]] && grep -q '^Icon=' "$desktop_file"; then
        sed -i 's|^Icon=.*|Icon=org.pegasus_frontend.Pegasus|' "$desktop_file"
        record_manifest "$desktop_file" "modified" "Desktop launcher uses installed native Pegasus icon theme entry"
    fi
    install_pegasus_auto_launcher
    install_pegasus_themes
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f -t "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" >/dev/null 2>&1 || true
    fi
}

install_pegasus_scanline_preset() {
    local source="$1"
    local preset_dir
    preset_dir="$(dirname "$source")"
    local reflective_source="$preset_dir/MBZ__3__STD__GDV-MINI.slangp"
    local destination="$preset_dir/MBZ__PEGASUS__STD-REFLECTIONS.slangp"
    [[ -f "$reflective_source" ]] || return 0
    cp -f "$reflective_source" "$destination"
    cat >> "$destination" <<'EOF'

# Pegasus defaults: clean scanlines and bezel reflections without screen glow
# Preserve core aspect detection and add 120 output pixels of centered width.
HSM_ASPECT_RATIO_MODE = 0
HSM_ASPECT_RATIO_EXPLICIT = 1.3333
HSM_PEGASUS_SCREEN_WIDTH_OFFSET = "120.000000"
HSM_SCANLINE_DIRECTION = "1.000000"
HSM_CURVATURE_MODE = "1.000000"
HSM_CRT_CURVATURE_SCALE = "100.000000"
HSM_SCREEN_VIGNETTE_ON = "0.000000"
HSM_BG_OPACITY = "1.000000"
HSM_NON_INTEGER_SCALE = "86.000000"
shadowMask = "-1.000000"
scanline = "8.000000"
PR = "0.000000"
PG = "0.000000"
PB = "0.000000"
AS = "0.000000"
HSM_REFLECT_FULLSCREEN_GLOW = "0.000000"
HSM_REFLECT_BEZEL_INNER_EDGE_FULLSCREEN_GLOW = "0.000000"
HSM_REFLECT_CORNER_FADE = "0.000000"
scale_x19 = 400
scale_y19 = 300
scale_x22 = 64
scale_y22 = 64
scale_x23 = 8
scale_y23 = 8
EOF
    record_manifest "$destination" "created_or_modified" "Pegasus 400x300 reflective preset with clean horizontal scanlines and no screen glow"
}

# Mega Bezel has no independent horizontal scale; extend its geometry math without replacing core aspect detection.
install_pegasus_screen_width_offset() {
    local target="$1"
    python3 - "$target" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
globals_path = root / "shaders/base/common/globals.inc"
params_path = root / "shaders/base/common/params-0-screen-scale.inc"
cache_path = root / "shaders/base/cache-info.inc"

def replace_once(text, old, new, marker, path):
    if marker in text:
        return text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one patch anchor in {path}, found {count}")
    return text.replace(old, new, 1)

contents = {}
for path in (globals_path, params_path, cache_path):
    if not path.is_file():
        raise RuntimeError(f"Required Mega Bezel source file is missing: {path}")
    contents[path] = path.read_text(encoding="utf-8")

contents[globals_path] = replace_once(
    contents[globals_path],
    "\tfloat HSM_NON_INTEGER_SCALE;\n",
    "\tfloat HSM_NON_INTEGER_SCALE;\n\tfloat HSM_PEGASUS_SCREEN_WIDTH_OFFSET;\n",
    "float HSM_PEGASUS_SCREEN_WIDTH_OFFSET;",
    globals_path,
)
contents[params_path] = replace_once(
    contents[params_path],
    "float HSM_NON_INTEGER_SCALE = global.HSM_NON_INTEGER_SCALE / 100;\n",
    "float HSM_NON_INTEGER_SCALE = global.HSM_NON_INTEGER_SCALE / 100;\n"
    "\n"
    "#pragma parameter HSM_PEGASUS_SCREEN_WIDTH_OFFSET \"Pegasus Screen Width Offset (Pixels)\" 0 0 200 1\n"
    "float HSM_PEGASUS_SCREEN_WIDTH_OFFSET = global.HSM_PEGASUS_SCREEN_WIDTH_OFFSET;\n",
    "float HSM_PEGASUS_SCREEN_WIDTH_OFFSET = global.HSM_PEGASUS_SCREEN_WIDTH_OFFSET;",
    params_path,
)
contents[params_path] = replace_once(
    contents[params_path],
    "#pragma parameter HSM_PEGASUS_SCREEN_WIDTH_OFFSET \"Pegasus Screen Width Offset (Pixels)\" 0 0 100 1",
    "#pragma parameter HSM_PEGASUS_SCREEN_WIDTH_OFFSET \"Pegasus Screen Width Offset (Pixels)\" 0 0 200 1",
    "#pragma parameter HSM_PEGASUS_SCREEN_WIDTH_OFFSET \"Pegasus Screen Width Offset (Pixels)\" 0 0 200 1",
    params_path,
)
contents[cache_path] = replace_once(
    contents[cache_path],
    "return vec2(screen_aspect / output_aspect_ratio, 1) * screen_height;",
    "return vec2(screen_aspect / output_aspect_ratio, 1) * screen_height\n"
    "\t\t\t\t+ vec2(HSM_PEGASUS_SCREEN_WIDTH_OFFSET / global.FinalViewportSize.x, 0);",
    "HSM_PEGASUS_SCREEN_WIDTH_OFFSET / global.FinalViewportSize.x",
    cache_path,
)
contents[cache_path] = replace_once(
    contents[cache_path],
    "return vec2(integer_scale_horz, integer_scale_vert);",
    "return vec2(integer_scale_horz + HSM_PEGASUS_SCREEN_WIDTH_OFFSET / global.FinalViewportSize.x, integer_scale_vert);",
    "integer_scale_horz + HSM_PEGASUS_SCREEN_WIDTH_OFFSET",
    cache_path,
)
contents[cache_path] = replace_once(
    contents[cache_path],
    "\tout_screen_scale *= HSM_2ND_SCREEN_SCALE_OFFSET;\n\n\treturn out_screen_scale;",
    "\tout_screen_scale *= HSM_2ND_SCREEN_SCALE_OFFSET;\n"
    "\tout_screen_scale.x += HSM_PEGASUS_SCREEN_WIDTH_OFFSET / global.FinalViewportSize.x;\n\n"
    "\treturn out_screen_scale;",
    "out_screen_scale.x += HSM_PEGASUS_SCREEN_WIDTH_OFFSET",
    cache_path,
)
contents[cache_path] = replace_once(
    contents[cache_path],
    "\t\t\t\t\t+ HSM_NON_INTEGER_SCALE\n",
    "\t\t\t\t\t+ HSM_NON_INTEGER_SCALE\n"
    "\t\t\t\t\t+ HSM_PEGASUS_SCREEN_WIDTH_OFFSET\n",
    "\t\t\t\t\t+ HSM_PEGASUS_SCREEN_WIDTH_OFFSET\n",
    cache_path,
)

for path, text in contents.items():
    path.write_text(text, encoding="utf-8")
PY
    record_manifest "$target/shaders/base/common/globals.inc" "modified" "Added Pegasus horizontal screen-width parameter to Mega Bezel"
    record_manifest "$target/shaders/base/common/params-0-screen-scale.inc" "modified" "Added Pegasus horizontal screen-width parameter to Mega Bezel"
    record_manifest "$target/shaders/base/cache-info.inc" "modified" "Applied Pegasus horizontal screen-width offset to Mega Bezel screen geometry"
}

install_retroarch_controller_profiles() {
    local retro_config="${XDG_CONFIG_HOME:-$HOME/.config}/retroarch"
    local profile_dir="$retro_config/autoconfig"
    local cache_dir="$WORK_ROOT/retroarch-joypad-autoconfig"

    mkdir -p "$profile_dir"
    if ! command -v git >/dev/null 2>&1; then
        printf 'Git is unavailable; RetroArch controller autoconfig profiles were not updated.\n' >&2
        return 0
    fi
    rm -rf "$cache_dir"
    if ! git clone --depth 1 https://github.com/libretro/retroarch-joypad-autoconfig.git "$cache_dir" >/dev/null 2>&1; then
        printf 'Controller profile download failed; existing RetroArch profiles were preserved.\n' >&2
        return 0
    fi
    if [[ -d "$cache_dir/udev" ]]; then
        cp -a "$cache_dir/udev/." "$profile_dir/"
        record_manifest "$profile_dir" "created_or_modified" "Official RetroArch controller autoconfig profiles"
        printf 'Installed RetroArch controller profiles: %s\n' "$profile_dir"
    fi
}

create_duimon_performance_presets() {
     local target="$1"
     local performance_base="$target/zzz_global_params/Base_Shader/PEGASUS_LITE_NO_REFLECT.slangp"
     local reflective_base="$target/zzz_global_params/Base_Shader/PEGASUS_LITE_REFLECT.slangp"
     local arcade_source="FB-Neo/FB-Neo-[STD]-[Guest-Mini][CABINET][NO TILT].slangp"
     local -a source_presets=(
         "$arcade_source"
         "Atari_2600/2600-[STD]-[Guest-Mini]-[Bezel].slangp"
         "Nintendo_3DS/3DS-[STD]-[Guest-Mini].slangp"
         "Nintendo_Game_Boy/Gameboy-[STD]-[Guest-Mini]-[Bezel].slangp"
         "Nintendo_GBA/GBA-[STD]-[Guest-Mini]-[Bezel].slangp"
         "Nintendo_N64/N64-[STD]-[Guest-Mini]-[Bezel].slangp"
         "Nintendo_NDS/NDS-[STD]-[Guest-Mini].slangp"
         "Nintendo_Gamecube/Gamecube-[STD]-[Guest-Mini]-[Bezel].slangp"
         "Nintendo_NES/NES-[STD]-[Guest-Mini]-[Bezel].slangp"
         "Nintendo_SNES/SNES-[STD]-[Guest-Mini]-[Bezel].slangp"
         "NEC_PC_Engine/PC_Engine-[STD]-[Guest-Mini]-[Bezel].slangp"
         "NEC_SuperGrafx/SuperGrafx_Alt-[STD]-[Guest-Mini]-[Bezel].slangp"
         "SEGA_CD/SEGACD_Alt-[STD]-[Guest-Mini]-[Bezel].slangp"
         "SEGA_32X/SEGA32X_Alt-[STD]-[Guest-Mini]-[Bezel].slangp"
         "SEGA_Genesis/Genesis-[STD]-[Guest-Mini]-[Bezel].slangp"
         "SEGA_Master_System/SMS_Alt-[STD]-[Guest-Mini]-[Bezel].slangp"
         "SEGA_Dreamcast/Dreamcast_Alt-[STD]-[Guest-Mini]-[Bezel].slangp"
         "SONY_Playstation/Playstation_Alt-[STD]-[Guest-Mini]-[Bezel].slangp"
         "SONY_Playstation_2/Playstation2-[STD]-[Guest-Mini]-[Bezel].slangp"
         "SONY_PSP/PSP-[STD]-[Guest-Mini].slangp"
     )
     local source_relative source destination extra preset_base width_offset generated=0

     cat > "$performance_base" <<'EOF'
# Pegasus profile: no-reflection GDV-MINI base for optional low-load use.
#reference "../../../../shaders_slang/bezel/Mega_Bezel/Presets/Base_CRT_Presets/MBZ__4__STD-NO-REFLECT__GDV-MINI.slangp"
EOF
     record_manifest "$performance_base" "created_or_modified" "Duimon Lite performance base using GDV-MINI without reflection passes"

     cat > "$reflective_base" <<'EOF'
# Pegasus profile: half-resolution GDV-MINI bezel reflections with glow effects disabled by preset overrides.
#reference "../../../../shaders_slang/bezel/Mega_Bezel/Presets/Base_CRT_Presets/MBZ__3__STD__GDV-MINI.slangp"
scale_x19 = 400
scale_y19 = 300
scale_x22 = 64
scale_y22 = 64
scale_x23 = 8
scale_y23 = 8
EOF
     record_manifest "$reflective_base" "created_or_modified" "Duimon half-resolution GDV-MINI reflective base without screen glow"

     for source_relative in "${source_presets[@]}"; do
         source="$target/Presets/Lite/$source_relative"
         if [[ ! -f "$source" ]]; then
             printf 'Duimon source preset unavailable; skipping layout generation: %s\n' "$source" >&2
             continue
         fi
         destination="${source%.slangp}-Pegasus-Reflections.slangp"
         rm -f "${source%.slangp}-Pegasus-Scanlines.slangp"
         cp -f "$source" "$destination"
         preset_base="PEGASUS_LITE_REFLECT"
         sed -i \
             -e "s|../../../zzz_global_params/Base_Shader/LITE_Bezel.slangp|../../../zzz_global_params/Base_Shader/$preset_base.slangp|" \
             -e "s|../../../zzz_global_params/Base_Shader/LITE.slangp|../../../zzz_global_params/Base_Shader/$preset_base.slangp|" \
             "$destination"
         if ! grep -q "^#reference .*${preset_base}.slangp" "$destination"; then
             printf 'Duimon preset base did not match the Pegasus performance profile; not selecting it: %s\n' "$source" >&2
             continue
         fi
         extra=''
         width_offset="120.000000"
         if [[ "$source_relative" == "$arcade_source" ]]; then
             width_offset="0.000000"
             extra=$'HSM_BG_SCALE = "126.199600"\nHSM_SCREEN_POSITION_Y = "-26.000000"\nHSM_ASPECT_RATIO_MODE = "1.000000"\nHSM_ASPECT_RATIO_EXPLICIT = "1.431961"'
         fi
         cat >> "$destination" <<EOF

# Pegasus layout and scanline overrides
# Preserve core/system aspect detection with the requested horizontal expansion.
HSM_SCANLINE_DIRECTION = "1.000000"
HSM_CURVATURE_MODE = "1.000000"
HSM_CRT_CURVATURE_SCALE = "100.000000"
HSM_SCREEN_VIGNETTE_ON = "0.000000"
shadowMask = "-1.000000"
scanline = "8.000000"
HSM_PEGASUS_SCREEN_WIDTH_OFFSET = "$width_offset"
HSM_NON_INTEGER_SCALE = "86.000000"
PR = "0.000000"
PG = "0.000000"
PB = "0.000000"
AS = "0.000000"
HSM_REFLECT_FULLSCREEN_GLOW = "0.000000"
HSM_REFLECT_BEZEL_INNER_EDGE_FULLSCREEN_GLOW = "0.000000"
HSM_REFLECT_CORNER_FADE = "0.000000"
$extra
EOF
         record_manifest "$destination" "created_or_modified" "Duimon preset with bezel reflections and simple horizontal scanlines without glow"
         generated=$((generated + 1))
     done
     printf 'Generated Duimon performance layouts: %s\n' "$generated"
}

install_duimon_megabezel_defaults() {
    local retro_config="${XDG_CONFIG_HOME:-$HOME/.config}/retroarch"
    local packs_root="$retro_config/shaders/Mega_Bezel_Packs"
    local target="$packs_root/Duimon-Mega-Bezel"
    local cache_dir="$WORK_ROOT/Duimon-Mega-Bezel"
    local arcade_presets="$target/Presets/Lite/FB-Neo/FB-Neo-[STD]-[Guest-Mini][CABINET][NO TILT].slangp"
    local genesis_presets="$target/Presets/Lite/SEGA_Genesis/Genesis-[STD]-[Guest-Mini]-[Bezel].slangp"
    local nes_presets="$target/Presets/Lite/Nintendo_NES/NES-[STD]-[Guest-Mini]-[Bezel].slangp"
    local snes_presets="$target/Presets/Lite/Nintendo_SNES/SNES-[STD]-[Guest-Mini]-[Bezel].slangp"

    mkdir -p "$packs_root"
    if [[ -f "$arcade_presets" && -f "$genesis_presets" && -f "$nes_presets" && -f "$snes_presets" ]]; then
        create_duimon_performance_presets "$target"
        record_manifest "$target" "created_or_modified" "Duimon Mega Bezel performance layouts for FBNeo and planned consoles"
        printf 'Verified Duimon Lite presets and performance layouts for configured systems.\n'
        return 0
    fi

    rm -rf "$cache_dir"
    if ! git clone --depth 1 https://github.com/Duimon/Duimon-Mega-Bezel.git "$cache_dir" >/dev/null 2>&1; then
        printf 'Duimon Mega Bezel download failed; fallback Mega Bezel preset will remain available.\n' >&2
        return 0
    fi
    if [[ ! -f "$cache_dir/Presets/Lite/FB-Neo/FB-Neo-[STD]-[Guest-Mini][CABINET][NO TILT].slangp" || ! -f "$cache_dir/Presets/Lite/SEGA_Genesis/Genesis-[STD]-[Guest-Mini]-[Bezel].slangp" || ! -f "$cache_dir/Presets/Lite/Nintendo_NES/NES-[STD]-[Guest-Mini]-[Bezel].slangp" || ! -f "$cache_dir/Presets/Lite/Nintendo_SNES/SNES-[STD]-[Guest-Mini]-[Bezel].slangp" ]]; then
        printf 'Duimon package layout was not recognized; fallback Mega Bezel preset will remain available.\n' >&2
        return 0
    fi

    rm -rf "$target"
    cp -a "$cache_dir" "$target"
    create_duimon_performance_presets "$target"
    record_manifest "$target" "created_or_modified" "Official Duimon Mega Bezel Lite graphics and presets"
    printf 'Installed Duimon Mega Bezel presets under: %s\n' "$target"
}

install_slang_shader_pack() {
    local retro_config="${XDG_CONFIG_HOME:-$HOME/.config}/retroarch"
    local slang_root="$retro_config/shaders/shaders_slang"
    local compat_file="$slang_root/include/compat_macros.inc"
    local blur_file="$slang_root/blurs/shaders/royale/blur9x9.slang"
    local cache_dir="$WORK_ROOT/slang-shaders"

    if [[ -f "$compat_file" && -f "$blur_file" ]]; then
        record_manifest "$slang_root" "created_or_modified" "RetroArch slang shader pack"
        return 0
    fi

    rm -rf "$cache_dir"
    if ! git clone --depth 1 https://github.com/libretro/slang-shaders.git "$cache_dir" >/dev/null 2>&1; then
        printf 'slang-shaders include download failed; Mega Bezel shader compilation may fail.\n' >&2
        return 0
    fi
    if [[ ! -f "$cache_dir/include/compat_macros.inc" || ! -f "$cache_dir/blurs/shaders/royale/blur9x9.slang" ]]; then
        printf 'slang-shaders package layout not recognized; Mega Bezel shader compilation may fail.\n' >&2
        return 0
    fi

    mkdir -p "$slang_root"
    cp -a "$cache_dir/." "$slang_root/"
    rm -rf "$slang_root/.git"
    record_manifest "$slang_root" "created_or_modified" "RetroArch slang shader pack"
    printf 'Installed RetroArch slang shader pack under: %s\n' "$slang_root"
}

install_megabezel_defaults() {
    local retro_config="${XDG_CONFIG_HOME:-$HOME/.config}/retroarch"
    local shader_root="$retro_config/shaders/shaders_slang/bezel"
    local target="$shader_root/Mega_Bezel"
    local config_file="$retro_config/retroarch.cfg"
    local append_config="$retro_config/pegasus-megabezel.cfg"
    local preset="$target/Presets/Base_CRT_Presets/Root_Presets/MBZ__5__POTATO__GDV-MINI.slangp"
    local release_url="https://github.com/HyperspaceMadness/Mega_Bezel/releases/download/Mega_Bezel_V1.17.1_2024-04-14/Mega_Bezel_V1.17.1_2024-04-14.zip"
    local zip_file="$WORK_ROOT/Mega_Bezel_V1.17.1_2024-04-14.zip"
    local extract_dir="$WORK_ROOT/mega-bezel-v1.17.1"

    mkdir -p "$shader_root" "$extract_dir"
    install_slang_shader_pack
    install_duimon_megabezel_defaults
    if [[ -f "$target/shaders/base/cache-info.inc" ]]; then
        install_pegasus_screen_width_offset "$target"
    fi
    if [[ -f "$preset" ]]; then
        python3 - "$config_file" "$preset" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
preset = sys.argv[2]
lines = path.read_text(encoding="utf-8", errors="replace").splitlines() if path.exists() else []
values = {
    "video_driver": "vulkan",
    "video_shader_enable": "true",
    "video_shader": preset,
    "input_overlay_enable": "false",
    "video_fullscreen": "true",
    "video_fullscreen_x": "1280",
    "video_fullscreen_y": "720",
    "video_smooth": "false",
    "video_windowed_fullscreen": "false",
    "video_refresh_rate": "60.000000",
    "aspect_ratio_index": "1",
    "video_aspect_ratio_auto": "false",
    "video_force_aspect": "true",
}
for key, value in values.items():
    found = False
    updated = []
    for line in lines:
        if line.strip().startswith(key + " ") or line.strip().startswith(key + "="):
            if not found:
                updated.append(f'{key} = "{value}"')
                found = True
        else:
            updated.append(line)
    if not found:
        updated.append(f'{key} = "{value}"')
    lines = updated
path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY
        python3 - "$append_config" "$preset" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
preset = sys.argv[2]
lines = path.read_text(encoding="utf-8", errors="replace").splitlines() if path.exists() else []
values = {
    "video_driver": "vulkan",
    "video_shader_enable": "false",
    "video_shader": preset,
    "input_overlay_enable": "false",
    "video_fullscreen": "true",
    "video_fullscreen_x": "1280",
    "video_fullscreen_y": "720",
    "video_smooth": "false",
    "video_windowed_fullscreen": "false",
    "video_refresh_rate": "60.000000",
    "aspect_ratio_index": "1",
    "video_aspect_ratio_auto": "false",
    "video_force_aspect": "true",
}
for key, value in values.items():
    found = False
    updated = []
    for line in lines:
        if line.strip().startswith(key + " ") or line.strip().startswith(key + "="):
            if not found:
                updated.append(f'{key} = "{value}"')
                found = True
        else:
            updated.append(line)
    if not found:
        updated.append(f'{key} = "{value}"')
    lines = updated
path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY
        install_pegasus_scanline_preset "$preset"
        record_manifest "$config_file" "created_or_modified" "Ensured Vulkan and Mega Bezel are enabled by default"
        record_manifest "$append_config" "created_or_modified" "Pegasus RetroArch append-config deferring shader loading to the per-core launcher"
        printf 'Verified Mega Bezel preset: %s\n' "$preset"
        return 0
    fi

    if ! curl -fsSL "$release_url" -o "$zip_file"; then
        printf 'Mega Bezel download failed; existing shader configuration will be preserved.\n' >&2
        return 0
    fi
    rm -rf "$extract_dir/package"
    mkdir -p "$extract_dir/package"
    if ! unzip -q "$zip_file" -d "$extract_dir/package"; then
        printf 'Mega Bezel archive could not be extracted; existing shader configuration will be preserved.\n' >&2
        return 0
    fi
    local source_dir
    source_dir=$(find "$extract_dir/package" -type d -name Mega_Bezel -print -quit)
    if [[ -z "$source_dir" || ! -f "$source_dir/Presets/Base_CRT_Presets/Root_Presets/MBZ__5__POTATO__GDV-MINI.slangp" ]]; then
        printf 'Mega Bezel package layout was not recognized; existing configuration was preserved.\n' >&2
        return 0
    fi

    rm -rf -- "$target"
    cp -a -- "$source_dir" "$target"
    preset="$target/Presets/Base_CRT_Presets/Root_Presets/MBZ__5__POTATO__GDV-MINI.slangp"
    record_manifest "$target" "created_or_modified" "Official Mega Bezel V1.17.1 Slang shader package"
    install_pegasus_screen_width_offset "$target"
    install_pegasus_scanline_preset "$preset"

    python3 - "$config_file" "$preset" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
preset = sys.argv[2]
lines = path.read_text(encoding="utf-8", errors="replace").splitlines() if path.exists() else []
values = {
    "video_driver": "vulkan",
    "video_shader_enable": "true",
    "video_shader": preset,
    "input_overlay_enable": "false",
    "video_fullscreen": "true",
    "video_fullscreen_x": "1280",
    "video_fullscreen_y": "720",
    "video_windowed_fullscreen": "false",
    "video_refresh_rate": "60.000000",
    "aspect_ratio_index": "1",
    "video_aspect_ratio_auto": "false",
    "video_force_aspect": "true",
}
for key, value in values.items():
    found = False
    updated = []
    for line in lines:
        if line.strip().startswith(key + " ") or line.strip().startswith(key + "="):
            if not found:
                updated.append(f'{key} = "{value}"')
                found = True
        else:
            updated.append(line)
    if not found:
        updated.append(f'{key} = "{value}"')
    lines = updated
path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY
    python3 - "$append_config" "$preset" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
preset = sys.argv[2]
lines = path.read_text(encoding="utf-8", errors="replace").splitlines() if path.exists() else []
values = {
    "video_driver": "vulkan",
    "video_shader_enable": "false",
    "video_shader": preset,
    "input_overlay_enable": "false",
    "video_fullscreen": "true",
    "video_fullscreen_x": "1280",
    "video_fullscreen_y": "720",
    "video_windowed_fullscreen": "false",
    "video_refresh_rate": "60.000000",
    "aspect_ratio_index": "1",
    "video_aspect_ratio_auto": "false",
    "video_force_aspect": "true",
}
for key, value in values.items():
    found = False
    updated = []
    for line in lines:
        if line.strip().startswith(key + " ") or line.strip().startswith(key + "="):
            if not found:
                updated.append(f'{key} = "{value}"')
                found = True
        else:
            updated.append(line)
    if not found:
        updated.append(f'{key} = "{value}"')
    lines = updated
path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY
    record_manifest "$append_config" "created_or_modified" "Pegasus RetroArch append-config enforcing shader and exclusive fullscreen"
    record_manifest "$config_file" "created_or_modified" "Enabled Vulkan, Mega Bezel, and disabled conflicting input overlays by default"
    printf 'Installed Mega Bezel preset: %s\n' "$preset"
}

configure_retroarch_paths() {
    local retro_config="${XDG_CONFIG_HOME:-$HOME/.config}/retroarch"
    local config_file="$retro_config/retroarch.cfg"
    local core_info_dir="$retro_config/info"
    local bios_dir="$INSTALL_DIR/bios"
    local saves_dir="$INSTALL_DIR/saves"
    local timestamp backup_file

    mkdir -p "$INSTALL_DIR/roms" "$bios_dir" "$saves_dir" "$retro_config" "$core_info_dir"
    if [[ -d /usr/share/libretro/info ]]; then
        cp -an /usr/share/libretro/info/. "$core_info_dir/"
        record_manifest "$core_info_dir" "created_or_modified" "User-writable RetroArch core info metadata"
    fi
    install_retroarch_controller_profiles
    record_manifest "$INSTALL_DIR/roms" "created" "Empty Pegasus ROM directory for later user game files"
    record_manifest "$bios_dir" "created" "Empty BIOS/firmware directory for later user files"
    record_manifest "$saves_dir" "created" "RetroArch save and state directory"

    if [[ -e "$config_file" ]]; then
        timestamp="$(date +%Y%m%d-%H%M%S)"
        backup_file="$STATE_ROOT/backups/retroarch.cfg.$timestamp"
        cp -a -- "$config_file" "$backup_file"
        record_manifest "$backup_file" "backed_up" "Prior RetroArch configuration preserved"
    fi

    python3 - "$config_file" "$bios_dir" "$saves_dir" "$retro_config" "$core_info_dir" <<'PY'
import sys
from pathlib import Path

path, bios_dir, saves_dir, retro_config, core_info_dir = sys.argv[1:]
config = Path(path)
lines = config.read_text(encoding="utf-8", errors="replace").splitlines() if config.exists() else []
values = {
    "rgui_show_start_screen": "false",
    "menu_driver": "xmb",
    "menu_pause_libretro": "true",
    "input_driver": "udev",
    "input_joypad_driver": "udev",
    "input_menu_toggle": "f1",
    "input_desktop_menu_toggle": "f5",
    "input_enable_hotkey_btn": "9",
    "input_menu_toggle_btn": "10",
    "input_menu_toggle_gamepad_combo": "0",
    "video_fullscreen": "true",
    "video_fullscreen_x": "1280",
    "video_fullscreen_y": "720",
    "video_windowed_fullscreen": "false",
    "video_force_aspect": "true",
    "video_refresh_rate": "60.000000",
    "aspect_ratio_index": "1",
    "video_aspect_ratio_auto": "false",
    "video_vsync": "true",
    "fps_show": "false",
    "framecount_show": "false",
    "content_runtime_log": "false",
    "log_to_file": "false",
    "log_verbosity": "false",
    "audio_sync": "true",
    "system_directory": bios_dir,
    "savefile_directory": saves_dir,
    "savestate_directory": saves_dir,
    "libretro_directory": str(Path(retro_config) / "cores"),
    "core_options_path": str(Path(retro_config) / "core-options.cfg"),
    "libretro_info_path": core_info_dir,
    "core_updater_buildbot_cores_url": "https://buildbot.libretro.com/nightly/linux/aarch64/latest/",
    "core_updater_buildbot_assets_url": "https://buildbot.libretro.com/assets/",
    "menu_show_core_updater": "true",
    "libretro_info_path": core_info_dir,
    "core_updater_buildbot_cores_url": "https://buildbot.libretro.com/nightly/linux/aarch64/latest/",
    "core_updater_buildbot_assets_url": "https://buildbot.libretro.com/assets/",
    "menu_show_core_updater": "true",
}
for key, value in values.items():
    escaped = value.replace("\\", "\\\\")
    found = False
    updated = []
    for line in lines:
        if line.strip().startswith(key + " ") or line.strip().startswith(key + "="):
            if not found:
                updated.append(f'{key} = "{escaped}"')
                found = True
        else:
            updated.append(line)
    if not found:
        updated.append(f'{key} = "{escaped}"')
    lines = updated
config.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY
    record_manifest "$config_file" "created_or_modified" "Native RetroArch BIOS, save, and startup paths for Pegasus layout"
    install_megabezel_defaults
}

install_fbneo() {
    local core_dir="${XDG_CONFIG_HOME:-$HOME/.config}/retroarch/cores"
    local core_file="$core_dir/fbneo_libretro.so"
    local cache_dir="$WORK_ROOT/fbneo"
    local zip_file="$cache_dir/fbneo_libretro.so.zip"
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/retroarch/retroarch.cfg"
    local timestamp backup_file hash

    printf '\nOfficial ARM64 FBNeo core plan\n'
    printf '  Source: %s\n' "$FBNEO_CORE_URL"
    printf '  Core directory: %s\n' "$core_dir"
    printf '  Existing core, if present, will be backed up before replacement.\n'
    if (( DRY_RUN )); then
        printf 'Dry run: no files, directories, downloads, or configuration will be changed.\n'
        return 0
    fi
    if ! confirm_install; then
        printf 'Installation not started.\n'
        return 0
    fi

    start_logging
    mkdir -p "$cache_dir" "$core_dir" "$(dirname "$config_file")"
    curl -fL --retry 3 -o "$zip_file" "$FBNEO_CORE_URL"
    unzip -o "$zip_file" -d "$cache_dir" >/dev/null

    if [[ ! -f "$cache_dir/fbneo_libretro.so" ]]; then
        printf 'Downloaded archive did not contain fbneo_libretro.so.\n' >&2
        return 1
    fi
    if ! file "$cache_dir/fbneo_libretro.so" | grep -q 'ARM aarch64'; then
        printf 'Downloaded FBNeo core is not native ARM64.\n' >&2
        return 1
    fi

    if [[ -e "$core_file" ]]; then
        timestamp="$(date +%Y%m%d-%H%M%S)"
        backup_file="$STATE_ROOT/backups/fbneo_libretro.so.$timestamp"
        cp -a -- "$core_file" "$backup_file"
        record_manifest "$backup_file" "backed_up" "Prior FBNeo core preserved before replacement"
    fi
    cp -f -- "$cache_dir/fbneo_libretro.so" "$core_file"
    hash="$(sha256sum "$core_file" | awk '{print $1}')"
    record_manifest "$core_file" "created_or_modified" "Official ARM64 FBNeo libretro nightly; SHA256 $hash"

    touch "$config_file"
    timestamp="$(date +%Y%m%d-%H%M%S)"
    if grep -q '^libretro_directory' "$config_file"; then
        backup_file="$STATE_ROOT/backups/retroarch.cfg.fbneo.$timestamp"
        cp -a -- "$config_file" "$backup_file"
        record_manifest "$backup_file" "backed_up" "RetroArch config preserved before FBNeo directory setting"
        sed -i "s|^libretro_directory = .*|libretro_directory = \"$core_dir\"|" "$config_file"
    else
        printf 'libretro_directory = "%s"\n' "$core_dir" >> "$config_file"
    fi
    record_manifest "$config_file" "modified" "Added user FBNeo core directory"

    printf '\nFBNeo installation completed.\n'
    printf 'Core: %s\n' "$core_file"
    printf 'Architecture: ARM64/aarch64\nSHA256: %s\n' "$hash"
    printf 'Log: %s\nManifest: %s\n' "$LOG_FILE" "$MANIFEST_FILE"
}

install_snes9x() {
    local core_dir="${XDG_CONFIG_HOME:-$HOME/.config}/retroarch/cores"
    local core_file="$core_dir/snes9x_libretro.so"
    local cache_dir="$WORK_ROOT/snes9x"
    local zip_file="$cache_dir/snes9x_libretro.so.zip"
    local timestamp backup_file hash

    printf '\nOfficial ARM64 Snes9x core plan\n'
    printf '  Source: %s\n' "$SNES9X_CORE_URL"
    printf '  Core directory: %s\n' "$core_dir"
    printf '  Existing core, if present, will be backed up before replacement.\n'
    if (( DRY_RUN )); then
        printf 'Dry run: no files, directories, downloads, or configuration will be changed.\n'
        return 0
    fi
    if ! confirm_install; then
        printf 'Installation not started.\n'
        return 0
    fi

    start_logging
    mkdir -p "$cache_dir" "$core_dir"
    curl -fL --retry 3 -o "$zip_file" "$SNES9X_CORE_URL"
    unzip -o "$zip_file" -d "$cache_dir" >/dev/null

    if [[ ! -f "$cache_dir/snes9x_libretro.so" ]]; then
        printf 'Downloaded archive did not contain snes9x_libretro.so.\n' >&2
        return 1
    fi
    if ! file "$cache_dir/snes9x_libretro.so" | grep -q 'ARM aarch64'; then
        printf 'Downloaded Snes9x core is not native ARM64.\n' >&2
        return 1
    fi

    if [[ -e "$core_file" ]]; then
        timestamp="$(date +%Y%m%d-%H%M%S)"
        backup_file="$STATE_ROOT/backups/snes9x_libretro.so.$timestamp"
        mkdir -p "$(dirname "$backup_file")"
        cp -a -- "$core_file" "$backup_file"
        record_manifest "$backup_file" "backed_up" "Prior Snes9x core preserved before replacement"
    fi
    cp -f -- "$cache_dir/snes9x_libretro.so" "$core_file"
    hash="$(sha256sum "$core_file" | awk '{print $1}')"
    record_manifest "$core_file" "created_or_modified" "Official ARM64 Snes9x libretro nightly; SHA256 $hash"

    printf '\nSnes9x installation completed.\n'
    printf 'Core: %s\n' "$core_file"
    printf 'Architecture: ARM64/aarch64\nSHA256: %s\n' "$hash"
    printf 'Log: %s\nManifest: %s\n' "$LOG_FILE" "$MANIFEST_FILE"
}

install_retroarch() {
    local packages=()
    local package

    if (( BLOCKERS > 0 )); then
        printf 'Preflight has %s blocker(s); refusing to install.\n' "$BLOCKERS" >&2
        return 1
    fi
    while IFS= read -r package; do
        [[ -n "$package" ]] && packages+=("$package")
    done < <(available_retroarch_packages)
    if ((${#packages[@]} == 0)) || ! package_available retroarch; then
        printf 'RetroArch is unavailable in the configured Ubuntu package sources.\n' >&2
        return 1
    fi

    printf '\nRetroArch native package plan\n'
    printf '  Packages: %s\n' "${packages[*]}"
    printf '  ROM directory: %s/roms\n' "$INSTALL_DIR"
    printf '  BIOS directory: %s/bios\n' "$INSTALL_DIR"
    printf '  Save directory: %s/saves\n' "$INSTALL_DIR"
    printf '  Existing RetroArch config will be backed up before updating if present.\n'
    if ! confirm_install; then
        printf 'Installation not started.\n'
        return 0
    fi

    start_logging
    install_packages "${packages[@]}"
    configure_retroarch_paths
    local previous_assume_yes="$ASSUME_YES"
    ASSUME_YES=1
    install_fbneo
    install_snes9x
    ASSUME_YES="$previous_assume_yes"
    configure_library_launchers "$INSTALL_DIR/roms"
    install_pegasus_desktop_icon || true

    if ! command -v retroarch >/dev/null 2>&1; then
        printf 'RetroArch installation completed without a retroarch executable.\n' >&2
        return 1
    fi
    printf '\nRetroArch native installation completed.\n'
    printf 'Executable: %s\n' "$(command -v retroarch)"
    printf 'Available cores:\n'
    { for core_dir in /usr/lib/aarch64-linux-gnu/libretro /usr/lib/libretro; do
        if [[ -d "$core_dir" ]]; then
            find "$core_dir" -maxdepth 1 -type f -name '*.so' -print
        fi
    done; } | sort | sed 's/^/  /'
    printf 'ROM directory: %s/roms\nBIOS directory: %s/bios\nSave directory: %s/saves\n' "$INSTALL_DIR" "$INSTALL_DIR" "$INSTALL_DIR"
    printf 'Log: %s\nManifest: %s\n' "$LOG_FILE" "$MANIFEST_FILE"
}

install_frontend() {
    local source_dir="$WORK_ROOT/source-$SOURCE_TAG"
    local build_dir="$WORK_ROOT/cmake-build-$SOURCE_TAG"
    local desktop_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
    local desktop_file="$desktop_dir/org.pegasus_frontend.Pegasus.desktop"
    local timestamp backup_file existing_entry
    local available_jobs
    local filepath package
    local install_dir_preexisting=0

    if (( BLOCKERS > 0 )); then
        printf 'Preflight has %s blocker(s); refusing to install.\n' "$BLOCKERS" >&2
        return 1
    fi

    if (( EXISTING_PEGASUS )) || [[ -e "$INSTALL_DIR/pegasus-fe" ]]; then
        if (( WITH_RETROARCH )) && [[ -x "$INSTALL_DIR/pegasus-fe" ]]; then
            print_plan
            if ! confirm_install; then
                printf 'Installation not started.\n'
                return 0
            fi
            start_logging
            local retro_packages=()
            while IFS= read -r package; do
                [[ -n "$package" ]] && retro_packages+=("$package")
            done < <(available_retroarch_packages)
            install_packages "${retro_packages[@]}"
            configure_retroarch_paths
            local previous_assume_yes="$ASSUME_YES"
            ASSUME_YES=1
            install_fbneo
            install_snes9x
            ASSUME_YES="$previous_assume_yes"
            configure_library_launchers "$INSTALL_DIR/roms"
            install_pegasus_desktop_icon || true
            printf '\nExisting Pegasus installation preserved; RetroArch installed/configured.\n'
            printf 'ROM directory: %s/roms\nBIOS directory: %s/bios\nSave directory: %s/saves\n' "$INSTALL_DIR" "$INSTALL_DIR" "$INSTALL_DIR"
            printf 'Log: %s\nManifest: %s\n' "$LOG_FILE" "$MANIFEST_FILE"
            return 0
        fi
        printf 'An existing Pegasus command was detected; refusing to create a duplicate installation.\n' >&2
        return 1
    fi
    if [[ -L "$INSTALL_DIR" ]]; then
        printf 'Install directory is a symbolic link; refusing to follow it: %s\n' "$INSTALL_DIR" >&2
        return 1
    elif [[ -e "$INSTALL_DIR" ]]; then
        if [[ -d "$INSTALL_DIR" ]] && ! find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
            install_dir_preexisting=1
        else
            printf 'Install directory already exists and is not empty; refusing to overwrite unknown files: %s\n' "$INSTALL_DIR" >&2
            return 1
        fi
    fi

    if [[ -e "$source_dir" ]]; then
        if [[ ! -d "$source_dir/.git" ]] || [[ "$(git -C "$source_dir" rev-parse HEAD 2>/dev/null || true)" != "$SOURCE_COMMIT" ]]; then
            printf 'Existing source directory does not match the pinned commit; refusing to overwrite: %s\n' "$source_dir" >&2
            return 1
        fi
    fi
    if [[ -e "$build_dir" && ! -f "$build_dir/.pegasus-installer-build" ]]; then
        printf 'Existing build directory is not marked as installer-owned; refusing to use it: %s\n' "$build_dir" >&2
        return 1
    fi
    if (( JOBS > 1 )) && command -v nproc >/dev/null 2>&1; then
        available_jobs="$(nproc)"
        if (( JOBS > available_jobs )); then
            printf 'Requested %s jobs but only %s CPUs are available.\n' "$JOBS" "$available_jobs" >&2
            return 1
        fi
    fi

    print_plan
    if ! confirm_install; then
        printf 'Installation not started.\n'
        return 0
    fi

    start_logging
    install_packages "${BUILD_PACKAGES[@]}"
    if (( WITH_RETROARCH )); then
        local retro_packages=()
        while IFS= read -r package; do
            [[ -n "$package" ]] && retro_packages+=("$package")
        done < <(available_retroarch_packages)
        if ((${#retro_packages[@]} == 0)); then
            printf 'RetroArch is unavailable in the configured Ubuntu package sources.\n' >&2
            return 1
        fi
        install_packages "${retro_packages[@]}"
    fi

    mkdir -p "$WORK_ROOT"
    if [[ ! -d "$source_dir" ]]; then
        git clone --depth 1 --branch "$SOURCE_TAG" "$SOURCE_URL" "$source_dir"
        record_manifest "$source_dir" "created" "Pinned Pegasus source checkout"
    fi
    local checked_commit
    checked_commit="$(git -C "$source_dir" rev-parse HEAD)"
    if [[ "$checked_commit" != "$SOURCE_COMMIT" ]]; then
        printf 'Pinned source verification failed: expected %s, got %s\n' "$SOURCE_COMMIT" "$checked_commit" >&2
        return 1
    fi
    git -C "$source_dir" submodule sync --recursive
    git -C "$source_dir" submodule update --init --recursive
    record_manifest "$source_dir" "modified" "Initialized submodules at the exact commits pinned by the source tag"

    mkdir -p "$build_dir" "$INSTALL_DIR"
    if [[ ! -f "$build_dir/.pegasus-installer-build" ]]; then
        printf '%s\n' "$SOURCE_COMMIT" > "$build_dir/.pegasus-installer-build"
        record_manifest "$build_dir/.pegasus-installer-build" "created" "Marks installer-owned build directory"
    fi
    if (( install_dir_preexisting )); then
        record_manifest "$INSTALL_DIR" "modified" "Pegasus installed into the pre-existing empty user directory"
    else
        record_manifest "$INSTALL_DIR" "created" "User-local Pegasus installation directory"
    fi

    cmake -S "$source_dir" -B "$build_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
        -DPEGASUS_INSTALL_BINDIR="$INSTALL_DIR" \
        -DPEGASUS_INSTALL_DESKTOPDIR="$desktop_dir" \
        -DPEGASUS_ON_X11=ON \
        -DPEGASUS_USE_SDL2_GAMEPAD=ON \
        -DPEGASUS_ENABLE_LTO=OFF
    cmake --build "$build_dir" --parallel "$JOBS"

    mkdir -p "$desktop_dir"
    if [[ -L "$desktop_file" ]]; then
        printf 'Refusing to overwrite a symbolic-link desktop entry: %s\n' "$desktop_file" >&2
        return 1
    fi
    existing_entry=0
    if [[ -e "$desktop_file" ]]; then
        timestamp="$(date +%Y%m%d-%H%M%S)"
        backup_file="$STATE_ROOT/backups/org.pegasus_frontend.Pegasus.desktop.$timestamp"
        cp -a -- "$desktop_file" "$backup_file"
        record_manifest "$backup_file" "backed_up" "Prior desktop launcher preserved before update"
        existing_entry=1
    fi
    cmake --install "$build_dir"

    if [[ ! -x "$INSTALL_DIR/pegasus-fe" ]]; then
        printf 'Build/install completed without the expected executable: %s\n' "$INSTALL_DIR/pegasus-fe" >&2
        return 1
    fi
    record_manifest "$INSTALL_DIR/pegasus-fe" "created" "Pegasus built from the pinned native source"
    while IFS= read -r -d '' filepath; do
        [[ "$filepath" == "$INSTALL_DIR/pegasus-fe" ]] && continue
        record_manifest "$filepath" "created" "Pegasus CMake install output"
    done < <(find "$INSTALL_DIR" -type f -print0)
    if (( existing_entry )); then
        record_manifest "$desktop_file" "modified" "Upstream per-user launcher installed after backing up prior file"
    else
        record_manifest "$desktop_file" "created" "Upstream per-user X11 launcher"
    fi
    if [[ ! -f "$desktop_file" ]]; then
        printf 'Expected X11 desktop entry was not installed: %s\n' "$desktop_file" >&2
        return 1
    fi
    install_pegasus_desktop_icon || true

    if (( WITH_RETROARCH )); then
        configure_retroarch_paths
        local previous_assume_yes="$ASSUME_YES"
        ASSUME_YES=1
        install_fbneo
        ASSUME_YES="$previous_assume_yes"
        configure_library_launchers "$INSTALL_DIR/roms"
        printf '\nNative RetroArch and FBNeo installed/configured.\n'
        printf 'ROM directory: %s/roms\nBIOS directory: %s/bios\nSave directory: %s/saves\n' "$INSTALL_DIR" "$INSTALL_DIR" "$INSTALL_DIR"
    fi

    printf '\nPegasus frontend install completed.\n'
    printf 'Executable: %s\n' "$INSTALL_DIR/pegasus-fe"
    printf 'Launcher: %s\n' "$desktop_file"
    printf 'Log: %s\nManifest: %s\n' "$LOG_FILE" "$MANIFEST_FILE"
    printf 'Next: launch Pegasus manually from the Ubuntu desktop and verify it exits cleanly before configuring a library.\n'
}

parse_args() {
    while (($#)); do
        case "$1" in
            --help|-h)
                usage
                exit 0
                ;;
            --check-only)
                [[ -z "$OPERATION" ]] || { printf 'Choose only one operation.\n' >&2; exit 2; }
                OPERATION="check"
                ;;
            --install-frontend)
                [[ -z "$OPERATION" ]] || { printf 'Choose only one operation.\n' >&2; exit 2; }
                OPERATION="install"
                ;;
            --configure-library)
                [[ -z "$OPERATION" && $# -ge 2 ]] || { printf 'Use --configure-library PATH as the only operation.\n' >&2; exit 2; }
                OPERATION="configure-library"
                shift
                LIBRARY_ROOT="$1"
                ;;
            --inspect-library)
                [[ -z "$OPERATION" && $# -ge 2 ]] || { printf 'Use --inspect-library PATH as the only operation.\n' >&2; exit 2; }
                OPERATION="inspect-library"
                shift
                LIBRARY_ROOT="$1"
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            --with-retroarch)
                WITH_RETROARCH=1
                ;;
            --install-retroarch)
                [[ -z "$OPERATION" ]] || { printf 'Choose only one operation.\n' >&2; exit 2; }
                OPERATION="install-retroarch"
                ;;
            --install-fbneo)
                [[ -z "$OPERATION" ]] || { printf 'Choose only one operation.\n' >&2; exit 2; }
                OPERATION="install-fbneo"
                ;;
            --install-snes9x)
                [[ -z "$OPERATION" ]] || { printf 'Choose only one operation.\n' >&2; exit 2; }
                OPERATION="install-snes9x"
                ;;
            --yes)
                ASSUME_YES=1
                ;;
            --jobs)
                [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || { printf '--jobs requires a positive integer.\n' >&2; exit 2; }
                JOBS="$2"
                shift
                ;;
            *)
                printf 'Unknown option: %s\n' "$1" >&2
                usage >&2
                exit 2
                ;;
        esac
        shift
    done

    if [[ -z "$OPERATION" ]]; then
        usage
        exit 2
    fi
    if (( ASSUME_YES )) && [[ "$OPERATION" != "install" && "$OPERATION" != "install-retroarch" && "$OPERATION" != "install-fbneo" && "$OPERATION" != "install-snes9x" ]]; then
        printf '--yes is valid only with --install-frontend, --install-retroarch, --install-fbneo, or --install-snes9x.\n' >&2
        exit 2
    fi
    if (( WITH_RETROARCH )) && [[ "$OPERATION" != "install" ]]; then
        printf '--with-retroarch is valid only with --install-frontend.\n' >&2
        exit 2
    fi
    if (( DRY_RUN )) && [[ "$OPERATION" != "install" && "$OPERATION" != "install-retroarch" && "$OPERATION" != "install-fbneo" && "$OPERATION" != "install-snes9x" ]]; then
        printf '--dry-run is valid only with --install-frontend, --install-retroarch, --install-fbneo, or --install-snes9x.\n' >&2
        exit 2
    fi
}

parse_args "$@"

case "$OPERATION" in
    check)
        run_preflight
        if (( BLOCKERS > 0 )); then
            exit 1
        fi
        ;;
    install)
        run_preflight
        install_frontend
        ;;
    install-retroarch)
        run_preflight
        install_retroarch
        ;;
    install-fbneo)
        run_preflight
        install_fbneo
        ;;
    install-snes9x)
        run_preflight
        install_snes9x
        ;;
    configure-library)
        configure_library_launchers "$LIBRARY_ROOT"
        install_pegasus_auto_launcher
        install_pegasus_themes
        install_megabezel_defaults
        ;;
    inspect-library)
        inspect_library "$LIBRARY_ROOT"
        ;;
esac
