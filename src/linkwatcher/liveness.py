"""Watch-liveness monitoring for the file system observer (PD-BUG-139).

AI Context
----------
- **Problem this solves**: a watchdog ``Observer`` can stay ``is_alive()``
  while delivering no events at all — the dispatcher thread keeps running
  after the per-watch *emitter* thread (the actual event producer on
  Windows) is lost.  The daemon is then permanently blind while reporting
  itself healthy, and every file move is silently missed.

- **Why observer.is_alive() is not enough** (measured, watchdog 6.0.0):

  =========================  ====================  =============  ==========
  scenario                   observer.is_alive()   emitter alive  events
  =========================  ====================  =============  ==========
  healthy                    True                  True           delivered
  emitter self-stopped       True                  False          none
  emitter raised             True                  False          none
  =========================  ====================  =============  ==========

  ``WindowsApiEmitter.queue_events`` calls ``self.stop()`` on a
  ``is_removed_self`` event, and ``EventEmitter.run`` has no exception
  guard — both leave the observer alive and the watch dead.

- **Two layered checks**:
  1. *Emitter liveness* — cheap, precise, fires within one poll.  Catches a
     lost emitter thread and names it.  A dead thread never revives, so this
     is conclusive on the first observation.
  2. *Delivery canary* — the general check.  Verifies events actually arrive
     end-to-end, so it holds no matter which internal path failed, including
     failure modes that leave no fingerprint at all.

- **Probe on suspicion, not on a timer**: a passive "time since last event"
  heartbeat cannot distinguish a quiet repository from a blind daemon.  The
  canary therefore only runs after the tree has been silent for
  ``idle_seconds``, which keeps writes at zero on active repositories while
  bounding detection latency on quiet ones.

- **Reports, does not recover**: a stalled watch is reported and the daemon
  stops cleanly.  A running-but-blind daemon is strictly worse than a
  stopped one because it gives false assurance, and the existing launcher /
  Control Panel restart path is a well-tested recovery route.  In-process
  re-arming is deliberately out of scope until field evidence shows how
  often and under what conditions this fires.

- **The probe is transient, not state** (PD-BUG-145): it only has to exist
  long enough to emit one event, so it is deleted as soon as its round trip
  is decided rather than left on disk between probes.  Persisting it made it
  survivable: the daemon is normally ended by a hard kill (``Stop-Process
  -Force`` from the launcher, ``psutil terminate()`` from the Control Panel),
  which runs no Python shutdown code, so a probe left on disk was stranded
  there — visibly, as an untracked dotfile in the repository root, whenever
  placement falls back to the project root.  Deletion here cannot cover a
  crash *during* a probe; the service sweeps that case at startup.
"""

import time
from pathlib import Path


def _unlink_sentinel(sentinel_path):
    """Default sentinel remover — idempotent, so a missing file is fine."""
    Path(sentinel_path).unlink(missing_ok=True)


class WatchLivenessMonitor:
    """Detects a file system watch that has stopped delivering events.

    Args:
        observer: the watchdog ``Observer`` (or any object exposing
            ``emitters``).
        handler: the event handler exposing the liveness surface
            (``seconds_since_last_event``, ``arm_liveness_probe``,
            ``liveness_probe_observed``).
        logger: structured logger.
        idle_seconds: silence required before a canary probe is run.
        probe_timeout: how long to wait for the sentinel event to arrive.
        failure_threshold: consecutive failed probes before reporting
            unhealthy.  Must be > 1 so one missed probe never stops a daemon.
        sentinel_path: absolute path of the probe file, inside the watched
            tree.
        write_sentinel: callable writing the sentinel (injected for testing).
        remove_sentinel: callable deleting the sentinel once its round trip
            is decided (injected for testing).  Must be idempotent.
        clock / sleep: injected for testing.
        enabled: master switch; when False ``check()`` always reports healthy.
    """

    def __init__(
        self,
        observer,
        handler,
        logger,
        *,
        idle_seconds,
        probe_timeout,
        failure_threshold,
        sentinel_path,
        write_sentinel,
        remove_sentinel=_unlink_sentinel,
        clock=time.monotonic,
        sleep=time.sleep,
        enabled=True,
    ):
        self.observer = observer
        self.handler = handler
        self.logger = logger
        self.idle_seconds = idle_seconds
        self.probe_timeout = probe_timeout
        self.failure_threshold = failure_threshold
        self.sentinel_path = sentinel_path
        self.write_sentinel = write_sentinel
        self.remove_sentinel = remove_sentinel
        self.clock = clock
        self.sleep = sleep
        self.enabled = enabled

        self.consecutive_failures = 0

    def check(self):
        """Run one liveness check.

        Returns:
            bool: True while the watch is believed to be delivering events,
            False once it is established as blind.  A False return means the
            daemon must not keep running: it would report healthy while
            silently losing every update.
        """
        if not self.enabled or self.observer is None:
            return True

        if not self._emitters_are_alive():
            return False

        return self._delivery_is_flowing()

    # -- check 1: emitter threads ------------------------------------------

    def _emitters_are_alive(self):
        emitters = list(getattr(self.observer, "emitters", []) or [])
        dead = [e for e in emitters if not e.is_alive()]

        if emitters and not dead:
            return True

        # Either the emitter set is empty (a self-stopped emitter is removed
        # from delivery entirely) or at least one thread is gone.  Neither
        # state recovers on its own.
        self.logger.error(
            "observer_emitter_died",
            detail=(
                "File system watch is no longer delivering events: the "
                "observer thread is alive but its event emitter is not. "
                "No file moves will be detected until the daemon restarts. "
                "Restart to resume monitoring, then run a link validation "
                "scan (--validate) to find references left stale while the "
                "watch was blind — restarting does not repair those."
            ),
            emitters_registered=len(emitters),
            emitters_dead=len(dead),
        )
        return False

    # -- check 2: end-to-end delivery --------------------------------------

    def _delivery_is_flowing(self):
        idle = self.handler.seconds_since_last_event()
        if idle < self.idle_seconds:
            # Events are arriving; nothing to prove and nothing to write.
            self.consecutive_failures = 0
            return True

        if self._probe_round_trips():
            self.consecutive_failures = 0
            return True

        self.consecutive_failures += 1
        if self.consecutive_failures < self.failure_threshold:
            self.logger.warning(
                "watch_liveness_probe_failed",
                detail="Liveness probe was not observed; retrying before acting.",
                consecutive_failures=self.consecutive_failures,
                failure_threshold=self.failure_threshold,
                idle_seconds=round(idle, 1),
            )
            return True

        self.logger.error(
            "watch_delivery_stalled",
            detail=(
                "File system watch has stopped delivering events: "
                f"{self.consecutive_failures} consecutive liveness probes were "
                "never observed. No file moves are being detected. "
                "Restart the daemon to restore link maintenance, then run a "
                "link validation scan (--validate) to find references left "
                "stale while the watch was blind — restarting does not "
                "repair those."
            ),
            consecutive_failures=self.consecutive_failures,
            idle_seconds=round(idle, 1),
        )
        return False

    def _probe_round_trips(self):
        """Write the sentinel and wait for its event to come back."""
        self.handler.arm_liveness_probe(self.sentinel_path)

        try:
            self.write_sentinel(self.sentinel_path)
        except OSError as e:
            # A probe we could not write proves nothing about delivery, so it
            # must not be counted as a delivery failure.
            self.logger.warning(
                "watch_liveness_probe_unwritable",
                error=str(e),
                path=self.sentinel_path,
            )
            return True

        try:
            deadline = self.clock() + self.probe_timeout
            while self.clock() < deadline:
                if self.handler.liveness_probe_observed():
                    return True
                self.sleep(0.05)

            return self.handler.liveness_probe_observed()
        finally:
            self._discard_sentinel()

    def _discard_sentinel(self):
        """Delete the probe now that its round trip is decided (PD-BUG-145).

        The sentinel is scaffolding, not state: keeping it on disk between
        probes bought nothing and made it strandable by the hard kills that
        normally end this daemon.  Deleting it here also makes every probe a
        create rather than a truncating rewrite.

        Best-effort by design — a probe that round-tripped has already proved
        the watch is alive, and failing to delete the file afterwards says
        nothing about delivery, so an error here must never change the
        verdict.  The delete event this emits is consumed by the still-armed
        ``handler.dispatch`` and never reaches the parser or link database.
        """
        try:
            self.remove_sentinel(self.sentinel_path)
        except OSError as e:
            self.logger.debug(
                "liveness_sentinel_discard_failed",
                error=str(e),
                path=self.sentinel_path,
            )
