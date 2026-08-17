# Edge cases — Test Specification Creation (PF-TSK-012)

Consult-on-stumble record for the Test Specification Creation task and this skill (PF-PRO-059
two-zone convention). Each entry is keyed to the situation in which it applies — read the
entry whose situation you are in; nothing here is part of the routine path. Any session may
append or rewrite entries autonomously per the workspace Standing Orders (an entry names its
provenance; the ~150-line promotion tripwire applies).

## The selected feature turns out not to need tests

**Situation**: the task was selected for a feature that produces no testable behavior
(assessment or documentation features).

Do not run the task through. Update the Feature Tracking Test Status directly to
"🚫 No Test Required" instead, and record the reason in the feature's Notes.

## `New-TestSpecification.ps1` rejects `-TddPath`

**Situation**: the creation script errors that the TDD path is not found.

The path must be a real file path, **relative from the project root, forward slashes** (e.g.
`doc/technical/tdd/tdd-feature.md`) — not absolute, not backslashed, not relative from the
spec's own directory. (Other script-path / module-resolution errors: see the Script
Development Quick Reference.)

## The draft spec is coming out too thin

**Situation**: the Test Categories tables cover only a fraction of the TDD, or scenarios read
generic.

The source TDD is under-mined. Map **every** component (models / services / UI) to specific
test requirements first, then add edge and error cases at the tier-appropriate depth — the
thinness signal is usually a component→test mapping gap, not a scenario-writing gap.
