Write-Host "🚀 VoiceFlow - 智能语音助手 项目初始化" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 检查 Flutter 是否安装
try {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Write-Host "✅ Flutter 已安装" -ForegroundColor Green
        flutter --version
    } else {
        Write-Host "❌ Flutter 未安装" -ForegroundColor Red
        Write-Host "请访问: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ 检查 Flutter 时出错" -ForegroundColor Red
    exit 1
}

# 检查 iOS 开发环境
Write-Host ""
Write-Host "检查 iOS 开发环境..." -ForegroundColor Yellow
flutter doctor --ios

# 进入项目目录
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Split-Path -Parent $scriptPath
Set-Location $projectPath

# 安装依赖
Write-Host ""
Write-Host "📦 安装依赖..." -ForegroundColor Yellow
flutter pub get

# 创建必要的目录
Write-Host ""
Write-Host "📁 创建目录结构..." -ForegroundColor Yellow

$directories = @(
    "assets/icons",
    "assets/images",
    "lib/features/schedule/data",
    "lib/features/schedule/domain",
    "lib/features/schedule/presentation",
    "lib/features/reminder/data",
    "lib/features/reminder/domain",
    "lib/features/reminder/presentation",
    "lib/features/profile/data",
    "lib/features/profile/domain",
    "lib/features/profile/presentation"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Host ""
Write-Host "✅ 项目初始化完成！" -ForegroundColor Green
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "1. 运行应用: flutter run" -ForegroundColor White
Write-Host "2. 查看文档: Get-Content SETUP_GUIDE.md" -ForegroundColor White
Write-Host "3. 查看计划: Get-Content PROJECT_PLAN.md" -ForegroundColor White