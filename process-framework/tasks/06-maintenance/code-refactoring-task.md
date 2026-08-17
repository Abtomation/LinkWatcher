---
id: PF-TSK-022
type: Process Framework
category: Task Definition
version: 2.5
created: 2025-07-21
updated: 2026-07-13
change_notes: "v2.5 - Check Recommended Skills wiring: refactoring-planning craft skill replaces the retired Refactoring Plan Template Customization Guide (Craft-as-Skill BL-5 batch 3)"
description: "Systematic code improvement and technical debt reduction without changing external behavior"
complexity: medium
use_when: >-
  Systematic product-code improvement and technical debt reduction without changing external behavior. Does **NOT** cover building comprehensive test suites for new features (unit / component / integration / e2e) — route to [Integration & Testing](../04-implementation/integration-and-testing.md) (PF-TSK-053). Triggers: 'refactor X', 'reduce tech debt in module Y', 'clean up Z' (product code only — framework refactors go to Process Improvement).
triggers:
  - "refactor X"
  - "reduce tech debt in module Y"
  - "clean up Z"
automation: semi
scripts:
  - ../../scripts/file-creation/06-maintenance/New-RefactoringPlan.ps1
  - ../../scripts/file-creation/support/New-TempTaskState.ps1
  - ../../scripts/file-creation/06-maintenance/New-BugReport.ps1
  - ../../scripts/file-creation/02-design/New-ArchitectureDecision.ps1
  - ../../scripts/update/Update-TechDebt.ps1
trigger_status:
  - raw: "`technical-debt-tracking.md` → Active items (not Resolved/Deferred)"
output_status:
  - raw: "`technical-debt-tracking.md` → `Resolved`; `e2e-test-tracking.md` → affected groups → `🔄 Needs Re-execution`"
next_tasks:
  - task: code-review-task.md
    condition: "Review refactored code for quality and correctness"
  - task: ../03-testing/performance-baseline-capture-task.md
    condition: "Re-capture performance baselines after refactoring to detect regressions. Recommended when the refactored code participates in performance-critical paths (check [performance-test-tracking.md](../../../test/state-tracking/permanent/performance-test-tracking.md) Related Features column)"
  - task: ../03-testing/e2e-acceptance-test-execution-task.md
    condition: "Execute manual tests for groups marked for re-execution after refactoring"
  - task: ../cyclical/technical-debt-assessment-task.md
    condition: "Reassess technical debt after refactoring completion"
  - task: ../03-testing/test-specification-creation-task.md
    condition: "If refactoring reveals systemic test gaps that warrant a formal test specification"
---

# Code Refactoring Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Systematic code improvement and technical debt reduction without changing external behavior

## AI Agent Role

**Role**: Senior Software Engineer
**Mindset**: Pragmatic, quality-focused, delivery-oriented
**Focus Areas**: Code quality, maintainability, performance, technical debt reduction
**Communication Style**: Present trade-offs between speed and quality, discuss refactoring benefits and risks

## Context Requirements

- **Critical (Must Read):**

  - **Target Code Area** - Specific files, modules, or components to be refactored
  - **Current Code Quality Issues** - Identified problems, code smells, or technical debt items (check the **Dims** column in [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) for the primary dimension)
  - **Existing Test Coverage** - Current test suite for the code area to ensure behavior preservation

- **Important (Load If Space):**

  - **Technical Debt Assessment** - Results from Technical Debt Assessment Task if available
  - **Code Quality Metrics** - Current complexity, maintainability, and quality measurements
  - **System Architecture Documentation** - Understanding of how refactored code fits into overall system
  - **Recent Code Changes** - Git history and recent modifications to understand change patterns
  - [`refactoring-planning` craft skill](../../../.claude/skills/refactoring-planning/SKILL.md) — the Refactoring Plan customization craft (mode/template selection, scope-delta honesty, measurable baselines and goals, workflow-aware and dimension-aware patterns), activated in Step 1 (Check Recommended Skills). Replaces the retired Refactoring Plan Template Customization Guide and applies inside whichever path document creates the plan.

- **Reference Only (Access When Needed):**
  - **Coding Standards** - Project-specific coding conventions and style guides
  - **Performance Benchmarks** - Current performance metrics to ensure refactoring doesn't degrade performance
  - [Test-file customization craft (`test-specification` skill)](../../../.claude/skills/test-specification/references/test-file-customization.md) - For creating new test files when coverage gaps are identified (replaces the retired Test File Creation Guide)

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Step 1: Check Recommended Skills

Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `code-refactoring-task`. If the `refactoring-planning` craft skill is available in the session, activate it — it owns the **Refactoring Plan customization craft** this task's path documents delegate to (mode/template selection, scope-delta recording, measurable baselines and goals, workflow-aware and dimension-aware patterns). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/refactoring-planning/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The customization craft is unavailable for this run only if the skill file itself is absent (the retired procedural customization guide has no successor).

### Step 2: Effort Assessment Gate

> **🚨 SCOPE GUARD — Framework path target**: This task is for **product code only**. Before proceeding, verify the refactor target. If any target file lives in `process-framework/` or a root-level routing file (`CLAUDE.md`, `MEMORY.md`, `ai-tasks.md`), this task does **NOT** apply. Behavior-preserving framework code refactors (regex replacement, helper extraction, parser swap in `*.ps1`/`*.psm1` scripts) are handled in [Process Improvement](../support/process-improvement-task.md) (PF-TSK-009)'s execute-changes step, medium-risk path, with synthetic-harness verification — not here. **Stop now and switch tasks.** See [ai-tasks.md framework-vs-product policy](../../ai-tasks.md#framework-path-vs-product-path-disambiguation).

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

> **Key principle**: The path follows the **chosen fix approach**, not the raw size of the debt. File count and effort alone do not determine it — a 5-file dead code removal or config wiring change is Lightweight; a single-file class decomposition that changes interfaces is Standard. The same debt item can fall on either path depending on how you choose to fix it (a localized in-place patch vs. a structural redesign), so classify the approach you intend to take — and when weighing two approaches, that choice sets the path.

> **🚨 CHECKPOINT**: Present **both** a justification recommendation **and** an effort classification to the human partner for approval.
>
> **Justification recommendation** (present first):
> - **Proceed** — Refactoring is justified; benefits clearly outweigh costs and risks.
> - **Modify scope** — Refactoring has merit but the scope should be adjusted (narrower, broader, or different approach).
> - **Rejected** — Refactoring is not justified (cost > benefit, risk too high, issue is cosmetic, code is scheduled for replacement, etc.). Provide a brief rationale.
>
> **Reclassification**: If the TD describes valid work that is not technical debt, reject it and route to the correct tracker. Use the [Issue Classification and Routing Guide](../../guides/framework/issue-classification-and-routing-guide.md) to pick the destination (product bug / feature request / framework improvement) and file it with that tracker's creation script.
>
> Include the new item's ID in the TD rejection note (e.g., "Reclassified as PF-IMP-XXX") so the routing is traceable.
>
> **If the human approves Rejected**:
> 1. Identify the **source** of the tech debt item (which task, session, or agent introduced it) from [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md).
> 2. Update the tech debt item status to Rejected using `Update-TechDebt.ps1 -NewStatus "Rejected" -ResolutionNotes "Rejected: <rationale>"`.
> 3. **Root cause analysis**: Read the source task's guidance (the specific section/dimension that produced the TD item) and analyze **why** it generated an unjustified item — e.g., missing language-context filter, overly broad pattern matching, aspirational standard treated as actual practice. In the session's **feedback form**, document: the tech debt ID, the source task, the analysis of what guidance gap allowed the false positive, and a concrete recommendation for improving the source task (e.g., a process improvement via `New-ProcessImprovement.ps1`).
> 4. **Aspirational standard check**: If the rejection reason is that the referenced standard (ADR, guideline, or design doc) describes aspirational behavior rather than actual practice, update the standard to reflect reality — or create a process improvement (via `New-ProcessImprovement.ps1`) to do so — before closing the rejection. Leaving an inaccurate standard in place causes repeat false-positive TDs in future validation rounds.
> 5. Skip to the Task Completion Checklist below — no refactoring plan or code changes are needed.
>
> **Workflow awareness**: Before proceeding, check the `workflows:` metadata in the affected feature's [implementation state file](../../../doc/state-tracking/features) (or look up the feature in [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md)). Note which user workflows the refactored code participates in — this informs the scope of regression testing needed after refactoring to ensure workflow correctness is preserved.
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
- **Bug Reports** - Any bugs discovered during refactoring documented in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage
- **Updated State Files** - All relevant state tracking files updated according to the applicable path

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | [`[PF-RFP-XXX]-[refactoring-scope].md`](../../../doc/refactoring/plans) | [`New-RefactoringPlan.ps1`](../../scripts/file-creation/06-maintenance/New-RefactoringPlan.ps1) | Detailed refactoring plan with scope, approach, and timeline |
| **Creates** | [`[PF-TTS-XXX]-[task-context].md`](../../state-tracking/temporary) | [`New-TempTaskState.ps1`](../../scripts/file-creation/support/New-TempTaskState.ps1) | Work-in-progress tracking for refactoring sessions (conditional: ≥ 5 items or 3+ sessions; otherwise use refactoring plan's Implementation Tracking) |
| **Creates** | [`[PF-ADR-XXX]-[decision-title].md`](../../architecture/adrs) | [`New-ArchitectureDecision.ps1`](../../scripts/file-creation/02-design/New-ArchitectureDecision.ps1) | Architecture Decision Records for architectural refactoring |
| **Updates** | [`bug-tracking.md`](../../../doc/state-tracking/permanent/bug-tracking.md) | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) | Add bugs discovered during refactoring with 4-tier severity decision matrix |
| **Updates** | [`technical-debt-tracking.md`](../../../doc/state-tracking/permanent/technical-debt-tracking.md) + sibling [`archive/technical-debt-tracking-archive.md`](../../../doc/state-tracking/permanent/archive/technical-debt-tracking-archive.md) (archive-split 2026-05-26, PF-IMP-873) | [`Update-TechDebt.ps1`](../../scripts/update/Update-TechDebt.ps1) | Status transitions: Open → InProgress → Resolved/Rejected (auto-moves to archive ## Resolved / ## Rejected) |
| **Updates** | [`architecture-tracking.md`](../../../doc/state-tracking/permanent/architecture-tracking.md) | Manual | Improve feature status (e.g., "🔄 Needs Enhancement" → "🟡 In Progress") |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual | For foundation features (0.x.x), document architectural improvements |
| **Updates** | [`test-tracking.md`](../../../test/state-tracking/permanent/test-tracking.md) | Manual | Note test improvements or new test requirements |
| **Updates** | Product documentation (TDD, FDD, feature state file, test spec, integration narrative) | Manual | When refactoring changes module boundaries, interfaces, or design patterns (Step 12) |

## Next Tasks

- [**Code Review Task**](code-review-task.md) - Review refactored code for quality and correctness
- [**Performance Baseline Capture**](../03-testing/performance-baseline-capture-task.md) - Re-capture performance baselines after refactoring to detect regressions. Recommended when the refactored code participates in performance-critical paths (check [performance-test-tracking.md](../../../test/state-tracking/permanent/performance-test-tracking.md) Related Features column)
- [**Manual Test Execution**](../03-testing/e2e-acceptance-test-execution-task.md) - Execute manual tests for groups marked for re-execution after refactoring
- [**Technical Debt Assessment Task**](../cyclical/technical-debt-assessment-task.md) - Reassess technical debt after refactoring completion
- [**Test Specification Creation**](../03-testing/test-specification-creation-task.md) - If refactoring reveals systemic test gaps that warrant a formal test specification

<!-- merged from transition-registry entry: Code Refactoring -->
### Prerequisites for Transition

- [ ] **Refactoring Implementation Complete**: All planned refactoring work executed
- [ ] **3-Phase State Updates Complete**: All state files updated according to comprehensive checklist
  - [ ] Phase 1: Temporary state tracking, bug tracking, technical debt progress documented
  - [ ] Phase 2: Technical debt resolved, feature status improved, architecture tracking updated
  - [ ] Phase 3: Temporary state archived, context packages updated
- [ ] **Bug Discovery Complete**: Systematic bug identification performed with 4-tier decision matrix
- [ ] **ADRs Created**: Architecture Decision Records created for architectural refactoring (via New-ArchitectureDecision.ps1)
- [ ] **Quality Validation**: All tests still passing after refactoring
- [ ] **Documentation Updated**: Refactoring plan completed with results and lessons learned

### Next Task Selection

```
What was the refactoring outcome?
├─ Feature status improved to "👀 Needs Review" → Code Review
│   └─ Reason: Refactored features need testing and quality verification
├─ Bugs discovered during refactoring → Bug Triage → Bug Fixing
│   └─ Reason: Address bugs found during refactoring process
├─ Architectural changes made → Code Review (focus on architecture)
│   └─ Reason: Architectural refactoring needs specialized review
└─ Technical debt resolved → Continue Development → Code Review
    └─ Reason: Improved codebase ready for continued development
```

### Preparation for Next Task

1. **For Testing/Code Review**: Prepare summary of refactoring changes and architectural improvements
2. **For Bug Triage**: Ensure all discovered bugs are properly documented with refactoring context
3. **For Continued Development**: Update development context with improved codebase state
4. **Always**: Verify external behavior remains unchanged and all tests are passing

## Related Resources

- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - For identifying refactoring targets
- [`refactoring-planning` craft skill](../../../.claude/skills/refactoring-planning/SKILL.md) - the Refactoring Plan customization craft (replaces the retired customization guide); activated by the Check Recommended Skills step
