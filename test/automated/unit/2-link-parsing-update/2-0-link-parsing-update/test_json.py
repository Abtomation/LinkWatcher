"""
Tests for the JSON parser.

This module tests JSON-specific link parsing functionality.
Implements JP test cases from comprehensive test documentation.
"""

import pytest

from linkwatcher.link_types import LinkType
from linkwatcher.parsers.json_parser import JsonParser

pytestmark = [
    pytest.mark.feature("2.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("parser"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md"
    ),
]


class TestJsonParser:
    """Test cases for JsonParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = JsonParser()

        # Check that parser is properly initialized
        assert parser is not None

    def test_jp_001_string_values_with_file_paths(self, temp_project_dir):
        """
        JP-001: String values with file paths

        Test Case: {"file": "path.txt"}
        Expected: File path parsed
        Priority: High
        """
        parser = JsonParser()

        # Create JSON file with file path string values
        json_file = temp_project_dir / "config.json"
        json_content = """{
  "application": {
    "name": "Test App",
    "config_file": "config/settings.conf",
    "data_file": "data/input.csv",
    "template": "templates/main.html"
  },
  "paths": {
    "log_file": "logs/app.log",
    "backup_dir": "backup/",
    "schema": "schemas/user.json"
  },
  "version": "1.0.0"
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find file references
        assert len(references) >= 5

        # Check specific references
        targets = [ref.link_target for ref in references]
        assert "config/settings.conf" in targets
        assert "data/input.csv" in targets
        assert "templates/main.html" in targets
        assert "logs/app.log" in targets
        assert "schemas/user.json" in targets

        # Check reference types
        for ref in references:
            assert ref.link_type in ("json", "json-dir")
            assert ref.file_path == str(json_file)

    def test_jp_002_nested_objects(self, temp_project_dir):
        """
        JP-002: Nested objects

        Test Case: Complex JSON with file refs
        Expected: All file paths found
        Priority: High
        """
        parser = JsonParser()

        # Create JSON with deeply nested structures
        json_file = temp_project_dir / "complex.json"
        json_content = """{
  "database": {
    "connections": {
      "primary": {
        "config": "db/primary.conf",
        "schema": "db/schema.sql"
      },
      "secondary": {
        "config": "db/secondary.conf",
        "backup": "db/backup.sql"
      }
    }
  },
  "services": {
    "web": {
      "static_files": "web/static/",
      "templates": "web/templates/",
      "config": {
        "main": "web/config/main.json",
        "logging": "web/config/logging.json"
      }
    },
    "api": {
      "docs": "api/swagger.json",
      "tests": "api/tests/"
    }
  },
  "monitoring": {
    "metrics": "monitoring/metrics.json",
    "alerts": {
      "config": "monitoring/alerts.json",
      "templates": {
        "email": "templates/alert_email.html",
        "slack": "templates/alert_slack.json"
      }
    }
  }
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find many nested references
        assert len(references) >= 10

        # Check nested references
        targets = [ref.link_target for ref in references]
        assert "db/primary.conf" in targets
        assert "db/schema.sql" in targets
        assert "web/config/main.json" in targets
        assert "api/swagger.json" in targets
        assert "monitoring/metrics.json" in targets
        assert "templates/alert_email.html" in targets

    def test_jp_003_arrays_of_file_paths(self, temp_project_dir):
        """
        JP-003: Arrays of file paths

        Test Case: {"files": ["a.txt", "b.txt"]}
        Expected: All array items parsed
        Priority: High
        """
        parser = JsonParser()

        # Create JSON with arrays of file references
        json_file = temp_project_dir / "arrays.json"
        json_content = """{
  "input_files": [
    "data/file1.csv",
    "data/file2.csv",
    "data/file3.csv"
  ],
  "templates": [
    "templates/header.html",
    "templates/footer.html",
    "templates/content.html"
  ],
  "configs": [
    "config/dev.json",
    "config/prod.json",
    "config/test.json"
  ],
  "mixed_array": [
    {
      "name": "First",
      "file": "assets/first.json"
    },
    {
      "name": "Second",
      "file": "assets/second.json"
    }
  ],
  "scripts": ["scripts/build.sh", "scripts/deploy.sh", "scripts/test.sh"],
  "metadata": {
    "version": "1.0",
    "files": [
      "meta/version.txt",
      "meta/changelog.md"
    ]
  }
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find all array items
        assert len(references) >= 14

        # Check array items
        targets = [ref.link_target for ref in references]

        # Input files array
        assert "data/file1.csv" in targets
        assert "data/file2.csv" in targets
        assert "data/file3.csv" in targets

        # Templates array
        assert "templates/header.html" in targets
        assert "templates/footer.html" in targets

        # Mixed array (nested objects)
        assert "assets/first.json" in targets
        assert "assets/second.json" in targets

        # Scripts array
        assert "scripts/build.sh" in targets
        assert "scripts/deploy.sh" in targets
        assert "scripts/test.sh" in targets

        # Nested arrays
        assert "meta/version.txt" in targets
        assert "meta/changelog.md" in targets

    def test_jp_004_escaped_strings(self, temp_project_dir):
        """
        JP-004: Escaped strings

        Test Case: {"file": "path/with/backslashes.txt"}
        Expected: Escaped paths handled
        Priority: Medium
        """
        parser = JsonParser()

        # Create JSON with escaped strings
        json_file = temp_project_dir / "escaped.json"
        json_content = """{
  "windows_paths": {
    "config": "C:\\\\Program Files\\\\App\\\\config.ini",
    "data": "C:\\\\Users\\\\Data\\\\file.txt",
    "logs": "C:\\\\Logs\\\\app.log"
  },
  "escaped_chars": {
    "quotes": "file with \\"quotes\\".txt",
    "newlines": "path/nwith/nnewlines.txt",
    "tabs": "path/twith/ttabs.txt"
  },
  "mixed": {
    "normal": "normal/path.txt",
    "escaped": "escaped/path/file.txt",
    "unicode": "unicode/u0020file.txt"
  },
  "special": {
    "json_file": "data\\\\config.json",
    "backup": "backup/data/file.bak"
  }
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find file references with proper unescaping
        targets = [ref.link_target for ref in references]

        # Check that escaped paths are handled
        # Note: The exact handling depends on the parser implementation
        # Some parsers might normalize paths, others might preserve escaping
        assert len(targets) >= 8

        # Should find some recognizable file references
        found_files = [
            t for t in targets if any(ext in t for ext in [".txt", ".ini", ".log", ".json", ".bak"])
        ]
        assert len(found_files) >= 6


class TestJsonParserEdgeCases:
    """Edge cases for JSON parser."""

    def test_invalid_json_handling(self, temp_project_dir):
        """Test handling of invalid JSON."""
        parser = JsonParser()

        # Create invalid JSON file
        json_file = temp_project_dir / "valid.json"
        json_content = """{
  "invalid": json,
  "missing": "quotes,
  "extra": "comma",
  "unclosed": {
    "bracket": "here"
  // missing closing brace
"""
        json_file.write_text(json_content)

        # Should not crash on invalid JSON
        references = parser.parse_file(str(json_file))

        # Should return empty list for invalid JSON
        assert isinstance(references, list)

    def test_empty_json_file(self, temp_project_dir):
        """Test handling of empty JSON file."""
        parser = JsonParser()

        # Create empty JSON file
        json_file = temp_project_dir / "empty.json"
        json_file.write_text("")

        # Should handle empty file gracefully
        references = parser.parse_file(str(json_file))
        assert references == []

    def test_json_with_null_values(self, temp_project_dir):
        """Test handling of JSON with null values."""
        parser = JsonParser()

        # Create JSON with null values
        json_file = temp_project_dir / "nulls.json"
        json_content = """{
  "config": {
    "file": "config.json",
    "backup": null,
    "data": "data.json",
    "cache": null
  },
  "files": [
    "file1.txt",
    null,
    "file2.txt",
    null
  ],
  "empty": null,
  "valid": "valid.json"
}"""
        json_file.write_text(json_content)

        # Should handle null values without issues
        references = parser.parse_file(str(json_file))

        # Should find the non-null file references
        targets = [ref.link_target for ref in references]
        assert "config.json" in targets
        assert "data.json" in targets
        assert "file1.txt" in targets
        assert "file2.txt" in targets
        assert "valid.json" in targets

    def test_json_with_numbers_and_booleans(self, temp_project_dir):
        """Test JSON with various data types."""
        parser = JsonParser()

        # Create JSON with mixed data types
        json_file = temp_project_dir / "mixed.json"
        json_content = """{
  "config": {
    "file": "config.json",
    "version": 1.2,
    "enabled": true,
    "debug": false,
    "timeout": 30
  },
  "files": [
    "file1.txt",
    123,
    "file2.txt",
    true,
    "file1.txt"
  ],
  "metadata": {
    "count": 42,
    "active": true,
    "log_file": "logs/app.log",
    "max_size": 1048576
  }
}"""
        json_file.write_text(json_content)

        # Should only find string values that look like file paths
        references = parser.parse_file(str(json_file))

        targets = [ref.link_target for ref in references]
        assert "config.json" in targets
        assert "file1.txt" in targets
        assert "file2.txt" in targets
        assert "file1.txt" in targets
        assert "logs/app.log" in targets

        # Should not find numbers or booleans
        assert 123 not in targets
        assert True not in targets
        assert 1.2 not in targets

    def test_deeply_nested_json(self, temp_project_dir):
        """Test very deeply nested JSON structures."""
        parser = JsonParser()

        # Create deeply nested JSON
        json_file = temp_project_dir / "deep.json"
        json_content = """{
  "level1": {
    "level2": {
      "level3": {
        "level4": {
          "level5": {
            "level6": {
              "level7": {
                "level8": {
                  "level9": {
                    "level10": {
                      "deep_file": "very/deep/nested/file.txt",
                      "another": "deep/file.json"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}"""
        json_file.write_text(json_content)

        # Should handle deep nesting
        references = parser.parse_file(str(json_file))

        targets = [ref.link_target for ref in references]
        assert "very/deep/nested/file.txt" in targets
        assert "deep/file.json" in targets

    def test_large_json_arrays(self, temp_project_dir):
        """Test JSON with large arrays."""
        parser = JsonParser()

        # Create JSON with large array
        json_file = temp_project_dir / "large.json"

        # Generate large array of file references
        import json as json_module

        files = [f"data/file_{i:03d}.txt" for i in range(100)]
        json_content = json_module.dumps({"files": files})

        json_file.write_text(json_content)

        # Should handle large arrays efficiently
        references = parser.parse_file(str(json_file))

        # Should find all file references
        assert len(references) == 100

        targets = [ref.link_target for ref in references]
        assert "data/file_000.txt" in targets
        assert "data/file_050.txt" in targets
        assert "data/file_099.txt" in targets


class TestJsonParserDuplicateLineNumbers:
    """Regression tests for PD-BUG-013: duplicate-value line number resolution."""

    def test_bug013_duplicate_values_get_correct_line_numbers(self, temp_project_dir):
        """
        PD-BUG-013: When the same file path appears multiple times in JSON,
        each reference should get its own correct line number.
        """
        parser = JsonParser()

        json_file = temp_project_dir / "duplicates.json"
        json_content = """{
  "primary": "data.csv",
  "files": [
    "data.csv"
  ],
  "backup": {
    "source": "data.csv"
  }
}"""
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        # Should find 3 references to data.csv
        data_refs = [r for r in references if r.link_target == "data.csv"]
        assert len(data_refs) == 3

        # Each must have a DIFFERENT line number (the correct one)
        line_numbers = [r.line_number for r in data_refs]
        assert len(set(line_numbers)) == 3, f"Expected 3 unique line numbers, got {line_numbers}"

        # Verify the actual line numbers are correct
        # Line 2: "primary": "data.csv"
        # Line 4: "data.csv"  (inside array)
        # Line 7: "source": "data.csv"
        assert sorted(line_numbers) == [2, 4, 7]

    def test_bug013_mixed_duplicate_and_unique_values(self, temp_project_dir):
        """
        PD-BUG-013: Mix of duplicate and unique paths should all resolve correctly.
        """
        parser = JsonParser()

        json_file = temp_project_dir / "mixed_dupes.json"
        json_content = """{
  "input": "shared.txt",
  "output": "unique.log",
  "backup": "shared.txt",
  "archive": "unique.log",
  "final": "shared.txt"
}"""
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        shared_refs = [r for r in references if r.link_target == "shared.txt"]
        unique_refs = [r for r in references if r.link_target == "unique.log"]

        assert len(shared_refs) == 3
        assert len(unique_refs) == 2

        shared_lines = sorted([r.line_number for r in shared_refs])
        unique_lines = sorted([r.line_number for r in unique_refs])

        assert shared_lines == [2, 4, 6], f"shared.txt lines: {shared_lines}"
        assert unique_lines == [3, 5], f"unique.log lines: {unique_lines}"

    def test_bug013_adjacent_duplicate_values(self, temp_project_dir):
        """
        PD-BUG-013 edge case: same path on consecutive lines in an array.
        """
        parser = JsonParser()

        json_file = temp_project_dir / "adjacent.json"
        json_content = """{
  "files": [
    "report.md",
    "report.md",
    "report.md"
  ]
}"""
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        report_refs = [r for r in references if r.link_target == "report.md"]
        assert len(report_refs) == 3

        line_numbers = [r.line_number for r in report_refs]
        assert (
            len(set(line_numbers)) == 3
        ), f"Expected 3 unique line numbers for adjacent duplicates, got {line_numbers}"
        assert sorted(line_numbers) == [3, 4, 5]


class TestJsonParserDirectoryPaths:
    """Regression tests for PD-BUG-030: directory paths not detected in JSON values."""

    def test_bug030_directory_paths_detected_in_json(self, temp_project_dir):
        """
        PD-BUG-030: JSON values containing directory paths (no file extension)
        should be detected as references when they contain path separators.
        """
        parser = JsonParser()

        dir_a = "lib/docs/reference"
        dir_b = "vendor/tools/scripts"
        dir_c = "vendor/tools/templates"

        json_file = temp_project_dir / "registry.json"
        json_content = (
            "{\n"
            '  "directories": {\n'
            f'    "docs": "{dir_a}",\n'
            f'    "scripts": "{dir_b}",\n'
            f'    "templates": "{dir_c}"\n'
            "  }\n"
            "}"
        )
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        targets = [ref.link_target for ref in references]
        assert dir_a in targets
        assert dir_b in targets
        assert dir_c in targets

    def test_bug030_directory_paths_coexist_with_file_paths(self, temp_project_dir):
        """
        PD-BUG-030: Directory paths and file paths should both be detected
        without interfering with each other.
        """
        parser = JsonParser()

        json_file = temp_project_dir / "mixed.json"
        json_content = """{
  "config": {
    "output_dir": "build/output",
    "config_file": "config/settings.json",
    "source_dir": "src/components",
    "readme": "docs/README.md"
  }
}"""
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        targets = [ref.link_target for ref in references]
        # File paths (have extensions)
        assert "config/settings.json" in targets
        assert "docs/README.md" in targets
        # Directory paths (no extensions)
        assert "build/output" in targets
        assert "src/components" in targets

    def test_bug030_non_path_strings_not_detected(self, temp_project_dir):
        """
        PD-BUG-030: Non-path strings should NOT be falsely detected as
        directory paths just because they exist in JSON.
        """
        parser = JsonParser()

        json_file = temp_project_dir / "nonpaths.json"
        json_content = """{
  "name": "My Application",
  "version": "2.0",
  "description": "A test application for unit testing",
  "author": "Test User",
  "real_path": "src/utils/helpers"
}"""
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        targets = [ref.link_target for ref in references]
        # Only the real path should be detected
        assert "src/utils/helpers" in targets
        # Non-path strings should not be detected
        assert "My Application" not in targets
        assert "2.0" not in targets
        assert "A test application for unit testing" not in targets
        assert "Test User" not in targets


class TestJsonParserCompoundStrings:
    """PD-BUG-061: JSON parser cannot detect file paths embedded in compound command strings.

    Root cause: looks_like_directory_path() is called on the entire string value.
    The suspicious character check rejects strings containing *, (, ), etc.
    No sub-path extraction exists. Fix must avoid false positives from wildcard patterns.
    """

    def test_compound_string_with_embedded_file_path(self):
        """JSON array value with embedded file path should extract the path,
        not the whole string."""
        parser = JsonParser()
        json_content = (
            "{\n"
            '  "permissions": {\n'
            '    "allow": [\n'
            '      "Bash(python alpha-project/scripts/feedback_db.py *)"\n'
            "    ]\n"
            "  }\n"
            "}"
        )
        references = parser.parse_content(json_content, "settings.json")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/scripts/feedback_db.py" in targets
        # Must NOT store the whole compound string as a target
        assert not any("Bash(" in t for t in targets)

    def test_compound_string_multiple_patterns(self):
        """Multiple compound strings should each have their embedded paths extracted."""
        parser = JsonParser()
        json_content = (
            "{\n"
            '  "allow": [\n'
            '    "Bash(pwsh.exe -ExecutionPolicy Bypass -File scripts/deploy.ps1)",\n'
            '    "Bash(python tools/check.py *)",\n'
            '    "config/settings.json"\n'
            "  ]\n"
            "}"
        )
        references = parser.parse_content(json_content, "settings.json")
        targets = [ref.link_target for ref in references]
        assert "scripts/deploy.ps1" in targets
        assert "tools/check.py" in targets
        # Plain path should still work
        assert "config/settings.json" in targets

    def test_compound_string_no_false_positive_from_glob(self):
        """A compound string with no real embedded path should not produce false positives."""
        parser = JsonParser()
        json_content = (
            "{\n"
            '  "patterns": [\n'
            '    "some random text with spaces",\n'
            '    "version 1.0.0 release notes"\n'
            "  ]\n"
            "}"
        )
        references = parser.parse_content(json_content, "settings.json")
        targets = [ref.link_target for ref in references]
        assert len(targets) == 0


BS = chr(92)
Q = chr(39)


class TestBug126EscapedLiteralLineLocation:
    r"""PD-BUG-126 regression: a JSON string value carrying ANY escape sequence
    was dropped, so its target was silently left stale when the file moved.

    Classification was never the problem -- ``_classify_path`` accepts the
    decoded value.  The reference died one step later, at line location:
    ``_find_unclaimed_line`` searched the RAW source line for the DECODED
    value, and every escape makes those two differ, so the search returned 0
    and the reference was discarded without a log line.

    JSON has no escape-free string form, so this reaches every path that must
    be escaped -- notably a Windows-style path, whose only valid JSON spelling
    is with doubled backslashes.
    """

    def _parse(self, tmp_dir, raw_value):
        json_file = tmp_dir / "config.json"
        json_file.write_text('{\n  "p": ' + raw_value + "\n}\n", encoding="utf-8")
        return JsonParser().parse_file(str(json_file))

    def test_escaped_forward_slash_is_detected(self, temp_project_dir):
        r"""``"logs\/sub\/x.txt"`` is valid JSON decoding to a plain POSIX path."""
        refs = self._parse(temp_project_dir, '"logs' + BS + "/sub" + BS + '/x.txt"')

        assert len(refs) == 1, "escaped forward slash dropped at line location"
        assert refs[0].link_target == "logs/sub/x.txt"
        assert refs[0].line_number == 2

    def test_unicode_escape_is_detected(self, temp_project_dir):
        r"""``"logs/sub/\u0078.txt"`` decodes to ``logs/sub/x.txt``."""
        refs = self._parse(temp_project_dir, '"logs/sub/' + BS + 'u0078.txt"')

        assert len(refs) == 1, "unicode escape dropped at line location"
        assert refs[0].link_target == "logs/sub/x.txt"

    def test_escaped_backslash_path_is_detected(self, temp_project_dir):
        r"""The reported case: ``"logs\sub\x.txt"`` decodes to ``logs\sub\x.txt``."""
        refs = self._parse(temp_project_dir, '"logs' + BS * 2 + "sub" + BS * 2 + 'x.txt"')

        assert len(refs) == 1, "backslash-authored path dropped at line location"
        assert refs[0].link_target == "logs" + BS + "sub" + BS + "x.txt"

    def test_span_covers_the_raw_literal_not_the_decoded_value(self, temp_project_dir):
        r"""The recorded span must address the RAW source text.

        The updater splices replacements in by column, so a span sized to the
        (shorter) decoded value would leave escape debris behind in the file.
        """
        raw_inner = "logs" + BS + "/sub" + BS + "/x.txt"
        json_file = temp_project_dir / "config.json"
        content = '{\n  "p": "' + raw_inner + '"\n}\n'
        json_file.write_text(content, encoding="utf-8")

        refs = JsonParser().parse_file(str(json_file))

        assert len(refs) == 1
        ref = refs[0]
        line = content.split("\n")[ref.line_number - 1]
        assert (
            line[ref.column_start : ref.column_end] == raw_inner
        ), "span must cover the raw escaped literal, got " "{!r}".format(
            line[ref.column_start : ref.column_end]
        )

    def test_plain_value_still_detected(self, temp_project_dir):
        """Control: an escape-free value must keep working exactly as before."""
        refs = self._parse(temp_project_dir, '"logs/sub/x.txt"')

        assert len(refs) == 1
        assert refs[0].link_target == "logs/sub/x.txt"

    def test_escaped_and_plain_values_both_detected(self, temp_project_dir):
        """Both spellings on adjacent lines are found, each on its own line."""
        json_file = temp_project_dir / "config.json"
        json_file.write_text(
            '{\n  "back": "logs'
            + BS * 2
            + "sub"
            + BS * 2
            + 'x.txt",\n  "fwd": "logs/sub/x.txt"\n}\n',
            encoding="utf-8",
        )

        refs = JsonParser().parse_file(str(json_file))
        by_line = {r.line_number: r.link_target for r in refs}

        assert by_line.get(2) == "logs" + BS + "sub" + BS + "x.txt"
        assert by_line.get(3) == "logs/sub/x.txt"


class TestBug130EscapedCompoundStringPaths:
    r"""PD-BUG-130 regression: a path embedded in a COMPOUND (space-bearing)
    JSON value was lost whenever the source literal carried any escape.

    ``_extract_embedded_paths`` located the value by searching the raw line for
    the DECODED whole string -- which never matches once anything is escaped --
    and offset each candidate span within the DECODED text rather than the raw
    text.  Two silent outcomes followed, decided only by where the path sat:

    * path in the MIDDLE -> whole-string classification also failed, and the
      reference was discarded with no reference and no warning;
    * path at the END -> the compound string itself passed
      ``looks_like_file_path`` and was registered with the ENTIRE command line
      as its ``link_target`` (a mode the PD-BUG-126 fall-through introduced;
      at HEAD both shapes were simply dropped).

    Sibling of PD-BUG-126, which fixed the whole-string branch only.
    """

    def _parse(self, tmp_dir, raw_value, name="config.json"):
        json_file = tmp_dir / name
        json_file.write_text('{\n  "k": ' + raw_value + "\n}\n", encoding="utf-8")
        return JsonParser().parse_file(str(json_file))

    def _raw_line(self, tmp_dir, name="config.json"):
        return (tmp_dir / name).read_text(encoding="utf-8").split("\n")[1]

    def test_escaped_path_in_middle_is_detected(self, temp_project_dir):
        r"""The reported case: ``"Bash(python logs\\sub\\run.py *)"``."""
        refs = self._parse(
            temp_project_dir,
            '"Bash(python logs' + BS * 2 + "sub" + BS * 2 + 'run.py *)"',
        )

        targets = [r.link_target for r in refs]
        assert targets == [
            "logs" + BS + "sub" + BS + "run.py"
        ], "escaped candidate inside a compound string was dropped, got {!r}".format(targets)

    def test_escaped_path_at_end_is_not_registered_as_whole_string(self, temp_project_dir):
        r"""``"pwsh -File logs\\sub\\run.ps1"`` must yield the PATH, not the command.

        Negative assertion is the load-bearing one: pre-fix this produced a
        reference whose target was the entire command line, which is not a
        path, can never resolve, and pollutes the link database.
        """
        refs = self._parse(
            temp_project_dir,
            '"pwsh -File logs' + BS * 2 + "sub" + BS * 2 + 'run.ps1"',
        )

        targets = [r.link_target for r in refs]
        whole = "pwsh -File logs" + BS + "sub" + BS + "run.ps1"

        assert whole not in targets, "whole command string registered as a link target"
        assert targets == ["logs" + BS + "sub" + BS + "run.ps1"]

    def test_span_covers_the_raw_candidate_not_the_decoded_one(self, temp_project_dir):
        r"""The recorded span must address RAW source text.

        The updater splices by column, so a decoded-relative span would land on
        the wrong characters inside an escaped literal -- the PD-BUG-124
        corruption class.
        """
        refs = self._parse(
            temp_project_dir,
            '"Bash(python logs' + BS * 2 + "sub" + BS * 2 + 'run.py *)"',
        )

        assert len(refs) == 1
        ref = refs[0]
        line = self._raw_line(temp_project_dir)
        assert line[ref.column_start : ref.column_end] == (
            "logs" + BS * 2 + "sub" + BS * 2 + "run.py"
        ), "span must cover the raw escaped candidate, got {!r}".format(
            line[ref.column_start : ref.column_end]
        )

    def test_clean_candidate_inside_escaped_literal_is_detected(self, temp_project_dir):
        r"""The real repo case: the CANDIDATE has no escapes, the literal does.

        ``.claude/settings.json`` carries a hook command holding embedded JSON,
        so the literal is full of ``\"`` while the path inside it is ordinary.
        The whole-value search still fails, so the path was dropped.
        """
        raw = (
            '"echo {' + BS + '"doc' + BS + '":' + BS + '"process-framework/ai-tasks.md' + BS + '"}"'
        )
        refs = self._parse(temp_project_dir, raw)

        targets = [r.link_target for r in refs]
        assert targets == [
            "process-framework/ai-tasks.md"
        ], "clean candidate inside an escaped literal was dropped, got {!r}".format(targets)

        ref = refs[0]
        line = self._raw_line(temp_project_dir)
        assert line[ref.column_start : ref.column_end] == "process-framework/ai-tasks.md"

    def test_unicode_escape_inside_compound_string(self, temp_project_dir):
        r"""``x`` spelling maps back to its own raw span, not a re-escaped guess."""
        refs = self._parse(
            temp_project_dir,
            '"Bash(python logs/sub/' + BS + 'u0078.py *)"',
        )

        assert [r.link_target for r in refs] == ["logs/sub/x.py"]
        ref = refs[0]
        line = self._raw_line(temp_project_dir)
        assert line[ref.column_start : ref.column_end] == "logs/sub/" + BS + "u0078.py"

    def test_two_escaped_candidates_in_one_value(self, temp_project_dir):
        """Each candidate gets its own raw span, in order."""
        refs = self._parse(
            temp_project_dir,
            '"copy logs' + BS * 2 + "a.txt logs" + BS * 2 + 'b.txt"',
        )

        assert [r.link_target for r in refs] == [
            "logs" + BS + "a.txt",
            "logs" + BS + "b.txt",
        ]
        line = self._raw_line(temp_project_dir)
        assert line[refs[0].column_start : refs[0].column_end] == "logs" + BS * 2 + "a.txt"
        assert line[refs[1].column_start : refs[1].column_end] == "logs" + BS * 2 + "b.txt"

    def test_plain_compound_string_still_detected(self, temp_project_dir):
        """Control: the escape-free compound string is unaffected (PD-BUG-061)."""
        refs = self._parse(temp_project_dir, '"Bash(python logs/sub/run.py *)"')

        assert [r.link_target for r in refs] == ["logs/sub/run.py"]

    def test_compound_string_without_paths_still_ignored(self, temp_project_dir):
        """Control: an escaped compound string holding no path yields nothing."""
        refs = self._parse(temp_project_dir, '"echo ' + BS + '"hello world' + BS + '""')

        assert refs == []

    def test_unlocatable_compound_value_is_logged_and_not_fallen_through(
        self, temp_project_dir, monkeypatch
    ):
        """Observability contract (the OB half of this bug, and of TD283).

        When the raw literal genuinely cannot be located, the value must be
        reported through ``path_value_line_not_located`` -- and must NOT fall
        through to whole-string classification, which is what manufactured the
        bogus whole-command reference.
        """
        events = []

        parser = JsonParser()
        monkeypatch.setattr(
            parser, "_find_decoded_literal", lambda *a, **k: (0, 0, 0, ""), raising=False
        )

        class _Recorder:
            def warning(self, event, **kw):
                events.append(event)

            def __getattr__(self, name):
                return lambda *a, **k: None

        parser.logger = _Recorder()

        # Path in the MIDDLE deliberately: with the path at the END the
        # whole-string branch ALSO reaches _add_escaped_reference and logs,
        # so the warning assertion would pass without the compound branch
        # logging at all.  The middle shape is silent in both branches
        # pre-fix, which is what makes this test discriminate.
        content = '{\n  "k": "Bash(python logs' + BS * 2 + "sub" + BS * 2 + 'run.py *)"\n}\n'
        refs = parser.parse_content(content, "config.json")

        assert refs == [], "unlocatable value must not produce a whole-string reference"
        assert "path_value_line_not_located" in events, "silent drop: nothing was logged"


class TestBug131CompoundStringDirectoryPaths:
    """PD-BUG-131 regression: a DIRECTORY path embedded in a compound
    (space-bearing) JSON value was never extracted, and the whole command
    string was registered as the reference target in its place.

    Root cause: ``_extract_embedded_paths`` reached only for ``_path_pattern``,
    which requires a file extension.  The two structured parsers never adopted
    the shared ``QUOTED_DIR_PATTERN`` the other five parsers use for
    extensionless directories, so a compound value holding one yielded no
    candidates, returned False, and fell through to whole-string
    classification.

    The delimiter requirement is deliberate and matches every other parser:
    an UNQUOTED extensionless token is not a directory reference anywhere in
    this product (markdown, generic, python, powershell all require quotes).
    """

    def test_quoted_directory_inside_compound_string_is_extracted(self):
        """The real-population shape: a quoted directory inside a command."""
        parser = JsonParser()
        content = (
            "{\n"
            '  "permissions": {\n'
            '    "allow": [\n'
            '      "Bash([ -d ' + BS + '"doc/technical/design' + BS + '" ])"\n'
            "    ]\n"
            "  }\n"
            "}\n"
        )
        references = parser.parse_content(content, "settings.json")
        targets = [r.link_target for r in references]

        assert "doc/technical/design" in targets
        # Strong negative: the whole command must NOT survive as a target
        assert not any("Bash(" in t for t in targets)

    def test_extracted_directory_carries_the_dir_link_type(self):
        """A directory candidate must be typed JSON_DIR, not JSON."""
        parser = JsonParser()
        content = "{\n" '  "cmd": "Bash([ -d ' + BS + '"doc/technical/design' + BS + '" ])"\n' "}\n"
        references = parser.parse_content(content, "settings.json")
        dir_refs = [r for r in references if r.link_target == "doc/technical/design"]

        assert dir_refs, "directory candidate was not extracted"
        assert dir_refs[0].link_type == LinkType.JSON_DIR

    def test_unquoted_compound_directory_does_not_register_whole_command(self):
        """Symptom (b): the bracketed command must not become a link target.

        The unquoted ``doc/design`` is deliberately NOT extracted (no delimiter,
        per product convention), but the whole command must not be registered
        as a directory reference either -- it can never resolve.
        """
        parser = JsonParser()
        content = '{\n  "cmd": "Bash([ -d doc/design ])"\n}\n'
        references = parser.parse_content(content, "settings.json")
        targets = [r.link_target for r in references]

        assert not any("Bash(" in t for t in targets)

    def test_directory_value_with_spaces_still_classified_whole_string(self):
        """Discriminating control for symptom (b): a genuine path containing a
        space is still a directory reference -- the containment must reject
        command syntax, not spaces."""
        parser = JsonParser()
        content = '{\n  "target": "doc/my design"\n}\n'
        references = parser.parse_content(content, "settings.json")

        assert [r.link_target for r in references] == ["doc/my design"]
        assert references[0].link_type == LinkType.JSON_DIR

    def test_path_with_space_and_parenthesis_is_still_classified(self):
        """Boundary control for the command-shape guard (code review, Finding 1).

        The first cut keyed on "a space plus any of ``()[]``", which reads the
        same way to a filename and silently dropped these.  A Windows ``(1)``
        copy suffix is ordinary on this product's declared platform, so the
        drop was the same silent-staleness class PD-BUG-130 removes.

        Both existing discriminating controls used space-ONLY values, which is
        exactly why the defect passed the suite.
        """
        parser = JsonParser()
        for value, expected_type in [
            ("assets/img (1).png", LinkType.JSON),
            ("doc/report (final).pdf", LinkType.JSON),
            ("doc/notes (draft)", LinkType.JSON_DIR),
        ]:
            content = '{\n  "target": "' + value + '"\n}\n'
            references = parser.parse_content(content, "settings.json")

            assert [r.link_target for r in references] == [
                value
            ], "space + parenthesis must not read as a command: {!r}".format(value)
            assert references[0].link_type == expected_type

    def test_bracketed_filename_tag_does_not_read_as_a_command(self):
        """A bracketed filename tag carries no space INSIDE the brackets, which
        is what separates it from a ``[ -d path ]`` test operator.

        Asserted against the guard directly, not against the parser output: a
        bracketed value is independently rejected by ``looks_like_regex_or_glob``
        (PD-BUG-095, ``[draft]`` reads as a character class), so a parser-level
        assertion here would pin unrelated pre-existing behaviour and would
        break if that glob rule ever changed.
        """
        assert JsonParser()._is_command_shaped("doc/report [draft] final.md") is False
        # ...while the test-operator form it must catch still reads as a command
        assert JsonParser()._is_command_shaped("[ -d doc/design ]") is True

    def test_bare_test_operator_command_is_still_contained(self):
        """The guard must keep catching the shape it exists for, including the
        form with no call head."""
        parser = JsonParser()
        content = '{\n  "cmd": "[ -d doc/design ]"\n}\n'
        references = parser.parse_content(content, "settings.json")

        assert [r.link_target for r in references] == []

    def test_prose_containing_a_slash_is_not_harvested_as_a_directory(self):
        """Noise containment: an unquoted prose slash must not become a target.

        Measured in the real repo: 12 of the 14 whole-string compound values
        are prose of this shape.  A looser (delimiter-free) directory pattern
        would harvest every one of them.
        """
        parser = JsonParser()
        content = '{\n  "description": "Product Documentation - UI/UX Design"\n}\n'
        references = parser.parse_content(content, "settings.json")
        targets = [r.link_target for r in references]

        assert "UI/UX" not in targets

    def test_prose_apostrophes_do_not_span_a_directory_candidate(self):
        """The quoted-directory pattern must not match the GAP between two
        prose apostrophes.

        Found by measurement, not by review: against a real config template
        carrying a list of quoted naming examples, the first cut of this fix
        produced the candidate " (Dart/Go), " -- the text BETWEEN the closing
        apostrophe of one example and the opening apostrophe of the next.
        A directory candidate must be a clean path token.
        """
        parser = JsonParser()
        prose = (
            "Examples: "
            + Q
            + "test_{name}"
            + Q
            + " (Python), "
            + Q
            + "{name}_test"
            + Q
            + " (Dart/Go), "
            + Q
            + "{name}.test"
            + Q
            + " (JS/Jest)."
        )
        content = "{\n" + '  "_comment": "' + prose + '"\n' + "}\n"
        references = parser.parse_content(content, "settings.json")
        targets = [r.link_target for r in references]

        assert not any("Dart/Go" in t for t in targets)
        assert not any("JS/Jest" in t for t in targets)

    def test_quoted_file_path_inside_compound_is_not_duplicated_as_directory(self):
        """De-overlap control: QUOTED_DIR_PATTERN also matches extension-bearing
        quoted paths, so a file candidate must be recorded once, as a file."""
        parser = JsonParser()
        content = "{\n" '  "cmd": "Bash([ -f ' + BS + '"doc/design/x.md' + BS + '" ])"\n' "}\n"
        references = parser.parse_content(content, "settings.json")
        matching = [r for r in references if r.link_target == "doc/design/x.md"]

        assert len(matching) == 1, "candidate recorded more than once"
        assert matching[0].link_type == LinkType.JSON

    def test_compound_file_path_extraction_still_works(self):
        """Control (PD-BUG-061): the file-path branch is unaffected."""
        parser = JsonParser()
        content = '{\n  "cmd": "Bash(python doc/scripts/run.py *)"\n}\n'
        references = parser.parse_content(content, "settings.json")

        assert [r.link_target for r in references] == ["doc/scripts/run.py"]

    def test_filename_with_spaces_still_falls_through(self):
        """Control: a value with no candidates keeps whole-string classification."""
        parser = JsonParser()
        content = '{\n  "target": "doc/a file with spaces.txt"\n}\n'
        references = parser.parse_content(content, "settings.json")

        assert [r.link_target for r in references] == ["doc/a file with spaces.txt"]


class TestBug134SubstringLineAttribution:
    """Regression tests for PD-BUG-134: a value attributed to an earlier line
    that merely CONTAINS it as a substring, leaving its own line stale.

    Distinct from PD-BUG-013, which covered two values sharing the same WHOLE
    string.  Here the value is a substring of a larger literal, so the claimed
    set cannot help -- the (value, line) pair genuinely is unclaimed.
    """

    def test_bug134_plain_value_not_attributed_to_compound_line(self):
        """The reported fixture: a compound value on line 2 embeds the same
        directory that line 3 holds as a plain value.  Both used to be recorded
        against line 2, so line 3 went stale on a move with nothing logged."""
        parser = JsonParser()
        content = (
            "{\n"
            '  "watched_dir": "Bash([ -d ' + BS + '"doc/technical/design' + BS + '" ])",\n'
            '  "plain_dir": "doc/technical/design"\n'
            "}\n"
        )

        references = parser.parse_content(content, "settings.json")
        matching = [r for r in references if r.link_target == "doc/technical/design"]

        assert len(matching) == 2, "expected the compound candidate and the plain value"
        lines = sorted(r.line_number for r in matching)
        assert lines == [2, 3], f"expected one reference per line, got {lines}"
        assert lines != [2, 2], "both references collapsed onto the compound line"

    def test_bug134_directory_not_attributed_inside_longer_path(self):
        """A directory that is a PREFIX of a longer path on an earlier line.
        The short value used to be recorded at a span INSIDE the longer path,
        so its own line was never rewritten."""
        parser = JsonParser()
        content = (
            "{\n"
            '  "spec": "doc/technical/design/spec.md",\n'
            '  "dir": "doc/technical/design"\n'
            "}\n"
        )

        references = parser.parse_content(content, "settings.json")
        dir_refs = [r for r in references if r.link_target == "doc/technical/design"]

        assert len(dir_refs) == 1
        assert dir_refs[0].line_number == 3, (
            "directory attributed to the longer path's line " f"(line {dir_refs[0].line_number})"
        )
        # The recorded span must address the value itself, not a slice of the
        # longer path -- a span inside line 2 is what produced the overlap the
        # PD-BUG-098 filter then silently dropped.
        line3 = content.split("\n")[2]
        assert line3[dir_refs[0].column_start : dir_refs[0].column_end] == "doc/technical/design"

    def test_bug134_file_not_attributed_inside_compound_naming_it_twice(self):
        """A compound value naming the file twice (once with a suffix) on an
        earlier line than the plain value."""
        parser = JsonParser()
        content = (
            "{\n"
            '  "cmd": "python tools/run.py --out tools/run.py.bak",\n'
            '  "script": "tools/run.py"\n'
            "}\n"
        )

        references = parser.parse_content(content, "settings.json")
        exact = [r for r in references if r.link_target == "tools/run.py"]

        assert len(exact) == 2, "expected the compound candidate and the plain value"
        assert sorted(r.line_number for r in exact) == [2, 3]

    def test_bug134_key_shaped_collision_does_not_capture_the_value(self):
        """Boundary control: an earlier value that merely ENDS with the search
        text must not claim it (suffix collision)."""
        parser = JsonParser()
        content = "{\n" '  "other": "vendor/doc/design",\n' '  "dir": "doc/design"\n' "}\n"

        references = parser.parse_content(content, "settings.json")
        exact = [r for r in references if r.link_target == "doc/design"]

        assert len(exact) == 1
        assert exact[0].line_number == 3

    def test_bug134_duplicate_whole_values_still_get_distinct_lines(self):
        """Non-regression control (PD-BUG-013): the claimed-set behaviour for
        values sharing the WHOLE string is unchanged by the stricter match."""
        parser = JsonParser()
        content = (
            "{\n"
            '  "primary": "data.csv",\n'
            '  "backup": "data.csv",\n'
            '  "final": "data.csv"\n'
            "}\n"
        )

        references = parser.parse_content(content, "settings.json")
        refs = [r for r in references if r.link_target == "data.csv"]

        assert sorted(r.line_number for r in refs) == [2, 3, 4]

    def test_bug134_escaped_literal_path_still_located(self):
        """Non-regression control (PD-BUG-126): an escaped value is still found
        by the decoding search, which the stricter plain match must not disturb."""
        parser = JsonParser()
        content = "{\n" '  "log": "logs' + BS + BS + "sub" + BS + BS + 'x.txt"\n' "}\n"

        references = parser.parse_content(content, "settings.json")
        matching = [r for r in references if r.link_target == "logs" + BS + "sub" + BS + "x.txt"]

        assert len(matching) == 1
        assert matching[0].line_number == 2

    def test_bug134_array_elements_still_attributed_per_line(self):
        """Boundary control: array elements carry a trailing comma, so the
        quoted-form match must not require end-of-value."""
        parser = JsonParser()
        content = "{\n" '  "files": [\n' '    "a/one.md",\n' '    "a/two.md"\n' "  ]\n" "}\n"

        references = parser.parse_content(content, "settings.json")
        by_target = {r.link_target: r.line_number for r in references}

        assert by_target == {"a/one.md": 3, "a/two.md": 4}
