---
id: TE-E2E-018
type: E2E Acceptance Test Case
group: TE-E2G-008
feature_ids: ["2.1.1", "2.2.1", "1.1.1"]
workflow: WF-005
priority: P2
execution_mode: scripted
estimated_duration: 5 minutes
source: Cross-Cutting Spec PF-TSP-044 S-015
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-018 File Referenced From All Formats

## Preconditions

- [ ] LinkWatcher is running and monitoring the workspace project directory
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group multi-format-references`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] The `project/reference/` directory does NOT exist yet

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/data/schema.md` | Target file that will be moved | `# Schema` with description |
| `project/docs/index.md` | Markdown file referencing the target | Link `[Schema](../data/schema.md)` |
| `project/config/paths.yaml` | YAML config referencing the target | `schema: data/schema.md` |
| `project/config/manifest.json` | JSON manifest referencing the target | `"schema": "data/schema.md"` |
| `project/scripts/loader.py` | Python file referencing the target | `SCHEMA_PATH = "data/schema.md"` |
| `project/README.md` | Project readme (not referencing target) | `# Project` with description |

## Steps

1. **Start LinkWatcher**: Ensure LinkWatcher is running and monitoring the workspace project directory
   - **Tool**: Command Line
   - **Target**: `python main.py` pointed at the workspace

2. **Wait for initial scan**: Allow LinkWatcher to complete its startup scan
   - **Duration**: Wait 3-5 seconds
   - **Observe**: Log output confirming all files including .yaml, .json, and .py are scanned

3. **Move target file**: Move `project/data/schema.md` to `project/reference/schema.md`
   - **Tool**: Command Line / File Explorer
   - **Target**: `project/data/schema.md` -> `project/reference/schema.md`

4. **Wait for processing**: Allow LinkWatcher to detect the move and update all referencing files
   - **Duration**: Wait 5-8 seconds for all file format parsers to process updates
   - **Observe**: Log output showing link updates across all four referencing files

5. **Verify Markdown**: Check that `docs/index.md` has the updated link
   - **Tool**: Text editor
   - **Target**: `project/docs/index.md`

6. **Verify YAML**: Check that `config/paths.yaml` has the updated path
   - **Tool**: Text editor
   - **Target**: `project/config/paths.yaml`

7. **Verify JSON**: Check that `config/manifest.json` has the updated path
   - **Tool**: Text editor
   - **Target**: `project/config/manifest.json`

8. **Verify Python**: Check that `scripts/loader.py` has the updated path
   - **Tool**: Text editor
   - **Target**: `project/scripts/loader.py`

## Scripted Action

**Script**: `run.ps1`
**Action**: Moves `project/data/schema.md` to `project/reference/schema.md`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `docs/index.md` | Schema link | `[Schema](../data/schema.md)` | `[Schema](../reference/schema.md)` |
| `config/paths.yaml` | schema field | `schema: data/schema.md` | `schema: reference/schema.md` |
| `config/manifest.json` | schema field | `"schema": "data/schema.md"` | `"schema": "reference/schema.md"` |
| `scripts/loader.py` | SCHEMA_PATH | `SCHEMA_PATH = "data/schema.md"` | `SCHEMA_PATH = "reference/schema.md"` |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of `data/schema.md` move to `reference/schema.md`
- LinkWatcher log shows link updates in all four file formats: .md, .yaml, .json, .py
- Each parser (Markdown, YAML, JSON, Python) correctly identifies and updates the reference

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-018` — compares workspace against `expected/`
- [ ] **Visual inspection**: Open all four referencing files and confirm updated paths
- [ ] **Log check**: Check application log for updates across all four file formats

## Pass Criteria

- [ ] `docs/index.md` contains `[Schema](../reference/schema.md)` (Markdown link updated)
- [ ] `config/paths.yaml` contains `schema: reference/schema.md` (YAML path updated)
- [ ] `config/manifest.json` contains `"schema": "reference/schema.md"` (JSON path updated)
- [ ] `scripts/loader.py` contains `SCHEMA_PATH = "reference/schema.md"` (Python string updated)
- [ ] `reference/schema.md` exists with original content
- [ ] `README.md` is unchanged (contains no reference to the moved file)
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `Failed`
- Note which pass criterion failed and which file format(s) were not updated
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- This test exercises all four major parser types simultaneously (Markdown, YAML, JSON, Python).
- If some formats update but others do not, this indicates a parser-specific issue rather than a general link update failure.
- The YAML and JSON files use root-relative paths (no `../` prefix) since they typically store project-root-relative references. The Markdown file uses a relative path from its own location.
