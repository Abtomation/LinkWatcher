"""
Tests for the Markdown parser.

This module tests markdown-specific link parsing functionality.
"""

from pathlib import Path

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.parsers.markdown import MarkdownParser


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
        """Test parsing standalone file references."""
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

        # Should find standalone references
        assert len(references) >= 3

        # Check specific references
        targets = [ref.link_target for ref in references]
        assert "tests/parsers/file.txt" in targets
        assert "another_file.json" in targets
        assert "path/to/document.md" in targets

        # Check link types
        standalone_refs = [ref for ref in references if ref.link_type == "markdown-standalone"]
        assert len(standalone_refs) >= 3

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
        expected_targets = ["../../manual_markdown_tests/test_project/documentatio/file1.txt, "docs/file2.md", "config/settings.yaml", "shorthand.txt"]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    @pytest.mark.high
    def test_mp_003_inline_code_fake_links(self, temp_project_dir):
        """
        MP-003: Inline code with fake links

        Test Case: `[fake](link.txt)` should be ignored
        Expected: Links inside inline code are not parsed
        Priority: High
        """
        parser = MarkdownParser()

        # Create markdown file with inline code containing fake links
        md_file = temp_project_dir / "test.md"
        content = """# Inline Code Test

Real links:
- [Real link](real.txt)

Fake links in inline code (should be ignored):
- Use `[fake link](fake.txt)` in your code
- The syntax is `[text](url)` for links
- Example: `[config](config.yaml)`

Mixed content:
- Real [link](mixed.txt) and `[fake](ignore.txt)` code
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find real links but not fake ones in code
        targets = [ref.link_target for ref in references]

        # Should find real links
        assert "real.txt" in targets
        assert "mixed.txt" in targets

        # Should NOT find fake links in inline code
        assert "fake.txt" not in targets
        assert "config.yaml" not in targets
        assert "ignore.txt" not in targets

    @pytest.mark.high
    def test_mp_004_code_blocks_fake_links(self, temp_project_dir):
        """
        MP-004: Code blocks with fake links

        Test Case: ```[fake](link.txt)``` should be ignored
        Expected: Links inside code blocks are not parsed
        Priority: High
        """
        parser = MarkdownParser()

        # Create markdown file with code blocks containing fake links
        md_file = temp_project_dir / "test.md"
        content = """# Code Block Test

Real link before code:
[Real link](before.txt)

```markdown
# Fake markdown in code block
[Fake link 1](fake1.txt)
[Fake link 2](fake2.txt)
```

```python
# Python code with fake links
config_file = "[config](config.txt)"
link = "[documentation](docs.md)"
```

```
Plain code block
[Another fake](another.txt)
```

Real link after code:
[Real link](after.txt)
"""
        md_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find real links but not fake ones in code blocks
        targets = [ref.link_target for ref in references]

        # Should find real links
        assert "before.txt" in targets
        assert "after.txt" in targets

        # Should NOT find fake links in code blocks
        assert "fake1.txt" not in targets
        assert "fake2.txt" not in targets
        assert "config.txt" not in targets
        assert "docs.md" not in targets
        assert "another.txt" not in targets

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
            "../../manual_markdown_tests/test_project/documentatio/file1.txt",
            "file2.txt",
            "../../manual_markdown_tests/test_project/documentatio/file1.txt",
            "reference1.txt",
            "reference2.txt",
            "image.png",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

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

    @pytest.mark.low
    def test_mp_009_escaped_characters(self, temp_project_dir):
        """
        MP-009: Escaped characters

        Test Case: [text](file\.txt) with escaped characters
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
