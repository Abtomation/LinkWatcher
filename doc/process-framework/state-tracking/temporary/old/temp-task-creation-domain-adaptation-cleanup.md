---
id: PF-STA-050
type: Document
category: General
version: 1.0
created: 2026-02-27
updated: 2026-02-27
task_name: domain-adaptation-cleanup
---

# Domain Adaptation Cleanup — State Tracking

> **Purpose**: Track systematic removal of BreakoutBuddies-specific references across all framework and product documentation files. All files evaluated 2026-02-27.

## Action Groups

### Group 1: REMOVE — Product Documentation (19 files) ✅ DONE

All 19 files deleted. Empty directories cleaned. All references in surviving files cleaned.

### Group 2: REMOVE — Framework-Specific Tasks (3 files) ✅ DONE

All 3 Flutter-only tasks deleted. References cleaned from documentation-map, tasks/README, enhancement templates, bug-tracking, etc.

### Group 3: REMOVE — Dart-Only Template (1 file) ✅ DONE

test-file-template.dart deleted. References updated in test-file-creation-guide.md and tech-agnostic-testing-pipeline-concept.md.

### Group 4: REMOVE — BreakoutBuddies TDD README (1 file) ✅ DONE

README.md deleted. References cleaned from system-architecture-review.md and adr-creation-task.md.

### Group 5: ADAPT — Archive Feature States (41 files, bulk operation) ✅ DONE

Removed "Flutter best practices" / "Follows Riverpod patterns" lines from all 41 archive files. Also removed Riverpod AsyncNotifier examples from 5 files. Replaced "Widget Tests" → "Component Tests" and "Key UI Flows" → "Key Flows" across all 41 files.

### Group 6: ADAPT — Framework Tasks (18 files) ✅ DONE

All files adapted: Flutter/Dart/Supabase/Riverpod/Escape Room references replaced with generic equivalents. Handled by parallel Agent 1. Also included 5 validation tasks (code-quality, architectural-consistency, integration-dependencies, documentation-alignment, extensibility-maintainability).

### Group 7: ADAPT — Framework Guides (13 files) ✅ DONE

All files adapted by parallel Agent 2 + manual cleanup. Replaced BB project names, Dart code examples → Python, Flutter patterns → generic.

### Group 8: ADAPT — Minor Name Replacements (12 files) ✅ DONE

All "BreakoutBuddies" → "the project" replacements completed across all 12 files.

### Group 9: ADAPT — Templates (10 files) ✅ DONE

All templates adapted by parallel Agent 3. BB project names → generic, Dart code blocks → generic.

### Group 10: ADAPT — Context Maps & Visualizations (7 files) ✅ DONE

All context maps adapted by parallel Agent 3. Flutter/Riverpod refs → generic. SupabaseClient → DBClient in data-layer map.

### Group 11: ADAPT — Scripts (5 files) ✅ DONE

Scripts adapted by parallel Agent 3 + manual cleanup. BB paths → generic, .dart examples → .py in DocumentManagement.psm1, TestTracking.psm1.

### Group 12: ADAPT — Miscellaneous (6 files) ✅ DONE

All miscellaneous files adapted by parallel Agent 3.

### Group 13: KEEP — No Changes Needed ✅ CONFIRMED

Historical records and LinkWatcher-specific product docs correctly left unchanged.

### Additional Files Fixed (discovered during verification)

- `doc/product-docs/guides/guides/development-guide.md` — Full adaptation: Riverpod → generic, Supabase → generic, Dart examples → Python, Escape Room sections → generic, pubspec.yaml → requirements.txt
- `doc/product-docs/ci-cd/ci-cd-dependencies-visualization.md` — Rewrote mobile app pipeline → Python CLI pipeline
- `doc/process-framework/guides/guides/hybrid-document-creation-guide.md` — Updated Dart test examples → Python
- `doc/process-framework/guides/guides/implementation-guide.md` — Full adaptation of 1630-line guide: all Dart code → Python
- `doc/process-framework/guides/guides/task-transition-guide.md` — .dart example path → .py
- `doc/process-framework/templates/templates/feature-task-breakdown-template.md` — "Widget tests" → "Component tests"
- `doc/id-registry.json` — Removed BB project name from description

## Progress

### Sessions 1-3: 2026-02-27
**Focus**: Full evaluation + complete execution
**Status**: ✅ ALL COMPLETE

**Summary**:
- 24 files removed (Groups 1-4)
- 41 archive files bulk-adapted (Group 5)
- ~65 files individually adapted (Groups 6-12)
- ~10 additional files fixed during verification
- All remaining BB/Flutter/Dart/Supabase references are in historical records only (feedback archives, process-improvement-tracking log entries)
