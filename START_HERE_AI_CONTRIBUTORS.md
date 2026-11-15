# START HERE: Build a Feature with an AI Agent

This is the entry point for contributors who want to use an AI coding agent. It explains the current safe workflow and links to the feature briefs. The in-Pegasus AI development mode is only a specification; it is not implemented yet.

> **Before contributing:** the project license and public contribution readiness still require owner decisions. Check [project status](docs/PROJECT_STATUS.md) and ask the maintainer whether outside contributions are being accepted. Do not assume third-party code or assets can be redistributed.

## Step 1: Choose a task

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).
2. Check for an existing issue, or propose a focused issue with the user outcome, scope, and test expectations.
3. Wait for maintainer triage. A feature brief marked **Draft — not agent-ready** is a roadmap, not approval to implement it.
4. Choose one maintainer-approved issue and its matching brief from the [feature catalog](features/README.md). Keep one issue per branch and pull request.

## Step 2: Fork the repository and create a branch

Create a fork on GitHub, then clone your fork and add the project repository as `upstream`:

```bash
git clone https://github.com/<your-github-name>/pegasus-arm-opi5.git
cd pegasus-arm-opi5
git remote add upstream https://github.com/mharoonfsd/pegasus-arm-opi5.git
git fetch upstream
git switch --create feature/<issue-number>-<short-name> upstream/main
```

Replace the placeholders with your GitHub account, issue number, and a short task name. Do not work directly on `main` or push to the upstream repository.

## Step 3: Start a new AI coding session

Open the repository root in your coding environment and start a fresh AI session with the selected feature brief. Give the agent the **entire brief**, not only its title. At the end of the brief, copy and include its **Copy-ready agent instruction**.

Ask the agent to read the repository instructions and linked issue, summarize the goal, scope, risks, acceptance criteria, and tests, then wait for your approval before editing. Do not give the agent credentials or access to ROMs, BIOS/firmware, saves, scraped media, or private configuration. Use synthetic fixtures for testing.

## Step 4: Review and approve the implementation plan

Check that the agent's plan:

- stays within the approved issue and feature brief;
- uses native Linux/ARM64 dependencies and verifies official sources, versions, and licenses;
- preserves existing user files and settings;
- includes focused tests, documentation, rollback, and any required Orange Pi validation.

Correct the plan with the agent before approving edits. If an official native ARM64 build is unavailable, stop and ask the maintainer/user to choose from the documented options.

## Step 5: Review the implementation as it is built

Keep the agent on the feature branch. Review each meaningful change; do not approve unexplained commands, broad cleanup, new repositories, unverified binaries, or unrelated dependencies. The agent must not commit, push, merge, or run unapproved commands. The human contributor is responsible for understanding and reviewing all generated code.

Never put ROMs, BIOS/firmware, saves, scraped media, credentials, private logs, or personal configuration in the repository or test fixtures. Do not claim Orange Pi compatibility from a successful build or configuration alone.

## Step 6: Run tests and inspect the final changes

From the repository root, run the checks relevant to the change. The basic syntax checks are:

```bash
bash -n scripts/install-pegasus.sh
python3 - <<'PY'
from pathlib import Path

for path in sorted(Path("scripts").glob("*.py")):
    compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY
```

Also run the applicable checks in [`.github/workflows/ci.yml`](.github/workflows/ci.yml): ShellCheck, Ruff, Bandit, Gitleaks, actionlint, and zizmor. A scanner failure blocks the required status check. Report verified false positives narrowly with a rationale for maintainer review; do not suppress a real vulnerability. Scanners cannot prove code harmless or decide every unnecessary change.

For hardware-dependent work, test on the named Orange Pi/Ubuntu/core/game combination and record the exact procedure and measurable result. If you did not run a device test, say so plainly.

Before submitting, inspect your branch diff and run:

```bash
git diff --check
git status --short
```

Confirm that the diff contains only the approved task and no user data or generated artifacts.

## Step 7: Submit a pull request

After your own review, push your **fork branch** and open a pull request to `mharoonfsd/pegasus-arm-opi5:main`. Link the issue, follow the repository's pull request template, describe tests and hardware limitations, and explain rollback for risky changes. Wait for required CI checks and maintainer review; passing CI alone is not merge approval.

```bash
git push --set-upstream origin feature/<issue-number>-<short-name>
```

The repository owner must configure branch protection/rulesets to require the CI status checks and human approval. Contributors and AI agents do not merge their own work.

## Feature brief

Start at [features/README.md](features/README.md) to find the feature catalog, task-spec template, and current draft briefs.
