"""
Document Metadata:
ID: TE-TST-145
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-10
Updated: 2026-08-10
Component Name: ReferenceLookup
Feature Id: 2.2.1
Language: Python
Test Name: SimultaneousMoves
Test Type: Unit
"""

# SimultaneousMoves Unit Test — PD-BUG-114 regression tests
#
# Covers the "both link endpoints move in one operation" race: file A links to
# file B, and BOTH files physically leave their old disk locations before
# watchdog delivers either move event (the real-world result of two quick
# `mv` commands). Before the fix, A's link to B was left untouched — neither
# re-depthed for A's new location nor re-pointed at B's — while links in A
# whose targets did not move were re-depthed correctly in the same pass.
#
# Mechanism (PD-BUG-114): the PD-BUG-033 existence guard in
# reference_lookup._calculate_updated_relative_path resolves each outgoing
# link against the moved file's OLD directory and skips it when that resolved
# path no longer exists on disk. When the link's target has itself just moved,
# the guard fires as a false negative — and the target's own move event cannot
# repair the link afterwards in either processing order.
#
# Test File ID: TE-TST-145
# Created: 2026-08-10

import pytest
from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService

pytestmark = [
    pytest.mark.feature("2.2.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("test/specifications/feature-specs/test-spec-2-2-1-link-updating.md"),
]


def _setup_dual_move_project(root, b_link="../../proposals/B.md"):
    """Create the PD-BUG-114 layout mirroring the reported instance.

    A (state-tracking/temporary/A.md) links to B (proposals/B.md), which moves
    with it, and twice to C (other/C.md), which stays put. A also carries a
    link-shaped string whose target never existed (PD-BUG-033 guard case).
    """
    (root / "state-tracking" / "temporary" / "old").mkdir(parents=True)
    (root / "proposals" / "old").mkdir(parents=True)
    (root / "other").mkdir(parents=True)

    a = root / "state-tracking" / "temporary" / "A.md"
    b = root / "proposals" / "B.md"
    c = root / "other" / "C.md"

    b.write_text("# B\n", encoding="utf-8")
    c.write_text("# C\n", encoding="utf-8")
    a.write_text(
        "# A\n"
        f"Link to moved-with-me: [B]({b_link})\n"
        "Link to unmoved 1: [C](../../other/C.md)\n"
        "Link to unmoved 2: [C again](../../other/C.md)\n"
        "Never-existed target: [G](../../nonexistent/ghost.md)\n",
        encoding="utf-8",
    )
    return a, b


def _move_both_then_deliver(temp_project_dir, order):
    """Move A and B on disk first, then deliver both events in the given order."""
    a_old, b_old = _setup_dual_move_project(temp_project_dir)
    a_new = temp_project_dir / "state-tracking" / "temporary" / "old" / "A.md"
    b_new = temp_project_dir / "proposals" / "old" / "B.md"

    service = LinkWatcherService(str(temp_project_dir))
    service._initial_scan()

    # Both files leave their old locations BEFORE any event is processed —
    # this is the race that produces PD-BUG-114.
    a_old.rename(a_new)
    b_old.rename(b_new)

    ev_a = FileMovedEvent(str(a_old), str(a_new))
    ev_b = FileMovedEvent(str(b_old), str(b_new))
    events = [ev_a, ev_b] if order == "referencing_first" else [ev_b, ev_a]
    for event in events:
        service.handler.on_moved(event)

    return service, a_new.read_text(encoding="utf-8")


class TestSimultaneousMoves:
    """PD-BUG-114: relative link updates when both link endpoints move together."""

    def test_both_endpoints_move_referencing_file_event_first(self, temp_project_dir):
        """A's event processed before B's: link to B must still be corrected."""
        _, content = _move_both_then_deliver(temp_project_dir, "referencing_first")

        # The stale as-authored link must be gone (negative assertion — the bug
        # left it exactly as authored).
        assert "](../../proposals/B.md)" not in content
        # The link must point at B's new location, re-depthed for A's new location.
        assert "[B](../../../proposals/old/B.md)" in content
        # Links whose targets did not move are re-depthed (worked before the fix).
        assert content.count("(../../../other/C.md)") == 2
        assert "](../../other/C.md)" not in content

    def test_both_endpoints_move_target_file_event_first(self, temp_project_dir):
        """B's event processed before A's: link to B must still be corrected."""
        _, content = _move_both_then_deliver(temp_project_dir, "target_first")

        assert "](../../proposals/B.md)" not in content
        assert "[B](../../../proposals/old/B.md)" in content
        assert content.count("(../../../other/C.md)") == 2
        assert "](../../other/C.md)" not in content

    def test_database_consistent_after_simultaneous_move(self, temp_project_dir):
        """After both events, the DB must resolve A's link to B's NEW path."""
        service, _ = _move_both_then_deliver(temp_project_dir, "referencing_first")

        refs_new = service.link_db.get_references_to_file("proposals/old/B.md")
        source_files = {ref.file_path for ref in refs_new}
        assert "state-tracking/temporary/old/A.md" in source_files

    def test_fragment_preserved_across_simultaneous_move(self, temp_project_dir):
        """An anchored link (#fragment) keeps its fragment through the repair."""
        a_old, b_old = _setup_dual_move_project(
            temp_project_dir, b_link="../../proposals/B.md#section-2"
        )
        a_new = temp_project_dir / "state-tracking" / "temporary" / "old" / "A.md"
        b_new = temp_project_dir / "proposals" / "old" / "B.md"

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        a_old.rename(a_new)
        b_old.rename(b_new)
        service.handler.on_moved(FileMovedEvent(str(a_old), str(a_new)))
        service.handler.on_moved(FileMovedEvent(str(b_old), str(b_new)))

        content = a_new.read_text(encoding="utf-8")
        assert "](../../proposals/B.md#section-2)" not in content
        assert "[B](../../../proposals/old/B.md#section-2)" in content

    def test_rename_in_place_with_concurrent_target_move(self, temp_project_dir):
        """A renamed in its own directory while B moves: link still corrected.

        Same root cause family: the same-directory early return skipped the
        outgoing-link pass entirely, so a target that vanished mid-operation
        was never repaired. Target's event processed first (the failing order).
        """
        (temp_project_dir / "docs").mkdir()
        (temp_project_dir / "proposals" / "old").mkdir(parents=True)

        a_old = temp_project_dir / "docs" / "A.md"
        b_old = temp_project_dir / "proposals" / "B.md"
        b_old.write_text("# B\n", encoding="utf-8")
        a_old.write_text("# A\nSee [B](../proposals/B.md) here.\n", encoding="utf-8")

        a_new = temp_project_dir / "docs" / "A-renamed.md"
        b_new = temp_project_dir / "proposals" / "old" / "B.md"

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        a_old.rename(a_new)
        b_old.rename(b_new)
        service.handler.on_moved(FileMovedEvent(str(b_old), str(b_new)))
        service.handler.on_moved(FileMovedEvent(str(a_old), str(a_new)))

        content = a_new.read_text(encoding="utf-8")
        assert "](../proposals/B.md)" not in content
        assert "[B](../proposals/old/B.md)" in content

    def test_never_existed_target_still_not_rewritten(self, temp_project_dir):
        """PD-BUG-033 regression guard: link-shaped strings whose target never
        existed must survive the moved-file pass unmodified."""
        _, content = _move_both_then_deliver(temp_project_dir, "referencing_first")

        assert "[G](../../nonexistent/ghost.md)" in content


def _rename_in_place_and_deliver(temp_project_dir, rel_dir, old_name, new_name, body):
    """Author a file, rename it inside its own directory, deliver the move event.

    Returns (new_path, content_before, content_after).
    """
    target_dir = temp_project_dir / rel_dir
    target_dir.mkdir(parents=True, exist_ok=True)
    old_path = target_dir / old_name
    old_path.write_text(body, encoding="utf-8")

    service = LinkWatcherService(str(temp_project_dir))
    service._initial_scan()

    new_path = target_dir / new_name
    old_path.rename(new_path)
    service.handler.on_moved(FileMovedEvent(str(old_path), str(new_path)))

    return new_path, body, new_path.read_text(encoding="utf-8")


class TestSameDirectoryRenamePreservesAuthoredForm:
    """PD-BUG-114 follow-up — code review Major finding (2026-08-10).

    Removing the ``old_dir == new_dir`` early return was required so a target
    that vanished mid-operation reaches the move-memory repair.  But it also
    routed every in-place rename through ``os.path.relpath``, which returns a
    *canonical* path — so a link the author wrote in any non-canonical form was
    silently reformatted even though it already resolved to the right file.

    The recalculation must be **semantic, not textual**: a link that still
    resolves to its intended target from the file's new location is left
    exactly as authored, whatever form the author chose.
    """

    def test_dot_slash_link_untouched_by_same_directory_rename(self, temp_project_dir):
        """``./target.md`` must survive an in-place rename byte-identical."""
        (temp_project_dir / "docs").mkdir()
        (temp_project_dir / "docs" / "target.md").write_text("# T\n", encoding="utf-8")

        _, before, after = _rename_in_place_and_deliver(
            temp_project_dir, "docs", "A.md", "B.md", "# A\nSee [T](./target.md) here.\n"
        )

        # Negative assertion: the canonicalized form must NOT have been written.
        assert "[T](target.md)" not in after
        assert after == before

    def test_backslash_link_untouched_by_same_directory_rename(self, temp_project_dir):
        """A backslash-authored path in a .ps1 must not be flipped to forward slashes."""
        (temp_project_dir / "other").mkdir()
        (temp_project_dir / "other" / "C.md").write_text("# C\n", encoding="utf-8")

        _, before, after = _rename_in_place_and_deliver(
            temp_project_dir,
            "scripts",
            "Run.ps1",
            "Run-Renamed.ps1",
            '# helper\n$doc = "..\\other\\C.md"\n',
        )

        assert "../other/C.md" not in after
        assert after == before

    def test_trailing_slash_directory_link_untouched(self, temp_project_dir):
        """A trailing-slash directory link must keep its trailing slash."""
        (temp_project_dir / "docs").mkdir()
        (temp_project_dir / "assets").mkdir()
        (temp_project_dir / "assets" / "logo.png").write_bytes(b"x")

        _, before, after = _rename_in_place_and_deliver(
            temp_project_dir, "docs", "A.md", "B.md", "# A\nSee [assets](../assets/) here.\n"
        )

        assert after == before

    def test_cross_directory_move_still_rewrites(self, temp_project_dir):
        """Boundary guard: suppression must not leak into moves that DO need a rewrite.

        The same ``./target.md`` form, moved to a deeper directory, no longer
        resolves to its target and must be recalculated.
        """
        (temp_project_dir / "docs" / "sub").mkdir(parents=True)
        (temp_project_dir / "docs" / "target.md").write_text("# T\n", encoding="utf-8")

        a_old = temp_project_dir / "docs" / "A.md"
        a_old.write_text("# A\nSee [T](./target.md) here.\n", encoding="utf-8")

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        a_new = temp_project_dir / "docs" / "sub" / "A.md"
        a_old.rename(a_new)
        service.handler.on_moved(FileMovedEvent(str(a_old), str(a_new)))

        content = a_new.read_text(encoding="utf-8")
        assert "[T](./target.md)" not in content
        assert "[T](../target.md)" in content
