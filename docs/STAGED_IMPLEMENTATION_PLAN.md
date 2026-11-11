# Staged Implementation Plan — From Solo Project to Community Development

## 1. Objective

Move from a single-maintainer, AI-assisted project to a community-driven project where:

- contributors use their own AI subscriptions and computing resources;
- changes are developed in forks or authorized feature branches;
- AI-ready issues describe small, independently implementable tasks;
- trusted community maintainers review and merge contributions;
- the project owner retains responsibility for roadmap, licensing, funding and overall direction;
- the community can contribute code, tests, hardware, compute, documentation or money.

This plan is deliberately staged. Do not open every permission, automation or community channel on day one.

## 2. Stage 0 — Owner decisions and repository audit

**Goal:** establish the rules before inviting contributions.

Tasks:

1. Decide personal repository versus GitHub Organization. If multiple long-term maintainers are expected from the start, prefer an organization. Keep the owner as organization owner.
2. Choose the open-source licence after reviewing code and dependency provenance.
3. Audit third-party dependencies and assets: Pegasus, RetroArch, cores, themes, shaders, fonts, artwork, scripts and downloaded tools.
4. Check current Git history for secrets, credentials, ROMs, BIOS, saves, proprietary assets and private logs.
5. Reconcile the project status and parity tracker against current source and hardware evidence.
6. Define owner, core maintainer, area maintainer, triager and contributor roles.
7. Agree that trusted maintainers can approve/merge routine changes while the owner reserves fundamental policy decisions.

**Exit criteria:**

- Licence decision documented.
- No known sensitive files or secrets remain in the public history.
- Current README/status/known limitations match the implementation.
- The maintainer roles and approval policy are written down.

Do not announce a licence or claim open-source status until the licence is actually selected and committed.

## 3. Stage 1 — Public repository foundation

**Goal:** make the repository understandable and safe for an outside developer.

Tasks:

1. Add/refresh README, CONTRIBUTING, AGENTS and AI coding instructions.
2. Add issue forms for bugs, feature requests, AI-ready tasks and hardware reports.
3. Add PR template.
4. Add SECURITY and Code of Conduct documents.
5. Add labels and a GitHub Projects board.
6. Enable Discussions if moderation capacity exists.
7. Protect the default branch.
8. Set least-privilege Actions permissions and add basic host-side CI.
9. Add funding policy and real funding links only after their payout path is verified.

**Exit criteria:**

- Someone new can understand the project and its present limitations.
- Someone can open a useful issue or PR without private maintainer guidance.
- `main` cannot be changed by a direct push from ordinary contributors.
- Untrusted PR workflows run without secrets and without accessing private hardware.

## 4. Stage 2 — Create the first AI-ready backlog

**Goal:** prove that work can be completed by external contributors without the owner designing every step.

Start with 5–10 small, independent tasks. Do not label a task `agent-ready` until it has:

- clear user outcome;
- current and desired behaviour;
- affected component or instruction to inspect it;
- in-scope and out-of-scope boundaries;
- acceptance criteria;
- expected automated and hardware tests;
- dependency and licensing notes where relevant.

Good initial task categories:

- documentation improvements;
- unit tests for recursive ROM discovery;
- metadata parser edge cases;
- path-with-spaces handling;
- error messages for missing library or BIOS;
- one isolated emulator launch integration;
- a hardware test checklist;
- installer preflight diagnostics.

Avoid assigning high-risk installer rewrites or security changes to an untested first-time contributor.

**Exit criteria:**

- At least five well-scoped issues are ready.
- One sample issue has been completed by a contributor in a fork.
- The first external PR has passed the documented review and test process.

## 5. Stage 3 — Small trusted maintainer pilot

**Goal:** delegate review and routine integration safely.

Recruit a small initial group based on demonstrated work, not promises or donation amount.

Suggested initial roles:

- Project owner: overall direction, policy, funding, releases and security.
- One installer/system maintainer: reviews shell scripts, dependencies and system changes.
- One emulator/integration maintainer: reviews cores, launch commands and system configs.
- One community triager: labels and organizes issues/Discussions.

One person may hold more than one responsibility initially.

Process:

1. Start with Triage permission for issue/community work.
2. Grant Maintain permission only when code review/integration responsibility is established.
3. Use CODEOWNERS for high-risk or separate code areas.
4. Require trusted maintainers to use 2FA and protect their accounts.
5. Keep organization-owner/Admin access restricted.
6. Review permissions regularly.

**Exit criteria:**

- At least one trusted maintainer can review and merge a routine PR.
- The owner is not required to handle every label, duplicate issue and documentation PR.
- Critical settings and release permissions remain restricted.

## 6. Stage 4 — Community hardware and compute programme

**Goal:** obtain wider test coverage without creating unsafe shared execution infrastructure.

Publish a short test programme for:

- clean install;
- repeated install/update;
- Pegasus startup and exit;
- controller navigation;
- supported game launch;
- metadata/artwork generation;
- save/load;
- graphics and performance notes.

Ask volunteers to run tests on their own hardware and submit a structured report. Provide test commands that do not upload ROMs, BIOS, save files or credentials.

Accept:
- temporary hardware loans;
- hardware donations;
- local testing time;
- controlled cloud credits or a volunteer-run test;
- AI implementation using contributor-owned subscriptions.

Do not run untrusted public PRs on volunteer self-hosted Actions runners. Use GitHub-hosted CI for normal public PRs and independent hardware reports for ARM64 testing.

**Exit criteria:**

- A documented hardware test matrix exists.
- At least one external tester has submitted a reproducible report.
- Test results identify exact board, OS, kernel, graphics stack, emulator/core and test outcome.

## 7. Stage 5 — Development Preview and community onboarding

**Goal:** open participation while being honest about experimental status.

Publish:

- source repository and licence;
- current installation instructions;
- supported/experimental/unsupported system matrix;
- known issues;
- development roadmap;
- AI contribution instructions;
- funding and non-financial contribution options.

Use a clear status such as **Development Preview**. Do not market it as a complete RetroBat replacement.

Measure:
- external issue quality;
- time to first PR;
- PR review cycle;
- CI pass rate;
- number of independently reproduced tests;
- number of systems with actual game-launch evidence;
- number of contributors returning for a second contribution.

## 8. Stage 6 — Public Alpha and active fundraising

**Goal:** invite broader usage and recurring support when the project can demonstrate a dependable limited experience.

The previously discussed 45% weighted parity target is a planning signal, not the release gate by itself.

Suggested Alpha gate:

- clean install validated on the target Orange Pi 5 Ubuntu ARM64 environment;
- Pegasus launches and exits correctly;
- at least 4–5 selected systems have a real game launch test;
- controller-driven browse/launch/menu/exit flow works;
- library and metadata handling are documented;
- missing ROM/BIOS/library errors are understandable;
- installer repeatability and backup/recovery path are validated;
- at least one external tester has reproduced the basic workflow;
- known limitations are published.

At this point, invite financial contributions and explain that they may support development subscriptions, project expenses and the maintainer's livelihood. Do not sell guaranteed support or features.

## 9. Stage 7 — Public Beta and broader delegation

**Goal:** grow the contributor base without losing quality.

Tasks:

- recruit additional area maintainers only after reviewing contribution history;
- expand the supported system matrix based on hardware evidence;
- improve per-system and per-game configuration;
- strengthen BIOS checks, controllers, saves and library interoperability;
- improve release automation and recovery;
- publish test results from more than one ARM64 hardware configuration if claiming broader support;
- create a regular but sustainable progress update.

Possible beta gate:

- most priority systems have documented launch status;
- installation and update processes are reproducible;
- controller and save behaviour have meaningful test coverage;
- common failures have troubleshooting instructions;
- maintainers can handle routine PRs without the owner being involved in every change.

## 10. Stage 8 — Sustainable project operations

**Goal:** make the project resilient to the owner's availability.

- Document release process and maintainer responsibilities.
- Maintain at least two people who understand critical installer/release procedures, while keeping owner permissions restricted.
- Keep funding income and project expenses recorded.
- Publish periodic summary of completed work and current priorities.
- Maintain a tested recovery/backup process.
- Rotate or review privileged access.
- Avoid relying on one person's paid AI subscription for every contribution.
- Avoid promising fixed release cadence or support SLA unless capacity exists.

## 11. Suggested first 30-day execution sequence

This is a task sequence, not a promise of calendar completion.

### First batch: foundation
- Audit current code, dependencies and Git history.
- Decide licence and repository location.
- Reconcile status and tracker.
- Add governance and contribution documents.
- Configure branch protection and minimum CI.

### Second batch: contribution workflow
- Create labels and Projects board.
- Add issue and PR templates.
- Write 5–10 agent-ready tasks.
- Test the process with one external fork/PR.
- Fix unclear instructions or over-large issue scope.

### Third batch: trusted pilot
- Identify 1–3 prospective maintainers/moderators.
- Start with least privilege.
- Agree on review areas and escalation policy.
- Merge routine PRs through the protected workflow.

### Fourth batch: external validation
- Publish hardware test procedures.
- Recruit a small number of ARM64 testers.
- Gather reproducible test evidence.
- Update supported system matrix.
- Decide whether the project is ready for a Development Preview announcement.

## 12. Go/no-go gates

| Gate | Go when | Do not proceed when |
|---|---|---|
| Public repository | Licence, dependency audit, README, known limitations are ready | Secret/proprietary content or unclear code rights remain |
| AI contribution pilot | Agent instructions, fork workflow, PR template and CI exist | Agents are being asked to work directly in upstream main |
| Trusted maintainers | Person has demonstrated judgement and review quality | Access is granted solely due to enthusiasm or donations |
| Hardware programme | Tests are documented and safe | Volunteers are asked to share passwords or unrestricted remote access |
| Alpha fundraising | Basic workflow is independently reproducible | The project only works on the maintainer's configured machine |
| Beta | Broader support and maintenance paths are demonstrated | Many systems are marked supported based only on metadata/configuration |

## 13. What success looks like

The mature operating model is not one where the project owner writes all features. It is one where:

- issues are clear enough for contributors and AI agents to work independently;
- contributors can fork and submit code without needing upstream permission;
- tests and human review protect the upstream repository;
- trusted maintainers can integrate ordinary work;
- hardware volunteers increase the tested compatibility matrix;
- people who cannot donate money still have meaningful ways to help;
- financial contributions sustain the maintainer and development tools without creating paywalls or unrealistic promises.
