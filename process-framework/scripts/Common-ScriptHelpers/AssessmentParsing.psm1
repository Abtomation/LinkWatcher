# AssessmentParsing.psm1

<#
.SYNOPSIS
Parses tier assessment documents to extract a feature's design requirements and tier.
#>
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
#
# PF-PRO-064 / PF-IMP-1947 (Instruction Medium, sub-concept 1 of the Framework
# Portfolio Architecture): adds the feature's declared implementation medium
# (Medium) and a fourth design dimension (InstructionDesignRequired) with its
# own gate in Get-NextStatusAfterDesignArtifact. Both are additive and default
# to the code medium, so an assessment written before this change parses
# exactly as it did.

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
      - Implementation medium ('code' | 'instruction' | 'mixed')
      - UI Design Required (bool)
      - API Design Required (bool)
      - Database Design Required (bool)
      - Instruction Design Required (bool)

    Throws on missing assessment file. Per appdev convention every feature
    has an assessment; a missing assessment indicates broken state, not a
    normal path.

    An assessment with no Implementation Medium section parses as 'code' — the
    documented default, and what every assessment written before PF-PRO-064
    already means.

    .PARAMETER FeatureId
    Feature ID in dotted form (e.g., "1.2.3"). The helper searches
    doc/documentation-tiers/assessments/ for files matching
    PD-ASS-*-<FeatureId>-*.md.

    .PARAMETER AssessmentFilePath
    Explicit path to an assessment file (overrides FeatureId lookup).
    Used primarily by tests and by callers that already located the file.

    .OUTPUTS
    Hashtable with keys: FeatureId, AssessmentId, AssessmentFile, Tier (int 1/2/3),
    Medium ('code'/'instruction'/'mixed'), UIDesignRequired (bool),
    APIDesignRequired (bool), DBDesignRequired (bool),
    InstructionDesignRequired (bool).
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

    # Extract the declared implementation medium (PF-PRO-064). Section form:
    #   ## Implementation Medium
    #
    #   - [ ] Code - ...
    #   - [ ] Instruction - ...
    #   - [ ] Mixed - ...
    # Absent section, or no box checked, means 'code' — the documented default,
    # which is what every pre-PF-PRO-064 assessment already means.
    $medium = 'code'
    if ($content -match '##\s+Implementation\s+Medium(?:(?!\r?\n#)[\s\S])*?\[\s*[xX]\s*\]\s+(Code|Instruction|Mixed)\b') {
        $medium = $matches[1].ToLower()
    }

    # Extract Design Required flags. Each section has the form:
    #   ### <Name> Design Required
    #
    #   - [ ] Yes - ...
    #   - [ ] No  - ...
    # The "Yes" checkbox being checked means the design is required.
    # The pattern (?:(?!\r?\n#)[\s\S])*? consumes section content lazily without
    # crossing into the next heading of any level, so a section never matches a
    # checkbox belonging to a later one. (It replaces an earlier (?!###) form,
    # which stopped only at "###" and so left the LAST design section's window
    # open across the "##" headings that follow it — latent while Database was
    # last, live once a fourth section was appended after it.)
    $sectionBody       = '(?:(?!\r?\n#)[\s\S])*?\[\s*[xX]\s*\]\s+Yes'
    $uiDesignRequired  = ($content -match ('###\s+UI\s+Design\s+Required' + $sectionBody))
    $apiDesignRequired = ($content -match ('###\s+API\s+Design\s+Required' + $sectionBody))
    $dbDesignRequired  = ($content -match ('###\s+Database\s+Design\s+Required' + $sectionBody))
    $instructionDesignRequired = ($content -match ('###\s+Instruction\s+Design\s+Required' + $sectionBody))

    return @{
        FeatureId                 = $FeatureId
        AssessmentId              = $assessmentId
        AssessmentFile            = $AssessmentFilePath
        Tier                      = $tier
        Medium                    = $medium
        UIDesignRequired          = $uiDesignRequired
        APIDesignRequired         = $apiDesignRequired
        DBDesignRequired          = $dbDesignRequired
        InstructionDesignRequired = $instructionDesignRequired
    }
}

function Get-NextStatusAfterDesignArtifact {
    <#
    .SYNOPSIS
    Computes the next-master-Status value after a design artifact — or the tier
    assessment itself — is completed, based on remaining design requirements
    from the feature's tier assessment.

    .DESCRIPTION
    Wraps Get-FeatureDesignRequirements and applies the standard transition
    rules used by the design-creator wrappers and the post-assessment update
    script. Centralizes the rule so all consumers agree on it (PF-IMP-1425).

    Rules (in priority order — first match wins):
      - If CurrentArtifact == "Assessment" AND Tier >= 2 → "📋 Needs FDD"
        (post-assessment, Tier 2+ needs FDD before the design chain; Tier 1
        skips FDD and falls through to the chain below)
      - If DB Design required AND CurrentArtifact != "SchemaDesign" → "🗄️ Needs DB Design"
      - If API Design required AND CurrentArtifact != "APISpecification" → "🔌 Needs API Design"
      - If UI Design required AND CurrentArtifact != "UIDesign" → "🎨 Needs UI Design"
      - If Instruction Design required AND CurrentArtifact != "InstructionDesign"
        → "📜 Needs Instruction Design"
      - Else if Tier == 1 → "🔧 Needs Impl Plan"
      - Else (Tier 2+) → "📝 Needs TDD"

    Instruction Design is the fourth design dimension (PF-PRO-064), gated last
    in the chain so a mixed feature's instruction design is authored with its
    code designs already in hand. It is independent of the feature's Medium:
    medium says what the deliverable is made of, this gate says whether the
    feature has an instruction dimension to design — declared, never inferred.
    Note the gate alone cannot fix a pure-instruction feature's terminal
    document: every gate here is a pass-through and the only terminals are TDD
    and Impl Plan, so a pure-instruction feature still lands on "📝 Needs TDD".
    Medium-aware terminal selection is the separate half of the fix and SHIPPED
    at PF-PRO-064 work item WI-5: New-TDD.ps1 takes -Medium and selects the
    tier-agnostic instruction terminal (tdd-instruction-template.md) for a
    pure-instruction feature, keeping the tier-forked code TDD for code and
    mixed. This helper still does not branch on Medium — it parses and carries
    it, and the terminal-shape decision belongs to the creator, not the router.

    UI Design is a workflow gate ordered after API and before TDD (PF-IMP-1352):
    a UI-Design-required feature routes to "🎨 Needs UI Design"; once the UI design
    is created, New-UIDesign calls this helper with CurrentArtifact "UIDesign" to
    advance to TDD / Impl Plan. (The former terminal "🎨 UI Design Created" milestone
    was retired in the same change — UI Design previously fell through this gate,
    silently skipping it; PF-IMP-1352.)

    .PARAMETER FeatureId
    Feature ID in dotted form (e.g., "1.2.3"). Requirements are resolved from
    the canonical assessments directory.

    .PARAMETER AssessmentFilePath
    Explicit path to the assessment file (alternative to FeatureId, mirroring
    Get-FeatureDesignRequirements's parameter sets) — for callers that already
    located the file, e.g. Update-FeatureTrackingFromAssessment.ps1.

    .PARAMETER CurrentArtifact
    Name of the artifact just created — excluded from "remaining requirements"
    to prevent self-routing (e.g., after Schema Design, don't route back to
    "Needs DB Design"). "Assessment" is the post-assessment entry point: no
    design artifact exists yet, so nothing is excluded (PF-IMP-1425).
    #>
    [CmdletBinding(DefaultParameterSetName='ByFeatureId')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='ByFeatureId')]
        [ValidatePattern('^\d+\.\d+(\.\d+)?$')]
        [string]$FeatureId,

        [Parameter(Mandatory=$true, ParameterSetName='ByPath')]
        [string]$AssessmentFilePath,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Assessment', 'FDD', 'SchemaDesign', 'APISpecification', 'UIDesign', 'InstructionDesign')]
        [string]$CurrentArtifact
    )

    $req = if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        Get-FeatureDesignRequirements -AssessmentFilePath $AssessmentFilePath
    } else {
        Get-FeatureDesignRequirements -FeatureId $FeatureId
    }

    # Post-assessment entry point (PF-IMP-1425): Tier 2+ needs FDD before the
    # design chain; Tier 1 skips FDD and falls through to the chain below.
    if ($CurrentArtifact -eq 'Assessment' -and $req.Tier -ge 2) {
        return "📋 Needs FDD"
    }

    if ($req.DBDesignRequired -and $CurrentArtifact -ne 'SchemaDesign') {
        return "🗄️ Needs DB Design"
    }
    if ($req.APIDesignRequired -and $CurrentArtifact -ne 'APISpecification') {
        return "🔌 Needs API Design"
    }
    if ($req.UIDesignRequired -and $CurrentArtifact -ne 'UIDesign') {
        return "🎨 Needs UI Design"
    }
    if ($req.InstructionDesignRequired -and $CurrentArtifact -ne 'InstructionDesign') {
        return "📜 Needs Instruction Design"
    }
    if ($req.Tier -eq 1) {
        return "🔧 Needs Impl Plan"
    }
    return "📝 Needs TDD"
}

Export-ModuleMember -Function Get-FeatureDesignRequirements, Get-NextStatusAfterDesignArtifact
