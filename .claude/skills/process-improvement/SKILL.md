---
name: process-improvement
description: >-
  Craft for executing framework Process Improvement (PF-TSK-009) sessions well — the judgment
  half of the task: the reasoning behind its evaluation and checkpoint gates (conciseness,
  minimum-viability, root-cause-vs-symptom, prevention, data-driven validation, solution exploration,
  counter-proposal evaluation, fold-into-sibling, reclassification), function-first problem
  identification, non-standard entry modes, execution
  safeguards for risky change shapes, plus worked examples and troubleshooting. Activated only
  from the Process Improvement task's Check-Recommended-Skills step (via recommended_skills);
  not a product-code improvement skill.
user-invocable: false
---

# Process Improvement Craft

This skill owns the **craft** of the Process Improvement task — the reasoning behind its gates,
so edge cases the literal rules don't cleanly cover are decided by **intent**, not mechanical
rule application. The **task (PF-TSK-009)** owns everything else: the 17-step process, the
gates as operative rules, checkpoints, risk classes, tracking updates, and the feedback form.
Its **reference companion** (lookup tables — problem-verification notes, evaluation criteria,
routing, risk classification, stale-description sites, TOOL_DOC_ID, constituent
disposition) stays a separate agnostic
document; do not duplicate it.

> **Division of labor.** The task owns process; this skill owns judgment. Nothing here
> overrides a checkpoint — gate surfacing happens at the task's approach checkpoint (Step 6),
> and approval outcomes stay with the human partner.

## Gate rationales (decide edge cases by intent)

The operative rules live in the task's Step 6 and the reference companion's evaluation gates;
each entry below carries only its trigger anchor, the why, and the edge calls — new craft
lands as a decision input inside an existing entry, never as a new block.

**Conciseness rule** *(Step 3; all-favorable → one line)* — *Why*: the full table obscures the
decision when the answer is "all good, here's the approach"; the table is for when the
analysis itself is the point. *Edge*: a borderline criterion goes into the one-line summary —
the rule removes redundancy, never nuance.

**Minimum-viability gate** *(fires on "Yes" / "Not Explored")* — *Why*: IMPs often propose a
structural fix where a doc-only or warning-only change resolves the same friction; even when
the lighter option loses, the comparison disciplines the choice, and "Not Explored" gets the
same treatment — absent exploration is indistinguishable from absent existence. An existing
mechanism-level fail-safe that already makes the failure loud and bounded weights the
comparison toward the do-nothing/minimal variant: the residual risk the change would remove
is small by construction. *Edge*: if the simpler alternative already failed in a prior IMP,
cite that IMP — the gate satisfies itself with evidence, not ceremony. **Minimal mechanism,
full extent (PF-PRO-059)**: minimality constrains the *mechanism* (the lightest change shape
that solves it), never the *extent* — shrinking the site count is not "more minimal", it is an
incomplete fix.

**Root-cause-vs-symptom gate** *(fires on "Symptom-only")* — *Why*: the telltales go beyond
flag-shaped framings ("add a flag to disable X", "let callers skip Y" — where the *default* of
X/Y is usually the actual bug): making a tool more flexible so a mis-sequenced workflow can
keep its shape is also a symptom fix — before flexing the tool, ask whether the workflow
visits it at the wrong moment. When naming the underlying defect, also name which layer of the
causal chain the fix addresses — process gap, mechanism gap, or whether the defect class even
persists: a layer left to improvisation (a mechanism gap "covered" by prose-only guidance) is
weaker than one addressed directly. *Edge*: an out-of-reach root cause (third party, external
dependency) is named as such — the gate's job is articulation, not resolution.

**Prevention gate** *(fires on a named upstream gap)* — *Why*: Root-Cause Targeting is
first-order — it judges the fix; without a second-order question, closing the *class* of a
defect happens only when an agent spontaneously notices or a recurrence forces a new IMP.
**Two-strikes class-kill (PF-PRO-059)**: a prior *completed* fix for the same defect class
means prose has already failed once, so the answer is structural rather than a second prose
round — the recognizable-stumble exception is the destination axis under *Solution
exploration*. *Silence default*: a step that demands content invites fabricated gaps.

**Data-driven validation gate** *(fires on "Analyzed")* — *Why*: intuition-born IMPs can read
as obviously correct and be wrong against data — precedent: a feedback-DB query showed a
friction appeared in <2% of sessions while the proposed fix taxed all of them. *Edge*: "No
Data Available" is acceptable — the gate forbids ignoring available data, not manufacturing
it.

**Solution exploration** *(Step 6, before proposing)* — *Why*: without explicit exploration
the first viable approach becomes the chosen approach; the MVP asks "is doing nothing
structural enough?", the radical option asks "what would solving this properly look like?"
(weighted by benefit ceiling, not effort cost). Choose the *dimension* of variation
deliberately — variants generated inside the IMP's own proposed mechanism inherit its
framing, and the IMP's **shape** names the dimension that framing hides:

- **Workflow-shaped** (context switches, round trips, task/session handoffs): the radical
  alternative re-sequences the process itself — enumerate each operation's true preconditions
  and genuine context requirement, then reorder to minimize transitions — before any tool is
  made more flexible.
- **Defect-shaped** (a verified mechanism defect with a known fix): the space may be
  legitimately one-dimensional — state that rather than manufacture a third mechanism; a
  filler option makes the checkpoint look like a choice that isn't.
- **Convention-shaped** (the IMP patches an artifact to fit a convention): one explored option
  questions the convention itself — the friction may be evidence against the rule, not
  against the artifact.
- **Conflict-shaped** (artifacts state incompatible rules): one explored option eliminates the
  contradiction at its source — never only rank the documents; a precedence rule leaves both
  texts standing and the conflict alive.
- **Contract-level** (cuts across the shapes): when every option patches inside the same
  frame, re-question the responsibility of the artifact the IMP assumes is fixed — redefining
  who owns the step can dissolve the defect instead of patching it.

*Destination is a separate axis from shape*: where a workspace runs the two-zone edge-case
convention, an additive guidance IMP has one survivor routing the addition to the owning task's
edge file rather than core — decided by the *boundary rule*: core keeps the happy path and
load-bearing rules; anything conditional on a rare recognized situation is edge material. The
test for edge-vs-detector is recognizability: the agent must be able to *know* it is in the
documented situation (an error text, an unexpected state, an explicit fork) — otherwise
two-strikes applies and the fix is a detector.

*Edge*: a pre-rejected idea presented as an alternative costs a round trip — a survivor is an
option you would implement if the human selected it.

**Counter-proposal evaluation** *(Step 6, when your approach materially differs)* — *Why*: the
counter-proposal is also raw input — shaped by the agent's read, not independent verification;
without parallel scrutiny it sneaks in via authority. Verify its enabling premises against the
live tree the same way the IMP's were — for any option acting on an existing mechanism, name
what consumes that mechanism and check the premise holds today, not merely plausibly: that a
task the proposal *relocates* work to actually performs it, that a mechanism it *replaces*
feeds no consumer depending on the output semantics it would change, that one it *removes*
feeds none at all. Watch Recurring Value (useful across future sessions, or ceremony?) and
Minimum Viability (would leaving it alone work?). *Edge*: a strictly-narrower counter-proposal
(scope reduction) just notes the reduction — the gate is for materially different approaches.

**Fold-into-sibling outcome** *(Step 6, an open sibling owns the decision)* — *Why*: distinct
from Step 2's Superseded case: there the problem is already gone; here it is real, but
building would pre-empt the sibling's design authority. *Why the findings-carry matters*: the
row archives into the Rejected section, which nobody re-reads — carry the verification
findings onto the absorbing
IMP's Notes (`-AppendNotes`) before superseding, or the sibling re-does (or worse, never sees)
the session's analysis. *Edge*: if the sibling is stale (Completed or Rejected since the
coordination note was written), the fold target is gone — re-evaluate on this IMP's own
merits instead.

**Reclassification heuristic** *(Step 6)* — reclassify by **what the corrective fix changes**,
not the symptom's directory (per the Issue Classification and Routing Guide). *Why*: intake
framing is often product-shaped while the underlying issue is framework-shaped, or vice versa.
*Edge*: cross-path cases (a framework script operating on `src/`, a project artifact whose
*structure* is template-imposed) are decided by the artifact being fixed.

## Function-first problem identification (Step 2)

An IMP frames its own problem, and the frame is usually change-shaped ("reword X", "reformat
Y", "clarify Z") — verifying only that the reported incident occurred confirms the frame
without testing it. Step 2 therefore opens with the **absence test**: assume the target
deleted and state what concretely breaks. Only what breaks is the target's function — which
surfaces what the frame hides: a target whose deletion breaks nothing (remove, don't reword),
a duplicate of a canonical home (remove, point there), text exceeding what its consumers use
(trim). This is why Step 2 states the verified problem as a function-vs-state gap rather than
a restatement of the IMP.

*Why the shape readings matter* (the readings themselves are catalogued in the reference
companion): each names a case where the base test silently misreads. A **purely additive** IMP
has no referent to delete, so the test drops out exactly where frame inheritance is most
complete — nothing in the row is being weighed against anything; redirecting to the neighbour
turns an unfalsifiable "would this help?" into a decidable question that fails usefully in both
directions. A **partially-inert** target is the opposite trap: the test returns "something
breaks" from the live half, and that half's legitimacy is what makes re-mechanizing the inert
half feel justified — so apply the reading per half, or the finding inverts from removal to
rewrite.

*Evidence weight for a single-incident caution*: an additive caution harvested from the
session's own friction carries a built-in bias — the author is also the reporter, and one felt
incident reads as a class. Probe the incident before weighing the addition: did the human have
to correct a wrong outcome they would otherwise have approved (a real gap), or did the session
self-correct in flight (the existing guidance worked)? One self-corrected incident is evidence
the system held, not that it needs another caution.

*Why absence simulation rather than naming consumers*: the target's own text usually names an
audience ("surface X at the checkpoint", "input to session sequencing"), so "who consumes
this?" is answerable from inside the frame — copying those self-asserted consumers is
inheritance formatted as verification. "What breaks without it?" is not answerable from inside
the frame: a checkpoint one-liner nobody acts on breaks nothing, and the phantom consumer
dissolves. Frame pressure is strongest exactly when `[HUMAN-CORRECTION]` provenance or a
triage-endorsed fix makes the framing feel pre-validated (worked incident in the edge-case
file). The Step 6 `Removal:` verdict line is the enforcement: a skipped trace becomes missing
output, visible to author and reviewer alike.

*Why at problem identification, not solution exploration*: alternatives generated after the
frame is accepted inherit it — without the trace, a useless target surfaces only through human
reprompts escalating sentence → clause → whole passage. *Edge*: when every part of the target
survives the absence test — its deletion would concretely break a step or decision — the IMP's
framing is confirmed: proceed with it, now verified rather than inherited.

## Execution safeguards for specific change shapes (Step 10)

- **Runtime-tool verification**: when correctness depends on another tool's runtime behavior
  (a validator, LinkWatcher, a generator like `Build-DocumentationMap.ps1`), run that tool
  against the change and report the observed result at the decision-review checkpoint — infer
  nothing from the edit alone. When the premise concerns behavior the tool's user docs do not
  cover, read the tool's own source or config — the operative truth lives there, not in the
  handbook. The same discipline runs in reverse at problem verification
  (Step 2): a premise about a tool's runtime behavior is confirmed or refuted only by running
  it, and a failed probe refutes nothing until the observed behavior is explained —
  environment, discovery timing, or lazy skill registration can make a true claim fail to
  reproduce (worked incident in the edge-case file). Explain-before-dismissing extends to the
  session's *own* tooling: an anomaly in a scratch script or ad-hoc command (a substitution
  that silently no-ops, output that disagrees with disk) is root-caused before its result is
  used, never waved off as a tooling quirk.
- **Data-safety for destructive changes**: deleting or rewriting tracked data (state-file row,
  registry entry, generated artifact) → re-derive the target from its source and diff before
  replacing; take a timestamped backup before deleting; dispose of backups at finalization
  cleanup.
- **Spillover judgment (PF-PRO-059)**: the spillover lane defers only across a genuine
  *verification boundary* — work this session cannot verify (another task's artifact chain, a
  change needing a soak or a different cwd) — never work that is merely tedious; a remainder
  that is bounded and mechanically identical completes in-pass per the task's full-extent
  rule. A spillover chain deeper than one means the decomposition is wrong — escalate rather
  than chain.
- **Edge-file routing judgment (PF-PRO-059)**: the destination is chosen at Step 6 — see the
  destination axis under *Solution exploration*. Execution applies that choice, and routes the
  same way for edge material that first surfaces mid-execution.

## Reference index

- [references/examples-and-troubleshooting.md](references/examples-and-troubleshooting.md) —
  two worked example patterns (coordinated ecosystem streamlining; inline step guidance) and
  recovery recipes (approval skipped; linked documents missed). Load when you want a pattern
  to imitate or hit a friction surface.
- [references/edge-cases.md](references/edge-cases.md) — consult-on-stumble record
  (non-standard entry modes, claim-collision recoveries, failed-reproduction incidents,
  pre-validated-framing precedent, `-Command` transit mangling, malformed-row provenance,
  concurrent-deletion recovery). Consult on an error, surprise, or ambiguous fork at any
  task step; append autonomously per the workspace Standing Orders.
