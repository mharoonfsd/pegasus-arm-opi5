# Feature: Gameplay recording

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>

## User outcome

Users can explicitly record gameplay where the emulator supports it and control storage, quality, and resource impact.

## Current state

No project-managed capture workflow or Orange Pi performance baseline is established.

## Scope

- Determine supported capture APIs and hardware/software encoder availability without changing system graphics drivers.
- Make capture opt-in with visible recording state, destination, stop control, and conservative defaults.
- Report storage and performance requirements before starting.

## Out of scope

- Background recording by default, streaming, or capturing desktop/user activity outside gameplay.
- Installing unverified codecs or changing Mesa/Vulkan/kernel configuration.

## Acceptance criteria

- [ ] Capture scope is limited to the selected game and is visibly active.
- [ ] User chooses/approves output location; failures and disk-space constraints are reported.
- [ ] Capture stops reliably when requested or when the game exits.
- [ ] No capture path is described as supported until measured on the target board.

## Validation

- Test control/lifecycle and output handling with synthetic or mock sources.
- If implementation proceeds, measure game performance and resource use on Orange Pi; do not claim stable 60 FPS without representative evidence.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Do not record or transmit content without explicit user action.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
