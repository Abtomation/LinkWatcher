---
id: PF-DOC-000
type: Documentation
category: Guide
version: 1.0
created: 2023-06-15
updated: 2025-05-29
---

# LinkWatcher Documentation

This directory contains the documentation for the LinkWatcher project. The documentation is organized into the following directories:

## Development Approach

LinkWatcher uses a task-based development approach that:

1. Breaks down work into specific, well-defined tasks
2. Provides clear inputs and outputs for each task
3. Maintains project state through self-documenting artifacts
4. Eliminates the need for explicit handover documentation
5. Creates a natural flow between development activities

The project uses a task-based approach for development, focusing on specific tasks with clear inputs, processes, and outputs.

## Directory Structure

> **Important:** The documentation structure has been reorganized into two main categories: Process Framework Documentation and Product Documentation.

The documentation is now organized into two main categories:

### Process Framework Documentation

Documentation about how development is done:

- **process-framework/** - Process-related documentation
  - **guides/** - Development guides and standards
  - **improvement/** - Process improvement documentation
  - **methodologies/** - Development methodologies
  - **tasks/** - Development task definitions
    - **continuous/** - Ongoing tasks
    - **cyclical/** - Recurring tasks
    - **01-planning/** through **07-deployment/** - Categorized one-time tasks
  - **templates/** - Templates for process documentation

### Product Documentation

Documentation about LinkWatcher implementation:

- **../docs/** - Product-related documentation (at project root)
  - **testing.md** - Testing guide and framework
  - **ci-cd.md** - CI/CD pipeline documentation
  - **LOGGING.md** - Logging system documentation
  - **TROUBLESHOOTING_FILE_TYPES.md** - File type monitoring troubleshooting

### Supporting Directories

- **process-framework/state-tracking/** - Project state tracking files

  - **feature-tracking.md** - Current status of all features
  - **release-status.md** - Status of releases
  - **bug-tracking.md** - Status of bugs
  - **process-improvement-tracking.md** - Status of process improvements

## Creating New Documentation

To create new documentation:

1. Determine whether your documentation is Process Framework or Product Documentation
2. Choose the appropriate directory for your documentation
3. Copy the template from [Process: Documentation Template](process-framework/templates/templates/documentation-template.md)
4. Fill in the template with your content
5. Follow the guidelines in the [Process: Documentation Guide](process-framework/guides/guides/documentation-guide.md)
6. **Add your new documentation to the [Process: Documentation Map](process-framework/documentation-map.md)**

## Documentation Standards

All documentation should follow the standards outlined in the [Process: Documentation Guide](process-framework/guides/guides/documentation-guide.md). This ensures consistency and quality across all documentation.

## Contributing to Documentation

When you identify documentation needs or improvements:

1. Directly suggest specific changes to existing documentation
2. Provide complete new documentation when needed
3. Follow the [Process: Documentation Guide](process-framework/guides/guides/documentation-guide.md) standards
4. Update the [Process: Documentation Map](process-framework/documentation-map.md) for any new or moved files
5. Ensure all links remain functional after changes

As the AI assistant for this project, you should proactively maintain documentation without requiring formal issue creation or pull requests. This also includes the documentation template.

## Moving or Renaming Documentation

**IMPORTANT:** When moving or renaming documentation files:

1. **Always consult the [Process: Documentation Map](process-framework/documentation-map.md) first**
2. Update the file's entry in the Documentation Map
3. Update all links in the files listed in the "Linked From" column
4. Check for any other files that might link to the moved/renamed file

Failure to update links can lead to broken documentation references throughout the project.

## Documentation Review Process

All documentation changes should be reviewed by you. The review should check for:

- Technical accuracy
- Clarity and readability
- Adherence to documentation standards
- Completeness

## Contact

If you have any questions about the documentation, please ask the user.
