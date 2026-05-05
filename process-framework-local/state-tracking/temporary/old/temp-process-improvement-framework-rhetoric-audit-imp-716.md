---
id: PF-STA-101
type: Document
category: General
version: 2.0
created: 2026-05-04
updated: 2026-05-04
task_name: framework-rhetoric-audit-imp-716
---

# Temporary Process Improvement State: Framework Rhetoric Audit IMP-716

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a process improvement. Move to `process-framework-local/state-tracking/temporary/old` after all phases are complete.

## Improvement Overview

- **Improvement Name**: Framework Rhetoric Audit IMP-716
- **Source IMP(s)**: [PF-IMP-716](/process-framework-local/state-tracking/permanent/process-improvement-tracking.md) (replaces rejected PF-IMP-715)
- **Source Feedback**: User decision 2026-05-04 — narrowed scope chosen at Step 6 of PF-IMP-716 execution (Option B: targeted scope reduction)
- **Scope**: Targeted reduction of three high-confidence ornamental emphasis categories. **Skip** all rules mapping to documented past failures.

### In-Scope Categories

1. **Double-emoji markers**: text wrapped in matching emojis on both sides (e.g., `🚨 X 🚨`, `**🚨 TASK IS NOT COMPLETE 🚨**`). Action: strip the trailing emoji; keep the leading marker if the rule is otherwise load-bearing, or strip both if it's purely ornamental.
2. **Duplicate reinforcement**: a header that contains an emphasis word, immediately followed by a paragraph that restates the same rule with another emphasis word. Action: keep one of the two; remove the duplicated emphasis from the other.
3. **Ornamental bullet-list emphasis**: bullets in best-practices/checklist sections where the bullet itself communicates the rule, decorated with leading emoji + CAPS. Action: strip the emoji and reduce CAPS to standard sentence case while keeping the rule.

### Out-of-Scope (Do Not Touch)

The following are **load-bearing** and remain as-is even if they appear excessive:

- Task-selection-first rules (failed 3+ times per memory)
- LinkWatcher foreground/background warnings (foreground blocked sessions in past)
- Prohibited git commands (stash destroyed work in March 2026)
- Session limit warnings (3 IMPs/session — quality degrades beyond)
- IMP-as-raw-input directives (recently added based on documented behavior)
- CHECKPOINT markers on actual checkpoint steps (visual navigation anchor)
- Parallel session warnings (data corruption risk)
- One-batch-per-session for validation (documented violation)
- Any rule where memory or a feedback form documents a past failure

When in doubt, retain. The cost of a false-retain (keeping ornamental emphasis) is small. The cost of a false-strip (removing a rule that prevented past failures) is process regression.

## Audit Heuristic

For each candidate occurrence, in order:

1. **Search context for failure history**: does memory or recent feedback link this rule to a documented past failure? → **RETAIN**.
2. **Is it a structural marker (CHECKPOINT step label, MANDATORY FINAL STEP, SESSION LIMIT header)?** → **RETAIN** (navigation function).
3. **Is it doubled (`🚨 X ... 🚨`)?** → strip trailing decoration, evaluate remaining marker against #1-2.
4. **Is it a duplicate of an adjacent header/paragraph?** → keep one, downgrade the other to plain prose.
5. **Is it on a bullet that already communicates the rule via its content?** → strip leading emoji + CAPS, keep bullet content.

## Affected Components (Candidate Files)

Initial Grep on `🚨 CRITICAL|⚠️ MANDATORY|NEVER|🚨` — 30 files match. Most edits expected in high-density files:

| File | Occurrences | Likely In-Scope |
| ---- | ----------- | --------------- |
| process-framework/ai-tasks.md | 8 | 4-5 |
| process-framework/tasks/support/process-improvement-task.md | 9 | 3-4 |
| process-framework/tasks/support/task-creation-guide.md | 13 | 4-6 |
| process-framework/tasks/04-implementation/* (multiple) | 9 each | TBD per file |
| Others (templates, guides, scripts) | varied | TBD |

Full per-file inventory built during Session A (first audit session).

## Implementation Roadmap

### Phase 1: Setup & Heuristic (this session)

- [x] Sample analysis — completed during PF-TSK-009 Step 6
- [x] Scope narrowing — chosen by user at Step 6 (Option B)
- [x] Heuristic documented (above)
- [x] Out-of-scope rules documented (above)
- [x] Temp state file created (this file)

### Phase 2: Per-File Audit (multi-session)

Cadence: ~3-5 files per session to maintain checkpoint discipline. Each file:
- Read with context around each emphasis occurrence
- Apply heuristic, propose edits
- Step 6 checkpoint per file or file group (agent's call based on edit volume)
- Apply approved edits
- Move to next file

Suggested file ordering (high-density first):

- ✅ **Session A** (2026-05-04): ai-tasks.md, .ai-entry-point.md, process-improvement-task.md — 3 confident edits applied across 2 files
- ✅ **Session B** (2026-05-04): task-creation-guide.md, framework-extension-task.md, feature-implementation-planning-task.md — 10 edits applied across 3 files
- ✅ **Session C** (2026-05-04): 3 templates (root-cause) + bulk sweep of canonical templated pair across 55 task definitions + 3 additional concept-template Category 1+2 finds via verification grep — **116 edits across 61 files**
- ✅ **Session D** (2026-05-04): final remaining-files sweep — 3 file-specific Category 2/3 reductions in `assessment-guide.md`, `guide-creation-best-practices-guide.md`, `process-framework-task-registry.md`; remaining markers confirmed load-bearing or functional, retained per "when in doubt → retain"

### Phase 3: Finalization

- [x] Final grep to confirm scope handled — `🚨 ... 🚨` doubled patterns in `process-framework/`: zero matches (sole remaining match is dual-CHECKPOINT false positive on one line, out-of-scope per state file). `⚠️ ... ⚠️` and `🛑 ... 🛑` doubled patterns: zero matches.
- [x] Verify no out-of-scope rules accidentally modified — load-bearing keywords (`🚨 Select a task`, `🚨 SESSION LIMIT`, `🚨 ONE PHASE PER SESSION`, `🚨 CHECKPOINT`, `🚨 MANDATORY FINAL STEP`, `🚨 CRITICAL: The IMP is raw input`, `⚠️ PARALLEL SESSION CHECK`, `prohibited git`, `one-batch-per-session`) confirmed intact across 43 occurrences in 10 files.
- [x] Log tool changes in feedback DB — 65 entries logged total across Sessions A-D (changes #886 through #954)
- [x] Mark IMP-716 Completed in process-improvement-tracking.md (`Update-ProcessImprovement.ps1 -NewStatus Completed -Impact MEDIUM`, 2026-05-04 23:52)
- [x] Move this state file to `process-framework-local/state-tracking/temporary/old/`

## Session Tracking

### Session 1: 2026-05-04

**Focus**: Setup only — sample analysis, scope narrowing, heuristic documentation, state file creation. No content edits this session.

**Completed**:

- Sampled 20 occurrences across 3 files (ai-tasks.md, .ai-entry-point.md, process-improvement-task.md)
- Estimated ~50% load-bearing, ~50% reduction-eligible
- Narrowed scope to 3 high-confidence categories (Option B at Step 6)
- Documented audit heuristic and out-of-scope rules
- Created this state file

**Issues/Blockers**:

- None

### Session 2 (Session A): 2026-05-04

**Focus**: Per-file audit of three high-density files: ai-tasks.md, .ai-entry-point.md, process-improvement-task.md.

**Completed**:

- **Inventoried all emphasis markers** across the three files (30 occurrences total)
- **Applied heuristic per occurrence**: most occurrences mapped to out-of-scope load-bearing rules (task selection, LinkWatcher fg/bg, CHECKPOINT markers, session limits, IMP-as-input, parallel session, automation-scripts-first, prohibited git, completion-checklist failure history)
- **Step 6 checkpoint**: presented 3 confident edits + 1 borderline candidate to human; human approved confident edits, agent decided to retain the borderline case under the "when in doubt → retain" guidance
- **Edits applied**:
  1. `ai-tasks.md` line 504: removed duplicate `> **🚨 Remember**: A task is NOT complete...` callout (Category 2 — bare reinforcement of bullet item 13 directly above)
  2. `process-improvement-task.md` line 53: stripped trailing 🚨 from `🚨 CRITICAL: This task is NOT complete... 🚨` (Category 1 double-emoji marker)
  3. `process-improvement-task.md` line 218: stripped both 🚨 from `**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**` (Category 1 + Category 2 duplicate of header `## ⚠️ MANDATORY Task Completion Checklist` directly above). Result: `**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**` (preserved CAPS — functional negation emphasis, not ornamental).
- **Borderline case retained**: `.ai-entry-point.md` line 17 `- **🚨 CRITICAL**: Every task has a mandatory completion checklist...` — Category 3 candidate (bullet content communicates rule, surrounding bullets use category emojis), but completion-checklist failure history weighed against reduction.
- **Logged tool changes** in feedback DB (changes #886 and #887)
- **Side observation flagged**: `ai-tasks.md` ends abruptly at line 657 with truncated text "The framewor". Pre-existing issue unrelated to IMP-716 — not addressed under this scope. Worth filing separately if it matters.

**Harvest**: 3 confident edits across 2 files. Smaller than the per-file estimate suggested at setup; the high-density files in Session A are dense with load-bearing rules (most markers map to documented past failures or structural navigation).

**Issues/Blockers**:

- None

**Next Session Plan**:

- Session B focus: task-creation-guide.md, framework-extension-task.md, implementation tasks (per Phase 2 ordering)
- Same workflow: inventory → heuristic per occurrence → Step 6 checkpoint per file or file group → apply approved edits → log to feedback DB

### Session 3 (Session B): 2026-05-04

**Focus**: Per-file audit of three files: task-creation-guide.md, framework-extension-task.md, feature-implementation-planning-task.md (highest-density implementation task selected for cadence discipline).

**Completed**:

- **Inventoried all emphasis markers** across the three files (46 occurrences total: 17 + 13 + 16)
- **Step 6 checkpoint**: presented 6 confident edits + 5 borderlines with lean recommendations; human approved with full delegation ("Go on then with session C")
- **Edits applied** (10 total — 6 confident + 4 lean-drop borderlines, retained line 358):
  1. `task-creation-guide.md` line 23: dropped `🚨 CRITICAL:` prefix from `## Understanding the Two-Phase Task Creation Process` (header on a teaching point, not load-bearing rule)
  2. `task-creation-guide.md` line 380: stripped `**🚨 CRITICAL: ` and trailing `**` from Always-identify-dependencies bullet (Category 3, no documented failure history)
  3. `task-creation-guide.md` line 398: dropped `(🚨 MANDATORY)` parenthetical from Use-the-Task-Creation-Script step (Category 2 duplicate of rule on line 51)
  4. `task-creation-guide.md` line 445: stripped trailing 🚨 inside example markdown block (Category 1)
  5. `task-creation-guide.md` line 474: stripped both 🚨 from TASK IS NOT COMPLETE banner inside example block (Category 1+2)
  6. `framework-extension-task.md` line 62: stripped trailing 🚨 on doubled-emoji opener (Category 1)
  7. `framework-extension-task.md` line 167: dropped `⚠️ **CRITICAL**: ` from Script-outputs-are-STARTING-POINTS bullet (Category 2 duplicate of line 89)
  8. `framework-extension-task.md` line 232: stripped both 🚨 on TASK IS NOT COMPLETE banner (Category 1+2)
  9. `feature-implementation-planning-task.md` line 114: stripped trailing 🚨 on doubled-emoji opener (Category 1)
  10. `feature-implementation-planning-task.md` line 341: stripped both 🚨 on TASK IS NOT COMPLETE banner (Category 1+2)

- **Borderline retained**: `task-creation-guide.md` line 358 (`🚨 CRITICAL: Feedback collection MUST follow the structured process below`) — Category 3 candidate but feedback-skipping has documented failure history; "when in doubt → retain" applied. (On reflection: this is a tighter Category 2 case than originally judged; consider revisiting in a future cleanup session.)

- **Logged tool changes** in feedback DB (changes #888, #889, #890; `task-creation-guide.md` registered as new tool ID with `--new-tool` flag)

**Critical discovery (Session B)**: The canonical templated pair (`🚨 CRITICAL: This task is NOT complete... 🚨` opening callout and `🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨` closing banner) appears in **54–56 files** across `process-framework/`. This is the dominant pattern in the audit baseline. Source is the templates: `templates/support/task-template.md`, `templates/support/task-completion-template.md`, `templates/04-implementation/foundation-feature-template.md`. Existing task definitions inherited the pattern at creation time and need retrospective sweep.

**Issues/Blockers**:

- None

**Next Session Plan**:

- Session C focus: **revised** to handle the bulk templated-pair sweep before the originally planned validation-scripts/templates/guides scope. Phased approach:
  - **Phase 1**: Fix 3 template files (root-cause prevention for future tasks)
  - **Phase 2**: Bulk sweep ~54 task definitions for the canonical pair (mechanical, all match Category 1 + 2 heuristic)
  - **Phase 3**: Verify with grep that no `🚨 ... 🚨` remains in canonical-pair form across `process-framework/`
- Step 6 checkpoint at start of Session C to confirm phased approach before bulk execution

## Completion Criteria

- [ ] All candidate files audited with heuristic applied
- [ ] Per-file edits human-approved at checkpoints
- [ ] Out-of-scope rules verified untouched (re-grep load-bearing keywords)
- [ ] IMP-716 marked Completed
- [ ] Feedback DB entries logged
- [ ] This state file moved to `temporary/old/`

## Notes and Decisions

### Key Decisions Made

- **Narrow scope to ornamental subset (Option B)**: 2026-05-04. Rationale: full audit risked regression on documented past failures (~50% of occurrences are load-bearing). Targeted scope captures the high-confidence reduction wins (~30-40 occurrences) while leaving load-bearing rules intact.
- **Defer all edits to future sessions**: 2026-05-04. Rationale: Session 1 hit IMP #3 of 3 (session limit). Setup work (heuristic + state file) fits this session; per-file audits need fresh sessions.

### Implementation Notes

- Apply heuristic per occurrence, not per file — some files contain both load-bearing and ornamental emphasis.
- When in doubt → retain.
- The CHECKPOINT marker class (`🚨 CHECKPOINT` in step labels) is explicitly out-of-scope — navigation anchor consistency across task definitions matters more than emphasis reduction.
