---
variant_group: validation-dimension-paths
description: "AI Agent Continuity dimension path for Dimension Validation — analysis steps and criteria for context clarity, modular structure, and documentation quality supporting AI agent workflow continuity"
---

# AI Agent Continuity — Validation Dimension Path

> **Parent task**: [Dimension Validation](dimension-validation-task.md) (PF-TSK-092). Execute the shared process there; this path file supplies the dimension-specific content that plugs into the parent's steps 2, 3, 5, 7, 8, and 12, plus the tokens for steps 6 and 13.
>
> | `-ValidationType` (step 6) | `Dims` (step 13) |
> |---|---|
> | `AIAgentContinuity` | see note below |
>
> **Standalone note**: AI Agent Continuity is a standalone validation task, not a development dimension — it does not appear in feature Dimension Profiles, and is included in validation rounds for projects using AI-assisted development workflows. It has no dedicated `Dims` code; tech-debt items it raises use the most applicable development-dimension code (commonly `DA` for documentation/workflow-quality findings).
>
> **Scope note**: workflow-optimization focus — run with `-FeatureIds "workflow-optimization"`.

## AI Agent Role (parent: AI Agent Role)

**Role**: Continuity Specialist
**Mindset**: Workflow-focused, context-aware, session-continuity oriented
**Focus Areas**: Context clarity, modular structure, documentation quality, AI agent workflow optimization, session handoff effectiveness
**Communication Style**: Identify workflow bottlenecks and context gaps, recommend structural improvements for AI agent effectiveness, ask about multi-session development patterns when evaluating continuity needs

## Dimension Context (parent step 2)

- **Process Framework Documentation** - structure and organization of the process framework
- **Task Definitions** - [Tasks Directory](../../tasks) - task structure and workflow patterns for AI agent execution
- **State Tracking Files** - [State Tracking Directory](../../state-tracking) - session continuity and progress tracking patterns
- **AI Tasks System** - [AI Tasks Registry](../../ai-tasks.md) - task discovery and selection patterns

## Dimension Criteria (parent step 3)

Review AI agent workflow patterns and session handoff requirements.

## Execution Analysis Steps (parent step 5)

5a. **Context Clarity Assessment**: Evaluate how well the codebase provides clear context for AI agent understanding
5b. **Modular Structure Analysis**: Assess code organization and component separation for AI agent navigation
5c. **Documentation Quality Evaluation**: Review documentation completeness and clarity for AI agent workflow support
5d. **Session Continuity Review**: Evaluate state tracking and progress documentation for multi-session workflows
5e. **Workflow Optimization Analysis**: Assess task structure and process guidance for AI agent effectiveness

## Scoring & Findings (parent steps 7–8)

- Apply the 4-point scoring system (0–3) to each AI agent continuity criterion.
- Record specific workflow bottlenecks, context gaps, and optimization recommendations.

## Remediation Prioritization (parent step 12)

Create action items for workflow and continuity improvements.

## Dimension Outputs (parent: Outputs)

- **AI Agent Continuity Validation Report** - created in `doc/validation/reports/ai-agent-continuity/PD-VAL-XXX-ai-agent-continuity-workflow-optimization.md`
- **Workflow Bottleneck Analysis** - AI agent workflow obstacles and context gaps
- **Continuity Gap Assessment** - session handoff effectiveness and multi-session workflow support
- **Optimization Recommendations** - recommendations for improving AI agent workflow continuity and effectiveness
