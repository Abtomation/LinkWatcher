"""Canonical link type identifiers used across all parsers, updater, and validator.

Every link type string in the codebase should reference a member of ``LinkType``
rather than using a bare string literal.  ``LinkType`` inherits from ``str`` so
members compare equal to their string values — e.g. ``LinkType.MARKDOWN == "markdown"``
is ``True`` — making migration backward-compatible.
"""

from enum import Enum


class LinkType(str, Enum):
    """Enumeration of all link type identifiers produced by LinkWatcher parsers."""

    # --- Markdown family ---
    MARKDOWN = "markdown"
    MARKDOWN_REFERENCE = "markdown-reference"
    MARKDOWN_QUOTED = "markdown-quoted"
    MARKDOWN_QUOTED_DIR = "markdown-quoted-dir"
    MARKDOWN_STANDALONE = "markdown-standalone"
    MARKDOWN_BACKTICK = "markdown-backtick"
    MARKDOWN_BACKTICK_DIR = "markdown-backtick-dir"
    MARKDOWN_BARE_PATH = "markdown-bare-path"
    MARKDOWN_AT_PREFIX = "markdown-at-prefix"
    HTML_ANCHOR = "html-anchor"

    # --- Python family ---
    PYTHON_DOCSTRING = "python-docstring"
    PYTHON_DOCSTRING_DIR = "python-docstring-dir"
    PYTHON_QUOTED = "python-quoted"
    PYTHON_QUOTED_DIR = "python-quoted-dir"
    PYTHON_IMPORT = "python-import"
    PYTHON_COMMENT = "python-comment"

    # --- YAML family ---
    YAML = "yaml"
    YAML_DIR = "yaml-dir"

    # --- JSON family ---
    JSON = "json"
    JSON_DIR = "json-dir"

    # --- Dart family ---
    DART_IMPORT = "dart-import"
    DART_PART = "dart-part"
    DART_QUOTED = "dart-quoted"
    DART_STANDALONE = "dart-standalone"
    DART_EMBEDDED = "dart-embedded"

    # --- PowerShell family ---
    POWERSHELL_QUOTED = "powershell-quoted"
    POWERSHELL_QUOTED_DIR = "powershell-quoted-dir"
    POWERSHELL_EMBEDDED_MD_LINK = "powershell-embedded-md-link"
    POWERSHELL_HERE_STRING = "powershell-here-string"
    POWERSHELL_HERE_STRING_DIR = "powershell-here-string-dir"
    POWERSHELL_BLOCK_COMMENT = "powershell-block-comment"
    POWERSHELL_BLOCK_COMMENT_DIR = "powershell-block-comment-dir"
    POWERSHELL_COMMENT = "powershell-comment"
    POWERSHELL_COMMENT_DIR = "powershell-comment-dir"

    # --- Generic family ---
    GENERIC_QUOTED = "generic-quoted"
    GENERIC_QUOTED_DIR = "generic-quoted-dir"
    GENERIC_UNQUOTED = "generic-unquoted"

    # --- Legacy / catch-all ---
    QUOTED = "quoted"
