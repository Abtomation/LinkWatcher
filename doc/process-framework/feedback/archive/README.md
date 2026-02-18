# Feedback Archive

This directory contains archived feedback forms that have been processed during Tools Review sessions.

## Structure

```
archive/
├── YYYY-MM/                          # Year-Month grouping
│   └── tools-review-YYYYMMDD/        # Specific review session
│       ├── processed-forms/          # Feedback forms that were analyzed
│       └── ../../../process-framework/feedback/archive/review-summary.md         # Summary of the review session
└── ../../../process-framework/feedback/archive/README.md                         # This file
```

## Archive Process

When a Tools Review Task is completed:

1. **Create Archive Folder**: Create a new folder using the pattern `YYYY-MM/tools-review-YYYYMMDD/`
2. **Move Processed Forms**: Move all feedback forms that were analyzed to the `processed-forms/` subfolder
3. **Copy Review Summary**: Copy the completed review feedback form to the archive folder
4. **Document**: Update any archive index or tracking files

## Purpose

- **Organization**: Keeps active feedback folder clean and focused on unprocessed forms
- **History**: Provides historical record of what was analyzed in each review
- **Traceability**: Maintains clear connection between reviews and processed forms
- **State Management**: Makes it easy to identify which forms still need processing

## Archive Retention

Archived feedback forms should be retained indefinitely as they provide valuable historical data for:
- Process improvement trends
- Tool effectiveness over time
- Decision audit trails
- Learning from past feedback patterns
