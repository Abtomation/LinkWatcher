# Test Gaps Identified During Post-Move Analysis (2026-03-31)

> Source: `post-move-remaining-refs-run2.md` analysis of `doc/process-framework` -> `process-framework/` directory move.

---

## Already Created (confirmed failing)

These tests were created in `test/automated/test_directory_move_detection.py` class `TestRelativePathPrefixUpdateOnDirectoryMove` and confirmed to fail:

### 1. `../` Relative Path Prefix Prevents Updater Matching

- **Test**: `test_relative_path_with_dotdot_prefix_updated_on_directory_move`
- **Root cause**: Database stores relative path as-is (e.g., `../doc/guides/debt`). Directory move lookup uses simple prefix matching on variations like `doc/guides`, which doesn't match the `../` prefix. Source-file-relative resolution is not accounted for.
- **Real-world example**: `process-framework/scripts/update/Update-TechnicalDebtFromAssessment.ps1` line 55: `$AssessmentDirectory = "../doc/process-framework/..."`
- **Refs affected**: ~18 across ~15 PowerShell files

### 2. Four-Level Deep Relative Path Not Updated

- **Test**: `test_four_level_deep_relative_path_updated_on_directory_move`
- **Root cause**: Same as above — `../../../../doc/guides/scripts/test/Run-Tests.ps1` markdown link is stored as relative from source. Updater can't match during directory move.
- **Real-world example**: `doc/product-docs/state-tracking/features/archive/4.1.1-test-suite-implementation-state.md` line 153

---

## Parser-Level Tests to Create

### B1: YAML Sub-Path Extraction from Compound Strings — PD-BUG-060 ✅ xfail tests created

- **Bug**: PD-BUG-060 (🔍 Triaged P4/S)
- **File**: `test/automated/parsers/test_yaml.py`
- **Class**: `TestYamlParserCompoundStrings`
- **Mark**: `@pytest.mark.xfail(reason="PD-BUG-060: YAML parser stores entire string value, no sub-path extraction")`
- **Root cause**: YAML parser checks entire string value against path heuristics. `looks_like_file_path()` on the full 94-char command string fails. No mechanism to extract sub-paths from within larger strings.
- **Real-world example**: `.pre-commit-config.yaml` line 36: `pwsh.exe -ExecutionPolicy Bypass -File doc/process-framework/scripts/test/Run-Tests.ps1 -Quick`
- **Refs affected**: 1 file, 1 ref

**Tests needed**:

1. `test_compound_command_string_with_embedded_file_path` — YAML value `"pwsh.exe -File doc/scripts/test/Run-Tests.ps1 -Quick"`, assert `doc/scripts/test/Run-Tests.ps1` detected
2. `test_compound_string_with_embedded_directory_path` — YAML value `"Bash(python doc/scripts/feedback_db.py *)"`, assert `doc/scripts/feedback_db.py` detected

### B2: JSON Sub-Path Extraction from Compound Strings — PD-BUG-061 ✅ xfail tests created

- **Bug**: PD-BUG-061 (🔍 Triaged P4/S)
- **File**: `test/automated/parsers/test_json.py`
- **Class**: `TestJsonParserCompoundStrings`
- **Mark**: `@pytest.mark.xfail(reason="PD-BUG-061: JSON parser stores entire string value, no sub-path extraction")`
- **Root cause**: JSON parser checks entire string against path heuristics. `looks_like_directory_path()` rejects due to `*` in suspicious chars list. Even if not rejected, stored target is the full `Bash(...)` string.
- **Real-world example**: `.claude/settings.local.json` line 8: `"Bash(python doc/process-framework/scripts/feedback_db.py *)"`
- **Refs affected**: 1 file, 1 ref

**Tests needed**:

1. `test_compound_string_with_embedded_file_path` — JSON array value `"Bash(python doc/scripts/feedback_db.py *)"`, assert `doc/scripts/feedback_db.py` detected

### B3: Python Docstrings (Triple-Quoted Strings) — PD-BUG-062 ✅ xfail tests created

- **Bug**: PD-BUG-062 (🔍 Triaged P4/S)
- **File**: `test/automated/parsers/test_python.py`
- **Class**: `TestPythonParserDocstrings`
- **Mark**: `@pytest.mark.xfail(reason="PD-BUG-062: Python parser cannot detect paths in triple-quoted docstrings")`
- **Root cause**: `QUOTED_PATH_PATTERN` (`[\'"]([^\'"]+\.[a-zA-Z0-9]+)[\'"]`) stops at first quote char — can't match across triple-quote boundaries. `comment_pattern` only fires on `#` comments. Docstring content is invisible.
- **Real-world example**: `process-framework/scripts/feedback_db.py` lines 8-15: usage examples in docstring
- **Refs affected**: ~8 refs in 1 file

**Tests needed**:

1. `test_docstring_with_file_paths` — Python file with `"""Usage:\n    python doc/scripts/feedback_db.py init\n"""`, assert `doc/scripts/feedback_db.py` detected
2. `test_docstring_with_directory_paths` — Python file with `"""Templates in doc/scripts/templates/support/\n"""`, assert directory path detected

### B4: Markdown Paths with `[` `]` Template Placeholders — PD-BUG-063 ✅ xfail tests created (known limitation)

- **Bug**: PD-BUG-063 (🔍 Triaged P4/S — known limitation, no immediate fix planned)
- **File**: `test/automated/parsers/test_markdown.py`
- **Class**: `TestMarkdownParserBracketPlaceholders`
- **Mark**: `@pytest.mark.xfail(reason="PD-BUG-063: bare_path_pattern excludes [ ] from character class")`
- **Root cause**: `bare_path_pattern` regex uses `[a-zA-Z0-9_.\-]` for path segments, which excludes `[` and `]`. Paths like `doc/process-framework/[category]/New-[ScriptName].ps1` can't match.
- **Real-world example**: `process-framework/templates/support/temp-task-creation-state-template.md` line 84
- **Refs affected**: 1 file, 1 ref

**Tests needed**:

1. `test_bare_path_with_bracket_placeholders` — Markdown content with `doc/framework/[category]/New-[ScriptName].ps1`, assert the path is detected

### B5: Parenthesized Prose Paths — PD-BUG-064 ✅ xfail tests created

- **Bug**: PD-BUG-064 (🔍 Triaged P4/S)
- **File**: `test/automated/parsers/test_markdown.py`
- **Class**: `TestMarkdownParserParenthesizedProsePaths`
- **Mark**: `@pytest.mark.xfail(reason="PD-BUG-064: Parenthesized prose context prevents path detection")`
- **Root cause**: `bare_path_pattern` should match paths with 2+ segments, but surrounding `(script: ...)` or `### ` header prefix may interfere with regex boundary conditions.
- **Real-world examples**:
  - `doc/product-docs/test-audits/README.md` lines 10-11: `(script: doc/process-framework/scripts/...)`
  - `doc/product-docs/test-audits/README.md` lines 114, 122: `### New-TestAuditReport.ps1 (doc/process-framework/scripts/...)`
- **Refs affected**: ~4 refs across 2 files

**Tests needed**:

1. `test_path_in_parenthesized_prose` — Markdown with `(script: doc/scripts/test/Run-Tests.ps1)`, assert `doc/scripts/test/Run-Tests.ps1` detected
2. `test_path_in_section_header_parentheses` — Markdown with `### Script.ps1 (doc/scripts/file-creation/)`, assert directory path detected

### B-A3: PowerShell Leading Whitespace in Quoted Paths — PD-BUG-065 ✅ xfail tests created

- **Bug**: PD-BUG-065 (🔍 Triaged P4/S)
- **File**: `test/automated/parsers/test_powershell.py`
- **Class**: `TestPowerShellLeadingWhitespace`
- **Mark**: `@pytest.mark.xfail(reason="PD-BUG-065: Leading whitespace included in captured group prevents path matching")`
- **Root cause**: `QUOTED_DIR_PATTERN_STRICT` (`[\'"]([^\'"]*[/\\][^\'"]+)[\'"]`) captures leading spaces in group(1). The stored target `"  doc/process-framework/..."` has literal spaces that prevent filesystem path matching during directory move. Fix: `.strip()` the captured group.
- **Real-world examples**:
  - `process-framework/scripts/update/Update-TestAuditState.ps1` line 337
  - `process-framework/scripts/update/Update-FeatureImplementationState.ps1` line 299
  - `process-framework/scripts/update/Update-CodeReviewState.ps1` line 394
- **Refs affected**: 3 files, 3 refs
- **Note**: The leading spaces are intentional console output formatting (visual indentation under a header line). The fix is in the parser (strip whitespace), not in the source files.

**Tests needed**:

1. `test_leading_whitespace_in_quoted_dir_path` — PowerShell with `Write-Host "  doc/framework/state-tracking/backups"`, assert `doc/framework/state-tracking/backups` (trimmed) detected

---

## E2E Acceptance Tests to Create

### E2E-1: Directory Move with Compound YAML String

- **Scenario**: YAML file has `entry: "pwsh.exe -File doc/subdir/scripts/Run.ps1 -Quick"`
- **Action**: Move `doc/subdir` to `subdir`
- **Expected**: YAML value updated to contain `subdir/scripts/Run.ps1`
- **Blocked by**: B1 (parser must extract sub-paths first)

### E2E-2: Directory Move with Python Docstring Paths

- **Scenario**: Python file with docstring containing `python doc/subdir/script.py init`
- **Action**: Move `doc/subdir` to `subdir`
- **Expected**: Docstring path updated
- **Blocked by**: B3 (parser must detect docstring content first)

### E2E-4: Directory Move with `../` Relative Paths

- **Scenario**: PowerShell file with `$path = "../doc/subdir/assessments"`
- **Action**: Move `doc/subdir` to `subdir`
- **Expected**: Relative path updated correctly
- **Blocked by**: A2 fix (updater must resolve relative paths from source file context)

---

## Resolved / No Test Needed

| Item | Resolution |
|------|-----------|
| **A1**: `cd /c/path/.../doc/process-framework/...` | Will be solved another way |
| **A5**: Suspicious chars `<`, `>`, `*`, `|` | References removed, no longer applicable |
| **A6**: PD-id-registry.json stale path | Fixed manually (data entry error, not code bug) |
| **A7**: Unquoted dir paths in PS comments | Intentionally not detected (scoped out of PD-BUG-055/057) |
| **A8**: Mermaid block paths | Mermaid paths already updated; remaining refs are broken formatting in code block / table sections |
| **B6**: `cd` absolute path end-to-end | No longer applicable (scenario removed) |
| **E2E-3**: `cd` absolute path directory move | No longer applicable |
