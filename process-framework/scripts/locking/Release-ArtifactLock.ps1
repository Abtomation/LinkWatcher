<#
.SYNOPSIS
    Releases this session's lock on a guarded artifact — committing the file's changes first
    via a path-scoped commit (git commit --only), then deleting the lock row: commit-then-
    unlock, never the reverse (PF-PRO-061).

.DESCRIPTION
    The path-scoped commit uses `git commit --only -- <path>` pathspec semantics, which
    commit that file's working-tree state while leaving the shared index untouched — a
    parallel session's staged work is never swept in. An untracked (newly created) file is
    added first, then committed with the same pathspec.

    Built-in handling for the known per-commit failure shapes:
      - pre-commit auto-fixer hooks ("files were modified by this hook"): retried once —
        the retry picks up the fixed working tree;
      - .git/index.lock contention from a parallel committer: short retry loop;
      - any other (blocking-gate) failure: the LOCK IS RETAINED and the error reported —
        fix the cause, then re-run release.

    Before committing a changed markdown artifact, release maintains its frontmatter
    revision stamp (PF-IMP-1900): `updated:` is set to today and the `version:` last
    segment is incremented via Step-FrontmatterRevision (DocumentManagement.psm1), so
    agent edits never land with a stale stamp and no session hand-computes version
    numbers. Non-markdown files and files without frontmatter are committed as-is.

    If the file has no changes (a no-op edit), release skips the commit and just unlocks.
    No push and no LinkWatcher stop: both belong to full Git Commit and Push (PF-TSK-082)
    runs, not to path-scoped micro-commits (rationale in concept PF-PRO-061).

.PARAMETER Path
    The checked-out file to release — absolute, cwd-relative, or repo-root-relative.

.PARAMETER Message
    Optional commit-message first line. Default: "Update <filename> (<holder from lock>)".

.PARAMETER CoAuthoredBy
    Optional Co-Authored-By trailer value (e.g. "Claude Fable 5 <noreply@anthropic.com>").
    Omitted when not supplied.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [ValidateLength(3, 200)][string]$Message,
    [ValidateLength(3, 200)][string]$CoAuthoredBy
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'LockStore.psm1') -Force

function Invoke-PathScopedCommit {
    # Commits the working-tree state of one repo-relative path; returns the short commit hash.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$CommitMessage
    )

    $fixerRetried = $false
    $indexRetries = 0
    while ($true) {
        $output = (& git -C $ProjectRoot commit --only -m $CommitMessage -- $RelativePath 2>&1) -join "`n"
        if ($LASTEXITCODE -eq 0) {
            $hash = (& git -C $ProjectRoot rev-parse --short HEAD 2>&1) -join ''
            return $hash
        }
        if ($output -match 'index\.lock') {
            $indexRetries++
            if ($indexRetries -gt 5) { throw "Path-scoped commit failed: .git/index.lock still contended after 5 retries.`n$output" }
            Start-Sleep -Milliseconds 300
            continue
        }
        if (-not $fixerRetried -and $output -match 'files were modified by this hook') {
            $fixerRetried = $true   # auto-fixer amended the file; retry picks up the fixed tree
            continue
        }
        throw "Path-scoped commit for '$RelativePath' failed — LOCK RETAINED; fix the cause and re-run release.`n$output"
    }
}

$projectRoot = Resolve-LockingProjectRoot
$config = Get-LockingConfig -ProjectRoot $projectRoot

if (-not $config.Enabled) {
    Write-Warning "Artifact locking is disabled in this workspace — release is a no-op."
    exit 0
}

$rel = ConvertTo-RepoRelativePath -ProjectRoot $projectRoot -Path $Path
$sessionId = $env:CLAUDE_CODE_SESSION_ID

# Locate the lock and verify ownership BEFORE committing anything.
$lock = Invoke-LockStoreTransaction -StorePath $config.StorePath -Body {
    param($locks)
    $mine = @($locks | Where-Object { $_.path.ToLowerInvariant() -eq $rel.ToLowerInvariant() })
    return @{ Result = $(if ($mine.Count -gt 0) { $mine[0] } else { $null }) }
}
if ($null -eq $lock) {
    throw "'$rel' is not checked out — nothing to release. (Checkout-Artifact.ps1 acquires; the PreToolUse hook blocks lockless edits.)"
}
if ($sessionId -and $lock.sessionId -and $lock.sessionId -ne $sessionId) {
    throw "'$rel' is held by another session ('$($lock.holder)', session $($lock.sessionId)) — releasing a foreign lock requires Remove-ArtifactLock.ps1 with human approval."
}

if (-not $PSCmdlet.ShouldProcess($rel, 'Commit path-scoped changes and release lock')) { exit 0 }

# Cheap sensitive-file check on the single path (mirrors PF-TSK-082 Step 4's pattern).
if ($rel -match '\.(env|key|pem|secret|credential|password)') {
    throw "'$rel' matches the sensitive-file pattern — refusing the automatic commit. Resolve with the human partner (lock retained)."
}

$statusLine = ((& git -C $projectRoot status --porcelain -- $rel 2>&1) -join "`n").Trim()
$commitHash = $null
if ([string]::IsNullOrWhiteSpace($statusLine)) {
    Write-Host "[INFO] '$rel' has no uncommitted changes — releasing without a commit." -ForegroundColor Gray
} else {
    # Frontmatter revision stamp (PF-IMP-1900): a markdown artifact released with real
    # changes gets `updated:` set to today and its `version:` last segment incremented,
    # so agent edits can never land unbumped and no session does version arithmetic by
    # hand. Files without a leading frontmatter block (and non-markdown) pass untouched.
    if ($rel -match '\.md$') {
        $absTarget = Join-Path $projectRoot $rel
        $raw = Get-Content -Path $absTarget -Raw
        if ($raw -match '\A---\r?\n') {
            Import-Module (Join-Path $PSScriptRoot '../Common-ScriptHelpers/DocumentManagement.psm1') -Force -WarningAction SilentlyContinue
            $rev = Step-FrontmatterRevision -Content $raw
            if ($rev.Changed) {
                Set-Content -Path $absTarget -Value $rev.Content -NoNewline
                $stampNote = if ($rev.NewVersion) { "v$($rev.OldVersion) → v$($rev.NewVersion)" } else { "updated date only" }
                Write-Host "[INFO] Frontmatter revision stamped on '$rel' ($stampNote)." -ForegroundColor Gray
            }
        }
    }
    if ($statusLine -match '^\?\?') {
        & git -C $projectRoot add -- $rel 2>&1 | Out-Null   # untracked: introduce to git first
        if ($LASTEXITCODE -ne 0) { throw "git add for new file '$rel' failed — lock retained." }
    }
    $firstLine = if ($Message) { $Message } else { "Update $(Split-Path $rel -Leaf) ($($lock.holder))" }
    if ($firstLine.Length -gt 72) { $firstLine = $firstLine.Substring(0, 72) }
    $fullMessage = $firstLine
    if ($CoAuthoredBy) { $fullMessage += "`n`nCo-Authored-By: $CoAuthoredBy" }
    $commitHash = Invoke-PathScopedCommit -ProjectRoot $projectRoot -RelativePath $rel -CommitMessage $fullMessage
}

# Commit succeeded (or was a no-op) — now, and only now, drop the row.
Invoke-LockStoreTransaction -StorePath $config.StorePath -Body {
    param($locks)
    $kept = @($locks | Where-Object { $_.path.ToLowerInvariant() -ne $rel.ToLowerInvariant() })
    return @{ Locks = $kept }
} | Out-Null

if ($commitHash) {
    Write-Host "[OK] Committed '$rel' ($commitHash) and released the lock." -ForegroundColor Green
} else {
    Write-Host "[OK] Released the lock on '$rel' (no changes to commit)." -ForegroundColor Green
}
exit 0
