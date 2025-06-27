"""
Integration Tests for Link Updates (LR Test Cases)

This module implements the LR test cases from our comprehensive test documentation,
focusing on different types of link references and their updates.

Test Cases Implemented:
- LR-001: Markdown standard links
- LR-002: Markdown relative links
- LR-003: Markdown with anchors
- LR-004: YAML file references
- LR-005: JSON file references
- LR-006: Python imports (if supported)
- LR-007: Dart imports
- LR-008: Generic text files
"""

from pathlib import Path

import pytest

from linkwatcher.service import LinkWatcherService


class TestLinkReferences:
    """Integration tests for different types of link references."""

    def test_lr_001_markdown_standard_links(self, temp_project_dir):
        """
        LR-001: Markdown standard links

        Test Case: [text](file.txt) with file move
        Expected: Link updated to new path
        Priority: Critical
        """
        # Create target file
        target_file = temp_project_dir / "target.txt"
        target_file.write_text("Target content")

        # Create markdown file with standard links
        md_file = temp_project_dir / "document.md"
        md_content = """# Document

Standard links:
- [Link to target](target.txt)
- [Another link](target.txt "with title")
- [Third link](target.txt)

Mixed content with [inline link](target.txt) in paragraph.
"""
        md_file.write_text(md_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify initial references found
        refs = service.link_db.get_references_to_file("target.txt")
        assert len(refs) >= 4  # Should find all 4 links

        # Move target file
        new_target = temp_project_dir / "new_target.txt"
        target_file.rename(new_target)

        # Process move event
        service.handler.on_moved(None, str(target_file), str(new_target), False)

        # Verify all links were updated
        md_updated = md_file.read_text()

        # Count occurrences
        new_count = md_updated.count("new_target.txt")
        old_count = md_updated.count("target.txt")

        assert new_count >= 4  # All links should be updated
        assert old_count == 0  # No old links should remain

        # Verify specific link formats are preserved
        assert "[Link to target](new_target.txt)" in md_updated
        assert '[Another link](new_target.txt "with title")' in md_updated
        assert "[inline link](new_target.txt)" in md_updated

    def test_lr_002_markdown_relative_links(self, temp_project_dir):
        """
        LR-002: Markdown relative links

        Test Case: [text](../file.txt) with file move
        Expected: Relative path correctly updated
        Priority: Critical
        """
        # Create directory structure
        docs_dir = temp_project_dir / "docs"
        assets_dir = temp_project_dir / "assets"
        docs_dir.mkdir()
        assets_dir.mkdir()

        # Create target file in assets
        target_file = assets_dir / "image.png"
        target_file.write_text("Image data")

        # Create markdown file in docs with relative links
        md_file = docs_dir / "guide.md"
        md_content = """# Guide

Images:
- [Logo](../assets/image.png)
- ![Image](../assets/image.png "Alt text")

See the [image file](../assets/image.png) for details.
"""
        md_file.write_text(md_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move target file to different location
        new_target = temp_project_dir / "media" / "logo.png"
        new_target.parent.mkdir()
        target_file.rename(new_target)

        # Process move event
        service.handler.on_moved(None, str(target_file), str(new_target), False)

        # Verify relative paths were updated correctly
        md_updated = md_file.read_text()

        # From docs/ directory, media/logo.png should be ../media/logo.png
        assert "../media/logo.png" in md_updated
        assert "../assets/image.png" not in md_updated

        # Verify all link types were updated
        assert "[Logo](../media/logo.png)" in md_updated
        assert '![Image](../media/logo.png "Alt text")' in md_updated
        assert "[image file](../media/logo.png)" in md_updated

    def test_lr_003_markdown_with_anchors(self, temp_project_dir):
        """
        LR-003: Markdown with anchors

        Test Case: [text](file.txt#section) with file move
        Expected: Path updated, anchor preserved
        Priority: High
        """
        # Create target file
        target_file = temp_project_dir / "documentation.md"
        target_content = """# Documentation

## Introduction
Content here.

## Configuration
More content.

## API Reference
API details.
"""
        target_file.write_text(target_content)

        # Create file with anchor links
        index_file = temp_project_dir / "index.md"
        index_content = """# Index

Navigation:
- [Introduction](documentation.md#introduction)
- [Configuration](documentation.md#configuration)
- [API Reference](documentation.md#api-reference)

Quick links:
- See [config section](documentation.md#configuration) for setup
- Check [API docs](documentation.md#api-reference) for details
"""
        index_file.write_text(index_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move target file
        new_target = temp_project_dir / "docs" / "manual.md"
        new_target.parent.mkdir()
        target_file.rename(new_target)

        # Process move event
        service.handler.on_moved(None, str(target_file), str(new_target), False)

        # Verify anchors were preserved
        index_updated = index_file.read_text()

        # Check that path is updated but anchors are preserved
        assert "docs/manual.md#introduction" in index_updated
        assert "docs/manual.md#configuration" in index_updated
        assert "docs/manual.md#api-reference" in index_updated

        # Verify old references are gone
        assert "documentation.md#" not in index_updated

        # Verify specific link formats
        assert "[Introduction](docs/manual.md#introduction)" in index_updated
        assert "[config section](docs/manual.md#configuration)" in index_updated
        assert "[API docs](docs/manual.md#api-reference)" in index_updated

    def test_lr_004_yaml_file_references(self, temp_project_dir):
        """
        LR-004: YAML file references

        Test Case: file: path/to/file.txt with file move
        Expected: YAML value updated
        Priority: High
        """
        # Create target files
        config_file = temp_project_dir / "app.conf"
        config_file.write_text("setting=value")

        template_file = temp_project_dir / "template.html"
        template_file.write_text("<html></html>")

        # Create YAML file with file references
        yaml_file = temp_project_dir / "config.yaml"
        yaml_content = """
application:
  name: "Test App"
  config_file: app.conf
  template: template.html

files:
  - app.conf
  - template.html
  - "app.conf"  # quoted reference

paths:
  config: "app.conf"
  template: 'template.html'  # single quotes
"""
        yaml_file.write_text(yaml_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move config file
        new_config = temp_project_dir / "settings" / "application.conf"
        new_config.parent.mkdir()
        config_file.rename(new_config)

        # Process move event
        service.handler.on_moved(None, str(config_file), str(new_config), False)

        # Verify YAML was updated
        yaml_updated = yaml_file.read_text()

        # Check all references were updated
        assert "settings/application.conf" in yaml_updated
        assert "app.conf" not in yaml_updated

        # Verify different YAML formats were handled
        assert "config_file: settings/application.conf" in yaml_updated
        assert "- settings/application.conf" in yaml_updated
        assert '"settings/application.conf"' in yaml_updated
        assert 'config: "settings/application.conf"' in yaml_updated

    def test_lr_005_json_file_references(self, temp_project_dir):
        """
        LR-005: JSON file references

        Test Case: {"file": "path/to/file.txt"} with file move
        Expected: JSON value updated
        Priority: High
        """
        # Create target files
        data_file = temp_project_dir / "data.csv"
        data_file.write_text("col1,col2\nval1,val2")

        schema_file = temp_project_dir / "schema.json"
        schema_file.write_text('{"type": "object"}')

        # Create JSON file with file references
        config_json = temp_project_dir / "config.json"
        config_content = """{
  "application": {
    "name": "Test App",
    "data_source": "data.csv",
    "schema": "schema.json"
  },
  "files": [
    "data.csv",
    "schema.json"
  ],
  "paths": {
    "data": "data.csv",
    "schema": "schema.json"
  },
  "backup": {
    "data_file": "data.csv"
  }
}"""
        config_json.write_text(config_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move data file
        new_data = temp_project_dir / "datasets" / "main.csv"
        new_data.parent.mkdir()
        data_file.rename(new_data)

        # Process move event
        service.handler.on_moved(None, str(data_file), str(new_data), False)

        # Verify JSON was updated
        config_updated = config_json.read_text()

        # Check all references were updated
        assert "datasets/main.csv" in config_updated
        assert "data.csv" not in config_updated

        # Verify JSON structure is maintained
        import json

        config_data = json.loads(config_updated)

        assert config_data["application"]["data_source"] == "datasets/main.csv"
        assert "datasets/main.csv" in config_data["files"]
        assert config_data["paths"]["data"] == "datasets/main.csv"
        assert config_data["backup"]["data_file"] == "datasets/main.csv"

    def test_lr_006_python_imports(self, temp_project_dir):
        """
        LR-006: Python imports

        Test Case: from module import file with file move
        Expected: Import statement updated (if supported)
        Priority: Medium
        """
        # Create Python module structure
        utils_dir = temp_project_dir / "utils"
        utils_dir.mkdir()

        # Create Python files
        helper_file = utils_dir / "helper.py"
        helper_file.write_text("def help_function(): pass")

        init_file = utils_dir / "__init__.py"
        init_file.write_text("")

        # Create main file with imports
        main_file = temp_project_dir / "main.py"
        main_content = """#!/usr/bin/env python3
\"\"\"Main application module.\"\"\"

from utils.helper import help_function
import utils.helper
from utils import helper

# Also reference "utils/helper.py" in comments
# Configuration in utils/helper.py
config_path = "utils/helper.py"
"""
        main_file.write_text(main_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move helper file
        new_helper = utils_dir / "assistant.py"
        helper_file.rename(new_helper)

        # Process move event
        service.handler.on_moved(None, str(helper_file), str(new_helper), False)

        # Verify references were updated
        main_updated = main_file.read_text()

        # Check string references were updated
        assert "utils/assistant.py" in main_updated
        assert "utils/helper.py" not in main_updated

        # Note: Import statement updates would require more sophisticated parsing
        # For now, we focus on string references which are more reliable

    def test_lr_007_dart_imports(self, temp_project_dir):
        """
        LR-007: Dart imports

        Test Case: import 'package:app/file.dart' with file move
        Expected: Import path updated
        Priority: Medium
        """
        # Create Dart file structure
        lib_dir = temp_project_dir / "lib"
        lib_dir.mkdir()

        # Create Dart files
        utils_file = lib_dir / "utils.dart"
        utils_content = """
class Utils {
  static String format(String input) {
    return input.trim();
  }
}
"""
        utils_file.write_text(utils_content)

        # Create main Dart file with imports
        main_dart = temp_project_dir / "main.dart"
        main_content = """
import 'lib/utils.dart';
import "lib/utils.dart";

// Also reference 'lib/utils.dart' in comments
// See lib/utils.dart for utilities
const configFile = 'lib/utils.dart';
"""
        main_dart.write_text(main_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move utils file
        helpers_dir = lib_dir / "helpers"
        helpers_dir.mkdir()
        new_utils = helpers_dir / "string_utils.dart"
        utils_file.rename(new_utils)

        # Process move event
        service.handler.on_moved(None, str(utils_file), str(new_utils), False)

        # Verify references were updated
        main_updated = main_dart.read_text()

        # Check all references were updated
        assert "lib/helpers/string_utils.dart" in main_updated
        assert "lib/utils.dart" not in main_updated

        # Verify different quote styles were handled
        assert "'lib/helpers/string_utils.dart'" in main_updated
        assert '"lib/helpers/string_utils.dart"' in main_updated

    def test_lr_008_generic_text_files(self, temp_project_dir):
        """
        LR-008: Generic text files

        Test Case: Quoted file references with file move
        Expected: References updated
        Priority: Medium
        """
        # Create target files
        readme_file = temp_project_dir / "README.txt"
        readme_file.write_text("Project information")

        license_file = temp_project_dir / "LICENSE"
        license_file.write_text("MIT License")

        # Create generic text file with references
        notes_file = temp_project_dir / "NOTES.txt"
        notes_content = """Project Notes
=============

Important files:
- "README.txt" contains project info
- 'LICENSE' contains license terms
- See README.txt for setup
- Check "LICENSE" for legal info

File paths:
README.txt
"README.txt"
'README.txt'
LICENSE
"LICENSE"
'LICENSE'

Mixed content with README.txt and "LICENSE" references.
"""
        notes_file.write_text(notes_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move README file
        new_readme = temp_project_dir / "docs" / "PROJECT_INFO.txt"
        new_readme.parent.mkdir()
        readme_file.rename(new_readme)

        # Process move event
        service.handler.on_moved(None, str(readme_file), str(new_readme), False)

        # Verify references were updated
        notes_updated = notes_file.read_text()

        # Check all references were updated
        assert "docs/PROJECT_INFO.txt" in notes_updated
        assert "README.txt" not in notes_updated

        # Verify different quote styles were handled
        assert '"docs/PROJECT_INFO.txt"' in notes_updated
        assert "'docs/PROJECT_INFO.txt'" in notes_updated


class TestLinkReferenceEdgeCases:
    """Edge cases for link reference handling."""

    def test_mixed_reference_types(self, temp_project_dir):
        """Test file with multiple types of references."""
        # Create target file
        target = temp_project_dir / "shared.txt"
        target.write_text("Shared content")

        # Create file with mixed reference types
        mixed_file = temp_project_dir / "mixed.md"
        mixed_content = """# Mixed References

Markdown: [link](shared.txt)
Quoted: "shared.txt"
Unquoted: shared.txt
Code: `shared.txt`
HTML: <a href="shared.txt">link</a>
"""
        mixed_file.write_text(mixed_content)

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move target
        new_target = temp_project_dir / "common.txt"
        target.rename(new_target)
        service.handler.on_moved(None, str(target), str(new_target), False)

        # Verify updates
        mixed_updated = mixed_file.read_text()
        assert "common.txt" in mixed_updated
        assert mixed_updated.count("shared.txt") == 0  # All should be updated

    def test_false_positive_avoidance(self, temp_project_dir):
        """Test that false positives are avoided."""
        # Create file with potential false positives
        test_file = temp_project_dir / "test.md"
        content = """# Test

Real reference: [link](real.txt)
URL: https://example.com/fake.txt
Email: user@domain.txt
Version: v1.2.txt
Extension: .txt files
"""
        test_file.write_text(content)

        # Create real target
        real_file = temp_project_dir / "real.txt"
        real_file.write_text("Real content")

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Should only find the real reference
        refs = service.link_db.get_references_to_file("real.txt")
        assert len(refs) == 1

        # Should not find false positives
        fake_refs = service.link_db.get_references_to_file("fake.txt")
        assert len(fake_refs) == 0
