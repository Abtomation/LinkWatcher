---
id: TE-E2G-008
type: E2E Acceptance Test Group
feature_ids: ["2.1.1", "2.2.1", "1.1.1"]
workflow: WF-005
test_cases_count: 1
estimated_duration: 5 minutes
created: 2026-03-18
updated: 2026-03-18
---

# Master Test: multi-format-references

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher running and monitoring workspace
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group multi-format-references`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] Project has MD, YAML, JSON, and Python files all referencing `data/schema.md`

## Quick Validation Sequence

1. **Move file referenced from all formats**
   - Action: Move `data/schema.md` to `reference/schema.md`
   - Tool: File Explorer
   - Target: `data/schema.md`
   - Expected: All 4 formats (`docs/index.md`, `config/paths.yaml`, `config/manifest.json`, `scripts/loader.py`) have paths updated from `data/schema.md` to `reference/schema.md`

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No errors in LinkWatcher log
- [ ] Run `Verify-TestResult.ps1 -Group multi-format-references` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-018 | [TE-E2E-018-file-referenced-from-all-formats/test-case.md](TE-E2E-018-file-referenced-from-all-formats/test-case.md) | File referenced from MD, YAML, JSON, and Python simultaneously — all formats updated on move |

## Notes

This is the only test in this group. If it fails, check parser-specific tests in the yaml-json-python-parser-scenarios and markdown-parser-scenarios groups.
