---
id: PF-VIS-041
type: Process Framework
category: Context Map
version: 1.1
created: 2025-01-15
updated: 2026-02-27
task_id: PF-TSK-041
---

# Bug Triage Context Map

## Purpose

Visual guide to the components, relationships, and information flow relevant to the Bug Triage task, helping AI agents understand the context and dependencies for systematic bug evaluation and prioritization.

## Context Map

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                BUG TRIAGE CONTEXT MAP                                       │
│                                                                                             │
│  INPUT SOURCES                    EVALUATION PROCESS                    OUTPUT TARGETS      │
│  ┌─────────────────┐             ┌─────────────────────┐              ┌───────────────┐     │
│  │ 🆕 Bug Reports  │────────────▶│   TRIAGE ANALYSIS  │─────────────▶│ 🔍 Triaged   │     │
│  │ • User Reports  │             │                     │              │   Bug Registry│     │
│  │ • Test Failures │             │ 1. Validity Check   │              │               │     │
│  │ • Code Reviews  │             │ 2. Impact Assessment│              │ • Priority    │     │
│  │ • Monitoring    │             │ 3. Severity Rating  │              │ • Severity    │     │
│  └─────────────────┘             │ 4. Priority Matrix  │              │ • Assignment  │     │
│                                  │ 5. Duplicate Check  │              │ • Rationale   │     │
│  REFERENCE DATA                  │  6. Effort Estimate │              │ • Estimates   │     │
│  ┌─────────────────┐             └─────────────────────┘              └───────────────┘     │
│  │ Feature Context │                        │                                               │
│  │ • Feature Priorities                     │                                               │
│  │ • Implementation Status                  ▼                                               │
│  │ • Dependencies                  ┌─────────────────────┐                                  │
│  │ • Feature State File            │  DECISION FRAMEWORK │                                  │
│  │   (known issues, bugs)          │                     │                                  │
│  └─────────────────┘               │                     │                                  │
│                                    │                     │                                  │
│  ┌─────────────────┐               │ Priority Matrix:    │                                  │
│  │ System Context  │               │ Impact × Frequency  │                                  │
│  │ • Architecture  │               │                     │                                  │
│  │ • Components    │               │ Special Rules:      │                                  │
│  │ • Interfaces    │               │ • Security = P1     │                                  │
│  │ • Data Flow     │               │ • Data Loss = P1    │                                  │
│  └─────────────────┘               │ • Regression = Feat │                                  │
│                                    └─────────────────────┘                                  │
│                                                                                             │
│  WORKFLOW INTEGRATION                                                                       │
│  ┌─────────────────┐               ┌─────────────────────┐              ┌─────────────────┐ │
│  │ Previous Tasks  │               │   CURRENT TASK      │              │ Next Tasks      │ │
│  │                 │               │                     │              │                 │ │
│  │ • Testing       │──────────────▶│    BUG TRIAGE      │─────────────▶│ • Bug Fixing    │ │
│  │ • Code Review   │               │                     │              │ • Feature       │ │
│  │ • User Reports  │               │ Evaluate & Assign   │              │   Implementation│ │
│  │ • Monitoring    │               │ Priority & Severity │              │ • Documentation │ │
│  └─────────────────┘               └─────────────────────┘              └─────────────────┘ │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Relationships

### Critical Dependencies (Must Read)

- **[Bug Tracking](../../../../doc/state-tracking/permanent/bug-tracking.md)** - Central registry of all bugs with current status
- **[Feature Tracking](../../../../doc/state-tracking/permanent/feature-tracking.md)** - Feature priorities and relationships for impact assessment
- **[Visual Notation Guide](../../../guides/support/visual-notation-guide.md)** - For interpreting context map diagrams

### Important Context (Load If Space)

- **[Feature Implementation State Files](/doc/state-tracking/features)** - Affected feature's known issues, related bugs, and implementation progress
- **[Project Architecture](/doc/technical/architecture)** - System understanding for impact assessment

### Reference Resources (Access When Needed)

- **[Process Improvement Tracking](../../../state-tracking/permanent/process-improvement-tracking.md)** - For identifying process-related bug patterns

## Information Flow

### Input Processing

1. **Bug Reports** → Collected from multiple sources (users, testing, monitoring)
2. **Reopened Bugs** → Previously closed bugs that recurred (moved from Closed section via Update-BugStatus.ps1)
3. **Context Gathering** → Feature priorities, system architecture, existing bugs
4. **Validation** → Confirm bug validity and reproduction steps

### Evaluation Process

1. **Impact Assessment** → Determine user and system impact
2. **Severity Rating** → Technical severity classification
3. **Priority Assignment** → Business priority using decision matrix
4. **Duplicate Detection** → Compare with existing bug registry
5. **Effort Estimation** → Rough complexity assessment
6. **Assignment Recommendation** → Suggest appropriate developer/team

### Output Generation

1. **Bug Registry Update** → Status change from 🆕 Reported (or 🔄 Reopened) to 🔍 Triaged
2. **Documentation** → Rationale, priority, severity, estimates
3. **Workflow Trigger** → Enable next tasks (Bug Fixing, Feature Implementation)

## Decision Points

### Priority Assignment Matrix

| Impact | Frequency  | Priority           |
| ------ | ---------- | ------------------ |
| High   | High       | P1 (Critical)      |
| High   | Medium/Low | P2 (High)          |
| Medium | High       | P2 (High)          |
| Medium | Medium/Low | P3 (Medium)        |
| Low    | Any        | P3/P4 (Medium/Low) |

### Special Considerations

- **Security Issues** → Always P1
- **Data Loss Bugs** → Always P1
- **Regression Bugs** → Priority based on affected feature
- **Performance Issues** → Priority based on user impact

## Context Handoff Points

### From Previous Tasks

- **Testing** → Failed test cases and quality issues
- **Code Review** → Code quality and functionality problems
- **User Reports** → Real-world usage issues

### To Next Tasks

- **Bug Fixing** → Triaged bugs ready for resolution
- **Feature Implementation** → Bugs revealing feature gaps
- **Documentation Management** → Documentation updates needed
- **Process Improvement** → Process-related issues identified

## AI Agent Guidance

### Context Loading Priority

1. Load bug tracking and feature tracking state files first
2. For each bug, load the affected feature's implementation state file for known issues and related bugs
3. Understand current system priorities and architecture
4. Review similar bugs for consistency in triage decisions
5. Access testing and architecture guides as needed

### Decision Making Support

- Use the priority matrix consistently
- Document rationale for all decisions
- Consider system-wide impact, not just local effects
- Balance technical severity with business priority
- Look for patterns that might indicate systemic issues

### Quality Assurance

- Ensure all reported bugs are evaluated
- Verify duplicate detection is thorough
- Confirm assignment recommendations are appropriate
- Document effort estimates for planning purposes
- Update statistics and metrics in bug tracking
