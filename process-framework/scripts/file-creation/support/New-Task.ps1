# New-Task.ps1
# Creates a new task document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("00-setup", "01-planning", "02-design", "03-testing", "04-implementation", "05-validation", "06-maintenance", "07-deployment", "support", "cyclical")]
    [string]$WorkflowPhase = "01-planning",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Helper: pad table row cells to match separator line column widths
function Format-AlignedTableRow {
    param(
        [string[]]$FileLines,
        [int]$TableHeaderIndex,
        [string[]]$Cells
    )
    # Separator line is immediately after the header
    $separatorLine = $FileLines[$TableHeaderIndex + 1]
    # Extract column widths from separator segments (e.g., "| ---- | ---------- |")
    $segments = $separatorLine -split '\|'
    # Skip first/last empty segments from leading/trailing pipe
    $colWidths = @()
    foreach ($seg in $segments) {
        $trimmed = $seg.Trim()
        if ($trimmed -match '^-+$') {
            $colWidths += $seg.Length  # preserve original spacing including surrounding spaces
        }
    }
    # Build padded row
    $paddedCells = @()
    for ($c = 0; $c -lt $Cells.Count; $c++) {
        if ($c -lt $colWidths.Count) {
            $targetWidth = $colWidths[$c] - 2  # subtract 2 for the surrounding spaces
            $cell = $Cells[$c]
            if ($cell.Length -lt $targetWidth) {
                $cell = $cell + (' ' * ($targetWidth - $cell.Length))
            }
            $paddedCells += " $cell "
        } else {
            $paddedCells += " $($Cells[$c]) "
        }
    }
    return "|" + ($paddedCells -join '|') + "|"
}

# Prepare custom replacements
$customReplacements = @{
    "# [Task Name]"                                                                       = "# $TaskName"
    "[1-2 sentences explaining the task's purpose and importance in the overall process]" = if ($Description -ne "") { $Description } else { "Task for $TaskName" }
}

# Create the document using standardized process
# Build absolute template path
$projectRoot = Get-ProjectRoot
$processFrameworkDir = Join-Path $projectRoot "process-framework"
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\task-template.md"

try {
    # IMP-407: Auto-append "-task" suffix with double-suffix guard
    $taskDocName = $TaskName
    if ($taskDocName -notmatch '(?i)[-\s]task$') {
        $taskDocName = "$taskDocName-task"
    }
    # IMP-438: Compute kebab filename once and reuse across all update sections
    $kebabFileName = ConvertTo-KebabCase -InputString $taskDocName

    $taskId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-TSK" -IdDescription "$WorkflowPhase task: ${TaskName}" -DocumentName $taskDocName -DirectoryType $WorkflowPhase -Replacements $customReplacements -OpenInEditor:$OpenInEditor

    Write-Verbose "Created task with ID: $taskId"

    # Update the documentation map
    $docMapPath = Join-Path -Path $processFrameworkDir -ChildPath "PF-documentation-map.md"
    if (Test-Path $docMapPath) {
        if ($PSCmdlet.ShouldProcess("Update documentation map with new task")) {
            $docMap = Get-Content -Path $docMapPath
            # Map workflow phase to PF-documentation-map.md section header
            $phaseToDocMapSection = @{
                "00-setup"          = "#### 00 - Setup Tasks"
                "01-planning"       = "#### 01 - Planning Tasks"
                "02-design"         = "#### 02 - Design Tasks"
                "03-testing"        = "#### 03 - Testing Tasks"
                "04-implementation" = "#### 04 - Implementation Tasks"
                "05-validation"     = "#### 05 - Validation Tasks"
                "06-maintenance"    = "#### 06 - Maintenance Tasks"
                "07-deployment"     = "#### 07 - Deployment Tasks"
                "support"           = "#### Support Tasks"
                "cyclical"          = "#### Cyclical Tasks"
            }
            $sectionHeader = $phaseToDocMapSection[$WorkflowPhase]
            if (-not $sectionHeader) {
                Write-Warning "Unknown workflow phase '$WorkflowPhase' for documentation map. Manual update required."
                return
            }
            $sectionIndex = $docMap.IndexOf($sectionHeader)

            if ($sectionIndex -ge 0) {
                # IMP-437: Use list format matching existing doc-map entries
                $descriptionText = if ($Description -ne "") { $Description } else { "Task for $TaskName" }
                $newEntry = "- [Task: $TaskName](tasks/$WorkflowPhase/$kebabFileName.md) - $descriptionText"
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

            # Map workflow phase to tasks/README.md section header
            $phaseToReadmeSection = @{
                "00-setup"          = "### 00 - Setup Tasks"
                "01-planning"       = "### 01 - Planning Tasks"
                "02-design"         = "### 02 - Design Tasks"
                "03-testing"        = "### 03 - Testing Tasks"
                "04-implementation" = "### 04 - Implementation Tasks"
                "05-validation"     = "### 05 - Validation Tasks"
                "06-maintenance"    = "### 06 - Maintenance Tasks"
                "07-deployment"     = "### 07 - Deployment Tasks"
                "support"           = "### Support Tasks"
                "cyclical"          = "### Cyclical Tasks"
            }
            $sectionHeader = $phaseToReadmeSection[$WorkflowPhase]
            if (-not $sectionHeader) {
                Write-Warning "Unknown workflow phase '$WorkflowPhase' for tasks README. Manual update required."
                return
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
                    $cells = @(
                        "[$TaskName]($WorkflowPhase/$kebabFileName.md)",
                        $Description,
                        "When working on $TaskName"
                    )
                    $newEntry = Format-AlignedTableRow -FileLines $tasksReadme -TableHeaderIndex $tableStartIndex -Cells $cells
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
    $aiTasksPath = Join-Path -Path $projectRoot -ChildPath "process-framework/ai-tasks.md"
    if (Test-Path $aiTasksPath) {
        if ($PSCmdlet.ShouldProcess("Update AI Tasks main entry point with new task")) {
            $aiTasks = Get-Content -Path $aiTasksPath

            # Validate process-framework/ai-tasks.md structure matches script expectations
            $expectedSections = @(
                "### 🎓 00 - Setup Tasks",
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
            $relativePath = "/process-framework/tasks/$WorkflowPhase/$kebabFileName.md"

            # Map workflow phase to section header (process-framework/ai-tasks.md uses phase-based sections)
            $phaseToSection = @{
                "00-setup" = "### 🎓 00 - Setup Tasks"
                "01-planning" = "### 📋 01 - Planning Tasks"
                "02-design" = "### 🎨 02 - Design Tasks"
                "03-testing" = "### 🧪 03 - Testing Tasks"
                "04-implementation" = "### ⚙️ 04 - Implementation Tasks"
                "05-validation" = "### ✅ 05 - Validation Tasks"
                "06-maintenance" = "### 🔧 06 - Maintenance Tasks"
                "07-deployment" = "### 🚀 07 - Deployment Tasks"
                "support" = "### 🔧 Support Tasks"
            }

            $sectionHeader = $phaseToSection[$WorkflowPhase]
            if (-not $sectionHeader) {
                Write-Warning "Unknown workflow phase '$WorkflowPhase'. Cannot determine section header. Manual update required."
                return
            }

            $useWhen = if ($Description -ne "") { $Description } else { "When working on $TaskName" }
            if ($WorkflowPhase -eq "support") {
                $tableHeaderPattern = "^\| Task.*\| Use When.*\| Link.*\|$"
                $cells = @("**$TaskName**", $useWhen, "[→ Definition]($relativePath)")
            } else {
                $tableHeaderPattern = "^\| Task.*\| Use When.*\| Complexity.*\| Link.*\|$"
                $cells = @("**$TaskName**", $useWhen, "🟡 Medium", "[→ Definition]($relativePath)")
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
                    $newEntry = Format-AlignedTableRow -FileLines $aiTasks -TableHeaderIndex $tableStartIndex -Cells $cells
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

    # Update the Process Framework Task Registry
    $registryPath = Join-Path -Path $processFrameworkDir -ChildPath "infrastructure/process-framework-task-registry.md"
    if (Test-Path $registryPath) {
        if ($PSCmdlet.ShouldProcess("Update task registry with new task")) {
            $registry = Get-Content -Path $registryPath -Encoding UTF8

            # Map workflow phase to registry section header and entry prefix
            $phaseToRegistry = @{
                "00-setup"          = @{ Section = "### **SETUP TASKS**";      Prefix = "S" }
                "01-planning"       = @{ Section = "### **DISCRETE TASKS**";   Prefix = "" }
                "02-design"         = @{ Section = "### **DISCRETE TASKS**";   Prefix = "" }
                "03-testing"        = @{ Section = "### **DISCRETE TASKS**";   Prefix = "" }
                "04-implementation" = @{ Section = "### **DISCRETE TASKS**";   Prefix = "" }
                "05-validation"     = @{ Section = "### **VALIDATION TASKS**"; Prefix = "V" }
                "06-maintenance"    = @{ Section = "### **DISCRETE TASKS**";   Prefix = "" }
                "07-deployment"     = @{ Section = "### **DISCRETE TASKS**";   Prefix = "" }
                "support"           = @{ Section = "### **SUPPORT TASKS**";    Prefix = "" }
                "cyclical"          = @{ Section = "### **CYCLICAL TASKS**";   Prefix = "" }
            }

            $registryInfo = $phaseToRegistry[$WorkflowPhase]
            if ($registryInfo) {
                $sectionHeader = $registryInfo.Section
                $entryPrefix = $registryInfo.Prefix

                # Find section boundaries
                $sectionStart = -1
                $sectionEnd = $registry.Length - 1
                for ($i = 0; $i -lt $registry.Length; $i++) {
                    if ($registry[$i] -eq $sectionHeader) {
                        $sectionStart = $i
                    } elseif ($sectionStart -ge 0 -and $i -gt $sectionStart -and $registry[$i] -match '^### \*\*') {
                        $sectionEnd = $i - 1
                        break
                    }
                }

                if ($sectionStart -ge 0) {
                    # Find the highest entry number in this section
                    $maxNum = 0
                    for ($i = $sectionStart; $i -le $sectionEnd; $i++) {
                        if ($registry[$i] -match "^#### \*\*${entryPrefix}(\d+)") {
                            $num = [int]$matches[1]
                            if ($num -gt $maxNum) { $maxNum = $num }
                        }
                    }
                    $nextNum = $maxNum + 1

                    $relPath = "../tasks/$WorkflowPhase/$kebabFileName.md"

                    # Build skeleton entry
                    $skeleton = @(
                        ""
                        "#### **${entryPrefix}${nextNum}. ${TaskName}** ([$taskId]($relPath))"
                        ""
                        "**`u{1F527} Process Type:** `u{1F527} **Manual** (Newly created — customize after task definition is complete)"
                        ""
                        "**`u{1F4CB} AUTOMATION DETAILS**"
                        ""
                        "- **Script:** _None — update after task customization_"
                        "- **Output Directory:** _TBD_"
                        ""
                        "**`u{1F4C1} FILE OPERATIONS**"
                        "| Operation | File Path | Update Method | Details |"
                        "|-----------|-----------|---------------|---------|"
                        "| _TBD_ | _Update after task customization_ | _TBD_ | _TBD_ |"
                        ""
                        "**`u{1F3AF} KEY IMPACTS**"
                        ""
                        "- **Primary output:** _Update after task customization_"
                        "- **Enables next steps:** _TBD_"
                        "- **Dependencies:** _TBD_"
                    )

                    # Insert before the next section (at sectionEnd + 1) or at the end of this section
                    $insertAt = $sectionEnd + 1
                    $registry = $registry[0..($insertAt - 1)] + $skeleton + $registry[$insertAt..($registry.Length - 1)]
                    $registry | Set-Content -Path $registryPath -Encoding UTF8
                    Write-Verbose "Updated task registry with skeleton entry"
                } else {
                    Write-Warning "Could not find section '$sectionHeader' in task registry. Manual update required."
                }
            } else {
                Write-Warning "Unknown workflow phase '$WorkflowPhase' for task registry mapping. Manual update required."
            }
        }
    }

    # Display next steps guidance
    Write-Host ""
    Write-Host "🚨 MANDATORY NEXT STEP: Task Creation Guide Review Required" -ForegroundColor Red
    Write-Host "   You MUST consult the Task Creation Guide before proceeding with customization." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "� REQUIRED READING:" -ForegroundColor Cyan
    Write-Host "process-framework/guides/support/task-creation-guide.md" -ForegroundColor White
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
        Write-Verbose "  - Process Framework Task Registry"
        Write-Verbose "Edit the file to complete the task documentation."
    }
}
catch {
    Write-ProjectError -Message "Failed to create task: $($_.Exception.Message)" -ExitCode 1
}
