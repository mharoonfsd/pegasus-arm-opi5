# Feature: System and per-game options

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can adjust supported settings for one system or game without editing unrelated games or losing existing configuration.

## Current state

The installer generates some RetroArch launch/preset configuration, but there is no complete user-facing per-system/per-game options workflow.

## Scope

- Define the settings that can be safely overridden, their precedence, storage format, and reset behavior.
- Keep generated defaults separate from user edits and avoid duplicate/conflicting configuration.
- Show the effective value and source where feasible.

## Out of scope

- Automatically changing global Ubuntu, driver, display-server, Mesa/Vulkan, or controller settings.
- Exposing arbitrary shell commands as a game option.

## Acceptance criteria

- [ ] Precedence among default, system, and game options is deterministic and documented.
- [ ] Reset affects only the selected override; user config is backed up before migration.
- [ ] Invalid or unsupported values are rejected with an actionable error.
- [ ] Paths and arguments are passed safely without shell-string interpolation.

## Validation

- Test precedence, reset, invalid values, and paths with spaces in isolated temporary configurations.
- Verify any visible setting on hardware where it affects emulator behavior; do not infer performance from configuration alone.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Preserve original configurations and document rollback.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
