# Feature: RetroBat library compatibility

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can reuse compatible metadata and media paths from an existing RetroBat/EmulationStation library without copying or reorganizing the library.

## Current state

The installer can inspect a user-supplied library root read-only. The project does not yet claim compatibility with every RetroBat format or path convention; see the [installation brief](../docs/orange_pi_5_pegasus_installation_brief.md).

## Scope

- Inventory supported EmulationStation gamelist formats, path roots, multi-disc entries, and media references.
- Prefer Pegasus's supported EmulationStation data source where it works; otherwise propose an isolated, reproducible adapter.
- Make any path mapping explicit, Linux-aware, and configurable without changing source files.

## Out of scope

- Moving, renaming, rewriting, or deleting any source-library files.
- Importing Windows emulator commands or assuming Windows paths work on Linux.
- Claiming save-file compatibility without a separate emulator-specific check.

## Acceptance criteria

- [ ] Compatibility is reported by format and field, including unsupported/ambiguous cases.
- [ ] A representative sample can be inspected read-only and compared with Pegasus output.
- [ ] Any generated adapter is isolated, repeatable, count-reconciled, and accompanied by a conversion report.
- [ ] Duplicate sources and missing mounts/media produce explicit guidance.
- [ ] Documentation includes backup/rollback and never directs users to copy the whole library.

## Validation

- Use synthetic paths with spaces, Unicode, relative roots, missing media, and multi-disc records.
- Validate against actual user data only read-only and only with explicit user selection; do not put that data in tests or Git.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Keep ROMs, BIOS, saves, scraped media, and private configuration out of the repository.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
