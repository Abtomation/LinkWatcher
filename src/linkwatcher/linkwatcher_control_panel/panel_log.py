"""
Panel self-diagnostic log for the LinkWatcher Control Panel.

The panel *is* the monitoring surface for the daemons, so its own diagnostics go
to a separate small rotating file — ``<install_dir>/logs/panel.log`` — kept off
the daemon's structured logger.  It records the operationally important events
(forced terminations, start/validation failures, caught worker exceptions) so
panel misbehavior is diagnosable without a console, including under the detached
``pythonw.exe`` hook launch where there is no stdout/stderr at all.

AI Context
----------
- **Module home rationale**: this lives in its own module (not ``app.py``) so
  every worker module (``discovery``, ``lifecycle``, ``validation``,
  ``config_edit``) can obtain the logger via :func:`get_panel_logger` without
  importing ``app.py`` — which imports *them* — avoiding an import cycle.  The
  TDD (PD-TDD-033 §3.3) mandates a panel log but leaves its module home open;
  this is the minor structural choice recorded in the feature state file.
- **Entry points**: :func:`setup_panel_log` (call once at startup) and
  :func:`get_panel_logger` (call anywhere to log).
"""

import logging
import logging.handlers
import sys
from pathlib import Path
from typing import Optional

PANEL_LOGGER_NAME = "linkwatcher.panel"
PANEL_LOG_FILENAME = "panel.log"

# A diagnostic log stays small — 1 MB with a few rotated backups is ample.
_DEFAULT_MAX_BYTES = 1 * 1024 * 1024
_DEFAULT_BACKUP_COUNT = 3

_LOG_FORMAT = "%(asctime)s [%(levelname)s] %(name)s: %(message)s"


def get_panel_logger() -> logging.Logger:
    """Return the shared panel logger.

    Safe to call before :func:`setup_panel_log`: an unconfigured logger simply
    has no handlers yet (records are dropped rather than raising).
    """
    return logging.getLogger(PANEL_LOGGER_NAME)


def setup_panel_log(
    install_dir, *, level: int = logging.INFO, to_console: Optional[bool] = None
) -> logging.Logger:
    """Configure the panel logger to write to ``<install_dir>/logs/panel.log``.

    Idempotent — re-invocation closes and replaces existing handlers, so repeated
    setup (notably in tests) neither stacks handlers nor leaks Windows file
    locks.  Never raises on a filesystem problem: a failed file handler degrades
    to console-only (or silence under ``pythonw``) so the panel still starts.

    ``to_console`` defaults to mirroring warnings to stderr when a real stderr
    exists (dev runs); it is skipped under the console-less ``pythonw`` launch.
    """
    logger = logging.getLogger(PANEL_LOGGER_NAME)
    logger.setLevel(level)
    # Keep panel diagnostics off the root/daemon logger.
    logger.propagate = False

    # Idempotent re-setup: drop and close any handlers from a prior call.
    for handler in logger.handlers[:]:
        handler.close()
        logger.removeHandler(handler)

    formatter = logging.Formatter(_LOG_FORMAT)

    log_dir = Path(install_dir) / "logs"
    try:
        log_dir.mkdir(parents=True, exist_ok=True)
        file_handler = logging.handlers.RotatingFileHandler(
            log_dir / PANEL_LOG_FILENAME,
            maxBytes=_DEFAULT_MAX_BYTES,
            backupCount=_DEFAULT_BACKUP_COUNT,
            encoding="utf-8",
        )
        file_handler.setFormatter(formatter)
        file_handler.setLevel(logging.DEBUG)  # everything to the file
        logger.addHandler(file_handler)
    except OSError as exc:  # pragma: no cover - filesystem edge case
        # A log-file problem must never stop the panel from launching.
        logging.getLogger(__name__).warning("panel_log_file_unavailable: %s", exc)

    if to_console is None:
        to_console = sys.stderr is not None
    if to_console and sys.stderr is not None:
        stream_handler = logging.StreamHandler(sys.stderr)
        stream_handler.setFormatter(formatter)
        stream_handler.setLevel(logging.WARNING)
        logger.addHandler(stream_handler)

    return logger
