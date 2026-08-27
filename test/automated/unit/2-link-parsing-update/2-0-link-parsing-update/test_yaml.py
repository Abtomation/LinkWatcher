"""
Tests for the YAML parser.

This module tests YAML-specific link parsing functionality.
Implements YP test cases from comprehensive test documentation.
"""

import pytest

from linkwatcher.link_types import LinkType
from linkwatcher.parsers.yaml_parser import YamlParser

pytestmark = [
    pytest.mark.feature("2.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("parser"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md"
    ),
]


class TestYamlParser:
    """Test cases for YamlParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = YamlParser()

        # Check that parser is properly initialized
        assert parser is not None

    def test_yp_001_simple_values(self, temp_project_dir):
        """
        YP-001: Simple values

        Test Case: file: path/to/file.txt
        Expected: File path parsed correctly
        Priority: High
        """
        parser = YamlParser()

        # Create YAML file with simple file references
        yaml_file = temp_project_dir / "config.yaml"
        yaml_content = """
application:
  name: "Test App"
  config_file: settings.conf
  data_file: ../tests/parsers/input.csv
  template: templates/main.html

paths:
  log_file: logs/app.log
  backup_dir: backup/
  schema: schemas/user.json
"""
        yaml_file.write_text(yaml_content)

        # Parse the file
        references = parser.parse_file(str(yaml_file))

        # Should find file references
        assert len(references) >= 5

        # Check specific references
        targets = [ref.link_target for ref in references]
        assert "settings.conf" in targets
        assert "../tests/parsers/input.csv" in targets
        assert "templates/main.html" in targets
        assert "logs/app.log" in targets
        assert "schemas/user.json" in targets

        # Check reference types
        for ref in references:
            assert ref.link_type in ("yaml", "yaml-dir")
            assert ref.file_path == str(yaml_file)

    def test_yp_002_nested_structures(self, temp_project_dir):
        """
        YP-002: Nested structures

        Test Case: Complex YAML with file refs
        Expected: All file paths found
        Priority: High
        """
        parser = YamlParser()

        # Create YAML with nested structures
        yaml_file = temp_project_dir / "complex.yaml"
        yaml_content = """
database:
  connections:
    primary:
      config: db/primary.conf
      schema: db/schema.sql
    secondary:
      config: db/secondary.conf
      backup: db/backup.sql

services:
  web:
    static_files: web/static/
    templates: web/templates/
    config:
      main: web/config/main.yaml
      logging: web/config/logging.yaml
  api:
    docs: api/swagger.yaml
    tests: api/tests/

monitoring:
  logs:
    - logs/access.log
    - logs/error.log
    - logs/debug.log
  metrics: monitoring/metrics.json
"""
        yaml_file.write_text(yaml_content)

        # Parse the file
        references = parser.parse_file(str(yaml_file))

        # Should find many nested references
        assert len(references) >= 10

        # Check nested references
        targets = [ref.link_target for ref in references]
        assert "db/primary.conf" in targets
        assert "db/schema.sql" in targets
        assert "web/config/main.yaml" in targets
        assert "api/swagger.yaml" in targets
        assert "logs/access.log" in targets
        assert "monitoring/metrics.json" in targets

    def test_yp_003_arrays(self, temp_project_dir):
        """
        YP-003: Arrays

        Test Case: files: [file1.txt, file2.txt]
        Expected: All array items parsed
        Priority: High
        """
        parser = YamlParser()

        # Create YAML with arrays of file references
        yaml_file = temp_project_dir / "arrays.yaml"
        yaml_content = """
input_files:
  - data/file1.csv
  - data/file2.csv
  - data/file3.csv

templates:
  - templates/header.html
  - templates/footer.html
  - templates/content.html

configs:
  - config/dev.yaml
  - config/prod.yaml
  - config/test.yaml

mixed_array:
  - name: "First"
    file: assets/first.json
  - name: "Second"
    file: assets/second.json

inline_array: [scripts/build.sh, scripts/deploy.sh, scripts/test.sh]
"""
        yaml_file.write_text(yaml_content)

        # Parse the file
        references = parser.parse_file(str(yaml_file))

        # Should find all array items
        assert len(references) >= 12

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

        # Inline array
        assert "scripts/build.sh" in targets
        assert "scripts/deploy.sh" in targets
        assert "scripts/test.sh" in targets

    def test_yp_004_multiline_strings(self, temp_project_dir):
        """
        YP-004: Multi-line strings

        Test Case: Multi-line string with file paths
        Expected: File paths in strings found
        Priority: Medium
        Regression: PD-BUG-079
        """
        parser = YamlParser()

        # Create YAML with multi-line strings containing file references
        yaml_file = temp_project_dir / "multiline.yaml"
        yaml_content = """
description: |
  This application processes data from input.csv
  and generates reports in output/report.html.
  Configuration is stored in config/settings.yaml.

instructions: >
  First, check the setup.md file for installation.
  Then run the scripts/install.sh script.
  Finally, review the docs/usage.md documentation.

sql_query: |
  -- Load data from data/users.sql
  -- Export results to exports/users.csv
  SELECT * FROM users;

script: |
  #!/bin/bash
  # Process files/input.txt
  # Generate files/output.txt
  echo "Processing complete"
"""
        yaml_file.write_text(yaml_content)

        # Parse the file
        references = parser.parse_file(str(yaml_file))

        # Should find file references in multi-line strings
        targets = [ref.link_target for ref in references]

        # PD-BUG-079: Must NOT return empty — multiline paths must be detected
        assert len(references) > 0, "No references found in multiline YAML blocks"

        # Paths with directory separators (these are unambiguous file paths)
        assert "output/report.html" in targets
        assert "config/settings.yaml" in targets
        assert "scripts/install.sh" in targets
        assert "docs/usage.md" in targets

        # Check references found in multi-line strings
        expected_files = [
            "output/report.html",
            "config/settings.yaml",
            "scripts/install.sh",
            "docs/usage.md",
            "data/users.sql",
            "exports/users.csv",
            "files/input.txt",
            "files/output.txt",
        ]

        found_count = 0
        for expected in expected_files:
            if expected in targets:
                found_count += 1

        # Should find most of the references (some might be filtered out)
        assert found_count >= 6

    def test_yp_004b_multiline_literal_block_line_numbers(self, temp_project_dir):
        """
        YP-004b: Multiline literal block — verify line numbers are accurate.

        Regression: PD-BUG-079
        """
        parser = YamlParser()

        yaml_file = temp_project_dir / "multiline_lines.yaml"
        yaml_content = (
            "notes: |\n"
            "  See docs/guide.md for details.\n"
            "  Also check src/main.py for usage.\n"
        )
        yaml_file.write_text(yaml_content)

        references = parser.parse_file(str(yaml_file))
        targets = {ref.link_target: ref for ref in references}

        assert "docs/guide.md" in targets, "docs/guide.md not found in multiline block"
        assert "src/main.py" in targets, "src/main.py not found in multiline block"

        # Verify line numbers point to actual raw lines
        guide_ref = targets["docs/guide.md"]
        assert guide_ref.line_number == 2  # "  See docs/guide.md for details."

        main_ref = targets["src/main.py"]
        assert main_ref.line_number == 3  # "  Also check src/main.py for usage."

    def test_yp_005_comments_ignored(self, temp_project_dir):
        """
        YP-005: Comments with file paths

        Test Case: # See file.txt
        Expected: Comments ignored
        Priority: Medium
        """
        parser = YamlParser()

        # Create YAML with comments containing file references
        yaml_file = temp_project_dir / "comments.yaml"
        yaml_content = """
# Configuration file - see docs/config.md for details
# Also check setup/install.sh for installation

application:
  name: "Test App"
  # Data file: ../tests/parsers/input.csv (this is a comment)
  config_file: config/real.yaml  # Real reference
  # template: templates/fake.html (commented out)

# The following files are important:
# - logs/app.log
# - cache/data.cache
# - temp/processing.tmp

database:
  # Connection string in db/connection.conf
  host: localhost
  # schema: db/schema.sql (not used)
  active_schema: db/active.sql  # This is real
"""
        yaml_file.write_text(yaml_content)

        # Parse the file
        references = parser.parse_file(str(yaml_file))

        # Should only find real references, not commented ones
        targets = [ref.link_target for ref in references]

        # Real references should be found
        assert "config/real.yaml" in targets
        assert "db/active.sql" in targets

        # Commented references should NOT be found
        assert "docs/config.md" not in targets
        assert "setup/install.sh" not in targets
        assert "../tests/parsers/input.csv" not in targets
        assert "templates/fake.html" not in targets
        assert "logs/app.log" not in targets
        assert "db/connection.conf" not in targets
        assert "db/schema.sql" not in targets

    def test_yp_006_yaml_anchors_aliases(self, temp_project_dir):
        """
        YP-006: YAML anchors and aliases

        Test Case: YAML with &anchor and *alias
        Expected: Anchors handled correctly
        Priority: Low
        """
        parser = YamlParser()

        # Create YAML with anchors and aliases
        yaml_file = temp_project_dir / "anchors.yaml"
        yaml_content = """
# Define anchors
defaults: &defaults
  config_file: config/default.yaml
  log_file: logs/default.log
  data_dir: data/

# Use anchors
development:
  <<: *defaults
  config_file: config/dev.yaml
  debug_log: logs/debug.log

production:
  <<: *defaults
  config_file: config/prod.yaml
  error_log: logs/error.log

# Reference anchor directly
test: *defaults

# Anchor with file reference
database_config: &db_config
  schema: db/schema.sql
  migrations: db/migrations/

services:
  primary:
    database: *db_config
  secondary:
    database: *db_config
    backup: db/backup.sql
"""
        yaml_file.write_text(yaml_content)

        # Parse the file
        references = parser.parse_file(str(yaml_file))

        # Should find file references from anchors and regular values
        targets = [ref.link_target for ref in references]

        # Check that file references are found
        assert "config/default.yaml" in targets
        assert "config/dev.yaml" in targets
        assert "config/prod.yaml" in targets
        assert "logs/default.log" in targets
        assert "logs/debug.log" in targets
        assert "logs/error.log" in targets
        assert "db/schema.sql" in targets
        assert "db/backup.sql" in targets


class TestYamlParserEdgeCases:
    """Edge cases for YAML parser."""

    def test_invalid_yaml_handling(self, temp_project_dir):
        """Test handling of invalid YAML."""
        parser = YamlParser()

        # Create invalid YAML file
        yaml_file = temp_project_dir / "invalid.yaml"
        yaml_content = """
invalid: yaml: content:
  - missing quotes
  - [unclosed bracket
  - key without:
    value
"""
        yaml_file.write_text(yaml_content)

        # Should not crash on invalid YAML
        references = parser.parse_file(str(yaml_file))

        # Might return empty list or partial results
        assert isinstance(references, list)

    def test_empty_yaml_file(self, temp_project_dir):
        """Test handling of empty YAML file."""
        parser = YamlParser()

        # Create empty YAML file
        yaml_file = temp_project_dir / "empty.yaml"
        yaml_file.write_text("")

        # Should handle empty file gracefully
        references = parser.parse_file(str(yaml_file))
        assert references == []

    def test_yaml_with_binary_data(self, temp_project_dir):
        """Test handling of YAML with binary data."""
        parser = YamlParser()

        # Create YAML with binary data
        yaml_file = temp_project_dir / "binary.yaml"
        yaml_content = """
config:
  file: config.yaml
  binary_data: !!binary |
    R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5
    OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+
    +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC
  other_file: other.yaml
"""
        yaml_file.write_text(yaml_content)

        # Should handle binary data without issues
        references = parser.parse_file(str(yaml_file))

        # Should find the file references
        targets = [ref.link_target for ref in references]
        assert "config.yaml" in targets
        assert "other.yaml" in targets

    def test_quoted_file_paths(self, temp_project_dir):
        """Test various quoting styles for file paths."""
        parser = YamlParser()

        # Create YAML with different quoting styles
        yaml_file = temp_project_dir / "quotes.yaml"
        yaml_content = """
files:
  single_quoted: 'path/to/file1.txt'
  double_quoted: "path/to/file2.txt"
  unquoted: path/to/file3.txt

special_chars:
  spaces: "file with spaces.txt"
  symbols: 'file-with-symbols_123.txt'
  mixed: "path/to/file with spaces & symbols.txt"

paths:
  windows: "C:\\\\Windows\\\\file.txt"
  unix: "/usr/local/bin/script.sh"
  relative: "../relative/path.txt"
"""
        yaml_file.write_text(yaml_content)

        # Parse the file
        references = parser.parse_file(str(yaml_file))

        # Should find all file references regardless of quoting
        targets = [ref.link_target for ref in references]

        assert "path/to/file1.txt" in targets
        assert "path/to/file2.txt" in targets
        assert "path/to/file3.txt" in targets
        assert "file with spaces.txt" in targets
        assert "file-with-symbols_123.txt" in targets
        assert "path/to/file with spaces & symbols.txt" in targets


class TestYamlParserDirectoryPaths:
    """Regression tests for PD-BUG-030: directory paths not detected in YAML values."""

    def test_bug030_directory_paths_detected_in_yaml(self, temp_project_dir):
        """
        PD-BUG-030: YAML values containing directory paths (no file extension)
        should be detected as references when they contain path separators.
        """
        parser = YamlParser()

        dir_a = "lib/docs/reference"
        dir_b = "vendor/tools/scripts"
        dir_c = "vendor/tools/templates"

        yaml_file = temp_project_dir / "dirs.yaml"
        yaml_content = (
            "directories:\n" f"  docs: {dir_a}\n" f"  scripts: {dir_b}\n" f"  templates: {dir_c}\n"
        )
        yaml_file.write_text(yaml_content)

        references = parser.parse_content(yaml_content, str(yaml_file))

        targets = [ref.link_target for ref in references]
        assert dir_a in targets
        assert dir_b in targets
        assert dir_c in targets

    def test_bug030_directory_paths_coexist_with_file_paths(self, temp_project_dir):
        """
        PD-BUG-030: Directory and file paths should both be detected in YAML.
        """
        parser = YamlParser()

        yaml_file = temp_project_dir / "mixed.yaml"
        yaml_content = """config:
  output_dir: build/output
  config_file: config/settings.yaml
  source_dir: src/components
  readme: docs/README.md
"""
        yaml_file.write_text(yaml_content)

        references = parser.parse_content(yaml_content, str(yaml_file))

        targets = [ref.link_target for ref in references]
        # File paths
        assert "config/settings.yaml" in targets
        assert "docs/README.md" in targets
        # Directory paths
        assert "build/output" in targets
        assert "src/components" in targets


class TestYamlParserCompoundStrings:
    """PD-BUG-060: YAML parser cannot detect file paths embedded in compound command strings.

    Root cause: looks_like_file_path() is called on the entire string value.
    The PD-BUG-028 heuristic rejects segments with 3+ space-separated words,
    and there is no sub-path extraction from compound strings.
    """

    def test_compound_command_string_with_embedded_file_path(self):
        """Compound command string containing an embedded file path should be detected."""
        parser = YamlParser()
        yaml_content = (
            "hooks:\n"
            '  - entry: "pwsh.exe -ExecutionPolicy Bypass -File alpha-project/scripts/test/Run-Tests.ps1 -Quick"\n'  # noqa: E501
        )
        references = parser.parse_content(yaml_content, "config.yaml")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/scripts/test/Run-Tests.ps1" in targets

    def test_compound_hook_entry_with_embedded_file_path(self):
        """Compound hook entry with an embedded FILE path should be detected.

        Renamed under PD-BUG-131: this was called
        ``test_compound_string_with_embedded_directory_path`` while asserting a
        .py FILE target, so it read as directory coverage that did not exist --
        which is roughly where PD-BUG-131 hid.  Real directory coverage now
        lives in TestBug131CompoundScalarDirectoryPaths.
        """
        parser = YamlParser()
        yaml_content = (
            "hooks:\n" '  - entry: "python alpha-project/scripts/feedback_db.py record --json"\n'
        )
        references = parser.parse_content(yaml_content, "config.yaml")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/scripts/feedback_db.py" in targets

    def test_bug_092_multi_document_yaml_dir_paths(self, temp_project_dir):
        """
        PD-BUG-092: Multi-document YAML (--- delimiters) must still detect
        directory paths. Previously, yaml.safe_load() raised ComposerError
        and fell back to GenericParser which lacks bare dir path detection,
        causing ~256 files to retain stale references after a directory move.
        """
        parser = YamlParser()
        yaml_content = (
            "# First document\n"
            "target_area: linkwatcher/parsers\n"
            "reference: linkwatcher/handler.py\n"
            "---\n"
            "# Second document\n"
            "source_area: linkwatcher/updater\n"
        )
        references = parser.parse_content(yaml_content, "config.yaml")
        targets = [ref.link_target for ref in references]
        # Both documents' values must be extracted
        assert (
            "linkwatcher/parsers" in targets
        ), f"Directory path from first document missed; got: {targets}"
        assert (
            "linkwatcher/updater" in targets
        ), f"Directory path from second document missed; got: {targets}"
        assert (
            "linkwatcher/handler.py" in targets
        ), f"File path from first document missed; got: {targets}"
        # Must use YAML link types (not GENERIC_* from fallback)
        link_types = {r.link_type for r in references}
        assert all(
            "generic" not in lt for lt in link_types
        ), f"Should not fall back to GenericParser; got link_types: {link_types}"


BS = chr(92)


class TestBug126EscapedLiteralLineLocation:
    r"""PD-BUG-126 regression, YAML half.

    ``_find_next_occurrence`` searches the RAW line for the DECODED value, so a
    double-quoted scalar carrying an escape is dropped exactly as in JSON.

    Exposure is narrower than JSON's: YAML honours backslash escapes only in
    DOUBLE-quoted scalars, so the single-quoted and plain forms already worked
    (there, raw and decoded are identical).  Those two are pinned as controls
    -- they must keep working.
    """

    def _parse(self, tmp_dir, raw_line):
        yaml_file = tmp_dir / "config.yaml"
        yaml_file.write_text(raw_line + "\n", encoding="utf-8")
        return YamlParser().parse_file(str(yaml_file))

    def test_double_quoted_escaped_backslash_is_detected(self, temp_project_dir):
        r"""``p: "logs\sub\x.txt"`` -- escapes honoured, so raw != decoded."""
        refs = self._parse(temp_project_dir, 'p: "logs' + BS * 2 + "sub" + BS * 2 + 'x.txt"')

        assert len(refs) == 1, "double-quoted escaped scalar dropped at line location"
        assert refs[0].link_target == "logs" + BS + "sub" + BS + "x.txt"

    def test_single_quoted_still_detected(self, temp_project_dir):
        """Control: single-quoted scalars take backslashes literally."""
        refs = self._parse(temp_project_dir, "p: 'logs" + BS + "sub" + BS + "x.txt'")

        assert len(refs) == 1
        assert refs[0].link_target == "logs" + BS + "sub" + BS + "x.txt"

    def test_plain_scalar_still_detected(self, temp_project_dir):
        """Control: plain scalars take backslashes literally."""
        refs = self._parse(temp_project_dir, "p: logs" + BS + "sub" + BS + "x.txt")

        assert len(refs) == 1
        assert refs[0].link_target == "logs" + BS + "sub" + BS + "x.txt"

    def test_forward_slash_still_detected(self, temp_project_dir):
        """Control: the ordinary escape-free path is unaffected."""
        refs = self._parse(temp_project_dir, "p: logs/sub/x.txt")

        assert len(refs) == 1
        assert refs[0].link_target == "logs/sub/x.txt"


class TestBug130EscapedCompoundStringPaths:
    r"""PD-BUG-130 regression, YAML half.

    Same defect and same two silent modes as the JSON twin: the compound-string
    branch searched the raw line for the DECODED value and offset candidate
    spans within the decoded text.  Narrower reach than JSON only because YAML
    honours backslash escapes in DOUBLE-quoted scalars alone -- plain and
    single-quoted scalars take them literally, so raw and decoded agree and the
    ordinary search already succeeds.
    """

    def _parse(self, tmp_dir, line, name="config.yaml"):
        yaml_file = tmp_dir / name
        yaml_file.write_text(line + "\n", encoding="utf-8")
        return YamlParser().parse_file(str(yaml_file))

    def _raw_line(self, tmp_dir, name="config.yaml"):
        return (tmp_dir / name).read_text(encoding="utf-8").split("\n")[0]

    def test_escaped_path_in_middle_is_detected(self, temp_project_dir):
        r"""``k: "pwsh -File logs\\sub\\run.ps1 -Verbose"``."""
        refs = self._parse(
            temp_project_dir,
            'k: "pwsh -File logs' + BS * 2 + "sub" + BS * 2 + 'run.ps1 -Verbose"',
        )

        targets = [r.link_target for r in refs]
        assert targets == [
            "logs" + BS + "sub" + BS + "run.ps1"
        ], "escaped candidate inside a compound scalar was dropped, got {!r}".format(targets)

    def test_escaped_path_at_end_is_not_registered_as_whole_string(self, temp_project_dir):
        """The whole command line must never become the link target."""
        refs = self._parse(
            temp_project_dir,
            'k: "pwsh -File logs' + BS * 2 + "sub" + BS * 2 + 'run.ps1"',
        )

        targets = [r.link_target for r in refs]
        whole = "pwsh -File logs" + BS + "sub" + BS + "run.ps1"

        assert whole not in targets, "whole command string registered as a link target"
        assert targets == ["logs" + BS + "sub" + BS + "run.ps1"]

    def test_span_covers_the_raw_candidate_not_the_decoded_one(self, temp_project_dir):
        """The span must address the raw escaped candidate (PD-BUG-124 class)."""
        refs = self._parse(
            temp_project_dir,
            'k: "pwsh -File logs' + BS * 2 + "sub" + BS * 2 + 'run.ps1 -Verbose"',
        )

        assert len(refs) == 1
        ref = refs[0]
        line = self._raw_line(temp_project_dir)
        assert line[ref.column_start : ref.column_end] == (
            "logs" + BS * 2 + "sub" + BS * 2 + "run.ps1"
        ), "span must cover the raw escaped candidate, got {!r}".format(
            line[ref.column_start : ref.column_end]
        )

    def test_clean_candidate_inside_escaped_scalar_is_detected(self, temp_project_dir):
        r"""The candidate is escape-free; the surrounding scalar is not."""
        refs = self._parse(
            temp_project_dir,
            'k: "echo ' + BS + '"x' + BS + '" && pwsh -File doc/scripts/Run.ps1"',
        )

        assert [r.link_target for r in refs] == ["doc/scripts/Run.ps1"]
        ref = refs[0]
        line = self._raw_line(temp_project_dir)
        assert line[ref.column_start : ref.column_end] == "doc/scripts/Run.ps1"

    def test_plain_compound_scalar_still_detected(self, temp_project_dir):
        """Control: escape-free compound scalar is unaffected (PD-BUG-060)."""
        refs = self._parse(temp_project_dir, 'k: "pwsh -File doc/scripts/Run.ps1 -Quick"')

        assert [r.link_target for r in refs] == ["doc/scripts/Run.ps1"]

    def test_single_quoted_compound_scalar_still_detected(self, temp_project_dir):
        r"""Control: single-quoted scalars take ``\`` literally, so raw == decoded."""
        refs = self._parse(
            temp_project_dir, "k: 'pwsh -File logs" + BS + "sub" + BS + "run.ps1 -Quick'"
        )

        assert [r.link_target for r in refs] == ["logs" + BS + "sub" + BS + "run.ps1"]


class TestBug131CompoundScalarDirectoryPaths:
    """PD-BUG-131 regression: a DIRECTORY path embedded in a compound
    (space-bearing) YAML scalar was never extracted, and the whole command
    string was registered as the reference target in its place.

    Root cause: ``_extract_embedded_paths`` reached only for ``_path_pattern``,
    which requires a file extension.  The two structured parsers never adopted
    the shared ``QUOTED_DIR_PATTERN`` the other five parsers use for
    extensionless directories, so a compound scalar holding one yielded no
    candidates, returned False, and fell through to whole-string
    classification.

    The delimiter requirement is deliberate and matches every other parser:
    an UNQUOTED extensionless token is not a directory reference anywhere in
    this product.
    """

    def test_quoted_directory_inside_compound_scalar_is_extracted(self):
        """A quoted directory inside a command scalar is a directory reference."""
        parser = YamlParser()
        content = "cmd: pwsh.exe -File 'doc/technical/design' -Recurse\n"
        references = parser.parse_content(content, "config.yaml")
        targets = [r.link_target for r in references]

        assert "doc/technical/design" in targets
        # Strong negative: the whole command must NOT survive as a target
        assert not any("pwsh.exe -File" in t for t in targets)

    def test_extracted_directory_carries_the_dir_link_type(self):
        """A directory candidate must be typed YAML_DIR, not YAML."""
        parser = YamlParser()
        content = "cmd: pwsh.exe -File 'doc/technical/design' -Recurse\n"
        references = parser.parse_content(content, "config.yaml")
        dir_refs = [r for r in references if r.link_target == "doc/technical/design"]

        assert dir_refs, "directory candidate was not extracted"
        assert dir_refs[0].link_type == LinkType.YAML_DIR

    def test_unquoted_compound_directory_does_not_register_whole_command(self):
        """Symptom (b): the bracketed command must not become a link target."""
        parser = YamlParser()
        content = 'cmd: "Bash([ -d doc/design ])"\n'
        references = parser.parse_content(content, "config.yaml")
        targets = [r.link_target for r in references]

        assert not any("Bash(" in t for t in targets)

    def test_directory_value_with_spaces_still_classified_whole_string(self):
        """Discriminating control for symptom (b): a genuine path containing a
        space is still a directory reference -- the containment must reject
        command syntax, not spaces."""
        parser = YamlParser()
        content = 'target: "doc/my design"\n'
        references = parser.parse_content(content, "config.yaml")

        assert [r.link_target for r in references] == ["doc/my design"]
        assert references[0].link_type == LinkType.YAML_DIR

    def test_prose_containing_a_slash_is_not_harvested_as_a_directory(self):
        """Noise containment: an unquoted prose slash must not become a target."""
        parser = YamlParser()
        content = 'description: "Parser tests for Dart import/part statement parsing"\n'
        references = parser.parse_content(content, "config.yaml")
        targets = [r.link_target for r in references]

        assert "import/part" not in targets

    def test_prose_apostrophes_do_not_span_a_directory_candidate(self):
        """Symmetry with the JSON suite (code review suggestion).

        The code is shared through ``BaseParser._collect_path_candidates``, so
        behaviour is identical; this pins it on the YAML side too rather than
        relying on the JSON test to cover both.
        """
        parser = YamlParser()
        q = chr(39)
        content = (
            "description: "
            + chr(34)
            + "naming: "
            + q
            + "a_test"
            + q
            + " (Dart/Go), "
            + q
            + "b_test"
            + q
            + chr(34)
            + "\n"
        )
        references = parser.parse_content(content, "config.yaml")
        targets = [r.link_target for r in references]

        assert not any("Dart/Go" in t for t in targets)

    def test_quoted_file_path_inside_compound_is_not_duplicated_as_directory(self):
        """De-overlap control: a file candidate is recorded once, as a file."""
        parser = YamlParser()
        content = "cmd: pwsh.exe -File 'doc/scripts/Run.ps1' -Quick\n"
        references = parser.parse_content(content, "config.yaml")
        matching = [r for r in references if r.link_target == "doc/scripts/Run.ps1"]

        assert len(matching) == 1, "candidate recorded more than once"
        assert matching[0].link_type == LinkType.YAML

    def test_compound_file_path_extraction_still_works(self):
        """Control (PD-BUG-060): the file-path branch is unaffected."""
        parser = YamlParser()
        content = 'cmd: "pwsh -File doc/scripts/Run.ps1 -Quick"\n'
        references = parser.parse_content(content, "config.yaml")

        assert [r.link_target for r in references] == ["doc/scripts/Run.ps1"]

    def test_filename_with_spaces_still_falls_through(self):
        """Control: a scalar with no candidates keeps whole-string classification."""
        parser = YamlParser()
        content = 'target: "doc/a file with spaces.txt"\n'
        references = parser.parse_content(content, "config.yaml")

        assert [r.link_target for r in references] == ["doc/a file with spaces.txt"]


class TestBug134SubstringLineAttribution:
    """Regression tests for PD-BUG-134: a scalar attributed to an earlier line
    that merely CONTAINS it as a substring, leaving its own line stale.

    The YAML sibling of the JSON defect.  ``_find_next_occurrence`` already
    skips a position another reference took, which covers a scalar repeated
    verbatim -- but not one sitting INSIDE a larger literal, where no
    reference holds that exact (target, column) pair.
    """

    def test_bug134_directory_not_attributed_inside_longer_path(self):
        """A directory that is a PREFIX of a longer path on an earlier line."""
        parser = YamlParser()
        content = "spec: doc/technical/design/spec.md\ndir: doc/technical/design\n"

        references = parser.parse_content(content, "config.yaml")
        dir_refs = [r for r in references if r.link_target == "doc/technical/design"]

        assert len(dir_refs) == 1
        assert dir_refs[0].line_number == 2, (
            "directory attributed to the longer path's line " f"(line {dir_refs[0].line_number})"
        )
        line2 = content.split("\n")[1]
        assert line2[dir_refs[0].column_start : dir_refs[0].column_end] == "doc/technical/design"

    def test_bug134_plain_scalar_not_attributed_to_unquoted_compound_line(self):
        """An UNQUOTED directory inside a compound scalar is deliberately not a
        reference (PD-BUG-131), so no reference holds that position -- and the
        plain scalar on the next line used to be attributed to it, which both
        left line 2 stale and rewrote a value that is not a reference."""
        parser = YamlParser()
        content = "cmd: pwsh -File doc/technical/design -Recurse\nplain: doc/technical/design\n"

        references = parser.parse_content(content, "config.yaml")
        matching = [r for r in references if r.link_target == "doc/technical/design"]

        assert len(matching) == 1, f"expected only the plain scalar, got {matching}"
        assert matching[0].line_number == 2, (
            "plain scalar attributed to the compound line " f"(line {matching[0].line_number})"
        )

    def test_bug134_suffix_collision_does_not_capture_the_value(self):
        """Boundary control: an earlier value ENDING with the search text must
        not claim it."""
        parser = YamlParser()
        content = "other: vendor/doc/design\ndir: doc/design\n"

        references = parser.parse_content(content, "config.yaml")
        exact = [r for r in references if r.link_target == "doc/design"]

        assert len(exact) == 1
        assert exact[0].line_number == 2

    def test_bug134_quoted_compound_candidate_still_gets_its_own_line(self):
        """Non-regression control (PD-BUG-131): a QUOTED directory inside a
        compound scalar is a reference, and the plain scalar below it keeps a
        separate line."""
        parser = YamlParser()
        content = (
            "cmd: \"pwsh.exe -File 'doc/technical/design' -Recurse\"\nplain: doc/technical/design\n"
        )

        references = parser.parse_content(content, "config.yaml")
        matching = [r for r in references if r.link_target == "doc/technical/design"]

        assert len(matching) == 2
        assert sorted(r.line_number for r in matching) == [1, 2]

    def test_bug134_tagged_scalar_still_located(self):
        """Fallback control: a shape the standalone-scalar rule does not
        recognise (an explicit YAML tag) must still be located rather than
        dropped -- the strict pass falls back to the plain scan."""
        parser = YamlParser()
        content = "dir: !!str doc/technical/design\n"

        references = parser.parse_content(content, "config.yaml")
        matching = [r for r in references if r.link_target == "doc/technical/design"]

        assert len(matching) == 1, "tagged scalar dropped instead of falling back"
        assert matching[0].line_number == 1

    def test_bug134_list_items_attributed_per_line(self):
        """Boundary control: block sequence entries."""
        parser = YamlParser()
        content = "dirs:\n  - doc/one/design\n  - doc/two/design\n"

        references = parser.parse_content(content, "config.yaml")
        by_target = {r.link_target: r.line_number for r in references}

        assert by_target == {"doc/one/design": 2, "doc/two/design": 3}

    def test_bug134_flow_sequence_and_trailing_comment_attributed(self):
        """Boundary control: a flow sequence and a commented scalar are both
        whole values despite their trailing punctuation."""
        parser = YamlParser()
        content = "flow: [doc/a/design, doc/b/design]\nnoted: doc/c/design  # keep\n"

        references = parser.parse_content(content, "config.yaml")
        by_target = {r.link_target: r.line_number for r in references}

        assert by_target == {
            "doc/a/design": 1,
            "doc/b/design": 1,
            "doc/c/design": 2,
        }

    def test_bug134_block_scalar_candidates_still_located(self):
        """Non-regression control (PD-BUG-079): candidates inside a multiline
        block scalar are located individually and are NOT whole values, so the
        standalone rule must not be applied to them."""
        parser = YamlParser()
        content = (
            "script: |\n  pwsh -File doc/scripts/Run.ps1 -Quick\n  python doc/scripts/run.py\n"
        )

        references = parser.parse_content(content, "config.yaml")
        by_target = {r.link_target: r.line_number for r in references}

        assert by_target == {"doc/scripts/Run.ps1": 2, "doc/scripts/run.py": 3}

    def test_bug134_block_scalar_candidate_not_pulled_onto_a_later_value(self):
        """The block-scalar opt-out (whole_value=False) is load-bearing, not
        redundant with the fallback.

        Applying the standalone rule to a block-scalar candidate makes the
        strict pass skip the fragment on its own line and match a LATER line
        where the same path is a whole value.  The two references then swap
        lines: the candidate claims the standalone line, and the standalone
        value is pushed onto the block scalar by the fallback behind it."""
        parser = YamlParser()
        content = (
            "script: |\n" "  pwsh -File doc/scripts/Run.ps1 -Quick\n" "other: doc/scripts/Run.ps1\n"
        )

        references = parser.parse_content(content, "config.yaml")
        refs = [r for r in references if r.link_target == "doc/scripts/Run.ps1"]

        assert len(refs) == 2
        assert sorted(r.line_number for r in refs) == [2, 3]
        # Order matters: the block-scalar candidate is recorded first and must
        # hold line 2, the line it actually occupies.
        assert refs[0].line_number == 2, "block-scalar candidate pulled onto the later value"
        assert refs[1].line_number == 3

    def test_bug134_repeated_scalar_still_gets_distinct_lines(self):
        """Non-regression control: a scalar repeated verbatim keeps one
        reference per line."""
        parser = YamlParser()
        content = "a: data/report.md\nb: data/report.md\nc: data/report.md\n"

        references = parser.parse_content(content, "config.yaml")
        refs = [r for r in references if r.link_target == "data/report.md"]

        assert sorted(r.line_number for r in refs) == [1, 2, 3]
