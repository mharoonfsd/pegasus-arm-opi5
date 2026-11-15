# Contributing

Community participation is being prepared. Before inviting public contributions, the project owner must choose a license and complete the code/dependency/asset provenance review described in `docs/GITHUB_SETUP_CHECKLIST.md`. Until then, do not assume the repository has a selected license or that third-party content may be redistributed.

## Ways to help

Contributions can include focused code changes, documentation, reproducible bug reports, hardware validation, controller/display testing, and controlled compute support. Financial support is optional and is not required to participate. See `FUNDING.md` for the funding policy and current status.

## Before starting work

Start with [`START_HERE_AI_CONTRIBUTORS.md`](START_HERE_AI_CONTRIBUTORS.md) for the step-by-step AI-assisted contribution workflow.

1. Check for an existing issue or open a focused issue with the expected behavior and acceptance criteria.
2. Wait for maintainer triage before treating an issue as `agent-ready`.
3. Fork the repository and work on a task-specific branch. Do not push directly to the upstream default branch.
4. For AI-assisted work, follow `AGENTS.md` and `docs/AI_AGENT_TASK_PROMPT.md`. The human submitting the change must review and understand it.

## Pull requests

- Keep each PR focused on one issue and link that issue.
- Explain the behavior change, risks, rollback, and any hardware-only checks.
- Update user-facing documentation when behavior or safety requirements change.
- Never include ROMs, BIOS/firmware, game saves, scraped media, credentials, private logs, or personal configuration.
- Do not add binaries or third-party assets without documenting their source, license, and attribution.
- Do not claim compatibility unless the named board, OS, core, and test procedure were actually exercised.

## Validation

Run the relevant checks available for the change. The CI workflow also runs the scanner jobs documented in [the Actions policy](.github/SETUP_ACTIONS_POLICY.md). The syntax checks can be run locally with:

```bash
bash -n scripts/install-pegasus.sh
python3 - <<'PY'
from pathlib import Path

for path in sorted(Path("scripts").glob("*.py")):
    compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY
```

For installer, library, graphics, or emulator changes, also describe tests that require the Orange Pi or user data. Do not run destructive or privileged tests against a real library as a substitute for a safe test fixture. For host-side scanner checks, see the exact commands in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

CI runs shell, Python, workflow, and secret checks. A scanner finding that fails a required check must be fixed before merge; do not hide findings with broad suppressions. If a tool reports a verified false positive, propose a narrow rule/path exception with a rationale for maintainer review. No scanner can prove code harmless or judge all unnecessary code, so every PR still needs human review. High-risk changes should receive a second human review where practical; donations or compute contributions never grant review or merge authority.

Feature-specific contributor briefs are indexed in [`features/README.md`](features/README.md). Each brief is a task specification, not merge approval: follow `AGENTS.md`, use a task-specific branch, and wait for maintainer triage before treating a draft as ready.
