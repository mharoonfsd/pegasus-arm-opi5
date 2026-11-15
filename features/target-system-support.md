# Feature: Native support for the target systems

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>
- **Platform scope:** Ubuntu ARM64 / Orange Pi 5

## User outcome

Users can discover and launch compatible games from the project's eight target systems using verified native Linux/ARM64 emulators or cores.

## Current state

The target set is Atari 2600, FBNeo, MAME, Mega Drive/Genesis (one system), Mega CD/Sega CD, Nintendo 64, NES, and SNES. Existing Pegasus metadata generation for some systems is not proof of emulator availability, launch success, compatibility, or performance. The installation brief and [project status](../docs/PROJECT_STATUS.md) distinguish historical setup from current validation.

## Scope

- Maintain a per-system matrix for canonical name/ROM folder, official native ARM64 emulator/core, required BIOS (as a name/check only), supported formats, exact launch command, and validation status.
- Implement launch metadata only for combinations verified against official documentation and tested without distributing copyrighted game data.
- For arcade systems, document romset/core compatibility separately for FBNeo and MAME.

## Out of scope

- Adding systems beyond the eight listed targets.
- Bundling, downloading, or redistributing ROMs, BIOS/firmware, emulator binaries, or proprietary assets.
- Claiming all games work based on one successful sample.

## Acceptance criteria

- [ ] All eight targets have an explicit `verified`, `not verified`, or `unsupported` status with evidence.
- [ ] No system is marked supported from a metadata entry or successful compilation alone.
- [ ] Each verified launch records board, Ubuntu version, core/emulator version, command, test-game provenance-free identifier, result, and performance where relevant.
- [ ] Missing core, BIOS, file, and incompatible format errors are distinct and actionable.
- [ ] If an official native ARM64 build is unavailable, stop and present the user with supported options before choosing a substitute.

## Validation

- Use synthetic fixtures for metadata/launch-string tests; never commit game data.
- Run an actual launch test on the Orange Pi for every system claimed supported. Report exactly which tests were not run.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Use only native Linux/ARM64 binaries; never use Wine, Box64, x86 emulation, or x86-only builds.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
