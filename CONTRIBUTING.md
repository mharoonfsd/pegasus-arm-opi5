# Contributing

Community participation is being prepared. Before inviting public contributions, the project owner must choose a license and complete the code/dependency/asset provenance review described in `docs/GITHUB_SETUP_CHECKLIST.md`. Until then, do not assume the repository has a selected license or that third-party content may be redistributed.

## Ways to help

Contributions can include focused code changes, documentation, reproducible bug reports, hardware validation, controller/display testing, and controlled compute support. Financial support is optional and is not required to participate. See `FUNDING.md` for the funding policy and current status.

## Before starting work

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

Run the relevant checks available for the change. The repository's initial CI checks shell syntax and Python source parsing:

```bash
bash -n scripts/install-pegasus.sh
python3 - <<'PY'
from pathlib import Path

for path in sorted(Path("scripts").glob("*.py")):
    compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY
```

For installer, library, graphics, or emulator changes, also describe tests that require the Orange Pi or user data. Do not run destructive or privileged tests against a real library as a substitute for a safe test fixture.

Maintainers review and merge PRs after checks pass. High-risk changes should receive a second human review where practical; donations or compute contributions never grant review or merge authority.
