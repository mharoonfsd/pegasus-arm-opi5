# Standard AI Agent Task Prompt

Copy this prompt into a coding agent after opening a contributor fork and selecting an `agent-ready` GitHub issue.

```text
You are working on the Pegasus ARM64 open-source project in my personal fork.
You are not authorized to modify the upstream repository directly.

First read:
- AGENTS.md
- CONTRIBUTING.md
- docs/PROJECT_STATUS.md
- docs/orange_pi_5_pegasus_installation_brief.md
- docs/STAGED_IMPLEMENTATION_PLAN.md
- the linked GitHub issue

Issue URL:
[PASTE ISSUE URL]

Before editing:
1. Inspect the current code and repository structure.
2. Summarize the user problem and desired behaviour.
3. Identify affected files and dependencies.
4. List risks, especially installer, filesystem, ROM/BIOS/save, ARM64,
   GPU/graphics, emulator, security and licensing risks.
5. Propose a small implementation plan.
6. Define how you will test the change.
7. Stop and ask me to approve the plan before editing.

After approval:
1. Work only on this issue and in my fork/branch.
2. Follow AGENTS.md and existing project conventions.
3. Add or update tests.
4. Run the relevant tests and report exact commands and results.
5. Do not claim hardware compatibility unless it was tested on the stated board.
6. Update docs and project status only where evidence supports it.
7. Do not add ROMs, BIOS, saves, scraped media, secrets, passwords, tokens,
   private logs or personal configuration.
8. Do not run untrusted code on self-hosted runners or request upstream secrets.
9. Do not modify funding destinations, repository settings, branch protection,
   secrets, release configuration or the main branch.
10. Prepare a PR summary with files changed, tests run, tests not run,
    risks, rollback notes and any hardware validation still required.

Do not merge the PR or publish a release.
```

## Maintainer review prompt

```text
Review this pull request as a maintainer. Do not modify files.

Check:
- scope and issue acceptance criteria;
- security and shell safety;
- data preservation and rollback;
- ARM64 and graphics assumptions;
- dependency/source/license provenance;
- test adequacy and test evidence;
- hardware requirements and compatibility claims;
- docs and status tracker accuracy.

List findings by severity with file/line references.
Distinguish confirmed defects from suggestions.
Do not claim a test was run unless its result is present.
```
