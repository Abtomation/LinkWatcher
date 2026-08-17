# Level 3 Instruction Fixtures

Load this when the case under construction verifies an **instruction** — a task, guide, playbook or
procedure an agent executes — rather than a script. This is Level 3 of the instruction verification
stack (PF-PRO-064): *agent + instruction + fixture → asserted end state*.

A scripted case and an instruction case use the same harness and the same directory shape. Four
things change, and each follows from one fact: **the actor is an agent, not a script.**

## 1. There is no `run.ps1` — and that is correct

`run.ps1` is the action. When the action is "an agent reads the instruction and does what it says",
there is nothing to put in it. Writing one anyway means re-implementing the instruction in
PowerShell and then testing *that* — which verifies the re-implementation, not the instruction.

So an instruction case has no `run.ps1`, and `Run-E2EAcceptanceTest.ps1` skips it. That is the
harness's existing non-scripted path (it prints a message suggesting direct execution), not a gap.
Both halves that surround the action are still used:

| Phase | Owner |
|-------|-------|
| Setup | `Setup-TestEnvironment.ps1` (harness) |
| Action | **the agent**, following `test-case.md` → the instruction under test |
| Assert | `assert.ps1` (shipped with the fixture) |
| Verify | `Verify-TestResult.ps1` (harness) |

## 2. Ship an `assert.ps1` oracle — the agent must not be its own oracle

In a scripted case the assertions live inside `run.ps1`, which is fine because the actor is
deterministic. Here the actor is the thing in doubt. An agent that executes the instruction *and*
checks the result grades its own reading of the instruction — precisely the reading under test. A
misreading produces a matching mis-assertion and the case passes.

So split the roles and ship them separately:

- `assert.ps1` is authored **with the fixture**, and never written or edited by the executing agent.
- `test-case.md` tells the agent not to read it before executing. Reading the oracle first converts
  the exercise into "satisfy these assertions", which any competent agent can do without ever
  following the procedure. **§4 makes this structural**: the executing agent is never given the
  oracle at all.

Give the oracle a `-WorkspacePath` parameter, have it delete any stale `success.txt` before
asserting (so a previous pass cannot be mistaken for a new one), collect **all** failures rather
than bailing on the first, and name in each message *which step* the missing fact implicates.

## 3. `expected/` holds the verdict, not the end state

`Verify-TestResult.ps1` compares files byte-for-byte and does not normalize. A real instruction end
state usually carries a timestamp, an allocated ID, or a content hash, so literal end-state files in
`expected/` could not match twice. The oracle normalizes; `expected/success.txt` (`ok`) is what the
harness compares.

## 4. The executor is a cold subagent — spawned, not the main session

The main agent orchestrates the case but never executes the instruction itself. It runs the phases
in order — `Setup-TestEnvironment.ps1` → **spawn a subagent as the executor** → `assert.ps1` →
`Verify-TestResult.ps1` — and feeds the executor **only** `test-case.md` and its bindings: never
`assert.ps1`, never the orchestrating session's context.

This makes the oracle separation structural rather than requested (§2's "do not read it first" rule
stops relying on honor — the executor cannot read what it was never given), and it keeps the read
**cold**: a main agent that authored or debugged the procedure cannot give it a fresh read, and a
fresh read is the thing L3 exists to test.

Agent-executed cases are **permanently outside `Run-E2EAcceptanceTest.ps1`** — the runner stays
scripted-only and agent-agnostic (it cannot spawn agents, and agent coupling lives in skills and
task text, never in scripts). Tracking updates ride the execution task's existing manual path for
non-scripted cases (`Update-TestExecutionStatus.ps1`).

## Designing assertions that discriminate

The hard part is not asserting that *something changed*. It is asserting that the agent followed the
procedure **as written** rather than reaching a plausible-looking state some other way. Aim for
end-state facts that are different for a correct run and a wrong-order run.

Seed the fixture so the two diverge numerically or structurally:

| Assertion kind | What it catches |
|---|---|
| A value only an *early* step could produce | A skipped or reordered prerequisite step |
| A distinct value the wrong order also produces | Distinguishes "wrong" from "didn't run" — the wrong run should not merely fail, it should fail *differently* |
| A side-effect marker from a step that has no bookkeeping | A step performed only nominally (e.g. "run it and verify" skipped between two recorded calls) |
| The absence of writes outside the sandbox | An override that was never in effect — a pass that corrupted live state |

**Verify the discrimination at authoring time.** Run the case twice: once following the instruction
correctly (oracle passes), once executing it in the wrong order (oracle fails, naming the facts). An
oracle never observed failing is an oracle that may assert nothing.

## Hermetic state

Instruction procedures routinely touch central framework state. Everything in
[hermetic-central.md](hermetic-central.md) applies unchanged — with one difference: no `run.ps1`
exists to set and clear `FRAMEWORK_CENTRAL_OVERRIDE` in a `try`/`finally`, so `test-case.md` must
make setting it an explicit protocol step (labelled as fixture plumbing, not part of the
instruction), and `assert.ps1` must carry the leak check that a scripted case would end with.

Keep the seed under `project/` rather than a sibling `sandbox-central-seed/`:
`Setup-TestEnvironment.ps1` copies **only** `project/` into the workspace, and with no `run.ps1`
nothing else would copy a sibling directory.

## Writing the protocol without leaking the procedure

`test-case.md` must not restate the steps of the instruction under test. A case that spells them out
tests the case, not the instruction — the agent follows the restatement and the instruction's own
clarity is never exercised. Give the agent only:

1. the harness commands (setup, assert, verify) — plumbing, safe to state exactly;
2. a **link** to the instruction under test;
3. the **bindings** it needs (which ScriptId, which path, which fixture file plays which role);
4. an explicit instruction to follow the linked procedure in the order it gives.

## Worked example

`test/e2e-acceptance-testing/soak-verification/templates/TE-E2E-014-instruction-execution-soak-resync-procedure/`
(appdev). Instruction under test: the Soak Re-Sync procedure in the Script Development Quick
Reference. The fixture seeds a soak row with a stale hash and counter 1, so a correct re-sync leaves
counter **2** while skipping the reset leaves **0** — a script wrongly recorded as soak-complete.
It also asserts a `ran.txt` marker (proving the "run it for real" step happened) and that the real
central tracking file was untouched.
