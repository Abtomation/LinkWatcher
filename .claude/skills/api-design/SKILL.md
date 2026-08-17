---
name: api-design
description: >-
  Craft for customizing API design documents (PD-API) well — the "how to fill them" half of the
  framework's API Design task (PF-TSK-020), covering both artifact kinds: API Specifications
  (REST vs. Service-Interface template selection, auth strategy, error-handling granularity) and
  API Data Models (flat-vs-nested structure, required-vs-optional fields, validation granularity,
  versioning). Activated only from the API Design task's Check-Recommended-Skills step (via
  recommended_skills); not a REST-implementation, backend-coding, or schema-design skill.
user-invocable: false
---

# API Design Craft

This skill owns the **craft** of customizing API design documents — *how* to fill PD-API
specification and data-model documents well. It is the customization-craft home for the **API
Design task (PF-TSK-020)**, which owns everything else: task selection, role, checkpoints,
document creation via scripts, state-file updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create documents, or write state from this skill — those stay in the task. This skill drives the
> contract and model customization between the task's checkpoints.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates the documents with the framework's
agnostic scripts — always via script, never hand-authored, so IDs, metadata, and structure stay
framework-consistent:

- `process-framework/scripts/file-creation/02-design/New-APISpecification.ps1` — creates the API
  Specification; `-APIType` selects the template variant (the load-bearing decision — see below).
- `process-framework/scripts/file-creation/02-design/New-APIDataModel.ps1` — creates request/response
  Data Model documents.
- `process-framework/scripts/file-creation/02-design/New-APIDocumentation.ps1` — optional
  developer-facing documentation page.

## The load-bearing decision: API type selects the template

`-APIType` picks the underlying template, and the two variants are structurally different:

| `-APIType` value | Template emitted | Use when |
|---|---|---|
| `Service Interface` | Service-Interface variant (PF-TEM-078) | Subprocess / COM / file-system / library / IPC contracts. Per-integration sections (Purpose, Invocation contract, Inputs, Outputs, Error model, Concurrency, Versioning) instead of REST endpoints. |
| `REST` (default) | REST variant (PF-TEM-021) | HTTP/REST APIs with endpoints, status codes, and credential-based auth. |
| `GraphQL`, `gRPC`, anything else | Same as `REST` | Fall through to the REST template; adapt manually (e.g. replace `HTTP_METHOD ENDPOINT_PATH` with GraphQL operation or gRPC service/method names). |

Pick **Service Interface** for any non-network integration boundary where the REST
endpoint/auth/status-code model is structurally wrong; **REST** for resource-based APIs over HTTP.

## Per-artifact craft (load only the one you need)

- **API Specification** (auth strategy, error-handling granularity, documentation detail, the
  Service-Interface worked example) →
  [references/api-specification.md](references/api-specification.md)
- **API Data Model** (flat-vs-nested, required-vs-optional, validation granularity, versioning,
  worked example) → [references/api-data-model.md](references/api-data-model.md)

## Separation of concerns

API design documents own **API-level concerns only**: endpoints/contracts, request/response
schemas, auth patterns, status codes, versioning, rate limiting, API-level validation. Everything
else is referenced, not duplicated — database schema → Database Schema Design (PF-TSK-021); service
implementation / architecture → TDD; functional requirements → FDD; detailed test plans → Test
Specification. Canonical ownership rules and the cross-reference format live in the
[Information Flow Guide — API Design Task](../../../process-framework/guides/framework/information-flow-guide.md#api-design-task-pf-tsk-020).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Spec sprawls across too many endpoints | Multiple APIs documented in one file | Split per business domain / responsibility; link related specs |
| References data models that don't exist or drift | Spec written before the models | Create models first via `New-APIDataModel.ps1`; link the actual PD-API documents |
| Model balloons into deep nested structures | One model documenting too many relationships | Split into parent + child models; use the **Relationships** section to connect them |
| Validation rules don't match the running API | Doc drifted from implementation | Re-derive constraints from the endpoint code; split per API version if they differ |

(Script path / module-resolution errors: see the
[Script Development Quick Reference](../../../process-framework/guides/support/script-development-quick-reference.md).)
