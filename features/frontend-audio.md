# Feature: Frontend music and sounds

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can optionally enable or disable menu music and interface sounds without affecting in-game audio.

## Current state

No project-supported menu music or frontend sound configuration is documented.

## Scope

- Determine what the installed Pegasus version supports natively before adding code or dependencies.
- Define opt-in controls, volume/mute behavior, and lifecycle so audio stops when leaving Pegasus or starting a game.
- Keep music files user-provided or use assets with documented redistribution rights.

## Out of scope

- Always-on audio, network streaming, or audio changes to RetroArch/system settings.
- Committing copyrighted music or sound assets of unclear provenance.

## Acceptance criteria

- [ ] Feature is optional and disabled when unsupported or no permitted asset is configured.
- [ ] In-game audio is not altered; frontend audio stops at the documented lifecycle boundary.
- [ ] Missing devices/assets and playback errors are visible and do not block navigation.
- [ ] Asset source and license requirements are documented.

## Validation

- Test feature-off, missing asset/device, mute, and lifecycle behavior with a mock or permitted sample.
- Verify audio routing on the target desktop before claiming device support.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Do not access microphones, record audio, or transmit audio.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
