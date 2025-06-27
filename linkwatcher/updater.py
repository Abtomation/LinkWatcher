"""
Link updater for modifying files when links need to be updated.

This module handles the actual file modifications when links need to be
updated due to file moves or renames.
"""

import os
import shutil
import tempfile
from pathlib import Path
from typing import Dict, List, Set

from colorama import Fore, Style

from .models import LinkReference


class LinkUpdater:
    """
    Handles updating link references in files when targets change.
    Uses proper file handling to ensure atomic updates and backup safety.
    """

    def __init__(self, project_root: str = "."):
        self.backup_enabled = True
        self.dry_run = False
        self.project_root = Path(project_root).resolve()

    def update_references(
        self, references: List[LinkReference], old_path: str, new_path: str
    ) -> Dict[str, int]:
        """
        Update all references from old_path to new_path.

        Returns:
            Dict with statistics: {'files_updated': int, 'references_updated': int, 'errors': int}
        """
        stats = {"files_updated": 0, "references_updated": 0, "errors": 0}

        # Group references by file for efficient processing
        files_to_update = self._group_references_by_file(references)

        for file_path, file_references in files_to_update.items():
            try:
                if self._update_file_references(file_path, file_references, old_path, new_path):
                    stats["files_updated"] += 1
                    stats["references_updated"] += len(file_references)
                    print(
                        f"{Fore.GREEN}✓ Updated {len(file_references)} reference(s) in {file_path}"
                    )
                else:
                    print(f"{Fore.YELLOW}⚠ No changes needed in {file_path}")
            except Exception as e:
                stats["errors"] += 1
                print(f"{Fore.RED}✗ Error updating {file_path}: {e}")

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
    ) -> bool:
        """
        Update references in a single file.

        Returns:
            True if file was modified, False if no changes were needed
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
            return True

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

            for ref in sorted_refs:
                line_idx = ref.line_number - 1  # Convert to 0-based index

                if 0 <= line_idx < len(lines):
                    line = lines[line_idx]

                    # Calculate the new target path
                    new_target = self._calculate_new_target(ref, old_path, new_path)

                    # Update the line if the target changed
                    if new_target != ref.link_target:
                        updated_line = self._replace_in_line(line, ref, new_target)
                        if updated_line != line:
                            lines[line_idx] = updated_line
                            changes_made = True

            # Write the updated content if changes were made
            if changes_made:
                self._write_file_safely(abs_file_path, "".join(lines))
                return True

            return False

        except Exception as e:
            raise Exception(f"Failed to update file {abs_file_path}: {e}")

    def _calculate_new_target(self, ref: LinkReference, old_path: str, new_path: str) -> str:
        """Calculate the new target path for a reference."""
        original_target = ref.link_target

        # Special handling for Python imports
        if ref.link_type == "python-import":
            return self._calculate_new_python_import(original_target, old_path, new_path)

        # Handle anchors
        if "#" in original_target:
            target_part, anchor = original_target.split("#", 1)
            updated_target = self._calculate_new_target_relative(
                target_part, old_path, new_path, ref.file_path
            )
            return f"{updated_target}#{anchor}"
        else:
            return self._calculate_new_target_relative(
                original_target, old_path, new_path, ref.file_path
            )

    def _calculate_new_target_relative(
        self, original_target: str, old_path: str, new_path: str, source_file: str
    ) -> str:
        """
        Calculate the new target path using the proposed approach:
        1. Analyze the original link type and characteristics
        2. Convert to absolute path for unambiguous comparison
        3. If it matches the moved file, convert back to original link style with new location
        """
        try:
            # Step 1: Analyze the original link type
            link_info = self._analyze_link_type(original_target, source_file)
            
            # Step 2: Convert original target to absolute path for comparison
            absolute_target = self._resolve_to_absolute_path(original_target, source_file, link_info)
            
            # Normalize paths for comparison (use forward slashes)
            absolute_target_norm = absolute_target.replace("\\", "/")
            old_path_norm = old_path.replace("\\", "/")
            new_path_norm = new_path.replace("\\", "/")
            
            # Step 3: Check if this link refers to the moved file
            if absolute_target_norm == old_path_norm:
                # Step 4: Convert new absolute path back to original link style
                return self._convert_to_original_link_type(new_path_norm, source_file, link_info)
            
            # No match found, return original
            return original_target
            
        except Exception as e:
            # If the new approach fails, fall back to original target
            print(f"DEBUG: Link resolution failed for '{original_target}': {e}")
            return original_target

    def _analyze_link_type(self, target: str, source_file: str) -> dict:
        """
        Analyze the link to determine its type and characteristics.
        Returns a dict with link metadata for later reconstruction.
        """
        info = {
            'original_target': target,
            'separator_style': '\\' if '\\' in target else '/',
            'is_absolute': False,
            'is_relative_explicit': False,
            'is_filename_only': False,
        }
        
        target_norm = target.replace('\\', '/')
        
        # Check if it's an absolute path (starts with / or drive letter)
        if target_norm.startswith('/') or (len(target_norm) > 1 and target_norm[1] == ':'):
            info['is_absolute'] = True
        # Check if it's explicitly relative (starts with ./ or ../)
        elif target_norm.startswith('./') or target_norm.startswith('../'):
            info['is_relative_explicit'] = True
        # Check if it's just a filename (no path separators)
        elif '/' not in target_norm:
            info['is_filename_only'] = True
        
        return info

    def _resolve_to_absolute_path(self, target: str, source_file: str, link_info: dict) -> str:
        """
        Convert a link target to an absolute path for comparison.
        """
        from pathlib import Path
        
        target_norm = target.replace('\\', '/')
        source_norm = source_file.replace('\\', '/')
        
        # If already absolute, return as-is
        if link_info['is_absolute']:
            return target_norm
        
        # Get the directory containing the source file
        source_dir = os.path.dirname(source_norm)
        
        # Handle different relative path types
        if link_info['is_filename_only']:
            # Filename only - assume it's in the same directory as source
            if source_dir:
                return f"{source_dir}/{target_norm}"
            else:
                return target_norm
        else:
            # Relative path - resolve relative to source directory
            if source_dir:
                # Use pathlib for proper relative path resolution
                source_path = Path(source_dir)
                target_path = source_path / target_norm
                return str(target_path).replace('\\', '/')
            else:
                return target_norm

    def _convert_to_original_link_type(self, new_absolute_path: str, source_file: str, link_info: dict) -> str:
        """
        Convert an absolute path back to the original link style.
        """
        from pathlib import Path
        
        new_path_norm = new_absolute_path.replace('\\', '/')
        source_norm = source_file.replace('\\', '/')
        source_dir = os.path.dirname(source_norm)
        
        # If original was absolute, return absolute
        if link_info['is_absolute']:
            result = new_path_norm
        # If original was filename-only, check if we can keep it that way
        elif link_info['is_filename_only']:
            new_filename = os.path.basename(new_path_norm)
            new_dir = os.path.dirname(new_path_norm)
            
            # If new file is in same directory as source, keep filename-only
            if new_dir == source_dir:
                result = new_filename
            else:
                # Need to use relative path
                result = self._calculate_relative_path_between_files(source_file, new_path_norm)
        else:
            # Original was relative - calculate new relative path
            result = self._calculate_relative_path_between_files(source_file, new_path_norm)
        
        # Apply original separator style
        if link_info['separator_style'] == '\\':
            result = result.replace('/', '\\')
        
        return result

    def _calculate_relative_path_between_files(self, source_file: str, target_file: str) -> str:
        """Calculate the relative path from source_file to target_file."""
        from pathlib import Path
        
        # Normalize paths
        source_normalized = source_file.replace("\\", "/")
        target_normalized = target_file.replace("\\", "/")
        
        # Get directory of source file
        source_dir = os.path.dirname(source_normalized)
        
        # If source is in root directory, target path is just the target
        if not source_dir:
            return target_normalized
            
        # Calculate relative path using pathlib
        try:
            source_path = Path(source_dir)
            target_path = Path(target_normalized)
            relative_path = os.path.relpath(str(target_path), str(source_path))
            # Normalize path separators to forward slashes
            return relative_path.replace("\\", "/")
        except ValueError:
            # If relative path calculation fails, return absolute path
            return target_normalized

    def _replace_path_part(self, target: str, old_path: str, new_path: str) -> str:
        """Replace the path part while preserving relative/absolute format."""
        old_normalized = self._normalize_path(old_path)
        target_normalized = self._normalize_path(target)

        if target_normalized == old_normalized:
            # Exact match - preserve the original format (relative vs absolute)
            return f"/{new_path}" if target.startswith("/") else new_path
        elif target_normalized.endswith(old_normalized):
            # Partial match - replace the ending part
            prefix_len = len(target_normalized) - len(old_normalized)
            prefix = target[:prefix_len] if prefix_len > 0 else ""
            return f"{prefix}{new_path}"

        return target  # No match, return original

    def _normalize_path(self, path: str) -> str:
        """Normalize a path for consistent comparisons."""
        path = path.lstrip("/")
        return os.path.normpath(path).replace("\\", "/")

    def _replace_in_line(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace the target in a line based on the reference information."""
        # Handle different link types appropriately
        if ref.link_type == "markdown":
            # For markdown links [text](target), replace just the target part
            return self._replace_markdown_target(line, ref, new_target)
        else:
            # For other types, use position-based replacement for precision
            return self._replace_at_position(line, ref, new_target)

    def _replace_markdown_target(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target in markdown link format."""
        # Find the pattern [text](target) and replace just the target
        import re

        # Escape special regex characters in the original target
        escaped_target = re.escape(ref.link_target)

        # Pattern to match [text](target) where target is our specific target
        pattern = rf"(\[[^\]]*\]\()({escaped_target})(\))"

        def replace_func(match):
            return f"{match.group(1)}{new_target}{match.group(3)}"

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
        if ref.link_type in ["markdown-quoted", "quoted"] and text_at_position.startswith('"') and text_at_position.endswith('"'):
            # Replace just the content inside quotes
            return line[:start_col] + f'"{new_target}"' + line[end_col:]
        elif ref.link_type in ["markdown-quoted", "quoted"] and text_at_position.startswith("'") and text_at_position.endswith("'"):
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
                print(f"{Fore.YELLOW}Warning: Could not create backup for {file_path}: {e}")

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
                except:
                    pass
            raise e

    def set_dry_run(self, enabled: bool):
        """Enable or disable dry run mode."""
        self.dry_run = enabled

    def set_backup_enabled(self, enabled: bool):
        """Enable or disable backup creation."""
        self.backup_enabled = enabled

    def _calculate_new_python_import(self, original_target: str, old_path: str, new_path: str) -> str:
        """Calculate new target for Python import statements."""
        # For Python imports, original_target is already in slash notation (link_target)
        # We need to compare it directly with the old_path
        
        # Normalize all paths for comparison
        target_normalized = original_target.replace("\\", "/")
        old_normalized = old_path.replace("\\", "/")
        new_normalized = new_path.replace("\\", "/")
        
        # Check if the import path matches the old path
        if target_normalized == old_normalized:
            # Exact match - replace entirely and convert to dot notation for return
            return new_normalized.replace("/", ".")
        elif target_normalized.startswith(old_normalized + "/"):
            # Partial match - replace the prefix
            suffix = target_normalized[len(old_normalized):]
            return (new_normalized + suffix).replace("/", ".")
        
        return original_target  # No change needed
