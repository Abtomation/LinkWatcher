# Classification detail and priority inputs

## Ownership check (Rule 0)

Runs before everything else, including reconciliation: *whose artifact is this?* In a portfolio
of federated workspaces, a finding about an artifact this workspace merely **received** cannot be
fixed here — the canonical copy lives at the owning workspace, and a local edit is reverted by the
next sync. The row belongs in the owner's queue, not ours.

**Resolving the home tree**, cheapest signal first:

1. **The artifact's own ownership line.** Every shipped file names its owner in its header — a
   PowerShell `.NOTES` `OWNERSHIP:` line, a Python header comment, markdown frontmatter
   `owned_by:`, JSON `metadata.owned_by`. Read it directly, or resolve it with
   `Get-ArtifactOwnerId -Path <file>` (Common-ScriptHelpers). This is the authoritative answer
   whenever the row names a concrete file.
2. **No ownership line** → the artifact is this workspace's own. Unmarked means unshipped, which
   means local. Classify normally.
3. **The row names no file** (a process complaint, a workflow gap, a "the task should say X"
   finding). Resolve the *task or guide* it targets and read that artifact's ownership line —
   findings about a task are findings about the file that defines it.

**Ambiguity escalates by default**, and the asymmetry is why: escalating something local costs
one hand-back row in someone's Intake, while claiming something foreign produces an edit against
a received copy — work that looks done, passes review, and is silently overwritten at the next
sync. The cheap error is the recoverable one.

**Escalate the finding, not a decision.** The row lands in the owner's *Intake*, unclassified:
the owner has the context this workspace lacks (its own coverage sources, its own open clusters,
its own priorities). Supply a `-Reason` naming **why that workspace owns the artifact** — the
receiving triage's first question is "why is this mine?", and the audit prefix is where it looks.
Do not pre-assign priority or destination section on the owner's behalf.

**Do not escalate**: rows already Completed/Rejected (they have reached an outcome), Active
Pilots rows (their lifecycle cannot be continued elsewhere), or a row whose finding is genuinely
about *this* workspace's use of a foreign artifact rather than the artifact itself — e.g. "our
binding for the shared skill points at the wrong path" is local, while "the shared skill's
instructions are wrong" is the owner's.

## Reconciliation check (before decision-tree Rule 1)

"Already resolved" is the most common way a stale IMP slips through and burns a downstream
claim/verify cycle (PF-IMP-1004). Before routing, quick-check the row against four coverage
sources that are **not** open IMPs:

1. **Recently-completed IMPs** — Section 6 (Completed) in the archive file. Search it for the
   **named artifact** (script or file name) in the row's description, not only topic keywords
   (`Find-Improvement.ps1 -Keyword <artifact-name>`) — two rows describing the same defect
   often share the filename while sharing no topic wording. When the hit is a
   `Superseded by <umbrella-ID>` row, follow the pointer: the umbrella's completed row carries
   a `[CONSTITUENT PF-IMP-NNNN: …]` disposition marker per constituent, and
   `dropped — do not re-file` (like `[DEAD PREMISE]`) rejects the resurfacing row on sight —
   the bare supersession pointer alone does not mean the constituent shipped. Those markers are
   **terminal** reasons; a **conditional** rejection reason — correct when recorded, premised
   on a state of the world — is verified against current reality before the rejection is
   treated as terminal: an expired condition makes the resurfacing row a legitimate *revival*,
   not a duplicate. Tools Review marks the write side with `[REVIVES PF-IMP-NNNN]`, quoting
   the recorded reason — spot-check its premise like any load-bearing specific.
2. **Pending-migration entries** — `per-project-migrations/<PROJECT-ID>/pending-migrations.md`
   (the fix may already be queued or applied as a migration).
3. **Shipped `blueprint/` changes** — the same artifact already corrected in
   `blueprint/process-framework/`.
4. **Validate-StateTracking surfaces** — a check that already covers the reported condition.

Additionally, **spot-check one load-bearing specific** the IMP leans on — a named
parameter/flag, a validator surface label, a file/line claim — against the canonical
`blueprint/process-framework` source (PF-IMP-1162). A specific that no longer matches source
is a staleness signal that mandates a closer look — not disproof of the row: a row's stated
evidence and its stated mechanism fail **independently**, so check whether the described
mechanism and impact still hold before rejecting (PF-IMP-1579's evidence line was false while
its mechanism was correct and its impact verified).

**Outbound pointers resolve at read time** (PF-IMP-1814): before inheriting a row's own
"coordinate / depends on / see PF-IMP-NNNN" pointers into a routing or pairing note, run the
exact-ID lookup (`Find-Improvement.ps1 -Keyword <row-id>`) and read its `ref:` lines — every
id the row references prints with its current section and state. A pointer resolving to a
Completed / Rejected / Superseded row is stale, and one whose resolved description does not
match the claim is mis-aimed (the off-by-one variant) — correct it in the row's Notes at
triage rather than carrying it forward.

If covered: route to **Rejected** with `Rejection Reason = "Already resolved/covered by
<ref>"`. This is the already-resolved judgment triage owns — not merit evaluation.

## Edge-case routing table

| If the IMP says… | Route | Why |
|---|---|---|
| "Add a new column to feature-tracking.md" | Structural Changes | Schema **reshape of an existing** working doc → migration entries needed |
| "Add a *new* per-project config file that ships migration entries" | Extensions | New capability addition; the migration signal does **not** override that (PF-IMP-990) |
| "Fix the regex in `Validate-StateTracking.ps1` Surface 6" | Improvements | Behavior-preserving framework script edit |
| "Create a new task for Y workflow" | Extensions | New task definition; Resp Task = section owner **PF-TSK-026** (authors via PF-TSK-001 as a sub-task), never the section-less PF-TSK-001 (PF-IMP-990) |
| "Improve the wording of PF-TSK-009's evaluation step" | Improvements | Content edit to an existing task |
| "Move PF-TSK-XXX from `support/` to `cyclical/`" | Structural Changes | File move with cross-references to update |
| "Pilot the X proposal" | (don't route) | Pilots enter Active Pilots directly via `New-ProcessImprovement.ps1 -AsPilot`, filed by the originating task — never through Intake |

## Common ambiguous pairs

- **Improvement vs Structural Change** — "moves a section heading and rewrites the surrounding
  text": if the heading move is load-bearing → Structural Change; if the rewrite is
  load-bearing and the move incidental → Improvement.
- **Improvement vs Extension** — "adds a `-NewFlag` parameter to an existing script": if the
  new behavior is a meaningful workflow on its own → Extension; a small variation on existing
  behavior → Improvement.

Route genuinely balanced calls on your recommendation and name them individually in the
session digest with both options and the rationale for the pick.

## Priority inputs (evidence-adjusted preliminary read)

Triage sets a *starting* priority; the receiving task adjusts during its own evaluation.

### Human-correction provenance (`[HUMAN-CORRECTION]`)

Tools Review appends `[HUMAN-CORRECTION]` to the Notes of any IMP drained from a feedback
form's Human Intervention Log. These mark moments the framework demonstrably failed in-session
— the highest-trust improvement signal the pipeline carries.

**Rule**: a marked row starts **one priority level above** the otherwise-preliminary read
(Low → Medium, Medium → High). Booster sets the starting point, not the ceiling.

### Recurrence provenance (`[RECURRENCE of PF-IMP-NNN]`)

Tools Review appends `[RECURRENCE of PF-IMP-NNN]` when its intake dedupe hits a **Completed**
archive row whose symptom re-appeared after the fix took effect — the fix demonstrably failed
to prevent recurrence, and the named row hands the implementing session the failed fix to
study rather than rediscover.

**Rule**: same one-level boost as `[HUMAN-CORRECTION]`. Spot-check the token's premise like
any load-bearing specific: the observation must postdate the fix reaching the observing
project (completion date for appdev-origin forms, first rollout to that project otherwise) —
if it doesn't, the row is a plain duplicate of resolved work → Rejected per the
reconciliation check.

**Class-kill routing instruction (PF-PRO-059)**: a verified recurrence — or any
reconciliation-check hit showing a prior *completed* same-shape fix whose class re-surfaced —
routes with an explicit instruction appended to Notes: *"Two strikes on this class — receiving
task proposes a detector/assert/gate that kills the class, not another instance fix."* Prose
has already failed once; routing it as another instance-fix invites a third strike.

### Ratings-trend evidence (`feedback_db.py`)

Default posture: **no routine sweep.** Reach for ratings evidence only where a row's priority
is genuinely contested — drill down on that one tool:

```bash
python process-framework/scripts/feedback_db.py report --tool <tool_doc_id>
```

Read the report for two signals:

- **Chronic vs one-off** — low dimension averages across several cycles → chronic, boost
  priority. A single low rating against a stable-high history → one-off complaint, temper the
  read (the receiving task's problem verification catches it if real).
- **Post-change regression** — the report interleaves `log-change` entries between rating
  cycles; ratings dropping in the cycles *after* a logged change suggest that change regressed
  the tool. Boost priority and name the suspect change in the row's Notes.

The tool key is the canonical `tool_doc_id` (task ID for task definitions, filename for
everything else) — verify with `feedback_db.py list-tools --filter <substring>` when unsure.
