"""
Integration tests for PNG/SVG image file monitoring and link updates.

These tests verify that image files (PNG, SVG) are properly monitored
for file system events and that links pointing to them are updated correctly.
"""

import tempfile
from pathlib import Path

import pytest

from linkwatcher.parser import LinkParser
from linkwatcher.service import LinkWatcherService


class TestImageFileMonitoring:
    """Test image file monitoring functionality."""

    def test_png_svg_files_are_monitored(self):
        """Test that PNG and SVG files are included in monitored extensions."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)

            # Create test files
            test_md = temp_path / "README.md"
            test_png = temp_path / "logo.png"
            test_svg = temp_path / "icon.svg"

            # Create dummy files
            test_png.write_text("fake png content")
            test_svg.write_text("fake svg content")
            test_md.write_text("# Test\n\n![Logo](logo.png)\n![Icon](icon.svg)")

            # Initialize service
            service = LinkWatcherService(str(temp_path))

            # Check that PNG/SVG files are monitored
            assert service.handler._should_monitor_file(
                str(test_png)
            ), "PNG files should be monitored"
            assert service.handler._should_monitor_file(
                str(test_svg)
            ), "SVG files should be monitored"
            assert service.handler._should_monitor_file(
                str(test_md)
            ), "MD files should be monitored"

            # Check monitored extensions include image files
            assert (
                ".png" in service.handler.monitored_extensions
            ), "PNG extension should be monitored"
            assert (
                ".svg" in service.handler.monitored_extensions
            ), "SVG extension should be monitored"

    def test_image_references_found_in_initial_scan(self):
        """Test that references to image files are found during initial scan."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)

            # Create test structure
            test_md = temp_path / "README.md"
            test_png = temp_path / "logo.png"
            test_svg = temp_path / "icon.svg"

            # Create files
            test_png.write_text("fake png content")
            test_svg.write_text("fake svg content")

            markdown_content = """# Test Document

## Images
![Logo](logo.png "Company Logo")
![Icon](icon.svg "App Icon")

## Reference Links
[logo-ref]: logo.png "Logo Reference"
[icon-ref]: icon.svg "Icon Reference"

Using references: ![Logo][logo-ref] and ![Icon][icon-ref]
"""
            test_md.write_text(markdown_content)

            # Initialize service and perform initial scan
            service = LinkWatcherService(str(temp_path))
            service._initial_scan()

            # Check database stats
            stats = service.link_db.get_stats()
            assert stats["files_with_links"] >= 1, "Should find files with links"
            assert stats["total_references"] >= 4, "Should find multiple image references"

            # Check specific references
            png_refs = service.link_db.get_references_to_file("logo.png")
            svg_refs = service.link_db.get_references_to_file("icon.svg")

            assert len(png_refs) >= 2, "Should find multiple PNG references"
            assert len(svg_refs) >= 2, "Should find multiple SVG references"

    def test_image_file_movement_updates_links(self):
        """Test that moving image files updates links correctly."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)

            # Create test structure
            docs_dir = temp_path / "docs"
            assets_dir = temp_path / "assets"
            images_dir = temp_path / "images"

            docs_dir.mkdir()
            assets_dir.mkdir()
            images_dir.mkdir()

            # Create image files
            logo_png = assets_dir / "logo.png"
            icon_svg = assets_dir / "icon.svg"
            logo_png.write_text("fake png content")
            icon_svg.write_text("fake svg content")

            # Create markdown file with image references
            md_file = docs_dir / "guide.md"
            md_content = """# Guide

Images from assets:
- ![Logo](../assets/logo.png "Company Logo")
- ![Icon](../assets/icon.svg "App Icon")

Reference style:
[logo]: ../assets/logo.png "Logo"
[icon]: ../assets/icon.svg "Icon"
"""
            md_file.write_text(md_content)

            # Initialize service and scan
            service = LinkWatcherService(str(temp_path))
            service._initial_scan()

            # Verify initial references
            png_refs = service.link_db.get_references_to_file("assets/logo.png")
            svg_refs = service.link_db.get_references_to_file("assets/icon.svg")

            assert len(png_refs) >= 1, "Should find PNG references"
            assert len(svg_refs) >= 1, "Should find SVG references"

            # Move PNG file to images directory
            new_logo = images_dir / "logo.png"
            logo_png.rename(new_logo)

            # Simulate file move event
            from linkwatcher.handler import FileMovedEvent

            class MockMoveEvent:
                def __init__(self, src, dest):
                    self.src_path = src
                    self.dest_path = dest
                    self.is_directory = False

            move_event = MockMoveEvent(str(logo_png), str(new_logo))
            service.handler._handle_file_moved(move_event)

            # Check that markdown file was updated
            updated_content = md_file.read_text()

            # Should contain new path
            assert "../images/logo.png" in updated_content, "Should update PNG path"
            # Should not contain old path
            assert "../assets/logo.png" not in updated_content, "Should remove old PNG path"

            # Verify titles are preserved
            assert 'logo.png "Company Logo"' in updated_content, "Should preserve PNG title"


class TestImageFileParsing:
    """Test parsing of image files themselves."""

    def test_png_file_parsing(self):
        """Test that PNG files can be parsed (should return no links)."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            test_png = temp_path / "test.png"

            # Create fake PNG content (binary-ish)
            test_png.write_bytes(
                b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01fake png data"
            )

            parser = LinkParser()
            references = parser.parse_file(str(test_png))

            # PNG files should not contain parseable links
            assert len(references) == 0, "PNG files should not contain links"

    def test_svg_file_parsing(self):
        """Test that SVG files can be parsed and may contain links."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            test_svg = temp_path / "test.svg"

            # Create SVG with embedded link
            svg_content = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <circle cx="50" cy="50" r="40" fill="red"/>
  <a href="example.html">
    <text x="50" y="50">Click me</text>
  </a>
</svg>"""
            test_svg.write_text(svg_content)

            parser = LinkParser()
            references = parser.parse_file(str(test_svg))

            # SVG files may contain links (using generic parser)
            # The exact number depends on the generic parser implementation
            assert isinstance(references, list), "Should return a list of references"

            # If links are found, verify they're reasonable
            if references:
                for ref in references:
                    assert hasattr(ref, "link_target"), "Reference should have link_target"
                    assert hasattr(ref, "link_text"), "Reference should have link_text"

    def test_parser_extension_support(self):
        """Test that parser correctly identifies supported extensions."""
        parser = LinkParser()
        supported = parser.get_supported_extensions()

        # Core extensions should be supported
        assert ".md" in supported, "Markdown should be supported"
        assert ".py" in supported, "Python should be supported"
        assert ".json" in supported, "JSON should be supported"

        # Image extensions use generic parser (not in specialized parsers)
        assert ".png" not in supported, "PNG should use generic parser"
        assert ".svg" not in supported, "SVG should use generic parser"
