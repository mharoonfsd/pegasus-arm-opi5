# GitHub Actions security policy

- Use GitHub-hosted runners for public pull requests. Never run untrusted fork code on a volunteer's self-hosted hardware.
- Keep default token permissions read-only and set the minimum explicit `permissions:` for every workflow.
- Use `pull_request` for fork validation. Do not use `pull_request_target` to check out or execute PR-controlled code.
- Do not expose repository secrets to pull-request workflows.
- Pin third-party Actions to reviewed full commit SHAs. Keep CI limited to host-side, non-privileged checks.
- Keep release publishing separate from validation and restrict it to a maintainer-approved process on protected tags.

The CI workflow runs host-side Bash/Python syntax checks, ShellCheck, Ruff's unused-code rules, Bandit, Gitleaks, actionlint, and zizmor. It does not execute the installer or claim Orange Pi hardware compatibility. Tool releases are pinned and verified where downloaded as binaries; third-party Actions are pinned to full commit SHAs.

All required scanner jobs must pass before merge. Scanner output must identify the affected file and line when the tool provides a source location. New security findings fail their job. Do not blanket-ignore rules or suppress findings in bulk. A suppression is allowed only for a verified false positive, with the exact rule and path plus rationale documented next to the narrow exception and approved by a maintainer. Real vulnerabilities must be fixed, not waived.

These scanners are static checks, not malware detection or proof that code is safe. They cannot reliably decide whether arbitrary code is "unnecessary"; objective unused-code checks and focused human diff review cover that concern. Maintain human approval, dependency/provenance checks, and extra review for installer, workflow, security, and user-data changes.

Gitleaks scans added and modified files in each PR/commit. Before the first public release, maintainers must separately scan Git history and resolve any historical secret exposure; removing a secret from the current tree does not revoke or erase it from history.

The workflow emits stable status checks, but branch protection/rulesets are configured in GitHub repository settings, not by this workflow. The owner must require every relevant CI job plus human review on `main`; do not consider a passing scan sufficient if the required checks are not enforced.
