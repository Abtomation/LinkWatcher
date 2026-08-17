---
variant_group: validation-dimension-paths
description: "Security & Data Protection dimension path for Dimension Validation — analysis steps and criteria for security best practices, data protection, input validation, and secrets management"
---

# Security & Data Protection — Validation Dimension Path

> **Parent task**: [Dimension Validation](dimension-validation-task.md) (PF-TSK-092). Execute the shared process there; this path file supplies the dimension-specific content that plugs into the parent's steps 2, 3, 5, 7, 8, and 12, plus the tokens for steps 6 and 13.
>
> | `-ValidationType` (step 6) | `Dims` (step 13) |
> |---|---|
> | `SecurityDataProtection` | `SE` |

## AI Agent Role (parent: AI Agent Role)

**Role**: Security Auditor
**Mindset**: Threat-aware, defense-in-depth, risk-based prioritization
**Focus Areas**: Authentication, authorization, input validation, secrets management, data protection, OWASP principles
**Communication Style**: Identify security vulnerabilities and data exposure risks, recommend mitigations with severity ratings, ask about threat model assumptions and acceptable risk levels

## Dimension Context (parent step 2 — Important / Load If Space)

- **Configuration Files** - Application configuration files that may contain secrets or security settings
- **API Specifications** - API contracts and endpoint definitions for input validation review
- **Dependency Manifests** - Package dependency files (requirements.txt, package.json, etc.) for vulnerability scanning
- **Architecture Decision Records** - [ADR Directory](../../../doc/technical/architecture) - security-related architectural decisions

## Dimension Criteria (parent step 3)

Review applicable security standards: **OWASP Top 10**, language-specific security guidelines, and the project-specific threat model if available.

## Execution Analysis Steps (parent step 5)

5a. **Input Validation Analysis**: Examine all user-facing and external data entry points for proper validation, sanitization, and type checking
5b. **Authentication & Authorization Review**: Verify that access controls are properly implemented, session management is secure, and privilege escalation paths are protected
5c. **Secrets Management Assessment**: Check that API keys, credentials, tokens, and sensitive configuration values are not hardcoded, are properly stored, and are excluded from version control
5d. **Data Protection Review**: Evaluate data handling for sensitive information — encryption at rest/in transit, proper logging sanitization (no secrets in logs), and secure data disposal
5e. **Dependency Security Scan**: Review third-party dependencies for known vulnerabilities, outdated packages, and unnecessary permissions

## Scoring & Findings (parent steps 7–8)

- Apply the 4-point scoring system (0–3) to each security criterion.
- Record specific security vulnerabilities, data exposure risks, and remediation recommendations **with severity ratings**.

## Remediation Prioritization (parent step 12)

Prioritize remediation action items by severity: **Critical > High > Medium > Low**.

## Dimension Outputs (parent: Outputs)

- **Security & Data Protection Validation Report** - created in `doc/validation/reports/security-data-protection/PD-VAL-XXX-security-data-protection-features-[feature-range].md`
- **Security Remediation Action Items** - for features scoring below the quality threshold, prioritized by severity
