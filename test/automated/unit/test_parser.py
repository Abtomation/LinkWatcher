"""
Tests for the main LinkParser class.

This module tests the parser coordination and file type delegation.
"""

from pathlib import Path

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.parser import LinkParser


class TestLinkParser:
    """Test cases for LinkParser."""

    def test_parser_initialization(self):
        """Test parser initialization with default parsers."""
        parser = LinkParser()

        # Check that default parsers are loaded
        assert ".md" in parser.parsers
        assert ".yaml" in parser.parsers
        assert ".yml" in parser.parsers
        assert ".json" in parser.parsers
        assert ".dart" in parser.parsers
        assert ".py" in parser.parsers

        # Check that generic parser exists
        assert parser.generic_parser is not None

    def test_parse_markdown_file(self, temp_project_dir, file_helper):
        """Test parsing a markdown file."""
        parser = LinkParser()

        # Create a markdown file
        md_file = temp_project_dir / "test.md"
        content = """# Test Document

This has a [markdown link](target.txt) and a "quoted_file.py".
"""
        file_helper.create_markdown_file(md_file, content)

        # Parse the file
        references = parser.parse_file(str(md_file))

        # Should find both references
        assert len(references) >= 2

        # Check for markdown link
        pytest.assert_reference_found(references, "target.txt", "markdown")

        # Check for quoted reference
        pytest.assert_reference_found(references, "quoted_file.py")

    def test_parse_yaml_file(self, temp_project_dir, file_helper):
        """Test parsing a YAML file."""
        parser = LinkParser()

        # Create a YAML file
        yaml_file = temp_project_dir / "config.yaml"
        data = {
            "database": {"config_file": "tests/unit/config.json", "schema": "schema.sql"},
            "logging": {"file": "app.log"},
        }
        file_helper.create_yaml_file(yaml_file, data)

        # Parse the file
        references = parser.parse_file(str(yaml_file))

        # Should find file references
        assert len(references) >= 2

        # Check for specific references
        targets = [ref.link_target for ref in references]
        assert "tests/unit/config.json" in targets
        assert "app.log" in targets

    def test_parse_json_file(self, temp_project_dir, file_helper):
        """Test parsing a JSON file."""
        parser = LinkParser()

        # Create a JSON file
        json_file = temp_project_dir / "config.json"
        data = {
            "templates": {"main": "main.html", "error": "error.html"},
            "assets": {"css": "styles.css", "js": "app.js"},
        }
        file_helper.create_json_file(json_file, data)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find file references
        assert len(references) >= 2

        # Check for specific references
        targets = [ref.link_target for ref in references]
        assert "main.html" in targets
        assert "styles.css" in targets

    def test_parse_unsupported_file_type(self, temp_project_dir):
        """Test parsing an unsupported file type falls back to generic parser."""
        parser = LinkParser()

        # Create a file with unsupported extension
        unknown_file = temp_project_dir / "test.xyz"
        content = """
        This file references "some_file.txt" and 'another_file.json'.
        """
        unknown_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(unknown_file))

        # Should find references using generic parser
        assert len(references) >= 2

        # Check that references were found
        targets = [ref.link_target for ref in references]
        assert "some_file.txt" in targets
        assert "another_file.json" in targets

        # Check that they're marked as generic
        for ref in references:
            assert ref.link_type.startswith("generic")

    def test_add_custom_parser(self, temp_project_dir):
        """Test adding a custom parser for a file type."""
        parser = LinkParser()

        # Create a mock custom parser
        class MockParser:
            def parse_file(self, file_path):
                return [
                    LinkReference(
                        file_path=file_path,
                        line_number=1,
                        column_start=0,
                        column_end=10,
                        link_text="custom.txt",
                        link_target="custom.txt",
                        link_type="custom",
                    )
                ]

        # Add custom parser
        parser.add_parser(".custom", MockParser())

        # Create a file with custom extension
        custom_file = temp_project_dir / "test.custom"
        custom_file.write_text("Some content")

        # Parse the file
        references = parser.parse_file(str(custom_file))

        # Should use custom parser
        assert len(references) == 1
        assert references[0].link_type == "custom"
        assert references[0].link_target == "custom.txt"

    def test_remove_parser(self):
        """Test removing a parser."""
        parser = LinkParser()

        # Remove markdown parser
        parser.remove_parser(".md")

        # Should no longer have markdown parser
        assert ".md" not in parser.parsers

    def test_get_supported_extensions(self):
        """Test getting list of supported extensions."""
        parser = LinkParser()

        extensions = parser.get_supported_extensions()

        # Should include default extensions
        assert ".md" in extensions
        assert ".yaml" in extensions
        assert ".json" in extensions
        assert ".dart" in extensions
        assert ".py" in extensions

    def test_parse_nonexistent_file(self):
        """Test parsing a file that doesn't exist."""
        parser = LinkParser()

        # Try to parse non-existent file
        references = parser.parse_file("nonexistent.md")

        # Should return empty list without crashing
        assert references == []

    def test_parse_empty_file(self, temp_project_dir):
        """Test parsing an empty file."""
        parser = LinkParser()

        # Create empty file
        empty_file = temp_project_dir / "empty.md"
        empty_file.write_text("")

        # Parse the file
        references = parser.parse_file(str(empty_file))

        # Should return empty list
        assert references == []

    def test_parse_binary_file(self, temp_project_dir):
        """Test parsing a binary file gracefully fails."""
        parser = LinkParser()

        # Create a binary file
        binary_file = temp_project_dir / "test.bin"
        binary_file.write_bytes(b"\x00\x01\x02\x03\x04\x05")

        # Try to parse the file
        references = parser.parse_file(str(binary_file))

        # Should return empty list without crashing
        assert references == []

    def test_parser_thread_safety(self, temp_project_dir, file_helper):
        """Test that parser can be used safely from multiple threads."""
        import threading
        import time

        parser = LinkParser()
        results = []

        # Create test files
        for i in range(5):
            md_file = temp_project_dir / f"doc_{i}.md"
            content = f"# Document {i}\n\n[Link](file_{i}.txt)"
            file_helper.create_markdown_file(md_file, content)

        def parse_files():
            for i in range(5):
                file_path = temp_project_dir / f"doc_{i}.md"
                refs = parser.parse_file(str(file_path))
                results.extend(refs)
                time.sleep(0.001)  # Small delay

        # Start multiple threads
        threads = []
        for _ in range(3):
            thread = threading.Thread(target=parse_files)
            threads.append(thread)
            thread.start()

        # Wait for completion
        for thread in threads:
            thread.join()

        # Should have found references from all threads
        assert len(results) == 15  # 3 threads * 5 files * 1 reference each
