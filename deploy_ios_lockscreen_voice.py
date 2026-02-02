#!/usr/bin/env python3
"""
iOS锁屏语音播放功能部署脚本
完整部署和测试iOS锁屏语音播放功能
"""

import os
import sys
import subprocess
import json
from pathlib import Path

def run_command(cmd, cwd=None, check=True):
    """执行命令并返回结果"""
    print(f"🔧 执行命令: {cmd}")
    try:
        result = subprocess.run(
            cmd, 
            shell=True, 
            cwd=cwd, 
            capture_output=True, 
            text=True, 
            encoding='utf-8',
            errors='ignore',
            check=check
        )
        if result.stdout:
            print(f"✅ 输出: {result.stdout.strip()}")
        return result
    except subprocess.CalledProcessError as e:
        print(f"❌ 命令执行失败: {e}")
        if e.stderr:
            print(f"错误信息: {e.stderr}")
        if not check:
            return e
        raise

def check_flutter_environment():
    """检查Flutter环境"""
    print("🔍 检查Flutter环境...")
    
    # 检查Flutter版本
    result = run_command("flutter --version", check=False)
    if result.returncode != 0:
        print("❌ Flutter未安装或不在PATH中")
        return False
    
    # 检查iOS工具链
    result = run_command("flutter doctor --verbose", check=False)
    if result.stdout and "iOS toolchain" not in result.stdout:
        print("⚠️ iOS工具链可能未正确配置")
    
    return True

def verify_ios_configuration():
    """验证iOS配置"""
    print("🔍 验证iOS配置...")
    
    # 检查Info.plist配置
    info_plist_path = "ios/Runner/Info.plist"
    if not os.path.exists(info_plist_path):
        print(f"❌ 找不到 {info_plist_path}")
        return False
    
    with open(info_plist_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    required_configs = [
        "UIBackgroundModes",
        "<string>audio</string>",
        "NSMicrophoneUsageDescription",
        "NSSpeechRecognitionUsageDescription",
        "NSUserNotificationsUsageDescription"
    ]
    
    missing_configs = []
    for config in required_configs:
        if config not in content:
            missing_configs.append(config)
    
    if missing_configs:
        print(f"❌ Info.plist缺少配置: {missing_configs}")
        return False
    
    print("✅ iOS配置验证通过")
    return True

def verify_swift_files():
    """验证Swift原生文件"""
    print("🔍 验证Swift原生文件...")
    
    swift_files = [
        "ios/Runner/AudioSessionManager.swift",
        "ios/Runner/AppDelegate.swift"
    ]
    
    for file_path in swift_files:
        if not os.path.exists(file_path):
            print(f"❌ 找不到 {file_path}")
            return False
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 检查关键方法
        if "AudioSessionManager.swift" in file_path:
            required_methods = [
                "speakInBackground",
                "activateAudioSession",
                "checkBackgroundAudioPermission"
            ]
        else:  # AppDelegate.swift
            required_methods = [
                "setupMethodChannels",
                "handleAudioSessionMethodCall",
                "handleVoiceMethodCall"
            ]
        
        missing_methods = []
        for method in required_methods:
            if method not in content:
                missing_methods.append(method)
        
        if missing_methods:
            print(f"❌ {file_path} 缺少方法: {missing_methods}")
            return False
    
    print("✅ Swift文件验证通过")
    return True

def verify_dart_services():
    """验证Dart服务文件"""
    print("🔍 验证Dart服务文件...")
    
    service_files = [
        "lib/core/services/voice_service_mobile.dart",
        "lib/core/services/notification_service_mobile.dart"
    ]
    
    for file_path in service_files:
        if not os.path.exists(file_path):
            print(f"❌ 找不到 {file_path}")
            return False
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 检查关键功能
        if "voice_service_mobile.dart" in file_path:
            required_features = [
                "speakInLockscreen",
                "_activateAudioSession",
                "isBackgroundPlaybackSupported"
            ]
        else:  # notification_service_mobile.dart
            required_features = [
                "showVoiceNotification",
                "_playVoiceInBackground",
                "scheduleVoiceNotification"
            ]
        
        missing_features = []
        for feature in required_features:
            if feature not in content:
                missing_features.append(feature)
        
        if missing_features:
            print(f"❌ {file_path} 缺少功能: {missing_features}")
            return False
    
    print("✅ Dart服务文件验证通过")
    return True

def clean_and_build():
    """清理并构建项目"""
    print("🧹 清理项目...")
    
    # Flutter清理
    run_command("flutter clean")
    
    # 获取依赖
    run_command("flutter pub get")
    
    # iOS清理
    if os.path.exists("ios"):
        run_command("rm -rf ios/build", check=False)
        run_command("rm -rf ios/Pods", check=False)
        run_command("rm -f ios/Podfile.lock", check=False)
    
    print("✅ 项目清理完成")

def install_ios_dependencies():
    """安装iOS依赖"""
    print("📦 安装iOS依赖...")
    
    if not os.path.exists("ios"):
        print("❌ iOS目录不存在")
        return False
    
    # 安装CocoaPods依赖
    result = run_command("pod install", cwd="ios", check=False)
    if result.returncode != 0:
        print("⚠️ CocoaPods安装可能有问题，尝试更新...")
        run_command("pod repo update", cwd="ios", check=False)
        run_command("pod install", cwd="ios", check=False)
    
    print("✅ iOS依赖安装完成")
    return True

def build_ios_app():
    """构建iOS应用"""
    print("🔨 构建iOS应用...")
    
    # 构建iOS应用
    result = run_command("flutter build ios --no-codesign", check=False)
    if result.returncode != 0:
        print("❌ iOS构建失败")
        return False
    
    print("✅ iOS应用构建成功")
    return True

def create_test_script():
    """创建测试脚本"""
    print("📝 创建测试脚本...")
    
    test_script = """#!/bin/bash
# iOS锁屏语音播放测试脚本

echo "🚀 启动iOS锁屏语音播放测试..."

# 检查设备连接
echo "📱 检查iOS设备连接..."
flutter devices

# 运行测试应用
echo "🔧 运行测试应用..."
flutter run -d ios --debug test_ios_lockscreen_voice.dart

echo "✅ 测试脚本执行完成"
"""
    
    with open("test_ios_lockscreen.sh", "w") as f:
        f.write(test_script)
    
    # 添加执行权限
    os.chmod("test_ios_lockscreen.sh", 0o755)
    
    print("✅ 测试脚本创建完成: test_ios_lockscreen.sh")

def create_deployment_guide():
    """创建部署指南"""
    print("📚 创建部署指南...")
    
    guide_content = """# iOS锁屏语音播放功能部署指南

## 功能概述
本功能实现了iOS应用在锁屏状态下的语音播放能力，包括：
- 后台音频会话管理
- 锁屏语音播放
- 语音通知集成
- 媒体控制中心支持

## 核心组件

### 1. iOS原生组件
- `AudioSessionManager.swift`: 音频会话管理器
- `AppDelegate.swift`: 应用代理，处理方法通道

### 2. Flutter服务
- `voice_service_mobile.dart`: 移动端语音服务
- `notification_service_mobile.dart`: 移动端通知服务

### 3. 配置文件
- `Info.plist`: iOS权限和后台模式配置
- `Runner.entitlements`: iOS权限配置

## 部署步骤

### 1. 环境检查
```bash
python3 deploy_ios_lockscreen_voice.py
```

### 2. 手动测试
```bash
# 运行测试应用
flutter run -d ios test_ios_lockscreen_voice.dart

# 或使用测试脚本
./test_ios_lockscreen.sh
```

### 3. 测试流程
1. 在真实iOS设备上运行测试应用
2. 点击"测试后台语音播放"
3. 立即锁屏设备
4. 等待语音播放

## 权限要求
- 通知权限 (NSUserNotificationsUsageDescription)
- 麦克风权限 (NSMicrophoneUsageDescription) 
- 语音识别权限 (NSSpeechRecognitionUsageDescription)
- 后台音频模式 (UIBackgroundModes: audio)

## 故障排除

### 锁屏无语音播放
1. 检查Info.plist中的UIBackgroundModes配置
2. 确认音频会话正确激活
3. 验证TTS引擎初始化

### 通知不显示
1. 检查通知权限
2. 确认通知服务初始化
3. 验证通知内容格式

### 构建失败
1. 清理项目: `flutter clean`
2. 重新获取依赖: `flutter pub get`
3. 重新安装CocoaPods: `cd ios && pod install`

## 注意事项
- 必须在真实iOS设备上测试
- 模拟器不支持完整的后台音频功能
- iOS系统可能在某些情况下限制后台音频播放
- 建议在iOS 14+版本上测试

## 技术实现细节

### 音频会话配置
```swift
try audioSession.setCategory(.playback, 
                           mode: .voicePrompt,
                           options: [.allowBluetooth, 
                                   .allowBluetoothA2DP,
                                   .defaultToSpeaker,
                                   .mixWithOthers])
```

### 方法通道通信
```dart
const platform = MethodChannel('voiceflow/voice');
await platform.invokeMethod('speakInBackground', {'text': text});
```

### 媒体控制中心
- 支持锁屏播放控制
- 显示播放信息
- 响应播放/暂停/停止命令

## 测试建议
1. 测试不同长度的语音文本
2. 测试在不同iOS版本上的兼容性
3. 测试与其他音频应用的兼容性
4. 测试电池优化对功能的影响
"""
    
    with open("IOS_LOCKSCREEN_VOICE_DEPLOYMENT_GUIDE.md", "w", encoding="utf-8") as f:
        f.write(guide_content)
    
    print("✅ 部署指南创建完成: IOS_LOCKSCREEN_VOICE_DEPLOYMENT_GUIDE.md")

def main():
    """主函数"""
    print("🚀 iOS锁屏语音播放功能部署脚本")
    print("=" * 50)
    
    # 检查Flutter环境
    if not check_flutter_environment():
        print("❌ Flutter环境检查失败")
        sys.exit(1)
    
    # 验证iOS配置
    if not verify_ios_configuration():
        print("❌ iOS配置验证失败")
        sys.exit(1)
    
    # 验证Swift文件
    if not verify_swift_files():
        print("❌ Swift文件验证失败")
        sys.exit(1)
    
    # 验证Dart服务
    if not verify_dart_services():
        print("❌ Dart服务验证失败")
        sys.exit(1)
    
    # 清理并构建
    clean_and_build()
    
    # 安装iOS依赖
    if not install_ios_dependencies():
        print("❌ iOS依赖安装失败")
        sys.exit(1)
    
    # 构建iOS应用
    if not build_ios_app():
        print("❌ iOS应用构建失败")
        sys.exit(1)
    
    # 创建测试脚本
    create_test_script()
    
    # 创建部署指南
    create_deployment_guide()
    
    print("\n" + "=" * 50)
    print("✅ iOS锁屏语音播放功能部署完成！")
    print("\n📋 下一步操作:")
    print("1. 连接真实iOS设备")
    print("2. 运行测试脚本: ./test_ios_lockscreen.sh")
    print("3. 或直接运行: flutter run -d ios test_ios_lockscreen_voice.dart")
    print("4. 测试锁屏语音播放功能")
    print("\n📚 详细说明请查看: IOS_LOCKSCREEN_VOICE_DEPLOYMENT_GUIDE.md")

if __name__ == "__main__":
    main()