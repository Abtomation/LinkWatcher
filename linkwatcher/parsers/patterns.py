"""
Shared regex patterns for file reference parsing.

Pre-compiled patterns used by multiple parsers to detect quoted file paths
and directory paths. Centralised here to eliminate duplication (TD087).
"""

import re

# Matches quoted strings containing a file extension (e.g., 'foo.py', "bar.md").
# Used by: generic, markdown, python, powershell, dart parsers.
QUOTED_PATH_PATTERN = re.compile(r'[\'"]([^\'"]+\.[a-zA-Z0-9]+)[\'"]')

# Matches quoted strings containing at least one path separator (/ or \).
# No extension required — captures directory references.
# Used by: generic, markdown, python parsers.
QUOTED_DIR_PATTERN = re.compile(r'[\'"]([^\'"]*[/\\][^\'"]*)[\'"]')

# Stricter variant: requires at least one character after the last separator.
# Avoids matching paths that end with a bare separator.
# Used by: powershell parser.
QUOTED_DIR_PATTERN_STRICT = re.compile(r'[\'"]([^\'"]*[/\\][^\'"]+)[\'"]')
