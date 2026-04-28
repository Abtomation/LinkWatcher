"""
File type specific parsers for the LinkWatcher system.

This package contains specialized parsers for different file types,
each implementing the base parser interface.

AI Context
----------
- **Entry point**: ``LinkParser`` (in ``parser.py``, not this package)
  is the facade that delegates to per-format parsers registered here.
  Each parser extends ``BaseParser`` and implements ``parse_content()``.
- **Adding a parser**: create a new module in this package, subclass
  ``BaseParser``, implement ``parse_content()`` returning a list of
  ``LinkReference``, add an import + ``__all__`` entry here, and
  register the extension mapping in ``LinkParser.__init__()`` (the
  ``self.parsers`` dict keyed by file extension).
- **Common tasks**:
  - Debugging missed links: check the specific parser's regex patterns
    in ``parse_content()`` — each parser uses format-specific regexes.
  - Understanding shared patterns: ``parsers/patterns.py`` defines
    reusable regex constants (e.g., quoted path patterns) used across
    multiple parsers.
  - Testing: each parser has a dedicated test file in
    ``test/automated/parsers/``.
"""

from .base import BaseParser
from .dart import DartParser
from .generic import GenericParser
from .json_parser import JsonParser
from .markdown import MarkdownParser
from .powershell import PowerShellParser
from .python import PythonParser
from .yaml_parser import YamlParser

__all__ = [
    "BaseParser",
    "MarkdownParser",
    "YamlParser",
    "JsonParser",
    "DartParser",
    "PythonParser",
    "PowerShellParser",
    "GenericParser",
]
