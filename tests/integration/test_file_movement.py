"""
Integration Tests for File Movement (FM Test Cases)

This module implements the FM test cases from our comprehensive test documentation,
focusing on file movement detection and link updates.

Test Cases Implemented:
- FM-001: Single file rename (same directory)
- FM-002: File move to different directory
- FM-003: File move with rename
- FM-004: Directory rename affecting multiple files
- FM-005: Nested directory movement
"""

import time
from pathlib import Path

import pytest
from watchdog.events import DirMovedEvent, FileMovedEvent

from linkwatcher.service import LinkWatcherService


class TestFileMovement:
    """Integration tests for file movement scenarios."""

    def test_fm_001_single_file_rename(self, temp_project_dir, file_helper):
        """
        FM-001: Single file rename (same directory)

        Test Case: Rename test.txt -> renamed.txt in same directory
        Expected: All references updated to renamed.txt
        Priority: Critical
        """
        # Setup test files
        original_file = temp_project_dir / "test.txt"
        original_file.write_text("Original content")

        # Create files with references
        md_file = temp_project_dir / "doc.md"
        md_content = """# Documentation

See [test file](test.txt) for details.
Also check "test.txt" for more info.
"""
        md_file.write_text(md_content)

        yaml_file = temp_project_dir / "config.yaml"
        yaml_content = """
settings:
  help_file: test.txt
  reference: "test.txt"
"""
        yaml_file.write_text(yaml_content)

        # Initialize service and perform initial scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify initial state
        stats = service.link_db.get_stats()
        assert stats["total_references"] >= 2

        # Perform file rename
        new_file = temp_project_dir / "renamed.txt"
        original_file.rename(new_file)

        # Simulate file system event processing
        move_event = FileMovedEvent(str(original_file), str(new_file))
        service.handler.on_moved(move_event)

        # Verify references were updated
        md_updated = md_file.read_text()
        yaml_updated = yaml_file.read_text()

        assert "renamed.txt" in md_updated
        assert "test.txt" not in md_updated
        assert "renamed.txt" in yaml_updated

        # Verify database was updated
        references = service.link_db.get_references_to_file("renamed.txt")
        assert len(references) >= 2

        old_references = service.link_db.get_references_to_file("test.txt")
        assert len(old_references) == 0

    def test_fm_002_file_move_different_directory(self, temp_project_dir, file_helper):
        """
        FM-002: File move to different directory

        Test Case: Move docs/file.txt -> assets/file.txt
        Expected: All references updated with new path
        Priority: Critical
        """
        # Setup directory structure
        docs_dir = temp_project_dir / "docs"
        assets_dir = temp_project_dir / "assets"
        docs_dir.mkdir()
        assets_dir.mkdir()

        # Create original file
        original_file = docs_dir / "file.txt"
        original_file.write_text("File content")

        # Create files with references
        readme = temp_project_dir / "README.md"
        readme_content = """# Project

See [documentation](docs/file.txt) for setup.
Configuration in "docs/file.txt".
"""
        readme.write_text(readme_content)

        # Create reference from within docs directory
        guide = docs_dir / "guide.md"
        guide_content = """# Guide

Refer to [file](file.txt) in same directory.
"""
        guide.write_text(guide_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Perform file move
        new_file = assets_dir / "file.txt"
        original_file.rename(new_file)

        # Process move event
        move_event = FileMovedEvent(str(original_file), str(new_file))
        service.handler.on_moved(move_event)

        # Verify references were updated
        readme_updated = readme.read_text()
        guide_updated = guide.read_text()

        # README should reference assets/file.txt
        assert "assets/file.txt" in readme_updated
        assert "docs/file.txt" not in readme_updated

        # Guide should reference ../assets/file.txt (relative path)
        assert "../assets/file.txt" in guide_updated or "assets/file.txt" in guide_updated
        # Verify the old link target is not present as a link (but may appear in text)
        assert "[file](file.txt)" not in guide_updated

    def test_fm_003_file_move_with_rename(self, temp_project_dir, file_helper):
        """
        FM-003: File move with rename

        Test Case: Move docs/old.txt -> assets/new.txt
        Expected: All references updated to new path and name
        Priority: Critical
        """
        # Setup directory structure
        docs_dir = temp_project_dir / "docs"
        assets_dir = temp_project_dir / "assets"
        docs_dir.mkdir()
        assets_dir.mkdir()

        # Create original file
        original_file = docs_dir / "old.txt"
        original_file.write_text("Original content")

        # Create multiple files with references
        files_with_refs = []

        # README with markdown link
        readme = temp_project_dir / "README.md"
        readme.write_text("# Project\n\nSee [old docs](docs/old.txt) for legacy info.")
        files_with_refs.append(readme)

        # Config with YAML reference
        config = temp_project_dir / "config.yaml"
        config.write_text("legacy_file: docs/old.txt\nother: value")
        files_with_refs.append(config)

        # JSON config
        json_config = temp_project_dir / "settings.json"
        json_config.write_text('{"legacy": "docs/old.txt", "version": 1}')
        files_with_refs.append(json_config)

        # Python file with string reference
        py_file = temp_project_dir / "main.py"
        py_file.write_text('# Configuration in "docs/old.txt"\nconfig_file = "docs/old.txt"')
        files_with_refs.append(py_file)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify initial references
        initial_refs = service.link_db.get_references_to_file("docs/old.txt")
        assert len(initial_refs) >= 3  # Should find multiple references

        # Perform move with rename
        new_file = assets_dir / "new.txt"
        original_file.rename(new_file)

        # Process move event
        move_event = FileMovedEvent(str(original_file), str(new_file))
        service.handler.on_moved(move_event)

        # Verify all references were updated
        readme_updated = readme.read_text()
        config_updated = config.read_text()
        json_updated = json_config.read_text()
        py_updated = py_file.read_text()

        # Check that new path is present and old path is gone
        assert "assets/new.txt" in readme_updated
        assert "docs/old.txt" not in readme_updated

        assert "assets/new.txt" in config_updated
        assert "docs/old.txt" not in config_updated

        assert "assets/new.txt" in json_updated
        assert "docs/old.txt" not in json_updated

        assert "assets/new.txt" in py_updated
        assert "docs/old.txt" not in py_updated

        # Verify database state
        new_refs = service.link_db.get_references_to_file("assets/new.txt")
        old_refs = service.link_db.get_references_to_file("docs/old.txt")

        assert len(new_refs) >= 3
        assert len(old_refs) == 0

    def test_fm_004_directory_rename(self, temp_project_dir, file_helper):
        """
        FM-004: Directory rename affecting multiple files

        Test Case: Rename docs/ -> documentation/
        Expected: All references to files in directory updated
        Priority: Critical
        """
        # Setup directory with multiple files
        docs_dir = temp_project_dir / "docs"
        docs_dir.mkdir()

        # Create multiple files in docs directory
        file1 = docs_dir / "guide.md"
        file1.write_text("# Guide\nContent here")

        file2 = docs_dir / "api.md"
        file2.write_text("# API\nAPI documentation")

        file3 = docs_dir / "config.yaml"
        file3.write_text("setting: value")

        # Create files with references to docs files
        readme = temp_project_dir / "README.md"
        readme_content = """# Project

- [User Guide](docs/guide.md)
- [API Docs](docs/api.md)
- Configuration: "docs/config.yaml"
"""
        readme.write_text(readme_content)

        main_py = temp_project_dir / "main.py"
        main_py.write_text('# See docs/guide.md and docs/api.md\nconfig = "docs/config.yaml"')

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify initial references
        stats = service.link_db.get_stats()
        assert stats["total_references"] >= 5  # Multiple references to docs files

        # Rename directory
        new_docs_dir = temp_project_dir / "documentation"
        docs_dir.rename(new_docs_dir)

        # Process directory move event
        move_event = DirMovedEvent(str(docs_dir), str(new_docs_dir))
        service.handler.on_moved(move_event)

        # Verify all references were updated
        readme_updated = readme.read_text()
        main_updated = main_py.read_text()

        # Check README updates
        assert "documentation/guide.md" in readme_updated
        assert "documentation/api.md" in readme_updated
        assert "documentation/config.yaml" in readme_updated
        assert "docs/" not in readme_updated

        # Check Python file updates
        assert "documentation/guide.md" in main_updated
        assert "documentation/api.md" in main_updated
        assert "documentation/config.yaml" in main_updated
        assert "docs/" not in main_updated

        # Verify database was updated
        guide_refs = service.link_db.get_references_to_file("documentation/guide.md")
        api_refs = service.link_db.get_references_to_file("documentation/api.md")
        config_refs = service.link_db.get_references_to_file("documentation/config.yaml")

        assert len(guide_refs) >= 2
        assert len(api_refs) >= 2
        assert len(config_refs) >= 2

        # Verify old references are gone
        old_guide_refs = service.link_db.get_references_to_file("docs/guide.md")
        assert len(old_guide_refs) == 0

    def test_fm_005_nested_directory_movement(self, temp_project_dir, file_helper):
        """
        FM-005: Nested directory movement

        Test Case: Move src/utils/ -> src/helpers/
        Expected: All nested file references updated
        Priority: High
        """
        # Setup nested directory structure
        src_dir = temp_project_dir / "src"
        src_dir.mkdir()
        utils_dir = src_dir / "utils"
        utils_dir.mkdir()

        # Create nested files
        string_utils = utils_dir / "string_utils.py"
        string_utils.write_text("def format_string(): pass")

        file_utils = utils_dir / "file_utils.py"
        file_utils.write_text("def read_file(): pass")

        # Create subdirectory in utils
        common_dir = utils_dir / "common"
        common_dir.mkdir()
        helpers = common_dir / "helpers.py"
        helpers.write_text("def helper_func(): pass")

        # Create files with references
        main_py = temp_project_dir / "main.py"
        main_content = """# Main application
from src.utils.string_utils import format_string
from src.utils.file_utils import read_file
# Also see "src/utils/common/helpers.py"
"""
        main_py.write_text(main_content)

        readme = temp_project_dir / "README.md"
        readme_content = """# Project

Utilities:
- [String Utils](src/utils/string_utils.py)
- [File Utils](src/utils/file_utils.py)
- [Helpers](src/utils/common/helpers.py)
"""
        readme.write_text(readme_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move utils directory to helpers
        helpers_dir = src_dir / "helpers"
        utils_dir.rename(helpers_dir)

        # Process directory move
        move_event = DirMovedEvent(str(utils_dir), str(helpers_dir))
        service.handler.on_moved(move_event)

        # Verify references were updated
        main_updated = main_py.read_text()
        readme_updated = readme.read_text()

        # Check main.py updates
        assert "src.helpers.string_utils" in main_updated
        assert "src.helpers.file_utils" in main_updated
        assert "src/helpers/common/helpers.py" in main_updated
        assert "src/utils/" not in main_updated

        # Check README updates
        assert "src/helpers/string_utils.py" in readme_updated
        assert "src/helpers/file_utils.py" in readme_updated
        assert "src/helpers/common/helpers.py" in readme_updated
        assert "src/utils/" not in readme_updated

        # Verify database reflects the changes
        string_refs = service.link_db.get_references_to_file("src/helpers/string_utils.py")
        file_refs = service.link_db.get_references_to_file("src/helpers/file_utils.py")
        helper_refs = service.link_db.get_references_to_file("src/helpers/common/helpers.py")

        assert len(string_refs) >= 1
        assert len(file_refs) >= 1
        assert len(helper_refs) >= 1


class TestFileMovementEdgeCases:
    """Edge cases and error scenarios for file movement."""

    def test_move_nonexistent_file(self, temp_project_dir):
        """Test handling of move events for non-existent files."""
        service = LinkWatcherService(str(temp_project_dir))

        # Try to process move event for non-existent file
        old_path = str(temp_project_dir / "nonexistent.txt")
        new_path = str(temp_project_dir / "new.txt")

        # Should not crash
        move_event = FileMovedEvent(old_path, new_path)
        service.handler.on_moved(move_event)

        # Database should remain clean
        stats = service.link_db.get_stats()
        assert stats["total_references"] == 0

    def test_move_to_existing_file(self, temp_project_dir):
        """Test handling of move to existing file (overwrite scenario)."""
        # Create two files
        file1 = temp_project_dir / "file1.txt"
        file1.write_text("Content 1")

        file2 = temp_project_dir / "file2.txt"
        file2.write_text("Content 2")

        # Create reference to file1
        readme = temp_project_dir / "README.md"
        readme.write_text("See [file1](file1.txt)")

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move file1 to file2 (overwrite)
        file1.replace(file2)

        # Process move event
        move_event = FileMovedEvent(str(file1), str(file2))
        service.handler.on_moved(move_event)

        # Reference should be updated
        readme_updated = readme.read_text()
        assert "file2.txt" in readme_updated
        assert "file1.txt" not in readme_updated
