"""
Tests for the Markdown parser.

This module tests markdown-specific link parsing functionality.
"""

import pytest

from linkwatcher.parsers.markdown import MarkdownParser

pytestmark = [
    pytest.mark.feature("2.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("parser"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md"
    ),
]


class TestMarkdownParser:
    """Test cases for MarkdownParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = MarkdownParser()

        # Check that regex patterns are compiled
        assert parser.link_pattern is not None
        assert parser.quoted_pattern is not None
        assert parser.standalone_pattern is not None

    def test_parse_standard_markdown_links(self, temp_project_dir):
        """Test parsing standard markdown links [text](url)."""
        parser = MarkdownParser()

        # Create markdown file with standard links
        md_file = temp_project_dir / "test.md"
        content = """# Test Document

This has a [link to file](test.txt) and another [link](../other/file.md).
Also a [link with anchor](document.md#section).
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find all markdown links
        assert len(references) >= 3

        # Check specific links
        targets = [ref.link_target for ref in references]
        assert "test.txt" in targets
        assert "../other/file.md" in targets
        assert "document.md#section" in targets

        # Check link types
        for ref in references:
            if ref.link_type == "markdown":
                assert ref.link_text in ["link to file", "link", "link with anchor"]

    def test_parse_quoted_file_references(self, temp_project_dir):
        """Test parsing quoted file references."""
        parser = MarkdownParser()

        # Create markdown file with quoted references
        md_file = temp_project_dir / "test.md"
        content = """# Test Document

This document references "config.yaml" and 'data.json'.
Also mentions "tests/parsers/file.txt" in quotes.
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find quoted references
        assert len(references) >= 3

        # Check specific references
        targets = [ref.link_target for ref in references]
        assert "config.yaml" in targets
        assert "data.json" in targets
        assert "tests/parsers/file.txt" in targets

        # Check link types
        quoted_refs = [ref for ref in references if ref.link_type == "markdown-quoted"]
        assert len(quoted_refs) >= 3

    def test_parse_standalone_file_references(self, temp_project_dir):
        """Test parsing standalone file references.

        Regression: PD-BUG-080
        """
        parser = MarkdownParser()

        # Create markdown file with standalone references
        md_file = temp_project_dir / "test.md"
        content = """# Test Document

This document mentions tests/parsers/file.txt and another_file.json.
Also references path/to/document.md in the text.
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # PD-BUG-080: Must NOT miss paths followed by sentence punctuation
        targets = [ref.link_target for ref in references]
        assert (
            "another_file.json" in targets
        ), "another_file.json not found — trailing period broke standalone match"
        assert "tests/parsers/file.txt" in targets
        assert "path/to/document.md" in targets

        # Should find standalone references
        assert len(references) >= 3

        # Check link types
        standalone_refs = [ref for ref in references if ref.link_type == "markdown-standalone"]
        assert len(standalone_refs) >= 3

    def test_parse_standalone_trailing_punctuation_variants(self, temp_project_dir):
        """Test standalone paths followed by various sentence punctuation.

        Regression: PD-BUG-080
        """
        parser = MarkdownParser()

        md_file = temp_project_dir / "punct.md"
        content = """# Punctuation tests

See docs/guide.md.
Check src/main.py,
Read config/app.yaml;
Open lib/utils.js:
Run tests/run.sh!
Try tools/check.py?
Inside (path/to/file.txt) parentheses.
"""
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        assert "docs/guide.md" in targets, "Period boundary failed"
        assert "src/main.py" in targets, "Comma boundary failed"
        assert "config/app.yaml" in targets, "Semicolon boundary failed"
        assert "lib/utils.js" in targets, "Colon boundary failed"
        assert "tests/run.sh" in targets, "Exclamation boundary failed"
        assert "tools/check.py" in targets, "Question mark boundary failed"
        assert "path/to/file.txt" in targets, "Closing paren boundary failed"

    def test_skip_external_links(self, temp_project_dir):
        """Test that external links are skipped."""
        parser = MarkdownParser()

        # Create markdown file with external links
        md_file = temp_project_dir / "test.md"
        content = """# Test Document

This has [external link](https://example.com) and [email](mailto:test@example.com).
Also [local link](local.txt) which should be found.
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should only find local link
        targets = [ref.link_target for ref in references]
        assert "local.txt" in targets
        assert "https://example.com" not in targets
        assert "mailto:test@example.com" not in targets

    def test_skip_anchor_only_links(self, temp_project_dir):
        """Test that anchor-only links are skipped."""
        parser = MarkdownParser()

        # Create markdown file with anchor-only links
        md_file = temp_project_dir / "test.md"
        content = """# Test Document

This has [anchor link](#section) and [file with anchor](file.txt#section).
Also [local link](local.txt) which should be found.
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find file links but not anchor-only
        targets = [ref.link_target for ref in references]
        assert "local.txt" in targets
        assert "file.txt#section" in targets
        assert "#section" not in targets

    def test_avoid_duplicate_detection(self, temp_project_dir):
        """Test that the same reference isn't detected multiple times."""
        parser = MarkdownParser()

        # Create markdown file where same file could be detected by multiple patterns
        md_file = temp_project_dir / "test.md"
        content = """# Test Document

This has a [markdown link](test.txt) on the same line as "test.txt".
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find both references (they're different - one markdown, one quoted)
        test_txt_refs = [ref for ref in references if ref.link_target == "test.txt"]
        assert len(test_txt_refs) == 2

        # Should have different types
        types = [ref.link_type for ref in test_txt_refs]
        assert "markdown" in types
        assert "markdown-quoted" in types

    def test_line_and_column_positions(self, temp_project_dir):
        """Test that line and column positions are correctly recorded."""
        parser = MarkdownParser()

        # Create markdown file with known positions
        md_file = temp_project_dir / "test.md"
        content = """# Test Document
This has a [link](test.txt) here.
And "quoted.txt" on this line.
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Check positions
        for ref in references:
            assert ref.line_number > 0
            assert ref.column_start >= 0
            assert ref.column_end > ref.column_start

            # Verify position makes sense
            lines = content.split("\n")
            if ref.line_number <= len(lines):
                line = lines[ref.line_number - 1]
                if ref.column_end <= len(line):
                    extracted = line[ref.column_start : ref.column_end]
                    # Should contain the link target or be part of the link syntax
                    assert ref.link_target in extracted or ref.link_target in line

    def test_complex_markdown_document(self, temp_project_dir):
        """Test parsing a complex markdown document."""
        parser = MarkdownParser()

        # Create complex markdown file
        md_file = temp_project_dir / "complex.md"
        content = """# Complex Document

## Introduction
This document has various types of links:

1. [Standard link](docs/readme.md)
2. [Link with anchor](api.md#methods)
3. [Relative link](../config/settings.yaml)

## Code Examples
```python
# This code references "example.py"
import example
```

## References
- Configuration file: "config.json"
- Data file: 'data.csv'
- Template: templates/main.html

## External Links
- [GitHub](https://github.com)
- [Email](mailto:test@example.com)

## Anchors
- [Section](#introduction)
- [Another section](#code-examples)
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find multiple references
        assert len(references) >= 6

        # Check for expected local file references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "docs/readme.md",
            "api.md#methods",
            "../config/settings.yaml",
            "example.py",
            "config.json",
            "data.csv",
            "templates/main.html",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

        # Should not find external links or anchor-only links
        assert "https://github.com" not in targets
        assert "mailto:test@example.com" not in targets
        assert "#introduction" not in targets

    def test_empty_file(self, temp_project_dir):
        """Test parsing an empty markdown file."""
        parser = MarkdownParser()

        # Create empty file
        md_file = temp_project_dir / "empty.md"
        md_file.write_text("")

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should return empty list
        assert references == []

    def test_file_with_no_links(self, temp_project_dir):
        """Test parsing a markdown file with no links."""
        parser = MarkdownParser()

        # Create file with no links
        md_file = temp_project_dir / "no_links.md"
        content = """# Document Without Links

This is just plain text with no file references.
It has some words that might look like files but aren't:
- word.extension (but not a real file reference)
- http://example.com (external, should be ignored)
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find minimal or no references
        # (word.extension might be detected as standalone, depending on heuristics)
        assert len(references) <= 1

    def test_error_handling(self):
        """Test error handling for invalid files."""
        parser = MarkdownParser()

        # Try to parse non-existent file
        references = parser.parse_file("nonexistent.md")

        # Should return empty list without crashing
        assert references == []

    # ========================================================================
    # DOCUMENTED TEST CASES (MP-001 to MP-009)
    # These test cases match the documented test IDs in TEST_CASE_STATUS.md
    # ========================================================================

    @pytest.mark.critical
    def test_mp_001_standard_links(self, temp_project_dir):
        """
        MP-001: Standard links

        Test Case: [text](file.txt) parsing
        Expected: Correctly identify and parse standard markdown links
        Priority: Critical
        """
        parser = MarkdownParser()

        # Create markdown file with various standard link formats
        md_file = temp_project_dir / "test.md"
        content = """# Standard Links Test

Standard markdown links:
- [Simple link](file.txt)
- [Link with path](docs/readme.md)
- [Link with extension](config.json)
- [Multiple](first.txt) [links](second.txt) on same line
- [Link with spaces in text](file with spaces.txt)

Inline: This is a [link in paragraph](inline.txt) within text.
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find all standard links
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "file.txt",
            "docs/readme.md",
            "config.json",
            "first.txt",
            "second.txt",
            "file with spaces.txt",
            "inline.txt",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

        # Verify link types are correct
        markdown_refs = [ref for ref in references if ref.link_type == "markdown"]
        assert len(markdown_refs) >= 7

    @pytest.mark.high
    def test_mp_002_reference_links(self, temp_project_dir):
        """
        MP-002: Reference links

        Test Case: [text][ref] and [ref]: url parsing
        Expected: Correctly identify reference-style links
        Priority: High
        """
        parser = MarkdownParser()

        # Create markdown file with reference links
        md_file = temp_project_dir / "test.md"
        content = """# Reference Links Test

Reference style links:
- [Link text][ref1]
- [Another link][ref2]
- [Third link][ref3]

Reference definitions:
[ref1]: file1.txt "Title 1"
[ref2]: docs/file2.md
[ref3]: config/settings.yaml "Configuration file"

Also test [shorthand reference][] style.
[shorthand reference]: shorthand.txt
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find reference link targets
        targets = [ref.link_target for ref in references]
        expected_targets = ["file1.txt", "docs/file2.md", "config/settings.yaml", "shorthand.txt"]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    @pytest.mark.high
    def test_mp_003_backtick_quoted_paths(self, temp_project_dir):
        """
        MP-003: Backtick-quoted file and directory paths (PD-BUG-054)

        Test Case: `path/to/file.ext` and `path/to/dir/` should be detected
        Expected: Paths inside backtick inline code are parsed as references
        Priority: High
        """
        parser = MarkdownParser()

        file_a = "vendor/tools/scripts/New-Task.ps1"
        dir_a = "vendor/tools/scripts"
        dir_b = "vendor/tasks/support"
        file_b = "alpha-project/docs/guides/setup.md"

        md_file = temp_project_dir / "test.md"
        content = (
            "# Backtick Path Test\n\n"
            "Real markdown links:\n"
            "- [Real link](real.txt)\n\n"
            "Backtick-quoted file paths (should be detected):\n"
            f"- Use `{file_a}` to create tasks\n"
            "- The config is at `config/settings.yaml`\n\n"
            "Backtick-quoted directory paths (should be detected):\n"
            f"- Scripts are in `{dir_a}`\n"
            f"- Navigate to `{dir_b}`\n\n"
            "Mixed content:\n"
            f"- Real [link](mixed.txt) and `{file_b}` inline\n"
        )
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        # Real markdown links still detected
        assert "real.txt" in targets
        assert "mixed.txt" in targets

        # Backtick-quoted file paths detected
        assert file_a in targets
        assert "config/settings.yaml" in targets

        # Backtick-quoted directory paths detected
        assert dir_a in targets
        assert dir_b in targets

        # Backtick-quoted file path in mixed line detected
        assert file_b in targets

    @pytest.mark.high
    def test_mp_004_code_block_bare_paths(self, temp_project_dir):
        """
        MP-004: Bare paths inside fenced code blocks (PD-BUG-054)

        Test Case: Bare directory paths in code blocks should be detected
        Expected: Paths in code blocks are parsed as references
        Priority: High
        """
        parser = MarkdownParser()

        dir_path = "vendor/tools/scripts/support"
        file_path = "vendor/tasks/support/creation-process.md"

        md_file = temp_project_dir / "test.md"
        content = (
            "# Code Block Path Test\n\n"
            "Real link before code:\n"
            "[Real link](before.txt)\n\n"
            "```powershell\n"
            f"cd {dir_path}\n"
            './New-FeedbackForm.ps1 -DocumentId "PF-TSK-XXX"\n'
            "```\n\n"
            "```bash\n"
            f"cd /c/path/to/project/{dir_path} && pwsh.exe -Command 'test'\n"
            "```\n\n"
            "```\n"
            "Plain code block\n"
            f"{file_path}\n"
            "```\n\n"
            "Real link after code:\n"
            "[Real link](after.txt)\n"
        )
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        # Real markdown links still detected
        assert "before.txt" in targets
        assert "after.txt" in targets

        # Bare directory path in code block detected
        assert dir_path in targets

        # Bare file path in code block detected
        assert file_path in targets

    @pytest.mark.medium
    def test_mp_005_html_links(self, temp_project_dir):
        """
        MP-005: HTML links in markdown

        Test Case: <a href="file.txt">text</a> parsing
        Expected: HTML links in markdown are parsed
        Priority: Medium
        """
        parser = MarkdownParser()

        # Create markdown file with HTML links
        md_file = temp_project_dir / "test.md"
        content = """# HTML Links Test

HTML links in markdown:
- <a href="../../manual_markdown_tests/test_project/documentatio/file1.txt">HTML Link 1</a>
- <a href="docs/file2.md">HTML Link 2</a>
- <a href="config.json" title="Config">Configuration</a>

Mixed with markdown:
- [Markdown link](markdown.txt) and <a href="html.txt">HTML link</a>

Self-closing and various formats:
- <a href='single-quotes.txt'>Single quotes</a>
- <a href="spaces in name.txt">Spaces in filename</a>
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find HTML links
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "../../manual_markdown_tests/test_project/documentatio/file1.txt",
            "docs/file2.md",
            "config.json",
            "markdown.txt",
            "html.txt",
            "single-quotes.txt",
            "spaces in name.txt",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    def test_html_anchor_basic_parsing(self, temp_project_dir):
        """PD-BUG-011 regression: HTML anchor tags should be parsed in markdown."""
        parser = MarkdownParser()

        md_file = temp_project_dir / "test.md"
        content = """# HTML Anchors

- <a href="docs/guide.md">Guide</a>
- <a href="config.json">Config</a>
- <a href='single.txt'>Single quotes</a>
"""
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        assert "docs/guide.md" in targets
        assert "config.json" in targets
        assert "single.txt" in targets

        # Verify link_type is html-anchor (not accidental quoted match)
        html_refs = [r for r in references if r.link_type == "html-anchor"]
        html_targets = [r.link_target for r in html_refs]
        assert "docs/guide.md" in html_targets
        assert "config.json" in html_targets
        assert "single.txt" in html_targets

    def test_html_anchor_no_double_capture(self, temp_project_dir):
        """PD-BUG-011 regression: HTML href values must not also be captured by quoted_pattern."""
        parser = MarkdownParser()

        md_file = temp_project_dir / "test.md"
        content = """# No duplicates
- <a href="file.txt">link</a>
"""
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        # file.txt should appear exactly once (not duplicated by quoted_pattern)
        assert targets.count("file.txt") == 1

    @pytest.mark.medium
    def test_mp_006_image_links(self, temp_project_dir):
        """
        MP-006: Image links

        Test Case: ![alt](image.png) parsing
        Expected: Image links are parsed correctly
        Priority: Medium
        """
        parser = MarkdownParser()

        # Create markdown file with image links
        md_file = temp_project_dir / "test.md"
        content = """# Image Links Test

Image links:
- ![Logo](logo.png)
- ![Screenshot](screenshots/main.png)
- ![Icon](assets/icon.svg "Application icon")

Reference style images:
- ![Alt text][img1]
- ![Another image][img2]

[img1]: images/photo1.jpg "Photo 1"
[img2]: images/photo2.jpg

Mixed content:
Text with ![inline image](inline.png) in paragraph.
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find all image links
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "logo.png",
            "screenshots/main.png",
            "assets/icon.svg",
            "images/photo1.jpg",
            "images/photo2.jpg",
            "inline.png",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    @pytest.mark.medium
    def test_mp_007_links_with_titles(self, temp_project_dir):
        """
        MP-007: Links with titles

        Test Case: [text](file.txt "title") parsing
        Expected: Links with titles are parsed, titles preserved
        Priority: Medium
        """
        parser = MarkdownParser()

        # Create markdown file with titled links
        md_file = temp_project_dir / "test.md"
        content = """# Links with Titles Test

Links with titles:
- [Link 1](file1.txt "This is title 1")
- [Link 2](file2.txt 'Single quote title')
- [Link 3](file3.txt (Parentheses title))

Reference links with titles:
[ref1]: reference1.txt "Reference title 1"
[ref2]: reference2.txt 'Reference title 2'

Image with title:
![Image](image.png "Image title")
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find all links regardless of title format
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "file1.txt",
            "file2.txt",
            "file3.txt",
            "reference1.txt",
            "reference2.txt",
            "image.png",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    @pytest.mark.xfail(reason="Regex requires non-empty link text; no escape handling")
    @pytest.mark.low
    def test_mp_008_malformed_links(self, temp_project_dir):
        """
        MP-008: Malformed links

        Test Case: [text](file.txt handling of malformed syntax
        Expected: Graceful handling of malformed links
        Priority: Low
        """
        parser = MarkdownParser()

        # Create markdown file with malformed links
        md_file = temp_project_dir / "test.md"
        content = """# Malformed Links Test

Valid links (should be found):
- [Valid link](valid.txt)

Malformed links (graceful handling):
- [Missing closing paren](missing.txt
- [Missing opening paren]missing2.txt)
- [Empty link]()
- [](empty-text.txt)
- [Unmatched [brackets](unmatched.txt)
- [Double [[brackets]]](double.txt)

Edge cases:
- [Link with \\[escaped\\] brackets](escaped.txt)
- [Link](file.txt) [Another](file2.txt) multiple on line
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find valid links
        targets = [ref.link_target for ref in references]

        # Should definitely find valid links
        assert "valid.txt" in targets
        assert "escaped.txt" in targets
        assert "file.txt" in targets
        assert "file2.txt" in targets

        # Parser should handle malformed links gracefully (not crash)
        # Some malformed links might be partially parsed, which is acceptable

    @pytest.mark.xfail(reason="Parser has no markdown escape sequence (backslash-bracket) handling")
    @pytest.mark.low
    def test_mp_009_escaped_characters(self, temp_project_dir):
        """
        MP-009: Escaped characters

        Test Case: [text](file\\.txt) with escaped characters
        Expected: Escaped characters handled correctly
        Priority: Low
        """
        parser = MarkdownParser()

        # Create markdown file with escaped characters
        md_file = temp_project_dir / "test.md"
        content = r"""# Escaped Characters Test

Links with escaped characters:
- [Escaped brackets](file\[1\].txt)
- [Escaped parentheses](file\(2\).txt)
- [Escaped backslash](file\\3.txt)

Text with escaped link syntax (should not be links):
- \[Not a link\](not-link.txt)
- This is \[escaped\] text

Valid links mixed with escaped text:
- [Real link](real.txt) and \[fake link\](fake.txt)
- \[Escaped\] [Valid link](valid.txt)

Special characters in filenames:
- [File with spaces](file with spaces.txt)
- [File with dots](file.name.txt)
- [File with dashes](file-name.txt)
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find valid links
        targets = [ref.link_target for ref in references]

        # Should find links with escaped characters in filenames
        expected_valid = [
            "real.txt",
            "valid.txt",
            "file with spaces.txt",
            "file.name.txt",
            "file-name.txt",
        ]

        for expected in expected_valid:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

        # Should NOT find escaped link syntax
        assert "not-link.txt" not in targets
        assert "fake.txt" not in targets

        # Files with escaped characters in names might be found depending on parser implementation
        # This is acceptable as long as the parser doesn't crash

    # ========================================================================
    # LINK REFERENCE TYPE TESTS (LR-001 to LR-003)
    # These test cases focus on parser-level detection of different link types
    # ========================================================================

    @pytest.mark.critical
    def test_lr_001_standard_links(self, temp_project_dir):
        """
        LR-001: Markdown standard links

        Test Case: Parser detection of [text](file.txt) links
        Expected: Standard markdown links correctly identified
        Priority: Critical
        """
        parser = MarkdownParser()

        # Create markdown file with standard links
        md_file = temp_project_dir / "test.md"
        content = """# Standard Links

- [Documentation](docs/readme.md)
- [Configuration](config.yaml)
- [Source code](src/main.py)
- [Tests](tests/test_main.py)

Inline links: See [API reference](api.md) for details.
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Verify all standard links found
        targets = [ref.link_target for ref in references]
        expected = ["docs/readme.md", "config.yaml", "src/main.py", "tests/test_main.py", "api.md"]

        for target in expected:
            assert target in targets, f"Standard link '{target}' not found"

        # Verify link types
        markdown_links = [ref for ref in references if ref.link_type == "markdown"]
        assert len(markdown_links) >= 5

    @pytest.mark.critical
    def test_lr_002_relative_links(self, temp_project_dir):
        """
        LR-002: Markdown relative links

        Test Case: Parser detection of relative path links
        Expected: Relative paths correctly parsed
        Priority: Critical
        """
        parser = MarkdownParser()

        # Create markdown file with relative links
        md_file = temp_project_dir / "test.md"
        content = """# Relative Links

- [Parent directory](../parent.txt)
- [Sibling directory](../sibling/file.md)
- [Current directory](current.txt)
- [Subdirectory](sub/file.txt)
- [Deep path](../../deep/path/file.txt)

Navigation:
- [Up one level](../index.md)
- [Down two levels](dir1/dir2/file.txt)
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Verify relative links found
        targets = [ref.link_target for ref in references]
        expected_relative = [
            "../parent.txt",
            "../sibling/file.md",
            "current.txt",
            "sub/file.txt",
            "../../deep/path/file.txt",
            "../index.md",
            "dir1/dir2/file.txt",
        ]

        for target in expected_relative:
            assert target in targets, f"Relative link '{target}' not found"

    @pytest.mark.high
    def test_lr_003_links_with_anchors(self, temp_project_dir):
        """
        LR-003: Markdown with anchors

        Test Case: Parser detection of links with anchors
        Expected: Links with anchors correctly parsed
        Priority: High
        """
        parser = MarkdownParser()

        # Create markdown file with anchor links
        md_file = temp_project_dir / "test.md"
        content = """# Links with Anchors

- [Introduction](readme.md#introduction)
- [Configuration](config.md#setup)
- [API Methods](api.md#methods)
- [Troubleshooting](docs/help.md#common-issues)

Internal anchors:
- [Section 1](#section-1)
- [Section 2](#section-2)

Mixed:
- [File without anchor](plain.md)
- [File with anchor](guide.md#getting-started)
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Verify anchor links found
        targets = [ref.link_target for ref in references]
        expected_with_anchors = [
            "readme.md#introduction",
            "config.md#setup",
            "api.md#methods",
            "docs/help.md#common-issues",
            "guide.md#getting-started",
        ]

        expected_without_anchors = ["plain.md"]

        # Should find links with anchors
        for target in expected_with_anchors:
            assert target in targets, f"Anchor link '{target}' not found"

        # Should find links without anchors
        for target in expected_without_anchors:
            assert target in targets, f"Plain link '{target}' not found"

        # Should NOT find internal anchors (anchor-only links)
        assert "#section-1" not in targets
        assert "#section-2" not in targets

    # ========================================================================
    # DIRECTORY PATH DETECTION TESTS (PD-BUG-031 regression)
    # ========================================================================

    @pytest.mark.high
    def test_bug031_quoted_directory_paths_detected(self, temp_project_dir):
        """
        PD-BUG-031 regression: Quoted directory paths (no file extension) should be detected.

        The markdown parser previously only used looks_like_file_path() which requires
        a file extension. Directory paths like "vendor/tasks" were silently
        skipped. The fix integrates looks_like_directory_path() for quoted strings.
        """
        parser = MarkdownParser()

        dir_a = "vendor/tools/scripts"
        dir_b = "vendor/tools/templates"
        dir_c = "lib/docs/architecture"
        dir_d = "vendor/methods/documentation-tiers"

        md_file = temp_project_dir / "test.md"
        content = (
            "# Directory Path Test\n\n"
            "Paths in documentation:\n"
            f'- Use `cd "{dir_a}"` to navigate\n'
            f'- The templates are in "{dir_b}"\n'
            f"- See '{dir_c}' for details\n\n"
            "PowerShell examples:\n"
            "```powershell\n"
            f'cd "{dir_d}"\n'
            "```\n"
        )
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        # Should detect quoted directory paths (no extension)
        assert dir_a in targets
        assert dir_b in targets
        assert dir_c in targets
        assert dir_d in targets

        # Verify link type
        dir_refs = [r for r in references if r.link_type == "markdown-quoted-dir"]
        assert len(dir_refs) >= 3

    @pytest.mark.high
    def test_bug031_directory_paths_no_overlap_with_markdown_links(self, temp_project_dir):
        """
        PD-BUG-031 regression: Directory paths inside markdown links should not
        be double-detected by the quoted directory pattern.
        """
        parser = MarkdownParser()

        link_target = "vendor/tools/templates"
        dir_target = "vendor/docs/guides"

        md_file = temp_project_dir / "test.md"
        content = (
            "# Overlap Test\n\n"
            f"- [Templates directory]({link_target})\n"
            f'- Also see "{dir_target}" for guides\n'
        )
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))

        # The markdown link target should be detected once as "markdown" type
        md_refs = [r for r in references if r.link_target == link_target]
        assert len(md_refs) == 1
        assert md_refs[0].link_type == "markdown"

        # The standalone quoted path should be detected as directory
        dir_refs = [r for r in references if r.link_target == dir_target]
        assert len(dir_refs) >= 1

    @pytest.mark.medium
    def test_bug031_non_directory_strings_not_detected(self, temp_project_dir):
        """
        PD-BUG-031 regression: Strings that look like directories but aren't
        should not be falsely detected.
        """
        parser = MarkdownParser()

        md_file = temp_project_dir / "test.md"
        content = """# False Positive Test

- URL: "https://github.com/user/repo"
- Email: "user@example.com"
- Short text: "hello"
- No separators: "just-a-string"
"""
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        dir_refs = [r for r in references if r.link_type == "markdown-quoted-dir"]

        # None of these should be detected as directory paths
        assert len(dir_refs) == 0

    @pytest.mark.high
    def test_mp_010_at_prefix_paths(self, temp_project_dir):
        """
        MP-010: @-prefixed path references (PD-BUG-055)

        Test Case: @vendor/tools/entry-point.md should be detected
        Expected: Paths prefixed with @ are parsed with @ stripped from target
        Priority: High
        """
        parser = MarkdownParser()

        file_a = "vendor/tools/entry-point.md"
        file_b = "vendor/tools/tasks.md"
        file_c = "vendor/tools/id-registry.json"
        file_d = "lib/docs/id-registry.json"

        md_file = temp_project_dir / "test.md"
        content = (
            "# At-Prefix Path Test\n\n"
            f"1. **Read the entry point**: @{file_a}\n"
            f"2. **Select a task**: @{file_b} - All work MUST be task-based\n"
            f"- Tracked in @{file_c} and @{file_d}\n"
        )
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        # @ prefix paths detected with @ stripped
        assert file_a in targets
        assert file_b in targets
        assert file_c in targets
        assert file_d in targets

    @pytest.mark.high
    def test_mp_011_leading_slash_paths(self, temp_project_dir):
        """
        MP-011: Leading slash path references (PD-BUG-055)

        Test Case: /vendor/data/forms/ should be detected
        Expected: Paths with leading / are parsed as references
        Priority: High
        """
        parser = MarkdownParser()

        dir_a = "vendor/data/forms"
        file_a = "vendor/tools/templates/feedback-form-template.md"
        dir_b = "vendor/tools/scripts/support"

        md_file = temp_project_dir / "test.md"
        content = (
            "# Leading Slash Path Test\n\n"
            f"Files saved to: /{dir_a}/\n"
            f"Ensure the template exists at /{file_a}\n"
            f"Navigate to /{dir_b} directory\n"
        )
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        # Leading slash directory path detected (parser may retain trailing slash)
        assert f"/{dir_a}/" in targets or f"/{dir_a}" in targets or dir_a in targets

        # Leading slash file path detected
        assert f"/{file_a}" in targets or file_a in targets

        # Leading slash directory path (no trailing slash) detected
        assert f"/{dir_b}" in targets or dir_b in targets

    @pytest.mark.medium
    def test_mp_012_mermaid_blocks_excluded(self, temp_project_dir):
        """
        MP-012: Mermaid code blocks are excluded (PD-BUG-055)

        Test Case: Paths in ```mermaid blocks should be ignored
        Expected: Mermaid diagram content is purely illustrative, not parsed
        Priority: Medium
        """
        parser = MarkdownParser()

        bash_dir = "vendor/tools/scripts"
        mermaid_dir = "vendor/tools/scripts/support"
        mermaid_dir2 = "vendor/data/forms"

        md_file = temp_project_dir / "test.md"
        content = (
            "# Mermaid Exclusion Test\n\n"
            "Real link before:\n"
            "[Real link](before.txt)\n\n"
            "```mermaid\n"
            "graph TD\n"
            f"    C --> D[cd {mermaid_dir}]\n"
            f"    W --> X[/{mermaid_dir2}/]\n"
            "```\n\n"
            "Real link after:\n"
            "[Real link](after.txt)\n\n"
            "```bash\n"
            f"cd {bash_dir}\n"
            "```\n"
        )
        md_file.write_text(content)

        references = parser.parse_file(str(md_file))
        targets = [ref.link_target for ref in references]

        # Real links detected
        assert "before.txt" in targets
        assert "after.txt" in targets

        # Bash code block paths still detected (not mermaid)
        assert bash_dir in targets

        # Mermaid content NOT detected
        mermaid_paths = [t for t in targets if "forms" in t or "scripts/support" in t]
        assert len(mermaid_paths) == 0, f"Mermaid paths should not be detected: {mermaid_paths}"


class TestMarkdownParserBracketPlaceholders:
    """PD-BUG-063: bare_path_pattern cannot match paths with [ ] template placeholders.

    Root cause: bare_path_pattern uses [a-zA-Z0-9_.\\-] for path segments,
    which excludes [ and ] characters. Known limitation, no immediate fix planned.
    """

    @pytest.mark.xfail(reason="PD-BUG-063: bare_path_pattern excludes [ ] from character class")
    def test_bare_path_with_bracket_placeholders(self):
        """Paths with bracket template placeholders should be detected."""
        parser = MarkdownParser()
        content = "Run the script at alpha-project/framework/[category]/New-[ScriptName].ps1\n"
        references = parser.parse_content(content, "test.md")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/framework/[category]/New-[ScriptName].ps1" in targets


class TestMarkdownParserParenthesizedProsePaths:
    """PD-BUG-064: bare_path_pattern detects paths followed by closing parenthesis."""

    def test_path_in_parenthesized_prose(self):
        """Path inside parenthesized prose should be detected."""
        parser = MarkdownParser()
        content = "Use the test runner (script: alpha-project/scripts/test/Run-Tests.ps1)\n"
        references = parser.parse_content(content, "test.md")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/scripts/test/Run-Tests.ps1" in targets

    def test_path_in_section_header_parentheses(self):
        """Directory path in section header parentheses should be detected."""
        parser = MarkdownParser()
        content = "### Script.ps1 (alpha-project/scripts/file-creation/)\n"
        references = parser.parse_content(content, "test.md")
        targets = [ref.link_target for ref in references]
        assert any("alpha-project/scripts/file-creation" in t for t in targets)

    def test_standard_markdown_link_not_double_matched(self):
        """Standard markdown links [text](path) should not be affected by ) lookahead."""
        parser = MarkdownParser()
        content = "See [the guide](alpha-project/docs/guides/support/guide.md) for details.\n"
        references = parser.parse_content(content, "test.md")
        # Should have exactly one reference (the markdown link), not a duplicate bare path
        targets = [ref.link_target for ref in references]
        assert targets.count("alpha-project/docs/guides/support/guide.md") == 1

    def test_path_followed_by_space_still_works(self):
        """Existing behavior: path followed by space should still be detected."""
        parser = MarkdownParser()
        content = "Run alpha-project/scripts/test/Run-Tests.ps1 to execute tests.\n"
        references = parser.parse_content(content, "test.md")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/scripts/test/Run-Tests.ps1" in targets


class TestMarkdownParserBarePathProseFiltering:
    """PD-BUG-084: bare_path_pattern should not duplicate standalone detections on prose lines.

    Root cause: all_spans passed to _extract_bare_paths only included standard
    markdown link and HTML anchor spans. Paths already detected by standalone,
    quoted, or backtick patterns were re-detected by bare_path, causing false
    positive duplicates that corrupt prose/comment text during updates.
    """

    def test_prose_comment_no_bare_path_duplicate(self):
        """Prose line with file paths should not produce bare-path duplicates."""
        parser = MarkdownParser()
        content = "- Should find: test_project/docs/readme.md\n"
        references = parser.parse_content(content, "test.md")
        bare_path_refs = [r for r in references if r.link_type == "markdown-bare-path"]
        # standalone already detects this path; bare_path should not duplicate it
        assert len(bare_path_refs) == 0, (
            f"bare_path should not duplicate standalone detection, got: "
            f"{[r.link_target for r in bare_path_refs]}"
        )

    def test_prose_comma_separated_no_bare_path_duplicate(self):
        """Comma-separated paths in prose should not produce bare-path duplicates."""
        parser = MarkdownParser()
        content = (
            "- Should find: test_project/docs/readme.md, "
            "test_project/config/settings.yaml, "
            "test_project/api/reference.txt\n"
        )
        references = parser.parse_content(content, "test.md")
        bare_path_refs = [r for r in references if r.link_type == "markdown-bare-path"]
        assert len(bare_path_refs) == 0, (
            f"bare_path should not duplicate standalone detections, got: "
            f"{[r.link_target for r in bare_path_refs]}"
        )

    def test_standalone_still_detects_prose_paths(self):
        """Standalone pattern should still detect paths in prose (pre-existing behavior)."""
        parser = MarkdownParser()
        content = "- Should find: test_project/docs/readme.md\n"
        references = parser.parse_content(content, "test.md")
        standalone_refs = [r for r in references if r.link_type == "markdown-standalone"]
        targets = [r.link_target for r in standalone_refs]
        assert "test_project/docs/readme.md" in targets

    def test_bare_path_unique_directory_detection_preserved(self):
        """bare_path should still detect directory paths that standalone cannot."""
        parser = MarkdownParser()
        # Directory path (no extension) — only bare_path detects this
        content = "See process-framework/scripts/file-creation for details.\n"
        references = parser.parse_content(content, "test.md")
        bare_path_refs = [r for r in references if r.link_type == "markdown-bare-path"]
        targets = [r.link_target for r in bare_path_refs]
        assert any("process-framework/scripts/file-creation" in t for t in targets)

    def test_bare_path_no_duplicate_with_inline_prose(self):
        """Path in mid-sentence prose should not be duplicated by bare_path."""
        parser = MarkdownParser()
        content = "See test_project/docs/readme.md for details\n"
        references = parser.parse_content(content, "test.md")
        bare_path_refs = [r for r in references if r.link_type == "markdown-bare-path"]
        assert len(bare_path_refs) == 0, (
            f"bare_path should not duplicate standalone detection, got: "
            f"{[r.link_target for r in bare_path_refs]}"
        )
