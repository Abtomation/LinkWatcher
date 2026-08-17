#!/usr/bin/env python3
"""
LinkWatcher Control Panel — desktop supervisor for LinkWatcher daemons.

Thin entry script beside ``main.py`` (mirrors the deployed flat install layout).
It resolves the install directory, enforces the single-instance rule, loads
panel settings, locates the central project registry, wires the panel log, and
launches the GUI.

Only one panel exists at a time: a second launch (manual or hook auto-open)
hands a surface request to the running window over the loopback channel and
exits without building a window (see ...control_panel.single_instance).

Usage:
    python control_panel.py [--registry PATH] [--project-root DIR] [--debug]

Registry resolution order (see linkwatcher.linkwatcher_control_panel.settings):
    --registry  →  LINKWATCHER_PROJECT_REGISTRY env  →  panel-config.yaml key
      →  .framework-central-pointer discovery (--project-root, then cwd walk-up)
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
    from linkwatcher.linkwatcher_control_panel.app import ControlPanelApp
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
        help="Path to the central project-registry.json (highest-precedence source).",
    )
    parser.add_argument(
        "--project-root",
        help=(
            "A registered project root; the panel discovers the central registry "
            "from its process-framework/.framework-central-pointer. The hook "
            "wrapper passes this when it auto-opens the panel."
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
    # Route surface requests from the listener thread onto the UI thread.
    guard.on_surface = lambda: app.post(app.surface)
    try:
        app.run()
    finally:
        guard.release()


if __name__ == "__main__":
    main()
