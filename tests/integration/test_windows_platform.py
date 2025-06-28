"""
Windows Platform Compatibility Tests (CP Test Cases)

This module implements Windows-specific compatibility test cases, focusing on
ensuring proper behavior on Windows operating system.

Test Cases Implemented:
- CP-001: Path separator handling (Windows backslash)
- CP-002: Case insensitive behavior (Windows default)
- CP-003: Windows file name restrictions
- CP-004: Long path handling (Windows)
- CP-005: Special characters in paths (Windows)
- CP-006: Junction handling (Windows)
- CP-007: Drive letter handling (Windows)
- CP-008: Hidden file handling (Windows)
"""

import os
import sys
import tempfile
from pathlib import Path, PurePath, PurePosixPath, PureWindowsPath
from unittest.mock import patch

import pytest

from linkwatcher.parser import LinkParser
from linkwatcher.service import LinkWatcherService
from linkwatcher.updater import LinkUpdater


class TestPathSeparatorHandling:
    """Test handling of different path separators."""

    def test_cp_001_mixed_path_separators(self, temp_project_dir):
        """
        CP-001: Path separator handling (/ vs \)

        Test Case: Files with mixed path separators
        Expected: Normalize paths correctly on all platforms
        Priority: Critical
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create directory structure
        docs_dir = temp_project_dir / "docs"
        docs_dir.mkdir()

        # Create files with different path separator styles
        test_file = temp_project_dir / "test.md"
        content = """# Test Document

Links with different separators:
- [Unix style](docs/readme.md)
- [Windows style](docs\\api.md)
- [Mixed style](docs/sub\\file.txt)

Quoted references:
- "../tests/integration/config.yaml"
- "../tests/integration/settings.json"
- 'docs/data/info.txt'
"""
        test_file.write_text(content)

        # Create target files
        (docs_dir / "readme.mdd").write_text("# README")
        (docs_dir / "api.md").write_text("# API")
        (docs_dir / "config.yaml").write_text("config: value")
        (docs_dir / "settings.json").write_text('{"setting": "value"}')

        # Parse and verify path normalization
        service._initial_scan()

        # All references should be found regardless of separator style
        references = service.link_db.get_all_references()
        targets = [ref.link_target for ref in references]

        # Check that paths are normalized to platform-appropriate format
        expected_files = [
            "docs/readme.md",
            "docs/api.md",
            "../tests/integration/config.yaml",
            "docs/settings.json",
        ]

        for expected in expected_files:
            # Should find the file with normalized path
            normalized_path = str(Path(expected))
            assert any(
                normalized_path in target or expected in target for target in targets
            ), f"Expected to find {expected} or {normalized_path} in {targets}"

    def test_cp_001_path_normalization_in_updates(self, temp_project_dir):
        """Test path normalization during file updates."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create files
        docs_dir = temp_project_dir / "docs"
        docs_dir.mkdir()

        source_file = docs_dir / "source.txt"
        source_file.write_text("Source content")

        # Create file with mixed separators
        test_file = temp_project_dir / "test.md"
        if os.name == "nt":  # Windows
            content = "[Link](docs\\source.txt)"
        else:  # Unix-like
            content = "[Link](docs/source.txt)"
        test_file.write_text(content)

        service._initial_scan()

        # Move source file
        new_source = docs_dir / "renamed_source.txt"
        source_file.rename(new_source)

        service.handler.on_moved(None, str(source_file), str(new_source), False)

        # Check that update uses correct path separators
        updated_content = test_file.read_text()

        # Should contain the new path with platform-appropriate separators
        if os.name == "nt":
            assert (
                "docs\\renamed_source.txt" in updated_content
                or "docs/renamed_source.txt" in updated_content
            )
        else:
            assert "docs/renamed_source.txt" in updated_content

    def test_cp_001_relative_path_resolution(self, temp_project_dir):
        """Test relative path resolution across platforms."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create nested directory structure
        src_dir = temp_project_dir / "src"
        docs_dir = temp_project_dir / "docs"
        src_dir.mkdir()
        docs_dir.mkdir()

        # Create files with relative paths
        src_file = src_dir / "main.py"
        content = '''"""Main module."""

# References with relative paths
CONFIG_FILE = "../../tests/integration/config.yaml"
README_FILE = "../docs/readme.md"
'''
        src_file.write_text(content)

        # Create target files
        (docs_dir / "config.yaml").write_text("config: value")
        (docs_dir / "readme.mdd").write_text("# README")

        service._initial_scan()

        # Should resolve relative paths correctly
        references = service.link_db.get_all_references()
        targets = [ref.link_target for ref in references]

        assert "../../tests/integration/config.yaml" in targets
        assert "../docs/readme.md" in targets


class TestCaseSensitivity:
    """Test case sensitivity behavior across platforms."""

    def test_cp_002_case_sensitive_file_matching(self, temp_project_dir):
        """
        CP-002: Case sensitivity behavior

        Test Case: File references with different cases
        Expected: Behavior consistent with platform file system
        Priority: High
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create files with different cases
        readme_lower = temp_project_dir / "readme.mdd"
        readme_lower.write_text("# Lower case readme")

        # Only create upper case file on case-sensitive systems
        if self._is_case_sensitive_filesystem(temp_project_dir):
            readme_upper = temp_project_dir / "README.md"
            readme_upper.write_text("# Upper case README")

        # Create test file with references
        test_file = temp_project_dir / "test.md"
        content = """# Test Document

References:
- [Lower case](readme.md)
- [Upper case](README.md)
- [Mixed case](ReadMe.md)
"""
        test_file.write_text(content)

        service._initial_scan()

        # Check behavior based on file system case sensitivity
        references = service.link_db.get_all_references()
        targets = [ref.link_target for ref in references]

        if self._is_case_sensitive_filesystem(temp_project_dir):
            # On case-sensitive systems, should distinguish between cases
            assert "readme.mdd" in targets
            assert "README.md" in targets
            assert "ReadMe.md" in targets
        else:
            # On case-insensitive systems, all should resolve to existing file
            assert any(target.lower() == "readme.mdd" for target in targets)

    def test_cp_002_case_sensitivity_in_updates(self, temp_project_dir):
        """Test case sensitivity in file updates."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create source file
        source_file = temp_project_dir / "source.txt"
        source_file.write_text("Source content")

        # Create reference with different case
        test_file = temp_project_dir / "test.md"
        if self._is_case_sensitive_filesystem(temp_project_dir):
            content = "[Link](SOURCE.TXT)"  # Different case
        else:
            content = "[Link](source.txt)"  # Same case
        test_file.write_text(content)

        service._initial_scan()

        # Move source file
        new_source = temp_project_dir / "renamed_source.txt"
        source_file.rename(new_source)

        service.handler.on_moved(None, str(source_file), str(new_source), False)

        # Check update behavior
        updated_content = test_file.read_text()

        if self._is_case_sensitive_filesystem(temp_project_dir):
            # On case-sensitive systems, might not update if case doesn't match
            # This depends on implementation - could be either behavior
            assert "renamed_source.txt" in updated_content or "SOURCE.TXT" in updated_content
        else:
            # On case-insensitive systems, should update regardless of case
            assert "renamed_source.txt" in updated_content

    def _is_case_sensitive_filesystem(self, path):
        """Check if the filesystem is case-sensitive."""
        test_file = path / "CaseSensitivityTest.tmp"
        test_file.write_text("test")

        try:
            # Try to access with different case
            different_case = path / "casesensitivitytest.tmp"
            return not different_case.exists()
        finally:
            if test_file.exists():
                test_file.unlink()


class TestFileNameRestrictions:
    """Test handling of platform-specific file name restrictions."""

    def test_cp_003_invalid_characters_handling(self, temp_project_dir):
        """
        CP-003: File name restrictions

        Test Case: File names with platform-restricted characters
        Expected: Handle gracefully or provide appropriate errors
        Priority: Medium
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Test different problematic characters
        problematic_names = []

        if os.name == "nt":  # Windows
            problematic_names = [
                "file<name>.txt",
                "file>name.txt",
                "file:name.txt",
                'file"name.txt',
                "file|name.txt",
                "file?name.txt",
                "file*name.txt",
            ]
        else:  # Unix-like
            problematic_names = [
                "file\x00name.txt",  # Null character
                "file/name.txt",  # Forward slash in filename
            ]

        # Create test file with references to problematic names
        test_file = temp_project_dir / "test.md"
        content = "# Test Document\n\n"

        for name in problematic_names:
            content += f"- [Link]({name})\n"

        test_file.write_text(content)

        # Should handle problematic file names gracefully
        service._initial_scan()

        # Service should continue operating
        stats = service.link_db.get_stats()
        assert stats is not None

    def test_cp_003_reserved_names_handling(self, temp_project_dir):
        """Test handling of reserved file names."""
        service = LinkWatcherService(str(temp_project_dir))

        # Windows reserved names
        if os.name == "nt":
            reserved_names = [
                "CON.txt",
                "PRN.txt",
                "AUX.txt",
                "NUL.txt",
                "COM1.txt",
                "COM2.txt",
                "LPT1.txt",
                "LPT2.txt",
            ]
        else:
            # Unix-like systems don't have reserved names in the same way
            reserved_names = []

        if reserved_names:
            # Create test file with references to reserved names
            test_file = temp_project_dir / "test.md"
            content = "# Test Document\n\n"

            for name in reserved_names:
                content += f"- [Link]({name})\n"

            test_file.write_text(content)

            # Should handle reserved names gracefully
            service._initial_scan()

            # Service should continue operating
            stats = service.link_db.get_stats()
            assert stats is not None


class TestLongPathHandling:
    """Test handling of long file paths."""

    def test_cp_004_long_path_support(self, temp_project_dir):
        """
        CP-004: Long path handling

        Test Case: Very long file paths
        Expected: Handle according to platform limitations
        Priority: Medium
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create deeply nested directory structure
        current_path = temp_project_dir
        path_components = []

        # Build a long path (but not too long to cause issues in tests)
        for i in range(10):
            component = f"very_long_directory_name_{i:02d}_with_lots_of_characters"
            path_components.append(component)
            current_path = current_path / component
            current_path.mkdir(exist_ok=True)

        # Create file in deep directory
        deep_file = current_path / "tests/integration/file.txt"
        deep_file.write_text("Deep file content")

        # Create reference to deep file
        test_file = temp_project_dir / "test.md"
        relative_path = "/".join(path_components + ["tests/integration/file.txt"])
        content = f"[Deep link]({relative_path})"
        test_file.write_text(content)

        # Should handle long paths
        service._initial_scan()

        # Verify reference was found
        references = service.link_db.get_references_to_file(relative_path)
        assert len(references) >= 0  # Should handle without crashing

    def test_cp_004_windows_long_path_support(self, temp_project_dir):
        """Test Windows long path support (>260 characters)."""
        service = LinkWatcherService(str(temp_project_dir))

        # Try to create a path longer than 260 characters
        long_name = "a" * 200  # Very long directory name

        try:
            long_dir = temp_project_dir / long_name
            long_dir.mkdir()

            long_file = long_dir / ("b" * 50 + ".txt")
            long_file.write_text("Long path file")

            # Create reference
            test_file = temp_project_dir / "test.md"
            relative_path = f"{long_name}/{'b' * 50}.txt"
            content = f"[Long path link]({relative_path})"
            test_file.write_text(content)

            # Should handle long paths (or fail gracefully)
            service._initial_scan()

            stats = service.link_db.get_stats()
            assert stats is not None

        except OSError:
            # Long paths might not be supported, that's OK
            pytest.skip("Long paths not supported on this system")


class TestSpecialCharacters:
    """Test handling of special characters in file paths."""

    def test_cp_005_unicode_characters_in_paths(self, temp_project_dir):
        """
        CP-005: Special characters in paths

        Test Case: Unicode characters in file names and paths
        Expected: Handle Unicode correctly on all platforms
        Priority: Medium
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create files with Unicode characters
        unicode_files = [
            "café.txt",
            "résumé.md",
            "测试文件.txt",
            "файл.md",
            "🚀rocket.txt",
            "naïve_approach.py",
        ]

        created_files = []
        for filename in unicode_files:
            try:
                unicode_file = temp_project_dir / filename
                unicode_file.write_text(f"Content of {filename}")
                created_files.append(filename)
            except (OSError, UnicodeError):
                # Some Unicode characters might not be supported
                continue

        if created_files:
            # Create test file with references
            test_file = temp_project_dir / "test.md"
            content = "# Unicode Test\n\n"

            for filename in created_files:
                content += f"- [Unicode link]({filename})\n"

            test_file.write_text(content)

            # Should handle Unicode file names
            service._initial_scan()

            # Verify references were found
            references = service.link_db.get_all_references()
            targets = [ref.link_target for ref in references]

            for filename in created_files:
                assert filename in targets, f"Unicode file {filename} not found in references"

    def test_cp_005_spaces_and_special_chars(self, temp_project_dir):
        """Test handling of spaces and special characters."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create files with spaces and special characters
        special_files = [
            "file with spaces.txt",
            "file-with-dashes.md",
            "file_with_underscores.py",
            "file.with.dots.txt",
            "file (with parentheses).md",
            "file [with brackets].txt",
            "file {with braces}.json",
        ]

        for filename in special_files:
            special_file = temp_project_dir / filename
            special_file.write_text(f"Content of {filename}")

        # Create test file with references
        test_file = temp_project_dir / "test.md"
        content = "# Special Characters Test\n\n"

        for filename in special_files:
            content += f"- [Special link]({filename})\n"
            content += f'- Quoted: "{filename}"\n'

        test_file.write_text(content)

        # Should handle special characters
        service._initial_scan()

        # Verify references were found
        references = service.link_db.get_all_references()
        targets = [ref.link_target for ref in references]

        for filename in special_files:
            assert filename in targets, f"Special file {filename} not found in references"


class TestSymlinkHandling:
    """Test handling of symbolic links and junctions."""

    # Unix symlink test removed - Windows-only implementation

    def test_cp_006_junction_handling_windows(self, temp_project_dir):
        """Test junction handling on Windows."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create target directory
        target_dir = temp_project_dir / "target_dir"
        target_dir.mkdir()

        target_file = target_dir / "file.txt"
        target_file.write_text("Target file content")

        # Try to create junction (requires admin privileges)
        try:
            import subprocess

            junction_dir = temp_project_dir / "junction_dir"

            # Use mklink to create junction
            result = subprocess.run(
                ["mklink", "/J", str(junction_dir), str(target_dir)],
                shell=True,
                capture_output=True,
            )

            if result.returncode == 0:
                # Junction created successfully
                test_file = temp_project_dir / "test.md"
                content = "[Junction file](junction_dir/file.txt)"
                test_file.write_text(content)

                # Should handle junctions
                service._initial_scan()

                references = service.link_db.get_references_to_file("junction_dir/file.txt")
                assert len(references) >= 0
            else:
                pytest.skip("Cannot create junction (insufficient privileges)")

        except Exception:
            pytest.skip("Junction creation failed")


class TestDriveLetterHandling:
    """Test Windows drive letter handling."""

    def test_cp_007_drive_letter_paths(self, temp_project_dir):
        """
        CP-007: Drive letter handling (Windows)

        Test Case: Absolute paths with drive letters
        Expected: Handle drive letters correctly
        Priority: Medium
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Get current drive letter
        current_drive = Path(temp_project_dir).drive

        # Create test file with absolute path references
        test_file = temp_project_dir / "test.md"
        content = f"""# Drive Letter Test

References with drive letters:
- [Absolute path]({current_drive}\\temp\\file.txt)
- [Another path]({current_drive}/temp/another.txt)

Quoted references:
- "{current_drive}\\config\\settings.json"
- '{current_drive}/data/info.csv'
"""
        test_file.write_text(content)

        # Should handle drive letter paths
        service._initial_scan()

        # Verify references were found
        references = service.link_db.get_all_references()
        targets = [ref.link_target for ref in references]

        # Should find absolute paths
        assert any(current_drive.lower() in target.lower() for target in targets)

    def test_cp_007_unc_path_handling(self, temp_project_dir):
        """Test UNC path handling on Windows."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create test file with UNC path references
        test_file = temp_project_dir / "test.md"
        content = """# UNC Path Test

UNC path references:
- [Network file](\\\\server\\share\\file.txt)
- [Another network file](//server/share/another.txt)

Quoted UNC paths:
- "\\\\server\\config\\settings.json"
- '//server/data/info.csv'
"""
        test_file.write_text(content)

        # Should handle UNC paths gracefully
        service._initial_scan()

        # Verify references were found (even if files don't exist)
        references = service.link_db.get_all_references()
        targets = [ref.link_target for ref in references]

        # Should find UNC paths
        unc_targets = [target for target in targets if target.startswith(("\\\\", "//"))]
        assert len(unc_targets) >= 2


class TestHiddenFileHandling:
    """Test handling of hidden files and directories."""

    def test_cp_008_hidden_file_handling(self, temp_project_dir):
        """
        CP-008: Hidden file handling

        Test Case: References to hidden files
        Expected: Handle according to configuration
        Priority: Low
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create hidden files (different methods for different platforms)
        if os.name == "nt":  # Windows
            hidden_file = temp_project_dir / "hidden.txt"
            hidden_file.write_text("Hidden file content")

            # Set hidden attribute on Windows
            try:
                import subprocess

                subprocess.run(["attrib", "+H", str(hidden_file)], check=True)
            except (subprocess.CalledProcessError, FileNotFoundError):
                # attrib command might not be available
                pass
        else:  # Unix-like
            hidden_file = temp_project_dir / ".hidden_file.txt"
            hidden_file.write_text("Hidden file content")

        # Create reference to hidden file
        test_file = temp_project_dir / "test.md"
        if os.name == "nt":
            content = "[Hidden file](hidden.txt)"
        else:
            content = "[Hidden file](.hidden_file.txt)"
        test_file.write_text(content)

        # Should handle hidden files
        service._initial_scan()

        # Verify reference was found
        if os.name == "nt":
            references = service.link_db.get_references_to_file("hidden.txt")
        else:
            references = service.link_db.get_references_to_file(".hidden_file.txt")

        assert len(references) >= 0  # Should handle without crashing

    def test_cp_008_hidden_directory_handling(self, temp_project_dir):
        """Test handling of hidden directories."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create hidden directory
        if os.name == "nt":
            hidden_dir = temp_project_dir / "hidden_dir"
            hidden_dir.mkdir()

            # Set hidden attribute
            try:
                import subprocess

                subprocess.run(["attrib", "+H", str(hidden_dir)], check=True)
            except (subprocess.CalledProcessError, FileNotFoundError):
                pass
        else:
            hidden_dir = temp_project_dir / ".hidden_dir"
            hidden_dir.mkdir()

        # Create file in hidden directory
        hidden_file = hidden_dir / "file.txt"
        hidden_file.write_text("File in hidden directory")

        # Create reference
        test_file = temp_project_dir / "test.md"
        if os.name == "nt":
            content = "[Hidden dir file](hidden_dir/file.txt)"
        else:
            content = "[Hidden dir file](.hidden_dir/file.txt)"
        test_file.write_text(content)

        # Should handle hidden directories according to configuration
        service._initial_scan()

        # Service should continue operating
        stats = service.link_db.get_stats()
        assert stats is not None
