# Test Case: E2E-004 Markdown Link Update on File Move

## Metadata

| Field | Value |
|-------|-------|
| Test Case ID | E2E-004 |
| Group | markdown-parser-scenarios (E2E-GRP-03) |
| Feature | 2.1.1 — Link Parsing System |
| Priority | P1 |
| Estimated Duration | 5 minutes |
| Created | 2026-03-16 |
| Last Updated | 2026-03-16 |
| Source | Feature 2.1.1 Markdown parser, BUG-007 regression |

## Preconditions

- [ ] LinkWatcher is running in background
- [ ] Test fixtures copied to a **non-gitignored** location (LinkWatcher does not watch gitignored paths)
- [ ] All files in `test_project/` exist and are accessible

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/MP-001_standard_links.md` | Standard markdown link test | 7 markdown links to test_project files |
| `project/MP-010_special_characters_filenames.md` | Special character filename test (BUG-007 regression) | Links to files with spaces, ampersands, parentheses, brackets |
| `project/LR-001_standard_links_parser.md` | Parser-level link detection | 9 markdown links across file types |
| `project/MP-002` through `MP-009` | Additional parser scenario files | Code blocks, inline code, HTML, images, malformed, escaped chars |
| `project/test_project/` | Simulated project with real files | docs/, config/, assets/, api/, files with special characters |

## Steps

1. **Copy fixtures**: Copy the entire `project/` directory contents to a non-gitignored location in the project
   - **Tool**: File Explorer or command line
   - **Note**: Must be outside `test/manual-testing/workspace/` (gitignored) for LinkWatcher to detect changes

2. **Start LinkWatcher**: Ensure LinkWatcher is running and has completed initial scan
   - **Verify**: Check LinkWatcher_run/LinkWatcherLog_20260317-103751.txt for "Initial scan complete"

3. **Move file**: Move `test_project/docs/readme.md` to `test_project/archive/readme.md`
   - **Tool**: File Explorer (drag and drop) or `mkdir archive && mv docs/readme.md archive/`
   - **Target**: Create `archive/` subdirectory, move `readme.md` into it

4. **Wait**: Wait 10–15 seconds for LinkWatcher to detect the move
   - **Duration**: 10–15 seconds
   - **Observe**: Check LinkWatcher log for move detection of `readme.md`

5. **Verify standard links**: Open `MP-001_standard_links.md` and check the Documentation link
   - **Before**: `[Documentation](test_project/docs/readme.md)`
   - **After**: `[Documentation](test_project/archive/readme.md)`

6. **Verify parser links**: Open `LR-001_standard_links_parser.md` and check the Documentation link
   - **Before**: `[Documentation](test_project/docs/readme.md)`
   - **After**: `[Documentation](test_project/archive/readme.md)`

## Expected Results

### File Changes

| File | Change |
|------|--------|
| `MP-001_standard_links.md` | `test_project/docs/readme.md` → `test_project/archive/readme.md` (1 occurrence) |
| `LR-001_standard_links_parser.md` | `test_project/docs/readme.md` → `test_project/archive/readme.md` (1 occurrence) |
| `test_project/README.md` | `docs/readme.md` → `archive/readme.md` if referenced (check) |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows move detection for `readme.md`
- Only markdown files containing references to `readme.md` are modified
- Special character filenames in `MP-010` are NOT affected (different files)
- Code block and inline code references in `MP-003`, `MP-004` should NOT be updated (parser correctly ignores code contexts)

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase E2E-004` (if workspace not gitignored)
- [ ] **Visual inspection**: Open modified .md files and confirm link targets updated
- [ ] **Log check**: LinkWatcher log shows update messages for affected files

## Pass Criteria

- [ ] All markdown link references to `test_project/docs/readme.md` updated to `test_project/archive/readme.md`
- [ ] Links inside code blocks (`MP-004`) NOT updated
- [ ] Links inside inline code (`MP-003`) NOT updated
- [ ] Special character filename references (`MP-010`) unaffected
- [ ] No errors in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which file(s) and pattern type(s) were not updated correctly
- Create a bug report using `New-BugReport.ps1` if the failure indicates a parser defect

## Notes

- **Gitignore constraint**: LinkWatcher does not monitor gitignored paths. The formal `workspace/` directory is gitignored, so this test must be executed with fixtures in a non-ignored location.
- **BUG-007 regression**: `MP-010` specifically tests special character filenames that were broken before BUG-007 fix. Moving one of those files (e.g., `file with spaces.txt`) is a separate valuable test scenario.
