# VoiceFlow 快速测试设置脚本
# 用于快速启动本地测试环境

Write-Host "🚀 VoiceFlow 快速测试设置" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# 检查是否已构建Web版本
if (!(Test-Path "build/web/index.html")) {
    Write-Host "❌ 未找到Web构建文件，正在构建..." -ForegroundColor Yellow
    flutter build web
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Web构建失败，请检查错误信息" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Web构建完成" -ForegroundColor Green
} else {
    Write-Host "✅ 发现已有Web构建文件" -ForegroundColor Green
}

# 获取本机IP地址
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi" | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"}).IPAddress | Select-Object -First 1

if (!$ipAddress) {
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne "127.0.0.1" -and $_.IPAddress -ne "::1"}).IPAddress | Select-Object -First 1
}

Write-Host ""
Write-Host "📱 真机测试信息" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "本机IP地址: $ipAddress" -ForegroundColor White
Write-Host "测试端口: 8080" -ForegroundColor White
Write-Host ""
Write-Host "📋 测试步骤:" -ForegroundColor Yellow
Write-Host "1. 确保手机和电脑连接同一WiFi网络" -ForegroundColor White
Write-Host "2. 在手机浏览器中访问: http://$ipAddress:8080" -ForegroundColor White
Write-Host "3. 测试通知功能: 点击'推送测试'按钮" -ForegroundColor White
Write-Host "4. 测试语音功能: 点击'语音测试'按钮" -ForegroundColor White
Write-Host "5. 独立测试页面: http://$ipAddress:8080/test_notifications.html" -ForegroundColor White
Write-Host ""

# 询问是否启动服务器
$startServer = Read-Host "是否现在启动本地服务器? (y/n)"
if ($startServer -eq "y" -or $startServer -eq "Y" -or $startServer -eq "") {
    Write-Host ""
    Write-Host "🌐 启动本地Web服务器..." -ForegroundColor Green
    Write-Host "服务器地址: http://localhost:8080" -ForegroundColor White
    Write-Host "手机访问地址: http://$ipAddress:8080" -ForegroundColor White
    Write-Host ""
    Write-Host "按 Ctrl+C 停止服务器" -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Green
    
    Set-Location "build/web"
    python -m http.server 8080
} else {
    Write-Host ""
    Write-Host "💡 手动启动服务器命令:" -ForegroundColor Yellow
    Write-Host "cd build/web" -ForegroundColor White
    Write-Host "python -m http.server 8080" -ForegroundColor White
    Write-Host ""
    Write-Host "然后在手机浏览器访问: http://$ipAddress:8080" -ForegroundColor White
}

Write-Host ""
Write-Host "📚 更多测试信息请查看: REAL_DEVICE_TESTING_GUIDE.md" -ForegroundColor Cyan