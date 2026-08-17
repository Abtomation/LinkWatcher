# ADR Worked Examples

Two condensed examples of the customization approach (the task creates the document via
`process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1`; these show how
the sections are then filled).

## Example 1: State Management Pattern Selection

- **Context**: need for consistent state management across the application; current pain points
  with ad-hoc state handling; scalability requirements.
- **Decision**: the chosen state-management solution, selected for type safety, testability, and
  framework integration.
- **Impact Assessment**: Technical Risk: Medium · Effort: 2–3 weeks · Affected: all UI screens and
  data layers · Migration: yes · Performance: positive · Security: none.
- **Alternatives** (structured): Option A — pros (familiar, simple) / cons (limited composition) /
  rejected: scalability. Option B — pros (predictable, testable) / cons (verbose, steep learning
  curve) / rejected: complexity overhead. Option C — pros (feature-rich, fast) / cons (opinionated,
  global-state issues) / rejected: maintainability.
- **Consequences**: + testability, type safety, performance; − learning curve, migration effort.
- **References**: chosen framework docs, state-management best practices, related assessments.

## Example 2: Database Migration Strategy

- **Context**: manual schema changes are error-prone; automated migrations needed for production
  deployments.
- **Decision**: automated migration system using the project's database migration tools with
  version-control integration.
- **Impact Assessment**: Technical Risk: Low · Effort: 1 week · Affected: database layer +
  deployment pipeline · Migration: no · Performance: neutral · Security: improved
  (version-controlled schema changes).
- **Alternatives**: manual migrations — pros (simple, direct control) / cons (error-prone, not
  scalable) / rejected: reliability. Custom scripts — pros (flexible) / cons (maintenance overhead,
  reinventing the wheel) / rejected: development cost. Third-party tools — pros (feature-rich,
  proven) / cons (vendor lock-in, learning curve) / rejected: integration complexity.
- **Consequences**: + deployment reliability, fewer manual errors; − initial setup complexity.
- **References**: migration tool docs, database versioning best practices, pipeline requirements.
