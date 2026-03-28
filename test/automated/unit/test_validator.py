"""
Tests for the link validation module.

Tests LinkValidator, BrokenLink, ValidationResult, report generation,
and CLI integration (--validate flag).
"""

import os
from pathlib import Path

import pytest

from linkwatcher.config.settings import LinkWatcherConfig
from linkwatcher.validator import BrokenLink, LinkValidator, ValidationResult

pytestmark = [
    pytest.mark.feature("6.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
]


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
    cfg.monitored_extensions = overrides.get("monitored_extensions", {".md", ".yaml", ".json"})
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
        r = ValidationResult(broken_links=[BrokenLink("a.md", 1, "b.md", "markdown")])
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
        _create_file(str(tmp_path), "docs/target.md", "# Target")
        _create_file(str(tmp_path), "source.md", "[link](docs/target.md)\n")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.is_clean
        assert result.files_scanned >= 1
        assert result.links_checked >= 1

    def test_broken_link_detected(self, tmp_path):
        """A link to a non-existent file should be reported."""
        _create_file(str(tmp_path), "source.md", "[link](docs/does-not-exist.md)\n")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert not result.is_clean
        assert len(result.broken_links) >= 1
        bl = result.broken_links[0]
        assert bl.target_path == "docs/does-not-exist.md"
        assert bl.source_file == "source.md"

    def test_anchor_stripped_before_check(self, tmp_path):
        """file.md#section should check file.md existence only."""
        _create_file(str(tmp_path), "target.md", "# Section")
        _create_file(str(tmp_path), "source.md", "[link](target.md#section)\n")

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
        assert all(bl.target_path != "#section" for bl in result.broken_links)

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
        _create_file(str(tmp_path), ".git/config.md", "[link](missing.md)\n")
        _create_file(str(tmp_path), "source.md", "# ok\n")

        cfg = _make_config(ignored_directories={".git"})
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # .git/config.md should not appear in results
        for bl in result.broken_links:
            assert ".git" not in bl.source_file

    def test_monitored_extensions_respected(self, tmp_path):
        """Only files with monitored extensions should be scanned."""
        _create_file(str(tmp_path), "readme.txt", "[link](missing.md)\n")

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
        _create_file(str(tmp_path), "docs/exists.md", "# ok")
        _create_file(
            str(tmp_path),
            "source.md",
            "[valid](docs/exists.md)\n[broken](docs/nope.md)\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert len(result.broken_links) >= 1
        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/nope.md" in targets
        assert "docs/exists.md" not in targets

    def test_subdirectory_link_resolution(self, tmp_path):
        """Links should resolve relative to the source file's directory."""
        _create_file(str(tmp_path), "docs/guide.md", "# Guide")
        _create_file(str(tmp_path), "docs/index.md", "[guide](guide.md)\n")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert result.is_clean

    def test_parent_directory_link(self, tmp_path):
        """../file.md should resolve correctly."""
        _create_file(str(tmp_path), "readme.md", "# Root")
        _create_file(str(tmp_path), "docs/index.md", "[up](../readme.md)\n")

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

    def test_linkwatcher_run_dir_ignored(self, tmp_path):
        """Files in LinkWatcher_run/ should be skipped automatically."""
        _create_file(str(tmp_path), "LinkWatcher_run/log.md", "[link](missing.md)\n")
        _create_file(str(tmp_path), "source.md", "# ok\n")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        for bl in result.broken_links:
            assert "LinkWatcher_run" not in bl.source_file

    def test_standalone_link_in_code_block_skipped(self, tmp_path):
        """Bare paths inside fenced code blocks should be skipped."""
        content = "# Guide\n" "\n" "```bash\n" "path/to/missing.ps1\n" "```\n"
        _create_file(str(tmp_path), "source.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # The bare path inside the code block should NOT appear as broken
        for bl in result.broken_links:
            assert "missing.ps1" not in bl.target_path

    def test_proper_link_in_code_block_still_checked(self, tmp_path):
        """Proper [text](path) links inside code blocks are still checked."""
        content = "# Guide\n" "\n" "```markdown\n" "[link](docs/does-not-exist.md)\n" "```\n"
        _create_file(str(tmp_path), "source.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/does-not-exist.md" in targets

    def test_standalone_link_outside_code_block_still_checked(self, tmp_path):
        """Bare paths in normal prose should still be checked."""
        content = "# Guide\n" "\n" "See docs/nonexistent/missing.md for details.\n"
        _create_file(str(tmp_path), "source.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/nonexistent/missing.md" in targets

    def test_root_relative_path_resolved(self, tmp_path):
        """Paths starting with / should resolve against project root."""
        _create_file(str(tmp_path), "docs/guide.md", "# Guide")
        _create_file(
            str(tmp_path),
            "deep/nested/source.md",
            "[link](/docs/guide.md)\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # /docs/guide.md should resolve to <project_root>/docs/guide.md
        assert result.is_clean

    def test_root_relative_broken_detected(self, tmp_path):
        """A root-relative path to a missing file should be reported."""
        _create_file(
            str(tmp_path),
            "source.md",
            "[link](/does/not/exist.md)\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        assert not result.is_clean
        assert any(bl.target_path == "/does/not/exist.md" for bl in result.broken_links)

    def test_old_and_archive_dirs_ignored(self, tmp_path):
        """Files in old/ and archive/ directories are excluded from validation."""
        # Broken link inside old/ — should NOT be reported
        _create_file(str(tmp_path), "old/stale.md", "[link](does/not/exist.md)\n")
        # Broken link inside archive/ — should NOT be reported
        _create_file(str(tmp_path), "archive/stale.md", "[link](does/not/exist.md)\n")
        # Broken link in a real dir — SHOULD be reported
        _create_file(str(tmp_path), "docs/active.md", "[link](does/not/exist.md)\n")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        sources = {bl.source_file for bl in result.broken_links}
        assert "docs/active.md" in sources, "Active file broken link should be reported"
        assert not any("old/" in s for s in sources), "old/ files should be excluded"
        assert not any("archive/" in s for s in sources), "archive/ files should be excluded"

    def test_fixtures_dir_ignored(self, tmp_path):
        """Test fixture files should be excluded from validation."""
        _create_file(
            str(tmp_path), "fixtures/sample.json", '{"path": "data/does-not-exist.json"}\n'
        )
        _create_file(str(tmp_path), "docs/real.md", "# ok\n")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        sources = {bl.source_file for bl in result.broken_links}
        assert not any("fixtures/" in s for s in sources), "fixtures/ files should be excluded"

    def test_source_code_files_not_validated(self, tmp_path):
        """Python/PowerShell files should not be scanned for validation."""
        _create_file(str(tmp_path), "script.py", '"missing_file.md"\n')
        _create_file(str(tmp_path), "source.md", "# ok\n")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # script.py should not be scanned — only .md files
        for bl in result.broken_links:
            assert not bl.source_file.endswith(".py")

    def test_standalone_root_relative_path_resolved(self, tmp_path):
        """Standalone paths that exist at project root should not be broken.

        Standalone paths in prose are typically project-root-relative
        (e.g. 'doc/guide.md' mentioned in a deeply nested file).
        The validator should try root resolution as fallback.
        """
        _create_file(str(tmp_path), "doc/scripts/helper.ps1", "# helper")
        # Standalone mention of a project-root-relative path in a nested file
        _create_file(
            str(tmp_path),
            "doc/deep/nested/source.md",
            "Run validation: doc/scripts/helper.ps1 to check.\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # doc/scripts/helper.ps1 exists at root — should NOT be broken
        targets = {bl.target_path for bl in result.broken_links}
        assert "doc/scripts/helper.ps1" not in targets

    def test_standalone_root_relative_broken_still_detected(self, tmp_path):
        """Standalone paths that don't exist anywhere should still be broken."""
        _create_file(
            str(tmp_path),
            "doc/deep/source.md",
            "See doc/nonexistent/missing.md for details.\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "doc/nonexistent/missing.md" in targets

    def test_standalone_in_table_root_relative_resolved(self, tmp_path):
        """Standalone paths inside table cells should also get root fallback."""
        _create_file(str(tmp_path), "scripts/tool.ps1", "# tool")
        _create_file(
            str(tmp_path),
            "doc/report.md",
            "| Tool | Path |\n| --- | --- |\n| Linter | scripts/tool.ps1 |\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "scripts/tool.ps1" not in targets

    def test_markdown_link_no_root_fallback(self, tmp_path):
        """Proper [text](path) links should NOT get root-relative fallback.

        Only standalone/data-value link types benefit from dual resolution.
        Proper markdown links have explicit syntax — the author chose
        the relative path deliberately, so wrong paths should be flagged.
        """
        _create_file(str(tmp_path), "doc/guide.md", "# Guide")
        _create_file(
            str(tmp_path),
            "doc/deep/nested/source.md",
            "[link](doc/guide.md)\n",  # Wrong: should be ../../guide.md
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # This should still be broken — proper links don't get root fallback
        targets = {bl.target_path for bl in result.broken_links}
        assert "doc/guide.md" in targets

    def test_yaml_root_relative_path_resolved(self, tmp_path):
        """YAML data-value paths that exist at project root should not be broken."""
        _create_file(str(tmp_path), "test/automated/unit/test_service.py", "# test")
        _create_file(
            str(tmp_path),
            "test/test-registry.yaml",
            "- filePath: test/automated/unit/test_service.py\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "test/automated/unit/test_service.py" not in targets

    def test_yaml_broken_path_still_detected(self, tmp_path):
        """YAML paths that don't exist anywhere should still be broken."""
        _create_file(
            str(tmp_path),
            "config/registry.yaml",
            "- filePath: nonexistent/module/test.py\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "nonexistent/module/test.py" in targets

    def test_json_root_relative_path_resolved(self, tmp_path):
        """JSON data-value paths that exist at project root should not be broken."""
        _create_file(str(tmp_path), "doc/feedback/form.md", "# form")
        _create_file(
            str(tmp_path),
            "data/ratings.json",
            '{"source": "doc/feedback/form.md"}\n',
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "doc/feedback/form.md" not in targets


# ---------------------------------------------------------------------------
# Target filtering (_should_check_target)
# ---------------------------------------------------------------------------


class TestShouldCheckTarget:
    """Tests for the heuristic filters that skip non-path targets."""

    def test_url_skipped(self):
        assert LinkValidator._should_check_target("https://example.com", "markdown") is False

    def test_python_import_skipped(self):
        assert LinkValidator._should_check_target("app.utils", "python-import") is False

    def test_shell_command_bash_skipped(self):
        assert LinkValidator._should_check_target("Bash(python scripts/run.py)", "json") is False

    def test_shell_command_pwsh_skipped(self):
        assert (
            LinkValidator._should_check_target(
                "pwsh.exe -ExecutionPolicy Bypass -File script.ps1", "yaml"
            )
            is False
        )

    def test_shell_command_python_skipped(self):
        assert (
            LinkValidator._should_check_target("python main.py --validate", "generic-unquoted")
            is False
        )

    def test_shell_command_git_skipped(self):
        assert LinkValidator._should_check_target("git status", "generic-unquoted") is False

    def test_wildcard_glob_skipped(self):
        assert LinkValidator._should_check_target("*.md", "generic-unquoted") is False

    def test_wildcard_double_star_skipped(self):
        assert LinkValidator._should_check_target("**/*.py", "generic-unquoted") is False

    def test_wildcard_question_mark_skipped(self):
        assert LinkValidator._should_check_target("file?.txt", "generic-unquoted") is False

    def test_target_with_spaces_skipped(self):
        """Targets containing spaces are likely prose or commands, not paths."""
        assert (
            LinkValidator._should_check_target("some random text.md", "generic-unquoted") is False
        )

    def test_non_path_string_skipped(self):
        """Strings that don't look like file paths should be rejected."""
        assert LinkValidator._should_check_target("justtext", "generic-unquoted") is False

    def test_valid_relative_path_accepted(self):
        assert LinkValidator._should_check_target("docs/guide.md", "markdown") is True

    def test_bare_filename_skipped(self):
        """Bare filenames without path separators are prose mentions."""
        assert LinkValidator._should_check_target("readme.md", "markdown") is False
        assert LinkValidator._should_check_target("Script.ps1", "markdown-standalone") is False

    def test_numeric_slash_skipped(self):
        """Scores like 3.475/4.0 should not be treated as paths."""
        assert LinkValidator._should_check_target("3.475/4.0", "markdown-standalone") is False
        assert LinkValidator._should_check_target("80/100", "markdown-standalone") is False

    def test_placeholder_skipped(self):
        """Template placeholders should be skipped."""
        assert (
            LinkValidator._should_check_target(
                "feedback-forms/YYYYMMDD-HHMMSS-feedback.md", "markdown-standalone"
            )
            is False
        )

    def test_square_bracket_placeholder_skipped(self):
        """Square-bracket template placeholders like [feature-id] should be skipped."""
        assert (
            LinkValidator._should_check_target(
                "state-tracking/features/feature-implementation-state-[feature-id].md", "markdown"
            )
            is False
        )
        assert (
            LinkValidator._should_check_target(
                "visualization/context-maps/[task-type]/[task-name]-map.md", "markdown"
            )
            is False
        )
        assert (
            LinkValidator._should_check_target(
                "architecture/context-packages/[architecture-area]-context.md", "markdown"
            )
            is False
        )

    def test_dot_relative_accepted(self):
        """Paths starting with ./ or ../ are real references."""
        assert LinkValidator._should_check_target("./readme.md", "markdown") is True
        assert LinkValidator._should_check_target("../readme.md", "markdown") is True

    def test_valid_parent_path_accepted(self):
        assert LinkValidator._should_check_target("../readme.md", "markdown") is True

    def test_valid_deep_path_accepted(self):
        assert (
            LinkValidator._should_check_target("doc/process-framework/tasks/task.md", "markdown")
            is True
        )

    def test_root_relative_accepted(self):
        assert (
            LinkValidator._should_check_target("/doc/process-framework/tasks/task.md", "markdown")
            is True
        )


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


# ---------------------------------------------------------------------------
# Validation ignored patterns (config-driven)
# ---------------------------------------------------------------------------


class TestValidationIgnoredPatterns:
    """Tests for the validation_ignored_patterns config feature."""

    def test_default_pattern_skips_path_to(self, tmp_path):
        """Default 'path/to/' pattern should suppress placeholder paths."""
        _create_file(
            str(tmp_path),
            "source.md",
            "[link](path/to/document.md)\n[real](docs/missing.md)\n",
        )

        cfg = _make_config()
        # Default includes "path/to/"
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "path/to/document.md" not in targets, "path/to/ should be ignored"
        assert "docs/missing.md" in targets, "Real broken link should still be reported"

    def test_custom_pattern_skips_matching_targets(self, tmp_path):
        """User-defined patterns should suppress matching targets."""
        _create_file(
            str(tmp_path),
            "source.md",
            "[a](example/placeholder.md)\n[b](docs/real-broken.md)\n",
        )

        cfg = _make_config(validation_ignored_patterns={"example/"})
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "example/placeholder.md" not in targets
        assert "docs/real-broken.md" in targets

    def test_empty_patterns_disables_filtering(self, tmp_path):
        """Empty pattern set should not filter anything."""
        _create_file(
            str(tmp_path),
            "source.md",
            "[link](path/to/document.md)\n",
        )

        cfg = _make_config(validation_ignored_patterns=set())
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "path/to/document.md" in targets

    def test_multiple_patterns(self, tmp_path):
        """Multiple patterns should all be applied."""
        _create_file(
            str(tmp_path),
            "source.md",
            "[a](path/to/doc.md)\n[b](example/test.md)\n[c](docs/real.md)\n",
        )

        cfg = _make_config(validation_ignored_patterns={"path/to/", "example/"})
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "path/to/doc.md" not in targets
        assert "example/test.md" not in targets
        assert "docs/real.md" in targets


# ---------------------------------------------------------------------------
# Archival <details> section filter
# ---------------------------------------------------------------------------


class TestArchivalDetailsFilter:
    """Tests for skipping standalone links inside archival <details> blocks."""

    def test_standalone_in_archival_details_skipped(self, tmp_path):
        """Standalone paths inside a 'Closed' details block should be skipped."""
        content = (
            "# Bugs\n"
            "\n"
            "Active content here.\n"
            "\n"
            "<details>\n"
            "<summary><strong>View Closed Bugs History</strong></summary>\n"
            "\n"
            "| Bug | Path |\n"
            "| --- | --- |\n"
            "| BUG-1 | some/deleted/file.md |\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "bugs.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "some/deleted/file.md" not in targets

    def test_proper_link_in_archival_details_still_checked(self, tmp_path):
        """Proper [text](path) links inside archival details ARE still checked."""
        content = (
            "<details>\n"
            "<summary>View Closed History</summary>\n"
            "\n"
            "[link](docs/does-not-exist.md)\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "source.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/does-not-exist.md" in targets

    def test_non_archival_details_still_checked(self, tmp_path):
        """Standalone paths in non-archival details blocks should still be checked."""
        content = (
            "<details>\n"
            "<summary><strong>0. System Architecture</strong></summary>\n"
            "\n"
            "| Feature | Path |\n"
            "| --- | --- |\n"
            "| Core | some/nonexistent/path.md |\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "features.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "some/nonexistent/path.md" in targets

    def test_completed_keyword_triggers_archival(self, tmp_path):
        """'completed' in summary should trigger archival mode."""
        content = (
            "<details>\n"
            "<summary>Show completed improvements (52 items)</summary>\n"
            "\n"
            "| IMP | Ref |\n"
            "| --- | --- |\n"
            "| IMP-1 | ../Common-ScriptHelpers.psm1 |\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "tracking.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "../Common-ScriptHelpers.psm1" not in targets

    def test_archived_keyword_triggers_archival(self, tmp_path):
        """'archived' in summary should trigger archival mode."""
        content = (
            "<details>\n"
            "<summary><strong>Show archived features (2 items)</strong></summary>\n"
            "\n"
            "Old refs: some/old/feature.md mentioned here.\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "features.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "some/old/feature.md" not in targets

    def test_history_keyword_triggers_archival(self, tmp_path):
        """'history' in summary should trigger archival mode."""
        content = (
            "<details>\n"
            "<summary>Show update history (100 entries)</summary>\n"
            "\n"
            "| Date | Change |\n"
            "| --- | --- |\n"
            "| 2026-01-01 | Fixed scripts/old-tool.ps1 path |\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "log.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "scripts/old-tool.ps1" not in targets


# ---------------------------------------------------------------------------
# Extension-before-slash filter
# ---------------------------------------------------------------------------


class TestExtBeforeSlashFilter:
    """Targets like 'logging.py/logging_config.py' are slash-separated
    alternatives, not real file paths."""

    def test_ext_before_slash_skipped(self, tmp_path):
        """Target with .py/ mid-path should be skipped."""
        _create_file(str(tmp_path), "source.md", "See logging.py/logging_config.py\n")
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()
        assert result.links_checked == 0

    def test_yaml_ext_before_slash_skipped(self, tmp_path):
        """Target with .yaml/ mid-path should be skipped."""
        _create_file(str(tmp_path), "source.md", "See config.yaml/defaults.json\n")
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()
        assert result.links_checked == 0

    def test_real_path_with_extension_in_dir_still_checked(self, tmp_path):
        """A real path like 'docs/guide.md' should still be checked."""
        _create_file(str(tmp_path), "source.md", "[link](docs/guide.md)\n")
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()
        assert result.links_checked == 1


# ---------------------------------------------------------------------------
# Per-file ignore list (.linkwatcher-ignore)
# ---------------------------------------------------------------------------


class TestLinkwatcherIgnoreFile:
    """Tests for the .linkwatcher-ignore per-file suppression rules."""

    def _cfg_with_ignore(self, **overrides):
        """Config with validation_ignore_file pointing to project root."""
        return _make_config(validation_ignore_file=".linkwatcher-ignore", **overrides)

    def test_ignore_rule_suppresses_matching_broken_link(self, tmp_path):
        """A rule matching source glob and target substring should suppress."""
        _create_file(str(tmp_path), "templates/doc.md", "[link](related-design.md)\n")
        _create_file(
            str(tmp_path),
            ".linkwatcher-ignore",
            "templates/**/*.md -> related-design.md\n",
        )
        v = LinkValidator(str(tmp_path), self._cfg_with_ignore())
        result = v.validate()
        targets = {bl.target_path for bl in result.broken_links}
        assert "related-design.md" not in targets

    def test_non_matching_rule_does_not_suppress(self, tmp_path):
        """A rule for a different source should not suppress."""
        _create_file(str(tmp_path), "docs/real.md", "[link](missing/file.md)\n")
        _create_file(
            str(tmp_path),
            ".linkwatcher-ignore",
            "templates/**/*.md -> missing/file.md\n",
        )
        v = LinkValidator(str(tmp_path), self._cfg_with_ignore())
        result = v.validate()
        targets = {bl.target_path for bl in result.broken_links}
        assert "missing/file.md" in targets

    def test_no_ignore_file_works_normally(self, tmp_path):
        """Without .linkwatcher-ignore, all broken links are reported."""
        _create_file(str(tmp_path), "source.md", "[link](missing/doc.md)\n")
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()
        assert len(result.broken_links) == 1

    def test_comments_and_blank_lines_ignored(self, tmp_path):
        """Comments and blank lines in .linkwatcher-ignore are skipped."""
        _create_file(str(tmp_path), "source.md", "[link](missing/doc.md)\n")
        _create_file(
            str(tmp_path),
            ".linkwatcher-ignore",
            "# This is a comment\n\n  \nother/**/*.md -> missing/doc.md\n",
        )
        v = LinkValidator(str(tmp_path), self._cfg_with_ignore())
        result = v.validate()
        # Rule doesn't match source.md, so link should still be reported
        assert len(result.broken_links) == 1

    def test_target_substring_matching(self, tmp_path):
        """Target pattern is a substring match, not exact."""
        _create_file(str(tmp_path), "docs/report.md", "[link](some/path/README.md)\n")
        _create_file(
            str(tmp_path),
            ".linkwatcher-ignore",
            "docs/**/*.md -> README.md\n",
        )
        v = LinkValidator(str(tmp_path), self._cfg_with_ignore())
        result = v.validate()
        targets = {bl.target_path for bl in result.broken_links}
        assert "some/path/README.md" not in targets
