---
id: PF-GDE-049
type: Document
category: General
version: 1.0
created: 2026-03-15
updated: 2026-03-15
guide_category: guides
guide_status: Active
guide_title: Manual Test Case Customization Guide
guide_description: Step-by-step instructions for customizing manual test case and master test templates created by New-ManualTestCase.ps1
related_script: New-ManualTestCase.ps1
related_tasks: PF-TSK-069
---

# Manual Test Case Customization Guide

## Overview

This guide explains how to use `New-ManualTestCase.ps1` to create manual test cases and how to customize the generated output. The script creates the directory structure, assigns IDs, and updates tracking files automatically. Your job is to customize the `test-case.md` content and populate the fixture directories.

## When to Use

Use this guide when the [Manual Test Case Creation task (PF-TSK-069)](/doc/process-framework/tasks/03-testing/manual-test-case-creation-task.md) requires you to create concrete test cases. The script handles infrastructure; this guide focuses on content customization.

## Prerequisites

- Test specification, bug report, or refactoring plan identifying what needs manual testing
- Feature ID and name for the feature being tested
- Understanding of the test group this case belongs to (or decision to create a new group)

## Step-by-Step Instructions

### 1. Run the Creation Script

**New group + first test case:**

```bash
cd /c/path/to/project/doc/process-framework/scripts/file-creation && pwsh.exe -ExecutionPolicy Bypass -Command '& .\New-ManualTestCase.ps1 -TestCaseName "descriptive-name" -GroupName "group-name" -FeatureId "X.Y.Z" -FeatureName "Feature Name" -NewGroup -Source "Test Spec PF-TSP-NNN" -Description "Brief description" -Confirm:$false'
```

**Additional test case in existing group:**

```bash
cd /c/path/to/project/doc/process-framework/scripts/file-creation && pwsh.exe -ExecutionPolicy Bypass -Command '& .\New-ManualTestCase.ps1 -TestCaseName "descriptive-name" -GroupName "group-name" -FeatureId "X.Y.Z" -FeatureName "Feature Name" -Source "Test Spec PF-TSP-NNN" -Description "Brief description" -Confirm:$false'
```

**Script output:**
- `test/manual-testing/templates/<group>/MT-NNN-<name>/` directory with `test-case.md`, `project/`, `expected/`
- If `-NewGroup`: `master-test-<group-name>.md` in the group directory
- Updated test-tracking.md (new entry with status `📋 Case Created`)
- Updated feature-tracking.md (Test Status updated)
- Updated master test "If Failed" table (new row added)

### 2. Customize test-case.md

The script pre-fills metadata (ID, group, feature, priority, dates, source). You need to customize:

**Preconditions** — Replace placeholders with exact starting state:
- What services must be running and with what configuration
- What the file system state must be before starting
- Any specific settings or environment variables

**Test Fixtures** — Document what's in the `project/` directory:
- List each fixture file with its purpose
- Describe relevant content that the test depends on

**Steps** — Replace placeholder steps with exact, unambiguous actions:
- One action per step
- Specify the exact tool (File Explorer, VS Code, command line)
- Specify the exact target (file path, UI element, command)
- Add wait/observe steps where timing matters (e.g., "Wait 2-3 seconds for events to process")

**Expected Results** — Define concrete outcomes:
- File Changes table: exact file, line, before/after content
- Behavioral Outcomes: log messages, UI state, service behavior
- Reference `expected/` directory if the entire post-test state is captured there

**Verification Method** — Select applicable methods:
- Automated comparison via `Verify-TestResult.ps1`
- Visual inspection
- Log checking

**Pass Criteria** — Define measurable conditions that must ALL be true.

### 3. Populate project/ Directory

Add the exact files needed as the starting state of the test. These should be:
- Complete, valid files (not stubs)
- Minimal — only what the test needs, not an entire project
- Self-contained — the test should work with only these files

### 4. Populate expected/ Directory

Add files in their expected post-test state. This enables automated comparison via `Verify-TestResult.ps1`. Only include files that should change during the test.

### 5. Customize Master Test (New Groups Only)

If you created a new group with `-NewGroup`, customize `master-test-<group-name>.md`:

**Quick Validation Sequence** — This is the curated part that requires judgment:
- Combine key scenarios from individual test cases into a sequential flow
- Order steps to build on each other where possible
- Each step should produce a verifiable result

The "If Failed" table is automatically maintained by the script when you add new test cases.

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Group directory | `<descriptive-name>` | `basic-file-operations` |
| Test case directory | `MT-NNN-<descriptive-name>` | `MT-001-single-file-rename` |
| Master test file | `master-test-<group-name>.md` | `master-test-basic-file-operations.md` |
| Test case file | `test-case.md` (always) | `test-case.md` |

## Script Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-TestCaseName` | Yes | Short descriptive name (used in directory, e.g., `single-file-rename`) |
| `-GroupName` | Yes | Test group name (must match existing directory, or use `-NewGroup`) |
| `-FeatureId` | Yes | Feature ID (e.g., `1.1.1`) |
| `-FeatureName` | Yes | Human-readable feature name |
| `-Priority` | No | P0/P1/P2/P3 (default: P1) |
| `-Source` | No | What triggered creation (e.g., `Test Spec PF-TSP-038`) |
| `-Description` | No | Brief description of what the test validates |
| `-NewGroup` | No | Switch to create a new group directory + master test |
| `-OpenInEditor` | No | Opens test-case.md in default editor after creation |

## Troubleshooting

### Group directory does not exist

**Symptom:** Script throws "Group directory does not exist"

**Solution:** Either use `-NewGroup` to create the group, or check that `-GroupName` matches an existing directory name exactly.

### Master test not updated

**Symptom:** New test case not appearing in master test's "If Failed" table

**Cause:** Master test file name doesn't match `master-test-<GroupName>.md` convention

**Solution:** Ensure the master test file follows the naming convention exactly.

## Related Resources

- [Manual Test Case Creation Task](/doc/process-framework/tasks/03-testing/manual-test-case-creation-task.md) — Task definition
- [Manual Test Case Template](/doc/process-framework/templates/03-testing/manual-test-case-template.md) — Template for test-case.md
- [Manual Master Test Template](/doc/process-framework/templates/03-testing/manual-master-test-template.md) — Template for master test files
- [New-ManualTestCase.ps1](/doc/process-framework/scripts/file-creation/03-testing/New-ManualTestCase.ps1) — Creation script
