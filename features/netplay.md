# Feature: Netplay

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can start network play only for a verified native core/emulator combination and understand its network and compatibility requirements.

## Current state

The project has no verified Orange Pi netplay support or documented network-play UX.

## Scope

- Identify officially supported netplay modes, core/version matching, latency requirements, firewall behavior, and privacy implications.
- Make host/join actions explicit and restrict network behavior to the selected session.
- Provide a clear offline path and stop/disconnect control.

## Out of scope

- Opening ports or changing firewall/router settings automatically.
- Relay services, account systems, or public matchmaking without separate review.

## Acceptance criteria

- [ ] Supported combinations and known constraints are documented from official sources.
- [ ] No network listener starts until the user explicitly starts a session.
- [ ] Connection errors and disconnect behavior are actionable and safe.
- [ ] Network traffic and any external service are disclosed; no library scan/upload occurs.

## Validation

- Test protocol/UX logic with mocks; do not start public listeners in CI.
- Verify a controlled local network session on supported hardware before making compatibility claims.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Network and firewall changes require explicit user approval.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
