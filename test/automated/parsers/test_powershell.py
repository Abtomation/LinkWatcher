"""
Tests for the PowerShell parser.

This module tests PowerShell-specific link parsing functionality
including line comments, block comments, string literals, Join-Path,
and Import-Module patterns.
"""

import pytest

from linkwatcher.parsers.powershell import PowerShellParser

pytestmark = [
    pytest.mark.feature("2.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("parser"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md"
    ),
]


class TestPowerShellParser:
    """Test cases for PowerShellParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = PowerShellParser()
        assert parser.quoted_pattern is not None
        assert parser.path_pattern is not None
        assert parser.block_comment_start is not None
        assert parser.block_comment_end is not None

    def test_line_comment_with_path(self):
        """Test extracting file paths from # line comments."""
        parser = PowerShellParser()
        content = "# Reference to doc/process-framework/README.md\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "doc/process-framework/README.md" in targets
        assert any(r.link_type == "powershell-comment" for r in refs)

    def test_block_comment_with_paths(self):
        """Test extracting file paths from <# #> block comments."""
        parser = PowerShellParser()
        content = "<#\n.NOTES\n  See doc/guides/setup-guide.md for details\n#>\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "doc/guides/setup-guide.md" in targets
        assert any(r.link_type == "powershell-block-comment" for r in refs)

    def test_single_line_block_comment(self):
        """Test block comment that opens and closes on the same line."""
        parser = PowerShellParser()
        content = "<# See config/settings.yaml for config #>\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "config/settings.yaml" in targets

    def test_double_quoted_string(self):
        """Test extracting file paths from double-quoted strings."""
        parser = PowerShellParser()
        content = '$path = "tests/parsers/config.json"\n'
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "tests/parsers/config.json" in targets
        assert any(r.link_type == "powershell-quoted" for r in refs)

    def test_single_quoted_string(self):
        """Test extracting file paths from single-quoted strings."""
        parser = PowerShellParser()
        content = "$path = 'src/utils/helpers.py'\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "src/utils/helpers.py" in targets

    def test_join_path_in_string(self):
        """Test extracting file paths from Join-Path string arguments."""
        parser = PowerShellParser()
        content = '$target = Join-Path -Path "tests/manual" -ChildPath "move-target.md"\n'
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "move-target.md" in targets

    def test_import_module_path(self):
        """Test extracting file paths from Import-Module statements."""
        parser = PowerShellParser()
        content = '# Import-Module "lib/modules/helpers.psm1" -Force\n'
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "lib/modules/helpers.psm1" in targets

    def test_test_path_operation(self):
        """Test extracting file paths from Test-Path operations."""
        parser = PowerShellParser()
        content = 'if (Test-Path "config/app-settings.yaml") {\n'
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "config/app-settings.yaml" in targets

    def test_get_content_path(self):
        """Test extracting file paths from Get-Content -Path parameter."""
        parser = PowerShellParser()
        content = '$data = Get-Content -Path "data/input.json" -Raw\n'
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "data/input.json" in targets

    def test_here_string_with_paths(self):
        """Test extracting file paths from here-strings.

        Here-strings (@"..."@) contain unquoted text. Paths on bare lines
        (not in comments or quotes) are not currently extracted — this is
        consistent with PythonParser behavior for multi-line strings.
        Paths that are also quoted inside the here-string ARE extracted.
        """
        parser = PowerShellParser()
        content = '$text = @"\n' 'Config: "config/settings.yaml"\n' '"@\n'
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "config/settings.yaml" in targets

    def test_array_of_paths(self):
        """Test extracting file paths from arrays."""
        parser = PowerShellParser()
        content = '$files = @(\n    "src/config.yaml",\n    "tests/test_main.py"\n)\n'
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "src/config.yaml" in targets
        assert "tests/test_main.py" in targets

    def test_write_host_with_path_only_string(self):
        """Test extracting file paths from Write-Host with path-only strings."""
        parser = PowerShellParser()
        content = 'Write-Host "output/results.json" -ForegroundColor Green\n'
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "output/results.json" in targets

    def test_no_false_positive_on_cmdlet_names(self):
        """Test that PowerShell cmdlet names are not detected as file paths."""
        parser = PowerShellParser()
        content = "Get-ChildItem | Where-Object { $_.Name }\n"
        refs = parser.parse_content(content, "test.ps1")
        assert len(refs) == 0

    def test_no_false_positive_on_variables(self):
        """Test that PowerShell variables are not detected as file paths."""
        parser = PowerShellParser()
        content = "$result = $env:USERPROFILE\n"
        refs = parser.parse_content(content, "test.ps1")
        assert len(refs) == 0

    def test_comment_inside_string_ignored(self):
        """Test that # inside a string is not treated as a comment start."""
        parser = PowerShellParser()
        # The # in the string should not start a comment
        content = '$msg = "Use # for comments"\n'
        refs = parser.parse_content(content, "test.ps1")
        # Should not find any file paths (the string doesn't contain a path)
        file_refs = [r for r in refs if r.link_type == "powershell-comment"]
        assert len(file_refs) == 0

    def test_multiple_paths_on_same_line(self):
        """Test extracting multiple file paths from the same line."""
        parser = PowerShellParser()
        content = "# Copy from src/input.txt to output/result.txt\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "src/input.txt" in targets
        assert "output/result.txt" in targets

    def test_line_numbers_are_correct(self):
        """Test that line numbers are 1-based and correct."""
        parser = PowerShellParser()
        content = "# First line\n# Second line: src/file.py\n# Third line\n"
        refs = parser.parse_content(content, "test.ps1")
        path_refs = [r for r in refs if r.link_target == "src/file.py"]
        assert len(path_refs) >= 1
        assert path_refs[0].line_number == 2

    def test_deduplication(self):
        """Test that duplicate references on the same line are deduplicated."""
        parser = PowerShellParser()
        # A quoted path on a comment line could match both quoted and comment patterns
        content = '# Path is "tests/data/config.yaml"\n'
        refs = parser.parse_content(content, "test.ps1")
        # Should not have duplicates for same target on same line at same column
        seen = set()
        for r in refs:
            key = (r.line_number, r.link_target, r.column_start)
            assert key not in seen, f"Duplicate reference: {key}"
            seen.add(key)

    def test_empty_content(self):
        """Test parsing empty content."""
        parser = PowerShellParser()
        refs = parser.parse_content("", "test.ps1")
        assert refs == []

    def test_content_with_no_paths(self):
        """Test parsing content that has no file paths."""
        parser = PowerShellParser()
        content = "$x = 42\nWrite-Host $x\n"
        refs = parser.parse_content(content, "test.ps1")
        assert refs == []

    def test_parse_file_from_disk(self, temp_project_dir):
        """Test parsing a real .ps1 file from disk."""
        parser = PowerShellParser()
        ps_file = temp_project_dir / "test-script.ps1"
        ps_file.write_text(
            "# Script for tests/data/config.yaml\n" '$path = "src/utils/helpers.py"\n'
        )
        refs = parser.parse_file(str(ps_file))
        targets = [r.link_target for r in refs]
        assert "tests/data/config.yaml" in targets
        assert "src/utils/helpers.py" in targets

    def test_block_comment_multiline(self):
        """Test multi-line block comment with multiple paths."""
        parser = PowerShellParser()
        content = (
            "<#\n"
            ".SYNOPSIS\n"
            "    Process files.\n"
            "\n"
            ".EXAMPLE\n"
            "    .\\process.ps1 -Input data/input.csv\n"
            "\n"
            ".NOTES\n"
            "    Config: config/settings.yaml\n"
            "    Output: output/report.md\n"
            "#>\n"
            "param($Input)\n"
        )
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "data/input.csv" in targets
        assert "config/settings.yaml" in targets
        assert "output/report.md" in targets

    def test_backslash_paths(self):
        """Test paths using backslashes (Windows-style)."""
        parser = PowerShellParser()
        content = "# See doc\\guides\\setup-guide.md\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "doc\\guides\\setup-guide.md" in targets


class TestEmbeddedMarkdownLinks:
    """Test extraction of markdown-style links embedded in PowerShell strings."""

    def test_embedded_md_link_with_variable(self):
        """Test markdown link with PS variable at end: [text](path/$var)."""
        parser = PowerShellParser()
        content = '$link = "[$id](doc/process-framework/assessments/$fileName)"\n'
        refs = parser.parse_content(content, "test.ps1")
        embedded = [r for r in refs if r.link_type == "powershell-embedded-md-link"]
        assert len(embedded) == 1
        assert embedded[0].link_target == "doc/process-framework/assessments/$fileName"

    def test_embedded_md_link_static_path(self):
        """Test markdown link with static directory path."""
        parser = PowerShellParser()
        content = '$link = "[Label](doc/some/directory)"\n'
        refs = parser.parse_content(content, "test.ps1")
        embedded = [r for r in refs if r.link_type == "powershell-embedded-md-link"]
        assert len(embedded) == 1
        assert embedded[0].link_target == "doc/some/directory"

    def test_embedded_md_link_in_write_host(self):
        """Test markdown link embedded in Write-Host string."""
        parser = PowerShellParser()
        content = (
            'Write-Host "  Add link: [$id](doc/framework/templates/$file)" '
            "-ForegroundColor Cyan\n"
        )
        refs = parser.parse_content(content, "test.ps1")
        embedded = [r for r in refs if r.link_type == "powershell-embedded-md-link"]
        assert len(embedded) == 1
        assert embedded[0].link_target == "doc/framework/templates/$file"

    def test_embedded_md_link_column_positions(self):
        """Test that column positions point to the path, not the full string."""
        parser = PowerShellParser()
        content = '$x = "[text](doc/path/here)"\n'
        refs = parser.parse_content(content, "test.ps1")
        embedded = [r for r in refs if r.link_type == "powershell-embedded-md-link"]
        assert len(embedded) == 1
        # The path starts after "](", verify it points to "doc/path/here"
        assert content[embedded[0].column_start : embedded[0].column_end] == "doc/path/here"

    def test_no_false_positive_non_path(self):
        """Test that non-path content in parens is not matched."""
        parser = PowerShellParser()
        content = '$x = "[label](just-text)"\n'
        refs = parser.parse_content(content, "test.ps1")
        embedded = [r for r in refs if r.link_type == "powershell-embedded-md-link"]
        assert len(embedded) == 0

    def test_embedded_md_link_not_duplicate_with_dir_match(self):
        """Test that a clean directory path matched by quoted_dir_pattern is not duplicated."""
        parser = PowerShellParser()
        # This is a clean dir path — matched by quoted_dir_pattern, not embedded pattern
        content = '-OutputDirectory "doc/process-framework/assessments"\n'
        refs = parser.parse_content(content, "test.ps1")
        dir_refs = [r for r in refs if r.link_type == "powershell-quoted-dir"]
        embedded = [r for r in refs if r.link_type == "powershell-embedded-md-link"]
        assert len(dir_refs) == 1
        # Should NOT also appear as embedded (no ]( pattern)
        assert len(embedded) == 0


class TestRegexPatternFiltering:
    """PD-BUG-033: Regex patterns in quoted strings must not be detected as file paths.

    Note: The parser still extracts these patterns (it has no semantic awareness).
    The fix is in _calculate_updated_relative_path() in reference_lookup.py, which
    skips rewriting references whose resolved target doesn't exist on disk.
    See TestBug033RegexNotRewrittenOnMove in tests/integration/test_link_updates.py
    for the integration-level regression tests.

    These parser-level tests document the current extraction behavior.
    """

    def test_parser_extracts_regex_as_dir_path(self):
        """Document that the parser currently extracts regex strings with backslashes.

        This is expected — the fix is in the updater layer, not the parser.
        The parser sees backslashes as path separators (quoted_dir_pattern).
        """
        parser = PowerShellParser()
        content = r"if ($fileName -match 'ART-ASS-\d+-([0-9]+\.[0-9]+\.[0-9]+)-') {" + "\n"
        refs = parser.parse_content(content, "test.ps1")
        # Parser DOES extract this (by design — filtered at update time)
        regex_refs = [r for r in refs if "ART-ASS" in r.link_target]
        assert len(regex_refs) >= 1, "Parser should extract regex string (filtered at update layer)"

    def test_legitimate_single_quoted_path_still_detected(self):
        """Single-quoted file paths must still be detected by the parser."""
        parser = PowerShellParser()
        content = "$path = 'src/utils/helpers.py'\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "src/utils/helpers.py" in targets


class TestBug057BlockCommentDirectoryPaths:
    """PD-BUG-057: Directory paths in block comments and here-strings are not detected.

    Root cause: Block comment and here-string lines only get path_pattern extraction
    (requires file extension). The quoted_dir_pattern check that detects directory
    paths is skipped because block comment processing uses `continue`.
    """

    def test_quoted_dir_path_in_block_comment(self):
        """Quoted directory path in block comment .EXAMPLE should be detected."""
        parser = PowerShellParser()
        content = (
            "<#\n"
            ".EXAMPLE\n"
            '    Get-PrefixDirectories -Prefix "PF-TSK" -DirectoryType "discrete"\n'
            '    # Returns: "doc/process-framework/tasks/discrete"\n'
            "#>\n"
        )
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "doc/process-framework/tasks/discrete" in targets

    def test_unquoted_dir_path_in_block_comment_prose_not_detected(self):
        """Unquoted directory paths in prose are NOT detected (scope of PD-BUG-055, not 057).

        PD-BUG-057 covers quoted string literals. Unquoted prose paths like
        "defaults to doc/path/" are a separate issue tracked as PD-BUG-055.
        """
        parser = PowerShellParser()
        content = (
            "<#\n"
            ".PARAMETER AssessmentDirectory\n"
            "Directory containing files "
            "(defaults to doc/process-framework/assessments/technical-debt/)\n"
            "#>\n"
        )
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        # Unquoted dir paths in prose are not detected — this is expected behavior
        assert not any("doc/process-framework/assessments/technical-debt" in t for t in targets)

    def test_quoted_dir_path_in_example_command(self):
        """Quoted directory path in .EXAMPLE command argument should be detected."""
        parser = PowerShellParser()
        content = (
            "<#\n"
            ".EXAMPLE\n"
            '    Test-ValidDirectoryForPrefix -Prefix "PF-FEE" '
            '-Directory "doc/process-framework/feedback/feedback-forms"\n'
            "#>\n"
        )
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "doc/process-framework/feedback/feedback-forms" in targets

    def test_dir_path_in_here_string(self):
        """Directory path in here-string should be detected."""
        parser = PowerShellParser()
        content = (
            '$text = @"\n' 'Location: "doc/process-framework/state-tracking/temporary"\n' '"@\n'
        )
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "doc/process-framework/state-tracking/temporary" in targets

    def test_file_path_in_block_comment_still_works(self):
        """File paths with extensions in block comments should still be detected (no regression)."""
        parser = PowerShellParser()
        content = "<#\n" "See doc/guides/setup-guide.md for details\n" "#>\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "doc/guides/setup-guide.md" in targets

    def test_embedded_md_link_in_block_comment(self):
        """Markdown-style link in block comment should be detected."""
        parser = PowerShellParser()
        content = "<#\n" "See [Guide](doc/process-framework/guides/support) for details\n" "#>\n"
        refs = parser.parse_content(content, "test.ps1")
        targets = [r.link_target for r in refs]
        assert "doc/process-framework/guides/support" in targets
