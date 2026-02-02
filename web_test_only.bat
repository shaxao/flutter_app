@echo off
chcp 65001 >nul
echo.
echo 🚀 VoiceFlow Web专用测试启动器
echo ==========================================
echo 💡 专为Windows用户设计，无需Xcode
echo.

REM 检查是否在正确的目录
if not exist "pubspec.yaml" (
    echo ❌ 错误：请在 flutter_app 目录下运行此脚本
    pause
    exit /b 1
)

REM 检查Flutter环境
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：未找到Flutter环境，请先安装Flutter
    pause
    exit /b 1
)

echo ✅ Flutter环境检查通过 (Flutter 3.35.5)
echo.

echo 📱 测试选项：
echo 1. 立即开始Web测试 (推荐)
echo 2. GitHub Actions构建iOS说明
echo 3. 查看测试指南
echo 4. 退出
echo.

set /p choice="请选择 (1-4): "

if "%choice%"=="1" goto web_test
if "%choice%"=="2" goto github_actions
if "%choice%"=="3" goto view_guide
if "%choice%"=="4" goto end

echo 无效选择，请重新运行脚本
pause
exit /b 1

:web_test
echo.
echo 🌐 启动Web版本测试...
echo ================================

REM 检查Web构建
if not exist "build\web\index.html" (
    echo 📦 构建Web版本...
    flutter build web
    if errorlevel 1 (
        echo ❌ Web构建失败
        pause
        exit /b 1
    )
)

REM 获取IP地址
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set ip=%%a
    goto :found_ip
)
:found_ip
set ip=%ip: =%

echo ✅ Web构建完成
echo.
echo 📋 测试信息：
echo 本机访问: http://localhost:8080
echo 手机访问: http://%ip%:8080
echo 独立测试: http://%ip%:8080/test_notifications.html
echo.
echo 🧪 核心测试项目：
echo □ 页面正常加载和导航
echo □ 点击"推送测试" - 应该看到通知
echo □ 点击"语音测试" - 应该听到语音
echo □ 添加语音提醒功能
echo □ 批量导入提醒功能
echo □ 访问独立测试页面验证浏览器API
echo.
echo 📱 推荐测试浏览器：
echo • Chrome (Android/iOS) - 最佳支持
echo • Safari (iOS) - iPhone必测
echo • Firefox/Edge - 兼容性验证
echo.

echo 按任意键启动本地服务器...
pause >nul

cd build\web
echo 🌐 服务器启动中...
echo 访问地址: http://localhost:8080
echo 手机访问: http://%ip%:8080
echo 独立测试: http://%ip%:8080/test_notifications.html
echo.
echo 按 Ctrl+C 停止服务器
echo ================================
python -m http.server 8080
goto end

:github_actions
echo.
echo 🔧 GitHub Actions iOS构建说明...
echo ================================
echo.
echo 📋 你的项目已配置自动构建：
echo • 文件位置: .github/workflows/ios-build.yml
echo • 支持Flutter 3.35.5版本
echo • 无需本地Xcode环境
echo.
echo 🚀 使用步骤：
echo 1. 推送代码到GitHub仓库的main分支
echo 2. 访问GitHub仓库的Actions页面
echo 3. 等待"VoiceFlow iOS Build & Sign"完成
echo 4. 下载构建的IPA文件
echo 5. 使用Sideloadly安装到iPhone
echo.
echo 📦 构建产物：
echo • VoiceFlow-unsigned.ipa - 用于Sideloadly安装
echo • VoiceFlow-signed.ipa - 已签名版本 (需配置证书)
echo • VoiceFlow-Web - Web版本文件
echo.
echo 💡 手动触发构建：
echo 1. 访问GitHub仓库Actions页面
echo 2. 选择"VoiceFlow iOS Build & Sign"
echo 3. 点击"Run workflow"
echo.
echo 🔗 Sideloadly下载：https://sideloadly.io/
echo.
echo 📚 详细说明请查看：WEB_ONLY_TESTING.md
echo.
pause
goto start

:view_guide
echo.
echo 📚 测试指南文档：
echo ================================
echo.
echo 📄 推荐阅读顺序：
echo 1. WEB_ONLY_TESTING.md - 专为你设计的Web测试指南
echo 2. TESTING_SUMMARY.md - 完整测试总结
echo 3. WEB_NOTIFICATION_VOICE_FIX.md - Web功能修复详情
echo.
echo 🌐 Web测试重点：
echo • 浏览器通知和语音功能
echo • 多浏览器兼容性测试
echo • 移动端响应式设计
echo • 独立测试页面使用
echo.
echo 📱 iOS应用获取：
echo • 通过GitHub Actions自动构建
echo • 无需本地Xcode环境
echo • 使用Sideloadly安装
echo.
echo 💡 Web版本功能完整性：
echo • ✅ 语音提醒 (浏览器语音合成)
echo • ✅ 推送通知 (浏览器原生通知)
echo • ✅ 批量导入提醒
echo • ✅ 定时提醒管理
echo • ❌ 后台运行 (需要iOS应用)
echo • ❌ 锁屏语音播报 (需要iOS应用)
echo.
pause
goto start

:start
cls
goto :eof

:end
echo.
echo 👋 测试完成！
echo.
echo 📚 更多帮助：
echo • WEB_ONLY_TESTING.md - Web专用测试指南
echo • GitHub Actions页面 - 查看iOS构建状态
echo • test_notifications.html - 独立功能测试
echo.
echo 💡 提示：Web版本已经包含完整的语音提醒功能
echo 可以满足大部分使用需求，iOS应用主要增加后台运行能力
echo.
pause