"""
Utility functions for the LinkWatcher system.

This module contains common utility functions used across the system.
"""

import os
import re
from pathlib import Path
from typing import Set


def should_monitor_file(
    file_path: str, monitored_extensions: Set[str], ignored_dirs: Set[str]
) -> bool:
    """
    Check if a file should be monitored based on extension and directory.

    Args:
        file_path: Path to the file
        monitored_extensions: Set of file extensions to monitor (e.g., {'.md', '.py'})
        ignored_dirs: Set of directory names to ignore (e.g., {'.git', 'node_modules'})

    Returns:
        True if file should be monitored, False otherwise
    """
    # Check file extension
    file_ext = os.path.splitext(file_path)[1].lower()
    if file_ext not in monitored_extensions:
        return False

    # Check if file is in an ignored directory
    path_parts = Path(file_path).parts
    for part in path_parts:
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

    # Must have a file extension
    if "." not in text:
        return False

    # Check for common file extensions
    common_extensions = {
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
    if ext in common_extensions:
        return True

    # Check for path-like characteristics
    if "/" in text or "\\" in text:
        return True

    # Check for relative path indicators
    if text.startswith("./") or text.startswith("../"):
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
