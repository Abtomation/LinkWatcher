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
        """Bare paths inside fenced code blocks should be skipped.

        Uses a path that does NOT match the default validation_ignored_patterns
        ('path/to/') so the code-block filter (line 405) is actually exercised.
        """
        content = "# Guide\n\n```bash\ndocs/missing-script.ps1\n```\n"
        _create_file(str(tmp_path), "source.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # The bare path inside the code block should NOT appear as broken
        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/missing-script.ps1" not in targets

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
        _create_file(str(tmp_path), "alpha-project/scripts/helper.ps1", "# helper")
        # Standalone mention of a project-root-relative path in a nested file
        _create_file(
            str(tmp_path),
            "alpha-project/deep/nested/source.md",
            "Run validation: alpha-project/scripts/helper.ps1 to check.\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # alpha-project/scripts/helper.ps1 exists at root — should NOT be broken
        targets = {bl.target_path for bl in result.broken_links}
        assert "alpha-project/scripts/helper.ps1" not in targets

    def test_standalone_root_relative_broken_still_detected(self, tmp_path):
        """Standalone paths that don't exist anywhere should still be broken."""
        _create_file(
            str(tmp_path),
            "alpha-project/deep/source.md",
            "See alpha-project/nonexistent/missing.md for details.\n",
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "alpha-project/nonexistent/missing.md" in targets

    def test_standalone_in_table_root_relative_resolved(self, tmp_path):
        """Standalone paths inside table cells should also get root fallback."""
        _create_file(str(tmp_path), "scripts/tool.ps1", "# tool")
        _create_file(
            str(tmp_path),
            "alpha-project/report.md",
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
        _create_file(str(tmp_path), "alpha-project/guide.md", "# Guide")
        _create_file(
            str(tmp_path),
            "alpha-project/deep/nested/source.md",
            "[link](alpha-project/guide.md)\n",  # Wrong: should be ../../guide.md
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        # This should still be broken — proper links don't get root fallback
        targets = {bl.target_path for bl in result.broken_links}
        assert "alpha-project/guide.md" in targets

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
        _create_file(str(tmp_path), "alpha-project/feedback/form.md", "# form")
        _create_file(
            str(tmp_path),
            "data/ratings.json",
            '{"source": "alpha-project/feedback/form.md"}\n',
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "alpha-project/feedback/form.md" not in targets


# ---------------------------------------------------------------------------
# Target filtering (_should_check_target)
# ---------------------------------------------------------------------------


class TestShouldCheckTarget:
    """Tests for the heuristic filters that skip non-path targets."""

    @pytest.mark.parametrize(
        "target, link_type, reason",
        [
            # URLs
            ("https://example.com", "markdown", "URL prefix"),
            # Python imports
            ("app.utils", "python-import", "python-import link type"),
            # Shell commands
            ("Bash(python scripts/run.py)", "json", "Bash() command"),
            ("pwsh.exe -ExecutionPolicy Bypass -File script.ps1", "yaml", "pwsh command"),
            ("python main.py --validate", "generic-unquoted", "python command"),
            ("git status", "generic-unquoted", "git command"),
            # Wildcards / globs
            ("*.md", "generic-unquoted", "wildcard *"),
            ("**/*.py", "generic-unquoted", "double-star glob"),
            ("file?.txt", "generic-unquoted", "question mark wildcard"),
            # Spaces (prose / commands)
            ("some random text.md", "generic-unquoted", "target with spaces"),
            # Non-path strings (no separator)
            ("justtext", "generic-unquoted", "no path separator"),
            # Bare filenames (prose mentions)
            ("readme.md", "markdown", "bare filename without separator"),
            ("Script.ps1", "markdown-standalone", "bare filename .ps1"),
            # Numeric / slash patterns (scores)
            ("3.475/4.0", "markdown-standalone", "numeric slash score"),
            ("80/100", "markdown-standalone", "numeric fraction"),
            # Template placeholders
            (
                "feedback-forms/YYYYMMDD-HHMMSS-feedback.md",
                "markdown-standalone",
                "YYYY placeholder",
            ),
            (
                "state-tracking/features/feature-implementation-state-[feature-id].md",
                "markdown",
                "square-bracket placeholder",
            ),
            (
                "visualization/context-maps/[task-type]/[task-name]-map.md",
                "markdown",
                "multi square-bracket placeholder",
            ),
            (
                "architecture/context-packages/[architecture-area]-context.md",
                "markdown",
                "single square-bracket placeholder",
            ),
            # Regex metacharacters (^{}|) — TD170 line 450
            ("[^\\'\"]+\\.[a-zA-Z0-9]+", "markdown-standalone", "regex with ^ metachar"),
            ("config{dev|prod}.yaml", "markdown-standalone", "regex with {} and |"),
            ("src/{main|test}/app.py", "generic-unquoted", "regex with {|} braces"),
            # Regex fragments ]+  and \[ — TD170 line 455
            ("pattern]+(more)", "markdown-standalone", "regex ]+ fragment"),
            ("match\\[index\\]", "markdown-standalone", "regex \\[ escaped bracket"),
            # PowerShell .\ invocation syntax — TD170 line 460
            (".\\Script.ps1", "markdown-standalone", "PowerShell .\\ invocation"),
            (".\\Run-Tests.ps1", "generic-unquoted", "PowerShell .\\ invocation variant"),
            # Separator but no extension and not dir-like — TD170 line 481
            ("some/dir", "markdown", "separator but no ext, not dir-like"),
        ],
        ids=lambda x: x if isinstance(x, str) and len(x) < 40 else None,
    )
    def test_target_skipped(self, target, link_type, reason):
        """Targets that are not real file paths should be rejected."""
        assert (
            LinkValidator._should_check_target(target, link_type) is False
        ), f"Expected skip for {reason}: {target!r}"

    @pytest.mark.parametrize(
        "target, link_type, reason",
        [
            ("docs/guide.md", "markdown", "relative path with separator"),
            ("./readme.md", "markdown", "dot-relative path"),
            ("../readme.md", "markdown", "parent-relative path"),
            ("alpha-project/framework/tasks/task.md", "markdown", "deep relative path"),
            ("/alpha-project/framework/tasks/task.md", "markdown", "root-relative path"),
            # Dir-like targets (ending in / or \) — TD170 lines 480-481
            ("some-unknown-dir/", "markdown-standalone", "dir-like target ending in /"),
            ("nested/path/subdir/", "markdown", "nested dir-like target"),
        ],
        ids=lambda x: x if isinstance(x, str) and len(x) < 40 else None,
    )
    def test_target_accepted(self, target, link_type, reason):
        """Targets that look like real file/dir paths should be accepted."""
        assert (
            LinkValidator._should_check_target(target, link_type) is True
        ), f"Expected accept for {reason}: {target!r}"


# ---------------------------------------------------------------------------
# Template file filtering (TD170 — line 399)
# ---------------------------------------------------------------------------


class TestTemplateFileFiltering:
    """Tests for skipping standalone links in template files."""

    def test_standalone_link_in_template_file_skipped(self, tmp_path):
        """Standalone paths inside /templates/ directories should be skipped.

        The check is '/templates/' in the relative path, so the templates/
        directory must be nested (e.g. process-framework/templates/...).
        """
        content = "Use the path docs/some-placeholder/guide.md as reference.\n"
        _create_file(
            str(tmp_path), "process-framework/templates/support/example-template.md", content
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/some-placeholder/guide.md" not in targets

    def test_proper_link_in_template_file_still_checked(self, tmp_path):
        """Proper [text](path) links in template files ARE still checked."""
        content = "[link](docs/does-not-exist.md)\n"
        _create_file(
            str(tmp_path), "process-framework/templates/support/example-template.md", content
        )

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/does-not-exist.md" in targets

    def test_non_template_standalone_still_checked(self, tmp_path):
        """Standalone paths in non-template files should still be checked."""
        content = "See docs/nonexistent/missing.md for details.\n"
        _create_file(str(tmp_path), "guides/real-guide.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/nonexistent/missing.md" in targets


# ---------------------------------------------------------------------------
# Placeholder line detection (TD170 — lines 587, 390)
# ---------------------------------------------------------------------------


class TestPlaceholderLines:
    """Tests for _get_placeholder_lines and placeholder line skipping."""

    def test_get_placeholder_lines_detects_replace_with_actual(self):
        """Lines with 'replace with actual' should be detected as placeholders."""
        lines = [
            "# Template",
            "Normal content here.",
            "*(replace with actual link)*",
            "More content.",
            "*(Replace With Actual path here)*",
        ]
        result = LinkValidator._get_placeholder_lines(lines)
        assert 3 in result, "Line 3 contains 'replace with actual'"
        assert 5 in result, "Line 5 contains 'Replace With Actual' (case insensitive)"
        assert 1 not in result
        assert 2 not in result
        assert 4 not in result

    def test_links_on_placeholder_lines_skipped(self, tmp_path):
        """All link types on placeholder lines should be skipped."""
        content = (
            "# Template\n"
            "\n"
            "[real link](docs/does-not-exist.md) *(replace with actual link)*\n"
            "\n"
            "[normal broken](docs/also-missing.md)\n"
        )
        _create_file(str(tmp_path), "source.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/does-not-exist.md" not in targets, "Link on placeholder line should be skipped"
        assert "docs/also-missing.md" in targets, "Normal broken link should be reported"


# ---------------------------------------------------------------------------
# _check_file error handling (TD170 — lines 270-276, 280-286)
# ---------------------------------------------------------------------------


class TestCheckFileErrorHandling:
    """Tests for graceful handling of file read/parse errors."""

    def test_unreadable_file_gracefully_skipped(self, tmp_path):
        """OSError during file read should be caught without crashing."""
        _create_file(str(tmp_path), "source.md", "[link](target.md)\n")
        source_path = os.path.join(str(tmp_path), "source.md")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = ValidationResult()

        # Make file unreadable by removing it after validator init
        os.remove(source_path)
        # Directly call _check_file with a non-existent path
        v._check_file(source_path, result)

        # Should not crash; files_scanned should not increment
        assert result.files_scanned == 0

    def test_parse_exception_gracefully_handled(self, tmp_path, monkeypatch):
        """Parser exceptions during parse_content should be caught."""
        _create_file(str(tmp_path), "source.md", "[link](target.md)\n")
        source_path = os.path.join(str(tmp_path), "source.md")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = ValidationResult()

        # Monkeypatch parser to raise an exception
        def _raise(*args, **kwargs):
            raise RuntimeError("Simulated parse failure")

        monkeypatch.setattr(v.parser, "parse_content", _raise)
        v._check_file(source_path, result)

        # Should not crash; files_scanned should not increment
        assert result.files_scanned == 0


# ---------------------------------------------------------------------------
# _target_exists_at_root anchor stripping (TD170 — lines 647-649)
# ---------------------------------------------------------------------------


class TestTargetExistsAtRootAnchor:
    """Tests for anchor stripping in _target_exists_at_root."""

    def test_root_anchor_stripped_before_check(self, tmp_path):
        """Anchored targets should strip #section before root existence check."""
        _create_file(str(tmp_path), "docs/guide.md", "# Section")

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)

        assert v._target_exists_at_root("docs/guide.md#section") is True

    def test_pure_anchor_at_root_always_valid(self, tmp_path):
        """A pure #anchor target at root level should return True."""
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)

        assert v._target_exists_at_root("#some-section") is True

    def test_root_anchor_missing_file(self, tmp_path):
        """Anchored target with non-existent file at root should return False."""
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)

        assert v._target_exists_at_root("nonexistent/file.md#section") is False


# ---------------------------------------------------------------------------
# _target_exists pure anchor link (TD170 — lines 659-662)
# ---------------------------------------------------------------------------


class TestTargetExistsPureAnchor:
    """Tests for pure anchor link handling in _target_exists."""

    def test_pure_anchor_always_valid(self, tmp_path):
        """A pure #anchor link should be treated as valid (intra-file ref)."""
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        source = os.path.join(str(tmp_path), "source.md")

        assert v._target_exists(source, "#some-section") is True

    def test_anchored_file_ref_resolved(self, tmp_path):
        """A file#anchor target should strip anchor and check file existence."""
        _create_file(str(tmp_path), "docs/guide.md", "# Section")
        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        source = os.path.join(str(tmp_path), "docs", "guide.md")

        assert v._target_exists(source, "guide.md#section") is True


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
        """Markdown links in non-archival details blocks should still be checked."""
        content = (
            "<details>\n"
            "<summary><strong>0. System Architecture</strong></summary>\n"
            "\n"
            "See [Core Architecture](some/nonexistent/path.md) for details.\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "features.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "some/nonexistent/path.md" in targets

    def test_standalone_paths_in_table_rows_skipped(self, tmp_path):
        """Standalone bare paths in table rows are data, not navigable links."""
        content = "| Feature | Path |\n" "| --- | --- |\n" "| Core | some/nonexistent/path.md |\n"
        _create_file(str(tmp_path), "features.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "some/nonexistent/path.md" not in targets

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

    def test_summary_on_next_line_detected(self, tmp_path):
        """<details> with <summary> on the NEXT line should still detect archival."""
        content = (
            "<details>\n"
            "<summary>Show Closed Items</summary>\n"
            "\n"
            "Old refs: some/deleted/path.md mentioned here.\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "tracking.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "some/deleted/path.md" not in targets

    def test_details_without_summary_not_archival(self, tmp_path):
        """<details> followed by non-summary content should not trigger archival."""
        content = (
            "<details>\n"
            "Some direct content without a summary tag.\n"
            "\n"
            "See [link](docs/does-not-exist.md) for details.\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "source.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "docs/does-not-exist.md" in targets

    def test_details_summary_on_same_line(self, tmp_path):
        """<details><summary>archival</summary> on one line should detect archival."""
        content = (
            "<details><summary>Click to expand closed items</summary>\n"
            "\n"
            "Old ref: some/archived/old-path.md mentioned here.\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "tracking.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "some/archived/old-path.md" not in targets

    def test_details_with_empty_lines_then_summary(self, tmp_path):
        """<details> followed by blank lines then <summary> should still work."""
        content = (
            "<details>\n"
            "\n"
            "<summary>View Archived Features</summary>\n"
            "\n"
            "Old path: some/archived/feature.md\n"
            "\n"
            "</details>\n"
        )
        _create_file(str(tmp_path), "features.md", content)

        cfg = _make_config()
        v = LinkValidator(str(tmp_path), cfg)
        result = v.validate()

        targets = {bl.target_path for bl in result.broken_links}
        assert "some/archived/feature.md" not in targets


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

    def test_oserror_reading_ignore_file_handled(self, tmp_path, monkeypatch):
        """OSError when reading .linkwatcher-ignore should be handled gracefully."""
        _create_file(str(tmp_path), "source.md", "[link](missing/doc.md)\n")
        _create_file(str(tmp_path), ".linkwatcher-ignore", "**/*.md -> missing\n")

        cfg = self._cfg_with_ignore()
        v = LinkValidator(str(tmp_path), cfg)

        # Monkeypatch open to raise OSError when reading the ignore file
        real_open = open

        def _raise_on_ignore(path, *args, **kwargs):
            if ".linkwatcher-ignore" in str(path):
                raise OSError("Permission denied")
            return real_open(path, *args, **kwargs)

        monkeypatch.setattr("builtins.open", _raise_on_ignore)
        rules = v._load_ignore_file()
        assert rules == []

    def test_malformed_lines_without_arrow_skipped(self, tmp_path):
        """Lines without ' -> ' separator should be silently ignored."""
        _create_file(str(tmp_path), "source.md", "[link](missing/doc.md)\n")
        _create_file(
            str(tmp_path),
            ".linkwatcher-ignore",
            "this line has no arrow separator\nsource.md -> missing/doc.md\n",
        )
        v = LinkValidator(str(tmp_path), self._cfg_with_ignore())
        result = v.validate()
        # The valid rule should still work despite the malformed line
        targets = {bl.target_path for bl in result.broken_links}
        assert "missing/doc.md" not in targets
