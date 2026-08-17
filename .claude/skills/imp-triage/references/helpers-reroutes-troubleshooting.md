# Helper invocation, re-route patterns, and troubleshooting

All commands run from the project root. The default `-TrackingFile` is the central 7-section
`process-improvement-tracking.md` (resolved via `Get-CentralFrameworkPath`) — pass it only to
override for tests or legacy layouts. The helper refuses (clear error) when the file lacks the
canonical `## Section 1 — Intake` heading.

## Initial sort from Intake

The typical invocation is short — the helper supplies smart defaults:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
    -ImprovementId "PF-IMP-NNN" \
    -MoveToSection "<Improvements|Extensions|StructuralChanges>" \
    -Priority "<High|Medium|Low>" \
    -Confirm:$false
```

Auto-defaults on Intake-source moves: `-Status` → `Needs Prioritization`; `-RespTask` → the
destination section's conventional owner (PF-TSK-009 / PF-TSK-026 / PF-TSK-014); `-RoutedBy` →
`PF-TSK-089`. No `[REROUTED …]` prefix is added (initial sort, not a re-route) — `-Reason`
feeds only that prefix, so it is ignored here; attach notes to a freshly-sorted row by passing
`-AppendNotes` in the same move call (PF-IMP-1393 (c) — appended to the moved row's Notes; in
an `-AlsoMoveIds` batch, every moved row gets it).

Routes to Rejected: drop `-Priority`, add `-RejectionReason "<one-line rationale>"`.

## Consolidation (two-step flow)

**Step A — create the umbrella in Intake, superseding the sources in the same call:**

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 \
    -Source "PF-TSK-089 cluster consolidation" \
    -Description "<theme of the combined work scope (500-char cap)>" \
    -Notes "Constituents: <ID> (<one-line scope>), ..." \
    -Supersedes "PF-IMP-AAA, PF-IMP-BBB" \
    -Confirm:$false
```

Composing a long `-Description`? Measure before invoking — `('<text>').Length` must be
10–500, and the binder rejects an over-cap value only *after* the whole multi-KB command line
is composed and fired (two such wasted round trips recorded, PF-IMP-1832). Over the cap:
compress and move detail to `-Notes` (uncapped).

Each superseded source moves to Section 7 — Rejected with `Status = "Superseded"` and
`Rejection Reason = "Superseded by <new-ID>"` — closed by section membership, not Notes
annotation. Pilots and already-rejected sources are warned and skipped (the umbrella is still
created). Idempotent on re-run: already-superseded rows fail at the source-section gate with
warnings, no state corruption.

**Step B — route the umbrella** out of Intake with the initial-sort command above, to whatever
section the combined work scope warrants.

## Re-route from a triaged section (downstream tasks, inline)

Same helper, invoked by PF-TSK-009/014/026 when a picked-up IMP turns out mis-scoped — no
separate triage session:

```bash
... -ImprovementId "PF-IMP-NNN" -MoveToSection "<destination>" -Priority "<preserved-or-adjusted>" \
    -Reason "<scope-mismatch rationale>" -Confirm:$false
```

The helper auto-defaults `-RoutedBy` from the source section's conventional owner and
auto-prepends `[REROUTED YYYY-MM-DD by PF-TSK-NNN: <reason>]` to Notes. Three legitimate
patterns:

- **A: Improvements → StructuralChanges** — work turns out to require moves/reorg.
- **B: Improvements → Extensions** — proper fix requires multiple new artifacts.
- **C: any open section → Rejected** — merit-based rejection by the *receiving* task
  (`-RejectionReason` carries the rationale). **Anti-pattern**: triage itself rejecting on
  merit — triage's only rejection grounds are already-resolved, duplicate-of-open
  (consolidate instead), or out-of-scope misfile.

Override case: triage re-evaluating a triaged row in a follow-up session passes
`-RoutedBy "PF-TSK-089"` explicitly.

## Bulk triage

**Same destination + same options** — one call via `-AlsoMoveIds` (PF-IMP-982): each ID's
source section resolves independently; a not-found/failed ID is reported and skipped without
aborting the rest. Pass the extra IDs as one comma-separated string — it survives `pwsh -File`'s
literal-token binding (split-in-place, PF-IMP-1830), so the preferred `-File` form works:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-800" -AlsoMoveIds "PF-IMP-801,PF-IMP-803" -MoveToSection "Improvements" -Priority "Medium" -Confirm:\$false
```

**Mixed destinations or per-row priorities** — loop per row and verify Intake afterward
(failures abort one row, they don't roll back prior moves):

```powershell
foreach ($imp in @(
    @{ Id = "PF-IMP-800"; Section = "Improvements"; Pri = "Medium" },
    @{ Id = "PF-IMP-802"; Section = "Rejected";     RejReason = "Duplicate of PF-IMP-650" }
)) {
    if ($imp.Section -eq "Rejected") {
        & $helper -ImprovementId $imp.Id -MoveToSection $imp.Section -RejectionReason $imp.RejReason -Confirm:$false
    } else {
        & $helper -ImprovementId $imp.Id -MoveToSection $imp.Section -Priority $imp.Pri -Confirm:$false
    }
}
```

`-WhatIf` on any invocation previews the move without writing — useful when source-section
identification is uncertain.

## Evidence access from cwd=appdev

Triage may need project files to confirm a duplicate or sanity-check a classification. Resolve
the row's `Project` column through the registry — no cwd switching:

```powershell
$registry = Get-Content "process-framework-central/project-registry.json" | ConvertFrom-Json
# Producer-attributed rows — "FWK-APP (appdev)", or the historical pre-P-13 label
# "PRJ-000 (appdev)" — are THIS workspace: no registry row exists for them (PF-PRO-068 P-13)
if ($row.Project -match '^(?:FWK-|PRJ-000\b)') { $projectPath = (Get-Location).Path }
# "APP-002 (Name)" → APP-002 → absolute project root
elseif ($row.Project -match '^([A-Z]{2,4}-[A-Z]*\d+)') { $projectPath = $registry.projects.($matches[1]).path }
```

## Troubleshooting

| Symptom | Cause → fix |
|---|---|
| "Tracking file does not have the central 7-section structure" | Wrong `-TrackingFile` override, or the central file's `## Section 1 — Intake` heading was damaged → verify path / section headings |
| "PF-IMP-NNN not found in any section" | Typo or an ID that never existed — an already-archived ID reports its actual section instead (PF-IMP-1393 (a)) → grep the central file and its archive for the ID first |
| Re-route prefix reads `<no reason supplied>` | Caller omitted `-Reason` — move succeeded, audit trail records who/when; hand-edit Notes if the why matters |
| Re-route prefix missing entirely | `-RoutedBy ""` with an unrecognized source section → re-invoke with explicit `-RoutedBy "<task ID>"` |
| Missed an obvious duplicate (both now in open sections) | Same-session fix: `New-ProcessImprovement.ps1 -Supersedes "A, B"` → classify + route the umbrella; mention at the checkpoint |
| "already in section X — no change" (WARN, exit 0) | Re-run of an applied move — desired state already achieved, continue |
| `-SetRespTask` / `-SetPriority` / `-EditNotes` / `-EditDescription` refuses an Intake or Active Pilots row | Those sections are 7-col and have no Resp Task / Priority column, so only `-AppendNotes` applies there (PF-IMP-1570) → move the row to a triaged section first (`-MoveToSection`), or hand-edit. `-AppendNotes` itself works on every section — every live one (including pilot trial-evidence appends) and already-archived Completed / Rejected rows (PF-IMP-1719). On a triaged row, `-SetPriority` is also the way to re-prioritize without a move — a same-section `-MoveToSection` no-ops (PF-IMP-1885) |
| `Project` column blank/malformed | Hand-edit to `APP-NNN (current-name)`; if truly unknown, the filing workspace's own label — config `project_id` + name, e.g. `FWK-APP (appdev)` — keeps the row parseable (pre-P-13 rows carry the historical `PRJ-000 (appdev)` with the same meaning) |
