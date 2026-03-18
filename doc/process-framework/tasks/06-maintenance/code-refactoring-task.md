---
id: PF-TSK-022
type: Process Framework
category: Task Definition
version: 2.0
created: 2025-07-21
updated: 2026-03-04
task_type: Discrete
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

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/06-maintenance/code-refactoring-task-map.md)

- **Critical (Must Read):**

  - **Target Code Area** - Specific files, modules, or components to be refactored
  - **Current Code Quality Issues** - Identified problems, code smells, or technical debt items
  - **Existing Test Coverage** - Current test suite for the code area to ensure behavior preservation

- **Important (Load If Space):**

  - **Technical Debt Assessment** - Results from Technical Debt Assessment Task if available
  - **Code Quality Metrics** - Current complexity, maintainability, and quality measurements
  - **System Architecture Documentation** - Understanding of how refactored code fits into overall system
  - **Recent Code Changes** - Git history and recent modifications to understand change patterns

- **Reference Only (Access When Needed):**
  - **Coding Standards** - Project-specific coding conventions and style guides
  - **Performance Benchmarks** - Current performance metrics to ensure refactoring doesn't degrade performance
  - [Visual Notation Guide](/doc/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Step 1: Effort Assessment Gate

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

> **🚨 CHECKPOINT**: Present effort classification (Lightweight or Standard) to human partner for approval.
>
> - **If Lightweight**: Read and follow the **[Lightweight Path](code-refactoring-lightweight-path.md)** document.
> - **If Standard**: Read and follow the **[Standard Path](code-refactoring-standard-path.md)** document.
>
> **Only load the path document that applies.** Each path document contains its own complete process steps and task completion checklist.

## Outputs

- **Refactoring Plan Document** - Lightweight or standard plan documenting scope, changes, and results (stored in `doc/product-docs/refactoring/plans`)
- **Refactored Code** - Improved code with better structure, reduced complexity, and maintained functionality
- **Updated Test Suite** - Enhanced or additional tests to cover refactored code areas (standard path)
- **Quality Metrics Report** - Before/after comparison of code quality indicators and performance metrics (standard path)
- **Technical Debt Reduction** - Documented reduction in technical debt items and code quality issues
- **Bug Reports** - Any bugs discovered during refactoring documented in [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
- **Updated State Files** - All relevant state tracking files updated according to the applicable path

## Next Tasks

- [**Code Review Task**](code-review-task.md) - Review refactored code for quality and correctness
- [**Manual Test Execution**](../03-testing/e2e-acceptance-test-execution-task.md) - Execute manual tests for groups marked for re-execution after refactoring
- [**Technical Debt Assessment Task**](../cyclical/technical-debt-assessment-task.md) - Reassess technical debt after refactoring completion

## Related Resources

- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - For identifying refactoring targets
