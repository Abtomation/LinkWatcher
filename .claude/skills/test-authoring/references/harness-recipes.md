# Harness recipes

Phase 3 of the [Test Authoring Guide](../../../../process-framework/guides/03-testing/test-authoring-guide.md#phase-3-prove)
— fail-first where a defect exists, mutation verification where none does — is discharged in
each harness's own form. This file is a router: the recipes that have no other home are written
here; everything else points at its canonical home.

## pytest (Python)

- **Mutate at runtime, not in the working tree.** Reverting a fix to prove its tests is an edit
  to a tree other sessions may be live in. Instead, write a one-file pytest plugin in the
  scratchpad that patches the fixed function or attribute back to its pre-fix wiring at
  configure time, and load it with `-p` from `PYTHONPATH`:

  ```python
  # scratch/prefix_plugin.py — loaded with: PYTHONPATH=scratch pytest -p prefix_plugin <tests>
  import pkg.module
  def pytest_configure(config):
      pkg.module.ESCAPABLE_TYPES = ()          # the pre-fix wiring, or the buggy value
  ```

  Expect exactly the fix's tests red and every control green; nothing on disk changes. The same
  plugin form applies a *mutation* where no defect exists (return the buggy value, invert the
  branch). Origin: PF-FEE-1904, PF-FEE-1914.
- **Editable installs shadow a scratch copy.** With `pip install -e`, the install's meta-path
  finder outranks `sys.path`, so a scratch checkout of `src/` (e.g. `git show HEAD:<path>` into a
  temp tree for a pre-fix baseline) is silently ignored and the run imports the *fixed* source —
  an all-green baseline that proves nothing. Confirm resolution before reading any result:
  `python -c "import pkg.module as m; print(m.__file__)"`, or `pytest --collect-only -q` and
  check the paths. Prefer the runtime-patching form above; it needs no second tree. Origin:
  PF-FEE-1892.
- **Markers and sync.** `New-TestFile.ps1` writes the `feature` / `priority` / `test_type`
  markers; after adding tests to an existing file, sync counts with
  `Validate-TestTracking.ps1 -Fix -Path <files>` (guide Phase 4).

## Pester (PowerShell)

Product suites in PowerShell projects follow the same doctrine as the framework's own suites,
whose recipes live in the
[Script Development Quick Reference](../../../../process-framework/guides/support/script-development-quick-reference.md)
(PF-GDE-019):

- **Sentinel seeding and the two obligations** —
  [Load-Bearing Assertions](../../../../process-framework/guides/support/script-development-quick-reference.md#load-bearing-assertions-discriminating-condition--mutation-verification).
- **Proving a side-effecting script reaches its gates without executing them** —
  [Subprocess + WhatIf + Side-Effect-Counting pattern](../../../../process-framework/guides/support/script-development-quick-reference.md#subprocess--whatif--side-effect-counting-test-pattern);
  proving the gated body *works* —
  [Phantom Parameters Survive `-WhatIf`-Only Suites](../../../../process-framework/guides/support/script-development-quick-reference.md#-phantom-parameters-on-shared-helpers-survive--whatif-only-suites)
  (real-write coverage through the project-root override seam — mutate a sandbox copy, never
  the live tree).
- **Capturing what the script emits** —
  [`-WhatIf` Output Is Not Capturable In-Process](../../../../process-framework/guides/support/script-development-quick-reference.md#--whatif-output-is-not-capturable-in-process),
  [A Log Line Inside a `ShouldProcess` Block Doesn't Run Under `-WhatIf`](../../../../process-framework/guides/support/script-development-quick-reference.md#-a-log-line-inside-a-shouldprocess-block-doesnt-run-under--whatif),
  [Capturing `Write-Error`](../../../../process-framework/guides/support/script-development-quick-reference.md#-capturing-write-error-from-a-script-under-test),
  [`Update-*` Scripts Log Default-Quiet](../../../../process-framework/guides/support/script-development-quick-reference.md#-update--scripts-log-default-quiet--pester-assertions-on-info-text-need--verbose).
- **Assertions that pass vacuously or hang** —
  [Testing Mandatory Parameters](../../../../process-framework/guides/support/script-development-quick-reference.md#-testing-mandatory-parameters-without-triggering-the-interactive-prompt),
  [Angle-Bracket Tokens in `It`/`Describe` Names](../../../../process-framework/guides/support/script-development-quick-reference.md#-angle-bracket-tokens-in-pester-itdescribe-names),
  [`Should -BeLike` Bracketed Literals](../../../../process-framework/guides/support/script-development-quick-reference.md#-should--belike-treats-a-bracketed-literal-as-a-wildcard-character-class).
- **Behaviour-preserving mass changes** —
  [Golden-File Equivalence Harness](../../../../process-framework/guides/support/script-development-quick-reference.md#behavior-preserving-refactor-verification-golden-file-equivalence-harness)
  (byte-identity, not per-script expectation).
- **Emoji literals in `-Match` patterns flake by run composition** (PF-IMP-2233, mechanism
  unsettled): a positive `-Match` on an emoji literal can go falsely red and a
  `Should -Not -Match` falsely green, typically on the first run of a batch. Assert on a text
  token adjacent to the glyph instead; treat a first-of-batch red on such an assertion as
  suspect and re-run the file in isolation before reading it as a defect.

## E2E instruction fixtures (agent-executed cases)

The oracle must have been **observed failing** on a wrong-order run before it counts — the
discriminating-assertion table and the authoring-time double run are in the
`e2e-test-case-creation` skill's
[instruction-fixtures reference](../../e2e-test-case-creation/references/instruction-fixtures.md#designing-assertions-that-discriminate);
the cold-executor run path is
[E2E Acceptance Test Execution](../../../../process-framework/tasks/03-testing/e2e-acceptance-test-execution-task.md).
Scripted cases prove `run.ps1` + `expected/` the same way: run once correctly, once with the
action skipped, and confirm `Verify-TestResult.ps1` distinguishes them.

## Performance benchmarks

Phase 3 for a benchmark is *detecting the regression it guards*: inject the slowdown (a larger
N, a deliberately quadratic path, a removed cache) and confirm the tolerance band trips, then
restore. Measurement discipline, flaky-benchmark avoidance and the bands themselves are the
[Performance Testing Guide](../../../../process-framework/guides/03-testing/performance-testing-guide.md)
(§ Measurement Best Practices, § Avoiding Flaky Benchmarks, § Tolerance Bands).

## Any harness

- Confirm module resolution before the first run that counts (`--collect-only`, a printed
  `__file__`, or the harness's equivalent).
- Run through `process-framework/scripts/test/Run-Tests.ps1` so the project's configured
  runner, categories and coverage tool apply; `-ListCategories` gives the `-TestType` vocabulary.
