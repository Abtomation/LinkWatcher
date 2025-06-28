#!/usr/bin/env python3
"""
Script to update remaining print statements in handler.py to use structured logging.
This is a one-time migration script.
"""

import re
from pathlib import Path


def update_handler_logging():
    """Update remaining print statements in handler.py"""

    handler_file = Path("linkwatcher/handler.py")

    if not handler_file.exists():
        print(f"File {handler_file} not found")
        return

    content = handler_file.read_text(encoding="utf-8")

    # Define replacements for remaining print statements
    replacements = [
        # Directory move completion
        (
            r'print\(\s*f"{Fore\.GREEN}✓ Updated \{total_references_updated\} reference\(s\) for \{len\(moved_files\)\} moved files"\s*\)',
            """self.logger.info("directory_move_completed",
                           total_references_updated=total_references_updated,
                           moved_files_count=len(moved_files))
            print(
                f"{Fore.GREEN}✓ Updated {total_references_updated} reference(s) for {len(moved_files)} moved files"
            )""",
        ),
        # Directory move error
        (
            r'print\(f"{Fore\.RED}✗ Error handling directory move: \{e\}"\)',
            """self.logger.error("directory_move_error",
                            old_dir=old_dir,
                            new_dir=new_dir,
                            error=str(e),
                            error_type=type(e).__name__)
            print(f"{Fore.RED}✗ Error handling directory move: {e}")""",
        ),
        # File deleted
        (
            r'print\(f"{Fore\.RED}🗑️ File deleted: \{deleted_path\}"\)',
            """self.logger.file_deleted(deleted_path)
        print(f"{Fore.RED}🗑️ File deleted: {deleted_path}")""",
        ),
        # Broken references found
        (
            r'print\(\s*f"{Fore\.YELLOW}⚠️ Found \{len\(references\)\} broken reference\(s\) to deleted file"\s*\)',
            """self.logger.warning("broken_references_found",
                                deleted_file=deleted_path,
                                broken_references_count=len(references))
                print(
                    f"{Fore.YELLOW}⚠️ Found {len(references)} broken reference(s) to deleted file"
                )""",
        ),
        # Individual broken reference
        (
            r'print\(f"   \{Fore\.YELLOW\}• \{ref\.file_path\}:\{ref\.line_number\} - \{ref\.link_text\}"\)',
            """self.logger.debug("broken_reference_detail",
                              file_path=ref.file_path,
                              line_number=ref.line_number,
                              link_text=ref.link_text)
                    print(f"   {Fore.YELLOW}• {ref.file_path}:{ref.line_number} - {ref.link_text}")""",
        ),
        # File deletion error
        (
            r'print\(f"{Fore\.RED}✗ Error handling file deletion: \{e\}"\)',
            """self.logger.error("file_deletion_error",
                            deleted_path=deleted_path,
                            error=str(e),
                            error_type=type(e).__name__)
            print(f"{Fore.RED}✗ Error handling file deletion: {e}")""",
        ),
        # Directory deleted
        (
            r'print\(f"{Fore\.RED}🗑️ Directory deleted: \{deleted_dir\}"\)',
            """self.logger.warning("directory_deleted", deleted_dir=deleted_dir)
        print(f"{Fore.RED}🗑️ Directory deleted: {deleted_dir}")""",
        ),
        # Directory deletion warning
        (
            r'print\(f"{Fore\.YELLOW}⚠️ Directory deletion detected\. Consider running a full rescan\."\)',
            """self.logger.warning("directory_deletion_detected",
                            deleted_dir=deleted_dir,
                            recommendation="full_rescan")
        print(f"{Fore.YELLOW}⚠️ Directory deletion detected. Consider running a full rescan.")""",
        ),
        # Detected move
        (
            r'print\(f"{Fore\.CYAN}📁 Detected move: \{potential_move_source\} → \{created_path\}"\)',
            """self.logger.info("move_detected",
                            source=potential_move_source,
                            destination=created_path)
            print(f"{Fore.CYAN}📁 Detected move: {potential_move_source} → {created_path}")""",
        ),
        # File created
        (
            r'print\(f"{Fore\.GREEN}📄 File created: \{created_path\}"\)',
            """self.logger.file_created(created_path)
            print(f"{Fore.GREEN}📄 File created: {created_path}")""",
        ),
        # File creation error
        (
            r'print\(f"{Fore\.RED}✗ Error handling file creation: \{e\}"\)',
            """self.logger.error("file_creation_error",
                            created_path=created_path,
                            error=str(e),
                            error_type=type(e).__name__)
                print(f"{Fore.RED}✗ Error handling file creation: {e}")""",
        ),
    ]

    # Apply replacements
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

    # Write back the updated content
    handler_file.write_text(content, encoding="utf-8")
    print(f"Updated {handler_file}")


if __name__ == "__main__":
    update_handler_logging()
