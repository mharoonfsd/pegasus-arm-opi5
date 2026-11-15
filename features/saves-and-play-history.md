# Feature: Saves and play history

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can find recent games and understand where emulator save data is written, without accidental data loss or false promises of cross-emulator compatibility.

## Current state

RetroArch save/system directories are configured by the installer, but the project does not claim a unified history browser, save manager, or cross-core save compatibility.

## Scope

- Document actual save locations for each supported core/emulator.
- Add recent-play/history behavior only if it can be maintained without changing source game files.
- Make any backup/export feature opt-in, scoped, and clear about compatibility.

## Out of scope

- Moving or deleting existing saves automatically.
- Assuming save states or memory-card formats work across cores or devices.

## Acceptance criteria

- [ ] Save location and format are reported per tested core/emulator.
- [ ] Existing files are preserved; any backup/export requires explicit destination and reports skipped/error cases.
- [ ] Recent-play records do not include private paths or leave the machine without consent.
- [ ] Documentation distinguishes battery saves, save states, and emulator-specific memory cards.

## Validation

- Test path selection and history with empty temporary directories and synthetic records.
- Verify save creation with a legally owned test title on the target device before making compatibility claims.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Saves are user data and must never be committed or cleaned up by a broad command.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
