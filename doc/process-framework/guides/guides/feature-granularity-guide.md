---
id: PF-GDE-048
type: Document
category: General
version: 1.0
created: 2026-02-20
updated: 2026-02-20
guide_category: Planning
guide_status: Active
guide_description: Defines what constitutes a well-scoped feature, provides validation tests for granularity, and offers scaling guidance.
related_tasks: PF-TSK-064,PF-TSK-013,PF-TSK-067
guide_title: Feature Granularity Guide
---

# Feature Granularity Guide

## Overview

This guide defines what constitutes a well-scoped feature and provides practical tests for validating feature granularity. It applies whenever features are being identified, defined, or evaluated — whether discovering features in an existing codebase, planning new features, or classifying change requests.

**Getting feature granularity right is critical.** Every downstream activity — analysis, documentation, planning, implementation tracking — builds on the feature list. Too many features creates documentation overhead and artificial boundaries. Too few makes planning and tracking meaningless.

## When to Use

Use this guide whenever you are:

- **Discovering features** in an existing codebase (onboarding)
- **Identifying new features** during product planning
- **Classifying a change request** as a new feature vs. enhancement
- **Reviewing a feature list** for consistency and appropriate scope
- **Splitting or merging features** during implementation

> **Read this guide before creating Feature Implementation State files.** Each feature generates tracking overhead proportional to its existence — state files, documentation, tracking entries. Getting granularity right here avoids significant rework later.

## What Is a Feature?

A feature is **a cohesive unit of functionality that you would plan, track, and discuss as a single item**. It represents a capability of the system, not an implementation detail.

### Three Validation Tests

Apply these tests to every candidate feature. A well-scoped feature should pass all three:

**1. The Planning Test**
Would you realistically plan a work session around this?

- "This sprint we're improving the authentication system" — **yes, this is a feature**
- "This sprint we're working on password hashing" — **no, that's part of authentication**

**2. The Conversation Test**
Would you describe this to a stakeholder as a distinct capability?

- "Our system has a notification service" — **yes, this is a feature**
- "Our system has an email template formatter" — **no, that's how notifications work internally**

**3. The Independence Test**
Could this change without necessarily changing other features? It doesn't need to be fully independent, but it should have its own reason to evolve.

- "The search engine can be improved independently of the user profile system" — **yes, these are separate features**
- "The password reset flow can't exist without authentication" — **still a feature if it has its own evolution path** (new reset methods, new notification channels, etc.)

## Granularity Boundaries

### Too Fine-Grained (Common Mistake)

You've gone too granular when features are:

- **Private methods or internal algorithms** inside another feature's codebase (e.g., "password hashing" inside "authentication")
- **Configuration options or behavioral flags** (e.g., "dry-run mode" is a capability of the feature it belongs to, not a feature itself)
- **Individual implementations of a common pattern** that are only meaningful as a group (e.g., six format-specific parsers that all follow the same interface — consider whether they form one "parsing system" feature)
- **Infrastructure that only exists to support another feature** (e.g., "test fixtures" is not a feature — it's part of the test infrastructure)

**Red flags for over-granularization:**
- Multiple features implemented entirely within a single source file
- Features with fewer than ~30 lines of implementation
- Features that no one would plan a work session around in isolation
- A feature count significantly above the scaling guidance range

### Too Coarse-Grained (Less Common but Equally Problematic)

You've gone too broad when features are:

- **Entire architectural layers** (e.g., "Backend" or "Data Layer" — these contain multiple distinct capabilities)
- **So broad that changes to one part don't affect the rest** (e.g., if "API Layer" contains both authentication endpoints and reporting endpoints that share nothing, they're separate features)
- **Impossible to describe the scope without listing sub-capabilities** (if you need bullet points to explain what one feature covers, it may need splitting)

**Red flags for under-granularization:**
- A single feature spanning more than 5-6 source files with different responsibilities
- A feature where bug reports in one area would never relate to another area of the same feature
- A feature count significantly below the scaling guidance range

## Scaling Guidance

Feature count should scale with project complexity, not just lines of code:

| Project Scope | Typical Range | Examples |
|---------------|---------------|---------|
| Small utility / CLI tool | 5–15 features | A file converter, a linting tool, a monitoring agent |
| Medium application | 15–30 features | A web API with multiple domains, a desktop application |
| Large system | 30–60 features | A multi-service platform, a full-stack application with complex business logic |

These ranges are guidelines, not strict limits. If your count falls significantly outside the expected range, revisit your granularity:

- **Above range:** Look for merge opportunities — are multiple features really sub-components of one capability?
- **Below range:** Look for features that are too broad — do they contain unrelated responsibilities?

## Applying This Guide

### During Feature Discovery (Onboarding)

1. Start top-down: identify the system's major capabilities from entry points and documentation
2. Validate bottom-up: walk the source tree to verify each file maps to a candidate feature
3. Apply the three tests to every candidate before finalizing
4. Check against scaling guidance for the project size
5. Present the list to the human partner for validation before creating state files

### During Feature Planning (New Features)

1. When proposing a new feature, apply the three tests
2. Verify it doesn't overlap significantly with an existing feature (which would make it an enhancement instead)
3. Check that it's not too broad — could it be split into independently plannable capabilities?

### During Change Request Evaluation

1. Determine whether the request maps to an existing feature (enhancement) or requires a new one
2. If creating a new feature, validate granularity against this guide
3. If classifying as an enhancement, verify the target feature isn't becoming too broad as a result

### Sub-Components Are Not Lost

When a candidate is demoted from "feature" to "sub-component" during consolidation, it should be documented as a section or capability within its parent feature's state file. The goal is to organize information at the right level, not to discard it.

## Related Resources

- [Codebase Feature Discovery](../../tasks/00-onboarding/codebase-feature-discovery.md) - Uses this guide during onboarding
- [Feature Discovery](../../tasks/01-planning/feature-discovery-task.md) - Uses this guide when identifying new features
- [Feature Request Evaluation](../../tasks/01-planning/feature-request-evaluation.md) - Uses this guide when classifying change requests
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Where features are recorded
