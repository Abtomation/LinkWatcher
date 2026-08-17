#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates improvement status updates and section moves in the Process Improvement Tracking state file

.DESCRIPTION
This script automates improvement lifecycle transitions in process-improvement-tracking.md.

Updates the following files (defaults; override with -TrackingFile / -ArchiveFile):
- appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md (live sections 1–5, resolved via .framework-central-pointer)
- appdev/process-framework-central/state-tracking/permanent/archive/process-improvement-tracking-archive.md (Sections 6 Completed + 7 Rejected; archive-split 2026-05-13)

Supports three parameter sets:

1. StatusUpdate (default; existing behavior):
   - Status-only update: changes Status and Last Updated columns in the Current table
   - Completion: moves improvement from Current to Completed section, updates summary count,
     and updates frontmatter date
   - Supersession (PF-IMP-832 (c)): -NewStatus Superseded with -SupersededBy moves the row
     to Section 7 — Rejected with Rejection Reason = "Superseded by <SupersededBy>". Keeps
     supersession distinct from implementation in trend analysis (per PF-IMP-803 rationale).
   - Pilot lifecycle (Active/Resolved): see PF-PRO-030
   - Annotation (PF-IMP-832 (a)): -AppendNotes (idempotent), -SetRespTask and -SetPriority
     (PF-IMP-1885) edit Notes / Resp Task / Priority columns. Available alone (pure
     annotation, no status change — at least one
     of -NewStatus / -AppendNotes / -SetRespTask / -SetPriority must be supplied) or alongside
     -NewStatus (annotation applied to source row before the status transition). Annotation-only
     -AppendNotes covers every section — every live one incl. Intake / Active Pilots
     (PF-IMP-1570) and both archive ones, Completed / Rejected (PF-IMP-1719), where it
     writes $ArchiveFile and leaves the terminal Resolution / Rejection Date untouched;
     -SetRespTask / -SetPriority / -EditNotes / -EditDescription stay triaged-sections-only
     (Intake, Active Pilots and the archive sections carry no Resp Task / Priority column).
   - Tool-change logging (PF-IMP-832 (b)): -LogToolChanges (JSON, same shape as
     feedback_db.py log-change --batch - stdin) folds the PF-TSK-009's tool-change-logging step manual
     feedback_db invocation into the Completed transition. Log-change failure is reported
     as WARN; the IMP move is preserved (caller can retry log-change manually).

2. SectionMove (new — PF-TSK-089 IMP Triage helper, PF-PRO-029 Phase 4):
   - Moves an IMP between sections in the centralized 7-section tracking file
   - Valid destinations: Intake | Improvements | Extensions | StructuralChanges | Rejected
     (ActivePilots and Completed are excluded — they have specialized flows)
   - Handles column-schema transformation between source and destination sections
   - On re-routes (source != Intake), auto-prepends [REROUTED YYYY-MM-DD by PF-TSK-NNN: <reason>]
     to the Notes column for an audit trail. Initial sort from Intake produces no prefix, so
     -Reason is ignored on Intake-source moves (PF-IMP-1238) — pass -AppendNotes in the same
     call to attach a note to the moved row (PF-IMP-1393 (c); idempotent, applied after the
     re-route prefix, and to every row of an -AlsoMoveIds batch).

   Batch mode (PF-IMP-982): pass -AlsoMoveIds to move several IMPs to the SAME section
   with the SAME options in one call. Each ID's source section is resolved independently;
   a not-found/failed ID is reported and skipped without aborting the rest of the batch.

   Smart defaults — typical invocations only need -ImprovementId, -MoveToSection, -Priority
   (and -RejectionReason when target is Rejected, plus -Reason on re-routes for the audit trail):
   - -Status resolves per row on triaged-section moves (PF-IMP-1831): explicit -Status wins;
     otherwise a triaged-source row keeps its current Status (a live "In Progress" claim
     survives the move), and only a row with none (Intake source, blank cell) takes the
     "Needs Prioritization" default. Accepts either the display spelling ("In Progress") or
     the -NewStatus token spelling ("InProgress") (PF-IMP-1006).
   - -RejectionReason also seeds the re-route audit-trail -Reason when moving to Rejected (PF-IMP-1005).
   - -RespTask defaults to the destination section's conventional owner
     (PF-TSK-009 / PF-TSK-026 / PF-TSK-014 for Improvements / Extensions / StructuralChanges).
   - -Retriage (PF-IMP-857) is sugar for "IMP Triage is re-evaluating a triaged-section
     row": forces -RoutedBy = PF-TSK-089 (overriding the source-section default), and
     errors out for Intake-source moves (where PF-TSK-089 is already the default).
   - -RoutedBy defaults from the source section's conventional routing-task
     (PF-TSK-089 for Intake-source initial sorts; PF-TSK-009 / 026 / 014 for re-routes
     from those sections). Override only for the rare case where Triage re-evaluates
     a triaged-section row in a follow-up session.

   Requires the centralized 7-section tracking file, which is the default (resolved via
   Get-CentralFrameworkPath). -TrackingFile overrides it only for tests or legacy layouts.

3. Escalate (PF-PRO-068 WI-5 — Contract 6 federation):
   - Moves an IMP OUT of this workspace's tracker and into the Section 1 — Intake of another
     workspace's tracker on the parent-pointer chain, preserving the ID.
   - Use when triage finds that the artifact a finding targets is owned by a different
     workspace: the owner holds the canonical artifact, so the owner triages and fixes it.
   - -EscalateTo names the owning workspace by its declared project_id (e.g. 'FWK-FB').
     Resolution walks the parent-pointer chain (Resolve-WorkspaceRootById) and REFUSES an ID
     that is not on it, rather than guessing a destination.
   - Destination is always Intake — the receiving workspace owns the classification, so
     escalation hands over a finding, not a routing decision made on its behalf.
   - The ID is preserved because PF-IMP mints from ONE portfolio-global counter at the chain
     root (P-3); a duplicate ID already present in the target is a hard refusal.
   - Notes gain an "[ESCALATED YYYY-MM-DD from <origin> by PF-TSK-NNN: <reason>]" prefix
     (sibling of [REROUTED ...]) and the Source cell records the origin workspace — the
     receiving triage needs to know whose tree the finding came from to reproduce it.
   - Writes the target tracker BEFORE removing the source row: an interruption then leaves the
     row in both trackers (visible and reconcilable) rather than in neither.
   - This is the framework's one sanctioned cross-workspace write, and it is append-into-Intake
     only. Every other cross-workspace change goes through a migration entry (N-5 ownership).

When transitioning to Completed:
- Removes the row from the source section (Improvements / Extensions / Structural Changes) in $TrackingFile
- Adds a reformatted row to Section 6 — Completed in $ArchiveFile (archive-split 2026-05-13)
- Updates the <summary> item count (no-op for current layout; preserved for legacy)
- Updates frontmatter updated date on both files

When transitioning to Rejected (PF-IMP-852):
- Removes the row from the source section (Intake / Improvements / Extensions / Structural Changes) in $TrackingFile
- Adds a reformatted row to Section 7 — Rejected in $ArchiveFile with Rejection Reason = the
  caller-supplied -ValidationNotes; the source row's Notes column is preserved unchanged in
  the destination row
- Updates frontmatter updated date on both files
- Keeps "decided not to implement" distinct from "implemented" for trend analysis
  (per PF-IMP-803 rationale extended to outright rejection by PF-IMP-852)

PARAMETER REQUIREMENTS BY STATUS:
  Status                Required Parameters
  ----------            -------------------
  NeedsPrioritization   (none beyond ImprovementId, NewStatus)
  NeedsImplementation   (none beyond ImprovementId, NewStatus)
  InProgress            (none beyond ImprovementId, NewStatus)
  Deferred              (none beyond ImprovementId, NewStatus)
  Delegated             (none beyond ImprovementId, NewStatus)
  Completed             -Impact (HIGH|MEDIUM|LOW), -ValidationNotes (description of what was done);
                        -LogToolChanges (PF-IMP-832 (b), JSON payload — optional, folds the
                        PF-TSK-009's tool-change-logging step feedback_db log-change into the same call)
  Rejected              (PF-IMP-852) -ValidationNotes (rejection rationale — used as the
                        Rejection Reason column value). Moves the row to Section 7 — Rejected.
                        -Impact is ignored (Section 7 schema has no Impact column); a WARN is
                        emitted if -Impact is supplied.
  Superseded            (PF-IMP-832 (c)) -SupersededBy <IMP-NNN|PF-IMP-NNN|PF-PRO-NNN> (required —
                        the artifact that subsumes this one); -ValidationNotes optional (folded
                        into destination Notes ahead of existing content). Moves the row
                        to Section 7 — Rejected with Rejection Reason = "Superseded by
                        <SupersededBy>".
  Active                pilots only — IMP must be in Active Pilots section
  Resolved              pilots only — IMP must be in Active Pilots section; -Impact (HIGH|MEDIUM|LOW), -ValidationNotes (decision summary; required for Active→Resolved transition, optional for re-invocation/migration); triggers concept doc archive and moves pilot row to Completed Improvements (PF-IMP-729)

ANNOTATION (PF-IMP-832 (a), PF-IMP-863) — available alongside any non-pilot -NewStatus,
alone (annotation-only mode), or (-AppendNotes only, PF-IMP-1393 (c)) alongside -MoveToSection:
  -AppendNotes <text>       Idempotently append text to the Notes column. Skipped if the
                            same literal substring is already present in Notes. Date stamp
                            is the caller's responsibility (the script does not prefix
                            anything — caller controls wording).
  -SetRespTask <PF-TSK-NNN> Replace the Resp Task column value (validated against
                            ^[A-Z]{2,4}-TSK-\d+$). Skipped if already equal.
  -SetPriority <High|Medium|Low>
                            PF-IMP-1885. Replace the Priority column value on a triaged-section
                            row without a section move (a same-section -MoveToSection is refused
                            as a no-op, so this is the only re-prioritization path). Skipped if
                            already equal.
  -EditDescription <text>   PF-IMP-1007. Replace the Description column value. Idempotent —
                            skipped if already equal.
  -EditNotes <text>         PF-IMP-1007. Replace the Notes column value (vs -AppendNotes,
                            which appends). Mutually exclusive with -AppendNotes. Idempotent —
                            skipped if already equal.
  -AnnotateAsRolledInto <IMP-NNN|PF-IMP-NNN>
                            PF-IMP-863. Thin specialization of -AppendNotes for the
                            duplicate-of-open-IMP cluster-consolidation case. Operates on
                            the SURVIVING cluster owner (-ImprovementId). Folds a canonical
                            "[rolled-into PF-IMP-NNN YYYY-MM-DD]" annotation into Notes via
                            the same idempotent pipeline as -AppendNotes (re-invocation
                            with same source ID + same date → no-op). The source duplicate's
                            lifecycle is the caller's responsibility (typically a separate
                            -NewStatus Superseded -SupersededBy on the source IMP).
  When neither -NewStatus nor any annotation param is supplied, the script errors out.

.PARAMETER ImprovementId
The improvement ID to update (e.g., "IMP-063" for regular IMPs, or PF-IMP-NNN for pilots)

.PARAMETER NewStatus
The new status. Valid values: NeedsPrioritization, NeedsImplementation, InProgress, Completed, Deferred, Delegated, Rejected, Superseded (regular IMP statuses); Active, Resolved (pilot-only statuses, see PF-PRO-030).
Optional within StatusUpdate set since PF-IMP-832 (a) — omit when running pure annotation
via -AppendNotes / -SetRespTask alone.

.PARAMETER AppendNotes
PF-IMP-832 (a). Append text to the Notes column. In annotation-only mode this covers every
section — the 10-col triaged sections (Improvements / Extensions / Structural Changes), the
7-col Intake and Active Pilots sections (PF-IMP-1570), and the archive sections Completed
(8-col) and Rejected (7-col) (PF-IMP-1719). An archived row is edited in $ArchiveFile, and its
Resolution / Rejection Date is left as written — that date records when the row terminated, not
when it was last annotated. Idempotent — does not duplicate if the same
literal substring is already present in Notes. Date stamp is the caller's responsibility
(the script does not prefix anything). Available alongside any non-pilot -NewStatus or alone
(when used alone, the script writes the annotation without any status transition).
PF-IMP-1393 (c): also valid with -MoveToSection, so a route-with-coordination-note lands in
one call — the text is appended to each moved row's Notes after the [REROUTED ...] prefix
logic (every row of an -AlsoMoveIds batch gets the same note).

.PARAMETER SetRespTask
PF-IMP-832 (a). Replace the Resp Task column value on a row in one of the 10-col triaged
sections (validated against ^[A-Z]{2,4}-TSK-\d+$). Idempotent — skipped if Resp Task already equals
the supplied value. Available alongside any non-pilot -NewStatus or alone.

.PARAMETER SetPriority
PF-IMP-1885. Replace the Priority column value (High | Medium | Low) on a row in one of the
10-col triaged sections without a section move — a same-section -MoveToSection is refused as
a no-op, so this is the only path to re-prioritize an existing row (e.g. raising a merged
umbrella to High). Sibling of -SetRespTask: idempotent (skipped if Priority already equals
the supplied value), available alongside any non-pilot -NewStatus or alone.

.PARAMETER LogToolChanges
PF-IMP-832 (b). JSON payload (array, same shape as `feedback_db.py log-change --batch -`
accepts via stdin) of tool-change entries to log when the Completed transition runs. Folds
the PF-TSK-009's tool-change-logging step manual feedback_db invocation into the same call that flips the
status. Only valid with -NewStatus Completed. PF-IMP-1393 (b): the payload is validated
(JSON shape + tool_doc_ids, via log-change --validate-only) BEFORE the terminal move — a
bad tool_doc_id aborts the whole call with nothing written, so it can be fixed up front.
On a runtime log-change failure after the move, the IMP move is preserved (already written
before the log call) and a WARN is emitted.

First-time tool registration in mixed batches (PF-IMP-866 / supersedes PF-IMP-862):
the JSON pass-through carries arbitrary fields, so per-entry `"new_tool": true` opts
that row out of feedback_db.py's unknown-tool block while preserving typo detection on
the other entries. No dedicated -NewTool switch on this wrapper — annotate the JSON.
Example: `-LogToolChanges '[{"tool":"Existing.ps1","date":"2026-05-23","imp":"PF-IMP-XXX","description":"..."},
{"tool":"BrandNew.ps1","date":"2026-05-23","imp":"PF-IMP-XXX","description":"...","new_tool":true}]'`.

.PARAMETER SupersededBy
PF-IMP-832 (c). The artifact that subsumes / replaces this one (validated against
^(IMP|PF-IMP|PF-PRO)-\d+$ — existence is not checked). Required with -NewStatus Superseded.
PF-IMP-1019: PF-PRO IDs are accepted so a cluster of IMPs subsumed by a proposal /
extension concept can be recorded. The Superseded transition moves the row to
Section 7 — Rejected with Rejection Reason = "Superseded by <SupersededBy>".

.PARAMETER ArchiveConcept
PF-IMP-1688. The extension concept (PF-PRO-NNN) to move to proposals/old/ as part of this
transition — the full-rollout counterpart of the pilot path, which discovers its concept
from the Active Pilots row's Concept column instead (so this is rejected with
-NewStatus Resolved). Used by PF-TSK-026 Step 21 to close out a non-pilot extension.
Safe to re-run: an already-archived concept or an occupied destination WARNs rather than
failing the transition.

.PARAMETER Impact
Impact level. Valid values: HIGH, MEDIUM, LOW, "—" (em-dash placeholder).
- Required when NewStatus is Completed (use HIGH/MEDIUM/LOW).
- Ignored when NewStatus is Rejected (PF-IMP-852: Section 7 schema has no Impact column;
  a WARN is emitted if supplied so callers can update their invocations).

.PARAMETER ValidationNotes
Description of what was done or rationale for the lifecycle transition.
- Required when NewStatus is Completed — populates the Validation Notes column in
  Section 6 — Completed (folded with Impact prefix).
- Required when NewStatus is Rejected — populates the Rejection Reason column in
  Section 7 — Rejected verbatim (PF-IMP-852). Caller is responsible for wording
  (e.g., embedding "Rejecting per <task> on <date>" if desired). This is the
  rejection-reason carrier for the -NewStatus Rejected path; since PF-IMP-1343 the
  -RejectionReason alias is also accepted on this path (folded into -ValidationNotes).
- Ignored for other statuses.

.PARAMETER RejectionReason
The rejection reason. Serves two paths:
- SectionMove triage path (-MoveToSection Rejected): the Rejection Reason column value
  (and seeds the re-route audit-trail -Reason, PF-IMP-1005).
- StatusUpdate reject path (-NewStatus Rejected): PF-IMP-1343 accepts it as an alias for
  -ValidationNotes so `-NewStatus Rejected -RejectionReason "<reason>"` binds and works as
  agents expect. Folded into -ValidationNotes in Main. Supplying both -RejectionReason and
  -ValidationNotes, or -RejectionReason with a non-Rejected status, is a targeted error.

.PARAMETER EscalateTo
PF-PRO-068 WI-5. Declared project_id of the workspace that owns the artifact this IMP targets
(e.g. 'FWK-FB'). The row moves out of this workspace's tracker into that workspace's
Section 1 — Intake, ID-preserving. Resolution walks the parent-pointer chain and refuses an
ID that is not on it.

.PARAMETER TargetTrackingFile
Escape hatch for tests and two-level sandbox fixtures: the destination tracker path, bypassing
chain resolution of -EscalateTo. Production callers pass only -EscalateTo.

.PARAMETER EscalatedBy
Task ID credited in the "[ESCALATED ... by PF-TSK-NNN: ...]" audit-trail prefix. Defaults to
PF-TSK-089 (IMP Triage), which owns the escalation decision.

.PARAMETER TrackingFile
Path to the main process-improvement-tracking.md (live sections 1–5). Defaults to the
central path resolved via Get-CentralFrameworkPath. Override only for tests or non-default
layouts.

.PARAMETER ArchiveFile
Path to the sibling archive file containing Section 6 — Completed and Section 7 — Rejected
(archive-split 2026-05-13). Defaults to `archive/process-improvement-tracking-archive.md`
next to -TrackingFile. Override only for tests or non-default layouts.

.PARAMETER ImplementingTask
Task ID credited with the work in the Completed/Resolved row's Implementing Task column.
Optional override: for pilots it is otherwise extracted from the Pilot Description's
"(from PF-TSK-NNN)" pattern and defaults to PF-TSK-026; for regular IMPs it is sourced from the
row's Resp Task column.

.PARAMETER EditDescription
PF-IMP-1007. Replaces the Description column value (10-col triaged sections only). Idempotent —
skipped when already equal.

.PARAMETER EditNotes
PF-IMP-1007. Replaces the Notes column value outright, where -AppendNotes adds to it. Mutually
exclusive with -AppendNotes; 10-col triaged sections only. Idempotent — skipped when already
equal.

.PARAMETER AnnotateAsRolledInto
PF-IMP-863. Thin specialization of -AppendNotes for cluster consolidation: folds a canonical
"[rolled-into PF-IMP-NNN YYYY-MM-DD]" note into the Notes of the SURVIVING cluster owner named by
-ImprovementId. Accepts IMP-NNN or PF-IMP-NNN. Re-invocation with the same source ID and date is a
no-op. The absorbed duplicate's own lifecycle is the caller's job — typically a separate
-NewStatus Superseded -SupersededBy on that row.

.PARAMETER MoveToSection
SectionMove parameter set. Destination section for a triage move. Valid values: Intake,
Improvements, Extensions, StructuralChanges, Rejected — ActivePilots and Completed are excluded
because they have specialized flows. Column schemas are transformed between source and
destination automatically.

.PARAMETER AlsoMoveIds
SectionMove batch mode (PF-IMP-982). Additional improvement IDs to move to the same section with
the same options in one call. Each ID's source section is resolved independently; an ID that is
not found or fails is reported and skipped without aborting the rest of the batch. Accepts a real
array (-Command callers) or a comma-separated string — split per the framework CSV-string
convention so the list survives pwsh -File's literal-token binding (PF-IMP-1830 / PF-IMP-1542):
-AlsoMoveIds "PF-IMP-811,PF-IMP-812" works from -File.

.PARAMETER Priority
SectionMove parameter set. Priority written into the destination row (the triaged sections carry a
Priority column).

.PARAMETER Status
SectionMove parameter set. Status written into the destination row. When omitted, resolved per
row (PF-IMP-1831): a triaged-source row keeps its current Status across the move; a row with no
preservable Status (Intake source, blank cell) takes "Needs Prioritization". Accepts either the
display spelling ("In Progress") or the -NewStatus token spelling ("InProgress") (PF-IMP-1006).

.PARAMETER RespTask
SectionMove parameter set. Owning task written into the destination row's Resp Task column.
Defaults to the destination section's conventional owner — PF-TSK-009 for Improvements,
PF-TSK-026 for Extensions, PF-TSK-014 for Structural Changes.

.PARAMETER RoutedBy
SectionMove parameter set. Task credited in the [REROUTED ...] audit-trail prefix. Defaults from
the source section's conventional routing task: PF-TSK-089 for Intake-source initial sorts;
PF-TSK-009 / PF-TSK-026 / PF-TSK-014 for re-routes out of those sections. Override only when
Triage re-evaluates a triaged-section row in a follow-up session — see -Retriage.

.PARAMETER Retriage
SectionMove parameter set (PF-IMP-857). Sugar for "IMP Triage is re-evaluating a triaged-section
row": forces -RoutedBy to PF-TSK-089, overriding the source-section default. Errors on
Intake-source moves, where PF-TSK-089 is already the default.

.PARAMETER Reason
SectionMove parameter set. Reason text embedded in the [REROUTED YYYY-MM-DD by PF-TSK-NNN: ...]
Notes prefix on a re-route. Ignored on Intake-source moves, which produce no prefix (PF-IMP-1238)
— pass -AppendNotes in the same call to attach a note there. Seeded from -RejectionReason when
moving to Rejected (PF-IMP-1005).

BASH GOTCHA: When invoking from bash, use single-quoted -ValidationNotes
(e.g., -ValidationNotes 'text with `code` references') because bash interprets
backticks inside double-quoted strings as command substitution, silently truncating
literal-code spans like `[string]$Param` to empty before pwsh receives the argument.
The script will report success but store corrupted notes. PowerShell-native
invocation is unaffected.

.EXAMPLE
# Mark improvement as needing implementation (after prioritization)
Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "NeedsImplementation"

.EXAMPLE
# Mark improvement as in progress
Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "InProgress"

.EXAMPLE
# Complete an improvement
Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "Completed" -Impact "MEDIUM" -ValidationNotes "Created Update-ProcessImprovement.ps1 script."

.EXAMPLE
# Reject an improvement (PF-IMP-852: routes to Section 7 — Rejected; -ValidationNotes becomes the Rejection Reason)
Update-ProcessImprovement.ps1 -ImprovementId "IMP-061" -NewStatus "Rejected" -ValidationNotes "Evaluated and determined not beneficial. Rejecting per PF-TSK-009 session 2026-05-12."

.EXAMPLE
# Reject using the -RejectionReason alias (PF-IMP-1343): identical effect to the -ValidationNotes form above
Update-ProcessImprovement.ps1 -ImprovementId "IMP-061" -NewStatus "Rejected" -RejectionReason "Evaluated and determined not beneficial. Rejecting per PF-TSK-009 session 2026-05-12."

.EXAMPLE
# Defer an improvement
Update-ProcessImprovement.ps1 -ImprovementId "IMP-037" -NewStatus "Deferred"

.EXAMPLE
# Resolve a pilot (PF-PRO-030 lifecycle): records decision, archives the linked concept doc, and moves the row to Completed Improvements
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-688" -NewStatus "Resolved" -Impact "MEDIUM" -ValidationNotes "Soak pilot proven; broader rollout filed as PF-IMP-700"

.EXAMPLE
# Pure annotation (PF-IMP-832 (a)): append text to Notes without any status change
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-832" -AppendNotes "[Delegated 2026-05-12 by PF-TSK-009: scope mismatch — re-route to PF-TSK-014]"

.EXAMPLE
# Pure annotation: replace Resp Task without any status change
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-832" -SetRespTask "PF-TSK-014"

.EXAMPLE
# Combined: claim an IMP (status change) + append delegation note + set Resp Task in one call
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-832" -NewStatus "InProgress" -AppendNotes "[Claimed 2026-05-12 by PF-TSK-009 session]" -SetRespTask "PF-TSK-009"

.EXAMPLE
# Complete with tool-change logging (PF-IMP-832 (b)): folds PF-TSK-009's tool-change-logging step into the same call
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-832" -NewStatus "Completed" -Impact "MEDIUM" -ValidationNotes "Added params (a), (b), (c), (d)." -LogToolChanges '[{"tool":"Update-ProcessImprovement.ps1","date":"2026-05-12","imp":"PF-IMP-832","description":"Added -AppendNotes, -SetRespTask, -LogToolChanges, -SupersededBy params; new Superseded status; improved Resolved error message"}]'

.EXAMPLE
# Supersede an IMP (PF-IMP-832 (c)): move to Section 7 Rejected with "Superseded by ..." reason
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-786" -NewStatus "Superseded" -SupersededBy "PF-IMP-832" -ValidationNotes "Consolidated into PF-IMP-832 cluster during PF-TSK-089 IMP Triage on 2026-05-11"

.EXAMPLE
# IMP Triage initial sort: move from Intake to Improvements
# (defaults: -Status=Needs Prioritization, -RespTask=PF-TSK-009, -RoutedBy=PF-TSK-089)
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-800" -MoveToSection "Improvements" -Priority "Medium" -TrackingFile "C:\path\to\appdev\process-framework-central\state-tracking\permanent\process-improvement-tracking.md"

.EXAMPLE
# IMP Triage rejection: move from Intake to Rejected with one-line rejection reason
# (-RoutedBy defaults to PF-TSK-089 from the Intake source section)
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-801" -MoveToSection "Rejected" -RejectionReason "Duplicate of PF-IMP-650 (already resolved)" -TrackingFile "<central path>"

.EXAMPLE
# Re-route from Improvements to Structural Changes by PF-TSK-009 after evaluating scope mismatch
# (auto-prepends [REROUTED 2026-MM-DD by PF-TSK-009: <reason>] to Notes; -RoutedBy defaults from source section)
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-802" -MoveToSection "StructuralChanges" -Priority "High" -Reason "Requires directory reorganization" -TrackingFile "<central path>"

.EXAMPLE
# Batch sort (PF-IMP-982): move several Intake rows to Improvements in one call.
# Each ID's source section is detected independently; a not-found/failed ID is reported
# and skipped without aborting the rest of the batch. The CSV form shown works from
# pwsh -File (PF-IMP-1830); -Command callers may pass a real array instead.
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-810" -AlsoMoveIds "PF-IMP-811,PF-IMP-812" -MoveToSection "Improvements" -Priority "Medium" -TrackingFile "<central path>"

.EXAMPLE
# Escalate a finding whose target artifact is owned by another workspace (PF-PRO-068 WI-5).
# The row leaves this tracker and lands in FWK-FB's Intake with its ID intact.
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-900" -EscalateTo "FWK-FB" -Reason "Defect in the shared substrate helper Core.psm1, owned by FWK-FB"

.EXAMPLE
# Route-with-coordination-note in ONE call (PF-IMP-1393 (c)): sort an Intake row and attach
# the triage note to the moved row's Notes in the same invocation (no follow-up -AppendNotes call).
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-820" -MoveToSection "Improvements" -Priority "Medium" -AppendNotes "[TRIAGE 2026-07-13] Coordinate: PF-IMP-821 edits the same file - one implementing session can take both."

.NOTES
This script is part of the Process Improvement automation system and integrates with:
- Process Improvement Task (PF-TSK-009)
- Tools Review Task (PF-TSK-010)

Output behavior: Default output is one summary line per invocation (the operation
outcome, e.g. "PF-IMP-697 → InProgress"), plus one extra line per side-effect
(concept-doc archive on pilot Resolved). WARN and ERROR messages always pass
through. Pass -Verbose to restore the full play-by-play log (banner, parameter
echoes, prereq narration, per-step transformer messages) for debugging.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "StatusUpdate")]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidatePattern('^(IMP|PF-IMP)-\d+$')]
    [string]$ImprovementId,

    # --- StatusUpdate parameter set (existing behavior) ---

    # PF-IMP-832 (a): NewStatus is optional within StatusUpdate so that pure annotation
    # (-AppendNotes / -SetRespTask alone) can fire without an artificial status transition.
    # Main validates that at least one of -NewStatus, -AppendNotes, or -SetRespTask is bound.
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidateSet("NeedsPrioritization", "NeedsImplementation", "InProgress", "Completed", "Deferred", "Delegated", "Rejected", "Superseded", "Active", "Resolved")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidateSet("HIGH", "MEDIUM", "LOW", "—")]
    [string]$Impact,

    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [string]$ValidationNotes,

    # Phase 7 cross-schema move-to-Completed (Session 11, 2026-05-11): when a pilot or
    # improvement transitions to Completed, the new 8-col Completed schema requires an
    # Implementing Task value. For the improvement path, this defaults to the source row's
    # Resp Task. For the pilot path, this defaults to the OriginatingTask regex-extracted
    # from the Pilot Description (falling back to PF-TSK-026). Pass -ImplementingTask
    # explicitly when the actual implementing task differs from those defaults.
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidatePattern('^[A-Z]{2,4}-TSK-\d+$')]
    [string]$ImplementingTask,

    # PF-IMP-832 (b): JSON payload (array, same shape as feedback_db.py log-change --batch -
    # accepts via stdin) of tool-change entries to log when the Completed transition runs.
    # Folds the PF-TSK-009's tool-change-logging step manual feedback_db log-change invocation into the same
    # call that flips the status, keeping the change log atomic with the status transition.
    # Only valid with -NewStatus Completed. On log-change failure, the IMP move is preserved
    # (already written before the log call) and a WARN is emitted — the caller can retry the
    # log-change manually with the same JSON.
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [string]$LogToolChanges,

    # PF-IMP-832 (c): the IMP that subsumes / replaces this one. Required when
    # -NewStatus is "Superseded". Pattern-validated against ^(IMP|PF-IMP|PF-PRO)-\d+$;
    # existence is not checked (the subsuming artifact may live in any section).
    # PF-IMP-1019: PF-PRO accepted because a cluster of IMPs is sometimes subsumed by
    # a proposal / extension concept (PF-PRO-NNN) rather than by another IMP.
    # The Superseded transition moves the row to Section 7 — Rejected with
    # Rejection Reason = "Superseded by <SupersededBy>" so trend analysis can
    # distinguish supersession from implementation (per PF-IMP-803 rationale).
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidatePattern('^(IMP|PF-IMP|PF-PRO)-\d+$')]
    [string]$SupersededBy,

    # PF-IMP-1688: the extension concept (PF-PRO-NNN) to archive alongside this transition.
    # The pilot path (-NewStatus Resolved) discovers its concept from the Active Pilots
    # row's Concept column; sections 2-4 carry no such column, so a full-rollout extension
    # closing at PF-TSK-026 Step 21 names the concept explicitly here. Same archive
    # semantics either way (Move-ConceptToArchive): warns and continues when the concept
    # is already archived or a destination file exists, so a re-run is safe.
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidatePattern('^PF-PRO-\d+$')]
    [string]$ArchiveConcept,

    # --- Annotate parameter set (PF-IMP-832 (a)) ---
    # Pure annotation: edits Notes and/or Resp Task on a row in one of the 10-col
    # triaged sections (Improvements / Extensions / Structural Changes) without
    # any status transition. -AppendNotes and -SetRespTask are also available as
    # optional add-ons in the StatusUpdate set (combine annotation with status
    # change in one call).
    # At least one of -AppendNotes or -SetRespTask is required when no -NewStatus
    # or -MoveToSection is supplied (runtime-validated in Main).

    # --- SectionMove parameter set (new — PF-TSK-089 IMP Triage helper) ---
    # Targets the centralized 7-section process-improvement-tracking.md (created in PF-PRO-029 Phase 2).
    # Moves rows between Intake / Improvements / Extensions / Structural Changes / Rejected.
    # Active Pilots and Completed are excluded — they have specialized flows
    # (-NewStatus Active/Resolved for pilots; -NewStatus Completed for completion).

    [Parameter(Mandatory = $true, ParameterSetName = "SectionMove")]
    [ValidateSet("Intake", "Improvements", "Extensions", "StructuralChanges", "Rejected")]
    [string]$MoveToSection,

    # PF-IMP-982: batch mode. Additional IMP IDs to move to the SAME -MoveToSection
    # with the SAME options (-Priority / -Status / -RespTask / -Reason / -RejectionReason)
    # as -ImprovementId. Lets IMP Triage sort several rows in one call. Each ID's source
    # section is detected independently (so -RoutedBy / re-route prefix resolve per-ID);
    # a not-found or failed ID is reported and skipped without aborting the rest of the
    # batch. The accumulated result is written once at the end.
    # PF-IMP-1830: each element may itself be a comma-separated ID list, split in the batch
    # build — pwsh -File binds 'a,b,c' as ONE literal element (no in-session array parsing),
    # so without the CSV form the batch mode is unreachable from the framework's prescribed
    # -File invocation (split-in-place pattern: PF-IMP-1428, implementation copied from
    # Run-Tests -TestFile, PF-IMP-1542). The pattern validates every ID in the element at
    # binding, so a malformed ID still fails fast.
    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [ValidatePattern('^\s*(IMP|PF-IMP)-\d+(\s*,\s*(IMP|PF-IMP)-\d+)*\s*$')]
    [string[]]$AlsoMoveIds,

    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [ValidateSet("High", "Medium", "Low")]
    [string]$Priority,

    # PF-IMP-1006: accept BOTH the display spelling ("In Progress") and the token
    # spelling ("InProgress") that -NewStatus (StatusUpdate set) uses, so callers do
    # not have to remember two different spellings across the two parameter sets.
    # Token forms are normalized to the display form in Main before the column write.
    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [ValidateSet("Needs Prioritization", "Needs Implementation", "In Progress",
                 "NeedsPrioritization", "NeedsImplementation", "InProgress")]
    [string]$Status,

    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [ValidatePattern('^[A-Z]{2,4}-TSK-\d+$')]
    [string]$RespTask,

    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [ValidatePattern('^[A-Z]{2,4}-TSK-\d+$')]
    [string]$RoutedBy,

    # PF-IMP-857: -Retriage is sugar over the existing -RoutedBy auto-default. When a
    # triaged-section row (Improvements / Extensions / Structural Changes) is being
    # re-evaluated by IMP Triage in a follow-up session, -RoutedBy must point to
    # PF-TSK-089 (Triage) — not the source section's owner (the existing default).
    # -Retriage makes the intent explicit and flips -RoutedBy to PF-TSK-089 if no
    # explicit override was passed. Invalid for source=Intake (initial triage is
    # the default for Intake-source moves; -Retriage would be a contradiction).
    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [switch]$Retriage,

    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [Parameter(Mandatory = $false, ParameterSetName = "Escalate")]
    [string]$Reason,

    # PF-IMP-1343: also valid in the StatusUpdate set so the status-path reject call
    # `-NewStatus Rejected -RejectionReason "<reason>"` binds cleanly. Without the second
    # set membership that call mixes the StatusUpdate-only -NewStatus with this otherwise
    # SectionMove-only param and dies at parameter-set resolution — before the body's
    # targeted "use -ValidationNotes" error can ever fire (a binder error can't be caught
    # in-body). On the StatusUpdate path it is folded into -ValidationNotes (the reject-reason
    # carrier) in Main; on the SectionMove path it keeps its -MoveToSection Rejected meaning.
    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [string]$RejectionReason,

    # --- Annotation params (PF-IMP-832 (a)) — optional within StatusUpdate ---
    # Can be supplied alone (pure annotation: no status change) or alongside -NewStatus
    # (apply annotation, then perform the status transition). Pilot statuses are not
    # supported (7-col Active Pilots schema has no Resp Task column).

    # PF-IMP-1393 (c): also valid in the SectionMove set so a route-with-coordination-note
    # lands in one call — the text is appended to each moved row's Notes after the
    # [REROUTED ...] prefix logic, with the same idempotent substring semantics as the
    # StatusUpdate-set annotation. In an -AlsoMoveIds batch, every moved row gets the note.
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [string]$AppendNotes,

    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidatePattern('^[A-Z]{2,4}-TSK-\d+$')]
    [string]$SetRespTask,

    # PF-IMP-1885: replace the Priority column on a row in one of the 10-col triaged
    # sections without a section move. -Priority lives in the SectionMove set and a
    # same-section -MoveToSection is refused as a no-op, so before this param a row's
    # priority could not be changed in place. Sibling of -SetRespTask: available alone
    # (pure annotation) or alongside any non-pilot -NewStatus; idempotent.
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidateSet("High", "Medium", "Low")]
    [string]$SetPriority,

    # PF-IMP-1007: replace (not append) the Description / Notes column on a row in
    # one of the 10-col triaged sections (Improvements / Extensions / Structural
    # Changes). Sibling of -AppendNotes (append) and -SetRespTask (replace Resp Task);
    # available alone (pure edit, no status change) or alongside -NewStatus.
    # Idempotent — skipped if the column already equals the supplied value.
    # -EditNotes and -AppendNotes are mutually exclusive (one replaces, the other
    # appends — combining them on the same Notes cell is ambiguous).
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [string]$EditDescription,

    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [string]$EditNotes,

    # PF-IMP-863: thin specialization of -AppendNotes for the duplicate-of-open-IMP
    # cluster-consolidation case. Operates on the SURVIVING IMP — the cluster owner
    # that absorbed the duplicate. Appends a canonical "[rolled-into <SourceId> on
    # <date>]" annotation to its Notes column. The source (duplicate) IMP's lifecycle
    # is the caller's responsibility (typically -NewStatus Superseded -SupersededBy on
    # the source IMP in a separate invocation). Idempotent via existing -AppendNotes
    # substring-check (same canonical message → no-op on re-invocation).
    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidatePattern('^(IMP|PF-IMP)-\d+$')]
    [string]$AnnotateAsRolledInto,

    # --- Escalate parameter set (PF-PRO-068 WI-5 — Contract 6 federation) ---
    # Moves an IMP from THIS workspace's tracker into the Intake of the tracker owned by
    # another workspace on the parent-pointer chain, preserving the ID.
    #
    # Why a distinct operation rather than a -MoveToSection destination: every SectionMove
    # destination is a section of the SAME file, and its whole contract (source-section
    # resolution, re-route prefixes, no-op refusal) is written in those terms. Escalation
    # crosses a workspace boundary, which changes what "where is this row" even means — and it
    # is the ONE sanctioned cross-workspace write in the framework, so it is worth being
    # unmissable at the call site rather than hidden behind a section name.

    [Parameter(Mandatory = $true, ParameterSetName = "Escalate")]
    [ValidatePattern('^[A-Z][A-Z0-9]*-[A-Z0-9]+$')]
    [string]$EscalateTo,

    # Escape hatch for tests and two-level sandbox fixtures: the destination tracker path,
    # bypassing chain resolution of -EscalateTo. Production callers pass only -EscalateTo.
    [Parameter(Mandatory = $false, ParameterSetName = "Escalate")]
    [string]$TargetTrackingFile,

    [Parameter(Mandatory = $false, ParameterSetName = "Escalate")]
    [ValidatePattern('^[A-Z]{2,4}-TSK-\d+$')]
    [string]$EscalatedBy,

    # --- Common: optional override for tracking file path ---
    # Phase 7 (2026-05-11): default is now the central process-improvement-tracking.md, resolved
    # via Get-CentralFrameworkPath. -TrackingFile remains as an escape hatch for tests or for
    # editing legacy project-local files during the historical-content migration window.
    [Parameter(Mandatory = $false)]
    [string]$TrackingFile,

    # Archive-split (2026-05-13): Section 6 Completed and Section 7 Rejected
    # live in a sibling archive file to keep the active tracking file small.
    # Default: `archive/process-improvement-tracking-archive.md` next to
    # $TrackingFile. Override only for tests or non-default layouts.
    [Parameter(Mandatory = $false)]
    [string]$ArchiveFile
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
# Temporarily silence $VerbosePreference around the import so -Verbose callers see
# only this script's own Write-Verbose output, not the helper module's internal
# Write-Verbose chatter (and its cascaded sub-module Import-Module messages).
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Configuration
# Phase 7 (2026-05-11): default is the central process-improvement-tracking.md, resolved via
# Get-CentralFrameworkPath. The script writes to the same file from cwd=appdev and cwd=project.
# -TrackingFile escape hatch retained for tests / legacy-file edits.
if (-not $TrackingFile) {
    $TrackingFile = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "state-tracking/permanent/process-improvement-tracking.md"
}
# Archive-split (2026-05-13): default ArchiveFile sits in an `archive/` subdir
# next to $TrackingFile. Honors -TrackingFile overrides — tests passing a
# custom tracking path get an archive path computed relative to it.
if (-not $ArchiveFile) {
    $trackingDir = Split-Path -Parent $TrackingFile
    $ArchiveFile = Join-Path -Path $trackingDir -ChildPath "archive/process-improvement-tracking-archive.md"
}
$ScriptName = "Update-ProcessImprovement.ps1"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# Soak verification (PF-PRO-028 — see process-framework-central/state-tracking/permanent/script-soak-tracking.md; v2.1 normalized ScriptId per PF-PRO-032)
$soakScriptId = "scripts/update/Update-ProcessImprovement.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

# Display name mapping (ValidateSet value → human-readable status text in tracking file)
$StatusDisplayNames = @{
    "NeedsPrioritization" = "Needs Prioritization"
    "NeedsImplementation" = "Needs Implementation"
    "InProgress"          = "In Progress"
    "Completed"           = "Completed"
    "Deferred"            = "Deferred"
    "Delegated"           = "Delegated"
    "Rejected"            = "Rejected"
    "Superseded"          = "Superseded"
    "Active"              = "Active"
    "Resolved"            = "Resolved"
}

# Pilot-only statuses (PF-PRO-030)
$PilotStatuses = @("Active", "Resolved")

function Test-Prerequisites {
    Write-ProjectLog "Checking prerequisites..."

    if (-not (Test-Path $TrackingFile)) {
        Write-ProjectLog "Tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # Validate required parameters for completion/rejection
    if ($NewStatus -in @("Completed", "Rejected")) {
        if (-not $ValidationNotes) {
            if ($NewStatus -eq "Rejected") {
                # PF-IMP-1164 / PF-IMP-1343: the -NewStatus Rejected flow takes the rejection
                # reason via -ValidationNotes or its alias -RejectionReason (PF-IMP-1343 folds
                # the latter into the former in Main). Reaching here means neither was supplied.
                Write-ProjectLog "A rejection reason is required when transitioning to Rejected: pass it via -ValidationNotes or -RejectionReason (it becomes the Rejection Reason)." -Level "ERROR"
            } else {
                Write-ProjectLog "ValidationNotes is required when transitioning to $NewStatus" -Level "ERROR"
            }
            return $false
        }
        if ($NewStatus -eq "Completed" -and -not $Impact) {
            Write-ProjectLog "Impact is required when transitioning to Completed (use HIGH/MEDIUM/LOW)" -Level "ERROR"
            return $false
        }
        # PF-IMP-852: Rejected routes to Section 7 — Rejected (7-col schema, no Impact column).
        # -Impact is silently ignored if supplied; emit WARN so callers can drop it from invocations.
        if ($NewStatus -eq "Rejected" -and $Impact) {
            Write-ProjectLog "-Impact is ignored when transitioning to Rejected (Section 7 schema has no Impact column)" -Level "WARN"
        }
    }

    # Validate required parameters for pilot resolution (PF-PRO-030, PF-IMP-729)
    # -Impact required (parallel to Completed). -ValidationNotes optional: required for fresh Active→Resolved
    # transitions (decision summary) but allowed to be empty for re-invocation/migration of already-resolved pilots
    # whose Notes column already contains the resolution narrative.
    if ($NewStatus -eq "Resolved" -and -not $Impact) {
        Write-ProjectLog "Impact is required when transitioning a pilot to Resolved (use HIGH/MEDIUM/LOW)" -Level "ERROR"
        return $false
    }

    # PF-IMP-832 (b): -LogToolChanges only valid with -NewStatus Completed
    if ($LogToolChanges -and $NewStatus -ne "Completed") {
        Write-ProjectLog "-LogToolChanges is only valid with -NewStatus Completed (got '$NewStatus'). The log-change call is bundled with the completion transition." -Level "ERROR"
        return $false
    }

    # PF-IMP-1688: -ArchiveConcept is the full-rollout counterpart of the pilot path's
    # automatic concept discovery; on Resolved the Concept column already supplies it.
    if ($ArchiveConcept -and $NewStatus -eq "Resolved") {
        Write-ProjectLog "-ArchiveConcept is not used with -NewStatus Resolved — the pilot path reads the concept from the Active Pilots row's Concept column." -Level "ERROR"
        return $false
    }

    # PF-IMP-832 (c): -NewStatus Superseded requires -SupersededBy
    if ($NewStatus -eq "Superseded" -and -not $SupersededBy) {
        Write-ProjectLog "-SupersededBy is required when transitioning to Superseded (pattern: IMP-NNN, PF-IMP-NNN, or PF-PRO-NNN)" -Level "ERROR"
        return $false
    }
    # And -SupersededBy is only meaningful with -NewStatus Superseded
    if ($SupersededBy -and $NewStatus -ne "Superseded") {
        Write-ProjectLog "-SupersededBy is only valid with -NewStatus Superseded (got '$NewStatus')" -Level "ERROR"
        return $false
    }

    Write-ProjectLog "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Pilot helpers (PF-PRO-030) ---

function Test-ImprovementLocation {
    # Returns "Intake", "ActivePilots", "Current", "Extensions", "StructuralChanges",
    # "Completed", "Rejected", or "NotFound".
    # Archive-split (2026-05-13): §6/§7 live in $ArchiveContent (sibling file);
    # §1-§5 live in $Content (main tracking file). Callers MUST supply both.
    # PF-IMP-861: Intake (§1) added — previously the helper returned "NotFound"
    # for Intake rows, which forced Main to special-case the supersedure/rejection
    # paths with a "NotFound bypass" (see Main's $isSupersedure/$isRejection branch).
    # With Intake coverage, the bypass collapses into a clean "is in Intake" branch.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId
    )
    $mainSections = [ordered]@{
        "Intake"            = "## Section 1 — Intake"
        "ActivePilots"      = "## Section 5 — Active Pilots"
        "Current"           = "## Section 2 — Improvements"
        "Extensions"        = "## Section 3 — Extensions"
        "StructuralChanges" = "## Section 4 — Structural Changes"
    }
    $archiveSections = [ordered]@{
        "Completed"         = "## Section 6 — Completed"
        "Rejected"          = "## Section 7 — Rejected"
    }

    foreach ($key in $mainSections.Keys) {
        $rows = ConvertFrom-MarkdownTable -Content $Content -Section $mainSections[$key]
        if ($rows | Where-Object { $_.ID -eq $ImprovementId }) {
            return $key
        }
    }
    if ($ArchiveContent) {
        foreach ($key in $archiveSections.Keys) {
            $rows = ConvertFrom-MarkdownTable -Content $ArchiveContent -Section $archiveSections[$key]
            if ($rows | Where-Object { $_.ID -eq $ImprovementId }) {
                return $key
            }
        }
    }
    return "NotFound"
}

function Update-PilotStatusInPlace {
    param(
        [string]$Content,
        [string]$ImprovementId,
        [string]$NewStatus,
        [string]$Notes  # On Resolved: appended to Notes column with date prefix
    )

    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Section 5 — Active Pilots" -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) {
        Write-ProjectLog "Pilot $ImprovementId not found in Active Pilots section" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    Write-ProjectLog "Found pilot entry for $ImprovementId"

    # Phase 7 pilot schema (central): | ID | Concept | Pilot Description | Project | Framework Version | Status | Notes |
    # Indices:                            0    1         2                    3         4                   5        6
    $columns = Split-MarkdownTableRow $currentEntry
    if ($null -eq $columns -or $columns.Count -ne 7) {
        $actualCount = if ($null -eq $columns) { 0 } else { $columns.Count }
        Write-ProjectLog "Malformed pilot row for $ImprovementId`: expected 7 columns (Phase 7 central schema), found $actualCount. $script:MalformedRowEscapeHint" -Level "ERROR"
        Write-ProjectLog "Cells as parsed:`n$(Get-MalformedRowDiagnostic -Columns $columns -ExpectedCount 7)" -Level "ERROR"
        Write-ProjectLog "Raw row: $currentEntry" -Level "ERROR"
        return $null
    }

    $displayName = $StatusDisplayNames[$NewStatus]
    $columns[5] = $displayName

    # On Resolved: append decision notes to Notes column (preserving any existing)
    if ($NewStatus -eq "Resolved" -and $Notes) {
        $existingNotes = $columns[6].Trim()
        $resolvedNote = "Resolved ${CurrentDate}: $Notes"
        if ($existingNotes -and $existingNotes -ne "") {
            $columns[6] = "$existingNotes; $resolvedNote"
        } else {
            $columns[6] = $resolvedNote
        }
    }

    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-ProjectLog "Updated pilot $ImprovementId status to: $displayName" -Level "SUCCESS"
    return $result
}

function Get-ConceptIdFromPilotRow {
    param(
        [string]$Content,
        [string]$ImprovementId
    )
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Section 5 — Active Pilots"
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) { return $null }

    # Phase 7 schema (Session 11, 2026-05-11): Concept column holds the PF-PRO-NNN ID directly
    # (was the "Source" column in the legacy 8-col schema, formatted as "PF-PRO-NNN / PF-TSK-NNN").
    if ($row.Concept -match 'PF-PRO-\d+') {
        return $matches[0]
    }
    return $null
}

function Move-ConceptToArchive {
    param([string]$ConceptId)

    # Phase 7 cutover: concept docs now live in appdev/process-framework-central/proposals/
    # regardless of cwd. Resolved via Get-CentralFrameworkPath.
    $proposalsDir = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "proposals"
    if (-not (Test-Path $proposalsDir)) {
        Write-ProjectLog "Proposals directory not found: $proposalsDir" -Level "WARN"
        return $false
    }

    # Find concept file by frontmatter id
    $sourcePath = $null
    Get-ChildItem -Path $proposalsDir -Filter "*.md" -File | ForEach-Object {
        if ($null -ne $sourcePath) { return }
        $fileContent = Get-Content -Path $_.FullName -Raw -Encoding UTF8
        if ($fileContent -match "(?m)^id:\s*$([regex]::Escape($ConceptId))\s*$") {
            $sourcePath = $_.FullName
        }
    }

    if (-not $sourcePath) {
        Write-ProjectLog "Concept $ConceptId not found in $proposalsDir (may already be archived). Skipping concept archive." -Level "WARN"
        return $true
    }

    $oldDir = Join-Path $proposalsDir "old"
    if (-not (Test-Path $oldDir)) {
        New-Item -ItemType Directory -Path $oldDir -Force | Out-Null
    }

    $destPath = Join-Path $oldDir (Split-Path $sourcePath -Leaf)
    if (Test-Path $destPath) {
        Write-ProjectLog "Concept $ConceptId already exists at archive destination: $destPath. Manual cleanup required." -Level "WARN"
        return $false
    }

    if ($PSCmdlet.ShouldProcess($sourcePath, "Move concept $ConceptId to proposals/old/")) {
        Move-Item -Path $sourcePath -Destination $destPath -Force
        Write-ProjectSummary "Archived concept $ConceptId to $destPath"
    }
    return $true
}

function Move-PilotToCompletedSection {
    # PF-IMP-729 + Phase 7 cross-schema fix (Session 11, 2026-05-11):
    # Transforms 7-column Active Pilots schema into 8-column Completed schema.
    # Source: | ID | Concept | Pilot Description | Project | Framework Version | Status | Notes |
    # Dest:   | ID | Description | Project | Framework Version | Resolution Date | Implementing Task | Resolved From | Notes |
    #
    # Archive-split (2026-05-13): destination row goes into $ArchiveContent
    # (sibling archive file). Returns @{ Content; ArchiveContent } on success,
    # $null on failure. Source-only removal applies to $Content.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId,
        [string]$Impact,
        [string]$ImplementingTask  # Optional override; otherwise extracted from Pilot Description "(from PF-TSK-NNN)" pattern, defaulting to PF-TSK-026
    )

    # Read pilot row to extract source columns for transformation
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Section 5 — Active Pilots"
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) {
        Write-ProjectLog "Pilot $ImprovementId not found in Active Pilots section for move" -Level "ERROR"
        return $null
    }

    # Build composite Description: keep the concept reference + the pilot description text
    $pilotDescription = $row.'Pilot Description'
    $description = "Pilot ($($row.Concept)): $pilotDescription"

    # Resolve Implementing Task: explicit parameter wins; otherwise regex-extract from the
    # Pilot Description text (New-ProcessImprovement.ps1 -AsPilot embeds the originating task
    # as "Pilot of <PF-PRO-NNN> (from <PF-TSK-NNN>)"); fall back to PF-TSK-026 (typical owner).
    if (-not $ImplementingTask) {
        if ($pilotDescription -match '\(from\s+([A-Z]{2,4}-TSK-\d+)\)') {
            $ImplementingTask = $matches[1]
        } else {
            $ImplementingTask = 'PF-TSK-026'
        }
    }

    # Synthesize Notes column: the new 8-col Completed schema folds Impact and any prior
    # "Resolved YYYY-MM-DD: ..." Notes-suffix (added by Update-PilotStatusInPlace) into one
    # cell since there are no separate Impact / Validation Notes columns anymore.
    $existingNotes = $row.Notes
    $synthesizedNotes = if ($Impact -and $existingNotes) {
        "Impact: $Impact. $existingNotes"
    } elseif ($Impact) {
        "Impact: $Impact."
    } else {
        $existingNotes
    }

    # All 8 destination columns must be listed in ColumnMapping to control output order.
    # Source-mapped: ID, Project, Framework Version. Synthesized: Description, Resolution
    # Date, Implementing Task, Resolved From, Notes — AdditionalColumns wins per the
    # Move-MarkdownTableRow contract (TableOperations.psm1 line 869).
    $columnMapping = [ordered]@{
        "ID"                = "ID"
        "Description"       = "_synthesized_"
        "Project"           = "Project"
        "Framework Version" = "Framework Version"
        "Resolution Date"   = "_synthesized_"
        "Implementing Task" = "_synthesized_"
        "Resolved From"     = "_synthesized_"
        "Notes"             = "_synthesized_"
    }
    $additionalColumns = [ordered]@{
        "Description"       = $description
        "Resolution Date"   = $CurrentDate
        "Implementing Task" = $ImplementingTask
        "Resolved From"     = "Active Pilot"
        "Notes"             = $synthesizedNotes
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -DestinationContent $ArchiveContent `
        -RowIdPattern ([regex]::Escape($ImprovementId)) `
        -SourceSection "## Section 5 — Active Pilots" `
        -DestinationSection "## Section 6 — Completed" `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns `
        -SectionEndPattern '^---\s*$'

    if ($null -eq $result.Content -or $null -eq $result.DestinationContent) {
        Write-ProjectLog "Failed to move pilot $ImprovementId to Completed section (archive)" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Removed $ImprovementId from Active Pilots"
    Write-ProjectLog "Added $ImprovementId to archive § Section 6 — Completed (Resolved From: Active Pilot)" -Level "SUCCESS"
    return @{ Content = $result.Content; ArchiveContent = $result.DestinationContent }
}

# --- Content-transformation functions ---
# Each takes a $Content string and returns modified $Content string.
# This enables a single read-modify-write cycle in Main.

function Test-IsInCompletedSection {
    # Archive-split (2026-05-13): §6 lives in $ArchiveContent; legacy single-file
    # callers (pre-split) still pass -Content alone — we fall back to scanning it
    # so a stale call site doesn't silently miss the section it's looking for.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId
    )
    $scanIn = if ($ArchiveContent) { $ArchiveContent } else { $Content }
    $rows = ConvertFrom-MarkdownTable -Content $scanIn -Section "## Section 6 — Completed"
    return [bool]($rows | Where-Object { $_.ID -eq $ImprovementId })
}

function Update-StatusInPlace {
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId,
        [string]$NewStatus
    )

    # PF-IMP-856 part B: locate the IMP across triaged sections instead of hardcoding §2.
    # All three open triaged sections (Improvements / Extensions / Structural Changes) share
    # the same 10-col schema; only the section heading differs. Mirrors the pattern
    # Update-AnnotationInPlace already uses and complements the Completion path's
    # Move-ToCompletedSection -SourceLocation coverage of the same three sections.
    $sectionShortName = Get-IMPCurrentSection -Content $Content -ArchiveContent $ArchiveContent -ImprovementId $ImprovementId

    if ($sectionShortName -notin @("Improvements", "Extensions", "StructuralChanges")) {
        switch ($sectionShortName) {
            { $_ -in @("Completed", "Rejected") } {
                Write-ProjectLog "Improvement $ImprovementId is already in the $sectionShortName section (archive). To reopen, manually move the row from the archive file back to a live triaged section first." -Level "ERROR"
            }
            "Intake"       { Write-ProjectLog "Improvement $ImprovementId is in the Intake section. Triage it first via -MoveToSection before applying status updates." -Level "ERROR" }
            "ActivePilots" { Write-ProjectLog "Improvement $ImprovementId is in the Active Pilots section. Use the pilot statuses (-NewStatus Active|Resolved) instead." -Level "ERROR" }
            "NotFound"     { Write-ProjectLog "Improvement entry not found in any section: $ImprovementId" -Level "ERROR" }
            default        { Write-ProjectLog "Improvement $ImprovementId is in section '$sectionShortName'; in-place status flips apply only to Improvements / Extensions / Structural Changes." -Level "ERROR" }
        }
        return $null
    }

    $sectionHeading = $script:CentralSectionHeadings[$sectionShortName]
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section $sectionHeading -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1

    if (-not $row) {
        Write-ProjectLog "Improvement entry not found in $sectionHeading (post-detect re-read failed): $ImprovementId" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    Write-ProjectLog "Found improvement entry for $ImprovementId in section: $sectionShortName"

    # Phase 7 (Session 11, 2026-05-11): all three triaged sections share the 10-col schema.
    # Parse columns: | ID | Source | Description | Project | Framework Version | Priority | Status | Resp Task | Last Updated | Notes |
    # Indices:        0    1        2             3         4                   5          6        7           8              9
    $columns = Split-MarkdownTableRow $currentEntry
    if ($null -eq $columns -or $columns.Count -ne 10) {
        $actualCount = if ($null -eq $columns) { 0 } else { $columns.Count }
        Write-ProjectLog "Malformed table row for $ImprovementId`: expected 10 columns (Phase 7 central schema), found $actualCount. $script:MalformedRowEscapeHint" -Level "ERROR"
        Write-ProjectLog "Cells as parsed:`n$(Get-MalformedRowDiagnostic -Columns $columns -ExpectedCount 10)" -Level "ERROR"
        Write-ProjectLog "Raw row: $currentEntry" -Level "ERROR"
        return $null
    }

    # Update Status (idx 6) and Last Updated (idx 8)
    $displayName = $StatusDisplayNames[$NewStatus]
    $columns[6] = $displayName
    $columns[8] = $CurrentDate

    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-ProjectLog "Updated $ImprovementId status to: $displayName (section: $sectionShortName)" -Level "SUCCESS"
    return $result
}

function Update-AnnotationInPlace {
    # PF-IMP-832 (a): edits Notes column (idempotent append) and/or Resp Task column on a row
    # in one of the 10-col triaged sections (Improvements / Extensions / Structural Changes).
    # PF-IMP-1007 extends this with -EditDescription / -EditNotes (idempotent REPLACE of the
    # Description / Notes columns).
    # Returns @{ Content = <modified content of the row's own file>; IsArchive = <bool> } —
    # Content is the original unchanged when every requested edit was a no-op per idempotency;
    # $null is returned on failure. Last Updated is bumped only when at least one column
    # actually changed, and only in sections that carry the column.
    # PF-IMP-1719: with -AllowArchive, a row already relocated to Section 6 — Completed or
    # Section 7 — Rejected is annotated in $ArchiveContent instead; IsArchive tells the caller
    # which file to write back.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId,
        [string]$AppendNotes,
        [string]$SetRespTask,
        [string]$SetPriority,
        [string]$EditDescription,
        [string]$EditNotes,
        [switch]$AllowArchive
    )

    $sectionShortName = Get-IMPCurrentSection -Content $Content -ArchiveContent $ArchiveContent -ImprovementId $ImprovementId
    $schema = $script:AnnotationSchemas[$sectionShortName]
    if ($null -eq $schema) {
        Write-ProjectLog "Annotation target $ImprovementId was not found in any of the seven canonical sections (searched: $sectionShortName)" -Level "ERROR"
        return $null
    }

    # PF-IMP-1719: annotating an archived row is annotation-only work. The status-transition
    # caller does not pass -AllowArchive, so a terminal row keeps refusing there exactly as
    # before — a transition on an already-archived row is its own error, not an annotation.
    if ($schema.Archive -and -not $AllowArchive) {
        Write-ProjectLog "$ImprovementId is in the archive ($sectionShortName). Annotating an archived row is supported in annotation-only mode — re-run with -AppendNotes and no -NewStatus." -Level "ERROR"
        return $null
    }

    # PF-IMP-1570 (C1): -AppendNotes now covers the 7-col sections (Intake, Active Pilots)
    # in annotation-only mode — previously refused outright, forcing hand-edits
    # (precedents: PF-IMP-1390 stale cross-reference, PF-IMP-1373 pilot trial evidence).
    # PF-IMP-1719 extends the same widening to the archive sections (Completed / Rejected),
    # the last tracking-file mutation that had no script path (precedent: the PF-IMP-1527
    # dead-premise marker and the PF-IMP-1605 change-ID correction, both hand-edited).
    # The other annotation params address columns those sections do not carry.
    if ($schema.ColumnCount -ne 10) {
        $unsupported = @()
        if ($SetRespTask)     { $unsupported += "-SetRespTask (no Resp Task column in $sectionShortName)" }
        if ($SetPriority)     { $unsupported += "-SetPriority (no Priority column in $sectionShortName)" }
        if ($EditDescription) { $unsupported += "-EditDescription (triaged sections only)" }
        if ($EditNotes)       { $unsupported += "-EditNotes (triaged sections only)" }
        if ($unsupported.Count -gt 0) {
            $remedy = if ($schema.Archive) {
                "An archived row takes -AppendNotes only; its other columns are the terminal record."
            } else {
                "Move the row to a triaged section first (-MoveToSection) if you need the others."
            }
            Write-ProjectLog "Unsupported annotation for $ImprovementId in $sectionShortName`: $($unsupported -join '; '). Only -AppendNotes applies to Intake / Active Pilots / archived rows. $remedy" -Level "ERROR"
            return $null
        }
    }

    # PF-IMP-1719: archived rows live in the sibling archive file, so every read, edit and
    # write below runs against $ArchiveContent instead of $Content.
    $targetContent = if ($schema.Archive) { $ArchiveContent } else { $Content }

    $sectionHeading = $script:CentralSectionHeadings[$sectionShortName]
    $rows = ConvertFrom-MarkdownTable -Content $targetContent -Section $sectionHeading -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) {
        Write-ProjectLog "Annotation: $ImprovementId not found in section $sectionShortName (re-read failed)" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    $columns = Split-MarkdownTableRow $currentEntry
    if ($null -eq $columns -or $columns.Count -ne $schema.ColumnCount) {
        $actualCount = if ($null -eq $columns) { 0 } else { $columns.Count }
        Write-ProjectLog "Malformed table row for $ImprovementId in $sectionShortName`: expected $($schema.ColumnCount) columns, found $actualCount. $script:MalformedRowEscapeHint" -Level "ERROR"
        Write-ProjectLog "Cells as parsed:`n$(Get-MalformedRowDiagnostic -Columns $columns -ExpectedCount $schema.ColumnCount)" -Level "ERROR"
        return $null
    }

    $changed = $false

    # -AppendNotes: idempotent append to Notes. "Already present" = literal substring match.
    # Notes index is section-dependent (idx 9 triaged, idx 6 Intake/Active Pilots) — PF-IMP-1570 (C1).
    if ($AppendNotes) {
        $notesIdx = $schema.Notes
        $existingNotes = $columns[$notesIdx].Trim()
        $isEmpty = (-not $existingNotes) -or ($existingNotes -eq "") -or ($existingNotes -eq "—")
        if ((-not $isEmpty) -and $existingNotes.Contains($AppendNotes)) {
            Write-ProjectLog "AppendNotes: text already present in Notes for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[$notesIdx] = if ($isEmpty) { $AppendNotes } else { "$existingNotes $AppendNotes" }
            $changed = $true
            Write-ProjectLog "Appended to Notes for $ImprovementId (section: $sectionShortName)" -Level "SUCCESS"
        }
    }

    # -SetRespTask: replace Resp Task (idx 7). Skip if already equal.
    # Guarded above: unreachable for sections without a Resp Task column.
    if ($SetRespTask) {
        $currentRespTask = $columns[7].Trim()
        if ($currentRespTask -eq $SetRespTask) {
            Write-ProjectLog "SetRespTask: Resp Task is already $SetRespTask for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[7] = $SetRespTask
            $changed = $true
            Write-ProjectLog "Set Resp Task to $SetRespTask for $ImprovementId (was: $currentRespTask)" -Level "SUCCESS"
        }
    }

    # PF-IMP-1885 -SetPriority: replace Priority (idx 5). Skip if already equal.
    # Guarded above: unreachable for sections without a Priority column.
    if ($SetPriority) {
        $currentPriority = $columns[5].Trim()
        if ($currentPriority -eq $SetPriority) {
            Write-ProjectLog "SetPriority: Priority is already $SetPriority for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[5] = $SetPriority
            $changed = $true
            Write-ProjectLog "Set Priority to $SetPriority for $ImprovementId (was: $currentPriority)" -Level "SUCCESS"
        }
    }

    # PF-IMP-1007 -EditDescription: replace Description (idx 2). Skip if already equal.
    if ($EditDescription) {
        if ($columns[2].Trim() -eq $EditDescription) {
            Write-ProjectLog "EditDescription: Description already equals the supplied value for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[2] = $EditDescription
            $changed = $true
            Write-ProjectLog "Replaced Description for $ImprovementId" -Level "SUCCESS"
        }
    }

    # PF-IMP-1007 -EditNotes: replace Notes (idx 9). Skip if already equal.
    if ($EditNotes) {
        if ($columns[9].Trim() -eq $EditNotes) {
            Write-ProjectLog "EditNotes: Notes already equals the supplied value for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[9] = $EditNotes
            $changed = $true
            Write-ProjectLog "Replaced Notes for $ImprovementId" -Level "SUCCESS"
        }
    }

    if (-not $changed) {
        # All annotation operations were idempotent no-ops; return unchanged content.
        return @{ Content = $targetContent; IsArchive = [bool]$schema.Archive }
    }

    # Bump Last Updated since at least one column changed. Index is section-dependent
    # (idx 8 triaged, idx 5 Intake); Active Pilots has no Last Updated column — PF-IMP-1570 (C1).
    # The archive sections likewise have none: their Resolution / Rejection Date records when
    # the row terminated, which a later annotation must not overwrite (PF-IMP-1719).
    if ($null -ne $schema.LastUpdated) {
        $columns[$schema.LastUpdated] = $CurrentDate
    }

    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $targetContent.Replace($currentEntry, $updatedEntry)
    return @{ Content = $result; IsArchive = [bool]$schema.Archive }
}

function Move-ToCompletedSection {
    # Phase 7 cross-schema translation (Session 11, 2026-05-11):
    # Transforms 10-column Improvements/Extensions/Structural-Changes schema into 8-column Completed schema.
    # Source: | ID | Source | Description | Project | Framework Version | Priority | Status | Resp Task | Last Updated | Notes |
    # Dest:   | ID | Description | Project | Framework Version | Resolution Date | Implementing Task | Resolved From | Notes |
    # SourceLocation extends the original Section-2-only behavior to cover Sections 3 (Extensions)
    # and 4 (Structural Changes) — both share the 10-col schema and only the "Resolved From"
    # label differs. Side observation surfaced in PF-IMP-760 notes; quick-fixed during IMP-771 closure.
    #
    # Archive-split (2026-05-13): destination row goes into $ArchiveContent
    # (sibling archive file). Returns @{ Content; ArchiveContent } on success,
    # $null on failure. Source-only removal applies to $Content.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId,
        [string]$Impact,
        [string]$ValidationNotes,
        [string]$ImplementingTask,  # Optional override; otherwise sourced from the row's Resp Task column
        [ValidateSet("Current", "Extensions", "StructuralChanges")]
        [string]$SourceLocation = "Current"
    )

    $sourceMap = @{
        "Current"           = @{ Heading = "## Section 2 — Improvements";        ResolvedFrom = "Improvement" }
        "Extensions"        = @{ Heading = "## Section 3 — Extensions";          ResolvedFrom = "Extension" }
        "StructuralChanges" = @{ Heading = "## Section 4 — Structural Changes";  ResolvedFrom = "Structural Change" }
    }
    $sourceHeading = $sourceMap[$SourceLocation].Heading
    $resolvedFromLabel = $sourceMap[$SourceLocation].ResolvedFrom

    # Read source row to access Notes + Resp Task for synthesis. Move-MarkdownTableRow
    # also reads the row, but doing it here lets us synthesize before calling.
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section $sourceHeading
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) {
        if (Test-IsInCompletedSection -Content $Content -ArchiveContent $ArchiveContent -ImprovementId $ImprovementId) {
            Write-ProjectLog "Improvement $ImprovementId is already in the Completed section (archive). The completion transition has already been applied — no action needed." -Level "ERROR"
        } else {
            Write-ProjectLog "Improvement $ImprovementId not found in $sourceHeading" -Level "ERROR"
        }
        return $null
    }

    # PF-IMP-1740 (c): completing a row whose Status never went In Progress (no claim
    # recorded) is legitimate but must be visible for parallel-session forensics. WARN, not
    # the source form's suggested INFO — this script logs default-quiet via Write-ProjectLog,
    # so an INFO would never surface in normal use (PF-FEE-1665).
    if ($row.Status -and $row.Status -ne "In Progress") {
        Write-ProjectLog "Completing $ImprovementId whose current Status is '$($row.Status)', not 'In Progress' — no claim recorded on this row. The transition proceeds; check for an unclaimed or parallel-session flow if this is unexpected." -Level "WARN"
    }

    # Resolve Implementing Task: explicit parameter wins; otherwise source row's Resp Task.
    if (-not $ImplementingTask) {
        $ImplementingTask = if ($row.'Resp Task') { $row.'Resp Task' } else { '' }
    }

    # Synthesize Notes column: fold Impact + ValidationNotes + existing Notes since the new
    # 8-col Completed schema has no separate columns for impact / validation narrative.
    $existingNotes = $row.Notes
    $parts = @()
    if ($Impact) { $parts += "Impact: $Impact." }
    if ($ValidationNotes) { $parts += "Validation: $ValidationNotes" }
    if ($existingNotes) { $parts += $existingNotes }
    $synthesizedNotes = $parts -join ' '

    # All 8 destination columns listed in ColumnMapping to control output order.
    # Source-mapped: ID, Description, Project, Framework Version. Synthesized: Resolution
    # Date, Implementing Task, Resolved From, Notes — AdditionalColumns wins.
    $columnMapping = [ordered]@{
        "ID"                = "ID"
        "Description"       = "Description"
        "Project"           = "Project"
        "Framework Version" = "Framework Version"
        "Resolution Date"   = "_synthesized_"
        "Implementing Task" = "_synthesized_"
        "Resolved From"     = "_synthesized_"
        "Notes"             = "_synthesized_"
    }
    $additionalColumns = [ordered]@{
        "Resolution Date"   = $CurrentDate
        "Implementing Task" = $ImplementingTask
        "Resolved From"     = $resolvedFromLabel
        "Notes"             = $synthesizedNotes
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -DestinationContent $ArchiveContent `
        -RowIdPattern ([regex]::Escape($ImprovementId)) `
        -SourceSection $sourceHeading `
        -DestinationSection "## Section 6 — Completed" `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns `
        -SectionEndPattern '^---\s*$'

    if ($null -eq $result.Content -or $null -eq $result.DestinationContent) {
        Write-ProjectLog "Failed to move $ImprovementId to Completed section (archive)" -Level "ERROR"
        if ($result.SourceRow) {
            Write-ProjectLog "Source row found but insertion failed. Check archive § Section 6 — Completed exists." -Level "ERROR"
        }
        return $null
    }

    Write-ProjectLog "Removed $ImprovementId from $sourceHeading"
    Write-ProjectLog "Added $ImprovementId to archive § Section 6 — Completed (Resolved From: $resolvedFromLabel)" -Level "SUCCESS"
    return @{ Content = $result.Content; ArchiveContent = $result.DestinationContent }
}

function Move-ToRejectedAsSuperseded {
    # PF-IMP-832 (c): moves a non-pilot IMP from Intake or any 10-col triaged section
    # (Improvements, Extensions, Structural Changes) to Section 7 — Rejected with
    # Rejection Reason = "Superseded by <SupersededBy>". Optional ValidationNotes is
    # folded into the destination Notes column ahead of the existing Notes content.
    #
    # Mirrors the Rejected schema produced by SectionMove's Rejected path, but driven by
    # status semantic rather than triage action — so no [REROUTED ...] audit-trail prefix
    # is added (that prefix is reserved for re-routes between triaged sections).
    #
    # Why Section 7 and not Section 6: per PF-IMP-803 rationale, conflating "implemented"
    # (Completed) and "superseded by another IMP" pollutes trend analysis on completed
    # IMPs. Section 7 Rejected is the canonical "did not implement" home; Rejection Reason
    # carries the supersession marker for grepability.
    #
    # Intake-source supported: Triage occasionally consolidates several Intake rows into a
    # newer IMP without first moving the source rows out of Intake. Allowing Intake as a
    # source lets the cluster owner mark the consolidated rows Superseded in one call.
    #
    # Archive-split (2026-05-13): destination row goes into $ArchiveContent
    # (sibling archive file § Section 7). Returns @{ Content; ArchiveContent }
    # on success, $null on failure.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId,
        [string]$SupersededBy,
        [string]$ValidationNotes
    )

    $sourceShortName = Get-IMPCurrentSection -Content $Content -ArchiveContent $ArchiveContent -ImprovementId $ImprovementId
    if ($sourceShortName -notin @("Intake", "Improvements", "Extensions", "StructuralChanges")) {
        Write-ProjectLog "Superseded status only applies to IMPs in Intake / Improvements / Extensions / Structural Changes. $ImprovementId is in: $sourceShortName" -Level "ERROR"
        return $null
    }

    $sourceHeading = $script:CentralSectionHeadings[$sourceShortName]
    $sourceRows = ConvertFrom-MarkdownTable -Content $Content -Section $sourceHeading
    $existingRow = $sourceRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $existingRow) {
        Write-ProjectLog "Superseded: $ImprovementId not found in section '$sourceShortName' (re-read failed)" -Level "ERROR"
        return $null
    }

    $existingNotes = if ($existingRow.PSObject.Properties.Name -contains "Notes") { $existingRow.Notes } else { "" }
    $existingNotesTrim = if ($existingNotes) { $existingNotes.Trim() } else { "" }
    $isEmpty = (-not $existingNotesTrim) -or ($existingNotesTrim -eq "—")

    $newNotes = if ($ValidationNotes) {
        if ($isEmpty) { $ValidationNotes } else { "$ValidationNotes — $existingNotesTrim" }
    } else {
        $existingNotes
    }

    $rejectionReason = "Superseded by $SupersededBy"

    # Rejected schema: ID | Description | Project | Framework Version | Rejection Date | Rejection Reason | Notes
    $columnMapping = [ordered]@{
        "ID"                = "ID"
        "Description"       = "Description"
        "Project"           = "Project"
        "Framework Version" = "Framework Version"
        "Rejection Date"    = ""
        "Rejection Reason"  = ""
        "Notes"             = "Notes"
    }
    $additionalColumns = [ordered]@{
        "Rejection Date"   = $CurrentDate
        "Rejection Reason" = $rejectionReason
        "Notes"            = $newNotes
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -DestinationContent $ArchiveContent `
        -RowIdPattern ([regex]::Escape($ImprovementId)) `
        -SourceSection $sourceHeading `
        -DestinationSection $script:CentralSectionHeadings["Rejected"] `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns `
        -SectionEndPattern '^---\s*$'

    if ($null -eq $result.Content -or $null -eq $result.DestinationContent) {
        Write-ProjectLog "Failed to move $ImprovementId to archive § Section 7 — Rejected (Superseded)" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Moved $ImprovementId from '$sourceShortName' to archive § Section 7 — Rejected (Superseded by $SupersededBy)" -Level "SUCCESS"
    return @{ Content = $result.Content; ArchiveContent = $result.DestinationContent }
}

function Move-ToRejected {
    # PF-IMP-852: moves a non-pilot IMP from Intake or any 10-col triaged section
    # (Improvements, Extensions, Structural Changes) to Section 7 — Rejected with
    # Rejection Reason = the caller-supplied rationale (-ValidationNotes from the
    # status-update entry point). The source row's Notes column is preserved
    # unchanged in the destination row.
    #
    # Sibling to Move-ToRejectedAsSuperseded: same destination section, same schema
    # transformation, but the Rejection Reason is the caller's rationale rather than
    # a synthesized "Superseded by X" string, and the existing Notes are preserved
    # verbatim rather than folded with ValidationNotes. This split keeps trend
    # analysis clean — Section 7's Rejection Reason column carries semantic
    # disposition while Notes preserves cluster/context history.
    #
    # Why Section 7 and not Section 6: per PF-IMP-803 rationale (extended to
    # outright rejection by PF-IMP-852), conflating "implemented" (Section 6 —
    # Completed) and "decided not to implement" (Section 7 — Rejected) pollutes
    # trend analysis on the Completed section.
    #
    # Archive-split (2026-05-13): destination row goes into $ArchiveContent
    # (sibling archive file § Section 7). Returns @{ Content; ArchiveContent }
    # on success, $null on failure.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId,
        [string]$RejectionReason
    )

    $sourceShortName = Get-IMPCurrentSection -Content $Content -ArchiveContent $ArchiveContent -ImprovementId $ImprovementId
    if ($sourceShortName -notin @("Intake", "Improvements", "Extensions", "StructuralChanges")) {
        Write-ProjectLog "Rejected status only applies to IMPs in Intake / Improvements / Extensions / Structural Changes. $ImprovementId is in: $sourceShortName" -Level "ERROR"
        return $null
    }

    $sourceHeading = $script:CentralSectionHeadings[$sourceShortName]
    $sourceRows = ConvertFrom-MarkdownTable -Content $Content -Section $sourceHeading
    $existingRow = $sourceRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $existingRow) {
        Write-ProjectLog "Rejected: $ImprovementId not found in section '$sourceShortName' (re-read failed)" -Level "ERROR"
        return $null
    }

    $existingNotes = if ($existingRow.PSObject.Properties.Name -contains "Notes") { $existingRow.Notes } else { "" }

    # Rejected schema: ID | Description | Project | Framework Version | Rejection Date | Rejection Reason | Notes
    $columnMapping = [ordered]@{
        "ID"                = "ID"
        "Description"       = "Description"
        "Project"           = "Project"
        "Framework Version" = "Framework Version"
        "Rejection Date"    = ""
        "Rejection Reason"  = ""
        "Notes"             = "Notes"
    }
    $additionalColumns = [ordered]@{
        "Rejection Date"   = $CurrentDate
        "Rejection Reason" = $RejectionReason
        "Notes"            = $existingNotes
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -DestinationContent $ArchiveContent `
        -RowIdPattern ([regex]::Escape($ImprovementId)) `
        -SourceSection $sourceHeading `
        -DestinationSection $script:CentralSectionHeadings["Rejected"] `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns `
        -SectionEndPattern '^---\s*$'

    if ($null -eq $result.Content -or $null -eq $result.DestinationContent) {
        Write-ProjectLog "Failed to move $ImprovementId to archive § Section 7 — Rejected" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Moved $ImprovementId from '$sourceShortName' to archive § Section 7 — Rejected" -Level "SUCCESS"
    return @{ Content = $result.Content; ArchiveContent = $result.DestinationContent }
}

function Update-SummaryCount {
    # Archive-split (2026-05-13): §6 lives in $ArchiveContent. Count rows there;
    # the `<summary>` tag (if present in either file) is updated in-place. The
    # pre-split callers passed only $Content — we still accept that and fall
    # back to scanning it.
    param(
        [string]$Content,
        [string]$ArchiveContent
    )

    $scanIn = if ($ArchiveContent) { $ArchiveContent } else { $Content }

    # Count IMP- rows in the Completed section. Heading accepts the central form
    # "## Section 6 — Completed" (post-Phase-7) and the legacy "## Completed Improvements".
    $count = 0
    $inCompletedSection = $false
    foreach ($line in ($scanIn -split "\r?\n")) {
        if ($line -match '^##\s+(Section\s+6\s+[—–-]\s+)?Completed') { $inCompletedSection = $true; continue }
        if ($inCompletedSection -and $line -match "^\s*</details>") { break }
        if ($inCompletedSection -and $line -match "^##\s") { break }
        if ($inCompletedSection -and $line -match "^\|\s*(PF-)?IMP-\d+") { $count++ }
    }

    # Update the <summary> tag where it exists. The current archive-split
    # layout has no `<summary>` block — this is a no-op preserved for backwards
    # compatibility with any future / legacy file that still uses it.
    $newContent = $Content -replace '(?<=Show completed improvements \()\d+(?= items?\))', $count.ToString()
    $newArchive = $ArchiveContent -replace '(?<=Show completed improvements \()\d+(?= items?\))', $count.ToString()

    Write-ProjectLog "Counted $count items in Completed section" -Level "SUCCESS"
    return @{ Content = $newContent; ArchiveContent = $newArchive }
}

function Invoke-LogToolChanges {
    # PF-IMP-832 (b): invokes `python feedback_db.py log-change --batch -` with the supplied
    # JSON piped to stdin. Resolves feedback_db.py relative to this script's location:
    # scripts/update/Update-ProcessImprovement.ps1 → ../feedback_db.py. Same relative layout
    # in appdev (blueprint/process-framework/scripts/) and in rolled-out projects
    # (process-framework/scripts/).
    # Returns $true on success, $false on failure. Caller treats failure as a non-fatal WARN.
    # PF-IMP-1393 (b): -ValidateOnly runs the same feedback_db checks (JSON shape +
    # unknown-tool block) via log-change --validate-only, writing nothing — used before
    # the terminal move so a bad tool_doc_id aborts cleanly instead of needing a
    # post-archive backfill. On validate failure the python stderr explains; the caller
    # escalates to ERROR.
    param([string]$JsonPayload, [switch]$ValidateOnly)

    $feedbackDb = Join-Path $PSScriptRoot ".." "feedback_db.py"
    try {
        $feedbackDb = (Resolve-Path -Path $feedbackDb -ErrorAction Stop).Path
    } catch {
        Write-ProjectLog "Could not resolve feedback_db.py at expected location ($feedbackDb): $($_.Exception.Message)" -Level "WARN"
        return $false
    }

    $pyArgs = @("log-change", "--batch", "-")
    if ($ValidateOnly) { $pyArgs += "--validate-only" }
    $mode = if ($ValidateOnly) { " (validate-only)" } else { "" }
    Write-ProjectLog "Invoking feedback_db.py log-change --batch$mode with supplied JSON payload"
    # Pipe JSON to python stdin. PowerShell forwards $JsonPayload as text to the process.
    $JsonPayload | & python $feedbackDb @pyArgs
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
        if (-not $ValidateOnly) {
            Write-ProjectLog "feedback_db.py log-change exited with code $exit. IMP move was preserved; re-run log-change manually with the same JSON to backfill the entry." -Level "WARN"
        }
        return $false
    }

    Write-ProjectLog "feedback_db.py log-change$mode succeeded" -Level "SUCCESS"
    return $true
}

function Test-ImpHasLoggedChanges {
    # PF-IMP-1740 (b): returns $true when feedback_db holds at least one change row for the
    # IMP, $false when it holds none, $null when the query is unavailable (python or
    # feedback_db.py missing, or the query failed) — the caller treats $null as "don't know"
    # and stays silent. Zero rows is detected textually via list-changes' no-match line
    # ("No logged changes match ..."), the stable zero-rows signal (the subcommand exits 0
    # either way); feedback_db.py's cmd_list_changes carries a comment noting this dependency.
    param([string]$ImprovementId)

    $feedbackDb = Join-Path $PSScriptRoot ".." "feedback_db.py"
    try {
        $feedbackDb = (Resolve-Path -Path $feedbackDb -ErrorAction Stop).Path
    } catch {
        return $null
    }
    try {
        $output = & python $feedbackDb list-changes --imp $ImprovementId 2>&1
    } catch {
        return $null
    }
    if ($LASTEXITCODE -ne 0) { return $null }
    if (($output | Out-String) -match 'No logged changes match') { return $false }
    return $true
}

# --- SectionMove helpers (PF-TSK-089 IMP Triage; PF-PRO-029 Phase 4) ---

# Mapping: short-name parameter value → full section heading text in the central file.
# These match the canonical 7-section structure created in PF-PRO-029 Phase 2
# (process-framework-central/state-tracking/permanent/process-improvement-tracking.md).
$script:CentralSectionHeadings = @{
    "Intake"             = "## Section 1 — Intake"
    "Improvements"       = "## Section 2 — Improvements"
    "Extensions"         = "## Section 3 — Extensions"
    "StructuralChanges"  = "## Section 4 — Structural Changes"
    "ActivePilots"       = "## Section 5 — Active Pilots"
    "Completed"          = "## Section 6 — Completed"
    "Rejected"           = "## Section 7 — Rejected"
}

# PF-IMP-1570 (C1): per-section column geometry for in-place annotation.
# The live sections carry two different schemas:
#   10-col triaged: | ID | Source | Description | Project | Framework Version | Priority | Status | Resp Task | Last Updated | Notes |
#    7-col Intake:  | ID | Source | Description | Project | Framework Version | Last Updated | Notes |
#    7-col Pilots:  | ID | Concept | Pilot Description | Project | Framework Version | Status | Notes |
# PF-IMP-1719 adds the two archive sections, which live in $ArchiveFile:
#    8-col Completed: | ID | Description | Project | Framework Version | Resolution Date | Implementing Task | Resolved From | Notes |
#    7-col Rejected:  | ID | Description | Project | Framework Version | Rejection Date | Rejection Reason | Notes |
# LastUpdated = $null means the section has no such column (Active Pilots; both archive
# sections, whose dates record when the row terminated and must not be bumped) — skip the bump.
# RespTask = $null means the section has no Resp Task column, so -SetRespTask cannot apply there.
# Archive = $true means the row lives in $ArchiveFile rather than $TrackingFile.
$script:AnnotationSchemas = [ordered]@{
    "Improvements"      = @{ ColumnCount = 10; Notes = 9; LastUpdated = 8;    RespTask = 7;     Archive = $false }
    "Extensions"        = @{ ColumnCount = 10; Notes = 9; LastUpdated = 8;    RespTask = 7;     Archive = $false }
    "StructuralChanges" = @{ ColumnCount = 10; Notes = 9; LastUpdated = 8;    RespTask = 7;     Archive = $false }
    "Intake"            = @{ ColumnCount = 7;  Notes = 6; LastUpdated = 5;    RespTask = $null; Archive = $false }
    "ActivePilots"      = @{ ColumnCount = 7;  Notes = 6; LastUpdated = $null; RespTask = $null; Archive = $false }
    "Completed"         = @{ ColumnCount = 8;  Notes = 7; LastUpdated = $null; RespTask = $null; Archive = $true }
    "Rejected"          = @{ ColumnCount = 7;  Notes = 6; LastUpdated = $null; RespTask = $null; Archive = $true }
}

# Annotation parameters that require a 10-col triaged section (they address columns
# that Intake / Active Pilots do not have, or whose semantics are triage-only).
$script:TriagedOnlyAnnotationParams = @("SetRespTask", "SetPriority", "EditDescription", "EditNotes")

function Get-MalformedRowDiagnostic {
    # PF-IMP-1570 (C3): a column-count failure means an unescaped pipe split one cell in two —
    # which shifts every later cell by one, so no single cell is identifiable as "the" divergent
    # one. Emit the indexed cell list with truncated snippets instead, so the split is locatable
    # by eye without external tooling (the malformed rows come from hand-appends; script-mode
    # appends escape correctly).
    param(
        [string[]]$Columns,
        [int]$ExpectedCount,
        [int]$SnippetLength = 40
    )
    if ($null -eq $Columns -or $Columns.Count -eq 0) { return "  (row did not parse into any cells)" }
    $lines = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $cell = "$($Columns[$i])".Trim()
        $snippet = if ($cell.Length -gt $SnippetLength) { $cell.Substring(0, $SnippetLength) + "…" } else { $cell }
        $marker = if ($i -ge $ExpectedCount) { "   <-- beyond the expected $ExpectedCount columns" } else { "" }
        $lines.Add(("  [{0}] {1}{2}" -f $i, $snippet, $marker))
    }
    return ($lines -join "`n")
}

# PF-IMP-1570 (C3): shared remediation guidance for every column-count failure site.
$script:MalformedRowEscapeHint = "Check for unescaped pipe characters in cell content. Escape literal pipes as '\|' (preferred — markdown table escape, supported by Split-MarkdownTableRow per PF-IMP-603) or '&#124;' (HTML-entity fallback)."

function Test-IsCentralTrackingFile {
    # Validates the file has the canonical 7-section structure. Returns $true if
    # the Intake heading is present, $false otherwise. Guards against running
    # SectionMove operations against the legacy 3-section project-local file.
    param([string]$Content)
    return ($Content -match '(?m)^## Section 1 — Intake\s*$')
}

function Get-IMPCurrentSection {
    # Scans the seven canonical sections for the IMP. Returns the short-name
    # ("Intake" / "Improvements" / etc.) of the section that contains the row,
    # or "NotFound" if not present.
    # Archive-split (2026-05-13): §1-§5 live in $Content; §6/§7 live in
    # $ArchiveContent. When $ArchiveContent is empty (single-file callers from
    # before the split), §6/§7 are scanned in $Content as a fallback.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId
    )
    foreach ($shortName in @("Intake", "Improvements", "Extensions", "StructuralChanges", "ActivePilots")) {
        $heading = $script:CentralSectionHeadings[$shortName]
        $rows = ConvertFrom-MarkdownTable -Content $Content -Section $heading
        if ($rows | Where-Object { $_.ID -eq $ImprovementId }) {
            return $shortName
        }
    }
    $archiveScan = if ($ArchiveContent) { $ArchiveContent } else { $Content }
    foreach ($shortName in @("Completed", "Rejected")) {
        $heading = $script:CentralSectionHeadings[$shortName]
        $rows = ConvertFrom-MarkdownTable -Content $archiveScan -Section $heading
        if ($rows | Where-Object { $_.ID -eq $ImprovementId }) {
            return $shortName
        }
    }
    return "NotFound"
}

function Get-NotesWithReroutePrefix {
    # When a re-route is in progress (source != Intake), prepend the audit-trail tag
    # to the existing Notes value: "[REROUTED YYYY-MM-DD by PF-TSK-NNN: <reason>]"
    # Initial sort from Intake produces no prefix (caller passes -SourceSection "Intake").
    param(
        [string]$ExistingNotes,
        [string]$SourceSection,
        [string]$RoutedBy,
        [string]$Reason
    )
    if ($SourceSection -eq "Intake") {
        return $ExistingNotes  # initial sort, no prefix
    }
    if (-not $RoutedBy) {
        # Defensive: should never trigger now that -RoutedBy auto-defaults from
        # source section in Main, but keep as a safety net for future callers.
        Write-ProjectLog "Re-route from $SourceSection has no -RoutedBy and no source-section default — skipping audit-trail prefix" -Level "WARN"
        return $ExistingNotes
    }
    # Reason is informational. If missing, still record the re-route (audit-trail
    # integrity matters more than narrative); mark the gap with a greppable marker.
    if (-not $Reason) {
        Write-ProjectLog "Re-route from $SourceSection has no -Reason; recording prefix with '<no reason supplied>' marker (audit-trail preservation)" -Level "WARN"
        $reasonText = "<no reason supplied>"
    } else {
        $reasonText = $Reason
    }
    $prefix = "[REROUTED $CurrentDate by ${RoutedBy}: $reasonText]"
    if ($ExistingNotes -and $ExistingNotes.Trim() -ne "" -and $ExistingNotes.Trim() -ne "—") {
        return "$prefix $($ExistingNotes.Trim())"
    }
    return $prefix
}

function Build-ColumnMappingForMove {
    # Returns a hashtable with two ordered dictionaries: ColumnMapping (source→dest
    # column name lookups) and AdditionalColumns (literal values for new columns
    # that don't exist in the source schema). Per-source-per-destination pairing
    # captures the column-schema differences across the 7 sections.
    #
    # Column schemas (per central tracking file):
    #   Intake (7):              ID | Source | Description | Project | Framework Version | Last Updated | Notes
    #   Improvements (10):       ID | Source | Description | Project | Framework Version | Priority | Status | Resp Task | Last Updated | Notes
    #   Extensions (10):         (same as Improvements)
    #   Structural Changes (10): (same as Improvements)
    #   Rejected (7):            ID | Description | Project | Framework Version | Rejection Date | Rejection Reason | Notes
    param(
        [string]$SourceShortName,
        [string]$DestShortName,
        [string]$Priority,
        [string]$Status,
        [string]$RespTask,
        [string]$RejectionReason,
        [string]$NewNotes  # already includes [REROUTED ...] prefix if applicable
    )

    $mapping = [ordered]@{}
    $additional = [ordered]@{}

    if ($DestShortName -in @("Improvements", "Extensions", "StructuralChanges")) {
        # Triaged sections all share the 10-column schema.
        $mapping["ID"]                = "ID"
        $mapping["Source"]            = "Source"
        $mapping["Description"]       = "Description"
        $mapping["Project"]           = "Project"
        $mapping["Framework Version"] = "Framework Version"
        $mapping["Priority"]          = "Priority"
        $mapping["Status"]            = "Status"
        $mapping["Resp Task"]         = "Resp Task"
        $mapping["Last Updated"]      = "Last Updated"
        $mapping["Notes"]             = "Notes"

        # AdditionalColumns: literal values for new/changed columns. These take
        # precedence over the mapping (Move-MarkdownTableRow behavior).
        if ($Priority)  { $additional["Priority"]  = $Priority }
        if ($Status)    { $additional["Status"]    = $Status }
        if ($RespTask)  { $additional["Resp Task"] = $RespTask }
        $additional["Last Updated"] = $CurrentDate
        $additional["Notes"]        = $NewNotes
    }
    elseif ($DestShortName -eq "Intake") {
        # Reverse triage / un-triage. Drops Priority/Status/Resp Task columns.
        $mapping["ID"]                = "ID"
        $mapping["Source"]            = "Source"
        $mapping["Description"]       = "Description"
        $mapping["Project"]           = "Project"
        $mapping["Framework Version"] = "Framework Version"
        $mapping["Last Updated"]      = "Last Updated"
        $mapping["Notes"]             = "Notes"

        $additional["Last Updated"] = $CurrentDate
        $additional["Notes"]        = $NewNotes
    }
    elseif ($DestShortName -eq "Rejected") {
        # Rejected schema: ID | Description | Project | Framework Version | Rejection Date | Rejection Reason | Notes
        $mapping["ID"]                = "ID"
        $mapping["Description"]       = "Description"
        $mapping["Project"]           = "Project"
        $mapping["Framework Version"] = "Framework Version"
        $mapping["Rejection Date"]    = ""    # not in source; supplied via additional
        $mapping["Rejection Reason"]  = ""    # not in source; supplied via additional
        $mapping["Notes"]             = "Notes"

        $additional["Rejection Date"]   = $CurrentDate
        $additional["Rejection Reason"] = $RejectionReason
        $additional["Notes"]            = $NewNotes
    }

    return @{ ColumnMapping = $mapping; AdditionalColumns = $additional }
}

function Resolve-EscalationTargetTracker {
    # Resolves -EscalateTo (a declared workspace ID, e.g. 'FWK-FB') to that workspace's
    # process-improvement tracker (PF-PRO-068 WI-5). Chain membership is the search space:
    # Resolve-WorkspaceRootById walks the parent-pointer chain and throws — loudly, naming the
    # walked chain — when the ID is not on it. That refusal is the point: a typo'd workspace ID
    # must never silently escalate a row into the wrong workspace's queue.
    param([Parameter(Mandatory=$true)][string]$WorkspaceId)

    $targetRoot = Resolve-WorkspaceRootById -WorkspaceId $WorkspaceId
    $targetCentral = Join-Path -Path $targetRoot -ChildPath "process-framework-central"
    if (-not (Test-Path $targetCentral)) {
        throw "Escalation target '$WorkspaceId' resolves to workspace '$targetRoot', which has no process-framework-central directory ($targetCentral). Only a producer face can receive an escalation."
    }
    return (Join-Path -Path $targetCentral -ChildPath "state-tracking/permanent/process-improvement-tracking.md")
}

function Move-IMPToWorkspace {
    # Cross-tracker escalation (PF-PRO-068 WI-5, Contract 6): removes the row from THIS
    # workspace's tracker and appends it to the target workspace's Section 1 — Intake,
    # ID-preserving.
    #
    # ID preservation is not a convenience — PF-IMP/PRO/FEE/REV/EVR mint from ONE portfolio-
    # global counter at the chain root (P-3), so a row keeps its ID wherever it lands and every
    # bare cross-reference in archives, ledgers and provenance keeps resolving. Renumbering on
    # escalation would break exactly that.
    #
    # The destination is always Intake, never a triaged section: the receiving workspace owns
    # the artifact, so it also owns the classification. Escalation hands over a finding, not a
    # routing decision made on the owner's behalf.
    #
    # Returns @{ Content; TargetContent } on success, $null on failure.
    param(
        [string]$Content,
        [string]$TargetContent,
        [string]$ImprovementId,
        [string]$SourceShortName,
        [string]$TargetWorkspaceId,
        [string]$SourceWorkspaceId,
        [string]$EscalatedBy,
        # Passed explicitly rather than read from the script scope by dynamic scoping: every
        # sibling helper here takes what it uses, and an implicitly-inherited value is invisible
        # at the call site (PF-EVR-035 F-6).
        [string]$Reason,
        [string]$AppendNotes
    )

    # Terminal and specialized-flow sections are refused: a Completed/Rejected row has already
    # reached its outcome, and Active Pilots carries a lifecycle the receiving workspace has no
    # context for. Escalation moves OPEN work.
    if ($SourceShortName -in @("ActivePilots", "Completed", "Rejected")) {
        Write-ProjectLog "$ImprovementId is in '$SourceShortName'. Escalation moves open work only — Completed / Rejected rows have reached their outcome, and Active Pilots rows carry a lifecycle the receiving workspace cannot continue." -Level "ERROR"
        return $null
    }

    $sourceHeading = $script:CentralSectionHeadings[$SourceShortName]
    $sourceRows = ConvertFrom-MarkdownTable -Content $Content -Section $sourceHeading
    $existingRow = $sourceRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $existingRow) {
        Write-ProjectLog "$ImprovementId not found in section '$SourceShortName' (re-read failed)" -Level "ERROR"
        return $null
    }
    $existingNotes = if ($existingRow.PSObject.Properties.Name -contains "Notes") { $existingRow.Notes } else { "" }

    # Audit-trail prefix, sibling of [REROUTED ...]. It records the ORIGIN workspace, which the
    # destination row otherwise loses entirely — the receiving triage needs to know whose tree
    # the finding came from to reproduce it.
    $reasonText = if ($Reason) { $Reason } else { "<no reason supplied>" }
    if (-not $Reason) {
        Write-ProjectLog "Escalation of $ImprovementId has no -Reason; recording the prefix with a '<no reason supplied>' marker (audit-trail preservation)" -Level "WARN"
    }
    $prefix = "[ESCALATED $CurrentDate from $SourceWorkspaceId by ${EscalatedBy}: $reasonText]"
    $newNotes = if ([string]::IsNullOrWhiteSpace($existingNotes) -or $existingNotes.Trim() -eq "—") {
        $prefix
    } else {
        "$prefix $($existingNotes.Trim())"
    }
    if ($AppendNotes) {
        if (-not $newNotes.Contains($AppendNotes)) { $newNotes = "$newNotes $AppendNotes" }
    }

    $colSpec = Build-ColumnMappingForMove `
        -SourceShortName $SourceShortName `
        -DestShortName "Intake" `
        -NewNotes $newNotes

    # Overwrite the Source cell so the receiving workspace's Intake reads as what it is — an
    # escalation from a named workspace — rather than inheriting the origin's own upstream
    # source label, which means nothing over there.
    $colSpec.AdditionalColumns["Source"] = "$EscalatedBy escalation from $SourceWorkspaceId"

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -DestinationContent $TargetContent `
        -RowIdPattern ([regex]::Escape($ImprovementId)) `
        -SourceSection $sourceHeading `
        -DestinationSection $script:CentralSectionHeadings["Intake"] `
        -ColumnMapping $colSpec.ColumnMapping `
        -AdditionalColumns $colSpec.AdditionalColumns `
        -SectionEndPattern '^---\s*$'

    if ($null -eq $result.Content -or $null -eq $result.DestinationContent) {
        Write-ProjectLog "Failed to escalate $ImprovementId from '$SourceShortName' to $TargetWorkspaceId" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Escalated $ImprovementId from '$SourceShortName' to $TargetWorkspaceId Intake" -Level "SUCCESS"
    return @{ Content = $result.Content; TargetContent = $result.DestinationContent }
}

function Test-PrerequisitesForMove {
    # Validates SectionMove parameter combinations and the tracking-file structure.
    param([string]$Content)

    if (-not (Test-Path $TrackingFile)) {
        Write-ProjectLog "Tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # Archive-split (2026-05-13): the SectionMove path may target Rejected,
    # which lives in the sibling archive file. Validate its existence up-front.
    if (-not (Test-Path $ArchiveFile)) {
        Write-ProjectLog "Archive file not found: $ArchiveFile. Sections 6 (Completed) and 7 (Rejected) live in this sibling file post-split." -Level "ERROR"
        return $false
    }

    if (-not (Test-IsCentralTrackingFile -Content $Content)) {
        Write-ProjectLog "Tracking file does not have the central 7-section structure ('## Section 1 — Intake' heading missing): $TrackingFile" -Level "ERROR"
        Write-ProjectLog "SectionMove operations require the centralized 7-section process-improvement-tracking.md (the resolved default). If you passed -TrackingFile, point it at the central tracker." -Level "ERROR"
        return $false
    }

    if ($MoveToSection -eq "Rejected" -and -not $RejectionReason) {
        Write-ProjectLog "-RejectionReason is required when -MoveToSection is 'Rejected'" -Level "ERROR"
        return $false
    }

    # PF-IMP-1005: on a re-route into Rejected (source != Intake), default the
    # audit-trail -Reason to -RejectionReason so the [REROUTED ...] Notes prefix
    # carries the real rejection reason instead of the "<no reason supplied>"
    # marker. No-op for Intake-source rejections (initial sort gets no prefix).
    if ($MoveToSection -eq "Rejected" -and -not $Reason -and $RejectionReason) {
        $script:Reason = $RejectionReason
        Write-ProjectLog "Defaulted -Reason to -RejectionReason for the re-route audit trail (PF-IMP-1005)" -Level "INFO"
    }

    if ($MoveToSection -in @("Improvements", "Extensions", "StructuralChanges")) {
        # PF-IMP-1831: no blanket -Status default here — the destination Status is resolved
        # PER ROW in Move-IMPBetweenSections (explicit -Status > source row's current Status
        # > "Needs Prioritization"), because batch rows can mix Intake sources (no Status
        # column, default applies) with triaged sources (current Status preserved — the old
        # unconditional default silently overwrote e.g. an In Progress claim).
        if (-not $RespTask) {
            # Auto-derive Resp Task from destination section (the conventional owner).
            $script:RespTask = switch ($MoveToSection) {
                "Improvements"      { "PF-TSK-009" }
                "Extensions"        { "PF-TSK-026" }
                "StructuralChanges" { "PF-TSK-014" }
            }
            Write-ProjectLog "Defaulted -RespTask to '$RespTask' (conventional owner of $MoveToSection section)" -Level "INFO"
        }
    }

    return $true
}

function Move-IMPBetweenSections {
    # Main mover for the SectionMove parameter set. Reads the IMP's current
    # section, builds the appropriate column transformation, and invokes the
    # generic Move-MarkdownTableRow helper.
    #
    # Archive-split (2026-05-13): when source or destination is Rejected, the
    # row read/write happens on $ArchiveContent (sibling archive file).
    # Returns @{ Content; ArchiveContent } on success, $null on failure.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId,
        [string]$SourceShortName,
        [string]$DestShortName,
        # PF-IMP-982: passed explicitly (per-ID resolved value) rather than read from the
        # script-scope $RoutedBy, whose [ValidatePattern] rejects the $null/empty default
        # that a non-triaged source section legitimately produces.
        [string]$RoutedBy
    )

    # Refuse no-op moves (source == destination).
    if ($SourceShortName -eq $DestShortName) {
        Write-ProjectLog "$ImprovementId is already in section '$DestShortName' — no move performed" -Level "WARN"
        return @{ Content = $Content; ArchiveContent = $ArchiveContent }  # caller treats unchanged content as a non-failure no-op
    }

    # Refuse moves involving Active Pilots / Completed (specialized flows handle those).
    if ($SourceShortName -in @("ActivePilots", "Completed")) {
        Write-ProjectLog "$ImprovementId is in '$SourceShortName' section. SectionMove does not support sources of ActivePilots or Completed — those have specialized flows (use -NewStatus Active/Resolved for pilots; row stays in Completed once resolved)." -Level "ERROR"
        return $null
    }

    # Source/destination archive selectors (archive-split, 2026-05-13).
    # Rejected (§7) lives in the archive; Completed is excluded above. All other
    # SectionMove-accessible sections (Intake / Improvements / Extensions /
    # Structural Changes) live in the main tracking file.
    $sourceInArchive = $SourceShortName -eq "Rejected"
    $destInArchive   = $DestShortName   -eq "Rejected"
    $sourceFileContent = if ($sourceInArchive) { $ArchiveContent } else { $Content }

    # Read the existing Notes value to compute the [REROUTED ...] prefix where applicable.
    $sourceHeading = $script:CentralSectionHeadings[$SourceShortName]
    $sourceRows = ConvertFrom-MarkdownTable -Content $sourceFileContent -Section $sourceHeading
    $existingRow = $sourceRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $existingRow) {
        Write-ProjectLog "$ImprovementId not found in section '$SourceShortName' (re-read failed)" -Level "ERROR"
        return $null
    }
    $existingNotes = if ($existingRow.PSObject.Properties.Name -contains "Notes") { $existingRow.Notes } else { "" }

    # PF-IMP-1238: -Reason feeds only the [REROUTED ...] audit-trail prefix, which is
    # suppressed on initial sorts out of Intake. A caller passing -Reason on an
    # Intake → triaged-section move would have it silently dropped; warn and point at
    # -AppendNotes. Excludes Rejected, where -Reason is legitimately auto-seeded from
    # -RejectionReason (PF-IMP-1005) and carried by the Rejection Reason column, not Notes.
    if ($SourceShortName -eq "Intake" -and $DestShortName -in @("Improvements", "Extensions", "StructuralChanges") -and $Reason) {
        Write-ProjectLog "-Reason is ignored on Intake-source initial sorts to $DestShortName (no re-route audit trail to record). Pass -AppendNotes in the same call to attach a note to the sorted row." -Level "WARN"
    }

    $newNotes = Get-NotesWithReroutePrefix `
        -ExistingNotes $existingNotes `
        -SourceSection $SourceShortName `
        -RoutedBy $RoutedBy `
        -Reason $Reason

    # PF-IMP-1393 (c): -AppendNotes rides the move in the same call — appended after the
    # [REROUTED ...] prefix logic with the StatusUpdate-set annotation's idempotent
    # semantics (skip when the literal text is already present).
    if ($AppendNotes) {
        $newNotesTrim = if ($newNotes) { $newNotes.Trim() } else { "" }
        $notesEmpty = (-not $newNotesTrim) -or ($newNotesTrim -eq "—")
        if ((-not $notesEmpty) -and $newNotesTrim.Contains($AppendNotes)) {
            Write-ProjectLog "AppendNotes: text already present in Notes for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $newNotes = if ($notesEmpty) { $AppendNotes } else { "$newNotesTrim $AppendNotes" }
            Write-ProjectLog "Appended to Notes for $ImprovementId (rides the section move)" -Level "SUCCESS"
        }
    }

    # PF-IMP-1831: per-row destination Status. Explicit -Status wins; otherwise a triaged-
    # source row KEEPS its current Status — the former unconditional pre-move default
    # silently overwrote a live value (e.g. an In Progress claim set minutes earlier),
    # announced only at default-quiet INFO. Only a row with no preservable Status (Intake
    # source — 7-col schema, no Status column — or a blank/placeholder cell) takes the
    # "Needs Prioritization" default. All triaged sections share one status legend, so a
    # preserved value is always valid in the destination.
    $effStatus = $Status
    if (-not $effStatus -and $DestShortName -in @("Improvements", "Extensions", "StructuralChanges")) {
        $sourceStatus = if ($existingRow.PSObject.Properties.Name -contains "Status") { "$($existingRow.Status)".Trim() } else { "" }
        if ($sourceStatus -and $sourceStatus -notin @("—", "-")) {
            $effStatus = $sourceStatus
            Write-ProjectLog "Preserving current Status '$sourceStatus' for $ImprovementId across the move to $DestShortName (PF-IMP-1831)" -Level "INFO"
        } else {
            $effStatus = "Needs Prioritization"
            Write-ProjectLog "Defaulted Status to 'Needs Prioritization' for $ImprovementId (no preservable source Status)" -Level "INFO"
        }
    }

    $colSpec = Build-ColumnMappingForMove `
        -SourceShortName $SourceShortName `
        -DestShortName $DestShortName `
        -Priority $Priority `
        -Status $effStatus `
        -RespTask $RespTask `
        -RejectionReason $RejectionReason `
        -NewNotes $newNotes

    $destHeading = $script:CentralSectionHeadings[$DestShortName]

    # Dispatch by source/dest file location. Move-MarkdownTableRow's two-file
    # mode (-DestinationContent) handles source-in-A / dest-in-B; we feed it
    # the right pair based on $sourceInArchive / $destInArchive.
    # The central file uses ## headings as section delimiters (no <details>
    # blocks). Override the default SectionEndPattern to match the next ## heading.
    if ($sourceInArchive -eq $destInArchive) {
        # Both sides in the same file (both main OR both archive).
        $sameFile = $sourceFileContent
        $result = Move-MarkdownTableRow `
            -Content $sameFile `
            -RowIdPattern ([regex]::Escape($ImprovementId)) `
            -SourceSection $sourceHeading `
            -DestinationSection $destHeading `
            -ColumnMapping $colSpec.ColumnMapping `
            -AdditionalColumns $colSpec.AdditionalColumns `
            -SectionEndPattern '^---\s*$'
        if ($null -eq $result.Content) {
            Write-ProjectLog "Failed to move $ImprovementId from '$SourceShortName' to '$DestShortName'" -Level "ERROR"
            return $null
        }
        $newMain    = if ($sourceInArchive) { $Content }         else { $result.Content }
        $newArchive = if ($sourceInArchive) { $result.Content }  else { $ArchiveContent }
    }
    else {
        # Cross-file: source and dest live in different files. Two-file mode.
        $srcContent  = if ($sourceInArchive) { $ArchiveContent } else { $Content }
        $destContent = if ($destInArchive)   { $ArchiveContent } else { $Content }
        $result = Move-MarkdownTableRow `
            -Content $srcContent `
            -DestinationContent $destContent `
            -RowIdPattern ([regex]::Escape($ImprovementId)) `
            -SourceSection $sourceHeading `
            -DestinationSection $destHeading `
            -ColumnMapping $colSpec.ColumnMapping `
            -AdditionalColumns $colSpec.AdditionalColumns `
            -SectionEndPattern '^---\s*$'
        if ($null -eq $result.Content -or $null -eq $result.DestinationContent) {
            Write-ProjectLog "Failed to move $ImprovementId from '$SourceShortName' to '$DestShortName' (two-file)" -Level "ERROR"
            return $null
        }
        # Map the two-file results back to (main, archive) regardless of direction.
        $newMain    = if ($sourceInArchive) { $result.DestinationContent } else { $result.Content }
        $newArchive = if ($sourceInArchive) { $result.Content }            else { $result.DestinationContent }
    }

    Write-ProjectLog "Moved $ImprovementId from '$SourceShortName' to '$DestShortName'" -Level "SUCCESS"
    return @{ Content = $newMain; ArchiveContent = $newArchive }
}

# --- Main ---

function Main {
    # Normalize short-form IDs: IMP-063 → PF-IMP-063
    if ($ImprovementId -match '^IMP-\d+$') {
        $script:ImprovementId = "PF-$ImprovementId"
    }

    Write-ProjectLog "Starting Process Improvement Update - $ScriptName"
    Write-ProjectLog "Improvement ID: $ImprovementId"

    # PF-IMP-1740 (a): a supplied -LogToolChanges that resolved to empty/whitespace is a hard
    # error before anything else runs. The classic shape is -LogToolChanges (Get-Content
    # <missing file>): Get-Content's non-terminating error leaves an empty argument, and the
    # falsy isCompletion-and-LogToolChanges guards would then skip validation AND the log call
    # — archiving the row with its change history silently lost (PF-FEE-1660). Checked in
    # Main, not Test-Prerequisites, so every dispatch path is covered.
    if ($script:LogToolChangesBoundEmpty) {
        Write-ProjectLog "-LogToolChanges was supplied but its value resolved to empty/whitespace — likely a failed file read (e.g. -LogToolChanges (Get-Content <path>) on a missing file). Nothing was changed; fix the payload source and re-run the same call." -Level "ERROR"
        exit 1
    }

    # --- SectionMove parameter set dispatch (PF-TSK-089 IMP Triage) ---
    if ($PSCmdlet.ParameterSetName -eq "Escalate") {
        # --- Escalate parameter set (PF-PRO-068 WI-5 — Contract 6 federation) ---
        $effEscalatedBy = if ($EscalatedBy) { $EscalatedBy } else { "PF-TSK-089" }
        $sourceWorkspaceId = try { (Get-ProjectConfig).project_id } catch { $null }
        if (-not $sourceWorkspaceId) {
            Write-ProjectLog "Cannot read this workspace's project_id from doc/project-config.json — the escalation audit trail records the ORIGIN workspace, so an unidentifiable origin is a hard stop rather than an anonymous row in someone else's queue." -Level "ERROR"
            exit 1
        }

        if (-not $TargetTrackingFile) {
            try {
                $TargetTrackingFile = Resolve-EscalationTargetTracker -WorkspaceId $EscalateTo
            } catch {
                Write-ProjectLog $_.Exception.Message -Level "ERROR"
                exit 1
            }
        }
        if ($TargetTrackingFile -eq $TrackingFile) {
            Write-ProjectLog "Escalation target resolves to this workspace's own tracker ($TrackingFile). '$EscalateTo' is this workspace — use -MoveToSection for moves within one tracker." -Level "ERROR"
            exit 1
        }
        if (-not (Test-Path $TargetTrackingFile)) {
            Write-ProjectLog "Escalation target tracker not found: $TargetTrackingFile" -Level "ERROR"
            exit 1
        }

        Write-ProjectLog "Escalate To:   $EscalateTo"
        Write-ProjectLog "Tracking File: $TrackingFile"
        Write-ProjectLog "Target File:   $TargetTrackingFile"

        $content = Get-Content $TrackingFile -Raw
        $archiveContent = Get-Content $ArchiveFile -Raw
        $targetContent = Get-Content $TargetTrackingFile -Raw

        if (-not (Test-IsCentralTrackingFile -Content $content)) {
            Write-ProjectLog "Tracking file does not have the central 7-section structure: $TrackingFile" -Level "ERROR"
            exit 1
        }
        if (-not (Test-IsCentralTrackingFile -Content $targetContent)) {
            Write-ProjectLog "Escalation target does not have the central 7-section structure ('## Section 1 — Intake' heading missing): $TargetTrackingFile" -Level "ERROR"
            exit 1
        }

        $sourceShortName = Get-IMPCurrentSection -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId
        Write-ProjectLog "Located $ImprovementId in section: $sourceShortName"
        if ($sourceShortName -eq "NotFound") {
            Write-ProjectLog "$ImprovementId not found in any section of $TrackingFile / $ArchiveFile" -Level "ERROR"
            exit 1
        }

        # An ID already present in the target tracker would produce two rows with one
        # portfolio-global ID — the exact breakage P-3's single counter exists to prevent.
        if ($targetContent -match ("(?m)^\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|")) {
            Write-ProjectLog "$ImprovementId already exists in the target tracker $TargetTrackingFile. IDs are portfolio-global (P-3), so escalating would create two rows sharing one ID. Reconcile the existing row first." -Level "ERROR"
            exit 1
        }

        if (-not $PSCmdlet.ShouldProcess($TargetTrackingFile, "Escalate $ImprovementId from $sourceShortName to $EscalateTo Intake")) {
            return
        }

        $escResult = Move-IMPToWorkspace `
            -Content $content `
            -TargetContent $targetContent `
            -ImprovementId $ImprovementId `
            -SourceShortName $sourceShortName `
            -TargetWorkspaceId $EscalateTo `
            -SourceWorkspaceId $sourceWorkspaceId `
            -EscalatedBy $effEscalatedBy `
            -Reason $Reason `
            -AppendNotes $AppendNotes

        if ($null -eq $escResult) { exit 1 }

        $newContent = Update-FrontmatterDate -Content $escResult.Content
        $newTarget  = Update-FrontmatterDate -Content $escResult.TargetContent

        # Write the TARGET first: a failure after the source row is already gone would lose the
        # row outright, whereas a failure after the target write leaves it in both trackers —
        # visible, reconcilable, and caught by the duplicate-ID guard above on the next attempt.
        Invoke-FileWriteWithRetry -Context (Split-Path $TargetTrackingFile -Leaf) -ScriptBlock {
            Set-Content -Path $TargetTrackingFile -Value $newTarget -NoNewline
        }
        Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
            Set-Content -Path $TrackingFile -Value $newContent -NoNewline
        }

        $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
        Assert-TableRowInFile -Path $TargetTrackingFile -Pattern $rowPattern -Context "escalated row for $ImprovementId in $TargetTrackingFile"

        Write-ProjectSummary "$ImprovementId escalated: $sourceWorkspaceId/$sourceShortName → $EscalateTo/Intake"
        return
    }

    if ($PSCmdlet.ParameterSetName -eq "SectionMove") {
        Write-ProjectLog "Move To Section: $MoveToSection"
        Write-ProjectLog "Tracking File: $TrackingFile"
        Write-ProjectLog "Archive File:  $ArchiveFile"

        $content = Get-Content $TrackingFile -Raw
        $archiveContent = Get-Content $ArchiveFile -Raw

        if (-not (Test-PrerequisitesForMove -Content $content)) {
            exit 1
        }

        # PF-IMP-1006: normalize a token-spelled -Status (e.g. "InProgress") to the display
        # form ("In Progress") that is written verbatim into the Status column, so callers may
        # use either the -NewStatus token spelling or the display spelling interchangeably.
        if ($Status -and $StatusDisplayNames.ContainsKey($Status)) {
            $script:Status = $StatusDisplayNames[$Status]
            Write-ProjectLog "Normalized -Status token to display form '$Status' (PF-IMP-1006)" -Level "INFO"
        }

        # PF-IMP-982: batch mode. Build the full ID list (-ImprovementId + -AlsoMoveIds),
        # normalize short IMP-NNN → PF-IMP-NNN, and de-dup. ($ImprovementId is already
        # normalized at the top of Main; $AlsoMoveIds are normalized here.)
        # PF-IMP-1830: split each element on commas first — pwsh -File binds a CSV list as
        # ONE element, and the split makes that element and a real -Command array yield the
        # same ID list (split-in-place pattern, PF-IMP-1428 / PF-IMP-1542).
        $batchIds = @($ImprovementId)
        if ($AlsoMoveIds) {
            foreach ($extra in @($AlsoMoveIds -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })) {
                $batchIds += if ($extra -match '^IMP-\d+$') { "PF-$extra" } else { $extra }
            }
        }
        $batchIds = $batchIds | Select-Object -Unique

        # -Retriage / explicit -RoutedBy conflict is a global param error (check once).
        if ($Retriage -and $RoutedBy -and $RoutedBy -ne "PF-TSK-089") {
            Write-ProjectLog "-Retriage implies -RoutedBy 'PF-TSK-089' but you supplied '$RoutedBy'. Choose one." -Level "ERROR"
            exit 1
        }
        # Capture the explicitly-supplied -RoutedBy before the loop mutates $script:RoutedBy
        # per-ID (each ID's source section determines its own default).
        $explicitRoutedBy = $RoutedBy

        $origContent        = $content
        $origArchiveContent = $archiveContent
        $moved  = @()   # [pscustomobject]@{ Id; Src }
        $noop   = @()   # IDs already in the destination section
        $failed = @()   # [pscustomobject]@{ Id; Reason }

        foreach ($id in $batchIds) {
            $sourceShortName = Get-IMPCurrentSection -Content $content -ArchiveContent $archiveContent -ImprovementId $id
            Write-ProjectLog "Located $id in section: $sourceShortName"

            if ($sourceShortName -eq "NotFound") {
                Write-ProjectLog "$id not found in any section of $TrackingFile / $ArchiveFile" -Level "ERROR"
                $failed += [pscustomobject]@{ Id = $id; Reason = "not found in any section" }
                continue
            }

            # PF-IMP-857: -Retriage is invalid for Intake-source moves (initial triage is
            # already attributed to PF-TSK-089). In a mixed batch this is a per-ID skip.
            if ($Retriage -and $sourceShortName -eq "Intake") {
                Write-ProjectLog "-Retriage is invalid for Intake-source moves ($id). The default Intake → triaged-section flow is already attributed to PF-TSK-089." -Level "ERROR"
                $failed += [pscustomobject]@{ Id = $id; Reason = "-Retriage invalid for Intake-source" }
                continue
            }

            # Resolve -RoutedBy for this ID: explicit override > -Retriage (PF-TSK-089) >
            # source-section conventional owner. Held in a LOCAL (not $script:RoutedBy):
            # the script param's [ValidatePattern] would reject the $null a non-triaged
            # source (e.g. Rejected) legitimately yields. Passed to Move-IMPBetweenSections.
            $effRoutedBy =
                if ($explicitRoutedBy) { $explicitRoutedBy }
                elseif ($Retriage)     { "PF-TSK-089" }
                else {
                    switch ($sourceShortName) {
                        "Intake"            { "PF-TSK-089" }
                        "Improvements"      { "PF-TSK-009" }
                        "Extensions"        { "PF-TSK-026" }
                        "StructuralChanges" { "PF-TSK-014" }
                        default             { $null }
                    }
                }
            if ($effRoutedBy) {
                Write-ProjectLog "Resolved -RoutedBy to '$effRoutedBy' for $id (source '$sourceShortName')" -Level "INFO"
            }

            if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Move $id from $sourceShortName to $MoveToSection")) {
                continue
            }

            $moveResult = Move-IMPBetweenSections `
                -Content $content `
                -ArchiveContent $archiveContent `
                -ImprovementId $id `
                -SourceShortName $sourceShortName `
                -DestShortName $MoveToSection `
                -RoutedBy $effRoutedBy

            if ($null -eq $moveResult) {
                $failed += [pscustomobject]@{ Id = $id; Reason = "move failed (see errors above)" }
                continue
            }

            # No-op (source == dest): Move-IMPBetweenSections returns content unchanged.
            if ($moveResult.Content -eq $content -and $moveResult.ArchiveContent -eq $archiveContent) {
                $noop += $id
                continue
            }

            $content        = $moveResult.Content
            $archiveContent = $moveResult.ArchiveContent
            $moved += [pscustomobject]@{ Id = $id; Src = $sourceShortName }
        }

        # Nothing actually moved: report no-ops / failures (also the -WhatIf path lands here,
        # since ShouldProcess returned false for every ID and no content changed).
        if ($moved.Count -eq 0) {
            if ($noop.Count -gt 0) {
                Write-ProjectSummary "$($noop -join ', ') already in '$MoveToSection' — no change" -Level "WARN"
            }
            if ($failed.Count -gt 0) {
                Write-ProjectSummary "Batch move failed: $($failed.Count) ID(s) not moved ($(($failed | ForEach-Object { $_.Id }) -join ', '))" -Level "ERROR"
                exit 1
            }
            return
        }

        # Update frontmatter date on whichever file(s) changed (the central file
        # frontmatter uses the `updated:` field convention; archive file mirrors it).
        if ($content -ne $origContent) {
            $content = Update-FrontmatterDate -Content $content
        }
        if ($archiveContent -ne $origArchiveContent) {
            $archiveContent = Update-FrontmatterDate -Content $archiveContent
        }

        if ($content -ne $origContent) {
            Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
                Set-Content -Path $TrackingFile -Value $content -NoNewline
            }
        }
        if ($archiveContent -ne $origArchiveContent) {
            Invoke-FileWriteWithRetry -Context (Split-Path $ArchiveFile -Leaf) -ScriptBlock {
                Set-Content -Path $ArchiveFile -Value $archiveContent -NoNewline
            }
        }

        if (-not $WhatIfPreference) {
            # Verify each moved row landed where it should: main file for §1-§4, archive
            # for Rejected. Use whichever target the destination corresponds to.
            $verifyFile = if ($MoveToSection -eq "Rejected") { $ArchiveFile } else { $TrackingFile }
            foreach ($m in $moved) {
                $rowPattern = "\|\s*" + [regex]::Escape($m.Id) + "\s*\|"
                Assert-TableRowInFile -Path $verifyFile -Pattern $rowPattern -Context "row for $($m.Id) in $verifyFile"
            }
        }

        if ($moved.Count -eq 1 -and $noop.Count -eq 0 -and $failed.Count -eq 0) {
            # Preserve the single-ID summary form.
            Write-ProjectSummary "$($moved[0].Id) moved: $($moved[0].Src) → $MoveToSection"
        } else {
            $summary = "$(($moved | ForEach-Object { $_.Id }) -join ', ') moved → $MoveToSection ($($moved.Count) moved"
            if ($noop.Count -gt 0)   { $summary += "; $($noop.Count) no-op" }
            if ($failed.Count -gt 0) { $summary += "; $($failed.Count) failed" }
            $summary += ")"
            Write-ProjectSummary $summary -Level $(if ($failed.Count -gt 0) { "WARN" } else { "SUCCESS" })
        }

        if ($failed.Count -gt 0) { exit 1 }
        return
    }

    # --- StatusUpdate parameter set (existing behavior + PF-IMP-832 / -863 additions) ---

    # PF-IMP-863: -AnnotateAsRolledInto is a thin specialization of -AppendNotes for the
    # duplicate-of-open-IMP cluster-consolidation case. Build the canonical annotation
    # message ONCE here and fold it into $AppendNotes — the rest of the pipeline (idempotency,
    # alongside-status fold-in, alone-mode trigger) then handles it transparently. Idempotency
    # comes free: same source ID + same date → same canonical string → AppendNotes substring
    # check skips on re-invocation.
    if ($AnnotateAsRolledInto) {
        # Normalize: accept IMP-NNN or PF-IMP-NNN, emit PF-IMP-NNN.
        $normalizedRolledInto = if ($AnnotateAsRolledInto -match '^IMP-\d+$') { "PF-$AnnotateAsRolledInto" } else { $AnnotateAsRolledInto }
        $rolledIntoAnnotation = "[rolled-into $normalizedRolledInto $CurrentDate]"
        if ($AppendNotes) {
            # Caller passed both — fold the rolled-into prefix in front so the canonical
            # marker stays scannable. Skip if the rolled-into substring is already present
            # (idempotent across mixed-invocation patterns).
            if ($AppendNotes -notlike "*$rolledIntoAnnotation*") {
                $script:AppendNotes = "$rolledIntoAnnotation $AppendNotes"
            }
        } else {
            $script:AppendNotes = $rolledIntoAnnotation
        }
    }

    # PF-IMP-1007: -AppendNotes and -EditNotes both target the Notes cell with opposite
    # semantics (append vs replace) — combining them is ambiguous. Reject up front.
    if ($AppendNotes -and $EditNotes) {
        Write-ProjectLog "-AppendNotes and -EditNotes are mutually exclusive (one appends to Notes, the other replaces it). Supply only one." -Level "ERROR"
        exit 1
    }

    # PF-IMP-1343: accept -RejectionReason on the status-path reject as an alias for the
    # reject-reason carrier -ValidationNotes (the SectionMove branch returned above, so any
    # -RejectionReason still bound here came in via the StatusUpdate set). It is meaningful
    # only for the Rejected status — fold it into $ValidationNotes, and reject the ambiguous
    # both-supplied case and the wrong-status / no-status misuses with a targeted error.
    if ($RejectionReason) {
        if ($NewStatus -ne "Rejected") {
            Write-ProjectLog "-RejectionReason is only valid with -NewStatus Rejected. For other statuses pass the rationale via -ValidationNotes; for the triage move use -MoveToSection Rejected -RejectionReason." -Level "ERROR"
            exit 1
        }
        if ($ValidationNotes) {
            Write-ProjectLog "Supply the rejection reason via exactly one of -RejectionReason or -ValidationNotes, not both." -Level "ERROR"
            exit 1
        }
        $script:ValidationNotes = $RejectionReason
    }

    # PF-IMP-832 (a): annotation-only mode. When -NewStatus is omitted but at least one of
    # -AppendNotes / -SetRespTask / -SetPriority / -EditDescription / -EditNotes /
    # -AnnotateAsRolledInto is bound, run the annotation as a standalone edit (no status
    # transition, no completion move). At least one must be supplied.
    if (-not $NewStatus) {
        if (-not $AppendNotes -and -not $SetRespTask -and -not $SetPriority -and -not $EditDescription -and -not $EditNotes) {
            # -AnnotateAsRolledInto already folded into $AppendNotes above; if that fold
            # populated nothing (it can't, given the ValidatePattern), the user-visible
            # error still reads naturally.
            Write-ProjectLog "Must supply at least one of -NewStatus, -AppendNotes, -SetRespTask, -SetPriority, -EditDescription, -EditNotes, or -AnnotateAsRolledInto" -Level "ERROR"
            exit 1
        }

        Write-ProjectLog "Tracking File: $TrackingFile"
        Write-ProjectLog "Archive File:  $ArchiveFile"

        if (-not (Test-Path $TrackingFile)) {
            Write-ProjectLog "Tracking file not found: $TrackingFile" -Level "ERROR"
            exit 1
        }
        if (-not (Test-Path $ArchiveFile)) {
            Write-ProjectLog "Archive file not found: $ArchiveFile" -Level "ERROR"
            exit 1
        }

        $content = Get-Content $TrackingFile -Raw
        $archiveContent = Get-Content $ArchiveFile -Raw

        if (-not (Test-IsCentralTrackingFile -Content $content)) {
            Write-ProjectLog "Tracking file does not have the central 7-section structure: $TrackingFile" -Level "ERROR"
            exit 1
        }

        if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Annotate $ImprovementId")) {
            return
        }

        # Annotation covers every live section plus — since PF-IMP-1719 — the two archive
        # sections. $archiveContent is both the search space for Get-IMPCurrentSection and the
        # edit target when the row turns out to be archived; the result says which file to write.
        $annotation = Update-AnnotationInPlace -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -AppendNotes $AppendNotes -SetRespTask $SetRespTask -SetPriority $SetPriority -EditDescription $EditDescription -EditNotes $EditNotes -AllowArchive
        if ($null -eq $annotation) { exit 1 }

        $targetFile = if ($annotation.IsArchive) { $ArchiveFile } else { $TrackingFile }
        $originalContent = if ($annotation.IsArchive) { $archiveContent } else { $content }
        $newContent = $annotation.Content

        if ($newContent -eq $originalContent) {
            Write-ProjectSummary "$ImprovementId annotation — no change (idempotent)" -Level "WARN"
            return
        }

        $newContent = Update-FrontmatterDate -Content $newContent

        Invoke-FileWriteWithRetry -Context (Split-Path $targetFile -Leaf) -ScriptBlock {
            Set-Content -Path $targetFile -Value $newContent -NoNewline
        }

        if (-not $WhatIfPreference) {
            $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
            Assert-TableRowInFile -Path $targetFile -Pattern $rowPattern -Context "row for $ImprovementId in $targetFile"
        }

        $annotations = @()
        if ($AppendNotes)     { $annotations += "Notes(append)" }
        if ($EditNotes)       { $annotations += "Notes(replace)" }
        if ($EditDescription) { $annotations += "Description(replace)" }
        if ($SetRespTask)     { $annotations += "Resp Task=$SetRespTask" }
        if ($SetPriority)     { $annotations += "Priority=$SetPriority" }
        Write-ProjectSummary "$ImprovementId annotated: $($annotations -join ', ')"
        return
    }

    Write-ProjectLog "New Status: $NewStatus"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    # PF-IMP-852: $isCompletion narrowed to Completed-only (was Completed+Rejected).
    # Rejected now follows its own Section 7 routing branch parallel to Superseded.
    $isCompletion = $NewStatus -eq "Completed"
    $isRejection = $NewStatus -eq "Rejected"
    $isPilotStatus = $NewStatus -in $PilotStatuses
    $isSupersedure = $NewStatus -eq "Superseded"

    # Detect which section the IMP lives in (read once, reuse for routing).
    # Archive-split (2026-05-13): §6/§7 live in $archiveContent. Read both.
    if (-not (Test-Path $ArchiveFile)) {
        Write-ProjectLog "Archive file not found: $ArchiveFile" -Level "ERROR"
        exit 1
    }
    $content = Get-Content $TrackingFile -Raw
    $archiveContent = Get-Content $ArchiveFile -Raw
    $location = Test-ImprovementLocation -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId
    Write-ProjectLog "Located $ImprovementId in section: $location"

    # Validate status / location compatibility
    if ($isPilotStatus) {
        if ($location -ne "ActivePilots") {
            # PF-IMP-832 (d): surface the canonical non-pilot alternatives so the caller
            # knows what to retry with. Previously the error told them what was invalid
            # but not what to use instead (PF-IMP-804 friction).
            Write-ProjectLog "Pilot status '$NewStatus' is only valid for IMPs in the Active Pilots section. $ImprovementId is in: $location. For regular IMPs, use -NewStatus Completed (or Rejected/Deferred/Superseded)." -Level "ERROR"
            exit 1
        }
    } else {
        if ($location -eq "ActivePilots") {
            Write-ProjectLog "Status '$NewStatus' is not valid for pilots. Use Active or Resolved for IMPs in the Active Pilots section." -Level "ERROR"
            exit 1
        }
        if ($location -eq "Intake") {
            # PF-IMP-861: Test-ImprovementLocation now scans Intake directly (was returning
            # NotFound for Intake rows, which forced a NotFound bypass for supersedure/rejection
            # paths — see PF-IMP-832 (c) / PF-IMP-852 history). Intake-source operations are
            # Supersession (cluster owner retiring consolidated rows still in Intake) and
            # Rejection (triage outright rejection). Status flips on Intake rows must triage
            # the row first via -MoveToSection.
            if (-not $isSupersedure -and -not $isRejection) {
                Write-ProjectLog "$ImprovementId is in Section 1 — Intake. Triage it first via -MoveToSection before applying status updates. (Supersession/Rejection are the only Intake-source operations.)" -Level "ERROR"
                exit 1
            }
        }
        if ($location -eq "NotFound") {
            Write-ProjectLog "$ImprovementId not found in any section of $TrackingFile / $ArchiveFile" -Level "ERROR"
            exit 1
        }
    }

    # PF-IMP-1393 (b): validate the -LogToolChanges payload (JSON shape + tool_doc_ids)
    # BEFORE the terminal move, so a bad ID is fixed up front instead of backfilled after
    # the row is already archived. Runtime failures of the real post-move log call keep
    # their preserve-move-on-WARN semantics.
    if ($isCompletion -and $LogToolChanges) {
        if (-not (Invoke-LogToolChanges -JsonPayload $LogToolChanges -ValidateOnly)) {
            Write-ProjectLog "-LogToolChanges validation failed — nothing was written. Fix the payload (see message above) and re-run the same completion call." -Level "ERROR"
            exit 1
        }
    }

    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Update $ImprovementId to $NewStatus")) {
        return
    }

    # --- Annotation alongside status update (PF-IMP-832 (a)) ---
    # If -AppendNotes / -SetRespTask / -SetPriority was supplied alongside -NewStatus, apply the
    # annotation to the source row BEFORE the status update / move. This ensures (a) in-place
    # updates see the new Notes/Resp Task/Priority in the same write cycle, and (b)
    # Completed-transition moves fold the new Notes into the synthesized destination row and use
    # the new Resp Task as the default Implementing Task. Pilots (7-col schema, no Resp Task or
    # Priority column) are not supported.
    if ($AppendNotes -or $SetRespTask -or $SetPriority -or $EditDescription -or $EditNotes) {
        if ($isPilotStatus) {
            Write-ProjectLog "-AppendNotes / -SetRespTask / -SetPriority / -EditDescription / -EditNotes / -AnnotateAsRolledInto are not supported for pilot statuses (Active Pilots rows have no Resp Task or Priority column and use a different schema)" -Level "ERROR"
            exit 1
        }
        # No -AllowArchive here: a status transition targets a live row, so an already-archived
        # IMP still fails rather than being annotated in place (PF-IMP-1719).
        $annotation = Update-AnnotationInPlace -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -AppendNotes $AppendNotes -SetRespTask $SetRespTask -SetPriority $SetPriority -EditDescription $EditDescription -EditNotes $EditNotes
        if ($null -eq $annotation) { exit 1 }
        $content = $annotation.Content
    }

    # --- Pilot path (PF-PRO-030) ---
    if ($isPilotStatus) {
        # Detect already-Resolved migration path (PF-IMP-729): if pilot is already in Resolved
        # status and Resolved is requested again, skip the in-place update + notes append (would
        # otherwise create a duplicate "Resolved YYYY-MM-DD: ..." entry in Notes) — just do the move.
        $alreadyResolved = $false
        if ($NewStatus -eq "Resolved") {
            $existingPilotRows = ConvertFrom-MarkdownTable -Content $content -Section "## Section 5 — Active Pilots"
            $existingRow = $existingPilotRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
            if ($existingRow -and $existingRow.Status -eq "Resolved") {
                $alreadyResolved = $true
                Write-ProjectLog "Pilot $ImprovementId already in Resolved status — skipping in-place update (migration path)" -Level "INFO"
            }
        }

        if (-not $alreadyResolved) {
            # Update pilot status in place (appends "Resolved YYYY-MM-DD: ..." to Notes if applicable)
            $content = Update-PilotStatusInPlace -Content $content -ImprovementId $ImprovementId -NewStatus $NewStatus -Notes $ValidationNotes
            if ($null -eq $content) { exit 1 }
        }

        # On Resolved: extract concept ID and move pilot row to Completed Improvements (PF-IMP-729)
        $conceptId = $null
        if ($NewStatus -eq "Resolved") {
            $conceptId = Get-ConceptIdFromPilotRow -Content $content -ImprovementId $ImprovementId
            if (-not $conceptId) {
                # PF-IMP-883: improvement-origin pilots (SourceConcept = PF-IMP-NNN) have no proposal
                # doc to archive — this is expected, not a defect. Only emit WARN if the Concept column
                # doesn't match either origin pattern (genuine defect).
                $pilotRows = ConvertFrom-MarkdownTable -Content $content -Section "## Section 5 — Active Pilots"
                $pilotRow = $pilotRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
                if ($pilotRow -and $pilotRow.Concept -match '^PF-IMP-\d+$') {
                    Write-ProjectLog "Pilot $ImprovementId is improvement-origin (Concept = $($pilotRow.Concept)); no concept doc to archive — skipping archival step." -Level "INFO"
                } else {
                    Write-ProjectLog "Could not extract concept ID from pilot row Concept column. Manual concept archive may be required." -Level "WARN"
                }
            }

            # Move pilot row from Active Pilots (main) to archive § Section 6 — Completed
            $moveResult = Move-PilotToCompletedSection -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -Impact $Impact -ImplementingTask $ImplementingTask
            if ($null -eq $moveResult) { exit 1 }
            $content        = $moveResult.Content
            $archiveContent = $moveResult.ArchiveContent

            # Update Completed summary count (no-op for current archive layout but
            # preserved for legacy `<summary>` tags that may exist in older files)
            $sumResult = Update-SummaryCount -Content $content -ArchiveContent $archiveContent
            $content        = $sumResult.Content
            $archiveContent = $sumResult.ArchiveContent
        }

        # Update frontmatter date on both files where touched
        $content = Update-FrontmatterDate -Content $content
        if ($NewStatus -eq "Resolved") {
            $archiveContent = Update-FrontmatterDate -Content $archiveContent
        }

        # Write tracking file (retry-on-IOException absorbs LinkWatcher contention — PF-IMP-718)
        Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
            Set-Content -Path $TrackingFile -Value $content -NoNewline
        }
        if ($NewStatus -eq "Resolved") {
            Invoke-FileWriteWithRetry -Context (Split-Path $ArchiveFile -Leaf) -ScriptBlock {
                Set-Content -Path $ArchiveFile -Value $archiveContent -NoNewline
            }
        }

        # Read-after-write verification: confirm the row exists in the expected file.
        # On Resolved the row landed in the archive § Section 6; otherwise it's still
        # in Active Pilots (main file).
        if (-not $WhatIfPreference) {
            $verifyFile = if ($NewStatus -eq "Resolved") { $ArchiveFile } else { $TrackingFile }
            $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
            Assert-TableRowInFile -Path $verifyFile -Pattern $rowPattern -Context "row for $ImprovementId in $verifyFile"
        }

        # Archive concept doc on Resolved (after tracking file is written, so a failure here doesn't leave inconsistent state)
        if ($NewStatus -eq "Resolved" -and $conceptId) {
            $archived = Move-ConceptToArchive -ConceptId $conceptId
            if (-not $archived) {
                Write-ProjectLog "Concept archive step had issues — manual review required" -Level "WARN"
            }
        }

        $pilotDisplay = $StatusDisplayNames[$NewStatus]
        if ($NewStatus -eq "Resolved") {
            Write-ProjectSummary "$ImprovementId pilot → $pilotDisplay (moved to Completed Improvements)"
        } else {
            Write-ProjectSummary "$ImprovementId pilot → $pilotDisplay"
        }
        return
    }

    # --- Regular IMP path (Phase 7 cross-schema translation) ---
    # Archive-split (2026-05-13): all three destination paths (Completed,
    # Rejected, Superseded) write to the sibling archive file. In-place status
    # updates touch only the main file. Track whether the archive changed so
    # we know whether to write it.
    $archiveTouched = $false
    if ($isCompletion) {
        # Step 1: Move row from source section (Improvements / Extensions / Structural Changes)
        # to archive § Section 6 — Completed. Pre-detected $location drives source-section
        # selection so Section 3/4 IMPs complete correctly (was hardcoded to Section 2 —
        # PF-IMP-760 note).
        if ($location -notin @("Current", "Extensions", "StructuralChanges")) {
            Write-ProjectLog "Completion transition not valid for $ImprovementId — found in section: $location. Expected one of: Current (Improvements) / Extensions / StructuralChanges." -Level "ERROR"
            exit 1
        }

        # PF-IMP-1740 (b): a Completed IMP normally carries feedback_db change rows — via this
        # call's -LogToolChanges fold or an earlier standalone log-change. A rejected standalone
        # batch otherwise leaves a Completed IMP with no change record and no signal
        # (PF-FEE-1648: twice in one session). Detection needs the DB, not a payload check.
        # Advisory only: zero-change completions can be legitimate, and the query returns $null
        # (stay silent) when python/feedback_db.py is unavailable.
        if (-not $LogToolChanges) {
            if ((Test-ImpHasLoggedChanges -ImprovementId $ImprovementId) -eq $false) {
                Write-ProjectLog "Completing $ImprovementId with no -LogToolChanges payload and no feedback_db change rows logged for it. If this session changed tools/artifacts, log them (feedback_db.py log-change) and verify with: feedback_db.py list-changes --imp $ImprovementId" -Level "WARN"
            }
        }

        $moveResult = Move-ToCompletedSection -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -Impact $Impact -ValidationNotes $ValidationNotes -ImplementingTask $ImplementingTask -SourceLocation $location
        if ($null -eq $moveResult) { exit 1 }
        $content        = $moveResult.Content
        $archiveContent = $moveResult.ArchiveContent
        $archiveTouched = $true

        # Step 2: Update summary count (no-op for current layout; preserved for legacy)
        $sumResult = Update-SummaryCount -Content $content -ArchiveContent $archiveContent
        $content        = $sumResult.Content
        $archiveContent = $sumResult.ArchiveContent
    }
    elseif ($isRejection) {
        # PF-IMP-852: Rejected → move to archive § Section 7 — Rejected with
        # Rejection Reason = the caller-supplied ValidationNotes.
        $moveResult = Move-ToRejected -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -RejectionReason $ValidationNotes
        if ($null -eq $moveResult) { exit 1 }
        $content        = $moveResult.Content
        $archiveContent = $moveResult.ArchiveContent
        $archiveTouched = $true
    }
    elseif ($isSupersedure) {
        # PF-IMP-832 (c): Superseded → move to archive § Section 7 Rejected with
        # Rejection Reason = "Superseded by <SupersededBy>".
        $moveResult = Move-ToRejectedAsSuperseded -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -SupersededBy $SupersededBy -ValidationNotes $ValidationNotes
        if ($null -eq $moveResult) { exit 1 }
        $content        = $moveResult.Content
        $archiveContent = $moveResult.ArchiveContent
        $archiveTouched = $true
    }
    else {
        # Status-only update on a triaged row (Improvements / Extensions / Structural Changes).
        # Update-StatusInPlace locates the IMP's current section internally (PF-IMP-856 part B).
        # No archive write.
        $content = Update-StatusInPlace -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -NewStatus $NewStatus
        if ($null -eq $content) { exit 1 }
    }

    # Update frontmatter date on whichever file(s) changed
    $content = Update-FrontmatterDate -Content $content
    if ($archiveTouched) {
        $archiveContent = Update-FrontmatterDate -Content $archiveContent
    }

    # Write main tracking file (retry-on-IOException absorbs LinkWatcher contention — PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $content -NoNewline
    }
    if ($archiveTouched) {
        Invoke-FileWriteWithRetry -Context (Split-Path $ArchiveFile -Leaf) -ScriptBlock {
            Set-Content -Path $ArchiveFile -Value $archiveContent -NoNewline
        }
    }

    # Read-after-write verification: confirm the IMP row landed in the right file.
    # Completion/Rejection/Supersedure land in the archive; in-place stays in main.
    # PF-IMP-1875: Assert-TableRowInFile, not the presence-only Assert-LineInFile — it also
    # resolves the row's governing header and compares cell counts, so a row that is not a
    # well-formed table row (missing terminator, cells shifted by an unescaped pipe) fails
    # loudly at the moment of the bad write instead of sitting unparseable in the tracker.
    # PF-IMP-1563 shipped that assert but wired it into only one of this script's four
    # verification sites; two archived rows reached the tree unparseable through this one.
    if (-not $WhatIfPreference) {
        $verifyFile = if ($archiveTouched) { $ArchiveFile } else { $TrackingFile }
        $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
        Assert-TableRowInFile -Path $verifyFile -Pattern $rowPattern -Context "IMP row for $ImprovementId in $verifyFile"
    }

    # PF-IMP-832 (b): on Completed transition with -LogToolChanges, invoke feedback_db.py
    # log-change --batch -. Runs after the write so a log-change failure leaves the IMP
    # transition intact (caller can retry log-change manually).
    if ($isCompletion -and $LogToolChanges -and $NewStatus -eq "Completed") {
        Invoke-LogToolChanges -JsonPayload $LogToolChanges | Out-Null
    }

    # PF-IMP-1688: archive the named extension concept (PF-TSK-026 Step 21, full-rollout
    # path). Runs after the write for the same reason as the pilot path above — a concept
    # move failure leaves the status transition intact and is recoverable by hand.
    if ($ArchiveConcept) {
        if (-not (Move-ConceptToArchive -ConceptId $ArchiveConcept)) {
            Write-ProjectLog "Concept archive step had issues — manual review required" -Level "WARN"
        }
    }

    $outcome = if ($isCompletion) {
        "$($StatusDisplayNames[$NewStatus]) (moved to archive § Section 6 — Completed)"
    } elseif ($isRejection) {
        "Rejected (moved to archive § Section 7 — Rejected)"
    } elseif ($isSupersedure) {
        "Superseded by $SupersededBy (moved to archive § Section 7 — Rejected)"
    } else {
        $StatusDisplayNames[$NewStatus]
    }
    Write-ProjectSummary "$ImprovementId → $outcome"
}

# PF-IMP-1740 (a): captured in the script body because $PSBoundParameters inside Main is
# Main's own (empty) set — only the script scope can tell "supplied but resolved empty"
# (e.g. -LogToolChanges (Get-Content <missing file>)) apart from "not supplied".
$script:LogToolChangesBoundEmpty = $PSBoundParameters.ContainsKey('LogToolChanges') -and
    [string]::IsNullOrWhiteSpace($LogToolChanges)

# Execute main function
try {
    Main
    if ($soakInSoak) {
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
    }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Process Improvement update failed: $($_.Exception.Message)" -ExitCode 1
}
