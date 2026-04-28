"""
Utility functions for the LinkWatcher system.

This module contains common utility functions used across the system.

AI Context
----------
- **Role**: Stateless pure-function library for path manipulation and
  file-classification heuristics.  No classes, no instance state — every
  function is a free function importable by any module.
- **High-traffic functions and primary callers**:
  - ``normalize_path()`` — canonical forward-slash form.
    Called by database.py, handler.py, path_resolver.py, service.py,
    validator.py, dir_move_detector.py.
  - ``should_monitor_file()`` — extension + ignored-dir filter.
    Called by handler.py, service.py, validator.py.
  - ``get_relative_path()`` — absolute-to-project-relative conversion.
    Called by database.py, handler.py, service.py, reference_lookup.py.
  - ``looks_like_file_path()`` / ``looks_like_directory_path()`` —
    heuristic classifiers for parser-extracted text.
    Called by parsers/base.py (``BaseParser``).
  - ``safe_file_read()`` — multi-encoding file reader with fallback.
    Called by database.py, reference_lookup.py, validator.py.
  - ``should_ignore_directory()`` — basename-level dir filter.
    Called by handler.py, service.py.
  - ``find_line_number()`` — linear search for text in line list.
    Called by validator.py.
- **Common tasks**:
  - Adding a new utility: add a free function here, import where needed.
    No registration or wiring required.
  - Debugging false-positive file detection: check
    ``looks_like_file_path()`` heuristics — URL prefixes, prose
    rejection (PD-BUG-028), and ``_COMMON_EXTENSIONS`` set.
  - Debugging path mismatches: check ``normalize_path()`` — handles
    Windows long-path prefix stripping (PD-BUG-014) and
    forward-slash normalization.
- **Testing**: ``test/automated/unit/test_utils.py`` (not on disk —
  noted in 0.1.1 state file as missing).
"""

import os
import re
from pathlib import Path
from typing import Optional, Set


def should_monitor_file(
    file_path: str,
    monitored_extensions: Set[str],
    ignored_dirs: Set[str],
    project_root: Optional[str] = None,
) -> bool:
    """
    Check if a file should be monitored based on extension and directory.

    Args:
        file_path: Path to the file
        monitored_extensions: Set of file extensions to monitor (e.g., {'.md', '.py'})
        ignored_dirs: Set of directory names to ignore (e.g., {'.git', 'node_modules'})
        project_root: If provided, only check path parts relative to this root.
            This prevents false rejections when the project lives under a
            directory whose name matches an ignored dir (PD-BUG-087).

    Returns:
        True if file should be monitored, False otherwise
    """
    # Check file extension
    file_ext = os.path.splitext(file_path)[1].lower()
    if file_ext not in monitored_extensions:
        return False

    # Check if file is in an ignored directory.
    # When project_root is provided, only check the portion of the path
    # below the project root — ancestor directories are irrelevant.
    if project_root:
        try:
            rel_parts = Path(file_path).relative_to(project_root).parts
        except ValueError:
            # file_path is not under project_root; fall back to full path
            rel_parts = Path(file_path).parts
    else:
        rel_parts = Path(file_path).parts

    for part in rel_parts:
        if part in ignored_dirs:
            return False

    return True


def should_ignore_directory(dir_path: str, ignored_dirs: Set[str]) -> bool:
    """
    Check if a directory should be ignored.

    Args:
        dir_path: Path to the directory
        ignored_dirs: Set of directory names to ignore

    Returns:
        True if directory should be ignored, False otherwise
    """
    dir_name = os.path.basename(dir_path)
    return dir_name in ignored_dirs


def normalize_path(path: str) -> str:
    """
    Normalize a path for consistent comparisons.

    Args:
        path: Path to normalize

    Returns:
        Normalized path with forward slashes
    """
    # Strip Windows long path prefix (\\?\ or //?/) before normalization
    # PD-BUG-014: Windows adds this prefix for paths >260 characters
    if path.startswith("\\\\?\\"):
        path = path[4:]
    elif path.startswith("//?/"):
        path = path[4:]
    # Remove leading slash and normalize
    path = path.lstrip("/")
    return os.path.normpath(path).replace("\\", "/")


def get_relative_path(abs_path: str, project_root: str) -> str:
    """
    Convert absolute path to relative path from project root.

    Args:
        abs_path: Absolute path to convert
        project_root: Project root directory

    Returns:
        Relative path from project root
    """
    try:
        abs_path_obj = Path(abs_path).resolve()
        project_root_obj = Path(project_root).resolve()
        return str(abs_path_obj.relative_to(project_root_obj)).replace("\\", "/")
    except ValueError:
        # Path is outside project root
        return abs_path.replace("\\", "/")


_COMMON_EXTENSIONS = frozenset(
    {
        ".md",
        ".txt",
        ".py",
        ".js",
        ".html",
        ".css",
        ".json",
        ".yaml",
        ".yml",
        ".dart",
        ".java",
        ".cpp",
        ".c",
        ".h",
        ".xml",
        ".csv",
        ".pdf",
        ".doc",
        ".docx",
        ".xls",
        ".xlsx",
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".svg",
        ".sql",
        ".log",
        ".conf",
        ".config",
        ".ini",
        ".properties",
        ".env",
        ".sh",
        ".bat",
        ".ps1",
    }
)


def looks_like_regex_or_glob(text: str) -> bool:
    """Detect strings that contain glob or regex meta-characters.

    PD-BUG-095: regex patterns (``\\d``, ``\\s``, ``\\w``, ``\\.``, character
    classes, anchors, alternation) and glob patterns (``*``, ``**``) were being
    classified as file paths by ``looks_like_file_path`` / ``looks_like_directory_path``,
    entered the link database, and got rewritten on directory moves — corrupting
    source files (e.g. ``'doc/foo/bar-\\d+'`` → ``'doc/bar/bar-/d+'``,
    ``'*.md'`` → ``'../*.md'``). This detector lets the path classifiers reject
    such strings before they enter the database.

    Conservatism: only flag clear regex/glob signals to avoid false-positives
    on real paths. Windows path safety: ``\\b`` and ``\\B`` are deliberately
    NOT flagged so that Windows directory names starting with 'b' (e.g.
    ``\\backups\\file.txt``) are not misclassified.

    Args:
        text: Text to check

    Returns:
        True if text contains regex or glob meta-characters, False otherwise.
    """
    if not text:
        return False
    # Glob: ``*`` and ``?`` wildcards — both invalid in Windows/POSIX filenames,
    # so any occurrence is a strong glob signal. URL callers strip URLs first.
    if "*" in text or "?" in text:
        return True
    # Pipe / alternation — not valid in Windows or POSIX filenames
    if "|" in text:
        return True
    # Negated character class start
    if "[^" in text:
        return True
    # Character class with content (e.g. ``[a-z]``, ``[0-9]``, ``[abc]``)
    if re.search(r"\[[\w\-]+\]", text):
        return True
    # Regex escape sequences ``\d \s \w`` (and uppercase) — only when followed by
    # a quantifier or at end of string. Without this constraint, Windows-style
    # paths like ``doc\setup-guide.md`` (``\setup`` starts with ``\s``) would be
    # falsely flagged as regex.
    if re.search(r"\\[dswDSW](?:[+*?{]|$)", text):
        return True
    # Escaped regex metacharacters (``\.`` ``\[`` ``\]`` ``\(`` ``\)`` ``\{`` ``\}`` ``\+`` ``\*`` ``\?`` ``\^`` ``\$``)
    if re.search(r"\\[\.\[\]\(\)\{\}\+\*\?\^\$]", text):
        return True
    # Line anchors: ``^`` at start or ``$`` at end of string
    if text.startswith("^") or text.endswith("$"):
        return True
    return False


def looks_like_file_path(text: str) -> bool:
    """
    Check if a string looks like a file path.

    Args:
        text: Text to check

    Returns:
        True if text looks like a file path, False otherwise
    """
    # Basic heuristics for file paths
    if not text or len(text) < 3:
        return False

    # Skip URLs
    if text.startswith(("http://", "https://", "ftp://", "mailto:", "tel:", "data:")):
        return False

    # PD-BUG-095: Reject glob/regex strings before the extension/separator heuristics —
    # they otherwise pass (e.g. ``*.md`` has a known extension, ``doc/foo/bar-\\d+``
    # has '/' separators) and get rewritten on directory moves, corrupting source files.
    if looks_like_regex_or_glob(text):
        return False

    # Must have a file extension
    if "." not in text:
        return False

    # PD-BUG-028: Reject prose-like strings with embedded filenames.
    # If a path segment starts with an uppercase word and has 3+ space-separated
    # words, it's likely a sentence (e.g., "Hello from move-target-2.ps1") rather
    # than a real file path. Filenames with spaces ("file with spaces.txt") almost
    # never start with an uppercase word.
    segments = re.split(r"[/\\]", text)
    for segment in segments:
        if segment in (".", "..", ""):
            continue
        words = segment.split()
        if len(words) >= 3 and words[0][:1].isupper():
            return False

    ext = os.path.splitext(text)[1].lower()
    if ext in _COMMON_EXTENSIONS:
        return True

    # Check for path-like characteristics
    if "/" in text or "\\" in text:
        return True

    # Check for relative path indicators
    if text.startswith("./") or text.startswith("../../.."):
        return True

    return False


def looks_like_directory_path(text: str) -> bool:
    """
    Check if a string looks like a directory path (no file extension required).

    PD-BUG-021: Separated from looks_like_file_path() to allow directory path
    detection without requiring a file extension.

    Args:
        text: Text to check

    Returns:
        True if text looks like a directory path, False otherwise
    """
    if not text or len(text) < 3:
        return False

    # Skip URLs
    if text.startswith(("http://", "https://", "ftp://", "mailto:", "tel:", "data:")):
        return False

    # PD-BUG-095: Reject glob/regex strings before the separator heuristic —
    # patterns like ``doc/foo/bar-\\d+`` have '/' but are regex, not paths.
    if looks_like_regex_or_glob(text):
        return False

    # Must have at least one path separator
    if "/" not in text and "\\" not in text:
        return False

    # Skip paths that look like URLs (contain ://)
    if "://" in text:
        return False

    # Skip if it contains suspicious characters
    if any(char in text for char in ["@", "?", "&", "=", "%", ":", "*", "<", ">", "|"]):
        return False

    # Too long is suspicious
    if len(text) > 300:
        return False

    return True


def find_line_number(lines: list, search_text: str) -> int:
    """
    Find the line number containing specific text.

    Args:
        lines: List of lines to search
        search_text: Text to find

    Returns:
        Line number (1-based) or 0 if not found
    """
    for i, line in enumerate(lines, 1):
        if search_text in line:
            return i
    return 0


def safe_file_read(file_path: str, encoding: str = "utf-8") -> str:
    """
    Safely read a file with fallback encodings.

    Args:
        file_path: Path to file to read
        encoding: Primary encoding to try

    Returns:
        File content as string

    Raises:
        IOError if file cannot be read with any encoding
    """
    encodings = [encoding, "utf-8", "latin-1", "cp1252"]

    for enc in encodings:
        try:
            with open(file_path, "r", encoding=enc) as f:
                return f.read()
        except UnicodeDecodeError:
            continue
        except Exception as e:
            raise IOError(f"Could not read file {file_path}: {e}")

    raise IOError(f"Could not decode file {file_path} with any encoding")


def is_file_size_within_limit(file_path: str, max_size_mb: int) -> bool:
    """
    Check whether a file's size is within the configured megabyte limit.

    Args:
        file_path: Path to the file to check.
        max_size_mb: Maximum file size in MB. Values <= 0 disable the check.

    Returns:
        True if the file is within the limit (or the check is disabled, or the
        file cannot be stat'd — leaving missing/inaccessible files for
        downstream code to handle); False if the file exceeds the limit.
    """
    if max_size_mb <= 0:
        return True
    try:
        size_bytes = os.path.getsize(file_path)
    except OSError:
        return True
    return size_bytes <= max_size_mb * 1024 * 1024
