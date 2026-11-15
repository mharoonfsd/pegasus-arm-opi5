# Feature Task Catalog

New contributors should start with [`START_HERE_AI_CONTRIBUTORS.md`](../START_HERE_AI_CONTRIBUTORS.md). These briefs turn the project's initial RetroBat comparison into bounded contribution areas for native Pegasus and RetroArch on Ubuntu ARM64. They are a roadmap, not a claim that every RetroBat feature is compatible, appropriate, or already supported here.

Every brief is currently **Draft — not agent-ready**. A maintainer must verify its scope, dependencies, licensing, issue link, and test plan before asking a contributor or coding agent to implement it. Read [CONTRIBUTING.md](../CONTRIBUTING.md), [AGENTS.md](../AGENTS.md), and [the task-spec template](TASK_SPEC_TEMPLATE.md) first.

## Current project comparison

These are repository-recorded states, not fresh hardware verification. "Not documented" means the project has no verified implementation claim; it is not a statement that upstream Pegasus cannot provide the capability.

| Area | Current project evidence and status | Brief |
|---|---|---|
| Install and recovery | The installer documents preflight, dry-run, frontend/RetroArch setup, and library configuration. A complete updater and automatic uninstall are not established. | [Installation, updates, and recovery](installation-update-recovery.md) |
| Target systems | Metadata generation is recorded for Mega Drive, FBNeo, NES, and SNES. That does not prove a native core is installed or a game launches. Per-system launch/performance verification remains open. | [Target-system support](target-system-support.md) |
| Existing library | The installer supports read-only inspection and a configurable library path. Compatibility against the actual RetroBat library has not been freshly validated. | [RetroBat library compatibility](retrobat-library-compatibility.md) |
| Scraping and media | Existing metadata/artwork may be reusable where formats and paths are compatible. No project-managed scraper/provider is established. | [Scraping, metadata, and game media](scraping-metadata-media.md) |
| Navigation and collections | Pegasus supplies the frontend; project-specific search, favorites, and saved collections are not documented as implemented. | [System navigation, collections, and search](navigation-collections-search.md) |
| Controllers and hotkeys | Keyboard/controller behavior is not established by the current target-device validation record; no project-wide controller/hotkey manager is established. | [Controllers and hotkeys](controllers-and-hotkeys.md) |
| System/game options | Some launcher-generated RetroArch presets and launch metadata exist. A general user-facing override manager is not established. | [System and per-game options](system-game-options.md) |
| Visual presentation | Historical configuration uses Duimon Mega Bezel presets and Bezel Project arcade artwork. Current performance and profile-switch behavior are not verified. | [Bezels and visual profiles](bezels-visual-profiles.md) |
| Saves and play history | RetroArch save directories and Pegasus playtime history are recorded. A unified save/history manager and cross-core compatibility are not established. | [Saves and play history](saves-and-play-history.md) |
| Optional features | No project-managed implementation/verification is recorded for manuals, theme management, frontend music, cheats, achievements, recording, netplay, or AI development mode. | See the individual briefs below. |

This comparison covers the gaps identified so far, not every per-system option in RetroBat. Before a new feature is scheduled, compare the relevant official RetroBat documentation with this table and add a separate bounded brief when it represents a distinct contribution.

## Platform target

The initial target set is eight distinct platforms/systems: Atari 2600, FBNeo, MAME, Mega Drive/Genesis (one system), Mega CD/Sega CD, Nintendo 64, NES, and SNES. FBNeo and MAME are arcade systems, not consoles. A Pegasus metadata generator recognizing a system does not establish that a native ARM64 emulator/core is installed, that a game launches, or that performance is adequate.

| Brief | Feature area | Status |
|---|---|---|
| [Installation, updates, and recovery](installation-update-recovery.md) | Safe install/update lifecycle and rollback | Draft |
| [Target-system support](target-system-support.md) | Native launch support for the eight targets | Draft |
| [RetroBat library compatibility](retrobat-library-compatibility.md) | Reuse existing library paths and formats safely | Draft |
| [Scraping, metadata, and game media](scraping-metadata-media.md) | Metadata and artwork/video import and management | Draft |
| [System navigation, collections, and search](navigation-collections-search.md) | Browse, filter, favorite, and group games | Draft |
| [Controllers and hotkeys](controllers-and-hotkeys.md) | Input setup, per-emulator mapping, and shortcuts | Draft |
| [System and per-game options](system-game-options.md) | User-visible overrides without destructive config edits | Draft |
| [Bezels and visual profiles](bezels-visual-profiles.md) | Artwork, shaders, and resource-aware display presets | Draft |
| [Saves and play history](saves-and-play-history.md) | Save-state/saved-game locations and recent-play views | Draft |
| [Game manuals](game-manuals.md) | Optional local manuals with library-safe path handling | Draft |
| [Themes and interface customization](themes-interface.md) | Theme selection and documented accessibility/display options | Draft |
| [Frontend music and sounds](frontend-audio.md) | Optional menu music and sound controls | Draft |
| [Cheats](cheats.md) | Opt-in emulator cheat configuration | Draft |
| [Achievements](achievements.md) | Optional supported achievement services | Draft |
| [Gameplay recording](gameplay-recording.md) | Opt-in capture with resource and storage controls | Draft |
| [Netplay](netplay.md) | Multiplayer/network play where supported by native cores | Draft |
| [Pegasus AI development mode](pegasus-ai-development-mode.md) | In-Pegasus task selection and a resource-gated background worker | Draft |

The official RetroBat documentation is a reference for user-facing capability areas; implementation decisions must be independently verified for Linux/ARM64 and this project's licensing and performance constraints:

- [Official RetroBat documentation](https://wiki.retrobat.org/)
- [Supported systems](https://wiki.retrobat.org/systems-and-emulators/supported-game-systems.md)
- [Arcade guide](https://wiki.retrobat.org/systems-and-emulators/arcade-guide.md)
- [Controllers](https://wiki.retrobat.org/controllers/supported-controllers.md)
- [Decorations and bezels](https://wiki.retrobat.org/advanced-features/decorations-and-bezels.md)
- [System and game configuration](https://wiki.retrobat.org/navigation/configuration-of-systems-and-games.md)
- [Scraping and metadata](https://wiki.retrobat.org/navigation/scraping-and-metadata.md)

Do not copy RetroBat source, documentation text, themes, artwork, shaders, emulator binaries, ROMs, BIOS, saves, or scraped media into this repository. Verify provenance and licenses for any proposed dependency or asset. All changes remain subject to required CI checks and human review; scanners cannot prove code harmless.
