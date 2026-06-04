# Naming.psm1
# Canonical slug-normalization helpers for framework scripts that produce
# directories or filenames from human-typed names (feature names, workflow
# names, task names, template names, etc.).
#
# Created: 2026-05-07 (PF-IMP-008)
# Reason: 11+ framework scripts had ad-hoc slug logic with disagreeing
#   special-character handling. PF-TSK-064 onboarding hit a duplicate src/
#   directory ('application_shell_infrastructure' vs
#   'application_shell_and_infrastructure') because human input variation
#   ('& ' vs 'and') was not detected by the silent dir-creation code path.
#
# Public functions:
#   ConvertTo-FeatureSlug -Name <s> -Convention <kebab-case|snake_case|PascalCase>
#   New-FeatureDirSlug -Id <s> -Name <s>
#   Get-LevenshteinDistance -A <s1> -B <s2>
#   Test-FeatureSlugCollision -SlugCandidate <s> -ExistingSlugs <s[]> -Threshold <int>

function ConvertTo-FeatureSlug {
    <#
    .SYNOPSIS
    Converts a human-typed name to a canonical slug for use in dir/filenames.

    .DESCRIPTION
    Performs:
      1. Strip leading version-prefix pattern (e.g. "0.1.1 ", "1.1.3 - ")
      2. Apply convention:
         - kebab-case: lowercase, non-alphanumeric -> '-', collapse, trim
         - snake_case: lowercase, non-alphanumeric -> '_', collapse, trim
         - PascalCase: split on non-alphanumeric, capitalize each word, join

    The '&' character is treated as any other non-alphanumeric (replaced with
    the convention separator). This matches the existing ConvertTo-KebabCase
    behavior — switching to '&'->'and' substitution would orphan already-on-disk
    files. Use Test-FeatureSlugCollision to catch human-input variation
    ('X and Y' vs 'X & Y') at scaffold time.

    .PARAMETER Name
    The human-typed name to slug. Must be non-empty (Mandatory parameter binding
    rejects literal '' before this function runs). May, however, reduce to the
    empty string after version-prefix stripping (e.g. '1.2.3' → '') — that case
    is handled internally and returns ''.

    .PARAMETER Convention
    One of: 'kebab-case' (default), 'snake_case', 'PascalCase'.

    .PARAMETER PreserveCase
    For 'kebab-case' / 'snake_case': skip the lowercase step so the original
    casing of input characters is preserved. Has no effect on 'PascalCase'.
    Use for callers whose existing on-disk files use Title-Case-with-hyphens
    (e.g. New-FeatureImplementationState.ps1 produces
    "0.1.1-Application-Shell-and-Infrastructure-implementation-state.md").
    New scripts should leave this off — lowercase is the canonical form.

    .EXAMPLE
    ConvertTo-FeatureSlug -Name "Application Shell & Infrastructure"
    # Returns: "application-shell-infrastructure"

    .EXAMPLE
    ConvertTo-FeatureSlug -Name "0.1.1 Application Shell & Infrastructure" -Convention "snake_case"
    # Returns: "application_shell_infrastructure"

    .EXAMPLE
    ConvertTo-FeatureSlug -Name "Application Shell and Infrastructure" -PreserveCase
    # Returns: "Application-Shell-and-Infrastructure"

    .EXAMPLE
    ConvertTo-FeatureSlug -Name "user-authentication system" -Convention "PascalCase"
    # Returns: "UserAuthenticationSystem"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('kebab-case', 'snake_case', 'PascalCase')]
        [string]$Convention = 'kebab-case',

        [Parameter(Mandatory = $false)]
        [switch]$PreserveCase
    )

    # Strip leading version-prefix pattern (e.g. "0.1.1 ", "1.1.3 - ", "2.0 — ")
    $clean = $Name -replace '^\d+\.\d+(\.\d+)?\s*[-–—]?\s*', ''
    $clean = $clean.Trim()

    if ($clean -eq '') { return '' }

    if ($Convention -eq 'PascalCase') {
        $words = $clean -split '[^a-zA-Z0-9]+' | Where-Object { $_ -ne '' }
        $result = ($words | ForEach-Object {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
        }) -join ''
        return $result
    }

    $separator = if ($Convention -eq 'snake_case') { '_' } else { '-' }
    $working = if ($PreserveCase) { $clean } else { $clean.ToLower() }
    $result = $working -replace '[^a-zA-Z0-9]', $separator
    $result = $result -replace "$separator+", $separator
    return $result.Trim($separator)
}

function New-FeatureDirSlug {
    <#
    .SYNOPSIS
    Composes a directory slug from a feature ID (dot-separated) and a human-typed name.

    .DESCRIPTION
    Builds slugs like "1-2-customer-read" from Id="1.2" + Name="Customer Read".
    The ID's dots become dashes; the Name is normalized via ConvertTo-FeatureSlug
    (kebab-case); the two are joined with a dash.

    Distinct from ConvertTo-FeatureSlug because that function STRIPS leading
    numeric-version prefixes (^\d+\.\d+...) from the name. Here, the ID prefix
    is PRESERVED and transformed to dash form — that is the whole point.

    Created 2026-05-14 (PF-IMP-871 / PF-PRO-034 — Test and Audit Infrastructure
    Reorganization Phase 2a).

    Used by:
      - Update-FeatureCategory.ps1 for atomic level-aware category mutation
      - New-TestInfrastructure.ps1 -Update for test/audit feature-category dirs

    .PARAMETER Id
    Dot-separated feature ID. Accepts level 1 ("1"), level 2 ("1.2"), or
    level 3 ("1.2.3"). Other depths are rejected.

    .PARAMETER Name
    The human-typed name. Slugged via ConvertTo-FeatureSlug -Convention kebab-case.
    If the slugged name is empty (e.g. Name was only non-alphanumeric chars),
    the result is the ID-slug alone.

    .EXAMPLE
    New-FeatureDirSlug -Id "1" -Name "Customer Management"
    # Returns: "1-customer-management"

    .EXAMPLE
    New-FeatureDirSlug -Id "1.2" -Name "Customer Read"
    # Returns: "1-2-customer-read"

    .EXAMPLE
    New-FeatureDirSlug -Id "1.2.3" -Name "Read by ID"
    # Returns: "1-2-3-read-by-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d+(\.\d+){0,2}$')]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $idSlug = $Id -replace '\.', '-'
    $nameSlug = ConvertTo-FeatureSlug -Name $Name -Convention 'kebab-case'

    if ([string]::IsNullOrEmpty($nameSlug)) {
        return $idSlug
    }

    return "$idSlug-$nameSlug"
}

function Get-LevenshteinDistance {
    <#
    .SYNOPSIS
    Computes the Levenshtein edit distance between two strings.

    .DESCRIPTION
    Standard dynamic-programming implementation. Returns the minimum number
    of single-character insertions, deletions, or substitutions needed to
    transform A into B. Used by Test-FeatureSlugCollision to detect
    near-duplicate slugs from human input variation (e.g. "and" vs "&").

    .PARAMETER A
    First string.

    .PARAMETER B
    Second string.

    .EXAMPLE
    Get-LevenshteinDistance -A "application_shell_infrastructure" -B "application_shell_and_infrastructure"
    # Returns: 4 (insertions: 'a','n','d','_')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$A,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$B
    )

    $n = $A.Length
    $m = $B.Length
    if ($n -eq 0) { return $m }
    if ($m -eq 0) { return $n }

    $d = New-Object 'int[,]' ($n + 1), ($m + 1)
    for ($i = 0; $i -le $n; $i++) { $d[$i, 0] = $i }
    for ($j = 0; $j -le $m; $j++) { $d[0, $j] = $j }

    for ($i = 1; $i -le $n; $i++) {
        for ($j = 1; $j -le $m; $j++) {
            $cost = if ($A[$i - 1] -eq $B[$j - 1]) { 0 } else { 1 }
            $del = $d[($i - 1), $j] + 1
            $ins = $d[$i, ($j - 1)] + 1
            $sub = $d[($i - 1), ($j - 1)] + $cost
            $d[$i, $j] = [Math]::Min([Math]::Min($del, $ins), $sub)
        }
    }
    return $d[$n, $m]
}

function Test-FeatureSlugCollision {
    <#
    .SYNOPSIS
    Returns existing slugs that are within a Levenshtein-distance threshold
    of a candidate slug — i.e. probable duplicates from human input variation.

    .DESCRIPTION
    Compares the candidate slug against each existing slug. Exact matches are
    excluded (an exact match is a re-creation, not a collision; the caller
    handles idempotency separately). Returns a list of close matches, each
    with the existing slug and its Levenshtein distance to the candidate,
    sorted by distance ascending.

    Default threshold is 5, calibrated to catch the canonical PF-IMP-008
    collision: 'application_shell_infrastructure' vs
    'application_shell_and_infrastructure' has Levenshtein distance = 4 (insert
    "and_"), so threshold 5 (distances < 5 reported) flags it. For very short
    slugs (< 10 chars), threshold 5 is too aggressive — pass a smaller value.
    For very long slugs, raise the threshold proportionally.

    .PARAMETER SlugCandidate
    The slug about to be created.

    .PARAMETER ExistingSlugs
    Slugs already on disk (or already known) to compare against.

    .PARAMETER Threshold
    Maximum distance (exclusive) for a match. Default: 5.
    Distances STRICTLY LESS THAN Threshold are reported.

    .EXAMPLE
    Test-FeatureSlugCollision -SlugCandidate "application_shell_and_infrastructure" -ExistingSlugs @("shared", "application_shell_infrastructure", "database_management") -Threshold 5
    # Returns one collision: application_shell_infrastructure (distance 4)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SlugCandidate,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ExistingSlugs,

        [Parameter(Mandatory = $false)]
        [int]$Threshold = 5
    )

    $collisions = @()
    foreach ($existing in $ExistingSlugs) {
        if ($existing -eq $SlugCandidate) { continue }
        $distance = Get-LevenshteinDistance -A $SlugCandidate -B $existing
        if ($distance -lt $Threshold) {
            $collisions += [pscustomobject]@{
                ExistingSlug = $existing
                Distance     = $distance
            }
        }
    }
    return $collisions | Sort-Object Distance
}

Export-ModuleMember -Function @(
    'ConvertTo-FeatureSlug',
    'New-FeatureDirSlug',
    'Get-LevenshteinDistance',
    'Test-FeatureSlugCollision'
)
