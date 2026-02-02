Write-Host "Flutter Project Setup" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Check Flutter
Write-Host "Checking Flutter..." -ForegroundColor Yellow
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "Flutter found!" -ForegroundColor Green
    flutter --version
} else {
    Write-Host "Flutter not found. Please install Flutter first." -ForegroundColor Red
    Write-Host "Visit: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

# Navigate to project directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Split-Path -Parent $scriptPath
Set-Location $projectPath

Write-Host "Project path: $projectPath" -ForegroundColor Cyan

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get

# Create directories
Write-Host "Creating directories..." -ForegroundColor Yellow
$dirs = @(
    "assets\icons",
    "assets\images",
    "lib\features\schedule\data",
    "lib\features\schedule\domain", 
    "lib\features\schedule\presentation",
    "lib\features\reminder\data",
    "lib\features\reminder\domain",
    "lib\features\reminder\presentation",
    "lib\features\profile\data",
    "lib\features\profile\domain",
    "lib\features\profile\presentation"
)

foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: flutter run" -ForegroundColor White
Write-Host "2. Read: SETUP_GUIDE.md" -ForegroundColor White
Write-Host "3. Check: PROJECT_PLAN.md" -ForegroundColor White