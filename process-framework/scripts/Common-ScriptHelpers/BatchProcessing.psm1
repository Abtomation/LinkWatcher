# BatchProcessing.psm1
# Batch operations and multi-file processing utilities
# Provides batch processing capabilities for multiple files and operations

<#
.SYNOPSIS
Batch operations and multi-file processing utilities for PowerShell scripts

.DESCRIPTION
This module provides functionality for:
- Batch processing of multiple files
- Multi-operation workflows
- Parallel processing capabilities
- Progress tracking for batch operations
- Error handling for batch processes

.NOTES
Version: 3.0 (Modularized from Common-ScriptHelpers v2.0)
Created: 2025-08-26
#>

# Import dependencies
$scriptPath = Split-Path -Parent $PSScriptRoot
$coreModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers\Core.psm1"
$outputModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers\OutputFormatting.psm1"

if (Test-Path $coreModule) { Import-Module $coreModule -Force }
if (Test-Path $outputModule) { Import-Module $outputModule -Force }

function Invoke-BatchFileOperation {
    <#
    .SYNOPSIS
    Performs a batch operation on multiple files

    .PARAMETER FilePaths
    Array of file paths to process

    .PARAMETER Operation
    The operation to perform on each file (scriptblock)

    .PARAMETER OperationName
    Name of the operation for progress tracking

    .PARAMETER ContinueOnError
    Continue processing other files if one fails

    .EXAMPLE
    $files = @("file1.md", "file2.md", "file3.md")
    $operation = { param($filePath) Get-Content $filePath | Measure-Object -Line }
    Invoke-BatchFileOperation -FilePaths $files -Operation $operation -OperationName "Line Count"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$FilePaths,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,

        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Batch Operation",

        [Parameter(Mandatory=$false)]
        [switch]$ContinueOnError
    )

    $results = @()
    $totalFiles = $FilePaths.Count
    $currentFile = 0

    Write-Host "Starting $OperationName on $totalFiles files..." -ForegroundColor Cyan

    foreach ($filePath in $FilePaths) {
        $currentFile++
        $percentComplete = [math]::Round(($currentFile / $totalFiles) * 100, 1)

        Write-Progress -Activity $OperationName -Status "Processing $filePath" -PercentComplete $percentComplete

        try {
            $result = & $Operation $filePath
            $results += @{
                FilePath = $filePath
                Success = $true
                Result = $result
                Error = $null
            }
            Write-Verbose "Successfully processed: $filePath"
        }
        catch {
            $errorMessage = $_.Exception.Message
            $results += @{
                FilePath = $filePath
                Success = $false
                Result = $null
                Error = $errorMessage
            }

            if ($ContinueOnError) {
                Write-Warning "Error processing $filePath`: $errorMessage"
            } else {
                Write-Progress -Activity $OperationName -Completed
                throw "Error processing $filePath`: $errorMessage"
            }
        }
    }

    Write-Progress -Activity $OperationName -Completed

    $successCount = ($results | Where-Object { $_.Success }).Count
    $failureCount = $totalFiles - $successCount

    Write-Host "Batch operation completed: $successCount successful, $failureCount failed" -ForegroundColor Green

    return $results
}

function Invoke-ParallelFileOperation {
    <#
    .SYNOPSIS
    Performs a parallel operation on multiple files using PowerShell jobs

    .PARAMETER FilePaths
    Array of file paths to process

    .PARAMETER Operation
    The operation to perform on each file (scriptblock)

    .PARAMETER MaxConcurrentJobs
    Maximum number of concurrent jobs (default: 4)

    .PARAMETER OperationName
    Name of the operation for progress tracking

    .EXAMPLE
    $files = @("file1.md", "file2.md", "file3.md")
    $operation = { param($filePath) Get-Content $filePath | Measure-Object -Line }
    Invoke-ParallelFileOperation -FilePaths $files -Operation $operation -OperationName "Line Count"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$FilePaths,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,

        [Parameter(Mandatory=$false)]
        [int]$MaxConcurrentJobs = 4,

        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Parallel Operation"
    )

    $jobs = @()
    $results = @()
    $totalFiles = $FilePaths.Count
    $processedFiles = 0

    Write-Host "Starting $OperationName on $totalFiles files with $MaxConcurrentJobs concurrent jobs..." -ForegroundColor Cyan

    # Start initial batch of jobs
    for ($i = 0; $i -lt [math]::Min($MaxConcurrentJobs, $totalFiles); $i++) {
        $job = Start-Job -ScriptBlock $Operation -ArgumentList $FilePaths[$i]
        $jobs += @{
            Job = $job
            FilePath = $FilePaths[$i]
            Index = $i
        }
    }

    $nextFileIndex = $jobs.Count

    # Process jobs as they complete
    while ($jobs.Count -gt 0) {
        $completedJobs = @()

        foreach ($jobInfo in $jobs) {
            if ($jobInfo.Job.State -eq 'Completed' -or $jobInfo.Job.State -eq 'Failed') {
                $completedJobs += $jobInfo
            }
        }

        foreach ($jobInfo in $completedJobs) {
            $processedFiles++
            $percentComplete = [math]::Round(($processedFiles / $totalFiles) * 100, 1)

            Write-Progress -Activity $OperationName -Status "Processed $processedFiles of $totalFiles files" -PercentComplete $percentComplete

            try {
                if ($jobInfo.Job.State -eq 'Completed') {
                    $result = Receive-Job -Job $jobInfo.Job
                    $results += @{
                        FilePath = $jobInfo.FilePath
                        Success = $true
                        Result = $result
                        Error = $null
                    }
                } else {
                    $error = Receive-Job -Job $jobInfo.Job 2>&1
                    $results += @{
                        FilePath = $jobInfo.FilePath
                        Success = $false
                        Result = $null
                        Error = $error
                    }
                }
            }
            catch {
                $results += @{
                    FilePath = $jobInfo.FilePath
                    Success = $false
                    Result = $null
                    Error = $_.Exception.Message
                }
            }
            finally {
                Remove-Job -Job $jobInfo.Job -Force
                $jobs = $jobs | Where-Object { $_.Job.Id -ne $jobInfo.Job.Id }
            }

            # Start next job if more files to process
            if ($nextFileIndex -lt $totalFiles) {
                $newJob = Start-Job -ScriptBlock $Operation -ArgumentList $FilePaths[$nextFileIndex]
                $jobs += @{
                    Job = $newJob
                    FilePath = $FilePaths[$nextFileIndex]
                    Index = $nextFileIndex
                }
                $nextFileIndex++
            }
        }

        if ($jobs.Count -gt 0) {
            Start-Sleep -Milliseconds 100
        }
    }

    Write-Progress -Activity $OperationName -Completed

    $successCount = ($results | Where-Object { $_.Success }).Count
    $failureCount = $totalFiles - $successCount

    Write-Host "Parallel operation completed: $successCount successful, $failureCount failed" -ForegroundColor Green

    return $results
}

function New-BatchOperationReport {
    <#
    .SYNOPSIS
    Creates a report from batch operation results

    .PARAMETER Results
    Results from a batch operation

    .PARAMETER ReportPath
    Path to save the report (optional)

    .PARAMETER OperationName
    Name of the operation for the report

    .EXAMPLE
    $report = New-BatchOperationReport -Results $batchResults -OperationName "File Processing"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$false)]
        [string]$ReportPath,

        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Batch Operation"
    )

    $totalFiles = $Results.Count
    $successCount = ($Results | Where-Object { $_.Success }).Count
    $failureCount = $totalFiles - $successCount
    $successRate = if ($totalFiles -gt 0) { [math]::Round(($successCount / $totalFiles) * 100, 1) } else { 0 }

    $report = @"
# $OperationName Report

## Summary
- **Total Files**: $totalFiles
- **Successful**: $successCount
- **Failed**: $failureCount
- **Success Rate**: $successRate%

## Results

### Successful Operations
"@

    $successfulResults = $Results | Where-Object { $_.Success }
    foreach ($result in $successfulResults) {
        $report += "`n- ✅ $($result.FilePath)"
    }

    $report += "`n`n### Failed Operations"

    $failedResults = $Results | Where-Object { -not $_.Success }
    foreach ($result in $failedResults) {
        $report += "`n- ❌ $($result.FilePath): $($result.Error)"
    }

    if ($ReportPath) {
        Set-Content -Path $ReportPath -Value $report -Encoding UTF8
        Write-Host "Report saved to: $ReportPath" -ForegroundColor Green
    }

    return $report
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-BatchFileOperation',
    'Invoke-ParallelFileOperation',
    'New-BatchOperationReport'
)
