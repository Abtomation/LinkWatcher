"""
Integration Tests for Complex Scenarios (CS Test Cases)

This module implements the CS test cases from our comprehensive test documentation,
focusing on complex multi-file scenarios and edge cases.

Test Cases Implemented:
- CS-001: Multiple references to same file
- CS-002: Circular references
- CS-003: Files with same name in different directories
- CS-004: Case sensitivity handling
- CS-005: Special characters in filenames
- CS-006: Very long file paths
"""

from pathlib import Path

import pytest

from linkwatcher.service import LinkWatcherService


class TestComplexScenarios:
    """Integration tests for complex multi-file scenarios."""

    def test_cs_001_multiple_references_same_file(self, temp_project_dir):
        """
        CS-001: Multiple references to same file

        Test Case: 5 files referencing target.txt, move target
        Expected: All 5 references updated
        Priority: Critical
        """
        # Create target file
        target_file = temp_project_dir / "target.txt"
        target_file.write_text("Important content")

        # Create 5 files with references to target
        referencing_files = []

        # File 1: README with markdown link
        readme = temp_project_dir / "README.md"
        readme.write_text("# Project\n\nSee [target file](target.txt) for details.")
        referencing_files.append(readme)

        # File 2: Config with YAML reference
        config = temp_project_dir / "config.yaml"
        config.write_text("data_file: target.txt\nother: value")
        referencing_files.append(config)

        # File 3: JSON settings
        settings = temp_project_dir / "settings.json"
        settings.write_text('{"input": "target.txt", "version": 1}')
        referencing_files.append(settings)

        # File 4: Python script
        script = temp_project_dir / "process.py"
        script.write_text('# Process target.txt\nfile_path = "target.txt"')
        referencing_files.append(script)

        # File 5: Documentation
        docs = temp_project_dir / "DOCS.md"
        docs.write_text('Documentation references "target.txt" and [target](target.txt).')
        referencing_files.append(docs)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify all references were found
        refs = service.link_db.get_references_to_file("target.txt")
        assert len(refs) >= 5  # Should find at least 5 references

        # Move target file
        new_target = temp_project_dir / "data" / "important.txt"
        new_target.parent.mkdir()
        target_file.rename(new_target)

        # Process move event
        service.handler.on_moved(None, str(target_file), str(new_target), False)

        # Verify all files were updated
        for ref_file in referencing_files:
            content = ref_file.read_text()
            assert "data/important.txt" in content
            assert "target.txt" not in content

        # Verify database was updated
        new_refs = service.link_db.get_references_to_file("data/important.txt")
        old_refs = service.link_db.get_references_to_file("target.txt")

        assert len(new_refs) >= 5
        assert len(old_refs) == 0

    def test_cs_002_circular_references(self, temp_project_dir):
        """
        CS-002: Circular references

        Test Case: File A → File B → File A, move File A
        Expected: Both references updated correctly
        Priority: High
        """
        # Create File A
        file_a = temp_project_dir / "file_a.md"
        file_a_content = """# File A

This file references [File B](file_b.md).
Also see "file_b.md" for more info.
"""
        file_a.write_text(file_a_content)

        # Create File B
        file_b = temp_project_dir / "file_b.md"
        file_b_content = """# File B

This file references [File A](file_a.md).
Back to "file_a.md" for context.
"""
        file_b.write_text(file_b_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify circular references were found
        refs_to_a = service.link_db.get_references_to_file("file_a.md")
        refs_to_b = service.link_db.get_references_to_file("file_b.md")

        assert len(refs_to_a) >= 2  # References from file_b
        assert len(refs_to_b) >= 2  # References from file_a

        # Move File A
        new_file_a = temp_project_dir / "documents" / "document_a.md"
        new_file_a.parent.mkdir()
        file_a.rename(new_file_a)

        # Process move event
        service.handler.on_moved(None, str(file_a), str(new_file_a), False)

        # Verify File B was updated to reference new location of File A
        file_b_updated = file_b.read_text()
        assert "documents/document_a.md" in file_b_updated
        assert "file_a.md" not in file_b_updated

        # Verify moved File A still references File B correctly
        new_file_a_content = new_file_a.read_text()
        assert "file_b.md" in new_file_a_content or "../file_b.md" in new_file_a_content

        # Verify database reflects the changes
        new_refs_to_a = service.link_db.get_references_to_file("documents/document_a.md")
        old_refs_to_a = service.link_db.get_references_to_file("file_a.md")

        assert len(new_refs_to_a) >= 2
        assert len(old_refs_to_a) == 0

    def test_cs_003_same_name_different_directories(self, temp_project_dir):
        """
        CS-003: Files with same name in different directories

        Test Case: Move docs/file.txt when src/file.txt exists
        Expected: Only correct references updated
        Priority: High
        """
        # Create directory structure
        docs_dir = temp_project_dir / "docs"
        src_dir = temp_project_dir / "src"
        docs_dir.mkdir()
        src_dir.mkdir()

        # Create files with same name in different directories
        docs_file = docs_dir / "file.txt"
        docs_file.write_text("Documentation content")

        src_file = src_dir / "file.txt"
        src_file.write_text("Source content")

        # Create files with references to both
        readme = temp_project_dir / "README.md"
        readme_content = """# Project

- [Documentation](docs/file.txt)
- [Source](src/file.txt)
- See "docs/file.txt" for docs
- Check "src/file.txt" for source
"""
        readme.write_text(readme_content)

        # Create file that references only docs version
        guide = temp_project_dir / "GUIDE.md"
        guide.write_text("# Guide\n\nRefer to [docs file](docs/file.txt) only.")

        # Create file that references only src version
        build = temp_project_dir / "BUILD.md"
        build.write_text('# Build\n\nCompile "src/file.txt" first.')

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify both files have references
        docs_refs = service.link_db.get_references_to_file("docs/file.txt")
        src_refs = service.link_db.get_references_to_file("src/file.txt")

        assert len(docs_refs) >= 2  # README + GUIDE
        assert len(src_refs) >= 2  # README + BUILD

        # Move only the docs file
        new_docs_file = temp_project_dir / "documentation" / "manual.txt"
        new_docs_file.parent.mkdir()
        docs_file.rename(new_docs_file)

        # Process move event
        service.handler.on_moved(None, str(docs_file), str(new_docs_file), False)

        # Verify only docs references were updated
        readme_updated = readme.read_text()
        guide_updated = guide.read_text()
        build_updated = build.read_text()

        # README should have docs reference updated but src reference unchanged
        assert "documentation/manual.txt" in readme_updated
        assert "src/file.txt" in readme_updated  # This should remain unchanged
        assert "docs/file.txt" not in readme_updated

        # GUIDE should be updated
        assert "documentation/manual.txt" in guide_updated
        assert "docs/file.txt" not in guide_updated

        # BUILD should be unchanged (it only referenced src/file.txt)
        assert "src/file.txt" in build_updated
        assert "documentation/manual.txt" not in build_updated
        assert "docs/file.txt" not in build_updated

        # Verify src file still exists and has correct references
        assert src_file.exists()
        src_refs_after = service.link_db.get_references_to_file("src/file.txt")
        assert len(src_refs_after) >= 2  # Should be unchanged

    def test_cs_004_case_sensitivity_handling(self, temp_project_dir):
        """
        CS-004: Case sensitivity handling

        Test Case: Move File.txt → file.txt on Windows
        Expected: References updated respecting OS case rules
        Priority: Medium
        """
        # Create file with mixed case
        original_file = temp_project_dir / "File.txt"
        original_file.write_text("Content")

        # Create references with various cases
        readme = temp_project_dir / "README.md"
        readme_content = """# Project

References:
- [File](File.txt)
- [file](file.txt)  # This might be the same file on Windows
- [FILE](FILE.txt)  # This might be the same file on Windows
"""
        readme.write_text(readme_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move to different case
        new_file = temp_project_dir / "document.txt"
        original_file.rename(new_file)

        # Process move event
        service.handler.on_moved(None, str(original_file), str(new_file), False)

        # Verify references were updated
        readme_updated = readme.read_text()
        assert "document.txt" in readme_updated

        # The exact behavior depends on the file system case sensitivity
        # On case-insensitive systems, all variations should be updated
        # On case-sensitive systems, only exact matches should be updated

    def test_cs_005_special_characters_filenames(self, temp_project_dir):
        """
        CS-005: Special characters in filenames

        Test Case: Move file with spaces & symbols.txt
        Expected: References with special chars updated
        Priority: Medium
        """
        # Create file with special characters
        special_file = temp_project_dir / "file with spaces & symbols.txt"
        special_file.write_text("Special content")

        # Create references with various quoting
        readme = temp_project_dir / "README.md"
        readme_content = """# Project

References:
- [Special file](file with spaces & symbols.txt)
- "file with spaces & symbols.txt"
- 'file with spaces & symbols.txt'
- `file with spaces & symbols.txt`
"""
        readme.write_text(readme_content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify references were found
        refs = service.link_db.get_references_to_file("file with spaces & symbols.txt")
        assert len(refs) >= 3  # Should find multiple references

        # Move to simpler name
        new_file = temp_project_dir / "special_file.txt"
        special_file.rename(new_file)

        # Process move event
        service.handler.on_moved(None, str(special_file), str(new_file), False)

        # Verify all references were updated
        readme_updated = readme.read_text()
        assert "special_file.txt" in readme_updated
        assert "file with spaces & symbols.txt" not in readme_updated

        # Verify different quote styles were handled
        assert "[Special file](special_file.txt)" in readme_updated
        assert '"special_file.txt"' in readme_updated
        assert "'special_file.txt'" in readme_updated

    def test_cs_006_very_long_file_paths(self, temp_project_dir):
        """
        CS-006: Very long file paths

        Test Case: Move file with 200+ char path
        Expected: Long paths handled correctly
        Priority: Low
        """
        # Create deeply nested directory structure
        deep_path = temp_project_dir
        path_parts = [
            "very",
            "deeply",
            "nested",
            "directory",
            "structure",
            "with",
            "many",
            "levels",
            "of",
            "subdirectories",
            "that",
            "creates",
            "a",
            "very",
            "long",
            "path",
            "for",
            "testing",
            "purposes",
            "only",
        ]

        for part in path_parts:
            deep_path = deep_path / part
            deep_path.mkdir()

        # Create file with long path
        long_path_file = deep_path / "file_with_very_long_path_name_for_testing.txt"
        long_path_file.write_text("Content in deeply nested file")

        # Create reference to long path file
        readme = temp_project_dir / "README.md"
        relative_path = str(long_path_file.relative_to(temp_project_dir))
        readme.write_text(f"# Project\n\nSee [deep file]({relative_path}) for details.")

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify reference was found
        refs = service.link_db.get_references_to_file(relative_path)
        assert len(refs) >= 1

        # Move to shorter path
        new_file = temp_project_dir / "short.txt"
        long_path_file.rename(new_file)

        # Process move event
        service.handler.on_moved(None, str(long_path_file), str(new_file), False)

        # Verify reference was updated
        readme_updated = readme.read_text()
        assert "short.txt" in readme_updated
        assert relative_path not in readme_updated


class TestComplexScenarioEdgeCases:
    """Edge cases for complex scenarios."""

    def test_simultaneous_moves(self, temp_project_dir):
        """Test handling of multiple simultaneous file moves."""
        # Create multiple files
        files = []
        for i in range(5):
            file_path = temp_project_dir / f"file_{i}.txt"
            file_path.write_text(f"Content {i}")
            files.append(file_path)

        # Create file with references to all
        readme = temp_project_dir / "README.md"
        content = "# Files\n\n"
        for i in range(5):
            content += f"- [File {i}](file_{i}.txt)\n"
        readme.write_text(content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move all files simultaneously
        new_files = []
        for i, old_file in enumerate(files):
            new_file = temp_project_dir / f"moved_{i}.txt"
            old_file.rename(new_file)
            new_files.append(new_file)

            # Process move event
            service.handler.on_moved(None, str(old_file), str(new_file), False)

        # Verify all references were updated
        readme_updated = readme.read_text()
        for i in range(5):
            assert f"moved_{i}.txt" in readme_updated
            assert f"file_{i}.txt" not in readme_updated

    def test_move_chain_reaction(self, temp_project_dir):
        """Test chain reaction of file moves."""
        # Create files A → B → C reference chain
        file_a = temp_project_dir / "a.txt"
        file_a.write_text('Content A, see "b.txt"')

        file_b = temp_project_dir / "b.txt"
        file_b.write_text('Content B, see "c.txt"')

        file_c = temp_project_dir / "c.txt"
        file_c.write_text('Content C, see "a.txt"')

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move files in sequence: A → A1, B → B1, C → C1
        moves = [
            (file_a, temp_project_dir / "a1.txt"),
            (file_b, temp_project_dir / "b1.txt"),
            (file_c, temp_project_dir / "c1.txt"),
        ]

        for old_file, new_file in moves:
            old_file.rename(new_file)
            service.handler.on_moved(None, str(old_file), str(new_file), False)

        # Verify final state
        a1_content = (temp_project_dir / "a1.txt").read_text()
        b1_content = (temp_project_dir / "b1.txt").read_text()
        c1_content = (temp_project_dir / "c1.txt").read_text()

        assert "b1.txt" in a1_content
        assert "c1.txt" in b1_content
        assert "a1.txt" in c1_content

    def test_partial_path_matches(self, temp_project_dir):
        """Test that partial path matches are handled correctly."""
        # Create files with similar names
        file1 = temp_project_dir / "test.txt"
        file1.write_text("Test content")

        file2 = temp_project_dir / "test_data.txt"
        file2.write_text("Test data content")

        # Create reference that could match both
        readme = temp_project_dir / "README.md"
        readme.write_text("# Project\n\nSee [test](test.txt) and [data](test_data.txt).")

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move test.txt
        new_file1 = temp_project_dir / "simple.txt"
        file1.rename(new_file1)
        service.handler.on_moved(None, str(file1), str(new_file1), False)

        # Verify only exact match was updated
        readme_updated = readme.read_text()
        assert "simple.txt" in readme_updated
        assert "test_data.txt" in readme_updated  # Should remain unchanged
        assert readme_updated.count("test.txt") == 0  # Should be completely replaced
