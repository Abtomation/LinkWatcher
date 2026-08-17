# Edge cases — Process Improvement (PF-TSK-009)

Consult-on-stumble record for the Process Improvement task and this skill (PF-PRO-059
two-zone convention). Each entry is keyed to the situation in which it applies — read the
entry whose situation you are in; nothing here is part of the routine path. Any session may
append or rewrite entries autonomously per the workspace Standing Orders (an entry names its
provenance; the ~150-line promotion tripwire applies).

## Entering without a standard pre-routed IMP (claim-protocol forks)

**Situation**: at the select-improvement step, the work does not arrive as a free open row in
Section 2 — Improvements.

- **Deferred row**: confirm the recorded deferral condition is cleared before claiming.
- **Direct human request, no IMP minted**: if the workspace's Fast-Track Lane criteria hold
  (defined in its `CLAUDE.md`, where the workspace has that lane), take the Fast-Track lane
  and skip the IMP pipeline. For larger requests the human may authorize
  proceeding before an IMP exists — record the authorization in the session feedback form and
  file the IMP at finalization so the trail exists.
- **Improvement identified mid-session** (a first-class new purpose, not spillover): file via
  `New-ProcessImprovement.ps1`, get human authorization, record the triage decision with
  `Update-ProcessImprovement.ps1 -MoveToSection Improvements -Priority <High|Medium|Low>
  -AppendNotes "<authorization one-line>"`, then claim and continue — a separate IMP Triage
  session is not required for a single inline-authorized IMP.
- **Authorized cross-section override**: re-route into Improvements first
  (`-MoveToSection Improvements`), then claim.

All modes rejoin the normal claim protocol and problem verification once active — only the
origin differs.

## The recommended candidate is claimed or gone when you return to claim it

**Situation**: at the select-improvement step, the continuation candidate recommended at the
recommend-next-action step — open on the fresh read that chose it — is now In Progress under
a parallel session, or no longer in Section 2 at all.

Do not claim it, and do not silently substitute another row. Return to the
recommend-next-action step: re-run the recommendation from a fresh read and propose a new
candidate or finalization, so the human chooses again with current facts. (Provenance:
PF-FEE-1690, absorbed by PF-IMP-1780.)

## A row you hold is completed by another session before you execute

**Situation**: mid-session — typically at execution or at the completion move — a row this
session claimed In Progress turns out to have been completed (or rejected) by a parallel
session: the completion move errors that the row is no longer in Section 2, or the
concurrent-modification check at the execute step shows the target file already contains the
change.

Do not apply your approved edit — it would duplicate or fight the shipped content. Instead:
read the target file to see what actually shipped; verify it preserved any sibling change
this session already landed; then report the collision to the human partner with both scopes
(what shipped vs. what this session had approved) so any residual delta is re-scoped rather
than silently re-applied. (Provenance: PF-FEE-1715, absorbed by PF-IMP-1867.)

## The IMP is a consolidation umbrella whose Notes already quote the sources

**Situation**: at the review-source-feedback step, the row is a consolidation umbrella whose
triage Notes already quote the source findings verbatim.

The source read may be skipped — the quotes carry the finding. Keep the exception narrow:
still read the source when a design-decision record sits behind it (e.g. an evaluation
report's constraints section), which is precisely where the read adds information the quote
cannot. (Provenance: PF-IMP-1709 / PF-FEE-1651, absorbed by PF-PRO-059.)

## A reproduction probe fails against a reported tool behavior

**Situation**: problem verification (or a runtime-tool check) cannot reproduce a claimed
runtime behavior — a script error, a validator miss, a failing call.

A failed reproduction is inconclusive until you can explain what the reporter saw —
environment differences, discovery timing, or lazy skill registration can make a true claim
fail to reproduce. Worked incident: PF-IMP-1517 was rejected on two failed probes that lazy
skill registration later explained; the claim was substantially right.

## The absence test under pre-validated framing

**Situation**: an IMP carries `[HUMAN-CORRECTION]` provenance, a triage-endorsed fix, or
prior pre-analysis, and its framing feels already validated.

That is exactly when frame pressure is strongest — run the absence test with full force.
Worked incident (2026-07-21): a clean-room re-run under PF-IMP-1694's test protocol restated
the IMP's frame and reached the correct deletion outcome only through human reprompts, even
with the consumer-naming rule in context.

## A regex-bearing one-liner misbehaves when passed through `-Command`

**Situation**: an ad-hoc PowerShell one-liner carrying regex backslash classes (`\d`, `\s`,
`\w`, escaped metacharacters) is run via `pwsh -Command` and the pattern fails to match — or
matches wrongly — against text it visibly should match. The failure masquerades as a bad
regex.

The pattern was likely mangled in transit: a `-Command` argument crosses shell quoting and
native argument parsing before PowerShell parses it a second time, and backslash sequences
are a casualty class alongside the documented `$`/backtick loss (Script Development Quick
Reference § quote-heavy `-Command` hazard, PF-IMP-1809). Do not debug the regex in place —
write the one-liner to a scratch `.ps1` and run it via `-File` from the start; the scratch
file is disposed of at finalization cleanup like any other. Worked incident: three of one
session's `-Command` one-liners were mangled before the switch to scratch files, despite the
hazard being documented. (Provenance: PF-FEE-1725 / PF-IMP-1888.)

## A malformed row turns up in a tracking or state-file table

**Situation**: root-cause analysis on a corrupted row — truncated cells, shifted columns,
stranded prose below a table — in any tracking or state-file table, where the fix design
depends on how the row got there.

Provenance is settled by convention, not derivable from the tree: tracking and state-file
rows originate from script writes — humans do not hand-edit rows (human statement,
PF-FEE-1643), and an agent hand-repair is a rare, recorded recovery step. So diagnose the
writing script or its invocation (quote/newline mangling, cell-count drift), and read the
corruption as evidence about guard coverage: insertion-time checks (`Assert-TableRowInFile`,
header-driven row build) sit on the only write path, so a malformed row means a guard gap or
an unguarded writer — never a human typo. Scope: the convention covers tracking/state-file
tables; do not over-generalize it to "no file is ever hand-edited". Worked incident: two
newline-truncated Intake rows were necessarily script-written, which confirmed the
PF-IMP-1563 assert covers that failure mode and located the fix at the writing script's
parameter boundary (PF-IMP-1598). (Provenance: PF-FEE-1643 Human Intervention Log /
PF-IMP-1732.)

## Flagging a residual behavior choice at the decision review

**Situation**: the decision review flags a residual behavior choice — a defensible
either-way call the execution settled that the human might decide differently (e.g. which of
several fallback outcomes a missing config file takes).

State the choice as its triggering **condition** and how often that condition fires, not
just the chosen behavior — a bare "we chose X" gets approved without being understood.
While a choice is unpresented, do not take the skip tier: present that one choice even when
the change otherwise qualifies for skipping; on an autonomous run, record it in the
`[AUTONOMOUS]` ValidationNotes instead. Worked incident: a flagged three-outcome
language-config chain was approved, then the human said they had not understood it — the
session re-explained and held finalization so the choice stayed cheap to change.
(Provenance: PF-FEE-1717 / PF-IMP-1849.)

## A touched file shows ` D` in `git status` at finalization

**Situation**: the end-of-session existence check finds a file this session edited marked
deleted (` D`).

A concurrent session's deletion silently took your edits with it. Recover your content from
this session's edit history, then reconcile with the deleting session's intent before
re-writing — the deletion may be a legitimate retirement, in which case your change belongs
in the successor artifact (or nowhere), not in a resurrected copy.
