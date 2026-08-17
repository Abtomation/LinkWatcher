---
id: PF-TSK-008
type: Process Framework
category: Task Definition
version: 1.4
created: 2024-07-15
updated: 2026-07-22
description: "Manage releases and deployments"
complexity: complex
use_when: >-
  Preparing and deploying releases. Runs the agnostic release gates, then **delegates project-specific deploy/version/distribute mechanics to the project's Release Process Guide** (`doc/ci-cd/release-process.md`) and gates on that guide's freshness.
automation: manual
scripts:
  - ../../scripts/file-creation/06-maintenance/New-BugReport.ps1
trigger_status:
  - raw: "_(user request)_ — checks `e2e-test-tracking.md`, feature impl state files; reads the project's **Release Process Guide** (`doc/ci-cd/release-process.md`, `PD-CIC`) **Freshness Stamp** at the Step 3 freshness gate (blocks the release if the guide is stale/missing — detects but never authors)"
output_status:
  - raw: "`feature-tracking.md` → feature statuses updated for release; `bug-tracking.md` → included fixes updated; **deploy / version / distribute mechanics delegated to the Release Process Guide** (Step 16) rather than authored inline; deployed version asserted against the decided bump (Step 17 gate) before tagging"
next_tasks:
  - task: ../06-maintenance/bug-fixing-task.md
    condition: "If issues are discovered during deployment"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "To begin work on the next release cycle"
---

# Release & Deployment

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Manage the process of preparing, versioning, and deploying releases of the application to various environments, ensuring quality and stability through proper verification and tracking.

## AI Agent Role

**Role**: DevOps Engineer
**Mindset**: Risk-averse, process-oriented, safety-first
**Focus Areas**: Deployment safety, automation, monitoring, rollback planning
**Communication Style**: Focus on rollback plans and deployment verification, ask about risk mitigation and monitoring requirements

## Context Requirements

- **Critical (Must Read):**

  - [Release Process Guide](../../../doc/ci-cd/release-process.md) - Release process documentation

- **Important (Load If Space):**

  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Features ready for release

- **Reference Only (Access When Needed):**
  - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Technical debt items addressed in this release

## Process

> **⚠️ MANDATORY: Always run the full test suite before deployment and verify application health afterward.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) and [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) to identify what's included in the release
2. **Verify user documentation completeness**: For each feature in the release scope with user-visible behavior, check the feature implementation state file's User Documentation section. If any show `❌ Needed`, trigger [User Documentation Creation](user-documentation-creation.md) before proceeding with the release.
3. **Verify Release Process Guide freshness** (inline gate, mirrors Step 2): Open your project's [Release Process Guide](../../../doc/ci-cd/release-process.md) and read its **Freshness Stamp** (`Verified against release` / `Verified on`). Treat the guide as **stale or missing** if **any** of the following hold:
   - the guide does not exist, or either Freshness-Stamp field reads `unverified`;
   - `Verified against release` predates the version you are about to release **and** the guide's deploy / version / distribute mechanics no longer match reality;
   - a path, script, or command the guide references no longer exists.

   If stale or missing, **stop and bring the guide current** — re-author its mechanics and re-set **both** Freshness-Stamp fields — before proceeding. This task **detects** staleness but **never authors** the guide; updating per-project release mechanics is a product-side responsibility. A fresh, accurate guide is a release gate, exactly like the user-documentation gate above.
4. **Decide and apply the version bump**: Decide the semantic-version bump for this release (major / minor / patch, judged from what shipped since the last release) — the bump *decision* is owned by this task. Apply it per the **Version Management** section of your project's [Release Process Guide](../../../doc/ci-cd/release-process.md), which owns *where and how* the version is written (version source of truth, bump procedure, tagging convention). After applying, verify **every** version source reports the new version — projects can carry more than one (package metadata, a hardcoded `__version__`, an installer manifest); grep for the old version string to catch stragglers.
5. Generate release notes from completed features and fixed bugs
6. Create a release branch if needed
7. Update any configuration files for the target environment(s)
8. **🚨 CHECKPOINT**: Present release scope, version numbers, and release notes to human partner for review

### Execution

9. **Run full pre-release test sweep**: Execute `Run-Tests.ps1 -All` to confirm all automated tests pass. This is a release gate — no deployment if tests fail. Pay special attention to **Critical** priority tests (query via `test_query.py --summary` or `pytest -m 'priority("Critical")'`) — these cover foundation features and must all pass. Extended priority tests (performance, edge cases) are informational but not release-blocking.
10. **Performance regression gate — scaled to the release's change surface**: If the release changes code covered by a registered performance test (compare [performance-test-tracking.md](../../../test/state-tracking/permanent/performance-test-tracking.md) against the release scope from Step 1), execute [Performance Baseline Capture](../03-testing/performance-baseline-capture-task.md) (PF-TSK-085) and check for regressions via `python process-framework/scripts/test/performance_db.py regressions` — investigate and document any flagged items before proceeding. If nothing in the release touches a measured surface, or the project has no registered performance tests, the gate is satisfied by recording that one-line determination for the pre-deployment checkpoint.
11. **E2E acceptance gate**: Check [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md) for E2E groups marked `🔄 Needs Re-execution` — all groups must show `✅ Passed` before release; trigger [E2E Acceptance Test Execution](../03-testing/e2e-acceptance-test-execution-task.md) for any that aren't. Check the **Workflow Milestone Tracking** — flag any release-scope workflow with `⬜ Not Created` status as a release risk. When nothing is flagged, this gate is a one-line confirmation; a project with no E2E tracking records that determination instead. When the release *itself* is the fix that re-enables E2E re-execution — the affected groups can only pass once the fixed artifact is deployed — the pre-deploy `✅ Passed` requirement is unsatisfiable; satisfy the gate with explicit human checkpoint approval (Step 15) plus a post-deploy E2E round scheduled against those groups.
12. Verify all deployment prerequisites are met
13. Complete the pre-deployment checklist
14. Obtain necessary approvals
15. **🚨 CHECKPOINT**: Present pre-deployment checklist results (including full test sweep results and any gate-scaling determinations from Steps 10–11) and obtain explicit approval before deploying
16. **Execute your project's Release Process Guide deploy steps** (delegation): Hand off to the per-project [Release Process Guide](../../../doc/ci-cd/release-process.md) (verified fresh in Step 3) and run its **Deploy / Distribute Steps**, its post-deploy verification, and any **Downstream-Impact / Announcement** actions it specifies. These mechanics are project-specific — global CLI install, packaged app, web service, library publish — and are **owned by the guide, not this task**: deployment, log/health monitoring, smoke tests, stakeholder notification, and post-deploy performance/error monitoring all live in the guide's deploy steps for your distribution model. This task orchestrates and gates the release; the guide supplies the concrete deploy / verify / notify / monitor actions. Carry the guide's verification results into the bug-discovery step below.
17. **🚨 Version-source agreement gate (before tagging)**: Run the deployed artifact's version report (e.g. the installed tool's `--version`) and confirm it reports the version decided in Step 4. A mismatch means a version source was missed — commonly a hardcoded version the deploy ships instead of package metadata. Treat it as a deploy failure: fix, redeploy, and re-verify **before** the release tag is created or pushed (tagging convention per the guide's Version Management section).

### Finalization

18. **Bug Discovery During Deployment**: Systematically identify and document any bugs discovered while executing the guide's deploy steps:

    - **Deployment Failures**: Issues that prevent successful deployment
    - **Configuration Problems**: Environment-specific configuration issues
    - **Performance Issues**: Degraded performance in production environment
    - **Integration Failures**: Problems with external services or APIs in production
    - **User Experience Issues**: UI/UX problems that only appear in production
    - **Data Migration Issues**: Problems with database migrations or data integrity

19. **Report Discovered Bugs**: If bugs are identified during deployment:

    - Use [../../scripts/file-creation/06-maintenance/New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage
    - Include deployment context and evidence in bug reports
    - Reference specific deployment logs or monitoring data
    - Note impact on deployment success and user experience

    For exact parameters and a worked example, run `Get-Help New-BugReport.ps1 -Full`; for its ValidateSet values, use the metadata one-liner in the [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md#powershell-script-execution-ai-agents) (and see the [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md)) — pass the deployment context via `-DiscoveredBy`, `-Environment`, and `-Evidence`.

20. Document any issues encountered during deployment
21. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Release Notes** - Document release version, included features, bug fixes, and known issues (format per project convention)
- **Bug Reports** - Any bugs discovered during deployment documented in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Update feature statuses to reflect release
- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Update bug statuses for fixes included in release

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Release notes are comprehensive and accurate
  - [ ] Release version has been properly incremented
  - [ ] Bug discovery performed systematically during deployment and monitoring
  - [ ] Any discovered bugs reported using New-BugReport.ps1 script with proper context and evidence
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature tracking updated to reflect released features
  - [ ] Bug tracking updated for fixes included in release
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-008`, context "Release & Deployment".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Needs Triage status for triage |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Update deployment status for released features<br/>• Add release version and deployment date |

## Next Tasks

- [**Bug Fixing**](../06-maintenance/bug-fixing-task.md) - If issues are discovered during deployment
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - To begin work on the next release cycle

<!-- merged from transition-registry entry: Release & Deployment (PF-TSK-008) -->
### Prerequisites for Transition

- [ ] Release notes created (version, features, bug fixes, known issues)
- [ ] Release Process Guide freshness gate passed (guide present and accurate) and its deploy / version / distribute steps executed via delegation (PF-TSK-008 Steps 3 and 16); deployed version asserted against the decided bump before tagging (Step 17 gate)
- [ ] All E2E test groups passed (verified in `e2e-test-tracking.md`)
- [ ] Feature tracking updated with release version for included features
- [ ] Bug reports created for any issues discovered during deployment validation

### Next Task Selection

```
What happened during deployment?
├─ Deployment successful, no issues → Begin next development cycle
│   ├─ Features planned → Feature Request Evaluation or Feature Discovery
│   └─ Tech debt to address → Technical Debt Assessment
├─ Issues discovered during deployment → Bug Triage (PF-TSK-041)
└─ Post-release monitoring reveals problems → Bug Triage (PF-TSK-041)
```

### Preparation for Next Task

1. Close out completed feature state files if appropriate (feature implementation state files are never archived — [PF-TEM-037](../../templates/04-implementation/feature-implementation-state-template.md))
2. Review Feature Request Tracking for the next batch of work
3. Update Technical Debt Tracking with any debt introduced during the release

## Related Resources

- [CI/CD Setup Guide](../../guides/07-deployment/ci-cd-setup-guide.md) - Guide for setting up CI/CD infrastructure
- [Test Infrastructure Guide](../../guides/03-testing/test-infrastructure-guide.md) - Test directory structure, tracking, and scaffolding
