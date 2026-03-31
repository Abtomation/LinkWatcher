---
id: PF-GDE-053
type: Document
category: General
version: 1.0
created: 2026-03-30
updated: 2026-03-30
guide_category: Framework
related_tasks: PF-TSK-014
guide_description: Single authoritative reference for 10 development dimensions across all task phases — planning, implementation, review, and validation
guide_status: Active
guide_title: Development Dimensions Guide
---

# Development Dimensions Guide

## Overview

This guide defines the **10 development dimensions** — quality aspects that should be considered throughout the development lifecycle, from planning through validation. Each dimension includes phase-specific guidance so that quality concerns are **designed for** during development rather than only **discovered** during post-implementation validation.

**Relationship to validation**: The [Feature Validation Guide](/process-framework/guides/05-validation/feature-validation-guide.md) references this guide for dimension definitions and applicability criteria but retains its own scoring methodology, thresholds, and reporting templates. The AI Agent Continuity validation task (PF-TSK-036) is a standalone validation task not backed by a dimension.

## When to Use

- **Planning tasks**: Evaluate which dimensions apply to a feature, enhancement, or bug
- **Implementation tasks**: Consult the implementation checklist for each applicable dimension
- **Review tasks**: Focus review attention on Critical dimensions using the review guidance
- **Validation tasks**: Use as reference for dimension definitions (scoring is in the validation guide)

## Dimension Importance Scale

| Level | Meaning | Implication |
|-------|---------|-------------|
| **Critical** | Central to quality; failure is a showstopper | Deep review, explicit acceptance criteria, Tier+1 TDD depth (D10) |
| **Relevant** | Applies but not primary; good practice to address | Checklist treatment during implementation and review |
| **N/A** | Does not apply to this feature | Omit from dimension profile |

> **Core dimensions** (AC, CQ, ID, DA) are always at least **Relevant** for any feature — no evaluation needed. Only the 6 **extended dimensions** (EM, SE, PE, OB, UX, DI) require explicit applicability assessment.

## Dimension Abbreviation Reference

| Abbr | Dimension | Type |
|------|-----------|------|
| AC | Architectural Consistency | Core |
| CQ | Code Quality & Standards | Core |
| ID | Integration & Dependencies | Core |
| DA | Documentation Alignment | Core |
| EM | Extensibility & Maintainability | Extended |
| SE | Security & Data Protection | Extended |
| PE | Performance & Scalability | Extended |
| OB | Observability | Extended |
| UX | Accessibility / UX Compliance | Extended |
| DI | Data Integrity | Extended |

> **TST** (Testing) is valid only as a tech debt category — it is not a development dimension.

---

## Dimensions

### Architectural Consistency (AC)

**Definition**: Adherence to established design patterns, ADR decisions, and interface conventions.
**Applicability**: Always Relevant (Core). Critical when introducing new patterns or touching architectural boundaries.

#### Phase-Specific Guidance

**Planning**:
- Identify which architectural patterns apply (Orchestrator/Facade, Registry, etc.)
- Note any ADRs that constrain implementation choices

**Implementation**:
- [ ] Follow established patterns documented in ADRs
- [ ] Use existing interfaces and base classes — do not create parallel abstractions
- [ ] Maintain consistent module boundaries (no cross-layer imports)
- [ ] Follow naming conventions for files, classes, and methods
- [ ] Register new components with appropriate registries/factories

**Review**:
- Verify ADR compliance for all architectural decisions
- Check that new code follows existing patterns rather than introducing alternatives
- Confirm module boundaries are respected

#### Common Anti-Patterns
- Bypassing the Facade to call internal components directly
- Creating a new pattern when an existing one covers the use case
- Inconsistent naming that obscures architectural role (e.g., mixing "handler" and "processor" for the same concept)

---

### Code Quality & Standards (CQ)

**Definition**: Adherence to coding standards, SOLID principles, complexity limits, and best practices.
**Applicability**: Always Relevant (Core). Critical for complex logic or shared utility code.

#### Phase-Specific Guidance

**Planning**:
- Identify applicable coding standards and style requirements
- Note complexity constraints for the implementation scope

**Implementation**:
- [ ] Follow project coding standards (naming, formatting, structure)
- [ ] Keep functions focused — single responsibility, manageable length
- [ ] Use meaningful names that reveal intent
- [ ] Handle errors explicitly — no silent swallowing or bare except
- [ ] Avoid code duplication — extract shared logic when ≥3 occurrences

**Review**:
- Check cyclomatic complexity of new/modified functions
- Verify error handling is explicit and appropriate
- Confirm naming consistency with surrounding code
- Look for SOLID violations (especially SRP and DIP)

#### Common Anti-Patterns
- Catch-all exception handlers that hide bugs
- God functions/classes that do too many things
- Copy-paste code instead of extracting shared utilities

---

### Integration & Dependencies (ID)

**Definition**: Health of component interfaces, dependency management, and data flow integrity.
**Applicability**: Always Relevant (Core). Critical when adding dependencies or modifying cross-component interfaces.

#### Phase-Specific Guidance

**Planning**:
- Identify integration points with existing components
- Map data flow through the system for the planned change

**Implementation**:
- [ ] Program to interfaces, not implementations
- [ ] Validate data at component boundaries (inputs from other modules)
- [ ] Maintain backward-compatible interfaces when modifying shared APIs
- [ ] Document any new dependencies with purpose and version constraints
- [ ] Avoid circular dependencies between modules

**Review**:
- Verify interface contracts are maintained or explicitly migrated
- Check that new dependencies are justified and version-pinned
- Confirm data flow matches architectural expectations

#### Common Anti-Patterns
- Tight coupling to implementation details of another module
- Adding dependencies without documenting purpose
- Breaking an existing interface without updating all consumers

---

### Documentation Alignment (DA)

**Definition**: Accuracy of documentation relative to actual implementation — TDD/FDD alignment, code comments, state files.
**Applicability**: Always Relevant (Core). Critical for Tier 2+ features with formal design documents.

#### Phase-Specific Guidance

**Planning**:
- Identify which documentation artifacts will be needed (TDD, FDD, test specs)
- Note existing docs that may need updates if the change modifies documented behavior

**Implementation**:
- [ ] Keep state file current — update status, completion %, next steps after each session
- [ ] Update code comments when changing behavior they describe
- [ ] If implementation diverges from TDD, update the TDD or record the deviation
- [ ] Add inline comments only where logic is non-obvious

**Review**:
- Check that state file reflects current implementation status
- Verify code comments match actual behavior
- Confirm TDD/FDD alignment for any changed interfaces or algorithms

#### Common Anti-Patterns
- Stale state files that don't reflect current progress
- Code comments that describe what the code did before a refactor
- Implementation that silently diverges from design documents

---

### Extensibility & Maintainability (EM)

**Definition**: Design for future extension, configuration flexibility, and ease of maintenance.
**Applicability**: Extended. **Apply when**: Feature provides extension points, uses plugin/registry patterns, or will be modified frequently.

#### Phase-Specific Guidance

**Planning**:
- Identify extension points the feature should provide
- Note configuration options needed for flexibility

**Implementation**:
- [ ] Use registry/factory patterns where new variants are expected
- [ ] Externalize magic numbers and thresholds to configuration
- [ ] Keep modules small and focused — prefer composition over inheritance
- [ ] Design for testability — injectable dependencies, clear boundaries
- [ ] Provide meaningful defaults for all configuration options

**Review**:
- Check that extension points are documented and usable
- Verify configuration options have sensible defaults
- Confirm testability — can components be tested in isolation?

#### Common Anti-Patterns
- Hard-coded values that should be configurable
- Monolithic modules that resist targeted changes
- Extension points that exist in code but are undocumented

---

### Security & Data Protection (SE)

**Definition**: Input validation, file system safety, secrets management, and data protection.
**Applicability**: Extended. **Apply when**: Feature handles user input, file paths, external data, or sensitive configuration.

#### Phase-Specific Guidance

**Planning**:
- "Does this feature handle user input or external data?" → If yes, Critical
- Identify trust boundaries and input sources

**Implementation**:
- [ ] Validate and sanitize all external inputs (user paths, config values, file contents)
- [ ] Prevent path traversal — resolve and verify paths stay within expected boundaries
- [ ] Never log sensitive data (credentials, tokens, full file contents)
- [ ] Use allowlists over denylists for input validation
- [ ] Handle file permissions appropriately — don't create world-writable files

**Review**:
- Verify all user-facing inputs are validated
- Check for path traversal vulnerabilities in file operations
- Confirm no sensitive data in logs or error messages
- Review file operations for permission and safety issues

#### Common Anti-Patterns
- Trusting user-supplied file paths without validation
- Logging full exception details that may contain sensitive data
- Using denylists (blocking known-bad) instead of allowlists (permitting known-good)

---

### Performance & Scalability (PE)

**Definition**: Algorithmic efficiency, resource consumption, I/O patterns, and scalability characteristics.
**Applicability**: Extended. **Apply when**: Feature processes collections, does file I/O at scale, or runs on every file event.

#### Phase-Specific Guidance

**Planning**:
- "Does this feature do I/O on large datasets or run frequently?" → If yes, Critical
- Identify hot paths and expected data volumes

**Implementation**:
- [ ] Avoid O(n²) or worse algorithms — use appropriate data structures (dicts, sets)
- [ ] Minimize file I/O operations — batch reads/writes where possible
- [ ] Use lazy evaluation for expensive computations that may not be needed
- [ ] Avoid repeated regex compilation — compile once, reuse
- [ ] Consider memory footprint for large collections

**Review**:
- Check algorithmic complexity of loops and data processing
- Verify I/O operations are batched or minimized
- Look for unnecessary repeated work (recompilation, re-reading, re-scanning)

#### Common Anti-Patterns
- Linear scans where an index/dict lookup would work
- Reading entire files when only headers are needed
- Compiling regex patterns inside loops

---

### Observability (OB)

**Definition**: Logging coverage, error traceability, and diagnostic capability.
**Applicability**: Extended. **Apply when**: Feature runs as a background process, handles errors silently, or has complex control flow.

#### Phase-Specific Guidance

**Planning**:
- "Is this a background process or complex workflow?" → If yes, Critical
- Identify key decision points and error paths that need logging

**Implementation**:
- [ ] Log at appropriate levels (DEBUG for flow, INFO for operations, WARNING for recoverable issues, ERROR for failures)
- [ ] Include contextual information in log messages (file path, operation, relevant IDs)
- [ ] Log both entry and outcome of significant operations
- [ ] Ensure error paths produce actionable log messages
- [ ] Use structured logging fields where the logging system supports it

**Review**:
- Verify error paths produce log output (no silent failures)
- Check log levels are appropriate (not everything at INFO)
- Confirm log messages include enough context to diagnose issues

#### Common Anti-Patterns
- Silent error swallowing — catch exception, do nothing
- Logging without context ("Error occurred" with no details)
- Over-logging at INFO level (noise that obscures real issues)

---

### Accessibility / UX Compliance (UX)

**Definition**: Accessibility standards, keyboard navigation, screen reader support, and inclusive design.
**Applicability**: Extended. **Apply when**: Feature has a user interface (GUI, web UI, interactive terminal). **N/A** for backend-only or CLI tools without interactive prompts.

#### Phase-Specific Guidance

**Planning**:
- "Does this feature have UI components?" → If yes, assess importance
- Identify applicable accessibility standards (WCAG, platform guidelines)

**Implementation**:
- [ ] Ensure keyboard navigation for all interactive elements
- [ ] Provide text alternatives for non-text content
- [ ] Maintain sufficient color contrast ratios
- [ ] Support screen reader announcements for dynamic content
- [ ] Test with assistive technologies

**Review**:
- Verify keyboard-only navigation works for all workflows
- Check color contrast meets WCAG guidelines
- Confirm screen reader compatibility

#### Common Anti-Patterns
- Mouse-only interactions with no keyboard alternative
- Color as the sole indicator of state or meaning
- Dynamic content changes that screen readers don't announce

---

### Data Integrity (DI)

**Definition**: Data consistency, atomicity of writes, constraint enforcement, and error recovery.
**Applicability**: Extended. **Apply when**: Feature modifies data (files, databases, state), especially with concurrent access or multi-step writes.

#### Phase-Specific Guidance

**Planning**:
- "Does this feature modify persistent data?" → If yes, assess importance
- Identify concurrent access scenarios and failure modes

**Implementation**:
- [ ] Use atomic write patterns — write to temp file, then rename
- [ ] Create backups before destructive modifications
- [ ] Handle partial failure gracefully — don't leave data in inconsistent state
- [ ] Validate data before writing (schema, constraints, invariants)
- [ ] Use locking or coordination for concurrent access to shared data

**Review**:
- Verify write operations are atomic (no partial writes on failure)
- Check that backup/recovery mechanisms exist for destructive operations
- Confirm concurrent access scenarios are handled
- Verify data validation before persistence

#### Common Anti-Patterns
- Writing directly to the target file (corruption on crash)
- No backup before bulk modification
- Ignoring concurrent access to shared state files

---

## Related Resources

- [Feature Validation Guide](/process-framework/guides/05-validation/feature-validation-guide.md) — Scoring methodology and thresholds for validation rounds
- [Proposal: Dimension-Aware Development Integration (PF-PRO-013)](/process-framework/proposals/proposals/dimension-aware-development-integration-proposal.md) — Design rationale and decision log
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md) — Uses dimension abbreviations as Primary Dimension (+ TST)
