---
id: PF-TSK-008
type: Process Framework
category: Task Definition
version: 1.2
created: 2024-07-15
updated: 2026-03-22
---

# Release & Deployment

## Purpose & Context

Manage the process of preparing, versioning, and deploying releases of the application to various environments, ensuring quality and stability through proper verification and tracking.

## AI Agent Role

**Role**: DevOps Engineer
**Mindset**: Risk-averse, process-oriented, safety-first
**Focus Areas**: Deployment safety, automation, monitoring, rollback planning
**Communication Style**: Focus on rollback plans and deployment verification, ask about risk mitigation and monitoring requirements

## When to Use

- When preparing a new release version
- When deploying to staging or production environments
- When hotfixes need to be deployed urgently
- When a milestone of features is ready for release
- When release notes need to be generated

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/07-deployment/release-deployment-map.md)

- **Critical (Must Read):**

  - [Release Process Guide](/doc/ci-cd/release-process.md) - Release process documentation
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Features ready for release

- **Reference Only (Access When Needed):**
  - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Technical debt items addressed in this release

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Always run the full test suite before deployment and verify application health afterward.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) and [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) to identify what's included in the release
2. **Verify user documentation completeness**: For each feature in the release scope with user-visible behavior, check the feature implementation state file's User Documentation section. If any show `❌ Needed`, trigger [User Documentation Creation](user-documentation-creation.md) before proceeding with the release.
3. Update version numbers according to semantic versioning
4. Generate release notes from completed features and fixed bugs
5. Create a release branch if needed
6. Update any configuration files for the target environment(s)
7. **🚨 CHECKPOINT**: Present release scope, version numbers, and release notes to human partner for review

### Execution

8. Run the full test suite on the release candidate
9. **Run full pre-release test sweep**: Execute `Run-Tests.ps1 -All` to confirm all automated tests pass. This is a release gate — no deployment if tests fail. Pay special attention to **Critical** priority tests (query via `test_query.py --summary` or `pytest -m 'priority("Critical")'`) — these cover foundation features and must all pass. Extended priority tests (performance, edge cases) are informational but not release-blocking.
10. **Run performance baseline capture**: Execute [Performance Baseline Capture](../03-testing/performance-baseline-capture-task.md) (PF-TSK-085) to record current performance measurements and check for regressions against stored baselines. Use `python process-framework/scripts/test/performance_db.py regressions` to flag any degradations. Performance regressions are a release risk — investigate and document any flagged items before proceeding.
11. **Verify E2E acceptance test status**: Check [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md) for any E2E groups marked `🔄 Needs Re-execution`. All groups must show `✅ Passed` before release. If any need re-execution, trigger [E2E Acceptance Test Execution](../03-testing/e2e-acceptance-test-execution-task.md) first. Also check the **Workflow Milestone Tracking** — are all workflows in the release scope covered by E2E tests? Flag any workflow with `⬜ Not Created` status as a release risk.
11. Verify all deployment prerequisites are met
12. Complete the pre-deployment checklist
13. Obtain necessary approvals
14. **🚨 CHECKPOINT**: Present pre-deployment checklist results (including full test sweep results) and obtain explicit approval before deploying
15. Deploy to the target environment(s)
16. Monitor deployment logs for issues
17. Verify application health post-deployment
18. Run smoke tests to confirm basic functionality

### Finalization

19. **Bug Discovery During Deployment**: Systematically identify and document any bugs discovered during deployment:

    - **Deployment Failures**: Issues that prevent successful deployment
    - **Configuration Problems**: Environment-specific configuration issues
    - **Performance Issues**: Degraded performance in production environment
    - **Integration Failures**: Problems with external services or APIs in production
    - **User Experience Issues**: UI/UX problems that only appear in production
    - **Data Migration Issues**: Problems with database migrations or data integrity

20. **Report Discovered Bugs**: If bugs are identified during deployment:

    - Use [../../scripts/file-creation/06-maintenance/New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage
    - Include deployment context and evidence in bug reports
    - Reference specific deployment logs or monitoring data
    - Note impact on deployment success and user experience

    **Example Bug Report Command**:

    ```powershell
    # Navigate to the scripts directory from project root
    Set-Location "process-framework/scripts/file-creation"

    # Create bug report for issues found during deployment
    ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 -Title "API timeout in production environment" -Description "User authentication API calls timeout after 30 seconds in production but work fine in staging" -DiscoveredBy "Development" -Severity "Critical" -Component "Authentication" -Environment "Production" -Evidence "Deployment logs: /logs/deployment-2025-01-15.log"
    ```

21. Update release status documentation
22. Notify stakeholders of successful deployment
23. Monitor application performance and error rates
24. Document any issues encountered during deployment
25. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Release Notes** - Document release version, included features, bug fixes, and known issues (format per project convention)
- **Bug Reports** - Any bugs discovered during deployment documented in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Update feature statuses to reflect release
- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Update bug statuses for fixes included in release

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Release notes are comprehensive and accurate
  - [ ] Release version has been properly incremented
  - [ ] Bug discovery performed systematically during deployment and monitoring
  - [ ] Any discovered bugs reported using New-BugReport.ps1 script with proper context and evidence
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature tracking updated to reflect released features
  - [ ] Bug tracking updated for fixes included in release
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-008" and context "Release & Deployment"

## Next Tasks

- [**Bug Fixing**](../06-maintenance/bug-fixing-task.md) - If issues are discovered during deployment
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - To begin work on the next release cycle

## Related Resources

- [CI/CD Setup Guide](../../guides/07-deployment/ci-cd-setup-guide.md) - Guide for setting up CI/CD infrastructure
- [Test Infrastructure Guide](../../guides/03-testing/test-infrastructure-guide.md) - Test directory structure, tracking, and scaffolding
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks
