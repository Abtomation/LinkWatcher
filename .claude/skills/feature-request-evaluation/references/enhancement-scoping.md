# Enhancement State Tracking File Customization

`process-framework/scripts/file-creation/04-implementation/New-EnhancementState.ps1` creates an
Enhancement State Tracking file whose body is **17 pre-defined workflow blocks** mirroring the
standard feature-development workflow. Customizing it = evaluating each block **Applicable / Not
Applicable** for this specific enhancement, so the Feature Enhancement task knows what to execute
and what to skip. Done during Feature Request Evaluation's enhancement path, right after the
script runs. **Do not skip customization** — the generated placeholders are useless to the
executing task without it.

## Fill the header sections

- **Enhancement Overview** — target feature (ID + name), secondary features affected,
  one-sentence enhancement description, the human's original change request, approval date,
  estimated sessions, and **Affected Workflows** (WF-IDs from the target feature's `workflows:`
  metadata, or "None").
- **Scope Assessment** — files affected, design docs to amend (FDD/TDD/ADR or "None"), new tests
  required, interface impact (public vs internal), session estimate.
- **Dimension Impact Assessment** (populated by `-Dims`) — start from the parent feature's
  inherited Dimension Profile, then note any the enhancement **adds / elevates** (e.g. adds file
  writes → DI Critical; adds user input → SE Critical) or **reduces**, with per-dimension
  implementation concerns. See the
  [Development Dimensions Guide](../../../../process-framework/guides/framework/development-dimensions-guide.md).
- **Existing Documentation Inventory** — per doc type (FDD/TDD/ADR/Test Spec): ID + location +
  action ("N/A", or "None exists → Create").

## Evaluate each workflow block (the core step)

For **each** of the 17 blocks set five fields: **Applicable** (Yes/No), **Rationale**,
**Adaptation Notes**, **Deliverable**, **Session**. Not-Applicable blocks get `Applicable: No` + a
Rationale, with Adaptation Notes / Deliverable left "N/A" — the executing task skips them.

| Block | When to Mark Applicable | When to Mark Not Applicable |
|-------|------------------------|----------------------------|
| **1. Tier Reassessment** | Enhancement significantly changes feature complexity (e.g., adding a major subsystem to a Tier 1 feature) | Minor enhancement, overall complexity unchanged |
| **2. FDD Amendment** | Changes user-facing behavior on a Tier 2+ feature that has an FDD | No FDD, or purely internal change |
| **3. System Architecture Review** | Introduces new patterns, cross-cutting concerns, or architectural changes | Works within existing architecture |
| **4. API Design Amendment** | Modifies API endpoints, contracts, or data access patterns | No API changes |
| **5. DB Schema Design Amendment** | Requires new tables, columns, relationships, or migrations | No database changes |
| **6. TDD Amendment** | Changes technical design on a Tier 2+ feature that has a TDD | No TDD, or technical approach unchanged |
| **7. Test Specification** | Adds significant new testable behavior on a Tier 3 feature, or the existing spec needs updating | No spec needed, or existing tests cover the change |
| **8. Feature Implementation Planning** | Complex enough to benefit from upfront planning (multi-layer, multi-session) | Straightforward — proceed directly to implementation |
| **9. Data Layer Implementation** | Changes data models, repositories, or database integration | No data model changes |
| **10. State Management Implementation** | Changes state management, providers, or notifiers | No state layer changes |
| **11. UI Implementation** | Changes user interface components, widgets, or screens | No UI changes |
| **12. Integration & Testing** | Touches multiple layers needing integration verification | Single-layer change, no integration concerns |
| **13. Implementation Finalization** | Multi-session enhancement needs final cleanup and preparation | Single-session, no finalization needed |
| **14. Update Tests** | Changes testable behavior and tests exist or are needed | Trivial change, manual verification suffices |
| **15. Code Review** | Modifies core logic or has non-trivial changes (also validates acceptance criteria and benchmarks performance vs TDD targets — the consolidated quality gate). Marking it Applicable **routes** the feature to a standalone Code Review session after the enhancement is finalized (`-RestoredStatus "👀 Needs Review"`) — the enhancement session itself never performs the review of record | Trivial change (e.g., single config line) **and no inherited dimension is Critical** — an inherited-Critical dimension keeps this gate Applicable even for small-scope changes; when Not Applicable, finalization restores the `🟢 Completed` default |
| **16. User Documentation** | Adds or changes user-visible behavior (new CLI option, settings screen, changed output) needing handbook / quick-reference / README updates | Internal-only change, no user-facing impact |
| **17. Update Feature State** | **Always applicable** — the state file must always be updated. Also update `workflows:` metadata if the enhancement changes workflow participation, and User Workflow Tracking if workflow scope changes | Never mark as not applicable |

Then, for **multi-session** enhancements, group applicable blocks into sessions with a completion
checkpoint each (fill the Session Boundary Planning section); for single-session, remove that
section. Finally scan for any remaining `[bracketed placeholders]`.

### Per-block format (example)

```markdown
### Step 11: UI Implementation
- **Status**: [ ] Not started
- **Applicable**: Yes
- **Rationale**: Enhancement modifies PowerShell startup scripts (user-facing entry points).
- **Adaptation Notes**: Add process-detection logic to start_linkwatcher*.ps1 — check for a running
  LinkWatcher python process before starting a new instance.
- **Deliverable**: Updated startup scripts with duplicate-instance prevention
- **Session**: 1

### Step 15: Code Review
- **Status**: [ ] Not started
- **Applicable**: No
- **Rationale**: Trivial change with no behavioral impact on the core system.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A
```

(Block 17 — Update Feature State — is always `Applicable: Yes`.)

## Troubleshooting

- **Placeholders remain** — search the file for `[` and replace all; check the Applicable /
  Rationale / Adaptation Notes fields in every block.
- **Unsure if a block applies** — use the table above; when in doubt mark it applicable with a
  note (better for the executing task to evaluate-and-skip than to miss work).
- **Most/all blocks applicable, session estimate 3+, feels like a new feature** — likely
  misclassified. Re-evaluate with the human; if it's a new feature, archive this file and route
  through the new-feature path instead (Feature Request Evaluation → FDD → …).
