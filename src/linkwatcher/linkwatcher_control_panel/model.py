"""
Observable application state for the LinkWatcher Control Panel.

The panel renders from exactly one place — the :class:`AppModel` — in a one-way
data flow (PD-UIX-003 §10.2, TDD §4.3).  Worker threads never touch the model or
Tk directly: they post callbacks onto the app's dispatcher queue, which applies
them on the UI thread.  The model is therefore **not** thread-safe by design and
must only ever be mutated from the UI thread.

AI Context
----------
- **Two layers of truth**:
  - *Poll truth* — what :mod:`.discovery` last observed of external reality
    (registry + lock files + the OS process table).  Authoritative for
    RUNNING / STOPPED / STALE_LOCK.
  - *Pins* — panel-initiated transitional states (STARTING, DRAINING) and
    surfaced outcomes (FORCE_STOPPED, START_FAILED) claimed by the action worker
    that owns them.  A pin **overrides** poll truth so a slow poll cannot flicker
    a starting daemon back to "Stopped" (truthful-state rule, FDD FR-4).
- **A pin can never freeze a row.** Every pin carries a deadline; once the clock
  reaches it the pin is dropped and poll truth wins again — so a hung or crashed
  worker degrades to reality instead of a permanently stuck row (TDD §4.3).
  Transitional pins additionally resolve *early* when the poll observes their
  destination state (STARTING → RUNNING, DRAINING → exited).
- **Notification contract**: subscribers are called only when the *effective*
  rendered state actually changes.  Re-applying an identical poll, or setting a
  flag to the value it already has, notifies nobody.
- **Testability seam**: ``clock`` (a monotonic time source) is injectable, so pin
  expiry is exercised with a fake clock and no real waiting.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, replace
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Callable, Dict, List, Optional, Sequence, Tuple


class DaemonStatus(Enum):
    """Rendered daemon state; action enablement keys off this too (TDD §4.1)."""

    RUNNING = "running"
    STOPPED = "stopped"
    STARTING = "starting"
    DRAINING = "draining"
    FORCE_STOPPED = "force_stopped"
    START_FAILED = "start_failed"
    STALE_LOCK = "stale_lock"


# A transitional pin resolves early when the poll observes one of these states.
# Statuses absent from this map (FORCE_STOPPED, START_FAILED) are *outcome*
# surfacings: only their deadline clears them, so a forced stop stays visible
# rather than being silently overwritten by the next poll's "Stopped".
_PIN_RESOLVED_BY: Dict[DaemonStatus, frozenset] = {
    DaemonStatus.STARTING: frozenset({DaemonStatus.RUNNING}),
    DaemonStatus.DRAINING: frozenset({DaemonStatus.STOPPED, DaemonStatus.STALE_LOCK}),
}


@dataclass(frozen=True)
class ProjectInfo:
    """One registered project, as read from the central ``project-registry.json``.

    Static for the lifetime of a poll cycle.  Paths are derived from ``root``
    using the project layout the launcher and validator already assume.
    """

    project_id: str
    name: str
    root: Path
    config_path: Path
    log_dir: Path


@dataclass
class DaemonSnapshot:
    """One project's observed daemon state, produced by discovery each poll.

    ``pids`` is the *whole* verified process pair (venv shim + base interpreter),
    never a single PID — every lifecycle operation acts on the pair (TDD §4.4).
    ``started_at`` is the oldest ``create_time`` of that pair (epoch seconds).
    """

    project: ProjectInfo
    status: DaemonStatus
    pids: List[int]
    started_at: Optional[float] = None
    detail: Optional[str] = None


@dataclass
class ValidationRun:
    """Per-project result of a ``--validate`` run (populated in Phase E)."""

    state: str = "idle"  # idle | running | ok | broken | failed
    broken_count: Optional[int] = None
    report_path: Optional[Path] = None
    error: Optional[str] = None


@dataclass(frozen=True)
class Pin:
    """A panel-claimed state that overrides poll truth until it expires.

    ``deadline`` is in the model clock's domain (monotonic seconds).  The pin is
    considered expired once the clock **reaches** it (``now >= deadline``).
    """

    status: DaemonStatus
    deadline: float
    detail: Optional[str] = None


class AppModel:
    """Single observable model; views re-render from it and never from actions.

    Mutators (:meth:`apply_poll`, :meth:`pin`, :meth:`clear_pin`, :meth:`select`,
    :meth:`set_shutting_down`, :meth:`set_validation`, :meth:`tick`) each notify
    subscribers **only** if the effective rendered state changed as a result.
    """

    def __init__(self, clock: Callable[[], float] = time.monotonic):
        self._clock = clock
        self._poll: Dict[str, DaemonSnapshot] = {}
        self._pins: Dict[str, Pin] = {}
        self._subscribers: List[Callable[[], None]] = []

        self.validation: Dict[str, ValidationRun] = {}
        self.selected_project_id: Optional[str] = None
        self.last_refresh: Optional[datetime] = None
        self.shutting_down: bool = False
        self.discovery_error: Optional[str] = None

        # Digest of what subscribers were last told. Compared against — never
        # a freshly captured "before": for a pin expiry the *clock* is the
        # change, so a before-snapshot taken now would already contain it and
        # the repaint would be skipped.
        self._last_signature: Tuple = self._signature()

    # ------------------------------------------------------------------ #
    # Observation
    # ------------------------------------------------------------------ #
    def subscribe(self, callback: Callable[[], None]) -> None:
        """Register *callback*, invoked (no args) whenever effective state changes."""
        self._subscribers.append(callback)

    def _notify(self) -> None:
        for callback in list(self._subscribers):
            callback()

    def rows(self) -> List[DaemonSnapshot]:
        """Effective, render-ready snapshots in registry order (pins applied)."""
        return [self._effective(project_id) for project_id in self._poll]

    def snapshot_for(self, project_id: str) -> Optional[DaemonSnapshot]:
        """Effective snapshot for *project_id*, or ``None`` if it isn't listed."""
        if project_id not in self._poll:
            return None
        return self._effective(project_id)

    # ------------------------------------------------------------------ #
    # Mutation
    # ------------------------------------------------------------------ #
    def apply_poll(
        self,
        snapshots: Sequence[DaemonSnapshot],
        *,
        error: Optional[str] = None,
        refreshed_at: Optional[datetime] = None,
    ) -> None:
        """Replace poll truth with a full discovery result.

        Rows are keyed by ``project_id`` so selection and pins survive a refresh;
        projects no longer listed are dropped along with their pins, and a
        selection pointing at a dropped project is cleared.
        """
        self._poll = {snapshot.project.project_id: snapshot for snapshot in snapshots}
        self.discovery_error = error
        self.last_refresh = datetime.now() if refreshed_at is None else refreshed_at

        # Drop pins and selection belonging to projects that vanished.
        for project_id in [pid for pid in self._pins if pid not in self._poll]:
            del self._pins[project_id]
        if self.selected_project_id is not None and self.selected_project_id not in self._poll:
            self.selected_project_id = None

        self._notify_if_changed()

    def pin(
        self,
        project_id: str,
        status: DaemonStatus,
        *,
        ttl_seconds: float,
        detail: Optional[str] = None,
    ) -> None:
        """Claim *status* for *project_id* for at most *ttl_seconds*.

        The deadline is computed from the model clock, so a worker that never
        resolves its pin still releases the row back to poll truth.
        """
        self._pins[project_id] = Pin(
            status=status, deadline=self._clock() + ttl_seconds, detail=detail
        )
        self._notify_if_changed()

    def clear_pin(self, project_id: str) -> None:
        """Release *project_id*'s pin (the owning worker resolved its action)."""
        self._pins.pop(project_id, None)
        self._notify_if_changed()

    def pinned_status(self, project_id: str) -> Optional[DaemonStatus]:
        """The live (unexpired, unresolved) pinned status, if any — else ``None``."""
        pin = self._live_pin(project_id)
        return None if pin is None else pin.status

    def select(self, project_id: Optional[str]) -> None:
        """Set the selected row (``None`` clears); unknown ids are ignored."""
        if project_id is not None and project_id not in self._poll:
            return
        self.selected_project_id = project_id
        self._notify_if_changed()

    def set_shutting_down(self, value: bool = True) -> None:
        """Enter/leave global shutdown mode (idempotent — no spurious notify)."""
        self.shutting_down = value
        self._notify_if_changed()

    def set_validation(self, project_id: str, run: ValidationRun) -> None:
        """Record a project's validation state (Phase E owns the transitions)."""
        self.validation[project_id] = run
        self._notify_if_changed()

    def tick(self) -> None:
        """Re-evaluate pin deadlines without new poll data.

        Called from the UI dispatcher so an expiring pin releases its row even
        when discovery has nothing new to report.
        """
        self._notify_if_changed()

    # ------------------------------------------------------------------ #
    # Internals
    # ------------------------------------------------------------------ #
    def _live_pin(self, project_id: str) -> Optional[Pin]:
        """The pin still in force for *project_id* — a **pure** query.

        A pin stops being in force when its deadline is reached or when the poll
        observes the state it was waiting for.  Deciding this *without* mutating
        anything is what keeps :meth:`_signature` a faithful digest of the
        current render: if this pruned, an expiry would already be applied by the
        time the comparison ran and the row would silently fail to repaint.
        """
        pin = self._pins.get(project_id)
        if pin is None:
            return None
        if self._clock() >= pin.deadline:
            return None
        observed = self._poll.get(project_id)
        resolvers = _PIN_RESOLVED_BY.get(pin.status)
        if observed is not None and resolvers is not None and observed.status in resolvers:
            return None
        return pin

    def _prune_pins(self) -> None:
        """Housekeeping: forget pins that are no longer in force.

        Cannot change rendered state (only non-live pins are removed) — it just
        keeps the dict from accumulating dead entries.
        """
        for project_id in list(self._pins):
            if self._live_pin(project_id) is None:
                del self._pins[project_id]

    def _effective(self, project_id: str) -> DaemonSnapshot:
        """Poll snapshot for *project_id* with any live pin applied on top."""
        observed = self._poll[project_id]
        pin = self._live_pin(project_id)
        if pin is None:
            return observed
        return replace(
            observed,
            status=pin.status,
            detail=pin.detail if pin.detail is not None else observed.detail,
        )

    def _signature(self) -> Tuple:
        """Comparable digest of everything a view renders.

        Notification is driven by a before/after comparison of this value, which
        is what makes "unchanged input produces no notification" true by
        construction rather than by per-mutator bookkeeping.
        """
        rows = tuple(
            (
                project_id,
                snapshot.status,
                tuple(snapshot.pids),
                snapshot.started_at,
                snapshot.detail,
            )
            for project_id, snapshot in ((pid, self._effective(pid)) for pid in self._poll)
        )
        validation = tuple(
            (project_id, run.state, run.broken_count, run.report_path, run.error)
            for project_id, run in sorted(self.validation.items())
        )
        return (
            rows,
            validation,
            self.selected_project_id,
            self.shutting_down,
            self.discovery_error,
        )

    def _notify_if_changed(self) -> None:
        """Notify subscribers iff the render differs from what they were last told."""
        self._prune_pins()
        signature = self._signature()
        if signature != self._last_signature:
            self._last_signature = signature
            self._notify()
