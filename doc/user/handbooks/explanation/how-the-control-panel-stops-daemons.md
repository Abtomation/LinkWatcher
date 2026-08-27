---
id: PD-UGD-011
type: Product Documentation
category: User Guide
version: 1.1
created: 2026-08-18
updated: 2026-08-27
description: Why closing the Control Panel window stops every daemon it manages, and how the drain-then-terminate model bounds that shutdown
handbook_content_type: explanation
handbook_name: How the Control Panel Stops Daemons
---

# How the Control Panel Stops Daemons

This page explains the reasoning behind the Control Panel's stop behavior — in particular why closing the window stops daemons, and why a stop can take up to twenty seconds and still end in a forced termination. It is background, not instructions; for the steps, see [Control Panel Operations](../how-to/control-panel-operations.md).

## Closing the window stops the daemons

This is the panel's most surprising behavior, so it is worth stating plainly: **closing the Control Panel stops every daemon it manages.** The panel is not a viewer you can dismiss to get your screen back.

The reasoning is that a supervisor which leaves its subjects running creates a worse problem than it solves. LinkWatcher daemons are invisible — no window, no tray icon, no output. If the panel let them outlive it, closing the window would scatter background processes that you can now neither see nor stop without reopening the panel or hunting through Task Manager. Tying their lifetime to the window keeps one rule true: what the panel manages, the panel accounts for.

If you want daemons to keep running, leave the panel open, or do not use the panel to start them. Daemons started by a session hook and never touched by the panel are ordinary background daemons; the panel adopts them into its list, and closing the panel stops those too.

## Why stopping is not immediate

On Windows there is no polite way to ask another process to finish up. There is no SIGTERM equivalent that a program can catch and act on — process termination is a hard kill that gives the target no chance to close what it is doing.

That matters because a LinkWatcher daemon is frequently mid-flight. It buffers file deletions for several seconds to correlate them with matching creations, which is how it recognizes a move rather than a delete-plus-unrelated-add. Kill it during that window and the correlation is simply lost: the move is never recognized, and the references that should have been updated silently are not.

Rather than accept that on every stop, the panel does something less direct and more useful: it waits for the daemon to *look* finished before terminating it.

## Drain, then terminate

When you stop a daemon — individually or as part of closing the window — the panel:

1. **Watches the project's newest log file.** It samples the file's path, size, and modification time every 0.25 seconds. A working daemon writes; a finished one does not.
2. **Waits for quiescence.** When that signature stops changing for the idle threshold (3 seconds by default), the daemon is considered done with whatever it was doing — *unless* the log was written recently enough that the daemon could still be holding a buffered move (see below), in which case the panel waits out that window instead.
3. **Terminates the process pair.** Both the venv shim parent and its interpreter child are terminated together.
4. **Cleans up the lock file** — but only if it still names a process the panel just terminated. A lock already reclaimed by a successor daemon is left alone.

If the log never goes quiet, step 2 does not wait forever. The grace period (20 seconds by default) bounds it. When that expires, the daemon is terminated anyway, and the row reports `✕ Force-stopped` rather than a clean stop.

That distinction is the point of surfacing it. A clean stop means the daemon had gone quiet first. A forced stop means it had not, so work may have been dropped — and you are told, rather than left to assume everything finished.

## What "drain" can and cannot promise

Drain is a **heuristic based on observed log activity**, not a handshake with the daemon. The panel has no channel into a running daemon and deliberately adds none — the whole design is that the panel manages daemons through surfaces that already exist (the lock file, the process table, the launcher, the log files, the config file). Introducing a shutdown protocol would mean changing the daemon to cooperate with the panel, and every daemon that predates the panel or runs without it would then be a special case.

The practical consequences:

- **A quiet log is strong evidence, not proof.** When LinkWatcher sees a file disappear, it holds that deletion for `move_detect_delay` (10 seconds by default) waiting to see whether a matching file appears elsewhere — that is how a move is recognised when the operating system reports it as a delete and a create rather than a rename. While it waits, it writes nothing, so a daemon with real pending work looks exactly like an idle one. The panel therefore reads each project's own `move_detect_delay` and, when the log was written inside that window, requires that much silence instead of the 3-second threshold. A stop that lands just after a deletion consequently takes around 10 seconds rather than 3; a daemon that has been quiet for longer than the window still stops in about 3, because a pending deletion cannot have survived that long. If the window is wider than the grace period allows, it is trimmed to fit and a warning is written to the panel log.
- **A directory move is covered only once its first file has appeared.** When a directory is moved, LinkWatcher buffers the directory's disappearance and waits for the files to show up under their new parent. From the first file onward it settles the batch within 5 seconds of the last arrival, which is inside the silence the drain requires — so an ordinary directory move on the same drive, where the files reappear immediately, is drained safely. The gap is the wait *before* the first file arrives: during it the daemon writes nothing at all, so the panel sees an idle daemon and reports a clean stop. In practice that gap only opens when the move is slow to start — copying to another drive or a network share, a very large tree, or a heavily loaded machine. Closing the panel in those first seconds can drop the reference updates for everything under the moved directory, and the stop will not be flagged as forced. If you have just moved a large directory somewhere slow, give it a moment before closing the panel — and if in doubt, run a [validation scan](../link-validation.md) afterwards, which lists any references left stale.
- **The cost is bounded to dropped work, never corrupted files.** LinkWatcher writes updates atomically. An interrupted update leaves the original file intact; it does not leave a half-rewritten one. The worst case is a move whose references were never updated — which the [validation scan](../link-validation.md) will find.
- **A busy project takes the full grace period, and the bar for "busy" is the correlation window.** Any log activity during the drain re-arms the wait to `move_detect_delay`, because the panel cannot tell a line that means "work finished" from one that means "a deletion is now buffered". So a clean stop needs the daemon to have stopped writing roughly 10 seconds before the grace period expires, not 3. A daemon still working past that point is force-stopped — which is the honest report, since it may have had pending work, but it does mean busy projects now show forced stops that used to read as clean. If that is routine for your projects, raise `grace_period_seconds`.
- **Raising the daemon's `log_level` past INFO switches the protection off.** The deletion record the panel implicitly depends on is logged at INFO, so at `WARNING` or `ERROR` the daemon is silent while it buffers, the log always looks old, and the drain falls back to the 3-second rule. The panel does not read the project's `log_level` and cannot warn you about this.
- **A daemon the panel did not start may be using a different delay than the panel assumes.** The panel works out how long to wait from the project's config file plus its own `LINKWATCHER_MOVE_DETECT_DELAY` environment variable. If you started a daemon yourself from a terminal where that variable was set to something else, and then let the panel adopt and stop it, the panel may wait a different span than that daemon needs. Set the value in the project's `linkwatcher-config.yaml` rather than in a single shell and the two can never disagree.

This is a deliberate trade: a heuristic that usually avoids interrupting work, against a protocol that would guarantee it at the cost of coupling the panel to the daemon.

## Why the panel never guesses at a process

Before terminating anything, the panel re-verifies identity against a **fresh** snapshot of the process table — it never trusts what it saw when it last polled.

A process qualifies as a project's daemon only if its command line runs `main.py` *and* its `--project-root` names that project. A matching PID in the lock file is not enough on its own, because operating systems recycle PIDs: the process wearing that number now may be something else entirely.

If nothing passes the test at termination time, nothing is terminated. The panel would rather fail to stop a daemon than stop the wrong process. This is also why a daemon started without `--project-root` is never claimed — it cannot be attributed to any project, so acting on it would be a guess.

## Closing with several daemons running

Closing the window drains every managed daemon **in parallel**, not one after another. Ten daemons take about as long as one.

While that happens, a modal dialog shows each daemon's state and a `k of n stopped` counter. You cannot dismiss it — once shutdown starts the panel is committed, and offering a cancel button would imply a way back that does not exist.

Shutdown is bounded twice over. Each drain is bounded by the grace period. On top of that, a watchdog fires at grace plus 15 seconds and forces the exit regardless of what any worker is doing. **The panel cannot hang on close.** In practice the watchdog never fires — every drain resolves or force-terminates well before it — but its existence is what makes "closing the panel always ends" a guarantee rather than an expectation.

One case is deliberately excluded: a daemon still in `Starting…` when you close is not drained. Its launcher is still in flight, so there is no verified process to stop yet; that daemon keeps running unmanaged. Reopening the panel lists and manages it normally. Waiting for it would mean the one code path that must never hang would have to wait on a start it does not control.

## Why the panel uses the project's own launcher to start

Symmetrically, the panel does not spawn daemons itself. Start shells out to the project's `start_linkwatcher_background.ps1` — the same script the session hook runs.

This keeps exactly one code path for starting a daemon. Every guard that script implements — the duplicate-instance check, stale-lock reclaim, logging setup, crash handling — applies identically whether the start came from a hook, a terminal, or the panel. A second start path inside the panel would be a second thing to keep in sync, and the first divergence would show up as a daemon that behaves differently depending on who started it.

It also means the panel inherits the launcher's idempotence: starting an already-running project is a no-op rather than a duplicate daemon.

## Related Documentation

- [Control Panel Operations](../how-to/control-panel-operations.md) — performing starts, stops, and scans
- [Control Panel Reference](../reference/control-panel-reference.md) — the timing values referenced here and how to change them
- [Link Validation](../link-validation.md) — finding references a dropped update left stale
- [Logging and Monitoring](../logging-and-monitoring.md) — the daemon log activity the drain observes

---

*This handbook is part of the LinkWatcher Product Documentation.*
