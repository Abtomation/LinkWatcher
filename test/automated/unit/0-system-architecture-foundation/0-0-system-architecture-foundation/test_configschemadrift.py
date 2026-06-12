"""
Document Metadata:
ID: TE-TST-136
Type: Test File
Category: Test
Version: 1.0
Created: 2026-06-10
Updated: 2026-06-10
Feature Id: 0.1.3
Test Name: ConfigSchemaDrift
Component Name: ConfigSchemaDrift
Test Type: unit
Language: Python

Config-schema drift guard.

LinkWatcherConfig (src/linkwatcher/config/settings.py) is the source of truth
for the config schema. Two documentation surfaces must stay in sync with it:

1. The "Full Reference" YAML block in doc/user/handbooks/configuration-guide.md
   presents itself as the complete list of settings and their defaults —
   asserted as full key equality plus scalar-default value equality.
2. The WIP template config-examples/linkwatcher-config.yaml carries only the
   curated *project-configurable* subset (which keys belong there is a human
   decision, see doc/ci-cd/release-process.md "Config-Schema Propagation") —
   asserted one-way: every template key must be a real config field.

Failing assertions name the exact drifted keys. Quick-reference and
capabilities-reference handbooks are intentionally partial and not tested.
"""

import dataclasses
import re
from pathlib import Path

import pytest
import yaml

from linkwatcher.config import LinkWatcherConfig

pytestmark = [
    pytest.mark.feature("0.1.3"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-0-1-3-configuration-system.md"
    ),
]

PROJECT_ROOT = Path(__file__).resolve().parents[5]
GUIDE_PATH = PROJECT_ROOT / "doc" / "user" / "handbooks" / "configuration-guide.md"
TEMPLATE_PATH = PROJECT_ROOT / "config-examples" / "linkwatcher-config.yaml"

# Keys legitimately present in the guide's Full Reference but absent from
# LinkWatcherConfig. Empty today — add entries here with a justifying comment
# instead of weakening the assertions.
GUIDE_KEY_ALLOWLIST: set = set()

# Defaults are value-compared for these types only; set/dict/list defaults in
# the guide are illustrative and compared by key presence alone.
SCALAR_TYPES = (bool, int, float, str)


def code_fields():
    """LinkWatcherConfig fields keyed by name — the schema source of truth."""
    return {f.name: f for f in dataclasses.fields(LinkWatcherConfig)}


def load_full_reference():
    """Parse the fenced YAML block under 'Full Reference' in the config guide."""
    text = GUIDE_PATH.read_text(encoding="utf-8")
    match = re.search(r"### Full Reference.*?```yaml\r?\n(.*?)```", text, re.DOTALL)
    assert match, (
        "configuration-guide.md: could not locate the fenced yaml block under the "
        "'Full Reference' heading — if the guide was restructured, update this test"
    )
    data = yaml.safe_load(match.group(1))
    assert isinstance(data, dict) and len(data) >= 20, (
        "configuration-guide.md: Full Reference block parsed to "
        f"{type(data).__name__} with {len(data) if isinstance(data, dict) else 0} "
        "keys — expected the complete schema; the block may have been split or emptied"
    )
    return data


def load_template():
    """Parse the WIP per-project validation config template."""
    data = yaml.safe_load(TEMPLATE_PATH.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else {}


class TestConfigSchemaDrift:
    """Drift assertions between LinkWatcherConfig and its documentation surfaces."""

    def test_guide_full_reference_contains_every_config_field(self):
        missing = set(code_fields()) - set(load_full_reference())
        assert not missing, (
            "Config fields missing from configuration-guide.md Full Reference: "
            f"{sorted(missing)}"
        )

    def test_guide_full_reference_has_no_stale_keys(self):
        stale = set(load_full_reference()) - set(code_fields()) - GUIDE_KEY_ALLOWLIST
        assert not stale, (
            "configuration-guide.md Full Reference documents keys that are not "
            f"LinkWatcherConfig fields (renamed/removed?): {sorted(stale)}"
        )

    def test_guide_full_reference_scalar_defaults_match(self):
        guide = load_full_reference()
        mismatches = []
        for name, field in code_fields().items():
            default = field.default
            if default is dataclasses.MISSING:
                continue  # factory defaults (sets/dicts) are illustrative in the guide
            if default is not None and not isinstance(default, SCALAR_TYPES):
                continue
            if name in guide and guide[name] != default:
                mismatches.append(f"{name}: guide={guide[name]!r} code={default!r}")
        assert (
            not mismatches
        ), "configuration-guide.md Full Reference shows stale defaults:\n  " + "\n  ".join(
            mismatches
        )

    def test_guide_ignored_directories_values_match_code_default(self):
        """Regression guard for PD-BUG-103: the guide's ignored_directories list
        drifted from the code default; key-presence checks alone missed it.
        Set equality flags both stale extras and omitted entries."""
        guide_value = set(load_full_reference()["ignored_directories"])
        code_value = LinkWatcherConfig().ignored_directories
        assert guide_value == code_value, (
            "configuration-guide.md Full Reference ignored_directories drifted from "
            f"LinkWatcherConfig default — only in guide: {sorted(guide_value - code_value)}, "
            f"only in code: {sorted(code_value - guide_value)}"
        )

    def test_guide_monitored_extensions_values_match_code_default(self):
        """Companion to the ignored_directories guard (PD-BUG-103): the guide's
        Full Reference lists the complete monitored_extensions default, so its
        values must match the code default exactly."""
        guide_value = set(load_full_reference()["monitored_extensions"])
        code_value = LinkWatcherConfig().monitored_extensions
        assert guide_value == code_value, (
            "configuration-guide.md Full Reference monitored_extensions drifted from "
            f"LinkWatcherConfig default — only in guide: {sorted(guide_value - code_value)}, "
            f"only in code: {sorted(code_value - guide_value)}"
        )

    def test_wip_template_keys_are_valid_config_fields(self):
        stale = set(load_template()) - set(code_fields())
        assert not stale, (
            "config-examples/linkwatcher-config.yaml contains keys that are not "
            f"LinkWatcherConfig fields (renamed/removed?): {sorted(stale)}"
        )

    def test_drift_detection_catches_a_removed_key(self):
        """Negative self-check on doctored data — never on the real files."""
        doctored = dict(load_full_reference())
        doctored.pop("monitored_extensions", None)
        assert "monitored_extensions" in set(code_fields()) - set(doctored), (
            "drift-detection mechanism failed to flag a key removed from a "
            "doctored copy of the guide"
        )
