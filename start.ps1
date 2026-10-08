$baseDir = $PSScriptRoot

Write-Host "Starting Redis..."
try {
    Start-Process redis-server -WindowStyle Minimized
} catch {
    Write-Host "Redis server failed to start or is already running."
}

$services = @(
    "frontend",
    "backend\gateway",
    "backend\services\ai",
    "backend\services\auth",
    "backend\services\file",
    "backend\services\payment",
    "backend\services\project",
    "backend\services\terminal"
)

foreach ($service in $services) {
    $svcDir = Join-Path $baseDir $service
    Write-Host "Starting $service..."
    
    $command = "
        cd '$svcDir'
        if (!(Test-Path 'node_modules')) { 
            Write-Host 'Installing dependencies for $service...' -ForegroundColor Yellow
            npm install 
        } 
        Write-Host 'Starting $service...' -ForegroundColor Green
        npm run dev
    "
    
    # Opens a new PowerShell window for each service
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $command
}

Write-Host "All services are starting up in separate windows!" -ForegroundColor Cyan
