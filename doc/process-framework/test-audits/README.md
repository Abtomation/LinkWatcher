# Test Audits Directory

This directory contains Test Audit Reports and related automation scripts for the BreakoutBuddies project's test quality assurance process.

## Directory Structure

```
test-audits/
├── README.md                           # This file
├── ../scripts/file-creation/New-TestAuditReport.ps1n/New-TestAuditReport.ps1            # Script to create new audit reports
├── Validate-AuditReport.ps1           # Script to validate audit reports
├── foundation/                        # Audit reports for 0.x.x features
├── authentication/                    # Audit reports for 1.x.x features
└── core-features/                     # Audit reports for 2.x.x+ features
```

## Feature Category Organization

Audit reports are organized by feature categories based on feature ID:

- **foundation/**: Features with ID `0.x.x` (System Architecture & Foundation)
- **authentication/**: Features with ID `1.x.x` (Authentication & User Management)
- **core-features/**: Features with ID `2.x.x+` (Core Application Features)

## Usage

### Creating a New Audit Report

Use the `New-TestAuditReport.ps1` script to create a new audit report:

```powershell
# Basic usage
..\scripts\file-creation\New-TestAuditReport.ps1New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFileId "PD-TST-001" -AuditorName "AI Agent"

# Open in editor after creation
..\scripts\file-creation\New-TestAuditReport.ps1New-TestAuditReport.ps1 -FeatureId "1.1.2" -TestFileId "PD-TST-015" -AuditorName "QA Engineer" -OpenInEditor
```

**Parameters**:
- `FeatureId`: The feature ID being audited (determines category directory)
- `TestFileId`: The test file ID being audited (e.g., "PD-TST-001")
- `AuditorName`: Name of the auditor (default: "AI Agent")
- `OpenInEditor`: Optional switch to open the created file in the default editor

### Validating an Audit Report

Use the `Validate-AuditReport.ps1` script to validate audit report completeness:

```powershell
# Basic validation
.\Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0.2.3-PD-TST-001.md"

# Detailed validation with all issues
.\Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0.2.3-PD-TST-001.md" -Detailed

# Validation with automatic fixes (where possible)
.\Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0.2.3-PD-TST-001.md" -Fix
```

**Validation Checks**:
- Metadata section completeness
- All six evaluation criteria addressed
- Audit decision consistency with findings
- Required sections completed
- Template placeholder detection
- Validation checklist completion

## Audit Process

The Test Audit process follows these steps:

1. **Preparation**: Review test implementation and specification
2. **Evaluation**: Assess tests against six quality criteria:
   - Purpose Fulfillment
   - Coverage Completeness
   - Test Quality & Structure
   - Performance & Efficiency
   - Maintainability
   - Integration Alignment
3. **Documentation**: Complete audit report with findings and recommendations
4. **Validation**: Use validation script to ensure report completeness
5. **Finalization**: Update test implementation tracking with audit results

## ID Registry Integration

- **Prefix**: `PF-TAR` (Process Framework - Test Audit Report)
- **ID Format**: `PF-TAR-001`, `PF-TAR-002`, etc.
- **Auto-assignment**: IDs are automatically assigned by the creation script
- **Registry**: Central ID registry tracks all assigned IDs

## Related Documentation

- [Test Audit Task Definition](../tasks/03-testing/test-audit-task.md)
- [Test Implementation Tracking](../state-tracking/permanent/test-implementation-tracking.md)
- [Test Audit Concept](../proposals/test-audit-concept.md)
- [Test Registry](../../../test/test-registry.yaml)

## File Naming Convention

Audit reports follow this naming pattern:
```
audit-report-[FEATURE_ID]-[TEST_FILE_ID].md
```

Examples:
- `audit-report-0.2.3-PD-TST-001.md`
- `audit-report-1.1.2-PD-TST-015.md`
- `audit-report-2.1.1-PD-TST-025.md`

## Automation Scripts

### ../scripts/file-creation/New-TestAuditReport.ps1n/New-TestAuditReport.ps1
- Creates new audit reports from template
- Automatically determines feature category
- Assigns unique PF-TAR ID
- Updates central ID registry
- Provides comprehensive template with all required sections

### Validate-AuditReport.ps1
- Validates audit report completeness
- Checks all six evaluation criteria
- Verifies audit decision consistency
- Detects template placeholders
- Provides detailed validation feedback

---

**Last Updated**: 2025-08-07
**Maintained By**: Process Framework - Test Audit Task (PF-TSK-030)
