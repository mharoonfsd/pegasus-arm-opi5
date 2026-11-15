# Feature: Scraping, metadata, and game media

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can optionally obtain or maintain game metadata and media in a predictable, reversible way.

## Current state

Pegasus can display metadata supplied by its configured sources, but the project does not claim a complete scraper, supported provider, or automated media-management workflow.

## Scope

- Define supported metadata fields and media types (for example title, description, release year, box art, screenshot, video).
- Compare official provider APIs, rate limits, credentials, terms, and licensing before selecting a provider.
- Provide preview, explicit selection, stable naming, conflict handling, and a report before writing.

## Out of scope

- Scraping protected services, bypassing rate limits, or using unapproved credentials.
- Automatically overwriting source-library metadata or downloading bulk media without consent.
- Committing downloaded media or user API keys.

## Acceptance criteria

- [ ] Provider, data fields, terms, storage path, and rate limits are documented.
- [ ] Preview/dry-run does not write; each actual change is attributable and reversible.
- [ ] Missing matches, ambiguous matches, API errors, and rate limits are reported distinctly.
- [ ] Credentials use an approved OS credential store or explicit runtime prompt, never tracked files.
- [ ] Only media whose provenance/license permits the intended use is fetched.

## Validation

- Use mocked provider responses and synthetic game entries for matching, path, rate-limit, and failure cases.
- Do not make live provider calls in CI or include scraped assets in fixtures.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). The user must retain ownership of their library and control where downloaded media is stored.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
