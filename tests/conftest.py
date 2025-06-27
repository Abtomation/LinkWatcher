"""
Pytest configuration and fixtures for LinkWatcher tests.

This module provides common fixtures and test utilities used across
the test suite.
"""

import shutil
import tempfile
from pathlib import Path
from typing import Dict, List

import pytest

from linkwatcher import LinkDatabase, LinkParser, LinkUpdater, LinkWatcherService
from linkwatcher.config import TESTING_CONFIG, LinkWatcherConfig


@pytest.fixture
def temp_project_dir():
    """Create a temporary project directory for testing."""
    temp_dir = tempfile.mkdtemp()
    yield Path(temp_dir)
    shutil.rmtree(temp_dir, ignore_errors=True)


@pytest.fixture
def sample_files(temp_project_dir):
    """Create sample files for testing."""
    files = {}

    # Create markdown file with links
    md_content = """# Test Document

This is a [link to file](test.txt) and another [link](other/file.md).

Also reference to "quoted_file.py" and standalone_file.json.
"""
    md_file = temp_project_dir / "test.md"
    md_file.write_text(md_content)
    files["markdown"] = md_file

    # Create target files
    txt_file = temp_project_dir / "test.txt"
    txt_file.write_text("Test content")
    files["text"] = txt_file

    # Create other directory and file
    other_dir = temp_project_dir / "other"
    other_dir.mkdir()
    other_file = other_dir / "file.md"
    other_file.write_text("# Other file")
    files["other"] = other_file

    # Create Python file
    py_file = temp_project_dir / "quoted_file.py"
    py_file.write_text("# Python file")
    files["python"] = py_file

    # Create JSON file
    json_file = temp_project_dir / "standalone_file.json"
    json_file.write_text('{"test": "data"}')
    files["json"] = json_file

    return files


@pytest.fixture
def link_database():
    """Create a fresh LinkDatabase instance."""
    return LinkDatabase()


@pytest.fixture
def link_parser():
    """Create a LinkParser instance."""
    return LinkParser()


@pytest.fixture
def link_updater():
    """Create a LinkUpdater instance configured for testing."""
    updater = LinkUpdater()
    updater.set_dry_run(True)  # Safe for testing
    return updater


@pytest.fixture
def test_config():
    """Create a test configuration."""
    return TESTING_CONFIG


@pytest.fixture
def link_service(temp_project_dir, test_config):
    """Create a LinkWatcherService instance for testing."""
    service = LinkWatcherService(str(temp_project_dir))
    # Apply test configuration
    service.handler.monitored_extensions = test_config.monitored_extensions
    service.handler.ignored_dirs = test_config.ignored_directories
    service.updater.set_dry_run(test_config.dry_run_mode)
    return service


@pytest.fixture
def populated_database(link_database, link_parser, sample_files):
    """Create a database populated with sample file links."""
    for file_path in sample_files.values():
        if file_path.suffix in {".md", ".txt"}:
            references = link_parser.parse_file(str(file_path))
            for ref in references:
                link_database.add_link(ref)
    return link_database


class TestFileHelper:
    """Helper class for creating test files."""

    @staticmethod
    def create_markdown_file(path: Path, content: str = None) -> Path:
        """Create a markdown file with optional content."""
        if content is None:
            content = "# Test\n\nThis is a [test link](test.txt)."
        path.write_text(content)
        return path

    @staticmethod
    def create_yaml_file(path: Path, data: Dict = None) -> Path:
        """Create a YAML file with optional data."""
        if data is None:
            data = {"file_ref": "test.txt", "other": "value"}

        import yaml

        content = yaml.dump(data)
        path.write_text(content)
        return path

    @staticmethod
    def create_json_file(path: Path, data: Dict = None) -> Path:
        """Create a JSON file with optional data."""
        if data is None:
            data = {"file_ref": "test.txt", "other": "value"}

        import json

        content = json.dumps(data, indent=2)
        path.write_text(content)
        return path


@pytest.fixture
def file_helper():
    """Provide the TestFileHelper class."""
    return TestFileHelper


# Custom assertions for testing
def assert_reference_found(references: List, target: str, link_type: str = None):
    """Assert that a reference to a target is found."""
    found = any(ref.link_target == target for ref in references)
    assert found, f"Reference to '{target}' not found in {[ref.link_target for ref in references]}"

    if link_type:
        found_with_type = any(
            ref.link_target == target and ref.link_type == link_type for ref in references
        )
        assert found_with_type, f"Reference to '{target}' with type '{link_type}' not found"


def assert_reference_not_found(references: List, target: str):
    """Assert that a reference to a target is not found."""
    found = any(ref.link_target == target for ref in references)
    assert not found, f"Reference to '{target}' unexpectedly found"


# Add custom assertions to pytest namespace
pytest.assert_reference_found = assert_reference_found
pytest.assert_reference_not_found = assert_reference_not_found
