# GitHub Project Board Configuration

Use one GitHub Project to manage delivery. The weighted parity tracker remains the product-feature scorecard; the Project board manages day-to-day work.

## Fields

| Field | Type | Values / use |
|---|---|---|
| Status | Single select | Inbox, Needs triage, Ready, In progress, PR review, Needs hardware test, Done, Blocked |
| Priority | Single select | P0, P1, P2, P3 |
| Area | Single select | Installer, Pegasus UI, RetroArch, Emulator, Metadata, Controller, Graphics, Docs, CI/Security |
| Contribution path | Single select | Code, AI-assisted code, Hardware test, Compute, Documentation, Design |
| Hardware required | Single select | None, Orange Pi 5, Other ARM64, Controller, Display/audio |
| Size | Single select | XS, S, M, L, Research |
| Milestone | Single select | Repository foundation, Development Preview, Alpha, Beta, Stable |
| Feature ID | Text | Link to the parity tracker, e.g. F01 |
| Verification | Single select | Not tested, Host CI, Orange Pi 5, Other ARM64, Multiple boards |
| Assignee | Person | Person coordinating the issue, not the AI agent |

## Views

### Roadmap
Group by Milestone. Use this for public progress updates.

### Ready for AI
Filter:
- Status = Ready
- Label = `agent-ready`

Show title, priority, area, size, hardware required and issue link.

### Needs hardware
Filter:
- Status = Needs hardware test OR label = `needs-hardware`

Show exact board and validation procedure.

### PR review
Show open pull requests, requested reviewer, linked issue, CI status and age.

### Backlog
Group by Priority and Area. Do not let low-priority ideas crowd out release blockers.

## Operating rules

- Every meaningful task should have a GitHub Issue.
- Every issue should have one responsible human coordinator.
- The AI agent is not the assignee of record.
- Use milestones for release gates, not arbitrary dates.
- A task moves to Done only after acceptance criteria and required verification are met.
- Update the parity tracker when evidence changes, not merely when an issue closes.
- Avoid duplicate tracking: Project board = execution; parity tracker = product coverage.
