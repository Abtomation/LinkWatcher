---
id: PD-ASS-000
type: Documentation
version: 1.0
created: 2023-06-15
updated: 2023-06-15
artifact_directory: ART-ASS-001
---

# Documentation Assets

This directory contains assets used in the BreakoutBuddies documentation, such as images, diagrams, and other media files.

## Directory Structure

- <!-- [images](/doc/assets/images) - File not found --> - Contains screenshots, icons, and other image files used in documentation
- <!-- [diagrams](/doc/assets/diagrams) - File not found --> - Contains architectural diagrams, flowcharts, and other visual representations

## Guidelines for Using Assets

When using assets in documentation:

1. **Use descriptive filenames** - Name files clearly to indicate their content (e.g., `authentication-flow-diagram.png`)
2. **Include alt text** - Always include alternative text for images in Markdown: `!<!-- [Alt text description](../../technica/assets/path/to/image.png) - Template/example link commented out -->`
3. **Optimize images** - Compress images to reduce file size without significantly reducing quality
4. **Use appropriate formats**:
   - PNG for screenshots and diagrams with text
   - JPEG for photographs
   - SVG for vector graphics when possible

## Adding New Assets

When adding new assets:

1. Place the asset in the appropriate subdirectory
2. Use a descriptive filename that clearly indicates the content
3. If creating a diagram, consider including the source file (e.g., draw.io XML) alongside the exported image
4. Update this ../../technica/assets/README.md if adding new asset categories or changing the organization

## Tools for Creating Assets

### Recommended Tools for Diagrams

- [Draw.io](https://draw.io) (free, web-based)
- [Lucidchart](https://www.lucidchart.com) (freemium)
- [Mermaid](https://mermaid-js.github.io/mermaid/#/) (text-based, can be embedded in Markdown)

### Recommended Tools for Screenshots

- Built-in OS screenshot tools (Windows Snipping Tool, macOS Screenshot, etc.)
- [Greenshot](https://getgreenshot.org/) (free, Windows)
- [Snagit](https://www.techsmith.com/screen-capture.html) (paid, Windows/macOS)

## Maintenance

Periodically review assets to:

1. Remove unused assets
2. Update outdated screenshots or diagrams
3. Improve image quality or clarity where needed
