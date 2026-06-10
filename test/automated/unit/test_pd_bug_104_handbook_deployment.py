"""
Document Metadata:
ID: TE-TST-137
Type: Test File
Category: Test
Version: 1.0
Created: 2026-06-10
Updated: 2026-06-10
Test Name: PD-BUG-104 Handbook Deployment
Component Name: InstallGlobal
Feature Id: 0.1.1
Language: Python
Test Type: Unit
"""

# PD-BUG-104: Global install omits user handbooks — the per-project config
# template's pointer (<install>/doc/user/handbooks/configuration-guide.md)
# is dead on every deployed machine because doc/user/handbooks/ has no
# entry in install_global.py's deployment manifest.
#
# The handbooks must deploy structure-preserving (doc/user/handbooks/, NOT a
# flat docs/) so that (a) the existing config-template pointer resolves as-is
# and (b) the handbooks' absolute-from-root cross-links
# (e.g. /doc/user/handbooks/quick-reference.md) stay resolvable against the
# install root.
#
# Test File ID: TE-TST-137
# Created: 2026-06-10

import sys
from pathlib import Path

import pytest

# deployment/ is not a package on sys.path — add it so the module imports by name.
_PROJECT_ROOT = Path(__file__).resolve().parents[3]
_DEPLOYMENT_DIR = _PROJECT_ROOT / "deployment"
sys.path.insert(0, str(_DEPLOYMENT_DIR))

import install_global  # noqa: E402

HANDBOOKS_SOURCE = "doc/user/handbooks"

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
]


class TestHandbookDeploymentManifest:
    """Manifest-level guards on install_global's CORE_DIRS constant."""

    def test_core_dirs_includes_handbooks_structure_preserving(self):
        """The handbooks deploy with their repo-relative structure preserved."""
        core_dirs = getattr(install_global, "CORE_DIRS", ())
        assert (HANDBOOKS_SOURCE, HANDBOOKS_SOURCE) in core_dirs

    def test_core_dirs_handbooks_not_flattened(self):
        """Negative guard: a flat destination (e.g. 'docs') would leave the
        config-template pointer <install>/doc/user/handbooks/... dead and break
        the handbooks' absolute-from-root cross-links."""
        core_dirs = getattr(install_global, "CORE_DIRS", ())
        handbook_dests = [dest for src, dest in core_dirs if src == HANDBOOKS_SOURCE]
        assert handbook_dests == [HANDBOOKS_SOURCE]

    def test_core_dirs_sources_exist_in_repo(self):
        """Every manifest source directory must exist — catches manifest drift."""
        core_dirs = getattr(install_global, "CORE_DIRS", ())
        assert core_dirs, "CORE_DIRS module constant missing or empty"
        for src, _dest in core_dirs:
            assert (_PROJECT_ROOT / src).is_dir(), f"manifest source missing: {src}"


class TestHandbookDeploymentCopy:
    """End-to-end copy behavior of install_linkwatcher() into a temp install dir."""

    def test_install_copies_all_handbooks(self, tmp_path):
        """install_linkwatcher() must deliver every source handbook to
        <install>/doc/user/handbooks/, including the configuration guide the
        per-project config template points at."""
        install_dir = tmp_path / "global-install"

        result = install_global.install_linkwatcher(_PROJECT_ROOT, install_dir)
        assert result is True

        deployed_dir = install_dir / "doc" / "user" / "handbooks"
        assert deployed_dir.is_dir(), "doc/user/handbooks/ missing from install"

        source_handbooks = {p.name for p in (_PROJECT_ROOT / HANDBOOKS_SOURCE).glob("*.md")}
        deployed_handbooks = {p.name for p in deployed_dir.glob("*.md")}
        assert deployed_handbooks == source_handbooks

        # The exact file the per-project config template pointer references.
        assert (deployed_dir / "configuration-guide.md").is_file()
