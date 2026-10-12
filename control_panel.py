#!/usr/bin/env python3
"""
LinkWatcher Control Panel — desktop supervisor for LinkWatcher daemons.

Thin entry script beside ``main.py`` (mirrors the deployed flat install layout).
It resolves the install directory, wires the panel log, enforces the
single-instance rule, loads panel settings, locates the child registry to
supervise from, and launches the GUI — in that order, so that everything after
the log is wired is diagnosable from ``panel.log``.

Only one panel exists at a time: a second launch (manual or hook auto-open)
hands a surface request to the running window over the loopback channel and
exits without building a window (see ...control_panel.single_instance).

Usage:
    python control_panel.py [--registry PATH] [--project-root DIR] [--debug]

Registry resolution order (see linkwatcher.linkwatcher_control_panel.settings):
    --registry  →  LINKWATCHER_PROJECT_REGISTRY env  →  panel-config.yaml key
      →  the child registry the workspace root owns (--project-root, else the
         current directory taken exactly)
      →  parent-pointer discovery (--project-root, then cwd walk-up)
      →  error state (panel opens with a "registry not found" banner).
"""

import argparse
import logging
import sys
from pathlib import Path

# Mirror main.py: put the install directory on the path so the flat deployed
# layout (control_panel.py beside the linkwatcher/ package) imports cleanly.
# In the dev repo the package is resolved via the editable install.
sys.path.insert(0, str(Path(__file__).parent))

try:
    from linkwatcher.linkwatcher_control_panel.app import ControlPanelApp, make_surface_hook
    from linkwatcher.linkwatcher_control_panel.panel_log import setup_panel_log
    from linkwatcher.linkwatcher_control_panel.settings import (
        load_panel_settings,
        resolve_registry_path,
    )
    from linkwatcher.linkwatcher_control_panel.single_instance import SingleInstanceGuard
except ImportError as exc:  # pragma: no cover - dependency/setup failure path
    print(f"Missing required dependency: {exc}")
    print("Please install dependencies with: pip install -e .")
    sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="LinkWatcher Control Panel — supervise LinkWatcher daemons.",
    )
    parser.add_argument(
        "--registry",
        help="Path to a child registry file (highest-precedence source).",
    )
    parser.add_argument(
        "--project-root",
        help=(
            "A workspace root; the panel supervises from the child registry that "
            "workspace owns, or — for a leaf project, which owns none — from the "
            "one its parent owns, found via the parent-pointer in its framework "
            "face. Defaults to the current directory, so a launch from the "
            "workspace root needs no argument. The hook wrapper passes it "
            "explicitly when it auto-opens the panel."
        ),
    )
    parser.add_argument("--debug", action="store_true", help="Verbose (DEBUG) panel logging.")
    args = parser.parse_args()

    install_dir = Path(__file__).parent
    level = logging.DEBUG if args.debug else logging.INFO
    log = setup_panel_log(install_dir, level=level)

    # Single instance (KR-04): a second launch surfaces the open window and
    # exits here, before any Tk widget is built (EC-9/AC-11).
    guard = SingleInstanceGuard(install_dir)
    instance = guard.acquire()
    if instance.already_running:
        print(instance.message)
        return
    if instance.warning:
        log.warning(instance.warning)

    loaded = load_panel_settings(install_dir)
    for warning in loaded.warnings:
        log.warning(warning)

    project_root = Path(args.project_root) if args.project_root else None
    registry = resolve_registry_path(
        args.registry, settings=loaded.settings, project_root=project_root
    )
    if registry.resolved:
        log.info("registry resolved via %s: %s", registry.source, registry.path)
    else:
        log.warning("registry unresolved: %s", registry.error)

    app = ControlPanelApp(loaded.settings, registry, install_dir)
    # Route surface requests from the listener thread onto the UI thread, and
    # report back only once the raise has actually run there (PD-BUG-157).
    # The hook is built by a factory in app.py so the contract is testable at
    # the site that implements it (TD312).
    guard.on_surface = make_surface_hook(app)
    # Drop the single-instance claim as soon as the panel commits to exiting,
    # rather than only in the finally below — that runs after the whole
    # drain-then-terminate shutdown, during which the listener would otherwise
    # keep telling launches a window exists that is about to be destroyed
    # (PD-BUG-160).  release() is idempotent and only ever deletes a port file
    # it still owns, so the finally remains correct and a successor that has
    # already taken over is left alone.
    app.on_shutdown_begin = guard.release
    try:
        app.run()
    finally:
        guard.release()


if __name__ == "__main__":
    main()
