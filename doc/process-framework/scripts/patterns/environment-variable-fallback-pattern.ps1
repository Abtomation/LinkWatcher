<#
.SYNOPSIS
    Template showing environment variable fallback pattern for CMD.exe compatibility

.DESCRIPTION
    This pattern allows PowerShell scripts to be called from CMD.exe without the
    echo temp file workaround by falling back to environment variables for parameters
    that contain spaces.

.NOTES
    Add this code block after your param() block to enable environment variable fallback.

    Usage from CMD.exe:
    set SCRIPT_ParamName=Value with spaces
    pwsh.exe -File script.ps1

    Usage from PowerShell (normal):
    .\script.ps1 -ParamName "Value with spaces"

.EXAMPLE
    # In your script, modify parameter declarations and add fallback:

    param(
        # ⚠️ IMPORTANT: Do NOT use [Parameter(Mandatory=$true)]
        # Mandatory validation prevents fallback from working
        # Use manual validation after fallback instead
        [string]$DocumentId,
        [string]$Description,
        [string]$TaskName,

        # Optional parameters with defaults work fine
        [ValidateSet('High', 'Medium', 'Low')]
        [string]$Priority = 'Medium'
    )

    # Environment variable fallback pattern
    $envFallbacks = @{
        'DocumentId' = 'SCRIPT_DocumentId'
        'Description' = 'SCRIPT_Description'
        'TaskName' = 'SCRIPT_TaskName'
        'Priority' = 'SCRIPT_Priority'
    }

    foreach ($param in $envFallbacks.Keys) {
        $envVarName = $envFallbacks[$param]
        $currentValue = Get-Variable -Name $param -ValueOnly -ErrorAction SilentlyContinue

        if (-not $currentValue) {
            $envValue = [System.Environment]::GetEnvironmentVariable($envVarName)
            if ($envValue) {
                Write-Verbose "Using environment variable $envVarName for parameter $param"
                Set-Variable -Name $param -Value $envValue
            }
        }
    }

    # Manual validation for required parameters (replaces Mandatory=$true)
    if (-not $DocumentId -or -not $Description -or -not $TaskName) {
        Write-Error "Missing required parameters. DocumentId, Description, and TaskName are required."
        exit 1
    }

    # Rest of your script...

.EXAMPLE
    # CMD.exe one-liner pattern:
    set SCRIPT_TaskName=My new feature&& set SCRIPT_Description=This has spaces&& pwsh.exe -File New-Task.ps1 && set SCRIPT_TaskName=&& set SCRIPT_Description=
#>

# This is a template file - copy the pattern shown above into your scripts
Write-Host "This is a template file. See the comments above for usage." -ForegroundColor Yellow
