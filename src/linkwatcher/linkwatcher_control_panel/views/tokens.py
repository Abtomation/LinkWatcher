"""
Design tokens for the Control Panel views — semantic colors and status glyphs.

Sourced verbatim from the UI Design (PD-UIX-003 §3.1 / §3.4), which in turn
draws them from the project Design Guidelines (PD-UIX-001).  No new colors are
introduced here.  Centralizing them in one module honors PD-UIX-003 §10.4
("strings/tokens in one module") and keeps the ``views/`` layer the single place
a toolkit swap (the recorded PySide6 fallback) would touch.

Every status is rendered as **glyph + text**, never color-only (PD-UIX-001 §6 /
WCAG 2.1 AA) — the glyphs below always accompany a text label.
"""

# --- Semantic color tokens (PD-UIX-003 §3.1) ---------------------------------
STATUS_RUNNING = "#107C10"  # running rows; validation success
STATUS_STOPPED = "#6E6E6E"  # stopped rows; idle / secondary text
STATUS_TRANSITION = "#9D5D00"  # Starting… / draining…; restart-needed notice
STATUS_ERROR = "#C42B1C"  # failures, force-stopped, stale lock, config errors
ACCENT_PRIMARY = "#0067C0"  # selection highlight, focus accents, links

# Muted text (captions, empty-state hints) reuses the stopped/secondary token.
MUTED_TEXT = STATUS_STOPPED

# --- Status glyphs (PD-UIX-003 §3.4) -----------------------------------------
GLYPH_RUNNING = "●"  # ● running
GLYPH_STOPPED = "■"  # ■ stopped
GLYPH_TRANSITION = "▲"  # ▲ starting… / draining…
GLYPH_ERROR = "✕"  # ✕ force-stopped / failed
GLYPH_WARNING = "⚠"  # ⚠ stale lock / warnings
GLYPH_STOPPED_CLEAN = "✔"  # ✔ stopped cleanly (shutdown dialog); validation clean
GLYPH_INFO = "ⓘ"  # ⓘ informational notices (unsaved changes)

# --- Toolbar glyphs (PD-UIX-003 §3.4) ----------------------------------------
GLYPH_START = "▶"  # ▶ Start
GLYPH_STOP = "■"  # ■ Stop
GLYPH_REFRESH = "⟳"  # ⟳ Refresh

# --- Typography (PD-UIX-003 §3.2; Tk font tuples, sizes in points) -----------
FONT_HEADING = ("Segoe UI", 11, "bold")  # pane headings (≈ 14 px Semibold)
FONT_MONO = ("Consolas", 10)  # log content, config editor, report paths
