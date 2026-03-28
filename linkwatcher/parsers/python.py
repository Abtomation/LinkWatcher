"""
Python file parser for extracting file references.

This parser handles Python files and extracts file references
from strings and comments, excluding standard library imports.
"""

import re
import sys
from typing import List

from ..models import LinkReference
from .base import BaseParser
from .patterns import QUOTED_PATH_PATTERN

# Authoritative stdlib module list on Python 3.10+; comprehensive fallback for 3.8/3.9.
try:
    _STDLIB_TOP_LEVEL_MODULES = sys.stdlib_module_names
except AttributeError:
    _STDLIB_TOP_LEVEL_MODULES = frozenset(
        {
            "abc",
            "aifc",
            "argparse",
            "array",
            "ast",
            "asynchat",
            "asyncio",
            "asyncore",
            "atexit",
            "audioop",
            "base64",
            "bdb",
            "binascii",
            "binhex",
            "bisect",
            "builtins",
            "bz2",
            "cProfile",
            "calendar",
            "cgi",
            "cgitb",
            "chunk",
            "cmath",
            "cmd",
            "code",
            "codecs",
            "codeop",
            "collections",
            "colorsys",
            "compileall",
            "concurrent",
            "configparser",
            "contextlib",
            "contextvars",
            "copy",
            "copyreg",
            "crypt",
            "csv",
            "ctypes",
            "curses",
            "dataclasses",
            "datetime",
            "dbm",
            "decimal",
            "difflib",
            "dis",
            "distutils",
            "doctest",
            "email",
            "encodings",
            "enum",
            "errno",
            "faulthandler",
            "fcntl",
            "filecmp",
            "fileinput",
            "fnmatch",
            "formatter",
            "fractions",
            "ftplib",
            "functools",
            "gc",
            "getopt",
            "getpass",
            "gettext",
            "glob",
            "grp",
            "gzip",
            "hashlib",
            "heapq",
            "hmac",
            "html",
            "http",
            "idlelib",
            "imaplib",
            "imghdr",
            "imp",
            "importlib",
            "inspect",
            "io",
            "ipaddress",
            "itertools",
            "json",
            "keyword",
            "lib2to3",
            "linecache",
            "locale",
            "logging",
            "lzma",
            "mailbox",
            "mailcap",
            "marshal",
            "math",
            "mimetypes",
            "mmap",
            "modulefinder",
            "multiprocessing",
            "netrc",
            "nis",
            "nntplib",
            "numbers",
            "operator",
            "optparse",
            "os",
            "ossaudiodev",
            "parser",
            "pathlib",
            "pdb",
            "pickle",
            "pickletools",
            "pipes",
            "pkgutil",
            "platform",
            "plistlib",
            "poplib",
            "posix",
            "posixpath",
            "pprint",
            "profile",
            "pstats",
            "pty",
            "pwd",
            "py_compile",
            "pyclbr",
            "pydoc",
            "queue",
            "quopri",
            "random",
            "re",
            "readline",
            "reprlib",
            "resource",
            "rlcompleter",
            "runpy",
            "sched",
            "secrets",
            "select",
            "selectors",
            "shelve",
            "shlex",
            "shutil",
            "signal",
            "site",
            "smtpd",
            "smtplib",
            "sndhdr",
            "socket",
            "socketserver",
            "spwd",
            "sqlite3",
            "sre_compile",
            "sre_constants",
            "sre_parse",
            "ssl",
            "stat",
            "statistics",
            "string",
            "stringprep",
            "struct",
            "subprocess",
            "sunau",
            "symtable",
            "sys",
            "sysconfig",
            "syslog",
            "tabnanny",
            "tarfile",
            "telnetlib",
            "tempfile",
            "termios",
            "test",
            "textwrap",
            "this",
            "threading",
            "time",
            "timeit",
            "tkinter",
            "token",
            "tokenize",
            "trace",
            "traceback",
            "tracemalloc",
            "tty",
            "turtle",
            "turtledemo",
            "types",
            "typing",
            "unicodedata",
            "unittest",
            "urllib",
            "uu",
            "uuid",
            "venv",
            "warnings",
            "wave",
            "weakref",
            "webbrowser",
            "winreg",
            "winsound",
            "wsgiref",
            "xdrlib",
            "xml",
            "xmlrpc",
            "zipapp",
            "zipfile",
            "zipimport",
            "zlib",
        }
    )

# Regex to extract the top-level module name from an import line.
_IMPORT_MODULE_RE = re.compile(r"^\s*(?:import|from)\s+(\w+)")


class PythonParser(BaseParser):
    """Parser for Python files (.py)."""

    def __init__(self):
        super().__init__()
        self.quoted_pattern = QUOTED_PATH_PATTERN

        # Pattern for file paths in comments (find all occurrences)
        self.comment_pattern = re.compile(r"([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)")

        # Pattern for local import statements (relative imports with dots/slashes)
        self.local_import_pattern = re.compile(r"^\s*(?:import|from)\s+([a-zA-Z0-9_./]+)")

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse Python content for file references."""
        try:
            lines = content.split("\n")
            references = []

            for line_num, line in enumerate(lines, 1):
                # Skip standard library imports but process local imports
                _m = _IMPORT_MODULE_RE.match(line)
                if _m and _m.group(1) in _STDLIB_TOP_LEVEL_MODULES:
                    continue

                # Look for quoted file paths
                for match in self.quoted_pattern.finditer(line):
                    potential_file = match.group(1)

                    if self._looks_like_file_path(potential_file):
                        references.append(
                            LinkReference(
                                file_path=file_path,
                                line_number=line_num,
                                column_start=match.start(1),
                                column_end=match.end(1),
                                link_text=potential_file,
                                link_target=potential_file,
                                link_type="python-quoted",
                            )
                        )

                # Look for local import statements
                import_match = self.local_import_pattern.match(line)
                if import_match:
                    import_path = import_match.group(1)
                    # Convert dot notation to file path
                    # e.g., src.utils.string_utils -> src/utils/string_utils
                    if "." in import_path and not import_path.startswith("."):
                        file_path_candidate = import_path.replace(".", "/")
                        if self._looks_like_local_import(file_path_candidate):
                            references.append(
                                LinkReference(
                                    file_path=file_path,
                                    line_number=line_num,
                                    column_start=import_match.start(1),
                                    column_end=import_match.end(1),
                                    link_text=import_path,
                                    link_target=file_path_candidate,
                                    link_type="python-import",
                                )
                            )

                # Look for file paths in comments (only in lines that contain #)
                if "#" in line:
                    comment_part = line[line.find("#") :]  # Get only the comment part
                    for match in self.comment_pattern.finditer(comment_part):
                        potential_file = match.group(1)

                        if self._looks_like_file_path(potential_file):
                            # Adjust column position to account for the comment offset
                            comment_start = line.find("#")
                            references.append(
                                LinkReference(
                                    file_path=file_path,
                                    line_number=line_num,
                                    column_start=comment_start + match.start(1),
                                    column_end=comment_start + match.end(1),
                                    link_text=potential_file,
                                    link_target=potential_file,
                                    link_type="python-comment",
                                )
                            )

            return references

        except Exception as e:
            self.logger.warning("parse_error", file_path=file_path, parser="python", error=str(e))
            return []

    def _looks_like_local_import(self, import_path: str) -> bool:
        """Check if an import path looks like a local module reference."""
        # Local imports typically start with project directories like src/, lib/, etc.
        # or contain multiple path segments
        if "/" in import_path and len(import_path.split("/")) >= 2:
            # Check if it looks like a local path (not a standard library)
            first_part = import_path.split("/")[0]
            # Common local directory names
            local_dirs = {"src", "lib", "app", "core", "utils", "helpers", "modules", "packages"}
            return first_part in local_dirs or len(import_path.split("/")) >= 3
        return False
