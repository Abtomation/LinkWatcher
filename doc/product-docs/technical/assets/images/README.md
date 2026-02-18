---
id: PD-ASS-001
type: Documentation
version: 1.0
created: 2023-06-15
updated: 2023-06-15
artifact_directory: ART-ASS-003
---

# Documentation Images

This directory contains image files used in the BreakoutBuddies documentation, such as screenshots, icons, and other visual elements.

## Guidelines for Images

- Use descriptive filenames that clearly indicate the content
- Optimize images to reduce file size without significantly reducing quality
- Use appropriate formats (PNG for screenshots, JPEG for photographs)
- Keep images organized by creating subdirectories for specific categories if needed

## Adding New Images

When adding new images:

1. Use a descriptive filename (e.g., `login-screen-mobile.png`)
2. Compress the image to reduce file size
3. Include the image in documentation using proper Markdown syntax with alt text:
   ```markdown
   !<!-- [Login Screen on Mobile](/doc/assets/images/login-screen-mobile.png) - File not found -->
   ```

## Image Categories

As the project grows, consider organizing images into subdirectories such as:

- `/screenshots` - Application screenshots
- `/icons` - Icon files used in documentation
- `/ui-elements` - Images of specific UI components
- `/diagrams` - Simple diagrams that don't require the complexity of the diagrams directory
