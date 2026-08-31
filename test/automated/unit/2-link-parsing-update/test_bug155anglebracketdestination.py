"""
Document Metadata:
ID: TE-TST-165
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-31
Updated: 2026-08-31
Component Name: Parsers
Feature Id: 2.1.1
Language: Python
Test Name: Bug155AngleBracketDestination
Test Type: Unit
"""

# Bug155AngleBracketDestination Unit Test
#
# PD-BUG-155 -- a CommonMark angle-bracket destination is never updated on a
# move, on either rewrite path.
#
# CommonMark permits the destination of an inline link AND of a reference
# definition to be enclosed in angle brackets, and REQUIRES that form when the
# path contains a space:
#
#     [x](<doc/a b.md>)        [label]: <doc/a b.md>
#
# ``MarkdownParser._extract_url_from_link_content`` strips whitespace and peels
# titles but never unwraps the brackets, so ``link_target`` holds
# ``<doc/a b.md>`` -- brackets included.  Everything downstream then fails for
# that one reason, each in a different way and all of them SILENTLY:
#
#   * updater path (references in OTHER files) -- the database is keyed on
#     target, so the reference is never SELECTED for a moved file.  No warning,
#     no count, no stale-file entry.
#   * moved-file path (re-depth) -- the bracketed "path" never resolves on
#     disk, so the existence guard drops it before replacement is reached.
#   * ``--validate`` -- the validator's placeholder filter is
#     ``YYYY|XXX|HHMMSS|<[^>]+>|\\[[a-z][a-z-]*\\]``, so EVERY angle-wrapped
#     target is discarded as a template placeholder and never checked on disk.
#     The documented recovery procedure therefore cannot find these stale links.
#   * ``_is_skippable_target`` -- ``<https://x>`` is not recognised as external,
#     so an angle-wrapped URL is registered as a file reference.
#
# The PowerShell parser's embedded-markdown-link extraction carries the same
# defect independently.
#
# SCOPE -- one defect, three capture sites.  The markdown fix lands once in
# ``_extract_url_from_link_content``, which serves BOTH the inline-link and the
# reference-definition extractors.
#
# FIX -- unwrap at capture, preserve at replacement.  ``unwrap_angle_destination``
# unwraps only a well-formed CommonMark angle destination (opens ``<``, closes
# ``>``, no ``<`` or ``>`` between), and the two markdown replacers try an
# angle-wrapped pattern variant before today's tight one, writing the brackets
# back verbatim.  Preserving rather than normalizing the authored form is the
# PD-BUG-118 / PD-BUG-120 / PD-BUG-124 / PD-BUG-152 rule: a rewrite changes
# WHERE a link points, never HOW it was written.  For PowerShell the recorded
# span COVERS the brackets, so the unwrap is paired with narrowing that span --
# without it, positional replacement would splice the new target over the
# brackets and emit a tight destination containing a space, turning a silent
# no-op into invalid CommonMark.
#
# Test File ID: TE-TST-165
# Created: 2026-08-31

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.link_types import LinkType
from linkwatcher.parser import LinkParser
from linkwatcher.parsers.markdown import MarkdownParser
from linkwatcher.parsers.powershell import PowerShellParser
from linkwatcher.reference_lookup import ReferenceLookup
from linkwatcher.updater import LinkUpdater

pytestmark = [
    pytest.mark.feature("2.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


# --------------------------------------------------------------------------
# Helpers -- both drive the REAL production entry points, so the columns and
# targets under test are the ones production actually produces.
# --------------------------------------------------------------------------


def targets_of(body, file_name="f.md", parser=None):
    """Parse one body and return the recorded targets."""
    parser = parser or MarkdownParser()
    return [r.link_target for r in parser.parse_content(body, file_name)]


def update_other_file(tmp_path, body, old, new, name="other.md"):
    """Updater path: rewrite references to a moved target inside ANOTHER file."""
    other = tmp_path / name
    other.write_text(body, encoding="utf-8")

    refs = LinkParser().parse_file(str(other))
    updater = LinkUpdater()
    updater.set_dry_run(False)
    updater.set_backup_enabled(False)
    updater.update_references(refs, old, new)
    return other.read_text(encoding="utf-8")


def move_and_rewrite(tmp_path, body, targets):
    """Moved-file path: move sub/note.md -> sub/deeper/note.md, return content.

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


# --------------------------------------------------------------------------
# Capture -- the root cause
# --------------------------------------------------------------------------


class TestAngleBracketCapture:
    """The recorded target must be the PATH, never the angle-bracket syntax."""

    def test_inline_angle_destination_captured_without_brackets(self):
        assert targets_of("[x](<doc/a.md>)") == ["doc/a.md"]

    def test_inline_angle_destination_with_space_captured_without_brackets(self):
        # The one case CommonMark REQUIRES the angle form for.
        assert targets_of("[x](<doc/a b.md>)") == ["doc/a b.md"]

    def test_inline_angle_destination_with_title_captured_without_brackets(self):
        # Unwrapping must happen AFTER the title is peeled off.
        assert targets_of('[x](<doc/a.md> "the title")') == ["doc/a.md"]

    def test_reference_definition_angle_destination_captured_without_brackets(self):
        refs = MarkdownParser().parse_content("[label]: <doc/a b.md>", "f.md")
        assert [r.link_target for r in refs] == ["doc/a b.md"]
        assert refs[0].link_type == LinkType.MARKDOWN_REFERENCE

    def test_angle_wrapped_url_is_skipped_not_registered_as_a_file(self):
        # Unwrapping lets the external-target guard see the scheme it was
        # always meant to reject.
        assert targets_of("[x](<https://example.com>)") == []
        assert targets_of("[x](<mailto:a@b.c>)") == []

    def test_tight_destination_is_untouched_by_the_unwrap(self):
        assert targets_of("[x](doc/a.md)") == ["doc/a.md"]

    def test_malformed_angle_destination_is_not_unwrapped(self):
        # Not a valid CommonMark angle destination: it carries an unescaped
        # '<' inside.  Discriminating case -- a naive strip("<>") passes the
        # tests above and fails here.
        assert targets_of("[x](<doc/a<b.md>)") == ["<doc/a<b.md>"]

    def test_powershell_records_no_bracketed_target(self):
        # Behaviour-level and deliberately not filtered by link type.  For a
        # space-free path the parser emits a POWERSHELL_COMMENT reference over
        # the very same span as the embedded one, and ``_deduplicate`` (keyed on
        # line + target + column_start) legitimately collapses the identical
        # pair -- so asserting that a specific link TYPE survives would pin
        # dedup internals rather than the defect.  What must hold either way is
        # that no reference carries the bracket syntax in its target.
        for line in ("# see [x](<doc/a.md>)", "# see [x](<doc/a b.md>)"):
            targets = targets_of(line, "s.ps1", parser=PowerShellParser())
            assert targets, line
            assert not any("<" in t or ">" in t for t in targets), targets

    def test_powershell_embedded_span_excludes_the_brackets(self):
        # Load-bearing: this span is spliced positionally, so a span still
        # covering the brackets would have the new target written OVER them.
        # The spaced path is required to reach the embedded reference at all --
        # see the dedup note above.
        line = "# see [x](<doc/a b.md>)"
        ref = [
            r
            for r in PowerShellParser().parse_content(line, "s.ps1")
            if r.link_type == LinkType.POWERSHELL_EMBEDDED_MD_LINK
        ][0]
        assert ref.link_target == "doc/a b.md"
        assert line[ref.column_start : ref.column_end] == "doc/a b.md"


# --------------------------------------------------------------------------
# Updater path -- references in OTHER files to a moved target
# --------------------------------------------------------------------------


class TestUpdaterPath:
    """The larger exposure: every file referencing a moved target."""

    def test_angle_destination_follows_the_move(self, tmp_path):
        out = update_other_file(tmp_path, "[a](<doc/a.md>)\n", "doc/a.md", "doc2/a.md")
        assert "[a](<doc2/a.md>)" in out
        assert "<doc/a.md>" not in out

    def test_spaced_angle_destination_follows_the_move(self, tmp_path):
        out = update_other_file(tmp_path, "[a](<doc/a b.md>)\n", "doc/a b.md", "doc2/a b.md")
        assert "[a](<doc2/a b.md>)" in out
        assert "<doc/a b.md>" not in out

    def test_angle_destination_keeps_its_title(self, tmp_path):
        out = update_other_file(tmp_path, '[a](<doc/a.md> "the title")\n', "doc/a.md", "doc2/a.md")
        assert '[a](<doc2/a.md> "the title")' in out

    def test_reference_definition_angle_destination_follows_the_move(self, tmp_path):
        out = update_other_file(tmp_path, "[label]: <doc/a b.md>\n", "doc/a b.md", "doc2/a b.md")
        assert "[label]: <doc2/a b.md>" in out
        assert "<doc/a b.md>" not in out

    def test_tight_control_still_follows_the_move(self, tmp_path):
        out = update_other_file(tmp_path, "[c](doc/a.md)\n", "doc/a.md", "doc2/a.md")
        assert "[c](doc2/a.md)" in out

    def test_powershell_embedded_angle_destination_keeps_its_brackets(self, tmp_path):
        # The SPACED path is deliberate.  For a space-free path the PowerShell
        # parser also emits a POWERSHELL_COMMENT reference capturing the bare
        # path at the correct span, and that reference rewrites the line on its
        # own -- so a space-free case passes even with the embedded reference
        # still broken, and pins nothing.  With a space, the comment reference
        # captures only the trailing fragment, which cannot match the moved
        # path, leaving the embedded reference as the only one that can act.
        out = update_other_file(
            tmp_path,
            "# see [x](<doc/a b.md>)\n",
            "doc/a b.md",
            "doc2/a b.md",
            name="s.ps1",
        )
        # Pins the span narrowing: without it the new target is spliced OVER
        # the brackets and the authored form is destroyed.
        assert "[x](<doc2/a b.md>)" in out
        assert "<doc/a b.md>" not in out


# --------------------------------------------------------------------------
# Moved-file path -- the moved file's own relative links get re-depthed
# --------------------------------------------------------------------------


class TestMovedFilePath:
    """The links inside the file that moved."""

    def test_angle_destination_is_re_depthed(self, tmp_path):
        out = move_and_rewrite(tmp_path, "[a](<../doc/a.md>)\n", ("doc/a.md",))
        assert "[a](<../../doc/a.md>)" in out
        assert "[a](<../doc/a.md>)" not in out

    def test_spaced_angle_destination_is_re_depthed(self, tmp_path):
        out = move_and_rewrite(tmp_path, "[s](<../doc/a b.md>)\n", ("doc/a b.md",))
        assert "[s](<../../doc/a b.md>)" in out
        assert "[s](<../doc/a b.md>)" not in out

    def test_tight_control_still_re_depthed(self, tmp_path):
        out = move_and_rewrite(tmp_path, "[c](../doc/a.md)\n", ("doc/a.md",))
        assert "[c](../../doc/a.md)" in out

    def test_angle_and_tight_on_one_line_both_follow(self, tmp_path):
        out = move_and_rewrite(
            tmp_path,
            "[c](../doc/a.md) and [a](<../doc/b.md>)\n",
            ("doc/a.md", "doc/b.md"),
        )
        assert "[c](../../doc/a.md)" in out
        assert "[a](<../../doc/b.md>)" in out
