# Debt Identification Criteria

Per-category criteria for recognizing technical debt during systematic code analysis. Apply them
with the core test from SKILL.md (impedes development · ongoing cost · conscious trade-off or
outdated · measurable remediation value) — focus on debt that impacts business value, not code
aesthetics.

## Contents

1. [Code Quality Debt](#1-code-quality-debt)
2. [Architecture Debt](#2-architecture-debt)
3. [Performance Debt](#3-performance-debt)
4. [Security Debt](#4-security-debt)
5. [Testing Debt](#5-testing-debt)
6. [Documentation Debt](#6-documentation-debt)
7. [Assessment Methodology](#assessment-methodology)
8. [Calibration Troubleshooting](#calibration-troubleshooting)

## 1. Code Quality Debt

Code that is difficult to understand, maintain, or extend due to poor structure or practices.

- **High-priority indicators**: cyclomatic complexity > 10; duplication > 50 lines; method
  length > 100 lines; class size > 500 lines.
- **Medium-priority indicators**: unclear/misleading names; magic numbers/strings; commented-out
  dead code; formatting that breaks project style.
- **Shape to watch**: a 150-line method mixing validation, business logic, and formatting; mutable
  shared state with no clear ownership.

## 2. Architecture Debt

Structural issues that make the system harder to understand, modify, or extend.

- **High-priority indicators**: tight coupling to concrete implementations; missing abstractions
  over repeated patterns; circular dependencies; god objects.
- **Medium-priority indicators**: inconsistent patterns for similar problems (e.g. some modules
  use a Repository, others hit the DB directly); missing interfaces; business logic mixed into UI
  or data access; superseded architectural patterns.
- **Shape to watch**: presentation code making direct API calls and processing data in a render
  path.

## 3. Performance Debt

Code causing unnecessary performance degradation or resource consumption.

- **High-priority indicators**: resource leaks (undisposed objects, unremoved listeners); O(n²)
  where O(n) is available; unnecessary rebuild/recompute per render or request; blocking
  operations on the main thread.
- **Medium-priority indicators**: unused dependencies inflating bundles; wrong data structure for
  the use case; multiple network calls where one suffices; unoptimized assets.
- **Shape to watch**: a connect/subscribe in startup with no cleanup path; expensive transforms
  run per item on every request with no caching or pagination.

## 4. Security Debt

Code introducing vulnerabilities or ignoring security best practices.

- **High-priority indicators**: dependencies with known vulnerabilities; hardcoded secrets in
  source; missing input validation/sanitization; weak authentication or authorization patterns.
- **Medium-priority indicators**: HTTP where HTTPS belongs; excessive permissions; sensitive data
  stored unencrypted; missing security headers on web deployments.

## 5. Testing Debt

Insufficient or poor-quality tests that reduce confidence in changes.

- **High-priority indicators**: critical paths untested; < 70% coverage on important modules;
  flaky tests; no integration tests.
- **Medium-priority indicators**: obsolete test data/scenarios; tests hard to understand or
  maintain; happy-path-only coverage; a suite too slow to run routinely.

## 6. Documentation Debt

Missing, outdated, or poor-quality documentation that impedes development.

- **High-priority indicators**: public APIs undocumented; architecture docs that no longer match
  the implementation; missing/incorrect setup instructions; complex business rules unexplained.
- **Medium-priority indicators**: complex algorithms uncommented; outdated README; no
  troubleshooting guidance; inconsistent documentation style.

## Assessment Methodology

1. **Automated first**: run the project's linter, type checker, and outdated-dependency check;
   use the output as candidate leads, not conclusions.
2. **Manual review**: recent commits for patterns, high-change-frequency files, TODO/FIXME
   markers, error logs and bug reports.
3. **Per-item impact questions** — business: user experience? development velocity? maintenance
   cost? failure/security risk? — technical: comprehension cost? measurable degradation?
   scalability limit? integration friction?
4. **Per-item effort questions**: scope of change (files/components), dependencies involved,
   testing needed, likelihood of unintended consequences, required expertise and coordination,
   realistic timeline.

## Calibration Troubleshooting

- **Debt vs. design choice unclear** — apply the impediment test (does it slow future work?), the
  cost test (ongoing cost?), and business impact; when still unclear, discuss with the human
  partner.
- **Overwhelming item count** — high-impact first, group related issues into initiatives, cap the
  cycle, filter low-priority automatically.
- **Inconsistent results across assessors/sessions** — calibrate on concrete examples per
  category; record the reasoning with each item so later cycles can align.
