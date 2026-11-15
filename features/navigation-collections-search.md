# Feature: System navigation, collections, and search

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can navigate systems and games, find titles, and create useful filtered or user-defined collections.

## Current state

Pegasus provides frontend navigation and theme behavior, but the project has no documented parity implementation for saved collections, favorites, or cross-library search.

## Scope

- Define behavior for system/game views, text search, favorites, recently played, and user-defined collections.
- Preserve the existing library provider and game metadata; keep generated collection data separate where possible.
- Document keyboard/controller interaction and empty/error states.

## Out of scope

- Replacing Pegasus or introducing a second launcher.
- Rewriting the source library or adding a remote database/service.

## Acceptance criteria

- [ ] Search and collections work against the configured provider without duplicating game entries.
- [ ] Empty, duplicate, unavailable-library, and stale-entry states are clear and recoverable.
- [ ] User-created data can be backed up and removed without altering source game files.
- [ ] Navigation is testable with keyboard and a representative controller.

## Validation

- Add automated tests using a synthetic library with duplicate titles, missing files, Unicode, and paths with spaces.
- Verify controller and visual behavior on the target device before claiming hardware support.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Do not collect analytics or transmit library contents.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
