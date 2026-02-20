---
id: PD-TDD-032
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 5.1.2
feature_name: Test Automation
tier: 2
retrospective: true
---

# Test Automation - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Test Automation, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [5.1.2 Implementation State](../../../../process-framework/state-tracking/features/5.1.2-test-automation-implementation-state.md) and source code analysis.

## Technical Overview

Test automation is configured within the CI workflow (`ci.yml`) test job as a sequence of `run_tests.py` invocations. Each test category is executed as a separate workflow step with explicit CLI flags. The feature bridges 4.1.1 (test framework) and 5.1.1 (CI pipeline) by defining execution order, failure tolerance, and artifact collection.

## Component Architecture

### CI Test Job Steps

| Step | Command | Failure Mode | Purpose |
|------|---------|-------------|---------|
| Test Discovery | `python run_tests.py --discover` | Strict | Verify test collection works |
| Unit Tests | `python run_tests.py --unit --coverage` | Strict | Core logic validation + coverage |
| Parser Tests | `python run_tests.py --parsers` | Strict | Parser correctness |
| Integration Tests | `python run_tests.py --integration` | Soft (`continue-on-error`) | Cross-component workflows |

### CI Performance Job Steps

| Step | Command | Failure Mode | Purpose |
|------|---------|-------------|---------|
| Performance Tests | `python run_tests.py --performance` | Soft (`continue-on-error`) | Benchmark validation |
| Artifact Upload | `actions/upload-artifact@v3` | N/A | Store performance results |

### Execution Flow

```
[test job - runs on every push/PR]
  discover → unit+coverage → parsers → integration → codecov upload

[performance job - main branch push only, gated behind test]
  performance tests → artifact upload
```

### run_tests.py CLI Interface

The test automation relies on `run_tests.py` flags to select categories:
- `--discover`: Test collection validation
- `--unit`: Unit tests only
- `--parsers`: Parser tests only
- `--integration`: Integration tests only
- `--performance`: Performance tests only
- `--coverage`: Enable pytest-cov collection
- `--quick`: Fast subset (unit + parsers)
- `--all`: All test categories

## Key Technical Decisions

### Sequential Test Category Execution

Test categories run sequentially within a single job rather than as parallel jobs. This avoids repeated dependency installation overhead and provides ordered feedback (most stable tests first). Categories ordered: discover → unit → parsers → integration.

### Performance Tests Gated Behind Main Branch

Performance job uses `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` and `needs: [test]`. PRs get fast feedback without waiting for expensive performance benchmarks. Regressions are caught post-merge.

## Dependencies

| Component | Usage |
|-----------|-------|
| `run_tests.py` | Test execution CLI (category selection, coverage flags) |
| `.github/workflows/ci.yml` | Workflow definition containing test automation steps |
| `pytest` / `pytest-cov` | Test execution engine and coverage collection |
| `requirements-test.txt` | Test dependency specification |
