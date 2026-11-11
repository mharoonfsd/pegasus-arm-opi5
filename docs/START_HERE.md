# Pegasus ARM64 — Community and AI Development Playbook

This package documents the selected operating model:

**Community-driven AI development. Contributors use their own AI subscriptions and compute to develop in forks. The project owner and trusted community maintainers coordinate, review and merge contributions.**

## Read these first

1. `docs/OPERATING_MODEL.md` — roles, permissions, authority, approval and contribution lifecycle.
2. `docs/GITHUB_SETUP_CHECKLIST.md` — settings, branch protection, Actions security, labels and Projects.
3. `docs/STAGED_IMPLEMENTATION_PLAN.md` — stages, exit criteria and rollout sequence.
4. `docs/AI_AGENT_TASK_PROMPT.md` — copy/paste prompt for contributors' coding agents.
5. `docs/PROJECT_BOARD_CONFIGURATION.md` — board fields, views and tracking rules.
6. `.github/SETUP_ACTIONS_POLICY.md` — CI security policy.
7. `docs/PROJECT_STATUS.md` — current implementation evidence and public-readiness gaps.

## Also read the original project guidance

- `AGENTS.md`
- `CONTRIBUTING.md`
- `FUNDING.md`
- `docs/STAGED_IMPLEMENTATION_PLAN.md`
- `docs/AI_AGENT_TASK_PROMPT.md`
- `docs/OPERATING_MODEL.md` (including the hardware and compute contribution model)
- `docs/PROJECT_STATUS.md`

## Before public publication

- Merge with existing files rather than blindly overwriting them.
- Choose and add a real open-source licence; this pack does not select one.
- Audit code, dependency and asset licences.
- Reconcile status and feature tracking with the actual repository and current tests.
- Replace all funding and username placeholders with verified values, or leave funding links unpublished.
- Do not create an active `.github/CODEOWNERS` until actual usernames/teams and permissions are confirmed.
- Configure GitHub settings manually using `docs/GITHUB_SETUP_CHECKLIST.md`.

## Default governance

- Project owner retains organization/repository administration.
- Trusted maintainers can review and merge routine changes within delegated scope.
- Contributors and AI agents work in forks; AI agents have no independent access to upstream.
- `main` is protected by PR review and CI checks.
- Installer, security, workflow and release changes receive enhanced review.
- Volunteers run tests on their own hardware and submit reports; public fork code does not run on community self-hosted runners.
