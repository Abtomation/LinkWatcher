# Task Metadata Schema (PF-PRO-042)

The task file is the **single source of truth for task metadata**.
[`Build-TaskMetadata.ps1`](../../../../process-framework/scripts/validation/Build-TaskMetadata.ps1)
generates the ai-tasks.md task tables, the process-framework task registry, the
task-transition registry, and the tasks/README catalog from it — **never hand-edit those
generated surfaces**; edit the task file and regenerate. `-Check` is the pre-commit drift
gate; `-ReportMissing` flags any task missing a required field. The task's `description:`
frontmatter separately feeds `Build-DocumentationMap.ps1` — keep it one concise line.

## Frontmatter fields

Beyond the 8 standard fields (`id`, `type`, `category`, `domain`, `version`, `created`,
`updated`, `description`), every task file carries up to 7 metadata fields:

```yaml
complexity: simple | medium | complex     # renders 🟢/🟡/🔴 in routing tables
use_when: >-
  Routing text for the Use When column of ai-tasks.md.
triggers:                                  # example phrasings, appended to the Use When cell
  - "improve task X"
automation: full | semi | partial | manual # renders the catalog Process Type
scripts:                                   # file-relative paths (LinkWatcher-maintained on moves)
  - ../../scripts/file-creation/support/New-Task.ps1
trigger_status:                            # state-file status that activates this task
  - file: feature-tracking.md
    status: "📝 Needs TDD"
output_status:                             # state-file status this task produces
  - file: feature-tracking.md
    status: "🧪 Needs Test Spec"
    condition: ""                          # optional, for branching outputs
next_tasks:                                # downstream chain (mirrors the Next Tasks section)
  - task: ../03-testing/test-specification-creation-task.md
    condition: "Always"
```

## Per-category rules (`-ReportMissing` enforces these)

- `complexity` — required for categorized tasks (00–07); omitted for support and cyclical
  tasks (their routing tables have no Complexity column)
- `use_when`, `automation` — required for all tasks; cyclical tasks' `use_when` supplies the
  Trigger column text
- `frequency` — cyclical tasks only (renders the Frequency column, e.g. `"Quarterly/As needed"`)
- `triggers`, `scripts` — optional (omit when the task has no example phrasings / no
  automation scripts)
- `trigger_status` / `output_status` — required only for tasks activated by / producing a
  state-file status; where a trigger or output is prose rather than a `file → status` pair,
  use `raw: "<text>"` instead of `file`/`status`
- `next_tasks` — required whenever the Next Tasks section is non-empty

## Authored metadata body sections

Two authored body sections complete the metadata source (the template's TASK METADATA SCHEMA
comment marks them):

- **`## File Operations`** — a table of every file the task creates or updates: Operation
  (**Creates**/**Updates**), File Path, Update Method (script or manual), Details (status
  transitions, content changes). Aggregated into the task's registry catalog entry; keep it
  current when the task gains or loses file side-effects.
- **`## Next Tasks` transition subsections** — after the link list, three subsections
  aggregated into the transition registry, kept consistent with the `next_tasks` frontmatter:
  - **Prerequisites for Transition** — checklist of outputs/state required before leaving the
    task
  - **Next Task Selection** — decision tree (where branching) or plain rule
  - **Preparation for Next Task** — numbered steps that set up the next task's inputs

## Manual residue (NOT generated from the task's own file)

When a task is added or its chain changes, these are edited by hand in *other* files, then
projections regenerated: sibling tasks' `next_tasks` frontmatter and Related Resources; the
hand-written ai-tasks.md prose (decision tree, Common Workflows, workflow diagrams); the
registry's hand-written trigger-chain diagram region; and any reused supporting artifact's
back-reference (`related_task` frontmatter / Related Resources).
