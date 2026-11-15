# Feature: Game manuals

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can open a manual they already own or have permission to use from a game context.

## Current state

The repository does not implement a manual browser or define a manual storage convention.

## Scope

- Specify supported local document formats, discovery rules, accessibility, and a user-configurable media path.
- Open documents with a documented native viewer or a narrowly scoped in-app viewer after dependency review.

## Out of scope

- Downloading manuals from unverified or unauthorized sources.
- Committing manuals or copying/reorganizing the game library.

## Acceptance criteria

- [ ] Missing or unsupported documents are reported without failing game launch.
- [ ] Paths with spaces and Unicode work; external paths remain configurable and read-only.
- [ ] Viewer dependency, format support, and licensing are documented.

## Validation

- Test discovery with synthetic PDFs/placeholders and missing/unreadable paths.
- Verify on the Orange Pi using a public-domain or user-authorized test document.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Keep copyrighted manuals and personal library data out of Git.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
