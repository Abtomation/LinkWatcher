# Retrospective Documentation — Tier 1 Path

> **Parent task**: [Retrospective Documentation Creation](retrospective-documentation-creation.md) (PF-TSK-066)
>
> **Scope**: Phase 3 closure pass for **Tier 1 features only**. Tier 1 features have no FDD, TDD, Test Specification, or ADR — their design intent lives in the [Feature Implementation State file](../../../doc/state-tracking/features) §6 "Design Decisions". Steps 5-11 of the parent task do not apply. This companion condenses Phase 3 to the subset that does.
>
> **Use when**: The current feature is Tier 1 (validated in Step 3 of the parent task). For Tier 2/3 features, return to the parent task and follow Steps 5-17 in full.
>
> **Phase 4 finalization**: After completing this companion for each Tier 1 feature in the batch, return to the parent task for Steps 18-27 (cross-feature verification, gap analysis, archive).

## Process

> **🚨 CRITICAL: This companion covers Phase 3 closure for Tier 1 features. Phase 4 finalization runs from the parent task once all features in scope are closed.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**

**T1. Confirm tier assignment**: The feature must already be Tier 1 in [feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md). If parent Step 3 raised doubts, resolve them in the parent task (validate against PF-TSK-065 analysis findings) before returning here. Tier-promotion or tier-demotion routes back through Steps 5-11 if the feature becomes Tier 2+.

**T2. Create Architecture Decision Records (optional)**: If the feature embodies a discrete architectural decision worth recording, create an ADR using [New-ArchitectureDecision.ps1](../../scripts/file-creation/02-design/New-ArchitectureDecision.ps1).

   > Tier 1 features rarely have ADR-worthy decisions, but it does happen (format-toolchain choice, identifier-validation strategy, etc.). When in doubt, skip — Tier 1's lightweight nature means architectural decisions usually got resolved during implementation rather than documented separately.

   - **Source**: Feature Implementation State file §6 "Design Decisions"
   - **Content**: Document architectural patterns/decisions
   - **Note**: Mark as "Retrospective" in the ADR header
   - Update master state: ADR ✅ (if created) or N/A

**T3. Generate Tech Debt Items from Quality Assessment** (Target-State Tier 1 only): Tier 1 features classified Target-State (Code Maturity < 2.0) still have gaps worth tracking. Skip this step for As-Built Tier 1 features.

   - **Source**: Feature Implementation State file §7 "Quality Assessment" — dimension scores and notes
   - For each gap implied by a low dimension score (0 or 1):
     - **Dedup first**: Search [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) for existing entries covering the same gap, file, or pattern. If found, link rather than re-register.
     - If no existing TD covers the gap:
       ```powershell
       pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "<gap description>" -Dims "<DIM_CODE>" -Location "<path/to/file-or-directory>" -Priority "<Critical|High|Medium|Low>" -EstimatedEffort "<S|M|L>" -AssessmentId "PD-QAR-XXX" -Notes "<Feature Name> — dimension <X> score <Y>"
       ```
   - Update the Feature Implementation State file §8 "Issues & Known Limitations" with links to created items.
   - **"No new TDs" is a valid outcome**: If gap analysis surfaces no items beyond what PF-TSK-065 already captured, note this in §8 explicitly.

**T4. Create Quality Assessment Report** (Target-State Tier 1 only): Use the automation script with the `-Tier 1` flag — the script pre-fills the "no FDD/TDD/Test Spec/ADR — design intent in PD-FIS §6" disclaimer at the top.

   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/00-setup/New-QualityAssessmentReport.ps1 -FeatureName "<name>" -FeatureId "<id>" -Tier 1 -CodeMaturity <score> -TestMaturity <score>
   ```

   - Fill in:
     - Section 2: Dimension scores with evidence (copy from Feature Implementation State file §7)
     - Section 3: Overall quality narrative — systemic issues, not just individual symptoms
     - Section 4: Gap analysis linking to the PD-TDI-XXX items from T3
     - Section 5: Recommended remediation sequence — order by dependency and impact
     - Section 6: Links to feature state file and tech debt items (FDD/TDD links N/A for Tier 1)
   - Update Feature Implementation State file §7 "Quality Assessment Report" link
   - Update master state: QAR ✅ for this feature (or N/A for As-Built Tier 1)

**T5. Assess User Documentation Coverage**: Same step as the parent task's Step 13. Tier 1 features with CLI commands, configuration, or user workflows still need this assessment.

   - **Purpose**: Apply the [Diátaxis Content Type Guide](../../guides/07-deployment/diataxis-content-type-guide.md) to populate the `### User Documentation` section in the [Feature Implementation State file](../../../doc/state-tracking/features) with one row per relevant content type.
   - **T5a — Apply decision matrix**: Identify which content types are relevant via the [decision matrix](../../guides/07-deployment/diataxis-content-type-guide.md#decision-matrix). Internal/architectural Tier 1 features may have no relevant types — that's valid (use a single `N/A` row with rationale).
   - **T5b — For each relevant content type, assess existing coverage**:
     - Grep `doc/user/handbooks/` for feature-related terms (CLI options, config keys, component names)
     - Categorize using the [status taxonomy](../../guides/07-deployment/diataxis-content-type-guide.md#status-taxonomy): `✅ Created — [link]` / `✅ Covered Elsewhere — [link]` / `❌ Needed`
   - **T5c — Populate state file**: Add one row per relevant content type to the `### User Documentation` section.
   - **T5d — Flag feature**: If any row is `❌ Needed`, set the feature to `📖 Needs User Docs` in [feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) to enter the [PF-TSK-081](../07-deployment/user-documentation-creation.md) queue post-onboarding.
   - Update master state: User Doc Audit ✅ for this feature

**T6. 🚨 CHECKPOINT**: Present completed Tier 1 deliverables (ADR if created, TDs if registered, QAR if Target-State, user-doc rows) to the human partner for review.

**T7. Update Feature Implementation State File** for the feature:
   - **§2 (Current State Summary)**: Reflect documentation completeness
   - **§3 (Documentation Inventory) → Design Documentation table**: For Tier 1, populate rows with `N/A — Tier 1 feature, design intent in §6`. Add ADR row if T2 produced one.
   - **§3 (Documentation Inventory) → User Documentation table**: Populated by T5c
   - **§8 (Notes & Next Steps)**: Update with documentation-complete status; replace any stale "pending documentation" markers with actual next actions

**T8. Update [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)**:
   - Set `📖 Needs User Docs` Status if T5d triggered it
   - ADR / QAR links live in the per-feature state file's `### Design Documentation` table (Tier 1 → §3 / Tier 2+ → §4 Documentation Inventory); they are NOT written to master feature-tracking.md columns (per PF-PRO-002 / PF-IMP-760)

**T9. Update [Master State](../../../doc/state-tracking/temporary/old/retrospective-master-state.md) After Each Session**:
   - Mark closure status per Tier 1 feature
   - Log session notes
   - **Complete feedback form for the session** (PF-TSK-066, not this companion — the parent task owns the feedback context)

**T10. Return to parent task for Phase 4** once all Tier 1 (and any Tier 2+) features in the current scope are closed. Phase 4 (Steps 18-27) covers cross-feature verification, pre-existing documentation gap analysis, framework improvement harvest, documentation map updates, and master state archive — these run once per onboarding effort, not per feature.

## ⚠️ MANDATORY Per-Feature Completion Checklist

**Per-feature Tier 1 closure is NOT complete until ALL items below are checked off. Phase 4 finalization runs from the parent task.**

- [ ] **Tier 1 path applies**: Feature is confirmed Tier 1 in [feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) (T1)
- [ ] **Optional ADR** (T2): Created if architectural decision worth recording, or noted as N/A in master state
- [ ] **Target-State Tier 1 only — Tech Debt items** (T3): Generated from §7 quality assessment, or "No new TDs" noted explicitly
- [ ] **Target-State Tier 1 only — Quality Assessment Report** (T4): Created via `New-QualityAssessmentReport.ps1 -Tier 1`, dimension scores filled, gap analysis linked, remediation sequence defined
- [ ] **User documentation coverage assessment** (T5): Per-content-type rows populated in Feature Implementation State file `### User Documentation`; `📖 Needs User Docs` flag set if any `❌ Needed`
- [ ] **CHECKPOINT** (T6): Deliverables reviewed and approved by human partner
- [ ] **Feature Implementation State file updated** (T7): §2 status, §3 Documentation Inventory (Design + User), §8 Next Steps
- [ ] **Feature Tracking updated** (T8): `📖 Needs User Docs` Status set if applicable; ADR / QAR rows added to per-feature state file's `### Design Documentation` table (NOT master columns — PF-PRO-002 / PF-IMP-760)
- [ ] **Master State updated** (T9): closure status per feature, session notes, feedback form for the session

## Related Resources

- [Parent task: Retrospective Documentation Creation](retrospective-documentation-creation.md) (PF-TSK-066) — full Phase 3 for Tier 2/3, plus Phase 4 finalization for all tiers
- [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) — where tier assignments originate
- [Codebase Feature Analysis (PF-TSK-065)](codebase-feature-analysis.md) — where dimension scores are populated
- [Feature Implementation State Tracking Guide](../../guides/04-implementation/feature-implementation-state-tracking-guide.md) — using the lightweight state file template
- [Diátaxis Content Type Guide](../../guides/07-deployment/diataxis-content-type-guide.md) — decision matrix + status taxonomy for T5
