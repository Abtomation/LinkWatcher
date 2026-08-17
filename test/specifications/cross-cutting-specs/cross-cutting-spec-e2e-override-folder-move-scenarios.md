---
id: TE-TSP-046
type: Document
category: General
version: 1.0
created: 2026-08-10
updated: 2026-08-10
description: "Cross-cutting E2E spec for WF-011 — override-folder move/rename scenarios: virtual-root link rewriting with a live daemon and path_resolution_overrides config"
feature_ids: ["0.1.3", "1.1.1", "0.1.2", "2.1.1", "2.2.1"]
test_name: E2E Override-Folder Move Scenarios
test_type: cross-cutting
---

# Cross-Cutting Test Specification: E2E Override-Folder Move Scenarios

## Overview

This document defines **E2E acceptance test scenarios** for [WF-011 "Override-folder move → virtual-root links updated"](/doc/state-tracking/permanent/user-workflow-tracking.md): a user restructures a folder configured in `path_resolution_overrides` (the blueprint use case), and host-absolute `/…` references between files inside that folder are matched against the folder's virtual root and rewritten — preserving their virtual-root style — while files outside every override folder are never touched.

These scenarios require a running LinkWatcher instance started with a config carrying a `path_resolution_overrides` mapping, and simulate real user actions (file rename, directory move) with observable outcomes.

**Test Type**: Cross-Cutting (E2E Acceptance)
**Workflow**: WF-011 (P2)
**Features Covered**: 0.1.3, 1.1.1, 0.1.2, 2.1.1, 2.2.1
**Created**: 2026-08-10
**Source Enhancement**: Blueprint-aware reference updating (PF-STA-110, feature 2.2.1, v1.1 design PD-TDD-026/PD-FDD-027)
**Implementation Coverage**: see [Coverage Summary](#coverage-summary)

## Feature Context

### Features Under Test

| Feature ID | Feature Name | Role in Cross-Cutting Scenario |
|------------|-------------|-------------------------------|
| 0.1.3 | Configuration System | Loads `path_resolution_overrides` from the YAML config and exposes it to the service wiring |
| 1.1.1 | File System Monitoring | Detects the file rename / directory move inside the override folder via delete+create pairing |
| 0.1.2 | In-Memory Link Database | Holds the indexed `/…` references from the initial scan; supplies batch lookups for the directory move |
| 2.1.1 | Link Parsing System | Extracts the host-absolute `/…` references from markdown fixtures during scan |
| 2.2.1 | Link Updating | Override-aware PathResolver: base-aware input resolution, base-stripping output reconstruction, containment guard, `update_resolution_override_applied` event |

### Integration Points

The override-aware behavior is **config-driven end to end**: the `path_resolution_overrides` key (0.1.3) is plumbed through `service.py` → `LinkUpdater` → `PathResolver` (2.2.1) and only takes effect when a real move event (1.1.1) resolves a database-held reference (0.1.2, parsed by 2.1.1) whose source file lies inside the configured folder. The unit and integration suites construct `PathResolver`/`LinkUpdater` directly; only an E2E run exercises the full config-file → daemon → live-rewrite chain.

### Justification for Cross-Cutting Specification

- The feature-level spec ([TE-TSP-040](../feature-specs/test-spec-2-2-1-link-updating.md) v1.1, scenarios a–f) covers override-aware resolution at unit/integration level with directly-constructed components. It cannot validate that a **user-supplied YAML config** actually reaches the resolver in a running daemon.
- The behavior spans five features working in concert: config load, FS event detection, database lookup, parsing, and rewrite — a failure anywhere in the wiring is invisible to per-feature tests.
- The workflow's defining guarantee — *files outside every override folder are never affected* — is a whole-project claim best asserted on a real workspace tree after a real daemon run.

## Test Scenarios

Scenario IDs are spec-scoped (`S-046-NN`) to avoid colliding with the S-NNN series in [TE-TSP-044](cross-cutting-spec-e2e-acceptance-testing-scenarios.md).

### WF-011: Override-Folder Move — Virtual-Root Links Updated

**Workflow**: User moves/renames files or directories inside a `path_resolution_overrides` folder; host-absolute `/…` references from sibling override-folder files are rewritten preserving virtual-root style.
**Features**: 0.1.3, 1.1.1, 0.1.2, 2.1.1, 2.2.1
**Priority**: P2

| ID | Scenario | Arrange | Act | Assert | Priority |
|----|----------|---------|-----|--------|----------|
| S-046-01 | Override-folder file rename → virtual-root links rewritten | Project with config mapping `blueprint: blueprint`; `blueprint/` tree where a sibling file references a target file as `/…` (virtual-root form); daemon running with that config | Rename the target file inside the override folder (the "-task suffix" founding use case) | Sibling file's `/…` reference rewritten to the new name, **leading-slash virtual-root style preserved** (not rewritten to a relative or on-disk path); log shows `update_resolution_override_applied` | High |
| S-046-02 | Outside-folder file is never affected | Same fixture additionally contains a file **outside** `blueprint/` holding the byte-identical `/…` reference string | Same action as S-046-01 / S-046-03 | Outside file is byte-for-byte unchanged | High |
| S-046-03 | Override-folder directory move → all contained refs updated | Same config; `blueprint/` contains a subdirectory with referenced file(s), referenced via `/…` from a sibling override-folder file | Move/rename the subdirectory inside the override folder (restructure case) | All `/…` references to contained files rewritten to the new directory path, virtual-root style preserved; outside file unchanged | High |

> **Deliberately not duplicated at E2E level** (covered by TE-TSP-040 v1.1 unit scenarios): non-existent-target containment guard (c), separator preservation on override rewrites (d), and the suffix-hijack gate (f). These are resolver-internal guards fully exercised by the automated suite; E2E adds no observational value over the unit assertions.

## Mock Requirements

None — E2E acceptance scenarios run against the real system (live daemon, real file system events, real config file). No mocks, stubs, or fakes.

## Test Implementation Guidance

### File Location

Scenarios are implemented as **E2E acceptance test cases** (not pytest tests):

```
test/e2e-acceptance-testing/override-folder-move-virtual-root-links-updated/templates/
```

Created via `New-E2EAcceptanceTestCase.ps1` (PF-TSK-069) with `-Workflow WF-011`; scripted cases are executable via `Run-E2EAcceptanceTest.ps1` (Setup → run.ps1 → wait → Verify).

### Dependencies Between Tests

- None — each test case runs from its own pristine fixture copy (`Setup-TestEnvironment.ps1`). S-046-02 is asserted inside both movement cases (negative control fixture) rather than as a standalone case.

## Coverage Summary

| Scenario | E2E Case | Group | Status |
|----------|----------|-------|--------|
| S-046-01 (+ S-046-02 control) | [TE-E2E-032](../../e2e-acceptance-testing/override-folder-move-virtual-root-links-updated/templates/TE-E2E-032-file-rename-virtual-root-links/test-case.md) | TE-E2G-014 | 📋 Needs Execution |
| S-046-03 (+ S-046-02 control) | [TE-E2E-033](../../e2e-acceptance-testing/override-folder-move-virtual-root-links-updated/templates/TE-E2E-033-directory-move-virtual-root-links/test-case.md) | TE-E2G-014 | 📋 Needs Execution |

## Related Resources

- [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) — WF-011 definition
- [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) — milestone + test case status
- [TE-TSP-040 Link Updating test spec](../feature-specs/test-spec-2-2-1-link-updating.md) — feature-level override-aware scenarios (a–f)
- [TE-TSP-044 E2E Acceptance Testing Scenarios](cross-cutting-spec-e2e-acceptance-testing-scenarios.md) — sibling spec for WF-001–WF-008
- [LinkWatcher Capabilities Reference](/doc/user/handbooks/linkwatcher-capabilities-reference.md) — override-folder virtual-root links (v2.2)

---
