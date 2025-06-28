"""
Tests for the YAML parser.

This module tests YAML-specific link parsing functionality.
Implements YP test cases from comprehensive test documentation.
"""

from pathlib import Path

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.parsers.yaml_parser import YamlParser


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
            assert ref.link_type == "yaml"
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

        # Check references found in multi-line strings
        expected_files = [
            "input.csv",
            "output/report.html",
            "config/settings.yaml",
            "setup.md",
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
