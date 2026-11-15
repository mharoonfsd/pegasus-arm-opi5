# Feature: <name>

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>
- **Platform scope:** <if applicable>

Before a maintainer marks this brief agent-ready, fill in the linked issue, current implementation evidence, required dependencies/licenses, and exact feature-specific host/device validation commands. Do not use a generic "works on Orange Pi" claim in place of a reproducible test.

## User outcome

<Describe one observable user problem and the expected outcome.>

## Current state

<Cite the relevant code/docs and distinguish verified behavior from assumptions. State whether the current behavior is tested, historical, partial, absent, or unknown.>

## Scope

- <Focused behavior to implement>

## Out of scope

- <Adjacent work that must remain separate>

## Acceptance criteria

- [ ] <Observable, testable requirement>
- [ ] Errors are explicit and identify a safe next step; no success-shaped fallback.
- [ ] Existing user data and configuration are preserved unless the user explicitly approves a change.
- [ ] User-facing documentation and rollback instructions are updated where needed.

## Validation

- From the repository root, run `bash -n scripts/install-pegasus.sh` and run the Python parse check and all required scanner jobs documented in [`CONTRIBUTING.md`](../CONTRIBUTING.md) and [the CI workflow](../.github/workflows/ci.yml).
- <Add the exact feature-specific host test command and fixture location before marking this brief agent-ready.>
- <Hardware-only validation, if required: give the exact board/OS/core/game, launch command, test segment, and measurable expected result.>
- Do not infer Orange Pi compatibility from a successful build or a different device.

## Safety, dependencies, and licensing

- Keep all changes native to Linux/ARM64; do not use Wine, Box64, x86 emulation, or x86-only binaries.
- Do not move, rename, delete, or copy ROMs, BIOS/firmware, saves, or scraped media.
- Verify official upstream availability and ARM64 support before selecting binaries or dependencies. If a suitable official build is unavailable, stop and present the user with the supported options; do not silently substitute an untrusted build.
- Document source, version, checksum/signature, license, and rollback for new tools, packages, or assets.
- Never add credentials, user data, proprietary game assets, or private logs.

## Implementation notes

- Inspect the relevant project instructions, README, project status, installation brief, and linked issue before editing.
- Use a task-specific branch. Keep the patch focused; do not auto-commit, push, or merge.
- Report exactly what was tested and what remains unverified.

## Copy-ready agent instruction

Implement only this brief. Read it, [`AGENTS.md`](../AGENTS.md), [`README.md`](../README.md), [`CONTRIBUTING.md`](../CONTRIBUTING.md), [`docs/PROJECT_STATUS.md`](../docs/PROJECT_STATUS.md), [`docs/orange_pi_5_pegasus_installation_brief.md`](../docs/orange_pi_5_pegasus_installation_brief.md), and the linked issue. Before editing, summarize the user outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch. Preserve user data; use synthetic fixtures unless access to specific user data is explicitly approved. Do not add ROMs, BIOS/firmware, saves, scraped media, credentials, or private logs. If a suitable official native ARM64 dependency is unavailable, stop and present the user with options. Run relevant CI checks and the feature-specific tests, report exact results and unverified hardware behavior, and do not commit, push, or merge.
