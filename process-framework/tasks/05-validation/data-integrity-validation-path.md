---
variant_group: validation-dimension-paths
description: "Data Integrity dimension path for Dimension Validation — analysis steps and criteria for data consistency, constraint enforcement, migration safety, and backup/recovery patterns"
---

# Data Integrity — Validation Dimension Path

> **Parent task**: [Dimension Validation](dimension-validation-task.md) (PF-TSK-092). Execute the shared process there; this path file supplies the dimension-specific content that plugs into the parent's steps 2, 3, 5, 7, 8, and 12, plus the tokens for steps 6 and 13.
>
> | `-ValidationType` (step 6) | `Dims` (step 13) |
> |---|---|
> | `DataIntegrity` | `DI` |

## AI Agent Role (parent: AI Agent Role)

**Role**: Data Quality Engineer
**Mindset**: Consistency-focused, corruption-prevention-oriented, recovery-aware
**Focus Areas**: Data validation rules, constraint enforcement, referential integrity, migration safety, idempotency, backup/recovery, data transformation correctness
**Communication Style**: Identify data corruption risks and integrity gaps, recommend defensive patterns, ask about data criticality levels and acceptable data loss thresholds

## Dimension Context (parent step 2)

- **Database Schema Designs** - [Schema Directory](../../../doc/technical/database/schemas) - data model specifications
- **Technical Design Documents** - [TDD Directory](../../../doc/technical/tdd) - data handling design specifications
- **Test Suites** - existing data integrity and edge case tests

## Dimension Criteria (parent step 3)

Review data model specifications, constraint requirements, and transaction consistency expectations.

## Execution Analysis Steps (parent step 5)

5a. **Input Data Validation Review**: Examine data entry points for proper type checking, range validation, format enforcement, and handling of null/empty/malformed inputs
5b. **Constraint Enforcement Analysis**: Verify that uniqueness constraints, referential integrity, business rules, and invariants are enforced at the appropriate layer (database, application, or both)
5c. **Data Transformation Correctness**: Review data transformation pipelines for lossless conversion, proper encoding handling, rounding errors, and edge case handling (empty collections, boundary values)
5d. **Concurrent Access Safety**: Assess data operations under concurrent access — race conditions, dirty reads, lost updates, and proper use of transactions or optimistic locking
5e. **Error Recovery & Idempotency**: Evaluate how data operations handle failures — partial writes, interrupted transactions, retry safety, and rollback completeness
5f. **Backup & Recovery Patterns**: Review data persistence for backup capabilities, recovery procedures, and data export/import integrity

## Scoring & Findings (parent steps 7–8)

- Apply the 4-point scoring system (0–3) to each data integrity criterion.
- Record specific data integrity risks, constraint gaps, and improvement recommendations.

## Remediation Prioritization (parent step 12)

Create action items for data integrity improvements — prioritize by data loss risk severity.

## Dimension Outputs (parent: Outputs)

- **Data Integrity Validation Report** - created in `doc/validation/reports/data-integrity/PD-VAL-XXX-data-integrity-features-[feature-range].md`
- **Data Integrity Improvement Recommendations** - for features scoring below the quality threshold
