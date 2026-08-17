---
id: PF-GDE-078
type: Process Framework
category: Guide
version: 1.2
created: 2026-07-28
updated: 2026-08-10
description: Consult-on-stumble edge-case record for the Tools Review task (PF-TSK-010) - legacy-form naming, recurrence-vs-duplicate ordering, site-list label precedent, queue-depth observations, ratings-key anomalies (PF-PRO-059 two-zone convention).
related_task: PF-TSK-010
---

# Tools Review Edge Cases

## Overview

Consult-on-stumble edge-case record for the [Tools Review task (PF-TSK-010)](../../tasks/support/tools-review-task.md) — the PF-GDE-homed edge file of the PF-PRO-059 two-zone convention (Tools Review has no craft skill, so its edge file is this ID'd guide; archetype: the Script Development Quick Reference). Each entry is keyed to the situation in which it applies; nothing here is part of the routine path.

## When to Use

Consult on an error, surprise, or ambiguous fork at any Tools Review step — read the entry whose situation you are in. Any session may append or rewrite entries autonomously per the workspace Standing Orders (an entry names its provenance; the ~150-line promotion tripwire applies).

## A feedback form carries the legacy pre-cutover filename

**Situation**: a form in the central feedback-forms folder is named `YYYYMMDD-HHMMSS-PF-TSK-XXX-feedback.md` (hyphen-separated, no `<PROJECT-ID>` segment) instead of the Phase 7 underscore form.

Pre-cutover forms with the legacy naming were migrated by Phase 7.5 and live at the same central path. Treat them as project-of-origin = unknown unless their frontmatter declares otherwise; process them normally otherwise.

## A dedup hit is a Completed archive row — recurrence or plain duplicate?

**Situation**: the classify-and-register step's deduplication search returns a Completed archive row for the same symptom, and the symptom appears again in this cycle's forms.

The distinction is **ordering**: the form's session timestamp must postdate the fix reaching the observing project — the completion date for appdev-origin forms, the first rollout to that project otherwise. If it does, it is a *recurrence* (evidence the fix did not hold): register the new IMP with `[RECURRENCE of PF-IMP-NNN]` in `-Notes`, naming the completed row whose fix failed. If it does not — or the ordering cannot be established — it is a plain duplicate: skip registration.

## Why site-list labels matter (precedent)

**Situation**: deciding whether the EXHAUSTIVE / ILLUSTRATIVE label on a filed site enumeration is worth the effort.

An unlabeled list reads as complete when it isn't: PF-IMP-1549 filed "~8 sites" against a real population 4× larger, and the implementing session had no way to know the list was examples-only until it re-derived scope itself. The pasted-search-plus-label convention exists so re-derivation is one command.

## Tempted to file a queue-depth / backpressure observation

**Situation**: analysis surfaces an observation that Tools Review gives no signal about how deep the open IMP queue already is, or files findings regardless of drain capacity.

That reflects the intended design, not a gap to close. Queue-*depth* backpressure stays out of scope: whether a **qualifying** finding files never depends on how deep the open IMP queue is — whether to keep filing or pause to drain is the human's call, and drain capacity is owned downstream (IMP Triage and the implementing tasks). Do not file it as an IMP. Distinct from this, the classify-and-register step's **materiality bar** (PF-IMP-1882, owner decision 2026-07-29) governs *what qualifies*: it is a property of the finding (evidence of observed friction/defect), evaluated identically whether the queue holds 5 rows or 500 — below-bar candidates route to the Improvement Backlog, not Intake. Applying the bar is not a backpressure decision; proposing to *tighten or loosen* it based on queue depth would be, and routes to the owner.

## The ratings JSON keys an ID-carrying artifact by filename

**Situation**: reviewing `extract_ratings.py` output before recording, a `tool_doc_id` for an artifact that has a portable framework ID (PF-TSK/PF-GDE/PF-TEM/PF-FST) contains its filename instead.

The extractor and `record` both normalize headings to the portable ID, so a filename here means the frontmatter index missed that artifact. Report it (file an IMP against the extractor/index), don't hand-patch the JSON — a hand-patch hides the index gap and it resurfaces every cycle.

## Related Resources

- [Tools Review Task (PF-TSK-010)](../../tasks/support/tools-review-task.md) — the owning task
- [Script Development Quick Reference](script-development-quick-reference.md) — the script-domain edge-case file (archetype of this form)
