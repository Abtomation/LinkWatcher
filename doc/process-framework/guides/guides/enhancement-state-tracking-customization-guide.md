---
id: PF-GDE-047
type: Document
category: General
version: 2.0
created: 2026-02-19
updated: 2026-02-19
guide_description: Step-by-step instructions for customizing Enhancement State Tracking files created by New-EnhancementState.ps1
guide_title: Enhancement State Tracking Customization Guide
related_script: New-EnhancementState.ps1
guide_status: Active
related_tasks: PF-TSK-067,PF-TSK-068
---

# Enhancement State Tracking Customization Guide

## Overview

This guide provides step-by-step instructions for customizing Enhancement State Tracking files after they are created by `New-EnhancementState.ps1`. The generated file contains pre-defined workflow blocks that follow the standard feature development workflow from the [Task Transition Guide](task-transition-guide.md). Each block must be evaluated and marked as applicable or not applicable for the specific enhancement. This guide is used during the Feature Request Evaluation task (PF-TSK-067).

## When to Use

Use this guide immediately after running `New-EnhancementState.ps1` during the Feature Request Evaluation task. At this point you should have:

1. Classified the change request as an enhancement (not a new feature)
2. Proposed a target feature and received human approval
3. Assessed the enhancement scope using practical criteria
4. Run `New-EnhancementState.ps1` to create the structural file

> **CRITICAL**: Do not skip customization. The generated file contains placeholders that will not be useful to the Feature Enhancement task (PF-TSK-068) without customization.

## Prerequisites

Before you begin, ensure you have:

- The generated Enhancement State Tracking file (output of `New-EnhancementState.ps1`)
- The target feature's implementation state file (in `state-tracking/features/`)
- Access to the target feature's existing design docs (FDD, TDD, ADR) if they exist
- The original change request description
- Human approval of the target feature
- The target feature's current documentation tier (from feature tracking)

## Step-by-Step Instructions

### Step 1: Complete the Enhancement Overview

Replace the metadata table placeholders:

| Field | How to Fill |
|-------|-------------|
| **Target Feature** | Feature ID and name from feature tracking (e.g., "5.1.7 — Windows Dev Scripts") |
| **Enhancement Description** | One-sentence summary of what the enhancement adds or changes |
| **Change Request** | The human partner's original description of what they want |
| **Human Approval** | Date the human partner confirmed the target feature |
| **Estimated Sessions** | 1 for single-session work, 2+ for multi-session (based on scope assessment) |

**Expected Result:** All placeholder values in the Enhancement Overview table are replaced with specific content.

### Step 2: Fill the Scope Assessment

Replace each criterion in the Scope Assessment table based on your analysis:

- **Files Affected**: Count and list the key source files, test files, and documentation files that will change
- **Design Docs to Amend**: Specify which existing FDD, TDD, or ADR documents need updating, or "None" if no design docs exist
- **New Tests Required**: "Yes — [describe new test cases]" or "No — modify existing tests only"
- **Interface Impact**: "Public interface change" if the feature's external behavior changes, or "Internal only" if the change is hidden from consumers
- **Session Estimate**: "Single session" or "Multi-session" with brief rationale

**Expected Result:** Each criterion has a specific assessment, not a placeholder.

### Step 3: Populate the Documentation Inventory

For each row in the Existing Documentation Inventory table:

1. Check the target feature's implementation state file for links to existing design docs
2. For each document type (FDD, TDD, ADR, Test Spec), fill in the ID, location, and action needed
3. Use "N/A" for document types that don't exist and aren't needed
4. Use "None exists" with action "Create" if a document doesn't exist but is needed

**Expected Result:** A complete inventory of existing documentation with clear action directives for each.

### Step 4: Evaluate Each Workflow Block

This is the most important customization step. The template contains 17 pre-defined workflow blocks following the standard feature development workflow. For **each block**, you must:

1. **Set Applicable to "Yes" or "No"** based on whether this type of work is needed for the enhancement
2. **Fill the Rationale** explaining why the block is or is not needed
3. **Customize the Adaptation Notes** with specific details for applicable blocks
4. **Set the Deliverable** to describe what the block will produce
5. **Assign a Session number** for applicable blocks

#### Block-by-Block Evaluation Guide

| Step | Block | When to Mark Applicable | When to Mark Not Applicable |
|------|-------|------------------------|----------------------------|
| **1. Tier Reassessment** | When enhancement significantly changes feature complexity (e.g., adding major subsystem to Tier 1 feature) | When enhancement is minor and doesn't change overall complexity |
| **2. FDD Amendment** | When enhancement changes user-facing behavior on a Tier 2+ feature that has an FDD | When feature has no FDD, or enhancement is purely internal |
| **3. System Architecture Review** | When enhancement introduces new patterns, cross-cutting concerns, or architectural changes | When enhancement works within existing architecture |
| **4. API Design Amendment** | When enhancement modifies API endpoints, contracts, or data access patterns | When no API changes are required |
| **5. DB Schema Design Amendment** | When enhancement requires new tables, columns, relationships, or migrations | When no database changes are required |
| **6. TDD Amendment** | When enhancement changes technical design on a Tier 2+ feature that has a TDD | When feature has no TDD, or enhancement doesn't change technical approach |
| **7. Test Specification** | When enhancement adds significant new testable behavior on a Tier 3 feature, or when existing test spec needs updating | When feature has no test spec and one isn't needed, or existing tests cover the change |
| **8. Feature Implementation Planning** | When enhancement is complex enough to benefit from upfront planning (multi-layer, multi-session) | When enhancement is straightforward and can proceed directly to implementation |
| **9. Data Layer Implementation** | When enhancement changes data models, repositories, or database integration | When no data model changes are required |
| **10. State Management Implementation** | When enhancement changes state management, providers, or notifiers | When no state layer changes are required |
| **11. UI Implementation** | When enhancement changes user interface components, widgets, or screens | When no UI changes are required |
| **12. Integration & Testing** | When enhancement touches multiple layers that need integration verification | When single-layer change with no integration concerns |
| **13. Quality Validation** | When significant enhancement needs quality auditing (performance, security, accessibility) | When minor change where code review suffices |
| **14. Implementation Finalization** | When multi-session enhancement needs final cleanup and preparation | When single-session enhancement with no finalization needed |
| **15. Update Tests** | When enhancement changes testable behavior and tests exist or are needed | When enhancement is trivial and manual verification suffices |
| **16. Code Review** | When enhancement modifies core logic or has non-trivial changes | When change is trivial (e.g., single config line) |
| **17. Update Feature State** | **Always applicable** — state file must always be updated | Never mark as not applicable |

**For Not Applicable blocks**: Set `Applicable: No`, fill the Rationale explaining why, and leave Adaptation Notes and Deliverable as "N/A". The Feature Enhancement task will skip these blocks.

**Expected Result:** Every block has Applicable set to Yes or No with a rationale. Applicable blocks have specific adaptation notes, deliverables, and session assignments.

### Step 5: Plan Session Boundaries (Multi-Session Only)

For multi-session enhancements:

1. Review the session numbers assigned to each applicable block
2. Group blocks into sessions based on natural work boundaries
3. Fill in the Session Boundary Planning section with session focus areas and goals
4. Ensure each session has a clear completion checkpoint

For single-session enhancements: Remove the Session Boundary Planning section entirely.

**Expected Result:** Clear session-by-session grouping of work, or section removed for single-session enhancements.

### Step 6: Clean Up

1. Ensure the Session Log section has a placeholder for Session 1 with the correct date
2. Verify the Finalization Checklist is intact
3. Do a final scan for any remaining `[bracketed placeholders]` that should have been replaced

**Expected Result:** A clean, customized state file ready for the Feature Enhancement task to consume.

## Examples

### Example: Single-Session Enhancement (Small Scope — Tier 1 Feature)

**Scenario**: Adding duplicate instance check to LinkWatcher startup scripts (Feature 5.1.7, Tier 1)

```markdown
## Execution Steps

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Enhancement is a minor addition to a Tier 1 feature. Adding a process check does not change the feature's overall complexity.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 2: FDD Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No FDD exists for this Tier 1 feature, and the enhancement doesn't warrant creating one.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Enhancement works within existing startup script architecture.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No API involved in startup scripts.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No database involved.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 6: TDD Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No TDD exists for this Tier 1 feature.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 7: Test Specification

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Manual verification only — checking if duplicate instance detection works.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Enhancement is straightforward — add process check to scripts. No planning needed.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 9: Data Layer Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No data model changes required.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 10: State Management Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No state layer changes required.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 11: UI Implementation

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: Enhancement modifies PowerShell startup scripts (user-facing entry points).
- **Adaptation Notes**: Add process detection logic to existing startup scripts (start_linkwatcher.ps1, start_linkwatcher_background.ps1). Check for running python processes with LinkWatcher arguments before starting a new instance.
- **Deliverable**: Updated startup scripts with duplicate instance prevention
- **Session**: 1

### Step 12: Integration & Testing

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Single-layer change with no integration concerns.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 13: Quality Validation

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Minor change, code review would suffice but is also skipped (see Step 16).
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Single-session enhancement, no finalization needed.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 15: Update Tests

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Manual verification only — no automated tests for PowerShell startup scripts.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 16: Code Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Trivial change to startup scripts with no behavioral impact on the core system.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 17: Update Feature State

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: Feature state must always be updated
- **Adaptation Notes**: Update 5.1.7 implementation state file to document the duplicate instance check enhancement.
- **Deliverable**: Updated feature state file reflecting the new capability
- **Session**: 1
```

### Example: Multi-Session Enhancement (Larger Scope — Tier 2 Feature)

**Scenario**: Adding retry logic with configurable backoff to the YAML parser (Feature 2.1.3, Tier 2)

```markdown
## Execution Steps

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Adding retry logic is a moderate extension. The feature remains Tier 2 — it doesn't introduce enough complexity to warrant Tier 3 documentation.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 2: FDD Amendment

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: The FDD describes parser behavior including error handling. Retry logic changes the user-facing behavior when parsing fails.
- **Adaptation Notes**: Amend the Error Handling section of the existing FDD (PD-FDD-005) to describe retry behavior from the user's perspective: when retries happen, what the user sees during retries, and how permanent failures are reported.
- **Deliverable**: Updated FDD with retry behavior in Error Handling section
- **Session**: 1

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Retry logic is contained within the YAML parser module. No cross-cutting concerns or new architectural patterns introduced.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No API endpoints involved — parser is used internally.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No database changes required for retry logic.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 6: TDD Amendment

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: The TDD describes parser implementation including error handling. Retry logic requires technical design for backoff strategy and failure thresholds.
- **Adaptation Notes**: Add "Retry Logic" subsection to existing TDD's (PD-TDD-008) Error Handling section. Define: retry count configuration, exponential backoff algorithm, jitter strategy, failure threshold, and integration with existing error reporting.
- **Deliverable**: Updated TDD with retry configuration, backoff strategy, and failure thresholds
- **Session**: 1

### Step 7: Test Specification

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Feature is Tier 2 — no formal test specification exists. Test cases will be defined during the Update Tests step.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Enhancement scope is clear from the TDD amendment — no separate planning step needed.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 9: Data Layer Implementation

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: Enhancement adds configuration parameters (retry count, backoff base, max delay) to the settings model.
- **Adaptation Notes**: Add retry configuration fields to existing settings.py/defaults.py configuration model. Follow existing configuration patterns.
- **Deliverable**: Updated settings.py with retry configuration parameters
- **Session**: 2

### Step 10: State Management Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No state management layer in LinkWatcher — configuration is loaded directly.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 11: UI Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: No UI involved — retry is internal parser behavior.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 12: Integration & Testing

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: Retry logic spans configuration loading and parser execution — needs integration verification.
- **Adaptation Notes**: Extend existing YamlParser class with retry wrapper. Do not modify the parser's public interface — retry should be transparent to callers. Verify configuration loads correctly and retry behavior works end-to-end.
- **Deliverable**: Updated yaml_parser.py with retry capability, integration verified
- **Session**: 2

### Step 13: Quality Validation

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Code review (Step 16) is sufficient for this enhancement.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Two-session enhancement but finalization is handled within Session 2.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

### Step 15: Update Tests

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: Retry logic introduces new testable behavior: retry counts, backoff timing, failure scenarios.
- **Adaptation Notes**: Add test cases to existing test_yaml_parser.py. Test: successful retry after transient failure, max retry exhaustion, backoff timing verification, configuration parameter validation.
- **Deliverable**: Updated test file with retry logic coverage
- **Session**: 2

### Step 16: Code Review

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: Retry logic modifies core parser behavior and introduces timing-sensitive code.
- **Adaptation Notes**: Focus review on: thread safety of retry state, backoff calculation correctness, proper exception handling during retries, and configuration validation.
- **Deliverable**: Code review completed and any issues resolved
- **Session**: 2

### Step 17: Update Feature State

- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: Feature state must always be updated
- **Adaptation Notes**: Update 2.1.3 implementation state file to document the retry logic enhancement. Add retry configuration to the feature's capabilities list.
- **Deliverable**: Updated feature state file reflecting the new retry capability
- **Session**: 2
```

## Troubleshooting

### Placeholder content remains after customization

**Symptom:** The Feature Enhancement task encounters `[bracketed placeholders]` in the state file.

**Cause:** Customization step was incomplete or a block was missed.

**Solution:** Search the file for `[` and replace all remaining placeholders with actual content. Pay special attention to the Applicable, Rationale, and Adaptation Notes fields in each block.

### Unsure whether a block should be applicable

**Symptom:** You can't decide if a workflow block is needed for the enhancement.

**Cause:** The enhancement's scope is unclear, or it sits on the boundary between needing and not needing a particular type of work.

**Solution:** Use the Block-by-Block Evaluation Guide in Step 4 above. When in doubt, mark the block as applicable with a note — it's better to have the Feature Enhancement task evaluate and skip a block than to miss needed work. The Feature Enhancement task can add a note like "Evaluated and confirmed not needed" during execution.

### Enhancement seems too large for the Enhancement Workflow

**Symptom:** Most or all blocks are marked applicable, the session estimate is 3+, or the enhancement feels like a new feature.

**Cause:** The change request may have been misclassified. Very large modifications may be better handled as new features through the standard Feature Development Workflow.

**Solution:** Re-evaluate whether this is truly an enhancement or a new feature. Consult the human partner. If reclassified as a new feature, archive the Enhancement State Tracking File and route to the Feature Development Workflow (Feature Tier Assessment → FDD → etc.).

## Related Resources

- [Enhancement State Tracking Template (PF-TEM-045)](../../templates/templates/enhancement-state-tracking-template-template.md) — The template that `New-EnhancementState.ps1` uses
- [Feature Request Evaluation Task (PF-TSK-067)](../../tasks/01-planning/feature-request-evaluation.md) — The task that uses this guide
- [Feature Enhancement Task (PF-TSK-068)](../../tasks/04-implementation/feature-enhancement.md) — The task that consumes the customized state file
- [Enhancement Workflow Concept (PF-PRO-002)](../../proposals/proposals/enhancement-workflow-concept.md) — Design rationale for the workflow
- [Task Transition Guide](task-transition-guide.md) — The standard feature development workflow that this template follows
- [Documentation Tier Adjustment (PF-TSK-011)](../../tasks/cyclical/documentation-tier-adjustment-task.md) — Referenced by Step 1 (Tier Reassessment)
