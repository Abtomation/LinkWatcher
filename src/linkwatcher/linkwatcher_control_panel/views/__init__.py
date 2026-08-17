"""
Views layer for the LinkWatcher Control Panel.

All Tkinter/ttk widget construction lives here so the rest of the subpackage
(model, discovery, lifecycle, settings) stays toolkit-independent — the recorded
PySide6 accessibility fallback (TDD §8 Q1) would rewrite only this package.
"""

from .main_window import MainWindow
from .shutdown_dialog import ShutdownDialog

__all__ = ["MainWindow", "ShutdownDialog"]
