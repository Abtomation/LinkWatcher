"""
Test configuration and environment setup.

This module provides configuration for different test environments
and common test settings.
"""

import os
from pathlib import Path

from linkwatcher.config import LinkWatcherConfig

# Test environment configurations
TEST_ENVIRONMENTS = {
    "unit": {
        "description": "Unit test environment",
        "config": LinkWatcherConfig(
            monitored_extensions={".md", ".txt", ".yaml", ".json"},
            ignored_directories={".git", "node_modules"},
            dry_run_mode=True,
            create_backups=False,
            log_level="DEBUG",
            show_statistics=False,
            colored_output=False,
        ),
    },
    "integration": {
        "description": "Integration test environment",
        "config": LinkWatcherConfig(
            monitored_extensions={".md", ".txt", ".yaml", ".json", ".py"},
            ignored_directories={".git", "node_modules", "__pycache__"},
            dry_run_mode=False,  # Actually modify files for integration tests
            create_backups=True,
            log_level="INFO",
            show_statistics=True,
            colored_output=False,
        ),
    },
    "performance": {
        "description": "Performance test environment",
        "config": LinkWatcherConfig(
            monitored_extensions={".md", ".txt", ".yaml", ".json", ".py"},
            ignored_directories={".git", "node_modules", "__pycache__"},
            dry_run_mode=False,
            create_backups=False,  # Skip backups for performance
            log_level="WARNING",  # Minimal logging
            show_statistics=True,
            colored_output=False,
            initial_scan_enabled=True,
            max_file_size_mb=50,  # Allow larger files for performance testing
        ),
    },
    "manual": {
        "description": "Manual test environment",
        "config": LinkWatcherConfig(
            monitored_extensions={".md", ".txt", ".yaml", ".json", ".py", ".dart"},
            ignored_directories={".git", ".dart_tool", "node_modules", ".vscode", "__pycache__"},
            dry_run_mode=False,
            create_backups=True,
            log_level="INFO",
            show_statistics=True,
            colored_output=True,
            initial_scan_enabled=True,
        ),
    },
}


def get_test_config(environment: str = "unit") -> LinkWatcherConfig:
    """Get configuration for specified test environment."""
    if environment not in TEST_ENVIRONMENTS:
        raise ValueError(f"Unknown test environment: {environment}")

    return TEST_ENVIRONMENTS[environment]["config"]


def get_test_data_dir() -> Path:
    """Get path to test data directory."""
    return Path(__file__).parent / "fixtures"


def get_temp_test_dir() -> Path:
    """Get path for temporary test files."""
    import tempfile

    return Path(tempfile.gettempdir()) / "linkwatcher_tests"


# Test file patterns and extensions
TEST_FILE_PATTERNS = {
    "markdown": ["*.md", "*.markdown"],
    "yaml": ["*.yaml", "*.yml"],
    "json": ["*.json"],
    "python": ["*.py"],
    "dart": ["*.dart"],
    "text": ["*.txt"],
}


# Sample file contents for testing
SAMPLE_CONTENTS = {
    "markdown_with_links": """# Test Document

This document contains various types of links:

1. [Standard link](target.txt)
2. [Relative link](../other/file.md)
3. [Link with anchor](document.md#section)

## File References

Also references:
- Configuration: "config.yaml"
- Data file: 'data.json'
- Script: scripts/process.py

## External Links (should be ignored)

- [GitHub](https://github.com)
- [Email](mailto:test@example.com)
""",
    "yaml_with_refs": """
# Configuration file
database:
  url: "sqlite:///data/app.db"
  schema: "schema.sql"
  migrations: "migrations/"

logging:
  file: "logs/app.log"
  level: INFO

templates:
  directory: templates/
  main: main.html
  error: error.html

files:
  - "data/users.csv"
  - "data/products.json"
  - "config/settings.yaml"
""",
    "json_with_refs": """{
  "database": {
    "primary": "data/primary.db",
    "backup": "data/backup.db",
    "schema": "schema/database.sql"
  },
  "assets": {
    "css": "static/css/main.css",
    "js": "static/js/app.js",
    "images": "static/images/"
  },
  "templates": [
    "templates/base.html",
    "templates/index.html",
    "templates/error.html"
  ],
  "config_files": {
    "main": "config/main.yaml",
    "database": "config/database.json",
    "logging": "config/logging.yaml"
  }
}""",
    "python_with_refs": '''"""
Python module with file references.
"""

import os
import sys
from pathlib import Path

# Configuration files
CONFIG_FILE = "config/settings.yaml"
DATABASE_CONFIG = 'config/database.json'
LOG_CONFIG = "config/logging.yaml"

# Data files
DATA_DIR = "data/"
USERS_FILE = "data/users.csv"
PRODUCTS_FILE = "data/products.json"

# Template files
TEMPLATE_DIR = "templates/"
BASE_TEMPLATE = "templates/base.html"
INDEX_TEMPLATE = 'templates/index.html'

class FileProcessor:
    """Process various file types."""

    def __init__(self):
        self.schema_file = "schema/database.sql"
        self.migration_dir = "migrations/"

    def load_config(self):
        """Load configuration from config/main.yaml."""
        pass

    def process_data(self):
        """
        Process data files.

        Reads from input/raw.csv and writes to output/processed.json.
        """
        pass

# File mappings
FILE_MAPPINGS = {
    "config": "config/main.yaml",
    "data": "data/main.csv",
    "template": "templates/main.html",
    "schema": "schema/main.sql"
}

if __name__ == "__main__":
    # Load from "config/main.yaml"
    print("Processing files...")
''',
    "text_with_refs": """
This is a plain text file with file references.

Configuration files:
- config.yaml
- settings.json
- "database.conf"

Data files:
- users.csv
- products.json
- 'orders.xml'

See documentation in docs/readme.md for more information.
Check the schema in schema/database.sql.
""",
}


# Test project structures
TEST_PROJECT_STRUCTURES = {
    "simple": {
        "README.md": SAMPLE_CONTENTS["markdown_with_links"],
        "config.yaml": SAMPLE_CONTENTS["yaml_with_refs"],
        "data.json": SAMPLE_CONTENTS["json_with_refs"],
        "main.py": SAMPLE_CONTENTS["python_with_refs"],
        "notes.txt": SAMPLE_CONTENTS["text_with_refs"],
    },
    "complex": {
        "README.md": """# Complex Project

[User Guide](docs/guide.md)
[API Reference](docs/api.md)
Configuration in "config/settings.yaml"
""",
        "docs/guide.md": """# User Guide

[API Reference](api.md)
[Configuration](../config/settings.yaml)
""",
        "docs/api.md": """# API Reference

[User Guide](guide.md)
[Examples](../examples/basic.py)
""",
        "config/settings.yaml": """
app:
  name: "Complex App"
  version: "1.0.0"

database:
  url: "data/app.db"
  schema: "schema.sql"

logging:
  file: "logs/app.log"
""",
        "src/main.py": '''
"""Main application."""

CONFIG_FILE = "config/settings.yaml"
DATA_FILE = "data/users.csv"
TEMPLATE = "templates/main.html"
''',
        "examples/basic.py": '''
"""Basic example."""

# See "config/settings.yaml" for configuration
import sys
''',
        "data/users.csv": "id,name,email\n1,John,john@example.com\n",
        "templates/main.html": "<html><body>{{ content }}</body></html>",
    },
}


def create_test_project(base_path: Path, structure_name: str = "simple"):
    """Create a test project with specified structure."""
    if structure_name not in TEST_PROJECT_STRUCTURES:
        raise ValueError(f"Unknown project structure: {structure_name}")

    structure = TEST_PROJECT_STRUCTURES[structure_name]
    created_files = {}

    for file_path, content in structure.items():
        full_path = base_path / file_path
        full_path.parent.mkdir(parents=True, exist_ok=True)
        full_path.write_text(content)
        created_files[file_path] = full_path

    return created_files


# Performance test configurations
PERFORMANCE_TEST_CONFIGS = {
    "small": {"num_files": 50, "files_per_dir": 10, "refs_per_file": 3},
    "medium": {"num_files": 200, "files_per_dir": 20, "refs_per_file": 5},
    "large": {"num_files": 1000, "files_per_dir": 50, "refs_per_file": 10},
    "xlarge": {"num_files": 5000, "files_per_dir": 100, "refs_per_file": 15},
}


def get_performance_config(size: str = "small") -> dict:
    """Get performance test configuration."""
    if size not in PERFORMANCE_TEST_CONFIGS:
        raise ValueError(f"Unknown performance config size: {size}")

    return PERFORMANCE_TEST_CONFIGS[size]


# Test timeouts (in seconds)
TEST_TIMEOUTS = {
    "unit": 5,
    "integration": 30,
    "performance_small": 60,
    "performance_medium": 180,
    "performance_large": 300,
    "performance_xlarge": 600,
}


def get_test_timeout(test_type: str) -> int:
    """Get timeout for specified test type."""
    return TEST_TIMEOUTS.get(test_type, 30)  # Default 30 seconds
