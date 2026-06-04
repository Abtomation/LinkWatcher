# Update-Tracking.ps1 — Test fixture for PD-BUG-033
if ($fileName -match 'ART-ASS-\d+-([0-9]+\.[0-9]+\.[0-9]+)-') {
    $FeatureId = $matches[1]
}
if ($assessmentContent -match '\[x\]\s+Tier\s+(\d+)') {
    $recommendedTier = "Tier $($matches[1])"
}
if ($fileName -match '(ART-ASS-\d+)-') {
    $AssessmentId = $matches[1]
}
Import-Module "../../Common-Helpers.psm1" -Force
