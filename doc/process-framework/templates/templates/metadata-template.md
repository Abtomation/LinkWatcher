---
id: PF-TEM-010
type: Process Framework
category: Template
version: 1.0
created: 2023-06-15
updated: 2025-07-04
---

# Metadata Template for Documentation Files

This template provides the standard metadata format to be included at the top of all documentation files in the BreakoutBuddies project.

## Metadata Format

```yaml
---
id: [PREFIX]-SEC-XXX
type: Documentation
version: 1.0
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

## Example for Documentation

```yaml
---
id: PD-DEV-001
type: Documentation
version: 1.0
created: 2025-05-15
updated: 2025-05-15
---
```

## Example for Artifact README

```yaml
---
id: PD-API-001
type: Documentation
version: 1.0
created: 2025-05-15
updated: 2025-05-15
artifact_directory: ART-API-001
---
```

## Fields Explanation

- **id**: Unique identifier for the document
  - Format: `[PREFIX]-SEC-XXX` for documentation or `ART-SEC-XXX` for artifacts
  - SEC: First three letters of the section (e.g., DEV for Development, API for API)
  - XXX: Sequential number within that section

- **type**: Type of document
  - Values: `Documentation` or `Artifact`

- **version**: Document version number
  - Start with 1.0 and increment for major changes

- **created**: Date when the document was first created
  - Format: YYYY-MM-DD

- **updated**: Date when the document was last updated
  - Format: YYYY-MM-DD

- **artifact_directory** (optional): For README files in artifact directories
  - Reference to the artifact directory ID

## Usage Instructions

1. Copy the appropriate metadata block from this template
2. Paste it at the very top of your documentation file
3. Fill in the appropriate values for each field
4. Ensure the ID matches the one assigned in the Documentation Map

## Notes

- All documentation files must include this metadata
- The metadata must be enclosed in triple-dashes (`---`)
- The metadata must be at the very top of the file
- The ID must match the one assigned in the Documentation Map
