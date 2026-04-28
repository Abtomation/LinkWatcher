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

import shutil
import time

import pytest
from watchdog.events import DirMovedEvent, FileCreatedEvent, FileDeletedEvent

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.service import LinkWatcherService
from linkwatcher.updater import LinkUpdater

pytestmark = [
    pytest.mark.feature("1.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.cross_cutting(["0.1.2", "2.2.1", "2.1.1"]),
    pytest.mark.test_type("integration"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-1-1-1-file-system-monitoring.md"
    ),
]


class TestGetFilesUnderDirectory:
    """Tests for get_files_under_directory helper (on DirectoryMoveDetector)."""

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

    def test_excludes_target_only_files(self, handler_with_db):
        """PD-BUG-075: target-only files must NOT be in known_files.

        docs/api.md is referenced by other files but contains no links
        itself, so it is not in files_with_links and must not appear.
        Including target-only files inflates the count with entries that
        can never match filesystem create events.
        """
        handler, link_db, tmp_path = handler_with_db
        files = handler._dir_move_detector.get_files_under_directory("docs")
        # docs/api.md has no links → not a source file → must be excluded
        assert not any("docs/api.md" in f for f in files)

    def test_finds_source_files(self, handler_with_db):
        """Files that contain links under the directory are found."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._dir_move_detector.get_files_under_directory("docs")
        # docs/guide.md contains a link (is in files_with_links)
        assert any("docs/guide.md" in f for f in files)

    def test_finds_nested_files(self, handler_with_db):
        """Files in nested subdirectories are found."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._dir_move_detector.get_files_under_directory("docs")
        # docs/sub/nested.md contains a link
        assert any("docs/sub/nested.md" in f for f in files)

    def test_excludes_files_outside_directory(self, handler_with_db):
        """Files outside the specified directory are not included."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._dir_move_detector.get_files_under_directory("docs")
        assert not any("README.md" == f for f in files)
        for f in files:
            assert f.startswith("docs/"), f"File '{f}' should start with 'docs/'"

    def test_empty_result_for_unknown_directory(self, handler_with_db):
        """Returns empty set for a directory not in the database."""
        handler, link_db, tmp_path = handler_with_db
        files = handler._dir_move_detector.get_files_under_directory("nonexistent")
        assert len(files) == 0

    def test_target_only_subdir_returns_empty(self, tmp_path):
        """PD-BUG-075: a subdirectory containing only target-only files returns empty.

        Previously this test verified that relative link targets were resolved
        into the queried directory.  After PD-BUG-075, target resolution was
        removed because it inflated known_files with phantom entries.  A
        subdirectory that contains no source files (only files referenced by
        links from elsewhere) correctly returns empty — directory move
        detection for such directories relies on sibling source files or
        the parent directory being detected instead.
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
        ref_file.write_text("Reference content")  # No links → target-only
        readme = project_dir / "README.md"
        readme.write_text("# Project\n[API](api/reference.txt)\n")

        # Parse README into DB (simulating initial scan)
        refs = parser.parse_file(str(readme))
        for ref in refs:
            ref.file_path = "sub_project/README.md"
            link_db.add_link(ref)

        # sub_project/api/ has no source files → should return empty
        files = handler._dir_move_detector.get_files_under_directory("sub_project/api")
        assert len(files) == 0, f"Expected empty set for target-only directory, got {files}"

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
        files = handler._dir_move_detector.get_files_under_directory("docs/guide.md")
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

        files = handler._dir_move_detector.get_files_under_directory("docs")
        assert not any("docs-other" in f for f in files), (
            f"Files from 'docs-other/' matched prefix 'docs' — "
            f"trailing slash missing in dir_prefix. Files: {files}"
        )


class TestGetFilesUnderDirectoryInflation:
    """Regression tests for PD-BUG-075: phantom link targets inflating known_files.

    When a directory has files that cross-reference each other heavily,
    get_files_under_directory() must return only actual source files —
    not every resolved link target that happens to fall under the directory
    prefix.  The old code iterated ALL link targets in the database,
    resolved each from the source file's location, and added any that
    resolved under the queried directory.  This inflated the count from
    ~N real files to N + (number of unique resolved target paths), making
    the match threshold unreachable and breaking directory move detection.
    """

    @pytest.fixture
    def handler_with_cross_refs(self, tmp_path):
        """Directory with source files that link to many non-source targets.

        Reproduces PD-BUG-075: feedback files contain links to sub-paths
        (archive/, ratings/, templates/) that are target-only — they exist
        on disk but contain no links themselves, so they're NOT in
        files_with_links.  The old code resolved these targets from
        the source file's location, found they fell under "feedback/",
        and added them to known_files as phantoms.
        """
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        feedback_dir = tmp_path / "feedback"
        feedback_dir.mkdir()

        # Create sub-directories with target-only files (no links in them)
        archive_dir = feedback_dir / "archive"
        archive_dir.mkdir()
        ratings_dir = feedback_dir / "ratings"
        ratings_dir.mkdir()

        target_only_count = 0
        for i in range(20):
            (archive_dir / f"old-form-{i}.md").write_text(f"# Archived form {i}")
            target_only_count += 1
        for i in range(15):
            (ratings_dir / f"rating-{i}.md").write_text(f"# Rating {i}")
            target_only_count += 1

        # Create 5 source files that reference the target-only files
        source_count = 5
        for i in range(source_count):
            archive_links = "\n".join(
                f"- [archive {j}](archive/old-form-{j}.md)" for j in range(20)
            )
            rating_links = "\n".join(f"- [rating {j}](ratings/rating-{j}.md)" for j in range(15))
            (feedback_dir / f"form{i}.md").write_text(
                f"# Form {i}\n{archive_links}\n{rating_links}\n"
            )

        # Scan only the source files (files with links) into the database
        # Target-only files are on disk but have no links to parse
        for file_path in tmp_path.rglob("*.md"):
            rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
            references = parser.parse_file(str(file_path))
            if references:  # Only files with links get added
                for ref in references:
                    ref.file_path = rel_path
                    link_db.add_link(ref)

        return handler, link_db, tmp_path, source_count, target_only_count

    def test_no_phantom_inflation(self, handler_with_cross_refs):
        """PD-BUG-075: known_files must not be inflated by resolved link targets.

        With 5 source files under feedback/, the result should contain
        exactly those 5 files — not 5 + 35 target-only files that happen
        to resolve under the same directory prefix.
        """
        handler, link_db, tmp_path, source_count, target_only_count = handler_with_cross_refs
        files = handler._dir_move_detector.get_files_under_directory("feedback")

        # Must contain only the source files, not inflated by targets
        assert len(files) == source_count, (
            f"Expected {source_count} files (source files only), "
            f"got {len(files)} — phantom link targets are inflating the count. "
            f"Files: {sorted(files)}"
        )

    def test_only_source_files_returned(self, handler_with_cross_refs):
        """PD-BUG-075: every entry in known_files must be an actual source file."""
        handler, link_db, tmp_path, source_count, target_only_count = handler_with_cross_refs
        files = handler._dir_move_detector.get_files_under_directory("feedback")
        source_files = {f for f in link_db.get_source_files() if f.startswith("feedback/")}

        # Every returned file should be a known source file
        for f in files:
            assert f in source_files, (
                f"File '{f}' is in known_files but is not a source file — "
                f"it's a phantom link target"
            )

    def test_dir_move_detection_succeeds_with_cross_refs(self, handler_with_cross_refs):
        """PD-BUG-075: directory move detection must succeed even when files
        cross-reference each other heavily.

        Simulates: feedback/ deleted, feedback-archive/ created with same files.
        The detector must buffer the correct count and match all real files.
        """
        handler, link_db, tmp_path, source_count, target_only_count = handler_with_cross_refs
        detector = handler._dir_move_detector

        # Phase 1: Buffer the directory deletion
        result = detector.handle_directory_deleted("feedback")
        assert result is True

        pending = detector.pending_dir_moves.get("feedback")
        assert pending is not None
        assert pending.total_expected == source_count, (
            f"Expected {source_count} total_expected, got {pending.total_expected} — "
            f"phantom targets are inflating the count"
        )


class TestDirectoryDeleteBuffering:
    """Tests that _handle_directory_deleted buffers files for move detection."""

    @pytest.fixture
    def setup(self, tmp_path):
        """Set up handler with files in a directory.

        PD-BUG-075: Files under the directory must contain links (be source
        files) to be detected by get_files_under_directory(), which now only
        returns files_with_links entries.
        """
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Create directory with files that contain links (source files)
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        guide = docs_dir / "guide.md"
        guide.write_text("# Guide\nSee [api](api.md) for details.")
        api = docs_dir / "api.md"
        api.write_text("# API\nSee [guide](guide.md) for details.")

        # Create references to the files from outside
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
        assert "docs" in handler._dir_move_detector.pending_dir_moves, (
            "Expected 'docs' in pending_dir_moves, got: "
            f"{list(handler._dir_move_detector.pending_dir_moves.keys())}"
        )
        pending = handler._dir_move_detector.pending_dir_moves["docs"]
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

        pending = handler._dir_move_detector.pending_dir_moves["docs"]
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

        # _handle_file_deleted delegates to MoveDetector, which buffers
        # the directory path itself. No child files should be buffered
        # (as _handle_directory_deleted would do).
        pending_keys = set(handler._move_detector._pending.keys())
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

        pending = handler._dir_move_detector.pending_dir_moves["docs"]

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

        # Single file should go to MoveDetector's pending buffer (per-file
        # move detection), NOT to pending_dir_moves (directory move detection)
        assert len(handler._dir_move_detector.pending_dir_moves) == 0, (
            f"Single file delete should NOT create pending_dir_moves entry, "
            f"but found: {list(handler._dir_move_detector.pending_dir_moves.keys())}"
        )
        assert "docs/guide.md" in handler._move_detector._pending, (
            f"Single file delete should be in MoveDetector pending, "
            f"but got: {list(handler._move_detector._pending.keys())}"
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
        guide.write_text("# Guide\nSee [README](../README.md) for details.")

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
            len(service.handler._dir_move_detector.pending_dir_moves) >= 1
        ), "Should have pending_dir_moves entry"

        # Step 2: Move the actual file to new location (remove old dir to
        # simulate real Windows directory move where the whole dir is gone)
        new_guide = new_docs_dir / "guide.md"
        guide.rename(new_guide)
        docs_dir.rmdir()  # Old dir gone after move (realistic)

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
        ), "Old reference 'docs/guide.md' should be removed from README"

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
        guide.write_text("# Guide\nSee [api](api.md).")
        api = docs_dir / "api.md"
        api.write_text("# API\nSee [guide](guide.md).")

        readme = tmp_path / "README.md"
        readme.write_text("# Project\n\n" "- [Guide](docs/guide.md)\n" "- [API](docs/api.md)\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Step 1: Directory delete (Windows: is_directory=False)
        dir_delete_event = FileDeletedEvent(str(docs_dir))
        dir_delete_event.is_directory = False
        service.handler.on_deleted(dir_delete_event)

        # Step 2: Move files and fire create events (remove old dir to
        # simulate real Windows directory move where the whole dir is gone)
        new_guide = new_docs_dir / "guide.md"
        guide.rename(new_guide)

        new_api = new_docs_dir / "api.md"
        api.rename(new_api)
        docs_dir.rmdir()  # Old dir gone after move (realistic)

        service.handler.on_created(FileCreatedEvent(str(new_guide)))
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
        nested.write_text("# Setup Guide\nSee [README](../../README.md).")

        readme = tmp_path / "README.md"
        readme.write_text("See [setup](docs/guides/setup.md).")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Directory delete (Windows: is_directory=False)
        dir_delete_event = FileDeletedEvent(str(docs_dir))
        dir_delete_event.is_directory = False
        service.handler.on_deleted(dir_delete_event)

        # File create at new location (remove old dir tree to simulate
        # real Windows directory move where the whole dir is gone)
        new_nested = new_sub_dir / "setup.md"
        nested.rename(new_nested)
        shutil.rmtree(str(docs_dir))  # Old dir gone after move (realistic)
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
        guide.write_text("# Guide\nSee [README](../README.md).")

        readme = tmp_path / "README.md"
        readme.write_text("See [guide](docs/guide.md).")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Shorten max timeout for test speed
        service.handler._dir_move_detector._max_timeout = 0.2

        # Directory delete (Windows: is_directory=False)
        dir_delete_event = FileDeletedEvent(str(docs_dir))
        dir_delete_event.is_directory = False
        service.handler.on_deleted(dir_delete_event)

        # Verify files are buffered in pending_dir_moves
        assert len(service.handler._dir_move_detector.pending_dir_moves) >= 1

        # Wait for max timeout + processing
        time.sleep(0.5)

        # Pending should be cleared (processed as actual deletions)
        assert len(service.handler._dir_move_detector.pending_dir_moves) == 0


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


class TestDirectoryMoveOutwardLinks:
    """Regression tests for PD-BUG-039: directory move does not update
    outward-pointing links inside moved files.

    When a directory is moved, links inside the moved files that point
    outward (e.g., ../other.md) must be adjusted for the new directory depth.
    """

    def test_outward_links_updated_in_moved_files(self, tmp_path):
        """Links inside moved files pointing outward must be adjusted."""
        # Setup: docs/guides/intro.md links to docs/readme.md using ../readme.md
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        guides_dir = docs_dir / "guides"
        guides_dir.mkdir()
        readme = docs_dir / "readme.md"
        readme.write_text("# Readme")
        intro = guides_dir / "intro.md"
        intro.write_text("See [readme](../readme.md) for details.\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Move guides/ to top-level (one level up)
        new_guides = tmp_path / "guides"
        guides_dir.rename(new_guides)

        move_event = DirMovedEvent(str(guides_dir), str(new_guides))
        service.handler.on_moved(move_event)

        # The link inside intro.md was ../readme.md (from docs/guides/)
        # After move to top-level guides/, it should be docs/readme.md
        updated = (new_guides / "intro.md").read_text()
        assert (
            "../readme.md" not in updated
        ), f"Old relative link '../readme.md' should be updated, got: {updated}"
        assert (
            "docs/readme.md" in updated
        ), f"Expected 'docs/readme.md' in updated file, got: {updated}"


class TestDirectoryMoveCoMovedReferences:
    """Regression tests for PD-BUG-038: directory move does not update
    references in other files when co-moved files reference each other.

    When files A and B are in the same directory and A references B,
    the sequential processing must not break B's lookup by prematurely
    updating A's database entry.
    """

    def test_external_references_updated_for_all_co_moved_files(self, tmp_path):
        """External file references to ALL co-moved files must be updated."""
        # Setup: README references both docs/a.md and docs/b.md
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        file_a = docs_dir / "a.md"
        file_a.write_text("# File A\nSee [b](b.md).\n")
        file_b = docs_dir / "b.md"
        file_b.write_text("# File B\nSee [a](a.md).\n")

        readme = tmp_path / "README.md"
        readme.write_text("# Project\n\n" "- [A](docs/a.md)\n" "- [B](docs/b.md)\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Verify initial references
        refs_a = service.link_db.get_references_to_file("docs/a.md")
        refs_b = service.link_db.get_references_to_file("docs/b.md")
        assert len(refs_a) >= 1, "Should find reference to docs/a.md"
        assert len(refs_b) >= 1, "Should find reference to docs/b.md"

        # Move docs/ to guides/
        new_docs = tmp_path / "guides"
        docs_dir.rename(new_docs)

        move_event = DirMovedEvent(str(docs_dir), str(new_docs))
        service.handler.on_moved(move_event)

        # Both references in README must be updated
        readme_content = readme.read_text()
        assert (
            "guides/a.md" in readme_content
        ), f"Expected 'guides/a.md' in README, got: {readme_content}"
        assert (
            "guides/b.md" in readme_content
        ), f"Expected 'guides/b.md' in README, got: {readme_content}"
        assert "docs/a.md" not in readme_content, "Old 'docs/a.md' should be gone from README"
        assert "docs/b.md" not in readme_content, "Old 'docs/b.md' should be gone from README"

    def test_deep_relative_path_references_updated(self, tmp_path):
        """References using deep relative paths (../../) must be found and updated.

        This tests the scenario from the original bug report where references
        stored as relative paths (e.g., ../../guides/file.md) were not found
        during directory move processing.
        """
        # Setup: project/src/components/index.md references
        # project/docs/guides/api.md using ../../docs/guides/api.md
        src_dir = tmp_path / "src" / "components"
        src_dir.mkdir(parents=True)
        docs_dir = tmp_path / "docs" / "guides"
        docs_dir.mkdir(parents=True)

        api_guide = docs_dir / "api.md"
        api_guide.write_text("# API Guide\n")
        setup_guide = docs_dir / "setup.md"
        setup_guide.write_text("# Setup Guide\n")

        index = src_dir / "index.md"
        index.write_text(
            "# Components\n\n"
            "- [API](../../docs/guides/api.md)\n"
            "- [Setup](../../docs/guides/setup.md)\n"
        )

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Move docs/guides/ to docs/reference/
        new_guides = tmp_path / "docs" / "reference"
        docs_dir.rename(new_guides)

        move_event = DirMovedEvent(str(docs_dir), str(new_guides))
        service.handler.on_moved(move_event)

        # Both references in index.md must be updated
        updated = index.read_text()
        assert (
            "docs/reference/api.md" in updated or "../../docs/reference/api.md" in updated
        ), f"Expected reference to new path, got: {updated}"
        assert (
            "docs/guides/api.md" not in updated
        ), f"Old path 'docs/guides/api.md' should be gone, got: {updated}"
        assert (
            "docs/guides/setup.md" not in updated
        ), f"Old path 'docs/guides/setup.md' should be gone, got: {updated}"


class TestDirectoryMoveCrossReferencesWithinMovedDir:
    """Regression tests for PD-BUG-050: directory move fails to update
    cross-references when both the referencing file and the referenced file
    are within the moved directory.

    Root cause: _handle_directory_moved processes each moved file via
    process_directory_file_move(). When file A references file B, and both
    are in the moved directory, the updater tries to write to file A at its
    OLD path (because the DB source_file entry still has the old path),
    causing Errno 2 (file not found).
    """

    def test_cross_references_within_moved_directory_updated(self, tmp_path):
        """When files within a moved directory reference each other,
        all cross-references must be updated to reflect new paths."""
        # Setup: features/ contains a.md and b.md that reference each other
        features_dir = tmp_path / "features"
        features_dir.mkdir()
        file_a = features_dir / "a.md"
        file_a.write_text("# Feature A\nSee also [Feature B](b.md).\n")
        file_b = features_dir / "b.md"
        file_b.write_text("# Feature B\nSee also [Feature A](a.md).\n")

        # External file also references both
        readme = tmp_path / "README.md"
        readme.write_text("# Project\n\n" "- [A](features/a.md)\n" "- [B](features/b.md)\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Move features/ to product/features/
        product_dir = tmp_path / "product"
        product_dir.mkdir()
        new_features = product_dir / "features"
        features_dir.rename(new_features)

        move_event = DirMovedEvent(str(features_dir), str(new_features))
        service.handler.on_moved(move_event)

        # External references in README must be updated
        readme_content = readme.read_text()
        assert (
            "product/features/a.md" in readme_content
        ), f"Expected 'product/features/a.md' in README, got: {readme_content}"
        assert (
            "product/features/b.md" in readme_content
        ), f"Expected 'product/features/b.md' in README, got: {readme_content}"

        # Internal cross-references should be preserved (sibling relative links)
        a_content = (new_features / "a.md").read_text()
        b_content = (new_features / "b.md").read_text()
        assert (
            "b.md" in a_content
        ), f"a.md should still reference b.md via relative path, got: {a_content}"
        assert (
            "a.md" in b_content
        ), f"b.md should still reference a.md via relative path, got: {b_content}"

    def test_external_deep_relative_reference_to_moved_file(self, tmp_path):
        """An external file using a deep relative path (../../../../../) to
        reference a file in the moved directory must have its link updated.

        Reproduces PD-BUG-050 scenario: ADR at doc/a/b/c/d/e/adr.md
        references doc/state/features/core.md via ../../../../../state/features/core.md.
        When state/features/ moves to product/state/features/, the link must update.
        """
        # Create deep directory structure for the referencing file
        adr_dir = tmp_path / "doc" / "a" / "b" / "c" / "d" / "e"
        adr_dir.mkdir(parents=True)
        adr = adr_dir / "adr.md"

        # Create the target file in the directory that will move
        features_dir = tmp_path / "doc" / "state" / "features"
        features_dir.mkdir(parents=True)
        core = features_dir / "core.md"
        core.write_text("# Core Architecture\n")

        # ADR references core.md via deep relative path
        adr.write_text("# ADR\n\n" "- [Core State](../../../../../state/features/core.md)\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Move doc/state/features/ to doc/product/state/features/
        product_dir = tmp_path / "doc" / "product" / "state"
        product_dir.mkdir(parents=True)
        new_features = product_dir / "features"
        features_dir.rename(new_features)

        move_event = DirMovedEvent(str(features_dir), str(new_features))
        service.handler.on_moved(move_event)

        # ADR reference must be updated
        adr_content = adr.read_text()
        assert "state/features/core.md" not in adr_content.replace(
            "product/state/", ""
        ), f"Old path 'state/features/core.md' should be gone from ADR, got: {adr_content}"
        assert (
            "product/state/features/core.md" in adr_content
        ), f"Expected 'product/state/features/core.md' in ADR, got: {adr_content}"

    def test_external_file_referencing_moved_files_updated(self, tmp_path):
        """An external file referencing files inside the moved directory via
        absolute project paths must have ALL references updated, even when
        the moved files also cross-reference each other."""
        # Setup: state/ contains core.md, db.md, monitoring.md
        # They cross-reference each other AND an external tracker references all
        state_dir = tmp_path / "state"
        state_dir.mkdir()

        core = state_dir / "core.md"
        core.write_text("# Core\n" "Depends on [DB](db.md) and [Monitoring](monitoring.md).\n")
        db = state_dir / "db.md"
        db.write_text("# DB\nUsed by [Core](core.md).\n")
        monitoring = state_dir / "monitoring.md"
        monitoring.write_text("# Monitoring\nUsed by [Core](core.md).\n")

        tracker = tmp_path / "tracker.md"
        tracker.write_text(
            "# Tracker\n\n"
            "| Feature | State |\n"
            "| [Core](state/core.md) | Done |\n"
            "| [DB](state/db.md) | Done |\n"
            "| [Monitoring](state/monitoring.md) | Done |\n"
        )

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Move state/ to product/state/
        product_dir = tmp_path / "product"
        product_dir.mkdir()
        new_state = product_dir / "state"
        state_dir.rename(new_state)

        move_event = DirMovedEvent(str(state_dir), str(new_state))
        service.handler.on_moved(move_event)

        # ALL references in tracker must be updated
        tracker_content = tracker.read_text()
        assert (
            "product/state/core.md" in tracker_content
        ), f"Expected 'product/state/core.md' in tracker, got: {tracker_content}"
        assert (
            "product/state/db.md" in tracker_content
        ), f"Expected 'product/state/db.md' in tracker, got: {tracker_content}"
        assert (
            "product/state/monitoring.md" in tracker_content
        ), f"Expected 'product/state/monitoring.md' in tracker, got: {tracker_content}"
        # Old paths must be gone
        assert "state/core.md" not in tracker_content.replace(
            "product/state/", ""
        ), "Old 'state/core.md' should be gone from tracker"
        assert "state/db.md" not in tracker_content.replace(
            "product/state/", ""
        ), "Old 'state/db.md' should be gone from tracker"

    def test_no_errno2_errors_during_cross_reference_update(self, tmp_path):
        """PD-BUG-050 regression: directory move must NOT produce Errno 2
        errors when updating cross-references between files within the moved
        directory.

        Previous behavior: Phase 1 tried to write to moved files at their OLD
        paths (stale DB source_file entries), causing Errno 2. Phase 1.5
        compensated, masking the bug. This test asserts zero errors — not just
        correct end state.
        """
        features_dir = tmp_path / "features"
        features_dir.mkdir()
        (features_dir / "a.md").write_text("# A\nSee [B](features/b.md) for details.\n")
        (features_dir / "b.md").write_text("# B\nSee [A](features/a.md) for details.\n")
        (features_dir / "c.md").write_text("# C\nSee [A](features/a.md) and [B](features/b.md).\n")
        (tmp_path / "README.md").write_text(
            "# README\n- [A](features/a.md)\n- [B](features/b.md)\n- [C](features/c.md)\n"
        )

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        product_dir = tmp_path / "product"
        product_dir.mkdir()
        new_features = product_dir / "features"
        features_dir.rename(new_features)

        move_event = DirMovedEvent(str(features_dir), str(new_features))
        service.handler.on_moved(move_event)

        # Assert zero errors — the bug manifested as Errno 2 error count > 0
        error_count = service.handler.stats.get("errors", 0)
        assert error_count == 0, (
            f"Expected 0 errors during directory move, got {error_count}. "
            "This indicates stale DB source paths causing Errno 2 (PD-BUG-050)."
        )

        # Also verify correctness (belt and suspenders)
        readme = (tmp_path / "README.md").read_text()
        assert "product/features/a.md" in readme
        assert "product/features/b.md" in readme
        assert "product/features/c.md" in readme


class TestRelativePathPrefixUpdateOnDirectoryMove:
    """Tests for directory moves where stored references use ../
    relative path prefixes.

    Verifies that the database's resolved-path index correctly maps
    relative targets (e.g., "../../alpha-project/guides/debt") back to their
    project-root-relative form ("alpha-project/guides/debt") so that directory
    move lookups find and update them.
    """

    def test_relative_path_with_dotdot_prefix_updated_on_directory_move(self, tmp_path):
        """A PowerShell file using ../../alpha-project/guides/... must have its reference
        updated when alpha-project/guides/ moves to guides/.

        Verifies that relative paths with ../ prefixes are correctly resolved
        via the database's resolved-path index and updated during directory moves.
        """
        # Setup: scripts/update/Update-Debt.ps1 references ../../alpha-project/guides/debt/
        # (two levels up from scripts/update/ reaches project root)
        scripts_dir = tmp_path / "scripts" / "update"
        scripts_dir.mkdir(parents=True)
        guides_dir = tmp_path / "alpha-project" / "guides" / "debt"
        guides_dir.mkdir(parents=True)

        debt_readme = guides_dir / "README.md"
        debt_readme.write_text("# Technical Debt Assessments\n")

        ps_script = scripts_dir / "Update-Debt.ps1"
        ps_script.write_text(
            "param(\n"
            '    [string]$AssessmentDirectory = "../../alpha-project/guides/debt"\n'
            ")\n"
            "\n"
            '$UpdateScript = "../../alpha-project/guides/debt/README.md"\n'
        )

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Move alpha-project/guides/ to guides/ (one level up)
        new_guides = tmp_path / "guides"
        (tmp_path / "alpha-project" / "guides").rename(new_guides)

        move_event = DirMovedEvent(
            str(tmp_path / "alpha-project" / "guides"),
            str(new_guides),
        )
        service.handler.on_moved(move_event)

        # References must be updated
        updated = ps_script.read_text()
        assert (
            "alpha-project/guides" not in updated
        ), f"Old path 'alpha-project/guides' should be gone from script, got:\n{updated}"
        assert (
            "guides/debt" in updated
        ), f"Expected reference to new 'guides/debt' path, got:\n{updated}"

    def test_four_level_deep_relative_path_updated_on_directory_move(self, tmp_path):
        """A markdown file at depth 5 using ../../../../../alpha-project/guides/scripts/...
        must have its reference updated when alpha-project/guides/ moves to guides/.

        Verifies that deeply nested relative paths are correctly resolved
        via the database's resolved-path index and updated during directory moves.
        """
        # Setup: deep file referencing alpha-project/guides/scripts/test/Run-Tests.ps1
        # File is at depth 5 (alpha-project/product/tracking/features/archive/),
        # so 5 levels of ../ are needed to reach project root.
        deep_dir = tmp_path / "alpha-project" / "product" / "tracking" / "features" / "archive"
        deep_dir.mkdir(parents=True)
        scripts_dir = tmp_path / "alpha-project" / "guides" / "scripts" / "test"
        scripts_dir.mkdir(parents=True)

        run_tests = scripts_dir / "Run-Tests.ps1"
        run_tests.write_text("# Test runner script\n")

        archive_file = deep_dir / "state.md"
        archive_file.write_text(
            "# Feature State\n\n"
            "Run tests: [Run-Tests.ps1]"
            "(../../../../../alpha-project/guides/scripts/test/Run-Tests.ps1)\n"
        )

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Move alpha-project/guides/ to guides/
        new_guides = tmp_path / "guides"
        (tmp_path / "alpha-project" / "guides").rename(new_guides)

        move_event = DirMovedEvent(
            str(tmp_path / "alpha-project" / "guides"),
            str(new_guides),
        )
        service.handler.on_moved(move_event)

        # Reference must be updated — the relative path changes
        updated = archive_file.read_text()
        assert (
            "alpha-project/guides" not in updated
        ), f"Old path 'alpha-project/guides' should be gone, got:\n{updated}"
        assert (
            "Run-Tests.ps1" in updated
        ), f"Reference to Run-Tests.ps1 should still exist, got:\n{updated}"


class TestDirectoryMoveToIgnoredDirName:
    """Regression tests for PD-BUG-071: directory rename to an ignored-dir name
    silently drops reference updates.

    When a directory is renamed and the new name matches an entry in
    ignored_directories, the file-level processing (Phase 0/1) is skipped
    because should_monitor_file() rejects files in the destination. Phase 2
    (directory-path string replacement) still catches some references, but
    the DB source paths remain stale and moved files are not rescanned.
    """

    def test_db_source_path_updated_when_dir_renamed_to_ignored_name(self, tmp_path):
        """DB source paths must be updated even when destination is an ignored dir.

        PD-BUG-071: Renaming docs/ -> build/ (where 'build' is in
        ignored_directories) causes Phase 0 (DB update) to be skipped because
        moved_files is empty. The DB still records the file under the old
        source path docs/guide.md instead of build/guide.md.
        """
        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        guide = docs_dir / "guide.md"
        guide.write_text("# Guide\nSee [other](../other.md) for details.")

        other = tmp_path / "other.md"
        other.write_text("# Other\nContent.")

        readme = tmp_path / "README.md"
        readme.write_text("See [guide](docs/guide.md) for details.\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Verify initial DB state
        refs_before = service.link_db.get_references_to_file("docs/guide.md")
        assert len(refs_before) >= 1

        # Rename docs/ -> build/ (an ignored directory name in DEFAULT_CONFIG)
        build_dir = tmp_path / "build"
        docs_dir.rename(build_dir)

        move_event = DirMovedEvent(str(docs_dir), str(build_dir))
        service.handler.on_moved(move_event)

        # Phase 0 check: DB source path must be updated from docs/guide.md -> build/guide.md
        targets = service.link_db.get_all_targets_with_references()
        source_paths = []
        for target, refs in targets.items():
            for ref in refs:
                source_paths.append(ref.file_path)

        assert "build/guide.md" in source_paths or not any(
            "guide.md" in sp for sp in source_paths
        ), (
            f"DB should have source path 'build/guide.md' (not 'docs/guide.md'). "
            f"Actual source paths: {source_paths}"
        )
        # Negative assertion: old source path must NOT remain
        assert "docs/guide.md" not in source_paths, (
            f"Stale source path 'docs/guide.md' should not remain in DB after move. "
            f"Actual source paths: {source_paths}"
        )

    def test_moved_files_enumerated_when_dir_renamed_to_ignored_name(self, tmp_path):
        """moved_files list must include files even when destination is ignored.

        PD-BUG-071: The os.walk + should_monitor_file filter in
        _handle_directory_moved produces an empty moved_files list when the
        destination directory name is in ignored_directories, causing all
        Phase 0/1/1.5 processing to be skipped.
        """
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()
        run_py = scripts_dir / "run.py"
        run_py.write_text("# run script")
        config_md = scripts_dir / "config.md"
        config_md.write_text("# config docs")

        main_md = tmp_path / "main.md"
        main_md.write_text("See [run](scripts/run.py) and [config](scripts/config.md).\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Rename scripts/ -> dist/ (an ignored directory name)
        dist_dir = tmp_path / "dist"
        scripts_dir.rename(dist_dir)

        move_event = DirMovedEvent(str(scripts_dir), str(dist_dir))
        service.handler.on_moved(move_event)

        # Verify references updated in the file
        main_content = main_md.read_text()
        assert (
            "dist/run.py" in main_content
        ), f"Expected 'dist/run.py' in main.md, got: {main_content}"
        assert (
            "dist/config.md" in main_content
        ), f"Expected 'dist/config.md' in main.md, got: {main_content}"
        assert (
            "scripts/run.py" not in main_content
        ), f"Old 'scripts/run.py' should be gone, got: {main_content}"

        # Core assertion: handler must enumerate moved files even when
        # destination is an ignored directory. files_moved stat of 0 means
        # Phase 0/1 were entirely skipped.
        stats = service.handler.get_stats()
        assert stats.get("files_moved", 0) >= 2, (
            f"Expected at least 2 files_moved (run.py + config.md), "
            f"got {stats.get('files_moved', 0)}. Phase 0/1 was skipped."
        )


class TestDirectoryMovePhase15CounterPropagation:
    """PD-BUG-091: directory_move_completed log must include Phase 1.5 counts
    in total_references_updated.

    Root cause: _update_links_within_moved_file performs actual updates and
    increments handler.stats, but the handler wrapper had no return statement,
    so the count was dropped. The directory_move_completed log then reported
    only Phase 1b + Phase 2 contributions, under-reporting actual work.
    """

    def test_phase_1_5_updates_counted_in_directory_move_log(self, tmp_path):
        """Relative links rewritten inside moved files (Phase 1.5) must be
        added to total_references_updated in the directory_move_completed log.
        """
        from unittest.mock import MagicMock

        # External target outside the directory that will move
        (tmp_path / "external.md").write_text("# External\n")

        # Directory to move, containing a file with relative link to external
        src_dir = tmp_path / "docs"
        src_dir.mkdir()
        inner = src_dir / "inner.md"
        inner.write_text("# Inner\n\nSee [external](../external.md).\n")

        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Capture log events emitted by the handler
        mock_logger = MagicMock()
        service.handler.logger = mock_logger

        # Move docs/ to sub/docs/ so inner.md's relative link must be rewritten
        # from ../external.md to ../../external.md (1 Phase 1.5 update)
        sub_dir = tmp_path / "sub"
        sub_dir.mkdir()
        new_docs = sub_dir / "docs"
        src_dir.rename(new_docs)

        move_event = DirMovedEvent(str(src_dir), str(new_docs))
        service.handler.on_moved(move_event)

        # Sanity: the actual Phase 1.5 update happened on disk
        inner_content = (new_docs / "inner.md").read_text()
        assert "../../external.md" in inner_content, (
            f"Precondition: Phase 1.5 must have rewritten the relative link. "
            f"Got: {inner_content!r}"
        )

        # Find the directory_move_completed log event
        completion_calls = [
            c
            for c in mock_logger.info.call_args_list
            if c.args and c.args[0] == "directory_move_completed"
        ]
        assert len(completion_calls) == 1, (
            f"Expected exactly one directory_move_completed log, " f"got {len(completion_calls)}"
        )

        total = completion_calls[0].kwargs["total_references_updated"]

        # Negative assertion (the key BUG-091 assertion): total must NOT be 0
        # when Phase 1.5 has done work. Before the fix, Phase 1.5 contributions
        # were silently dropped and total_references_updated reported 0.
        assert total != 0, (
            f"BUG-091: total_references_updated is 0 despite Phase 1.5 "
            f"rewriting a relative link. Phase 1.5 return value must be "
            f"propagated into the counter."
        )
        # Positive assertion: exactly 1 link was updated by Phase 1.5 in this
        # scenario (no external refs, no dir-path refs → Phase 1b=0, Phase 2=0)
        assert total == 1, (
            f"Expected total_references_updated == 1 (single Phase 1.5 " f"update), got {total}"
        )
        # Guard against double-counting in handler.stats: Phase 1.5 is added
        # to handler.stats from within _update_links_within_moved_file, so the
        # directory move handler must not add it again via total.
        stats = service.handler.get_stats()
        assert stats.get("links_updated", 0) == 1, (
            f"Expected handler.stats['links_updated'] == 1 (single Phase 1.5 "
            f"update, no double-counting), got {stats.get('links_updated')}"
        )
