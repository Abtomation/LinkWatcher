---
id: PD-REF-236
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-06-12
updated: 2026-06-12
priority: Low
refactoring_scope: Align pyproject.toml black/isort line-length (120) with the authoritative pre-commit gate (100)
target_area: Build tooling config (pyproject.toml)
mode: lightweight
---

# Lightweight Refactoring Plan: Align pyproject.toml black/isort line-length (120) with the authoritative pre-commit gate (100)

- **Target Area**: Build tooling config (pyproject.toml)
- **Priority**: Low
- **Created**: 2026-06-12
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: N/A (direct human request) — Align pyproject black/isort line-length with pre-commit gate

**Scope**: `[tool.black] line-length` and `[tool.isort] line_length` in pyproject.toml say 120, while the authoritative commit gate (`.pre-commit-config.yaml`) enforces black/isort at 100 — and the codebase is formatted at 100. The mismatch makes bare `black`/`dev format` runs (which read pyproject) produce 120-width output that the gate then rejects or that drifts (observed: `main.py` fails black at 100). Change both values to 100 so config matches the gate and reality. Not a registered TD item — requested directly by the human partner during the PD-BUG-102 code review session (surfaced as a review observation).

**Changes Made**:
- [x] `[tool.black] line-length: 120 → 100` (+ comment pointing at the pre-commit gate as the source of truth)
- [x] `[tool.isort] line_length: 120 → 100` (+ same comment)

> Plan-approval checkpoint (L5) disposition: the exact change inventory (both lines, direction 120→100, scope boundaries) was presented at the Step 1 Effort Assessment Gate and approved verbatim by the human partner — recorded here instead of re-presenting an identical plan.
>
> Root-cause note: the archived CI/CD tooling TDD (tdd-5-1-1, Dev Tooling Configuration tables) documents `line-length = 100` as the designed value for both tools — pyproject.toml had drifted to 120 against documented intent. This change restores the documented design; the archived TDD again matches reality.

**Test Baseline**: 936 passed, 0 failed, 3 skipped, 6 deselected, 4 xfailed (full suite `Run-Tests.ps1 -All -Coverage`, this session 14:38, no code changes since). Formatter-config-only change — pytest does not read `[tool.black]`/`[tool.isort]`, so no re-run planned; behavior preservation is verified via black/isort check equivalence instead (see Test Result).
**Test Result**: Formatter-config-only change — pytest re-run skipped (pytest reads neither `[tool.black]` nor `[tool.isort]`). Behavior-preservation verification instead: bare `python -m black --check` and `python -m isort --check-only` (both reading the updated pyproject) now pass the gate-clean files `handler.py`, `utils.py`, `service.py` unchanged — before the change, bare black wanted to reformat all three to 120. Local toolchain and pre-commit gate now agree.

**Documentation & State Updates**:
- [x] Items 1–8 batched N/A (build-config-only shortcut): formatter-config edit in pyproject.toml `[tool.*]` sections; no product code, tests, or `[tool.pytest.*]` touched; design, user-facing, and state documents do not reference build tooling config. Verified by grep across `doc/user/`, `README.md`, `doc/technical/` for line-length settings — only hit is the archived CI/CD tooling TDD, which documents 100 and now matches again (no edit needed).
- [x] Technical Debt Tracking: N/A — no TD item registered; change executed as a direct human request from the PD-BUG-102 code review session.

**Bugs Discovered**: None

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more debt items mid-session (i.e., new TD IDs — sub-findings of an existing TD become additional `Changes Made` bullets within its Item, not new Items), copy the "## Item N" section above. -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | N/A (human request) | Complete | None | None (archived TDD tdd-5-1-1 already documents 100 — restored to match) |

## Related Documentation
- [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md)
