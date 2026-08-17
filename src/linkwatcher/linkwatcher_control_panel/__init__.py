"""
LinkWatcher Control Panel — a desktop supervisor over LinkWatcher daemons.

A single-window Tkinter/ttk application that lists every registered project's
daemon state, starts/stops daemons, tails logs, views/edits per-project config,
triggers link validation, and drains-then-terminates all managed daemons on
close.  It is a *pure supervisor*: it adds no daemon-side contract and manages
daemons entirely through existing external surfaces (lock files, OS process
state, the launcher script, ``--validate``, log files, the per-project config).

Only the lightweight, GUI-free modules are re-exported here so importing
settings/panel-log does not pull in Tkinter.  Import the GUI composition root
explicitly: ``from linkwatcher.linkwatcher_control_panel.app import
ControlPanelApp``.
"""

from .config_edit import (
    ConfigReadResult,
    SaveResult,
    create_default_config,
    read_config,
    save_config,
)
from .discovery import (
    DiscoveryPoller,
    ProcessEntry,
    PsutilProcessTable,
    classify_project,
    load_projects,
    poll_once,
)
from .lifecycle import (
    LifecycleController,
    PsutilTerminator,
    RunResult,
    ShutdownOrchestrator,
    SubprocessRunner,
    cleanup_lock,
    drain_and_terminate,
    newest_log_stat,
    run_launcher,
    watch_quiescence,
)
from .log_tail import LogTail, TailUpdate
from .model import AppModel, DaemonSnapshot, DaemonStatus, ProjectInfo, ValidationRun
from .panel_log import get_panel_logger, setup_panel_log
from .settings import (
    REGISTRY_ENV_VAR,
    LoadedSettings,
    PanelSettings,
    RegistryResolution,
    load_panel_settings,
    resolve_registry_path,
)
from .validation import (
    ValidationController,
    build_validate_command,
    parse_validation_result,
    validator_python,
)

__all__ = [
    "PanelSettings",
    "LoadedSettings",
    "RegistryResolution",
    "load_panel_settings",
    "resolve_registry_path",
    "REGISTRY_ENV_VAR",
    "get_panel_logger",
    "setup_panel_log",
    "AppModel",
    "DaemonSnapshot",
    "DaemonStatus",
    "ProjectInfo",
    "ValidationRun",
    "DiscoveryPoller",
    "ProcessEntry",
    "PsutilProcessTable",
    "classify_project",
    "load_projects",
    "poll_once",
    "LifecycleController",
    "PsutilTerminator",
    "RunResult",
    "ShutdownOrchestrator",
    "SubprocessRunner",
    "cleanup_lock",
    "drain_and_terminate",
    "newest_log_stat",
    "run_launcher",
    "watch_quiescence",
    "LogTail",
    "TailUpdate",
    "ValidationController",
    "build_validate_command",
    "parse_validation_result",
    "validator_python",
    "ConfigReadResult",
    "SaveResult",
    "read_config",
    "save_config",
    "create_default_config",
]
