"""
Config read / validate-on-save / atomic replace for the Configuration pane
(TDD §4.6, KR-05).

AI Context
----------
- **Invalid content never reaches disk** (EC-11/UNIT-C2/C3): the pipeline is
  parse (``yaml.safe_load``, line-numbered errors) → write the candidate bytes
  to a temp file in the *same directory* → construct via the **real**
  ``LinkWatcherConfig.from_file()`` on that temp file and run its
  ``validate()`` → ``os.replace``.  Validating via ``from_file`` on the temp
  means the exact bytes that would be persisted go through the exact code path
  the daemon uses at startup — the no-parallel-validator rule (D-T6) extended
  to the parse itself (checkpoint-approved 2026-08-10).
- **Atomic by construction** (UNIT-C4/C5): the real config is only ever touched
  by ``os.replace``; any block or crash deletes the temp and leaves the
  original byte-identical.  ``replace`` is an injectable seam so the
  interrupted-save case is testable.
- **An empty/comments-only config is valid** — it means "all built-in
  defaults", per the config file's own documented contract (``load_config``
  falls back to defaults for it), so a blank editor saves cleanly.
- **The missing-config state never auto-writes** (EC-10/UNIT-C1): reading a
  missing file reports ``missing`` (the pane offers "Create default config" as
  an explicit action); an unreadable file reports ``error`` with the reason.
- The default skeleton (UNIT-C6) is modeled on the real per-project configs and
  round-trips through ``LinkWatcherConfig.from_file()`` — it is written through
  the same save pipeline as any other content.

Raising contract
----------------
Neither public function raises for any state of the *content* it is given:
``read_config`` returns ``missing``/``error`` and ``save_config`` returns a
blocked ``SaveResult``.  This holds for the two cases that used to escape,
because the exceptions involved are not ``OSError`` subclasses (CR-2 / CR-3):

- a file that is not valid UTF-8 (``UnicodeDecodeError``), and
- a well-formed YAML document with a wrongly typed value, which raises out of
  ``LinkWatcherConfig`` rather than being reported by ``validate()``.

Both are logged to the panel log before being returned, so a refused read or
save always leaves a record.  Callers may therefore bind pane state to the
result, but must still not assume a *successful* return: only ``status == "ok"``
carries text, and only ``SaveResult.ok`` means the file changed.
"""

from __future__ import annotations

import os
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

import yaml

from ..config import LinkWatcherConfig
from .panel_log import get_panel_logger

# What "Create default config" writes: a commented, round-trippable skeleton
# modeled on the real per-project configs (never overwrites an existing file).
DEFAULT_CONFIG_SKELETON = """\
# LinkWatcher per-project config — created by the Control Panel.
#
# Read by the broken-link scan (--validate) AND by the live daemon at startup.
# The daemon reads this file only at startup — restart it to apply changes.
# An absent key (or an empty file) means the built-in default.
#
# NOTE: set-typed keys (e.g. ignored_directories, monitored_extensions)
# REPLACE the built-in default set wholesale — to extend a default set,
# enumerate the full desired set including the defaults you want to keep.
#
# Full key list, defaults, and semantics:
#   <LinkWatcher install>/doc/user/handbooks/configuration-guide.md

# Per-folder resolution base for absolute-from-host ("/...") links during
# --validate (e.g. blueprint folders that ship as a project root elsewhere).
path_resolution_overrides: {}
"""


@dataclass(frozen=True)
class ConfigReadResult:
    """Outcome of :func:`read_config`.

    ``status`` is ``"ok"`` (``text`` set), ``"missing"`` (EC-10 banner with a
    "Create default config" affordance), or ``"error"`` (unreadable — banner
    only, no create offer since the file *exists*).
    """

    status: str
    text: Optional[str] = None
    error: Optional[str] = None


@dataclass(frozen=True)
class SaveResult:
    """Outcome of :func:`save_config`: persisted, or blocked with a reason."""

    ok: bool
    error: Optional[str] = None


def read_config(config_path) -> ConfigReadResult:
    """Load the raw config text for the editor; never raises (EC-10).

    "Never raises" includes a file that is not valid UTF-8: ``read_text`` raises
    ``UnicodeDecodeError`` (a ``ValueError``, *not* an ``OSError``), which used to
    escape this contract entirely and abort the caller mid-load (CR-2).  Such a
    file is reported as ``error`` rather than decoded leniently: the panel would
    have to write the text back on save, and replacement characters would silently
    destroy the bytes it could not decode.
    """
    path = Path(config_path)
    if not path.is_file():
        return ConfigReadResult("missing", error=f"No config file at {path}")
    try:
        return ConfigReadResult("ok", text=path.read_text(encoding="utf-8"))
    except UnicodeDecodeError as exc:
        get_panel_logger().warning(
            "config_read_not_utf8 path=%s byte=%s reason=%s", path, exc.start, exc.reason
        )
        return ConfigReadResult(
            "error",
            error=(
                f"{path} is not valid UTF-8 (byte {exc.start}: {exc.reason}). "
                "Repair the file's encoding outside the panel — editing it here "
                "could not round-trip its contents safely."
            ),
        )
    except OSError as exc:
        get_panel_logger().warning("config_read_failed path=%s error=%s", path, exc)
        return ConfigReadResult("error", error=f"Could not read {path}: {exc}")


def _yaml_error_message(exc: yaml.YAMLError) -> str:
    """A line-numbered, human-readable reason for a YAML parse failure (EC-11)."""
    mark = getattr(exc, "problem_mark", None)
    problem = getattr(exc, "problem", None)
    if mark is not None and problem:
        return f"Line {mark.line + 1}: {problem}"
    return " ".join(str(exc).split())


def save_config(config_path, text: str, *, replace: Callable = os.replace) -> SaveResult:
    """The validate-on-save pipeline (KR-05): block invalid, persist atomically.

    On any block or failure the file on disk is untouched — only a successful
    ``replace`` (the injectable atomic step) ever changes it.
    """
    path = Path(config_path)

    try:
        data = yaml.safe_load(text)
    except yaml.YAMLError as exc:
        return SaveResult(False, _yaml_error_message(exc))
    if data is not None and not isinstance(data, dict):
        return SaveResult(
            False, f"Top level must be a mapping of settings (got {type(data).__name__})"
        )

    fd, temp_path = tempfile.mkstemp(
        dir=str(path.parent), prefix=".lw-config-save-", suffix=".yaml"
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
        if data is not None:
            # The real loader parses the exact bytes to be persisted (D-T6).
            try:
                config = LinkWatcherConfig.from_file(temp_path)
                issues = config.validate()
            except yaml.YAMLError as exc:  # belt-and-braces; safe_load caught it above
                return SaveResult(False, _yaml_error_message(exc))
            except OSError:
                raise  # a real I/O failure on the temp file — the outer handler owns it
            except Exception as exc:
                # Neither `_from_dict` nor `validate()` coerces or type-checks
                # values, so a well-formed YAML document carrying a wrongly typed
                # value raises out of them instead of being reported as an issue —
                # `log_level: 5` reaches `self.log_level.upper()` as an int, and
                # `max_file_size_mb: 'big'` reaches a numeric comparison.  The
                # content is invalid either way, so this refuses the save with an
                # explanation rather than letting the exception escape and take
                # the operator's unsaved edits with it (CR-3 / EC-11 / KR-05).
                # The underlying loader defect belongs to the Configuration
                # System feature and is filed separately.
                get_panel_logger().warning(
                    "config_save_blocked_invalid_value path=%s error_type=%s error=%s",
                    path,
                    type(exc).__name__,
                    exc,
                )
                return SaveResult(
                    False,
                    "A setting has a value of the wrong type, so the configuration "
                    "loader could not check it. Compare your changed keys against "
                    "the documented types in the configuration guide. The loader "
                    f"reported — {type(exc).__name__}: {exc}",
                )
            if issues:
                return SaveResult(False, "; ".join(issues))
        # data is None (empty / comments-only) = "all defaults" — valid by contract.
        replace(temp_path, path)
        return SaveResult(True)
    except OSError as exc:
        return SaveResult(False, f"Save failed: {exc}")
    finally:
        try:
            os.unlink(temp_path)
        except OSError:
            pass  # already replaced (success) or already gone


def create_default_config(config_path) -> SaveResult:
    """Write the commented default skeleton — explicit action, never an overwrite."""
    path = Path(config_path)
    if path.exists():
        return SaveResult(False, f"{path} already exists — not overwriting")
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        return SaveResult(False, f"Could not create {path.parent}: {exc}")
    return save_config(path, DEFAULT_CONFIG_SKELETON)
