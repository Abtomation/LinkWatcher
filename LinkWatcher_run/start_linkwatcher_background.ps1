# LinkWatcher Background Starter for this project

# Check if LinkWatcher is already running
$existingProcess = Get-Process -Name "python*" -ErrorAction SilentlyContinue |
    Where-Object {
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            $cmdLine -and $cmdLine -match "main\.py"
        } catch {
            $false
        }
    }

if ($existingProcess) {
    Write-Host "LinkWatcher is already running (PID: $($existingProcess.Id -join ', '))" -ForegroundColor Yellow
    Write-Host "Not starting a new instance." -ForegroundColor Yellow
    return
}

Write-Host "Starting LinkWatcher in background for this project..." -ForegroundColor Cyan

# Start the LinkWatcher in background using Start-Process
$process = Start-Process -FilePath "python" -ArgumentList "C:\Users\ronny\bin\main.py" -WindowStyle Hidden -PassThru

if ($process) {
    Write-Host "LinkWatcher started successfully in background (PID: $($process.Id))" -ForegroundColor Green
} else {
    Write-Host "Failed to start LinkWatcher" -ForegroundColor Red
}
