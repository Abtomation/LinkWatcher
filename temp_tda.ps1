Set-Location 'c:\Users\ronny\VS_Code\LinkWatcher'
& .\doc\process-framework\scripts\file-creation\New-TechnicalDebtAssessment.ps1 -AssessmentName 'Handler Module Structural Debt Assessment' -Scope 'linkwatcher/ Python modules (primary: handler.py)' -AssessmentType 'Post-Feature' -Confirm:$false
