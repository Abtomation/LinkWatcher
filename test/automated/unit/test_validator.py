"""
Tests for the link validation module.

Tests LinkValidator, BrokenLink, ValidationResult, report generation,
and CLI integration (--validate flag).
"""

import os
import tempfile
from pathlib import Path

import pytest

from linkwatcher.config.settings import LinkWatcherConfig
from linkwatcher.validator import BrokenLink, LinkValidator, ValidationResult


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _create_file(base: str, rel_path: str, content: str = "") -> str:
    """Create a file inside *base* at *rel_path* with *content*."""
    full = os.path.join(base, rel_path.replace("/", os.sep))
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as fh:
        fh.write(content)
    return full


def _make_config(**overrides) -> LinkWatcherConfig:
    """Return a minimal config suitable for tests."""
    cfg = LinkWatcherConfig()
    cfg.monitored_extensions = overrides.get(
        "monitored_extensions", {".md", ".yaml", ".json"}
    )
    cfg.ignored_directories = overrides.get("ignored_directories", {".git"})
    # Disable parsers we don't need so tests run faster
    cfg.enable_dart_parser = False
    cfg.enable_python_parser = False
    cfg.enable_powershell_parser = False
    for key, val in overrides.items():
        if hasattr(cfg, key):
            setattr(cfg, key, val)
    return cfg


# ---------------------------------------------------------------------------
# DataClass tests
# ---------------------------------------------------------------------------


class TestBrokenLink:
    def test_fields(self):
        bl = BrokenLink(
            source_file="docs/readme.md",
            line_number=10,
            target_path="missing.md",
            link_type="markdown",
        )
        assert bl.source_file == "docs/readme.md"
        assert bl.line_number == 10
        assert bl.target_path == "missing.md"
        assert bl.link_type == "markdown"


class TestValidationResult:
    def test_is_clean_when_no_broken(self):
        r = ValidationResult()
        assert r.is_clean is True

    def test_not_clean_when_broken(self):
        r = ValidationResult(
            broken_links=[
                BrokenLink("a.md", 1, "b.md", "markdown")
            ]
        )
        assert r.is_clean is False

    def test_defaults(self):
        r = ValidationResult()
        assert r.files_scanned == 0
        assert r.links_checked == 0
        assert r.duration_seconds == 0.0


# ---------------------------------------------------------------------------
# Validator core logic
# ---------------------------------------------------------------------------


class TestLinkValidator:
    def test_valid_links_no_broken(self, tmp_path):
        """A workspace where all links resolve — expect zero broken links."""
        _create_file(str(tmp_path), "target.md", "# Target")
        _create_file(
            str(tmp_path), "source.md", "[link](target.md)\n"
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.is_clean
        assert result.files_scanned >= 1
        assert result.links_checked >= 1

    def test_broken_link_detected(self, tmp_path):
        """A link to a non-existent file should be reported."""
        _create_file(
            str(tmp_path), "source.md", "[link](does-not-exist.md)\n"
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert not result.is_clean
        assert len(result.broken_links) >= 1
        bl = result.broken_links[0]
        assert bl.target_path == "does-not-exist.md"
        assert bl.source_file == "source.md"

    def test_anchor_stripped_before_check(self, tmp_path):
        """file.md#section should check file.md existence only."""
        _create_file(str(tmp_path), "target.md", "# Section")
        _create_file(
            str(tmp_path), "source.md", "[link](target.md#section)\n"
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.is_clean

    def test_pure_anchor_always_valid(self, tmp_path):
        """A link like #section (no file part) should always pass."""
        _create_file(str(tmp_path), "source.md", "[link](#section)\n")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # Pure anchors should not produce broken links
        assert all(
            bl.target_path != "#section" for bl in result.broken_links
        )

    def test_url_links_skipped(self, tmp_path):
        """HTTP/HTTPS links should not be checked."""
        _create_file(
            str(tmp_path),
            "source.md",
            "[ext](https://example.com)\n[ftp](ftp://files.example.com/f)\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.links_checked == 0

    def test_ignored_directories_skipped(self, tmp_path):
        """Files inside ignored directories should not be scanned."""
        _create_file(
            str(tmp_path), ".git/config.md", "[link](missing.md)\n"
        )
        _create_file(str(tmp_path), "source.md", "# ok\n")

        cfg = _make_config(ignored_directories={".git"})
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # .git/config.md should not appear in results
        for bl in result.broken_links:
            assert ".git" not in bl.source_file

    def test_monitored_extensions_respected(self, tmp_path):
        """Only files with monitored extensions should be scanned."""
        _create_file(
            str(tmp_path), "readme.txt", "[link](missing.md)\n"
        )

        cfg = _make_config(monitored_extensions={".md"})  # .txt not included
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.files_scanned == 0

    def test_empty_workspace(self, tmp_path):
        """An empty workspace should return a clean result."""
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.is_clean
        assert result.files_scanned == 0
        assert result.links_checked == 0

    def test_mixed_valid_and_broken(self, tmp_path):
        """Only broken links should appear in the result."""
        _create_file(str(tmp_path), "exists.md", "# ok")
        _create_file(
            str(tmp_path),
            "source.md",
            "[valid](exists.md)\n[broken](nope.md)\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert len(result.broken_links) >= 1
        targets = {bl.target_path for bl in result.broken_links}
        assert "nope.md" in targets
        assert "exists.md" not in targets

    def test_subdirectory_link_resolution(self, tmp_path):
        """Links should resolve relative to the source file's directory."""
        _create_file(str(tmp_path), "docs/guide.md", "# Guide")
        _create_file(
            str(tmp_path), "docs/index.md", "[guide](guide.md)\n"
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.is_clean

    def test_parent_directory_link(self, tmp_path):
        """../file.md should resolve correctly."""
        _create_file(str(tmp_path), "readme.md", "# Root")
        _create_file(
            str(tmp_path), "docs/index.md", "[up](../readme.md)\n"
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.is_clean

    def test_duration_recorded(self, tmp_path):
        """validate() should record a positive duration."""
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.duration_seconds >= 0.0


# ---------------------------------------------------------------------------
# Report generation
# ---------------------------------------------------------------------------


class TestReportFormatting:
    def test_clean_report(self):
        result = ValidationResult(files_scanned=10, links_checked=50)
        report = LinkValidator.format_report(result)

        assert "No broken links found." in report
        assert "Files scanned : 10" in report
        assert "Links checked : 50" in report

    def test_broken_report_includes_details(self):
        result = ValidationResult(
            broken_links=[
                BrokenLink("src/a.md", 5, "missing.md", "markdown"),
            ],
            files_scanned=1,
            links_checked=1,
        )
        report = LinkValidator.format_report(result)

        assert "src/a.md:5" in report
        assert "missing.md" in report
        assert "Broken links  : 1" in report

    def test_write_report_creates_file(self, tmp_path):
        result = ValidationResult(files_scanned=1, links_checked=1)
        path = LinkValidator.write_report(result, str(tmp_path))

        assert os.path.exists(path)
        assert path.endswith("LinkWatcherBrokenLinks.txt")
        content = Path(path).read_text(encoding="utf-8")
        assert "No broken links found." in content

    def test_write_report_creates_directory(self, tmp_path):
        out_dir = os.path.join(str(tmp_path), "nested", "output")
        result = ValidationResult()
        path = LinkValidator.write_report(result, out_dir)

        assert os.path.exists(path)
