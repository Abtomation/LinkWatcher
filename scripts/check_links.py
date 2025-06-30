#!/usr/bin/env python3
"""
Link Checker Utility

A standalone utility to check for broken links in the project.
This can be run independently of the file watcher service.
"""

import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Set

# Add the parent directory to the path so we can import from linkwatcher
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from colorama import Fore, Style, init
    from linkwatcher.parser import LinkParser
    from linkwatcher.models import LinkReference
except ImportError as e:
    print(f"Missing required dependency: {e}")
    print("Please install dependencies with: pip install -r requirements.txt")
    sys.exit(1)

# Initialize colorama
init(autoreset=True)


@dataclass
class BrokenLink:
    """Represents a broken link found during checking."""

    file_path: str
    line_number: int
    link_text: str
    link_target: str
    reason: str


class LinkChecker:
    """
    Comprehensive link checker that validates all links in the project.
    """

    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root).resolve()
        self.parser = LinkParser()
        self.broken_links: List[BrokenLink] = []

        # Files and directories to ignore
        self.ignored_dirs = {".git", ".dart_tool", "node_modules", ".vscode", "build", "dist"}
        self.ignored_files = {"link_check_results.txt", "broken_links.txt"}

        # Extensions to check
        self.monitored_extensions = {".md", ".yaml", ".yml", ".dart", ".py", ".json", ".txt"}

    def check_all_links(self) -> Dict[str, List[BrokenLink]]:
        """Check all links in the project and return broken links grouped by file."""
        print(f"{Fore.CYAN}Checking links in: {self.project_root}")

        files_checked = 0
        links_checked = 0
        broken_by_file = {}

        # Find all files to check
        files_to_check = self._find_files_to_check()

        print(f"{Fore.YELLOW}Found {len(files_to_check)} files to check")

        for file_path in files_to_check:
            try:
                file_broken_links = self._check_file_links(file_path)
                links_in_file = len(self.parser.parse_file(str(file_path)))

                files_checked += 1
                links_checked += links_in_file

                if file_broken_links:
                    rel_path = str(file_path.relative_to(self.project_root))
                    broken_by_file[rel_path] = file_broken_links
                    self.broken_links.extend(file_broken_links)

                # Progress indicator
                if files_checked % 10 == 0:
                    print(f"{Fore.BLUE}   Checked {files_checked}/{len(files_to_check)} files...")

            except Exception as e:
                print(f"{Fore.RED}Error checking {file_path}: {e}")

        # Print summary
        print(f"\n{Fore.GREEN}Link check complete!")
        print(f"   Files checked: {files_checked}")
        print(f"   Links checked: {links_checked}")
        print(f"   Broken links: {len(self.broken_links)}")
        print(f"   Files with broken links: {len(broken_by_file)}")

        return broken_by_file

    def _find_files_to_check(self) -> List[Path]:
        """Find all files that should be checked for links."""
        files_to_check = []

        for root, dirs, files in os.walk(self.project_root):
            # Skip ignored directories
            dirs[:] = [d for d in dirs if d not in self.ignored_dirs]

            # Skip if current directory should be ignored
            if any(ignored_dir in Path(root).parts for ignored_dir in self.ignored_dirs):
                continue

            for file in files:
                # Skip ignored files
                if file in self.ignored_files:
                    continue

                file_path = Path(root) / file

                # Check if file extension should be monitored
                if file_path.suffix.lower() in self.monitored_extensions:
                    files_to_check.append(file_path)

        return files_to_check

    def _check_file_links(self, file_path: Path) -> List[BrokenLink]:
        """Check all links in a single file."""
        broken_links = []

        try:
            references = self.parser.parse_file(str(file_path))

            for ref in references:
                broken_link = self._validate_link(file_path, ref)
                if broken_link:
                    broken_links.append(broken_link)

        except Exception as e:
            # Create a broken link entry for the parsing error
            broken_links.append(
                BrokenLink(
                    file_path=str(file_path.relative_to(self.project_root)),
                    line_number=0,
                    link_text="[Parse Error]",
                    link_target="",
                    reason=f"Could not parse file: {e}",
                )
            )

        return broken_links

    def _validate_link(self, file_path: Path, ref: LinkReference) -> BrokenLink:
        """Validate a single link reference."""
        target = ref.link_target

        # Skip external links
        if target.startswith(("http://", "https://", "mailto:", "tel:", "ftp://")):
            return None

        # Skip anchors only
        if target.startswith("#"):
            return None

        # Skip package references (Dart/Flutter)
        if target.startswith("package:"):
            return None

        # Extract file part (remove anchor)
        file_part = target.split("#")[0] if "#" in target else target

        if not file_part:  # Empty after removing anchor
            return None

        # Resolve the target path
        if file_part.startswith("/"):
            # Absolute path within project
            target_path = self.project_root / file_part.lstrip("/")
        else:
            # Relative path
            target_path = file_path.parent / file_part

        # Normalize the path
        try:
            target_path = target_path.resolve()
        except (OSError, ValueError) as e:
            return BrokenLink(
                file_path=str(file_path.relative_to(self.project_root)),
                line_number=ref.line_number,
                link_text=ref.link_text,
                link_target=ref.link_target,
                reason=f"Invalid path: {e}",
            )

        # Check if target exists
        if not target_path.exists():
            return BrokenLink(
                file_path=str(file_path.relative_to(self.project_root)),
                line_number=ref.line_number,
                link_text=ref.link_text,
                link_target=ref.link_target,
                reason="File not found",
            )

        # Check if target is outside project (security check)
        try:
            target_path.relative_to(self.project_root)
        except ValueError:
            return BrokenLink(
                file_path=str(file_path.relative_to(self.project_root)),
                line_number=ref.line_number,
                link_text=ref.link_text,
                link_target=ref.link_target,
                reason="Link points outside project",
            )

        return None  # Link is valid

    def print_results(self, broken_by_file: Dict[str, List[BrokenLink]]):
        """Print detailed results of the link check."""
        if not broken_by_file:
            print(f"\n{Fore.GREEN}All links are valid!")
            return

        print(f"\n{Fore.RED}Found broken links:")
        print("=" * 50)

        for file_path, broken_links in broken_by_file.items():
            print(f"\n{Fore.YELLOW}{file_path}")

            for broken_link in broken_links:
                if broken_link.line_number > 0:
                    print(f"   {Fore.RED}Line {broken_link.line_number}: {broken_link.link_target}")
                else:
                    print(f"   {Fore.RED}{broken_link.link_target}")

                print(f"   {Fore.CYAN}   Text: {broken_link.link_text}")
                print(f"   {Fore.MAGENTA}   Reason: {broken_link.reason}")

    def save_results(
        self,
        broken_by_file: Dict[str, List[BrokenLink]],
        output_file: str = "link_check_results.txt",
    ):
        """Save results to a file."""
        output_path = self.project_root / output_file

        with open(output_path, "w", encoding="utf-8") as f:
            f.write("Link Check Results\n")
            f.write("=" * 50 + "\n")
            f.write(f"Generated: {Path(__file__).name}\n")
            f.write(f"Project: {self.project_root}\n")
            f.write(f"Total broken links: {len(self.broken_links)}\n")
            f.write(f"Files with broken links: {len(broken_by_file)}\n\n")

            if not broken_by_file:
                f.write("All links are valid!\n")
                return

            for file_path, broken_links in broken_by_file.items():
                f.write(f"\n{file_path}\n")
                f.write("-" * len(file_path) + "\n")

                for broken_link in broken_links:
                    if broken_link.line_number > 0:
                        f.write(f"Line {broken_link.line_number}: {broken_link.link_target}\n")
                    else:
                        f.write(f"{broken_link.link_target}\n")

                    f.write(f"   Text: {broken_link.link_text}\n")
                    f.write(f"   Reason: {broken_link.reason}\n\n")

        print(f"\n{Fore.GREEN}Results saved to: {output_path}")


def main():
    """Main entry point for the link checker."""
    import argparse

    parser = argparse.ArgumentParser(description="Check all links in the project")
    parser.add_argument(
        "--project-root", default=".", help="Project root directory (default: current directory)"
    )
    parser.add_argument(
        "--output",
        default="link_check_results.txt",
        help="Output file for results (default: link_check_results.txt)",
    )
    parser.add_argument("--no-save", action="store_true", help="Don't save results to file")
    parser.add_argument(
        "--quiet", action="store_true", help="Only show summary, not detailed results"
    )

    args = parser.parse_args()

    # Create and run the checker
    checker = LinkChecker(args.project_root)
    broken_by_file = checker.check_all_links()

    # Show results
    if not args.quiet:
        checker.print_results(broken_by_file)

    # Save results
    if not args.no_save:
        checker.save_results(broken_by_file, args.output)

    # Exit with error code if broken links found
    if broken_by_file:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
