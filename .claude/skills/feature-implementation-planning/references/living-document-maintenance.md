# Living-Document Maintenance

How to keep a Feature Implementation State file useful across sessions, tasks, and years. The
file serves **different purposes at different stages** — maintain the sections that stage reads:

| Lifecycle stage | Primary purpose | Key sections updated |
|---|---|---|
| Planning | Design validation, task sequencing | Feature Overview, Implementation Progress, Dependencies |
| Implementation | Progress tracking, context preservation | Current State, Implementation Progress, Code Inventory, Issues Log |
| Testing | Issue tracking, integration validation | Issues Log, Next Steps, Code Inventory |
| Post-implementation | Permanent feature documentation | Documentation Inventory, Design Decisions |
| Maintenance | Context for bug fixes, dependency understanding | Issues Log, Code Inventory, Dependencies |
| Extension | Foundation for modifications | Feature Overview, Code Inventory, Design Decisions |
| Onboarding | Existing-doc audit, extraction source | Documentation Inventory (Existing Project Documentation) |

## Update cadence

**After every work session** (never end a session without these three):
- Current State Summary — timestamp, completion %, move done items In Progress → Working,
  update/remove blockers
- Next Steps — 1–3 immediate actions with specifics, open questions, a clear starting point
- Implementation Progress — the current task's entry

**Immediately when it happens**:
- Issues & Resolutions Log — when a problem is discovered (status, severity, problem, impact,
  investigation; resolution + prevention when solved; reflect blockers in Current State)
- Code Inventory — when files are created/modified (with the matching code marker — see
  [bidirectional-markers.md](bidirectional-markers.md))
- Design Decisions — when an architectural choice is made (options, decision, rationale,
  implications, validation criteria; cross-reference the relevant Implementation Progress task)

**As needed**: Documentation Inventory (as docs are created), Dependencies (as integrations
appear).

## Session start pattern

1. Current State Summary (30-second orientation)
2. Next Steps → Immediate Next Actions
3. Issues & Resolutions Log — any blockers?
4. Implementation Progress — current task status
5. Code Inventory — what already exists

## Level-of-detail heuristics

- **Current State Summary**: high-level only, 3–5 items per subsection
- **Implementation Progress**: enough that someone else understands what was done
- **Code Inventory**: one row per file; key components, not every function
- **Design Decisions**: the *why* (rationale), not just the *what*
- **Issues Log**: enough to understand and prevent recurrence
- **Next Steps**: specific enough that the next person knows exactly what to do

## Finalization and beyond

Before marking `COMPLETE`: all tasks checked off in Implementation Progress, all files in Code
Inventory, all issues resolved or tracked, Documentation Inventory accurate — then set status
`COMPLETE`, completion 100%, **in place**. The file is never archived: keep maintaining it for
bug fixes (Issues Log + Code Inventory), extensions (Dependencies + Design Decisions), and as
the permanent context source for impact analysis.

## Self-review before marking a task complete

- Sections for the current stage complete; timestamps current; status and completion % honest
- Code Inventory matches the actual files, and every file carries its feature marker
- Design decisions recorded for major choices; issues logged with resolutions or tracked
- Next Steps and Current State give the next session a zero-context-loss start
- Links valid; template structure and status vocabulary respected

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Document feels overwhelming to maintain | Trying to perfect every section every time | Focus on Current State / Implementation Progress / Next Steps; update other sections as you naturally touch their subject matter |
| File no longer reflects reality | Updates only at task boundaries | Adopt the session-end trio above as a hard exit ritual; the `updated` timestamp tells you when it was last trusted |
| Can't find information quickly | Not using the section structure | Orientation → Current State; what's next → Next Steps; past choices → Design Decisions; specific code → Code Inventory; past problems → Issues Log |
| Stale Next Steps | Skipped at session end | It's the most expensive omission — the next session pays it back in re-discovery time |
