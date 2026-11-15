# Feature: Controller setup and hotkeys

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can navigate Pegasus and supported games with common controllers and understand or customize safe shortcuts.

## Current state

The project has not established a supported controller matrix or a project-specific hotkey setup flow. RetroArch and standalone emulators may use different input systems and mappings.

## Scope

- Document controller discovery, Pegasus navigation, RetroArch mapping, and emulator-specific exceptions.
- Define a small, safe hotkey model including quit, pause, and save-state actions only where supported.
- Preserve the user's existing global input configuration and allow emulator-native configuration.

## Out of scope

- Rewriting system-wide keyboard/controller mappings.
- Claiming every controller or emulator combination is supported.

## Acceptance criteria

- [ ] Input configuration is scoped to the application/emulator and can be restored.
- [ ] Default shortcuts avoid accidental destructive actions and are documented.
- [ ] Unrecognized devices, duplicate bindings, and unsupported emulator actions are reported.
- [ ] Keyboard and at least one selected controller are tested on actual target hardware before support claims.

## Validation

- Unit-test mapping parsing and conflict detection with synthetic devices/configuration.
- Record controller model, connection type, OS, emulator/core, and test result for hardware validation.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Never silently overwrite user input configuration.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
