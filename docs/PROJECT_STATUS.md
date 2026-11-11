# Project status

**Repository stage:** local repository foundation in progress. No hosted remote or public release has been selected.

This status distinguishes implementation described in project records from validation repeated during repository setup. It is not a release or compatibility claim.

## Recorded implementation

- `scripts/install-pegasus.sh` provides preflight, dry-run, frontend installation, optional RetroArch setup, and library configuration operations. See `README.md` for the documented interface and safety boundaries.
- `docs/pegasus-arm64-research.md` records a successful native build and startup on the target Orange Pi 5 environment at the time of that research. This was not re-tested as part of repository setup.
- The installation brief records previous library, artwork, shader, and display work. Treat device state and performance figures there as historical until revalidated.

## Not yet established for a public release

- No project license has been selected. Complete the code, dependency, theme, shader, font, and artwork provenance review before choosing one or publishing.
- No GitHub owner/organization, repository URL, or remote has been selected.
- No official donation destination or private vulnerability reporting endpoint is configured.
- The current installation, update, rollback, frontend-exit, library compatibility, and per-system game-launch behavior need a fresh, reproducible validation pass before release claims are made.
- Hardware and performance support outside the specifically tested Orange Pi 5 configuration is unknown.
- The initial CI checks provide syntax validation only; they are not functional or hardware tests.

## Public-readiness rule

Do not publish a release or describe the project as broadly supported until licensing/provenance, current status evidence, private security reporting, safe CI, and a reproducible installation path have been reviewed. Record exact boards, OS versions, cores, commands, and outcomes for hardware tests.
