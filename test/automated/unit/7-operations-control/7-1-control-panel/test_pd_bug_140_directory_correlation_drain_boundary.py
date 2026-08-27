"""
Document Metadata:
ID: TE-TST-158
Type: Test File
Category: Test
Version: 1.4
Created: 2026-08-26
Updated: 2026-08-27
Component Name: lifecycle
Feature Id: 7.1.1
Language: Python
Test Name: PdBug140DirectoryCorrelationDrainBoundary
Test Type: Unit
"""

# PD-BUG-140 — where the panel drain's coverage of *directory* move-correlations
# actually ends.
#
# PD-BUG-140 was filed on the premise that a directory move "is correlated over a
# window of up to 300 s, which no drain bounded by a 20 s grace period can
# outlast".  Measured against the real DirectoryMoveDetector and the real
# post-PD-BUG-136 `watch_quiescence`, that premise is wrong, and the resolution
# (checkpoint-approved 2026-08-26) was to correct FDD 7-1-1-BR-3 and TDD §4.4
# rather than to change code.
#
# These tests exist to keep the corrected documentation load-bearing.  Each one
# pins a specific sentence now written into the design documents, so a later
# change to the constants or the timer wiring turns a test red instead of
# silently making the design docs lie:
#
#   1. `dir_move_settle_delay` (5 s) sits INSIDE the drain's required idle span
#      (10 s at defaults) — this is *why* a matched correlation is covered, and
#      it is a relationship between two independently-editable constants owned by
#      two different features (daemon config vs. panel drain).
#   2. A correlation that has matched at least one file really does resolve
#      within the settle delay — the guarantee, exercised rather than asserted.
#   3. The residual exposure is the ZERO-MATCH window only: between
#      `dir_move_buffered` and the first match the daemon writes nothing, so the
#      drain sees an idle log and stops cleanly.
#   4. `dir_move_max_timeout` names two things, and the documents use both
#      referents (CR F9).  The config TIMER is armed for every pending directory
#      move, so it bounds both states; it is merely the SOLE bound in the
#      zero-match state, where no settle timer is ever armed.  The log RECORD of
#      that name fires only on the partial-match branch — the zero-match window
#      closes with `directory_true_delete`.  And the shape that actually waits
#      the timer out — a genuine directory deletion — does in-memory bookkeeping
#      only, which is why it costs nothing at terminate.
#   5. The DEFERRED detection option (PD-FRQ-020) is bounded by the daemon's
#      `log_level`: every record it would key on is INFO, and a stdlib logger
#      gates before its handlers, so above INFO there is nothing to detect —
#      not even in the file log, whose handler sits at DEBUG.
#
# The drain half uses the fake clock/log-stat seams already used by
# test_panel_lifecycle.py; the detector half uses real timers with a compressed
# settle delay, so no test here sleeps for the production 5 s.
#
# Mutation verification (2026-08-27, closing code-review findings F3/F4).  Two
# assertions were re-derived because they could not fail for the reason they
# named, and each was then broken on purpose to confirm it now can:
#
#   * F3 — test 1 hardcoded the panel defaults and `move_detect_delay` as
#     literals, so it pinned nothing about the relationship it describes.  Now
#     read from `PanelSettings()` / `LinkWatcherConfig()`.  Mutation: dropping
#     `move_detect_delay` to 3.0 (below the 5 s settle delay) turns it RED; with
#     the old hardcoded 10.0 the same mutation left it GREEN.
#   * F4 — test 3 asserted the silent window against a hand-built `LogStat`,
#     observing nothing the detector actually emits; the heartbeat its docstring
#     invoked would have left it green.  Now a recording logger observes real
#     output.  Mutation: wiring a `dir_move_pending_heartbeat` timer into
#     `handle_directory_deleted` turns it RED, naming the injected record.
#
# Mutation verification (2026-08-27, closing code-review finding F7).  Test 5 was
# written from the condition that would falsify it rather than from the
# conclusion it states:
#
#   * F7 — the design documents called the deferred detection option viable
#     without naming the `log_level` that gates it.  Mutation: changing
#     `dir_move_buffered` from `self._logger.info(` to `self._logger.warning(`
#     in `dir_move_detector.py` turns the WARNING case RED on the assertion
#     naming it, and leaves the INFO case GREEN — so the test discriminates on
#     the record's level, which is the whole claim.
#
# Mutation verification (2026-08-27, closing code-review finding F10).  Test 2
# used to assert only `config.dir_move_max_timeout > PANEL_GRACE_PERIOD`, which
# says nothing about WHICH state the timer exposes — the claim its name made.
# It now asserts the discriminator on a real detector, and both halves were
# broken on purpose:
#
#   * F10-a — making `_reset_settle_timer` a no-op (so a match never arms a
#     settle timer) turns it RED on "one match arms the settle timer".
#   * F10-b — calling `_reset_settle_timer` at buffering time (so a settle timer
#     exists before any match) turns it RED on "no settle timer exists before
#     the first match".
#
#   Both mutations leave the OLD assertion green — neither touches the config
#   constants it compared — which is the F10 gap in one sentence.
#
# All five mutations were reverted and the sources verified byte-identical.

import logging
import threading
import time

import pytest

from linkwatcher.config.settings import LinkWatcherConfig
from linkwatcher.dir_move_detector import DirectoryMoveDetector
from linkwatcher.linkwatcher_control_panel.lifecycle import (
    LogStat,
    _required_idle_span,
    watch_quiescence,
)
from linkwatcher.linkwatcher_control_panel.settings import PanelSettings
from linkwatcher.logging import LogLevel, get_logger, reset_logger, setup_logging

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


# Panel defaults that the drain runs with, and the daemon's move_detect_delay,
# which the drain adopts as its required idle span while a correlation could
# still be open (PD-BUG-136).
#
# These are READ from the real defaults rather than copied as literals (CR F3).
# The documented guarantee is a relationship *between* these constants, so a
# test that hardcodes them stays green while the guarantee it claims to pin
# silently becomes false — lowering `move_detect_delay` or `grace_period_seconds`
# would go unnoticed.
PANEL_IDLE_THRESHOLD = PanelSettings().log_idle_threshold_seconds
PANEL_GRACE_PERIOD = PanelSettings().grace_period_seconds
CORRELATION_WINDOW = LinkWatcherConfig().move_detect_delay

# How long the zero-match test watches an unmatched correlation for spontaneous
# output.  Long enough to catch a heartbeat wired at any plausible tick, short
# enough that the suite does not pay for it.
_SILENT_WINDOW_PROBE = 0.4


class _FakeDb:
    """Minimal LinkDatabase stand-in — the detector only asks for source files."""

    def __init__(self, files):
        self._files = list(files)

    def get_source_files(self):
        return list(self._files)


class _RecordingLogger:
    """Records every record the detector emits, as ``(stream, event)`` pairs.

    Installed in place of the detector's real logger so a test can assert on
    what the daemon *actually writes* rather than on a hand-built stand-in
    (CR F4).  Mirrors the surface ``DirectoryMoveDetector`` uses:
    ``info``/``warning``/``error``/``debug`` plus ``performance.log_metric``.
    """

    class _Performance:
        def __init__(self, records):
            self._records = records

        def log_metric(self, metric_name, value, unit="", **kwargs):
            self._records.append(("metric", metric_name))

    def __init__(self):
        self.records = []
        self.performance = self._Performance(self.records)

    def _record(self, stream):
        def _emit(event, **kwargs):
            self.records.append((stream, event))

        return _emit

    def __getattr__(self, name):
        if name in ("info", "warning", "error", "debug"):
            return self._record(name)
        raise AttributeError(name)

    def events(self):
        """Just the event names, in emission order."""
        return [event for _stream, event in self.records]


def _make_detector(tmp_path, settle_delay=0.3, max_timeout=300.0):
    """A real detector over a real (empty) project root, with fast timers."""
    moved = []
    true_deleted = []
    done = threading.Event()

    def on_dir_move(old_dir, new_dir):
        moved.append((old_dir, new_dir))
        done.set()

    def on_true_file_delete(file_path):
        true_deleted.append(file_path)
        done.set()

    detector = DirectoryMoveDetector(
        link_db=_FakeDb(["notes/a.md", "notes/b.md"]),
        project_root=str(tmp_path),
        on_dir_move=on_dir_move,
        on_true_file_delete=on_true_file_delete,
        max_timeout=max_timeout,
        settle_delay=settle_delay,
    )
    return detector, moved, true_deleted, done


# --------------------------------------------------------------------------- #
# 1. The constant relationship that makes a matched correlation coverable
# --------------------------------------------------------------------------- #
def test_settle_delay_fits_inside_the_drains_required_idle_span():
    """The documented guarantee is a relationship between two features' defaults.

    TDD §4.4 now states that a directory correlation which has matched at least
    one file resolves within `dir_move_settle_delay` of its last match, *inside*
    the idle span the drain requires — which is the whole reason such a
    correlation cannot be terminated out from under the daemon.

    That sentence is only true while the daemon's settle delay stays below the
    panel's required idle span.  The two live in different packages and different
    features (daemon config vs. panel drain), so nothing but this assertion
    couples them: raise `dir_move_settle_delay` past `move_detect_delay` and the
    guarantee silently becomes false.
    """
    settle_delay = LinkWatcherConfig().dir_move_settle_delay
    required_idle = _required_idle_span(
        idle_threshold=PANEL_IDLE_THRESHOLD,
        grace_period=PANEL_GRACE_PERIOD,
        correlation_window=CORRELATION_WINDOW,
        log_age=0.0,
    )

    assert settle_delay < required_idle, (
        f"dir_move_settle_delay={settle_delay}s must stay inside the drain's "
        f"required idle span={required_idle}s, or a matched directory "
        f"correlation can be terminated mid-flight (FDD 7-1-1-BR-3 / TDD 4.4)"
    )


def test_max_timeout_timer_is_the_sole_bound_only_in_the_zero_match_state(tmp_path):
    """Why the 300 s timer exposes the zero-match state and not the matched one.

    This is the half of the original bug report that survives: no drain bounded
    by the grace period can outlast `dir_move_max_timeout`.  But the timer is
    armed for *every* pending directory move, so "300 s exceeds the grace
    period" alone says nothing about which state is exposed — the documents'
    claim is that it is the **sole** bound only where no settle timer is armed.

    So this asserts the discriminator directly, on a real detector: at buffering
    there is a max timer and no settle timer, and one match arms a settle timer
    whose delay sits inside the drain's required idle span.  Arm the settle
    timer at buffering, or stop arming it on match, and this goes red — which
    the previous version (`config.dir_move_max_timeout > PANEL_GRACE_PERIOD`
    alone) could not do for the state it named (CR F10).
    """
    config = LinkWatcherConfig()
    assert config.dir_move_max_timeout > PANEL_GRACE_PERIOD, (
        "the surviving half of the original report: the max-timeout timer "
        "outlasts any drain bounded by the grace period"
    )

    # Delays long enough that nothing fires while the state is inspected.
    detector, _moved, _true_deleted, _done = _make_detector(
        tmp_path, settle_delay=30.0, max_timeout=300.0
    )
    try:
        detector.handle_directory_deleted("notes")
        pending = detector.pending_dir_moves["notes"]

        assert pending.max_timer is not None, "buffering must arm the max timer"
        assert pending.settle_timer is None, (
            "no settle timer exists before the first match, which is exactly why "
            "the 300 s timer is the SOLE bound in the zero-match state — the "
            "state FDD 7-1-1-EC-12 records as exposed"
        )

        detector.match_created_file("archive/a.md", str(tmp_path / "archive" / "a.md"))
        pending = detector.pending_dir_moves["notes"]

        assert pending.settle_timer is not None, (
            "one match arms the settle timer, so the max timeout stops being the "
            "operative bound; without this the matched state would be exposed too "
            "and the residual would be wider than the documents claim"
        )
        # That the REAL settle delay sits inside the drain's required idle span
        # is test 1's claim, and is deliberately not restated here: this test
        # runs a compressed delay, so asserting it against these constants would
        # be true by construction and pin nothing.
    finally:
        for pending in list(detector.pending_dir_moves.values()):
            for timer in (pending.max_timer, pending.settle_timer):
                if timer is not None:
                    timer.cancel()


# --------------------------------------------------------------------------- #
# 2. The guarantee, exercised: one match ⇒ resolution within the settle delay
# --------------------------------------------------------------------------- #
def test_matched_directory_correlation_resolves_within_the_settle_delay(tmp_path):
    """A correlation with at least one match is never left hanging for 300 s.

    Scenario B of the PD-BUG-140 reproduction, compressed: the settle timer is
    reset on every match and fires `settle_delay` after the last one, so the
    correlation resolves on its own schedule regardless of whether the remaining
    files ever arrive.  This is what makes it coverable by a bounded drain.
    """
    settle_delay = 0.3
    detector, moved, _true_deleted, done = _make_detector(tmp_path, settle_delay=settle_delay)

    detector.handle_directory_deleted("notes")
    assert detector.pending_dir_moves, "delete should buffer a pending correlation"

    started = time.monotonic()
    detector.match_created_file("archive/a.md", str(tmp_path / "archive" / "a.md"))

    # The second file never arrives — the settle timer must resolve it anyway.
    assert done.wait(timeout=5.0), "settle timer never fired for a matched correlation"
    elapsed = time.monotonic() - started

    assert moved == [("notes", "archive")]
    assert not detector.pending_dir_moves, "correlation should be cleared once processed"
    assert elapsed < settle_delay + 3.0, (
        f"matched correlation took {elapsed:.2f}s to resolve; the guarantee is "
        f"settle_delay ({settle_delay}s) after the last match, not max_timeout"
    )


# --------------------------------------------------------------------------- #
# 3. The residual: the zero-match window is NOT covered
# --------------------------------------------------------------------------- #
def test_zero_match_window_lets_the_drain_stop_cleanly(tmp_path, fake_clock):
    """The documented limitation: a buffered directory delete is invisible.

    Between `dir_move_buffered` and the first matched create the daemon writes
    nothing, so its log signature is byte-for-byte an idle daemon's.  The drain
    ages the log past the correlation window and reports a **clean** stop while
    the correlation is still open — which is the silent loss PD-BUG-140 records,
    and the reason the residual is written into FDD 7-1-1-BR-3 rather than
    fixed in code.

    The silence half is **observed, not stipulated** (CR F4): a recording logger
    is installed before the delete, so buffering must emit exactly the two known
    records and the wait that follows must emit nothing.  Add the daemon-side
    heartbeat D-T7 rejects — or any new record in the buffering path — and this
    goes red.  Its reach is bounded by ``_SILENT_WINDOW_PROBE``: a heartbeat
    slower than that probe would slip through, so this is a tripwire on the
    documented silence, not a proof of silence for all time.
    """
    detector, moved, true_deleted, _done = _make_detector(tmp_path, max_timeout=300.0)
    spy = _RecordingLogger()
    detector._logger = spy

    detector.handle_directory_deleted("notes")

    assert spy.events() == ["dir_move_buffered", "dir_move_batch_size"], (
        "buffering a directory delete emits exactly these two records; a new one "
        "here changes what the drain could see and EC-12 must be revisited"
    )

    # The silent window itself: nothing may be written while the correlation
    # waits for creates that have not started.
    del spy.records[:]
    time.sleep(_SILENT_WINDOW_PROBE)
    assert spy.events() == [], (
        f"the daemon wrote {spy.events()} while holding an unmatched directory "
        f"correlation; the drain could see that, so the FDD 7-1-1-EC-12 residual "
        f"and TDD D-T7 no longer describe the code"
    )

    # A log written at the moment of the delete, then frozen: exactly what the
    # daemon's log looks like while it waits for creates that have not started.
    frozen = LogStat(tmp_path / "LinkWatcherLog.txt", 4096, 0.0)
    clock = fake_clock

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=PANEL_IDLE_THRESHOLD,
        grace_period=PANEL_GRACE_PERIOD,
        correlation_window=CORRELATION_WINDOW,
        clock=clock,
        sleep=clock.advance,
        log_stat=lambda _dir: frozen,
        wall_clock=lambda: 0.0,
    )

    assert quiescent is True, (
        "the drain reports a CLEAN stop, not a forced one — the false clean that "
        "makes this loss silent (bug Dims: OB)"
    )
    assert detector.pending_dir_moves, (
        "the correlation is still open at the moment the panel terminates the "
        "daemon: every reference under the moved directory is dropped"
    )
    assert moved == [] and true_deleted == []


# --------------------------------------------------------------------------- #
# 4. Why waiting out the 300 s window costs nothing for a genuine deletion
# --------------------------------------------------------------------------- #
def test_true_directory_deletion_only_does_in_memory_bookkeeping(tmp_path):
    """The zero-match shape that *does* run to 300 s is the harmless one.

    A directory genuinely deleted (no creates ever) resolves via the max timer
    into `_process_dir_true_delete`, whose entire effect is the per-file
    true-delete callback — database bookkeeping in a process the panel is about
    to terminate anyway.  No reference update is pending, so nothing is lost.
    This is what keeps the residual's blast radius limited to a slow-*starting*
    directory move.
    """
    detector, moved, true_deleted, done = _make_detector(
        tmp_path, max_timeout=0.3, settle_delay=0.3
    )

    detector.handle_directory_deleted("notes")
    assert done.wait(timeout=5.0), "max timer never fired for an unmatched delete"

    assert moved == [], "no directory move should be inferred without a single match"
    assert sorted(true_deleted) == ["notes/a.md", "notes/b.md"]
    assert not detector.pending_dir_moves


# --------------------------------------------------------------------------- #
# 5. What bounds the DEFERRED detection option (PD-FRQ-020): the daemon's
#    log_level, not the panel's willingness to read
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize(
    ("level", "visible"),
    [(LogLevel.INFO, True), (LogLevel.WARNING, False)],
)
def test_silent_window_records_are_gated_by_the_daemons_log_level(tmp_path, level, visible):
    """The deferred warn-on-close can only see what the daemon's `log_level` emits.

    TDD D-T7 and FDD 7-1-1-EC-12 record a *detection* option that needs no
    daemon-side contract: the panel reads records the daemon already writes and
    reports the stop as lossy rather than clean.  That holds only at INFO or
    below.  Every record the option would key on is INFO — `dir_move_buffered`
    and the `dir_move_batch_size` metric that open the silent window, and the
    `dir_move_processing` / `directory_true_delete` records that close it — and
    a stdlib logger gates on its own level *before* any handler runs, so raising
    `log_level` removes them from the **file** log too, not merely the console.
    The one survivor is the `dir_move_max_timeout` **log record** (WARNING) —
    not the config timer of the same name, which is armed for every pending
    move: the record fires only on the partial-match branch, never for this
    window, which closes with `directory_true_delete` at INFO (CR F9).

    Not hypothetical: the shipped `PRODUCTION_CONFIG` preset and
    `config-examples/production-config.yaml` both set `log_level: WARNING` —
    precisely where TDD §4.4 already records the drain protection as lost
    entirely.  Whoever picks PD-FRQ-020 up meets that bound here rather than
    discovering it after building the reader (code-review finding F7).

    End-to-end on purpose: the real detector emits through the real global
    logger into a real file, so no stand-in can make this pass.
    """
    log_file = tmp_path / "logs" / "LinkWatcherLog.txt"
    setup_logging(level=level, log_file=str(log_file), colored_output=False)
    detector = None
    try:
        detector, _moved, _true_deleted, _done = _make_detector(tmp_path, max_timeout=300.0)
        detector.handle_directory_deleted("notes")

        handlers = get_logger().logger.handlers
        for handler in handlers:
            handler.flush()
        written = log_file.read_text(encoding="utf-8") if log_file.exists() else ""
        file_handler_levels = [h.level for h in handlers if isinstance(h, logging.FileHandler)]
    finally:
        if detector is not None:
            for pending in list(detector.pending_dir_moves.values()):
                for timer in (
                    getattr(pending, "max_timer", None),
                    getattr(pending, "settle_timer", None),
                ):
                    if timer is not None:
                        timer.cancel()
        reset_logger()

    assert ("dir_move_buffered" in written) is visible, (
        f"at log_level={level.value} the buffering record is "
        f"{'missing from' if visible else 'present in'} the daemon log; PD-FRQ-020's "
        f"detection surface is not what TDD D-T7 and FDD 7-1-1-EC-12 now describe"
    )
    assert ("dir_move_batch_size" in written) is visible, (
        f"at log_level={level.value} the batch-size metric is "
        f"{'missing from' if visible else 'present in'} the daemon log"
    )
    assert file_handler_levels == [logging.DEBUG], (
        "the file handler is at DEBUG, so the records above are gated by the "
        "LOGGER level, not by handler filtering — which is why lowering the "
        "handler level cannot restore PD-FRQ-020's visibility at WARNING"
    )
