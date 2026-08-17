---
id: PF-TEM-003
type: Process Framework
category: Template
version: 1.2
created: 2023-06-15
updated: 2026-07-13
status: Active
creates_document_type: Process Framework
creates_document_category: Guide
description: "Template for creating new guides"
---

# [Guide Title]

## Overview

[Brief description of what this guide helps the user accomplish. Keep it to 2-3 sentences that clearly explain the purpose and outcome.]

## When to Use

[Describe the specific situations when this guide should be used. Include triggers, prerequisites, or decision criteria.]

> **🚨 CRITICAL**: [Add any critical warning or requirement here — delete this callout if there is none]

## Table of Contents

[Optional. Delete for short guides.]

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Step-by-Step Instructions](#step-by-step-instructions)
4. [Examples](#examples)
5. [Troubleshooting](#troubleshooting)
6. [Related Resources](#related-resources)

## Prerequisites

[Optional section. Delete if the guide needs no setup.]

Before you begin, ensure you have:

- [Prerequisite 1]
- [Prerequisite 2]

## Background

[Optional section. Provide context that helps the reader understand why they're performing these steps, and any concepts they should know before proceeding.]

## Step-by-Step Instructions

### 1. [First Major Step]

1. [Detailed instruction]
2. [Detailed instruction]
   ```bash
   # Example command if applicable
   command --option value
   ```

**Expected Result:** [What the user should see after completing this step]

### 2. [Second Major Step]

1. [Detailed instruction]
2. [Detailed instruction]

**Expected Result:** [What the user should see after completing this step]

## Examples

### Example 1: [Specific Use Case]

[A complete, real-world example of the process described in the guide]

```bash
# Example command or code snippet
command --option value
```

**Result:** [What the user should expect to see]

## Troubleshooting

### [Common Issue]

**Symptom:** [What the user might see or experience]

**Cause:** [The likely cause]

**Solution:** [Step-by-step instructions to resolve it]

## Related Resources

- [Related guide, task, or script](../../guides/support/guide-creation-best-practices-guide.md)

<!--
TEMPLATE USAGE GUIDANCE:

TWO GUIDE SHAPES — keep the sections your shape needs and delete the rest:

- Procedure guide (a how-to): Overview, When to Use, Prerequisites, Background,
  Step-by-Step Instructions, Examples, Troubleshooting, Related Resources.
- Convention / reference guide (a decision rule, lookup table, or set of definitions):
  Overview, When to Use, your own domain sections, Related Resources. The Table of
  Contents, Prerequisites, Background, Step-by-Step Instructions and Troubleshooting
  scaffolding above is procedure-shaped — delete what your guide does not use.

CUSTOMIZATION CRAFT (how to fill in an artifact a New-* script creates) belongs in a
craft skill, not a guide — see guides/support/craft-skill-authoring-guide.md (PF-GDE-077).

METADATA: related_script and related_task are optional; supply them via
New-Guide.ps1 -RelatedScript / -RelatedTasks so the guide is traceable to its script and tasks.
-->
