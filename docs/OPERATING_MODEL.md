# Operating Model — Community-Driven AI Development

**Status:** Proposed operating policy. Adopt and tailor before public launch.

## 1. Mission and operating principle

The project is developed by a distributed community. Contributors bring their own AI coding tools, subscriptions, computers and expertise. They work in personal forks or authorized feature branches. The upstream repository is the integration point and is protected by human review.

The project owner sets the product direction and remains accountable for the repository. Trusted community maintainers help review, approve and merge changes within delegated responsibilities.

**AI agents are development tools, not project members.** They do not receive repository roles, secrets, merge authority or independent decision rights. A human contributor is responsible for every submission made from their fork.

## 2. Roles and permissions

| Role | Who | GitHub access | Responsibilities | Limits |
|---|---|---|---|---|
| Project owner / lead maintainer | Original project owner | Organization owner or repository Admin | Vision, roadmap, funding, appointing/removing maintainers, final policy decisions, release direction, security escalation | Keep account protected with 2FA/passkeys and recovery methods |
| Core maintainer | Trusted, established community member | Prefer repository `Maintain` role in an organization | Review/approve/merge normal PRs, triage work, maintain assigned modules, coordinate releases when delegated | No organization-owner/Admin access unless separately justified |
| Area maintainer / code owner | Trusted contributor responsible for a subsystem | Repository `Maintain` or suitable write-capable role | Reviews changes in assigned areas such as installer, emulator integration, metadata, docs or CI | Authority limited to assigned area; cannot override global policy |
| Community moderator / triager | Trusted helper who manages community flow | `Triage` role | Label issues, reproduce bugs, organize Discussions, request missing information, close duplicates | Cannot push code or merge changes |
| Contributor | Anyone, including AI-assisted contributor | No upstream write permission; works in own fork | Opens issues, develops changes, tests, submits PRs | No direct push to upstream protected branches |
| AI coding agent | Tool operated by a human contributor | No independent upstream role or secret access | Researches, plans, edits and tests within the contributor's fork/workspace | Cannot approve/merge, publish releases, change settings, access upstream secrets or run privileged workflows |

GitHub describes `Triage` as suitable for issue/PR management without write access and `Maintain` as suitable for repository management without sensitive/destructive actions. Use least privilege and verify the exact permission matrix for the repository's hosting arrangement before assigning roles.

### Personal repository or GitHub Organization?

- **Personal repository:** simplest for an initial solo project. The owner remains the account owner. Add only a very small number of trusted collaborators.
- **Organization repository:** preferable once there are multiple long-term maintainers, area ownership, moderation teams or a shared community identity. It supports clearer team-based access and project continuity.

Recommended path: if the repository has not yet been published and you already expect multiple trusted maintainers, consider creating a GitHub Organization before launch. Keep yourself as the organization owner. Give ordinary trusted maintainers the repository `Maintain` role, not organization-owner rights. Add a second organization owner only when there is a strong continuity/recovery reason and that person is fully trusted.

## 3. Decision rights

| Decision | Contributor | Area maintainer | Core maintainer | Project owner |
|---|---:|---:|---:|---:|
| Suggest a feature | Yes | Yes | Yes | Yes |
| Implement in a fork | Yes | Yes | Yes | Yes |
| Approve routine PR in owned area | No | Yes, if delegated | Yes | Yes |
| Merge routine PR | No | Yes, if delegated and branch rules pass | Yes | Yes |
| Approve installer/security/workflow changes | No | Only if explicitly assigned | Yes, with second review for high-risk changes | Yes |
| Change project roadmap priority | Suggest | Recommend | Recommend | Decide with maintainer consultation |
| Change project licence or funding policy | Suggest | No | Recommend | Decide |
| Create/delete repository, change secrets or branch protections | No | No | No by default | Owner/Admin only |
| Publish official release | No | Only if explicitly delegated | Yes, if delegated | Accountable; may reserve release approval |

The owner's authority over fundamental project policy does not mean every routine pull request must wait for the owner. Trusted maintainers should be able to merge ordinary, well-tested changes within the rules.

## 4. Review and approval policy

Use a proportionate policy:

### Routine, low-risk changes

Examples: documentation correction, test addition, isolated metadata improvement.

- One approval from a trusted maintainer or relevant area maintainer.
- Required CI checks pass.
- All review conversations resolved.
- The author is not the approving reviewer for their own change.

### Normal feature changes

Examples: a new emulator integration, a frontend feature, a metadata generator change.

- One maintainer approval, preferably from the affected area.
- Relevant automated tests pass.
- Hardware-only validation is either completed or explicitly recorded as outstanding.
- Documentation and status tracking are updated.

### High-risk changes

Examples:

- Installer, backup, restore, uninstall or filesystem handling;
- `.github/workflows/`, release automation or permissions;
- dependency download/execution, privilege escalation or network access;
- security controls, authentication, telemetry or secret handling;
- project licence, third-party assets or funding destinations;
- changes that could modify or delete ROMs, BIOS, saves or user configuration.

Require two human maintainer reviews where practical, including the relevant code owner. At least one reviewer should be independent of the author and the last person to push changes. If two reviewers are unavailable, the PR must be explicitly marked as an exception and approved by the project owner; do not quietly weaken the standard.

GitHub's ordinary CODEOWNERS requirement can require an approval from a code owner, but listing multiple owners does not automatically require every listed owner to approve. Use the review policy and branch settings deliberately.

## 5. Repository as the source of truth

Use GitHub components for distinct purposes:

| Component | Purpose |
|---|---|
| Repository | Source code, tests, docs, scripts and release history |
| Issues | Bugs, feature requests, agent-ready tasks and hardware tests |
| Projects | Roadmap, status, priority, ownership and milestones |
| Pull requests | Reviewable proposed changes |
| Actions | Safe, repeatable CI on untrusted and trusted code according to separate permissions |
| Discussions | Questions, design conversations, community support and show-and-tell |
| Releases | Versioned, tested public distributions |
| Funding links | Voluntary financial support |
| `CONTRIBUTING.md` | Human contribution rules |
| `AGENTS.md` | Common instructions for coding agents |

Do not use Discussions as a substitute for bug tracking. Convert reproducible defects into Issues.

## 6. Standard issue-to-merge lifecycle

1. **Intake:** a person opens a bug, feature, documentation or hardware-test issue.
2. **Triage:** a triager or maintainer checks for duplication, scope, reproduction and impact.
3. **Readiness:** a maintainer defines acceptance criteria, labels priority/area and, if sufficiently bounded, adds `agent-ready`.
4. **Claim:** a contributor comments that they are working on the issue. Avoid exclusive ownership for long periods; ask for a progress update or release the task if inactive.
5. **Development:** contributor forks the repository, runs an AI agent in the fork, inspects the diff and performs available tests.
6. **PR:** contributor submits one focused PR linked to the issue.
7. **Automated checks:** CI performs safe static and host-side tests.
8. **Human review:** the appropriate maintainer checks correctness, scope, provenance, licensing, user-data safety and hardware evidence.
9. **Validation:** if physical hardware is required, a named tester runs a reproducible procedure.
10. **Merge:** an authorized maintainer merges only after required reviews and checks pass.
11. **Closeout:** update status, tracker, documentation and release notes if applicable.

## 7. AI contribution boundary

Contributors use their own Copilot/Codex/Claude/other AI subscriptions and their own compute. They do not need the project's API keys or credentials.

Agents must:
- work only in the contributor's fork or authorized branch;
- read `AGENTS.md` and relevant docs;
- plan before editing;
- implement the issue's scope only;
- run tests and report exactly what was tested;
- update docs when behaviour changes;
- never merge, release or alter repository settings;
- never include ROMs, BIOS, saves, private logs or credentials.

The human submitting the PR is responsible for reviewing the output and being able to explain the change.

## 8. Hardware and compute contribution model

Treat these as separate contribution routes:

- **Local hardware validation:** volunteer runs a documented test on their own board and submits results.
- **Hardware loan or donation:** board, controller, storage or display is loaned or donated with clear ownership/return terms.
- **Cloud/compute support:** contributor provides a controlled credit grant or runs a specific test in their own environment.
- **AI development capacity:** contributor uses their own AI subscription and submits the resulting PR.

Do not collect passwords, cloud account access or unrestricted remote access to a volunteer's machine. Do not run untrusted public fork code on always-on volunteer self-hosted runners. See `COMPUTE_CONTRIBUTIONS.md`.

## 9. Conflict resolution and project direction

- Discuss technical disagreements in the PR or a linked design issue.
- Prefer documented evidence, target-hardware tests and maintainability over personal preference.
- If maintainers disagree, the project owner makes the final decision on direction after considering the technical arguments.
- A contributor may maintain a separate fork or propose an alternative design; upstream is not obligated to merge it.
- Be respectful. No contributor earns authority through donations, compute contributions or volume of AI-generated code.

## 10. Transparency and contributor recognition

- Credit accepted contributions through normal Git history and release notes.
- Ask before adding a person's name to a public supporters page.
- Do not assign higher technical authority based on donation amount.
- Do not promise response times, feature dates or personal support that cannot be sustained.
- Keep a brief public changelog of major roadmap and policy decisions.
