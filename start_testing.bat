@echo off
chcp 65001 >nul
echo.
echo 🚀 VoiceFlow 真机测试启动器
echo ================================
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

echo ✅ Flutter环境检查通过
echo.

REM 检查Web构建文件
if not exist "build\web\index.html" (
    echo 📦 未找到Web构建文件，正在构建...
    flutter build web
    if errorlevel 1 (
        echo ❌ Web构建失败
        pause
        exit /b 1
    )
    echo ✅ Web构建完成
) else (
    echo ✅ 发现已有Web构建文件
)

echo.
echo 📱 选择测试方式：
echo 1. Web版本测试 (推荐开始)
echo 2. iOS真机测试准备
echo 3. 查看测试指南
echo 4. 退出
echo.

set /p choice="请选择 (1-4): "

if "%choice%"=="1" goto web_test
if "%choice%"=="2" goto ios_test
if "%choice%"=="3" goto view_guide
if "%choice%"=="4" goto end

echo 无效选择，请重新运行脚本
pause
exit /b 1

:web_test
echo.
echo 🌐 启动Web版本测试...
echo ================================

REM 获取本机IP地址
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set ip=%%a
    goto :found_ip
)
:found_ip
set ip=%ip: =%

echo 📋 测试信息：
echo 本机IP地址: %ip%
echo 测试端口: 8080
echo.
echo 📱 手机测试步骤：
echo 1. 确保手机和电脑连接同一WiFi
echo 2. 在手机浏览器访问: http://%ip%:8080
echo 3. 测试功能页面: http://%ip%:8080/test_notifications.html
echo.
echo 🔧 功能测试清单：
echo □ 页面加载正常
echo □ 通知权限请求
echo □ 推送测试按钮
echo □ 语音测试按钮
echo □ 添加语音提醒
echo □ 批量导入功能
echo.

echo 按任意键启动本地服务器...
pause >nul

cd build\web
echo 🌐 服务器启动中...
echo 访问地址: http://localhost:8080
echo 手机访问: http://%ip%:8080
echo.
echo 按 Ctrl+C 停止服务器
echo ================================
python -m http.server 8080
goto end

:ios_test
echo.
echo 📱 iOS真机测试准备...
echo ================================
echo.
echo 📋 准备清单：
echo □ Mac电脑 (Xcode方法) 或 Windows/Mac (Sideloadly方法)
echo □ iPhone/iPad设备
echo □ USB数据线
echo □ Apple ID账号
echo.
echo 🔧 构建选项：
echo 1. 构建iOS调试版本 (需要Xcode)
echo 2. 构建IPA文件 (用于Sideloadly)
echo 3. 返回主菜单
echo.

set /p ios_choice="请选择 (1-3): "

if "%ios_choice%"=="1" goto build_ios_debug
if "%ios_choice%"=="2" goto build_ipa
if "%ios_choice%"=="3" goto start
echo 无效选择
pause
goto ios_test

:build_ios_debug
echo.
echo 🔨 构建iOS调试版本...
flutter clean
flutter pub get
flutter build ios --debug --no-codesign

if errorlevel 1 (
    echo ❌ iOS构建失败，请检查错误信息
    pause
    goto ios_test
)

echo ✅ iOS构建完成
echo.
echo 📂 下一步：
echo 1. 在Mac上运行: open ios/Runner.xcworkspace
echo 2. 在Xcode中配置签名和Bundle ID
echo 3. 连接iPhone并运行
echo.
echo 📚 详细步骤请查看: IOS_DEVICE_TESTING.md
pause
goto start

:build_ipa
echo.
echo 📦 构建iOS应用 (需要通过Xcode导出IPA)...
flutter clean
flutter pub get
flutter build ios --release

if errorlevel 1 (
    echo ❌ iOS构建失败，请检查错误信息
    pause
    goto ios_test
)

echo ✅ iOS构建完成
echo.
echo 📂 下一步 - 通过Xcode导出IPA：
echo 1. 运行: open ios/Runner.xcworkspace
echo 2. 在Xcode中选择 "Any iOS Device"
echo 3. Product ^> Archive
echo 4. 在Organizer中点击 "Distribute App"
echo 5. 选择 "Development" 导出方式
echo 6. 获得IPA文件后用Sideloadly安装
echo.
echo 📚 详细步骤请查看: IOS_DEVICE_TESTING.md
pause
goto start

:view_guide
echo.
echo 📚 测试指南文档：
echo ================================
echo.
echo 📄 可用文档：
echo 1. REAL_DEVICE_TESTING_GUIDE.md - 完整测试指南
echo 2. IOS_DEVICE_TESTING.md - iOS专用测试指南
echo 3. WEB_NOTIFICATION_VOICE_FIX.md - Web功能修复说明
echo.
echo 💡 建议阅读顺序：
echo 1. 先阅读 REAL_DEVICE_TESTING_GUIDE.md 了解整体流程
echo 2. 根据需要查看具体平台的详细指南
echo.
pause
goto start

:start
cls
goto :eof

:end
echo.
echo 👋 测试完成，感谢使用！
echo 📚 如需帮助，请查看测试指南文档
pause