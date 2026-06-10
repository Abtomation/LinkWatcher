---
id: PD-STA-004
type: Process Framework
category: State Tracking
version: 1.3
created: 2025-08-30
updated: 2026-06-04
---

# Bug Tracking

This document tracks the lifecycle of bugs and issues in the LinkWatcher project, providing a systematic approach to bug identification, triage, resolution, and verification.

<details>
<summary><strong>📋 Table of Contents</strong></summary>

- [Status Legends](#status-legends)
  - [Bug Status](#bug-status)
  - [Priority Levels](#priority-levels)
  - [Scope Levels](#scope-levels)
  - [Source Types](#source-types)
- [Bug Management Workflow](#bug-management-workflow)
- [Bug Registry](#bug-registry)
  - [Critical Bugs](#critical-bugs)
  - [High Priority Bugs](#high-priority-bugs)
  - [Medium Priority Bugs](#medium-priority-bugs)
  - [Low Priority Bugs](#low-priority-bugs)
- [Closed Bugs](#closed-bugs) (pointer → [archive](archive/bug-tracking-archive.md))
- [Bug Statistics](#bug-statistics)

</details>

## Status Legends

### Bug Status

| Symbol | Status        | Description                                                    | Next Task  |
| ------ | ------------- | -------------------------------------------------------------- | ---------- |
| 🆕     | Needs Triage  | Bug reported, awaiting evaluation and prioritization           | PF-TSK-041 |
| 🔍     | Needs Fix     | Triaged and prioritized, ready for bug fixing                  | PF-TSK-007 |
| 🟡     | In Progress   | Bug is currently being investigated or fixed                   | —          |
| 👀     | Needs Review  | Fix implemented and tested, awaiting Code Review verification  | PF-TSK-005 |
| 🔒     | Closed        | Reviewed, verified, and resolved                               | —          |
| 🔄     | Reopened      | Previously closed bug has recurred — needs re-triage           | PF-TSK-041 |
| ❌     | Rejected      | Not a bug, won't fix, or other rejection rationale — terminal state | —     |
| 🚫     | Duplicate     | Duplicate of another existing bug — terminal state             | —          |

### Priority Levels

| Priority | Description                                 | Response Time     |
| -------- | ------------------------------------------- | ----------------- |
| Critical | System breaking, security issues            | Immediate         |
| High     | Major functionality affected                | Within 24 hours   |
| Medium   | Minor functionality affected                | Within 1 week     |
| Low      | Cosmetic or enhancement requests            | When time permits |

### Scope Levels

| Scope | Description                                                      |
| ----- | ---------------------------------------------------------------- |
| S     | Small — single-session fix, no state file needed                 |
| M     | Medium — may span sessions, state file recommended               |
| L     | Large — multi-session, state file required (New-BugFixState.ps1) |

### Source Types

| Source                 | Description                              |
| ---------------------- | ---------------------------------------- |
| Testing                | Discovered during test execution         |
| Test Development       | Found during test implementation         |
| Test Audit             | Discovered during test audit process     |
| E2E Testing            | Discovered during E2E acceptance testing |
| User Report            | Reported by end users                    |
| Code Review            | Found during code review process         |
| Feature Development    | Found during feature implementation      |
| Foundation Development | Found during foundational feature work   |
| Code Refactoring       | Discovered during refactoring activities |
| Deployment             | Found during release deployment          |
| Monitoring             | Detected by system monitoring            |
| Development            | Found during general development work    |

## Bug Management Workflow

```mermaid
graph TD
    A[Bug Discovered] --> B[🆕 Needs Triage]
    B --> C[Bug Triage Process]
    C --> D[🔍 Needs Fix]
    C --> L[❌ Rejected]
    C --> M[🚫 Duplicate]
    D --> E[🟡 In Progress]
    E --> F{Scope?}
    F -->|S-scope quick path| G[Self-Review + 🔒 Closed]
    F -->|M/L-scope| H[👀 Needs Review]
    H --> I[Code Review]
    I -->|Approved| K[🔒 Closed]
    I -->|Issues found| E
    K --> N{L-scope + architectural?}
    N -->|AI assessment: yes| O[🔎 Needs Test Scoping]
    N -->|No| P[Done]
```

## Bug Registry

### Critical Bugs

| ID | Title | Status | Priority | Scope | Reported | Description | Related Feature | Workflows | Dims | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| _No critical bugs currently active_ |

### High Priority Bugs

| ID | Title | Status | Priority | Scope | Reported | Description | Related Feature | Workflows | Dims | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| _No high priority bugs currently active_ |


### Medium Priority Bugs

| ID | Title | Status | Priority | Scope | Reported | Description | Related Feature | Workflows | Dims | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PD-BUG-102 | Move of recently-linked file misses reference update (no_references_found) | 🆕 Needs Triage | Medium |  | 2026-06-10 | A markdown link freshly written into test-tracking.md was not rewritten when its target file was moved ~6 minutes later. The move itself was detected (move_detected via delete+create correlation) but file_moved ran with references_count=0 / no_references_found - the fresh link was absent from the in-memory database. Suspected gap: links added by an external modification shortly before a move are not indexed before the move resolves. | 1.1.1 |  |  | Source: Development; Environment: Development; Component: Handler/Database; Repro: 1. With LinkWatcher running, create file A (test/automated/unit/test_configschemadrift.py). 2. Write a markdown link to A into an existing monitored .md file (test/state-tracking/permanent/test-tracking.md, written by New-TestFile.ps1). 3. A few minutes later, move A to another directory with the same basename (Move-Item). 4. Observe move_detected followed by no_references_found in the log; the link in the .md file is not rewritten.; Expected: The modify event on test-tracking.md indexes the new link into the database; the subsequent move of the target rewrites the link to the new path.; Actual: Move processed with references_count=0 (no_references_found warning); link left pointing at the old path; manual repair required.; Evidence: logs/linkwatcher/LinkWatcherLog_20260610-215218.txt 2026-06-10 14:27:46-14:28:16 (file_created old path, file_deleted, move_detect_match result=matched, move_detected, file_moved references_count=0, no_references_found); discovered during PF-TSK-068 session for PF-STA-108; Second instance same day 14:44: a 30-minute-old link in feature-tracking.md (written 14:13 via Update-FeatureTrackingStatus) was not rewritten when its target state file moved to temporary/old/ (Finalize-Enhancement.ps1) — weakens the freshly-written-race hypothesis; modify-event rescan of externally edited .md files may be missing entirely |
| PD-BUG-105 | Project daemon interferes with scoped E2E workspace daemons - 6 E2E cases fail | 🆕 Needs Triage | Medium |  | 2026-06-10 | The project's LinkWatcher daemon watches test/e2e-acceptance-testing/*/workspace/ and applies default-config live updates over the scoped per-test daemons. Every E2E case whose expectation differs from a plain live update fails (dry-run, ignore rules, monitored extensions, backups, startup excludes, dir rename): TE-E2E-011/015/019/023/024/025; WF-002/003/006/007 now Failing. Likely surfaced by PD-BUG-100 lock change allowing per-project-root coexistence. | N/A |  |  | Source: E2ETesting; Environment: Development; Component: E2E Test Harness; Repro: Run-E2EAcceptanceTest.ps1 -TestCase TE-E2E-019 -Workflow dry-run-mode-preview-without-changes with the project daemon running; compare workspace docs/readme.md against expected (unchanged); Expected: Scoped workspace daemons are the only writers inside their test workspace during E2E execution; Actual: Project daemon concurrently updates workspace files with default config, overriding dry-run/ignore/backup expectations. Candidate fixes: exclude e2e workspace dirs from project daemon scope, or harness pauses project daemon during runs; Evidence: logs/linkwatcher/LinkWatcherLog.txt 22:03 entries with e2e-acceptance-testing paths; TE-E2E-019 workspace link rewritten despite dry-run |
| PD-BUG-106 | install_global.py venv rebuild fails when another project's daemon holds the shared venv | 🆕 Needs Triage | Medium |  | 2026-06-10 | stop_running_linkwatcher() only stops the daemon of the source project (via its .linkwatcher.lock). Daemons of other projects (e.g. appdev) run from the same shared ~/bin/.linkwatcher-venv and lock its python.exe, so the venv recreation step fails with Permission denied and the install exits 1 mid-flow (files copied, but no venv/wrapper/smoke-test). Hit during the v2.1.1 release. | N/A |  |  | Source: Development; Environment: Development; Component: Deployment; Repro: Start a LinkWatcher daemon for any other project (runs from ~/bin/.linkwatcher-venv python), then run python deployment/install_global.py from the source repo; Expected: Installer stops (or detects and reports) all daemons running from the install dir venv before rebuilding it, then completes; Actual: Errno 13 Permission denied on .linkwatcher-venv/Scripts/python.exe; install aborts after file copy, before venv/wrappers/smoke test; Evidence: v2.1.1 deploy 2026-06-10: first install run exit 1; appdev daemon PID 25200 held the venv python |

### Low Priority Bugs

| ID | Title | Status | Priority | Scope | Reported | Description | Related Feature | Workflows | Dims | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PD-BUG-103 | Config guide Full Reference ignored_directories list drifted from code default | 🆕 Needs Triage | Low |  | 2026-06-10 | configuration-guide.md Full Reference (claims to be the complete config with all defaults) shows an ignored_directories default that does not match LinkWatcherConfig.ignored_directories in settings.py. Users get a wrong picture of which directories LinkWatcher skips. Not caught by the drift-guard test, which compares set/dict defaults by key presence only (see TD261). | 0.1.3 |  |  | Source: TestAudit; Environment: Development; Component: Documentation; Repro: 1. Open doc/user/handbooks/configuration-guide.md -> 2. Find the ### Full Reference YAML block -> 3. Read the ignored_directories list -> 4. Compare against LinkWatcherConfig.ignored_directories default in src/linkwatcher/config/settings.py (lines 86-100); Expected: Guide ignored_directories list matches code default exactly: .git, .dart_tool, node_modules, .vscode, build, dist, __pycache__, tests, linkWatcher; Actual: Guide lists .pytest_cache, coverage, docs/_build, target, bin, obj instead, and omits linkWatcher and tests; Evidence: Test Audit report TE-TAR-075: test/audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-3-test-configschemadrift.md |

## Closed Bugs

> 🗄️ **Archived** — Closed and rejected bug rows live in [archive/bug-tracking-archive.md](archive/bug-tracking-archive.md) (sibling file, split 2026-05-26 per PF-IMP-872 to keep this file scannable as the closed/rejected history grows).
>
> `Update-BugStatus.ps1` reads and writes the archive automatically when transitioning to `Closed` / `Rejected` / `Reopened`. The archive holds two sections: `## Closed Bugs` (fixed) and `## Rejected Bugs` (not-a-bug / won't-fix) — kept distinct so trend analysis can separate "we fixed it" from "we decided not to fix it."

## Bug Statistics

### Current Status Summary

- **Total Active Bugs**: 4
- **Critical**: 0
- **High**: 0
- **Medium**: 3 (PD-BUG-102)
- **Low**: 1 (PD-BUG-103)
- **All Triaged**: Yes

---

## Integration with Feature Tracking

When bugs are related to specific features, they should reference the feature ID from [Feature Tracking](feature-tracking.md). This enables:

1. **Impact Assessment**: Understanding which features are affected by bugs
2. **Priority Alignment**: Aligning bug priority with feature priority
3. **Release Planning**: Ensuring critical bugs are fixed before feature releases
4. **Testing Coordination**: Coordinating bug fixes with feature testing

## Integration with Process Framework

This bug tracking system integrates with the following process framework components:

### Bug Management Tasks

- **[Bug Triage Task](../../../process-framework/tasks/06-maintenance/bug-triage-task.md)**: For bug evaluation and prioritization
- **[Bug Fixing Task](../../../process-framework/tasks/06-maintenance/bug-fixing-task.md)**: For bug resolution workflow

### Development Tasks with Bug Discovery Integration

- **[Data Layer Implementation (PF-TSK-051)](../../../process-framework/tasks/04-implementation/data-layer-implementation.md)**: Bug discovery during data model and repository work
- **[Integration & Testing (PF-TSK-053)](../../../process-framework/tasks/04-implementation/integration-and-testing.md)**: Bug discovery during integration testing
- **[Quality Validation (PF-TSK-054)](../../../process-framework/tasks/04-implementation/quality-validation.md)**: Bug discovery during quality validation
- **[Implementation Finalization (PF-TSK-055)](../../../process-framework/tasks/04-implementation/implementation-finalization.md)**: Bug discovery during finalization
- **[Feature Enhancement (PF-TSK-068)](../../../process-framework/tasks/04-implementation/feature-enhancement.md)**: Bug discovery during enhancement work
- **[Foundation Feature Implementation Task](../../../process-framework/tasks/04-implementation/foundation-feature-implementation-task.md)**: Bug discovery during foundational work
- **[Integration & Testing (PF-TSK-053)](../../../process-framework/tasks/04-implementation/integration-and-testing.md)**: Bug discovery during test development
- **[Test Audit Task](../../../process-framework/tasks/03-testing/test-audit-task.md)**: Bug discovery during test auditing
- **[Code Review Task](../../../process-framework/tasks/06-maintenance/code-review-task.md)**: Bug discovery during code reviews
- **[Code Refactoring Task](../../../process-framework/tasks/06-maintenance/code-refactoring-task.md)**: Bug discovery during refactoring
- **[Release Deployment Task](../../../process-framework/tasks/07-deployment/release-deployment-task.md)**: Bug discovery during deployment

### Automation Integration

All development tasks use the **`New-BugReport.ps1`** script for standardized bug reporting, ensuring consistent bug documentation and automatic integration with this tracking system.

## Usage Guidelines

### Adding New Bugs

#### Automated Method (Recommended)

Use the **`New-BugReport.ps1`** script for standardized bug creation:

- Automatically generates sequential PD-BUG-XXX IDs
- Ensures consistent formatting and required fields
- Integrates with development task workflows
- Creates bug report documents and updates this tracking file

#### Manual Method

1. Use the next sequential bug ID (PD-BUG-001, PD-BUG-002, etc.)
2. Start with status 🆕 Needs Triage
3. Fill in all required fields
4. Place in appropriate priority section
5. Reference related feature ID if applicable

### Updating Bug Status

1. Update the status symbol and any relevant fields
2. Add notes about status changes
3. Move bugs between priority sections if priority changes
4. Update statistics section

### Closing Bugs

Use `Update-BugStatus.ps1 -NewStatus "Closed"` which automatically:
1. Changes status to 🔒 Closed
2. Moves the bug entry from its active priority table to the Closed Bugs section
3. Recalculates Bug Statistics (active counts, resolved count)
4. Appends verification notes and timestamp

### Reopening Bugs

Use `Update-BugStatus.ps1 -NewStatus "Reopened" -ReopenReason "reason"` which automatically:
1. Changes status to 🔄 Reopened
2. Moves the bug entry from the Closed Bugs section back to the correct active priority table
3. Recalculates Bug Statistics (active counts, resolved count)
4. Appends reopen reason and timestamp

After reopening, re-evaluate priority and scope through [Bug Triage](../../../process-framework/tasks/06-maintenance/bug-triage-task.md#steps-to-reopen-a-bug).

### Bug ID Format

- **Format**: PD-BUG-XXX (where XXX is a sequential number)
- **Examples**: PD-BUG-001, PD-BUG-002, PD-BUG-003
- **Scope**: Project-wide unique identifiers following Product Documentation (PD) naming convention
- **Automated Creation**: When using `New-BugReport.ps1`, IDs are automatically generated in the correct format

---

_This document is maintained as part of the Process Framework State Tracking system and should be updated whenever bugs are reported, triaged, fixed, or closed._
