# PowerShell Scripts Link Test

This document contains links to PowerShell scripts to test if LinkWatcher properly updates these links when the .ps1 files are moved.

## Test Case: PowerShell Script Links

### Direct Links to PowerShell Scripts
- [Deployment Script](scripts/deploy.ps1) - Main deployment automation
- [Setup Script](scripts/setup.ps1) - Initial setup and configuration

### Links with Different Formats
- Link to deployment: [deploy.ps1](scripts/deploy.ps1)
- Link to setup: [setup.ps1](scripts/setup.ps1)

### Relative Path Links
- [../manual_test/scripts/deploy.ps1](scripts/deploy.ps1) (should be same as above)
- [./scripts/setup.ps1](scripts/setup.ps1)

### Links in Lists
1. First script: [deploy.ps1](scripts/deploy.ps1)
2. Second script: [setup.ps1](scripts/setup.ps1)

### Links in Tables
| Script | Purpose | Link |
|--------|---------|------|
| Deploy | Deployment automation | [deploy.ps1](scripts/deploy.ps1) |
| Setup | Initial configuration | [setup.ps1](scripts/setup.ps1) |

## Manual Test Instructions

1. **Initial State**: Verify that all links above work correctly
2. **Move Test**: Move one of the PowerShell scripts to a different location:
   - Move `scripts/deploy.ps1` to `scripts/automation/deploy.ps1`
   - Or move `scripts/setup.ps1` to `scripts/config/setup.ps1`
3. **Expected Behavior**: All links pointing to the moved script should be automatically updated
4. **Verification**: Check that all links in this document still work after the move

## Expected Results

✅ **Should work**: Links should be automatically updated when .ps1 files are moved
❌ **Current issue**: Links to .ps1 files are NOT being updated when the files are moved

## Notes

- This test specifically focuses on `.ps1` file extensions
- The issue appears to be that `.ps1` files are not included in the monitored extensions
- Other script types like `.py` files work correctly