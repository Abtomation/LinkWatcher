# Worked Scoping Examples

Four end-to-end walkthroughs of the decision matrix and E2E milestone evaluation. (Feature IDs and
modules are from a file-watcher product — map the shapes onto the current project.)

## Example 1: Parser Enhancement (Performance Tests Needed)

**Feature**: 2.1.1 Link Parsing System — adds backtick path detection to markdown parser

**Decision matrix walkthrough**:
- *Changes a parser or database module?* — **Yes**, modifies
  `src/<product>/parsers/markdown_parser.py`. → **Level 1 Component benchmark needed** for
  markdown parser throughput
- *Changes an end-to-end operation pipeline?* — **Yes**, parsing is part of initial scan and
  file-move handling. → **Level 2 Operation benchmark** should be verified (regression check, not
  new test if one exists)
- *Changes data structures, algorithms, or scaling?* — No, same algorithm, new pattern match only
- *Changes memory allocation, caching, or concurrency?* — No

**Result**: Add one Level 1 entry to performance-test-tracking.md targeting markdown parser
throughput. Verify existing Level 2 operation benchmark doesn't regress.

## Example 2: Configuration Enhancement (No Performance Tests Needed)

**Feature**: 0.1.3 Configuration System — adds new `validation_extensions` config option

**Decision matrix walkthrough**:
- *Changes a parser or database module?* — No, only `src/<product>/config.py`
- *Changes an end-to-end operation pipeline?* — No, config loading happens once at startup
- *Changes data structures, algorithms, or scaling?* — No
- *Changes memory allocation, caching, or concurrency?* — No

**Result**: No performance tests needed. Rationale: "Feature adds a configuration option read once
at startup — no hot-path impact."

## Example 3: Feature Completes a Workflow (E2E Tests Needed)

**Feature**: 6.1.1 Link Validation — the last feature needed for the "Link Health Audit" workflow

**E2E evaluation**:
1. Read user-workflow-tracking.md → 6.1.1 participates in "Link Health Audit" workflow
2. Check other features in workflow: 0.1.1 (Completed), 2.1.1 (Completed), 6.1.1 (now at Needs
   Test Scoping) → All features implemented
3. Workflow is now E2E-ready

**Result**: Add entry to e2e-test-tracking.md for "Link Health Audit" workflow with all three
participating features listed.

## Example 4: Feature Doesn't Complete Any Workflow (No E2E Tests)

**Feature**: 3.1.1 Logging System — participates in "Operational Monitoring" workflow

**E2E evaluation**:
1. Read user-workflow-tracking.md → 3.1.1 participates in "Operational Monitoring" workflow
2. Check other features: feature X.Y.Z is still at `🟡 In Progress` → workflow NOT E2E-ready

**Result**: No E2E tests yet. Document: "Operational Monitoring workflow requires X.Y.Z which is
still In Progress."
