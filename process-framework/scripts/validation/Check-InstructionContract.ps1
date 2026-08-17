<#
.SYNOPSIS
    Warn-first pre-commit / CI detector that what a framework instruction *names* actually exists — invoked scripts, cross-document step references, and passed parameter names (PF-PRO-064 verification level 2).

.DESCRIPTION
    An instruction document is executable text: an agent reads it and runs what it
    says. Unlike code, nothing binds its references to their targets, so a renamed
    parameter or a relocated script leaves the prose behind and the failure surfaces
    only when an agent runs the command and the binder rejects it.

    This detector checks the instruction contract — that named things exist — and
    deliberately checks ONLY three syntactically decidable classes:

      1. Invocation targets   Script paths after '-File' / '&' on lines that are
                              genuinely invocations (inside a fenced block, or
                              carrying 'pwsh'). These are the references that
                              actually execute.
      2. Cross-document       'Step N' references bound to ANOTHER document by an
         step references      explicit link or task ID. Verified against that
                              document's own numbered steps.
      3. Parameter names      '-Name' tokens on an invocation whose script class 1
                              resolved, checked against (Get-Command).Parameters.

    Two instruction surfaces are scanned, because both are text an agent copies and
    runs: markdown documents, and the '.EXAMPLE' blocks of a .ps1's comment-based
    help. The example blocks were folded in after the markdown pass found a stale
    parameter in a task file whose identical twin sat unscanned in the owning
    script's own help. An example resolves its target only when it names the
    containing script by its own basename or gives an explicit path; any other bare
    script name is not decidable and is skipped.

    A broad backticked-prose existence checker was built and REJECTED by measurement
    before this narrowing (PF-PRO-064 correction C-7): over the same corpus it flagged
    17 of 130 script tokens — all 17 false positives — and left 62.5% of 72 pathful
    tokens unresolved, essentially all placeholders and elisions. Each class kept here
    is distinguishable from prose by syntax alone, which is why none needs a
    suppression file.

    Free-prose path and script-name existence stay OUT of scope by design: LinkWatcher
    '--validate' and Run-ScriptConventionGate.ps1's AST check already own them,
    including their suppression models. This detector must not rebuild either.

    Placeholders are skipped rather than reported: a token carrying <>, [], {}, a
    'path/to/' segment, a cwd-relative './' prefix, or a generic stand-in basename
    ('Script.ps1', 'child.ps1') is documentation scaffolding, not a contract.

.PARAMETER Path
    One or more files or directories to scan, comma-separated. Defaults to the
    framework's instruction corpus: task definitions, guides, craft skills, and the
    framework scripts (for their '.EXAMPLE' help blocks). Split in place so the same
    value binds under both '-File' and '-Command'. Directories are scanned for both
    .md and .ps1; appdev's own process-framework-central/scripts is not in the default
    (it is not part of the rolled-out framework) and can be added explicitly.

.PARAMETER Blocking
    Exit non-zero when the contract is broken. Default is warn-first: findings are
    reported and the exit code stays 0, per the framework's new-detector convention.

.PARAMETER FrameworkRoot
    Path to the process-framework tree. Defaults to the tree containing this script,
    so the same relative layout resolves in appdev (blueprint/process-framework) and
    in a rolled-out project (process-framework).

.NOTES
    Exit codes:
        0 = clean, or findings in warn-first mode (default)
        1 = findings and -Blocking was supplied
        2 = no corpus resolved (bad -Path, or malformed layout)
#>

[CmdletBinding()]
param(
    [string[]]$Path = @(),
    [switch]$Blocking,
    [string]$FrameworkRoot
)

$ErrorActionPreference = 'Stop'

if (-not $FrameworkRoot) {
    $FrameworkRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}
# Layout-agnostic anchors:
#   appdev  : FrameworkRoot=<repo>/blueprint/process-framework, Workspace=<repo>/blueprint, Repo=<repo>
#   project : FrameworkRoot=<repo>/process-framework,           Workspace=<repo>,           Repo=<repo>
$WorkspaceRoot = (Split-Path $FrameworkRoot -Parent)
$RepoRoot      = if ((Split-Path $WorkspaceRoot -Leaf) -eq 'blueprint') { Split-Path $WorkspaceRoot -Parent } else { $WorkspaceRoot }

# --- Corpus ----------------------------------------------------------------
$Path = @($Path -split '[,]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
if (-not $Path -or $Path.Count -eq 0) {
    $Path = @(
        (Join-Path $FrameworkRoot 'tasks')
        (Join-Path $FrameworkRoot 'guides')
        (Join-Path (Split-Path $FrameworkRoot -Parent) '.claude/skills')
        (Join-Path $FrameworkRoot 'scripts')
    )
}

$corpus = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
foreach ($p in $Path) {
    if (Test-Path -LiteralPath $p -PathType Container) {
        Get-ChildItem -LiteralPath $p -File -Recurse |
            Where-Object { $_.Extension -in @('.md', '.ps1') } |
            ForEach-Object { $corpus.Add($_) }
    } elseif (Test-Path -LiteralPath $p -PathType Leaf) {
        $corpus.Add((Get-Item -LiteralPath $p))
    } else {
        Write-Warning "Path not found, skipped: $p"
    }
}
if ($corpus.Count -eq 0) {
    # Deliberately NOT Write-Error: $ErrorActionPreference is 'Stop' here, so Write-Error
    # would terminate with exit 1 and the documented exit-2 contract could never be reached.
    Write-Host "[ERROR] No markdown files resolved from -Path. Nothing to check." -ForegroundColor Red
    exit 2
}

# --- Helpers ---------------------------------------------------------------

# Documentation scaffolding, not a contract. Skipped, never reported.
$script:GenericBasenames = @(
    'script.ps1','scriptname.ps1','yourscript.ps1','your-script.ps1','child.ps1','parent.ps1',
    'new-something.ps1','update-something.ps1','foo.ps1','bar.ps1','myscript.ps1','example.ps1'
)
function Test-InstructionPlaceholder {
    param([Parameter(Mandatory)][string]$Token)
    if ($Token -match '[<>\[\]{}]')        { return $true }   # <TARGET_PATH>, [Extension Name]
    if ($Token -match '(^|/)path/to/')     { return $true }
    if ($Token -match '^\.[\\/]')          { return $true }   # .\child.ps1 — relative to an unknown cwd
    if ((Split-Path $Token -Leaf).ToLower() -in $script:GenericBasenames) { return $true }
    return $false
}

function Resolve-InstructionPath {
    <#  Resolves a path as an instruction document writes it. Docs use the
        rolled-out-project form ('process-framework/scripts/...'), which in appdev
        lives under blueprint/ — so resolution is anchored on the layout, never on a
        hardcoded 'blueprint' guess. #>
    param([Parameter(Mandatory)][string]$Token)

    if ($Token -match '^[A-Za-z]:[\\/]' -or $Token -match '^[\\/]{2}') {
        if (Test-Path -LiteralPath $Token -PathType Leaf) { return (Resolve-Path -LiteralPath $Token).Path }
        return $null
    }
    $variants = @($Token)
    if ($Token -match '^appdev/') { $variants += ($Token -replace '^appdev/', '') }

    foreach ($v in $variants) {
        $candidates = @()
        if ($v -match '^process-framework/') {
            $candidates += (Join-Path $FrameworkRoot ($v -replace '^process-framework/', ''))
        }
        $candidates += (Join-Path $WorkspaceRoot $v)
        $candidates += (Join-Path $RepoRoot $v)
        foreach ($c in $candidates) {
            if (Test-Path -LiteralPath $c -PathType Leaf) { return (Resolve-Path -LiteralPath $c).Path }
        }
    }
    return $null
}

function Get-LogicalLine {
    <#  Framework invocations span lines via backtick (PowerShell) or backslash (bash)
        continuation, and appear inside blockquoted fences. Joining them is what makes
        class 3 see the parameters that sit on continuation lines — where a phantom
        parameter actually hides. Returns text + first physical line + fence state. #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Lines)

    $out = [System.Collections.Generic.List[object]]::new()
    $inFence = $false; $buf = $null; $bufStart = 0; $bufFence = $false
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $l = $Lines[$i] -replace '^\s*>\s?', ''      # unwrap blockquoted content
        if ($l -match '^\s*```') {
            if ($null -ne $buf) { $out.Add([pscustomobject]@{ Text = $buf; Line = $bufStart; InFence = $bufFence }); $buf = $null }
            $inFence = -not $inFence
            continue
        }
        $trimmed   = $l.TrimEnd()
        $continues = ($trimmed -match '`$') -or ($trimmed -match '\\$')
        $body      = $trimmed -replace '[`\\]$', ''
        if ($null -ne $buf) { $buf = $buf + ' ' + $body.Trim() }
        else                { $buf = $body; $bufStart = $i + 1; $bufFence = $inFence }
        if (-not $continues) { $out.Add([pscustomobject]@{ Text = $buf; Line = $bufStart; InFence = $bufFence }); $buf = $null }
    }
    if ($null -ne $buf) { $out.Add([pscustomobject]@{ Text = $buf; Line = $bufStart; InFence = $bufFence }) }
    return , $out
}

function Get-HelpExampleLine {
    <#  Pulls the invocation lines out of a .ps1's comment-based-help '.EXAMPLE'
        blocks. Same continuation joining as the markdown path, since example
        invocations wrap on backticks too. Only .EXAMPLE is read — .SYNOPSIS and
        .DESCRIPTION are prose and belong to the measured-false-positive class. #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Lines)

    $out = [System.Collections.Generic.List[object]]::new()
    $inHelp = $false; $inExample = $false; $buf = $null; $bufStart = 0
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $l = $Lines[$i]
        if ($l -match '^\s*<#') { $inHelp = $true; continue }
        if ($l -match '^\s*#>') {
            if ($null -ne $buf) { $out.Add([pscustomobject]@{ Text = $buf; Line = $bufStart }); $buf = $null }
            $inHelp = $false; $inExample = $false; continue
        }
        if (-not $inHelp) { continue }
        if ($l -match '^\s*\.([A-Z]+)') {
            if ($null -ne $buf) { $out.Add([pscustomobject]@{ Text = $buf; Line = $bufStart }); $buf = $null }
            $inExample = ($Matches[1] -eq 'EXAMPLE')
            continue
        }
        if (-not $inExample) { continue }
        $t = $l.TrimEnd()
        if ($t.Trim() -eq '') {
            if ($null -ne $buf) { $out.Add([pscustomobject]@{ Text = $buf; Line = $bufStart }); $buf = $null }
            continue
        }
        $continues = ($t -match '`$')
        $body      = $t -replace '`$', ''
        if ($null -ne $buf) { $buf = $buf + ' ' + $body.Trim() }
        else                { $buf = $body; $bufStart = $i + 1 }
        if (-not $continues) { $out.Add([pscustomobject]@{ Text = $buf; Line = $bufStart }); $buf = $null }
    }
    if ($null -ne $buf) { $out.Add([pscustomobject]@{ Text = $buf; Line = $bufStart }) }
    return , $out
}

function Get-NumberedStep {
    param([Parameter(Mandatory)][string]$DocPath)
    $steps = @()
    foreach ($m in (Select-String -LiteralPath $DocPath -Pattern '^\s*(\d+)(?:\.\d+)?[a-z]?\.\s' -AllMatches)) {
        $steps += $m.Matches[0].Groups[1].Value
    }
    return ($steps | Select-Object -Unique)
}

# pwsh host switches (not the target script's) + PowerShell common parameters.
$hostParams   = @('File','Command','ExecutionPolicy','NoProfile','NoLogo','NonInteractive','EncodedCommand','Version','WindowStyle')
$commonParams = @('Verbose','Debug','ErrorAction','WarningAction','InformationAction','ProgressAction',
                  'ErrorVariable','WarningVariable','InformationVariable','OutVariable','OutBuffer',
                  'PipelineVariable','WhatIf','Confirm')

# --- Scan ------------------------------------------------------------------
$findings   = [System.Collections.Generic.List[object]]::new()
$stats      = [ordered]@{ Class1 = 0; Class1Skipped = 0; Class2 = 0; Class3 = 0 }
$paramCache = @{}

function Test-InvocationParameter {
    <#  CLASS 3, shared by both surfaces. Quoted VALUES are stripped first: a value
        like "<feature-id>-tds.json" otherwise reads as a '-tds' parameter — the only
        false positive the pre-build measurement produced. #>
    param(
        [Parameter(Mandatory)][string]$Line,
        [Parameter(Mandatory)][string]$ResolvedScript,
        [Parameter(Mandatory)][string]$File,
        [Parameter(Mandatory)][int]$LineNumber
    )
    if (-not $paramCache.ContainsKey($ResolvedScript)) {
        try   { $paramCache[$ResolvedScript] = @((Get-Command $ResolvedScript -ErrorAction Stop).Parameters.Keys) }
        catch { $paramCache[$ResolvedScript] = $null }
    }
    $declared = $paramCache[$ResolvedScript]
    if ($null -eq $declared) { return }   # unparseable script: not this detector's finding

    $scrubbed = $Line -replace '"[^"]*"', '""' -replace "'[^']*'", "''"
    foreach ($pm in [regex]::Matches($scrubbed, '(?<![\w-])-([A-Za-z][A-Za-z0-9]*)')) {
        $pname = $pm.Groups[1].Value
        if ($pname -in $hostParams -or $pname -in $commonParams) { continue }
        $stats.Class3++
        if ($pname -notin $declared) {
            $findings.Add([pscustomobject]@{
                Class = 3; File = $File; Line = $LineNumber
                Message = "$(Split-Path $ResolvedScript -Leaf) has no parameter -$pname" })
        }
    }
}

foreach ($file in $corpus) {
    $raw = @(Get-Content -LiteralPath $file.FullName)
    $rel = $file.FullName.Replace('\', '/').Replace(($RepoRoot -replace '\\', '/') + '/', '')

    # ---- .ps1 surface: comment-based-help .EXAMPLE blocks --------------------
    if ($file.Extension -eq '.ps1') {
        foreach ($E in (Get-HelpExampleLine -Lines $raw)) {
            $line = $E.Text
            if ($line -match '^\s*#')     { continue }   # commentary inside an example
            if ($line -notmatch '\.ps1')  { continue }

            $m = [regex]::Match($line, '([^\s"''`,;()]+\.ps1)')
            if (-not $m.Success) { continue }
            $token = $m.Groups[1].Value
            if (Test-InstructionPlaceholder $token) { $stats.Class1Skipped++; continue }

            # Decidable targets only: the containing script by its own basename, or an
            # explicit path. Another bare script name could be any file in the tree.
            $resolved = $null
            if ((Split-Path $token -Leaf) -eq $file.Name) {
                $resolved = $file.FullName
            } elseif ($token -match '[\\/]') {
                $stats.Class1++
                $resolved = Resolve-InstructionPath $token
                if (-not $resolved) {
                    $findings.Add([pscustomobject]@{
                        Class = 1; File = $rel; Line = $E.Line
                        Message = "example invokes a script that does not exist: $token" })
                    continue
                }
            } else {
                continue   # not decidable
            }
            Test-InvocationParameter -Line $line -ResolvedScript $resolved -File $rel -LineNumber $E.Line
        }
        continue
    }

    # ---- markdown surface ---------------------------------------------------
    $ownIdMatch = $raw | Select-String -Pattern '^id:\s*(PF-\w+-\d+)' | Select-Object -First 1
    $ownId = if ($ownIdMatch) { $ownIdMatch.Matches[0].Groups[1].Value } else { $null }

    foreach ($L in (Get-LogicalLine -Lines $raw)) {
        $line = $L.Text

        # ---- CLASS 1 + 3 : invocation lines only -------------------------
        if ($L.InFence -or ($line -match 'pwsh(\.exe)?\s')) {
            foreach ($m in [regex]::Matches($line, '(?:-File|&)\s+["'']?([^\s"''`,;)]+\.(?:ps1|py))["'']?')) {
                $token = $m.Groups[1].Value
                if (Test-InstructionPlaceholder $token) { $stats.Class1Skipped++; continue }

                $stats.Class1++
                $resolved = Resolve-InstructionPath $token
                if (-not $resolved) {
                    $findings.Add([pscustomobject]@{
                        Class = 1; File = $rel; Line = $L.Line
                        Message = "invoked script does not exist: $token" })
                    continue
                }
                if ($resolved -notmatch '\.ps1$') { continue }

                Test-InvocationParameter -Line $line -ResolvedScript $resolved -File $rel -LineNumber $L.Line
            }
        }

        # ---- CLASS 2 : cross-document step references --------------------
        # Only bindings tight enough to be decidable: a link or task ID with nothing
        # between it and 'Step N' but whitespace/possessive. '[X](y.md) (activated at
        # Step 0)' is NOT one of these — that Step 0 belongs to the citing document.
        $refs = [System.Collections.Generic.List[object]]::new()
        foreach ($m in [regex]::Matches($line, '\]\(([^)]+?\.md)(?:#[^)]*)?\)(?:''s)?,?\s+Step\s+(\d+[a-z]?)')) {
            $refs.Add(@{ Target = $m.Groups[1].Value; Step = $m.Groups[2].Value; Kind = 'link' })
        }
        foreach ($m in [regex]::Matches($line, 'Step\s+(\d+[a-z]?)\s+(?:of|in)\s+(?:the\s+)?\[[^\]]*\]\(([^)]+?\.md)(?:#[^)]*)?\)')) {
            $refs.Add(@{ Target = $m.Groups[2].Value; Step = $m.Groups[1].Value; Kind = 'link' })
        }
        foreach ($m in [regex]::Matches($line, '([A-Z]{2,4}-TSK-\d+)(?:''s)?\s+Step\s+(\d+[a-z]?)')) {
            if ($ownId -and $m.Groups[1].Value -eq $ownId) { continue }   # self-reference is intra-document
            $refs.Add(@{ Target = $m.Groups[1].Value; Step = $m.Groups[2].Value; Kind = 'id' })
        }

        foreach ($r in $refs) {
            $stats.Class2++
            $targetPath = $null
            if ($r.Kind -eq 'id') {
                $targetPath = (Get-ChildItem (Join-Path $FrameworkRoot 'tasks') -Filter *.md -File -Recurse |
                    Where-Object { (Get-Content $_.FullName -TotalCount 3) -match "^id:\s*$($r.Target)\s*$" } |
                    Select-Object -First 1).FullName
            } else {
                $cand = Join-Path (Split-Path $file.FullName -Parent) $r.Target
                if (Test-Path -LiteralPath $cand -PathType Leaf) { $targetPath = (Resolve-Path -LiteralPath $cand).Path }
            }
            if (-not $targetPath) {
                $findings.Add([pscustomobject]@{
                    Class = 2; File = $rel; Line = $L.Line
                    Message = "step reference targets a document that does not exist: $($r.Target)" })
                continue
            }
            $n = $r.Step -replace '[a-z]$', ''
            if ((Get-NumberedStep -DocPath $targetPath) -notcontains $n) {
                $findings.Add([pscustomobject]@{
                    Class = 2; File = $rel; Line = $L.Line
                    Message = "$(Split-Path $targetPath -Leaf) has no Step $($r.Step)" })
            }
        }
    }
}

# --- Report ----------------------------------------------------------------
$classNames = @{ 1 = 'invocation target'; 2 = 'cross-document step ref'; 3 = 'parameter name' }

Write-Host ""
Write-Host "Instruction contract check (L2) - $($corpus.Count) documents" -ForegroundColor Cyan
Write-Host ("  checked: {0} invocation targets ({1} placeholders skipped), {2} step refs, {3} parameter names" -f `
    $stats.Class1, $stats.Class1Skipped, $stats.Class2, $stats.Class3)

if ($findings.Count -eq 0) {
    Write-Host "  [OK] instruction contract intact - no findings" -ForegroundColor Green
    exit 0
}

Write-Host ""
foreach ($g in ($findings | Group-Object Class | Sort-Object Name)) {
    Write-Host ("Class {0} - {1} ({2})" -f $g.Name, $classNames[[int]$g.Name], $g.Count) -ForegroundColor Yellow
    foreach ($f in $g.Group) { Write-Host ("  {0}:{1}  {2}" -f $f.File, $f.Line, $f.Message) }
}

Write-Host ""
if ($Blocking) {
    Write-Host "[FAIL] $($findings.Count) instruction-contract finding(s)." -ForegroundColor Red
    exit 1
}
Write-Host "[WARN] $($findings.Count) instruction-contract finding(s) - warn-first, not blocking." -ForegroundColor Yellow
Write-Host "       Promote with -Blocking once the corpus is clean." -ForegroundColor DarkGray
exit 0
