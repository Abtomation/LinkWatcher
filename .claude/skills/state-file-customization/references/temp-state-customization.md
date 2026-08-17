# Temporary State File Customization

Selection and customization craft for temporary multi-session state tracking files. The
creation scripts scaffold a meta-template; this reference holds the judgment that turns it
into a functional tracking document.

## Template selection guide

### Task creation workflows

**Template**: [temp-task-creation-state-template.md](../../../../process-framework/templates/support/temp-task-creation-state-template.md)
· **Script**: `New-TempTaskState.ps1`
**Best for**: creating new task definitions and their infrastructure; building new
capabilities.
**Characteristics**: creates NEW artifacts (no rollback needed); phase structure Core →
Infrastructure (conditional, only for file-creating tasks) → Templates/Guides →
Documentation → Framework Evaluation (mandatory quality gate); focus on artifact creation
and integration.

### Structure change workflows

**Template**: [structure-change-state-template.md](../../../../process-framework/templates/support/structure-change-state-template.md)
(or the rename / content-update / from-proposal siblings)
· **Script**: `New-StructureChangeState.ps1`
**Best for**: reorganizing existing structure, migrating files, changing documentation
architecture, modifying existing templates.
**Characteristics**: modifies EXISTING artifacts — rollback essential for complex changes.
Variant selection:

| Shape | Invocation | Template structure |
|---|---|---|
| Complex / breaking change | default `-ChangeType` | 5 phases with rollback, pilot, and metrics sections |
| Rename / move | `-ChangeType "Rename"` | 2 phases (Preparation + Execution), no pilot/rollback/metrics |
| Content-only change across files | `-ChangeType "Content Update"` | 2 phases, content-focused Affected Files table |
| Framework doc additions/modifications | `-ChangeType "Framework Extension"` | 3 phases (Preparation + Create/Modify + Validation), artifact tracking tables |
| Detailed proposal already exists | `-FromProposal` | Execution tracking only — copy the proposal's phases into the Implementation Roadmap; the proposal owns rationale, affected files, and the change type |

`-FromProposal` is compatible with `-ChangeType Rename` (the proposal owns the file mapping)
and the default ChangeType; it is **incompatible** with `Content Update` and
`Framework Extension` — those templates carry type-specific content/artifact tables that
don't fit the execution-only from-proposal template.

### Process improvement workflows

**Template**: [temp-process-improvement-state-template.md](../../../../process-framework/templates/support/temp-process-improvement-state-template.md)
· **Script**: `New-TempTaskState.ps1 -Variant ProcessImprovement`
**Best for**: multi-session improvements to existing processes, framework capabilities, or
specialized tooling.
**Characteristics**: purpose-built, minimal customization needed — Analysis/Design →
Implementation/Testing → Documentation/Integration → Validation/Completion; includes IMP
references, affected-components table, validation criteria.

### Framework extension workflows

**Template**: [temp-framework-extension-state-template.md](../../../../process-framework/templates/support/temp-framework-extension-state-template.md)
· **Script**: `New-TempTaskState.ps1 -Variant FrameworkExtension`
**Best for**: multi-artifact extensions (Framework Extension task) where artifact
dependencies and task impact need explicit tracking.
**Characteristics**: Concept & Approval → Artifact Creation (in dependency order) →
Integration & Task Updates → Finalization; includes Artifact Tracking and Task Impact
tables plus session planning.
**Concept-backed alternative**: when an approved concept already carries the roadmap detail,
`New-StructureChangeState.ps1 -FromProposal` is often the better fit — a lightweight
phase-checklist + session-log tracker that references the concept instead of re-transcribing
it (the Framework Extension task's state-tracking step describes this choice).

### Framework evaluation workflows

**Template**: [temp-framework-evaluation-state-template.md](../../../../process-framework/templates/support/temp-framework-evaluation-state-template.md)
· **Script**: `New-TempTaskState.ps1 -Variant FrameworkEvaluation`
**Best for**: multi-session Framework Evaluations — full-framework or multi-phase scopes, or
evaluations whose data-driven validation needs its own session(s).
**Characteristics**: purpose-built for the evaluation workflow — Artifacts-in-Scope
inventory, Dimension Progress table across the seven dimensions, Findings Log with scores
and routing; roadmap phases Scope & Inventory → Dimension Analysis → Findings & Checkpoint →
Report & Registration. Single-session targeted evaluations don't need it — track progress in
the evaluation report directly.

### Code refactoring workflows

**Template**: [temp-refactoring-state-template.md](../../../../process-framework/templates/support/temp-refactoring-state-template.md)
· **Script**: `New-TempTaskState.ps1 -Variant Refactoring`
**Best for**: multi-session refactorings on the Code Refactoring task's Standard Path — ≥ 5
items or 3+ sessions (smaller refactorings track progress in the refactoring plan's
Implementation Tracking section instead); refactorings tied to tech-debt items where
behavior preservation must be auditable session-to-session.
**Characteristics**: the **Test Baseline anchor is mandatory** — captured BEFORE any code
changes; it is the accountability mechanism for attributing regressions. Phase 0
(Prerequisites) → A (Strategy & ADR) → B (Incremental Implementation) → C (Behavior
Validation) → D (Closure); Discovered Bugs Log with severity decision matrix; 3-phase
state-file-update closure; audit-flagged TD closure step (triggers only when a resolved TD
references a `TE-TAR-*` audit report).

### Retrospective documentation workflows

**Template**: [temp-retrospective-documentation-state-template.md](../../../../process-framework/templates/support/temp-retrospective-documentation-state-template.md)
· **Script**: `New-TempTaskState.ps1 -Variant RetrospectiveDocumentation`
**Best for**: per-feature Retrospective Documentation Creation work spanning multiple
sessions — Tier 2/3 features where Test Spec / Quality Assessment Report / user-doc audit
defer to a follow-up session. Tier 1 and small Tier 2 features that fit one session track
progress in the master retrospective state file directly.
**Characteristics**: frontmatter binds the temp file to the onboarding context
(`parent_state` + `feature_id`); Required Deliverables table mapping the 11 deliverables to
the owning task's documentation steps; Per-Feature Closure Updates table; Session Plan with
explicit out-of-scope deferral so the contract between sessions is recorded. ADRs apply to
any feature with genuine architectural decisions, not just foundation features.

## Phase customization guidelines

The scaffolded phases are a starting shape, not a contract:

1. **Rename phases** to match the actual workflow.
2. **Modify checklists** — include only items relevant to this work; add what's missing.
3. **Mark conditional phases** SKIPPED with rationale rather than deleting silently.
4. **Adjust priorities** (HIGH/MEDIUM/LOW) to the work's real risk profile.

Common adapted shapes: Process improvements often compress to Analysis & Design →
Implementation → Finalization; framework extensions expand Artifact Creation into
per-dependency-order sub-phases; migrations follow Preparation → Infrastructure → Pilot →
Full Migration → Validation & Cleanup.

## Session planning strategies

A typical arc: Foundation & Analysis → Implementation Infrastructure → Content &
Documentation → Integration & Finalization. **That four-session breakdown is one
illustrative shape, not a target count** — size the plan to the actual scope; larger
extensions commonly span 8–12+ sessions.

Best practices:

1. **Estimate realistically** — plan 30–120 minutes per session based on complexity.
2. **Define clear objectives** — each session gets specific, measurable goals.
3. **Plan dependencies** — prerequisites complete before dependent work.
4. **Document progress** — update the state file after each session with progress and
   blockers.
5. **Plan next steps** — every session ends with a clear plan for the next one.

## Integration best practices

- **Regular updates** — after each session, with consistent status values (NOT_STARTED,
  IN_PROGRESS, COMPLETED, SKIPPED) and documented dependencies.
- **Archive-split for large files** — when a state file exceeds ~800 lines (common in 8+
  session extensions), archive completed session logs to a sibling `*-session-archive.md`
  file, keeping the most recent 2–3 sessions for continuity. The full procedure lives in the
  [Framework Extension task](../../../../process-framework/tasks/support/framework-extension-task.md)'s
  update-temporary-state-tracking step (archive-split convention).
- **Follow established processes** — use the creation scripts (New-Task.ps1,
  New-Template.ps1, …) rather than manual creation; keep the documentation map and related
  state files current; complete the per-session feedback form.
- **Quality assurance** — verify new components integrate with the existing framework,
  validate cross-references, confirm dependencies exist, and archive completed state files
  to the resolved `state-tracking/temporary/old/` directory.

### Common pitfalls

1. Skipping phases without marking them SKIPPED with rationale.
2. Creating templates/guides/scripts manually instead of via the established scripts.
3. Leaving placeholder content without an implementation plan.
4. Forgetting documentation-map and state-file updates.
5. Archiving the state file before ALL completion criteria are met.
