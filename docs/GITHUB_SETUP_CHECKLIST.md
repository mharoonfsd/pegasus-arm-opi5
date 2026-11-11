# GitHub Setup Checklist — Community-Driven AI Development

This checklist is for the repository owner. Perform settings changes manually in GitHub and verify each one. The checklist does not assume the repository URL, owner name, default branch or funding provider.

## A. Before making the repository public

- [ ] Confirm repository name, description, topics and social preview image.
- [ ] Choose whether the repository remains under a personal account or is created under a GitHub Organization.
- [ ] If using an organization, keep organization ownership limited to the project owner and only essential recovery/trust partners.
- [ ] Select an open-source licence after reviewing code provenance and third-party dependencies. Do not publish a placeholder licence.
- [ ] Audit Pegasus, RetroArch, libretro cores, themes, shaders, fonts, artwork, scripts and other third-party dependencies.
- [ ] Add third-party notices and attribution where required.
- [ ] Remove secrets, tokens, passwords, private paths, personal logs and local configuration from the working tree and Git history where necessary.
- [ ] Confirm no ROMs, commercial BIOS/firmware, game saves or scraped media are committed.
- [ ] Review `.gitignore`.
- [ ] Reconcile `PROJECT_STATUS.md` with the actual repository and current Orange Pi test evidence.
- [ ] Publish known limitations and hardware scope.
- [ ] Add `README.md`, `CONTRIBUTING.md`, `AGENTS.md`, `FUNDING.md`, security reporting instructions and a code of conduct.
- [ ] Decide whether to enable GitHub Discussions.
- [ ] Create the first release milestone or Development Preview tag only after a reproducible install path is documented.

## B. Repository identity and community features

In **Settings → General** (labels may change):

- [ ] Set the default branch to `main` (or document the chosen name).
- [ ] Set a concise description, website and relevant topics, for example `arm64`, `orange-pi-5`, `pegasus-frontend`, `retro-gaming`, `retroarch`, `ubuntu`.
- [ ] Enable Issues.
- [ ] Enable Discussions if there is capacity to moderate them.
- [ ] Enable Projects or create a repository-level project board.
- [ ] Enable Sponsorships only after the funding destination is verified.
- [ ] Add a social preview image that does not use unlicensed third-party artwork.

Suggested Discussions categories:

- Announcements (maintainers only can start announcement posts);
- Q&A;
- General;
- Ideas and design proposals;
- Hardware testing / Show and tell;
- Help and troubleshooting.

Keep reproducible bugs in Issues, not Discussions.

## C. People and access

### Recommended access model

| Person | Recommended access | Notes |
|---|---|---|
| Project owner | Organization Owner or repository Admin | Retain control of critical settings and ownership |
| Trusted core maintainer | Repository Maintain | Can help manage the repository without broad organization ownership |
| Area maintainer | Maintain where needed, otherwise Write | Use CODEOWNERS and clear scope |
| Issue/community moderator | Triage | Can organize issues/PRs without pushing code |
| Ordinary contributor | No upstream collaborator role | Fork and pull request |
| AI agent | No separate GitHub account/role | Operates through the human contributor's fork/workspace |

Checklist:

- [ ] Require 2FA for the organization and privileged maintainers.
- [ ] Use passkeys or hardware security keys where available.
- [ ] Add trusted maintainers gradually after observing review quality and reliability.
- [ ] Do not grant Admin/Organization Owner just to let someone review or merge PRs.
- [ ] Review access quarterly and remove access when no longer required.
- [ ] Keep at least one well-protected owner account and a tested recovery method.
- [ ] Never share a maintainer's personal access token with contributors or agents.

If the project remains in a personal repository, check which roles are available for that repository type. If it moves to an organization, GitHub's `Triage`, `Write` and `Maintain` roles provide more granular access.

## D. Protect `main`

Use **Settings → Rules → Rulesets** or **Settings → Branches**. Rulesets allow a clear branch policy; GitHub's interface and available features can vary by plan and repository type.

Create a branch ruleset targeting `main`:

- [ ] Enforcement status: Active.
- [ ] Require a pull request before merging.
- [ ] Require at least 1 approving review for routine changes.
- [ ] Dismiss stale approvals when new commits are pushed, or require approval of the most recent reviewable push.
- [ ] Require conversation resolution.
- [ ] Require the configured CI status checks.
- [ ] Require Code Owner review for owned paths, where suitable.
- [ ] Block force pushes.
- [ ] Block branch deletion.
- [ ] Do not allow ordinary contributors to bypass.
- [ ] Keep bypass access limited to a documented emergency procedure; preferably do not create routine bypass actors.
- [ ] Do not let a PR author approve their own PR.
- [ ] Require a human maintainer review; CI and AI review are not substitutes.

For high-risk changes (installer, workflows, security, dependencies, permissions, release process, user-data changes), adopt a project policy of two human reviews where practical. GitHub's CODEOWNERS requirement alone can be satisfied by any one listed code owner; it does not mean all owners must approve.

## E. CODEOWNERS

Add `.github/CODEOWNERS` after you know actual GitHub usernames or teams. Do not commit placeholder usernames.

Example only — replace every placeholder and adjust paths to the real repository:

```text
# Project owner reviews repository policy and configuration.
/.github/              @PROJECT_OWNER
/AGENTS.md             @PROJECT_OWNER
/LICENSE               @PROJECT_OWNER
/FUNDING.md            @PROJECT_OWNER

# High-risk installation code.
/scripts/              @PROJECT_OWNER @INSTALLER_MAINTAINER

# Emulator and launch integration.
/emulators/             @EMULATOR_MAINTAINER
/config/                @EMULATOR_MAINTAINER

# Documentation.
/docs/                  @DOCS_MAINTAINER
```

Rules:

- [ ] Confirm all owners exist and have sufficient repository permission.
- [ ] Protect the CODEOWNERS file itself.
- [ ] Keep ownership areas small and accurate.
- [ ] Enable “Require review from Code Owners” in the branch rule if using this mechanism.
- [ ] Revisit ownership when maintainers change.

GitHub only uses a CODEOWNERS file from the PR's base branch when requesting reviews. Keep it in the default branch.

## F. GitHub Actions and CI security

- [ ] Set default workflow `GITHUB_TOKEN` permissions to read-only.
- [ ] Add explicit least-privilege `permissions:` to every workflow/job.
- [ ] Use `pull_request` for untrusted fork PR validation.
- [ ] Do not use `pull_request_target` to check out and execute fork-controlled code.
- [ ] Do not expose repository secrets to fork PRs.
- [ ] Use GitHub-hosted runners for ordinary public PR CI.
- [ ] Do not connect always-on self-hosted runners to public fork PR workflows.
- [ ] Pin third-party Actions to full commit SHAs where practical; review upgrades.
- [ ] Restrict which Actions can be used if the repository's security posture warrants it.
- [ ] Avoid broad `contents: write`, `packages: write` or `pull-requests: write` permissions in test workflows.
- [ ] Keep release publishing in a separate trusted workflow triggered only from protected tags or a maintainer-approved release process.
- [ ] Do not store developer AI keys or personal cloud credentials as repository secrets.
- [ ] Enable Dependabot alerts/security updates where available.
- [ ] Enable secret scanning/push protection and code scanning where available for the plan and language mix.
- [ ] Add a `SECURITY.md` explaining how to report vulnerabilities privately.
- [ ] Review workflow changes as high-risk code.

Recommended minimal workflow permissions for a basic test workflow:

```yaml
permissions:
  contents: read
```

A specific workflow may need additional permissions, but add only what that workflow requires.

## G. Issues, labels and templates

Create labels:

| Label | Purpose |
|---|---|
| `agent-ready` | Requirements are sufficiently clear for an AI agent |
| `good first issue` | Good first task for new contributors |
| `help wanted` | Maintainer invites community help |
| `needs-triage` | Not yet classified |
| `needs-hardware` | Requires physical device/controller testing |
| `needs-reproduction` | Bug report lacks a reliable reproduction |
| `security` | Security-sensitive; restricted discussion as appropriate |
| `installer` | Installer/configuration |
| `frontend` | Pegasus/frontend |
| `emulator` | Emulator/core integration |
| `metadata` | ROM discovery, metadata, scraping/media |
| `controller` | Input/controller |
| `docs` | Documentation |
| `compute` | Hardware/compute testing contribution |
| `blocked` | External dependency or unresolved issue |
| `P0` / `P1` / `P2` / `P3` | Priority |

Templates to enable:

- [ ] Bug report.
- [ ] Feature request.
- [ ] AI-ready task.
- [ ] Hardware test report.
- [ ] Pull request template.

An issue should receive `agent-ready` only after a maintainer has written scope boundaries, acceptance criteria and test expectations.

## H. GitHub Projects board

Create one board with these fields:

| Field | Suggested values |
|---|---|
| Status | Inbox, Needs triage, Ready, In progress, PR review, Needs hardware test, Done, Blocked |
| Priority | P0, P1, P2, P3 |
| Area | Installer, Pegasus UI, RetroArch, Emulator, Metadata, Controller, Graphics, Docs, CI/Security |
| Contribution type | Code, AI-assisted, Hardware test, Compute, Docs, Design |
| Hardware required | None, Orange Pi 5, Other ARM64, Controller, Display/audio |
| Difficulty | Small, Medium, Large, Research |
| Milestone | Preview, Alpha, Beta, Stable |
| Parity weight | Existing tracker weight, if applicable |

Create views:

1. **Roadmap:** group by milestone.
2. **Agent-ready tasks:** filter label `agent-ready` and status Ready.
3. **Hardware validation:** filter `needs-hardware`.
4. **PR review:** open PRs awaiting maintainer review.
5. **Backlog:** unstarted issues grouped by priority.

Avoid duplicating the entire weighted feature tracker in Projects. Projects tracks execution; the parity tracker measures product breadth.

## I. Funding and non-financial support

- [ ] Publish the funding policy with clear statement that support may cover AI subscriptions, project costs and maintainer livelihood.
- [ ] Verify platform eligibility and successful payout setup before publishing a link.
- [ ] Add `.github/FUNDING.yml` only with real, verified funding destinations.
- [ ] Explain that donation is optional and does not buy access, project control or guaranteed feature delivery.
- [ ] Provide non-financial contribution routes: AI-assisted PR, hardware testing, documentation, compute/testing.
- [ ] Keep private records of contributions, platform fees and expenses.
- [ ] Do not describe personal project support as tax-deductible charity without legal basis.

## J. Release process

- [ ] Use a clear versioning convention, e.g. `0.x.y` during development.
- [ ] Keep release notes with Added, Changed, Fixed, Known limitations and Tested hardware.
- [ ] Tag only commits on protected `main`.
- [ ] Separate build/test workflows from release publishing.
- [ ] Generate checksums for released binaries/packages.
- [ ] Include source commit, build environment, dependency versions and known test gaps.
- [ ] Avoid claiming broad ARM64 support based on a single Orange Pi 5 test.

## K. Final readiness review

- [ ] A new user can find install instructions.
- [ ] A new contributor can find an `agent-ready` task.
- [ ] A contributor can fork and open a PR without upstream write access.
- [ ] An AI agent receives clear repository rules.
- [ ] PRs cannot bypass required human review and tests.
- [ ] Public fork code cannot access upstream secrets or a maintainer's hardware runner.
- [ ] A hardware tester can submit a repeatable report.
- [ ] A supporter can contribute financially or non-financially.
- [ ] The project status reflects tested facts, not aspirational support.
