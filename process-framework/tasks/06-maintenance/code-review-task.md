---
id: PF-TSK-005
type: Process Framework
category: Task Definition
version: 2.8
created: 2023-06-15
updated: 2026-08-05
description: "Review code for quality and correctness"
complexity: simple
use_when: >-
  Reviewing implemented product code for quality. Triggers: 'review the code', 'do a code review', 'check this PR' (product code only — framework changes are reviewed inline at Process Improvement's decision-review checkpoint).
triggers:
  - "review the code"
  - "do a code review"
  - "check this PR"
automation: manual
scripts:
  - ../../scripts/file-creation/06-maintenance/New-BugReport.ps1
trigger_status:
  - file: feature-tracking.md
    status: "👀 Needs Review"
output_status:
  - raw: "`feature-tracking.md` → `🔎 Needs Test Scoping` or `🔄 Needs Enhancement`"
next_tasks:
  - task: ../03-testing/performance-and-e2e-test-scoping-task.md
    condition: "If the review passed, feature moves to `🔎 Needs Test Scoping` for performance and E2E test needs identification"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "If issues were found, addresses the feedback from the code review"
  - task: code-refactoring-task.md
    condition: "If technical debt or code quality issues were identified"
  - task: ../07-deployment/user-documentation-creation.md
    condition: "If the feature introduces or changes user-visible behavior, create/update handbooks before release"
  - task: ../cyclical/technical-debt-assessment-task.md
    condition: "If systemic issues were found that affect multiple features"
---

# Code Review

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Review implemented code to ensure it meets quality standards, follows project coding best practices, and correctly implements the requirements specified in the Technical Design Document. This task acts as a quality gate to prevent issues from reaching production while ensuring performance, security, and maintainability standards are met.

This is the framework's **consolidated quality gate**: in addition to code-quality, security, and accessibility review, it validates the feature against its TDD acceptance criteria and business requirements and benchmarks performance against TDD targets (responsibilities formerly held by the retired Quality Validation task). For decomposed-mode features it records the quality-validation results in the feature's permanent implementation state file.

## AI Agent Role

**Role**: Code Quality Auditor
**Mindset**: Critical but constructive, standards-focused, quality-oriented
**Focus Areas**: Coding best practices, performance, state management, external integrations, accessibility, security, maintainability
**Communication Style**: Provide specific improvement suggestions with rationale, ask about design decisions, focus on long-term maintainability and user experience

## Context Requirements

- **Critical (Must Read):**

  - [Technical Design Document](../../../doc/technical/tdd) - The technical design document for the feature, including its **acceptance-criteria** and **performance-target** sections
  - Source code files that were created or modified during implementation
  - Project dependency configuration file - To verify dependency changes and versions

- **Important (Load If Space):**

  - Test files associated with the implementation
  - Linting/analysis configuration files - To understand code standards
  - Environment configuration files - For environment-specific settings review

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - To identify features with "👀 Needs Review" status
  - [Architecture Decision Records](../../../doc/technical/adr) - For architectural context
  - [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - For test coverage context

## Process

> **⚠️ MANDATORY: Always use the Code Review Checklist to ensure comprehensive reviews.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**
>
> **🚫 NO CODE CHANGES: This task is a read-only quality gate. Do NOT fix bugs, refactor code, or make any code changes during Code Review. Report all findings as bugs (via New-BugReport.ps1) or technical debt items. If the user requests code changes during review, explain that fixes should be done in a separate Bug Fixing or Code Refactoring task after the review is complete.**

### Preparation

> **🚨 SCOPE GUARD — Framework path target**: This task is for **product code review only**. If the changes to be reviewed live in `process-framework/` or a root-level routing file (`CLAUDE.md`, `MEMORY.md`, `ai-tasks.md`), this task does **NOT** apply — this includes **framework-distributed tooling under `process-framework/tools/` (e.g. the LinkWatcher launcher/config scripts), which stays framework even in a project whose product *is* that tool, so that edits flow back through rollout rather than diverging locally. When a product fix legitimately spans both product source *and* such tooling, review the product part here and route the tooling part to [Process Improvement](../support/process-improvement-task.md) (PF-TSK-009). Framework changes are reviewed inline at Process Improvement's decision-review checkpoint. **Stop now and switch tasks.** See [ai-tasks.md framework-vs-product policy](../../ai-tasks.md#framework-path-vs-product-path-disambiguation).

1. Review the [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) document to identify features with "👀 Needs Review" status
2. Select the next feature (or bug fix) for code review. **Working-tree scoping**: working trees here often mix the change under review with unrelated uncommitted edits (parallel sessions, LinkWatcher updates, other in-flight fixes). When they do, establish the review's change-set scope up front — identify the change under review with `git diff HEAD -- <path>` (cross-referenced against the bug's footprint or the feature's file list) and present that scope at the Step 9 checkpoint. Review only that change set; verify interaction seams with adjacent changes without re-reviewing change sets already closed. The same scoping applies to a **repeat review** (a feature returning via `🔄 Needs Enhancement`, or a bug-fix re-review after this task's own prior finding): scope the review to the fix delta — the gap entries and prior findings recorded in the feature's state file (or the bug's `-VerificationNotes`) — and seam-check the previously passed scope rather than re-reviewing it.
3. Review the TDD to understand the intended design and requirements
4. **Read the feature's Dimension Profile** from its implementation state file (or the bug's Dims column for bug fix reviews). Focus the review on **Critical** dimensions using the review focus points from the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md)
5. Review the implementation checklist to ensure all aspects are covered
6. Set up the development environment and ensure all dependencies are installed
7. Verify environment setup (e.g., correct Python/runtime version, tools available)
8. Install all project dependencies (e.g., `pip install -r requirements.txt`)
9. **🚨 CHECKPOINT**: Present feature selection, TDD review, dimension profile focus areas, implementation checklist, and environment setup to human partner for approval before starting code review analysis

### Pre-Review Analysis

> **Instruction-medium scoping (PF-PRO-064)**: Steps 10 and 13–14 verify **code**. For a feature whose medium is `instruction` (the `**Medium**` scalar in state-file §2), they are N/A — substitute the instruction verification levels: `Check-InstructionContract.ps1` with `-Path` covering the changed instruction artifacts (L2), plus the feature's agent-executed E2E results (L3) where such cases exist. A `mixed` feature gets both: Steps 10 and 13–14 on its code part, the substitutes on its instruction part. The lint/coverage checklist items scope the same way.

10. Run automated code quality checks using the project's configured tools:
   ```bash
   # Commands are defined in process-framework/languages-config/{language}/{language}-config.json
   # - Static analysis / linting: testing.lintCommand
   # - Test runner with coverage: testing.baseCommand + testing.coverageArgs
   # Project language and test directory are in doc/project-config.json
   #
   # Or use the framework test runner:
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All -Coverage
   ```
11. Review dependency changes in the project's dependency configuration for:
   - Version compatibility
   - Security implications
   - License compliance
   - Necessity of new dependencies

### Code Review Execution

12. Examine the implemented code, focusing on:

    > **For bug-fix reviews**: scope the bullet list below to the dimensions named in the bug's Dims column. Mark non-listed dimensions N/A in your findings rather than walking each one — Step 4's dimension profile already established the relevant scope.

    - **Coding Best Practices**: Language idioms, type safety, proper use of language features
    - **Architecture Adherence**: Design patterns, service layer, proper separation of concerns
    - **State Management**: State handling patterns, immutability, proper resource cleanup
    - **External Integrations**: Authentication flow, data models, error handling, connection management
    - **Performance**: Resource usage, memory management, efficient algorithms, lazy loading
    - **Accessibility**: Semantic labels, screen reader support, keyboard navigation
    - **Security**: Data validation, secure storage, authentication tokens, API security
    - **Platform Compatibility**: OS-specific considerations if applicable
    - **Error Handling**: Network errors, loading states, user-friendly error messages
    - **Testing**: Unit tests, integration tests, test coverage

### Testing Verification

13. Run and verify all test suites using the project's test runner:
    ```bash
    # Run by category (categories defined in process-framework/languages-config/)
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category unit
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category integration
    # Run full suite
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All
    ```
14. Verify test coverage meets project standards (aim for >80% for critical paths)
15. Test the feature in relevant environments (if applicable):
    - Development environment
    - Staging/test environment
    - Target platform(s)

### Performance & Accessibility Review

> **For bug-fix reviews**: run Steps 16-18 only when the relevant dimension code is in the bug's Dims column — `PE` for Step 16 (Performance), `AX` for Step 17 (Accessibility), `SE` for Step 18 (Security). Skip the others as N/A.

16. Use profiling tools to check for:
    - Unnecessary processing or redundant operations
    - Memory leaks
    - Performance bottlenecks
    - **Benchmark against TDD targets**: compare measured performance (latency, throughput, resource usage) against the performance targets in the TDD; flag any unmet target or regression as a finding
17. Test accessibility features:
    - Screen reader compatibility
    - Keyboard navigation
    - Color contrast
    - Text scaling

### Security Review

18. Verify security considerations:
    - Input validation and sanitization
    - Secure data storage
    - Authentication token handling
    - API endpoint security
    - Sensitive data exposure in logs

### Acceptance Criteria & Business Validation

> **For bug-fix reviews**: skip as N/A — the bug's Dims column, not feature acceptance criteria, scopes the review.

19. **Validate Acceptance Criteria & Business Requirements** (feature reviews): Confirm the implementation satisfies the TDD's acceptance criteria and business requirements — verify user stories, business rules, edge cases, and error scenarios behave as specified, and UX flows match the design. Record each criterion as met/unmet with evidence; route unmet criteria as findings in the next step.

### Defect Discovery During Review

20. **Identify Defects**: During code review, systematically identify any defects:

    - **Logic Errors**: Incorrect business logic implementation or algorithmic flaws
    - **Security Vulnerabilities**: Authentication bypasses, data exposure, injection vulnerabilities
    - **Performance Issues**: Memory leaks, inefficient queries, blocking operations
    - **Integration Problems**: API contract violations, data format mismatches
    - **Error Handling Gaps**: Missing error handling, improper exception management
    - **State Management Issues**: Incorrect state handling, state mutation problems
    - **Platform-Specific Issues**: Platform compatibility problems, accessibility violations
    - **Technical Debt**: Code that works but has known quality/design problems — shortcuts, suboptimal patterns, missing abstractions

21. **Route Discovered Defects**: Classify each finding and route to the correct tracking system:

    | Finding type | Condition | Route to | Fix task |
    |---|---|---|---|
    | **Bug** | Wrong behavior on a released/completed feature | [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) via [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) | [Bug Triage](bug-triage-task.md) → [Bug Fixing](bug-fixing-task.md) |
    | **Tech Debt** | Code works but has quality/design problems (any feature) | [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) via [Update-TechDebt.ps1 -Add](../../scripts/update/Update-TechDebt.ps1) | [Technical Debt Assessment](../cyclical/technical-debt-assessment-task.md) → [Code Refactoring](code-refactoring-task.md) |
    | **Implementation Gap** | Wrong behavior on an in-progress/unreleased feature | Feature's [implementation state file](../../../doc/state-tracking/features) section 8 (Issues & Resolutions Log) with status OPEN | Current implementation or [Feature Enhancement](../04-implementation/feature-enhancement.md) task |

    For all finding types:
    - Document in the code review findings with severity levels
    - Reference specific code locations and line numbers
    - Note impact on code review results and deployment readiness
    - For a confirmed Critical/Major data-integrity finding, assess concrete exposure before the Step 22 checkpoint: enumerate which artifacts/configurations in the affected deployment(s) can actually trigger the defect today, and state the result as counts in the finding (e.g. "0 corruptible today, 7 mutation-exposed") rather than a theoretical risk statement

    > **Key distinction**: Bugs are wrong behavior on released features. Tech debt is working code with quality problems. Implementation gaps are defects on features still being built. Do not route implementation gaps through Bug Triage — they are picked up by the next implementation session via the feature state file.

    **Example Bug Report Command (released features only)**:

    ```powershell
    # Create bug report for issues found during code review
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/06-maintenance/New-BugReport.ps1 -Title "Unhandled exception in data validation" -Description "Method validate_input() doesn't handle None parameter" -DiscoveredBy "CodeReview" -Severity "High" -Component "Data Validation" -Environment "Development" -Evidence "Code location: validate_input() in src/services/validator.py (near line 142 as of 2025-01-15)"
    ```

### Finalization

22. **🚨 CHECKPOINT**: Present code review findings, acceptance-criteria validation, bug reports, test results, performance analysis, and security review to human partner for review before finalization
23. Document findings using the severity levels from the Code Review Checklist:
    - 🔴 **Critical**: Security vulnerabilities, crashes, data corruption
    - 🟠 **Major**: Significant functionality or maintainability issues
    - 🟡 **Minor**: Issues that should be addressed but don't block deployment
    - 🔵 **Suggestion**: Recommendations for improvement
    - 🟢 **Positive**: Acknowledge good practices and well-implemented solutions
24. **Feature reviews**: Update the feature tracking document to reflect the review status. **For bug-fix reviews**: if the underlying feature is already Implemented, Feature Tracking is N/A — only Bug Tracking is updated (Step 25).
    - **Decomposed-mode features**: also record the quality-validation results — acceptance-criteria verdict, performance-vs-TDD-targets, and severity-categorized findings — in the feature's implementation state file (the permanent per-feature record — never archived, per its template [PF-TEM-037](../../templates/04-implementation/feature-implementation-state-template.md)).
25. **Bug fix reviews**: If this review is for a bug fix (identified by the bug's Dims column rather than a feature implementation state file), update [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md):
    - **On approval**: Transition bug from 👀 Needs Review → 🔒 Closed using `Update-BugStatus.ps1 -BugId "PD-BUG-XXX" -NewStatus "Closed" -VerificationNotes "Code review approved, no regressions"`. The script automatically moves the entry to the Closed section and recalculates statistics.
    - **On rejection**: Transition the bug back to 🟡 In Progress using `Update-BugStatus.ps1 -BugId "PD-BUG-XXX" -NewStatus "InProgress" -VerificationNotes "<review findings summary>"`, then route back to Bug Fixing (PF-TSK-007). The `-VerificationNotes` summary is the carrier the next Bug Fixing session reads to address the findings.
26. Update test implementation tracking based on test review results
27. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Code Review Document** - Comprehensive document with findings, recommendations, and positive acknowledgments. **For bug-fix reviews**: optional — findings are recorded in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) via `Update-BugStatus.ps1 -VerificationNotes` (on approval) plus any new bug reports; a separate review document is not required. **For feature/enhancement reviews recorded in a feature implementation state file**: likewise optional — the state-file record (quality-validation results plus routed findings) is the default; create a standalone document only when the review's depth warrants one.
- **Updated Feature Tracking** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) with review status updated
- **Test Coverage Report** - Generated coverage report from test runner
- **Code Quality Metrics** - Results from static analysis and formatting checks
- **Performance Analysis** - Profiling tool findings, performance recommendations, and benchmark comparison against TDD targets
- **Acceptance Criteria Validation** - Per-criterion met/unmet results confirming the feature meets its TDD acceptance criteria and business requirements (feature reviews)
- **Defect Reports** - Findings routed per step 21: bugs → [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md), tech debt → [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md), implementation gaps → feature state file
- **Updated Feature Implementation State File** - (decomposed-mode feature reviews) quality-validation results recorded in the permanent per-feature state file

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - **Feature reviews only** (N/A for bug-fix reviews on Implemented features). Update via [`Update-CodeReviewState.ps1`](../../scripts/update/Update-CodeReviewState.ps1) — never edit the file directly (see [Feature Tracking Mutation Guide](../../guides/support/feature-tracking-mutation-guide.md)). The script maps the review verdict to the feature's **Status** cell (`🔎 Needs Test Scoping` if passed, `🔄 Needs Enhancement` if not) and appends a review note (date, verdict, optional findings summary and review-document link) to its **Notes** cell — the only two cells the schema carries for review state; reviewer and full findings detail live in the review document / per-feature state file
- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - **Conditional** (only for bug fix reviews): Transition bug from 👀 Needs Review → 🔒 Closed on approval, or back to 🟡 In Progress on rejection
- Feature Implementation State File - **Conditional** (decomposed-mode feature reviews): record quality-validation results (acceptance-criteria verdict, performance-vs-TDD-targets, severity-categorized findings) in the permanent per-feature state file ([PF-TEM-037](../../templates/04-implementation/feature-implementation-state-template.md) — never archived)
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - **Read-only for the audit verdict.** Verify the test suite passes (re-run it per Step 13) and note coverage as part of the review. The `✅ Audit Approved` status is owned and set by [Test Audit (PF-TSK-030)](../03-testing/test-audit-task.md), which runs before Code Review — do **not** set or flip the audit status here. If the review surfaces failing, inadequate, or stale tests, route them as Step 21 findings (tech debt, or back to Test Audit) rather than editing the audit-status column.

**Script usage**: Run `pwsh.exe -ExecutionPolicy Bypass -Command 'Get-Help <script-path> -Full'` for `Update-CodeReviewState.ps1` parameters and inline examples. See also [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) for cross-cutting invocation patterns.

**Additional Automation**: Consider creating additional automation for:

- Automated code quality report generation
- Test coverage threshold validation
- Performance benchmark comparison

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

> **Bug-fix reviews**: this checklist is feature-shaped. Scope it to the bug's Dims column and Bug Tracking — the Manual Code Review dimension items outside the Dims column, and the feature-only items (Feature Tracking status, review-document link, coverage-percentage updates), are N/A, per the inline bug-fix rules already marked at Steps 12, 16–18, and 24–25.

> **Instruction-medium parts**: the lint/coverage/test-suite items apply to the code part only — instruction parts substitute the L2/L3 checks per the Pre-Review Analysis scoping note (a pure-`instruction` feature marks them N/A).

- [ ] **Pre-Review Setup**: Environment and tooling verification
  - [ ] Development environment verified and tools available
  - [ ] All dependencies installed
  - [ ] Code Review Checklist reviewed and understood
- [ ] **Automated Analysis**: Code quality and testing verification

  - [ ] Static analysis / linting executed and results reviewed
  - [ ] Code formatting checked
  - [ ] All test suites executed with coverage
  - [ ] Test coverage report generated and reviewed
  - [ ] Dependency changes reviewed for security and compatibility

- [ ] **Manual Code Review**: Comprehensive code examination

  - [ ] Coding best practices verified (language idioms, type safety, proper patterns)
  - [ ] Architecture adherence confirmed (design patterns, service layer, separation of concerns)
  - [ ] State management implementation reviewed
  - [ ] External integration security and error handling verified
  - [ ] Performance considerations addressed (resource usage, memory management)
  - [ ] Accessibility features tested (screen reader, keyboard navigation, color contrast)
  - [ ] Platform compatibility verified (target environments as applicable)
  - [ ] Security review completed (input validation, secure storage, API security)
  - [ ] Acceptance criteria & business requirements validated against the TDD (feature reviews; N/A for bug-fix reviews)
  - [ ] Performance benchmarked against TDD targets (feature reviews)
  - [ ] Defect discovery performed systematically across all review areas
  - [ ] Discovered defects routed correctly: bugs → bug-tracking (released features), tech debt → technical-debt-tracking, implementation gaps → feature state file (in-progress features)

- [ ] **Verify Outputs**: Confirm all required outputs have been produced

  - [ ] Comprehensive code review document with findings and recommendations (**feature reviews**; for bug-fix reviews this document is optional — findings live in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) instead)
  - [ ] All critical and major issues identified and documented with severity levels
  - [ ] Positive aspects of the implementation acknowledged
  - [ ] Test coverage report included
  - [ ] Performance analysis completed
  - [ ] Review follows the code review checklist completely

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) shows correct review status (`🔎 Needs Test Scoping` if passed, `🔄 Needs Enhancement` if not) — **N/A for bug-fix reviews on Implemented features**
  - [ ] **Decomposed-mode**: quality-validation results (acceptance criteria, performance-vs-targets, severity findings) recorded in the feature implementation state file
  - [ ] [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) consulted: test suite verified passing and any test issues routed as findings — the `✅ Audit Approved` verdict is left to [Test Audit (PF-TSK-030)](../03-testing/test-audit-task.md), not set here
  - [ ] Review note (date, verdict, findings summary) appended to the feature's Notes cell via `Update-CodeReviewState.ps1` — reviewer and full findings detail live in the review document / per-feature state file
  - [ ] Link to review document included (when a standalone review document was created)
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-005`, context "Code Review".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Needs Triage status for triage |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | [`Update-CodeReviewState.ps1`](../../scripts/update/Update-CodeReviewState.ps1) | **Feature reviews only** (N/A for bug-fix reviews on Implemented features). Maps the review verdict to the feature's Status cell (`🔎 Needs Test Scoping` if passed, `🔄 Needs Enhancement` if not) and appends a review note (date, verdict, optional findings summary and review-document link) to its Notes cell — never edit the file directly |
| **Verifies** | [`test-tracking.md`](../../../test/state-tracking/permanent/test-tracking.md) | Read-only | Confirm the test suite passes; record any test issues as Step 21 findings.<br/>• The `✅ Audit Approved` verdict is owned by [Test Audit (PF-TSK-030)](../03-testing/test-audit-task.md) — Code Review does **not** set or flip it. |
| **Updates** | [`technical-debt-tracking.md`](../../../doc/state-tracking/permanent/technical-debt-tracking.md) | `Update-TechDebt.ps1` (conditional) | Register tech debt findings discovered during review |
| **Updates** | Feature Implementation State Files | Manual (conditional) | Implementation gaps logged in Issues & Resolutions Log; (decomposed-mode) quality-validation results — acceptance criteria, performance-vs-targets, severity findings — recorded in the permanent per-feature state file |

## Next Tasks

- [**Performance & E2E Test Scoping (PF-TSK-086)**](../03-testing/performance-and-e2e-test-scoping-task.md) - If the review passed, feature moves to `🔎 Needs Test Scoping` for performance and E2E test needs identification
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If issues were found, addresses the feedback from the code review
- [**Code Refactoring**](code-refactoring-task.md) - If technical debt or code quality issues were identified
- [**User Documentation Creation**](../07-deployment/user-documentation-creation.md) - If the feature introduces or changes user-visible behavior, create/update handbooks before release

- [**Technical Debt Assessment**](../cyclical/technical-debt-assessment-task.md) - If systemic issues were found that affect multiple features

<!-- merged from transition-registry entries: Code Review + Code Review (Bug Fix Reviews); consolidated 2026-07-13 (PF-IMP-1457); prerequisites/preparation restatement trimmed 2026-07-22 (PF-IMP-1575) — completion criteria live in the Task Completion Checklist and Steps 24-25 -->
### Next Task Selection

```
What kind of review, and what was the result?
├─ Feature review — approved → Performance & E2E Test Scoping (PF-TSK-086)
│  (Feature status set to 🔎 Needs Test Scoping)
├─ Feature review — minor/major issues → Bug Fixing → Code Review (repeat)
├─ Feature review — code quality issues → Code Refactoring → Code Review (repeat)
├─ Bug-fix review — approved → Bug Status: 🔒 Closed → Release & Deployment (if release-ready)
├─ Bug-fix review — approved + L-scope architectural → Bug routes to PF-TSK-086 (🔎 Needs Test Scoping)
├─ Bug-fix review — issues found → Bug Status: 🟡 In Progress → Bug Fixing (repeat cycle)
└─ New issues discovered (either mode) → New Bug Reports → Bug Triage → Bug Fixing
```

## Related Resources

### General Coding Resources

- Project-specific coding standards and style guides
- Language-specific best practices documentation
- Performance optimization guidelines for your technology stack
- Accessibility implementation guides

### Project-Specific Resources

- [Architecture Decision Records](../../../doc/technical/adr) - Architectural context and decisions
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature status and dependencies
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Test coverage and status

### Development Tools & Standards

- Project linting/analysis configuration - Code standards
- Project dependency configuration - Dependencies and versions

### Automation & Scripts

- [Update-CodeReviewState.ps1](../../scripts/update/Update-CodeReviewState.ps1) — automated state file updates (`Get-Help <script> -Parameter *` for parameter details)
- [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) — cross-cutting PowerShell invocation patterns
- CLI commands for analysis and testing

### Fallback Guidance

If referenced files are missing or incomplete:

1. Refer to the [Definition of Done](../../guides/04-implementation/definition-of-done.md) as the primary quality reference
2. Focus on the review areas outlined in this task
3. Consult with your human partner for project-specific standards and requirements
