# Cluster detection and consolidation craft

## Scope of scan

Intake + Improvements + Extensions + Structural Changes + Active Pilots. **Never scan
Completed or Rejected** — closed sections are historical interest only. Use
`Find-Improvement.ps1 -Keyword <topic> -Scope Open` — long Notes cells defeat plain line grep.

## The three-signal criterion (PF-IMP-850)

2+ open IMPs cluster only when **all three** hold:

1. **Same primary read-set** — the implementing agent would read the same files/scripts/
   templates/guides to evaluate and implement each.
2. **Linked decisions** — implementing IMP A meaningfully constrains how IMP B is implemented
   (one edit deletes sections another would patch; a new sub-rule contradicts another's
   removal; an architectural choice in one binds the next).
3. **Coherent scope** — the work forms one logical edit pass a single session can plan,
   execute, and validate without losing context.

Same-artifact reference alone is **not enough** — it is the easiest signal to spot and the
weakest on its own. This criterion replaced an older "same artifact + overlapping intent" rule
that over-fragmented by biasing on source-similarity rather than implementing-session
efficiency.

### Tension forces consolidation

When 2+ IMPs target the same artifact with **contradicting or tensioned intent** (one
streamlines a section another extends), they **must** cluster — regardless of count. The
implementing session is the only place the conflict resolves coherently; splitting them across
sessions produces incoherent successive edits (session 1 demotes callouts, session 2 adds a
callout violating the style session 1 just chose). Tension is a *stronger* clustering signal
than agreement. When consolidating a tensioned cluster, the umbrella's Description explicitly
names the conflict the implementing session must resolve.

### Self-identified clusters

Intake rows often propose their own clusters — Tools Review writes cluster hints into Notes
per its classify-and-register step's CROSS-ROW NOTES convention ("Cluster with X and Y filed
in this batch — one principle, three artifacts"). Treat a self-identified cluster as a
**strong hint, verified independently**: apply the three-signal criterion anyway — the rows'
relationship assessment is filing-time judgment, not verification. Precedent: independent
application upgraded two rows' own "no tension" self-assessment to genuine tension (three
rows colliding on one risk-classification paragraph), changing the consolidation from
convenient to mandatory.

### Fenced-out spillovers are not re-consolidated

When candidate rows were deliberately fenced out of an earlier consolidation (their Notes say
so), do **not** re-consolidate them even when all three signals appear present — the fence is
a human scoping decision, and re-merging undoes it. Emit a scheduling note instead ("batch
these in one sitting" in the affected rows' Notes) so one implementing session still takes
them together.

### Counts as a cluster

- Three fixes against the same validator surface — same read-set; the fixes interact; one
  edit pass.
- Two IMPs proposing similar audit-trail prefixes for different scripts — same pattern, likely
  a missing helper extraction; the session designs the helper once and applies it to both.
- One IMP removing a CRITICAL callout from a task step + one adding a CRITICAL sub-rule to the
  same step — tension rule.

### Does NOT count

- Two IMPs about the same file where one edits schema and the other a far-away validation
  surface — no linked decisions, no coherent pass.
- A script-regex IMP and a comment-typo IMP in the same file — shared read-set, unlinked
  decisions.

## Thresholds

- **2-IMP cluster** = a **flag** — record it in the session digest with the
  three-signal analysis; default to consolidation when all three signals are present, leave
  separate when one is weak.
- **3+-IMP cluster** = an **action** — recommend consolidation when the signals are met.
- **Tension** on the same artifact: cluster regardless of count.

## Cross-section edit-target overlap (PF-IMP-1239)

When an Intake row shares an edit target with a row already triaged into an open section
(Improvements / Extensions / Structural Changes), the default is **route-with-coordination-note**:
route the Intake row to its own destination and record the shared target in both rows' Notes so
the implementing session handles them together. Only **pull the triaged row back** (re-triage to
consolidate) when there is true tension — contradicting intent on the same target per the rule
above. A shared read-set alone does not justify disturbing an already-triaged row.

## Consolidation mechanism notes

Commands live in
[helpers-reroutes-troubleshooting.md](helpers-reroutes-troubleshooting.md) (two-step flow:
create-with-`-Supersedes`, then route). Craft rules:

- **Surface the constituents in the umbrella's Notes** (PF-IMP-1028): `-Description` is capped
  at 500 chars — theme only. Record `Constituents: <ID> (<one-line scope>), …` in Notes
  via `-Notes` at creation or `-AppendNotes` after (both uncapped), so the implementing session
  reads per-item scope directly instead of reconstructing it from superseded archive rows. A
  theme overrunning 500 chars means move detail to Notes, not truncate.
- **Consolidating a member that is itself an umbrella**: supersede the umbrella only — never
  re-supersede its constituents (`-Supersedes` skips already-rejected rows anyway). Carry the
  absorbed umbrella's constituent list forward by name into the new umbrella's Notes, so the
  chain stays readable two levels deep: the old constituents point at the absorbed umbrella,
  which points at the new one.
- **Destination is an independent decision from consolidation** — apply the classification
  decision tree to the cluster's *combined work scope*, never to the cluster shape.

## Worked examples (compressed)

**→ Extensions.** Three IMPs asking three `Update-*` scripts for the same audit-trail logging.
All three signals: one helper's signature is bound by all three call sites; designing it in
isolation over-/under-fits the others. Combined scope = new shared Common-ScriptHelpers
capability + three caller refactors → exceeds a behavior-preserving edit set → **Extensions**.
Counter-example: had the cluster been three identical regex fixes to **one** script, it would
route to Improvements — same cluster shape, different combined work.

**→ Not a cluster.** Two IMPs against distinct `Validate-StateTracking.ps1` surfaces (false
positive in one, missed drift in another). Shared file, but each surface is its own function
block — no linked decisions, weak coherent-scope. Route both to Improvements separately; if
implementation later finds shared helper code, the receiving task re-routes inline.

**→ Improvements.** Three IMPs on one startup script's error handling (silent failure, wrong
stream, wrong exit code). All three signals: the exit-code and error-emission choices interact;
one edit pass on the startup path. Combined scope = behavior-preserving multi-defect edit
against one existing script → **Improvements**. Cluster size does not determine destination.

**→ Structural Changes.** Three move/rename IMPs (directory rename, file centralization,
naming-convention normalization). Rename ordering, migration-entry shape, and rollout cadence
are interdependent → one Structure Change campaign with one rollout window.

**→ Tension.** One IMP demoting CRITICAL callouts in a task step + one adding a new CRITICAL
sub-rule to the same step. Forced cluster; umbrella Description names the demote-vs-extend
stance the implementing session must pick; combined scope is content edits → Improvements.
