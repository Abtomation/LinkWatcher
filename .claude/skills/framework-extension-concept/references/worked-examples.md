# Worked Examples & Troubleshooting

## Example 1: Creation-type — placeholder replacement

**Before:**
```
Extension Name: [Extension Name]
Description: [Brief description of the extension]
Components: [List of components to be created]
```

**After:**
```
Extension Name: Multi-Language Support Extension
Description: Enable framework documentation and tasks to support multiple languages with
translation workflows and localized templates
Components:
- Language-specific task templates
- Translation workflow tasks
- Localized documentation templates
- Language preference management
```

## Example 2: Creation-type — measurable success criteria and timeline

**Before:**
```
Success Criteria: [How will you measure success]
Timeline: [Expected implementation timeline]
```

**After:**
```
Success Criteria:
- Task execution time tracking implemented
- Performance bottleneck identification automated
- Performance reports generated for all task types
- 90% of tasks show measurable performance metrics

Timeline: 4 sessions over 2 weeks
- Session 1: Performance tracking task definitions
- Session 2: Monitoring templates and data collection
- Session 3: Reporting and visualization components
- Session 4: Integration and testing
```

## Example 3: Modification-type — fully populated completeness tables

**Scenario:** every IMP is risk-classified during execution (Low / Medium / High), but the
classification is never persisted — it lives only in the session transcript. The extension
adds a `Risk Class` column to the Process Improvement tracking table. Uses
`New-FrameworkExtensionConcept.ps1 -Type Modification`.

**Selected Type:** Modification

**Modification Plan** *(order and grouping — schema first so the script can be tested
against the new column):*

| Order | Modification | Target Artifact | Type |
|-------|-------------|-----------------|------|
| 1 | Add a `Risk Class` column after `Status` | process-improvement-tracking.md | Schema |
| 2 | Add a `-RiskClass` parameter that writes the new column | Update-ProcessImprovement.ps1 | Logic |
| 3 | Document the persisted field at the execution and completion steps | process-improvement-task.md | Doc |

**Estimated session count:** 1

**State Tracking Audit** *(every state file the extension modifies):*

| State File | Current Purpose | Modification Needed | Change Type |
|-----------|-----------------|---------------------|-------------|
| process-improvement-tracking.md | Tracks all IMP lifecycle status | Add a `Risk Class` column (Low / Medium / High) after the `Status` column | Add field |

**Cross-reference impact:** `Update-ProcessImprovement.ps1` locates columns by header name
when rewriting rows; the new header must be added to its column map in the same change or row
writes will misalign.

**Guide Update Inventory** *(every doc that references the modified artifacts):*

| File to Update | References To | Update Needed |
|---------------|---------------|---------------|
| process-improvement-task.md | The tracking-table columns at the execution and completion steps | Add `Risk Class` to the documented column list and note it is written at completion |
| process-improvement-task-reference-guide.md | The Risk classification table | Add a sentence: the applied class is now persisted in the tracking row |

**Discovery method:** `grep` for `process-improvement-tracking.md` and for the table's
header row across `process-framework/`.

**Automation Integration Strategy** *(every script that reads or writes the modified
artifacts):*

| Existing Script | Current Behavior | Required Change | Backward Compatible? |
|----------------|-----------------|-----------------|---------------------|
| Update-ProcessImprovement.ps1 | Writes Status / Date / Notes columns | Add optional `-RiskClass`; write the new column when supplied | No — pre-existing rows lack the column; the same run backfills them with `—` |

**New automation needed:** None — the one-time backfill rides on the existing row-rewrite
path.

**Why these tables matter:** for a Modification extension, the State Tracking Audit, Guide
Update Inventory, and Automation Integration Strategy together form the completeness
contract — every file that *reads* a modified artifact must be found before implementation,
or references silently rot. The `Discovery method` and `Cross-reference impact` rows are
where reviewers verify you actually swept for those readers rather than guessing.

## Troubleshooting

### Extension scope too broad

**Symptom:** concept becomes overwhelming — too many components, unclear implementation path.
**Cause:** solving multiple unrelated problems in one extension.
**Solution:** break into smaller focused extensions; separate the core capability from
supporting features; check whether existing tasks already handle some components; create
multiple smaller extensions with explicit dependencies.

### Human review rejection

**Symptom:** concept rejected at a review checkpoint.
**Cause:** insufficient justification for framework-level change, or unclear integration
strategy.
**Solution:** re-verify the extension is truly needed; deepen the integration analysis
against existing components; sharpen the unique value proposition; consider alternatives
using existing framework capabilities.

### Multi-session implementation stalls

**Symptom:** progress stops between sessions on unclear state or dependencies.
**Cause:** inadequate state tracking or an unclear roadmap.
**Solution:** update the temporary state file with current progress and explicit next steps;
break remaining work into smaller chunks; confirm required resources and scripts are
accessible.

### Integration conflicts

**Symptom:** new extension components conflict with existing framework components.
**Cause:** insufficient analysis of the existing framework during concept development.
**Solution:** pause implementation; identify the specific conflicts and root causes; redesign
to work with existing components; update the concept and get human re-approval if the change
is significant.
