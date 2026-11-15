# Feature: Pegasus AI development mode

- **Status:** Draft — not agent-ready; feasibility spike required before implementation
- **Related issue:** <maintainer adds issue link>
- **Platform scope:** Orange Pi 5 / Ubuntu ARM64

## User outcome

When kiosk mode is off, a contributor can choose a maintainer-approved feature brief inside Pegasus, start a background AI-assisted development task, inspect its progress, and later review the resulting changes. Ordinary users in kiosk mode do not see or access Developer Mode.

## Current state

No AI development worker or task picker is implemented. Feature briefs in this catalog are drafts until maintainer triage. The existing Pegasus/RetroArch scripts do not prove that a persistent background worker can coexist with gameplay.

## Scope

- Add a Developer Mode entry inside Pegasus only when kiosk mode is disabled; do not create a separate launcher/companion in v1.
- Read only maintainer-approved task briefs from the contributor's local project clone. Before work starts, show the selected brief's goal, scope, tests, provider/cost information, and generated implementation plan; require explicit user approval.
- Show job state, errors, pause/resume/cancel controls, and a reviewable result in Pegasus when the contributor returns from a game.
- Choose one AI provider only after comparing cost, privacy, ARM64-compatible access, and availability. Keep credentials in the OS credential store, never in the repository, command history, logs, or generated files.
- Start a task from Pegasus before launching a game. Do not support starting a new task from inside an active game in v1: the contributor returns to Pegasus (ending the game), starts the task, then may relaunch a game. An already-running job may continue across game sessions.
- Run work in an isolated Git worktree/task branch with least privilege. Never auto-commit, push, or merge. Require user approval for commands outside a narrow documented allowlist; show the diff and tests for human review.
- Deny the worker access to ROM, BIOS/firmware, saves, scraped media, and private configuration by default. Give it only the repository/task context and synthetic fixtures it needs.
- Gate persistent background work on a feasibility spike measuring CPU, memory, storage, network/API cost, and gameplay frame pacing on the Orange Pi.
- While a job is active, use a reversible low-resource graphics profile: retain static Bezel Project artwork; first disable expensive Mega Bezel reflections/post-processing; disable shaders entirely only if measurements justify it. Attempt a live RetroArch switch; if it fails, leave the running game untouched and apply the profile on its next launch. Restore the original profile when work ends or is cancelled.
- Throttle local tests/builds during gameplay; pause or defer them if the 60 FPS target cannot be maintained.
- Preserve the retired no-HUD/no-persistent-polling behavior; use low-overhead event/status updates and add an opt-in HUD only if a measured need and explicit approval justify it.

## Out of scope

- A separate interactive desktop launcher, initiating new development from inside an active game, or opening kiosk mode automatically.
- Multi-provider abstraction in the first version.
- Unreviewed code execution, automatic commit/push/merge, or changes to the host OS, kernel, bootloader, desktop, graphics drivers, Mesa/Vulkan, or package sources.
- Treating AI output or scanner output as safe without human review.

## Acceptance criteria

- [ ] Developer Mode is unavailable when kiosk mode is enabled and reachable only through Pegasus when disabled.
- [ ] A test with kiosk mode enabled confirms no Developer Mode UI or keyboard/controller route is available; with kiosk mode off, the entry is reachable in Pegasus.
- [ ] A job preview shows the selected approved brief, scope, tests, provider/cost/privacy information, and implementation plan; no worker starts until the user approves.
- [ ] A new job can be selected and started before gameplay; no in-game new-task entry is exposed in v1; an existing job can resume across game sessions and its state/results are visible on return to Pegasus.
- [ ] Provider, cost/privacy trade-offs, credential-store integration, usage limits, pause/cancel/restart behavior, and error states are documented before implementation.
- [ ] A job cannot modify the main worktree, commit, push, merge, or run unapproved commands.
- [ ] The worker cannot read game/data paths or credentials unless a separately approved task explicitly needs a safe fixture.
- [ ] Cancellation, worker failure, and app restart preserve user changes and restore the original graphics profile.
- [ ] On a title/core that first sustains 60 FPS with the agent off, representative concurrent work maintains stable 60 FPS. Record a repeatable gameplay segment, frame timing/FPS, responsiveness, and measurable CPU/RAM/GPU use. A game/core whose baseline cadence is below 60 FPS is not a valid test fixture.
- [ ] If the target cannot meet the measured performance or resource limits, keep the worker disabled/deferred during gameplay and report the limitation; do not claim concurrent support.

## Validation

- First deliver a documented feasibility spike; do not implement a persistent worker until the user approves the provider and resource/performance results.
- Test kiosk gating, task preview/approval, job lifecycle/status, credentials, worktree isolation, inaccessible game-data paths, pause/cancel/resume, app restart, and graphics rollback with mocks/fixtures before any live AI call.
- Do not put credentials, ROMs, BIOS, saves, scraped media, or private logs in the test fixture or repository.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). The human contributor owns review of generated changes. AI access and network egress must be explicit, bounded, and user-visible.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Do not implement a persistent worker before the contributor approves a provider and the feasibility spike meets the documented performance and safety gates. Use a task-specific branch, preserve user data, and stop to present options if an official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
