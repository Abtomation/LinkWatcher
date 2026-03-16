# Common-Helpers.psm1 — Minimal module (test fixture for PD-BUG-033)
function Get-ProjectRoot {
    return (Split-Path -Parent $PSScriptRoot)
}
Export-ModuleMember -Function Get-ProjectRoot
