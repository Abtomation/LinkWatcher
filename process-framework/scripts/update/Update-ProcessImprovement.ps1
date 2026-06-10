#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates improvement status updates and section moves in the Process Improvement Tracking state file

.DESCRIPTION
This script automates improvement lifecycle transitions in process-improvement-tracking.md.

Updates the following files (defaults; override with -TrackingFile / -ArchiveFile):
- appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md (live sections 1–5, resolved via .framework-central-pointer)
- appdev/process-framework-central/state-tracking/permanent/archive/process-improvement-tracking-archive.md (Sections 6 Completed + 7 Rejected; archive-split 2026-05-13)

Supports two parameter sets:

1. StatusUpdate (default; existing behavior):
   - Status-only update: changes Status and Last Updated columns in the Current table
   - Completion: moves improvement from Current to Completed section, updates summary count,
     and updates frontmatter date
   - Supersession (PF-IMP-832 (c)): -NewStatus Superseded with -SupersededBy moves the row
     to Section 7 — Rejected with Rejection Reason = "Superseded by <SupersededBy>". Keeps
     supersession distinct from implementation in trend analysis (per PF-IMP-803 rationale).
   - Pilot lifecycle (Active/Resolved): see PF-PRO-030
   - Annotation (PF-IMP-832 (a)): -AppendNotes (idempotent) and -SetRespTask edit Notes /
     Resp Task columns. Available alone (pure annotation, no status change — at least one
     of -NewStatus / -AppendNotes / -SetRespTask must be supplied) or alongside -NewStatus
     (annotation applied to source row before the status transition).
   - Tool-change logging (PF-IMP-832 (b)): -LogToolChanges (JSON, same shape as
     feedback_db.py log-change --batch - stdin) folds the PF-TSK-009 Step 12 manual
     feedback_db invocation into the Completed transition. Log-change failure is reported
     as WARN; the IMP move is preserved (caller can retry log-change manually).

2. SectionMove (new — PF-TSK-089 IMP Triage helper, PF-PRO-029 Phase 4):
   - Moves an IMP between sections in the centralized 7-section tracking file
   - Valid destinations: Intake | Improvements | Extensions | StructuralChanges | Rejected
     (ActivePilots and Completed are excluded — they have specialized flows)
   - Handles column-schema transformation between source and destination sections
   - On re-routes (source != Intake), auto-prepends [REROUTED YYYY-MM-DD by PF-TSK-NNN: <reason>]
     to the Notes column for an audit trail. Initial sort from Intake produces no prefix.

   Batch mode (PF-IMP-982): pass -AlsoMoveIds to move several IMPs to the SAME section
   with the SAME options in one call. Each ID's source section is resolved independently;
   a not-found/failed ID is reported and skipped without aborting the rest of the batch.

   Smart defaults — typical invocations only need -ImprovementId, -MoveToSection, -Priority
   (and -RejectionReason when target is Rejected, plus -Reason on re-routes for the audit trail):
   - -Status defaults to "Needs Prioritization" on triaged-section moves; accepts either the
     display spelling ("In Progress") or the -NewStatus token spelling ("InProgress") (PF-IMP-1006).
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

   Requires the centralized 7-section tracking file. Pass -TrackingFile <central-path>
   until PF-PRO-029 Phase 7 cuts over the default.

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
                        PF-TSK-009 Step 12 feedback_db log-change into the same call)
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
or alone (annotation-only mode):
  -AppendNotes <text>       Idempotently append text to the Notes column. Skipped if the
                            same literal substring is already present in Notes. Date stamp
                            is the caller's responsibility (the script does not prefix
                            anything — caller controls wording).
  -SetRespTask <PF-TSK-NNN> Replace the Resp Task column value (validated against
                            ^PF-TSK-\d+$). Skipped if already equal.
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
PF-IMP-832 (a). Append text to the Notes column on a row in one of the 10-col triaged sections
(Improvements / Extensions / Structural Changes). Idempotent — does not duplicate if the same
literal substring is already present in Notes. Date stamp is the caller's responsibility
(the script does not prefix anything). Available alongside any non-pilot -NewStatus or alone
(when used alone, the script writes the annotation without any status transition).

.PARAMETER SetRespTask
PF-IMP-832 (a). Replace the Resp Task column value on a row in one of the 10-col triaged
sections (validated against ^PF-TSK-\d+$). Idempotent — skipped if Resp Task already equals
the supplied value. Available alongside any non-pilot -NewStatus or alone.

.PARAMETER LogToolChanges
PF-IMP-832 (b). JSON payload (array, same shape as `feedback_db.py log-change --batch -`
accepts via stdin) of tool-change entries to log when the Completed transition runs. Folds
the PF-TSK-009 Step 12 manual feedback_db invocation into the same call that flips the
status. Only valid with -NewStatus Completed. On log-change failure the IMP move is
preserved (already written before the log call) and a WARN is emitted.

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
  (e.g., embedding "Rejecting per <task> on <date>" if desired).
- Ignored for other statuses.

.PARAMETER TrackingFile
Path to the main process-improvement-tracking.md (live sections 1–5). Defaults to the
central path resolved via Get-CentralFrameworkPath. Override only for tests or non-default
layouts.

.PARAMETER ArchiveFile
Path to the sibling archive file containing Section 6 — Completed and Section 7 — Rejected
(archive-split 2026-05-13). Defaults to `archive/process-improvement-tracking-archive.md`
next to -TrackingFile. Override only for tests or non-default layouts.

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
# Complete with tool-change logging (PF-IMP-832 (b)): folds PF-TSK-009 Step 12 into the same call
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
# and skipped without aborting the rest of the batch.
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-810" -AlsoMoveIds "PF-IMP-811","PF-IMP-812" -MoveToSection "Improvements" -Priority "Medium" -TrackingFile "<central path>"

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
    [ValidatePattern('^PF-TSK-\d+$')]
    [string]$ImplementingTask,

    # PF-IMP-832 (b): JSON payload (array, same shape as feedback_db.py log-change --batch -
    # accepts via stdin) of tool-change entries to log when the Completed transition runs.
    # Folds the PF-TSK-009 Step 12 manual feedback_db log-change invocation into the same
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
    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [ValidatePattern('^(IMP|PF-IMP)-\d+$')]
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
    [ValidatePattern('^PF-TSK-\d+$')]
    [string]$RespTask,

    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [ValidatePattern('^PF-TSK-\d+$')]
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
    [string]$Reason,

    [Parameter(Mandatory = $false, ParameterSetName = "SectionMove")]
    [string]$RejectionReason,

    # --- Annotation params (PF-IMP-832 (a)) — optional within StatusUpdate ---
    # Can be supplied alone (pure annotation: no status change) or alongside -NewStatus
    # (apply annotation, then perform the status transition). Pilot statuses are not
    # supported (7-col Active Pilots schema has no Resp Task column).

    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [string]$AppendNotes,

    [Parameter(Mandatory = $false, ParameterSetName = "StatusUpdate")]
    [ValidatePattern('^PF-TSK-\d+$')]
    [string]$SetRespTask,

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

function Write-Log {
    # Default-quiet logger. INFO/SUCCESS go to Write-Verbose (visible only with -Verbose).
    # WARN/ERROR are always emitted to host. The single per-invocation summary line
    # is emitted directly via Write-SummaryLine, bypassing this gate.
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    switch ($Level) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        default   { Write-Verbose $line }
    }
}

function Write-SummaryLine {
    # One-line visible outcome per invocation. Bypasses Write-Log's default-quiet gate.
    param([string]$Message, [string]$Level = "SUCCESS")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR"   { "Red" }
        "WARN"    { "Yellow" }
        default   { "Green" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    if (-not (Test-Path $TrackingFile)) {
        Write-Log "Tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # Validate required parameters for completion/rejection
    if ($NewStatus -in @("Completed", "Rejected")) {
        if (-not $ValidationNotes) {
            Write-Log "ValidationNotes is required when transitioning to $NewStatus" -Level "ERROR"
            return $false
        }
        if ($NewStatus -eq "Completed" -and -not $Impact) {
            Write-Log "Impact is required when transitioning to Completed (use HIGH/MEDIUM/LOW)" -Level "ERROR"
            return $false
        }
        # PF-IMP-852: Rejected routes to Section 7 — Rejected (7-col schema, no Impact column).
        # -Impact is silently ignored if supplied; emit WARN so callers can drop it from invocations.
        if ($NewStatus -eq "Rejected" -and $Impact) {
            Write-Log "-Impact is ignored when transitioning to Rejected (Section 7 schema has no Impact column)" -Level "WARN"
        }
    }

    # Validate required parameters for pilot resolution (PF-PRO-030, PF-IMP-729)
    # -Impact required (parallel to Completed). -ValidationNotes optional: required for fresh Active→Resolved
    # transitions (decision summary) but allowed to be empty for re-invocation/migration of already-resolved pilots
    # whose Notes column already contains the resolution narrative.
    if ($NewStatus -eq "Resolved" -and -not $Impact) {
        Write-Log "Impact is required when transitioning a pilot to Resolved (use HIGH/MEDIUM/LOW)" -Level "ERROR"
        return $false
    }

    # PF-IMP-832 (b): -LogToolChanges only valid with -NewStatus Completed
    if ($LogToolChanges -and $NewStatus -ne "Completed") {
        Write-Log "-LogToolChanges is only valid with -NewStatus Completed (got '$NewStatus'). The log-change call is bundled with the completion transition." -Level "ERROR"
        return $false
    }

    # PF-IMP-832 (c): -NewStatus Superseded requires -SupersededBy
    if ($NewStatus -eq "Superseded" -and -not $SupersededBy) {
        Write-Log "-SupersededBy is required when transitioning to Superseded (pattern: IMP-NNN, PF-IMP-NNN, or PF-PRO-NNN)" -Level "ERROR"
        return $false
    }
    # And -SupersededBy is only meaningful with -NewStatus Superseded
    if ($SupersededBy -and $NewStatus -ne "Superseded") {
        Write-Log "-SupersededBy is only valid with -NewStatus Superseded (got '$NewStatus')" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
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
        Write-Log "Pilot $ImprovementId not found in Active Pilots section" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    Write-Log "Found pilot entry for $ImprovementId"

    # Phase 7 pilot schema (central): | ID | Concept | Pilot Description | Project | Framework Version | Status | Notes |
    # Indices:                            0    1         2                    3         4                   5        6
    $columns = Split-MarkdownTableRow $currentEntry
    if ($null -eq $columns -or $columns.Count -ne 7) {
        $actualCount = if ($null -eq $columns) { 0 } else { $columns.Count }
        Write-Log "Malformed pilot row for $ImprovementId`: expected 7 columns (Phase 7 central schema), found $actualCount." -Level "ERROR"
        Write-Log "Raw row: $currentEntry" -Level "ERROR"
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

    Write-Log "Updated pilot $ImprovementId status to: $displayName" -Level "SUCCESS"
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
        Write-Log "Proposals directory not found: $proposalsDir" -Level "WARN"
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
        Write-Log "Concept $ConceptId not found in $proposalsDir (may already be archived). Skipping concept archive." -Level "WARN"
        return $true
    }

    $oldDir = Join-Path $proposalsDir "old"
    if (-not (Test-Path $oldDir)) {
        New-Item -ItemType Directory -Path $oldDir -Force | Out-Null
    }

    $destPath = Join-Path $oldDir (Split-Path $sourcePath -Leaf)
    if (Test-Path $destPath) {
        Write-Log "Concept $ConceptId already exists at archive destination: $destPath. Manual cleanup required." -Level "WARN"
        return $false
    }

    if ($PSCmdlet.ShouldProcess($sourcePath, "Move concept $ConceptId to proposals/old/")) {
        Move-Item -Path $sourcePath -Destination $destPath -Force
        Write-SummaryLine "Archived concept $ConceptId to $destPath"
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
        Write-Log "Pilot $ImprovementId not found in Active Pilots section for move" -Level "ERROR"
        return $null
    }

    # Build composite Description: keep the concept reference + the pilot description text
    $pilotDescription = $row.'Pilot Description'
    $description = "Pilot ($($row.Concept)): $pilotDescription"

    # Resolve Implementing Task: explicit parameter wins; otherwise regex-extract from the
    # Pilot Description text (New-ProcessImprovement.ps1 -AsPilot embeds the originating task
    # as "Pilot of <PF-PRO-NNN> (from <PF-TSK-NNN>)"); fall back to PF-TSK-026 (typical owner).
    if (-not $ImplementingTask) {
        if ($pilotDescription -match '\(from\s+(PF-TSK-\d+)\)') {
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
        Write-Log "Failed to move pilot $ImprovementId to Completed section (archive)" -Level "ERROR"
        return $null
    }

    Write-Log "Removed $ImprovementId from Active Pilots"
    Write-Log "Added $ImprovementId to archive § Section 6 — Completed (Resolved From: Active Pilot)" -Level "SUCCESS"
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
                Write-Log "Improvement $ImprovementId is already in the $sectionShortName section (archive). To reopen, manually move the row from the archive file back to a live triaged section first." -Level "ERROR"
            }
            "Intake"       { Write-Log "Improvement $ImprovementId is in the Intake section. Triage it first via -MoveToSection before applying status updates." -Level "ERROR" }
            "ActivePilots" { Write-Log "Improvement $ImprovementId is in the Active Pilots section. Use the pilot statuses (-NewStatus Active|Resolved) instead." -Level "ERROR" }
            "NotFound"     { Write-Log "Improvement entry not found in any section: $ImprovementId" -Level "ERROR" }
            default        { Write-Log "Improvement $ImprovementId is in section '$sectionShortName'; in-place status flips apply only to Improvements / Extensions / Structural Changes." -Level "ERROR" }
        }
        return $null
    }

    $sectionHeading = $script:CentralSectionHeadings[$sectionShortName]
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section $sectionHeading -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1

    if (-not $row) {
        Write-Log "Improvement entry not found in $sectionHeading (post-detect re-read failed): $ImprovementId" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    Write-Log "Found improvement entry for $ImprovementId in section: $sectionShortName"

    # Phase 7 (Session 11, 2026-05-11): all three triaged sections share the 10-col schema.
    # Parse columns: | ID | Source | Description | Project | Framework Version | Priority | Status | Resp Task | Last Updated | Notes |
    # Indices:        0    1        2             3         4                   5          6        7           8              9
    $columns = Split-MarkdownTableRow $currentEntry
    if ($null -eq $columns -or $columns.Count -ne 10) {
        $actualCount = if ($null -eq $columns) { 0 } else { $columns.Count }
        Write-Log "Malformed table row for $ImprovementId`: expected 10 columns (Phase 7 central schema), found $actualCount. Check for unescaped pipe characters in cell content. Escape literal pipes as '\|' (preferred — markdown table escape, supported by Split-MarkdownTableRow per PF-IMP-603) or '&#124;' (HTML-entity fallback)." -Level "ERROR"
        Write-Log "Raw row: $currentEntry" -Level "ERROR"
        return $null
    }

    # Update Status (idx 6) and Last Updated (idx 8)
    $displayName = $StatusDisplayNames[$NewStatus]
    $columns[6] = $displayName
    $columns[8] = $CurrentDate

    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated $ImprovementId status to: $displayName (section: $sectionShortName)" -Level "SUCCESS"
    return $result
}

function Update-AnnotationInPlace {
    # PF-IMP-832 (a): edits Notes column (idempotent append) and/or Resp Task column on a row
    # in one of the 10-col triaged sections (Improvements / Extensions / Structural Changes).
    # PF-IMP-1007 extends this with -EditDescription / -EditNotes (idempotent REPLACE of the
    # Description / Notes columns).
    # Returns the modified $Content (or original $Content unchanged if every requested edit
    # was a no-op per idempotency, or $null on failure). Last Updated is bumped only when
    # at least one column actually changed.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$ImprovementId,
        [string]$AppendNotes,
        [string]$SetRespTask,
        [string]$EditDescription,
        [string]$EditNotes
    )

    $sectionShortName = Get-IMPCurrentSection -Content $Content -ArchiveContent $ArchiveContent -ImprovementId $ImprovementId
    if ($sectionShortName -notin @("Improvements", "Extensions", "StructuralChanges")) {
        Write-Log "Annotation only applies to IMPs in Improvements/Extensions/Structural Changes sections. $ImprovementId is in: $sectionShortName" -Level "ERROR"
        return $null
    }

    $sectionHeading = $script:CentralSectionHeadings[$sectionShortName]
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section $sectionHeading -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) {
        Write-Log "Annotation: $ImprovementId not found in section $sectionShortName (re-read failed)" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    $columns = Split-MarkdownTableRow $currentEntry
    if ($null -eq $columns -or $columns.Count -ne 10) {
        $actualCount = if ($null -eq $columns) { 0 } else { $columns.Count }
        Write-Log "Malformed table row for $ImprovementId in $sectionShortName`: expected 10 columns, found $actualCount." -Level "ERROR"
        return $null
    }

    $changed = $false

    # -AppendNotes: idempotent append to Notes (idx 9). "Already present" = literal substring match.
    if ($AppendNotes) {
        $existingNotes = $columns[9].Trim()
        $isEmpty = (-not $existingNotes) -or ($existingNotes -eq "") -or ($existingNotes -eq "—")
        if ((-not $isEmpty) -and $existingNotes.Contains($AppendNotes)) {
            Write-Log "AppendNotes: text already present in Notes for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[9] = if ($isEmpty) { $AppendNotes } else { "$existingNotes $AppendNotes" }
            $changed = $true
            Write-Log "Appended to Notes for $ImprovementId" -Level "SUCCESS"
        }
    }

    # -SetRespTask: replace Resp Task (idx 7). Skip if already equal.
    if ($SetRespTask) {
        $currentRespTask = $columns[7].Trim()
        if ($currentRespTask -eq $SetRespTask) {
            Write-Log "SetRespTask: Resp Task is already $SetRespTask for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[7] = $SetRespTask
            $changed = $true
            Write-Log "Set Resp Task to $SetRespTask for $ImprovementId (was: $currentRespTask)" -Level "SUCCESS"
        }
    }

    # PF-IMP-1007 -EditDescription: replace Description (idx 2). Skip if already equal.
    if ($EditDescription) {
        if ($columns[2].Trim() -eq $EditDescription) {
            Write-Log "EditDescription: Description already equals the supplied value for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[2] = $EditDescription
            $changed = $true
            Write-Log "Replaced Description for $ImprovementId" -Level "SUCCESS"
        }
    }

    # PF-IMP-1007 -EditNotes: replace Notes (idx 9). Skip if already equal.
    if ($EditNotes) {
        if ($columns[9].Trim() -eq $EditNotes) {
            Write-Log "EditNotes: Notes already equals the supplied value for $ImprovementId — skipping (idempotent)" -Level "INFO"
        } else {
            $columns[9] = $EditNotes
            $changed = $true
            Write-Log "Replaced Notes for $ImprovementId" -Level "SUCCESS"
        }
    }

    if (-not $changed) {
        # All annotation operations were idempotent no-ops; return unchanged content.
        return $Content
    }

    # Bump Last Updated (idx 8) since at least one column changed.
    $columns[8] = $CurrentDate

    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)
    return $result
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
            Write-Log "Improvement $ImprovementId is already in the Completed section (archive). The completion transition has already been applied — no action needed." -Level "ERROR"
        } else {
            Write-Log "Improvement $ImprovementId not found in $sourceHeading" -Level "ERROR"
        }
        return $null
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
        Write-Log "Failed to move $ImprovementId to Completed section (archive)" -Level "ERROR"
        if ($result.SourceRow) {
            Write-Log "Source row found but insertion failed. Check archive § Section 6 — Completed exists." -Level "ERROR"
        }
        return $null
    }

    Write-Log "Removed $ImprovementId from $sourceHeading"
    Write-Log "Added $ImprovementId to archive § Section 6 — Completed (Resolved From: $resolvedFromLabel)" -Level "SUCCESS"
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
        Write-Log "Superseded status only applies to IMPs in Intake / Improvements / Extensions / Structural Changes. $ImprovementId is in: $sourceShortName" -Level "ERROR"
        return $null
    }

    $sourceHeading = $script:CentralSectionHeadings[$sourceShortName]
    $sourceRows = ConvertFrom-MarkdownTable -Content $Content -Section $sourceHeading
    $existingRow = $sourceRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $existingRow) {
        Write-Log "Superseded: $ImprovementId not found in section '$sourceShortName' (re-read failed)" -Level "ERROR"
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
        Write-Log "Failed to move $ImprovementId to archive § Section 7 — Rejected (Superseded)" -Level "ERROR"
        return $null
    }

    Write-Log "Moved $ImprovementId from '$sourceShortName' to archive § Section 7 — Rejected (Superseded by $SupersededBy)" -Level "SUCCESS"
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
        Write-Log "Rejected status only applies to IMPs in Intake / Improvements / Extensions / Structural Changes. $ImprovementId is in: $sourceShortName" -Level "ERROR"
        return $null
    }

    $sourceHeading = $script:CentralSectionHeadings[$sourceShortName]
    $sourceRows = ConvertFrom-MarkdownTable -Content $Content -Section $sourceHeading
    $existingRow = $sourceRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $existingRow) {
        Write-Log "Rejected: $ImprovementId not found in section '$sourceShortName' (re-read failed)" -Level "ERROR"
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
        Write-Log "Failed to move $ImprovementId to archive § Section 7 — Rejected" -Level "ERROR"
        return $null
    }

    Write-Log "Moved $ImprovementId from '$sourceShortName' to archive § Section 7 — Rejected" -Level "SUCCESS"
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

    Write-Log "Counted $count items in Completed section" -Level "SUCCESS"
    return @{ Content = $newContent; ArchiveContent = $newArchive }
}

function Invoke-LogToolChanges {
    # PF-IMP-832 (b): invokes `python feedback_db.py log-change --batch -` with the supplied
    # JSON piped to stdin. Resolves feedback_db.py relative to this script's location:
    # scripts/update/Update-ProcessImprovement.ps1 → ../feedback_db.py. Same relative layout
    # in appdev (blueprint/process-framework/scripts/) and in rolled-out projects
    # (process-framework/scripts/).
    # Returns $true on success, $false on failure. Caller treats failure as a non-fatal WARN.
    param([string]$JsonPayload)

    $feedbackDb = Join-Path $PSScriptRoot ".." "feedback_db.py"
    try {
        $feedbackDb = (Resolve-Path -Path $feedbackDb -ErrorAction Stop).Path
    } catch {
        Write-Log "Could not resolve feedback_db.py at expected location ($feedbackDb): $($_.Exception.Message)" -Level "WARN"
        return $false
    }

    Write-Log "Invoking feedback_db.py log-change --batch with supplied JSON payload"
    # Pipe JSON to python stdin. PowerShell forwards $JsonPayload as text to the process.
    $JsonPayload | & python $feedbackDb log-change --batch -
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
        Write-Log "feedback_db.py log-change exited with code $exit. IMP move was preserved; re-run log-change manually with the same JSON to backfill the entry." -Level "WARN"
        return $false
    }

    Write-Log "feedback_db.py log-change succeeded" -Level "SUCCESS"
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
        Write-Log "Re-route from $SourceSection has no -RoutedBy and no source-section default — skipping audit-trail prefix" -Level "WARN"
        return $ExistingNotes
    }
    # Reason is informational. If missing, still record the re-route (audit-trail
    # integrity matters more than narrative); mark the gap with a greppable marker.
    if (-not $Reason) {
        Write-Log "Re-route from $SourceSection has no -Reason; recording prefix with '<no reason supplied>' marker (audit-trail preservation)" -Level "WARN"
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

function Test-PrerequisitesForMove {
    # Validates SectionMove parameter combinations and the tracking-file structure.
    param([string]$Content)

    if (-not (Test-Path $TrackingFile)) {
        Write-Log "Tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # Archive-split (2026-05-13): the SectionMove path may target Rejected,
    # which lives in the sibling archive file. Validate its existence up-front.
    if (-not (Test-Path $ArchiveFile)) {
        Write-Log "Archive file not found: $ArchiveFile. Sections 6 (Completed) and 7 (Rejected) live in this sibling file post-split." -Level "ERROR"
        return $false
    }

    if (-not (Test-IsCentralTrackingFile -Content $Content)) {
        Write-Log "Tracking file does not have the central 7-section structure ('## Section 1 — Intake' heading missing): $TrackingFile" -Level "ERROR"
        Write-Log "SectionMove operations require the centralized process-improvement-tracking.md (created in PF-PRO-029 Phase 2). Pass -TrackingFile <central-path> if running before Phase 7 cutover." -Level "ERROR"
        return $false
    }

    if ($MoveToSection -eq "Rejected" -and -not $RejectionReason) {
        Write-Log "-RejectionReason is required when -MoveToSection is 'Rejected'" -Level "ERROR"
        return $false
    }

    # PF-IMP-1005: on a re-route into Rejected (source != Intake), default the
    # audit-trail -Reason to -RejectionReason so the [REROUTED ...] Notes prefix
    # carries the real rejection reason instead of the "<no reason supplied>"
    # marker. No-op for Intake-source rejections (initial sort gets no prefix).
    if ($MoveToSection -eq "Rejected" -and -not $Reason -and $RejectionReason) {
        $script:Reason = $RejectionReason
        Write-Log "Defaulted -Reason to -RejectionReason for the re-route audit trail (PF-IMP-1005)" -Level "INFO"
    }

    if ($MoveToSection -in @("Improvements", "Extensions", "StructuralChanges")) {
        if (-not $Status) {
            $script:Status = "Needs Prioritization"  # default for triaged-section moves
            Write-Log "Defaulted -Status to 'Needs Prioritization' for triaged-section move" -Level "INFO"
        }
        if (-not $RespTask) {
            # Auto-derive Resp Task from destination section (the conventional owner).
            $script:RespTask = switch ($MoveToSection) {
                "Improvements"      { "PF-TSK-009" }
                "Extensions"        { "PF-TSK-026" }
                "StructuralChanges" { "PF-TSK-014" }
            }
            Write-Log "Defaulted -RespTask to '$RespTask' (conventional owner of $MoveToSection section)" -Level "INFO"
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
        Write-Log "$ImprovementId is already in section '$DestShortName' — no move performed" -Level "WARN"
        return @{ Content = $Content; ArchiveContent = $ArchiveContent }  # caller treats unchanged content as a non-failure no-op
    }

    # Refuse moves involving Active Pilots / Completed (specialized flows handle those).
    if ($SourceShortName -in @("ActivePilots", "Completed")) {
        Write-Log "$ImprovementId is in '$SourceShortName' section. SectionMove does not support sources of ActivePilots or Completed — those have specialized flows (use -NewStatus Active/Resolved for pilots; row stays in Completed once resolved)." -Level "ERROR"
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
        Write-Log "$ImprovementId not found in section '$SourceShortName' (re-read failed)" -Level "ERROR"
        return $null
    }
    $existingNotes = if ($existingRow.PSObject.Properties.Name -contains "Notes") { $existingRow.Notes } else { "" }

    $newNotes = Get-NotesWithReroutePrefix `
        -ExistingNotes $existingNotes `
        -SourceSection $SourceShortName `
        -RoutedBy $RoutedBy `
        -Reason $Reason

    $colSpec = Build-ColumnMappingForMove `
        -SourceShortName $SourceShortName `
        -DestShortName $DestShortName `
        -Priority $Priority `
        -Status $Status `
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
            Write-Log "Failed to move $ImprovementId from '$SourceShortName' to '$DestShortName'" -Level "ERROR"
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
            Write-Log "Failed to move $ImprovementId from '$SourceShortName' to '$DestShortName' (two-file)" -Level "ERROR"
            return $null
        }
        # Map the two-file results back to (main, archive) regardless of direction.
        $newMain    = if ($sourceInArchive) { $result.DestinationContent } else { $result.Content }
        $newArchive = if ($sourceInArchive) { $result.Content }            else { $result.DestinationContent }
    }

    Write-Log "Moved $ImprovementId from '$SourceShortName' to '$DestShortName'" -Level "SUCCESS"
    return @{ Content = $newMain; ArchiveContent = $newArchive }
}

# --- Main ---

function Main {
    # Normalize short-form IDs: IMP-063 → PF-IMP-063
    if ($ImprovementId -match '^IMP-\d+$') {
        $script:ImprovementId = "PF-$ImprovementId"
    }

    Write-Log "Starting Process Improvement Update - $ScriptName"
    Write-Log "Improvement ID: $ImprovementId"

    # --- SectionMove parameter set dispatch (PF-TSK-089 IMP Triage) ---
    if ($PSCmdlet.ParameterSetName -eq "SectionMove") {
        Write-Log "Move To Section: $MoveToSection"
        Write-Log "Tracking File: $TrackingFile"
        Write-Log "Archive File:  $ArchiveFile"

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
            Write-Log "Normalized -Status token to display form '$Status' (PF-IMP-1006)" -Level "INFO"
        }

        # PF-IMP-982: batch mode. Build the full ID list (-ImprovementId + -AlsoMoveIds),
        # normalize short IMP-NNN → PF-IMP-NNN, and de-dup. ($ImprovementId is already
        # normalized at the top of Main; $AlsoMoveIds are normalized here.)
        $batchIds = @($ImprovementId)
        if ($AlsoMoveIds) {
            foreach ($extra in $AlsoMoveIds) {
                $batchIds += if ($extra -match '^IMP-\d+$') { "PF-$extra" } else { $extra }
            }
        }
        $batchIds = $batchIds | Select-Object -Unique

        # -Retriage / explicit -RoutedBy conflict is a global param error (check once).
        if ($Retriage -and $RoutedBy -and $RoutedBy -ne "PF-TSK-089") {
            Write-Log "-Retriage implies -RoutedBy 'PF-TSK-089' but you supplied '$RoutedBy'. Choose one." -Level "ERROR"
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
            Write-Log "Located $id in section: $sourceShortName"

            if ($sourceShortName -eq "NotFound") {
                Write-Log "$id not found in any section of $TrackingFile / $ArchiveFile" -Level "ERROR"
                $failed += [pscustomobject]@{ Id = $id; Reason = "not found in any section" }
                continue
            }

            # PF-IMP-857: -Retriage is invalid for Intake-source moves (initial triage is
            # already attributed to PF-TSK-089). In a mixed batch this is a per-ID skip.
            if ($Retriage -and $sourceShortName -eq "Intake") {
                Write-Log "-Retriage is invalid for Intake-source moves ($id). The default Intake → triaged-section flow is already attributed to PF-TSK-089." -Level "ERROR"
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
                Write-Log "Resolved -RoutedBy to '$effRoutedBy' for $id (source '$sourceShortName')" -Level "INFO"
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
                Write-SummaryLine "$($noop -join ', ') already in '$MoveToSection' — no change" -Level "WARN"
            }
            if ($failed.Count -gt 0) {
                Write-SummaryLine "Batch move failed: $($failed.Count) ID(s) not moved ($(($failed | ForEach-Object { $_.Id }) -join ', '))" -Level "ERROR"
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
                Assert-LineInFile -Path $verifyFile -Pattern $rowPattern -Context "row for $($m.Id) in $verifyFile"
            }
        }

        if ($moved.Count -eq 1 -and $noop.Count -eq 0 -and $failed.Count -eq 0) {
            # Preserve the single-ID summary form.
            Write-SummaryLine "$($moved[0].Id) moved: $($moved[0].Src) → $MoveToSection"
        } else {
            $summary = "$(($moved | ForEach-Object { $_.Id }) -join ', ') moved → $MoveToSection ($($moved.Count) moved"
            if ($noop.Count -gt 0)   { $summary += "; $($noop.Count) no-op" }
            if ($failed.Count -gt 0) { $summary += "; $($failed.Count) failed" }
            $summary += ")"
            Write-SummaryLine $summary -Level $(if ($failed.Count -gt 0) { "WARN" } else { "SUCCESS" })
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
        Write-Log "-AppendNotes and -EditNotes are mutually exclusive (one appends to Notes, the other replaces it). Supply only one." -Level "ERROR"
        exit 1
    }

    # PF-IMP-832 (a): annotation-only mode. When -NewStatus is omitted but at least one of
    # -AppendNotes / -SetRespTask / -EditDescription / -EditNotes / -AnnotateAsRolledInto is
    # bound, run the annotation as a standalone edit (no status transition, no completion
    # move). At least one must be supplied.
    if (-not $NewStatus) {
        if (-not $AppendNotes -and -not $SetRespTask -and -not $EditDescription -and -not $EditNotes) {
            # -AnnotateAsRolledInto already folded into $AppendNotes above; if that fold
            # populated nothing (it can't, given the ValidatePattern), the user-visible
            # error still reads naturally.
            Write-Log "Must supply at least one of -NewStatus, -AppendNotes, -SetRespTask, -EditDescription, -EditNotes, or -AnnotateAsRolledInto" -Level "ERROR"
            exit 1
        }

        Write-Log "Tracking File: $TrackingFile"
        Write-Log "Archive File:  $ArchiveFile"

        if (-not (Test-Path $TrackingFile)) {
            Write-Log "Tracking file not found: $TrackingFile" -Level "ERROR"
            exit 1
        }
        if (-not (Test-Path $ArchiveFile)) {
            Write-Log "Archive file not found: $ArchiveFile" -Level "ERROR"
            exit 1
        }

        $content = Get-Content $TrackingFile -Raw
        $archiveContent = Get-Content $ArchiveFile -Raw

        if (-not (Test-IsCentralTrackingFile -Content $content)) {
            Write-Log "Tracking file does not have the central 7-section structure: $TrackingFile" -Level "ERROR"
            exit 1
        }

        if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Annotate $ImprovementId")) {
            return
        }

        # Annotation operates on §2-§4 rows only — never touches the archive.
        # We pass $archiveContent so Get-IMPCurrentSection can produce a precise
        # error message when the IMP turns out to be in the archive.
        $newContent = Update-AnnotationInPlace -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -AppendNotes $AppendNotes -SetRespTask $SetRespTask -EditDescription $EditDescription -EditNotes $EditNotes
        if ($null -eq $newContent) { exit 1 }

        if ($newContent -eq $content) {
            Write-SummaryLine "$ImprovementId annotation — no change (idempotent)" -Level "WARN"
            return
        }

        $newContent = Update-FrontmatterDate -Content $newContent

        Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
            Set-Content -Path $TrackingFile -Value $newContent -NoNewline
        }

        if (-not $WhatIfPreference) {
            $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
            Assert-LineInFile -Path $TrackingFile -Pattern $rowPattern -Context "row for $ImprovementId in $TrackingFile"
        }

        $annotations = @()
        if ($AppendNotes)     { $annotations += "Notes(append)" }
        if ($EditNotes)       { $annotations += "Notes(replace)" }
        if ($EditDescription) { $annotations += "Description(replace)" }
        if ($SetRespTask)     { $annotations += "Resp Task=$SetRespTask" }
        Write-SummaryLine "$ImprovementId annotated: $($annotations -join ', ')"
        return
    }

    Write-Log "New Status: $NewStatus"

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
        Write-Log "Archive file not found: $ArchiveFile" -Level "ERROR"
        exit 1
    }
    $content = Get-Content $TrackingFile -Raw
    $archiveContent = Get-Content $ArchiveFile -Raw
    $location = Test-ImprovementLocation -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId
    Write-Log "Located $ImprovementId in section: $location"

    # Validate status / location compatibility
    if ($isPilotStatus) {
        if ($location -ne "ActivePilots") {
            # PF-IMP-832 (d): surface the canonical non-pilot alternatives so the caller
            # knows what to retry with. Previously the error told them what was invalid
            # but not what to use instead (PF-IMP-804 friction).
            Write-Log "Pilot status '$NewStatus' is only valid for IMPs in the Active Pilots section. $ImprovementId is in: $location. For regular IMPs, use -NewStatus Completed (or Rejected/Deferred/Superseded)." -Level "ERROR"
            exit 1
        }
    } else {
        if ($location -eq "ActivePilots") {
            Write-Log "Status '$NewStatus' is not valid for pilots. Use Active or Resolved for IMPs in the Active Pilots section." -Level "ERROR"
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
                Write-Log "$ImprovementId is in Section 1 — Intake. Triage it first via -MoveToSection before applying status updates. (Supersession/Rejection are the only Intake-source operations.)" -Level "ERROR"
                exit 1
            }
        }
        if ($location -eq "NotFound") {
            Write-Log "$ImprovementId not found in any section of $TrackingFile" -Level "ERROR"
            exit 1
        }
    }

    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Update $ImprovementId to $NewStatus")) {
        return
    }

    # --- Annotation alongside status update (PF-IMP-832 (a)) ---
    # If -AppendNotes or -SetRespTask was supplied alongside -NewStatus, apply the annotation
    # to the source row BEFORE the status update / move. This ensures (a) in-place updates see
    # the new Notes/Resp Task in the same write cycle, and (b) Completed-transition moves fold
    # the new Notes into the synthesized destination row and use the new Resp Task as the
    # default Implementing Task. Pilots (7-col schema, no Resp Task column) are not supported.
    if ($AppendNotes -or $SetRespTask -or $EditDescription -or $EditNotes) {
        if ($isPilotStatus) {
            Write-Log "-AppendNotes / -SetRespTask / -EditDescription / -EditNotes / -AnnotateAsRolledInto are not supported for pilot statuses (Active Pilots rows have no Resp Task column and use a different schema)" -Level "ERROR"
            exit 1
        }
        $content = Update-AnnotationInPlace -Content $content -ArchiveContent $archiveContent -ImprovementId $ImprovementId -AppendNotes $AppendNotes -SetRespTask $SetRespTask -EditDescription $EditDescription -EditNotes $EditNotes
        if ($null -eq $content) { exit 1 }
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
                Write-Log "Pilot $ImprovementId already in Resolved status — skipping in-place update (migration path)" -Level "INFO"
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
                    Write-Log "Pilot $ImprovementId is improvement-origin (Concept = $($pilotRow.Concept)); no concept doc to archive — skipping archival step." -Level "INFO"
                } else {
                    Write-Log "Could not extract concept ID from pilot row Concept column. Manual concept archive may be required." -Level "WARN"
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
            Assert-LineInFile -Path $verifyFile -Pattern $rowPattern -Context "row for $ImprovementId in $verifyFile"
        }

        # Archive concept doc on Resolved (after tracking file is written, so a failure here doesn't leave inconsistent state)
        if ($NewStatus -eq "Resolved" -and $conceptId) {
            $archived = Move-ConceptToArchive -ConceptId $conceptId
            if (-not $archived) {
                Write-Log "Concept archive step had issues — manual review required" -Level "WARN"
            }
        }

        $pilotDisplay = $StatusDisplayNames[$NewStatus]
        if ($NewStatus -eq "Resolved") {
            Write-SummaryLine "$ImprovementId pilot → $pilotDisplay (moved to Completed Improvements)"
        } else {
            Write-SummaryLine "$ImprovementId pilot → $pilotDisplay"
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
            Write-Log "Completion transition not valid for $ImprovementId — found in section: $location. Expected one of: Current (Improvements) / Extensions / StructuralChanges." -Level "ERROR"
            exit 1
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
    if (-not $WhatIfPreference) {
        $verifyFile = if ($archiveTouched) { $ArchiveFile } else { $TrackingFile }
        $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
        Assert-LineInFile -Path $verifyFile -Pattern $rowPattern -Context "IMP row for $ImprovementId in $verifyFile"
    }

    # PF-IMP-832 (b): on Completed transition with -LogToolChanges, invoke feedback_db.py
    # log-change --batch -. Runs after the write so a log-change failure leaves the IMP
    # transition intact (caller can retry log-change manually).
    if ($isCompletion -and $LogToolChanges -and $NewStatus -eq "Completed") {
        Invoke-LogToolChanges -JsonPayload $LogToolChanges | Out-Null
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
    Write-SummaryLine "$ImprovementId → $outcome"
}

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
