# iOS真机测试详细指南

## 🎯 测试目标
验证VoiceFlow应用在iOS设备上的核心功能：
- 后台语音提醒
- 锁屏通知
- 系统级通知
- 语音合成播放

---

## 📋 测试前准备

### 硬件要求
- iPhone/iPad (iOS 12.0+)
- Lightning/USB-C数据线
- Mac电脑 (Xcode方法) 或 Windows/Mac电脑 (Sideloadly方法)

### 软件要求
- Xcode 14+ (Mac方法)
- Sideloadly (跨平台方法)
- Apple ID账号

---

## 🔧 方法1: 使用Xcode (推荐 - 需要Mac)

### 步骤1: 环境准备
```bash
# 检查Flutter环境
flutter doctor

# 检查iOS工具链
flutter doctor --verbose | grep -A 10 "iOS toolchain"
```

### 步骤2: 构建iOS项目
```bash
cd flutter_app

# 清理之前的构建
flutter clean

# 获取依赖
flutter pub get

# 构建iOS调试版本
flutter build ios --debug --no-codesign
```

### 步骤3: Xcode配置
```bash
# 打开Xcode项目
open ios/Runner.xcworkspace
```

在Xcode中：
1. 选择 `Runner` 项目
2. 在 `Signing & Capabilities` 选项卡中：
   - Team: 选择你的开发团队
   - Bundle Identifier: 修改为唯一标识符 (如: `com.yourname.voiceflow`)
3. 添加必要的Capabilities：
   - Background Modes
   - Push Notifications
   - Audio, AirPlay, and Picture in Picture

### 步骤4: 设备连接和安装
1. 用USB连接iPhone到Mac
2. 在iPhone上信任此电脑
3. 在Xcode中选择你的设备
4. 点击运行按钮 (▶️)

### 步骤5: 设备上信任开发者
1. 设置 > 通用 > VPN与设备管理
2. 找到你的开发者应用
3. 点击信任

---

## 🔧 方法2: 使用Sideloadly (跨平台)

### 步骤1: 构建IPA文件
```bash
cd flutter_app

# 对于Flutter 3.35.5，使用以下方法构建iOS应用
# 方法1: 构建iOS Release版本
flutter build ios --release

# 方法2: 如果需要调试版本
flutter build ios --debug --no-codesign
```

**注意**: Flutter 3.35.5 不支持直接构建IPA文件，需要通过Xcode手动导出。

#### 通过Xcode导出IPA:
1. 构建完成后，打开Xcode项目:
```bash
open ios/Runner.xcworkspace
```

2. 在Xcode中:
   - 选择 "Any iOS Device" 作为目标
   - Product > Archive
   - 在Organizer中选择刚创建的Archive
   - 点击 "Distribute App"
   - 选择 "Development" 或 "Ad Hoc"
   - 按提示完成导出，获得IPA文件

### 步骤2: 安装Sideloadly
1. 访问 https://sideloadly.io/
2. 下载适合你系统的版本
3. 安装并启动Sideloadly

### 步骤3: 使用Sideloadly安装
1. 连接iPhone到电脑
2. 在Sideloadly中：
   - IPA File: 选择构建的IPA文件
   - Apple ID: 输入你的Apple ID
   - Password: 输入密码
   - Device: 选择你的iPhone
3. 点击 "Start" 开始安装

### 步骤4: 信任开发者证书
1. 在iPhone上: 设置 > 通用 > VPN与设备管理
2. 找到你的Apple ID
3. 点击信任

---

## 🧪 功能测试清单

### 基础功能测试
```
测试项目                    状态    备注
应用启动                   [ ]     检查启动时间和界面
页面导航                   [ ]     测试所有页面切换
数据持久化                 [ ]     重启应用后数据保持
网络连接                   [ ]     API调用正常
```

### 通知功能测试
```
测试项目                    状态    备注
通知权限请求               [ ]     首次启动时请求
前台通知显示               [ ]     应用打开时的通知
后台通知显示               [ ]     应用在后台时
锁屏通知显示               [ ]     设备锁屏时
通知点击响应               [ ]     点击通知打开应用
通知声音播放               [ ]     系统通知声音
```

### 语音功能测试
```
测试项目                    状态    备注
前台语音播放               [ ]     应用打开时播放
后台语音播放               [ ]     应用在后台时
锁屏语音播放               [ ]     设备锁屏时播放
中文语音支持               [ ]     中文内容正确发音
语音播放控制               [ ]     暂停、停止功能
音量控制                   [ ]     系统音量控制
```

### 提醒功能测试
```
测试项目                    状态    备注
添加单个提醒               [ ]     手动添加提醒
批量导入提醒               [ ]     从文本批量导入
定时提醒触发               [ ]     按时间自动触发
提醒类型切换               [ ]     系统/AI/自定义音频
提醒编辑删除               [ ]     修改和删除提醒
提醒状态管理               [ ]     启用/禁用状态
```

### 后台运行测试
```
测试项目                    状态    备注
后台刷新权限               [ ]     系统设置中启用
应用后台运行               [ ]     切换到其他应用
定时任务执行               [ ]     后台定时检查提醒
内存管理                   [ ]     长时间运行稳定性
电池消耗                   [ ]     后台运行耗电情况
```

---

## 🔍 调试和问题排查

### 查看应用日志
```bash
# 连接设备后查看实时日志
xcrun devicectl list devices
xcrun devicectl device logs --device [DEVICE_ID] --style compact
```

### 常见问题解决

#### 1. 安装失败
**问题**: "Unable to install app"
**解决**:
- 检查Bundle ID是否唯一
- 确认开发者证书有效
- 清理Xcode缓存: Product > Clean Build Folder

#### 2. 通知不显示
**问题**: 通知权限已授予但不显示
**解决**:
- 检查系统设置 > 通知 > VoiceFlow
- 确认通知样式设置正确
- 重启应用重新请求权限

#### 3. 语音不播放
**问题**: 语音功能无响应
**解决**:
- 检查设备静音开关
- 确认音量设置
- 测试系统语音功能是否正常

#### 4. 后台不运行
**问题**: 应用切换到后台后停止工作
**解决**:
- 设置 > 通用 > 后台App刷新 > VoiceFlow (开启)
- 检查低电量模式是否开启
- 确认Background Modes配置正确

---

## 📊 性能监控

### 内存使用监控
```bash
# 使用Xcode Instruments监控内存
# 1. Product > Profile
# 2. 选择 "Leaks" 或 "Allocations"
# 3. 运行应用并监控内存使用
```

### 电池消耗测试
1. 设置 > 电池 > 电池健康与充电
2. 查看应用电池使用情况
3. 记录后台运行时的耗电量

### 网络请求监控
1. 在Xcode中启用Network Link Conditioner
2. 模拟不同网络条件
3. 测试应用在弱网环境下的表现

---

## 📝 测试报告模板

```
VoiceFlow iOS真机测试报告

测试信息:
- 测试日期: ____
- 测试人员: ____
- 设备型号: ____
- iOS版本: ____
- 应用版本: ____

功能测试结果:
✅ 通过  ❌ 失败  ⚠️ 部分通过

基础功能: ___
通知功能: ___
语音功能: ___
提醒功能: ___
后台运行: ___

性能表现:
- 启动时间: ___秒
- 内存使用: ___MB
- 电池消耗: ___% (测试时长: ___小时)

发现问题:
1. ____
2. ____

建议改进:
1. ____
2. ____

总体评价: ____
```

---

## 🚀 自动化测试脚本

### iOS构建和安装脚本
```bash
#!/bin/bash
# ios_test_build.sh

echo "🚀 开始iOS真机测试构建..."

# 清理环境
flutter clean
flutter pub get

# 构建iOS应用
echo "📱 构建iOS应用..."
flutter build ios --debug --no-codesign

if [ $? -eq 0 ]; then
    echo "✅ iOS构建成功"
    echo "📂 打开Xcode项目..."
    open ios/Runner.xcworkspace
    echo "🔧 请在Xcode中配置签名并运行到设备"
else
    echo "❌ iOS构建失败"
    exit 1
fi
```

### 权限检查脚本
```bash
#!/bin/bash
# check_permissions.sh

echo "🔍 检查iOS权限配置..."

# 检查Info.plist中的权限配置
if grep -q "NSUserNotificationUsageDescription" ios/Runner/Info.plist; then
    echo "✅ 通知权限配置正确"
else
    echo "❌ 缺少通知权限配置"
fi

if grep -q "NSMicrophoneUsageDescription" ios/Runner/Info.plist; then
    echo "✅ 麦克风权限配置正确"
else
    echo "⚠️ 可能需要麦克风权限"
fi

echo "🔧 权限检查完成"
```

---

**最后更新**: 2026-02-02  
**适用版本**: Flutter 3.35.5, iOS 12.0+  
**测试状态**: 待验证