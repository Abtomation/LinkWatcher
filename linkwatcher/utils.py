"""
Utility functions for the LinkWatcher system.

This module contains common utility functions used across the system.
"""

import os
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
        Exception if file cannot be read with any encoding
    """
    encodings = [encoding, "utf-8", "latin-1", "cp1252"]

    for enc in encodings:
        try:
            with open(file_path, "r", encoding=enc) as f:
                return f.read()
        except UnicodeDecodeError:
            continue
        except Exception as e:
            raise Exception(f"Could not read file {file_path}: {e}")

    raise Exception(f"Could not decode file {file_path} with any encoding")
