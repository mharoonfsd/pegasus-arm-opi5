# Feature: Bezels and visual profiles

- **Status:** Draft — not agent-ready
- **Related issue:** <maintainer adds issue link>
- **Platform scope:** 1280x720 Orange Pi 5 profile is current project context, not a universal display guarantee

## User outcome

Users can select compatible per-system/per-game artwork and visual profiles, including a low-resource profile that avoids disrupting gameplay.

## Current state

The README and installation brief describe historical Duimon Mega Bezel and Bezel Project art configuration. The project has not established a general profile manager or current on-device performance guarantee.

## Scope

- Separate artwork selection from shader/post-processing selection.
- Preserve a simple bezel/art-only choice and allow expensive reflections/effects to be disabled without deleting presets.
- Define profile ownership, precedence, failure behavior, and restoration.

## Out of scope

- Replacing GPU drivers, Mesa/Vulkan, display server, or system resolution.
- Bundling copyrighted artwork or shader packs without provenance and license review.
- Claiming stable 60 FPS from a static preset or spot benchmark.

## Acceptance criteria

- [ ] User/default profiles remain unchanged; profile switches are reversible and reported.
- [ ] Missing artwork/shader and failed live-switch cases leave the current game/configuration intact.
- [ ] A performance profile changes only documented settings and can be restored after cancellation or restart.
- [ ] Artwork and shader sources/licenses are documented and never downloaded from unverified locations.

## Validation

- Unit-test profile selection and restoration with synthetic configurations.
- Benchmark a game/core first shown to sustain 60 FPS without background work; compare representative frame-time intervals on the Orange Pi. A below-60-FPS baseline cannot validate a 60-FPS target.

## Safety, dependencies, and licensing

Follow the [task-spec template](TASK_SPEC_TEMPLATE.md). Do not delete source art, copy user data, or infer hardware compatibility from configuration.

## Copy-ready agent instruction

Implement only this brief. Read it, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, the installation brief, and the linked issue. Before editing, summarize the outcome, scope, risks, acceptance criteria, and exact tests, then wait for approval. Use a task-specific branch, preserve user data, and stop to present options if a suitable official ARM64 dependency is unavailable. Run the required CI checks and feature tests; report exact results and unverified hardware behavior. Do not commit, push, or merge.
