"""
Test utilities for LinkWatcher tests.

This module provides common utilities and helpers for testing.
"""

import shutil
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from linkwatcher.models import LinkReference
from linkwatcher.service import LinkWatcherService


class TestProjectBuilder:
    """Builder class for creating test project structures."""

    def __init__(self, base_path: Path):
        self.base_path = Path(base_path)
        self.files = {}
        self.directories = set()

    def add_directory(self, path: str) -> "TestProjectBuilder":
        """Add a directory to the project structure."""
        dir_path = self.base_path / path
        dir_path.mkdir(parents=True, exist_ok=True)
        self.directories.add(path)
        return self

    def add_file(self, path: str, content: str) -> "TestProjectBuilder":
        """Add a file with content to the project structure."""
        file_path = self.base_path / path
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content)
        self.files[path] = content
        return self

    def add_markdown_file(
        self, path: str, title: str, links: List[Tuple[str, str]] = None
    ) -> "TestProjectBuilder":
        """Add a markdown file with specified links."""
        content = f"# {title}\n\n"

        if links:
            content += "## Links\n\n"
            for link_text, link_target in links:
                content += f"- [{link_text}]({link_target})\n"
            content += "\n"

        return self.add_file(path, content)

    def add_yaml_file(self, path: str, data: Dict) -> "TestProjectBuilder":
        """Add a YAML file with specified data."""
        import yaml

        content = yaml.dump(data, default_flow_style=False)
        return self.add_file(path, content)

    def add_json_file(self, path: str, data: Dict) -> "TestProjectBuilder":
        """Add a JSON file with specified data."""
        import json

        content = json.dumps(data, indent=2)
        return self.add_file(path, content)

    def add_python_file(
        self, path: str, imports: List[str] = None, file_refs: List[str] = None
    ) -> "TestProjectBuilder":
        """Add a Python file with imports and file references."""
        content = '"""Generated Python file for testing."""\n\n'

        if imports:
            for imp in imports:
                content += f"import {imp}\n"
            content += "\n"

        if file_refs:
            content += "# File references\n"
            for i, ref in enumerate(file_refs):
                content += f'FILE_{i} = "{ref}"\n'
            content += "\n"

        return self.add_file(path, content)

    def build(self) -> Dict[str, Path]:
        """Build the project and return file paths."""
        result = {}
        for file_path in self.files.keys():
            result[file_path] = self.base_path / file_path
        return result


class LinkReferenceBuilder:
    """Builder class for creating LinkReference objects."""

    def __init__(self):
        self.references = []

    def add_reference(
        self,
        file_path: str,
        line: int,
        col_start: int,
        col_end: int,
        link_text: str,
        link_target: str,
        link_type: str,
    ) -> "LinkReferenceBuilder":
        """Add a link reference."""
        ref = LinkReference(
            file_path=file_path,
            line_number=line,
            column_start=col_start,
            column_end=col_end,
            link_text=link_text,
            link_target=link_target,
            link_type=link_type,
        )
        self.references.append(ref)
        return self

    def add_markdown_link(
        self, file_path: str, line: int, link_text: str, link_target: str
    ) -> "LinkReferenceBuilder":
        """Add a markdown link reference."""
        return self.add_reference(
            file_path=file_path,
            line_number=line,
            column_start=0,
            column_end=len(f"[{link_text}]({link_target})"),
            link_text=link_text,
            link_target=link_target,
            link_type="markdown",
        )

    def build(self) -> List[LinkReference]:
        """Build and return the list of references."""
        return self.references.copy()


class PerformanceTimer:
    """Context manager for timing operations."""

    def __init__(self, description: str = "Operation"):
        self.description = description
        self.start_time = None
        self.end_time = None
        self.duration = None

    def __enter__(self):
        self.start_time = time.time()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.end_time = time.time()
        self.duration = self.end_time - self.start_time
        print(f"{self.description} took {self.duration:.3f} seconds")


@contextmanager
def temporary_project(structure: Dict[str, str] = None):
    """
    Context manager for creating a temporary project directory.

    Args:
        structure: Dict mapping file paths to content

    Yields:
        Path to temporary project directory
    """
    temp_dir = tempfile.mkdtemp()
    try:
        project_path = Path(temp_dir)

        if structure:
            for file_path, content in structure.items():
                full_path = project_path / file_path
                full_path.parent.mkdir(parents=True, exist_ok=True)
                full_path.write_text(content)

        yield project_path
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


def create_sample_project(base_path: Path) -> Dict[str, Path]:
    """Create a sample project structure for testing."""
    builder = TestProjectBuilder(base_path)

    # Create directory structure
    builder.add_directory("docs")
    builder.add_directory("src")
    builder.add_directory("config")
    builder.add_directory("tests")

    # Add files with cross-references
    builder.add_markdown_file(
        "README.md",
        "Project README",
        [
            ("User Guide", "docs/guide.md"),
            ("API Reference", "docs/api.md"),
            ("Configuration", "config/settings.yaml"),
        ],
    )

    builder.add_markdown_file(
        "docs/guide.md",
        "User Guide",
        [
            ("API Reference", "api.md"),
            ("Configuration", "../config/settings.yaml"),
            ("Main Script", "../src/main.py"),
        ],
    )

    builder.add_markdown_file(
        "docs/api.md",
        "API Reference",
        [("User Guide", "guide.md"), ("Examples", "../examples/basic.py")],
    )

    builder.add_yaml_file(
        "config/settings.yaml",
        {
            "database": {"url": "sqlite:///data/app.db", "schema": "schema.sql"},
            "logging": {"file": "logs/app.log", "level": "INFO"},
            "templates": {"directory": "templates/", "main": "templates/main.html"},
        },
    )

    builder.add_python_file(
        "src/main.py",
        imports=["os", "sys", "json"],
        file_refs=["config/settings.yaml", "data/users.csv", "templates/main.html"],
    )

    builder.add_json_file(
        "config/database.json",
        {
            "connections": {"primary": "data/primary.db", "backup": "data/backup.db"},
            "migrations": "migrations/",
            "schema": "schema/database.sql",
        },
    )

    return builder.build()


def assert_references_equal(actual: List[LinkReference], expected: List[LinkReference]):
    """Assert that two lists of references are equal."""
    assert len(actual) == len(expected), f"Expected {len(expected)} references, got {len(actual)}"

    # Sort both lists for comparison
    actual_sorted = sorted(actual, key=lambda r: (r.file_path, r.line_number, r.link_target))
    expected_sorted = sorted(expected, key=lambda r: (r.file_path, r.line_number, r.link_target))

    for i, (actual_ref, expected_ref) in enumerate(zip(actual_sorted, expected_sorted)):
        assert actual_ref.file_path == expected_ref.file_path, f"Reference {i}: file_path mismatch"
        assert (
            actual_ref.link_target == expected_ref.link_target
        ), f"Reference {i}: link_target mismatch"
        assert actual_ref.link_type == expected_ref.link_type, f"Reference {i}: link_type mismatch"


def assert_file_contains(file_path: Path, expected_content: str):
    """Assert that a file contains the expected content."""
    actual_content = file_path.read_text()
    assert expected_content in actual_content, f"Expected content not found in {file_path}"


def assert_file_not_contains(file_path: Path, unexpected_content: str):
    """Assert that a file does not contain the unexpected content."""
    actual_content = file_path.read_text()
    assert unexpected_content not in actual_content, f"Unexpected content found in {file_path}"


def simulate_file_move(
    service: LinkWatcherService, old_path: str, new_path: str, is_directory: bool = False
):
    """Simulate a file move operation for testing."""
    service.handler.on_moved(None, old_path, new_path, is_directory)


def wait_for_processing(service: LinkWatcherService, timeout: float = 5.0):
    """Wait for the service to finish processing events."""
    # This is a simple implementation - in a real scenario you might need
    # to check for specific conditions or use proper synchronization
    time.sleep(0.1)  # Give time for processing


class MockFileSystemEvent:
    """Mock file system event for testing."""

    def __init__(self, src_path: str, dest_path: str = None, is_directory: bool = False):
        self.src_path = src_path
        self.dest_path = dest_path
        self.is_directory = is_directory


def create_large_project(
    base_path: Path, num_files: int = 100, files_per_dir: int = 10
) -> List[Path]:
    """Create a large project structure for performance testing."""
    created_files = []

    # Create directory structure
    num_dirs = (num_files + files_per_dir - 1) // files_per_dir

    for dir_idx in range(num_dirs):
        dir_path = base_path / f"dir_{dir_idx:03d}"
        dir_path.mkdir(exist_ok=True)

        # Create files in this directory
        start_file = dir_idx * files_per_dir
        end_file = min(start_file + files_per_dir, num_files)

        for file_idx in range(start_file, end_file):
            file_path = dir_path / f"file_{file_idx:04d}.md"

            # Create content with references to other files
            content = f"# File {file_idx}\n\n"

            # Add some cross-references
            for ref_idx in range(min(3, num_files)):
                target_idx = (file_idx + ref_idx + 1) % num_files
                target_dir = target_idx // files_per_dir
                target_file = f"dir_{target_dir:03d}/file_{target_idx:04d}.md"
                content += f"- [Reference {ref_idx}]({target_file})\n"

            file_path.write_text(content)
            created_files.append(file_path)

    return created_files


# Test data generators
def generate_markdown_with_links(num_links: int = 5) -> str:
    """Generate markdown content with specified number of links."""
    content = "# Test Document\n\n"

    for i in range(num_links):
        content += f"- [Link {i}](file_{i}.txt)\n"

    content += "\n## Quoted References\n\n"
    for i in range(num_links):
        content += f'See "quoted_file_{i}.json" for details.\n'

    return content


def generate_yaml_with_file_refs(num_refs: int = 5) -> str:
    """Generate YAML content with file references."""
    import yaml

    data = {
        "files": {f"file_{i}": f"path/to/file_{i}.txt" for i in range(num_refs)},
        "config": {"main": "config/main.yaml", "database": "config/db.json"},
        "templates": [f"template_{i}.html" for i in range(3)],
    }

    return yaml.dump(data, default_flow_style=False)


def generate_json_with_file_refs(num_refs: int = 5) -> str:
    """Generate JSON content with file references."""
    import json

    data = {
        "files": {f"file_{i}": f"data/file_{i}.json" for i in range(num_refs)},
        "assets": {"css": "styles/main.css", "js": "scripts/app.js", "images": "images/"},
        "references": [f"ref_{i}.txt" for i in range(3)],
    }

    return json.dumps(data, indent=2)
