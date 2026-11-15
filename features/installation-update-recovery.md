# Feature: Installation, updates, and recovery

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>
- **Platform scope:** Ubuntu ARM64, especially Orange Pi 5

## User outcome

Users can install and update the native Pegasus/RetroArch setup through a repeatable, understandable process, inspect what will change, and safely recover from a failed operation.

## Current state

[`scripts/install-pegasus.sh`](../scripts/install-pegasus.sh) provides preflight, dry-run, frontend installation, optional RetroArch setup, and library configuration. The project does not yet claim a complete automatic update or uninstall/recovery workflow; see [project status](../docs/PROJECT_STATUS.md).

## Scope

- Specify and implement idempotent update detection, user-owned backups, operation manifests, clear failure reporting, and documented rollback.
- Keep each privileged operation explicit and narrow; preserve user configuration by default.

## Out of scope

- Replacing Ubuntu, kernel, bootloader, desktop session, graphics drivers, Mesa/Vulkan, or package sources.
- Automatic cleanup of files not created and recorded by this installer.

## Acceptance criteria

- [ ] Check-only and dry-run make no changes; repeated installs do not duplicate configuration.
- [ ] Each created, modified, or backed-up file has a manifest entry and reason.
- [ ] A failed stage reports its command and log location without hiding the failure.
- [ ] Recovery restores only recorded files and never removes user libraries or pre-existing configuration.
- [ ] Readme and installation brief document prerequisites, exact commands, logs, limitations, and rollback.

## Validation

- Exercise check-only/dry-run and idempotence with isolated temporary HOME/config fixtures.
- Test install/update/recovery on the Orange Pi only after explicit approval; report exact OS and package sources. Host tests do not establish device compatibility.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Any new download must come from an official source and be version-pinned and integrity-checked where possible. Do not copy/move user data or run broad cleanup commands.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
