---
id: PF-TEM-019
type: Process Framework
category: Template
version: 1.2
created: 2025-07-04
updated: 2026-08-04
creates_document_type: Product Documentation
creates_document_category: Assessment
description: "Template for feature tier assessments"
---

# Documentation Tier Assessment: [Feature Name]

## Feature Description

[Brief description of the feature]

## Implementation Medium

> What this feature's deliverable is made of. **Declared, never inferred**, and declared at two levels only — here (the determination) and in the feature's implementation state file §2 (the carry-forward). Never on an individual artifact; which artifacts are of which kind is visible in the state file's inventories. The test is *who executes it*: a prompt or template consumed by your own code is code's data, not instruction. No box checked parses as **Code**.

- [ ] Code - [Every deliverable artifact is program code]
- [ ] Instruction - [Every deliverable artifact is markdown an agent executes — a procedure, prompt system, or playbook that is part of the delivered function]
- [ ] Mixed - [One-line composition note: which parts are instruction, which are code]

## Complexity Assessment

| Factor                | Weight | Score | Weighted Score   | Justification                    |
| --------------------- | ------ | ----- | ---------------- | -------------------------------- |
| **Scope**             | 0.8    | [1-3] | [Score * Weight] | [Components affected]            |
| **State Management**  | 1.2    | [1-3] | [Score * Weight] | [Complexity of state management] |
| **Data Flow**         | 1.5    | [1-3] | [Score * Weight] | [Complexity of data flow]        |
| **Business Logic**    | 2.5    | [1-3] | [Score * Weight] | [Complexity of business rules]   |
| **UI Complexity**     | 0.5    | [1-3] | [Score * Weight] | [Complexity of UI components]    |
| **API Integration**   | 1.5    | [1-3] | [Score * Weight] | [Complexity of API interactions] |
| **Database Changes**  | 1.2    | [1-3] | [Score * Weight] | [Extent of database changes]     |
| **Security Concerns** | 2.0    | [1-3] | [Score * Weight] | [Security requirements]          |
| **New Technologies**  | 1.0    | [1-3] | [Score * Weight] | [New technologies introduced]    |

**Sum of Weighted Scores**: [Sum of all weighted scores]
**Sum of Weights**: [Sum of all weights]
**Normalized Score**: [Sum of Weighted Scores] / [Sum of Weights]

## Design Requirements Evaluation

### UI Design Required

- [ ] Yes - [Justification for why UI design is needed]
- [ ] No - [Brief explanation of why UI design is not required]

### API Design Required

- [ ] Yes - [Justification for why API design is needed]
- [ ] No - [Brief explanation of why API design is not required]

### Database Design Required

- [ ] Yes - [Justification for why database design is needed]
- [ ] No - [Brief explanation of why database design is not required]

### Instruction Design Required

> Independent of the medium above: medium says what the deliverable is made of, this says whether the feature has an instruction dimension to design. A `Mixed` feature normally answers Yes here *and* to one or more of the three above.

- [ ] Yes - [Justification for why an instruction design is needed]
- [ ] No - [Brief explanation of why instruction design is not required]

## Documentation Tier Assignment

**Assigned Tier**:

- [ ] Tier 1 (Simple) 🔵 (1.0-1.6)
- [ ] Tier 2 (Moderate) 🟠 (1.61-2.3)
- [ ] Tier 3 (Complex) 🔴 (2.31-3.0)

## Rationale

[Explanation of why this tier was assigned, including any special considerations]

## Special Considerations

- [Any special considerations that might affect the tier assignment]
- [High-risk aspects]
- [Unfamiliar domains]
- [Dependencies on other features]

## Implementation Notes

[Any notes that might be helpful for implementation]
