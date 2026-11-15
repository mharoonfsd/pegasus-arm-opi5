# Implementation Brief: Pegasus Frontend and RetroArch on Orange Pi 5 Ubuntu, Reusing a Windows RetroBat Library

**Purpose of this file:** Give a coding AI enough context to research, design, and implement a safe installation/configuration script for the user's Orange Pi 5. The AI should follow the sequence in this document rather than jumping straight into installing packages or writing a long script based on guesses.

## 1. The request in plain language

I already use **RetroBat on a Windows PC**, and I want a similar retro-gaming library interface on my **Orange Pi 5 running Ubuntu 22.04.5 LTS**. I am interested in **Pegasus Frontend** because it is a customizable, cross-platform frontend.

I want Pegasus to run **natively on Ubuntu ARM64**, browse my game collection, and launch compatible native Linux emulators. I want to reuse as much as possible from my existing RetroBat collection—especially ROMs, BIOS/firmware, artwork, videos, game lists/metadata, and possibly save files—rather than creating and maintaining a completely separate library.

The desired outcome is a straightforward, repeatable setup with as much configuration already handled as practical. I do **not** want to emulate RetroBat itself or replace my current operating system.

### What success looks like

After setup, I should be able to:

1. Boot into or log into my existing Ubuntu desktop as usual.
2. Launch Pegasus as a normal native Linux application.
3. Browse a console-like library of the systems and games that the Orange Pi can support.
4. Use the existing RetroBat ROM/BIOS/library folders wherever possible, without copying or reorganizing the whole collection.
5. See existing game information and artwork wherever their format and paths are compatible.
6. Launch games through Linux/ARM64-compatible emulators, not Windows emulator executables.
7. Return to the normal Ubuntu desktop without being locked into a kiosk or replacement shell.
8. Re-run the setup/configuration safely without duplicate entries, lost settings, or damage to the library.

## 2. Explicit requirements and non-goals

### Required

- Install/configure **Pegasus Frontend** as the intended frontend, subject to first confirming the correct native build or documented native installation method for the target architecture.
- Target device: Orange Pi 5, Ubuntu 22.04.5 LTS, ARM64/aarch64.
- Use the user's current Ubuntu installation and preserve the existing desktop and applications.
- Investigate Pegasus's existing EmulationStation/RetroBat compatibility **before inventing a custom conversion process**. Prefer the simplest documented route that reuses existing metadata and assets.
- Make the library root configurable. Do not assume its physical drive, mount point, share address, Windows drive letter, user name, or RetroBat installation path.
- Reuse data in place where practical. Do not make a second copy of a large ROM/media library by default.
- Documentation maintenance: whenever requirements, implemented features, accepted scope, installer behavior, paths, safety rules, or verification state change, update this brief in the same work session. Keep the brief synchronized with the implementation and the README; never leave a material behavior change documented only in an answer or script.
- Clearly separate frontend installation from emulator installation, while allowing an explicit combined opt-in.
- The frontend installation must include native Qt/QML runtime modules required by the bundled Pegasus Grid theme and built-in settings menu, including `qml-module-qtgraphicaleffects`, `qml-module-qtmultimedia`, and `qml-module-qt-labs-qmlmodels`; a successful build must not leave Pegasus stuck on a theme-loading or blank-settings screen.
- Install **RetroArch and its native ARM64/Ubuntu libretro cores** by default in the complete Pegasus/RetroArch setup route. A frontend-only route remains available with `--install-frontend` alone.
- Use only cores available from the device's configured Ubuntu package sources; do not add a repository or PPA unless separately approved.
- Prefer native ARM64 RetroArch cores and package-provided core metadata. Do not assume that every RetroBat system or libretro core is available or performs well on the Orange Pi 5.
- Create only empty, user-owned `roms`, `bios`, and `saves` directories below the Pegasus installation directory by default. Never copy or move existing ROM, BIOS, or save data.
- Show exactly what the script will do before making system-level changes.
- Produce logs, backups of configuration files that are changed, and a manifest of files the script creates or modifies.
- Provide plain-language instructions that do not require the user to understand every Linux packaging detail.

### Explicitly forbidden

- **Do not run RetroBat itself** on Linux.
- **Do not use Wine, Box64, or x86 emulation** to run RetroBat or make the frontend function.
- Do not install Batocera, Recalbox, or any other replacement operating system.
- Do not replace or modify the user's Ubuntu installation, bootloader, kernel, desktop shell, display manager, graphics drivers, Mesa stack, Vulkan configuration, or system repositories as a side effect of a frontend install.
- Do not install x86-64-only executables on ARM64 or assume that an AppImage works just because it is an AppImage.
- Do not copy, delete, rename, reformat, or reorganize existing ROM, BIOS, media, or save folders automatically.
- Do not overwrite RetroBat's Windows settings or its existing metadata files.
- Do not assume that Windows emulator binaries, `.exe` paths, drive letters, or Windows-only settings can be reused by Linux.
- Do not install every possible emulator, download large artwork/video sets, or configure automatic login without a separate opt-in choice.
- Do not ask the user to answer a long questionnaire before doing safe discovery and frontend preflight work. Unknown optional details should be configurable later.

## 3. Known target machine (verify before acting)

The user's previously reported environment is:

- Device: Orange Pi 5
- OS: Ubuntu 22.04.5 LTS
- Architecture: `aarch64` / ARM64
- Kernel: `5.10.0-1012-rockchip`
- GPU: Mali-G610
- Graphics stack previously reported: Mesa/Panfrost
- Vulkan had failed in earlier experiments; therefore do not assume Vulkan is functional.
- The user has used `~/Applications` and `~/Downloads` for application-related files.
- The Windows PC already has a working RetroBat setup.

Treat this as a **known starting snapshot**, not as permission to hard-code paths or change graphics components. The preflight should report the actual system state and flag differences. The basic frontend setup must not try to repair prior Vulkan/Steam/graphics issues.

## 4. Most important technical principle: test existing compatibility first

Pegasus has documented support for EmulationStation as a data source on desktop Linux, embedded Linux, Windows, and macOS. The official documentation says it can read directories configured in `es_systems.cfg` and read game metadata/assets from `gamelist.xml`. It also warns that multiple, incompatible EmulationStation variants exist and that only the supported official variant is compatible.

RetroBat uses an EmulationStation-derived structure, but **do not assume every RetroBat configuration is directly compatible**. The first technical task is to establish which part of the user's existing library can be read as-is and what, if anything, needs a Linux-specific adapter.

Preferred approach, in order:

1. **First choice — read the existing EmulationStation-compatible data.** Check whether the installed Pegasus build can read the user's RetroBat-derived `es_systems.cfg`, per-system `gamelist.xml`, relative game paths, and media paths. Make a small, reversible test on a small sample, not on the entire library.
2. **Second choice — create a Linux-side configuration copy.** If the RetroBat metadata is usable but contains Windows paths, create a separate generated Linux config that points to the same library mounted on Ubuntu. Do not edit the Windows originals. Preserve the existing ROM/media layout.
3. **Third choice — generate Pegasus metadata files.** If the EmulationStation source is incompatible or cannot express what's needed, generate Pegasus `metadata.pegasus.txt` files from the existing metadata using the current documented syntax. Write them to a separate output/config area by default. A converter must preserve titles, file names, multi-disc grouping where possible, metadata, and artwork references; it must emit a report of anything it cannot convert.
4. **Only as a last resort — manual per-platform configuration.** Do not create a large manual emulator configuration until the automatic/native compatibility paths have been tested.

Relevant official references:

- [Pegasus documentation home](https://pegasus-frontend.org/docs/)
- [Pegasus Linux platform notes](https://pegasus-frontend.org/docs/user-guide/platform-linux/)
- [Pegasus metadata files and syntax](https://pegasus-frontend.org/docs/user-guide/meta-files/)
- [Pegasus third-party data sources, including EmulationStation](https://pegasus-frontend.org/docs/user-guide/meta-sources/)
- [RetroBat folder structure](https://wiki.retrobat.org/get-started/retrobat-folder-structure)

Read these current documents before selecting the implementation. The links are starting points, not substitutes for verifying what the actual installed release supports.

## 5. Reusing the RetroBat collection

### 5.1 Data that should be shared when compatible

- ROMs and disc images;
- BIOS and firmware files that are compatible with the chosen emulator;
- game lists and metadata;
- box art, logos, screenshots, video previews, and other media;
- save files only where emulator/core format and configuration make this safe;
- optionally screenshots and other user-created game data.

ROMs and BIOS files should not be copied simply to make Pegasus see them. The default goal is to point Pegasus and Linux emulators at the existing files.

### 5.2 Data that usually remains platform-specific

- Windows emulator executables, DLLs, installers, and launch scripts;
- Windows drive-letter paths such as `D:\\...`;
- launch commands invoking `.exe` files;
- emulator options, graphics settings, controller settings, and configuration paths that differ between Windows and Linux;
- Windows-specific RetroBat frontend settings.

Use native Linux ARM64 emulator packages/builds and create Linux-specific launch commands. The installer must not try to reuse Windows emulator binaries.

### 5.3 Possible locations for the shared library

The user has not yet said where their RetroBat folder is stored. Support the following possibilities without assuming which is true:

- **External drive:** same removable drive is connected to either computer. Detect its mount point; do not assume a fixed path.
- **Windows network share:** Windows remains the host/source of truth; Ubuntu accesses the library over the local network. Configure a mount only if requested and do not make system boot depend on it.
- **Separate local copies:** user may choose to copy/synchronize the data. This is not the default, and the script must not start synchronization or duplicate large folders without an explicit choice.

Use a configurable library root, for example `LIBRARY_ROOT`, rather than a hard-coded path. During first run, let the user browse/type the root or skip the library configuration and finish the frontend-only step. The script should identify likely subdirectories and display a proposed mapping for confirmation.

### 5.4 Storage safety

- Read and report the actual folder structure before proposing any mapping.
- Treat the RetroBat source folder as read-only by default.
- Do not modify `/etc/fstab`, SMB credentials, file-system mount settings, or permissions without explicit consent.
- For network shares, never put passwords in shell history, scripts, logs, or world-readable files. Use a protected credentials file or an established credential manager if a mount is explicitly requested.
- Avoid assuming that symlinks work on every external filesystem. Prefer configured paths when possible.
- Detect when the library root is unavailable and explain that Pegasus may show no games until it is mounted.
- If the storage is NTFS/exFAT, call out possible permission/symlink limitations rather than applying broad permission changes.
- Do not allow the same save file to be written simultaneously by Windows and Linux emulator instances. Document that save sharing is safest when both instances are closed before switching machines.

### 5.5 Example layout is illustrative only

A library might contain something similar to:

```text
RetroBat/                    # Example only; discover the real path
├── bios/
├── roms/
│   ├── nes/
│   ├── snes/
│   ├── megadrive/
│   ├── arcade/
│   └── ...
├── saves/
├── screenshots/
├── emulationstation/
│   └── .emulationstation/   # Exact location may differ by setup
└── ...
```

**Do not rename system directories to match this example.** The names above are examples only; use the user's existing folder names and discover actual paths. Preserve RetroBat conventions and introduce a separate mapping layer if Linux or Pegasus needs a different name/path.

## 6. Installation and configuration must be a straightforward, staged workflow

The coding AI should implement and document these stages in order. Do not combine everything into a large irreversible setup operation.

### Stage 0 — Research, before writing installation commands

1. Inspect current official Pegasus documentation and current upstream release assets.
2. Confirm whether a native ARM64/aarch64 build is published for the selected release. If not, investigate whether the official build-from-source path is realistic on Ubuntu 22.04 ARM64.
3. Do not claim ARM64 support solely because Pegasus supports Linux or because an x86-64 artifact exists.
4. Identify the official install method, supported runtime libraries, config locations, launcher method, and upgrade path.
5. Confirm how Pegasus discovers EmulationStation data and which exact files/paths it expects.
6. Confirm how to start emulators from Pegasus metadata and how to represent Linux paths safely.
7. Provide source links and summarize the decision. If a reliable native method cannot be established, stop before system modifications and explain options clearly.

### Stage 1 — Read-only preflight

The preflight/check-only mode must not modify the computer. It should report:

- OS version and `/etc/os-release`;
- CPU architecture from `uname -m`;
- kernel version;
- logged-in user and home directory;
- available disk space;
- desktop and display session (X11/Wayland if detectable);
- whether `sudo` and required download/extraction tools are available;
- current Pegasus version/install/config if present;
- relevant dependencies for the selected official installation method;
- graphics/OpenGL information if safe tools are installed, without assuming Vulkan;
- whether the selected Pegasus artifact matches ARM64;
- candidate RetroBat/library locations only if the user supplied a location or asks the script to inspect one.

Preflight output must distinguish **PASS**, **WARNING**, **BLOCKER**, and **NOT CHECKED**. Missing optional diagnostic tools are not evidence that the system is broken. Do not install tools during check-only mode.

### Stage 2 — Present a concise plan and ask before system changes

Before installing, print a summary like:

- Pegasus version and official source;
- detected architecture and compatibility result;
- packages to install and why;
- application/config/log/backup locations;
- whether any existing config will be changed;
- whether the library will be read-only or writable;
- optional emulator choices (none by default);
- the exact commands/changes planned.

Require user confirmation before `apt install`, writing system-wide desktop entries, mounting network shares, editing mount configuration, or changing existing files. The script may offer a noninteractive mode, but it must still have an explicit flag such as `--yes` and must refuse unsafe actions rather than infer consent.

### Stage 3 — Install Pegasus only

Install the native frontend using the verified official method. The script should:

- prefer a verified official ARM64 artifact if one exists;
- otherwise give a clearly documented source-build option rather than using an incompatible binary;
- install only dependencies required by the chosen method;
- avoid adding repositories/PPAs unless absolutely required, justified, and approved;
- use a per-user location where supported and appropriate;
- create a desktop/menu launcher if it fits the packaging method;
- preserve any existing Pegasus configuration and back it up before any requested edits;
- avoid setting Pegasus to autostart or replacing the desktop session;
- log installation output and final paths.

If an install fails, the script must report the failed step and useful logs. It must not blindly keep changing dependencies or graphics drivers to make the install appear successful.

### Stage 4 — Launch and verify Pegasus before connecting the library

Start Pegasus manually from the existing desktop or terminal. Check that it launches natively, can display its UI, and exits cleanly. Save the exact version and launch command. If it fails, capture terminal/log output and stop library/emulator configuration until the frontend issue is understood.

### Stage 5 — Connect the existing library with the least duplication

Once Pegasus launches:

1. Ask for or accept the actual library root, or allow the user to skip this stage.
2. Inspect the folder layout in read-only mode and show the proposed ROM, BIOS, metadata, media, and save paths.
3. Test the existing EmulationStation/RetroBat metadata provider on one system or a small sample.
4. Verify that game files, metadata, and at least one piece of media appear as expected.
5. If Windows-specific paths block discovery, generate a Linux-only config copy or mapping. Never edit the Windows original automatically.
6. If metadata conversion is required, create Pegasus metadata using the current documented syntax, with a report of converted/skipped entries and missing paths.
7. Reuse existing media and paths rather than scrape/download duplicate artwork by default.
8. Record mappings and generated files in a manifest.

Do not begin with the whole library if a small-system test can validate the path strategy first. After the sample works, apply the chosen approach to the remaining detected systems.

### Stage 6 — RetroArch and emulator integration

Pegasus is a frontend; it does not execute ROMs. The complete setup route therefore installs native Ubuntu ARM64 RetroArch and every package identified as an available ARM64/all-architecture libretro emulator core in the current package sources after explicit approval. Development packages and GTK frontend helpers are excluded. The core list is detected dynamically and may vary by Ubuntu repository configuration. The script must report the package list rather than pretending that every RetroBat system or third-party core is available.

The user's eventual target lineup is: **3DS, Atari 2600, Atomiswave, Dreamcast, FBNeo, Game Boy, Game Boy Advance, Master System, Mega CD/Sega CD, Mega Drive, N64, Nintendo DS, NES, GameCube (NGC), PC Engine, PS2, PSX, PSP, Sega 32X, SNES, and SuperGrafx**. This list describes desired future coverage only; it is not evidence that the required emulator cores, BIOS files, launch metadata, or Orange Pi 5 performance have been verified. Implement and validate these systems incrementally, prioritizing official/native ARM64 support and tested performance. `genesis` and `megadrive` are alternate names for the same Sega Mega Drive/Genesis platform; `megacd` and `segacd` are alternate names for Sega CD. Each pair should use one shared ROM/core setup, not duplicate system configurations.

RetroArch setup must:

- create `~/Applications/Pegasus/roms`, `~/Applications/Pegasus/bios`, and `~/Applications/Pegasus/saves` only as empty user directories when RetroArch is explicitly selected;
- configure RetroArch's system/BIOS and save/state directories to the Pegasus paths without moving library files;
- configure the official ARM64 RetroArch core-downloader and assets endpoints explicitly, since some ARM64 builds have no compiled-in buildbot URL; keep core info files in a writable per-user info directory;
- back up an existing RetroArch configuration before any requested update;
- verify that the `retroarch` executable is native ARM64 and list discovered `.so` cores;
- launch one supported game through one discovered core before broad Pegasus launch configuration;
- test controller input, BIOS-dependent games, save placement, and a normal return to Pegasus where practical.
- Complete RetroArch routes must install and verify the native ARM64 FBNeo core, configure recursive Pegasus Mega Drive/FBNeo metadata, and register both system directories automatically. NES and SNES launch metadata is also supported when their cores are installed. The user should place ROMs in their matching `roms/<system>` directories and BIOS files in `bios` before launching Pegasus.
- The bundled Pegasus Grid theme requires `qml-module-qtgraphicaleffects` and `qml-module-qtmultimedia`; the built-in settings menu requires `qml-module-qt-labs-qmlmodels`. Frontend installation must include these runtime modules plus the GStreamer good/bad/libav media plugins and verify startup and settings navigation without theme-loading or blank-settings errors.
- The gameOS theme exposes Grid/Vertical List layout and a Library & lists settings page for startup refresh, default sort/order, and favorites filtering. The startup wrapper reads the persisted theme preference, refreshes by default, logs refresh errors, and continues launching Pegasus.
- SNES metadata should prefer the official ARM64 Snes9x core in RetroArch's per-user core directory, with the Ubuntu-provided core as fallback. The installer exposes `--install-snes9x` to install/replace the official core while preserving any existing user core.

Standalone native ARM64 emulators remain optional for systems that need a better-supported standalone implementation than RetroArch. If the user opts into another emulator, recommend a small, prioritized set based on the systems they actually want. For each emulator:

- confirm a native ARM64 build and source;
- confirm how it is installed, invoked, and configured on Ubuntu 22.04;
- use an available and supported graphics backend; do not assume Vulkan is working;
- configure the emulator to use the shared ROM and BIOS paths where compatible;
- configure save paths deliberately and warn about cross-machine save compatibility;
- create/test a Pegasus launch command on one game before generating a whole system's launch config;
- test controller input and normal game exit where practical.

Do not promise that every RetroBat system will perform acceptably on the Orange Pi 5. Clearly label unsupported, untested, or performance-limited systems. Do not install duplicate emulators if suitable native versions already exist.

### Stage 7A — First-game verification and user ROM folders

- Copy user ROMs into system folders below `~/Applications/Pegasus/roms`; do not copy, rename, or convert existing RetroBat files automatically.
- Copy required BIOS/firmware files into `~/Applications/Pegasus/bios`, using exact filenames required by each core.
- ROM discovery must be recursive for every supported system. Folder names beneath a system directory are organizational only and may never prevent a game from loading; RetroArch should receive the exact nested ROM path.
- Folder names such as `A`, `AB`, `ABC`, `ABCD`, and button permutations may be used for controller-layout organization. Such directories do not imply automatic RetroArch remapping; controller overrides remain separately configurable and must be mapped and verified per layout.
- Launch the first Mega Drive game with `picodrive_libretro.so` to verify display, input, RetroArch saves, and clean exit.
- The Ubuntu 22.04 repositories provide no `FBNeo/FBA/FBA2012` libretro package. FBNeo is supported separately through the official RetroArch ARM64 buildbot nightly using `./install-pegasus.sh --install-fbneo`.
- FBNeo is a nightly build, not a pinned Ubuntu package. The installer verifies that the downloaded ELF is ARM64, records its SHA-256 hash in the manifest, backs up an existing core, and installs it under `~/.config/retroarch/cores` instead of adding repositories.
- Before broad use, test one supported FBNeo ROM through the core and report BIOS or Neo Geo firmware requirements separately from game compatibility.
- `aes.zip` is a Neo Geo BIOS/system archive, not a standalone game ROM. Launching it directly is expected to produce FBNeo's `Romset is unknown` error; place the actual arcade ROM archive in `roms/fbneo` and the required Neo Geo BIOS archive in `bios`.
- Verification state must distinguish a game-ROM copy from a BIOS archive. The FBNeo folder may contain references in `gamelist.xml` for games not physically present; only `.zip` files outside BIOS/archive names such as `aes.zip`, `neogeo.zip`, and `neocd.zip` count as candidate game ROMs for launch testing.
- **Verified BIOS availability:** `~/Applications/Pegasus/bios/neogeo.zip` is present and RetroArch is configured with absolute paths to the Pegasus BIOS, core, and save directories. This satisfies the location requirement.
- **Verified nested FBNeo launch:** `mslug.zip` under `roms/fbneo/ABC/` launched successfully through native ARM64 RetroArch and the official ARM64 FBNeo core. Folder depth does not prevent a game ROM from loading; the exact nested file path is valid for launch commands. The Neo Geo BIOS archive at `bios/neogeo.zip` was used successfully for Metal Slug.
- **Verified:** Metal Slug completed startup and reached its game title/insert-coin screen, confirming native core execution, display, ROM recognition, BIOS loading, and nested-directory discovery.
- Missing assets such as RetroArch UI fonts do not prevent core loading, but may be resolved by installing RetroArch assets without changing graphics drivers.
- EmulationStation `gamelist.xml` files may be useful for metadata discovery but are not a substitute for verifying a native emulator launch command.
- **Earlier verification:** Aladdin (`Aladdin (U) [!].zip`) ran successfully through native ARM64 RetroArch using the Genesis Plus GX core; the process exited cleanly when testing ended. This predates the current PicoDrive default and does not verify PicoDrive compatibility. The save file did not exist on the first launch, which is normal until the core creates it.
- Pegasus launch integration is generated with `bash scripts/install-pegasus.sh --configure-library ~/Applications/Pegasus/roms`. The generated `metadata.pegasus.txt` files register exact ROM paths recursively, use the native RetroArch core paths, preserve readable titles from existing `gamelist.xml` files when available, and exclude BIOS-like Neo Geo archives from the game list.
- The integration updates `~/.config/pegasus-frontend/game_dirs.txt` while preserving unrelated existing game directories and creates backups for prior metadata/configuration files. It performs no ROM, BIOS, save, RetroBat, package, repository, or RetroArch-core changes.
- **Verified integration state:** `metadata.pegasus.txt` files were generated for Mega Drive and FBNeo under the Pegasus ROM library, and Pegasus's game-directory configuration includes both system directories. The current Mega Drive launch command uses the installed PicoDrive core; FBNeo arcade launch commands continue to use FBNeo.
- **Theme verification and repair:** startup found that the pinned build's bundled Pegasus Grid theme requires `qml-module-qtgraphicaleffects`; `qml-module-qtmultimedia` is also included for theme/media support. Missing Graphical Effects caused the `Theme loading failed` screen even though games were discovered. After installing both modules, Pegasus restarted and loaded 225 games without the QtGraphicalEffects error. The FBNeo collection now uses the theme-supported `arcade` short name rather than an unavailable `fbneo` logo asset.
- **Automatic box art and screenshots:** every desktop launch refreshes metadata and searches for missing media. It uses ScreenScraper cache first, then existing EmulationStation `<image>` assets, then matching PNG art from the official RetroArch libretro thumbnail service for Mega Drive and FBNeo titles. Thumbnail URLs percent-encode platform and title components, including spaces. Downloads are cached under `roms/.media/box2dfront` and `roms/.media/screenshots`, and generated metadata includes `assets.boxFront`, `assets.screenshot`, and `assets.background` for matched games. If ScreenScraper provides videos, `assets.video` is also emitted.
- **Automatic startup wrapper:** `--configure-library` now installs `~/Applications/Pegasus/run-pegasus.sh` and updates the Ubuntu Pegasus desktop launcher to execute it. The wrapper refreshes recursive ROM discovery and media metadata before launching Pegasus, forces GNOME scaling to `1` and 1280×720/60 on X11 continuously while Pegasus runs, disables Qt auto-scaling, and launches Pegasus with reboot/shutdown/suspend entries disabled so `Exit Pegasus` is the default close path. Refresh failures never prevent Pegasus from opening; valid existing metadata and games remain usable.
- **Verified automatic media state:** the installer generated absolute `assets.boxFront`, `assets.screenshot`, and `assets.background` references for matched Mega Drive and FBNeo titles. Existing artwork is reused and missing metadata is refreshed without copying or renaming ROM or BIOS files. Video fields are generated when ScreenScraper provides video assets for the matched ROM IDs.
- **Settings-screen dependency:** the native settings menu uses `Qt.labs.qmlmodels` and its `qml-module-qt-labs-qmlmodels` Ubuntu package. The installer must install this module so settings contain a populated option list and Escape closes the settings layer normally rather than leaving a blank screen.
- **Display stability and Mega Bezel:** Pegasus and RetroArch force the connected display to 1280×720 at 60 Hz. Both startup wrappers restore this mode, disable GNOME fractional X11 scaling (`org.gnome.mutter experimental-features=[]`), and keep scale factor at 1.0 so launching the frontend or a game does not fall back to 1366×768. RetroArch forces its output aspect to 16:9 (`aspect_ratio_index=1`); the Mega Bezel presets use `HSM_NON_INTEGER_SCALE=86`. Console presets retain each core/system's aspect-ratio detection and add a centered 120-pixel horizontal width offset (60 pixels per side). FBNeo presets use explicit 1.431961:1 sizing instead of forced 4:3. This changes only the game image geometry, not the 16:9 output canvas or bezel artwork. RetroArch uses Vulkan VSync and audio synchronization for the core's native timing. FBNeo uses a generated per-game art background in the side panels when cover art is available, with the Duimon Lite cabinet/no-tilt preset as fallback. Mega Drive, NES, and SNES continue to use their console-specific Duimon Lite bezels. Presets set `HSM_SCANLINE_DIRECTION=1` to force horizontal scanlines. Console and FBNeo presets use reflective GDV-MINI. Fullscreen, inner-edge, and corner glow are disabled to prevent oval artifacts; direct bezel reflections remain enabled. CRT curvature is enabled; vignette, phosphor mask, and afterglow are disabled. RetroArch's in-game FPS/frame-count counters and resource monitoring are disabled. The video output remains configured for 1280×720 at 60 Hz with VSync, but a stable 60 FPS still depends on GPU load and game/core timing.
- **Display stability and Mega Bezel:** Pegasus launches RetroArch through `~/Applications/Pegasus/retroarch-pegasus.sh`, which forces GNOME scale `1`, reapplies 1280×720/60 continuously while RetroArch is running, and restores the same mode on exit. This prevents fallback to 1366×768 during frontend/game transitions. The launcher also forces the Mega Bezel shader explicitly.
- **Mega Bezel and RetroArch:** native RetroArch is built from official `v1.22.2` source at `~/Applications/Pegasus/RetroArch/bin/retroarch` with Vulkan/Slang support. The installer installs official Hyperspace Madness Mega Bezel V1.17.1 under `~/.config/retroarch/shaders/shaders_slang/bezel/Mega_Bezel`, the full `slang-shaders` dependency tree under `~/.config/retroarch/shaders/shaders_slang`, and official Duimon graphics/presets under `~/.config/retroarch/shaders/Mega_Bezel_Packs/Duimon-Mega-Bezel`. It configures Vulkan, enables `video_shader_enable`, disables on-screen FPS/frame-count counters, runtime tracking, and file logging, disables conflicting input overlays, disables input smoothing for crisp source pixels, and installs official UDEV controller profiles. The system-aware launcher selects Duimon Lite presets for FBNeo, Mega Drive/Genesis, NES, and SNES cores. The installer creates Pegasus-specific bases using reflective GDV-MINI; direct bezel reflections remain while fullscreen, inner-edge, and corner glow are disabled to avoid oval highlights. It also enables curvature while disabling vignette, phosphor mask, and afterglow so the game image shows simple horizontal scanlines. FBNeo games use ScreenScraper/available cover art to generate an art background with game-specific art along the sides; their generated presets use `scanline=8`, `shadowMask=-1`, `HSM_NON_INTEGER_SCALE=86`, and explicit 1.431961:1 arcade image aspect. All system presets explicitly set `HSM_SCANLINE_DIRECTION=1` (horizontal), enable CRT curvature, and disable vignette. If a game has no usable cover or Pillow is unavailable, the launcher uses the cabinet preset. Game art backgrounds are stored under `~/.config/retroarch/pegasus-gameart/fbneo/`, and generated presets under the Duimon FB-Neo `Pegasus-GameArt` directory; ROM and BIOS files are not changed. Console cores continue to use their matching Duimon console bezel presets with the original system-specific image geometry and 86% scale. Library metadata refresh recognizes `megadrive`, `fbneo`, `nes`, and `snes` folders recursively when their cores are installed. SNES9x is available; NES ROMs require one of the supported FCEUmm, Nestopia, or QuickNES cores to be installed before launch. The scanline pattern follows each core's reported game-image resolution, so a game outputting 320×240 gets that grid while modes such as 320×224 and 256×240 retain their own native line spacing; it does not force all titles to 320×240. RetroArch's output remains set to 1280×720 at 60 Hz with VSync. This configuration targets the display refresh, but actual sustained FPS must be verified on device for each core/game.
- **Controller input and RetroArch access while playing:** the installer installs official Libretro UDEV autoconfig profiles and uses the UDEV joypad driver. Switch Pro and compatible generic controllers are detected without manual button remapping; gamepad menu access uses **Select + Start** (Select is the RetroArch hotkey enable button and Start toggles the menu). Press **F1** on the keyboard for RetroArch's Quick Menu and **Escape** to return to gameplay. Press **F5** for the desktop-menu toggle. `menu_pause_libretro` is enabled so gameplay pauses when the menu opens. A later core-specific shader or shader preset can be selected from **Quick Menu → Shaders** without changing the global default.
- **ScreenScraper artwork:** native ARM64 Skyscraper 3.21.1 is installed at `~/Applications/Pegasus/tools/Skyscraper`. ScreenScraper credentials are stored only in `~/.skyscraper/config.ini` with mode `600`; the repository and documentation contain no password. Skyscraper uses Mega Drive and arcade/Neo Geo platform definitions and writes resources to its per-system cache. On `--configure-library`, the installer reads Skyscraper `quickid.xml` and `db.xml`, gives ScreenScraper cover artwork precedence over existing thumbnails, copies the cached cover into `roms/.media/box2dfront`, and sets `assets.boxFront` in generated Pegasus metadata. Recursive ROM folders remain unchanged.
- **ScreenScraper verification:** the complete Mega Drive scrape processed 55 ROMs with 54 successful matches and 55 artwork references generated; the FBNeo scrape processed 171 files and found 165 matches, with 163 artwork references generated in the playable collection metadata. Remaining unmatched FBNeo entries are BIOS or ROM filename variants; they remain playable and use fallback art if available. A BIOS archive is never exposed as a Pegasus game.
- **Selected theme:** gameOS (`PlayingKarrde/gameOS`) is the only theme installed or maintained by default. The installer removes other previously installed optional theme directories and their theme-settings files. gameOS is activated in `settings.txt`, and `Always show titles` is enabled so cover/video views display game names. Existing metadata `game` titles, box art, and screenshots remain unchanged.
### Stage 7 — Optional polish, only after basic success

Themes, video previews, menu music, controller tuning, automatic start at login, and kiosk-like behavior are optional. The standard installer installs only `gameOS`; it removes previously installed optional theme directories and settings. gameOS is selected by default and configured with game titles always visible. Theme directories are placed under `~/.local/share/pegasus-frontend/themes/` and must contain a valid `theme.cfg`. Do not change global shortcuts or autostart behavior without a separate explicit opt-in. Explain how to quit Pegasus and return to the normal desktop.

## 7. Installation script quality requirements

The output should be a maintainable Bash script, not a giant opaque command pasted into the terminal.

### Safety and repeatability

- Use safe Bash practices, clear functions, and `set -Eeuo pipefail` where appropriate.
- Do not require the entire script to run as root. Use `sudo` only for individual privileged actions.
- Never use `curl | sudo bash` or execute downloaded content before inspecting/verifying it.
- Download from HTTPS sources that have been confirmed as official. Verify signatures/checksums when provided.
- Pin or record the chosen release version rather than silently trusting an unverified `latest` URL.
- Handle paths with spaces and Unicode correctly; quote variables and use arrays rather than unsafe command-string concatenation.
- Never run destructive cleanup commands against user data. No `rm -rf` on guessed paths, no mass rename, no automatic ROM copying.
- Do not use recursive permission changes such as `chmod -R` on a library or home directory.
- Back up any existing config before changing it; retain timestamps and explain how to restore it.
- Detect an existing installation and avoid duplicate desktop entries/configuration.
- Provide `--help`, `--check-only`, and `--dry-run` modes. Dry-run and check-only must not change system or user data.
- Provide clear logging in a user-owned directory and redact credentials/secrets.
- Keep a manifest containing file path, action (created/modified/backed up), and reason.
- Use an explicit consent step before privileged or potentially disruptive operations.
- An optional uninstall must remove only files that the script created and can verify from its manifest. It must never remove ROMs, BIOS, saves, media, pre-existing configs, or unrelated packages.

### Suggested interface

The exact flags may differ, but aim for a simple workflow:

```text
./install-pegasus.sh --help
./install-pegasus.sh --check-only
./install-pegasus.sh --dry-run --install-frontend
./install-pegasus.sh --install-frontend
./install-pegasus.sh --install-frontend --with-retroarch
./install-pegasus.sh --dry-run --install-frontend --with-retroarch
./install-pegasus.sh --install-retroarch
./install-pegasus.sh --configure-library /path/to/retrobat-or-library
```

Do not hard-code `/path/to/retrobat-or-library`; it is just a usage example. The script should support a prompt and/or a documented environment variable for the library root. A frontend-only install must still be possible without knowing the user's storage location.

## 8. Pegasus metadata and launch configuration rules

- Verify the current official metadata syntax before generating files.
- Use Pegasus's supported EmulationStation source first where applicable.
- Pegasus metadata is human-readable and may be stored next to games or in its configured `metafiles` location; choose the least intrusive supported method.
- Keep Linux emulator launch commands separate from Windows `.exe` launch commands.
- Handle command arguments safely. Paths with spaces must not break launch commands.
- Prefer relative ROM/asset paths where supported and reliable. Where the Windows and Linux systems need different roots, maintain a clear mapping/configuration rather than altering the source.
- Preserve multi-disc games and game metadata where the source format allows it.
- Do not create a second metadata entry for every game if the EmulationStation provider already exposes it.
- Detect duplicate/conflicting sources and explain how to disable one source if duplicate entries appear.
- If conversion is needed, produce a report with counts: games seen, converted, skipped, missing ROMs, missing media, and records needing manual attention.
- Do not claim RetroBat settings are fully portable. The frontend, metadata, and resources may be shareable; emulator binaries and launch settings are platform-specific.

## 9. Graphics, video, and controller considerations

- The target GPU is Mali-G610, and prior Vulkan experiments failed. Treat the graphics state as an existing constraint, not an invitation to replace the graphics stack.
- Pegasus startup and frontend rendering should be tested before emulator setup. Distinguish a frontend display problem from an emulator rendering problem.
- Install only required video playback libraries documented for the chosen Pegasus build. If video previews fail but the frontend otherwise works, report that separately rather than breaking the installation to force them.
- Test keyboard navigation first, then controller detection and navigation.
- Do not remap the user's global controller or keyboard behavior automatically.
- Do not switch display managers or force a different display server unless a documented, separately approved troubleshooting path requires it.
- If a particular game/emulator cannot launch, record the exact emulator command and error to make debugging possible.

## 10. Acceptance checklist

The project is successful only when the final report addresses every item below:

- [ ] System preflight identifies Ubuntu version, architecture, kernel, home directory, and graphics/session information.
- [ ] The chosen Pegasus build/install method is verified to support this target, or the reason it cannot be installed is documented before changes are made.
- [ ] No x86-64-only binary is executed on ARM64.
- [ ] Pegasus launches natively from the existing Ubuntu desktop without Wine or Box64.
- [ ] Ubuntu desktop, boot setup, kernel, GPU drivers, Mesa/Vulkan stack, and system repositories remain unchanged by default.
- [ ] The user's RetroBat files are untouched.
- [ ] The script doesn't copy or reorganize ROMs, BIOS, saves, or media by default.
- [ ] The library root is configurable; if unknown, the frontend-only installation still works.
- [ ] A small test verifies whether the EmulationStation/RetroBat metadata and assets can be reused.
- [ ] If a config adapter/conversion is needed, the original remains unchanged and the generated files are documented.
- [ ] If RetroArch was selected, native ARM64 RetroArch and available Ubuntu libretro core packages are installed, verified, and recorded.
- [ ] The empty Pegasus `roms`, `bios`, and `saves` directories exist and are ready for later user files when RetroArch setup is selected.
- [ ] If RetroArch was selected, its BIOS/system and save directories are mapped without copying or modifying existing ROM/BIOS/save files.
- [ ] At least one supported game can be discovered and, if the emulator stage was selected, launched through a verified native emulator.
- [ ] Missing media, missing BIOS, unavailable mount, unavailable cores, incompatible emulator, and graphics failures are reported distinctly.
- [ ] Dry-run and check-only have no side effects.
- [ ] A second run does not duplicate entries or damage existing configuration.
- [ ] The final manifest lists all created/modified/backup files.
- [ ] Documentation explains how to launch Pegasus, choose the library, add emulators, read logs, restore configs, and exit to Ubuntu.

## 11. What the coding AI must deliver

1. **Research summary:** cite current official Pegasus, Ubuntu, RetroBat, and selected emulator documentation. State clearly whether a suitable native ARM64 artifact exists and what is required to run it.
2. **Preflight/check-only script:** safe to run first; collects facts and reports blockers without installing or editing anything.
3. **Installation/configuration script:** readable, commented, repeatable, and staged as specified above.
4. **README:** prerequisites, commands, expected prompts, file locations, logs, troubleshooting, and rollback instructions.
5. **Metadata/library adapter if needed:** generated from verified inputs, backed up/isolated, and accompanied by a conversion report.
6. **Example output:** show what a successful preflight and a dry-run look like so the user can review proposed changes.
7. **Final report template:** version, install method, path, config path, library path/mappings, launch command, log path, tests passed/failed, emulator support limitations, and next steps.

The AI should not return only an untested script and assert that everything works. It must distinguish what was verified from what is merely planned or remains untested.

## 12. Unknown details — handle gracefully

The following details are not yet known, and must not be guessed:

- Whether the library is on an external drive, a Windows network share, or separate local drives;
- The actual RetroBat root and subdirectory paths;
- The selected system targets are Atari 2600, FBNeo, MAME, Mega Drive/Genesis, Mega CD/Sega CD, Nintendo 64, NES, and SNES; native ARM64 support and performance are still to be verified system by system;
- Whether the user wants emulator installation included now or wants to start with Pegasus only;
- Whether the user eventually wants optional controller-first startup/autostart.

Do not block read-only research, preflight, or a frontend-only install on these unknowns. Provide a clear prompt when the library stage is reached. Keep emulator installation and autostart opt-in.

## 13. Recommended execution plan for the coding AI

Follow this exact order:

1. Read the linked official documentation.
2. Verify a native ARM64 Pegasus installation path and required dependencies.
3. Produce a concise technical plan and a read-only preflight script.
4. Review the preflight results; do not make up missing facts.
5. Implement the smallest safe frontend installer.
6. Verify Pegasus starts on the actual Ubuntu desktop.
7. Inspect the user's selected RetroBat folder read-only.
8. Test Pegasus's EmulationStation data source on one system or a small sample.
9. Add only the minimum Linux-specific configuration needed; keep the Windows originals untouched.
10. Test one native emulator/game only if the user has opted into emulator setup.
11. Document limitations and produce the manifest and rollback instructions.
12. Offer optional themes, broader emulator coverage, and autostart only after the basic path works.

## FPS performance measurement

> The zfast shader and transparent-overlay route was a temporary performance experiment and has been removed. The current FBNeo path below keeps the Duimon Mega Bezel visible. Resolution-reduction tests are reverted; both Pegasus and RetroArch remain at 1280×720.

Matching official Duimon presets for the planned consoles use `HSM_NON_INTEGER_SCALE=86`, retain core/system aspect-ratio detection, and apply a centered 120-pixel width offset (60 pixels per side). FBNeo uses explicit 1.431961:1 sizing instead of forced 4:3. These settings apply to generated system, per-game, and fallback layouts. Simple horizontal scanlines use `scanline=8`. Reflection rendering is reduced from 800×600 to 400×300, with smaller blur buffers. Moderate CRT curvature is enabled; vignette, phosphor mask, and afterglow are disabled. The reflective GDV-MINI base retains bezel reflections while fullscreen, inner-edge, and corner glow are disabled to avoid oval highlights and waves on the game image. FBNeo uses the same treatment with game-art panels. The launcher selects presets from known core names and ROM folder names. Automatic Pegasus metadata generation still covers Mega Drive, FBNeo, NES, and SNES only; this layout update does not install cores or register additional ROM libraries.

The launcher now selects per-game Duimon Lite Mega Bezel presets with matching artwork from the official Bezel Project MAME pack. Arcade assets are cached under `~/Applications/Pegasus/roms/.media/bezelproject/ArcadeBezels/`; their opaque backgrounds place the Bezel Project artwork beneath the Duimon bezel. Pegasus box-front images remain unchanged and are not used for these backgrounds. FBNeo games without matching Bezel Project art use the Duimon cabinet bezel, and console systems retain their matching Duimon presets. Both use the reflective GDV-MINI base at 1280×720 with fullscreen, inner-edge, and corner glow disabled; curvature is enabled while vignette, phosphor mask, and afterglow remain disabled, with horizontal scanlines and bezel reflections. The temporary 720×480 and 640×480 output tests were reverted after FPS increased only from 55.86 to 56.21 in title/attract snapshots. All generated system and game presets use `HSM_NON_INTEGER_SCALE=86`. Console presets apply a centered 120-pixel horizontal width offset (60 pixels per side). FBNeo presets use explicit 1.431961:1 sizing instead of forced 4:3, about 30 pixels per side narrower than the previous 1.53:1 ratio at the same display resolution.

With the restored Duimon bezel, title/attract-screen snapshots read 55.86 FPS at 720×480 and 56.21 FPS at 640×480; both resolution tests were reverted. Active gameplay and sustained 60 FPS are not verified. FBNeo reports native timing of 59.18 FPS, so the game's cadence differs from the display's 60 Hz refresh. The previous one-pass overlay route produced 58.56–59.59 FPS snapshots during title/attract screens, with one later spot reading of 60.02; those values do not apply to the current bezel route. The 20-pass no-reflection Mega Bezel route previously measured about 54.9 FPS at 1280×720; temporarily disabling shaders produced spot readings of 59.97 and 59.46. The 10-pass Potato base reached 59.45 later in a test but blurred/obscured the game image and was reverted. These are spot checks only. CPU/GPU governors were set to performance, the GPU reported 1 GHz, and sampled temperatures were around 53–57°C; no thermal throttling was evident in that check.

The lightweight X11 resource HUD and 500 ms session CSV/F12 marker monitor described in earlier notes have been retired. The launcher no longer starts those processes or polls RetroArch while it runs. RetroArch's FPS and frame-count OSDs, runtime tracking, and file logging are disabled. Historical CSVs and the previous Pegasus log are retained; new Pegasus log output is discarded. Pegasus's separate built-in playtime history (`stats.db`) remains enabled and records game start/duration data when a game exits; it does not sample system performance.

## Current screen and arcade art

The current Duimon presets enable moderate CRT curvature (`HSM_CURVATURE_MODE=1`, scale 100) while keeping horizontal scanlines and disabling screen glow, vignette, and phosphor-mask effects. For FBNeo, per-game backgrounds use the matching PNG from the official [Bezel Project MAME pack](https://github.com/thebezelproject/bezelprojectSA-MAME), cached under `~/Applications/Pegasus/roms/.media/bezelproject/ArcadeBezels/`. The full Bezel Project art is composed into an opaque shader background beneath the Duimon bezel; Pegasus box-front metadata is unchanged. The launcher does not enable the separate full-screen transparent input overlay. If no matching Bezel Project art is available, the standard Duimon cabinet preset is used. RetroArch's touch/gamepad input overlays are separate.

## Community feature briefs and automated checks

The initial parity roadmap and one-task-per-feature briefs are indexed in [`features/README.md`](../features/README.md). They are drafts, not proof of implementation or permission to make broad changes; a maintainer must triage each linked issue before it is treated as ready for an AI agent.

The hosted repository CI runs Bash/Python syntax checks, ShellCheck, Ruff unused-code checks, Bandit, Gitleaks on added/modified files, actionlint, and zizmor. Scanner findings are intended to block their required checks; branch protection/rulesets must be enabled by the repository owner. These tools provide actionable static diagnostics but cannot prove code harmless, identify every malicious change, or determine all unnecessary code. Human review remains mandatory. CI does not test the Orange Pi, launch games, or establish stable 60 FPS.

## Final rule

**Make it feel like RetroBat to use, but implement it as Pegasus on native Ubuntu ARM64. Reuse the existing library before creating a new one. Inspect first, test a small sample, make the smallest reversible change, and never confuse frontend support with emulator compatibility.**
