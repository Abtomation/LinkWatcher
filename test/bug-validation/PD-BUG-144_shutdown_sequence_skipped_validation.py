"""Manual validation for PD-BUG-144 — the service shutdown sequence is skipped
on every self-stop and signal shutdown.

WHAT THE BUG IS
---------------
``LinkWatcherService.stop()`` guarded its whole body with ``if self.running``.
Every path that reaches ``stop()`` has already cleared that flag: the monitoring
loop sets ``running = False`` when the watch fails its liveness check
(PD-BUG-139) or when the observer thread dies (PD-BUG-018), and
``_signal_handler`` sets it on SIGINT/SIGTERM. ``start()``'s ``finally`` then
calls ``stop()``, the guard is already False, and nothing runs — the observer is
never stopped or joined, the final statistics are never printed, and neither
``service_stopping`` nor ``service_stopped`` reaches the log.

WHY IT MATTERS MORE THAN "LOST STATISTICS"
------------------------------------------
It partially defeats PD-BUG-139. That fix exists so a daemon which has gone
blind stops LOUDLY, because the operator then has to run a validation scan to
find the references that went stale while it was blind. With this defect the
log ends at ``observer_emitter_died`` with no shutdown record, so a completed
clean stop looks exactly like a crash mid-work.

It also violates two stated requirements of feature 0.1.1: FR-5 ("graceful
shutdown ... stopping the file observer thread cleanly") and FR-6 ("SHALL
report operational statistics upon shutdown"), and falsifies AC-4 and AC-7,
both of which the FDD records as met.

WHAT IS *NOT* AFFECTED
----------------------
Anything that hard-kills the process, because then ``stop()`` never runs at
all: the Control Panel (``TerminateProcess``), ``stop_linkwatcher.ps1``
(``Stop-Process -Force``), and the E2E harness. That is why this belongs to
WF-008 (Ctrl+C, self-stop) and not WF-010.

HOW THE FIX ANSWERS IT
----------------------
Idempotence moves off the mutable ``running`` flag onto dedicated lifecycle
flags: ``_started`` (set once the observer thread is actually running) and
``_stopped`` (set on the first real shutdown). ``running`` keeps its own job —
"should the monitoring loop keep looping" — and is no longer overloaded as
"has shutdown already happened".

``_started`` is not belt-and-braces. ``start()`` builds the observer, schedules
it, and only then starts it, calling ``stop()`` from its ``finally`` whatever
happens. If scheduling raises, the observer object exists but its thread never
started, and ``join()`` on an unstarted thread raises ``RuntimeError`` — which
would mask the original failure. Guarding on ``self.observer`` being set would
reintroduce exactly that.

HOW TO RUN
----------
    python test/bug-validation/PD-BUG-144_shutdown_sequence_skipped_validation.py

Part 1 runs automatically: it starts a real service in a temp project, delivers
the same SIGINT the OS delivers on Ctrl+C, and reports whether the shutdown
sequence ran. Part 2 asks you to press Ctrl+C yourself in a real console, which
is the form a user actually meets.
"""

import shutil
import signal
import sys
import tempfile
import threading
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

SHUTDOWN_MARKERS = ("service_stopping", "file_observer_stopped", "service_stopped")


def _banner(text):
    print()
    print("=" * 72)
    print(text)
    print("=" * 72)


def _make_project():
    root = Path(tempfile.mkdtemp(prefix="pd_bug_144_"))
    (root / "readme.md").write_text("See [the guide](docs/guide.md).\n", encoding="utf-8")
    (root / "docs").mkdir()
    (root / "docs" / "guide.md").write_text("# Guide\n", encoding="utf-8")
    return root


def part1_in_process():
    _banner("PART 1 — deliver SIGINT to a real service and watch what shuts down")

    from linkwatcher.service import LinkWatcherService

    project = _make_project()
    print(f"Temp project: {project}")

    records = []

    class Recorder:
        """Wraps the real logger so we can see which shutdown records appear."""

        def __init__(self, inner):
            self._inner = inner

        def __getattr__(self, name):
            attr = getattr(self._inner, name)
            if name in ("info", "debug", "warning", "error"):

                def capture(event, *args, **kwargs):
                    records.append(event)
                    return attr(event, *args, **kwargs)

                return capture
            return attr

    service = LinkWatcherService(str(project), register_signals=False)
    service.logger = Recorder(service.logger)

    loop = threading.Thread(target=lambda: service.start(initial_scan=False), daemon=True)
    loop.start()

    deadline = time.time() + 20
    while time.time() < deadline and not service.running:
        time.sleep(0.05)
    if not service.running:
        print("  !! service never reached its monitoring loop — cannot validate")
        shutil.rmtree(project, ignore_errors=True)
        return

    print("  Service is monitoring. Delivering SIGINT (what Ctrl+C invokes)...")
    service._signal_handler(signal.SIGINT, None)
    loop.join(timeout=20)

    observer_alive = service.observer.is_alive()

    print()
    print("  RESULT")
    print(f"    start() returned .................. {not loop.is_alive()}")
    print(f"    observer thread still alive ....... {observer_alive}   <-- want False")
    for marker in SHUTDOWN_MARKERS:
        print(f"    logged {marker:<25} {marker in records}   <-- want True")

    print()
    if observer_alive or not all(m in records for m in SHUTDOWN_MARKERS):
        print("  >> BUG PRESENT: the shutdown sequence did not run.")
        print("     The observer was left running and/or no shutdown record was")
        print("     written. An operator reading this log cannot tell a clean")
        print("     stop from a crash.")
    else:
        print("  >> FIXED: observer stopped and joined, and every shutdown record")
        print("     was written, on a path that clears `running` before stop().")

    shutil.rmtree(project, ignore_errors=True)


def part2_real_console():
    _banner("PART 2 — press Ctrl+C yourself (the form a user actually meets)")

    project = _make_project()
    print("A temp project has been created for you:")
    print(f"    {project}")
    print()
    print("Run LinkWatcher in the FOREGROUND, in your own console:")
    print()
    print(f'    python "{REPO_ROOT / "main.py"}" --project-root "{project}"')
    print()
    print("Wait for the startup banner and 'monitoring_started', then press Ctrl+C.")
    print()
    print("WHAT TO LOOK FOR, in the console output after you press Ctrl+C:")
    print()
    print("  BEFORE the fix — the output simply stops. You see the")
    print("  'shutdown_signal_received' line and then nothing: no statistics")
    print("  block, no 'service_stopped'. The process exits, but it never says")
    print("  goodbye, so a clean stop is indistinguishable from a crash.")
    print()
    print("  AFTER the fix — you see the full sequence: 'service_stopping', the")
    print("  final statistics (files scanned, links found, updates performed —")
    print("  0.1.1-FR-6), and 'service_stopped'.")
    print()
    print("Delete the temp project when you are done:")
    print(f'    Remove-Item -Recurse -Force "{project}"')


if __name__ == "__main__":
    part1_in_process()
    part2_real_console()
    print()
