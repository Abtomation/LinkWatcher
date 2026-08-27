#!/usr/bin/env python3
"""
Manual validation for PD-BUG-139: a daemon that stops receiving file events
while continuing to report itself healthy.

During E2E case TE-E2E-036 a daemon ran for 34 seconds and logged no file
event at all. A move inside its watched tree went undetected and the
referencing document was left stale. The daemon reported healthy the whole
time and the panel polled it as running.

The mechanism is "alive but not delivering". On Windows the watchdog Observer
is two kinds of thread: one dispatcher, plus one *emitter* per watch that
actually produces events. The pre-fix daemon polled `observer.is_alive()`,
which reports the dispatcher only. Measured against watchdog 6.0.0:

    scenario                observer.is_alive()   emitter   events   stderr
    healthy                 True                  alive     flowing  --
    emitter self-stopped    True                  dead      NONE     nothing
    emitter raised          True                  dead      NONE     traceback

Row 2 is the bug exactly: permanent, silent, and invisible to the only health
check the product had. (watchdog reaches that row on its own: `queue_events`
calls `self.stop()` on an `is_removed_self` event, and `_is_observed_path_deleted`
misreads ANY transient OSError as a deleted watch root because it compares an
NT device path against a DOS path.)

The fix adds two layered checks -- emitter liveness, and an end-to-end delivery
canary that only probes after the tree has gone quiet -- and stops the daemon
loudly rather than letting it run blind.

This validation does NOT need the original incident, which was never reproduced
in three attempts. It kills the emitter directly -- the state the incident
ended up in, however it got there -- and lets you watch the daemon's reaction
with the fix off and on.

How to validate:

  1. python test/bug-validation/PD-BUG-139_blind_watch_detection_validation.py
     Runs both halves back to back on a throwaway project:
       -> "PRE-FIX  (detector disabled)" = the old behaviour. The daemon keeps
          reporting healthy forever after the watch dies. A real move made in
          that window is MISSED and the referencing file is left stale.
       -> "POST-FIX (detector enabled)"  = shipped. The daemon logs an ERROR
          naming the condition and stops.
     Exit 0 only when the pre-fix half really went blind AND the post-fix half
     detected it -- so a run that proves nothing fails loudly.

  2. To observe it yourself against a real daemon, set a short idle window in
     your project config and stop feeding it events:

         watch_liveness_enabled: true
         watch_liveness_idle_seconds: 10
         watch_liveness_probe_timeout: 3
         watch_liveness_failure_threshold: 3

     A healthy daemon stays silent (the probe round-trips). A daemon whose
     watch has died logs `watch_delivery_stalled` and exits.
"""

import shutil
import sys
import tempfile
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "src"))

from linkwatcher.config.settings import LinkWatcherConfig  # noqa: E402
from linkwatcher.service import LinkWatcherService  # noqa: E402


def build_project(root: Path):
    """A minimal project: one document referencing one target."""
    (root / "notes").mkdir(parents=True, exist_ok=True)
    (root / "archive").mkdir(parents=True, exist_ok=True)
    (root / "notes" / "setup.md").write_text("# Setup\n", encoding="utf-8")
    (root / "guide.md").write_text("See [setup](notes/setup.md) for details.\n", encoding="utf-8")


def make_service(root: Path, *, detector_enabled: bool):
    config = LinkWatcherConfig()
    config.watch_liveness_enabled = detector_enabled
    config.watch_liveness_idle_seconds = 2.0
    config.watch_liveness_probe_timeout = 2.0
    config.watch_liveness_failure_threshold = 2
    config.log_file = str(root / "logs" / "linkwatcher" / "LinkWatcherLog.txt")
    # A real daemon has this directory by the time the liveness monitor is
    # built, because logging setup created it at startup.  This harness drives
    # the service directly and never configures file logging, so without this
    # the own-output directory would not exist, the probe would fall back to
    # the project root, and the harness would "verify" a shape no deployment
    # actually has.
    Path(config.log_file).parent.mkdir(parents=True, exist_ok=True)

    service = LinkWatcherService(project_root=str(root), config=config, register_signals=False)
    return service


def kill_the_watch(service):
    """Put the observer into the state the incident ended in.

    The emitter thread is stopped while the observer keeps running -- exactly
    what watchdog does to itself on the `is_removed_self` path.
    """
    for emitter in list(service.observer.emitters):
        emitter.stop()


def run_half(label, *, detector_enabled):
    root = Path(tempfile.mkdtemp(prefix="pd139_validation_"))
    build_project(root)
    service = make_service(root, detector_enabled=detector_enabled)

    print(f"\n=== {label} ===")

    import threading

    thread = threading.Thread(target=service.start, kwargs={"initial_scan": True}, daemon=True)
    thread.start()
    time.sleep(2.0)

    print(f"  daemon running                 : {service.running}")
    print(f"  observer.is_alive()            : {service.observer.is_alive()}")

    kill_the_watch(service)
    print("  --- watch killed (emitter stopped, observer left running) ---")
    time.sleep(0.5)
    print(f"  observer.is_alive() after kill : {service.observer.is_alive()}   <-- still True")

    # A real move, made while the watch is dead.
    (root / "notes" / "setup.md").rename(root / "archive" / "setup.md")
    print("  moved notes/setup.md -> archive/setup.md")

    deadline = time.time() + 12
    while service.running and time.time() < deadline:
        time.sleep(0.25)

    guide = (root / "guide.md").read_text(encoding="utf-8").strip()
    stale = "notes/setup.md" in guide
    # Sample BEFORE teardown: the outcome is what the daemon decided on its
    # own, not what this harness set afterwards.
    still_running = service.running

    print(f"  daemon still running           : {still_running}")
    print(f"  guide.md now reads             : {guide}")
    print(f"  reference left stale           : {stale}")

    service.running = False
    try:
        service.stop()
    except Exception:
        pass
    shutil.rmtree(root, ignore_errors=True)

    return {"still_running": still_running, "stale": stale}


def observe_sentinel_placement():
    """Where the probe file lands, and whether it outlives the daemon.

    The canary writes a real file inside the watched tree, so its location is
    something you can see rather than infer. The first version of this fix put
    it in the ROOT of every watched project and never deleted it: the path
    resolver iterated the own-output exclusion registry (a dict) instead of its
    "dirs" set, so it walked the strings "dirs" and "file_stems", matched
    neither, and fell through to the root fallback every time.

    Watch for two things below: the probe appearing beside the daemon's own log
    rather than in the project root, and the project root staying clean both
    during the run and after shutdown.
    """
    import threading

    root = Path(tempfile.mkdtemp(prefix="pd139_sentinel_"))
    build_project(root)
    service = make_service(root, detector_enabled=True)

    print("\n=== SENTINEL PLACEMENT (probe file location + cleanup) ===")

    thread = threading.Thread(target=service.start, kwargs={"initial_scan": True}, daemon=True)
    thread.start()

    # Wait for the service to REACH its monitoring loop before judging
    # anything.  Sampling `service.running` before the service thread has set
    # it exits every wait loop instantly and reports a probe that simply had
    # not been written yet -- the same harness race that produced a spurious
    # false positive during the original fix.
    startup = time.time() + 15
    while not service.running and time.time() < startup:
        time.sleep(0.1)

    # Wait out the silence gate (2 s here) so the canary actually probes.
    probe = Path(service._liveness_sentinel_path())
    deadline = time.time() + 15
    while not probe.exists() and service.running and time.time() < deadline:
        time.sleep(0.25)

    written = probe.exists()
    in_log_dir = probe.parent.name == "linkwatcher"
    root_litter = sorted(p.name for p in root.glob(".linkwatcher-*"))

    print(f"  probe written                  : {written}")
    print(f"  probe path                     : {probe.relative_to(root)}")
    print(f"  beside the daemon's own log    : {in_log_dir}")
    print(f"  stray dotfiles in project root : {root_litter or 'none'}")

    service.running = False
    try:
        service.stop()
    except Exception:
        pass

    removed = not probe.exists()
    print(f"  probe removed on shutdown      : {removed}")

    shutil.rmtree(root, ignore_errors=True)
    return {"written": written, "in_log_dir": in_log_dir, "removed": removed, "litter": root_litter}


def main():
    print(__doc__.split("How to validate:")[0].strip())

    pre = run_half("PRE-FIX  (detector disabled)", detector_enabled=False)
    post = run_half("POST-FIX (detector enabled)", detector_enabled=True)
    placement = observe_sentinel_placement()

    print("\n" + "=" * 68)
    print("PRE-FIX : daemon kept running blind :", pre["still_running"])
    print("POST-FIX: daemon detected and stopped:", not post["still_running"])
    print("PROBE   : written beside the log     :", placement["in_log_dir"])
    print("PROBE   : removed on shutdown        :", placement["removed"])
    print("PROBE   : project root left clean    :", not placement["litter"])
    print("=" * 68)

    went_blind = pre["still_running"] and pre["stale"]
    detected = not post["still_running"]
    placed_well = (
        placement["written"]
        and placement["in_log_dir"]
        and placement["removed"]
        and not placement["litter"]
    )

    if went_blind and detected and placed_well:
        print("\nPASS - the blind state was reproduced, the fix detected it, and")
        print("the probe stayed in the daemon's own output directory.")
        return 0

    if went_blind and detected and not placed_well:
        if not placement["written"]:
            print("\nINCONCLUSIVE - the canary never probed, so placement was not")
            print("exercised. Detection itself passed.")
            return 2
        print("\nFAIL - detection works, but the probe file is mishandled:")
        print(f"  beside the log : {placement['in_log_dir']}")
        print(f"  removed on stop: {placement['removed']}")
        print(f"  root litter    : {placement['litter'] or 'none'}")
        return 1

    if not went_blind:
        print("\nINCONCLUSIVE - the pre-fix half did not go blind, so this run")
        print("proves nothing about the fix. Investigate before trusting it.")
        return 2

    print("\nFAIL - the daemon stayed blind with the detector enabled.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
