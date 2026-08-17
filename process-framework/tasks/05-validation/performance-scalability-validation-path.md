---
variant_group: validation-dimension-paths
description: "Performance & Scalability dimension path for Dimension Validation — analysis steps and criteria for performance characteristics, resource efficiency, and scalability patterns"
---

# Performance & Scalability — Validation Dimension Path

> **Parent task**: [Dimension Validation](dimension-validation-task.md) (PF-TSK-092). Execute the shared process there; this path file supplies the dimension-specific content that plugs into the parent's steps 2, 3, 5, 7, 8, and 12, plus the tokens for steps 6 and 13.
>
> | `-ValidationType` (step 6) | `Dims` (step 13) |
> |---|---|
> | `PerformanceScalability` | `PE` |

## AI Agent Role (parent: AI Agent Role)

**Role**: Performance Engineer
**Mindset**: Measurement-driven, bottleneck-aware, scalability-focused
**Focus Areas**: Response times, resource consumption, algorithmic complexity, concurrency patterns, caching strategies, I/O efficiency
**Communication Style**: Quantify performance characteristics where possible, identify scalability ceilings and bottlenecks, ask about performance requirements and acceptable latency thresholds

## Dimension Context (parent step 2)

- **Technical Design Documents** - [TDD Directory](../../../doc/technical/tdd) - performance requirements and design constraints
- **Performance Test Suites** - existing performance/benchmark tests
- **Configuration Files** - timeout settings, buffer sizes, thread pool configurations
- **Architecture Decision Records** - [ADR Directory](../../../doc/technical/architecture) - performance-related architectural decisions

## Dimension Criteria (parent step 3)

Review performance requirements from TDDs, identify critical paths, and establish baseline expectations.

## Execution Analysis Steps (parent step 5)

5a. **Algorithmic Complexity Analysis**: Review core algorithms for time and space complexity — identify O(n²) or worse patterns, unnecessary iterations, and suboptimal data structures
5b. **Resource Consumption Assessment**: Evaluate memory allocation patterns, file handle management, connection pooling, and thread/process lifecycle management
5c. **I/O Efficiency Review**: Analyze file operations, network calls, and database queries for batching opportunities, unnecessary reads/writes, and blocking operations
5d. **Concurrency & Thread Safety**: Assess thread synchronization, lock contention risks, deadlock potential, and opportunities for parallelization
5e. **Scalability Pattern Evaluation**: Review how features behave as data volume, file count, or project size increases — identify linear vs. non-linear scaling characteristics
5f. **Caching & Optimization Review**: Evaluate existing caching strategies, identify opportunities for memoization, lazy loading, or precomputation

## Scoring & Findings (parent steps 7–8)

- Apply the 4-point scoring system (0–3) to each performance criterion.
- Record specific performance bottlenecks, scalability risks, and optimization recommendations.

## Remediation Prioritization (parent step 12)

Create action items for performance improvements — prioritize by impact on user experience.

## Dimension Outputs (parent: Outputs)

- **Performance & Scalability Validation Report** - created in `doc/validation/reports/performance-scalability/PD-VAL-XXX-performance-scalability-features-[feature-range].md`
- **Performance Optimization Recommendations** - for features scoring below the quality threshold
