---
id: PD-ASS-002
type: Documentation
version: 1.0
created: 2023-06-15
updated: 2023-06-15
artifact_directory: ART-ASS-002
---

# Documentation Diagrams

This directory contains diagram files used in the BreakoutBuddies documentation, such as architecture diagrams, flowcharts, sequence diagrams, and other visual representations.

## Guidelines for Diagrams

- Use descriptive filenames that clearly indicate the content
- Include both the exported image (PNG/SVG) and the source file when possible
- Keep diagrams simple and focused on a specific concept
- Use consistent styling across diagrams (colors, shapes, fonts)
- Include a legend if the diagram uses non-standard symbols

## Adding New Diagrams

When adding new diagrams:

1. Use a descriptive filename (e.g., `authentication-flow-diagram.png`)
2. If possible, include the source file alongside the exported image (e.g., `authentication-flow-diagram.drawio`)
3. Include the diagram in documentation using proper Markdown syntax with alt text:
   ```markdown
   !<!-- [Authentication Flow Diagram](/doc/assets/diagrams/authentication-flow-diagram.png) - File not found -->
   ```

## Recommended Tools

- [Draw.io](https://draw.io) (free, web-based)
- [Lucidchart](https://www.lucidchart.com) (freemium)
- [Mermaid](https://mermaid-js.github.io/mermaid/#/) (text-based, can be embedded in Markdown)

## Diagram Categories

As the project grows, consider organizing diagrams into subdirectories such as:

- `/architecture` - System architecture diagrams
- `/flows` - Process and workflow diagrams
- `/er` - Entity-relationship diagrams
- `/sequence` - Sequence diagrams
- `/state` - State diagrams
