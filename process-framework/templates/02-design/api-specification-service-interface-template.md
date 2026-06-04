---
id: PF-TEM-078
type: Process Framework
category: Template
version: 1.0
created: 2026-05-08
updated: 2026-05-08
usage_context: Process Framework - API Specification Creation (Service-Interface variant)
template_for: API Specification (Service Interface)
creates_document_prefix: PD-API
creates_document_type: API Specification
creates_document_category: API Specification
description: Template for Service-Interface API specifications — subprocess invocations, COM/in-process integrations, file-system contracts, library contracts. Sibling of PF-TEM-021 (REST/HTTP variant); selected by New-APISpecification.ps1 when -APIType "Service Interface".
creates_document_version: 1.0
---

# [API_NAME]

## Overview

[API_DESCRIPTION]

- **API Type**: [API_TYPE]
- **Owner Feature**: [Feature ID and name, e.g. 1.1.3 Invoice Generation]
- **Version**: 1.0

This document defines a **service-interface contract**: the boundary between this feature and one or more external systems that are **not** reachable as network endpoints. Each integration is wrapped in an internal adapter — this document is the contract those adapters must satisfy.

### Integration summary

> **Replace this table with one row per integration.** Drop or duplicate the per-integration sections below to match.

| Integration | Type | Platform | Owner Adapter | Wraps |
|---|---|---|---|---|
| [Integration 1 name] | [Process invocation / COM / File system / Library / IPC] | [All / Windows / macOS / Linux] | [AdapterClassName] | [Underlying library, binary, or system] |
| [Integration 2 name] | [Type] | [Platform] | [AdapterClassName] | [What it wraps] |

Related documentation:

- **FDD**: [Link to FDD if one exists]
- **TDD**: [Link to TDD — typically the section that designs the adapter(s) consuming these contracts]
- **Feature State**: [Link to feature state file]

## Authentication / Authorization

> Service-interface integrations rarely use credential-based authentication. Document the trust boundary explicitly even when "no auth" applies.

[Choose one and customize:]

- **No credentials exchanged**: [Each integration runs as the current OS user; no separate credentials transit through this feature.]
- **OS user context**: [Integration X relies on the OS user's session — describe what the OS user must have set up.]
- **Token / API key**: [If a credentialed integration exists, document the credential type, storage, rotation policy.]

---

## Integration 1 — [Integration Name]

### Purpose

[Why this integration exists. Why this technology was chosen over alternatives. What capability this integration provides that the feature cannot satisfy in pure project code.]

### Invocation contract

> Document **how** the adapter calls the integration. Use a code block in the project's primary language to show the canonical call shape.

```[language]
# Replace with the canonical invocation pattern
# Include parameter values, configuration, error-handling shape
```

[For subprocess integrations: document binary lookup precedence here.]
[For COM/library integrations: document client/handle lifecycle.]
[For file-system integrations: document path, file format, and parser/writer.]

### Inputs

| Input | Type | Source | Notes |
|---|---|---|---|
| [parameter or arg name] | [Type / shape] | [Where the value comes from — config, caller, file, etc.] | [Constraints, defaults, encoding] |

### Outputs

| Output | Type | Notes |
|---|---|---|
| [Return value / side-effect / file written] | [Type / shape] | [What the caller can rely on] |

### Error model

> Map each failure mode to a typed adapter exception, recoverability flag, and (where surfaced) localized UI message.

| Failure | Cause | Adapter exception | Recoverable | UI message (en) |
|---|---|---|---|---|
| [Failure scenario] | [Underlying error or condition] | `[ExceptionClassName]` | Yes / No | "[User-visible text or — for recoverable failures — describe fallback]" |

### Performance contract

[Document the performance budget. Use whatever measurement is meaningful for this integration type — wall-clock latency, cold-start vs warm, throughput, memory.]

- **[Metric 1]**: [Budget]
- **[Metric 2]**: [Budget]
- **Hard timeout** (if applicable): [Wall-clock cap; behavior when exceeded]

### Concurrency

[Is the adapter reentrant? Single-threaded? Apartment-bound (COM)? What thread initializes the integration handle?]

### Versioning

[What versions of the underlying integration are supported. Whether minor/patch differences matter. Major-version bumps require revalidation.]

<!-- ===== End Integration 1 ===== -->

<!-- For each additional integration, copy the "Integration N — [Name]" block above and customize.
     Common variations to add as needed:
       - "Binary location resolution" subsection (subprocess integrations)
       - "Availability" subsection (platform-restricted integrations like Windows-only COM)
       - "Limitations" subsection (fallback or degraded-mode integrations)
       - "Token vocabulary" subsection (file-system / template integrations with placeholder syntax)
-->

## Integration 2 — [Integration Name]

### Purpose

[...]

### Invocation contract

```[language]
# ...
```

### Inputs

| Input | Type | Source | Notes |
|---|---|---|---|
|  |  |  |  |

### Outputs

| Output | Type | Notes |
|---|---|---|
|  |  |  |

### Error model

| Failure | Cause | Adapter exception | Recoverable | UI message (en) |
|---|---|---|---|---|
|  |  |  |  |  |

### Concurrency

[...]

### Versioning

[...]

<!-- ===== End Integration 2 ===== -->

---

## Cross-cutting concerns

### Logging

> Every external call should emit a log entry. Document the levels and the message vocabulary.

- **INFO** on success: `[Sample success message format]`
- **WARNING** on recoverable failure: `[Sample warning message format]`
- **ERROR** on abort: `[Sample error message format]`

### Configuration

> Tunable parameters that govern integration behavior. Document defaults and allowed ranges.

```jsonc
{
  // Replace with actual config keys
  "[config_key_1]": "[default value]",
  "[config_key_2]": 30
}
```

### Security

- **Network**: [Confirm whether any integration makes network calls. State "No external network calls" if true.]
- **Credentials**: [Confirm whether any credentials transit through this feature.]
- **Path safety**: [If file paths are constructed, document sanitization — control-char stripping, separator handling, path-traversal guards.]
- **Process isolation** (subprocess integrations): [Stdin/stdout handling, environment-variable scrubbing, working-directory pinning.]

---

## Database Schema Reference

> **📋 Primary Documentation**: Database Schema Design Task (PF-TSK-021)
> **🔗 Link**: [Database Schema Design Document - PD-SCH-XXX]
> **👤 Owner**: Database Schema Design Task
>
> **Purpose**: Brief notes on how the integration interacts with project data. Detailed schema lives in the Schema Design doc.

<!-- Drop this section if no integration touches project data. -->

**Data access patterns**:

- [Which tables the integration reads or writes, if any]
- [Whether the integration consumes data assembled by other components]

## Service Implementation Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-022)
> **🔗 Link**: [Technical Design Document - PD-TDD-XXX]
> **👤 Owner**: TDD Creation Task
>
> **Purpose**: Brief notes on the adapter design that consumes this contract. Detailed adapter architecture lives in the TDD.

**Adapter implementation notes**:

- [Class/module that implements the contract]
- [Key design patterns — Strategy, Adapter, fallback chain, etc.]
- [Where construction and lifecycle are owned]

## Testing Reference

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012)
> **🔗 Link**: [Test Specification Document - PD-TST-XXX]
> **👤 Owner**: Test Specification Creation Task
>
> **Purpose**: Brief notes on test surface for this contract.

**Contract testing requirements**:

- [Mock-vs-real-integration testing posture]
- [Error-path coverage requirements — every row in the Error model table should have at least one test]
- [Platform coverage — which integrations require Windows-only / macOS-only / Linux-only test runs]

---

## Gap Analysis (for retrospective documentation)

> Drop this section in greenfield specs. For retrospective documentation (target-state mode), enumerate the gap between current implementation and the contract above.

| Gap ID | Current | Target | Tracking |
|---|---|---|---|
| [GAP-API-X.Y.Z-001] | [What the implementation does today] | [What the contract requires] | [TD### or "new (filed Step N)"] |

## Notes

- [Open design questions, future enhancement hooks, known constraints worth recording]
- [If the contract has explicit backward-compatibility commitments — additive vs breaking changes — document them here]

## Changelog

- **v1.0** ([CREATION_DATE]): Initial Service-Interface API specification
