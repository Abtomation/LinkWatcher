"""
Tests for the Generic parser.

This module tests the generic fallback parser that handles files
not covered by specific parsers.
"""

from linkwatcher.parsers.generic import GenericParser
from linkwatcher.utils import looks_like_directory_path, looks_like_file_path


class TestGenericParser:
    """Test cases for GenericParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = GenericParser()

        # Check that regex patterns are compiled
        assert parser.quoted_pattern is not None
        assert parser.unquoted_pattern is not None

    def test_parse_quoted_references(self, temp_project_dir):
        """Test parsing quoted file references in generic text files."""
        parser = GenericParser()

        # Create generic text file with quoted references
        text_file = temp_project_dir / "notes.txt"
        content = """Project Notes

Configuration files:
- Main config: "config.yaml"
- Database config: 'database.json'
- Logging config: "logging.conf"

Data files:
- User data: "../tests/parsers/users.csv"
- Product data: '../tests/parsers/products.json'
- Order data: "../tests/parsers/orders.xml"

Documentation:
- See "docs/readme.md" for setup instructions
- Check 'docs/api.md' for API documentation
- Review "docs/troubleshooting.md" for common issues

Scripts and tools:
- Build script: "../tests/parsers/build.sh"
- Deploy script: '../tests/parsers/deploy.py'
- Test runner: "scripts/run_tests.bat"
"""
        text_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(text_file))

        # Should find quoted references
        assert len(references) >= 10

        # Check specific references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config.yaml",
            "database.json",
            "logging.conf",
            "../tests/parsers/users.csv",
            "../tests/parsers/products.json",
            "../tests/parsers/orders.xml",
            "docs/readme.md",
            "docs/api.md",
            "docs/troubleshooting.md",
            "../tests/parsers/build.sh",
            "../tests/parsers/deploy.py",
            "scripts/run_tests.bat",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

        # Check link types
        for ref in references:
            assert ref.link_type == "generic-quoted"

    def test_parse_log_files(self, temp_project_dir):
        """Test parsing log files with file references."""
        parser = GenericParser()

        # Create log file
        log_file = temp_project_dir / "application.log"
        log_content = """2024-01-15 10:30:00 INFO  Loading configuration from "config/app.yaml"
2024-01-15 10:30:01 INFO  Database connection established using 'database/app.db'
2024-01-15 10:30:02 WARN  Template file "templates/error.html" not found
2024-01-15 10:30:03 INFO  Loading user data from data/users.json
2024-01-15 10:30:04 ERROR Failed to write to "logs/error.log"
2024-01-15 10:30:05 INFO  Backup created at 'backups/2024-01-15.tar.gz'
2024-01-15 10:30:06 DEBUG Processing file: temp/processing.tmp
2024-01-15 10:30:07 INFO  Report generated: "reports/daily_report.pdf"
"""
        log_file.write_text(log_content)

        # Parse the file
        references = parser.parse_file(str(log_file))

        # Should find file references in log entries
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config/app.yaml",
            "database/app.db",
            "templates/error.html",
            "data/users.json",
            "logs/error.log",
            "backups/2024-01-15.tar.gz",
            "temp/processing.tmp",
            "reports/daily_report.pdf",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    def test_line_and_column_positions(self, temp_project_dir):
        """Test that line and column positions are correctly recorded."""
        parser = GenericParser()

        # Create file with known positions
        text_file = temp_project_dir / "positions.txt"
        content = """Line 1: "config.json"
Line 2: data.csv
Line 3: 'logs.txt'"""
        text_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(text_file))

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
                    # Should contain the link target or be part of the reference
                    assert ref.link_target in extracted or ref.link_target in line

    def test_empty_file(self, temp_project_dir):
        """Test parsing an empty file."""
        parser = GenericParser()

        # Create empty file
        empty_file = temp_project_dir / "empty.txt"
        empty_file.write_text("")

        # Parse the file
        references = parser.parse_file(str(empty_file))

        # Should return empty list
        assert references == []

    def test_binary_file_handling(self, temp_project_dir):
        """Test handling of binary files."""
        parser = GenericParser()

        # Create a file with binary content
        binary_file = temp_project_dir / "binary.dat"
        binary_content = b"\x00\x01\x02\x03\xff\xfe\xfd"
        binary_file.write_bytes(binary_content)

        # Parse the file
        references = parser.parse_file(str(binary_file))

        # Should handle gracefully and return empty list
        assert references == []

    def test_error_handling(self):
        """Test error handling for invalid files."""
        parser = GenericParser()

        # Try to parse non-existent file
        references = parser.parse_file("nonexistent.txt")

        # Should return empty list without crashing
        assert references == []


class TestGenericParserDirectoryPaths:
    """PD-BUG-021: Regression tests for directory path detection in GenericParser."""

    def test_bug021_quoted_directory_paths_detected(self):
        """PD-BUG-021: Quoted directory paths without extensions should be captured."""
        parser = GenericParser()

        content = """Script paths:
$templateDir = "doc/process-framework/templates/templates"
$outputDir = 'doc/process-framework/state-tracking/permanent'
Set-Location "../../scripts/file-creation"
"""
        references = parser.parse_content(content, "test.ps1")
        targets = [ref.link_target for ref in references]

        # These directory paths should be detected (currently they are NOT — the bug)
        assert (
            "doc/process-framework/templates/templates" in targets
        ), "Quoted directory path with forward slashes not detected"
        assert (
            "doc/process-framework/state-tracking/permanent" in targets
        ), "Single-quoted directory path not detected"
        assert "../../scripts/file-creation" in targets, "Relative directory path not detected"

    def test_bug021_directory_paths_have_correct_link_type(self):
        """PD-BUG-021: Directory path references should have distinct link_type."""
        parser = GenericParser()

        content = '$dir = "src/utils/helpers"\n'
        references = parser.parse_content(content, "test.ps1")

        dir_refs = [r for r in references if r.link_target == "src/utils/helpers"]
        assert len(dir_refs) == 1, "Should find exactly one directory path reference"
        assert (
            dir_refs[0].link_type == "generic-quoted-dir"
        ), f"Expected link_type 'generic-quoted-dir', got '{dir_refs[0].link_type}'"

    def test_bug021_directory_paths_do_not_duplicate_file_paths(self):
        """PD-BUG-021: Paths with extensions should not be duplicated by dir pattern."""
        parser = GenericParser()

        content = """Mixed references:
$config = "config/settings.yaml"
$dir = "config/settings"
"""
        references = parser.parse_content(content, "test.ps1")
        # File path (with extension) should be captured once by quoted_pattern
        file_refs = [r for r in references if r.link_target == "config/settings.yaml"]
        assert len(file_refs) == 1, "File path should appear exactly once"
        assert file_refs[0].link_type == "generic-quoted"

        # Directory path (no extension) should be captured by dir pattern
        dir_refs = [r for r in references if r.link_target == "config/settings"]
        assert len(dir_refs) == 1, "Directory path should appear exactly once"

    def test_bug021_backslash_directory_paths_detected(self):
        """PD-BUG-021: Windows backslash directory paths should be detected."""
        parser = GenericParser()

        content = r'$path = "doc\process-framework\scripts"' + "\n"
        references = parser.parse_content(content, "test.ps1")
        targets = [ref.link_target for ref in references]

        assert r"doc\process-framework\scripts" in targets, "Backslash directory path not detected"

    def test_bug021_directory_path_false_positive_prevention(self):
        """PD-BUG-021: Non-path quoted strings should not be captured as directories."""
        parser = GenericParser()

        content = """Various quoted strings:
$name = "hello world"
$msg = "error: something failed"
$url = "https://example.com/path"
$ver = "v2.0"
$flag = "true"
"""
        references = parser.parse_content(content, "test.ps1")
        targets = [ref.link_target for ref in references]

        # None of these should be detected as directory paths
        assert "hello world" not in targets
        assert "error: something failed" not in targets
        assert "https://example.com/path" not in targets
        assert "v2.0" not in targets
        assert "true" not in targets

    def test_bug021_line_number_and_column_correct(self):
        """PD-BUG-021: Directory path references should have correct positions."""
        parser = GenericParser()

        content = 'first line\n$dir = "src/components"\nthird line\n'
        references = parser.parse_content(content, "test.ps1")

        dir_refs = [r for r in references if r.link_target == "src/components"]
        assert len(dir_refs) == 1
        ref = dir_refs[0]
        assert ref.line_number == 2, f"Expected line 2, got {ref.line_number}"
        # Verify the column positions point to the actual path text
        line = content.split("\n")[1]
        extracted = line[ref.column_start : ref.column_end]
        assert "src/components" in extracted


class TestLooksLikeDirectoryPath:
    """PD-BUG-021: Tests for the looks_like_directory_path utility function."""

    def test_valid_directory_paths(self):
        """Valid directory paths should return True."""
        valid_paths = [
            "doc/process-framework",
            "src/utils/helpers",
            "../../scripts/file-creation",
            "../templates",
            "doc/process-framework/templates/templates",
            r"doc\process-framework\scripts",
            "tests/unit/",
        ]
        for path in valid_paths:
            assert looks_like_directory_path(path) is True, f"Expected True for '{path}'"

    def test_invalid_directory_paths(self):
        """Non-path strings should return False."""
        invalid_paths = [
            "",  # empty
            "a",  # too short
            "hello world",  # no separator
            "simple_word",  # no separator
            "https://example.com/path",  # URL
            "ftp://server/dir",  # URL
            "user@host/dir",  # contains @
            "path?query/val",  # contains ?
            "key=val/dir",  # contains =
            "100%/done",  # contains %
        ]
        for path in invalid_paths:
            assert looks_like_directory_path(path) is False, f"Expected False for '{path}'"


class TestBug028ProseFilenameRejection:
    """PD-BUG-028: looks_like_file_path should reject prose strings with embedded filenames."""

    def test_prose_with_embedded_filename_rejected(self):
        """Strings like 'Hello from move-target-2.ps1' are prose, not paths."""
        assert looks_like_file_path("Hello from move-target-2.ps1") is False

    def test_prose_with_relative_prefix_rejected(self):
        """Relative prefix doesn't make prose into a valid path."""
        assert looks_like_file_path("../Hello from move-target-2.ps1") is False

    def test_prose_with_uppercase_start_rejected(self):
        """Sentences starting with uppercase and 3+ words are prose, not paths."""
        assert looks_like_file_path("Output from script.ps1") is False
        assert looks_like_file_path("Generated by tool.py") is False
        assert looks_like_file_path("See the config.yaml") is False

    def test_real_filenames_with_spaces_accepted(self):
        """Filenames with 1-2 words (including spaces) should still be accepted."""
        assert looks_like_file_path("my file.txt") is True
        assert looks_like_file_path("test data.csv") is True

    def test_real_paths_with_spaces_in_dirs_accepted(self):
        """Paths with space-containing directory names (1-2 words) should be accepted."""
        assert looks_like_file_path("my docs/file.txt") is True
        assert looks_like_file_path("Program Files/app.exe") is True

    def test_normal_paths_still_accepted(self):
        """Standard paths without spaces should continue to work."""
        assert looks_like_file_path("config.yaml") is True
        assert looks_like_file_path("../config.yaml") is True
        assert looks_like_file_path("path/to/file.md") is True
        assert looks_like_file_path("move-target-2.ps1") is True
