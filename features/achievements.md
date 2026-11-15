# Feature: Achievements

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users may opt into achievements provided by a supported emulator/core service, with clear account and network requirements.

## Current state

The project does not claim an achievement client, supported service, or credential flow.

## Scope

- Verify native ARM64 core/emulator and service support, terms, network needs, account requirements, and offline behavior.
- Use an approved OS credential store; provide explicit sign-in/out and service disable controls.
- Keep achievement requests scoped to the selected supported game/core.

## Out of scope

- Storing passwords/tokens in repository files or logs.
- Circumventing service policies, spoofing play, or sending library data beyond the service's documented request.

## Acceptance criteria

- [ ] Service and core compatibility are documented and verified before integration.
- [ ] No secrets are stored in tracked files; logs redact sensitive values.
- [ ] Authentication/network failure is explicit and does not prevent offline game launch.
- [ ] User can disconnect/clear credentials using the OS credential store.

## Validation

- Test with mocked responses and no real credentials in CI.
- Do not use a real account in automated tests; validate target performance and service behavior separately.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Require a privacy/terms review before enabling any service integration.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
