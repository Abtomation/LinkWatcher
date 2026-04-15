---
id: TE-E2G-013
type: E2E Acceptance Test Group
feature_ids: ["0.1.1", "2.1.1", "6.1.1"]
workflow: WF-009
test_cases_count: 3
estimated_duration: 10 minutes
created: 2026-04-12
updated: 2026-04-12
---

# Master Test: link-validation-audit

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change to the validation feature (6.1.1). If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher is installed (`pip install -e .` from project root)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group link-validation-audit`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] No other LinkWatcher instance is running against the workspace

## Quick Validation Sequence

1. **Validate clean workspace (TE-E2E-026)**
   - Action: Run `python main.py --validate --project-root <workspace>/TE-E2E-026/project --log-file <workspace>/TE-E2E-026/validate.log`
   - Tool: Command Line
   - Target: TE-E2E-026 project fixtures (all links valid)
   - Expected: Exit code 0, report says "No broken links found.", `Broken links  : 0`

2. **Detect broken links across formats (TE-E2E-027)**
   - Action: Run `python main.py --validate --project-root <workspace>/TE-E2E-027/project --log-file <workspace>/TE-E2E-027/validate.log`
   - Tool: Command Line
   - Target: TE-E2E-027 project fixtures (3 intentional broken links in .md, .json, .yaml)
   - Expected: Exit code 1, report shows `Broken links  : 3`, all three listed with source:line and target

3. **Ignore rules suppress matching broken links (TE-E2E-028)**
   - Action: Run `python main.py --validate --project-root <workspace>/TE-E2E-028/project --config <workspace>/TE-E2E-028/project/linkwatcher-config.yaml --log-file <workspace>/TE-E2E-028/validate.log`
   - Tool: Command Line
   - Target: TE-E2E-028 project fixtures (2 broken links, 1 suppressed by .linkwatcher-ignore)
   - Expected: Exit code 1, report shows `Broken links  : 1`, suppressed link absent from report

## Pass Criteria

- [ ] Step 1: exit code 0, report clean
- [ ] Step 2: exit code 1, report lists exactly 3 broken links
- [ ] Step 3: exit code 1, report lists exactly 1 broken link (suppressed link absent)
- [ ] All project fixture files unchanged after each step (validation is read-only)

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-026 | [TE-E2E-026-validate-clean-workspace/test-case.md](TE-E2E-026-validate-clean-workspace/test-case.md) | Workspace with all valid links — validate reports clean, exit code 0 |
| TE-E2E-027 | [TE-E2E-027-validate-broken-links-detected/test-case.md](TE-E2E-027-validate-broken-links-detected/test-case.md) | Workspace with intentional broken links — validate detects and reports all, exit code 1 |
| TE-E2E-028 | [TE-E2E-028-validate-ignore-rules-suppress/test-case.md](TE-E2E-028-validate-ignore-rules-suppress/test-case.md) | Broken links matching .linkwatcher-ignore rules are suppressed from report |

## Notes

- Validation mode does not start the file watcher — it scans and exits immediately
- No lock file is created during validation
- Default validation extensions: `.md`, `.yaml`, `.yml`, `.json` — source code files (.py, .ps1) are not scanned
- Report file location is determined by `--log-file` (parent directory) or project root (fallback)
