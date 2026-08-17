---
variant_group: validation-dimension-paths
description: "Code Quality & Standards dimension path for Dimension Validation — analysis steps and criteria for code quality standards, SOLID principles, and best practices adherence"
---

# Code Quality & Standards — Validation Dimension Path

> **Parent task**: [Dimension Validation](dimension-validation-task.md) (PF-TSK-092). Execute the shared process there; this path file supplies the dimension-specific content that plugs into the parent's steps 2, 3, 5, 7, 8, and 12, plus the tokens for steps 6 and 13.
>
> | `-ValidationType` (step 6) | `Dims` (step 13) |
> |---|---|
> | `CodeQuality` | `CQ` |

## AI Agent Role (parent: AI Agent Role)

**Role**: Code Quality Auditor
**Mindset**: Detail-oriented, standards-focused, improvement-oriented
**Focus Areas**: Code quality metrics, SOLID principles, coding best practices, maintainability assessment
**Communication Style**: Provide specific examples of quality issues with concrete improvement suggestions, ask about quality trade-offs when multiple approaches exist

## Dimension Context (parent step 2)

- **Coding Style Guide** - Official coding standards for your project's language
- **SOLID Principles Documentation** - Reference materials for SOLID principles assessment
- **Test Suites** - existing tests for coverage and quality analysis
- **Code Quality Tools Configuration** - linting and analysis configuration files

## Dimension Criteria (parent step 3)

Review project coding style guides, SOLID principles, and best practices documentation.

## Execution Analysis Steps (parent step 5)

5a. **Code Style Analysis**: Review code formatting, naming conventions, and organizational structure against project coding standards
5b. **SOLID Principles Assessment**: Evaluate each feature's adherence to Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion principles
5c. **Best Practices Review**: Check component composition patterns, state management implementation, and platform-specific optimizations
   - **Layer-Boundary Validation** *(if `doc/project-config.json::layering_rules.layers` is non-empty)*: Read the declared layer rules and emit findings for source-code violations. See [feature-validation-guide.md § Layer-Boundary Validation](../../guides/05-validation/feature-validation-guide.md#layer-boundary-validation) for the detection workflow and a worked example. Empty `layers` = skip this sub-check (default).
5d. **Quality Metrics Evaluation**: Assess cyclomatic complexity, code duplication, method/class sizes, and maintainability indicators

## Scoring & Findings (parent steps 7–8)

- Apply the 4-point scoring system (0–3) to each quality criterion.
- Record specific quality issues, violations, and improvement recommendations.

## Remediation Prioritization (parent step 12)

Create action items for code quality improvements.

## Dimension Outputs (parent: Outputs)

- **Code Quality Validation Report** - created in `doc/validation/reports/code-quality/PD-VAL-XXX-code-quality-features-[feature-range].md`
- **Quality Improvement Recommendations** - for features scoring below the quality threshold
