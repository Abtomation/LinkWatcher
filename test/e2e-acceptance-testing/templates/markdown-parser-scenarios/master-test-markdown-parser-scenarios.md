---
id: TE-E2G-003
type: E2E Acceptance Test Group
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
test_cases_count: 1
estimated_duration: 5 minutes
created: 2026-03-16
updated: 2026-03-16
---

# Master Test: markdown-parser-scenarios

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher is running in background (`process-framework/tools/linkWatcher/start_linkwatcher_background.ps1`)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group markdown-parser-scenarios`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] Test fixtures copied to a **non-gitignored** location (LinkWatcher does not watch gitignored paths)

## Quick Validation Sequence

1. **Move markdown file and verify link updates (TE-E2E-004)**
   - Action: Move `test_project/docs/readme.md` to `test_project/archive/readme.md` (create `archive/` directory first)
   - Tool: File Explorer (drag and drop) or `mkdir archive && mv docs/readme.md archive/`
   - Target: `workspace/.../project/test_project/docs/readme.md` → `workspace/.../project/test_project/archive/readme.md`
   - Expected: `MP-001_standard_links.md` and `LR-001_standard_links_parser.md` update `test_project/docs/readme.md` → `test_project/archive/readme.md`. Links inside code blocks (`MP-004`) and inline code (`MP-003`) are NOT updated. Special character filename references (`MP-010`) are unaffected.

## Pass Criteria

- [ ] `MP-001_standard_links.md` link updated from `test_project/docs/readme.md` to `test_project/archive/readme.md`
- [ ] `LR-001_standard_links_parser.md` link updated from `test_project/docs/readme.md` to `test_project/archive/readme.md`
- [ ] Links inside code blocks and inline code are NOT updated
- [ ] Special character filename references (`MP-010`) are unaffected
- [ ] No errors in LinkWatcher log
- [ ] Run `Verify-TestResult.ps1 -Group markdown-parser-scenarios` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-004 | [TE-E2E-004-markdown-link-update-on-file-move/test-case.md](TE-E2E-004-markdown-link-update-on-file-move/test-case.md) | Move files referenced in markdown links (standard, special characters, quoted) and verify LinkWatcher updates all references |

## Notes

- **Gitignore constraint**: LinkWatcher does not monitor gitignored paths. The formal `workspace/` directory is gitignored, so this test must be executed with fixtures in a non-ignored location.
- This group includes `MP-010` which tests BUG-007 regression (special character filenames). Moving one of those files is a separate valuable test scenario not yet covered by a test case.
- Test fixtures include multiple markdown parser scenario files (MP-001 through MP-010, LR-001) covering standard links, code blocks, inline code, HTML, images, malformed links, escaped characters, and special character filenames
