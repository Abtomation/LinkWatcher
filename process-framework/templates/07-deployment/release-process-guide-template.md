---
id: PF-TEM-082
type: Process Framework
category: Template
version: 1.0
created: 2026-06-09
updated: 2026-06-09
creates_document_category: CI-CD
creates_document_version: 1.0
usage_context: Product Documentation - CI-CD Creation
template_for: CI-CD
creates_document_type: Product Documentation
description: Template for a project's per-project Release Process Guide (PD-CIC): deploy/version/distribute mechanics, freshness stamp, release checklist, optional downstream-impact announcement. Instantiated at Project Initiation (greenfield stub) or Retrospective Documentation Creation (onboarding capture); executed by Release & Deployment (PF-TSK-008).
creates_document_prefix: PD-CIC
---

# [Project Name] Release Process Guide

<!--
INSTANCE INSTRUCTIONS — delete this whole comment block in the finished guide.

This guide is the per-project tail of the release workflow. It records the deploy,
version, and distribute mechanics specific to how THIS project ships — the part that the
agnostic Release & Deployment task (PF-TSK-008) cannot generalize. It is instantiated one
of two ways:

  • Greenfield  — Project Initiation (PF-TSK-059) ships this as a structured stub. Leave
                  the Freshness Stamp as `unverified` and fill in the mechanics when your
                  first release approaches.
  • Onboarding  — Retrospective Documentation Creation (PF-TSK-066) Phase 4 captures an
                  existing RELEASING.md / release doc into this structure.

Fill every [placeholder]. Delete the sections and table rows that do not apply to your
distribution model, and remove every instructional comment before the guide is complete.
-->

## Scope — What This Guide Owns

This guide owns the **irreducible per-project release tail**: the concrete deploy,
version, and distribute mechanics for this project's distribution model
(*[global CLI install | packaged app | web service | library/package publish | ...]*).

It deliberately does **not** restate the generalizable release gates. Those are owned and
run by **Release & Deployment (PF-TSK-008)**: release-scope review, user-documentation
completeness, the semantic-version *decision*, release-note authoring, the full test
sweep, the performance-regression check, E2E verification, bug-discovery logging, and
state/feedback updates. At release time PF-TSK-008 runs those gates and then **delegates
to this guide** for the deploy steps below — and reads the Freshness Stamp before it does.

## Freshness Stamp

> Read by the Release & Deployment freshness gate (PF-TSK-008). Re-set **both** fields
> whenever the mechanics in this guide change or are re-verified against a real release.
> A greenfield stub leaves both as `unverified`, which the gate treats as "needs review".

- **Verified against release:** [version this guide was last confirmed accurate for, e.g. `2.3.0` — or `unverified`]
- **Verified on:** [`YYYY-MM-DD` the mechanics were last confirmed accurate — or `unverified`]

## Distribution Model

[One or two sentences: how this project ships and where the released artifact lives. Name
the source location and the deployed/published location. Example: "LinkWatcher is a
locally-installed CLI tool; 'deploy' means installing the source into `~/bin/` and
restarting the background process."]

## Version Management

[How this project's version is defined and bumped. Record only WHERE and HOW the bump is
applied — the *decision* of which semver level to bump is an agnostic gate owned by
PF-TSK-008, not this guide.]

- **Version source of truth:** [authoritative file + field, e.g. `pyproject.toml` → `[project].version`]
- **Bump procedure:** [exact steps to apply the new version]
- **Tagging convention (if any):** [e.g. `vMAJOR.MINOR.PATCH`, pushed to the remote]

## Deploy / Distribute Steps

[The ordered, concrete steps to deploy or distribute a release for THIS project — the
steps PF-TSK-008 delegates to. Include exact commands.]

1. [First step — exact command]
2. [Next step — exact command]
3. [Verification — how to confirm the release is live and healthy for this distribution
   model: smoke test, process-restart check, published-package availability, health
   endpoint, etc.]

### What Gets Deployed

[Optional but recommended: the source → destination map of what ships. Keep this table
consistent with the deploy steps above so the artifact set has a single source of truth.
Delete if it does not apply to your distribution model.]

| Source | Deployed / Published To | Purpose |
|--------|-------------------------|---------|
| [path] | [path or registry] | [why it ships] |

## Release Checklist

[A short, project-specific checklist the releaser walks at release time. It covers only
the per-project mechanics — the agnostic gates are checklisted inside PF-TSK-008, not
duplicated here.]

- [ ] Version bumped in [version source of truth]
- [ ] [Deploy/distribute command] completed without errors
- [ ] [Post-deploy verification] passed
- [ ] **Freshness Stamp** above updated to this release's version and date

## Downstream-Impact / Announcement (optional)

<!--
Keep this section ONLY if a release of this project can change a contract that downstream
consumers depend on (e.g. a config-schema change, a breaking API change, a changed install
path). It is the home for the "announce schema/config changes at release time"
responsibility. Delete the entire section if it does not apply.
-->

- **What downstream consumers depend on:** [config schema / API surface / install contract]
- **What changed this release:** [the breaking or affecting change, or `n/a`]
- **Who to notify, and how:** [channel — e.g. a note in the release notes, a message to dependent projects]

## Related Documentation

<!--
Replace these with working links from the guide's `doc/ci-cd/` location. From there:
  • Release & Deployment task → `../../process-framework/tasks/07-deployment/release-deployment-task.md`
  • CI/CD Setup Guide        → `../../process-framework/guides/07-deployment/ci-cd-setup-guide.md`
Add any project-specific references (install scripts, deployment runbooks).
-->

- [Release & Deployment Task — the agnostic task that delegates here]
- [CI/CD Setup Guide — infrastructure these steps may rely on]
- [Project-specific references as needed]

---

*This Release Process Guide is part of the [Project Name] Product Documentation (`PD-CIC`).*
