---
id: PF-TSK-022
type: Process Framework
category: Task Definition
version: 2.1
created: 2025-07-21
updated: 2026-03-27
---

# Code Refactoring Task

## Purpose & Context

Systematic code improvement and technical debt reduction without changing external behavior

## AI Agent Role

**Role**: Senior Software Engineer
**Mindset**: Pragmatic, quality-focused, delivery-oriented
**Focus Areas**: Code quality, maintainability, performance, technical debt reduction
**Communication Style**: Present trade-offs between speed and quality, discuss refactoring benefits and risks

## When to Use

- When code quality metrics decline or technical debt accumulates
- Before implementing new features in areas with known technical debt
- When code complexity makes maintenance difficult or error-prone
- After identifying code smells during code reviews
- When refactoring is recommended by Technical Debt Assessment Task
- Before major feature releases to improve code maintainability

## When NOT to Use

- For building comprehensive test suites for new features (unit + component + integration + e2e) — use [Integration & Testing](../04-implementation/integration-and-testing.md) (PF-TSK-053) instead

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/06-maintenance/code-refactoring-task-map.md)

- **Critical (Must Read):**

  - **Target Code Area** - Specific files, modules, or components to be refactored
  - **Current Code Quality Issues** - Identified problems, code smells, or technical debt items (check the **Dims** column in [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) for the primary dimension)
  - **Existing Test Coverage** - Current test suite for the code area to ensure behavior preservation

- **Important (Load If Space):**

  - **Technical Debt Assessment** - Results from Technical Debt Assessment Task if available
  - **Code Quality Metrics** - Current complexity, maintainability, and quality measurements
  - **System Architecture Documentation** - Understanding of how refactored code fits into overall system
  - **Recent Code Changes** - Git history and recent modifications to understand change patterns

- **Reference Only (Access When Needed):**
  - **Coding Standards** - Project-specific coding conventions and style guides
  - **Performance Benchmarks** - Current performance metrics to ensure refactoring doesn't degrade performance
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams
  - [Test File Creation Guide](../../guides/03-testing/test-file-creation-guide.md) - For creating new test files when coverage gaps are identified

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Step 1: Effort Assessment Gate

> **⚠️ IMPORTANT: Independently verify tech debt descriptions.** Do not accept a TD item's problem description or proposed fix at face value. Read the actual target code and trace the full code path yourself. TD descriptions may be inaccurate about root cause, incomplete about scope, or propose a fix that only addresses part of the problem. Ask: "Is this the COMPLETE picture? Does the proposed fix address the dominant cost?" Map all branches, loops, and early exits before recommending Proceed.

Evaluate the refactoring scope against these criteria:

| Criteria | Lightweight | Standard |
|----------|-------------|----------|
| Architectural impact | None | Any (class decomposition, interface redesign, pattern changes) |
| Interface/API changes | None | Any (public API signature changes, contract modifications) |
| Files affected | Any count | Any count |
| Estimated effort | Any | Any |

**Lightweight** — No architectural impact AND no interface/API changes.
**Standard** — ANY architectural impact OR interface/API change triggers the standard path.

> **Key principle**: File count and effort alone do not determine the path. A 5-file dead code removal or config wiring change is Lightweight. A single-file class decomposition that changes interfaces is Standard.

> **🚨 CHECKPOINT**: Present **both** a justification recommendation **and** an effort classification to the human partner for approval.
>
> **Justification recommendation** (present first):
> - **Proceed** — Refactoring is justified; benefits clearly outweigh costs and risks.
> - **Modify scope** — Refactoring has merit but the scope should be adjusted (narrower, broader, or different approach).
> - **Rejected** — Refactoring is not justified (cost > benefit, risk too high, issue is cosmetic, code is scheduled for replacement, etc.). Provide a brief rationale.
>
> **If the human approves Rejected**:
> 1. Identify the **source** of the tech debt item (which task, session, or agent introduced it) from [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md).
> 2. Update the tech debt item status to Rejected using `Update-TechDebt.ps1 -NewStatus "Rejected" -ResolutionNotes "Rejected: <rationale>"`.
> 3. **Root cause analysis**: Read the source task's guidance (the specific section/dimension that produced the TD item) and analyze **why** it generated an unjustified item — e.g., missing language-context filter, overly broad pattern matching, aspirational standard treated as actual practice. In the session's **feedback form**, document: the tech debt ID, the source task, the analysis of what guidance gap allowed the false positive, and a concrete recommendation for improving the source task (e.g., a process improvement via `New-ProcessImprovement.ps1`).
> 4. **Aspirational standard check**: If the rejection reason is that the referenced standard (ADR, guideline, or design doc) describes aspirational behavior rather than actual practice, update the standard to reflect reality — or create a process improvement (via `New-ProcessImprovement.ps1`) to do so — before closing the rejection. Leaving an inaccurate standard in place causes repeat false-positive TDs in future validation rounds.
> 5. Skip to the Task Completion Checklist below — no refactoring plan or code changes are needed.
>
> **Workflow awareness**: Before proceeding, check the `workflows:` metadata in the affected feature's [implementation state file](/doc/state-tracking/features/) (or look up the feature in [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md)). Note which user workflows the refactored code participates in — this informs the scope of regression testing needed after refactoring to ensure workflow correctness is preserved.
>
> **Effort classification** (present alongside justification if recommending Proceed or Modify scope):
> - **If Lightweight**: Read and follow the **[Lightweight Path](code-refactoring-lightweight-path.md)** document.
> - **If Standard**: Read and follow the **[Standard Path](code-refactoring-standard-path.md)** document.
>
> **Only load the path document that applies.** Each path document contains its own complete process steps and task completion checklist.

## Outputs

- **Refactoring Plan Document** - Lightweight or standard plan documenting scope, changes, and results (stored in `doc/refactoring/plans`)
- **Refactored Code** - Improved code with better structure, reduced complexity, and maintained functionality
- **Updated Test Suite** - Enhanced or additional tests to cover refactored code areas (standard path)
- **Quality Metrics Report** - Before/after comparison of code quality indicators and performance metrics (standard path)
- **Technical Debt Reduction** - Documented reduction in technical debt items and code quality issues
- **Bug Reports** - Any bugs discovered during refactoring documented in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
- **Updated State Files** - All relevant state tracking files updated according to the applicable path

## Next Tasks

- [**Code Review Task**](code-review-task.md) - Review refactored code for quality and correctness
- [**Performance Baseline Capture**](../03-testing/performance-baseline-capture-task.md) - Re-capture performance baselines after refactoring to detect regressions. Recommended when the refactored code participates in performance-critical paths (check [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) Related Features column)
- [**Manual Test Execution**](../03-testing/e2e-acceptance-test-execution-task.md) - Execute manual tests for groups marked for re-execution after refactoring
- [**Technical Debt Assessment Task**](../cyclical/technical-debt-assessment-task.md) - Reassess technical debt after refactoring completion
- [**Test Specification Creation**](../03-testing/test-specification-creation-task.md) - If refactoring reveals systemic test gaps that warrant a formal test specification

## Related Resources

- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - For identifying refactoring targets
