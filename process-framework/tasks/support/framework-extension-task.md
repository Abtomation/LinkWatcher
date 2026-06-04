---
id: PF-TSK-026
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.9
created: 2025-07-26
updated: 2026-06-02
description: "Support task for fundamentally extending the framework with new functionalities and capabilities"
---

# Framework Extension Task

## Purpose & Context

This task manages the systematic extension of the task-based development framework with entirely new functionalities, capabilities, or systematic approaches. It ensures that framework extensions are properly planned, implemented across multiple sessions, and integrated with existing framework components while maintaining consistency with established principles.

## AI Agent Role

**Role**: Framework Architect
**Mindset**: Extensibility-focused, component-oriented, integration-aware
**Focus Areas**: Framework design, component relationships, extensibility patterns, integration points
**Communication Style**: Consider framework evolution and component interactions, ask about long-term extensibility and integration requirements

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/framework-extension-task-map.md)

- **Critical (Must Read):**

  - **Framework Extension Concept Document** - Human-provided concept document defining the extension scope, workflow, and integration strategy
  - [Framework Extension Customization Guide](../../guides/support/framework-extension-customization-guide.md) - Essential guide for customizing Framework Extension Concept documents
  - [Task-Based Development Principles](../../ai-tasks.md#understanding-task-based-development) - Understanding of framework principles for consistent extension
  - [New Task Creation Process](new-task-creation-process.md) - For creating individual tasks within the extension
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `-?` before running**)
  - [Documentation Map](../../PF-documentation-map.md) - For understanding current framework structure and updating with new artifacts
  - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - For tracking framework capability enhancements
  - [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) - State tracking for creation-heavy extensions (use `-Variant FrameworkExtension` for multi-artifact tracking)
  - [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) - State tracking for modification-heavy extensions
  - [Template Development Guide](../../guides/support/template-development-guide.md) - For creating extension-specific templates
  - [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) - For creating automation scripts

- **Reference Only (Access When Needed):**
  - [PF ID Registry](../../PF-id-registry.json) - For adding new ID prefixes for extension-created file types
  - [Process Framework Task Registry — Trigger & Output](../../infrastructure/process-framework-task-registry.md) - For studying existing trigger/output chains (`🔗 TRIGGER & OUTPUT` blocks and State File Trigger Index)
  - [Structure Change Task](structure-change-task.md) - For understanding structural modifications vs. extensions
  - [Process Improvement Task](process-improvement-task.md) - For understanding granular improvements vs. extensions

## Process

> **🚨 Core invariants for this task:**
> - It is a **multi-session** task — create a comprehensive concept document and get human approval *before* implementation, then track progress across sessions in a temporary state file.
> - **Never proceed past a `🚨 CHECKPOINT`** without presenting findings and getting explicit human approval; implement all work incrementally.
> - The task is **not complete** until every step — including the feedback form — is finished.

### Phase 1: Concept Development & Approval

1. **Pre-Concept Analysis** — before creating the concept document, study the landscape:
   - (a) **Read the [Task Transition Registry](../../infrastructure/task-transition-registry.md)** to understand how existing tasks connect and hand over work
   - (a2) **Study the [Process Framework Task Registry — Trigger & Output](../../infrastructure/process-framework-task-registry.md)** (`🔗 TRIGGER & OUTPUT` blocks and State File Trigger Index) to understand which state file statuses trigger which tasks and what outputs each task produces — this reveals the full signal chain the extension must integrate with
   - (b) **Study existing project patterns AND framework-lineage patterns** (predecessor projects, blueprint sources, sibling projects sharing the same framework instance) solving similar problems — identify precedents in the project's current workflow (e.g., how E2E tracking handles non-standard test types, how validation dimensions were modularized) **and in the framework's history** (e.g., how the same abstraction was handled in a predecessor project that shaped this framework, or by a sibling project that adopted the framework before this one). Also familiarize yourself with established industry taxonomies/patterns for the problem domain (e.g., Diataxis for documentation organization, OWASP for security, Twelve-Factor for configuration) so you have proven external models to compare against in (c).
   - (c) **Establish the abstraction model** — what are the natural levels in the framework's architecture? **Where in the existing data model does this information already live? Could the new tracking duplicate state already maintained elsewhere (e.g., per-feature state files' §4 Documentation Inventory, ID registries, existing tracking columns)?** Where industry taxonomies (from (b)) are relevant, **carefully evaluate how to adapt them to the framework** rather than choosing between copy-verbatim and reject-outright. Define categories that genuinely fit the framework — neither copying industry terminology blindly nor reinventing what proven external models already solve.
   - (d) **Trace the full lifecycle end-to-end** — who triggers → who plans → who creates → who runs → who records → who reviews → how do you know what's left?
   - (e) **Evaluate scalability, abstraction level, and ownership** for every new concept — will this scale as the framework grows? Does it match the framework's architecture? Who owns each artifact, process, and decision? When evaluating scale, extrapolate genuinely (e.g., 10× current artifact count) — don't anchor on current framework scale.
   > Each sub-step should produce a concrete answer. If you cannot answer a question, that is a gap to resolve before proceeding.
2. **Create Framework Extension Concept Document** using the standardized script:
   ```powershell
   # Phase 7 (post-2026-05-11): proposals live in appdev central regardless of cwd.
   cd $(Get-CentralFrameworkPath)/proposals
   ./New-FrameworkExtensionConcept.ps1 -ExtensionName "[Extension Name]" -ExtensionDescription "[Brief description]" -Type [Creation/Modification/Hybrid] -ExtensionScope "[Extension scope]" -OpenInEditor
   ```
   - **`-Type`** selects a type-specific template: `Creation` (new artifacts only), `Modification` (changes to existing artifacts only), or `Hybrid` (both)
   - Script creates structural template in `appdev/process-framework-central/proposals/<PRJ-ID>_[extension-name]-concept.md` — Phase 7 (2026-05-11): PRJ-ID-prefixed filename, `project_id` stamped in frontmatter. Output dir resolved via `Get-CentralFrameworkPath` regardless of cwd.
   - **CRITICAL**: Template requires extensive customization following [Framework Extension Customization Guide](../../guides/support/framework-extension-customization-guide.md)
   - Define extension scope and new capabilities to be added
   - Specify workflow definition with clear input-process-output flow
   - Create artifact dependency map showing how new artifacts serve as inputs for subsequent tasks
   - Define state tracking integration strategy (new permanent state files vs. updating existing ones)
   - Include integration strategy with current framework workflow
3. **Present Concept for Human Review (concept-direction approval)** — Get explicit approval of the concept's direction and scope before investing in the deeper impact analysis (Step 4). This is a lightweight go/no-go on the idea itself; it is **not** the final implementation sign-off — that is Step 5, after impact analysis and the pilot decision are on the table.
4. **Analyze Framework Impact** — For each existing framework element (task, script, template) that the extension will modify:
   - Read the complete element
   - Summarize: (a) what information it has at each step, (b) what it is responsible for, (c) what it delegates
   - Document how the extension affects it, considering its actual knowledge state
   - **Do not propose modifications based on assumptions** — present this analysis at the checkpoint first
   > **Validation script check**: If the extension modifies state file structure (columns, sections, headings), identify which [Validate-StateTracking.ps1](../../scripts/validation/Validate-StateTracking.ps1) surfaces parse those files and include them in the impact analysis. Run `Validate-StateTracking.ps1` before and after changes to catch regressions.
   >
   > **Column-index impact check**: If the extension modifies tracking file structure (adds, removes, or reorders columns), grep for `Split-MarkdownTableRow` and hardcoded column index patterns (e.g., `\[3\]`, `\[4\]`) in all scripts that reference the modified tracking file. Scripts that *read* column indices break just as silently as scripts that *write* them.
   >
   > **00-setup impact check**: Check all 00-setup tasks (project-initiation, codebase-feature-discovery, codebase-feature-analysis, retrospective-documentation-creation) for impact even when the extension primarily affects later phases. Setup tasks declare configurations (ID prefixes, tracking schemas, directory structures, registries) that downstream tasks consume — adding a new artifact type, new ID prefix, or new tracking field typically requires updates here so new projects pick up the extension by default.
   >
   > **Documented-home check**: For each modified artifact in the impact list, verify it has a documented home — a task definition, customization guide, or other clearly-owned location that anchors its usage. Catches framework asymmetries where a script/template/guide exists without a parent task definition (e.g., UI Design has `New-UIDesign.ps1` + template + customization guide + context map but no task definition; surfaced only via grep for the missing PF-TSK reference). If a modified artifact has no documented home, file an IMP for the asymmetry before proceeding — the extension shouldn't extend an undocumented surface.
   >
   > **Soak-tracking status check**: For each PowerShell script targeted for modification, check its soak-tracking status via `Get-SoakStatus -ScriptId <relative-path>` against [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md). Hash-changing edits reset the counter and require re-soaking (default 3 successful invocations). This is load-bearing input to pilot decisions and session sequencing — modifying N soak-tracked scripts means ~3N re-soak invocations distributed across follow-up sessions. Surface the re-soak budget at the Step 5 checkpoint.
   >
   > **Routing self-check**: After completing impact analysis, re-evaluate routing — does the resulting work shape still match PF-TSK-026 (new capability requiring multiple interconnected components), or has it shifted to [PF-TSK-014](structure-change-task.md) (reorganization, file moves, schema changes) or [PF-TSK-009](process-improvement-task.md) (content edits to a single task/guide/template)? Impact analysis frequently reframes scope from extension to reorganization or improvement. If the work has shifted, re-route via `Update-ProcessImprovement.ps1 -ImprovementId <ID> -MoveToSection StructuralChanges|Improvements -RoutedBy "PF-TSK-026" -Reason "<why>"` and stop — the receiving task picks up in its own session. Present the routing decision (continue with PF-TSK-026 or re-route) as part of the Step 5 checkpoint material.
4.5. **Pilot vs. Full Rollout Decision** (PF-PRO-030) — for extensions that introduce new behavior with unknown failure modes (e.g., new helper invariants, new hooks, new assertion patterns adopted across many scripts), evaluate whether a **pilot** is appropriate before broad rollout. The pilot mitigates the risk of broad-scope rollback by validating the new behavior in a small representative subset first.
   - **Default**: `Full Rollout` — extension's modifications apply across all targeted artifacts at Phase 4. Use when the change is mechanical or fully understood.
   - **Pilot**: select 1-3 representative adopter artifacts; broader adoption is filed as a separate IMP after the pilot resolves. Use when the change introduces behavior whose failure modes can only be observed in production conditions.
   - **If `Pilot` is chosen**, define at this step:
     - **Adopter artifacts**: which 1-3 files/scripts/components will adopt the new behavior in Phase 4.
     - **Success criteria**: concrete observable signal that the pilot has succeeded (e.g., "all adopter soak counters reach 0", "30 days of clean operation", "no related bug reports").
     - **Decision trigger**: a follow-up IMP filed at Phase 4 finalization that, when processed, drives the rollout/rollback decision.
   - The pilot decision and (if applicable) the three definitions above are part of the Step 5 checkpoint material.
5. **🚨 CHECKPOINT (full-package approval)**: Present concept document, impact analysis, **pilot vs. full-rollout decision (and pilot definitions if applicable)**, and proposed implementation approach to human partner for approval. Unlike Step 3's concept-direction approval, this is the **final go/no-go before Phase 2 begins** — it signs off the complete package, not just the idea.
   > **Single-session lightweight path**: If the extension meets **all** of these criteria — (1) artifact scope is bounded — either modification-only, OR creates at most one new template/guide artifact and no new tasks, (2) completable in a single session, (3) no new ID prefixes needed — then at this checkpoint, propose the lightweight path to the human partner. If approved:
   > - **Skip Phase 2 entirely** (Steps 6–10: no temp state file, no roadmap, no session planning)
   > - **Phase 3 compresses to**: Implement modifications (Step 12) → verify linked documents with grep sweep → integration testing (Step 15)
   > - **Phase 4 compresses to**: Checkpoint (Step 16) → update core framework files (Step 17) → update permanent state files (Step 19) → completion checklist (Step 22). Skip Steps 18 (usage docs), 20 (state file archival), and 21 (concept archival — archive concept inline at this step instead).
   > - **Pilot interaction (PF-PRO-030)**: If a pilot was chosen at Step 4.5, Step 19's pilot row registration is unchanged (still required), but Step 21's deferral conditional still applies — **do not archive the concept inline**. The concept remains in `proposals/` until the pilot reaches `Resolved` status, at which point `Update-ProcessImprovement.ps1 -NewStatus Resolved` archives the concept and moves the pilot row from Active Pilots to Completed Improvements (PF-IMP-729).
   >
   > **Mid-session scope growth**: If any of the three lightweight criteria stops holding mid-session (e.g., human feedback reframes scope to require new artifacts, multi-session work, or a new ID prefix), switch to the full path — create the temp state file (Step 6) retroactively, update the concept document in place to reflect the broader scope, and resume Phase 2 from Step 7. **If the scope grows so far that the current concept no longer describes the work** (a fundamentally larger umbrella, not just a bigger version of the same idea), don't stretch the concept in place — file a new umbrella IMP, defer the original IMP with a cross-reference to it, archive the original concept, and author a fresh concept for the new scope.

### Phase 2: State Tracking & Planning

6. **Create Temporary State Tracking File** — choose the template based on extension type:
   - **Creation-heavy** (new tasks, templates, scripts): Use `New-TempTaskState.ps1` (FrameworkExtension variant):
     ```powershell
     New-TempTaskState.ps1 -TaskName "[Extension Name]" -Variant "FrameworkExtension" -Description "Framework extension for [brief description]"
     ```
   - **Modification-heavy** (primarily changing existing tasks, templates, scripts): Use `New-StructureChangeState.ps1` with the `"Framework Extension"` ChangeType — lightweight artifact tracking without pilot/rollback/metrics:
     ```powershell
     New-StructureChangeState.ps1 -ChangeName "[Extension Name]" -ChangeType "Framework Extension" -Description "Framework extension for [brief description]"
     ```
7. **Develop Implementation Roadmap** with detailed multi-session breakdown in the temporary state file
8. **Identify Required Components** (tasks, templates, guides, scripts, directories) and their dependencies
   - If the extension introduces language-specific commands or tooling, check if new fields are needed in `languages-config` files. Use [Update-LanguageConfig.ps1](../../scripts/update/Update-LanguageConfig.ps1) to add fields consistently across all language configs and the template.
   - For each new task, verify its routing entry in [ai-tasks.md](../../ai-tasks.md) carries concrete triggers (specific events, states, or conditions) — not generic "when needed" statements. Per [PF-IMP-875](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md), the task's own When-to-Use section convention has been removed; routing/disambiguation is now centralized in ai-tasks.md.
9. **Plan Integration Points** with existing framework components and state tracking files
10. **🚨 CHECKPOINT**: Present implementation roadmap, required components list, and session plan to human partner for approval

### Phase 3: Multi-Session Implementation

> **📋 DEFAULT CADENCE — ONE PHASE PER CALENDAR SESSION**: By default, run at most **one
> phase per calendar session** on the full multi-session path: Phase 2 (artifact creation),
> Phase 3 (integration & task updates), and any unplanned ID-prefix or state-file migration
> each get a fresh session.
>
> **Why**: Each phase ends in a `🚨 CHECKPOINT` plus phase-closure work (artifact-tracking
> updates, session-log entry, next-session plan). Combining phases collapses those checkpoints
> into one rushed review and makes the Session Tracking log claim phases were separate sessions
> when they weren't. One phase per session preserves checkpoint discipline and keeps the state
> file an honest record.
>
> **Waiver conditions**: This cadence is a default, not an absolute. Run a second phase in the
> same calendar session only when **all** hold: (a) the prior phase reached its checkpoint with
> explicit human approval, (b) its phase-closure work is done, and (c) clear session budget
> remains. When you waive it, log both phases under one calendar-session entry noting both were
> completed — do not split one sitting into two `### Session N` entries it didn't have. The
> Step 5 single-session lightweight path is a pre-approved waiver that skips Phase 2 entirely.
>
> **Resuming a phase across sessions**: When a phase spans more than one session, label the
> continuation in Session Tracking with a `(continuation)` suffix (e.g. `Session 5 — Phase 3
> (continuation)`), or sub-number parallel sub-streams within a phase (e.g. `3.1a` / `3.1b`).
> Pick one convention per extension and stay consistent.
>
> **"Session" terminology**: a *calendar session* (the cadence unit above) is one agent
> sitting; a *roadmap session* — the `Session N` units in the Step 11 plan — is a planned chunk
> of work that usually, but not always, maps to one calendar session. The Session Tracking log
> records calendar sessions and notes which roadmap units each covered.

11. **Execute Session-by-Session Implementation** following the detailed roadmap in temporary state tracking file:
    - **Session 1**: Core task definitions and primary infrastructure
    - **Session 2**: Supporting templates and document creation scripts
    - **Session 3**: Usage guides and integration documentation
    - **Session 4**: Framework integration and testing
12. **Modify Existing Task Definitions** (if the extension requires inserting steps into existing tasks):
    > **Step renumbering warning**: Inserting or removing numbered steps triggers cascading renumbering of all subsequent steps plus internal "Step N" cross-references. For large tasks (e.g., Bug Fixing) this can involve 10+ sequential edits. To reduce effort and errors: (1) add steps at the end of a phase where possible to minimize renumbering, (2) batch-verify all "Step" references with grep after renumbering to catch stale cross-references.
13. **Progressive Component Creation** using two-phase document creation approach:
    - **Phase A - Structure Generation**: Use scripts (New-Task.ps1, New-Template.ps1, New-Guide.ps1) to generate basic document frameworks
      - Script outputs are STARTING POINTS requiring extensive customization
      - Scripts create structural frameworks with placeholder content that MUST be replaced
    - **Phase B - Content Customization**: Follow best practices guides to fully customize generated structures
      - Templates require comprehensive content development following Template Development Guide
      - Guides require extensive customization following Guide Creation Best Practices Guide
      - Tasks require detailed process definition following Task Creation Guide
    - **Phase C - Framework Script Tests** (for extensions that create or modify `.ps1` / `.psm1` files): Add a Pester unit test (`<ScriptName>.Tests.ps1` under `appdev/test/automated/unit/framework/<area>/`) alongside each new script and run `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category <area>` (or `-Quick`) to confirm green before moving on. If the extension introduces a new tracked user workflow, file a follow-up via [E2E Acceptance Test Case Creation (PF-TSK-069)](../03-testing/e2e-acceptance-test-case-creation-task.md); if it introduces a new measured performance surface, route to [Performance Test Creation (PF-TSK-084)](../03-testing/performance-test-creation-task.md).
    > **⚠️ Cross-cutting reminder**: Each task created via [PF-TSK-001](new-task-creation-process.md) includes mandatory cross-cutting updates (Step 12L) — Task Transition Guide, Process Framework Task Registry, Task Trigger & Output Traceability, and existing task definitions' Next Tasks/Related Resources sections. Complete these during Phase 3 for each new task, not deferred to Phase 4.
14. **Update Temporary State Tracking** after each session with progress and next steps
    > **Archive-split convention (PF-IMP-895)**: When the state file exceeds ~800 lines, archive completed session logs to a sibling file to keep the active file within read-budget thresholds. Procedure:
    > 1. Create a sibling file named `<state-file-name>-session-archive.md` in the same directory.
    > 2. Add a header linking back to the active state file: `# Session Archive for [Extension Name]` + `> Archived sessions from [active state file link]. See that file for current status.`
    > 3. Cut all completed `### Session N` entries except the most recent 2–3 (keep those for continuity context) and paste them into the archive file, preserving order.
    > 4. In the active state file's `## Session Tracking` section, add a reference line above the remaining sessions: `> **Archived sessions**: Sessions 1–N are in [<state-file-name>-session-archive.md](<relative-link>).`
    >
    > This follows the same archive-split pattern used for process-improvement-tracking.md (2026-05-13). The archive is audit-trail only — no task reads it during normal operation. Check line count at the start of each session; split proactively rather than after the file has already become unwieldy.
15. **Integration Testing** to ensure compatibility with existing framework components

### Phase 4: Framework Integration & Finalization

16. **🚨 CHECKPOINT**: Present completed extension components, integration test results, and remaining work to human partner for review
17. **Update Core Framework Files**:
    - Update [ai-tasks.md](../../ai-tasks.md) with new tasks
    - Ensure every new artifact carries a one-line source description (`.SYNOPSIS` for scripts, `description:` frontmatter for markdown, `metadata.description` for JSON) — this is what the generated [PF-documentation-map.md](../../PF-documentation-map.md) renders.
    - Update the appropriate [ID registry](../../PF-id-registry.json) with new ID prefixes if needed
    - **Regenerate the documentation map**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1` (the map is a generated, DO-NOT-EDIT projection — PF-PRO-037).
    - **Run drift check**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1 -Check` — must exit 0 (in sync). On non-zero exit, the on-disk map differs from what the generator produces; rerun the generator (preceding bullet) and re-check. `-ReportMissing` lists any new artifact still lacking a source description.
18. **Create Usage Documentation** demonstrating how to use the new framework extension
19. **Update Permanent State Files** as defined in the concept document
    - **For each new PowerShell script created by this extension**, register it for soak verification with `Register-SoakScript -ScriptId <relative-path-from-project-root> -ScriptPath <absolute-path>` (loaded via `Common-ScriptHelpers`). The script's first 5 successful invocations must then call `Confirm-SoakInvocation -Outcome success` after agent verification — see [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) and the [PF-PRO-028 Script Self-Verification proposal](../../../process-framework-central/proposals/old/script-self-verification.md). Skip for non-script artifacts (templates, guides, state files, sub-modules).
    - **Pending-migration entries (cwd=appdev only)**: If the extension touched a `blueprint/` file *outside* `blueprint/process-framework/` — e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, or `blueprint/test/` — file a pending-migration entry under `process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md` for every registered product project. `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/`; the rest of `blueprint/` seeds project working trees at `Register-Project` bootstrap, so post-bootstrap changes don't reach existing projects without a migration. Use the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md).
    - **If a pilot was chosen at Step 4.5** (PF-PRO-030), register the pilot in the **Section 5 — Active Pilots** subsection of the central [process-improvement-tracking.md](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) (Phase 7 schema, 2026-05-11):
      ```powershell
      pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 `
          -AsPilot `
          -SourceConcept "<PF-PRO-NNN>" -OriginatingTask "<PF-TSK-NNN>" `
          -Adopters "<comma-separated adopter artifacts>" `
          -SuccessCriteria "<criteria text>" `
          -DecisionTrigger "<PF-IMP-NNN or descriptive text>"
      ```
      The script consumes the next PF-IMP-NNN ID from the registry and writes the pilot row with status `Active`. Note the assigned PF-IMP-NNN — Step 21 conditional below depends on its status.
20. **Move Temporary State Tracking** file to `the resolved `state-tracking/temporary/old/` directory (via `Get-StateTrackingContext`)`. (This step is unchanged whether or not a pilot was chosen — the implementation work is complete; the pilot lifecycle is now owned by the Active Pilots row.)
21. **Archive Completed Concept Document**: Move the framework extension concept document from `appdev/process-framework-central/proposals/` to `appdev/process-framework-central/proposals/old/` — the concept has served its purpose and should not remain alongside active proposals.
    - **Conditional on pilot status (PF-PRO-030)**: if a pilot was chosen at Step 4.5, **skip this step**. The concept doc remains in `proposals/` until the pilot reaches `Resolved` status, since the concept is the source of truth for the rollout/rollback decision and the spec for what is being scaled. When the pilot is later resolved via [`Update-ProcessImprovement.ps1`](../../scripts/update/Update-ProcessImprovement.ps1) `-NewStatus Resolved`, the script archives the concept doc and moves the pilot row from Active Pilots to Completed Improvements (PF-IMP-729).
22. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

### Concept Phase Outputs

- **Framework Extension Concept Document** - Comprehensive proposal in `appdev/process-framework-central/proposals/[extension-name]-concept.md` including workflow definition, artifact dependency map, and state tracking integration plan
- **Impact Analysis** - Documentation of how the extension affects existing framework components

### Implementation Phase Outputs

- **New Task Definitions** - Multiple interconnected tasks with clear input requirements, process workflows, and output specifications
- **Supporting Infrastructure** - Templates, guides, scripts, and directories for extension functionality
- **Integration Documentation** - Documentation showing how the extension works with existing framework workflow
- **Updated Core Framework Files** - Modified ai-tasks.md, the appropriate documentation map (PF-documentation-map.md for PF artifacts, doc/PD-documentation-map.md for product artifacts, test/TE-documentation-map.md for test artifacts), and the appropriate ID registry

### State Tracking Outputs

- **Temporary State Tracking File** - Multi-session implementation tracker with detailed roadmap and progress tracking
- **Updated Permanent State Files** - Enhanced existing state files or new permanent state files as defined in concept

## State Tracking

The following state files must be updated as part of this task:

- **Temporary State Tracking File** - Create using New-TempTaskState.ps1 to track multi-session implementation progress
- [Documentation Map](../../PF-documentation-map.md) - Update with all new artifacts and their relationships
- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Update with framework capability enhancements
- **Additional State Files** - As defined in the framework extension concept document (may include new permanent state files or updates to existing ones)

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

> **Note**: This is typically a multi-session task. Complete verification applies to the ENTIRE extension across all sessions. For **single-session lightweight path** extensions (approved at Step 5), items marked *(full path only)* can be skipped.

Before considering this task finished:

- [ ] **Phase 1 — Verify Concept**: Confirm concept development and approval completed

  - [ ] Framework extension concept document created using New-FrameworkExtensionConcept.ps1 script
  - [ ] Template extensively customized following Framework Extension Customization Guide
  - [ ] Comprehensive workflow definition with clear input-process-output flow
  - [ ] Artifact dependency map clearly shows how new artifacts serve as inputs for subsequent tasks
  - [ ] State tracking integration strategy defined (new permanent state files vs. updating existing ones)
  - [ ] Human approval obtained for concept before implementation

- [ ] **Phases 2–3 — Verify Implementation**: Confirm all extension components implemented using two-phase approach *(full path only)*

  - [ ] **Phase A - Structure Generation**: All document structures generated using appropriate scripts
    - [ ] Task definitions created using New-Task.ps1 (structural framework only)
    - [ ] Templates created using New-Template.ps1 (structural framework only)
    - [ ] Guides created using New-Guide.ps1 (structural framework only)
  - [ ] **Phase B - Content Customization**: All generated structures fully customized
    - [ ] Task definitions contain detailed input-process-output specifications (not placeholder content)
    - [ ] Templates contain comprehensive customizable content (not placeholder sections)
    - [ ] Guides contain detailed step-by-step instructions and examples (not template boilerplate)
  - [ ] Integration documentation shows how extension works with existing framework
  - [ ] Multi-session implementation tracked in temporary state file with two-phase progress tracking
  - [ ] **Framework script tests**: for each new or modified `.ps1`/`.psm1` created by this extension, the corresponding Pester unit test (`<ScriptName>.Tests.ps1`) exists and runs green. Full Pester suite passes at extension close. N/A if the extension created no PowerShell scripts.

- [ ] **Phase 4 — Verify Framework Integration**: Confirm extension properly integrated

  - [ ] [ai-tasks.md](../../ai-tasks.md) updated with new tasks
  - [ ] [Documentation Map](../../PF-documentation-map.md) regenerated via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1); every new artifact carries a source description
  - [ ] Run [`Build-DocumentationMap.ps1 -Check`](../../scripts/validation/Build-DocumentationMap.ps1) — exit 0 (map in sync)
  - [ ] [PF ID Registry](../../PF-id-registry.json) updated with new prefixes if needed
  - [ ] Permanent state files updated as defined in concept document

- [ ] **Phase 4 — Update State Files**: Ensure all state tracking files have been updated
  - [ ] Temporary state tracking file moved to the resolved `state-tracking/temporary/old/` directory (via `Get-StateTrackingContext`)
  - [ ] **Concept document archive (PF-PRO-030 pilot rule)**: if no pilot was chosen at Step 4.5, concept document moved to `appdev/process-framework-central/proposals/old/`. **If a pilot was chosen, concept document remains in `appdev/process-framework-central/proposals/` and the corresponding pilot row in [Section 5 — Active Pilots](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md#section-5--active-pilots) has status `Active` (concept will be archived later by `Update-ProcessImprovement.ps1 -NewStatus Resolved` when the pilot resolves).**
  - [ ] [Documentation Map](../../PF-documentation-map.md) reflects all new artifacts
  - [ ] [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated with framework capability enhancement
  - [ ] **Pilot row registered (PF-PRO-030)**: if a pilot was chosen at Step 4.5, the pilot row exists in the Active Pilots section with status `Active`, decision trigger noted, and adopters listed. N/A if Full Rollout was chosen.
  - [ ] **Soak verification registered**: every new PowerShell script created by this extension is registered in [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) via `Register-SoakScript` (verifies via `Get-SoakStatus -ScriptId <id>`). N/A if the extension created no new scripts.
  - [ ] **Module helper `-WhatIf` verification**: Any new `.psm1` helper that exposes `[CmdletBinding(SupportsShouldProcess=$true)]` has been smoke-tested by invocation from a script (not just an in-process call from a non-module pwsh session), confirming `$WhatIfPreference` is honored across the module boundary. Module SessionState isolation prevents preference inheritance via the scope chain; helpers must read the caller's preference explicitly via `$PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')`. N/A if no module helpers were created. (See `ExecutionVerification.psm1::_Test-CallerWhatIf` for the canonical pattern.)
  - [ ] **Pending-migration entries filed (cwd=appdev only)**: If this extension touched a `blueprint/` file outside `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`), a pending-migration entry has been filed under `process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md` for every registered product project, using the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/`; everything else in `blueprint/` reaches existing projects only via a migration entry. N/A if the extension touched only `blueprint/process-framework/` (which Push mirrors automatically).
- [ ] **Session end — Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-026" and context "Framework Extension Task"

## Next Tasks

- [**Process Improvement Task**](process-improvement-task.md) - If further refinements are needed for the extension
- **Extension-Specific Tasks** - Use the newly created tasks that comprise the framework extension

## Related Resources

### Core Framework Resources

- [Task-Based Development Principles](../../ai-tasks.md#understanding-task-based-development) - Understanding framework principles
- [New Task Creation Process](new-task-creation-process.md) - For creating individual tasks within extensions
- [Structure Change Task](structure-change-task.md) - For understanding structural modifications vs. extensions
- [Process Improvement Task](process-improvement-task.md) - For understanding granular improvements vs. extensions

### Development Infrastructure

- [Template Development Guide](../../guides/support/template-development-guide.md) - For creating extension-specific templates
- [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) - For creating automation scripts
- [Framework Extension Customization Guide](../../guides/support/framework-extension-customization-guide.md) - For customizing Framework Extension Concept documents
- [Visualization Creation Guide](../../guides/support/visualization-creation-guide.md) - For creating context maps

### State Management

- [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) - State tracking for creation-heavy extensions (use `-Variant FrameworkExtension` for multi-artifact tracking)
- [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) - State tracking for modification-heavy extensions
- [Documentation Map](../../PF-documentation-map.md) - Framework structure and artifact relationships
- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Framework capability tracking
