"""
Document Metadata:
ID: TE-TST-162
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-30
Updated: 2026-08-30
Component Name: ReferenceLookup
Feature Id: 2.2.1
Language: Python
Test Name: Bug153MovedFileMarkdownRewrite
Test Type: Unit
"""

# Bug153MovedFileMarkdownRewrite Unit Test
#
# Two defects in the markdown half of the within-moved-file rewrite
# (``ReferenceLookup._replace_links_in_lines``), fixed together.
#
# PD-BUG-153 -- stale link text.  The markdown phase built its OWN regex rather
# than calling the shared ``replacement.replace_markdown_target``, and that copy
# never inspected the link text.  A self-named link -- text identical to target,
# the ``[references/x.md](references/x.md)`` idiom -- had its target re-depthed
# while the visible text kept advertising a path that no longer resolves from the
# new location.  The updater path has done this correctly since PD-BUG-012; only
# the moved-file path diverged.  Silent, and counted as a successful update.
#
# Chain collision -- compounded targets.  The markdown phase replaced
# CONTENT-GLOBALLY, once per reference, in sequence.  When one reference's NEW
# target equalled a later reference's OLD target, the later pass rewrote the
# earlier reference a second time.  Measured on the pre-fix source:
#
#     [x](doc/a.md)      alone -> [x](../doc/a.md)      correct
#     [y](../doc/a.md)   alone -> [y](../../doc/a.md)   correct
#     both together      ->       [x](../../doc/a.md)   WRONG -- different file
#                                 [y](../../doc/a.md)   correct
#
# That is the PD-BUG-150 compounding shape surviving in the markdown phase:
# PD-BUG-150 made the non-markdown phase position-aware and left this one global.
#
# Both are fixed by the same structural change -- the markdown replacement is
# confined to the reference's own recorded column span and delegated to the
# shared helper -- so no reference can observe another's output, and the
# PD-BUG-012 link-text rule arrives with the helper rather than being copied.
# Span confinement is safe because a MARKDOWN span exactly covers its
# ``[text](target "title")`` construct: verified across 13 shapes (titles in all
# three quotings, backticked text, bold text, mid-line, several per line, table
# cells, list items) -- 0 exceptions.  MARKDOWN_REFERENCE spans the whole line
# and is deliberately NOT routed here; it stays on the positional path where its
# label-anchored replacer already guards it.
#
# Because each reference now writes only its own span, the former
# "one target, one content-global pass" de-duplication had to go: duplicates are
# no longer collapsed by a single global sub, so each occurrence needs its own
# rewrite.  TestDuplicateAndMultiLink pins that.
#
# Test File ID: TE-TST-162
# Created: 2026-08-30

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.parser import LinkParser
from linkwatcher.reference_lookup import ReferenceLookup
from linkwatcher.updater import LinkUpdater

pytestmark = [
    pytest.mark.feature("2.2.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


def move_and_rewrite(tmp_path, body, targets=("doc/a.md",)):
    """Move sub/note.md -> sub/deeper/note.md and return the rewritten content.

    ``targets`` are created so the existence guard in the recalculation does not
    skip the links under test.
    """
    for rel in targets:
        p = tmp_path / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("target\n", encoding="utf-8")

    (tmp_path / "sub" / "deeper").mkdir(parents=True, exist_ok=True)
    src = tmp_path / "sub" / "note.md"
    src.write_text(body, encoding="utf-8")
    dst = tmp_path / "sub" / "deeper" / "note.md"
    src.rename(dst)

    lookup = ReferenceLookup(LinkDatabase(), LinkParser(), LinkUpdater(), str(tmp_path))
    lookup.update_links_within_moved_file("sub/note.md", "sub/deeper/note.md", str(dst))
    return dst.read_text(encoding="utf-8")


class TestBug153SelfNamedLinkText:
    """PD-BUG-153: link text equal to the target must follow the move too."""

    def test_self_named_link_updates_both_halves(self, tmp_path):
        result = move_and_rewrite(tmp_path, "[../doc/a.md](../doc/a.md)\n")

        assert result == "[../../doc/a.md](../../doc/a.md)\n"
        # The defect left the TEXT behind; assert the stale half is gone, not
        # merely that the new target is present -- a positive-only assertion
        # passes against the bug, because the target was always updated.
        assert "[../doc/a.md]" not in result

    def test_self_named_link_with_title_keeps_title_and_updates_text(self, tmp_path):
        result = move_and_rewrite(tmp_path, '[../doc/a.md](../doc/a.md "The A doc")\n')

        assert result == '[../../doc/a.md](../../doc/a.md "The A doc")\n'
        assert "[../doc/a.md]" not in result

    def test_normal_link_text_is_never_rewritten(self, tmp_path):
        """Control: text that is not the target must be left exactly alone."""
        result = move_and_rewrite(tmp_path, "[A doc](../doc/a.md)\n")

        assert result == "[A doc](../../doc/a.md)\n"

    def test_backtick_wrapped_text_is_not_treated_as_self_named(self, tmp_path):
        """Boundary: the text is ```../doc/a.md```, not ``../doc/a.md``.

        The PD-BUG-012 rule is exact equality, so the condition must NOT fire --
        rewriting here would change rendered prose, not a path.  This is the
        boundary the updater path has always held; it must hold here too.
        """
        result = move_and_rewrite(tmp_path, "[`../doc/a.md`](../doc/a.md)\n")

        assert result == "[`../doc/a.md`](../../doc/a.md)\n"

    def test_reference_definition_label_is_untouched(self, tmp_path):
        """Boundary: a definition's ``link_text`` is its LABEL, never its target.

        MARKDOWN_REFERENCE stays on the positional path, whose label-anchored
        replacer preserves label and title (the PD-BUG-150 rework lesson).
        """
        result = move_and_rewrite(tmp_path, "[lbl]: ../doc/a.md\nSee [x][lbl].\n")

        assert result == "[lbl]: ../../doc/a.md\nSee [x][lbl].\n"


class TestBug153ChainCollision:
    """Compounding: one reference's new target equal to another's old target."""

    def test_chain_collision_does_not_compound_targets(self, tmp_path):
        """Each link must land on ITS own recalculated target.

        ``doc/a.md`` resolves from ``sub/`` to ``sub/doc/a.md`` and must become
        ``../doc/a.md``; ``../doc/a.md`` resolves to ``doc/a.md`` and must become
        ``../../doc/a.md``.  Pre-fix, the second pass caught the first link's
        freshly written text and re-depthed it again, silently pointing it at a
        different file.
        """
        result = move_and_rewrite(
            tmp_path,
            "[x](doc/a.md)\n[y](../doc/a.md)\n",
            targets=("doc/a.md", "sub/doc/a.md"),
        )

        assert result == "[x](../doc/a.md)\n[y](../../doc/a.md)\n"
        # The corruption signature: line 1 over-depthed to line 2's target.
        assert "[x](../../doc/a.md)" not in result

    def test_chain_collision_self_named_does_not_compound(self, tmp_path):
        """Both defects on one line: self-named text AND a colliding chain."""
        result = move_and_rewrite(
            tmp_path,
            "[doc/a.md](doc/a.md)\n[../doc/a.md](../doc/a.md)\n",
            targets=("doc/a.md", "sub/doc/a.md"),
        )

        assert result == "[../doc/a.md](../doc/a.md)\n[../../doc/a.md](../../doc/a.md)\n"
        assert "[doc/a.md](" not in result

    def test_chain_collision_on_a_single_line(self, tmp_path):
        """The same collision with both links sharing one line."""
        result = move_and_rewrite(
            tmp_path,
            "[x](doc/a.md) then [y](../doc/a.md)\n",
            targets=("doc/a.md", "sub/doc/a.md"),
        )

        assert result == "[x](../doc/a.md) then [y](../../doc/a.md)\n"
        assert "[x](../../doc/a.md)" not in result


def move_and_rewrite_deep(tmp_path, body, targets):
    """Same as :func:`move_and_rewrite`, one directory level deeper.

    ``sub/mid/note.md`` -> ``sub/mid/deeper/note.md``, so a link can legitimately
    carry two ``../`` levels without escaping the project root.
    """
    for rel in targets:
        p = tmp_path / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("target\n", encoding="utf-8")

    (tmp_path / "sub" / "mid" / "deeper").mkdir(parents=True, exist_ok=True)
    src = tmp_path / "sub" / "mid" / "note.md"
    src.write_text(body, encoding="utf-8")
    dst = tmp_path / "sub" / "mid" / "deeper" / "note.md"
    src.rename(dst)

    lookup = ReferenceLookup(LinkDatabase(), LinkParser(), LinkUpdater(), str(tmp_path))
    lookup.update_links_within_moved_file("sub/mid/note.md", "sub/mid/deeper/note.md", str(dst))
    return dst.read_text(encoding="utf-8")


class TestReverseChainRequiresSpanConfinement:
    """The chain shape that descending order alone cannot save.

    Right-to-left ordering stops a LEFT link from being caught by a later RIGHT
    rewrite, which covers the common chain.  It does nothing for the mirror
    image: when the LEFT link's OLD target is what the RIGHT link BECOMES, the
    right one is rewritten first and the left one's pass -- if allowed to reach
    the whole line -- then matches the text just written to its right.

    Confining each replacement to its own recorded span is what closes this, and
    these are the assertions that go red without it: mutation-verified by
    replacing ``replace_markdown_at_span`` with the line-scoped
    ``replace_markdown_target``.  The other chain tests do NOT discriminate it --
    they are satisfied by the ordering change alone, which is why this class
    exists separately rather than as more cases alongside them.

    The same shape is still live in the sibling updater path (measured
    2026-08-30, reported at the fix checkpoint rather than fixed here).
    """

    def test_reverse_chain_does_not_overwrite_the_right_hand_link(self, tmp_path):
        result = move_and_rewrite_deep(
            tmp_path,
            "[a](../../doc/a.md) and [b](../doc/a.md)\n",
            targets=("doc/a.md", "sub/doc/a.md"),
        )

        assert result == "[a](../../../doc/a.md) and [b](../../doc/a.md)\n"
        # Corruption signature: the right link dragged up to the left link's depth.
        assert "[b](../../../doc/a.md)" not in result

    def test_reverse_chain_self_named_keeps_each_pair_consistent(self, tmp_path):
        result = move_and_rewrite_deep(
            tmp_path,
            "[../../doc/a.md](../../doc/a.md) and [../doc/a.md](../doc/a.md)\n",
            targets=("doc/a.md", "sub/doc/a.md"),
        )

        assert result == (
            "[../../../doc/a.md](../../../doc/a.md) and " "[../../doc/a.md](../../doc/a.md)\n"
        )


class TestDuplicateAndMultiLink:
    """Span-confined replacement means every reference needs its own rewrite."""

    def test_duplicate_targets_on_one_line_are_both_updated(self, tmp_path):
        """Removing the content-global pass removed the de-duplication with it.

        Both references name the same target, so each must be rewritten at its
        own span; collapsing them would leave the second stale.
        """
        result = move_and_rewrite(tmp_path, "[a](../doc/a.md) and [b](../doc/a.md)\n")

        assert result == "[a](../../doc/a.md) and [b](../../doc/a.md)\n"
        assert "../doc/a.md" not in result.replace("../../doc/a.md", "")

    def test_duplicate_targets_on_separate_lines_are_both_updated(self, tmp_path):
        result = move_and_rewrite(tmp_path, "[a](../doc/a.md)\nfiller\n[b](../doc/a.md)\n")

        assert result == "[a](../../doc/a.md)\nfiller\n[b](../../doc/a.md)\n"

    def test_distinct_targets_on_one_line_each_land_at_own_span(self, tmp_path):
        result = move_and_rewrite(
            tmp_path,
            "[a](../doc/a.md) and [b](../doc/b.md)\n",
            targets=("doc/a.md", "doc/b.md"),
        )

        assert result == "[a](../../doc/a.md) and [b](../../doc/b.md)\n"

    def test_markdown_and_positional_reference_share_a_line(self, tmp_path):
        """Ordering guard for the merged pass.

        A markdown link and a quoted path on one line are rewritten by what used
        to be two separate phases.  Merging them into one descending-ordered pass
        is only safe if neither invalidates the other's columns -- this pins it.
        """
        result = move_and_rewrite(
            tmp_path,
            '[a](../doc/a.md) see "../doc/b.md"\n',
            targets=("doc/a.md", "doc/b.md"),
        )

        assert result == '[a](../../doc/a.md) see "../../doc/b.md"\n'

    def test_link_text_and_surrounding_prose_are_preserved(self, tmp_path):
        """The span must not swallow neighbouring text."""
        result = move_and_rewrite(tmp_path, "Before [A doc](../doc/a.md) after.\n")

        assert result == "Before [A doc](../../doc/a.md) after.\n"
