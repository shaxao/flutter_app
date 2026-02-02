@echo off
chcp 65001 >nul
echo.
echo 🚀 VoiceFlow 快速测试 - Flutter 3.35.5
echo ========================================
echo.

REM 检查Flutter环境
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 未找到Flutter环境
    pause
    exit /b 1
)

echo ✅ Flutter环境检查通过
echo.

echo 📱 推荐的测试顺序：
echo 1. Web版本测试 (最快验证功能)
echo 2. iOS模拟器测试 (快速功能验证)
echo 3. iOS真机测试 (完整功能测试)
echo.

set /p choice="选择测试方式 (1-3): "

if "%choice%"=="1" goto web_test
if "%choice%"=="2" goto ios_simulator
if "%choice%"=="3" goto ios_device

echo 无效选择
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
echo 测试页面: http://%ip%:8080/test_notifications.html
echo.
echo 🧪 测试项目：
echo □ 页面正常加载
echo □ 点击"推送测试" - 应该看到通知
echo □ 点击"语音测试" - 应该听到语音
echo □ 访问独立测试页面验证浏览器功能
echo.

cd build\web
echo 🌐 启动服务器...
python -m http.server 8080
goto end

:ios_simulator
echo.
echo 📱 启动iOS模拟器测试...
echo ================================
echo.
echo 🔧 准备模拟器环境...
flutter clean
flutter pub get

echo 📱 启动模拟器并运行应用...
echo 注意：模拟器无法测试真实通知和后台功能
echo.
flutter run -d ios
goto end

:ios_device
echo.
echo 📱 iOS真机测试准备...
echo ================================
echo.
echo 📋 需要的环境：
echo □ Mac电脑
echo □ Xcode 14+
echo □ iPhone/iPad设备
echo □ USB数据线
echo □ Apple ID账号
echo.
echo 🔨 构建iOS应用...
flutter clean
flutter pub get
flutter build ios --release

if errorlevel 1 (
    echo ❌ iOS构建失败
    pause
    goto end
)

echo ✅ iOS构建完成
echo.
echo 📂 下一步操作：
echo 1. 在Mac上运行以下命令打开Xcode：
echo    open ios/Runner.xcworkspace
echo.
echo 2. 在Xcode中：
echo    - 配置签名 (Signing ^& Capabilities)
echo    - 连接iPhone设备
echo    - 点击运行按钮
echo.
echo 3. 或者导出IPA文件：
echo    - Product ^> Archive
echo    - Distribute App ^> Development
echo    - 使用Sideloadly安装到设备
echo.
echo 📚 详细步骤请查看：
echo    - IOS_BUILD_FLUTTER_3_35.md
echo    - IOS_DEVICE_TESTING.md
echo.
pause
goto end

:end
echo.
echo 📚 更多帮助文档：
echo - TESTING_SUMMARY.md - 测试总结
echo - REAL_DEVICE_TESTING_GUIDE.md - 完整指南
echo - IOS_BUILD_FLUTTER_3_35.md - iOS构建指南
echo.
echo 👋 测试完成！