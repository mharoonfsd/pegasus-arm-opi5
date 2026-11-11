# Instructions for coding agents

This project targets native Pegasus and RetroArch use on Ubuntu ARM64, especially Orange Pi 5. Read the relevant parts of `README.md`, `CONTRIBUTING.md`, `docs/PROJECT_STATUS.md`, `docs/orange_pi_5_pegasus_installation_brief.md`, and the linked issue before changing code.

## Work process

- Work only on the linked task. Before editing, summarize the request, scope, risks, acceptance criteria, and tests; wait for the user's approval of the plan.
- Prefer small, reversible changes that follow the current Bash, Python, and documentation conventions.
- Do not infer hardware compatibility from configuration or successful compilation. Report exactly what was tested and what remains unverified.
- Update the README and installation brief when behavior, safety, paths, or verification status changes.
- Keep secrets, credentials, private logs, ROMs, BIOS/firmware, saves, and scraped game media out of Git.

## Installation and data safety

- Never use Wine, Box64, x86 emulation, or x86-only binaries for the target installation.
- Do not change the OS, kernel, bootloader, desktop session, graphics drivers, Mesa/Vulkan stack, or package sources as an incidental fix.
- Do not copy, move, rename, delete, or reorganize user libraries, ROMs, BIOS, saves, or media.
- Show and obtain explicit approval before privileged or disruptive operations. Keep privileged commands narrow and back up configuration before changing it.
- Quote paths, preserve existing user data, and surface errors instead of hiding failures behind successful fallbacks.

## Community and repository boundaries

- Develop in a contributor fork or an explicitly authorized branch, never directly on the upstream default branch.
- The human contributor is responsible for AI-generated changes. Agents do not approve, merge, publish releases, access repository secrets, or change hosting settings.
- Treat installer, security, workflow, dependency, license, and user-data changes as high risk and explain rollback and validation.
- Do not add a license, funding destination, CODEOWNERS identity, or repository setting based on a guess.
