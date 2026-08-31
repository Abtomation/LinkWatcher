"""Position-aware link replacement primitives shared by the two rewrite paths.

Both places LinkWatcher rewrites a link target need the *same* hardened
mechanics: replace at the column span the parser recorded, drop references whose
span is contained inside another on the same line, and refuse an ambiguous
unbounded replacement rather than corrupting the line.

Those mechanics were written once, in ``updater._apply_replacements`` (PD-BUG-098),
and the sibling path -- ``reference_lookup._replace_links_in_lines``, which rewrites
links *inside a file that just moved* -- kept a position-blind
``line.replace(target, new, 1)`` instead.  That gap produced PD-BUG-150: with two
self-similar references on one line, every replacement landed on the leftmost
match, compounding the first span to a wrong depth and leaving the second stale.

The same shape had already recurred three times (PD-BUG-118, PD-BUG-119,
PD-BUG-120): a fix lands at the choke point for references in OTHER files while
the moved-file path stays uncovered.  Extracting to this leaf module -- rather
than copying the logic a third time -- is what stops the next recurrence: there
is one implementation, and both callers reach it.

Dispatch lives here too, in :func:`replace_in_line`, and that placement is the
lesson of the first attempt at this fix.  Some link types record a span WIDER
than their target -- ``MARKDOWN`` and ``MARKDOWN_REFERENCE``, whose spans cover
the whole ``[text](target)`` / ``[label]: target "title"`` construct -- so
splicing a bare target across that span destroys the label, the text and the
title.  ``updater`` had always guarded against this by dispatching on link type
BEFORE reaching positional replacement.  The first PD-BUG-150 fix adopted the
primitive without that guard, and silently overwrote every reference definition
in a moved file.  Keeping the dispatch beside the primitive is what stops a
caller from picking one up without the other.

**Do not read that list as a complete inventory of wide spans.**  Rounds 1 and 2
of PD-BUG-150 each shipped one as load-bearing truth -- "``MARKDOWN`` and
``MARKDOWN_REFERENCE`` are the only types whose span is wider than their target,
so those two branches are the whole guard" -- and it was falsified both times,
most recently by ``POWERSHELL_QUOTED_DIR``, whose scan strips the captured text
into ``link_target`` while the columns keep the raw match extent.  Splicing
across that span destroyed the author's whitespace, silently, on BOTH rewrite
paths.  A span narrower than the construct is now guaranteed upstream instead of
enumerated here: ``BaseParser.parse_content`` enforces that a reference's columns
cover exactly its target unless the span covers a whole construct
(``base._tighten_span``, keyed on ``span.strip() == target``, so construct-
spanning and escaped spans are excluded by construction rather than by name).
The dispatch below handles the construct-spanning types; the invariant handles
everything else, including a parser added later that nobody remembers to list.

AI Context
----------
- **Callers**: ``LinkUpdater._replace_in_line`` / ``_replace_markdown_target`` /
  ``_replace_reference_target`` / ``_replace_at_position`` /
  ``_filter_contained_overlaps`` (thin delegators, so the updater's own
  behaviour is unchanged) and ``ReferenceLookup._replace_links_in_lines``,
  which reaches :func:`replace_markdown_at_span` for inline markdown links and
  :func:`replace_in_line` for every other type.  Since PD-BUG-154 those two
  arrive at the same place -- :func:`replace_in_line` routes ``MARKDOWN`` to
  the span-confined helper as well -- so the moved-file path's explicit
  special-case is now redundant rather than load-bearing, and both callers get
  span confinement whichever entry point they use.
- **Entry point for callers rewriting one reference**: :func:`replace_in_line`.
  Reach for :func:`replace_at_position` directly only when the link type is
  known not to be one of the two wide-span markdown types.
- **Leaf module**: imports only ``link_types`` and ``models``, so it can never
  close an import cycle with either caller.
- **Ordering contract**: ``replace_at_position`` trusts the caller's columns.
  A caller applying several replacements to one line MUST work right-to-left
  (descending ``column_start``), or an earlier replacement's length change
  leaves the next span's columns pointing into shifted text.
"""

import json
import re
from functools import lru_cache
from typing import Callable, Dict, List, Optional, Set, Tuple

from .link_types import LinkType
from .models import LinkReference

#: Link types whose recorded span may cover an ESCAPED source literal, so
#: ``link_text`` (raw source) and ``link_target`` (decoded value) legitimately
#: differ (PD-BUG-126).
ESCAPABLE_STRUCTURED_TYPES = (
    LinkType.JSON,
    LinkType.JSON_DIR,
    LinkType.YAML,
    LinkType.YAML_DIR,
)

#: Link types whose recorded span may include the surrounding quote characters.
QUOTE_SPANNING_TYPES = (
    LinkType.MARKDOWN_QUOTED,
    LinkType.QUOTED,
    LinkType.PYTHON_QUOTED,
    LinkType.HTML_ANCHOR,
)

#: Cap on the compiled-pattern cache (TD142).  Held here rather than on
#: ``LinkUpdater`` since the patterns are built from the reference, not from
#: any instance state, so one process-wide cache serves both rewrite paths.
_REGEX_CACHE_MAX_SIZE = 1024


@lru_cache(maxsize=_REGEX_CACHE_MAX_SIZE)
def _compiled(pattern: str) -> "re.Pattern":
    """Compile ``pattern``, reusing an earlier compilation when possible."""
    return re.compile(pattern)


def filter_contained_overlaps(
    replacement_items: List[Tuple[LinkReference, str]],
    file_path: str,
    logger,
) -> List[Tuple[LinkReference, str]]:
    """Drop refs whose column range is strictly contained in another ref
    on the same line (PD-BUG-098).

    Scope — strictly-contained overlap only.  Partial overlap (where two
    ranges overlap but neither strictly contains the other, e.g. ranges
    ``[5, 12)`` and ``[10, 18)``) is NOT addressed by this filter and
    would still produce the bottom-up replacement corruption.  Partial
    overlap has not been observed in practice (the canonical PD-BUG-098
    trigger — bare filename inside a longer path — always yields strict
    containment), so the simpler containment-only filter is sufficient
    until a reproducer for partial overlap surfaces.

    When two refs on the same line overlap such that one strictly contains
    the other, descending-column processing produces corrupted output.  The
    inner ref's replacement extends the line; the outer ref's original column
    positions are then stale, and position-based slicing yields
    ``<new_target> + chopped_tail`` because ``line[outer_end_col:]`` indexes
    into the freshly-inserted text.

    The outer ref's replacement covers the inner range textually, so
    dropping the inner ref preserves the intended outer rewrite.  When
    both refs would rewrite to a path resolving to the same file (the
    canonical trigger — directory moves where the inner is a bare-filename
    ref to the moved file), the result is identical to the non-overlapping
    case.  When their new_targets diverge, the outer wins; this is no
    worse than the previous behavior, which produced corruption.

    Args:
        replacement_items: List of ``(LinkReference, new_target)`` tuples.
        file_path: Source-file path for log messages.
        logger: Structured logger used to report each dropped ref.

    Returns:
        Filtered list with strictly-contained inner refs removed.  Order
        is otherwise preserved.
    """
    # Group items by 1-based line_number; preserve original index so the
    # returned list keeps stable ordering for items not dropped.
    by_line: Dict[int, List[Tuple[int, LinkReference, str]]] = {}
    for original_idx, (ref, new_target) in enumerate(replacement_items):
        by_line.setdefault(ref.line_number, []).append((original_idx, ref, new_target))

    dropped_indices: Set[int] = set()

    for line_number, line_items in by_line.items():
        if len(line_items) < 2:
            continue
        # For each pair, mark the strictly-contained one as dropped.
        for i, (_, ref_a, _) in enumerate(line_items):
            if line_items[i][0] in dropped_indices:
                continue
            a_start, a_end = ref_a.column_start, ref_a.column_end
            for j, (_, ref_b, _) in enumerate(line_items):
                if i == j or line_items[j][0] in dropped_indices:
                    continue
                b_start, b_end = ref_b.column_start, ref_b.column_end
                # B strictly contained in A: a_start <= b_start
                # and b_end <= a_end and ranges differ.
                if a_start <= b_start and b_end <= a_end and (a_start, a_end) != (b_start, b_end):
                    dropped_indices.add(line_items[j][0])
                    logger.warning(
                        "overlapping_references_resolved",
                        file_path=file_path,
                        line_number=line_number,
                        outer_target=ref_a.link_target,
                        outer_range=(a_start, a_end),
                        inner_target=ref_b.link_target,
                        inner_range=(b_start, b_end),
                        reason=(
                            "PD-BUG-098: inner ref strictly contained in outer; dropping inner"
                        ),
                    )

    if not dropped_indices:
        return replacement_items

    return [
        item
        for original_idx, item in enumerate(replacement_items)
        if original_idx not in dropped_indices
    ]


def replace_at_position(
    line: str,
    ref: LinkReference,
    new_target: str,
    logger,
    on_ambiguous_skip: Optional[Callable[[], None]] = None,
) -> str:
    """Replace ``ref``'s target at its recorded column span within ``line``.

    Args:
        line: The single line of file content holding the reference.
        ref: The parsed reference, carrying ``column_start`` / ``column_end``.
        new_target: The recalculated target to write in its place.
        logger: Structured logger used to report an ambiguous skip.
        on_ambiguous_skip: Optional callback invoked when an unbounded
            replacement was refused, so a caller tracking statistics can
            surface the skip.

    Returns:
        The updated line, or the original line when the replacement was
        refused as ambiguous.
    """
    # Special handling for Python imports - replace the text, not the target
    if ref.link_type == LinkType.PYTHON_IMPORT:
        # For Python imports, we need to replace the dot notation in the line
        # Convert new_target (slash notation) back to dot notation
        new_import_text = new_target.replace("/", ".")
        # PD-BUG-094 / TD251: bounded regex with negative lookbehind/lookahead
        # makes a second application a safe no-op. Without this, an unbounded
        # str.replace would substring-match inside the already-prefixed result
        # if duplicate refs ever reached this method (PD-BUG-096 class).
        pattern = r"(?<![.\w])" + re.escape(ref.link_text) + r"(?!\w)"
        return re.sub(pattern, new_import_text, line)

    # Use column positions to replace only the specific occurrence
    start_col = ref.column_start
    end_col = ref.column_end

    # Validate positions
    if start_col < 0 or end_col > len(line) or start_col >= end_col:
        # Fall back to bounded replacement when positions are invalid
        # (PD-BUG-098). Unbounded ``line.replace(old, new)`` would replace
        # every occurrence of ``link_target`` on the line, producing
        # multi-substitution corruption when the target appears more than
        # once.  Skip ambiguous cases (0 or >1 occurrences) and replace
        # exactly one occurrence otherwise.
        occurrences = line.count(ref.link_target)
        if occurrences == 1:
            return line.replace(ref.link_target, new_target, 1)
        if occurrences > 1:
            logger.warning(
                "ambiguous_fallback_replacement_skipped",
                file_path=ref.file_path,
                line_number=ref.line_number,
                link_target=ref.link_target,
                occurrences=occurrences,
                reason=(
                    "PD-BUG-098: invalid columns + multiple matches; refusing unbounded replace"
                ),
            )
            # TD252 / Option C: surface this silent skip in UpdateStats["errors"]
            # so callers see that a ref could not be safely replaced.  STALE-
            # escalation was rejected (whole-file blast radius for a single
            # ambiguous ref); per-skip counter preserves visibility without
            # blocking other refs in the same file.
            if on_ambiguous_skip is not None:
                on_ambiguous_skip()
        return line

    # PD-BUG-126 / PD-BUG-124 class: when the span covers an ESCAPED
    # source literal, the replacement has to be written in the same
    # escaped form -- splicing raw text into an escaped string literal
    # is exactly what left files unparseable before.
    if (
        ref.link_type in ESCAPABLE_STRUCTURED_TYPES
        and ref.link_text
        and ref.link_text != ref.link_target
    ):
        # ensure_ascii=False is load-bearing, not a preference: the
        # default would re-spell every non-ASCII character as a \uXXXX
        # escape, so a path holding one comes back in a different
        # spelling than the author wrote.  It stays valid and decodes
        # identically, but a rewrite changes WHERE a target points, never
        # HOW it was written -- the rule PD-BUG-118 / PD-BUG-120 /
        # PD-BUG-124 exist to enforce.  Backslashes and quotes are still
        # escaped either way, which is what keeps the file parseable.
        new_target = json.dumps(new_target, ensure_ascii=False)[1:-1]

    # Extract the text at the specified position
    text_at_position = line[start_col:end_col]

    # For quoted references, the text might include quotes
    if (
        ref.link_type in QUOTE_SPANNING_TYPES
        and text_at_position.startswith('"')
        and text_at_position.endswith('"')
    ):
        # Replace just the content inside quotes
        return line[:start_col] + f'"{new_target}"' + line[end_col:]
    elif (
        ref.link_type in QUOTE_SPANNING_TYPES
        and text_at_position.startswith("'")
        and text_at_position.endswith("'")
    ):
        # Replace just the content inside single quotes
        return line[:start_col] + f"'{new_target}'" + line[end_col:]
    else:
        # Direct replacement at position
        return line[:start_col] + new_target + line[end_col:]


def replace_markdown_target(line: str, ref: LinkReference, new_target: str) -> str:
    """Replace an inline markdown link's target, preserving its title and spacing.

    The recorded span covers the whole ``[text](target "title")`` construct, so
    the rewrite is done with a format-aware regex rather than by slicing the
    span.  When the link text is exactly the old target it is updated too
    (PD-BUG-012) -- a link written as ``[doc/a.md](doc/a.md)`` would otherwise
    keep advertising a path that no longer exists.

    CommonMark permits whitespace around the destination -- ``[x]( a.md )`` and
    ``[x](a.md)`` render identically -- and the parser records the target
    STRIPPED.  The pattern therefore matches that padding explicitly and writes
    it back unchanged; a padded link was previously left untouched by both
    rewrite paths, silently (PD-BUG-152).

    Args:
        line: The single line of file content holding the reference.
        ref: The parsed reference, whose ``link_target`` anchors the pattern.
        new_target: The recalculated target to write in its place.

    Returns:
        The updated line, unchanged when the pattern does not match.
    """
    escaped_target = re.escape(ref.link_target)

    # PD-BUG-155: the destination may be enclosed in CommonMark angle brackets,
    # which the parser no longer records as part of the target.  The wrapped
    # spelling is tried first and the brackets are written back verbatim; the
    # tight pattern below is unchanged.  The two variants cannot be confused
    # for one another: the wrapped one requires a literal ``<`` right after
    # ``](``, which no tight link has, and ``\s*`` in the tight one cannot
    # match that ``<``.
    #
    # [text](  target  optional_title  ) — text captured separately so it can be
    # updated when it matches the old target.  Titles: "x", 'x' or (x).
    #
    # Groups 4 and 7 capture the whitespace CommonMark permits around the
    # destination, and it is written back verbatim (PD-BUG-152).  The parser
    # strips that padding out of ``link_target``, so without these groups the
    # two juxtapositions this pattern requires -- ``](`` immediately followed by
    # the target, and the target immediately followed by a title or ``)`` --
    # could never hold for a padded link: the substitution matched nothing and
    # returned the line unchanged, leaving the link pointing at a path that no
    # longer exists.  Preserving the padding rather than normalizing it away is
    # the PD-BUG-118 / PD-BUG-120 / PD-BUG-124 rule, which the sibling
    # :func:`replace_reference_target` already honours: a rewrite changes WHERE
    # a link points, never HOW it was written.
    for opener, closer in (("<", ">"), ("", "")):
        pattern = (
            rf"(\[)([^\]]*)(\]\()(\s*){re.escape(opener)}({escaped_target}){re.escape(closer)}"
            rf"((?:\s+[\"'(][^\"')]*[\"')])?)(\s*)(\))"
        )

        def replace_func(match, opener=opener, closer=closer):
            link_text = match.group(2)
            # The link TEXT is a label, not a destination, so it never takes
            # the brackets even when the destination is wrapped.
            if link_text == ref.link_target:
                link_text = new_target
            return (
                f"{match.group(1)}{link_text}{match.group(3)}{match.group(4)}"
                f"{opener}{new_target}{closer}"
                f"{match.group(6)}{match.group(7)}{match.group(8)}"
            )

        rewritten, count = _compiled(pattern).subn(replace_func, line)
        if count:
            return rewritten

    return line


def replace_markdown_at_span(line: str, ref: LinkReference, new_target: str) -> str:
    """Rewrite an inline markdown link, CONFINED to its recorded column span.

    :func:`replace_markdown_target` anchors on the target and substitutes every
    match in whatever string it is handed.  Handed a whole line -- or whole file
    content -- that reach is too wide: a second reference whose OLD target equals
    this one's NEW target re-matches the text this call just wrote and re-depths
    it a second time, silently pointing a link at a different file.  Confining
    the substitution to the span the parser recorded for THIS reference makes
    each rewrite independent of every other -- the same discipline
    :func:`replace_at_position` gives every non-markdown type.  Both rewrite
    paths hit this shape and both are now routed here: PD-BUG-153 inside a moved
    file, PD-BUG-154 on the updater path via :func:`replace_in_line`.

    A ``MARKDOWN`` span exactly covers its ``[text](target "title")`` construct:
    measured across 13 shapes (titles in all three quotings, backticked and bold
    text, mid-line, several per line, table cells, list items) with 0 exceptions.
    The shape guard is a safety net for a span that is invalid or not
    construct-shaped, falling back to the line-scoped helper rather than
    refusing the rewrite.

    Args:
        line: The single line of file content holding the reference.
        ref: The parsed reference, carrying ``column_start`` / ``column_end``.
        new_target: The recalculated target to write in its place.

    Returns:
        The updated line, unchanged when the pattern does not match.
    """
    start, end = ref.column_start, ref.column_end
    if 0 <= start < end <= len(line):
        construct = line[start:end]
        if construct.startswith("[") and construct.endswith(")"):
            rewritten = replace_markdown_target(construct, ref, new_target)
            return line[:start] + rewritten + line[end:]

    return replace_markdown_target(line, ref, new_target)


def replace_reference_target(line: str, ref: LinkReference, new_target: str) -> str:
    """Replace the target of a reference definition ``[label]: target "title"``.

    The parser records this reference's span as the WHOLE definition line, so
    positional replacement would overwrite the label and the title along with
    the target -- destroying the definition and orphaning every ``[text][label]``
    usage in the file.  Anchoring on the label instead keeps both.

    Args:
        line: The single line of file content holding the definition.
        ref: The parsed reference, whose ``link_target`` anchors the pattern.
        new_target: The recalculated target to write in its place.

    Returns:
        The updated line, unchanged when the pattern does not match.
    """
    escaped_target = re.escape(ref.link_target)

    # [label]: target optional_title — titles: "x", 'x' or (x).
    # The destination may be angle-wrapped here exactly as in an inline link,
    # so the same two variants are tried and the brackets written back verbatim
    # (PD-BUG-155).
    for opener, closer in (("<", ">"), ("", "")):
        pattern = (
            rf"(\[[^\]]*\]:\s*){re.escape(opener)}({escaped_target}){re.escape(closer)}"
            rf"(\s+[\"'(][^\"')]*[\"')])?(\s*$)"
        )

        def replace_func(match, opener=opener, closer=closer):
            title_part = match.group(3) if match.group(3) else ""
            end_part = match.group(4) if match.group(4) else ""
            return f"{match.group(1)}{opener}{new_target}{closer}{title_part}{end_part}"

        rewritten, count = _compiled(pattern).subn(replace_func, line)
        if count:
            return rewritten

    return line


def replace_in_line(
    line: str,
    ref: LinkReference,
    new_target: str,
    logger,
    on_ambiguous_skip: Optional[Callable[[], None]] = None,
) -> str:
    """Rewrite one reference's target within ``line``, choosing by link type.

    This is the entry point every caller should use.  ``MARKDOWN`` and
    ``MARKDOWN_REFERENCE`` record a span covering the whole enclosing construct
    rather than just the target, so they are routed to a format-aware regex
    instead of being sliced positionally; everything else is replaced at the
    column span the parser recorded.  Bypassing this dispatch is what turned the
    first PD-BUG-150 fix into a reference-definition-destroying regression.

    ``MARKDOWN`` goes to :func:`replace_markdown_at_span`, which runs that
    format-aware regex CONFINED to the reference's own span.  It was routed to
    the line-scoped :func:`replace_markdown_target` until PD-BUG-154: with two
    links on one line and two moves in one batch, a link whose OLD target equals
    a neighbour's NEW target re-matched the text that neighbour's pass had just
    written and re-pointed it at a third file -- silently, both counting as
    updated.  Descending column order does not save this, because it is the LEFT
    link's pass that reaches rightward over text already rewritten.

    ``MARKDOWN_REFERENCE`` stays line-scoped and is safe there: its pattern is
    anchored to the ``[label]:`` prefix and end-of-line, so a definition line
    admits exactly one match and has no neighbour to reach.

    Those two are the ONLY wide-span types: measured end to end at the rework,
    driving a move through every link-type shape the parsers emit (33 shapes
    across markdown, Python, YAML, JSON, Dart, PowerShell and generic), only
    the markdown link and the reference definition damaged text outside their
    target under positional replacement.

    Args:
        line: The single line of file content holding the reference.
        ref: The parsed reference.
        new_target: The recalculated target to write in its place.
        logger: Structured logger used to report an ambiguous skip.
        on_ambiguous_skip: Optional callback invoked when an unbounded
            replacement was refused, so a caller tracking statistics can
            surface the skip.

    Returns:
        The updated line, or the original line when nothing was replaced.
    """
    if ref.link_type == LinkType.MARKDOWN:
        return replace_markdown_at_span(line, ref, new_target)
    if ref.link_type == LinkType.MARKDOWN_REFERENCE:
        return replace_reference_target(line, ref, new_target)
    return replace_at_position(line, ref, new_target, logger, on_ambiguous_skip)
