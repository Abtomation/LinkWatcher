---
id: PF-TSK-010
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.5
created: 2023-06-15
updated: 2026-03-29
---

# Tools Review Task

## Purpose & Context

Systematically evaluate and enhance the templates, guides, and other tools by collecting, analyzing, and implementing feedback, ensuring continuous improvement of documentation and processes.

## AI Agent Role

**Role**: DevOps Engineer
**Mindset**: Tool optimization-focused, efficiency-driven, continuous improvement-oriented
**Focus Areas**: Tool effectiveness, automation opportunities, user experience, process optimization
**Communication Style**: Focus on tool usability and efficiency gains, ask about pain points and improvement priorities

## When to Use

- After completing 5 development tasks
- Monthly, if fewer than 5 tasks have been completed
- Quarterly for comprehensive reviews
- When multiple feedback items suggest a common improvement opportunity
- When new tools or templates have been recently introduced

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/tools-review-map.md)

- **Critical (Must Read):**

  - [Feedback Forms](../../feedback) - Collected feedback on tools used in previous tasks
  - [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - Current improvement initiatives
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `-?` before running**)
  - [Task Templates](../../templates) - Templates used in tasks

- **Reference Only (Access When Needed):**
  - [Documentation Map](../../PF-documentation-map.md) - Overview of all project documentation

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Always group feedback forms by task type for consistent analysis.**
>
> **⏱️ Time Tracking**: Record your start time now for accurate feedback completion.
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review [feedback forms](../../feedback/feedback-forms/) collected at the end of each task
2. **Group feedback forms by task type** (e.g., all PF-TSK-002 forms together)
   - **🚨 BATCH SIZE LIMIT**: Evaluate a maximum of **40 feedback forms per session** to prevent context window exhaustion before analysis is complete
   - **Analysis quality over speed**: Analyze each form individually and thoroughly before moving to the next. Do not parallelize form analysis — sequential, careful reading catches improvement patterns that batch scanning misses.
   - All forms belonging to the same task type **must** be included in the same session — never split a task group across sessions
   - If total forms exceed 40, split into multiple sessions by task group boundaries (complete task groups only)
   - **Oversized task group**: When a single task group exceeds 40 forms, **task-group integrity takes priority** over the batch limit. Process the entire group in one session — do not split it. To manage context, dedicate the session exclusively to that group (no other task groups in the same session).
3. Create a structured analysis framework for each task group
4. Prepare a tracking sheet for identified improvements
5. **🚨 CHECKPOINT**: Present feedback inventory, task groupings, and initial themes to human partner for alignment

### Execution

> **🎯 UNIT OF ANALYSIS**: The output unit is the **individual improvement opportunity**, not the feedback form or task group. Task-group analysis (Steps 6–9) organizes the reading — but when registering IMPs (Step 12), each distinct actionable change must be its own entry. If a single form contains 3 independent suggestions, that's 3 IMPs. If a theme spans multiple forms but describes one change, that's 1 IMP.

6. Identify common themes and patterns across feedback **within each task group**
7. Evaluate each task type separately to ensure consistent analysis
8. Quantify ratings for effectiveness, clarity, completeness, and efficiency
9. Prioritize potential improvements based on frequency and impact
10. **🚨 CHECKPOINT**: Present analysis findings, identified themes, and prioritized improvement opportunities to human partner for approval
11. **Create review summary skeleton**: Run [`New-ReviewSummary.ps1`](../../scripts/file-creation/06-maintenance/New-ReviewSummary.ps1) now so the filename (which includes an unpredictable HHMMSS timestamp) is known before registering IMPs. Note the created filename for use in `-SourceLink` parameters below.
    ```powershell
    New-ReviewSummary.ps1 -FormsAnalyzed <N> -DateRangeStart 'YYYY-MM-DD' -DateRangeEnd 'YYYY-MM-DD'
    ```
    > Content sections will be filled during Finalization (Step 17).
12. **Routing Decision**: For each identified improvement, determine its target and use the appropriate script:

    | If the item is... | Route to... | Script |
    |---|---|---|
    | Process framework improvement (task, template, guide, script, workflow) | [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) | [`New-ProcessImprovement.ps1`](../../scripts/file-creation/support/New-ProcessImprovement.ps1) |
    | Product feature request (new capability or enhancement to existing feature) | [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) | [`New-FeatureRequest.ps1`](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1) |
    | Bug (something broken that needs fixing) | [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) |
    | Technical debt (code quality issue, not broken but should be improved) | [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) | [`Update-TechDebt.ps1 -Add`](../../scripts/update/Update-TechDebt.ps1) |

    ```powershell
    # Process framework improvement — single item
    New-ProcessImprovement.ps1 -Source "Tools Review YYYY-MM-DD" -SourceLink "../../feedback/reviews/tools-review-YYYYMMDD-HHMMSS.md" -Description "What needs improving" -Priority "MEDIUM" -Notes "Context"

    # Process framework improvements — batch mode (preferred when registering multiple IMPs)
    # Create a JSON file with an array of improvement objects, then:
    New-ProcessImprovement.ps1 -BatchFile "improvements.json"
    # Each object supports: Source, SourceLink, Description (required), Priority (required), Notes, Status

    # Product feature request — use the actual filename from Step 11
    .\New-FeatureRequest.ps1 -Source "Tools Review YYYY-MM-DD" -SourceLink "../../feedback/reviews/tools-review-YYYYMMDD-HHMMSS.md" -Description "What is being requested" -Priority "MEDIUM" -Notes "Context"
    ```
    - **🏷️ BUG vs IMP CLASSIFICATION**: The distinction is **domain-based**, not severity-based. Use the file location as the primary heuristic:
      - `process-framework/`, `doc/` → **IMP** (process framework tooling, even if the script crashes)
      - `linkwatcher/` → **BUG** (product code)
      - `test/` → either: test infrastructure issues (runner scripts, tracking) = **IMP**; product test defects = **BUG**
    - **🔗 TRACEABILITY REQUIREMENT**: Use `-SourceLink` with the actual review summary filename from Step 11 for full traceability
    - **🔍 DEDUPLICATION**: Before registering a new IMP, search both the "Current Improvement Opportunities" and "Completed Improvements" sections of [process-improvement-tracking.md](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) for existing entries covering the same tool or issue. Skip registration if already tracked.
    - **🎯 GRANULARITY**: Each IMP must describe exactly one actionable change. If a theme or feedback item contains multiple independent changes (e.g., "add X to task A, add Y to task B, add Z to task C"), register each as a separate IMP. Conversely, do not split a single cohesive change across multiple IMPs.
13. **🚨 SCOPE BOUNDARY**: Tools Review identifies and documents improvements only. For implementation, create [Process Improvement Task](process-improvement-task.md) entries or use [Feature Request Evaluation](../01-planning/feature-request-evaluation.md) for feature requests
14. Archive processed feedback forms for future reference (archive paths are needed for the next step)
15. **Record ratings in feedback database**: After archiving, extract ratings from the archived forms and record them:
    ```bash
    # Extract ratings from archived forms into JSON
    python process-framework/scripts/extract_ratings.py \
        --review-cycle-id "tools-review-YYYYMMDD" \
        --archived-prefix "process-framework-local/feedback/archive/YYYY-MM/tools-review-YYYYMMDD/processed-forms" \
        process-framework-local/feedback/archive/YYYY-MM/tools-review-YYYYMMDD/processed-forms/*feedback*.md \
        -o ratings-input.json

    # Record in database
    python process-framework/scripts/feedback_db.py record --json ratings-input.json
    ```
    The [`extract_ratings.py`](../../scripts/extract_ratings.py) script parses feedback form markdown and generates JSON matching the [feedback-db-input-template.json](../../templates/support/feedback-db-input-template.json) schema. Review the output before recording.

### Finalization

16. Verify all improvement opportunities are properly documented
17. **Fill review summary content**: Complete all sections of the review summary skeleton created in Step 11 (task group analysis, cross-group themes, improvement opportunities summary, archived forms list)
18. Ensure all tracking files are updated (process-improvement-tracking, feature-request-tracking, bug-tracking, technical-debt-tracking — as applicable)
19. Communicate identified improvements to project stakeholders
20. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Improvement Opportunities** - Documented in appropriate tracking files: [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) for framework improvements, [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) for product feature requests, [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) for bugs, [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) for tech debt
- **Review Summary** - Documentation of findings and identified improvements, using the [Tools Review Summary Template](../../templates/support/tools-review-summary-template.md). Create via [`New-ReviewSummary.ps1`](../../scripts/file-creation/06-maintenance/New-ReviewSummary.ps1)
- **Ratings Database Update** - Quantified ratings recorded in `process-framework-local/feedback/ratings.db` for trend analysis via `python process-framework/scripts/feedback_db.py record` (use [feedback-db-input-template.json](../../templates/support/feedback-db-input-template.json) as reference)
- **Process Improvement Tasks** - Created [Process Improvement Task](process-improvement-task.md) entries for implementation
- **Archive of Processed Forms** - Organized archive of processed feedback forms

## State Tracking

The following state files must be updated as part of this task:

- [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - Framework improvements identified from feedback analysis
- [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) - Product feature requests identified from feedback analysis
- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Bugs identified from feedback analysis
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Technical debt items identified from feedback analysis
- **🔗 MANDATORY**: All entries must include links to the tools review analysis file for full traceability

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Improvement opportunities documented in appropriate tracking files (process improvements, feature requests, bugs, tech debt)
  - [ ] Review summary documenting findings and identified improvements
  - [ ] [Process Improvement Task](process-improvement-task.md) entries created for implementation
  - [ ] Archive of processed feedback forms
- [ ] **Verify Feedback Grouping**: Ensure that only feedback forms for the same task type were analyzed together
- [ ] **Update State Files**: Confirm all state tracking files have been updated
  - [ ] Appropriate tracking files updated (process-improvement-tracking, feature-request-tracking, bug-tracking, technical-debt-tracking)
  - [ ] [Process Improvement Task](process-improvement-task.md) entries created for implementation
- [ ] **Solicit User Feedback**: **MANDATORY** - Actively ask the human user for their feedback on the session:
  - [ ] Ask specific questions about process effectiveness
  - [ ] Request feedback on any issues or challenges observed
  - [ ] Solicit suggestions for improvement
  - [ ] Gather overall satisfaction assessment
  - [ ] **Do not proceed** until user feedback has been collected and documented
- [ ] **Archive Processed Forms**: Move analyzed feedback forms to archive (must happen before recording ratings):
  - [ ] Create archive folder: `/process-framework-local/feedback/archive/YYYY-MM/tools-review-YYYYMMDD`
  - [ ] Create subfolder: `processed-forms/` within the archive folder
  - [ ] **⚠️ CRITICAL DISTINCTION**: Only move feedback forms that were **analyzed during this session**
    - ✅ **Archive These**: Feedback forms that you reviewed, analyzed, and extracted improvements from
    - ❌ **DO NOT Archive**: Newly created feedback forms (including the PF-TSK-010 form created for this session)
    - ❌ **DO NOT Archive**: Feedback forms that haven't been analyzed yet
  - [ ] Move only the analyzed feedback forms to the `processed-forms/` subfolder
  - [ ] **Keep Active**: Leave newly created feedback forms in the active feedback-forms folder for future analysis
  - [ ] Document which specific forms were archived vs. kept active in the review summary
- [ ] **Record Ratings**: Extract ratings via [`extract_ratings.py`](../../scripts/extract_ratings.py) and record in database via `feedback_db.py record` (see Step 15 for commands)
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-010" and context "Tools Review"
- [ ] **Schedule Next Review**: Set a reminder for the next tools review cycle

## Next Tasks

- [**Process Improvement**](process-improvement-task.md) - For implementing larger process changes

## Related Resources

- [Feedback Process Guide](../../../process-framework-local/feedback/archive/README.md) - Guide for collecting and processing feedback
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks

## Critical Process Note

**USER FEEDBACK IS MANDATORY**: The AI assistant must actively solicit and collect human user feedback before completing any feedback form. This is not optional - the process cannot be considered complete without genuine user input on the session's effectiveness, challenges, and improvement suggestions.
