# Post-Move Remaining `doc/process-framework` References (Run 2)

> Generated: 2026-03-31 after moving `doc/process-framework` → `process-framework/`
> Total: **69 files, ~143 remaining references**
>
> **LinkWatcher processing time**: ~5 minutes 44 seconds (07:55:22 → 08:01:06)
> - 830 files moved detected
> - 7,635 references updated automatically
> - 612 directory-path references updated
> - Log rotated during processing

---

## Comparison with Previous Run (Run 1)

| Metric | Run 1 (2026-03-30) | Run 2 (2026-03-31) | Change |
|--------|--------------------|--------------------|--------|
| **Processing time** | ~2 hours 3 minutes | ~5 minutes 44 seconds | **95% faster** |
| **Files moved** | 813 | 830 | +17 |
| **References updated** | 2,003 | 7,635 | **+281%** |
| **Directory-path refs updated** | 283 | 612 | **+116%** |
| **Remaining files** | ~140 | 69 | **-51%** |
| **Remaining references** | ~450 | ~143 | **-68%** |
| **Log rotations** | 3 (~40,000+ lines) | 1 | Reduced |

### Files Fixed by New Version (47 files no longer have remaining refs)

These files had remaining `doc/process-framework` references after Run 1 but are now fully updated in Run 2:

- `dev.bat` — `.bat` file type now monitored or paths updated
- `pyproject.toml` — `.toml` content now handled
- `process-framework/scripts/IdRegistry.psm1` — PowerShell string literals now updated
- `process-framework/scripts/AUTOMATION-USAGE-GUIDE.md` — Code block paths now updated
- `process-framework/ai-tasks.md` — Code block `cd` commands now updated
- `process-framework/tasks/README.md`
- `process-framework/infrastructure/process-framework-task-registry.md`
- `process-framework/templates/README.md`
- `process-framework/templates/support/structure-change-state-template.md`
- `process-framework/templates/support/structure-change-state-content-update-template.md`
- `process-framework/templates/support/structure-change-state-rename-template.md`
- `process-framework/templates/support/temp-process-improvement-state-template.md`
- `test/automated/unit/test_database.py` — Python string literals now updated
- `test/automated/parsers/test_generic.py` — Python string literals now updated
- `test/automated/parsers/test_json.py` — Python string literals now updated
- `test/automated/bug-validation/PD-BUG-021_directory_path_detection_validation.py` — Python string literals now updated
- `test/e2e-acceptance-testing/README.md` — Code block content now updated
- `test/state-tracking/permanent/test-tracking.md` — Backtick-quoted paths now updated
- `test/e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/test-case.md`
- 28 additional task/guide/template markdown files (code block `cd` commands, backtick paths, prose paths)

---

## Analysis: Why LinkWatcher Didn't Update These

Each remaining reference is traced to a specific parser capability gap. The analysis is based on reading the actual parser source code, heuristic functions (`looks_like_file_path`, `looks_like_directory_path`), and LinkWatcher logs confirming which files were scanned.

**Key technical context:**
- The markdown parser skips only ```` ```mermaid ```` blocks — all other fenced code blocks ARE scanned
- The YAML/JSON parsers walk the parsed tree and check each **complete string value** against path heuristics
- `looks_like_file_path()` rejects strings where any path segment has 3+ space-separated words starting with uppercase (PD-BUG-028 prose filter)
- `looks_like_directory_path()` rejects strings containing `@`, `?`, `&`, `=`, `%`, `:`, `*`, `<`, `>`, `|`
- `.claude/` is NOT in the `ignored_directories` set — the file IS scanned (confirmed in logs)

---

## Root-level config files

- [ ] `CLAUDE.md` (1 ref) — Line 79: `doc/process-framework/` inside a fenced code block (` ``` ` without language tag). **Should update? YES.** **Why missed**: The markdown parser DOES scan non-mermaid code blocks, and the `bare_path_pattern` regex requires at least 2 path segments (`(/?[a-zA-Z0-9_.][a-zA-Z0-9_.\-]*(?:[/\\][a-zA-Z0-9_.\-]+){2,}/?)`). The path `doc/process-framework/` has exactly 2 segments and includes a trailing `/`. The bare_path_pattern should match this. **Root cause investigation needed** — may be a regex edge case with the trailing slash, or the path was detected but the updater couldn't match it as a reference target because it's a directory prefix (stored in DB as the full parsed string, not a resolvable file target).

- [ ] `.pre-commit-config.yaml` (1 ref) — Line 36: YAML value `pwsh.exe -ExecutionPolicy Bypass -File doc/process-framework/scripts/test/Run-Tests.ps1 -Quick`. **Scanned: YES** (YamlParser, confirmed in logs). **Should update? YES.** **Why missed**: The YAML parser checks the **entire string value** against path heuristics. `looks_like_file_path()` returns `True` (the string contains `/`), so the entire 94-character command string is stored as `link_target`. When LinkWatcher searches for references to the moved path `doc/process-framework`, it can't match because the stored target is the full command string, not just the embedded path. The YAML parser has no mechanism to extract sub-paths from within larger string values.

- [ ] `.claude/settings.local.json` (1 ref) — Line 8: JSON value `"Bash(python doc/process-framework/scripts/feedback_db.py *)"`. **Scanned: YES** (JsonParser, confirmed in logs). **Should update? YES.** **Why missed**: The JSON parser checks the **entire string value**. `looks_like_directory_path()` rejects this string because it contains `*` (in the suspicious characters list). `looks_like_file_path()` also likely fails because `os.path.splitext()` on the full string produces a non-standard extension. Even if detected, the stored target would be the full `Bash(...)` string, not the embedded path. Same fundamental issue as the YAML case — no sub-path extraction from compound strings.

## Product docs (`doc/product-docs/`)

- [ ] `doc/product-docs/PD-id-registry.json` (1) — Line 228: `"main": "doc/process-framework/state-tracking"`. **Scanned: YES** (JsonParser). **Should update? YES.** **Why missed**: This is puzzling — `looks_like_directory_path("doc/process-framework/state-tracking")` should return `True` (has `/`, no suspicious chars, length OK). The JSON parser should have stored this as a `json-dir` reference. Other entries on lines 226-227 (`"process-framework/state-tracking/permanent"`) WERE updated. **Possible root cause**: The `_find_unclaimed_line` scanning may have been thrown off by the `_search_start_line` offset — if lines 226-227 were processed first and advanced the start offset past line 228, the fallback scan should still find it, but there could be an ordering issue in the recursive tree walk. Alternatively, the reference was detected but during the update phase, the old target `doc/process-framework/state-tracking` didn't match the moved path variations correctly.

- [ ] `doc/product-docs/state-tracking/features/archive/4.1.1-test-suite-implementation-state.md` (1) — Line 153: markdown link `[Run-Tests.ps1](../../../../doc/process-framework/scripts/test/Run-Tests.ps1)`. **Should update? YES.** **Why missed**: This is a standard `[text](target)` markdown link, which the parser handles. The relative path `../../../../doc/process-framework/...` traverses up 4 levels from `doc/product-docs/state-tracking/features/archive/`. After the move, the relative path should change. **Possible root cause**: The path resolver may fail to correctly map this deep relative path to the moved directory, or the `_calculate_new_target` method may not handle the case where the old absolute path no longer exists after the move.

- [ ] `doc/product-docs/state-tracking/permanent/bug-tracking.md` (2) — Lines 145, 186: Historical bug descriptions (PD-BUG-022, PD-BUG-056) mentioning the old path in prose within markdown table cells. **Should update? NO** — these are historical records describing what happened at a point in time. The paths appear inside backtick-quoted inline code within table cells and would match the `backtick_dir_pattern` and `bare_path_pattern`, but updating them would falsify the historical record.

- [ ] `doc/product-docs/state-tracking/permanent/technical-debt-tracking.md` (3) — Lines 158-160: TD127, TD128, TD129 descriptions mentioning the old path as historical context ("Identified during doc/process-framework directory move"). **Should update? NO** — falsifies the historical record.

- [ ] `doc/product-docs/test-audits/README.md` (4) — Lines 10-11, 114, 122: Paths in prose within parentheses `(script: doc/process-framework/scripts/...)` and section headers `### New-TestAuditReport.ps1 (doc/process-framework/scripts/...)`. **Should update? YES.** **Why missed**: These paths appear in parenthesized prose text. The `bare_path_pattern` should match paths with 2+ segments, but the surrounding parentheses `(script: ...)` or the `### ` header prefix may interfere with the regex boundary conditions. Needs investigation of whether these lines were detected but the stored reference format prevented matching during the update phase.

## Source code (`linkwatcher/`)

- [ ] `linkwatcher/parsers/markdown.py` (2) — Lines 49-50: Python `#` comments containing example paths. **Should update? NICE-TO-HAVE.** **Why missed**: The Python parser's `comment_pattern` regex (`[a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+`) requires a file extension. Line 49 has `doc/process-framework/scripts/file-creation` (no extension) — wouldn't match. Line 50 has `/doc/process-framework/...` with trailing `...` which is not a valid extension. The `QUOTED_DIR_PATTERN` only matches quoted strings, and these paths are unquoted in comments.

- [ ] `linkwatcher/validator.py` (1) — Line 623: Python comment with example path `# [text](/doc/process-framework/...) means <project_root>/doc/...`. **Should update? NICE-TO-HAVE.** **Why missed**: Same as above — `comment_pattern` requires extension, path has `...` suffix. Also contains angle brackets `<>` which would cause `looks_like_directory_path` to reject.

## Test files (`test/`)

- [ ] `test/automated/parsers/test_markdown.py` (18) — Python string literals containing test fixture content. These strings simulate markdown content with paths in code blocks, prose, backtick-quoted paths, Mermaid diagrams, and `@` references. **Should update? PARTIALLY.** Many of these are intentional test data that validates parser behavior for these exact reference patterns — changing them would invalidate the test assertions. The Python parser detects these via `QUOTED_PATH_PATTERN` and `QUOTED_DIR_PATTERN`, but the string literals are multi-line test fixtures where the path appears embedded in simulated markdown content. The `QUOTED_DIR_PATTERN` matches the outermost quotes of the Python string, not the path within. **Root cause**: Python parser has no concept of "path embedded within a larger string that itself is test data."

- [ ] `test/automated/parsers/test_powershell.py` (3) — Lines 258, 383, 426: Python string literals simulating PowerShell content as test data. Same root cause as above. Line 383 contains `(defaults to doc/process-framework/assessments/technical-debt/)` — parentheses around the path, unquoted within the Python string.

- [ ] `test/automated/parsers/test_yaml.py` (2) — Lines 495-496: Python string literals simulating YAML content as test data (`scripts: doc/process-framework/scripts/file-creation`). Same root cause.

- [ ] `test/audits/README.md` (4) — Lines 10-11, 114, 122: Same pattern as `doc/product-docs/test-audits/README.md` — paths in parenthesized prose and section headers. **Should update? YES.** **Why missed**: Same analysis as the test-audits README above.

- [ ] `test/archive/test-registry-archived-2026-03-26.yaml` (1) — Line 7: YAML comment `# VALIDATION: Run doc/process-framework/scripts/...`. **Should update? NO** — archived file. **Why missed even if it should**: YAML parser uses `yaml.safe_load()` which ignores comments entirely.

- [ ] `test/specifications/feature-specs/archive/test-spec-5-1-1-cicd-development-tooling.md` (1) — Line 131: Markdown link in archived spec. **Should update? NO** — archived historical document.

## Process framework scripts

**Parser capabilities for context:**
- PowerShell parser (`PowerShellParser`) handles: `QUOTED_PATH_PATTERN`, `QUOTED_DIR_PATTERN_STRICT`, embedded markdown links, general `path_pattern`, and `all_quoted_pattern` for extracting paths from prose in comments
- `#` line comments: scans comment segment with all patterns
- `<# #>` block comments: full pattern extraction on all interior lines
- Here-strings: full pattern extraction on all interior lines
- Python parser handles: `QUOTED_PATH_PATTERN`, `QUOTED_DIR_PATTERN`, `comment_pattern`, import statements

- [ ] `process-framework/scripts/feedback_db.py` (8) — Lines 8-15: Python docstring (triple-quoted string) containing usage examples like `python doc/process-framework/scripts/feedback_db.py init`. **Should update? YES** — misleading usage instructions. **Why missed**: The Python parser has no distinct handling for multi-line strings or docstrings. `QUOTED_PATH_PATTERN` (`[\'"]([^\'"]+\.[a-zA-Z0-9]+)[\'"]`) matches single/double quoted strings, but **not** content within triple-quoted strings — the regex `[^\'"]+` can't span across what appears as quote boundaries. `QUOTED_DIR_PATTERN` has the same limitation. The `comment_pattern` only fires on `#`-prefixed comments. So docstring content is effectively invisible to the Python parser.

- [ ] `process-framework/scripts/update/Update-TechnicalDebtFromAssessment.ps1` (3) — Lines 19, 55, 66: Line 19 is a PowerShell `#` comment in the `.DESCRIPTION` help block. Lines 55 and 66 are parameter default and variable assignment: `$AssessmentDirectory = "../doc/process-framework/..."` and `$UpdateScript = "../doc/process-framework/..."`. **Should update? YES** — script will break at runtime. **Why missed**: Lines 55/66 are quoted string values. `QUOTED_PATH_PATTERN` requires a file extension — `"../doc/process-framework/assessments/technical-debt"` has no extension, so it fails. `QUOTED_DIR_PATTERN_STRICT` should match (has `/`, content after last separator). **Root cause investigation needed** — the strict variant requires content after the last separator, which is satisfied here. The path may have been detected but the updater couldn't match it against the moved directory because the `../` prefix creates a relative path that doesn't directly match `doc/process-framework`.

- [ ] `process-framework/scripts/update/Update-ValidationReportState.ps1` (1) — Line 16: PowerShell `#` comment: `# ../doc/process-framework/documentation-map.md`. **Should update? NICE-TO-HAVE.** **Why missed**: Comment segment is scanned with `path_pattern` (`[a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+`), which requires a file extension. `documentation-map.md` has `.md` extension, so `path_pattern` should match `../doc/process-framework/documentation-map.md`. The `../` prefix and comment context may prevent the updater from resolving this to the moved path. Alternatively, the path may have been detected and stored, but during directory move processing, the reference lookup couldn't match it.

- [ ] `process-framework/scripts/update/Update-TestAuditState.ps1` (1) — Line 337: `Write-Host "  doc/process-framework/state-tracking/backups"`. **Should update? NICE-TO-HAVE.** **Why missed**: Path is inside a quoted string passed to `Write-Host`. `QUOTED_DIR_PATTERN_STRICT` should match `"  doc/process-framework/state-tracking/backups"` — but the leading spaces before `doc` would be included in the match. The captured group would be `  doc/process-framework/state-tracking/backups`, which `looks_like_directory_path` may reject or which wouldn't match the moved path due to leading whitespace.

- [ ] `process-framework/scripts/update/Update-ScriptReferences.ps1` (1) — Line 54: PowerShell hashtable value `"../doc/process-framework/feedback/New-FeedbackForm.ps1"`. **Should update? YES.** **Why missed**: `QUOTED_PATH_PATTERN` should match (has `.ps1` extension, is quoted). If detected, the `../` relative prefix may prevent matching against the moved directory path during reference lookup. Same relative-path resolution issue as Update-TechnicalDebtFromAssessment.

- [ ] `process-framework/scripts/update/Update-LanguageConfig.ps1` (1) — Line 16: PowerShell `#` comment listing a path. **Should update? NICE-TO-HAVE.** **Why missed**: Same analysis as other comment-based paths.

- [ ] `process-framework/scripts/update/Update-FeatureImplementationState.ps1` (1) — Line 299: `Write-Host "  doc/process-framework/state-tracking/backups"`. **Should update? NICE-TO-HAVE.** **Why missed**: Same as Update-TestAuditState — leading spaces in quoted string.

- [ ] `process-framework/scripts/update/Update-CodeReviewState.ps1` (1) — Line 394: `Write-Host "  doc/process-framework/state-tracking/backups"`. **Should update? NICE-TO-HAVE.** **Why missed**: Same pattern.

- [ ] `process-framework/scripts/file-creation/support/New-FrameworkExtensionConcept.ps1` (2) — Lines 182, 185: `Get-Content "../../../../../../proposals/doc/process-framework/proposals/test-framework-concept.md"` and `Remove-Item "../../../../../../proposals/doc/process-framework/proposals/test-framework-concept.md"`. **Should update? YES** — may break. **Why missed**: These are quoted paths with `.md` extension — `QUOTED_PATH_PATTERN` should match. The deeply nested relative path `../../../../../../proposals/doc/process-framework/...` would be stored as the link_target. The updater's `_calculate_new_target` may fail to resolve this 6-level-deep relative path to the moved directory. Note: this path also appears to be wrong/outdated even before the move (the `proposals/doc/process-framework/proposals/` structure looks like a pre-existing path bug).

- [ ] `process-framework/scripts/file-creation/support/New-Guide.ps1` (1) — Line 35: PowerShell comment in `.PARAMETER` help: `Subdirectory within doc/process-framework/guides/`. **Should update? NICE-TO-HAVE.** **Why missed**: Path appears in a `#`-prefixed comment or help block. No file extension, so `path_pattern` doesn't match. The `all_quoted_pattern` wouldn't fire because the path isn't quoted. The comment scanning finds the comment portion but the extracted path `doc/process-framework/guides/` has no extension and is unquoted.

- [ ] `process-framework/scripts/file-creation/support/New-Task.ps1` (1) — Line 104: String interpolation building a documentation-map entry: `"/doc/process-framework/tasks/../../../tasks/README.md"`. **Should update? YES** — will produce wrong paths in generated entries. **Why missed**: The string contains `$taskId` and `$relativePath` PS variables. The PowerShell parser strips trailing `$var` segments from embedded markdown links, but this is a plain quoted string, not a markdown link. `QUOTED_PATH_PATTERN` should match (has `.md` extension), but the path `doc/process-framework/tasks/../../../tasks/README.md` contains `../` traversals that may confuse the updater's path resolution.

- [ ] `process-framework/scripts/file-creation/02-design/New-APISpecification.ps1` (1) — Line 208: PowerShell `#` comment with path. **Should update? NICE-TO-HAVE.** **Why missed**: Comment scanning — path may lack extension or have unusual format.

- [ ] `process-framework/scripts/file-creation/02-design/New-APIDataModel.ps1` (1) — Line 184: PowerShell `#` comment with path. **Should update? NICE-TO-HAVE.** **Why missed**: Same as above.

- [ ] `process-framework/scripts/file-creation/00-setup/New-RetrospectiveMasterState.ps1` (1) — Line 32: PowerShell comment in `.NOTES` help: `The output file is placed in doc/process-framework/state-tracking/temporary/`. **Should update? NICE-TO-HAVE.** **Why missed**: Help block content. Path has no extension (ends with `/`), so `path_pattern` doesn't match. Unquoted, so `QUOTED_DIR_PATTERN` doesn't match.

- [ ] `process-framework/templates/support/document-creation-script-template.ps1` (2) — Lines 63-64: PowerShell `#` comments: `# All file-creation scripts are in doc/process-framework/scripts/file-creation/` and `# Common-ScriptHelpers.psm1 is one level up at doc/process-framework/scripts/`. **Should update? NICE-TO-HAVE.** **Why missed**: Comment scanning. Both paths lack file extensions (directory references ending in `/`), so `path_pattern` doesn't match. Unquoted, so quoted patterns don't apply.

## Process framework tasks and guides (markdown files)

**Key technical context**: The markdown parser skips ONLY ```` ```mermaid ```` blocks. All other fenced code blocks (` ```bash `, ` ```powershell `, ` ```cmd `, untagged ` ``` `) **are** scanned with all 10 patterns. So these paths WERE parsed. The issue is in the **detection → update pipeline**, not in parsing.

**Common patterns:**

1. `cd /c/path/to/project/doc/process-framework/scripts/...` — Uses `/c/path/to/project/` as a **placeholder prefix**. The `path/to` segment is in `validation_ignored_patterns` (see `linkwatcher/config/settings.py:149`), confirming this is recognized as a non-real path. The parser detects the full path but it doesn't resolve to any real file, so it's correctly never matched during directory move processing. **This is correct behavior** — placeholder example paths should not be auto-updated.

2. `Set-Location "<project-root>/doc/process-framework/..."` — Uses `<project-root>` as a **placeholder**. `looks_like_directory_path` rejects strings containing `<` and `>` (suspicious character list). Also correct behavior.

3. `cd /c/Users/ronny/VS_Code/LinkWatcher/doc/process-framework/...` — Uses a **real absolute path** (not a placeholder). These SHOULD have been updated. The `bare_path_pattern` matches the entire path from `/c/Users/...` as one token, and since the path is real, it could potentially resolve. However, the stored target includes the full absolute prefix, which may not match against the relative moved directory path `doc/process-framework`.

**Should update?**
- Placeholder paths (`/c/path/to/project/...`, `<project-root>/...`): **NO** — correctly skipped, but these placeholders should be replaced with root-relative paths project-wide so they become maintainable by LinkWatcher (see Process Improvement below)
- Real absolute paths (`/c/Users/ronny/...`): **YES** — these are real paths that should be root-relative

### Tasks (9 files, ~23 refs)

- [ ] `process-framework/tasks/support/new-task-creation-process.md` (7) — Lines 147, 165, 195, 218, 256, 262, 280: `cd /c/path/to/project/doc/process-framework/scripts/...` commands. **Why missed**: Placeholder path — `path/to` is a recognized non-real path. **Correct behavior.** Fix: replace with root-relative paths.
- [ ] `process-framework/tasks/03-testing/e2e-acceptance-test-execution-task.md` (4) — Lines 66, 76, 91, 102: `cd /c/path/to/project/doc/process-framework/scripts/test/e2e-acceptance-testing`. **Why missed**: Placeholder path. **Correct behavior.**
- [ ] `process-framework/tasks/03-testing/test-audit-task.md` (3) — Lines 161, 187, 203: `Set-Location "<project-root>/doc/process-framework/..."`. **Why missed**: Placeholder — `<>` chars rejected by `looks_like_directory_path`. **Correct behavior.**
- [ ] `process-framework/tasks/04-implementation/integration-and-testing.md` (2) — Lines 172, 179: Mix of `Set-Location "<project-root>/..."` (placeholder) and `cd /c/path/to/project/...` (placeholder). **Correct behavior.**
- [ ] `process-framework/tasks/support/framework-evaluation.md` (2) — Lines 173, 179: `cd /c/path/to/project/doc/process-framework/...`. Placeholder. **Correct behavior.**
- [ ] `process-framework/tasks/07-deployment/user-documentation-creation.md` (2) — Lines 91, 107: Placeholder paths. **Correct behavior.**
- [ ] `process-framework/tasks/03-testing/e2e-acceptance-test-case-creation-task.md` (1) — Line 102: Placeholder path. **Correct behavior.**
- [ ] `process-framework/tasks/03-testing/test-implementation-task.md` (1) — Line 126: `Set-Location "<project-root>/..."`. Placeholder. **Correct behavior.**
- [ ] `process-framework/tasks/06-maintenance/bug-fixing-task.md` (1) — Line 149: Placeholder path. **Correct behavior.**

### Guides (9 files, ~13 refs)

- [ ] `process-framework/guides/support/document-creation-script-development-guide.md` (4) — Lines 48, 68, 140, 148: Mix of backtick-quoted paths (`../doc/process-framework/templates/...`), `Copy-Item` commands, and `Join-Path` expressions. Backtick paths are matched by `backtick_dir_pattern` but the `../` relative prefix may prevent updater matching. `Import-Module (Join-Path ...)` lines have the path inside a function call — pattern may capture but updater can't resolve.
- [ ] `process-framework/guides/support/task-creation-guide.md` (3) — Lines 102, 154, 158: Line 102 is `cd /c/path/to/project/doc/process-framework/...` (placeholder — **correct behavior**). Lines 154, 158 are backtick-quoted `../doc/process-framework/...` paths (relative prefix may prevent updater matching).
- [ ] `process-framework/guides/03-testing/e2e-acceptance-test-case-customization-guide.md` (3) — Lines 39, 45, 51: `cd /c/path/to/project/doc/process-framework/...`. Placeholder paths. **Correct behavior.**
- [ ] `process-framework/guides/framework/feedback-form-completion-instructions.md` (1) — Line 24: `cd /c/Users/ronny/VS_Code/LinkWatcher/doc/process-framework/...` — **real absolute path** (not placeholder). **Why missed**: Bare path pattern matches the full absolute path from `/c/Users/...`. Stored target is the complete path including drive letter prefix, which doesn't match `doc/process-framework` during reference lookup. **Should be converted to root-relative.**
- [ ] `process-framework/guides/framework/feedback-form-guide.md` (1) — Line 19: Same — real absolute path. **Should be converted to root-relative.**
- [ ] `process-framework/guides/support/script-development-quick-reference.md` (1) — Line 161: `cd /c/Users/ronny/VS_Code/LinkWatcher/doc/process-framework/...`. Same — real absolute path. **Should be converted to root-relative.**
- [ ] `process-framework/guides/support/guide-creation-best-practices-guide.md` (1) — Line 467: `cd doc/process-framework/guides` — **root-relative path, no placeholder prefix**. `bare_path_pattern` requires 2+ segments — should match. **Root cause investigation needed** — this path should have been detected AND updated.
- [ ] `process-framework/guides/03-testing/test-infrastructure-guide.md` (1) — Line 134: `doc/process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1` — inline code. Path has `.ps1` extension and 5+ segments. **Should have been detected** — `backtick_path_pattern` would match if backtick-wrapped, or `bare_path_pattern` would match if in prose. **Root cause investigation needed.**
- [ ] `process-framework/guides/03-testing/integration-and-testing-usage-guide.md` (1) — Line 171: `Set-Location "<project-root>/doc/process-framework/..."`. Placeholder — rejected by `<>`. **Correct behavior.**

## Process framework templates + other docs

- [ ] `process-framework/templates/support/task-completion-template.md` (1) — Line 24: `cd /c/Users/ronny/VS_Code/LinkWatcher/doc/process-framework/...`. **Should update? YES.** **Why missed**: Real absolute path — bare_path_pattern matches the full path from `/c/Users/...`, stored target includes drive prefix. **Should be converted to root-relative.**

- [ ] `process-framework/templates/support/temp-task-creation-state-template.md` (1) — Line 84: Prose path in a markdown list: `doc/process-framework/[category]/New-[ScriptName].ps1`. **Should update? YES.** **Why missed**: Path contains `[` and `]` characters (template placeholders). `bare_path_pattern` regex uses `[a-zA-Z0-9_.\-]` for path segments, which excludes `[` and `]`. So the pattern can't match this path.

- [ ] `process-framework/visualization/process-flows/feedback-process-flowchart.md` (3) — Lines 23, 52, 117: Paths inside ```` ```mermaid ```` block node text and a troubleshooting table. **Should update? YES.** **Why missed**: Lines 23 and 52 are inside a ```` ```mermaid ```` fenced code block — the markdown parser **explicitly skips** all mermaid block content (PD-BUG-055). Line 117 is in a markdown table outside the mermaid block — path is backtick-quoted (`` `../doc/process-framework/templates/...` ``) and should be matched by `backtick_path_pattern`. **Root cause for line 117**: The `../` relative prefix in the stored target may prevent matching against the moved directory.

- [ ] `process-framework/visualization/context-maps/support/project-initiation-map.md` (1) — Line 43: Prose text `(doc/process-framework/project-config.json)` in a markdown list. **Should update? YES.** **Why missed**: Path is inside parentheses. `bare_path_pattern` should match `doc/process-framework/project-config.json` (has 2+ segments, file extension). If detected, the updater should handle this. **Root cause investigation needed** — may be that the parentheses prevent the regex from matching cleanly, or the path was detected but overlapped with another pattern match.

## Process framework state tracking (historical)

**Pattern: Historical records — completed state files, changelog entries, improvement descriptions.**
**Should update? NO** — falsifies historical records. These paths describe what happened at a specific point in time.

- [ ] `process-framework/state-tracking/permanent/process-improvement-tracking.md` (6) — Lines 30, 65, 104, 160, 441, 544: Historical changelog entries like "Identified during doc/process-framework move" and improvement descriptions mentioning the old path. Even though the markdown parser would detect some of these via `bare_path_pattern` or `backtick_dir_pattern`, updating them would falsify the historical record.
- [ ] `process-framework/state-tracking/temporary/old/structure-change-rename-manual-testing-to-e2e-acceptance-testing.md` (1) — Line 41: Completed state tracking file. Historical.
- [ ] `process-framework/state-tracking/temporary/old/temp-task-creation-scenario-based-e2e-acceptance-testing.md` (1) — Line 127: Completed state tracking file. Historical.

## Process framework archived feedback (9 files, 12 refs)

**Pattern: Historical feedback form text describing paths mentioned during task execution.**
**Should update? NO** — these are archived records of feedback given at a specific point in time. Updating would falsify the historical record.

**Why these were not updated even though the parser could detect them**: The markdown parser's `bare_path_pattern` and `backtick_path_pattern` would match many of these paths. They WERE likely detected and stored as references. However, the paths appear in prose descriptions like "Script path in lightweight path step L1 (`cd doc/process-framework/scripts/file-creation`)" — these are historical observations about what a document contained at the time, not navigational references. LinkWatcher correctly treated them as references and may have attempted updates, but the surrounding context (feedback form prose) means updating them is semantically wrong.

- [ ] `process-framework/feedback/archive/2026-02/tools-review-20260221/.../20260219-155547-PF-TSK-066-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-02/tools-review-20260227/.../20260227-131930-PF-TSK-023-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260304/.../20260304-003423-PF-TSK-034-feedback.md` (2)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260315/.../20260314-125525-PF-TSK-014-feedback.md` (2)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260320/.../20260318-153810-PF-TSK-009-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/.../20260327-232226-PF-TSK-022-feedback.md` (2)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/.../20260327-233642-PF-TSK-022-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/.../20260327-234510-PF-TSK-022-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/.../20260327-235750-PF-TSK-022-feedback.md` (1)

## Process framework proposals

- [ ] `process-framework/proposals/proposals/structure-change-test-directory-consolidation-and-framework-integration-proposal.md` (1) — Line 137: `doc/process-framework/` in a directory tree inside a fenced code block. **Should update? MAYBE** — active proposal. **Why missed**: `bare_path_pattern` matches but the full stored target may include surrounding tree characters (`├──`, etc.) or the path is only 2 segments which is at the regex minimum threshold.
- [ ] `process-framework/proposals/proposals/structure-change-generalize-testing-and-ci-cd-infrastructure-into-framework-proposal.md` (1) — Line 64: Same directory tree pattern. **Should update? MAYBE.**
- [ ] `process-framework/proposals/proposals/old/single-tracking-surface-proposal.md` (1) — Line 131: `# Source: doc/process-framework/state-tracking/features/*.md` in a code block comment. **Should update? NO** — archived. **Why missed**: `*` in the path would cause `looks_like_directory_path` to reject (suspicious character).
- [ ] `process-framework/proposals/proposals/old/structure-change-test-directory-consolidation-and-framework-integration-proposal.md` (1) — Line 137: Directory tree. **Should update? NO** — archived.
- [ ] `process-framework/proposals/proposals/old/tech-agnostic-testing-pipeline-concept.md` (1) — Line 140: Markdown table prose. **Should update? NO** — archived.

---

## Summary: Root Causes (Precise)

| Root Cause | Refs | Files | Should Fix (in LinkWatcher)? | Action |
|-----------|------|-------|------------------------------|--------|
| **Placeholder paths (correct behavior)** — `cd /c/path/to/project/...` and `Set-Location "<project-root>/..."` are recognized non-real paths; LinkWatcher correctly does not update them | ~33 | ~14 | NO — working as designed | Replace placeholders with root-relative paths project-wide (see PF-IMP below) |
| **Historical records** — archived feedback, completed state files, proposals, changelog entries, bug/TD descriptions | ~30 | ~20 | NO — correctly left unchanged | None needed |
| **Real absolute paths** — `cd /c/Users/ronny/VS_Code/LinkWatcher/doc/process-framework/...` uses real paths; stored target includes drive prefix, can't match moved dir | ~4 | ~4 | MAYBE — updater could normalize absolute paths | Convert to root-relative paths (part of same PF-IMP) |
| **Python docstring content** — triple-quoted strings invisible to Python parser regex patterns | ~8 | ~1 | YES — parser gap | Parser enhancement |
| **Mermaid block skip** — markdown parser skips all ```` ```mermaid ```` content by design | ~2 | ~1 | MAYBE — by design, but paths in diagrams become stale | Accept or enhance |
| **PowerShell Write-Host with leading spaces** — `"  doc/process-framework/..."` captured with whitespace prefix | ~3 | ~3 | NICE-TO-HAVE — cosmetic output strings | Minor parser improvement |
| **Unquoted dir paths in PS comments/help** — no extension, not quoted, `path_pattern` requires extension | ~8 | ~7 | NICE-TO-HAVE — documentation comments | Minor parser improvement |
| **Relative path prefix** — `../doc/process-framework/...` detected but updater can't resolve relative-prefixed target to moved dir | ~5 | ~4 | YES — updater path resolution gap | Updater enhancement |
| **Compound string values** — YAML/JSON values contain paths embedded in larger command strings | ~2 | ~2 | YES — need sub-path extraction from string values | Parser enhancement |
| **Python test fixture strings** — paths in test data that validate parser behavior for non-link patterns | ~23 | ~3 | PARTIALLY — changing some would invalidate test assertions | Manual review per test |
| **Template placeholder chars** — `[category]`, `[ScriptName]` in paths rejected by regex char class | ~1 | ~1 | NO — template placeholders aren't real paths | None needed |
| **Compound strings with suspicious chars** — `*`, `(`, `)` in surrounding string cause heuristic rejection | ~2 | ~2 | YES — need sub-path extraction | Parser enhancement |
| **Python code comments** — paths in `#` comments lack extension or have `...`/`<>` | ~3 | ~2 | NICE-TO-HAVE | Minor parser improvement |
| **Prose paths in README files** — paths in parentheses/section headers in `.md` files | ~8 | ~2 | YES — should be caught by bare_path_pattern | Investigation needed |
| **Root-relative paths that should have been caught** — `cd doc/process-framework/guides`, inline `doc/process-framework/...` with extension | ~2 | ~2 | YES — investigation needed | Bug investigation |

### Key Improvements Over Run 1

The biggest improvements in Run 2 come from the code changes committed between runs:

1. **Python string literal support** (PD-BUG-056 fix): Added `QUOTED_DIR_PATTERN` for directory paths in string literals. Previously ~54 refs across 9 test files were missed; now only ~23 across 3 files remain (the remaining are test fixtures that intentionally test parser behavior for non-link contexts).

2. **Performance optimization** (TD127-TD129): Secondary indexes, deferred rescans, and batched file writes reduced processing time from **2 hours 3 minutes → 5 minutes 44 seconds** (95% faster).

3. **Markdown non-mermaid code block scanning**: The parser now scans all fenced code blocks except ```` ```mermaid ````. Many code block paths that were missed in Run 1 are now detected. The remaining ~25 refs are detected but stored with absolute path prefixes that prevent matching during directory move processing.

4. **Overall coverage**: References updated jumped from 2,003 → 7,635 (+281%), while remaining references dropped from ~450 → ~143 (-68%).

### Remaining Gap Analysis

The **single biggest category** (~33 refs, ~14 files) is **placeholder paths that LinkWatcher correctly does not update**. These use conventions like `/c/path/to/project/` or `<project-root>/` that are recognized as non-real paths. The fix is not in LinkWatcher but in the documentation: replace all placeholder-prefixed paths with root-relative paths (e.g., `cd process-framework/scripts/file-creation`) so LinkWatcher can maintain them. See process improvement entry below.

The second largest category is **historical records** (~30 refs, ~20 files) which should NOT be updated — correctly left unchanged.

The remaining **actual LinkWatcher gaps** (~20 refs) are spread across several smaller root causes: Python docstrings (~8), relative path prefix resolution (~5), compound string values (~2), README prose paths (~8), and 2 root-relative paths that should have been caught but weren't (needs investigation).
