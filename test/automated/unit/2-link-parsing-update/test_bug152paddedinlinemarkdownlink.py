"""
Document Metadata:
ID: TE-TST-163
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-31
Updated: 2026-08-31
Component Name: Replacement
Feature Id: 2.2.1
Language: Python
Test Name: Bug152PaddedInlineMarkdownLink
Test Type: Unit
"""

# Bug152PaddedInlineMarkdownLink Unit Test
#
# PD-BUG-152 -- a padded inline markdown link is never re-depthed on a move.
#
# CommonMark allows whitespace around an inline link destination, and all three
# spellings render to an identical anchor:
#
#     [x]( ../doc/y.md )      [x]( ../doc/y.md)      [x](../doc/y.md )
#
# The markdown parser strips the captured destination, so ``link_target`` holds
# the TIGHT path while the source line is padded.  ``replace_markdown_target``
# then anchors its pattern on ``](`` IMMEDIATELY followed by the target, and on
# the target immediately followed by a title or ``)``:
#
#     (\[)([^\]]*)(\]\()({escaped_target})(\s+["'(][^"')]*["')])?(\))
#
# Those two juxtapositions can never hold for a padded link, so the substitution
# finds no match and the line is returned unchanged.  The link is left pointing
# at a path that no longer exists.
#
# SCOPE -- both rewrite paths, one choke point.  The bug was filed as
# moved-file-only.  It is not: ``replace_markdown_target`` is reached by BOTH
# rewrite paths -- the updater path (references in OTHER files) via
# ``replace_in_line``, and the moved-file path via ``replace_markdown_at_span``
# since the PD-BUG-153 fix.  The updater path is the larger exposure, since it
# reaches every file referencing a moved target rather than only the file being
# moved, and it fails SILENTLY: no warning and no count.  The moved-file path at
# least emits ``link_target_not_found_on_line``.
#
# FIX -- the pattern tolerates optional whitespace on both sides of the target
# and writes the authored whitespace back verbatim.  Preserving rather than
# normalizing it is the rule PD-BUG-118 / PD-BUG-120 / PD-BUG-124 established
# and the reference-definition replacer already honours: a rewrite changes WHERE
# a link points, never HOW it was written.
#
# Test File ID: TE-TST-163
# Created: 2026-08-31

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.link_types import LinkType
from linkwatcher.models import LinkReference
from linkwatcher.parser import LinkParser
from linkwatcher.reference_lookup import ReferenceLookup
from linkwatcher.replacement import replace_markdown_target
from linkwatcher.updater import LinkUpdater

pytestmark = [
    pytest.mark.feature("2.2.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


def md_ref(target, line="f.md", start=0, end=0, text="x"):
    """A MARKDOWN reference carrying the TIGHT target the parser records."""
    return LinkReference(
        file_path=line,
        line_number=1,
        column_start=start,
        column_end=end,
        link_text=text,
        link_target=target,
        link_type=LinkType.MARKDOWN,
    )


def move_and_rewrite(tmp_path, body, targets=("doc/a.md",)):
    """Move sub/note.md -> sub/deeper/note.md; return the rewritten content.

    ``targets`` are created so the existence guard in the recalculation does
    not skip the links under test.
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


def update_other_file(tmp_path, body, old="doc/a.md", new="doc2/a.md"):
    """Rewrite references to a moved target inside ANOTHER file (updater path).

    References come from the REAL parser rather than being hand-built, so the
    columns and targets under test are the ones production actually produces.
    """
    other = tmp_path / "other.md"
    other.write_text(body, encoding="utf-8")

    refs = LinkParser().parse_file(str(other))
    updater = LinkUpdater()
    updater.set_dry_run(False)
    updater.set_backup_enabled(False)
    stats = updater.update_references(refs, old, new)
    return other.read_text(encoding="utf-8"), stats


class TestBug152ChokePoint:
    """The shared replacer both rewrite paths funnel through."""

    @pytest.mark.parametrize(
        "line,expected",
        [
            # Padding on both sides, leading only, trailing only.
            ("[x]( ../doc/y.md )", "[x]( ../../doc/y.md )"),
            ("[x]( ../doc/y.md)", "[x]( ../../doc/y.md)"),
            ("[x](../doc/y.md )", "[x](../../doc/y.md )"),
            # Wider padding must survive at its authored width.
            ("[x](   ../doc/y.md   )", "[x](   ../../doc/y.md   )"),
        ],
    )
    def test_padded_target_is_replaced_and_padding_preserved(self, line, expected):
        out = replace_markdown_target(line, md_ref("../doc/y.md"), "../../doc/y.md")

        assert out == expected
        # Negative assertion: the defect returned the line UNCHANGED, so a
        # positive-only check for the new target would pass against a line that
        # still carried the old one somewhere.
        assert "( ../doc/y.md" not in out
        assert "(../doc/y.md " not in out

    @pytest.mark.parametrize(
        "line,expected",
        [
            ('[x]( ../doc/y.md "T" )', '[x]( ../../doc/y.md "T" )'),
            ("[x]( ../doc/y.md 'T')", "[x]( ../../doc/y.md 'T')"),
            ("[x](../doc/y.md (T) )", "[x](../../doc/y.md (T) )"),
        ],
    )
    def test_padding_and_title_are_both_preserved(self, line, expected):
        out = replace_markdown_target(line, md_ref("../doc/y.md"), "../../doc/y.md")

        assert out == expected

    def test_tight_form_is_unaffected(self):
        """Control: the spelling that always worked must be untouched."""
        out = replace_markdown_target(
            '[x](../doc/y.md "T")', md_ref("../doc/y.md"), "../../doc/y.md"
        )

        assert out == '[x](../../doc/y.md "T")'

    def test_self_named_text_still_updates_with_padding(self):
        """The PD-BUG-012 link-text rule must survive the widened pattern.

        Exact equality against the TIGHT target: the text here is unpadded, so
        the rule fires even though the destination is padded.
        """
        out = replace_markdown_target(
            "[../doc/y.md]( ../doc/y.md )",
            md_ref("../doc/y.md", text="../doc/y.md"),
            "../../doc/y.md",
        )

        assert out == "[../../doc/y.md]( ../../doc/y.md )"
        assert "[../doc/y.md]" not in out

    def test_non_matching_target_is_left_alone(self):
        """Control: a padded link to a DIFFERENT target must not be rewritten."""
        line = "[x]( ../doc/other.md )"
        out = replace_markdown_target(line, md_ref("../doc/y.md"), "../../doc/y.md")

        assert out == line


class TestBug152MovedFilePath:
    """The filed repro: the link lives inside the file that moves."""

    @pytest.mark.parametrize(
        "body,expected",
        [
            ("See [d]( ../doc/a.md ) here.\n", "See [d]( ../../doc/a.md ) here.\n"),
            ("See [d]( ../doc/a.md) here.\n", "See [d]( ../../doc/a.md) here.\n"),
            ("See [d](../doc/a.md ) here.\n", "See [d](../../doc/a.md ) here.\n"),
        ],
    )
    def test_padded_link_follows_the_move(self, tmp_path, body, expected):
        result = move_and_rewrite(tmp_path, body)

        assert result == expected
        assert "../doc/a.md" not in result.replace("../../doc/a.md", "")

    def test_padded_and_tight_links_on_one_line_both_follow(self, tmp_path):
        """The tight link always worked; the padded one must now join it.

        Discriminating condition: before the fix this line came back with the
        tight half re-depthed and the padded half stale, so the assertion can
        fail on exactly the defect.
        """
        result = move_and_rewrite(
            tmp_path,
            "A [p]( ../doc/a.md ) and B [t](../doc/b.md).\n",
            targets=("doc/a.md", "doc/b.md"),
        )

        assert result == "A [p]( ../../doc/a.md ) and B [t](../../doc/b.md).\n"

    def test_padded_chain_collision_does_not_compound(self, tmp_path):
        """Widening the pattern must not revive the PD-BUG-153 compounding.

        The chain-collision shape: one reference's NEW target equals another's
        OLD target.  Before PD-BUG-153 the markdown rewrite was content-global,
        so the second pass re-rewrote the first link and compounded it to a
        different file.  Span confinement fixed that -- and it has to keep
        holding now that padded links match too, since padded occurrences were
        previously invisible to the substitution entirely.
        """
        result = move_and_rewrite(
            tmp_path,
            "[x]( doc/a.md ) and [y]( ../doc/a.md )\n",
            targets=("sub/doc/a.md", "doc/a.md"),
        )

        assert result == "[x]( ../doc/a.md ) and [y]( ../../doc/a.md )\n"
        # The compounding signature is the FIRST link reaching ../../ .
        assert "[x]( ../../doc/a.md )" not in result

    def test_padded_reference_definition_still_preserved(self, tmp_path):
        """Control: MARKDOWN_REFERENCE takes a different replacer entirely.

        It already handled padding correctly; the fix must not disturb it.
        """
        result = move_and_rewrite(tmp_path, "[lbl]:  ../doc/a.md  \n\nSee [x][lbl].\n")

        assert result == "[lbl]:  ../../doc/a.md  \n\nSee [x][lbl].\n"


class TestBug152UpdaterPath:
    """The half the bug was NOT filed against, and the larger exposure.

    A padded link in ANY other file pointing at a moved target. This path fails
    silently -- no warning and no count -- so nothing surfaces the stale link.
    """

    @pytest.mark.parametrize(
        "body,expected",
        [
            ("See [d]( doc/a.md ) here.\n", "See [d]( doc2/a.md ) here.\n"),
            ("See [d]( doc/a.md) here.\n", "See [d]( doc2/a.md) here.\n"),
            ("See [d](doc/a.md ) here.\n", "See [d](doc2/a.md ) here.\n"),
        ],
    )
    def test_padded_link_in_another_file_is_updated(self, tmp_path, body, expected):
        content, stats = update_other_file(tmp_path, body)

        assert content == expected
        assert stats["references_updated"] >= 1

    def test_padded_link_with_title_in_another_file(self, tmp_path):
        content, _ = update_other_file(tmp_path, 'See [d]( doc/a.md "T" ).\n')

        assert content == 'See [d]( doc2/a.md "T" ).\n'

    def test_tight_link_in_another_file_unaffected(self, tmp_path):
        """Control: the spelling that always worked."""
        content, _ = update_other_file(tmp_path, "See [d](doc/a.md) here.\n")

        assert content == "See [d](doc2/a.md) here.\n"
