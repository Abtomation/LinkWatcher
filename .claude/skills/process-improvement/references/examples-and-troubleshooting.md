# Worked examples and troubleshooting

## Example: streamlining a task-definition ecosystem (coordinated multi-artifact session)

**Shape**: one IMP applies an evaluation report's findings to a task + its guide(s) + its
context map in one coordinated session (precedent: PF-IMP-865 applying PF-EVR-023 to the
PF-TSK-009 ecosystem).

**Preparation pattern**:
- Verify each finding against the *current* state of the target artifacts (line-level
  pre-confirmation before claiming) — evaluation reports capture a moment; artifacts drift.
- Surface bundled tensions at the approach checkpoint — e.g. the source bundled 11
  streamlining edits + 5 additive sub-rules; the session committed to streamlining-only and
  deferred the additive set.
- Get the human's pick on any strategic sub-decision embedded in the IMP (e.g. slim a guide
  vs. retire it) *before* execution.

**Execution pattern** (medium-risk, batched): consolidate scattered routing blocks into one
reference table; collapse nested callouts to bullets; demote redundant CRITICAL markers to one
operative gate; delete guide content that duplicates the task; rewrite a stale context map
outright when it describes a workflow that no longer exists.

**Result shape**: same operational behavior, less cognitive overhead per session.

## Example: adding inline guidance to a task step

**Shape**: feedback identifies a gap at a specific step of some task (e.g. bug-fix tests
bypass the test registry) and the fix is inline guidance at that step.

**Pattern**:
1. Read the feedback and the target step's current content.
2. Decide: reference another task's full process, or extract the relevant subset inline?
   Read the candidate full processes first and verify their scope matches the trigger.
3. Extract only the load-bearing pieces (e.g. the registry update + the creation script) as
   inline guidance, covering the common case and the rare case.

**Result shape**: the step is self-contained; agents don't read an unrelated 250-line task
definition to handle the routine path.

## Troubleshooting

### Approach approval skipped

**Symptom**: implementation started without explicit approval at the approach checkpoint (or
without the conditional alternatives checkpoint when multiple options were proposed).

**Resolution**: stop immediately; present current progress + planned approach; get explicit
approval before proceeding.

> Per-change sub-checkpoints are required only for **high-risk** changes — skipping them on
> low- or medium-risk changes is correct, not a violation.

### Linked documents missed

**Symptom**: after completing the improvement, other documents still reference the old
version.

**Resolution**: grep for references to the changed file(s) across the project; sweep the
common stale-description sites (script header blocks, the generated documentation maps, the
Build-TaskMetadata projections, READMEs, task definitions — list in the reference companion);
update or remove outdated references.
