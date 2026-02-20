# LinkWatcher Background Starter for this project
Write-Host "Starting LinkWatcher in background for this project..." -ForegroundColor Cyan

# Start the LinkWatcher in background using Start-Process
$process = Start-Process -FilePath "python" -ArgumentList "C:\Users\ronny\bin\main.py" -WindowStyle Hidden -PassThru

if ($process) {
    Write-Host "LinkWatcher started successfully in background (PID: $($process.Id))" -ForegroundColor Green
} else {
    Write-Host "Failed to start LinkWatcher" -ForegroundColor Red
}
