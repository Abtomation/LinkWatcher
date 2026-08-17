---
variant_group: validation-dimension-paths
description: "Architectural Consistency dimension path for Dimension Validation — analysis steps and criteria for architectural pattern adherence, ADR compliance, and interface consistency"
---

# Architectural Consistency — Validation Dimension Path

> **Parent task**: [Dimension Validation](dimension-validation-task.md) (PF-TSK-092). Execute the shared process there; this path file supplies the dimension-specific content that plugs into the parent's steps 2, 3, 5, 7, 8, and 12, plus the tokens for steps 6 and 13.
>
> | `-ValidationType` (step 6) | `Dims` (step 13) |
> |---|---|
> | `ArchitecturalConsistency` | `AC` |

## AI Agent Role (parent: AI Agent Role)

**Role**: Software Architect
**Mindset**: Systematic, pattern-focused, consistency-oriented
**Focus Areas**: Architectural patterns, design principles, interface contracts, ADR compliance
**Communication Style**: Identify architectural deviations and inconsistencies, recommend pattern improvements, ask about architectural trade-offs when multiple valid approaches exist

## Dimension Context (parent step 2)

- **Architecture Decision Records** - [ADR Directory](../../../doc/technical) - architectural decisions to validate against (Critical for this dimension)
- **Technical Design Documents** - [TDD Directory](../../../doc/technical/tdd) - technical specifications for selected features
- **Codebase Structure** - source code for selected features

## Dimension Criteria (parent step 3)

Review architectural patterns, design principles, and interface contracts that should be validated.

## Execution Analysis Steps (parent step 5)

5a. **Analyze Architectural Patterns**: Examine each feature's implementation for adherence to established patterns (Repository, Service Layer, etc.)
5b. **Validate ADR Compliance**: Check that implementation follows architectural decisions documented in ADRs
   > **When no ADR exists for a feature**: Assess whether the feature's architectural decisions are significant enough to warrant an ADR (e.g., non-obvious pattern choices, trade-offs with alternatives). If an ADR should exist, note it as a finding and recommend creating one using [New-ArchitectureDecision.ps1](../../scripts/file-creation/02-design/New-ArchitectureDecision.ps1) with the [`architecture-decision` craft skill](../../../.claude/skills/architecture-decision/SKILL.md) as the customization-craft home. If not (feature follows established project patterns without notable decisions), skip this criterion.
5c. **Assess Interface Consistency**: Verify that interfaces follow consistent patterns and contracts across features
   > **Justified divergence check**: Not every pattern difference is a defect. Before flagging an inconsistency, verify that different design constraints (stateless vs stateful, pure vs side-effecting, hot-path vs setup-only) don't justify the divergence. "No issues found" is a valid validation outcome — do not manufacture findings to fill a report.

## Scoring & Findings (parent steps 7–8)

- Apply the 4-point scoring system (0–3) to each validation criterion.
- Record specific architectural deviations, inconsistencies, and recommendations.

## Remediation Prioritization (parent step 12)

Create action items for architectural improvements.

## Dimension Outputs (parent: Outputs)

- **Architectural Consistency Validation Report** - created in `doc/validation/reports/architectural-consistency/PD-VAL-XXX-architectural-consistency-features-[feature-range].md`
- **Remediation Action Items** - architectural improvements for features scoring below the quality threshold
