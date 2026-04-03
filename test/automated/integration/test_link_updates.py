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

import pytest
from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService

pytestmark = [
    pytest.mark.feature("2.2.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.cross_cutting(["2.1.1", "0.1.1", "1.1.1"]),
    pytest.mark.test_type("integration"),
    pytest.mark.specification("test/specifications/feature-specs/test-spec-2-2-1-link-updating.md"),
]


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
        move_event = FileMovedEvent(str(target_file), str(new_target))
        service.handler.on_moved(move_event)

        # Verify all links were updated
        md_updated = md_file.read_text()

        # Count occurrences — subtract new_target.txt hits to get bare old refs
        new_count = md_updated.count("new_target.txt")
        total_target_count = md_updated.count("target.txt")
        old_count = total_target_count - new_count

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
        move_event = FileMovedEvent(str(target_file), str(new_target))
        service.handler.on_moved(move_event)

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
        move_event = FileMovedEvent(str(target_file), str(new_target))
        service.handler.on_moved(move_event)

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
        move_event = FileMovedEvent(str(config_file), str(new_config))
        service.handler.on_moved(move_event)

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
        move_event = FileMovedEvent(str(data_file), str(new_data))
        service.handler.on_moved(move_event)

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
        move_event = FileMovedEvent(str(helper_file), str(new_helper))
        service.handler.on_moved(move_event)

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
        move_event = FileMovedEvent(str(utils_file), str(new_utils))
        service.handler.on_moved(move_event)

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
        move_event = FileMovedEvent(str(readme_file), str(new_readme))
        service.handler.on_moved(move_event)

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
        move_event = FileMovedEvent(str(target), str(new_target))
        service.handler.on_moved(move_event)

        # Verify updates
        mixed_updated = mixed_file.read_text()
        assert "common.txt" in mixed_updated
        assert (
            mixed_updated.count("shared.txt") == 0
        )  # All references updated including backtick (PD-BUG-054)

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


class TestStaleLineNumberHandling:
    """Integration tests for stale line number detection and recovery (PD-BUG-005)."""

    def test_stale_triggers_rescan_and_retry(self, temp_project_dir):
        """
        PD-BUG-005: Full end-to-end test for stale line number recovery.

        Scenario:
        1. Initial scan builds database with correct line numbers
        2. User edits a source file (inserts lines, shifting the link)
        3. A referenced file is moved
        4. Handler detects stale line numbers, rescans, and retries
        5. Link is correctly updated despite the edit
        """
        # Create target file
        target_file = temp_project_dir / "target.txt"
        target_file.write_text("Target content")

        # Create source file with a link on line 3
        source_file = temp_project_dir / "source.md"
        original_content = "# Title\n\nSee [link](target.txt) for info.\n"
        source_file.write_text(original_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify database has reference at line 3
        refs = service.link_db.get_references_to_file("target.txt")
        assert len(refs) >= 1
        source_ref = [r for r in refs if "source.md" in r.file_path]
        assert len(source_ref) == 1
        assert source_ref[0].line_number == 3

        # Simulate user editing: insert 2 lines before the link
        # Link is now on line 5, but database still says line 3
        edited_content = "# Title\n\nNew paragraph 1.\n\nSee [link](target.txt) for info.\n"
        source_file.write_text(edited_content)

        # Move target file
        new_dir = temp_project_dir / "subdir"
        new_dir.mkdir()
        new_target = new_dir / "target.txt"
        target_file.rename(new_target)

        # Simulate file move event
        event = FileMovedEvent(str(target_file), str(new_target))
        service.handler._handle_file_moved(event)

        # Verify source file was updated correctly (despite stale line numbers)
        updated_content = source_file.read_text()
        assert "target.txt" not in updated_content or "subdir/target.txt" in updated_content
        assert "subdir/target.txt" in updated_content


class TestBug010TitlePreservation:
    """Regression tests for PD-BUG-010: Markdown link title attribute lost during updates."""

    def test_bug010_title_preserved_when_file_moved_deeper(self, temp_project_dir):
        """
        PD-BUG-010: Markdown link title attribute lost during updates.

        When a markdown file with titled links is moved to a DEEPER directory,
        the handler's _update_links_within_moved_file must preserve title attributes
        while updating relative paths.

        Root cause: handler.py regex in _update_links_within_moved_file did not
        include an optional title group, so links with titles failed to match
        and were silently not updated.
        """
        # Create a target file at project root
        target_file = temp_project_dir / "target.txt"
        target_file.write_text("Target content")

        # Create a markdown file at root level with titled links to target.txt
        md_file = temp_project_dir / "guide.md"
        md_content = """# Guide

Links with titles:
- [Link with double-quote title](target.txt "API Reference")
- [Link with single-quote title](target.txt 'Quick Guide')
- [Link with paren title](target.txt (See Also))
- [Link without title](target.txt)
"""
        md_file.write_text(md_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move the markdown file into a subdirectory (docs/sub/)
        # This forces relative paths to change: target.txt → ../../target.txt
        sub_dir = temp_project_dir / "docs" / "sub"
        sub_dir.mkdir(parents=True)
        new_md_file = sub_dir / "guide.md"
        md_file.rename(new_md_file)

        # Simulate move event — trigger internal link update
        event = FileMovedEvent(str(md_file), str(new_md_file))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated_content = new_md_file.read_text()

        # Old relative path (target.txt) must NOT remain — it should be ../../target.txt now
        # Count occurrences of just "target.txt" that are NOT preceded by ../../
        # Easiest: check that ../../target.txt appears for all links
        assert (
            '../../target.txt "API Reference"' in updated_content
        ), "Double-quote title must be preserved with updated path"
        assert (
            "../../target.txt 'Quick Guide'" in updated_content
        ), "Single-quote title must be preserved with updated path"
        assert (
            "../../target.txt (See Also)" in updated_content
        ), "Parenthesized title must be preserved with updated path"
        assert (
            "[Link without title](../../target.txt)" in updated_content
        ), "Link without title should also be updated"

    def test_bug010_title_preserved_cross_depth_move(self, temp_project_dir):
        """
        PD-BUG-010: Title preservation when file moves across different depths.

        Moving a file from a/b/doc.md to c/doc.md should update relative links
        AND preserve any title attributes on those links.
        """
        # Create target file at project root level
        target_file = temp_project_dir / "resources" / "data.txt"
        target_file.parent.mkdir(parents=True, exist_ok=True)
        target_file.write_text("Data content")

        # Create markdown file at a/b/doc.md with link going up two levels
        deep_dir = temp_project_dir / "a" / "b"
        deep_dir.mkdir(parents=True)
        md_file = deep_dir / "doc.md"
        md_content = '# Doc\n\nSee [data](../../resources/data.txt "Important Data") for details.\n'
        md_file.write_text(md_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move file from a/b/doc.md to c/doc.md (shallower)
        shallow_dir = temp_project_dir / "c"
        shallow_dir.mkdir()
        new_md_file = shallow_dir / "doc.md"
        md_file.rename(new_md_file)

        # Simulate move event
        event = FileMovedEvent(str(md_file), str(new_md_file))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated_content = new_md_file.read_text()

        # From c/doc.md, path to resources/data.txt is ../resources/data.txt (one level up)
        # Old path was ../../resources/data.txt (two levels up) — must NOT remain
        assert (
            "../../resources/data.txt" not in updated_content
        ), "Old relative path should be replaced"
        assert "../resources/data.txt" in updated_content, "New relative path should be present"
        assert '"Important Data"' in updated_content, "Title attribute must be preserved after move"
        # Verify the complete link format
        assert (
            '[data](../resources/data.txt "Important Data")' in updated_content
        ), "Complete link with title must be correctly formed"


class TestBug025SubstringCorruption:
    """Regression tests for PD-BUG-025: Greedy str.replace corrupts file content.

    When non-markdown link types use content.replace(ref.link_target, new_target),
    a short path like 'config.yaml' can match as a substring inside a longer path
    like 'configs/config.yaml', corrupting the longer reference.
    """

    def test_bug025_yaml_substring_path_not_corrupted(self, temp_project_dir):
        """
        PD-BUG-025: A YAML file with both 'config.yaml' and 'configs/config.yaml'
        should only update each reference independently without substring corruption.

        The short path 'config.yaml' must NOT corrupt the longer 'configs/config.yaml'
        via unbounded str.replace.
        """
        # Create target files
        config_file = temp_project_dir / "config.yaml"
        config_file.write_text("main: true")

        configs_dir = temp_project_dir / "configs"
        configs_dir.mkdir()
        nested_config = configs_dir / "config.yaml"
        nested_config.write_text("nested: true")

        # Create a YAML file referencing both paths
        yaml_file = temp_project_dir / "setup.yaml"
        yaml_content = "main_config: config.yaml\n" "nested_config: configs/config.yaml\n"
        yaml_file.write_text(yaml_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move yaml_file into a subdirectory
        sub_dir = temp_project_dir / "deploy"
        sub_dir.mkdir()
        new_yaml_file = sub_dir / "setup.yaml"
        yaml_file.rename(new_yaml_file)

        # Simulate move event
        event = FileMovedEvent(str(yaml_file), str(new_yaml_file))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated_content = new_yaml_file.read_text()

        # The short path should be updated to go up one level
        assert (
            "main_config: ../config.yaml" in updated_content
        ), "Short path should be updated to ../config.yaml"

        # The longer path must NOT be corrupted by the short path replacement
        # Bug: str.replace("config.yaml", "../config.yaml") would turn
        # "configs/config.yaml" into "configs/../config.yaml"
        assert (
            "configs/../config.yaml" not in updated_content
        ), "Longer path must NOT be corrupted by substring replacement"
        assert (
            "../configs/config.yaml" in updated_content
        ), "Longer path should be independently updated to ../configs/config.yaml"

    def test_bug025_generic_quoted_substring_not_corrupted(self, temp_project_dir):
        """
        PD-BUG-025: A generic file (e.g., .ps1) with both a short quoted path
        and a longer quoted path containing the short one as a suffix should
        update each independently.
        """
        # Create target files
        helpers_file = temp_project_dir / "helpers.py"
        helpers_file.write_text("# helpers")

        utils_dir = temp_project_dir / "utils"
        utils_dir.mkdir()
        utils_helpers = utils_dir / "helpers.py"
        utils_helpers.write_text("# utils helpers")

        # Create a PowerShell script referencing both paths in quotes
        # (.ps1 is a monitored extension handled by GenericParser)
        script_file = temp_project_dir / "run.ps1"
        script_content = "# PowerShell script\n" '$a = "helpers.py"\n' '$b = "utils/helpers.py"\n'
        script_file.write_text(script_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move the script into a subdirectory
        sub_dir = temp_project_dir / "scripts"
        sub_dir.mkdir()
        new_script = sub_dir / "run.ps1"
        script_file.rename(new_script)

        # Simulate move event
        event = FileMovedEvent(str(script_file), str(new_script))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated_content = new_script.read_text()

        # The short path should be updated
        assert '"../helpers.py"' in updated_content, "Short path should be updated to ../helpers.py"

        # The longer path must NOT be corrupted
        assert (
            "utils/../helpers.py" not in updated_content
        ), "Longer path must NOT be corrupted by substring replacement"
        assert (
            '"../utils/helpers.py"' in updated_content
        ), "Longer path should be independently updated to ../utils/helpers.py"


class TestBug032RootRelativeWithinMovedFile:
    """Regression tests for PD-BUG-032: PowerShell script paths corrupted with spurious ../ prefix.

    When a .ps1 file is moved (e.g., as part of a directory move),
    _calculate_updated_relative_path() in reference_lookup.py incorrectly treats
    project-root-relative paths as source-relative, prepending spurious ../
    prefixes. Project-root-relative paths should remain unchanged.
    """

    def test_bug032_root_relative_path_unchanged_when_script_moves_deeper(self, temp_project_dir):
        """
        PD-BUG-032: A PS1 script in a subdirectory with a project-root-relative
        path like 'doc/documentation-tiers/assessments' must NOT
        get a spurious ../ prefix when the script moves to a deeper directory.
        Reproduces the real scenario: script is already deep in the tree.
        """
        # Create the target directory that the path points to
        target_dir = (
            temp_project_dir / "alpha-project" / "documentation-tiers" / "assessments"
        )
        target_dir.mkdir(parents=True)

        # Create a PS1 script in a subdirectory (realistic scenario)
        script_dir = temp_project_dir / "scripts" / "file-creation"
        script_dir.mkdir(parents=True)
        script_file = script_dir / "New-Assessment.ps1"
        script_content = (
            "# Script\n"
            '$OutputDir = "alpha-project/documentation-tiers/assessments"\n'
            'Write-Host "Creating assessment in $OutputDir"\n'
        )
        script_file.write_text(script_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move the script one level deeper (simulates directory restructure)
        deeper_dir = temp_project_dir / "scripts" / "file-creation" / "01-planning"
        deeper_dir.mkdir(parents=True)
        new_script = deeper_dir / "New-Assessment.ps1"
        script_file.rename(new_script)

        # Simulate move event
        event = FileMovedEvent(str(script_file), str(new_script))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated_content = new_script.read_text()

        # The project-root-relative path must NOT get ../ prefix
        assert (
            '"alpha-project/documentation-tiers/assessments"' in updated_content
        ), "Project-root-relative path should remain unchanged"
        assert (
            "../alpha-project" not in updated_content
        ), "Must NOT prepend spurious ../ to project-root-relative path"

    def test_bug032_multiple_root_relative_paths_all_preserved(self, temp_project_dir):
        """
        PD-BUG-032: A script in a subdirectory with multiple project-root-relative
        paths must keep ALL of them unchanged when the script moves deeper.
        """
        # Create target directories (project-root-relative targets)
        (temp_project_dir / "alpha-project" / "templates").mkdir(parents=True)
        (temp_project_dir / "alpha-project" / "state-tracking" / "permanent").mkdir(parents=True)

        # Create PS1 script in a subdirectory
        script_dir = temp_project_dir / "scripts" / "update"
        script_dir.mkdir(parents=True)
        script_file = script_dir / "Update-State.ps1"
        script_content = (
            "# Update script\n"
            '$TemplatePath = "alpha-project/templates"\n'
            '$TrackingFile = "alpha-project/state-tracking/permanent"\n'
        )
        script_file.write_text(script_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move the script one level deeper
        sub_dir = temp_project_dir / "scripts" / "update" / "v2"
        sub_dir.mkdir()
        new_script = sub_dir / "Update-State.ps1"
        script_file.rename(new_script)

        # Simulate move event
        event = FileMovedEvent(str(script_file), str(new_script))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated_content = new_script.read_text()

        # Both project-root-relative paths must remain unchanged
        assert (
            '"alpha-project/templates"' in updated_content
        ), "First project-root-relative path should remain unchanged"
        assert (
            '"alpha-project/state-tracking/permanent"' in updated_content
        ), "Second project-root-relative path should remain unchanged"
        assert (
            "../alpha-project/" not in updated_content
        ), "Must NOT prepend ../ to any project-root-relative path"

    def test_bug032_source_relative_path_still_updated_correctly(self, temp_project_dir):
        """
        PD-BUG-032 negative test: Normal source-relative paths (e.g., ../config.yaml)
        must still be updated correctly when the containing file moves.
        Ensures the fix doesn't break existing source-relative behavior.
        """
        # Create a config file at project root
        config_file = temp_project_dir / "config.yaml"
        config_file.write_text("key: value")

        # Create a markdown file in a subdirectory with a source-relative link
        sub_dir = temp_project_dir / "docs"
        sub_dir.mkdir()
        md_file = sub_dir / "guide.md"
        md_content = "# Guide\n\nSee [config](../config.yaml) for details.\n"
        md_file.write_text(md_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move the markdown file deeper
        deep_dir = temp_project_dir / "docs" / "guides" / "sub"
        deep_dir.mkdir(parents=True)
        new_md = deep_dir / "guide.md"
        md_file.rename(new_md)

        # Simulate move event
        event = FileMovedEvent(str(md_file), str(new_md))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated_content = new_md.read_text()

        # Source-relative path must be updated to reflect new depth
        assert (
            "../config.yaml" not in updated_content or "../../../config.yaml" in updated_content
        ), "Source-relative path should be updated to new relative depth"
        assert (
            "../../../config.yaml" in updated_content
        ), "Path should go up 3 levels from docs/guides/sub/ to reach config.yaml"


class TestBug033RegexNotRewrittenOnMove:
    """Regression tests for PD-BUG-033: PowerShell parser corrupts regex patterns on file move.

    When a .ps1 file containing regex patterns in single-quoted strings is moved,
    _calculate_updated_relative_path() should skip targets that don't resolve to
    real files/directories on disk. Regex patterns like '\\d+' resolve to
    non-existent paths and must be left unchanged.

    Uses exact patterns from the corrupted Update-FeatureTrackingFromAssessment.ps1.
    """

    def test_bug033_regex_with_digit_class_preserved_on_move(self, temp_project_dir):
        """Regex 'ART-ASS-\\d+-([0-9]+\\.[0-9]+\\.[0-9]+)-' must not be rewritten.

        Original line 124 was corrupted from:
            if ($fileName -match 'ART-ASS-\\d+-([0-9]+\\.[0-9]+\\.[0-9]+)-')
        To:
            if ($fileName -match 'doc/documentation-tiers/ART-ASS-/d+...')
        """
        # Create a .ps1 file with the exact regex pattern
        script_dir = temp_project_dir / "scripts" / "update"
        script_dir.mkdir(parents=True)
        script_file = script_dir / "Update-Tracking.ps1"
        script_content = (
            "# Script\n"
            "if ($fileName -match 'ART-ASS-\\d+-([0-9]+\\.[0-9]+\\.[0-9]+)-') {\n"
            "    $FeatureId = $matches[1]\n"
            "}\n"
        )
        script_file.write_text(script_content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move the script to a deeper directory
        deeper_dir = temp_project_dir / "scripts" / "update" / "sub"
        deeper_dir.mkdir()
        new_script = deeper_dir / "Update-Tracking.ps1"
        script_file.rename(new_script)

        # Simulate move event
        event = FileMovedEvent(str(script_file), str(new_script))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated_content = new_script.read_text()

        # Regex pattern must be unchanged
        assert (
            "ART-ASS-\\d+-([0-9]+\\.[0-9]+\\.[0-9]+)-" in updated_content
        ), "Regex pattern was corrupted during file move"

    def test_bug033_regex_with_escaped_brackets_preserved_on_move(self, temp_project_dir):
        r"""Regex '\[x\]\s+Tier\s+(\d+)' must not be rewritten.

        Original line 151 was corrupted from:
            if ($content -match '\[x\]\s+Tier\s+(\d+)')
        To:
            if ($content -match '../../../../../../../../[x/]/s+Tier/s+(/d+)')
        """
        script_dir = temp_project_dir / "scripts"
        script_dir.mkdir(parents=True)
        script_file = script_dir / "Parse-Tier.ps1"
        script_content = (
            "# Tier parser\n"
            "if ($content -match '\\[x\\]\\s+Tier\\s+(\\d+)') {\n"
            "    $tier = $matches[1]\n"
            "}\n"
        )
        script_file.write_text(script_content)

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        deeper_dir = temp_project_dir / "scripts" / "sub"
        deeper_dir.mkdir()
        new_script = deeper_dir / "Parse-Tier.ps1"
        script_file.rename(new_script)

        event = FileMovedEvent(str(script_file), str(new_script))
        service.handler._handle_file_moved(event)

        updated_content = new_script.read_text()

        assert (
            "\\[x\\]\\s+Tier\\s+(\\d+)" in updated_content
        ), "Regex pattern with escaped brackets was corrupted during file move"

    def test_bug033_real_path_still_updated_alongside_regex(self, temp_project_dir):
        """A file with BOTH regex patterns and real source-relative paths:
        only real paths get updated, regex stays unchanged.

        Uses a source-relative path (../config.yaml from scripts/) so the
        existence check resolves it correctly and the updater recalculates it.
        """
        # Create target file at project root (source-relative from scripts/)
        config_file = temp_project_dir / "config.yaml"
        config_file.write_text("key: value")

        script_dir = temp_project_dir / "scripts"
        script_dir.mkdir(parents=True)
        script_file = script_dir / "Mixed.ps1"
        script_content = (
            "# Mixed content\n"
            '$cfg = "../config.yaml"\n'
            "if ($id -match '(ART-ASS-\\d+)-') {\n"
            "    Write-Host $id\n"
            "}\n"
        )
        script_file.write_text(script_content)

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        deeper_dir = temp_project_dir / "scripts" / "sub"
        deeper_dir.mkdir()
        new_script = deeper_dir / "Mixed.ps1"
        script_file.rename(new_script)

        event = FileMovedEvent(str(script_file), str(new_script))
        service.handler._handle_file_moved(event)

        updated_content = new_script.read_text()

        # Source-relative path should be updated (target exists → recalculate)
        assert (
            "../../config.yaml" in updated_content
        ), "Source-relative path should be updated to reflect new depth"

        # Regex pattern should be unchanged (target doesn't exist → skip)
        assert "(ART-ASS-\\d+)-" in updated_content, "Regex pattern should be preserved unchanged"


class TestBug043PythonImportModuleLookup:
    """Regression tests for PD-BUG-043: Python dot-notation imports
    not resolved during reference lookup.

    The PythonParser stores import targets in extensionless slash notation
    (e.g., ``utils/helpers``), but single-file-move lookup only tried paths
    with the ``.py`` extension.  These tests verify that moving a ``.py``
    file to a different directory correctly updates all Python reference
    types: import statements, quoted paths, and comment references.
    """

    def test_bug043_single_file_move_updates_python_imports(self, temp_project_dir):
        """Moving a .py file across directories must update dot-notation imports."""
        # Setup: utils/helpers.py referenced by app/main.py
        utils_dir = temp_project_dir / "utils"
        utils_dir.mkdir()
        helpers_file = utils_dir / "helpers.py"
        helpers_file.write_text("def format_name(n): return n.title()\n")

        app_dir = temp_project_dir / "app"
        app_dir.mkdir()
        main_file = app_dir / "main.py"
        main_file.write_text(
            "#!/usr/bin/env python3\n"
            "from utils.helpers import format_name\n"
            "import utils.helpers\n"
            'HELPERS_PATH = "utils/helpers.py"\n'
            "# See utils/helpers.py for details\n"
        )

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move utils/helpers.py → core/helpers.py
        core_dir = temp_project_dir / "core"
        core_dir.mkdir()
        new_helpers = core_dir / "helpers.py"
        helpers_file.rename(new_helpers)

        event = FileMovedEvent(str(helpers_file), str(new_helpers))
        service.handler._handle_file_moved(event)

        updated = main_file.read_text()

        # Import statements must be updated (dot notation)
        assert (
            "from core.helpers import format_name" in updated
        ), "from-import should update to core.helpers"
        assert "import core.helpers" in updated, "bare import should update to core.helpers"
        # Old imports must be gone
        assert (
            "utils.helpers" not in updated
        ), "no reference to old module utils.helpers should remain"

    def test_bug043_quoted_and_comment_refs_also_updated(self, temp_project_dir):
        """Quoted paths and comment references must also update on .py file move."""
        utils_dir = temp_project_dir / "utils"
        utils_dir.mkdir()
        helpers_file = utils_dir / "helpers.py"
        helpers_file.write_text("def greet(): pass\n")

        app_dir = temp_project_dir / "app"
        app_dir.mkdir()
        runner_file = app_dir / "runner.py"
        runner_file.write_text(
            'helper_file = "utils/helpers.py"\n' "# utils/helpers.py contains shared utilities\n"
        )

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        core_dir = temp_project_dir / "core"
        core_dir.mkdir()
        new_helpers = core_dir / "helpers.py"
        helpers_file.rename(new_helpers)

        event = FileMovedEvent(str(helpers_file), str(new_helpers))
        service.handler._handle_file_moved(event)

        updated = runner_file.read_text()

        assert "core/helpers.py" in updated, "quoted path should update to core/helpers.py"
        assert (
            "utils/helpers.py" not in updated
        ), "no reference to old path utils/helpers.py should remain"


class TestBug045PythonModuleUsageUpdate:
    """Regression tests for PD-BUG-045: Module usage sites not updated when import changes.

    When a Python file is moved and import statements are updated (e.g.,
    ``import utils.helpers`` → ``import core.helpers``), usage sites on other
    lines (e.g., ``utils.helpers.format_name()``) must also be updated.
    """

    def test_bug045_module_usage_updated_on_file_move(self, temp_project_dir):
        """Module usage (utils.helpers.func()) must update when import updates."""
        utils_dir = temp_project_dir / "utils"
        utils_dir.mkdir()
        helpers_file = utils_dir / "helpers.py"
        helpers_file.write_text("def format_name(n): return n.title()\n")

        app_dir = temp_project_dir / "app"
        app_dir.mkdir()
        runner_file = app_dir / "runner.py"
        runner_file.write_text(
            "import utils.helpers\n" "\n" "def run():\n" "    utils.helpers.format_name('runner')\n"
        )

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        core_dir = temp_project_dir / "core"
        core_dir.mkdir()
        new_helpers = core_dir / "helpers.py"
        helpers_file.rename(new_helpers)

        event = FileMovedEvent(str(helpers_file), str(new_helpers))
        service.handler._handle_file_moved(event)

        updated = runner_file.read_text()

        assert "import core.helpers" in updated, "import statement should update to core.helpers"
        assert (
            "core.helpers.format_name" in updated
        ), "module usage should update to core.helpers.format_name"
        assert (
            "utils.helpers" not in updated
        ), "no reference to old module utils.helpers should remain"

    def test_bug045_multiple_usage_sites_updated(self, temp_project_dir):
        """All usage sites of the module must be updated, not just the import."""
        utils_dir = temp_project_dir / "utils"
        utils_dir.mkdir()
        helpers_file = utils_dir / "helpers.py"
        helpers_file.write_text("def a(): pass\ndef b(): pass\n")

        app_dir = temp_project_dir / "app"
        app_dir.mkdir()
        main_file = app_dir / "main.py"
        main_file.write_text(
            "import utils.helpers\n"
            "\n"
            "x = utils.helpers.a()\n"
            "y = utils.helpers.b()\n"
            "print(utils.helpers)\n"
        )

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        core_dir = temp_project_dir / "core"
        core_dir.mkdir()
        new_helpers = core_dir / "helpers.py"
        helpers_file.rename(new_helpers)

        event = FileMovedEvent(str(helpers_file), str(new_helpers))
        service.handler._handle_file_moved(event)

        updated = main_file.read_text()

        assert (
            updated.count("core.helpers") >= 4
        ), f"expected at least 4 occurrences of core.helpers, got {updated.count('core.helpers')}"
        assert (
            "utils.helpers" not in updated
        ), "no reference to old module utils.helpers should remain"

    def test_bug045_no_false_positive_on_substring_module(self, temp_project_dir):
        """Module replacement must not affect substring matches (e.g., my_utils.helpers)."""
        utils_dir = temp_project_dir / "utils"
        utils_dir.mkdir()
        helpers_file = utils_dir / "helpers.py"
        helpers_file.write_text("def func(): pass\n")

        app_dir = temp_project_dir / "app"
        app_dir.mkdir()
        main_file = app_dir / "main.py"
        main_file.write_text(
            "import utils.helpers\n" "my_utils_helpers = 'unrelated'\n" "utils.helpers.func()\n"
        )

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        core_dir = temp_project_dir / "core"
        core_dir.mkdir()
        new_helpers = core_dir / "helpers.py"
        helpers_file.rename(new_helpers)

        event = FileMovedEvent(str(helpers_file), str(new_helpers))
        service.handler._handle_file_moved(event)

        updated = main_file.read_text()

        assert "import core.helpers" in updated
        assert "core.helpers.func()" in updated
        # The unrelated variable name must NOT be changed
        assert (
            "my_utils_helpers" in updated
        ), "substring 'my_utils_helpers' must not be affected by module rename"
