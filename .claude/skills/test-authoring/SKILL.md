---
name: test-authoring
description: >-
  Craft for writing a product test that can actually fail — the judgment half of the Test
  Authoring Guide (PF-GDE-079) procedure every test-writing task cites: finding the discriminating
  condition, landing new surface before the first run, scoping characterization tests, choosing
  the mutation and reading a failure for the defect's own signature, keeping negative assertions
  and fixtures capable of failing, and recording the contrast. A harness reference routes to the
  per-harness recipes (pytest runtime patching and editable-install shadowing, the Pester entries,
  E2E oracles, benchmarks); a bundled reference holds the test-file mechanics (New-TestFile.ps1
  TestType/Priority selection, mock strategy). Activated from the Check-Recommended-Skills step of
  Bug Fixing, Integration and Testing, Foundation Feature Implementation and UI Implementation
  (via recommended_skills); consulted inline by every other task that cites the guide. Not a
  test-specification, test-audit, E2E-case customization, or performance-scoping skill, and not
  for framework-script suites (those apply Load-Bearing Assertions directly).
user-invocable: false
---

# Test Authoring Craft

This skill owns the **judgment** behind the
[Test Authoring Guide](../../../process-framework/guides/03-testing/test-authoring-guide.md)
(PF-GDE-079) — *how* to discharge each phase well where the procedure alone does not decide.
The guide owns the procedure (the four phases and their order); the citing **task** owns
everything else (task selection, checkpoints, state writes, the feedback form). Bound hosts
activate this skill at their Check Recommended Skills step; every other task that cites the
guide consults it inline at its authoring step.

> **Division of labor.** The task owns process; the guide owns the steps; this skill owns
> craft. Do **not** run checkpoints, create files, or write state from this skill. Sibling
> crafts stay where they are: spec content is `test-specification`, E2E case customization and
> instruction fixtures are `e2e-test-case-creation`, when-to-test is `perf-e2e-scoping`, the
> refactoring plan is `refactoring-planning`. **Product tests only** — framework-script suites
> and migration pre-checks apply
> [Load-Bearing Assertions](../../../process-framework/guides/support/script-development-quick-reference.md#load-bearing-assertions-discriminating-condition--mutation-verification)
> (PF-GDE-019) directly.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. Test files are created by
`process-framework/scripts/file-creation/03-testing/New-TestFile.ps1` (parameter craft in
[references/test-file-customization.md](references/test-file-customization.md)); tracking is
synced by `process-framework/scripts/validation/Validate-TestTracking.ps1 -Fix -Path <files>`;
`process-framework/scripts/test/Run-Tests.ps1` dispatches to the project's harness
(`-ListCategories` lists the `-TestType` vocabulary).

## Before writing (guide Phase 1)

**Finding the discriminating condition.** Ask what a *wrong* implementation would produce for
this input, and assert the thing that differs. A condition you cannot state means one of two
things: the fixture makes the value true by construction — seed a value that exists nowhere in
the source, a sentinel, so "preserved" is not "identical by construction" — or the behaviour is
not observable at this level, so move the assertion to the level where it is. Shapes that
structurally cannot name one are rewritten, not kept: an existence-guarded body that skips
itself when the file is absent, a count compared against a file that may not exist (0 vs 0), a
negative match on a run that may die before the guarded line, an error-text match that names
the very file it failed to find.

**Landing new surface first.** The stub must preserve the old behaviour *and* must not itself
satisfy the test: a new parameter defaults to the old path, a new module exports its names with
pass-through bodies, a new helper returns what the old inline code returned. If the stub already
makes the test pass, the test is asserting the surface, not the behaviour — re-derive the
condition.

**Scoping characterization tests.** Pin the paths the change will touch, not the module:
enumerate the branches the diff reaches, count a transitive caller that exercises a branch
through a public API as coverage, and pin current behaviour *including* its imperfections — a
pin that "corrects" the output while pinning it protects nothing. No defect exists to fail-first
against, so each pin is mutation-verified like any other test.

## Write (guide Phase 2)

**Negative assertions.** `"error" not in output` passes a fix that emits nothing at all and
fails one that logs an unrelated warning. Prefer the exact expected line. When a substring is
unavoidable, confirm by inspection that the fragment cannot occur in *correct* output — a token
the correct path never emits — and pair it with a positive assertion on what the correct path
does emit.

**Fixture capability.** Trace the input from the fixture to the branch under test *before*
writing the assertion; if no input reaches the branch, no assertion on it can fail. A manual
validation script that only prints before/after state is a demonstration, not a test — it needs
an input the human varies and a difference they observe. The E2E form — an oracle observed
failing on a wrong-order run — is the `e2e-test-case-creation` skill's
[instruction-fixtures reference](../e2e-test-case-creation/references/instruction-fixtures.md#designing-assertions-that-discriminate).

## Prove (guide Phase 3)

**Reading a failure for the defect's signature.** Per test, ask whether the failure message
names the *behaviour the test asserts*:

| The failure reads as | It is | Do |
|---|---|---|
| the asserted value or line differs | the defect's signature | keep — this is the evidence |
| import error, unknown name, collection error | new surface not landed | back to Phase 1: land the surface, re-run |
| fixture or setup exception, missing file | a harness fault | fix the fixture — the run says nothing about the test yet |
| a *different* assertion in the same test | an overloaded test | split it — one behaviour per test |
| green before the fix | a fixture that never reaches the defect | fix the fixture or drop the test |

**Choosing the mutation.** Break the *behaviour* the assertion names, not code near it: invert
the branch condition, return the buggy value, drop the side effect, off-by-one the boundary. One
mutation per assertion — the smallest edit that should turn exactly that assertion red. Read the
result like a failure: exactly the mapped assertion red → load-bearing; nothing red → vacuous,
rewrite; a *different* assertion red → the mapping is wrong, fix the mapping, not the mutation;
many red → the mutation was too large, narrow it. Prefer a form that never touches a shared
working tree — the zero-mutation recipes per harness are in
[references/harness-recipes.md](references/harness-recipes.md) — and restore before the next
step either way.

**Module resolution.** Before reading any pre-fix or mutated run as evidence, confirm the
harness imported the tree you think it did — an installed copy silently outranks a scratch tree
(recipe per harness in the harness reference).

**Recording the contrast.** One line, in the carrier the guide's table names: what was broken
(or "pre-fix"), which tests went red and for what reason, and that the rest stayed green —
*"pre-fix: 2 red (missing strict error, empty-line passthrough), 74 green; post-fix: all
green"*, or *"mutation: escapable-types tuple emptied → exactly the 3 PD-BUG-126 tests red"*. A
record that carries only counts cannot be re-derived by the reviewer.

## Reference index

- [references/harness-recipes.md](references/harness-recipes.md) — Phase 3 in each harness's
  own form and where each harness's craft lives: pytest (runtime patching via a plugin,
  editable-install shadowing), Pester (the quick-reference entries, the subprocess `-WhatIf`
  pattern, the golden-file harness, the emoji-literal caveat), E2E instruction fixtures,
  performance benchmarks. Load when proving a test or choosing a harness-specific technique.
- [references/test-file-customization.md](references/test-file-customization.md) —
  `New-TestFile.ps1` parameter selection, customizing the generated scaffold, mock strategy.
  Load when the Phase 1 home decision is a new file.
- [references/edge-cases.md](references/edge-cases.md) — the consult-on-stumble record for
  test-authoring situations met by any task that cites the guide; appended autonomously per
  the workspace Standing Orders (PF-PRO-059). Consult on an error, surprise, or ambiguous fork.
