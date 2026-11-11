# GitHub Actions security policy

- Use GitHub-hosted runners for public pull requests. Never run untrusted fork code on a volunteer's self-hosted hardware.
- Keep default token permissions read-only and set the minimum explicit `permissions:` for every workflow.
- Use `pull_request` for fork validation. Do not use `pull_request_target` to check out or execute PR-controlled code.
- Do not expose repository secrets to pull-request workflows.
- Pin third-party Actions to reviewed full commit SHAs. Keep CI limited to host-side, non-privileged checks.
- Keep release publishing separate from validation and restrict it to a maintainer-approved process on protected tags.

The initial CI workflow only checks shell syntax and parses Python source. It does not install dependencies, access secrets, execute the installer, or claim Orange Pi hardware compatibility.
