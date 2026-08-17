# Founding Inputs

This directory holds the project's **founding inputs**: the pre-existing, human-supplied
material that predates project initiation and describes what this product is meant to be.

Drop whatever you already have in here — a written brief, a business-model document, a slide
or PDF export, a recorded conversation transcript. Any format. There is nothing to fill in and
no ceremony to follow.

## What belongs here

Raw material **you** authored or were given, in whatever form it arrived. If it explains the
product's intent and it existed before the framework did, it belongs here.

An agent may add a readable working **transcription** of a binary or non-English input
alongside the original (e.g. an English `.md` rendering of a German `.pdf`). A transcription is
still an input — it sits here, next to its source.

## What these files are not

Founding inputs are **not framework artifacts**. Deliberately:

- **No IDs.** They are not registered in `doc/PD-id-registry.json`. The framework does not own
  your PDF, and giving raw material IDs creates registry churn for no benefit.
- **No frontmatter required.** Nothing parses these files.
- **Not in the documentation map.** This directory is excluded from
  `doc/PD-documentation-map.md` by design, so frontmatter-less material is never flagged as
  missing a description.

## What reads them

[Project Initiation (PF-TSK-059)](../../../process-framework/tasks/00-setup/project-initiation-task.md)
reads this directory and **synthesizes** [`../product-concept.md`](../product-concept.md) from
it — the authoritative statement of what is being built, which downstream tasks then consume.
For an already-onboarded project,
[Retrospective Documentation Creation (PF-TSK-066)](../../../process-framework/tasks/00-setup/retrospective-documentation-creation.md)
captures existing origin documents into that same concept instead.

The Product Concept's **Sources** section indexes these files by path — that is how traceability
survives without IDs. If you add an input after the concept is written, add a Sources row too.

## If this directory is empty

That is a valid state. A project founded on a single conversation may have no pre-existing
files at all; record the brief here and synthesize from that. A project with no founding
material leaves the concept stub unfilled.
