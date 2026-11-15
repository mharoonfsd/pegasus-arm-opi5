# Feature: Cheats

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can optionally enable cheats only for emulators/cores that support a documented, compatible format.

## Current state

The project does not provide a unified cheat manager or claim cheat-format compatibility.

## Scope

- Inventory supported native core/emulator cheat interfaces and supported file formats.
- Make enable/disable state explicit, scoped per game, and reversible.
- Explain compatibility/version mismatch and avoid applying cheats silently.

## Out of scope

- Downloading cheat databases from unverified sources.
- Automatic modification of ROMs, emulator binaries, or unrelated game configuration.

## Acceptance criteria

- [ ] Compatibility is identified per tested core/version and unsupported cases are explicit.
- [ ] Cheat files are user-controlled and not committed; invalid data does not crash launch.
- [ ] Enabling/disabling changes only the selected game's setting and can be reversed.

## Validation

- Unit-test parsing and invalid input with synthetic, nonfunctional fixtures.
- Verify one supported configuration on device only with an authorized game; report untested cores.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Audit source/license for any external cheat data.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
