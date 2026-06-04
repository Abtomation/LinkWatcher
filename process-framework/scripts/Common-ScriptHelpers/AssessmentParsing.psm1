# AssessmentParsing.psm1
#
# Parses tier assessment documents to extract design requirements and tier
# classification. The assessment file (doc/documentation-tiers/assessments/
# PD-ASS-NNN-X.X.X-*.md) is the canonical source for these per-feature
# attributes; this helper exists so consumers can read them without
# duplicating the regex parsing logic.
#
# PF-IMP-766: retargets the design-required gate from the dropped master
# columns of feature-tracking.md to the assessment file itself, removing the
# legacy gate-scan blocks in New-FDD.ps1, New-SchemaDesign.ps1, and
# New-APISpecification.ps1.

# Import Core.psm1 (sibling sub-module) for Get-ProjectRoot.
$coreModule = Join-Path -Path $PSScriptRoot -ChildPath "Core.psm1"
if (Test-Path $coreModule) { Import-Module $coreModule -Force }

function Get-FeatureDesignRequirements {
    <#
    .SYNOPSIS
    Reads a feature's tier assessment file and returns design requirements + tier.

    .DESCRIPTION
    Locates the assessment file for a feature by ID (or accepts an explicit path)
    and parses it for:
      - Recommended tier (1, 2, or 3)
      - UI Design Required (bool)
      - API Design Required (bool)
      - Database Design Required (bool)

    Throws on missing assessment file. Per appdev convention every feature
    has an assessment; a missing assessment indicates broken state, not a
    normal path.

    .PARAMETER FeatureId
    Feature ID in dotted form (e.g., "1.2.3"). The helper searches
    doc/documentation-tiers/assessments/ for files matching
    PD-ASS-*-<FeatureId>-*.md.

    .PARAMETER AssessmentFilePath
    Explicit path to an assessment file (overrides FeatureId lookup).
    Used primarily by tests and by callers that already located the file.

    .OUTPUTS
    Hashtable with keys: FeatureId, AssessmentId, AssessmentFile, Tier (int 1/2/3),
    UIDesignRequired (bool), APIDesignRequired (bool), DBDesignRequired (bool).
    #>
    [CmdletBinding(DefaultParameterSetName='ByFeatureId')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='ByFeatureId')]
        [ValidatePattern('^\d+\.\d+(\.\d+)?$')]
        [string]$FeatureId,

        [Parameter(Mandatory=$true, ParameterSetName='ByPath')]
        [string]$AssessmentFilePath
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByFeatureId') {
        $projectRoot = Get-ProjectRoot
        $assessmentsDir = Join-Path -Path $projectRoot -ChildPath "doc/documentation-tiers/assessments"

        if (-not (Test-Path $assessmentsDir)) {
            throw "Assessment directory not found: $assessmentsDir"
        }

        $candidates = Get-ChildItem -Path $assessmentsDir -Filter "PD-ASS-*-$FeatureId-*.md" -ErrorAction SilentlyContinue

        if ($candidates.Count -eq 0) {
            throw "No assessment file found for feature $FeatureId in $assessmentsDir"
        } elseif ($candidates.Count -gt 1) {
            throw "Multiple assessment files found for feature $FeatureId — disambiguate with -AssessmentFilePath: $(($candidates | Select-Object -ExpandProperty Name) -join ', ')"
        }

        $AssessmentFilePath = $candidates[0].FullName
    } else {
        if (-not (Test-Path $AssessmentFilePath)) {
            throw "Assessment file not found: $AssessmentFilePath"
        }
    }

    $content = Get-Content -Path $AssessmentFilePath -Raw -Encoding UTF8

    # Extract feature ID (frontmatter or filename) when in -AssessmentFilePath mode
    if (-not $FeatureId) {
        if ($content -match 'feature_id:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
            $FeatureId = $matches[1]
        } elseif ((Split-Path $AssessmentFilePath -Leaf) -match 'PD-ASS-\d+-([0-9]+\.[0-9]+\.[0-9]+)-') {
            $FeatureId = $matches[1]
        }
    }

    # Extract assessment ID
    $assessmentId = $null
    if ($content -match 'id:\s*(PD-ASS-\d+)') {
        $assessmentId = $matches[1]
    } elseif ((Split-Path $AssessmentFilePath -Leaf) -match '(PD-ASS-\d+)-') {
        $assessmentId = $matches[1]
    }

    # Extract recommended tier — check the checkbox pattern first ("[x] Tier N")
    # then fall back to text patterns.
    $tier = $null
    if ($content -match '\[x\]\s+Tier\s+(\d+)') {
        $tier = [int]$matches[1]
    } elseif ($content -match '(?i)recommended\s+(?:documentation\s+)?tier[:\s]*(\d+)') {
        $tier = [int]$matches[1]
    } elseif ($content -match '(?i)tier\s+(\d+)\s+(?:is\s+)?recommended') {
        $tier = [int]$matches[1]
    }

    if (-not $tier) {
        throw "Could not determine recommended tier from assessment file: $AssessmentFilePath"
    }

    # Extract Design Required flags. Each section has the form:
    #   ### <Name> Design Required
    #
    #   - [ ] Yes - ...
    #   - [ ] No  - ...
    # The "Yes" checkbox being checked means the design is required.
    # The pattern (?:(?!###)[\s\S])*? consumes section content lazily without
    # crossing into the next "###" heading, preventing cross-section matches.
    $uiDesignRequired  = ($content -match '###\s+UI\s+Design\s+Required(?:(?!###)[\s\S])*?\[\s*[xX]\s*\]\s+Yes')
    $apiDesignRequired = ($content -match '###\s+API\s+Design\s+Required(?:(?!###)[\s\S])*?\[\s*[xX]\s*\]\s+Yes')
    $dbDesignRequired  = ($content -match '###\s+Database\s+Design\s+Required(?:(?!###)[\s\S])*?\[\s*[xX]\s*\]\s+Yes')

    return @{
        FeatureId          = $FeatureId
        AssessmentId       = $assessmentId
        AssessmentFile     = $AssessmentFilePath
        Tier               = $tier
        UIDesignRequired   = $uiDesignRequired
        APIDesignRequired  = $apiDesignRequired
        DBDesignRequired   = $dbDesignRequired
    }
}

function Get-NextStatusAfterDesignArtifact {
    <#
    .SYNOPSIS
    Computes the next-master-Status value after a design artifact is created,
    based on remaining design requirements from the feature's tier assessment.

    .DESCRIPTION
    Wraps Get-FeatureDesignRequirements and applies the standard transition
    rules used by the design-creator wrappers. Centralizes the rule so all
    wrappers agree on it.

    Rules (in priority order — first match wins):
      - If DB Design required AND CurrentArtifact != "SchemaDesign" → "🗄️ Needs DB Design"
      - If API Design required AND CurrentArtifact != "APISpecification" → "🔌 Needs API Design"
      - Else if Tier == 1 → "🔧 Needs Impl Plan"
      - Else (Tier 2+) → "📝 Needs TDD"

    UI Design is NOT a workflow gate in this chain — it produces a milestone
    "🎨 UI Design Created" status via New-UIDesign and is not consulted here.

    .PARAMETER FeatureId
    Feature ID in dotted form (e.g., "1.2.3").

    .PARAMETER CurrentArtifact
    Name of the artifact just created — excluded from "remaining requirements"
    to prevent self-routing (e.g., after Schema Design, don't route back to
    "Needs DB Design").
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^\d+\.\d+(\.\d+)?$')]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [ValidateSet('FDD', 'SchemaDesign', 'APISpecification')]
        [string]$CurrentArtifact
    )

    $req = Get-FeatureDesignRequirements -FeatureId $FeatureId

    if ($req.DBDesignRequired -and $CurrentArtifact -ne 'SchemaDesign') {
        return "🗄️ Needs DB Design"
    }
    if ($req.APIDesignRequired -and $CurrentArtifact -ne 'APISpecification') {
        return "🔌 Needs API Design"
    }
    if ($req.Tier -eq 1) {
        return "🔧 Needs Impl Plan"
    }
    return "📝 Needs TDD"
}

Export-ModuleMember -Function Get-FeatureDesignRequirements, Get-NextStatusAfterDesignArtifact
