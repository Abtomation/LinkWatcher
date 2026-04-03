#!/usr/bin/env python3
"""
Unit tests for comprehensive file type monitoring configuration.

Tests that all commonly referenced file types are properly configured
for monitoring, and that file type categories have adequate coverage.
"""

from pathlib import Path

import pytest

from linkwatcher.config.defaults import DEFAULT_CONFIG
from linkwatcher.service import LinkWatcherService

pytestmark = [
    pytest.mark.feature("1.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.cross_cutting(["0.1.1"]),
    pytest.mark.test_type("unit"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-1-1-1-file-system-monitoring.md"
    ),
]


class TestComprehensiveFileMonitoring:
    """Test monitoring of various file types commonly referenced in projects."""

    def test_all_common_extensions_are_monitored(self, tmp_path):
        """Test that all commonly referenced file extensions are monitored."""

        service = LinkWatcherService(str(tmp_path))

        expected_extensions = DEFAULT_CONFIG.monitored_extensions
        monitored = service.handler.monitored_extensions

        # Verify all expected extensions are present
        missing_extensions = expected_extensions - monitored
        assert not missing_extensions, f"Missing extensions: {missing_extensions}"

        # Verify monitored set covers at least the default config
        assert len(monitored) >= len(
            expected_extensions
        ), f"Expected at least {len(expected_extensions)} extensions, got {len(monitored)}"

    def test_web_development_files_monitored(self, tmp_path):
        """Test that web development files are properly monitored."""

        service = LinkWatcherService(str(tmp_path))

        web_files = [
            "index.html",
            "styles.css",
            "script.js",
            "app.ts",
            "component.jsx",
            "component.tsx",
            "app.vue",
            "api.php",
        ]

        for filename in web_files:
            test_file = tmp_path / filename
            test_file.write_text("test content")

            is_monitored = service.handler._should_monitor_file(str(test_file))
            assert is_monitored, f"Web file {filename} should be monitored"

    def test_image_files_monitored(self, tmp_path):
        """Test that various image formats are properly monitored."""

        service = LinkWatcherService(str(tmp_path))

        image_files = [
            "logo.png",
            "photo.jpg",
            "image.jpeg",
            "animation.gif",
            "icon.svg",
            "modern.webp",
            "favicon.ico",
        ]

        for filename in image_files:
            test_file = tmp_path / filename
            test_file.write_text("fake image content")

            is_monitored = service.handler._should_monitor_file(str(test_file))
            assert is_monitored, f"Image file {filename} should be monitored"

    def test_document_and_data_files_monitored(self, tmp_path):
        """Test that document and data files are properly monitored."""

        service = LinkWatcherService(str(tmp_path))

        document_files = [
            "config.yaml",
            "data.json",
            "export.csv",
            "schema.xml",
            "manual.pdf",
            "readme.txt",
            "notes.md",
        ]

        for filename in document_files:
            test_file = tmp_path / filename
            test_file.write_text("test content")

            is_monitored = service.handler._should_monitor_file(str(test_file))
            assert is_monitored, f"Document file {filename} should be monitored"

    def test_media_files_monitored(self, tmp_path):
        """Test that media files are properly monitored."""

        service = LinkWatcherService(str(tmp_path))

        media_files = ["demo.mp4", "audio.mp3", "sound.wav"]

        for filename in media_files:
            test_file = tmp_path / filename
            test_file.write_text("fake media content")

            is_monitored = service.handler._should_monitor_file(str(test_file))
            assert is_monitored, f"Media file {filename} should be monitored"

    def test_comprehensive_link_detection_and_updates(self, tmp_path):
        """Test that links to various file types are detected and updated correctly."""

        # Create a markdown file with links to various file types
        readme = tmp_path / "README.md"
        readme.write_text(
            """# Project Documentation

## Resources

- [Configuration](config.yaml)
- [Styles](assets/styles.css)
- [Logo](images/logo.png)
- [Demo Video](media/demo.mp4)
- [API Documentation](docs/api.html)
- [Data Export](data/export.csv)
- [Manual](docs/manual.pdf)

## Code Examples

See [main script](src/main.py) and [helper functions](src/utils.js).
"""
        )

        # Create referenced files
        (tmp_path / "config.yaml").write_text("key: value")
        (tmp_path / "assets").mkdir()
        (tmp_path / "assets" / "styles.css").write_text("body { margin: 0; }")
        (tmp_path / "images").mkdir()
        (tmp_path / "images" / "logo.png").write_text("fake png")
        (tmp_path / "media").mkdir()
        (tmp_path / "media" / "demo.mp4").write_text("fake video")
        (tmp_path / "docs").mkdir()
        (tmp_path / "docs" / "api.html").write_text("<html></html>")
        (tmp_path / "data").mkdir()
        (tmp_path / "data" / "export.csv").write_text("col1,col2\n1,2")
        (tmp_path / "docs" / "manual.pdf").write_text("fake pdf")
        (tmp_path / "src").mkdir()
        (tmp_path / "src" / "main.py").write_text("print('hello')")
        (tmp_path / "src" / "utils.js").write_text("console.log('utils')")

        # Initialize service and run initial scan
        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Verify that links to all file types were detected
        stats = service.link_db.get_stats()
        assert stats["files_with_links"] >= 1, "Should detect files with links"
        assert (
            stats["total_references"] >= 8
        ), "Should detect multiple references to different file types"

        # Test that references to different file types are found
        # These are files that should be referenced FROM the README.md
        referenced_files = [
            "config.yaml",
            "assets/styles.css",
            "images/logo.png",
            "media/demo.mp4",
            "docs/api.html",
            "data/export.csv",
            "docs/manual.pdf",
            "src/main.py",
            "src/utils.js",
        ]

        found_refs = 0
        for filepath in referenced_files:
            # Check both full path and just filename
            refs_full = service.link_db.get_references_to_file(filepath)
            refs_name = service.link_db.get_references_to_file(Path(filepath).name)
            if refs_full or refs_name:
                found_refs += 1

        assert found_refs >= 6, f"Should find references to multiple file types, found {found_refs}"


class TestFileTypeCategories:
    """Test that file types are properly categorized and handled."""

    def test_extension_coverage_by_category(self, tmp_path):
        """Test that we have good coverage across different file type categories."""

        service = LinkWatcherService(str(tmp_path))

        monitored = service.handler.monitored_extensions

        # Spot-check subsets: verify key extensions per category are present
        text_formats = {".md", ".txt", ".yaml", ".yml", ".json", ".xml", ".csv"}
        web_formats = {".html", ".htm", ".css", ".js", ".ts", ".jsx", ".tsx", ".vue", ".php"}
        image_formats = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".ico"}
        media_formats = {".mp4", ".mp3", ".wav"}
        code_formats = {".py", ".dart"}
        doc_formats = {".pdf"}

        # Verify each category has representation
        assert text_formats.intersection(monitored), "Should monitor text formats"
        assert web_formats.intersection(monitored), "Should monitor web formats"
        assert image_formats.intersection(monitored), "Should monitor image formats"
        assert media_formats.intersection(monitored), "Should monitor media formats"
        assert code_formats.intersection(monitored), "Should monitor code formats"
        assert doc_formats.intersection(monitored), "Should monitor document formats"

        # Verify good coverage within each category
        assert (
            len(text_formats.intersection(monitored)) >= 5
        ), "Should have good text format coverage"
        assert len(web_formats.intersection(monitored)) >= 6, "Should have good web format coverage"
        assert (
            len(image_formats.intersection(monitored)) >= 5
        ), "Should have good image format coverage"
