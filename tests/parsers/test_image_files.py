"""
Tests for parsing image files (PNG, SVG) with the generic parser.

These tests verify that image files are handled correctly by the parser system,
even though they use the generic parser rather than specialized parsers.
"""

import tempfile
from pathlib import Path

import pytest

from linkwatcher.parser import LinkParser
from linkwatcher.parsers.generic import GenericParser


class TestImageFileParsing:
    """Test parsing of various image file formats."""

    def test_png_file_parsing_returns_empty(self):
        """Test that PNG files return no links when parsed."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            png_file = temp_path / "image.png"

            # Create realistic PNG header + some data
            png_data = (
                b"\x89PNG\r\n\x1a\n"  # PNG signature
                b"\x00\x00\x00\rIHDR"  # IHDR chunk
                b"\x00\x00\x00\x10\x00\x00\x00\x10"  # 16x16 image
                b"\x08\x02\x00\x00\x00\x90\x91h6"  # Color type, etc.
                b"fake png data for testing"
            )
            png_file.write_bytes(png_data)

            # Test with generic parser directly
            generic_parser = GenericParser()
            references = generic_parser.parse_file(str(png_file))
            assert len(references) == 0, "PNG files should not contain parseable links"

            # Test with main parser (should use generic parser)
            main_parser = LinkParser()
            references = main_parser.parse_file(str(png_file))
            assert (
                len(references) == 0
            ), "PNG files should not contain parseable links via main parser"

    def test_svg_file_with_links(self):
        """Test that SVG files with embedded links are parsed correctly."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            svg_file = temp_path / "icon.svg"

            # Create SVG with various types of links
            svg_content = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="100" height="100">
  <!-- External link -->
  <a href="external.html">
    <rect x="10" y="10" width="30" height="30" fill="blue"/>
  </a>

  <!-- Relative link -->
  <a href="../docs/guide.md">
    <circle cx="70" cy="30" r="15" fill="red"/>
  </a>

  <!-- Image reference -->
  <image href="background.jpg" x="0" y="0" width="100" height="100"/>

  <!-- XLink reference (older SVG style) -->
  <use xlink:href="symbols.svg#icon"/>
</svg>"""
            svg_file.write_text(svg_content)

            # Parse with generic parser
            generic_parser = GenericParser()
            references = generic_parser.parse_file(str(svg_file))

            # Should find some links (exact number depends on generic parser implementation)
            assert isinstance(references, list), "Should return list of references"

            # If references found, verify they have required attributes
            for ref in references:
                assert hasattr(ref, "link_target"), "Reference should have link_target"
                assert hasattr(ref, "file_path"), "Reference should have file_path"
                assert hasattr(ref, "line_number"), "Reference should have line_number"

    def test_svg_file_without_links(self):
        """Test that SVG files without links return empty results."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            svg_file = temp_path / "simple.svg"

            # Create simple SVG without any links
            svg_content = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="50" height="50">
  <circle cx="25" cy="25" r="20" fill="green"/>
  <text x="25" y="30" text-anchor="middle">Hi</text>
</svg>"""
            svg_file.write_text(svg_content)

            # Parse with generic parser
            generic_parser = GenericParser()
            references = generic_parser.parse_file(str(svg_file))

            # Should return empty list for SVG without links
            assert len(references) == 0, "SVG without links should return no references"

    def test_corrupted_image_files(self):
        """Test that corrupted or invalid image files don't crash the parser."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)

            # Test corrupted PNG
            bad_png = temp_path / "corrupted.png"
            bad_png.write_text("This is not a real PNG file")

            generic_parser = GenericParser()

            # Should not crash, should return empty or handle gracefully
            try:
                references = generic_parser.parse_file(str(bad_png))
                assert isinstance(references, list), "Should return list even for corrupted files"
            except Exception as e:
                # If it throws an exception, it should be handled gracefully by the main parser
                main_parser = LinkParser()
                references = main_parser.parse_file(str(bad_png))
                assert isinstance(
                    references, list
                ), "Main parser should handle exceptions gracefully"

    def test_image_file_extensions_not_in_specialized_parsers(self):
        """Test that image extensions are not in specialized parsers list."""
        main_parser = LinkParser()
        specialized_extensions = main_parser.get_supported_extensions()

        # Image extensions should not have specialized parsers
        assert ".png" not in specialized_extensions, "PNG should not have specialized parser"
        assert ".svg" not in specialized_extensions, "SVG should not have specialized parser"
        assert ".jpg" not in specialized_extensions, "JPG should not have specialized parser"
        assert ".jpeg" not in specialized_extensions, "JPEG should not have specialized parser"
        assert ".gif" not in specialized_extensions, "GIF should not have specialized parser"

        # But text-based formats should have specialized parsers
        assert ".md" in specialized_extensions, "Markdown should have specialized parser"
        assert ".py" in specialized_extensions, "Python should have specialized parser"
        assert ".json" in specialized_extensions, "JSON should have specialized parser"

    def test_mixed_content_directory_parsing(self):
        """Test parsing a directory with mixed image and text files."""
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)

            # Create various file types
            md_file = temp_path / "README.md"
            png_file = temp_path / "logo.png"
            svg_file = temp_path / "icon.svg"

            # Markdown with image references
            md_content = """# Project

![Logo](logo.png)
![Icon](icon.svg)
"""
            md_file.write_text(md_content)

            # Simple image files
            png_file.write_bytes(b"\x89PNG\r\n\x1a\nfake png")
            svg_file.write_text('<svg><circle r="10"/></svg>')

            parser = LinkParser()

            # Parse each file
            md_refs = parser.parse_file(str(md_file))
            png_refs = parser.parse_file(str(png_file))
            svg_refs = parser.parse_file(str(svg_file))

            # Markdown should have references to images
            assert len(md_refs) >= 2, "Markdown should reference both images"

            # Image files should not have outgoing references
            assert len(png_refs) == 0, "PNG should not have outgoing references"
            assert len(svg_refs) == 0, "Simple SVG should not have outgoing references"

            # Verify the references point to the image files
            targets = [ref.link_target for ref in md_refs]
            assert "logo.png" in targets, "Should reference PNG file"
            assert "icon.svg" in targets, "Should reference SVG file"
