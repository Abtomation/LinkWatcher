# Debt Item (PD-TDI) Customization

A debt item documents **one specific instance** of debt — problem, impact, effort, remediation —
unlike the assessment, which surveys the whole project. Always create it with
`process-framework/scripts/file-creation/cyclical/New-DebtItem.ps1` (never hand-authored), then
register it in the tracker with `Update-TechDebt.ps1 -Add` (the creation script prints the
ready-to-run command). Add `-AssessmentId "PD-TDA-XXX"` to link the source assessment. The template
is self-documenting; this reference covers the judgment beyond its inline prompts.

## Dimension selection (`-Dim`)

Choose the one dimension that best describes the debt. The ten development dimensions (AC, CQ, ID,
DA, EM, SE, PE, OB, UX, DI) are defined once in the
[Development Dimensions Guide](../../../../process-framework/guides/framework/development-dimensions-guide.md) —
use those definitions. Debt items add one extra category that is **not** a development dimension:

- **TST — Testing**: zero-assertion tests, coverage gaps, flaky tests, test-infrastructure debt.

Run `Update-TechDebt.ps1 -ListDims` for the canonical code list.

## Priority (`-Priority`)

Initial priority drives scheduling and is refined later in the tracker:

| Priority | Criteria |
|---|---|
| **Critical** | Blocks development, security vulnerability, or active production issue |
| **High** | Significantly slows development velocity or degrades user experience |
| **Medium** | Moderate impact on maintainability or performance |
| **Low** | Minor; address when convenient |

## Customization decisions

- **Scope** — one focused issue (easiest to estimate and resolve), several related issues
  addressed together, or a system-wide pattern (break into multiple items).
- **Detail level** — high for architectural issues, moderate for typical code-quality issues,
  minimal for straightforward ones.
- **Remediation options** — document multiple approaches with trade-offs only when the solution is
  genuinely uncertain or complex; otherwise a single recommended approach suffices. Add a
  research-phase step when the solution isn't yet known.

**Load-bearing sections** when completing the template: Description (Problem / Current / Desired
State), Impact Assessment (business + technical), Effort Estimation, and Remediation Plan; the
rest is supporting context.
