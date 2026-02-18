# New-Task.ps1
# Creates a new task document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Discrete", "Cyclical", "Support", "Onboarding")]
    [string]$TaskType,

    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("00-onboarding", "01-planning", "02-design", "03-testing", "04-implementation", "05-validation", "06-maintenance", "07-deployment", "support", "cyclical")]
    [string]$Category = "01-planning",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "task_type" = $TaskType
}

# Prepare custom replacements
$customReplacements = @{
    "# [Task Name]"                                                                       = "# $TaskName"
    "[1-2 sentences explaining the task's purpose and importance in the overall process]" = if ($Description -ne "") { $Description } else { "Task for $TaskName" }
}

# Create the document using standardized process
# Build absolute template path
$projectRoot = Get-ProjectRoot
$processFrameworkDir = Join-Path $projectRoot "doc\process-framework"
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\templates\task-template.md"

try {
    $taskId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-TSK" -IdDescription "$TaskType task: ${TaskName}" -DocumentName $TaskName -DirectoryType $Category -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    Write-Verbose "Created task with ID: $taskId"

    # Update the documentation map
    $docMapPath = Join-Path -Path $processFrameworkDir -ChildPath "documentation-map.md"
    if (Test-Path $docMapPath) {
        if ($PSCmdlet.ShouldProcess("Update documentation map with new task")) {
            $docMap = Get-Content -Path $docMapPath
            $sectionHeader = "### $TaskType Tasks"
            $sectionIndex = $docMap.IndexOf($sectionHeader)

            if ($sectionIndex -ge 0) {
                $fileName = ConvertTo-KebabCase -InputString $TaskName
                $relativePath = "process-framework/tasks/$Category/$fileName.md"
                $newEntry = "| $taskId | [/$relativePath](/$relativePath) | Documentation | $TaskName | /doc/process-framework/tasks/../../../tasks/README.md |"
                $docMap = $docMap[0..$sectionIndex] + $newEntry + $docMap[($sectionIndex + 1)..($docMap.Length - 1)]
                $docMap | Set-Content -Path $docMapPath
                Write-Verbose "Updated documentation map with new task"
            }
            else {
                Write-Warning "Could not find section '$sectionHeader' in documentation map. Manual update required."
            }
        }
    }

    # Update the tasks README
    $tasksReadmePath = Join-Path -Path $processFrameworkDir -ChildPath "tasks\README.md"
    if (Test-Path $tasksReadmePath) {
        if ($PSCmdlet.ShouldProcess("Update tasks README with new task")) {
            $tasksReadme = Get-Content -Path $tasksReadmePath

            # Find the appropriate section based on task type
            $sectionHeader = switch ($TaskType) {
                "Discrete" { "### Discrete Tasks" }
                "Cyclical" { "### Cyclical Tasks" }
                "Support" { "### Discrete Tasks" }  # Support tasks are listed in Discrete section
                "Onboarding" { "### Onboarding Tasks" }
            }

            $sectionIndex = $tasksReadme.IndexOf($sectionHeader)

            if ($sectionIndex -ge 0) {
                $tableStartIndex = $sectionIndex
                for ($i = $sectionIndex; $i -lt $tasksReadme.Length; $i++) {
                    if ($tasksReadme[$i] -match "^\| Task.*\| Description.*\| When to Use.*\|$") {
                        $tableStartIndex = $i
                        break
                    }
                }

                if ($tableStartIndex -gt $sectionIndex) {
                    $fileName = ConvertTo-KebabCase -InputString $TaskName
                    $newEntry = "| [$TaskName]($Category/$fileName.md) | $Description | When working on $TaskName |"
                    $tasksReadme = $tasksReadme[0..($tableStartIndex + 1)] + $newEntry + $tasksReadme[($tableStartIndex + 2)..($tasksReadme.Length - 1)]
                    $tasksReadme | Set-Content -Path $tasksReadmePath
                    Write-Verbose "Updated tasks README with new task"
                }
                else {
                    Write-Warning "Could not find table in section '$sectionHeader' in tasks README. Manual update required."
                }
            }
            else {
                Write-Warning "Could not find section '$sectionHeader' in tasks README. Manual update required."
            }
        }
    }

    # Update the AI Tasks main entry point
    $aiTasksPath = Join-Path -Path $projectRoot -ChildPath "ai-tasks.md"
    if (Test-Path $aiTasksPath) {
        if ($PSCmdlet.ShouldProcess("Update AI Tasks main entry point with new task")) {
            $aiTasks = Get-Content -Path $aiTasksPath

            # Validate ai-tasks.md structure matches script expectations
            $expectedSections = @(
                "### 🎓 00 - Onboarding Tasks",
                "### 📋 01 - Planning Tasks",
                "### 🎨 02 - Design Tasks",
                "### 🧪 03 - Testing Tasks",
                "### ⚙️ 04 - Implementation Tasks",
                "### ✅ 05 - Validation Tasks",
                "### 🔧 06 - Maintenance Tasks",
                "### 🚀 07 - Deployment Tasks",
                "### 🔧 Support Tasks"
            )

            $missingSections = @()
            foreach ($section in $expectedSections) {
                if ($aiTasks -notcontains $section) {
                    $missingSections += $section
                }
            }

            if ($missingSections.Count -gt 0) {
                Write-Error "❌ STRUCTURE MISMATCH DETECTED in ai-tasks.md"
                Write-Error ""
                Write-Error "The following expected section headers are missing:"
                foreach ($missing in $missingSections) {
                    Write-Error "  - $missing"
                }
                Write-Error ""
                Write-Error "This script expects ai-tasks.md to use category-based section headers."
                Write-Error "The file structure has likely changed. Please update the script's"
                Write-Error "category-to-section mapping at line ~126 to match the current structure."
                Write-Error ""
                Write-Error "Script location: $PSCommandPath"
                Write-Error "Target file: $aiTasksPath"
                throw "ai-tasks.md structure validation failed. Cannot proceed with task creation."
            }

            Write-Verbose "✓ ai-tasks.md structure validation passed"

            # Determine the section header based on category
            $fileName = ConvertTo-KebabCase -InputString $TaskName
            $relativePath = "/doc/process-framework/tasks/$Category/$fileName.md"

            # Map category to section header (ai-tasks.md uses category-based sections)
            $categoryToSection = @{
                "00-onboarding" = "### 🎓 00 - Onboarding Tasks"
                "01-planning" = "### 📋 01 - Planning Tasks"
                "02-design" = "### 🎨 02 - Design Tasks"
                "03-testing" = "### 🧪 03 - Testing Tasks"
                "04-implementation" = "### ⚙️ 04 - Implementation Tasks"
                "05-validation" = "### ✅ 05 - Validation Tasks"
                "06-maintenance" = "### 🔧 06 - Maintenance Tasks"
                "07-deployment" = "### 🚀 07 - Deployment Tasks"
                "support" = "### 🔧 Support Tasks"
            }

            $sectionHeader = $categoryToSection[$Category]
            if (-not $sectionHeader) {
                Write-Warning "Unknown category '$Category'. Cannot determine section header. Manual update required."
                return
            }

            # Support Tasks section has a different table format than other categories
            if ($Category -eq "support") {
                $tableHeaderPattern = "^\| Task.*\| Type.*\| Use When.*\| Link.*\|$"
                $taskType = $TaskType
                $useWhen = if ($Description -ne "") { $Description } else { "When working on $TaskName" }
                $newEntry = "| **$TaskName** | $taskType | $useWhen | [→ Definition]($relativePath) |"
            } else {
                $tableHeaderPattern = "^\| Task.*\| Use When.*\| Complexity.*\| Link.*\|$"
                $complexity = "🟡 Medium"
                $useWhen = if ($Description -ne "") { $Description } else { "When working on $TaskName" }
                $newEntry = "| **$TaskName** | $useWhen | $complexity | [→ Definition]($relativePath) |"
            }

            $sectionIndex = $aiTasks.IndexOf($sectionHeader)

            if ($sectionIndex -ge 0) {
                $tableStartIndex = $sectionIndex
                for ($i = $sectionIndex; $i -lt $aiTasks.Length; $i++) {
                    if ($aiTasks[$i] -match $tableHeaderPattern) {
                        $tableStartIndex = $i
                        break
                    }
                }

                if ($tableStartIndex -gt $sectionIndex) {
                    # Insert after the separator line (which is after the header)
                    $insertIndex = $tableStartIndex + 2
                    $aiTasks = $aiTasks[0..($insertIndex - 1)] + $newEntry + $aiTasks[$insertIndex..($aiTasks.Length - 1)]
                    $aiTasks | Set-Content -Path $aiTasksPath
                    Write-Verbose "Updated AI Tasks main entry point with new task"
                }
                else {
                    Write-Warning "Could not find table in section '$sectionHeader' in AI Tasks file. Manual update required."
                }
            }
            else {
                Write-Warning "Could not find section '$sectionHeader' in AI Tasks file. Manual update required."
            }
        }
    }
    else {
        Write-Warning "AI Tasks file not found at $aiTasksPath. Manual update required."
    }

    # Display next steps guidance
    Write-Host ""
    Write-Host "🚨 MANDATORY NEXT STEP: Task Creation Guide Review Required" -ForegroundColor Red
    Write-Host "   You MUST consult the Task Creation Guide before proceeding with customization." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "� REQUIRED READING:" -ForegroundColor Cyan
    Write-Host "   doc/process-framework/guides/guides/task-creation-guide.md" -ForegroundColor White
    Write-Host "   Focus on: 'Phase 2: Content Customization' section" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  The created file is only a structural framework - it requires extensive" -ForegroundColor Yellow
    Write-Host "   customization following the guide's instructions to become functional." -ForegroundColor Yellow
    Write-Host ""

    if (-not $OpenInEditor) {
        Write-Verbose "Task created successfully with automatic updates to:"
        Write-Verbose "  - Documentation map"
        Write-Verbose "  - Tasks README"
        Write-Verbose "  - AI Tasks main entry point"
        Write-Verbose "Edit the file to complete the task documentation."
    }
}
catch {
    Write-ProjectError -Message "Failed to create task: $($_.Exception.Message)" -ExitCode 1
}
