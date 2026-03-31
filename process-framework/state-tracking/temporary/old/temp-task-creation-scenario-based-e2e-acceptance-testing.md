---
id: PD-STA-061
type: Document
category: General
version: 1.0
created: 2026-03-18
updated: 2026-03-18
task_name: scenario-based-e2e-acceptance-testing
---

# Multi-Session State: Scenario-Based E2E Acceptance Testing (PF-IMP-145)

> **TEMPORARY FILE**: Tracks multi-session implementation of PF-IMP-145. Move to `old/` after all sessions are complete.

## Overview

- **Improvement ID**: PF-IMP-145
- **Proposal**: [PF-PRO-008](../../../proposals/scenario-based-e2e-acceptance-testing.md)
- **Task**: PF-TSK-009 (Process Improvement)
- **Total Sessions**: 4 (1, 1.5, 2, 3)

## Session Plan

### Session 1: Content (Workflow Map + E2E Spec + Tracking Restructure)

**Status**: COMPLETED
**Date**: 2026-03-18

- [ ] Create User Workflow Map (`doc/product-docs/state-tracking/permanent/user-workflow-tracking.md`)
  - Identify all LinkWatcher user-facing workflows
  - Map each workflow to required features
  - Assign priorities
- [ ] Create `test/specifications/cross-cutting-specs/` directory
- [ ] Create cross-cutting E2E test specification using `New-TestSpecification.ps1 -CrossCutting`
  - Define scenario groups per workflow
  - Map scenarios to features
  - Prioritize by user impact and coverage gaps
- [ ] Add dedicated E2E section to test-tracking.md
  - Workflow Milestone Tracking sub-section
  - E2E Test Cases sub-section with Workflow and Feature IDs columns
  - Migrate existing E2E-001–004 and E2E-GRP-01–03 entries from per-feature sections
- [ ] Add E2E entries to test-registry.yaml for existing test cases (4 cases + 3 groups)
- [ ] Update documentation-map.md (workflow map, cross-cutting spec, cross-cutting-specs directory)
- [ ] Run Validate-StateTracking.ps1
- [ ] Feedback form

**Script bug fixed during session**: `New-TempTaskState.ps1` had garbled template path (`doc/product-docs/templates/templates/` → `process-framework/templates/support`)

### Session 1.5: E2E ID Rename + YAML Frontmatter

**Status**: COMPLETED
**Date**: 2026-03-18

Rename E2E IDs to follow standard prefix convention and add YAML frontmatter to all E2E files:
- `E2E-NNN` → `TE-E2E-NNN` (test cases)
- `E2E-GRP-NN` → `TE-E2G-NNN` (groups)

- [ ] Update id-registry.json: add TE-E2E and TE-E2G prefixes, remove old E2E and E2E-GRP
- [ ] Rename 4 test case directories (E2E-NNN → TE-E2E-NNN)
- [ ] Fix 4 test-case.md files: add YAML frontmatter, update IDs
- [ ] Fix 3 master-test.md files: add YAML frontmatter, update IDs
- [ ] Update test-tracking.md: all E2E entries with new IDs
- [ ] Update test-registry.yaml: all E2E entries with new IDs
- [ ] Update cross-cutting spec PF-TSP-044: all E2E references
- [ ] Update templates PF-TEM-053, PF-TEM-054: ID format + YAML frontmatter
- [ ] Update New-E2EAcceptanceTestCase.ps1: ID prefix logic
- [ ] Grep for remaining old E2E-NNN / E2E-GRP references
- [ ] Run Validate-StateTracking.ps1

### Session 2: Infrastructure (Script Updates)

**Status**: COMPLETED
**Date**: 2026-03-18

- [ ] Update `New-E2EAcceptanceTestCase.ps1`:
  - `-FeatureId` → `-FeatureIds` (comma-separated, backward-compatible)
  - Add `-Workflow` parameter (optional)
  - Add test-registry.yaml E2E entry creation
  - Target dedicated E2E section in test-tracking.md
  - Update test-case.md metadata template (`feature_ids` array)
- [ ] Update `TestTracking.psm1`:
  - `Add-TestImplementationEntry` supports `FeatureIds` array parameter
  - New function/parameter to target dedicated E2E section
- [ ] Update `Update-TestExecutionStatus.ps1`:
  - Search dedicated E2E section for entries
  - Update feature-tracking.md Test Status for all features in `FeatureIds` list
  - Update Workflow Milestone Tracking row status
- [ ] Update `Validate-TestTracking.ps1`:
  - Validate dedicated E2E section entries against disk and test-registry.yaml
  - Validate Workflow Milestone Tracking matches actual feature status
  - Cross-reference E2E entries between test-registry.yaml and test-tracking.md
- [ ] Test all scripts with `-WhatIf` or test invocations
- [ ] Run Validate-StateTracking.ps1
- [ ] Feedback form

### Session 3: Documentation (Task Definitions + Guides)

**Status**: COMPLETED
**Date**: 2026-03-18

- [ ] Update 7 task definitions:
  - PF-TSK-013 (Feature Discovery) — add workflow identification step
  - PF-TSK-065 (Codebase Feature Analysis) — add workflow identification step
  - PF-TSK-067 (Feature Request Evaluation) — add workflow map check
  - PF-TSK-012 (Test Specification Creation) — add cross-feature workflow section + fix legacy "manual" → "E2E" terminology
  - PF-TSK-069 (E2E Test Case Creation) — accept cross-cutting spec input, multi-feature attribution
  - PF-TSK-070 (E2E Test Execution) — workflow-based execution, dedicated section
  - PF-TSK-008 (Release & Deployment) — E2E coverage gate
- [ ] Update 4 guides:
  - PF-GDE-050 (Test Infrastructure Guide) — workflow map section, E2E section structure, test-registry.yaml format
  - PF-GDE-028 (Test Specification Creation Guide) — cross-feature workflow participation
  - PF-GDE-049 (E2E Acceptance Test Case Customization Guide) — multi-feature examples
  - PF-GDE-018 (Task Transition Guide) — milestone-triggered E2E workflow
- [ ] Update process-framework/ai-tasks.md — add milestone-triggered E2E workflow to Common Workflows
- [ ] Update documentation-map.md if any new entries needed
- [ ] Run Validate-StateTracking.ps1
- [ ] Mark PF-IMP-145 as Completed in process-improvement-tracking.md
- [ ] Feedback form (covers all 3 sessions)

## Key Decisions

- **Workflow map location**: `doc/product-docs/state-tracking/permanent/user-workflow-tracking.md` — product design artifact, sibling to feature-dependencies.md. One per project, no separate template/script.
- **E2E spec directory**: `test/specifications/cross-cutting-specs/` — for both Category A (e2e-spec-*) and Category B (integration-spec-*)
- **Tracking separation**: Workflow map holds planning data; test-tracking.md holds execution tracking data. Milestone rows bridge the two.
- **Multi-feature attribution**: `-FeatureIds` parameter (comma-separated), propagated to test-registry.yaml, test-tracking.md, and feature-tracking.md
- **Legacy terminology**: "manual" → "E2E" in PF-TSK-012 step 12
- **Script bug fix**: New-TempTaskState.ps1 template path corrected (doc/product-docs → doc/process-framework, templates/templates → templates/support)

## Completion Criteria

This file moves to `old/` when:
- [ ] All 3 sessions completed
- [ ] PF-IMP-145 marked as Completed
- [ ] Validate-StateTracking.ps1 passes
- [ ] Feedback form submitted
