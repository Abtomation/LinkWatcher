"""
Link updater for modifying files when links need to be updated.

This module handles the actual file modifications when links need to be
updated due to file moves or renames. Path resolution is delegated to
PathResolver (linkwatcher.path_resolver).
"""

import os
import re
import shutil
import tempfile
from enum import Enum
from pathlib import Path
from typing import Dict, List

from colorama import Fore

from .logging import get_logger
from .models import LinkReference
from .path_resolver import PathResolver


class UpdateResult(Enum):
    """Result of updating references in a single file."""

    UPDATED = "updated"
    STALE = "stale"
    NO_CHANGES = "no_changes"


class LinkUpdater:
    """
    Handles updating link references in files when targets change.
    Uses proper file handling to ensure atomic updates and backup safety.
    Delegates path resolution to PathResolver.
    """

    def __init__(self, project_root: str = "."):
        self.backup_enabled = True
        self.dry_run = False
        self.project_root = Path(project_root).resolve()
        self.logger = get_logger()
        self.path_resolver = PathResolver(project_root, self.logger)

    def update_references(
        self, references: List[LinkReference], old_path: str, new_path: str
    ) -> Dict:
        """
        Update all references from old_path to new_path.

        Returns:
            Dict with statistics: {'files_updated': int, 'references_updated': int, 'errors': int}
        """
        stats = {"files_updated": 0, "references_updated": 0, "errors": 0, "stale_files": []}

        # Group references by file for efficient processing
        files_to_update = self._group_references_by_file(references)

        for file_path, file_references in files_to_update.items():
            try:
                result = self._update_file_references(
                    file_path, file_references, old_path, new_path
                )
                if result == UpdateResult.UPDATED:
                    stats["files_updated"] += 1
                    stats["references_updated"] += len(file_references)
                    self.logger.links_updated(file_path, len(file_references))
                elif result == UpdateResult.STALE:
                    stats["stale_files"].append(file_path)
                    self.logger.warning(
                        "stale_references_detected",
                        file_path=file_path,
                        references_count=len(file_references),
                    )
                else:
                    self.logger.debug("no_changes_needed", file_path=file_path)
            except Exception as e:
                stats["errors"] += 1
                self.logger.error(
                    "file_update_failed",
                    file_path=file_path,
                    error=str(e),
                    error_type=type(e).__name__,
                )

        return stats

    def _group_references_by_file(
        self, references: List[LinkReference]
    ) -> Dict[str, List[LinkReference]]:
        """Group references by their containing file."""
        files = {}
        for ref in references:
            if ref.file_path not in files:
                files[ref.file_path] = []
            files[ref.file_path].append(ref)
        return files

    def _update_file_references(
        self, file_path: str, references: List[LinkReference], old_path: str, new_path: str
    ) -> UpdateResult:
        """
        Update references in a single file.

        Returns:
            UpdateResult.UPDATED if file was modified,
            UpdateResult.NO_CHANGES if no changes needed,
            UpdateResult.STALE if stale line numbers were detected (file NOT modified).
        """
        # Resolve relative path to absolute path
        if not os.path.isabs(file_path):
            abs_file_path = os.path.join(self.project_root, file_path)
        else:
            abs_file_path = file_path

        if self.dry_run:
            print(
                f"{Fore.CYAN}[DRY RUN] Would update {len(references)} references in {abs_file_path}"
            )
            return UpdateResult.UPDATED

        try:
            # Read the current file content
            with open(abs_file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()

            # Track if any changes were made
            changes_made = False

            # Sort references by line number (descending) and column (descending)
            # This ensures we update from bottom to top, preserving line/column positions
            sorted_refs = sorted(
                references, key=lambda r: (r.line_number, r.column_start), reverse=True
            )

            # Phase 1: Collect python-import module rename mappings
            python_module_renames = {}

            for ref in sorted_refs:
                line_idx = ref.line_number - 1  # Convert to 0-based index

                # Calculate the new target path (delegated to PathResolver)
                new_target = self._calculate_new_target(ref, old_path, new_path)

                if new_target == ref.link_target:
                    continue  # No change needed for this reference

                # Collect module rename mapping for Phase 2 (PD-BUG-045)
                if ref.link_type == "python-import" and ref.link_text:
                    new_module = new_target.replace("/", ".")
                    if ref.link_text != new_module:
                        python_module_renames[ref.link_text] = new_module

                # Stale detection: line index out of bounds
                if not (0 <= line_idx < len(lines)):
                    self.logger.warning(
                        "stale_line_number_detected",
                        file_path=file_path,
                        line_number=ref.line_number,
                        total_lines=len(lines),
                        link_target=ref.link_target,
                    )
                    return UpdateResult.STALE

                line = lines[line_idx]

                # Stale detection: expected target not found on this line
                if ref.link_target not in line:
                    # For Python imports, link_target uses slash notation
                    # (e.g. "src/utils/file_utils") but the line has dot
                    # notation ("src.utils.file_utils").  Check link_text too.
                    if ref.link_type == "python-import" and ref.link_text and ref.link_text in line:
                        pass  # Not stale — found via dot-notation link_text
                    elif new_target in line or (
                        ref.link_type == "python-import" and new_target.replace("/", ".") in line
                    ):
                        continue  # Already handled by an earlier replacement
                    else:
                        self.logger.warning(
                            "stale_line_content_detected",
                            file_path=file_path,
                            line_number=ref.line_number,
                            expected_target=ref.link_target,
                        )
                        return UpdateResult.STALE

                updated_line = self._replace_in_line(line, ref, new_target)
                if updated_line != line:
                    lines[line_idx] = updated_line
                    changes_made = True

            # Phase 2 (PD-BUG-045): File-wide module usage replacement.
            # When a Python import is updated (e.g., "import utils.helpers" →
            # "import core.helpers"), usage sites on other lines
            # (e.g., "utils.helpers.func()") must also be updated.
            if python_module_renames:
                content = "".join(lines)
                for old_module, new_module in python_module_renames.items():
                    # Use word-boundary regex to avoid false positives on
                    # substrings (e.g., "my_utils.helpers" should not match).
                    pattern = r"\b" + re.escape(old_module) + r"\b"
                    content = re.sub(pattern, new_module, content)
                new_lines = content.splitlines(True)
                if new_lines != lines:
                    lines = new_lines
                    changes_made = True

            # Write the updated content if changes were made
            if changes_made:
                self._write_file_safely(abs_file_path, "".join(lines))
                return UpdateResult.UPDATED

            return UpdateResult.NO_CHANGES

        except Exception as e:
            raise Exception(f"Failed to update file {abs_file_path}: {e}")

    def _calculate_new_target(self, ref: LinkReference, old_path: str, new_path: str) -> str:
        """Calculate the new target path for a reference.

        Delegates to PathResolver.calculate_new_target().
        """
        return self.path_resolver.calculate_new_target(ref, old_path, new_path)

    def _replace_in_line(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace the target in a line based on the reference information."""
        # Handle different link types appropriately
        if ref.link_type == "markdown":
            # For markdown links [text](target), replace just the target part
            return self._replace_markdown_target(line, ref, new_target)
        elif ref.link_type == "markdown-reference":
            # For reference links [label]: target "title", replace just the target part
            return self._replace_reference_target(line, ref, new_target)
        else:
            # For other types, use position-based replacement for precision
            return self._replace_at_position(line, ref, new_target)

    def _replace_markdown_target(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target in markdown link format, handling titles properly.

        When the link text exactly matches the old target, the text is also
        updated to the new target (PD-BUG-012).
        """
        # Escape special regex characters in the original target
        escaped_target = re.escape(ref.link_target)

        # Pattern to match [text](target optional_title) where target is our specific target
        # Text is captured separately so we can update it when it matches the old target
        # This handles titles in formats: "title", 'title', (title)
        pattern = rf"(\[)([^\]]*)(\]\()({escaped_target})(\s+[\"'(][^\"')]*[\"')])?(\))"

        def replace_func(match):
            # Group 1: [
            # Group 2: link text
            # Group 3: ](
            # Group 4: target (the file path we want to replace)
            # Group 5: optional title (including the space and quotes/parens)
            # Group 6: closing )
            link_text = match.group(2)
            title_part = match.group(5) if match.group(5) else ""
            # Update link text when it exactly matches the old target
            if link_text == ref.link_target:
                link_text = new_target
            return f"{match.group(1)}{link_text}{match.group(3)}{new_target}{title_part}{match.group(6)}"

        return re.sub(pattern, replace_func, line)

    def _replace_reference_target(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target in reference link format [label]: target "title"."""
        # Escape special regex characters in the original target
        escaped_target = re.escape(ref.link_target)

        # Pattern to match [label]: target optional_title
        # This handles titles in formats: "title", 'title', (title)
        pattern = rf"(\[[^\]]*\]:\s*)({escaped_target})(\s+[\"'(][^\"')]*[\"')])?(\s*$)"

        def replace_func(match):
            # Group 1: [label]:
            # Group 2: target (the file path we want to replace)
            # Group 3: optional title (including the space and quotes/parens)
            # Group 4: end of line
            title_part = match.group(3) if match.group(3) else ""
            end_part = match.group(4) if match.group(4) else ""
            return f"{match.group(1)}{new_target}{title_part}{end_part}"

        return re.sub(pattern, replace_func, line)

    def _replace_at_position(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target at specific position in line."""
        # Special handling for Python imports - replace the text, not the target
        if ref.link_type == "python-import":
            # For Python imports, we need to replace the dot notation in the line
            # Convert new_target (slash notation) back to dot notation
            new_import_text = new_target.replace("/", ".")
            return line.replace(ref.link_text, new_import_text)

        # Use column positions to replace only the specific occurrence
        start_col = ref.column_start
        end_col = ref.column_end

        # Validate positions
        if start_col < 0 or end_col > len(line) or start_col >= end_col:
            # Fall back to simple replacement if positions are invalid
            return line.replace(ref.link_target, new_target)

        # Extract the text at the specified position
        text_at_position = line[start_col:end_col]

        # For quoted references, the text might include quotes
        if (
            ref.link_type in ["markdown-quoted", "quoted", "python-quoted", "html-anchor"]
            and text_at_position.startswith('"')
            and text_at_position.endswith('"')
        ):
            # Replace just the content inside quotes
            return line[:start_col] + f'"{new_target}"' + line[end_col:]
        elif (
            ref.link_type in ["markdown-quoted", "quoted", "python-quoted", "html-anchor"]
            and text_at_position.startswith("'")
            and text_at_position.endswith("'")
        ):
            # Replace just the content inside single quotes
            return line[:start_col] + f"'{new_target}'" + line[end_col:]
        else:
            # Direct replacement at position
            return line[:start_col] + new_target + line[end_col:]

    def _write_file_safely(self, file_path: str, content: str):
        """Write file content safely with backup and atomic operation."""
        # Create backup if enabled
        if self.backup_enabled:
            backup_path = f"{file_path}.linkwatcher.bak"
            try:
                shutil.copy2(file_path, backup_path)
            except Exception as e:
                self.logger.warning(
                    "backup_creation_failed",
                    file_path=file_path,
                    error=str(e),
                    error_type=type(e).__name__,
                )

        # Write to temporary file first, then move (atomic operation)
        temp_path = None
        try:
            # Create temporary file in the same directory
            dir_path = os.path.dirname(file_path)
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", dir=dir_path, delete=False
            ) as temp_file:
                temp_path = temp_file.name
                temp_file.write(content)

            # Atomic move
            shutil.move(temp_path, file_path)

        except Exception as e:
            # Clean up temp file if it exists
            if temp_path and os.path.exists(temp_path):
                try:
                    os.unlink(temp_path)
                except Exception:
                    pass
            raise e

    def set_dry_run(self, enabled: bool):
        """Enable or disable dry run mode."""
        self.dry_run = enabled

    def set_backup_enabled(self, enabled: bool):
        """Enable or disable backup creation."""
        self.backup_enabled = enabled
