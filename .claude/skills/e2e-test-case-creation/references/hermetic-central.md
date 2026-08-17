# Hermetic-Central Pattern (Scripted Tests That Touch Central State)

Most scripted test cases exercise a script that mutates state files at fixed relative paths inside
the project tree — the sandbox plays "the project" and `Setup-TestEnvironment.ps1` gives each run a
clean workspace (the "sandbox-everywhere" pattern). But some framework scripts resolve
`process-framework-central/` instead (IMP lifecycle, central ID allocation, soak tracking,
rollout). Without intervention, a test invoking those would write sentinel rows and advance
counters in appdev's **real** central tracking files on every run.

The **hermetic-central pattern** redirects all central reads/writes to a per-test sandbox via an
environment-variable override, so the real appdev central is never touched mid-test.

## When it applies

Use this pattern when the script under test reaches central state — e.g.
`New-ProcessImprovement.ps1`, `Update-ProcessImprovement.ps1`, anything that allocates a central
`PF-IMP` / `PF-PRO` / etc. ID, soak-tracking scripts, or rollout/restore. If the script only
touches project-local `doc/` state, the plain sandbox-everywhere pattern is sufficient — you do not
need this.

## The override hook

Setting `$env:FRAMEWORK_CENTRAL_OVERRIDE` to a directory path redirects central resolution there.
It is honored by both central-path resolvers (PF-PRO-035 Session 29/30, OP-1):

- `Get-CentralFrameworkPath` in `process-framework/scripts/Common-ScriptHelpers/Core.psm1` —
  returns the override directly as the central path.
- `Resolve-CentralRegistryPath` in `process-framework/scripts/IdRegistry.psm1` — returns
  `<override>/PF-id-registry-central.json`. The override **must** cover this resolver too,
  otherwise ID allocations bypass it and leak counter increments into the real central registry.

Properties to rely on:

- The value is the **full central path**, not the appdev root — the fixture constructs exactly the
  directory it wants, including required state-file skeletons.
- Both resolvers **throw** if the override points at a non-existent path — the fixture must create
  the sandbox-central directory *before* invoking the script.
- Unset in production. (Distinct from `$env:PF_SOAK_DISABLE`, which suppresses soak counting
  rather than redirecting central state.)

## The `sandbox-central-seed/` convention

Place a `sandbox-central-seed/` directory beside the test case (alongside `test-case.md`,
`project/`, `expected/`). Seed it with the minimal central skeleton the script needs — typically
schema-correct, data-empty `process-framework-tracking` files plus minimal
`PF-id-registry-central.json` / `project-registry.json`. Pin counters to a **sentinel range**
(e.g. `PF-IMP.nextAvailable = 999900`) so allocated IDs are obviously distinguishable from real
central IDs and any leak is immediately visible as out-of-distribution noise.

This seed directory is **not** copied to the workspace by `Setup-TestEnvironment.ps1` (which only
copies `project/`). `run.ps1` copies it explicitly as its first action.

## The `run.ps1` recipe

1. **Snapshot real central** — read appdev's real `PF-id-registry-central.json` counter and
   `Get-FileHash` (SHA256) the real tracking file. These are the leak-detection baselines.
2. **Build a fresh sandbox-central** — copy `sandbox-central-seed/` → `<workspace>/sandbox-central/`
   (force-overwrite any prior run's state).
3. **Activate the override inside `try`/`finally`** —
   `$env:FRAMEWORK_CENTRAL_OVERRIDE = <workspace>/sandbox-central/`. Clear it in the `finally` so
   it clears even on assertion failure.
4. **Invoke the script(s) from the sandbox project** so `Get-ProjectRoot` resolves to the sandbox's
   project_id; all central writes land in the sandbox-central.
5. **Assert both directions** — the expected rows/counter landed in the sandbox-central, **and**
   the real central counter and tracking-file SHA256 are byte-identical to step 1's snapshot. The
   second assertion is the whole point of the pattern.

```powershell
param([Parameter(Mandatory=$true)][string]$WorkspacePath)
$ErrorActionPreference = 'Stop'

# 1. Snapshot real central (leak-detection baseline)
$realRegistry = Join-Path $appdevRoot 'process-framework-central/PF-id-registry-central.json'
$realTracking = Join-Path $appdevRoot 'process-framework-central/state-tracking/permanent/process-improvement-tracking.md'
$preCounter = (Get-Content $realRegistry -Raw | ConvertFrom-Json).prefixes.'PF-IMP'.nextAvailable
$preHash    = (Get-FileHash $realTracking -Algorithm SHA256).Hash

# 2. Fresh sandbox-central from the seed
$sandboxCentral = Join-Path $WorkspacePath 'sandbox-central'
if (Test-Path $sandboxCentral) { Remove-Item $sandboxCentral -Recurse -Force }
Copy-Item (Join-Path $PSScriptRoot 'sandbox-central-seed') $sandboxCentral -Recurse -Force

# 3. Activate override (cleared in finally even on failure)
$env:FRAMEWORK_CENTRAL_OVERRIDE = $sandboxCentral
try {
    # 4. Invoke the script(s) under test from the sandbox project
    & $scriptUnderTest -Param ... -Confirm:$false

    # 5a. Assert the write landed in the sandbox-central
    #     (counter advanced, row present, etc.)

    # 5b. Assert the REAL central was untouched (the leak gate)
    $postCounter = (Get-Content $realRegistry -Raw | ConvertFrom-Json).prefixes.'PF-IMP'.nextAvailable
    if ($postCounter -ne $preCounter) { Write-Error "Real central counter changed — override leaked"; exit 1 }
    if ((Get-FileHash $realTracking -Algorithm SHA256).Hash -ne $preHash) { Write-Error "Real central tracking changed — override leaked"; exit 1 }

    'ok' | Out-File (Join-Path $WorkspacePath 'project/success.txt') -Encoding utf8 -NoNewline
    exit 0
}
finally {
    Remove-Item env:FRAMEWORK_CENTRAL_OVERRIDE -ErrorAction SilentlyContinue
}
```

New central-touching cases pattern-match against this shape: the same `sandbox-central-seed/`
skeleton, the same override activation in a `try`/`finally`, and the same pre/post real-central
snapshot assertions.

## Leak-assertion failure procedure

A leak assertion failing means a code path bypassed `$env:FRAMEWORK_CENTRAL_OVERRIDE` and wrote to
the real central. Stop, do not commit the polluted files; `git diff HEAD -- process-framework-central`
from the appdev root to see what leaked, then extend the override to whichever resolver the
bypassing path used. Confirm the override was set *before* the first invocation and the
sandbox-central directory existed then (both resolvers throw on a missing override path).
