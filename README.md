# Pegasus on Orange Pi 5 (Ubuntu ARM64)

This project provides a staged, user-local setup for Pegasus Frontend on Ubuntu ARM64. The prebuilt upstream desktop release currently does not include a generic Orange Pi 5/ARM64 build, and the published Flathub bundle currently targets x86_64. This workflow therefore builds Pegasus from a pinned upstream source release on the device.

It does **not** run RetroBat, Wine, Box64, or x86 emulation. It does not replace Ubuntu, install emulators, alter graphics drivers, add software repositories, or copy/move your ROMs, BIOS, media, or saves.

> **Contributing with an AI agent? Start here:** [`START_HERE_AI_CONTRIBUTORS.md`](START_HERE_AI_CONTRIBUTORS.md).

## Status and scope

Implemented in this workspace:

- Read-only ARM64/Ubuntu/dependency preflight.
- Explicitly confirmed, pinned source build and per-user install.
- Optional native ARM64 RetroArch and Ubuntu libretro-core installation.
- A selected roadmap target of eight systems: Atari 2600, FBNeo, MAME, Mega Drive/Genesis (one system), Mega CD/Sega CD, Nintendo 64, NES, and SNES. This is a scope decision, not a claim that all systems can launch or perform adequately.
- Documented emulation targets; native ARM64 availability, launch behavior, and Orange Pi 5 performance remain to be verified per system.
- Dry-run mode.
- Read-only inspection of a library root supplied by the user.
- Per-user upstream launcher, installation log, manifest, and backup of an existing launcher before replacement.

Verified on the current Orange Pi environment:

- Read-only preflight identifies Ubuntu 22.04.5, ARM64 (`aarch64`), kernel `5.10.0-1012-rockchip`, X11, and Mali-G610/Panfrost.
- The home filesystem reports 39 GB available.
- Qt/SDL build dependencies were installed from the currently configured package sources after explicit authorization.
- The pinned source configured and built successfully using Pegasus' documented CMake path with the X11 desktop target enabled. Installation includes the Qt/QML runtime modules required by the bundled Pegasus Grid theme so the frontend does not stop at a theme-loading error.

Not yet device-verified:

- Exiting Pegasus cleanly through its UI on the Orange Pi; the startup process launched on X11, but a window-manager close request did not close it.
- Testing RetroBat/EmulationStation metadata against the actual library.
- Choosing or installing emulators.

Library setup is intentionally a later stage. The suggested Pegasus-side path is `~/Applications/Pegasus/roms`, but this is a preference, not a copying instruction. If your existing library lives elsewhere, keep it there and supply its real path for inspection; do not move it just to match the suggestion.

## Requirements and references

- Ubuntu 22.04 or later on ARM64 (`aarch64`).
- Network access to GitHub during source checkout.
- Enough free disk space for Qt development dependencies and a native build.
- A graphical Ubuntu desktop to validate Pegasus after building.
- Build prerequisites are installed only after the script shows the package plan and receives confirmation.

Research and source links are in [docs/pegasus-arm64-research.md](docs/pegasus-arm64-research.md). The original safety and acceptance requirements are in [docs/orange_pi_5_pegasus_installation_brief.md](docs/orange_pi_5_pegasus_installation_brief.md).

Feature briefs for future contributions are indexed in [features/README.md](features/README.md). They are drafts pending maintainer review and do not indicate implemented or verified functionality. CI runs syntax checks, ShellCheck, Python security/unused-code checks, Gitleaks on added/modified files, actionlint, and zizmor; these checks are not hardware tests or proof that code is harmless. Required status checks and branch rules must be configured by the repository owner.

## Commands

From the project directory:

```bash
bash scripts/install-pegasus.sh --help
bash scripts/install-pegasus.sh --check-only
bash scripts/install-pegasus.sh --dry-run --install-frontend
bash scripts/install-pegasus.sh --install-frontend
bash scripts/install-pegasus.sh --install-frontend --with-retroarch
bash scripts/install-pegasus.sh --dry-run --install-retroarch
bash scripts/install-pegasus.sh --install-retroarch
bash scripts/install-pegasus.sh --dry-run --install-fbneo
bash scripts/install-pegasus.sh --install-fbneo
bash scripts/install-pegasus.sh --configure-library "$HOME/Applications/Pegasus/roms"
```

`--configure-library PATH` creates native Pegasus launch metadata recursively for `megadrive`, `fbneo`, `nes`, and `snes` directories when the corresponding RetroArch core is installed, excludes BIOS archives, backs up existing metadata and `game_dirs.txt` where applicable, and registers the system directories with Pegasus. Complete RetroArch/frontend routes run this integration automatically. It prefers cached ScreenScraper media when available, then falls back to existing EmulationStation artwork and RetroArch/libretro thumbnails. It writes `assets.boxFront`, `assets.screenshot`, and `assets.background` for each matched game (and `assets.video` when a ScreenScraper video exists) under `roms/.media/`. For FBNeo, it also builds per-game art backgrounds and shader presets from available cover art; the launcher uses that game art on the sides and falls back to the standard arcade cabinet bezel when no art is available. The art/preset files are stored under `~/.config/retroarch/pegasus-gameart/fbneo/` and the Duimon preset directory. Console cores continue to use their console-specific bezels. It does not copy, rename, or move ROM/BIOS files.

The planned emulation lineup is **3DS, Atari 2600, Atomiswave, Dreamcast, FBNeo, Game Boy, Game Boy Advance, Master System, Mega CD/Sega CD, Mega Drive, N64, Nintendo DS, NES, GameCube (NGC), PC Engine, PS2, PSX, PSP, Sega 32X, SNES, and SuperGrafx**. This is a future target list, not a claim that every system is currently installed, configured, or performance-tested. Add systems in stages after checking native ARM64 core availability, required BIOS files, controller behavior, and acceptable Orange Pi 5 performance. `genesis` and `megadrive` refer to the same Sega Mega Drive/Genesis platform; `megacd` and `segacd` refer to the same Sega CD platform. Each pair should share one ROM/core setup rather than creating duplicate system configurations.

The gameOS theme includes settings for Grid/Vertical List layout, startup library refresh, default sort/order, and favorites filtering, in addition to its existing theme/display controls. The Ubuntu desktop launcher uses `~/Applications/Pegasus/run-pegasus.sh`. It refreshes ROM discovery and missing media metadata before each Pegasus start by default; the gameOS **Refresh library on startup** setting can disable that refresh. Refresh errors are logged and do not prevent Pegasus from launching. The wrapper also forces GNOME/X11 to 1280×720, disables fractional X11 scaling (`org.gnome.mutter experimental-features=[]`), sets scale 1.0, and starts Pegasus with reboot/shutdown/suspend menu entries disabled so **Exit Pegasus** is the only close path.

`--install-fbneo` downloads the official RetroArch ARM64 buildbot nightly, verifies the ELF is AArch64, records its SHA-256 hash, backs up any existing core, and installs it in the user RetroArch core directory. `--install-retroarch` dynamically discovers and installs native RetroArch plus every available ARM64/all-architecture libretro core package from the configured Ubuntu repositories, excluding development and GTK frontend helper packages. `--with-retroarch` performs the same emulator setup together with the Pegasus build. A core is available only when Ubuntu provides a compatible package; unprovided third-party cores are reported as unavailable and are never added through an unapproved PPA. Both create empty `roms`, `bios`, and `saves` directories below the Pegasus install path and back up an existing RetroArch configuration before setting BIOS/save paths. No ROMs, BIOS files, saves, or RetroBat data are copied or modified.

`--install-snes9x` installs the official ARM64 Snes9x nightly alongside the existing Ubuntu core, preserving a backup if a user core already exists. SNES launch metadata prefers this user-installed core and falls back to the Ubuntu package if it is absent.

On ARM64, RetroArch may not have a built-in Core Downloader URL. The installer configures the official ARM64 buildbot and assets endpoints and keeps Core Info files in RetroArch's writable user info directory, so the Core Downloader list and info updates have their required paths.

The install command prints its planned actions and prompts before installing packages or creating files. To explicitly accept the plan without an interactive prompt:

```bash
bash scripts/install-pegasus.sh --install-frontend --yes
```

`--yes` is explicit consent for the exact actions printed by the selected operation. It does not authorize library data changes. For RetroArch actions, select `--with-retroarch` or `--install-retroarch` explicitly. Use `--jobs N` to change the build parallelism (default: 2).

The installer checks for Ubuntu and ARM64, checks the pinned source commit, and refuses to overwrite an existing Pegasus executable or unrecognized build/install directory. It does not run `apt-get update`, add repositories, or edit existing Pegasus settings. A failed build is reported and the log is retained for diagnosis.

To select another user-local install path, set `PEGASUS_INSTALL_DIR`:

```bash
PEGASUS_INSTALL_DIR="$HOME/Applications/Pegasus" bash scripts/install-pegasus.sh --install-frontend
```

The CMake build and source live under the user's cache directory; installation is under `~/Applications/Pegasus`. The upstream X11 desktop launcher is installed under the user's XDG applications directory. The script prints the exact paths after installation.

## Example preflight and dry run

Output depends on the Orange Pi. A successful preflight should identify the Ubuntu version, `aarch64`, kernel, home directory, available disk space, display session (if active), and installed/missing build packages. Missing optional graphics diagnostics are reported as `NOT CHECKED`, not treated as a failed GPU.

The dry run prints the pinned source tag and commit, dependencies, install/cache/log paths, and the planned commands. It does not create logs or directories, install packages, download source, or change configuration.

## After installation

1. Launch **Pegasus Frontend** from Ubuntu's application menu, or run `~/Applications/Pegasus/pegasus-fe` in a terminal. Startup was verified on the current X11 session; Pegasus reported ARM64/xcb and loaded its default theme.
2. The installation uses **gameOS** as its only theme. It is installed under `~/.local/share/pegasus-frontend/themes/gameOS/`, selected automatically, and configured to always show game titles in the grid. Other optional theme directories are removed. Restart Pegasus to apply any theme-settings update; title visibility is enabled in gameOS settings.
3. RetroArch uses native Vulkan Duimon Mega Bezel presets through a system-aware Pegasus launcher. FBNeo per-game backgrounds use matching arcade artwork from the official Bezel Project MAME pack, cached under `~/Applications/Pegasus/roms/.media/bezelproject/ArcadeBezels/`; games without a matching asset use the regular Duimon arcade cabinet preset. Pegasus's separate `assets.boxFront` remains sourced from the existing box-art cache. Mega Drive/Genesis, NES, and SNES continue to use their corresponding console bezel presets. Generated presets use `HSM_NON_INTEGER_SCALE=86` without changing vertical scale. Console presets retain core/system aspect-ratio detection and use a centered 120-pixel horizontal width offset (60 pixels per side). FBNeo's original preset forces 4:3, so its game-art and cabinet presets use an explicit 1.431961:1 ratio, reducing the previous 1.53:1 width by about 30 pixels on each side at 1280×720. Console and FBNeo presets retain Duimon bezel artwork and use reflective GDV-MINI; fullscreen glow, inner-edge glow, and corner highlights are disabled so reflections remain on the bezel without oval screen glow. Moderate CRT curvature is enabled; vignette, phosphor masks, and afterglow remain disabled. The library refresher recognizes `megadrive`, `fbneo`, `nes`, and `snes` ROM folders recursively when their RetroArch cores are installed. SNES9x is already available; NES needs a supported FCEUmm, Nestopia, or QuickNES core before its ROMs can launch. All selected presets explicitly set `HSM_SCANLINE_DIRECTION=1` (horizontal), avoiding Mega Bezel's Auto mode that switches portrait games to vertical scanlines. GDV-MINI uses `scanline=8` and `shadowMask=-1` for clean scanlines without a phosphor grille or moiré pattern. In-game FPS/frame-count displays, resource overlays, session CSV sampling, RetroArch runtime logs, and RetroArch file logging are disabled. The launcher does not start monitor processes or poll the game while it runs. Input smoothing is disabled so source pixels stay crisp before the CRT effect. This gives a 320×240-style result where the game actually outputs that resolution, while preserving other classic modes such as 320×224 or 256×240 instead of forcing them into the wrong pixel grid. The installer deploys the full `slang-shaders` pack under `~/.config/retroarch/shaders/shaders_slang`, required by Duimon/Mega Bezel dependencies. Pegasus and RetroArch launch at **1280×720**, with RetroArch's output aspect explicitly set to **16:9** (aspect-ratio index 1), VSync enabled, and refresh target set to **60 Hz**. The Pegasus launcher sets the display mode once on launch; it does not continuously poll or reapply the resolution while games run. The output canvas remains 16:9. The 60 Hz output and VSync target the display refresh; the actual stable frame rate still depends on the core, GPU, and game. While a game is running, press **F1** or **Select + Start** on the gamepad to open RetroArch's menu; press **Escape** or the configured controller back action to close it and resume gameplay. Official Libretro controller profiles are installed automatically for UDEV devices, with the Switch Pro Controller supported by default. Press **F5** for the desktop menu toggle if needed.
> **60-FPS status:** In FBNeo Metal Slug, the 20-pass no-reflection preset measured about 54.9 FPS at two gameplay snapshots. With shaders disabled, spot readings were 59.97 FPS near startup and 59.46 FPS during gameplay; this points to shader workload, but does not prove sustained 60 FPS. A 10-pass Potato preset reached 59.45 FPS later in a test, but blurred/obscured the game image, so it was reverted.
>
> **Current FBNeo path:** The launcher uses per-game Duimon Lite Mega Bezel presets with matching Bezel Project arcade artwork as the shader background; games without a matching Bezel Project asset use the Duimon cabinet preset. This keeps the marquee artwork beneath the opaque Duimon bezel, without a transparent full-screen input overlay. Pegasus's box-front artwork remains unchanged. RetroArch and Pegasus remain at 1280×720 with the 20-pass no-reflection Mega Bezel base. Temporary 720×480 and 640×480 tests read 55.86 and 56.21 FPS on attract screens, respectively, and were reverted because the gains were small. Active-gameplay performance and steady 60 FPS are not verified.
>
> **Console layout:** Matching official Duimon presets for the planned consoles use an 86% inner-screen scale, preserve core/system aspect-ratio detection, and apply a centered 120-pixel horizontal width offset (60 pixels per side), with simple horizontal scanlines (`scanline=8`). FBNeo uses an explicit 1.431961:1 ratio rather than its preset's forced 4:3 ratio. Neither adjustment changes the 16:9 output canvas. Reflection rendering is reduced from 800×600 to 400×300, with smaller blur buffers, to reduce GPU work. CRT curvature is enabled; vignette, phosphor mask, afterglow, and screen-glow effects remain disabled; bezel reflections and system-specific artwork remain. The launcher selects a preset from the core name and, where needed, the ROM folder. Pegasus ROM metadata remains registered only for Mega Drive, FBNeo, NES, and SNES; this layout update does not install cores or add ROM metadata.
4. Use Pegasus's **Exit Pegasus** menu item to return to Ubuntu. System power actions are disabled in this setup to avoid selecting shutdown by mistake.

**Logging and monitoring:** Performance monitoring has been turned off. The prior CSV files are retained as historical data, but new sessions no longer create them; the HUD, F12 listener, FPS/frame-count displays, RetroArch runtime logs, and RetroArch log files are disabled. Pegasus starts with terminal logging suppressed, and its normal log file is redirected to `/dev/null` while the previous log is preserved. Pegasus's separate built-in playtime history (`stats.db`) remains enabled; it records game start/duration data on exit, not system performance.

**Mega Drive core:** Pegasus launches Mega Drive/Genesis ROMs with the installed PicoDrive core at `~/.config/retroarch/cores/picodrive_libretro.so`.
4. If you have a library path ready, inspect it without changing anything:

   ```bash
   bash scripts/install-pegasus.sh --inspect-library "$HOME/Applications/Pegasus/roms"
   ```

   Replace the example with the real path. This inspection only lists top-level entries and searches for EmulationStation config/list files at limited depth. It does not write to the library.
5. Only after frontend verification should the library source be tested with Pegasus. Prefer the existing EmulationStation provider if compatible; otherwise use an isolated Linux-side adapter. The Windows RetroBat files remain the source of truth and must not be changed automatically.
6. Add emulators separately, only for systems you choose and after confirming native ARM64 support and a working launch command.

The script does not yet generate a library adapter or install emulators because both require validating the actual library and target device first. Emulator support/performance and cross-machine save compatibility must not be assumed.

## Logs, manifest, backups, and rollback

The installer writes logs and a CSV manifest below:

```text
${XDG_STATE_HOME:-~/.local/state}/pegasus-opi5-installer/
```

If the upstream per-user Pegasus desktop launcher already exists, the installer backs it up before replacing it. The backup path is recorded in the manifest. No existing Pegasus settings or library files are changed by the script.

There is deliberately no automatic uninstall yet. To roll back, first review the manifest and log; remove only the user-local files created by this installer. Restore a backed-up launcher by copying its recorded backup back to the recorded launcher path. Do not remove library data or pre-existing configuration.

## Current screen and arcade art

The current Duimon presets enable moderate CRT curvature (`HSM_CURVATURE_MODE=1`, scale 100) while keeping horizontal scanlines and disabling screen glow, vignette, and phosphor-mask effects. For FBNeo, per-game backgrounds use the matching PNG from the official [Bezel Project MAME pack](https://github.com/thebezelproject/bezelprojectSA-MAME), stored under `~/Applications/Pegasus/roms/.media/bezelproject/ArcadeBezels/`. The full Bezel Project art is composed into an opaque background beneath the Duimon bezel; box-front images remain available to Pegasus but are no longer used for the arcade marquee/background. Games without a matching Bezel Project image use the standard Duimon cabinet preset. The launcher does not enable the separate full-screen transparent input overlay.

## Troubleshooting

- **Preflight reports another architecture or OS:** do not force the build; the workflow is scoped to Ubuntu ARM64.
- **A package is unavailable:** stop and review the Ubuntu package source/configuration manually. The script does not add a PPA or repository.
- **Build fails:** retain the printed log path and report the failing command and final error. Do not resolve it by replacing Mesa, Vulkan, the kernel, or the desktop stack.
- **Pegasus builds but does not display:** distinguish frontend startup/rendering from emulator behavior; test from a terminal and retain the output.
- **No games appear:** first verify the library mount and provider compatibility. Do not copy the full collection or convert metadata until a one-system sample proves what is needed.

## Community development and funding

The GitHub repository is being prepared for community contributions; no license has been selected and no release is being claimed. New contributors should begin with [`START_HERE_AI_CONTRIBUTORS.md`](START_HERE_AI_CONTRIBUTORS.md). Also review [CONTRIBUTING.md](CONTRIBUTING.md), [AGENTS.md](AGENTS.md), the [project status](docs/PROJECT_STATUS.md), the [operating model](docs/OPERATING_MODEL.md), and the [staged implementation plan](docs/STAGED_IMPLEMENTATION_PLAN.md) before inviting contributors.

The project is not currently accepting donations through an official online channel. The funding policy is in [FUNDING.md](FUNDING.md); verified funding links will be added only after the owner chooses a platform and completes payout verification. Code, documentation, and hardware testing remain useful non-financial ways to help.
