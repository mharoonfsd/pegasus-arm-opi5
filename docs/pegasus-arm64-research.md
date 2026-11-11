# Pegasus ARM64 research and implementation decision

Research performed: 2026-10-27.

## Decision

The current upstream desktop release and Flathub bundle do not provide a generic ARM64 desktop binary for the Orange Pi 5. The latest upstream GitHub release found during research is `weekly_2024w38`, published 2024-10-05. Its assets include an `amd64` Debian package and board-specific packages (Odroid and Raspberry Pi variants), but no generic `aarch64`/Orange Pi 5 desktop artifact. The current Flathub AppStream record identifies its bundle as `x86_64`.

Following the user's choice, the implementation uses Pegasus's documented native CMake source-build route, pinned to upstream tag `weekly_2024w38`, commit `c3462e68bf3a178420b44f356998255f8d82a113`. The source has configured and compiled successfully on the target as ARM64 with the X11 desktop target enabled. Installation and launch verification remain.

## Verified upstream guidance

- [Pegasus Linux platform notes](https://pegasus-frontend.org/docs/user-guide/platform-linux/) describe Ubuntu 22.04 or later for official builds and list Linux runtime dependencies. They also document a source-build option.
- [Pegasus build documentation](https://pegasus-frontend.org/docs/dev/build/) describes the native C++ build, Qt 5.15+ modules, optional SDL 2, and QMake/CMake build flows.
- [Pegasus EmulationStation data source documentation](https://pegasus-frontend.org/docs/user-guide/meta-sources/) says desktop Linux can read configured `es_systems.cfg` directories and `gamelist.xml`, but cautions that only the supported official EmulationStation variant is compatible.
- [Pegasus metadata file documentation](https://pegasus-frontend.org/docs/user-guide/meta-files/) describes Pegasus-native metadata and the `<config dir>/metafiles` option.
- [GitHub upstream release](https://github.com/mmatyas/pegasus-frontend/releases/tag/weekly_2024w38) and [pinned source commit](https://github.com/mmatyas/pegasus-frontend/commit/c3462e68bf3a178420b44f356998255f8d82a113).
- [Flathub listing](https://flathub.org/apps/org.pegasus_frontend.Pegasus) and current [Flathub manifest](https://github.com/flathub/org.pegasus_frontend.Pegasus/blob/master/org.pegasus_frontend.Pegasus.yml).
- [RetroBat folder structure](https://wiki.retrobat.org/get-started/retrobat-folder-structure) is only a starting reference; the user's actual layout must be inspected.

The selected source tag's CMake build requires Qt 5.15 modules, Qt LinguistTools, CMake 3.16+, and optionally SDL2. The device's CMake 3.22.1 and Qt 5.15.3 dependencies were checked. Pegasus's target-platform CMake defaults ARM systems to EGLFS, so this desktop workflow explicitly enables the X11 install target; the resulting configuration reports the per-user desktop launcher path. SDL2 is enabled for gamepad support and link-time optimization is disabled to keep the device build simpler.

## Scope and safety

The implementation provides a read-only preflight, a dry run, and an explicitly confirmed user-local source build. It checks the source checkout against the pinned commit before compiling. It does not install an x86 binary, use Wine/Box64, modify OS or graphics components, add package repositories, edit Pegasus settings, move/copy library files, or install emulators.

The proposed local install path is `~/Applications/Pegasus`; the preferred Pegasus-side ROM/library path is `~/Applications/Pegasus/roms`. This is not a requirement to relocate existing data. The actual RetroBat root remains unknown until supplied and inspected. Library conversion/mapping is deferred until Pegasus launches and a small sample can be tested.

## Target preflight performed

The read-only preflight and dry run were run in the current workspace environment, which reports the expected target characteristics:

- Ubuntu 22.04.5 LTS, `aarch64`, kernel `5.10.0-1012-rockchip`.
- X11 desktop session; Mali-G610/Panfrost reported by `glxinfo`.
- 39 GB available on the home filesystem.
- Required Qt/SDL development packages are now installed.
- Pegasus is not already installed at the planned user-local location.
- Native CMake configuration, compilation, and user-local installation succeeded for the pinned commit.
- The installed executable starts on X11 and identifies itself as Ubuntu ARM64/xcb with Qt 5.15.3. It displays the default theme and reports no games because no library has been configured.

The preflight and dry run made no changes. The missing packages and native source build still require explicit user confirmation before installation.

## What remains unverified

- Clean exit through Pegasus's UI and visual confirmation by the user. An automated window-close request did not exit the app.
- Controller input behavior.
- Compatibility of the user's EmulationStation/RetroBat configuration and media paths.
- Native emulator support/performance for the user's prioritized systems.

If a dependency is unavailable or the source build fails, stop and report the exact step and logs. Do not switch to x86 binaries or repair graphics components as an installation side effect.
