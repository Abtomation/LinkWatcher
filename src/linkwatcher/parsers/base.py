"""
Base parser interface for file type specific parsers.

This module defines the common interface that all parsers must implement.
"""

import os.path
import re
from abc import ABC, abstractmethod
from typing import Generator, List, Tuple

from ..logging import get_logger
from ..models import LinkReference
from ..utils import (
    find_line_number,
    looks_like_directory_path,
    looks_like_file_path,
    safe_file_read,
)
from .patterns import QUOTED_DIR_PATTERN


class BaseParser(ABC):
    """
    Abstract base class for file parsers.

    All file type specific parsers should inherit from this class
    and implement the parse_content method.
    """

    def __init__(self):
        self.logger = get_logger()

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """
        Read a file and parse its content for link references.

        Args:
            file_path: Path to the file to parse

        Returns:
            List of LinkReference objects found in the file
        """
        try:
            content = self._safe_read_file(file_path)
            return self.parse_content(content, file_path)
        except Exception as e:
            self.logger.warning(
                "parse_error",
                file_path=file_path,
                parser=type(self).__name__,
                error=str(e),
            )
            return []

    @abstractmethod
    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """
        Parse content string for link references.

        Args:
            content: The file content to parse
            file_path: Path used for LinkReference entries (not read from disk)

        Returns:
            List of LinkReference objects found in the content
        """
        pass

    def _looks_like_file_path(self, text: str) -> bool:
        """Check if text looks like a file path."""
        return looks_like_file_path(text)

    def _looks_like_directory_path(self, text: str) -> bool:
        """Check if text looks like a directory path (PD-BUG-021)."""
        return looks_like_directory_path(text)

    # Sentence punctuation a bare-path regex may swallow but which is prose,
    # not part of the path (PD-BUG-118).
    _TRAILING_PUNCTUATION = ".,;:!?"

    @classmethod
    def _trim_trailing_punctuation(cls, path: str) -> str:
        """Strip trailing sentence punctuation captured into a bare path
        (PD-BUG-118).

        Bare-path character classes include ``.``, so a path written at the end
        of a sentence ("templates live in doc/x/.") is captured *with* the
        period.  Every character inside a reference's recorded span is replaced
        when the target moves, so that punctuation was eaten from the prose —
        one of the reported PD-BUG-118 symptoms.

        This is the post-match form of the trailing-boundary lookahead the
        markdown standalone pattern already uses (PD-BUG-080); the bare-path,
        @-prefix and docstring-directory patterns never got one.

        A genuine trailing parent-directory segment (``../../..``) is preserved
        — only punctuation that is not exactly a ``..`` segment is trimmed.
        """
        trimmed = path.rstrip(cls._TRAILING_PUNCTUATION)
        removed = path[len(trimmed) :]
        if removed == ".." and trimmed.endswith(("/", "\\")):
            return path
        return trimmed

    def _safe_read_file(self, file_path: str) -> str:
        """Safely read file content."""
        return safe_file_read(file_path)

    def _find_line_number(self, lines: List[str], search_text: str) -> int:
        """Find line number containing specific text."""
        return find_line_number(lines, search_text)

    # --- Shared structured-data helpers (TD-180) ---

    #: Regex for extracting file paths from compound strings.
    #: Shared by YAML and JSON parsers (PD-BUG-060, PD-BUG-061).
    _path_pattern = re.compile(r"([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)")

    #: Matches a QUOTED extensionless directory inside a compound value.
    #: Reused from the shared pattern module (PD-BUG-131): the generic,
    #: markdown, python and powershell parsers already recognise a directory
    #: only when it is delimited, and the structured parsers now follow the
    #: same convention rather than accepting bare tokens -- which would
    #: harvest every slash-bearing prose fragment ("UI/UX Design",
    #: "File/directory names to exclude").
    _dir_pattern = QUOTED_DIR_PATTERN

    #: A directory candidate must be a CLEAN path token -- the same character
    #: class ``_path_pattern`` demands of a file candidate.  Without this the
    #: quoted-directory pattern spans the gap between two *prose* apostrophes:
    #: measured against a real config template, ``'{name}_test' (Dart/Go),
    #: '{name}.test'`` yielded the candidate `` (Dart/Go), `` (PD-BUG-131).
    _dir_token_pattern = re.compile(r"^[a-zA-Z0-9_\-./\\]+$")

    @staticmethod
    def _is_paired_delimiter(line: str, match) -> bool:
        r"""Is the delimiter pair around *match* a real literal?

        PD-BUG-135.  The directory patterns are delimiter-class regexes that
        require a separator *inside* the span::

            QUOTED_DIR_PATTERN     ['"]([^'"]*[/\\][^'"]*)['"]
            backtick_dir_pattern   `([^`]*[/\\][^`]*)`

        When a legitimate literal holds no separator the regex fails at that
        start position and re-anchors on the literal's CLOSING delimiter,
        pairing it with the NEXT literal's OPENING delimiter -- so the text
        between two literals is captured whenever it holds a ``/`` or ``\``.
        The dominant real shape is two backticked literals joined by a slash
        (```a` / `b``` yielding ``" / "`` 383 times in this repo's markdown).

        Two conditions make the pair a genuine literal:

        1. the opening delimiter really opens -- an EVEN number of that same
           character precedes it on the line; and
        2. the closing delimiter is the SAME character, so the span cannot
           straddle two literals of different quote styles.

        Deliberately NOT the clean-path-token guard used for the python
        sibling (PD-BUG-133): measured against this repo that rule deleted 997
        markdown references including ``~/bin`` (11x, the documented install
        directory) and 265 PowerShell references including ``Program
        Files/Git`` and every ``$Variable``-bearing path.

        Line-local by design.  A line whose delimiters genuinely do not pair
        (unbalanced prose apostrophes) can lose a real reference; measured
        cost was 3 references across the repo, all inside malformed nested
        backticks that markdown itself renders outside the code span.

        Takes the match rather than two offsets: the opening delimiter sits
        immediately before group 1, but the closing one is the match's LAST
        character, which is not ``end(1)`` for every pattern -- a pattern may
        admit a suffix between the captured path and its closing delimiter
        (markdown's ``backtick_path_pattern`` allows a ``:12-14`` line-number
        suffix).  Deriving both ends from the match keeps the guard correct
        for any such caller.
        """
        start = match.start(1)
        close = match.end() - 1
        if start <= 0 or close >= len(line) or close < start:
            return False
        opening = line[start - 1]
        if opening != line[close]:
            return False
        return line[: start - 1].count(opening) % 2 == 0

    def _collect_path_candidates(self, data: str) -> List[Tuple[int, int, str, bool]]:
        """Collect path candidates embedded in a compound string.

        Returns ``(start, end, text, is_dir)`` per candidate, ordered by
        position, with each span addressing *data*.

        File candidates (PD-BUG-060 / PD-BUG-061) come from the
        extension-bearing ``_path_pattern``.  Directory candidates
        (PD-BUG-131) come from the shared quoted-directory pattern: before
        this the structured parsers had no directory mechanic inside a
        compound value at all, so such a value produced no candidates and fell
        through to whole-string classification, which registered the ENTIRE
        command string as the target.

        A quoted path carrying an extension matches both patterns, so a
        directory candidate is kept only when it is not a file path and does
        not overlap a file candidate already collected.
        """
        candidates: List[Tuple[int, int, str, bool]] = []
        for match in self._path_pattern.finditer(data):
            text = match.group(1)
            if ("/" in text or "\\" in text) and self._looks_like_file_path(text):
                candidates.append((match.start(1), match.end(1), text, False))

        for match in self._dir_pattern.finditer(data):
            text = match.group(1)
            if not self._dir_token_pattern.match(text):
                continue
            if self._looks_like_file_path(text) or not self._looks_like_directory_path(text):
                continue
            start, end = match.start(1), match.end(1)
            if any(start < f_end and f_start < end for f_start, f_end, _, _ in candidates):
                continue
            candidates.append((start, end, text, True))

        candidates.sort(key=lambda c: c[0])
        return candidates

    #: Matches one double-quoted source literal, honouring backslash escapes
    #: (PD-BUG-126).  The alternation consumes either an ordinary character or
    #: a complete two-character escape, so an escaped quote never ends a match.
    _quoted_literal_pattern = re.compile(r'"(?:[^"\\]|\\.)*"')

    @classmethod
    def _find_decoded_literal(
        cls,
        lines: List[str],
        decoded: str,
        decoder,
        start_line: int = 0,
        taken=None,
    ) -> Tuple[int, int, int, str]:
        """Locate the source literal that DECODES to *decoded* (PD-BUG-126).

        The structured-data parsers hand out values their format decoder has
        already unescaped, but every span they record must address the RAW
        source.  For an escape-free value those are the same text, so a plain
        substring search finds it.  As soon as the author uses any escape the
        two diverge, the substring search fails, and the reference used to be
        dropped silently -- taking its target stale on the next move.

        Rather than search for the decoded text, walk the double-quoted
        literals actually present in the source and decode each one; that
        matches whichever spelling the author chose.

        Returns ``(line_number, col_start, col_end, raw_inner)`` addressing the
        text INSIDE the quotes, or ``(0, 0, 0, "")`` when nothing matches.
        """
        taken = taken if taken is not None else set()
        span = min(start_line, len(lines))
        order = list(range(span, len(lines))) + list(range(0, span))

        for line_idx in order:
            for match in cls._quoted_literal_pattern.finditer(lines[line_idx]):
                inner_start = match.start() + 1
                inner_end = match.end() - 1
                if (line_idx + 1, inner_start) in taken:
                    continue
                raw_inner = lines[line_idx][inner_start:inner_end]
                # Escape-free literals are already handled by the caller's
                # plain search; skipping them confines this path to the case it
                # exists for and avoids re-claiming ordinary values.
                if "\\" not in raw_inner:
                    continue
                try:
                    if decoder(match.group(0)) != decoded:
                        continue
                except Exception:
                    continue
                return line_idx + 1, inner_start, inner_end, raw_inner

        return 0, 0, 0, ""

    @staticmethod
    def _build_decoded_to_raw_index(raw_inner, decoder):
        r"""Map decoded character offsets onto RAW offsets (PD-BUG-130).

        ``_find_decoded_literal`` above answers *where the literal is*; this
        answers *where inside it each decoded character came from*, which is
        what a path embedded in a compound value needs.  The regex that finds
        path candidates runs over the DECODED string, so its spans are decoded
        offsets -- and every span a reference records must address RAW source.
        Adding a decoded offset to a raw column is how PD-BUG-124 corrupted
        files; the two agree only while the literal is escape-free.

        The map is built by decoding successively longer PREFIXES of the raw
        literal with the format's own decoder, rather than reimplementing
        escape rules.  A prefix that ends inside an escape simply fails to
        decode and is skipped, so every spelling the format allows -- ``\\``,
        ``\"``, ``\/``, ``\uXXXX``, YAML's ``\xNN`` -- lands correctly
        without this code knowing any of them.

        Returns a list ``index`` where ``index[d]`` is the raw offset at which
        decoded character *d* begins (with a final entry for the end of the
        literal), or ``None`` when the literal cannot be mapped.

        Cost is O(n) decodes over a single literal.  It runs only for a value
        that is compound, escaped AND path-bearing, so it stays off every
        ordinary parse.
        """
        index = {}
        for raw_pos in range(len(raw_inner) + 1):
            try:
                decoded_prefix = decoder('"' + raw_inner[:raw_pos] + '"')
            except Exception:
                continue  # prefix ends mid-escape -- not a character boundary
            if not isinstance(decoded_prefix, str):
                return None
            index.setdefault(len(decoded_prefix), raw_pos)

        decoded_len = max(index) if index else -1
        if decoded_len < 0:
            return None
        # Every decoded offset must have a raw boundary; a gap means the
        # literal decoded in a way this walk cannot address, and a wrong span
        # is worse than no reference.
        if any(d not in index for d in range(decoded_len + 1)):
            return None
        return [index[d] for d in range(decoded_len + 1)]

    @staticmethod
    def _walk_structured_data(data) -> Generator[Tuple[str, str], None, None]:
        """Yield ``(value, yaml_path)`` for every string leaf in a nested dict/list structure.

        This captures the recursive tree-walk logic shared by YAML and JSON parsers.
        Non-string leaves (int, float, bool, None) are silently skipped.

        Items are yielded in insertion order (matching the original recursive traversal)
        to preserve the ``_search_start_line`` forward-scan optimisation used by both parsers.
        """
        stack = [(data, "")]
        while stack:
            node, path = stack.pop()
            if isinstance(node, dict):
                # Push in reverse so that the first key is popped (processed) first.
                for key, value in reversed(list(node.items())):
                    stack.append((value, f"{path}.{key}"))
            elif isinstance(node, list):
                for i in range(len(node) - 1, -1, -1):
                    stack.append((node[i], f"{path}[{i}]"))
            elif isinstance(node, str):
                yield node, path

    def _classify_path(self, text: str) -> Tuple[bool, bool]:
        """Classify *text* as a file path, directory path, or neither.

        Returns ``(is_file, is_dir)``.  At most one will be True.
        """
        if self._is_command_shaped(text):
            # PD-BUG-131 (b): a compound value carrying shell/command syntax is
            # a command, not a path.  Without this it fell through to
            # whole-string classification and the ENTIRE command string was
            # registered as the link target -- a reference that can never
            # resolve, so the real path inside it stayed silently untracked.
            return False, False

        is_file = self._looks_like_file_path(text)
        if is_file:
            return True, False
        _, ext = os.path.splitext(text)
        if not ext and self._looks_like_directory_path(text):
            return False, True
        return False, False

    #: Command SYNTAX, as opposed to characters that merely occur in filenames
    #: (PD-BUG-131, narrowed at code review).  Three signals, each of which a
    #: filename does not produce:
    #:   ``\w(``  a parenthesis bound directly to a word -- a call head such as
    #:            ``Bash(``.  A filename annotation is space-separated
    #:            (``img (1).png``), so it does not match.
    #:   ``[ ``   / `` ]``  a bracket used as a standalone test operator
    #:            (``[ -d path ]``).  A bracketed filename tag (``[draft].md``)
    #:            carries no space inside the brackets.
    _command_syntax_pattern = re.compile(r"\w\(|\[\s|\s\]")

    @classmethod
    def _is_command_shaped(cls, text: str) -> bool:
        """True when *text* reads as a command invocation rather than a path.

        Anchored on command syntax (see ``_command_syntax_pattern``).  The
        first cut keyed on "a space plus any of ``()[]``", which reads the
        same way to a filename: code review measured it dropping
        ``assets/img (1).png``, ``doc/report (final).pdf`` and
        ``doc/notes (draft)`` -- and a Windows ``(1)`` copy suffix is ordinary
        on this product's declared platform, so a silent drop there is the
        very class PD-BUG-130 exists to remove.

        The space requirement is kept as a cheap precondition: a value with no
        space is never a command line here, so an unusual filename like
        ``src/mod(x).py`` stays classified.

        Scoped to the structured parsers, whose values are the ones that reach
        whole-string classification carrying whole shell commands.  Note this
        guard is only REACHED when the command's inner path is not extractable
        (an unquoted directory); a quoted one is pulled out by
        ``_extract_embedded_paths``, which returns handled before
        classification runs.
        """
        return " " in text and bool(cls._command_syntax_pattern.search(text))
