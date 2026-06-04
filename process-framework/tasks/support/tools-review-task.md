---
id: PF-TSK-010
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.8
created: 2023-06-15
updated: 2026-05-16
description: "Review and improve project tools and templates"
---

# Tools Review Task

## Purpose & Context

Systematically evaluate and enhance the templates, guides, and other tools by collecting, analyzing, and implementing feedback, ensuring continuous improvement of documentation and processes.

## AI Agent Role

**Role**: DevOps Engineer
**Mindset**: Tool optimization-focused, efficiency-driven, continuous improvement-oriented
**Focus Areas**: Tool effectiveness, automation opportunities, user experience, process optimization
**Communication Style**: Focus on tool usability and efficiency gains, ask about pain points and improvement priorities

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/tools-review-map.md)

- **Critical (Must Read):**

  - **Central feedback forms** at `appdev/process-framework-central/feedback/feedback-forms/` — incoming forms from all registered projects, named `YYYYMMDD-HHMMSS_<PRJ-ID>_PF-TSK-XXX_feedback.md` (Phase 7 cutover, 2026-05-11). All sessions read from this location regardless of cwd.
  - **Central process-improvement-tracking.md** at `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` — Tools Review writes new IMPs to its **Section 1 — Intake** subsection only; downstream routing is owned by IMP Triage (PF-TSK-089).
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `-?` before running**)
  - [Task Templates](../../templates) - Templates used in tasks

- **Reference Only (Access When Needed):**
  - [Documentation Map](../../PF-documentation-map.md) - Overview of all project documentation
  - [IMP Triage Task (PF-TSK-089)](imp-triage-task.md) - The downstream task that drains the Intake section

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Always group feedback forms by task type for consistent analysis.**
>
> **⏱️ Time Tracking**: Record your start time now for accurate feedback completion.
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review feedback forms collected at the end of each task. Source location: `appdev/process-framework-central/feedback/feedback-forms/` (Phase 7 cutover, 2026-05-11). Form filenames follow `YYYYMMDD-HHMMSS_<PRJ-ID>_PF-TSK-XXX_feedback.md` — the `<PRJ-ID>` segment identifies which project produced the form. Pre-cutover forms with the legacy `YYYYMMDD-HHMMSS-PF-TSK-XXX-feedback.md` naming have been migrated by Phase 7.5 and live at the same central path; treat them as project-of-origin = unknown unless their frontmatter declares otherwise.
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
    > Content sections will be filled during Finalization (Step 17). Skeleton-only at this stage.
12. **Classify and register each improvement** — Phase 7 collect-only model (2026-05-11). Tools Review does **not** triage; it only routes by domain (framework vs. product) and lets the downstream task handle priority/section/owner assignment.

    | If the item is... | Route to... | Script |
    |---|---|---|
    | Process framework improvement (task, template, guide, script, workflow) | **Central Intake section** of `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` (Section 1 — Intake) | [`New-ProcessImprovement.ps1`](../../scripts/file-creation/support/New-ProcessImprovement.ps1) |
    | Product feature request (new capability or enhancement to existing feature) | Project-local [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) (per project, not central) | [`New-FeatureRequest.ps1`](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1) |
    | Bug (something broken that needs fixing) | Project-local [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) (per project) | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) |
    | Technical debt (code quality issue, not broken but should be improved) | Project-local [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) (per project) | [`Update-TechDebt.ps1 -Add`](../../scripts/update/Update-TechDebt.ps1) |

    > **🎯 NEW IN PHASE 7**: Framework IMPs land in the central **Intake** section with a 7-column row (no Priority/Status/Resp Task cells). The [IMP Triage Task (PF-TSK-089)](imp-triage-task.md) then sorts Intake rows into Improvements / Extensions / Structural Changes / Active Pilots / Rejected based on classification. Tools Review's job is observation + intake, not classification.

    ```powershell
    # Framework improvement — single item (lands in Intake)
    # Phase 7: -Priority / -Status / -RespTask params no longer accepted; routing happens during Triage.
    New-ProcessImprovement.ps1 -Source "Tools Review YYYY-MM-DD" -SourceLink "appdev/process-framework-central/feedback/reviews/tools-review-YYYYMMDD-HHMMSS.md" -Description "What needs improving" -Notes "Context"

    # Framework improvements — batch mode (preferred when registering multiple IMPs)
    # Create a JSON file with an array of improvement objects, then:
    New-ProcessImprovement.ps1 -BatchFile "improvements.json"
    # Each object supports: Source, SourceLink, Description (required), Notes. Phase 7: Priority/Status/RespTask are
    # silently ignored on intake (warning emitted) — pass them to Update-ProcessImprovement.ps1 -MoveToSection after Triage.

    # Product feature request — use the actual filename from Step 11
    .\New-FeatureRequest.ps1 -Source "Tools Review YYYY-MM-DD" -SourceLink "appdev/process-framework-central/feedback/reviews/tools-review-YYYYMMDD-HHMMSS.md" -Description "What is being requested" -Priority "MEDIUM" -Notes "Context"
    ```
    - **📥 SUBSECTIONS TO DRAIN**: Each feedback form has two IMP-yielding subsections — `## Improvement Suggestions` (especially `### What could be improved` and `### Specific suggestions`) AND `### Documentation Streamlining Opportunities` (under `## Follow-up Actions Required`). The checkbox-todo formatting of Streamlining Opportunities does NOT mean human-only work; each checkbox item is an IMP candidate. Drain both.
    - **🏷️ BUG vs IMP CLASSIFICATION**: The distinction is **domain-based**, not severity-based. Use the file location as the primary heuristic:
      - `process-framework/`, `doc/` (in projects) or `blueprint/process-framework/`, `blueprint/doc/` (in appdev) → **IMP** (framework tooling, even if the script crashes)
      - `src/...` → **BUG** (product code)
      - `test/` → either: test infrastructure issues (runner scripts, tracking) = **IMP**; product test defects = **BUG**
    - **🔗 TRACEABILITY REQUIREMENT**: Use `-SourceLink` with the actual review summary filename from Step 11 for full traceability. The review summary itself lives at `appdev/process-framework-central/feedback/reviews/` post-Phase-7.
    - **🎯 ROUTING HINT (optional, goes in Notes)**: When the analysis you've already done makes the destination section obvious — multi-component scope (new task + template + script + guide) → suggests Extension; pure file/directory reorganization → suggests Structural Change; new task creation → suggests Extension via PF-TSK-001 — note that observation in `-Notes` as a hint to Triage (e.g., `-Notes "Triage hint: extension scope (new task + template + guide)"`). **Do not pass `-RespTask`** — that parameter no longer exists in Phase 7's New-ProcessImprovement intake path. Triage decides routing.
    - **🔍 DEDUPLICATION**: Before registering a new IMP, search **all open and closed sections** of the central process-improvement-tracking.md (Intake / Improvements / Extensions / Structural Changes / Active Pilots / Completed / Rejected) for existing entries covering the same tool or issue. Also search the project's own [technical-debt-tracking.md](../../../doc/state-tracking/permanent/technical-debt-tracking.md) — script/automation defects sometimes land there first when discovered mid-task. Skip registration if already tracked in either.
    - **🎯 GRANULARITY**: Each IMP must describe exactly one actionable change. If a theme or feedback item contains multiple independent changes (e.g., "add X to task A, add Y to task B, add Z to task C"), register each as a separate IMP. Conversely, do not split a single cohesive change across multiple IMPs.
13. **🚨 SCOPE BOUNDARY**: Tools Review identifies and documents improvements only. Triage is the **next** task, not part of this one. Hand off to [IMP Triage (PF-TSK-089)](imp-triage-task.md) — it drains the Intake section and routes rows to Improvements / Extensions / Structural Changes / Active Pilots / Rejected. For product items, the appropriate downstream is [Feature Request Evaluation](../01-planning/feature-request-evaluation.md) (feature requests) or [Bug Triage](../06-maintenance/bug-triage-task.md) (bugs).
14. **Archive processed feedback forms** (paths feed Step 15). Phase 7 cutover: archives live under `appdev/process-framework-central/feedback/archive/` regardless of which project's forms are being processed (cross-project shared archive).
    1. **Create the archive folder using the same HHMMSS as the review summary filename from Step 11** so concurrent same-date sessions stay isolated:
       `appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS/processed-forms/`
    2. **Build an explicit move list** — enumerate the exact filenames of the forms you analyzed this session (the same list that goes into the review summary's Archived Forms section). Do **not** use a `*.md` glob: concurrent sessions may have created additional forms in the active folder since you started reading.
    3. **Move by explicit filename list** (e.g., `Move-Item -Path 'appdev/process-framework-central/feedback/feedback-forms/<form1>.md','...<form2>.md',… -Destination '<archive>/'`), not by glob.
    4. **Verify after move**: count of files in the new archive folder equals length of your move list, AND none of the listed filenames remain in `appdev/process-framework-central/feedback/feedback-forms/`. Stop and reconcile before Step 15 if either check fails.
15. **Record ratings in feedback database**: After archiving, extract ratings from the archived forms and record them:
    ```bash
    # Extract ratings from archived forms into JSON
    # Use the same YYYYMMDD-HHMMSS as the archive folder created in Step 14
    python process-framework/scripts/extract_ratings.py \
        --review-cycle-id "tools-review-YYYYMMDD-HHMMSS" \
        --archived-prefix "appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS/processed-forms" \
        appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS/processed-forms/*feedback*.md \
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

- **Framework IMP rows in central Intake** — written to Section 1 — Intake of `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` (Phase 7). Triage (PF-TSK-089) is the consumer.
- **Product-side opportunities** (per project, not central): [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) for product feature requests, [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) for bugs, [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) for tech debt
- **Review Summary** - Documentation of findings and identified improvements, using the [Tools Review Summary Template](../../templates/support/tools-review-summary-template.md). Created via [`New-ReviewSummary.ps1`](../../scripts/file-creation/06-maintenance/New-ReviewSummary.ps1) — writes to `appdev/process-framework-central/feedback/reviews/` (Phase 7).
- **Ratings Database Update** - Quantified ratings recorded in `appdev/process-framework-central/feedback/ratings.db` for trend analysis via `python process-framework/scripts/feedback_db.py record` (use [feedback-db-input-template.json](../../templates/support/feedback-db-input-template.json) as reference)
- **Archive of Processed Forms** - Organized archive at `appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS/processed-forms/`

## State Tracking

The following state files must be updated as part of this task:

- **Central `process-improvement-tracking.md`** (Section 1 — Intake) at `appdev/process-framework-central/state-tracking/permanent/` — framework improvements from feedback analysis. Phase 7: rows always land in Intake; downstream Triage moves them to destination sections.
- Project-local [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) — product feature requests identified from feedback analysis (per project)
- Project-local [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) — bugs identified from feedback analysis (per project)
- Project-local [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) — technical debt items identified from feedback analysis (per project)
- **🔗 MANDATORY**: All entries must include links to the tools review analysis file for full traceability. The review summary lives in `appdev/process-framework-central/feedback/reviews/` post-Phase-7.

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Framework IMP rows landed in central **Section 1 — Intake** with the 7-col schema (ID, Source, Description, Project, Framework Version, Last Updated, Notes)
  - [ ] Product-side opportunities documented in the appropriate project-local tracking files (feature-request-tracking, bug-tracking, technical-debt-tracking)
  - [ ] Review summary created at `appdev/process-framework-central/feedback/reviews/`
  - [ ] Archive of processed feedback forms at `appdev/process-framework-central/feedback/archive/YYYY-MM/...`
- [ ] **Verify Feedback Grouping**: Ensure that only feedback forms for the same task type were analyzed together
- [ ] **Update State Files**: Confirm all state tracking files have been updated
  - [ ] Central process-improvement-tracking.md Intake section has the new rows
  - [ ] Project-local trackers updated for product items (per project, where applicable)
- [ ] **Archive Processed Forms**: Move analyzed feedback forms to central archive (must happen before recording ratings):
  - [ ] Create archive folder with session HHMMSS suffix matching the review summary filename from Step 11: `appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS`
  - [ ] Create subfolder: `processed-forms/` within the archive folder
  - [ ] **⚠️ CRITICAL DISTINCTION**: Only move feedback forms that were **analyzed during this session**
    - ✅ **Archive These**: Feedback forms that you reviewed, analyzed, and extracted improvements from
    - ❌ **DO NOT Archive**: Newly created feedback forms (including the PF-TSK-010 form created for this session)
    - ❌ **DO NOT Archive**: Feedback forms that haven't been analyzed yet
  - [ ] **Move by explicit filename list, not glob** — concurrent same-date sessions may have created additional forms in the active folder
  - [ ] **Verify after move**: archive folder count equals move-list length; no listed filenames remain in the active folder
  - [ ] **Keep Active**: Leave newly created feedback forms in the active feedback-forms folder for future analysis
  - [ ] Document which specific forms were archived vs. kept active in the review summary
- [ ] **Record Ratings**: Extract ratings via [`extract_ratings.py`](../../scripts/extract_ratings.py) and record in database via `feedback_db.py record` (see Step 15 for commands)
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-010" and context "Tools Review"
- [ ] **Schedule Next Review**: Set a reminder for the next tools review cycle

## Next Tasks

- [**IMP Triage (PF-TSK-089)**](imp-triage-task.md) — primary downstream task. Drains Intake into the appropriate destination sections (Improvements / Extensions / Structural Changes / Active Pilots / Rejected). Run this next so the freshly-intaken framework IMPs get properly classified before they sit too long.
- [**Process Improvement (PF-TSK-009)**](process-improvement-task.md) — for implementing IMPs that Triage routes to the Improvements section (downstream of Triage, not directly from Tools Review).

## Related Resources

- [IMP Triage Task (PF-TSK-089)](imp-triage-task.md) - The task that drains the Intake section into destination sections
- [IMP Triage Usage Guide (PF-GDE-067)](../../guides/support/imp-triage-usage-guide.md) - Decision criteria for the downstream Triage
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks
