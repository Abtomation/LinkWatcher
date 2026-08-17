---
variant_group: validation-dimension-paths
description: "Documentation Alignment dimension path for Dimension Validation — analysis steps and criteria for TDD alignment, ADR compliance, and API documentation accuracy"
---

# Documentation Alignment — Validation Dimension Path

> **Parent task**: [Dimension Validation](dimension-validation-task.md) (PF-TSK-092). Execute the shared process there; this path file supplies the dimension-specific content that plugs into the parent's steps 2, 3, 5, 7, 8, and 12, plus the tokens for steps 6 and 13.
>
> | `-ValidationType` (step 6) | `Dims` (step 13) |
> |---|---|
> | `DocumentationAlignment` | `DA` |
>
> **Scope note**: typically 3–4 features per session.

## AI Agent Role (parent: AI Agent Role)

**Role**: Documentation Specialist
**Mindset**: Detail-oriented, accuracy-focused, consistency-driven
**Focus Areas**: Documentation accuracy, TDD-code alignment, ADR compliance, API documentation completeness
**Communication Style**: Identify documentation gaps and inconsistencies, recommend specific documentation updates, ask about documentation standards when multiple approaches exist

## Dimension Context (parent step 2)

- **Technical Design Documents** - [TDD Directory](../../../doc/technical) - technical specifications to validate against implementation (Critical for this dimension)
- **Architecture Decision Records** - [ADR Directory](../../../doc/technical/adr) - architectural decisions to validate compliance
- **API Documentation** - [API Documentation](../../../doc/technical/api) - API specifications to validate against implementation
- **Feature Implementation State Files** - [Feature State Directory](../../../doc/state-tracking/features) - feature status, TDD/FDD links, and validation context
- **Documentation Standards** - [Documentation Guide](../../guides/05-validation/documentation-guide.md)

## Dimension Criteria (parent step 3)

Review documentation standards and alignment requirements. Apply the following criteria-handling rules:

> **Tier Assessment Verification**: For each feature, verify that the current tier assignment is still correct based on the feature's actual complexity and architectural significance. After confirming the tier, check that all documentation required for that tier level exists (e.g., Tier 2 requires TDD + FDD; Tier 3 additionally requires ADRs). Flag any missing required documentation as a finding.
>
> **Tier 1 features** lack TDDs by design. For TDD Alignment:
> - Substitute **Configuration/Code Documentation Accuracy**: validate that inline comments, docstrings, and README sections accurately describe the feature's behavior and interfaces.
> - Score the substituted criterion on the same 0–3 scale and note the substitution in the report.
>
> **ADR Compliance**: If ADRs exist for a feature, validate that the implementation complies with them. If no ADRs exist, skip this criterion — assessing whether an ADR should exist is handled by the Architectural Consistency dimension.
>
> **Evidence Requirements**: Every reported mismatch between documentation and code **must** include exact quoted text from the documentation (with file path and line number), exact quoted text from the code or actual behavior (with file path and line number), and a brief explanation of the discrepancy. This prevents false positives — if you cannot quote the specific text that is wrong, do not report it as a finding.

## Execution Analysis Steps (parent step 5)

5a. **TDD Alignment Analysis**: Compare Technical Design Documents with actual implementation to identify discrepancies
5b. **ADR Compliance Validation**: Verify that architectural decisions documented in ADRs are properly implemented and followed
5c. **API Documentation Accuracy**: Cross-reference API documentation with actual API implementations and interfaces
5d. **Documentation Completeness Assessment**: Identify missing documentation for implemented features and functionality
5e. **Integration Narrative Accuracy**: For features that participate in cross-feature workflows documented by Integration Narratives (`doc/technical/integration`), verify that:
   - The narrative accurately describes the current interaction patterns between features (compare against source code)
   - Component diagrams and data flow sequences reflect the actual implementation
   - Any TDD/Code divergences noted in the narrative are still accurate
   - If no Integration Narrative exists for a workflow where the feature participates, note this as a documentation gap (not a validation failure)
5f. **Root Cause Analysis**: For each significant documentation gap identified:
   - Identify which task in the development workflow should have created or updated the documentation (e.g., TDD Creation, Feature Implementation, Integration Narrative Creation, Code Refactoring)
   - Check whether that task's process steps or completion checklist explicitly require this documentation update
   - If the originating task lacks coverage, record it as a process improvement opportunity (via New-ProcessImprovement.ps1) in addition to the documentation remediation action item

## Scoring & Findings (parent steps 7–8)

- Apply the 4-point scoring system (0–3) to each documentation alignment criterion.
- Record specific documentation gaps, inconsistencies, and improvement recommendations.

## Remediation Prioritization (parent step 12)

Create action items for documentation improvements.

## Dimension Outputs (parent: Outputs)

- **Documentation Alignment Validation Report** - created in `doc/validation/reports/documentation-alignment/PD-VAL-XXX-documentation-alignment-features-[feature-range].md`
- **Documentation Gap Analysis** - analysis of missing or outdated documentation
- **Remediation Action Items** - recommendations for improving documentation alignment and completeness
