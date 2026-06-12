"""Unit tests for the release-time git-tag guard logic.

Covers the decision/parse helpers in ``deployment/install_global.py`` (PF-IMP-1106).
The guard warns at deploy time when the version being installed has no matching
``v<version>`` git tag. The actual git invocation and the print side effect are not
exercised here — only the pure decision (``release_tag_missing``) and the
version parser (``read_deployed_version``). The load-bearing case is that an
undeterminable state (unknown version, or git unavailable) must NOT warn.
"""

import sys
from pathlib import Path

import pytest

# deployment/ is not a package on sys.path — add it so the module imports by name.
_DEPLOYMENT_DIR = Path(__file__).resolve().parents[3] / "deployment"
sys.path.insert(0, str(_DEPLOYMENT_DIR))

import install_global as ig  # noqa: E402

# --- release_tag_missing: the pure warn/no-warn decision ---


def test_missing_when_version_known_and_tag_absent():
    assert ig.release_tag_missing("2.1.1", {"v2.0.1", "v2.1.0"}) is True


def test_not_missing_when_tag_present():
    assert ig.release_tag_missing("2.1.1", {"v2.1.0", "v2.1.1"}) is False


def test_not_missing_when_version_unknown():
    # Cannot determine — must not warn.
    assert ig.release_tag_missing(None, {"v2.1.0"}) is False
    assert ig.release_tag_missing("", {"v2.1.0"}) is False


def test_not_missing_when_tags_unavailable():
    # git unavailable / not a repo (tags is None) — must not warn.
    assert ig.release_tag_missing("2.1.1", None) is False


def test_not_missing_against_empty_tag_set_is_still_missing():
    # Known version, known (empty) tag set → the tag is genuinely absent.
    assert ig.release_tag_missing("2.1.1", set()) is True


# --- read_deployed_version: parse __version__ from a linkwatcher __init__.py ---


def _write_init(tmp_path, body):
    p = tmp_path / "__init__.py"
    p.write_text(body, encoding="utf-8")
    return p


def test_read_version_double_quotes(tmp_path):
    p = _write_init(tmp_path, '"""pkg"""\n__version__ = "2.1.1"\n')
    assert ig.read_deployed_version(p) == "2.1.1"


def test_read_version_single_quotes(tmp_path):
    p = _write_init(tmp_path, "__version__ = '3.0.0'\n")
    assert ig.read_deployed_version(p) == "3.0.0"


def test_read_version_absent_returns_none(tmp_path):
    p = _write_init(tmp_path, "# no version here\nfoo = 1\n")
    assert ig.read_deployed_version(p) is None


def test_read_version_missing_file_returns_none(tmp_path):
    assert ig.read_deployed_version(tmp_path / "does-not-exist.py") is None


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))
