# Project status

**Repository stage:** hosted community repository foundation in progress. The GitHub repository is [mharoonfsd/pegasus-arm-opi5](https://github.com/mharoonfsd/pegasus-arm-opi5); no public release has been selected.

This status distinguishes implementation described in project records from validation repeated during repository setup. It is not a release or compatibility claim.

## Recorded implementation

- `scripts/install-pegasus.sh` provides preflight, dry-run, frontend installation, optional RetroArch setup, and library configuration operations. See `README.md` for the documented interface and safety boundaries.
- `docs/pegasus-arm64-research.md` records a successful native build and startup on the target Orange Pi 5 environment at the time of that research. This was not re-tested as part of repository setup.
- The installation brief records previous library, artwork, shader, and display work. Treat device state and performance figures there as historical until revalidated.
- The selected roadmap target is Atari 2600, FBNeo, MAME, Mega Drive/Genesis (one system), Mega CD/Sega CD, Nintendo 64, NES, and SNES. The selection is not evidence that each target currently launches or performs well on the Orange Pi 5.
- The initial feature briefs are in `features/README.md`; they are drafts and none should be treated as agent-ready without maintainer triage.

## Not yet established for a public release

- No project license has been selected. Complete the code, dependency, theme, shader, font, and artwork provenance review before choosing one or publishing.
- No official donation destination or private vulnerability reporting endpoint is configured.
- The current installation, update, rollback, frontend-exit, library compatibility, and per-system game-launch behavior need a fresh, reproducible validation pass before release claims are made.
- Hardware and performance support outside the specifically tested Orange Pi 5 configuration is unknown.
- CI now runs host-side Bash/Python syntax checks, ShellCheck, Ruff unused-code checks, Bandit, Gitleaks on added/modified files, actionlint, and zizmor. These checks are not functional or hardware tests and do not prove code is harmless.
- Branch protection/rulesets and private vulnerability reporting require owner-side GitHub configuration and verification.

## Public-readiness rule

Do not publish a release or describe the project as broadly supported until licensing/provenance, current status evidence, private security reporting, safe CI, and a reproducible installation path have been reviewed. Record exact boards, OS versions, cores, commands, and outcomes for hardware tests.
