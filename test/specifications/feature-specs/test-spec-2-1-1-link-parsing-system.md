---
id: TE-TSP-039
description: "2.1.1 Tier 2 — Parser registry with 6 format-specific parsers"
type: Process Framework
category: Test Specification
version: 1.0
created: 2026-02-24
updated: 2026-02-24
feature_id: 2.1.1
feature_name: Link Parsing System
tdd_path: doc/technical/tdd/tdd-2-1-1-parser-framework-t2.md
test_tier: 2
retrospective: true
---

# Test Specification: Link Parsing System

> **Retrospective Document**: This test specification describes the existing test suite for the Link Parsing System, documented after implementation during framework onboarding. Content is derived from analysis of existing test files.

## Overview

This document provides comprehensive test specifications for the **Link Parsing System** feature (ID: 2.1.1), derived from the Technical Design Document [PD-TDD-025](../../../doc/technical/tdd/tdd-2-1-1-parser-framework-t2.md).

**Test Tier**: 2 (Unit + Integration)
**TDD Reference**: [TDD PD-TDD-025](../../../doc/technical/tdd/tdd-2-1-1-parser-framework-t2.md)
**Implementation Coverage**: 107/110 scenarios implemented (97%)

## Feature Context

### TDD Summary

The Link Parsing System uses a Registry+Facade pattern. `LinkParser` dispatches to format-specific parsers (`MarkdownParser`, `YamlParser`, `JsonParser`, `PythonParser`, `DartParser`, `GenericParser`) based on file extension. All parsers extend `BaseParser` and produce `List[LinkReference]`. The `GenericParser` acts as fallback for unregistered extensions.

### Test Complexity Assessment

**Selected Tier**: 2 — Multiple parser implementations each with format-specific edge cases, plus the facade dispatch logic and runtime extensibility.

## Cross-References

### Functional Requirements Reference

> **Primary Documentation**: [FDD PD-FDD-026](../../../doc/functional-design/fdds/fdd-2-1-1-parser-framework.md)

**Acceptance Criteria to Test**:
- `.md` file returns only markdown link references
- `.yaml` file returns YAML-format path references
- `.py` file returns Python import path references
- Unregistered extension routes to GenericParser
- `add_parser()` enables runtime extension
- `get_supported_extensions()` returns full default set

## Test Categories

### Unit Tests — Parser Facade

| Component | Test Focus | Key Test Cases | Fixtures |
|-----------|-----------|----------------|----------|
| LinkParser | Initialization | `test_parser_initialization` — parsers for .md, .yaml, .yml, .json, .dart, .py + generic | `temp_project_dir` |
| LinkParser | Markdown dispatch | `test_parse_markdown_file` — finds standard links and quoted references | `temp_project_dir`, `file_helper` |
| LinkParser | YAML dispatch | `test_parse_yaml_file` — finds nested file path values | `temp_project_dir`, `file_helper` |
| LinkParser | JSON dispatch | `test_parse_json_file` — finds file path strings | `temp_project_dir`, `file_helper` |
| LinkParser | Fallback | `test_parse_unsupported_file_type` — .xyz routes to generic parser | `temp_project_dir` |
| LinkParser | Add custom parser | `test_add_custom_parser` — .custom extension uses new parser | `temp_project_dir` |
| LinkParser | Remove parser | `test_remove_parser` — removes .md from registry | `temp_project_dir` |
| LinkParser | Get extensions | `test_get_supported_extensions` — returns all registered keys | None |
| LinkParser | Non-existent file | `test_parse_nonexistent_file` — returns empty list | None |
| LinkParser | Empty file | `test_parse_empty_file` — returns empty list | `temp_project_dir` |
| LinkParser | Binary file | `test_parse_binary_file` — returns empty list, no crash | `temp_project_dir` |
| LinkParser | Thread safety | `test_parser_thread_safety` — 3 threads × 5 files = 15 refs | `temp_project_dir`, `file_helper` |
| LinkParser | Size gate — under limit | `test_under_limit_file_parses_normally` — file < `max_file_size_mb` parses normally (TD227) | `temp_project_dir`, `file_helper` |
| LinkParser | Size gate — oversized | `test_oversize_file_is_skipped` — file > `max_file_size_mb` returns `[]`, logs `file_skipped_oversize` (TD227) | `temp_project_dir` |
| LinkParser | Size gate — disabled | `test_size_check_disabled_when_zero` — `max_file_size_mb=0` bypasses gate even for large files (TD227) | `temp_project_dir` |
| LinkParser | Size gate — missing file | `test_missing_file_still_returns_empty` — stat failure on missing file does not trigger gate; graceful empty result preserved (TD227) | None |

**Test File**: [`test/automated/unit/test_parser.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_parser.py) (16 methods)

### Parser Tests — Markdown

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| Standard links | `test_parse_standard_markdown_links`, `test_mp_001_standard_links`, `test_lr_001_standard_links` | Multiple on same line, inline links |
| Reference-style | `test_mp_002_reference_links` | Shorthand references |
| Quoted references | `test_parse_quoted_file_references` | Double and single quotes |
| Standalone refs | `test_parse_standalone_file_references` | Unquoted path/to/file.ext |
| External exclusion | `test_skip_external_links` | https://, mailto: filtered |
| Anchor-only exclusion | `test_skip_anchor_only_links` | #section excluded, file.txt#section kept |
| Duplicate detection | `test_avoid_duplicate_detection` | Same target as link and quoted text |
| Line/column positions | `test_line_and_column_positions`, `test_lr_002_relative_links` | Relative paths at correct positions |
| Backtick path detection | `test_mp_003_backtick_quoted_paths` | Backtick-quoted file and directory paths detected (PD-BUG-054) |
| Code block bare paths | `test_mp_004_code_block_bare_paths` | Bare directory paths in fenced code blocks detected (PD-BUG-054) |
| @-prefix paths | `test_mp_010_at_prefix_paths` | @doc/path/file.md detected with @ stripped (PD-BUG-055) |
| Leading-slash paths | `test_mp_011_leading_slash_paths` | /doc/path/dir/ detected as references (PD-BUG-055) |
| Mermaid exclusion | `test_mp_012_mermaid_blocks_excluded` | ```mermaid blocks skipped entirely (PD-BUG-055) |
| HTML links | `test_mp_005_html_links` | `<a href>`, single-quoted, spaces in names |
| Image links | `test_mp_006_image_links` | `![alt](img)`, reference-style images |
| Title attributes | `test_mp_007_links_with_titles` | Double, single quotes, parentheses |
| Malformed links | `test_mp_008_malformed_links` | Missing parens, empty text, unmatched brackets |
| Escaped characters | `test_mp_009_escaped_characters` | `\[not a link\]` ignored |
| Anchored links | `test_lr_003_links_with_anchors` | file#anchor kept, #section excluded |
| Complex document | `test_complex_markdown_document` | 7+ targets, mixed formats |
| Empty/error | `test_empty_file`, `test_file_with_no_links`, `test_error_handling` | Edge cases |
| Delimiter-gap spans | `TestBug135DelimiterGapSpans` (8 methods) | The span between two delimited literals is not a directory — covering the dominant backtick shape (`` `a` / `b` ``), the quoted-prose shape, mismatched delimiters, and the bogus span that STRADDLED and hid a real backticked directory. Controls pin `~/bin`, a real quoted directory, a real backticked directory, a leading literal, and the genuine neighbour beside a gap (PD-BUG-135) |

**Test File**: [`test/automated/parsers/test_markdown.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_markdown.py) (24 methods)

### Parser Tests — YAML

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| Simple values | `test_yp_001_simple_values` | Key-value file paths |
| Nested structures | `test_yp_002_nested_structures` | Deeply nested (databases, services) |
| Arrays | `test_yp_003_arrays` | List items, mixed objects, inline |
| Multi-line strings | `test_yp_004_multiline_strings` | Pipe `|` and folded `>` styles |
| Comment filtering | `test_yp_005_comments_ignored` | Paths in comments excluded |
| Anchors/aliases | `test_yp_006_yaml_anchors_aliases` | Anchor definitions and overrides |
| Invalid YAML | `test_invalid_yaml_handling` | Graceful failure |
| Empty file | `test_empty_yaml_file` | Returns empty list |
| Binary data | `test_yaml_with_binary_data` | `!!binary` blocks handled |
| Quoted paths | `test_quoted_file_paths` | Single, double, unquoted, special chars |
| Directory paths | `test_bug030_directory_paths_detected_in_yaml`, `test_bug030_directory_paths_coexist_with_file_paths` | Directory paths without extensions detected alongside file paths (PD-BUG-030) |
| Compound string extraction | `test_compound_command_string_with_embedded_file_path`, `test_compound_hook_entry_with_embedded_file_path` | Embedded file paths extracted from command-line strings via regex sub-path extraction (PD-BUG-060). The second test was renamed under PD-BUG-131: it asserted a FILE target under a directory-sounding name |
| Compound directory extraction | `TestBug131CompoundScalarDirectoryPaths` (9 methods) | A QUOTED directory inside a compound scalar is extracted and typed `YAML_DIR`; an unquoted one is not, and no longer registers the whole command as the target. Controls pin the de-overlap of file candidates, prose containment, and whole-string fall-through (PD-BUG-131) |
| Escaped compound strings | `TestBug130EscapedCompoundStringPaths` (6 methods) | A path inside a double-quoted compound scalar is found and its span mapped onto the RAW literal; the whole command string is never registered as the target, and an unlocatable scalar is logged rather than dropped (PD-BUG-130) |
| Value line attribution | `TestBug134SubstringLineAttribution` (10 methods) | A scalar is attributed to the line it occupies, not an earlier line whose larger literal contains it — a longer path it prefixes, or a compound scalar embedding it. Controls pin the plain-scan fallback for shapes the standalone rule does not recognise (an explicit `!!str` tag), the block-scalar opt-out, sequence/flow/comment boundaries, and verbatim repeats (PD-BUG-134) |

**Test File**: [`test/automated/parsers/test_yaml.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_yaml.py) (13 methods)

### Parser Tests — JSON

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| String values | `test_jp_001_string_values_with_file_paths` | Object value file paths |
| Nested objects | `test_jp_002_nested_objects` | 4 levels deep, 10+ refs |
| Arrays | `test_jp_003_arrays_of_file_paths` | Arrays, mixed, nested |
| Escaped strings | `test_jp_004_escaped_strings` | Windows paths, quotes |
| Comments | `test_jp_005_comments_in_json` | Non-standard comment handling |
| Invalid JSON | `test_invalid_json_handling` | Graceful failure |
| Empty file | `test_empty_json_file` | Returns empty list |
| Null values | `test_json_with_null_values` | Nulls skipped |
| Non-string types | `test_json_with_numbers_and_booleans` | Numbers, booleans not detected |
| Deep nesting | `test_deeply_nested_json` | 10 levels deep |
| Large arrays | `test_large_json_arrays` | 100-element array |
| Duplicate value line numbers | `test_bug013_duplicate_values_get_correct_line_numbers`, `test_bug013_mixed_duplicate_and_unique_values`, `test_bug013_adjacent_duplicate_values` | Same path on multiple lines gets unique correct line numbers (PD-BUG-013) |
| Directory paths | `test_bug030_directory_paths_detected_in_json`, `test_bug030_directory_paths_coexist_with_file_paths`, `test_bug030_non_path_strings_not_detected` | Directory paths without extensions detected alongside file paths, non-path strings rejected (PD-BUG-030) |
| Compound string extraction | `test_compound_string_with_embedded_file_path`, `test_compound_string_multiple_patterns`, `test_compound_string_no_false_positive_from_glob` | Embedded file paths extracted from compound command strings (e.g., permission patterns) via regex sub-path extraction (PD-BUG-061) |
| Escaped compound strings | `TestBug130EscapedCompoundStringPaths` (9 methods) | A path inside an escape-bearing compound value is found and its span mapped onto the RAW literal, covering doubled backslashes, `\uXXXX`, and a clean path inside a literal escaped elsewhere; the whole command string is never registered as the target, and an unlocatable value is logged rather than dropped (PD-BUG-130) |
| Compound directory extraction | `TestBug131CompoundStringDirectoryPaths` (12 methods) | A QUOTED directory inside a compound value is extracted and typed `JSON_DIR`; an unquoted one is not, and no longer registers the whole command as the target. Controls pin the de-overlap of file candidates, the clean-path-token guard against prose apostrophes, and whole-string fall-through (PD-BUG-131) |
| Adjacent-quoted-literal spans | `TestBug133AdjacentQuotedLiteralSpans` (6 methods) | The span between two adjacent quoted literals is not a directory candidate — covering the pathlib operator (`Path(a) / 'b'`), prose apostrophes, and escape fragments — while genuine quoted directories, trailing-separator directories and quoted file paths still resolve (PD-BUG-133) |
| Value line attribution | `TestBug134SubstringLineAttribution` (7 methods) | A value is attributed to the line it occupies, not an earlier line whose larger literal contains it — the lookup matches the quoted form `"value"`. Controls pin array elements with trailing commas, escaped-literal location, and the PD-BUG-013 whole-string duplicate behaviour (PD-BUG-134) |

**Test File**: [`test/automated/parsers/test_json.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_json.py) (20 methods)

### Parser Tests — Python

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| Import filtering | `test_skip_import_modules` | `import os`, `import requests` excluded |
| Dotted stdlib filtering | `test_skip_dotted_stdlib_imports` | `from email.mime.text`, `from xml.etree.ElementTree`, `from logging.handlers` excluded (TD038) |
| String literals | `test_parse_string_literals` | Double, single, triple, raw, f-strings |
| Docstrings | `test_docstring_references` | Module and function docstrings |
| Docstring column positions | `TestDocstringColumnPositions` (9 methods) | Columns on a line that *contains* triple quotes are line-absolute, not offsets into the extracted docstring text; covers indentation depth, two docstring segments on one line, code after the closing quotes, and a pure-body-line control (PD-BUG-118) |
| Docstring trailing punctuation | `test_sentence_period_not_swallowed_into_directory_target`, `test_trailing_period_without_slash_trimmed`, `test_backticked_path_in_docstring_keeps_delimiters` | Sentence punctuation following a path is excluded from the link target, so the rewrite cannot consume it from the prose (PD-BUG-118) |
| False positives | `test_avoid_false_positives` | Versions, emails, URLs, regex, SQL |
| Complex file | `test_complex_python_file` | 12+ refs across constants, classes, dicts |
| Line/column | `test_line_and_column_positions` | Position accuracy |
| Empty/error | `test_empty_file`, `test_error_handling` | Edge cases |
| Directory paths | `test_quoted_directory_paths`, `test_quoted_directory_paths_no_false_positives` | Quoted strings with path separators but no file extension detected as directory path references (PD-BUG-056) |

**Test File**: [`test/automated/parsers/test_python.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_python.py) (26 methods)

### Parser Tests — Dart

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| Package filtering | `test_skip_package_imports` | `dart:io`, `package:flutter` excluded |
| Asset references | `test_parse_asset_references` | 11 asset refs (images, fonts, data) |
| Pubspec refs | `test_parse_pubspec_references` | 8+ config file references |
| Doc comments | `test_parse_documentation_comments` | `///` comments with file paths |
| False positives | `test_avoid_false_positives` | Versions, emails, URLs, UUIDs, SQL |
| Flutter patterns | `test_flutter_specific_patterns` | Image.asset, AssetImage, File constructors |
| Complex file | `test_complex_dart_file` | 22+ refs across multiple classes |
| Empty/error | `test_empty_file`, `test_error_handling` | Edge cases |

**Test File**: [`test/automated/parsers/test_dart.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_dart.py) (12 methods)

### Parser Tests — Generic

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| Quoted references | `test_parse_quoted_references` | 12 double/single-quoted refs |
| Standalone refs | `test_parse_standalone_file_references` | 24+ one-per-line refs |
| Mixed refs | `test_parse_mixed_references` | Both types in same file |
| False positives | `test_avoid_false_positives` | 20 patterns (versions, emails, IPs, currency, etc.) |
| Config files | `test_parse_configuration_files` | .env format |
| Log files | `test_parse_log_files` | Timestamped entries |
| README files | `test_parse_readme_files` | 18+ plain text refs |
| Extension handling | `test_file_extension_handling` | 10 different extensions |
| Binary handling | `test_binary_file_handling` | Returns empty list |
| Large files | `test_large_file_handling` | 3000+ lines with scattered refs |
| Unicode | `test_unicode_handling` | French, Russian, Chinese paths |
| Empty/error | `test_empty_file`, `test_error_handling` | Edge cases |
| Quoted directory paths | `test_bug021_quoted_directory_paths_detected` and related tests in `TestGenericParserDirectoryPaths` class | Quoted strings containing path separators but no file extension detected as directory path references (PD-BUG-021) |
| Delimiter-gap spans | `TestBug135DelimiterGapSpans` (4 methods) | The span between two quoted literals is not a directory; controls pin a real quoted directory and the genuine neighbour beside a gap (PD-BUG-135) |

**Test File**: [`test/automated/parsers/test_generic.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_generic.py) (21 methods)

### Parser Tests — Image Files

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| PNG binary | `test_png_file_parsing_returns_empty` | No false positives from binary |
| SVG with links | `test_svg_file_with_links` | `<a href>`, `<image href>`, xlink:href |
| SVG without links | `test_svg_file_without_links` | Simple SVG returns empty |
| Corrupted image | `test_corrupted_image_files` | Text content with .png extension |
| Extension classification | `test_image_file_extensions_not_in_specialized_parsers` | .png, .svg, .jpg not specialized |
| Mixed directory | `test_mixed_content_directory_parsing` | Markdown finds image refs, images have zero outgoing |

**Test File**: [`test/automated/parsers/test_image_files.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_image_files.py) (6 methods)

### Parser Tests — PowerShell

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| Line/block comments | `test_line_comments`, `test_block_comments` | Comments filtered from parsing |
| Quoted strings | `test_double_quoted_strings`, `test_single_quoted_strings` | Both quoting styles |
| Cmdlet patterns | `test_join_path_patterns`, `test_import_module_patterns`, `test_test_path_get_content` | PowerShell-specific file operations |
| Here-strings | `test_here_strings_with_paths` | Multi-line strings |
| Arrays | `test_array_with_paths` | Array literal file paths |
| Write-Host | `test_write_host_with_paths` | Output statements |
| Cmdlet/var filtering | `test_cmdlet_names_not_detected`, `test_variable_names_not_detected` | False positive prevention |
| Backslash paths | `test_backslash_paths` | Windows-style separators |
| Embedded markdown | `test_markdown_links_in_strings`, `test_markdown_links_in_here_strings` | `[text](path)` in PS strings |
| Regex filtering | `test_regex_patterns_extracted_as_dir_paths`, `test_regex_filtered_at_updater_layer` | PD-BUG-033 |
| Deduplication | `test_deduplication` | Same ref on same line |
| Line numbers | `test_line_numbers_are_1_based` | 1-based indexing |
| Delimiter-gap spans | `TestBug135DelimiterGapSpans` (6 methods) | Neither an unpaired opening quote nor a mismatched pair yields a directory — the STRICT variant does not prevent either. Controls pin a `$Variable`-bearing path, single- and double-quoted directories, and the genuine neighbour beside a gap (PD-BUG-135) |

**Test File**: [`test/automated/parsers/test_powershell.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_powershell.py) (32 methods)
**Note**: Registered as TE-TST-129 during test audit (2026-03-15) — was previously unregistered.

### Cross-Parser Tests — Dot-Only Notation and Reference-Span Normalization (PD-BUG-149 / PD-BUG-151 / TD305)

Cross-parser rather than per-parser: both defects live in code every parser reaches, and PD-BUG-149 established that guarding one route leaves the others emitting the token by another. The cases are therefore exhaustive across the affected parsers, not representative.

| Test Focus | Key Test Cases | Edge Cases Covered |
|-----------|----------------|-------------------|
| Dot-only notation is not a reference | `TestBug149Helper` (15 methods), `TestBug149ParserDetection` (12) | `../`, `../../`, `./..`, backslash spellings — suppressed in markdown, generic, python, PowerShell, YAML and JSON; each paired with a NAMED sibling written the same way that must still be detected (PD-BUG-149) |
| Link-syntax boundary | `TestBug149PreservedBoundary` (1) | `[parent](../)` is an authored reference and is still detected and re-depthed — the one dot-only shape that must NOT be suppressed |
| Padded notation | `TestBug151PaddedTokenNotRegistered` (15) | The same tokens written with surrounding whitespace, which tested verbatim walked past the PD-BUG-149 guard. Asserts both that the padded form is absent AND that stripping it did not revive the tight form (PD-BUG-151) |
| Span covers exactly the target | `TestTD305SpanCoversExactlyTheTarget` (6) | A padded NAMED target is tracked by its trimmed path with columns covering only that path; a tight target is unchanged (TD305) |
| Span never wider than a tight target | `TestBug150SpanNeverWiderThanTightTarget` (14) | The **mirror** case, missing until PD-BUG-150 round 3: the target is already tight but the SPAN is wider, which is what a parser leaves when it strips the captured text into `link_target` while the columns keep the raw match extent. Asserted **type-agnostically** — a span may exceed its target, but never by whitespace alone — so no list of affected link types appears and a parser added later is covered. Includes a control that a construct-spanning markdown span keeps its width, and a control that an indented reference definition keeps its recorded columns |
| Padded URL | `TestBug151PaddedUrlNotRegistered` (2) | Padding also evaded the `startswith` URL guard. Latent, not live — it never resolved — but closed by the same re-validation. The control pins that the tight spelling adds no such target, so the padded case is a real difference |
| Moved-file rewrite | `TestBug151MovedFileRewrite` (13) | Padded spans come back BYTE-IDENTICAL after a depth-changing move, in prose (backtick and quoted) and in YAML/JSON/PowerShell/generic config **values**. Includes the depth-1 inert case — `` ` ../ ` `` recalculates to itself, so a suite exercising only depth 1 would call the bug fixed while it was not. Also pins that a padded named DIRECTORY now follows the move (measured STALE in five shapes pre-fix) and that PowerShell's padded and tight twins do not double-replace once normalization collapses them onto one span |

**Test File**: [`test/automated/unit/2-link-parsing-update/test_bug149dotonlypathtokens.py`](../../automated/unit/2-link-parsing-update/test_bug149dotonlypathtokens.py) (TE-TST-161 — 45 test functions, 80 collected cases after parametrization: 30 from PD-BUG-149, 36 added for PD-BUG-151 / TD305, 14 added for PD-BUG-150 round 3).
**Manual validation**: `test/bug-validation/PD-BUG-149_dot_only_prose_token_validation.py` (5 checks) and `test/bug-validation/PD-BUG-151_padded_dot_only_token_validation.py` (6 checks, **1/6 pre-fix → 6/6 post-fix**), both through the real service move handler.
**Round 3 (PD-BUG-150, 2026-08-31)** — the normalization above enforced only *half* the invariant it documented. `_normalize_reference` early-returns whenever the target is already tight, which is exactly the state the PowerShell quoted-directory scan produces, so the span kept padding the target no longer named and positional replacement destroyed it. `_tighten_span` closes the second half at the same choke point. Verified by a damage oracle rather than a shape census — rewrite every reference in the repo with a sentinel and require that mapping it back reproduces the line byte for byte: **16 damaged of 47,057 before, 0 of 47,231 after**. The earlier claim that normalization is "confined to references whose recorded span is EXACTLY the target" no longer holds and was the defect.

**Behavioural delta measured** for the PD-BUG-151 / TD305 fix, paired (each file parsed once, normalized vs un-normalized) across 88,359 references in the LinkWatcher and appdev deployments: 11 references dropped (4 padded dot-only, 4 padded bare separators, 3 PowerShell padded twins de-duplicated), 62 tightened, **0 added**.

## Test Implementation Roadmap

### Priority Order

1. **High Priority** (Implemented ✅)
   - [x] Facade dispatch to all 6 parsers
   - [x] Each parser: standard syntax, edge cases, error handling
   - [x] False positive avoidance across all parsers
   - [x] Runtime extensibility (add/remove parser)

2. **Medium Priority** (Implemented ✅)
   - [x] Thread safety of parser facade
   - [x] Code block filtering (markdown)
   - [x] Binary/image file safety
   - [x] Unicode path handling

3. **Low Priority** (Gaps identified)
   - [ ] Case-insensitive extension matching (`.MD`, `.Md` — mentioned in TDD, not explicitly tested)
   - [ ] Performance timing via `LogTimer` (TDD mentions logging parse duration)
   - [ ] Parser statefulness verification (parsers must be stateless per-call)
   - [ ] Error propagation behavior (TDD: parser exceptions propagate to caller)

### Coverage Gaps

- **Case-insensitive dispatch**: TDD mentions `.MD` routes to `MarkdownParser` — not tested
- **LogTimer integration**: TDD mentions performance timing for every `parse_file()` call — not tested
- **Statelessness**: Parsers are shared instances; no test verifies they produce identical results on repeated calls
- ~~**Directory path detection**: GenericParser did not detect quoted directory paths (no file extension)~~ — **Covered** by PD-BUG-021 fix (`TestGenericParserDirectoryPaths`, 6 methods)
- ~~**JSON duplicate value line numbers**: JsonParser assigned same line number to all occurrences of a repeated path value~~ — **Covered** by PD-BUG-013 fix (`TestJsonParserDuplicateLineNumbers`, 3 methods)

---

_Retrospective Test Specification — documents existing test suite as of 2026-02-24._
