# Onboarding / Retrospective Sections

State-file sections that exist only when the framework is adopted into an existing codebase.
Consumed inline by Codebase Feature Discovery (PF-TSK-064), Codebase Feature Analysis
(PF-TSK-065), and Retrospective Documentation Creation (PF-TSK-066) — those tasks own *when* each
section is touched; this reference owns *how to fill it well*.

**Retrospective framing**: in onboarding/retrospective files all content is **descriptive
("what is"), not prescriptive ("what should be")** — Implementation Progress tracks analysis
progress rather than planned tasks, Code Inventory is the primary deliverable (every file
assigned), and Design Decisions documents choices *discovered in code*. Tier-1 features use the
lightweight template variant (`New-FeatureImplementationState.ps1 -Lightweight`).

## Existing Project Documentation (Documentation Inventory subsection)

An audit ledger for documentation that predates framework adoption:

- **Populated** during Codebase Feature Discovery, from the project documentation survey — every
  pre-existing doc relevant to the feature, marked `Unconfirmed`
- **Confirmed** during Codebase Feature Analysis, as part of per-feature analysis —
  `Unconfirmed` → `Confirmed` / `Partially Accurate` / `Outdated`
- **Consumed** during Retrospective Documentation Creation — extract confirmed content before
  writing anything from scratch

Greenfield state files **omit this subsection entirely** — `New-FeatureImplementationState.ps1`
strips it from non-retrospective files (PF-IMP-1359); its presence signals an
onboarding/retrospective file.

## Quality Assessment (onboarding only)

Populated during Codebase Feature Analysis. Score the feature on 5 dimensions with the 0–3
scale (0 = absent/broken, 1 = present but problematic, 2 = adequate, 3 = well-implemented):

| Dimension | What you're judging |
|---|---|
| Structural clarity | Separation of concerns, layering, no god classes |
| Error handling | Consistent patterns, no silent failures |
| Data integrity | Validation at boundaries, no injection vectors |
| Test coverage | Existing tests cover critical paths |
| Maintainability | Readable code, reasonable complexity |

**Do not compute the derived values by hand.** After entering the 5 scores, run
`process-framework/scripts/update/Update-QualityClassification.ps1` — it computes **Code
Maturity** (average of the four non-test dimensions; drives classification), **Test Maturity**
(test coverage alone; a separate test-plan-urgency signal), applies the canonical threshold
(Code Maturity ≥ 2.0 → **As-Built**; < 2.0 → **Target-State**), and writes the Classification /
Code Maturity / Test Maturity lines back (auto-migrating legacy single-"Average Score" files).

For **Target-State** features, link the Quality Assessment Report (PD-QAR-XXX) created during
Retrospective Documentation Creation. For new (non-onboarding) features, leave the section
empty — the quality gate applies only during framework adoption.
