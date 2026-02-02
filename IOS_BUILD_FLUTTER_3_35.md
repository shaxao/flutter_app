# iOS构建指南 - Flutter 3.35.5

## 🎯 适用版本
- Flutter 3.35.5
- Dart 3.9.2
- 不支持 `flutter build ipa` 命令

---

## 🔧 方法1: 直接使用Xcode (推荐)

### 步骤1: 构建iOS项目
```bash
cd flutter_app

# 清理之前的构建
flutter clean
flutter pub get

# 构建iOS Release版本
flutter build ios --release
```

### 步骤2: 在Xcode中运行
```bash
# 打开Xcode项目
open ios/Runner.xcworkspace
```

### 步骤3: 配置和运行
1. 在Xcode中选择你的iPhone设备
2. 配置签名 (Signing & Capabilities)
3. 点击运行按钮直接安装到设备

**优点**: 最简单直接，适合开发测试
**缺点**: 需要Mac电脑和Xcode

---

## 🔧 方法2: 通过Xcode导出IPA (用于Sideloadly)

### 步骤1: 构建并Archive
```bash
cd flutter_app
flutter clean
flutter pub get
flutter build ios --release
open ios/Runner.xcworkspace
```

### 步骤2: 在Xcode中Archive
1. 选择目标设备为 "Any iOS Device (arm64)"
2. 菜单: Product > Archive
3. 等待Archive完成

### 步骤3: 导出IPA
1. Archive完成后会自动打开Organizer
2. 选择刚创建的Archive
3. 点击 "Distribute App"
4. 选择导出方式:
   - **Development**: 用于开发测试
   - **Ad Hoc**: 用于内部分发
5. 选择签名方式:
   - **Automatically manage signing**: 自动管理
   - **Manually manage signing**: 手动选择证书
6. 点击 "Export" 选择保存位置

### 步骤4: 使用Sideloadly安装
1. 下载Sideloadly: https://sideloadly.io/
2. 连接iPhone到电脑
3. 在Sideloadly中选择导出的IPA文件
4. 输入Apple ID和密码
5. 点击安装

---

## 🔧 方法3: 使用iOS Simulator (快速测试)

### 适用场景
- 快速功能测试
- 不需要真机特性 (通知、后台运行等)
- 开发阶段验证

### 步骤
```bash
cd flutter_app

# 启动iOS模拟器
open -a Simulator

# 运行应用到模拟器
flutter run -d ios
```

**注意**: 模拟器无法测试以下功能:
- 真实的推送通知
- 后台运行
- 锁屏语音播放
- 真机性能表现

---

## 🛠️ 常见问题解决

### 问题1: 构建失败 - CocoaPods错误
```bash
# 解决方案
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
flutter build ios --release
```

### 问题2: 签名错误
**错误信息**: "Signing for ... requires a development team"

**解决方案**:
1. 在Xcode中打开项目
2. 选择Runner项目
3. 在Signing & Capabilities中选择你的Team
4. 修改Bundle Identifier为唯一值

### 问题3: Archive失败
**错误信息**: "Archive failed"

**解决方案**:
1. 确保选择了 "Any iOS Device" 而不是模拟器
2. 检查所有依赖库的签名配置
3. 清理项目: Product > Clean Build Folder

### 问题4: 设备不信任开发者
**现象**: 应用安装后无法打开

**解决方案**:
1. 设置 > 通用 > VPN与设备管理
2. 找到你的开发者应用
3. 点击信任

---

## 📱 推荐的测试流程

### 阶段1: 模拟器快速验证
```bash
# 启动模拟器测试
flutter run -d ios
```
验证基础功能是否正常

### 阶段2: 真机开发测试
```bash
# 构建并通过Xcode直接运行
flutter build ios --release
open ios/Runner.xcworkspace
```
在Xcode中直接运行到真机

### 阶段3: 独立安装测试
通过Archive导出IPA，使用Sideloadly安装
测试应用独立运行的稳定性

---

## 🔍 调试技巧

### Xcode调试
1. 在Xcode中设置断点
2. 查看控制台输出
3. 使用Instruments监控性能

### Flutter调试
```bash
# 连接真机后查看日志
flutter logs

# 热重载 (开发模式)
flutter run -d ios --debug
```

### 设备日志
```bash
# 查看设备系统日志
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'
```

---

## 📋 构建检查清单

### 构建前检查
- [ ] Flutter环境正常: `flutter doctor`
- [ ] iOS工具链完整
- [ ] Xcode版本兼容
- [ ] 设备已连接并信任

### 构建过程检查
- [ ] `flutter clean` 清理完成
- [ ] `flutter pub get` 依赖获取成功
- [ ] `flutter build ios --release` 构建成功
- [ ] Xcode项目可以正常打开

### 安装后检查
- [ ] 应用图标显示正常
- [ ] 应用可以正常启动
- [ ] 基础功能工作正常
- [ ] 权限请求正常弹出

---

## 🚀 自动化脚本

### 一键构建脚本
```bash
#!/bin/bash
# ios_build.sh

echo "🚀 开始iOS构建..."

# 清理环境
flutter clean
flutter pub get

# 构建iOS
flutter build ios --release

if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    echo "📂 打开Xcode项目..."
    open ios/Runner.xcworkspace
    echo "🔧 请在Xcode中配置签名并运行"
else
    echo "❌ 构建失败"
    exit 1
fi
```

### Windows批处理版本
```cmd
@echo off
echo 🚀 开始iOS构建...

flutter clean
flutter pub get
flutter build ios --release

if %errorlevel% equ 0 (
    echo ✅ 构建成功
    echo 📂 请手动打开Xcode项目: ios/Runner.xcworkspace
) else (
    echo ❌ 构建失败
    pause
)
```

---

**最后更新**: 2026-02-02  
**适用Flutter版本**: 3.35.5  
**测试状态**: 适用于当前环境