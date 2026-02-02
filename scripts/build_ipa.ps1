Write-Host "🔨 构建 iOS IPA" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

# 进入项目目录
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Split-Path -Parent $scriptPath
Set-Location $projectPath

# 清理
Write-Host "🧹 清理旧构建..." -ForegroundColor Yellow
flutter clean
flutter pub get

# 构建 iOS (无签名)
Write-Host ""
Write-Host "📱 构建 iOS Release..." -ForegroundColor Yellow
flutter build ios --release --no-codesign

# 创建 IPA
Write-Host ""
Write-Host "📦 打包 IPA..." -ForegroundColor Yellow

$buildPath = "build/ios/iphoneos"
$payloadPath = "$buildPath/Payload"
$ipaPath = "SaizeriYa-Scheduler.ipa"

# 创建 Payload 目录
if (Test-Path $payloadPath) {
    Remove-Item $payloadPath -Recurse -Force
}
New-Item -ItemType Directory -Path $payloadPath -Force | Out-Null

# 复制 Runner.app
Copy-Item "$buildPath/Runner.app" $payloadPath -Recurse

# 创建 ZIP (IPA)
if (Test-Path $ipaPath) {
    Remove-Item $ipaPath -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($buildPath, $ipaPath)

# 清理临时文件
Remove-Item $payloadPath -Recurse -Force

Write-Host ""
Write-Host "✅ IPA 构建完成！" -ForegroundColor Green
Write-Host "📍 位置: $(Get-Location)\$ipaPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "1. 使用 Sideloadly 安装到设备" -ForegroundColor White
Write-Host "2. 或上传到 GitHub Actions 自动签名" -ForegroundColor White