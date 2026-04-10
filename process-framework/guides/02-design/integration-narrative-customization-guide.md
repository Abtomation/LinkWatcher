---
id: PF-GDE-059
type: Process Framework
category: Guide
version: 1.0
created: 2026-04-08
updated: 2026-04-08
related_task: PF-TSK-083
related_script: New-IntegrationNarrative.ps1
---

# Integration Narrative Customization Guide

## Overview

This guide provides step-by-step instructions for customizing Integration Narrative documents created by `New-IntegrationNarrative.ps1`. Integration Narratives explain how 2+ features collaborate in a cross-cutting workflow — filling in the template requires reading source code, not just TDDs.

## When to Use

Use this guide when customizing an Integration Narrative created by the [Integration Narrative Creation task](/process-framework/tasks/02-design/integration-narrative-creation.md) (PF-TSK-083). The script creates the document structure; this guide helps you fill it with verified, accurate content.

> **🚨 CRITICAL**: All cross-feature interactions documented in the narrative MUST be verified against actual source code. TDDs may be outdated. The narrative documents what the code *actually does*, not what design docs claim.

## Prerequisites

Before you begin, ensure you have:

- The Integration Narrative file created by `New-IntegrationNarrative.ps1` (PD-INT-XXX)
- Access to [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) to identify participating features
- Feature TDDs and ADRs for the participating features (paths in feature state files)
- The ability to read source code for all participating features

## Template Structure Analysis

The Integration Narrative template (PF-TEM-070) contains these sections, organized from high-level to detailed:

### Script-Populated Fields

The following are auto-populated by `New-IntegrationNarrative.ps1` — no customization needed:

- **Metadata** (`workflow_id`, `workflow_name`, dates, ID)
- **Title** (`# Integration Narrative: [Workflow Name]`)
- **Subtitle** (`> **Workflow**: [Workflow ID] — [Description]`)

### Sections Requiring Customization

| Section | Purpose | Required? |
|---------|---------|-----------|
| Workflow Overview | Entry point, exit point, flow summary | Yes |
| Participating Features | Feature table with workflow roles | Yes |
| Component Interaction Diagram | Mermaid diagram of cross-feature connections | Yes |
| Data Flow Sequence | Step-by-step data transformation pipeline | Yes |
| Callback/Event Chains | Event propagation across feature boundaries | Conditional |
| Configuration Propagation | Config values affecting multiple features | Conditional |
| Error Handling Across Boundaries | Error propagation and recovery | Yes |
| TDD/Code Divergence Notes | Discrepancies found during creation | Conditional |

**Conditional** sections: Include when the workflow uses that mechanism. Replace with the provided "not applicable" text when it doesn't apply.

### Section Dependencies

Complete sections in template order — later sections build on earlier ones:

1. **Workflow Overview** defines scope → informs which features to list
2. **Participating Features** identifies components → informs the diagram
3. **Component Interaction Diagram** maps connections → informs data flow details
4. **Data Flow Sequence** traces the pipeline → reveals callback/event patterns
5. **Callback/Event Chains** + **Configuration Propagation** + **Error Handling** fill in cross-cutting details discovered while writing sections 3-4

## Customization Decision Points

### Workflow Scope Decision

**Decision**: How wide should the narrative's scope be?

**Criteria**:
- A narrative should cover one complete workflow from trigger to outcome
- If a workflow has clearly independent sub-pipelines, consider separate narratives
- If two workflows share significant components, they may warrant a combined narrative

**Guideline**: Match the scope to what appears in [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md). Each row = one narrative.

### Diagram Detail Level Decision

**Decision**: How much internal feature detail to show in the Mermaid diagram?

**Criteria**:
- Show only components that interact across feature boundaries
- Omit purely internal feature components (those belong in TDDs)
- Include data stores only if multiple features read/write them
- Show 5-15 components; beyond 15, consider splitting

### TDD Trust Decision

**Decision**: When TDD and source code disagree, which to document?

**Answer**: Always document the source code behavior. Report the divergence as technical debt via `Update-TechDebt.ps1` and note it in the TDD/Code Divergence Notes section.

## Step-by-Step Instructions

### 1. Fill in Workflow Overview

Read the workflow entry in [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) and the feature state files for participating features.

1. Identify the **entry point** — the event or action that starts the workflow. Be specific (e.g., "A `FileSystemEvent` is emitted by the watchdog observer", not "A file is moved").
2. Identify the **exit point** — the observable outcome when the workflow completes.
3. Write the **flow summary** in 2-3 sentences describing the pipeline at a high level.

**Expected Result:** Three filled paragraphs that answer: what triggers it, what it produces, and how it flows.

### 2. Fill in Participating Features Table

1. Check [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) for the list of features in this workflow.
2. For each feature, describe its **role in this specific workflow** — not its general purpose. Example: "Correlates delete+create events within a time window to detect moves" (good) vs. "Handles move detection" (too vague).
3. Include only features that actively participate in the cross-feature data flow. Supporting features (e.g., logging, config loading) should only appear if they have workflow-specific behavior.

**Expected Result:** A table with 2-6 features, each with a specific role description.

### 3. Create Component Interaction Diagram

1. For each participating feature, identify the **source files** that implement the cross-feature interaction points. Read the actual source code.
2. List the components (classes, functions, modules) that sit at feature boundaries — where data crosses from one feature to another.
3. Draw the Mermaid diagram using the [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md):
   - Use `([Component])` for logic, `[(Database)]` for storage, `[/File/]` for file I/O
   - Label edges with what is passed: data types, event names, or callback signatures
   - Apply priority classes: `critical` (entry/exit), `important` (core pipeline), `reference` (supporting)
4. Verify each connection in the diagram exists in actual source code — check function calls, imports, and instantiation.

**Expected Result:** A Mermaid diagram with 5-15 components showing cross-feature connections with labeled edges.

### 4. Document Data Flow Sequence

This is the most important section — it traces the complete data transformation pipeline.

1. Start at the entry point identified in Step 1.
2. For each component in the pipeline:
   - Name the component and the **specific function/method** that handles the data (e.g., `MoveDetector.process_event()`, not just "MoveDetector")
   - Describe the **input data structure** it receives (type, key fields)
   - Describe **what it does** with the data — be concrete
   - Describe the **output data structure** it passes to the next component
3. Follow the data through every feature boundary until it reaches the exit point.
4. Verify each step by reading the actual source code. If the TDD says something different from the code, document what the code does.

**Expected Result:** A numbered sequence of 4-10 steps, each naming a specific function and describing the data transformation.

### 5. Document Callback/Event Chains (if applicable)

1. Search the source code for callback registrations, event handlers, observer patterns, or signal/slot connections that cross feature boundaries in this workflow.
2. For each chain found:
   - Where the callback is registered (file and function)
   - What triggers it (event name, condition)
   - What the handler does (file and function)
   - Which feature boundaries are crossed
3. If no callback/event mechanisms are used in this workflow, replace the section content with the "not applicable" text provided in the template comments.

**Expected Result:** One or more documented callback chains, or an explicit "not applicable" statement.

### 6. Document Configuration Propagation (if applicable)

1. Identify config values that affect more than one feature in this workflow. Check config files, CLI argument parsing, and environment variable handling.
2. For each shared config value, trace its path from definition to consumption.
3. If features use independent configuration with no cross-feature propagation, replace the section content with the "not applicable" text in the template comments.

**Expected Result:** A table of shared config values with their propagation paths, or an explicit "not applicable" statement.

### 7. Document Error Handling Across Boundaries

1. For each feature boundary crossing identified in Steps 3-4, examine what happens when the upstream component fails.
2. Document: where errors originate, how they propagate (exceptions, error codes, null results), what downstream features do, and how the workflow recovers.
3. Pay special attention to partial completion scenarios — does the workflow leave the system in an inconsistent state if it fails midway?

**Expected Result:** One or more error scenarios documented with origin, propagation, impact, and recovery.

### 8. Record TDD/Code Divergence

1. Review the divergences found during Steps 3-7.
2. For each divergence, add a row to the table: which TDD, what it claims, what the code does, and the tech debt ID (from `Update-TechDebt.ps1` — reported in task Step 7).
3. If no divergences were found, replace the table with the "no divergences" text in the template comments.

**Expected Result:** A divergence table or an explicit "no divergences" statement.

## Quality Assurance

### Self-Review Checklist

- [ ] Every cross-feature interaction is verified against source code (not just TDDs)
- [ ] Component Interaction Diagram matches the Data Flow Sequence (no orphan components)
- [ ] Data types/structures at each boundary are specified (not just "data")
- [ ] Specific function/method names are used (not just class/module names)
- [ ] All conditional sections have content or explicit "not applicable" statements
- [ ] TDD/code divergences are reported as tech debt items
- [ ] Diagram uses correct Visual Notation Guide symbols

### Completeness Check

A well-written Integration Narrative should enable someone to:
1. Trace a request/event from entry to exit through all participating features
2. Identify which component to investigate when a cross-feature bug is reported
3. Understand what config values affect the workflow's behavior
4. Know what happens when a component in the middle of the pipeline fails

If any of these would still require reading 3+ separate documents, the narrative needs more detail.

## Examples

### Example: Filling in a Data Flow Sequence Step

**Source code reading** (`linkwatcher/handler.py`):
```python
def on_moved(self, event):
    old_path = event.src_path
    new_path = event.dest_path
    self.service.handle_move(old_path, new_path)
```

**Resulting narrative step**:
> 2. **EventHandler.on_moved()** receives `FileMovedEvent(src_path, dest_path)`
>    - Extracts old and new paths from the watchdog event
>    - Passes to: `LinkWatcherService.handle_move(old_path, new_path)`

### Example: "Not Applicable" Replacement

When a workflow uses direct function calls with no callbacks:

> **Callback/Event Chains**
>
> This workflow uses direct function calls between components. No callback or event chain mechanisms are used.

## Troubleshooting

### Diagram Shows Too Many Components

**Symptom:** Mermaid diagram has 20+ components and is hard to read.

**Cause:** Including internal feature components that don't participate in cross-feature interactions.

**Solution:** Remove components that don't sit at a feature boundary. If component A calls component B and both belong to the same feature, show only the one that interacts with another feature.

### TDD and Code Disagree on Data Types

**Symptom:** TDD says a function accepts `str` but code shows it accepts `Path`.

**Cause:** Code evolved after TDD was written.

**Solution:** Document the code's actual behavior in the narrative. Report the divergence via `Update-TechDebt.ps1` and add a row to the TDD/Code Divergence Notes table.

### Unclear Where One Workflow Ends and Another Begins

**Symptom:** Following the data flow leads into a different workflow's territory.

**Cause:** Workflow boundaries aren't well-defined in user-workflow-tracking.md.

**Solution:** Discuss with human partner. The rule of thumb: a workflow ends when the primary objective is achieved. Secondary effects (logging, cache invalidation) that feed other workflows should be noted but not followed.

## Related Resources

- [Integration Narrative Template](/process-framework/templates/02-design/integration-narrative-template.md) (PF-TEM-070) - The template this guide customizes
- [Integration Narrative Creation Task](/process-framework/tasks/02-design/integration-narrative-creation.md) (PF-TSK-083) - The task that uses this guide
- [New-IntegrationNarrative.ps1](/process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1) - Script that creates narrative documents
- [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - Diagram notation standards
- [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) - Workflow definitions and feature mapping
