<#
.SYNOPSIS
    Warn-first (or blocking) pre-commit / CI gate over the framework PowerShell script fleet: an AST undefined-function (phantom-call) check, a hand-rolled frontmatter-date-regex check, an AST workspace-ID-literal check (PF-PRO-067), plus a curated PSScriptAnalyzer convention ruleset (PF-IMP-1328 / PF-IMP-1344 / PF-IMP-1582).
.DESCRIPTION
    Four checks over the framework script fleet (process-framework/scripts/**):

      1. Undefined-function check (AST, PSScriptAnalyzer-independent — always runs): flags a Verb-Noun
         command call that resolves to nothing — neither a function defined anywhere in the fleet nor an
         available cmdlet/command. Catches phantom helper calls (e.g. a Sync-CrossReferencedFiles or
         Validate-StateFileConsistency call whose function was never defined), which silently abort a real
         run after partial writes. Resolution is a static AST scan of the fleet's own function definitions
         (the loose path-imported .psm1 helpers do not resolve reliably via import+Get-Command), unioned
         with installed cmdlets.

      2. Hand-rolled frontmatter-date check (text scan — always runs): flags any inline
         regex-lookbehind date replace on the frontmatter `updated:` line outside
         DocumentManagement.psm1's Update-FrontmatterDate helper. Copies of that regex drift —
         the (?m)-less variant anchors ^ to start-of-string and silently no-ops the date write
         (PF-IMP-1582) — so every caller must go through the helper.

      3. Workspace-ID-literal check (AST — always runs; PF-PRO-067): flags -eq / -ne comparisons
         whose operand is a workspace-ID string literal (PRJ-NNN, PRJ-TNN, or FWK-MNEMONIC shapes).
         The uniform workspace model's invariant is "role is declared, never inferred" — role-shaped
         branching must read the declared role (project_metadata.role via Get-WorkspaceRole) and
         identity checks must compare the workspace's own project_id read from config, never an
         inline ID literal. Allowlist: Register-Project.ps1 (registration bootstrap legitimately
         assigns/compares the reserved identity); the allowlist is pinned by a Pester assertion so
         it cannot quietly grow.

      4. Convention lint (curated PSScriptAnalyzer ruleset): runs the high-signal ruleset in
         languages-config/powershell/PSScriptAnalyzerSettings.psd1. Skipped when PSScriptAnalyzer is not
         installed (it is an optional external module).

    Gate decision:
      - Default (warn-first): always exits 0 — findings are shown but never block the commit / CI run.
      - -Blocking: exits non-zero when either check reports findings (or, for the convention lint,
        PSScriptAnalyzer is unavailable). Promote to -Blocking once the fleet is clean.
.PARAMETER Blocking
    Fail the gate (non-zero exit on any finding, or on missing PSScriptAnalyzer) instead of warn-first.
.PARAMETER Path
    Directory to check (defaults to the framework script fleet next to this script).
.PARAMETER SettingsPath
    PSScriptAnalyzer settings file (defaults to the curated ruleset in languages-config/powershell/).
.EXAMPLE
    Run-ScriptConventionGate.ps1
    # warn-first / non-blocking — findings shown, commit never blocked.
.EXAMPLE
    Run-ScriptConventionGate.ps1 -Blocking
    # blocking — fails the gate on any phantom call or curated-rule finding.
#>
[CmdletBinding()]
param(
    [switch]$Blocking,
    [string]$Path = "",
    [string]$SettingsPath = ""
)

# Verb-Noun-shaped command names only (the framework/PowerShell function convention; phantoms are Verb-Noun).
$script:VerbNounPattern = '^[A-Z][a-zA-Z]+-[A-Z][a-zA-Z]+$'

function Get-UndefinedFunctionCall {
    # Returns one object per Verb-Noun call that resolves to neither a fleet-defined function nor an
    # available command. Static AST resolution — no module import (the loose .psm1 helpers do not resolve
    # reliably in a fresh session; the documented sub-module session-state fragility).
    param([string]$Root)

    $files = @(Get-ChildItem $Root -Recurse -Include *.ps1, *.psm1 -ErrorAction SilentlyContinue)
    $known = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    Get-Command -CommandType Cmdlet, Function, Alias, ExternalScript, Application -ErrorAction SilentlyContinue |
        ForEach-Object { [void]$known.Add($_.Name) }

    $asts = @{}
    foreach ($f in $files) {
        $t = $null; $e = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$t, [ref]$e)
        if (-not $ast) { continue }
        $asts[$f.FullName] = $ast
        foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
            [void]$known.Add($fn.Name)
        }
    }

    foreach ($f in $files) {
        $ast = $asts[$f.FullName]; if (-not $ast) { continue }
        foreach ($c in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)) {
            $name = $c.GetCommandName()
            if (-not $name) { continue }                       # dynamic (& $var) / path invocation
            if ($name -notmatch $script:VerbNounPattern) { continue }
            if ($known.Contains($name)) { continue }
            # Emit directly to the pipeline; the caller collects with @(...) into a clean array.
            [pscustomobject]@{ File = Split-Path $f.FullName -Leaf; Line = $c.Extent.StartLineNumber; Name = $name }
        }
    }
}


# Workspace-ID-literal check (PF-PRO-067). Allowlist: files whose workspace-ID comparisons are
# legitimate — Register-Project.ps1's registration bootstrap assigns/verifies the reserved
# identity. Pinned by a Pester assertion (Run-ScriptConventionGate.Tests.ps1) so a change here
# fails a test until acknowledged there.
$script:WorkspaceIdLiteralAllowlist = @('Register-Project.ps1')
# Literal shapes that look like workspace IDs: project (PRJ-NNN), sandbox (PRJ-TNN),
# framework mnemonic (FWK-XX..XXXX).
$script:WorkspaceIdLiteralPattern = '^((?:PRJ|APP)-\d{3}|(?:PRJ|APP)-T\d+|FWK-[A-Z]{2,4})$'

function Get-WorkspaceIdLiteralComparison {
    # PF-PRO-067 "role is declared, never inferred" detector: flags -eq/-ne comparisons (either
    # operand side, case-sensitive variants included) against a workspace-ID string literal.
    # Role-shaped branching must read the declared role; self-identity checks must read the
    # workspace's own project_id from config — never an inline ID literal.
    param([string]$Root)

    $eqOps = @([System.Management.Automation.Language.TokenKind]::Ieq,
               [System.Management.Automation.Language.TokenKind]::Ine,
               [System.Management.Automation.Language.TokenKind]::Ceq,
               [System.Management.Automation.Language.TokenKind]::Cne)

    Get-ChildItem $Root -Recurse -Include *.ps1, *.psm1 -ErrorAction SilentlyContinue |
        Where-Object { $script:WorkspaceIdLiteralAllowlist -notcontains $_.Name } |
        ForEach-Object {
            $t = $null; $e = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$t, [ref]$e)
            if (-not $ast) { return }
            $file = $_.Name
            foreach ($b in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.BinaryExpressionAst] }, $true)) {
                if ($eqOps -notcontains $b.Operator) { continue }
                foreach ($side in @($b.Left, $b.Right)) {
                    if ($side -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                        $side.Value -match $script:WorkspaceIdLiteralPattern) {
                        [pscustomobject]@{ File = $file; Line = $b.Extent.StartLineNumber; Literal = $side.Value }
                    }
                }
            }
        }
}

function Get-HandRolledFrontmatterDateReplace {
    # Flags inline copies of the frontmatter-date lookbehind regex outside the canonical
    # Update-FrontmatterDate helper (DocumentManagement.psm1). Copies drift — the (?m)-less
    # variant anchors ^ to start-of-string and silently no-ops the write (PF-IMP-1582).
    param([string]$Root)

    # Needle assembled at runtime so this script's own source never matches the scan.
    $needle = '(?<=' + '^updated:'
    Get-ChildItem $Root -Recurse -Include *.ps1, *.psm1 -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'DocumentManagement.psm1' } |
        Select-String -SimpleMatch $needle | ForEach-Object {
            [pscustomobject]@{ File = Split-Path $_.Path -Leaf; Line = $_.LineNumber }
        }
}

$scriptsRoot = Split-Path $PSScriptRoot -Parent          # process-framework/scripts
$pfRoot      = Split-Path $scriptsRoot -Parent           # process-framework
if ([string]::IsNullOrWhiteSpace($Path))         { $Path = $scriptsRoot }
if ([string]::IsNullOrWhiteSpace($SettingsPath)) { $SettingsPath = Join-Path $pfRoot 'languages-config/powershell/PSScriptAnalyzerSettings.psd1' }

$issues = 0

# --- Check 1: undefined-function (phantom) — PSScriptAnalyzer-independent ---
Write-Host ""
Write-Host "[script-convention gate] Undefined-function check (AST) over $Path" -ForegroundColor Cyan
$phantoms = @(Get-UndefinedFunctionCall -Root $Path)
if ($phantoms.Count -eq 0) {
    Write-Host "  clean — no unresolved Verb-Noun calls." -ForegroundColor Green
} else {
    Write-Host "  Unresolved Verb-Noun calls: $($phantoms.Count)" -ForegroundColor Red
    foreach ($p in ($phantoms | Sort-Object File, Line)) {
        Write-Host ("    {0}:{1}  {2}" -f $p.File, $p.Line, $p.Name) -ForegroundColor Red
    }
    $issues += $phantoms.Count
}

# --- Check 2: hand-rolled frontmatter-date replace (PF-IMP-1582) ---
Write-Host ""
Write-Host "[script-convention gate] Hand-rolled frontmatter-date check over $Path" -ForegroundColor Cyan
$handRolled = @(Get-HandRolledFrontmatterDateReplace -Root $Path)
if ($handRolled.Count -eq 0) {
    Write-Host "  clean — all frontmatter-date writes go through Update-FrontmatterDate." -ForegroundColor Green
} else {
    Write-Host "  Inline frontmatter-date regex copies (use Update-FrontmatterDate instead): $($handRolled.Count)" -ForegroundColor Red
    foreach ($h in ($handRolled | Sort-Object File, Line)) {
        Write-Host ("    {0}:{1}" -f $h.File, $h.Line) -ForegroundColor Red
    }
    $issues += $handRolled.Count
}

# --- Check 3: workspace-ID-literal comparisons (PF-PRO-067) — PSScriptAnalyzer-independent ---
Write-Host ""
Write-Host "[script-convention gate] Workspace-ID-literal check (AST) over $Path" -ForegroundColor Cyan
$idLiterals = @(Get-WorkspaceIdLiteralComparison -Root $Path)
if ($idLiterals.Count -eq 0) {
    Write-Host "  clean — no -eq/-ne comparisons against workspace-ID literals (role is declared, never inferred)." -ForegroundColor Green
} else {
    Write-Host "  Workspace-ID-literal comparisons (read the declared role / own project_id from config instead): $($idLiterals.Count)" -ForegroundColor Red
    foreach ($w in ($idLiterals | Sort-Object File, Line)) {
        Write-Host ("    {0}:{1}  {2}" -f $w.File, $w.Line, $w.Literal) -ForegroundColor Red
    }
    $issues += $idLiterals.Count
}

# --- Check 4: curated PSScriptAnalyzer convention ruleset (optional external dependency) ---
Write-Host ""
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "[script-convention gate] Convention lint: PSScriptAnalyzer not installed — install with: Install-Module PSScriptAnalyzer -Scope CurrentUser" -ForegroundColor Yellow
    if ($Blocking) { $issues += 1 }
} elseif (-not (Test-Path $SettingsPath)) {
    Write-Host "[script-convention gate] Convention lint: settings file not found at $SettingsPath" -ForegroundColor Yellow
    if ($Blocking) { $issues += 1 }
} else {
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    $findings = @(Invoke-ScriptAnalyzer -Path $Path -Settings $SettingsPath -Recurse)
    Write-Host "[script-convention gate] Convention lint (curated PSScriptAnalyzer ruleset) over $Path" -ForegroundColor Cyan
    if ($findings.Count -eq 0) {
        Write-Host "  clean — no curated-rule findings." -ForegroundColor Green
    } else {
        Write-Host "  Findings: $($findings.Count)" -ForegroundColor Yellow
        $findings | Group-Object RuleName | Sort-Object Count -Descending | ForEach-Object {
            Write-Host ("    {0,4}  {1}" -f $_.Count, $_.Name) -ForegroundColor Yellow
        }
        foreach ($f in $findings) {
            Write-Host ("    {0}:{1}  {2} [{3}]" -f $f.ScriptName, $f.Line, $f.RuleName, $f.Severity) -ForegroundColor DarkYellow
        }
        $issues += $findings.Count
    }
}

# --- Gate decision ---
Write-Host ""
if ($Blocking) {
    if ($issues -gt 0) {
        Write-Host "[script-convention gate] BLOCKING: $issues issue(s)." -ForegroundColor Red
        exit 1
    }
    Write-Host "[script-convention gate] BLOCKING: clean." -ForegroundColor Green
    exit 0
} else {
    Write-Host "[script-convention gate] warn-first / non-blocking (PF-IMP-1328 / PF-IMP-1344): the findings above do not block this commit. Promote with -Blocking once the fleet is clean." -ForegroundColor Yellow
    exit 0
}
