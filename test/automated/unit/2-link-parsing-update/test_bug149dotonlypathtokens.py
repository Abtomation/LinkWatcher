"""
Document Metadata:
ID: TE-TST-161
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-30
Updated: 2026-08-30
Component Name: Parsers
Feature Id: 2.1.1
Language: Python
Test Name: Bug149DotOnlyPathTokens
Test Type: Unit
"""

# Bug149DotOnlyPathTokens Unit Test
#
# PD-BUG-149 regression: a bare parent-directory token (``../``, ``../../``)
# written inside a quote or backtick was registered as a reference by every
# parser.  A path built only from dot segments names no artifact -- it is
# notation, not a reference.
#
# The symptom: when the containing file moves to a different depth, the
# within-moved-file rewrite re-depths those tokens like real links, silently
# corrupting prose.  Observed 2026-08-29 in appdev, where the sentence
# "a template carries 7 `../` links" became "... 7 `../../` links".
#
# TWO predicates had to be guarded, not one.  ``looks_like_directory_path``
# accepted any string carrying a separator; guarding it alone fixed markdown,
# generic and python but left PowerShell, YAML and JSON still emitting the
# token -- because ``looks_like_file_path`` ALSO accepted it (it has a dot and
# a separator, so it reached that function's "'/' in text" branch and was
# classified as a FILE path).  Both now delegate to ``utils.is_dot_only_path``,
# which is why the per-parser cases below are exhaustive rather than
# representative: they are what caught the second route.
#
# Deliberately NOT suppressed: a token written in link syntax -- ``[x](../)`` --
# is an authored reference and is extracted by a different code path that never
# consults the helper.  That boundary is pinned below.
#
# Test File ID: TE-TST-161
# Created: 2026-08-30

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.link_types import LinkType
from linkwatcher.parser import LinkParser
from linkwatcher.parsers.generic import GenericParser
from linkwatcher.parsers.json_parser import JsonParser
from linkwatcher.parsers.markdown import MarkdownParser
from linkwatcher.parsers.powershell import PowerShellParser
from linkwatcher.parsers.python import PythonParser
from linkwatcher.parsers.yaml_parser import YamlParser
from linkwatcher.reference_lookup import ReferenceLookup
from linkwatcher.updater import LinkUpdater
from linkwatcher.utils import looks_like_directory_path

pytestmark = [
    pytest.mark.feature("2.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


# Paths built only from dot segments -- notation, never a reference.
DOT_ONLY = ["../", "../../", "../..", "../../..", "./..", "../.", "..\\", "..\\..\\"]

# Paths that name something and must keep resolving as directories.
NAMED = [
    "../doc/",
    "../../src",
    "../templates",
    "../../scripts/file-creation",
    "doc/x",
    "..hidden/x",  # a directory genuinely NAMED "..hidden"
    "a../b",
]


def _targets(refs):
    return [r.link_target for r in refs]


class TestBug149Helper:
    """The shared choke point every parser reaches."""

    @pytest.mark.parametrize("path", DOT_ONLY)
    def test_dot_only_path_is_not_a_directory(self, path):
        assert (
            looks_like_directory_path(path) is False
        ), f"{path!r} is notation, not a directory reference"

    @pytest.mark.parametrize("path", NAMED)
    def test_named_path_is_still_a_directory(self, path):
        assert (
            looks_like_directory_path(path) is True
        ), f"{path!r} names something and must stay a directory reference"


class TestBug149ParserDetection:
    """No parser may register a bare dot-only token, and every parser must keep
    detecting the named sibling written the same way."""

    def test_markdown_backtick(self):
        parser = MarkdownParser()
        refs = parser.parse_content("A template carries 7 `../` links.\n", "sub/n.md")
        assert "../" not in _targets(refs)

    def test_markdown_backtick_named_still_detected(self):
        parser = MarkdownParser()
        refs = parser.parse_content("Sources live in `../doc/` today.\n", "sub/n.md")
        assert "../doc/" in _targets(refs)

    def test_generic_quoted(self):
        parser = GenericParser()
        refs = parser.parse_content('a template with 7 "../" links\n', "n.txt")
        assert "../" not in _targets(refs)

    def test_generic_quoted_named_still_detected(self):
        parser = GenericParser()
        refs = parser.parse_content('sources in "../doc/" today\n', "n.txt")
        assert "../doc/" in _targets(refs)

    def test_python_quoted(self):
        parser = PythonParser()
        refs = parser.parse_content('# a template with 7 "../" links\n', "m.py")
        assert "../" not in _targets(refs)

    def test_python_quoted_named_still_detected(self):
        parser = PythonParser()
        refs = parser.parse_content('# sources in "../doc/" today\n', "m.py")
        assert "../doc/" in _targets(refs)

    def test_powershell_quoted(self):
        parser = PowerShellParser()
        refs = parser.parse_content('# a template with 7 "../" links\n', "m.ps1")
        assert "../" not in _targets(refs)

    def test_powershell_quoted_named_still_detected(self):
        parser = PowerShellParser()
        refs = parser.parse_content('# sources in "../doc/" today\n', "m.ps1")
        assert "../doc/" in _targets(refs)

    def test_yaml_value(self):
        parser = YamlParser()
        refs = parser.parse_content('base: "../"\n', "c.yaml")
        assert "../" not in _targets(refs)

    def test_yaml_value_named_still_detected(self):
        parser = YamlParser()
        refs = parser.parse_content('base: "../doc/"\n', "c.yaml")
        assert "../doc/" in _targets(refs)

    def test_json_value(self):
        parser = JsonParser()
        refs = parser.parse_content('{"base": "../"}\n', "c.json")
        assert "../" not in _targets(refs)

    def test_json_value_named_still_detected(self):
        parser = JsonParser()
        refs = parser.parse_content('{"base": "../doc/"}\n', "c.json")
        assert "../doc/" in _targets(refs)


class TestBug149PreservedBoundary:
    """A dot-only token written in LINK SYNTAX is an authored reference and must
    survive -- it is extracted without consulting the helper."""

    def test_markdown_link_to_parent_still_detected(self):
        parser = MarkdownParser()
        refs = parser.parse_content("See [parent](../) for details.\n", "sub/n.md")
        markdown = [r for r in refs if r.link_type == LinkType.MARKDOWN]
        assert "../" in [r.link_target for r in markdown]


class TestBug149MovedFileRewrite:
    """End-to-end reproduction of the reported incident."""

    def _move_and_rewrite(self, tmp_path, body):
        (tmp_path / "README.md").write_text("readme\n", encoding="utf-8")
        (tmp_path / "sub" / "deeper").mkdir(parents=True)
        src = tmp_path / "sub" / "note.md"
        src.write_text(body, encoding="utf-8")
        dst = tmp_path / "sub" / "deeper" / "note.md"
        src.rename(dst)

        lookup = ReferenceLookup(LinkDatabase(), LinkParser(), LinkUpdater(), str(tmp_path))
        lookup.update_links_within_moved_file("sub/note.md", "sub/deeper/note.md", str(dst))
        return dst.read_text(encoding="utf-8")

    def test_prose_spans_survive_and_real_link_is_redepthed(self, tmp_path):
        body = (
            "See [x](../README.md) for details.\n"
            "A template carries 7 `../` links.\n"
            "So `../../` lands one level up.\n"
            "Each `../` link is depth-bound.\n"
        )
        result = self._move_and_rewrite(tmp_path, body)

        # The authored markdown link IS re-depthed -- the feature still works.
        assert "[x](../../README.md)" in result

        # The prose spans are untouched. Negative assertions: the corrupted
        # forms must be absent, not merely the correct ones present.
        assert "carries 7 `../` links" in result
        assert "carries 7 `../../` links" not in result
        assert "So `../../` lands" in result
        assert "So `../../../` lands" not in result
        assert "Each `../` link" in result
        assert "Each `../../` link" not in result

    def test_named_backtick_directory_is_still_redepthed(self, tmp_path):
        """Guard against over-correction: a NAMED backtick directory inside a
        moved file must still follow the move."""
        body = "Sources live in `../README.md` today.\n"
        result = self._move_and_rewrite(tmp_path, body)
        assert "`../../README.md`" in result


# ---------------------------------------------------------------------------
# PD-BUG-151 / TD305 -- the guard above tested the span VERBATIM, so the same
# token written with surrounding whitespace walked straight past it.
#
# Root cause (TD305): the parsers captured the padding INTO the reference span,
# so ``link_target`` was " ../../ " and the recorded columns covered the padding
# too.  Two consequences, one loud and one silent:
#
#   (a) DOT-ONLY padded -- PD-BUG-151.  The token stayed registered, and the
#       whole span INCLUDING its padding was replaced by the recalculated value,
#       so `` ` ../../ ` `` came back as `` `..` ``.  Destroyed, not re-depthed,
#       and silent: it was counted in moved_file_links_updated.  Measured
#       destructive in five parsers -- markdown (backtick AND quoted), YAML,
#       JSON, PowerShell (quoted) and generic.  YAML and JSON put the damage in
#       structured config VALUES, not prose.
#
#   (b) NAMED padded -- TD305.  " doc/sub " never resolved on disk, so the
#       existence guard skipped it: the reference silently went stale on a move,
#       with no warning and no error.
#
# Both are fixed at one choke point rather than at the 39 construction sites:
# ``BaseParser.parse_content`` now normalizes every reference its subclass
# produced -- strip the target, shrink the columns onto it, and re-apply the
# path predicates so a token that only qualified BECAUSE of its padding is
# dropped.  Stripping alone would have been worse than the bug: " ../../ "
# would have become a tight "../../" that the PD-BUG-149 guard was written to
# suppress, reviving that symptom instead of fixing it.
#
# The normalization is deliberately confined to references whose recorded span
# is EXACTLY the target.  The two wide-span markdown types and the escaped
# structured types (where link_text is raw source and link_target is decoded)
# fail that equality and are left alone -- which is what keeps this change off
# the column contract PD-BUG-150 had just made load-bearing.
# ---------------------------------------------------------------------------

# The padded spelling of every dot-only token above.  " ../ " is inert on a
# one-level move (it recalculates to itself) but destructive on any deeper one,
# so the suite must not treat "no corruption at depth 1" as proof.
PADDED_DOT_ONLY = [" ../ ", " ../../ ", "  ../..  ", " ./.. ", " ..\\.. "]


def _spans(refs, line):
    """Every reference's (target, text actually covered by its columns)."""
    return [(r.link_target, line[r.column_start : r.column_end]) for r in refs]


class TestBug151PaddedTokenNotRegistered:
    """No parser may register a dot-only token just because it carries padding.

    Exhaustive across the five measured-destructive parsers rather than
    representative: PD-BUG-149 proved that guarding one route leaves the others
    emitting the token by a different one.
    """

    @pytest.mark.parametrize("token", PADDED_DOT_ONLY)
    def test_markdown_backtick_padded(self, token):
        refs = MarkdownParser().parse_content(f"So `{token}` lands up.\n", "sub/n.md")
        assert token not in _targets(refs), "the padded token must not be registered"
        assert token.strip() not in _targets(refs), "and stripping it must not revive PD-BUG-149"

    @pytest.mark.parametrize("token", PADDED_DOT_ONLY)
    def test_markdown_quoted_padded(self, token):
        refs = MarkdownParser().parse_content(f'A token: "{token}" in prose.\n', "sub/n.md")
        assert token not in _targets(refs)
        assert token.strip() not in _targets(refs)

    def test_generic_quoted_padded(self):
        refs = GenericParser().parse_content('value = " ../../ "\n', "n.txt")
        assert " ../../ " not in _targets(refs)
        assert "../../" not in _targets(refs)

    def test_powershell_quoted_padded(self):
        refs = PowerShellParser().parse_content('$x = " ../../ "\n', "m.ps1")
        assert " ../../ " not in _targets(refs)
        assert "../../" not in _targets(refs)

    def test_yaml_value_padded(self):
        refs = YamlParser().parse_content('base: " ../../ "\n', "c.yaml")
        assert " ../../ " not in _targets(refs)
        assert "../../" not in _targets(refs)

    def test_json_value_padded(self):
        refs = JsonParser().parse_content('{"base": " ../../ "}\n', "c.json")
        assert " ../../ " not in _targets(refs)
        assert "../../" not in _targets(refs)

    def test_python_quoted_padded(self):
        refs = PythonParser().parse_content('X = " ../../ "\n', "m.py")
        assert " ../../ " not in _targets(refs)
        assert "../../" not in _targets(refs)


class TestTD305SpanCoversExactlyTheTarget:
    """The invariant the fix installs: a reference's columns cover its target
    and nothing else, so a padded NAMED target is tracked by its real path."""

    def test_markdown_quoted_named_padded(self):
        line = 'Sources live in " doc/sub " today.'
        refs = MarkdownParser().parse_content(line + "\n", "sub/n.md")
        assert "doc/sub" in _targets(refs), "the padded named target must still be tracked"
        for target, covered in _spans(refs, line):
            assert covered == target, f"span {covered!r} does not cover target {target!r}"

    def test_generic_quoted_named_padded(self):
        line = 'value = " doc/sub "'
        refs = GenericParser().parse_content(line + "\n", "n.txt")
        assert "doc/sub" in _targets(refs)
        for target, covered in _spans(refs, line):
            assert covered == target

    def test_yaml_named_padded(self):
        line = 'base: " doc/sub "'
        refs = YamlParser().parse_content(line + "\n", "c.yaml")
        assert "doc/sub" in _targets(refs)

    def test_json_named_padded(self):
        line = '{"base": " doc/sub "}'
        refs = JsonParser().parse_content(line + "\n", "c.json")
        assert "doc/sub" in _targets(refs)

    def test_powershell_named_padded(self):
        line = '$p = " doc/sub "'
        refs = PowerShellParser().parse_content(line + "\n", "m.ps1")
        assert "doc/sub" in _targets(refs)

    def test_tight_named_target_is_unchanged(self):
        """Control: the overwhelmingly common tight spelling must be untouched."""
        line = 'Sources live in "doc/sub" today.'
        refs = MarkdownParser().parse_content(line + "\n", "sub/n.md")
        assert "doc/sub" in _targets(refs)
        for target, covered in _spans(refs, line):
            assert covered == target


class TestBug151PaddedUrlNotRegistered:
    """The same padding walked past the URL guard, which is a ``startswith``.

    Latent rather than live -- a padded URL never resolves, so it was registered
    and then silently skipped -- but it is the same evasion and the fix closes
    it, so it is pinned here.
    """

    #: Registered for BOTH spellings and out of scope here -- the PowerShell
    #: quoted scan also emits the scheme-less remainder, which is absolute and
    #: is dropped downstream by ``_filter_relative_links``.  Named so the
    #: assertions below stay on the ONE target the padding actually adds.
    SCHEMELESS = "//example.com/a.md"

    def test_powershell_padded_url(self):
        refs = PowerShellParser().parse_content('$u = " https://example.com/a.md "\n', "m.ps1")
        targets = [t for t in _targets(refs) if t != self.SCHEMELESS]
        assert targets == [], f"the padded URL evaded the startswith guard: {targets!r}"

    def test_tight_url_still_ignored(self):
        """Control: the tight spelling adds no such target, which is what makes
        the padded case above a real difference rather than a restatement."""
        refs = PowerShellParser().parse_content('$u = "https://example.com/a.md"\n', "m.ps1")
        targets = [t for t in _targets(refs) if t != self.SCHEMELESS]
        assert targets == []


class TestBug151MovedFileRewrite:
    """End-to-end: the padded spans must come back BYTE-IDENTICAL after a move
    that changes depth, and the padded NAMED reference must follow the move."""

    def _move_and_rewrite(self, tmp_path, name, body):
        (tmp_path / "README.md").write_text("readme\n", encoding="utf-8")
        (tmp_path / "doc" / "sub").mkdir(parents=True)
        (tmp_path / "doc" / "sub" / "keep.md").write_text("keep\n", encoding="utf-8")
        (tmp_path / "sub" / "deeper").mkdir(parents=True)
        src = tmp_path / "sub" / name
        src.write_text(body, encoding="utf-8")
        dst = tmp_path / "sub" / "deeper" / name
        src.rename(dst)

        lookup = ReferenceLookup(LinkDatabase(), LinkParser(), LinkUpdater(), str(tmp_path))
        lookup.update_links_within_moved_file(f"sub/{name}", f"sub/deeper/{name}", str(dst))
        return dst.read_text(encoding="utf-8")

    def test_padded_backtick_span_is_byte_identical(self, tmp_path):
        body = "So ` ../../ ` lands two levels up.\n"
        result = self._move_and_rewrite(tmp_path, "note.md", body)
        assert result == body, "a padded dot-only span is notation and must not be touched"
        assert "`..`" not in result

    def test_padded_quoted_span_is_byte_identical(self, tmp_path):
        body = 'A quoted padded token: " ../../ " in prose.\n'
        result = self._move_and_rewrite(tmp_path, "note.md", body)
        assert result == body
        assert '".."' not in result

    def test_padded_yaml_value_is_byte_identical(self, tmp_path):
        body = 'key: " ../../ "\nother: plain\n'
        result = self._move_and_rewrite(tmp_path, "conf.yaml", body)
        assert result == body, "a config VALUE must not be destroyed by a move"
        assert 'key: ".."' not in result

    def test_padded_json_value_is_byte_identical(self, tmp_path):
        body = '{\n  "key": " ../../ "\n}\n'
        result = self._move_and_rewrite(tmp_path, "conf.json", body)
        assert result == body
        assert '".."' not in result

    def test_padded_powershell_value_is_byte_identical(self, tmp_path):
        body = '$x = " ../../ "\n'
        result = self._move_and_rewrite(tmp_path, "script.ps1", body)
        assert result == body
        assert '".."' not in result

    def test_padded_generic_value_is_byte_identical(self, tmp_path):
        body = 'value = " ../../ "\n'
        result = self._move_and_rewrite(tmp_path, "plain.txt", body)
        assert result == body
        assert '".."' not in result

    @pytest.mark.parametrize(
        "name,body",
        [
            ("note.md", 'See " ../doc/sub " for details.\n'),
            ("note2.md", "See ` ../doc/sub ` for details.\n"),
            ("conf.yaml", 'k: " ../doc/sub "\n'),
            ("conf.json", '{\n  "k": " ../doc/sub "\n}\n'),
            ("plain.txt", 'v = " ../doc/sub "\n'),
        ],
    )
    def test_padded_named_directory_now_follows_the_move(self, tmp_path, name, body):
        """TD305 (b): measured STALE in all five shapes before the fix -- n=0,
        no warning, the reference simply stopped pointing anywhere.

        DIRECTORY references specifically.  A padded reference carrying a file
        EXTENSION was always captured tight, because the extension-bearing
        pattern uses a clean character class that cannot match a space; it is
        the extensionless quoted-directory patterns (``[^'"]*`` between
        delimiters) that swallow the padding.  Asserting this on a file target
        would have passed before the fix and proved nothing.
        """
        result = self._move_and_rewrite(tmp_path, name, body)
        assert result == body.replace(
            "../doc", "../../doc"
        ), "the padded directory target must be re-depthed, and its padding preserved"

    def test_powershell_padded_and_tight_refs_do_not_double_replace(self, tmp_path):
        """The PowerShell quoted scan emits BOTH a padded and a tight reference
        for one target.  Before the fix their spans differed, so the padded one
        was skipped by the existence guard and the contained-overlap filter had
        nothing to do.  Normalizing makes them IDENTICAL, and
        ``filter_contained_overlaps`` drops only STRICTLY contained spans -- so
        without deduplication both would replace at the same columns and splice
        the line twice.  Measured zero exact-duplicate references across both
        deployments, so the dedupe changes nothing else.
        """
        body = '$p = " ../doc/sub/keep.md "\n'
        result = self._move_and_rewrite(tmp_path, "script.ps1", body)
        assert result == '$p = " ../../doc/sub/keep.md "\n'

    def test_padded_one_level_token_is_also_untouched(self, tmp_path):
        """`` ` ../ ` `` was INERT before the fix -- it recalculated to itself on
        a one-level move -- so a suite that only exercised depth 1 would have
        called the bug fixed while it was not."""
        body = "So ` ../ ` lands one level up.\n"
        result = self._move_and_rewrite(tmp_path, "note.md", body)
        assert result == body


# ---------------------------------------------------------------------------
# PD-BUG-150 (round 3) -- the invariant above was enforced in ONE DIRECTION.
#
# ``BaseParser.parse_content`` states the contract every downstream stage
# assumes: ``link_target`` carries no surrounding whitespace, AND
# ``[column_start, column_end)`` covers exactly that target.  TD305 enforced the
# first half -- a PADDED target is stripped and its columns shrink onto it --
# and then early-returns on ``stripped == target``.
#
# That early return is the hole.  ``target`` is already tight in exactly the
# state a parser leaves behind when it strips the captured text INTO
# ``link_target`` but keeps the raw match extent for the columns.
# ``powershell.py``'s quoted-directory scan does precisely that
# (``potential_dir = match.group(1).strip()`` beside ``column_start=
# match.start(1)``), so the span still covers padding the target no longer
# names.  Positional replacement then splices the bare target across the whole
# span and the authored whitespace is destroyed -- silently, and counted as a
# successful update.
#
# Measured over the two live deployments: 47,057 real references, 16 damaged,
# every one of them ``POWERSHELL_QUOTED_DIR``.  Both rewrite paths carry it --
# a REGRESSION in the moved-file path (the leftmost ``str.replace`` it replaced
# preserved the padding) and PRE-EXISTING in the updater path, which has
# spliced at columns since PD-BUG-098.
#
# The invariant below is asserted type-agnostically ON PURPOSE.  Rounds 1 and 2
# of this fix both shipped an ENUMERATION of the wide-span types as
# load-bearing truth ("MARKDOWN and MARKDOWN_REFERENCE are the only ones"), and
# it was falsified both times.  An enumeration is a fact about today's parsers;
# the next parser that strips a target makes it false again with nothing to
# catch it.  So no list appears here: a reference may record a span WIDER than
# its target (a markdown construct, an escaped literal, a quote-spanning span),
# but never one that is wider AND strips to it -- that combination is the
# corrupting shape, and nothing else needs excluding.
# ---------------------------------------------------------------------------


def _violations(refs, line):
    """Every reference whose span is wider than its target but strips to it."""
    bad = []
    for r in refs:
        covered = line[r.column_start : r.column_end]
        if covered != r.link_target and covered.strip() == r.link_target:
            bad.append((r.link_type, r.link_target, covered))
    return bad


class TestBug150SpanNeverWiderThanTightTarget:
    """A span may exceed its target, but never by whitespace alone."""

    @pytest.mark.parametrize(
        "line",
        [
            '$dir = "  doc/target  "',  # padded both sides
            '$dir = "  doc/target"',  # leading only
            '$dir = "doc/target  "',  # trailing only
        ],
    )
    def test_powershell_quoted_directory_span_is_tight(self, line):
        """The filed shape.  Extensionless, so it reaches the quoted-DIRECTORY
        scan -- the one that strips.  A target carrying an extension is captured
        tight by a character class that cannot match a space, so asserting this
        on a file target would pass before the fix and prove nothing."""
        refs = PowerShellParser().parse_content(line + "\n", "m.ps1")
        assert "doc/target" in _targets(refs), "the padded directory must still be tracked"
        assert not _violations(refs, line), (
            "PD-BUG-150: the quoted-directory scan strips the captured text into "
            "link_target but keeps the RAW match extent for the columns, so the span "
            "covers padding the target no longer names; positional replacement then "
            "splices the bare target across it and destroys the whitespace.  "
            "Violations: {!r}".format(_violations(refs, line))
        )

    @pytest.mark.parametrize(
        "name,line",
        [
            ("m.ps1", '$dir = "  doc/target  "'),
            ("n.md", 'A path: "  doc/target  " in prose.'),
            ("n.md", "A path: `  doc/target  ` in prose."),
            ("n.txt", 'value = "  doc/target  "'),
            ("c.yaml", 'base: "  doc/target  "'),
            ("c.json", '{"base": "  doc/target  "}'),
            ("m.py", 'p = "  doc/target  "'),
            ("m.dart", "import '  doc/target  ';"),
        ],
    )
    def test_no_parser_records_a_whitespace_wide_span(self, name, line):
        """Type-agnostic, across every parser the dispatcher routes to.

        Deliberately NOT a list of permitted wide-span types -- see the block
        comment above for why an enumeration is the thing being removed here.
        """
        refs = LinkParser().parse_content(line + "\n", name)
        assert not _violations(refs, line), "span wider than target by whitespace: {!r}".format(
            _violations(refs, line)
        )

    def test_construct_spanning_markdown_keeps_its_wide_span(self):
        """Control against OVER-tightening.  An inline markdown span covers the
        whole ``[text](target)`` construct and must stay that way -- its
        format-aware replacer needs it.  It survives because the construct does
        not strip to its target, which is what makes the invariant safe to state
        without an exclusion list."""
        line = "See [the doc](doc/sub/target.md) here."
        refs = [
            r
            for r in MarkdownParser().parse_content(line + "\n", "n.md")
            if r.link_type == LinkType.MARKDOWN
        ]
        assert refs, "the inline markdown link must still be parsed"
        for r in refs:
            covered = line[r.column_start : r.column_end]
            assert covered != r.link_target, "the markdown span must stay construct-wide"
            assert covered.strip() != r.link_target, "and must not strip to its target"

    @pytest.mark.parametrize(
        "line",
        [
            '    [lbl]: doc/a.md "Title"',
            "  [lbl]: doc/a.md",
        ],
    )
    def test_indented_reference_definition_keeps_its_recorded_columns(self, line):
        """Pins the ``span.strip() != target`` half of the guard.

        An INDENTED reference definition is the one shape found in real content
        whose span is wider than its target AND carries edge whitespace (a
        census over 47k references found exactly one instance).  Tightening it
        would advance ``column_start`` past the indent while ``column_end``
        stayed put, so the recorded span would no longer bracket the construct
        it describes.

        Deliberately asserts the COLUMNS, not an absence of corruption: no
        corruption follows today, because a reference definition is rewritten by
        a replacer anchored on the ``[label]:`` prefix that never reads the span.
        Measured -- with the guard removed the damage oracle still reports zero
        damage across the repo.  Claiming this guard prevents live corruption
        would be the same false load-bearing claim that got rounds 1 and 2 of
        this fix rejected; what it actually guarantees is that normalization
        never moves a span it does not understand.
        """
        refs = [
            r
            for r in MarkdownParser().parse_content(line + "\n", "n.md")
            if r.link_type == LinkType.MARKDOWN_REFERENCE
        ]
        assert refs, "the reference definition must still be parsed"
        for r in refs:
            assert (r.column_start, r.column_end) == (0, len(line)), (
                "normalization moved a construct-spanning span: recorded {!r}, "
                "expected the whole definition line {!r}".format(
                    line[r.column_start : r.column_end], line
                )
            )
