# Feature: Themes and interface customization

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can choose and configure an understandable Pegasus theme with readable navigation and safe defaults for limited hardware.

## Current state

Pegasus uses a bundled theme in the documented installation path. The project has not defined a project-maintained theme catalog or theme settings UX.

## Scope

- Document supported theme selection and safe install/remove/rollback behavior.
- Define display scaling, text/readability, and optional animation controls where the current Pegasus version supports them.
- Track theme source and license before recommending or packaging third-party themes.

## Out of scope

- Replacing Pegasus or installing a separate launcher.
- Bundling assets of unknown origin or disabling accessibility to gain performance.

## Acceptance criteria

- [ ] Theme changes preserve the previous setting and can be reverted.
- [ ] Missing/incompatible themes produce a clear fallback/error without silently altering data.
- [ ] Theme dependencies, source, and license are recorded.
- [ ] Performance-sensitive visual options are optional and measured on the target hardware.

## Validation

- Test configuration parsing, missing-theme handling, and rollback with isolated fixtures.
- Confirm rendering and text readability on the Orange Pi before claiming support.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Do not download or commit theme assets without provenance and license approval.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
