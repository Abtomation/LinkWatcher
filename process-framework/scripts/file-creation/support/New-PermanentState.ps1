<#
.SYNOPSIS
Creates a new permanent state tracking file with an automatically assigned ID.

.DESCRIPTION
Uses the central ID registry system and standardized document creation. By default creates a
project-local permanent tracker (PF-STA, routed by Get-StateTrackingContext). With -Shipped it
authors a FRAMEWORK-SHIPPED tracker into blueprint/doc/state-tracking/permanent/ with a portable
<FAMILY>-FST id (PF-IMP-1492; family resolved per workspace by Get-ArtifactPrefix — PF-FST at
appdev, FB-FST at FrameworkBuilder, PF-PRO-068 P-12a) — identical in every child and seeded into
a child's tree at bootstrap.

-Shipped runs at a PRODUCER FACE only (declared role 'framework' or 'framework-builder'), and
only where that face carries both halves of the shipped-tracker contract: the <FAMILY>-FST pool
declared in its framework ID registry, and the blueprint doc tree to write into. Both are
checked before the mint (PF-PRO-068 E4-h) so a half-configured face refuses with a message
naming what to add, rather than failing at the mint or writing into a tree nothing is seeded
from.

.PARAMETER StateName
Name of the tracker (e.g. "Release Status"). Drives the document title, the kebab-case filename,
and the "what this file tracks" line in the template body.

.PARAMETER Description
Brief description of what the file tracks. Replaces the template's placeholder description when
supplied; omitted leaves the placeholder in place.

.PARAMETER OpenInEditor
Opens the created state file in the configured editor after creation.

.PARAMETER Shipped
Authors a FRAMEWORK-SHIPPED tracker into blueprint/doc/state-tracking/permanent/ with a portable
<FAMILY>-FST id — identical in every child and seeded at bootstrap. Producer faces only; the
script errors at a leaf, and errors at a producer face missing either half of the contract.
Omitted (default) creates a project-local PF-STA tracker routed by Get-StateTrackingContext.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$StateName,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor,

    # Author a FRAMEWORK-SHIPPED tracker into the blueprint (producer faces only): allocates a
    # portable <FAMILY>-FST id and writes to blueprint/doc/state-tracking/permanent/. Omitted
    # (default) creates a project-local PF-STA tracker via Get-StateTrackingContext.
    [Parameter(Mandatory=$false)]
    [switch]$Shipped
)

# Import the common helpers + the ID registry module (Get-PrefixInfo for the -Shipped
# precondition below — IdRegistry is a sibling top-level module, not re-exported by the
# umbrella). Same idiom as New-Task.ps1.
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Import-Module (Join-Path $dir "IdRegistry.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, try/catch, and the error report are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script keeps only
# its param block (above), the state-specific data, and the success report.

# Prepare custom replacements
$customReplacements = @{
    "[State File Name]" = $StateName
    "[what this file tracks]" = $StateName.ToLower()
}

# Add description if provided
if ($Description -ne "") {
    $customReplacements["Brief state description"] = $Description
}

# Phase 5.5: configurable framework subtree via paths.process_framework
$processFrameworkDir = Get-ProcessFrameworkPath
$templatePath = Join-Path $processFrameworkDir "templates/support/state-file-template.md"

if ($Shipped) {
    # Framework-shipped tracker (producer-face only). Provenance convention (PF-IMP-1492): a
    # tracker shipped in the blueprint carries a portable PF-FST id — identical in every project
    # — not a project-local PD-STA/PF-STA id. Written to blueprint/doc/state-tracking/permanent/
    # so it seeds every project at bootstrap. The gate reads Get-StateTrackingContext's Mode,
    # which is role-derived (PF-PRO-067 Contract 4 — the "may I author blueprint/shipped
    # material?" role question): Mode 'central' means a producer-face workspace.
    $stContext = Get-StateTrackingContext
    if ($stContext.Mode -ne "central") {
        Write-ProjectError -Message "-Shipped requires a producer-face workspace (declared role 'framework' or 'framework-builder' in project_metadata.role): framework-shipped state trackers are authored in the owning workspace's blueprint (blueprint/doc/state-tracking/permanent), never in a leaf project's rolled-out copy." -ExitCode 1
    }
    # P-12a (PF-PRO-068): FST is a shipped framework pool, so the family is the workspace's
    # declared artifact_prefix. Resolved only inside this producer-face-gated branch — the
    # default (PF-STA) branch below runs at leaves, where Get-ArtifactPrefix throws by contract.
    $idPrefix      = "$(Get-ArtifactPrefix)-FST"
    $idDescription = "Framework-shipped state tracking: ${StateName}"
    $outputDir     = "blueprint/doc/state-tracking/permanent"
    $label         = "framework-shipped state tracker"

    # PRECONDITION (PF-PRO-068 E4-h, from PF-EVR-036 F5): a producer face may author a
    # framework-shipped tracker only if it has BOTH halves of the contract — the <FAMILY>-FST
    # pool declared in its framework ID registry, and the blueprint doc tree the tracker is
    # written into. Checked here, together, because each half fails badly on its own:
    #   - an undeclared pool surfaces only later, at the mint, as a registry error naming a
    #     prefix the operator never typed and not saying what to declare;
    #   - an absent doc tree does not surface AT ALL — the writer creates missing directories,
    #     so the tracker lands in a tree no child is ever seeded from, silently.
    # The message names BOTH halves whichever is missing: the pair is the contract, and a face
    # missing one is typically being stood up and needs the other in the same change.
    # The pool probe goes through Get-PrefixInfo deliberately — the same resolver the mint
    # uses — so this cannot become a second opinion that disagrees with the write path.
    $shippedDirAbs = Join-Path (Get-ProjectRoot) $outputDir
    $unmet = @()
    try { $null = Get-PrefixInfo -Prefix $idPrefix }
    catch { $unmet += "the '$idPrefix' pool is not declared in this workspace's framework ID registry" }
    if (-not (Test-Path -LiteralPath $shippedDirAbs)) {
        $unmet += "the shipped-tracker directory '$outputDir' does not exist in this workspace"
    }
    if ($unmet.Count -gt 0) {
        Write-ProjectError -Message ("-Shipped requires this workspace to declare the framework-shipped-tracker contract, and " +
            "$($unmet.Count) of its 2 halves $(if ($unmet.Count -eq 1) { 'is' } else { 'are' }) unmet: " + ($unmet -join '; ') + ". Both halves are needed: declare '$idPrefix' " +
            "in the framework ID registry with directories.permanent = 'doc/state-tracking/permanent', AND create " +
            "'$outputDir'. A shipped tracker is identical in every child, so a face that can mint the id but has nowhere " +
            "to author it (or vice versa) is a half-configured producer, not a usable one.") -ExitCode 1
    }
} else {
    $stContext     = Get-StateTrackingContext
    $idPrefix      = "PF-STA"
    $idDescription = "Permanent state tracking: ${StateName}"
    $outputDir     = "$($stContext.StateTrackingRelative)/permanent"
    $label         = "permanent state file"
}

$permanentId = New-FrameworkDocument -TemplatePath $templatePath -IdPrefix $idPrefix -IdDescription $idDescription -DocumentName $StateName -OutputDirectory $outputDir -Replacements $customReplacements -Label $label -OpenInEditor:$OpenInEditor

$details = @(
    "",
    "Next steps:",
    "1. Edit the file to define the state tracking structure",
    "2. Add initial state entries",
    "3. Use this file for ongoing project monitoring"
)

# Add mandatory guide consultation if not opening in editor
if (-not $OpenInEditor) {
    $details += "Customization required — see .claude/skills/state-file-customization/SKILL.md"
}

$successNoun = if ($Shipped) { "framework-shipped state tracker" } else { "permanent state file" }
Write-ProjectSuccess -Message "Created $successNoun with ID: $permanentId" -Details $details
