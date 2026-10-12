# Edge cases — Test Authoring (PF-GDE-079)

Consult-on-stumble record for test-authoring situations met by any task that cites the
[Test Authoring Guide](../../../../process-framework/guides/03-testing/test-authoring-guide.md)
(PF-PRO-059 two-zone convention). Each entry is keyed to the situation in which it applies —
read the entry whose situation you are in; nothing here is part of the routine path. Any
session may append or rewrite entries autonomously per the workspace Standing Orders (an entry
names its provenance; the ~150-line promotion tripwire applies).

## A validation script's before and after runs come out the same, or its assertion is green too easily

**Situation**: a manual validation script (Bug Fixing's regression-test step) shows no difference between the
buggy and the fixed configuration, or an assertion you expected to discriminate passes on its
first run.

- **Identical output for an unrelated reason**: the environment can mask the difference —
  timestamp granularity, a rename back-off, caching. In one APP-001 fix (PF-FEE-1905,
  2026-08-19) four log rotations in under a second collided on timestamped backup names and
  the back-off suppressed the rest, so the buggy and the fixed configuration each produced
  exactly one rotated file; printed side by side that read as a passing demo. Vary the input
  until the runs diverge (spread the trigger over time, or disable the masking mechanism),
  then assert on that divergence — the script's own before/after assertion is what caught it.
- **An assertion the failure itself satisfies**: on PD-BUG-123 (PF-FEE-1889, 2026-08-18)
  `log_level in output` and `AttributeError not in output` were both satisfied by a raw
  `ValueError` traceback — the defect's own output passed the check. Apply the guide's Phase 2
  step 7 (assert the exact line the correct path emits; confirm the negative fragment cannot
  occur in correct output) and Phase 3 step 10 (break the fix transiently — the assertion
  must go red).

*Provenance: PF-IMP-2140 (PF-TSK-009, 2026-09-20).*
