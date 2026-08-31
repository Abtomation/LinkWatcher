"""
Document Metadata:
ID: TE-TST-164
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-31
Updated: 2026-08-31
Component Name: LinkUpdater
Feature Id: 2.2.1
Language: Python
Test Name: Bug154UpdaterMarkdownSpanReach
Test Type: Unit
"""

# Bug154UpdaterMarkdownSpanReach Unit Test
#
# PD-BUG-154 -- the updater's markdown rewrite reaches past its own span.
#
# ``replacement.replace_in_line`` dispatched ``MARKDOWN`` to
# ``replace_markdown_target``, which anchors on the target and substitutes EVERY
# match in whatever string it is handed.  Handed a whole line, that reach is too
# wide: a second link whose OLD target equals this one's NEW target re-matches
# text a previous pass just wrote, and gets re-pointed at a different file.
#
# Descending column order protects the FORWARD chain and not the REVERSE one.
# Measured on the pre-fix source, one line with two links, two moves in one
# batch (``old/a.md`` -> ``new/a.md`` and ``new/a.md`` -> ``final/a.md``):
#
#     [x](old/a.md)  [y](new/a.md)   ->  [x](new/a.md)    [y](final/a.md)   correct
#     [x](new/a.md)  [y](old/a.md)   ->  [x](final/a.md)  [y](final/a.md)   WRONG
#
# In the second shape the right link is rewritten first, to ``new/a.md``; the
# left link's pass then anchors on ``new/a.md``, matches BOTH occurrences, and
# lands both links on ``final/a.md``.  Silent -- both count as updated and no
# warning is emitted.
#
# This is the PD-BUG-153 shape surviving on the sibling path.  PD-BUG-153 closed
# it inside a moved FILE by routing that path through
# ``replace_markdown_at_span``; the updater path -- references in OTHER files --
# kept the line-scoped helper.  The fix moves the shared dispatch onto the
# span-confined helper, so BOTH callers of ``replace_in_line`` get confinement
# and the two paths stop diverging.  That divergence is the exact failure mode
# ``replacement.py`` exists to prevent (PD-BUG-098 / 118 / 119 / 120 / 150).
#
# Reachability, established at triage: the only production caller of
# ``update_references_batch`` is the directory-move Phase 1b batch, whose moves
# are uniformly prefixed (every old path under ``old_dir``, every new path under
# ``new_dir``), so the old-path and new-path sets are disjoint and the chain
# cannot form from production input today.  These tests therefore pin a defect
# in the shared unit, before a future caller inherits it.
#
# Test File ID: TE-TST-164
# Created: 2026-08-31

import pytest

from linkwatcher.link_types import LinkType
from linkwatcher.logging import get_logger
from linkwatcher.models import LinkReference
from linkwatcher.parsers.markdown import MarkdownParser
from linkwatcher.replacement import replace_in_line
from linkwatcher.updater import LinkUpdater

pytestmark = [
    pytest.mark.feature("2.2.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


def batch_rewrite(tmp_path, body, moves, targets=("old/a.md", "new/a.md", "final/a.md")):
    """Write ``body`` to index.md, drive ``moves`` through the batch updater.

    References come from the real ``MarkdownParser``, so the column spans under
    test are the ones the parser actually records rather than hand-built ones.
    ``targets`` are created because target existence gates the recalculation.
    """
    for rel in targets:
        p = tmp_path / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("target\n", encoding="utf-8")

    index = tmp_path / "index.md"
    index.write_text(body, encoding="utf-8")

    refs = MarkdownParser().parse_file(str(index))

    move_groups = []
    for old, new in moves:
        group = [r for r in refs if r.link_target == old]
        if group:
            move_groups.append((group, old, new))

    updater = LinkUpdater(project_root=str(tmp_path))
    updater.backup_enabled = False
    updater.update_references_batch(move_groups)

    return index.read_text(encoding="utf-8")


CHAIN_MOVES = (("old/a.md", "new/a.md"), ("new/a.md", "final/a.md"))


class TestBug154ReverseChain:
    """The defect proper: a left link must not be re-pointed by its own pass."""

    def test_reverse_chain_leaves_the_right_link_alone(self, tmp_path):
        result = batch_rewrite(
            tmp_path,
            "See [x](new/a.md) and [y](old/a.md) here.\n",
            CHAIN_MOVES,
        )

        assert result == "See [x](final/a.md) and [y](new/a.md) here.\n"
        # Negative assertion carries the regression.  A positive-only check
        # ("final/a.md is present") passes against the bug, because the LEFT
        # link was always rewritten correctly -- it is the RIGHT link that gets
        # overwritten, so the tell is final/a.md appearing TWICE.
        assert result.count("final/a.md") == 1

    def test_forward_chain_is_unaffected(self, tmp_path):
        """Control: the mirror shape was already correct and must stay correct.

        Descending column order rewrites the right link first, and its anchor
        never matches the left link's different target.  If this regresses, the
        fix broke ordering rather than reach.
        """
        result = batch_rewrite(
            tmp_path,
            "See [x](old/a.md) and [y](new/a.md) here.\n",
            CHAIN_MOVES,
        )

        assert result == "See [x](new/a.md) and [y](final/a.md) here.\n"
        assert result.count("final/a.md") == 1


class TestBug154SpanConfinementPreservesMarkdownRules:
    """Confining the rewrite must not drop what the format-aware replacer does."""

    def test_title_is_preserved(self, tmp_path):
        """A MARKDOWN span covers ``[text](target "title")`` -- title included.

        Splicing a bare target across that span would destroy the title, which
        is the regression the first PD-BUG-150 fix shipped.  The span-confined
        helper delegates to the format-aware replacer INSIDE the span, so the
        title survives.
        """
        result = batch_rewrite(
            tmp_path,
            'See [x](old/a.md "The A doc") here.\n',
            (("old/a.md", "new/a.md"),),
        )

        assert result == 'See [x](new/a.md "The A doc") here.\n'

    def test_self_named_link_text_still_follows_the_move(self, tmp_path):
        """PD-BUG-012: text identical to the target is updated with it."""
        result = batch_rewrite(
            tmp_path,
            "See [old/a.md](old/a.md) here.\n",
            (("old/a.md", "new/a.md"),),
        )

        assert result == "See [new/a.md](new/a.md) here.\n"
        assert "[old/a.md]" not in result

    def test_non_matching_link_text_is_left_alone(self, tmp_path):
        """Boundary: the PD-BUG-012 rule is exact equality, never resemblance."""
        result = batch_rewrite(
            tmp_path,
            "See [`old/a.md`](old/a.md) here.\n",
            (("old/a.md", "new/a.md"),),
        )

        assert result == "See [`old/a.md`](new/a.md) here.\n"

    def test_duplicate_targets_on_one_line_are_both_updated(self, tmp_path):
        """Guard on the fix, not on the bug.

        Line-scoped replacement rewrote both duplicates in the FIRST pass and
        the second ref then short-circuited on the "already handled" branch.
        Span confinement removes that accident, so each duplicate must now be
        rewritten by its own pass.  If confinement were applied without the
        per-ref passes still running, this line would come back half-updated.
        """
        result = batch_rewrite(
            tmp_path,
            "See [x](old/a.md) and [y](old/a.md) here.\n",
            (("old/a.md", "new/a.md"),),
        )

        assert result == "See [x](new/a.md) and [y](new/a.md) here.\n"
        assert "old/a.md" not in result

    def test_reference_definition_stays_on_the_label_anchored_path(self, tmp_path):
        """Boundary: MARKDOWN_REFERENCE must NOT be routed to the span helper.

        Its span covers the whole definition line, so span-slicing would eat the
        label and orphan every ``[text][label]`` usage.  It stays with
        ``replace_reference_target``.
        """
        result = batch_rewrite(
            tmp_path,
            "[lbl]: old/a.md\nSee [x][lbl].\n",
            (("old/a.md", "new/a.md"),),
        )

        assert result == "[lbl]: new/a.md\nSee [x][lbl].\n"


class TestBug154DispatchMechanism:
    """Pin the dispatch itself, independent of the updater that calls it."""

    def test_replace_in_line_confines_markdown_to_the_recorded_span(self):
        """``replace_in_line`` is the shared entry point BOTH rewrite paths use.

        Asserting here rather than only through the updater is what makes the
        fix load-bearing for the other caller too: a future change that reverts
        the MARKDOWN branch to the line-scoped helper turns this red even if no
        updater-level scenario happens to exercise the chain.
        """
        line = "See [x](new/a.md) and [y](new/a.md) here.\n"
        # Span of the LEFT link only: "[x](new/a.md)" starts at column 4.
        ref = LinkReference(
            file_path="index.md",
            line_number=1,
            column_start=4,
            column_end=17,
            link_text="x",
            link_target="new/a.md",
            link_type=LinkType.MARKDOWN,
        )

        result = replace_in_line(line, ref, "final/a.md", get_logger())

        assert result == "See [x](final/a.md) and [y](new/a.md) here.\n"
        assert result.count("final/a.md") == 1
