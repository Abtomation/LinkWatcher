"""
Link validation module for the LinkWatcher system.

Provides on-demand workspace scanning to detect broken file references
across all supported file formats. Read-only operation — does not modify
any files.
"""

import os
import time
from dataclasses import dataclass, field
from typing import List, Optional

from .config.settings import LinkWatcherConfig
from .logging import get_logger
from .models import LinkReference
from .parser import LinkParser
from .utils import should_monitor_file


@dataclass
class BrokenLink:
    """A link reference whose target does not exist on disk."""

    source_file: str
    line_number: int
    target_path: str
    link_type: str


@dataclass
class ValidationResult:
    """Aggregated result of a workspace validation scan."""

    broken_links: List[BrokenLink] = field(default_factory=list)
    files_scanned: int = 0
    links_checked: int = 0
    duration_seconds: float = 0.0

    @property
    def is_clean(self) -> bool:
        return len(self.broken_links) == 0


# Prefixes that indicate a URL rather than a local file path.
_URL_PREFIXES = ("http://", "https://", "ftp://", "mailto:", "tel:", "data:")


class LinkValidator:
    """
    Scans a workspace and reports broken local file references.

    Reuses the existing LinkParser infrastructure to extract links,
    then resolves each target relative to its source file and checks
    whether it exists on disk.
    """

    def __init__(self, project_root: str, config: Optional[LinkWatcherConfig] = None):
        self.project_root = os.path.abspath(project_root)
        self.config = config or LinkWatcherConfig()
        self.parser = LinkParser(self.config)
        self.logger = get_logger()

    def validate(self) -> ValidationResult:
        """Walk the workspace, parse every monitored file, and check links."""
        result = ValidationResult()
        start = time.monotonic()

        monitored_ext = self.config.monitored_extensions
        ignored_dirs = self.config.ignored_directories

        for root, dirs, files in os.walk(self.project_root):
            # Prune ignored directories in-place (same pattern as _initial_scan)
            dirs[:] = [d for d in dirs if d not in ignored_dirs]

            for filename in files:
                file_path = os.path.join(root, filename)

                if not should_monitor_file(file_path, monitored_ext, ignored_dirs):
                    continue

                self._check_file(file_path, result)

        result.duration_seconds = time.monotonic() - start
        return result

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _check_file(self, file_path: str, result: ValidationResult) -> None:
        """Parse a single file and verify every link target."""
        try:
            references: List[LinkReference] = self.parser.parse_file(file_path)
        except Exception as exc:
            self.logger.warning(
                "validation_parse_failed",
                file_path=file_path,
                error=str(exc),
            )
            return

        result.files_scanned += 1

        for ref in references:
            target = ref.link_target

            # Skip URLs
            if target.startswith(_URL_PREFIXES):
                continue

            # Skip Python import targets (module paths, not file paths)
            if ref.link_type == "python-import":
                continue

            result.links_checked += 1

            if not self._target_exists(file_path, target):
                rel_source = os.path.relpath(file_path, self.project_root)
                result.broken_links.append(
                    BrokenLink(
                        source_file=rel_source.replace("\\", "/"),
                        line_number=ref.line_number,
                        target_path=target,
                        link_type=ref.link_type,
                    )
                )

    def _target_exists(self, source_file: str, target: str) -> bool:
        """Resolve *target* relative to *source_file* and check existence."""
        # Strip anchor (e.g. file.md#section → file.md)
        if "#" in target:
            target = target.split("#", 1)[0]
            if not target:
                # Pure anchor link (#section) — always valid within the file
                return True

        # Resolve relative to the directory containing the source file
        source_dir = os.path.dirname(source_file)
        resolved = os.path.normpath(os.path.join(source_dir, target))

        return os.path.exists(resolved)

    # ------------------------------------------------------------------
    # Report formatting
    # ------------------------------------------------------------------

    @staticmethod
    def format_report(result: ValidationResult) -> str:
        """Return a human-readable text report."""
        lines: List[str] = []
        lines.append("=" * 60)
        lines.append("LinkWatcher - Link Validation Report")
        lines.append("=" * 60)
        lines.append("")
        lines.append(f"Files scanned : {result.files_scanned}")
        lines.append(f"Links checked : {result.links_checked}")
        lines.append(f"Broken links  : {len(result.broken_links)}")
        lines.append(f"Duration      : {result.duration_seconds:.2f}s")
        lines.append("")

        if result.is_clean:
            lines.append("No broken links found.")
        else:
            lines.append("Broken links:")
            lines.append("-" * 60)
            for bl in result.broken_links:
                lines.append(f"  {bl.source_file}:{bl.line_number}")
                lines.append(f"    -> {bl.target_path}  ({bl.link_type})")
            lines.append("-" * 60)

        lines.append("")
        return "\n".join(lines)

    @staticmethod
    def write_report(result: ValidationResult, output_dir: str) -> str:
        """Write the report to *output_dir*/LinkWatcherBrokenLinks.txt.

        Returns the absolute path of the written file.
        """
        os.makedirs(output_dir, exist_ok=True)
        report_path = os.path.join(output_dir, "LinkWatcherBrokenLinks.txt")
        with open(report_path, "w", encoding="utf-8") as fh:
            fh.write(LinkValidator.format_report(result))
        return report_path
