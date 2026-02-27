"""
Test suite for directory move detection (PD-BUG-016) and nested directory
movement (PD-BUG-006).

PD-BUG-016: On Windows, watchdog reports directory moves as a FileDeletedEvent
with is_directory=False followed by individual FileCreatedEvents instead of a
DirMovedEvent. Tests simulate real Windows behavior (is_directory=False) and
route through on_deleted() to verify the DB-based directory detection.

PD-BUG-006: When a directory containing files is moved, Python import
references (dot-notation) were incorrectly flagged as stale by the updater
because the stale detection compared slash-notation link_target against
dot-notation line content.
"""

import time
from pathlib import Path

import pytest
from watchdog.events import DirMovedEvent, FileCreatedEvent, FileDeletedEvent

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.service import LinkWatcherService
from linkwatcher.updater import LinkUpdater


class TestGetFilesUnderDirectory:
    """Tests for _get_files_under_directory helper."""

    @pytest.fixture
    def handler_with_db(self, tmp_path):
        """Set up handler with a populated database."""
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Create test files
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        sub_dir = docs_dir / "sub"
        sub_dir.mkdir()

        guide = docs_dir / "guide.md"
        guide.write_text("# Guide\nSee [api](api.md) for details.")
        api = docs_dir / "api.md"
        api.write_text("# API\nReference docs.")
        nested = sub_dir / "nested.md"
        nested.write_text("# Nested\nSee [guide](../guide.md).")

        # Also create a file outside docs/
        readme = tmp_path / "README.md"
        readme.write_text("# Project\nSee [guide](docs/guide.md) and [api](docs/api.md).")

        # Scan all files into the database
        for file_path in tmp_path.rglob("*.md"):
            rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
            references = parser.parse_file(str(file_path))
            for ref in references:
                ref.file_path = rel_path
                link_db.add_link(ref)

        return handler, link_db, tmp_path

    def test_finds_target_files(self, handler_with_db):
        """Files that are link targets under the directory are found."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._get_files_under_directory("docs")
        # docs/api.md is a target (referenced from guide.md and README.md)
        assert any("docs/api.md" in f for f in files)

    def test_finds_source_files(self, handler_with_db):
        """Files that contain links under the directory are found."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._get_files_under_directory("docs")
        # docs/guide.md contains a link (is in files_with_links)
        assert any("docs/guide.md" in f for f in files)

    def test_finds_nested_files(self, handler_with_db):
        """Files in nested subdirectories are found."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._get_files_under_directory("docs")
        # docs/sub/nested.md contains a link
        assert any("docs/sub/nested.md" in f for f in files)

    def test_excludes_files_outside_directory(self, handler_with_db):
        """Files outside the specified directory are not included."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._get_files_under_directory("docs")
        assert not any("README.md" == f for f in files)
        for f in files:
            assert f.startswith("docs/"), f"File '{f}' should start with 'docs/'"

    def test_empty_result_for_unknown_directory(self, handler_with_db):
        """Returns empty set for a directory not in the database."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._get_files_under_directory("nonexistent")
        assert len(files) == 0

    def test_resolves_relative_targets_in_nested_project(self, tmp_path):
        """Link targets stored as relative-to-source paths are resolved correctly.

        Mirrors real-world scenario: project is in a subdirectory (e.g.,
        manual_markdown_tests/test_project/) and the markdown file at the
        project root references files with short relative paths like
        'api/reference.txt'.  The DB key is just 'api/reference.txt', but
        _get_files_under_directory is called with the full project-root-
        relative path 'sub_project/api'.  The function must resolve the
        relative target to 'sub_project/api/reference.txt' so the prefix
        match succeeds.
        """
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Create nested project structure
        project_dir = tmp_path / "sub_project"
        project_dir.mkdir()
        api_dir = project_dir / "api"
        api_dir.mkdir()
        ref_file = api_dir / "reference.txt"
        ref_file.write_text("Reference content")
        readme = project_dir / "README.md"
        readme.write_text("# Project\n[API](api/reference.txt)\n")

        # Parse README into DB (simulating initial scan)
        refs = parser.parse_file(str(readme))
        for ref in refs:
            ref.file_path = "sub_project/README.md"
            link_db.add_link(ref)

        # DB key is "api/reference.txt" (relative to README.md)
        # but we search with the full project-root-relative dir path
        files = handler._get_files_under_directory("sub_project/api")
        assert len(files) > 0
        assert any("sub_project/api/reference.txt" in f for f in files)

    def test_file_path_not_treated_as_directory(self, handler_with_db):
        """A file path passed to _get_files_under_directory returns empty set.

        Regression test for PD-BUG-020: When a single file is deleted,
        on_deleted calls _get_files_under_directory with the file's path.
        If the dir_prefix lacks a trailing slash (because normalize_path
        strips it), the file itself can match via startswith, causing
        the handler to treat a single-file move as a directory move and
        walk the entire project tree.
        """
        handler, link_db, tmp_path = handler_with_db
        # Pass a known file path (not a directory) — should return empty
        files = handler._get_files_under_directory("docs/guide.md")
        assert len(files) == 0, (
            f"_get_files_under_directory returned {len(files)} file(s) for a "
            f"file path 'docs/guide.md'; expected 0. Files: {files}"
        )

    def test_dir_prefix_trailing_slash_prevents_false_prefix_match(self, handler_with_db):
        """The dir_prefix in _get_files_under_directory must have a trailing slash.

        Without a trailing slash, 'docs' as prefix would match 'docs-other/...'
        via startswith. The trailing slash ensures only actual children match.

        Regression test for PD-BUG-020.
        """
        handler, link_db, tmp_path = handler_with_db

        # Create a sibling directory that shares a prefix with 'docs'
        docs_other = tmp_path / "docs-other"
        docs_other.mkdir()
        sibling = docs_other / "sibling.md"
        sibling.write_text("# Sibling doc")

        # Scan sibling into DB
        from linkwatcher.parser import LinkParser
        parser = LinkParser()
        refs = parser.parse_file(str(sibling))
        for ref in refs:
            ref.file_path = "docs-other/sibling.md"
            link_db.add_link(ref)
        link_db.files_with_links.add("docs-other/sibling.md")

        files = handler._get_files_under_directory("docs")
        assert not any("docs-other" in f for f in files), (
            f"Files from 'docs-other/' matched prefix 'docs' — "
            f"trailing slash missing in dir_prefix. Files: {files}"
        )


class TestDirectoryDeleteBuffering:
    """Tests that _handle_directory_deleted buffers files for move detection."""

    @pytest.fixture
    def setup(self, tmp_path):
        """Set up handler with files in a directory."""
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Create directory with files
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        guide = docs_dir / "guide.md"
        guide.write_text("# Guide")
        api = docs_dir / "api.md"
        api.write_text("# API")

        # Create references to the files
        readme = tmp_path / "README.md"
        readme.write_text("See [guide](docs/guide.md) and [api](docs/api.md).")

        # Populate database
        for file_path in tmp_path.rglob("*.md"):
            rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
            references = parser.parse_file(str(file_path))
            for ref in references:
                ref.file_path = rel_path
                link_db.add_link(ref)

        return handler, link_db, tmp_path, docs_dir

    def test_directory_delete_adds_files_to_pending(self, setup):
        """Directory delete buffers known files in pending_dir_moves.

        On Windows, watchdog fires FileDeletedEvent with is_directory=False
        for directory deletes. The on_deleted routing must detect this via
        database lookup and route to _handle_directory_deleted, which
        creates a _PendingDirMove entry (not per-file pending_deletes).
        """
        handler, link_db, tmp_path, docs_dir = setup

        # Simulate directory delete event as Windows watchdog does:
        # is_directory=False even though this is a directory
        event = FileDeletedEvent(str(docs_dir))
        event.is_directory = False
        handler.on_deleted(event)

        # Check that a PendingDirMove was created (not per-file pending_deletes)
        assert (
            "docs" in handler.pending_dir_moves
        ), f"Expected 'docs' in pending_dir_moves, got: {list(handler.pending_dir_moves.keys())}"
        pending = handler.pending_dir_moves["docs"]
        assert any(
            "docs/guide.md" in f for f in pending.unmatched
        ), f"docs/guide.md should be in unmatched, got: {pending.unmatched}"
        assert any(
            "docs/api.md" in f for f in pending.unmatched
        ), f"docs/api.md should be in unmatched, got: {pending.unmatched}"

        # Clean up timer to avoid test warnings
        if pending.max_timer:
            pending.max_timer.cancel()

    def test_directory_delete_creates_pending_dir_move(self, setup):
        """PendingDirMove tracks correct metadata."""
        handler, link_db, tmp_path, docs_dir = setup

        event = FileDeletedEvent(str(docs_dir))
        event.is_directory = False
        handler.on_deleted(event)

        pending = handler.pending_dir_moves["docs"]
        assert pending.new_dir is None, "new_dir should be None before any match"
        assert pending.matched_count == 0
        assert pending.total_expected == len(pending.unmatched)

        # Clean up timer
        if pending.max_timer:
            pending.max_timer.cancel()

    def test_empty_directory_no_directory_buffering(self, setup):
        """Directory with no known files is NOT routed to _handle_directory_deleted.

        When is_directory=False and no files are known under the path,
        on_deleted routes to _handle_file_deleted instead. This buffers
        just the directory path itself (harmless — won't match any file
        creates), rather than querying the DB for child files.
        """
        handler, link_db, tmp_path, docs_dir = setup

        # Create an empty directory not known to the database
        empty_dir = tmp_path / "empty"
        empty_dir.mkdir()

        event = FileDeletedEvent(str(empty_dir))
        event.is_directory = False
        handler.on_deleted(event)

        # _handle_file_deleted buffers the directory path itself, but
        # no child files should be buffered (as _handle_directory_deleted would do)
        pending_keys = set(handler.pending_deletes.keys())
        assert all(
            "/" not in k or k == "empty" for k in pending_keys
        ), f"No child files should be buffered for unknown directory, got: {pending_keys}"

    def test_pending_dir_move_prefix_has_trailing_slash(self, setup):
        """Regression: dir_prefix must end with '/' for correct path slicing.

        PD-BUG-019 fix discovered that normalize_path() strips trailing
        slashes (via os.path.normpath), so dir_prefix must be constructed
        as normalize_path(dir) + "/" to ensure rel_within_dir doesn't
        start with a leading slash when sliced from known_file paths.
        """
        handler, link_db, tmp_path, docs_dir = setup

        event = FileDeletedEvent(str(docs_dir))
        event.is_directory = False
        handler.on_deleted(event)

        pending = handler.pending_dir_moves["docs"]

        # dir_prefix MUST end with "/" for correct slicing
        assert pending.dir_prefix.endswith(
            "/"
        ), f"dir_prefix must end with '/', got: {repr(pending.dir_prefix)}"

        # Verify slicing produces correct relative paths (no leading slash)
        for known_file in pending.unmatched:
            rel_within = known_file[len(pending.dir_prefix) :]
            assert not rel_within.startswith(
                "/"
            ), f"rel_within_dir should not start with '/', got: {repr(rel_within)} for {known_file}"

        # Clean up timer
        if pending.max_timer:
            pending.max_timer.cancel()

    def test_single_file_delete_not_treated_as_directory(self, setup):
        """Regression: single file delete must NOT trigger directory move detection.

        PD-BUG-020: When a file known to the database is deleted (is_directory=False),
        _get_files_under_directory was called with the file path. Because
        normalize_path stripped the trailing slash from the dir_prefix, the
        file itself could match via startswith, causing on_deleted to route
        to _handle_directory_deleted. This made the handler treat a single-file
        move as a directory move and walk the entire project tree.
        """
        handler, link_db, tmp_path, docs_dir = setup

        guide_path = docs_dir / "guide.md"

        # Simulate single file deletion (not a directory)
        event = FileDeletedEvent(str(guide_path))
        event.is_directory = False
        handler.on_deleted(event)

        # Single file should go to pending_deletes (per-file move detection),
        # NOT to pending_dir_moves (directory move detection)
        assert len(handler.pending_dir_moves) == 0, (
            f"Single file delete should NOT create pending_dir_moves entry, "
            f"but found: {list(handler.pending_dir_moves.keys())}"
        )
        assert "docs/guide.md" in handler.pending_deletes, (
            f"Single file delete should be in pending_deletes, "
            f"but got: {list(handler.pending_deletes.keys())}"
        )


class TestDirectoryMoveViaDeleteCreate:
    """End-to-end tests for directory move detection via delete+create events."""

    def test_directory_move_updates_references(self, tmp_path):
        """Full flow: dir delete + file creates = references updated.

        With the batch directory move detection (PD-BUG-019 fix),
        processing happens on a separate thread after all files match.
        """
        # Setup
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        new_docs_dir = tmp_path / "documentation"
        new_docs_dir.mkdir()

        guide = docs_dir / "guide.md"
        guide.write_text("# Guide\nContent here.")

        readme = tmp_path / "README.md"
        readme.write_text("# Project\n\nSee [guide](docs/guide.md) for details.")

        # Initialize service and scan
        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Verify initial references
        refs = service.link_db.get_references_to_file("docs/guide.md")
        assert len(refs) >= 1, "Should have at least 1 reference to docs/guide.md"

        # Step 1: Simulate directory delete event (as watchdog does on Windows)
        dir_delete_event = FileDeletedEvent(str(docs_dir))
        dir_delete_event.is_directory = False
        service.handler.on_deleted(dir_delete_event)

        # Verify files were buffered in pending_dir_moves
        assert (
            len(service.handler.pending_dir_moves) >= 1
        ), "Should have pending_dir_moves entry"

        # Step 2: Move the actual file to new location
        new_guide = new_docs_dir / "guide.md"
        guide.rename(new_guide)

        # Step 3: Simulate file create event (triggers batch processing)
        file_create_event = FileCreatedEvent(str(new_guide))
        service.handler.on_created(file_create_event)

        # Wait for processing thread to complete
        time.sleep(2.0)

        # Verify: reference should be updated
        readme_content = readme.read_text()
        assert (
            "documentation/guide.md" in readme_content
        ), f"Expected 'documentation/guide.md' in README, got: {readme_content}"
        assert (
            "docs/guide.md" not in readme_content
        ), f"Old reference 'docs/guide.md' should be removed from README"

    def test_directory_move_multiple_files(self, tmp_path):
        """Directory move with multiple files all detected as moves.

        The batch detection (PD-BUG-019 fix) infers new_dir from the
        first match, then matches subsequent files by prefix. Processing
        triggers when all files are matched.
        """
        # Setup
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        new_docs_dir = tmp_path / "documentation"
        new_docs_dir.mkdir()

        guide = docs_dir / "guide.md"
        guide.write_text("# Guide")
        api = docs_dir / "api.md"
        api.write_text("# API")

        readme = tmp_path / "README.md"
        readme.write_text("# Project\n\n" "- [Guide](docs/guide.md)\n" "- [API](docs/api.md)\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Step 1: Directory delete (Windows: is_directory=False)
        dir_delete_event = FileDeletedEvent(str(docs_dir))
        dir_delete_event.is_directory = False
        service.handler.on_deleted(dir_delete_event)

        # Step 2: Move files and fire create events
        new_guide = new_docs_dir / "guide.md"
        guide.rename(new_guide)
        service.handler.on_created(FileCreatedEvent(str(new_guide)))

        new_api = new_docs_dir / "api.md"
        api.rename(new_api)
        service.handler.on_created(FileCreatedEvent(str(new_api)))

        # Wait for processing thread to complete
        time.sleep(2.0)

        # Verify both references updated
        readme_content = readme.read_text()
        assert "documentation/guide.md" in readme_content
        assert "documentation/api.md" in readme_content
        assert "docs/guide.md" not in readme_content
        assert "docs/api.md" not in readme_content

    def test_directory_move_nested_files(self, tmp_path):
        """Directory move with nested subdirectory files.

        The batch detection uses relative-path-within-dir matching,
        so nested/sub/file.md correctly matches against the pending entry.
        """
        # Setup
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        sub_dir = docs_dir / "guides"
        sub_dir.mkdir()
        new_docs_dir = tmp_path / "documentation"
        new_docs_dir.mkdir()
        new_sub_dir = new_docs_dir / "guides"
        new_sub_dir.mkdir()

        nested = sub_dir / "setup.md"
        nested.write_text("# Setup Guide")

        readme = tmp_path / "README.md"
        readme.write_text("See [setup](docs/guides/setup.md).")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Directory delete (Windows: is_directory=False)
        dir_delete_event = FileDeletedEvent(str(docs_dir))
        dir_delete_event.is_directory = False
        service.handler.on_deleted(dir_delete_event)

        # File create at new location
        new_nested = new_sub_dir / "setup.md"
        nested.rename(new_nested)
        service.handler.on_created(FileCreatedEvent(str(new_nested)))

        # Wait for processing thread
        time.sleep(2.0)

        # Verify
        readme_content = readme.read_text()
        assert "documentation/guides/setup.md" in readme_content
        assert "docs/guides/setup.md" not in readme_content

    def test_true_directory_delete_processes_normally(self, tmp_path):
        """When a directory is actually deleted (no creates follow), files
        are processed as deletions after the max timeout."""
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()

        guide = docs_dir / "guide.md"
        guide.write_text("# Guide")

        readme = tmp_path / "README.md"
        readme.write_text("See [guide](docs/guide.md).")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Shorten max timeout for test speed
        service.handler.dir_move_max_timeout = 0.2

        # Directory delete (Windows: is_directory=False)
        dir_delete_event = FileDeletedEvent(str(docs_dir))
        dir_delete_event.is_directory = False
        service.handler.on_deleted(dir_delete_event)

        # Verify files are buffered in pending_dir_moves
        assert len(service.handler.pending_dir_moves) >= 1

        # Wait for max timeout + processing
        time.sleep(0.5)

        # Pending should be cleared (processed as actual deletions)
        assert len(service.handler.pending_dir_moves) == 0


class TestNestedDirectoryMovePythonImports:
    """Regression tests for PD-BUG-006: nested directory movement must update
    Python import references (dot-notation) in addition to markdown links."""

    def test_python_imports_updated_on_directory_move(self, tmp_path):
        """Python import references are updated when containing directory moves."""
        # Setup
        src_dir = tmp_path / "src"
        src_dir.mkdir()
        utils_dir = src_dir / "utils"
        utils_dir.mkdir()

        helper = utils_dir / "helper.py"
        helper.write_text("def do_stuff(): pass")

        main_py = tmp_path / "main.py"
        main_py.write_text("from src.utils.helper import do_stuff\n")

        # Initialize and scan
        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Move utils -> helpers
        helpers_dir = src_dir / "helpers"
        utils_dir.rename(helpers_dir)

        move_event = DirMovedEvent(str(utils_dir), str(helpers_dir))
        service.handler.on_moved(move_event)

        # Verify Python import updated
        updated = main_py.read_text()
        assert "src.helpers.helper" in updated, f"Expected 'src.helpers.helper' in: {updated}"
        assert "src.utils.helper" not in updated

    def test_markdown_and_python_refs_both_updated(self, tmp_path):
        """Both markdown links and Python imports update for the same directory move."""
        src_dir = tmp_path / "src"
        src_dir.mkdir()
        utils_dir = src_dir / "utils"
        utils_dir.mkdir()

        mod = utils_dir / "mod.py"
        mod.write_text("# module")

        readme = tmp_path / "README.md"
        readme.write_text("See [mod](src/utils/mod.py) for details.\n")

        app = tmp_path / "app.py"
        app.write_text("from src.utils.mod import something\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        helpers_dir = src_dir / "helpers"
        utils_dir.rename(helpers_dir)

        move_event = DirMovedEvent(str(utils_dir), str(helpers_dir))
        service.handler.on_moved(move_event)

        readme_content = readme.read_text()
        assert "src/helpers/mod.py" in readme_content
        assert "src/utils/mod.py" not in readme_content

        app_content = app.read_text()
        assert "src.helpers.mod" in app_content
        assert "src.utils.mod" not in app_content

    def test_nested_subdirectory_python_imports(self, tmp_path):
        """Python imports for files in nested subdirectories are updated."""
        pkg = tmp_path / "pkg"
        pkg.mkdir()
        sub = pkg / "sub"
        sub.mkdir()
        deep = sub / "deep"
        deep.mkdir()

        target = deep / "worker.py"
        target.write_text("class Worker: pass")

        consumer = tmp_path / "consumer.py"
        consumer.write_text("from pkg.sub.deep.worker import Worker\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        new_sub = pkg / "newsub"
        sub.rename(new_sub)

        move_event = DirMovedEvent(str(sub), str(new_sub))
        service.handler.on_moved(move_event)

        updated = consumer.read_text()
        assert (
            "pkg.newsub.deep.worker" in updated
        ), f"Expected 'pkg.newsub.deep.worker' in: {updated}"
        assert "pkg.sub.deep.worker" not in updated

    def test_database_updated_after_nested_dir_move(self, tmp_path):
        """Database reflects new paths after nested directory move."""
        src_dir = tmp_path / "src"
        src_dir.mkdir()
        utils_dir = src_dir / "utils"
        utils_dir.mkdir()

        mod = utils_dir / "mod.py"
        mod.write_text("# module")

        readme = tmp_path / "README.md"
        readme.write_text("See [mod](src/utils/mod.py).\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Verify initial state
        old_refs = service.link_db.get_references_to_file("src/utils/mod.py")
        assert len(old_refs) >= 1

        helpers_dir = src_dir / "helpers"
        utils_dir.rename(helpers_dir)

        move_event = DirMovedEvent(str(utils_dir), str(helpers_dir))
        service.handler.on_moved(move_event)

        # Old path should have no references
        old_refs_after = service.link_db.get_references_to_file("src/utils/mod.py")
        assert len(old_refs_after) == 0, f"Expected 0 refs to old path, got {len(old_refs_after)}"

        # New path should have references
        new_refs = service.link_db.get_references_to_file("src/helpers/mod.py")
        assert len(new_refs) >= 1
