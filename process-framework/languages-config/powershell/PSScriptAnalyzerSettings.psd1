# Curated PSScriptAnalyzer ruleset for the framework PowerShell script fleet (PF-IMP-1328).
#
# Consumed by scripts/validation/Run-ScriptConventionGate.ps1 (warn-first pre-commit / CI gate).
# IncludeRules restricts the run to this high-signal set — the convention/footgun classes that
# actually fire on the fleet's *bare verb-named script* shape (param block at script scope, no
# enclosing `function Verb-Noun {}`).
#
# DELIBERATELY EXCLUDED (function-scoped or noise for this fleet; see PF-EVR-027 / PF-IMP-1328):
#   - PSUseShouldProcessForStateChangingFunctions / PSUseApprovedVerbs / PSProvideCommentHelp:
#     analyze FunctionDefinitionAst, so they miss the fleet's bare script-level contract and instead
#     flag internal helper functions (off-target noise — e.g. a correctly script-gated Update-*.ps1
#     gets flagged for its internal string-building helpers).
#   - PSAvoidUsingWriteHost: the deferred output/logging clean-slate (PF-IMP-1327, X-1) — ~1385
#     call sites; a separate initiative, not this gate.
#   - PSUseBOMForUnicodeEncodedFile: contradicts the framework's deliberate UTF-8-no-BOM convention.

@{
    IncludeRules = @(
        'PSAvoidAssignmentToAutomaticVariable',   # read-only / reserved automatic-var assignment (the $Args/$PID/$error footgun)
        'PSAvoidUsingEmptyCatchBlock',            # silently swallowed errors
        'PSUseDeclaredVarsMoreThanAssignments',   # assigned-but-never-used variables (dead code)
        'PSAvoidUsingInvokeExpression',           # code-injection footgun
        'PSPossibleIncorrectComparisonWithNull',  # $x -eq $null instead of $null -eq $x
        'PSShouldProcess'                         # declares SupportsShouldProcess but never calls $PSCmdlet.ShouldProcess (silent -WhatIf no-op)
    )
}
