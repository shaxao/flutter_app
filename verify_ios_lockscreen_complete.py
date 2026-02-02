#!/usr/bin/env python3
"""
iOS锁屏语音播放功能完整性验证脚本
验证所有必要的文件和配置是否正确
"""

import os
import sys

def check_file_exists(file_path, description):
    """检查文件是否存在"""
    if os.path.exists(file_path):
        print(f"✅ {description}: {file_path}")
        return True
    else:
        print(f"❌ {description}缺失: {file_path}")
        return False

def check_file_content(file_path, required_content, description):
    """检查文件内容是否包含必要的配置"""
    if not os.path.exists(file_path):
        print(f"❌ 文件不存在: {file_path}")
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except:
        try:
            with open(file_path, 'r', encoding='gbk') as f:
                content = f.read()
        except:
            print(f"❌ 无法读取文件: {file_path}")
            return False
    
    missing_items = []
    for item in required_content:
        if item not in content:
            missing_items.append(item)
    
    if missing_items:
        print(f"❌ {description}缺少内容: {missing_items}")
        return False
    else:
        print(f"✅ {description}配置完整")
        return True

def main():
    """主验证函数"""
    print("🔍 iOS锁屏语音播放功能完整性验证")
    print("=" * 50)
    
    all_checks_passed = True
    
    # 1. 检查iOS原生文件
    print("\n📱 检查iOS原生文件...")
    ios_files = [
        ("ios/Runner/AudioSessionManager.swift", "音频会话管理器"),
        ("ios/Runner/AppDelegate.swift", "应用代理"),
        ("ios/Runner/Info.plist", "iOS配置文件"),
        ("ios/Runner/Runner.entitlements", "iOS权限文件")
    ]
    
    for file_path, description in ios_files:
        if not check_file_exists(file_path, description):
            all_checks_passed = False
    
    # 2. 检查Flutter服务文件
    print("\n🎯 检查Flutter服务文件...")
    flutter_files = [
        ("lib/core/services/voice_service_mobile.dart", "移动端语音服务"),
        ("lib/core/services/notification_service_mobile.dart", "移动端通知服务"),
        ("lib/core/services/voice_service.dart", "语音服务接口"),
        ("lib/core/services/notification_service.dart", "通知服务接口")
    ]
    
    for file_path, description in flutter_files:
        if not check_file_exists(file_path, description):
            all_checks_passed = False
    
    # 3. 检查测试文件
    print("\n🧪 检查测试文件...")
    test_files = [
        ("test_ios_lockscreen_voice.dart", "iOS锁屏语音测试应用")
    ]
    
    for file_path, description in test_files:
        if not check_file_exists(file_path, description):
            all_checks_passed = False
    
    # 4. 检查关键配置内容
    print("\n⚙️ 检查关键配置内容...")
    
    # Info.plist配置检查
    info_plist_required = [
        "UIBackgroundModes",
        "<string>audio</string>",
        "NSMicrophoneUsageDescription",
        "NSSpeechRecognitionUsageDescription",
        "NSUserNotificationsUsageDescription"
    ]
    
    if not check_file_content("ios/Runner/Info.plist", info_plist_required, "Info.plist后台音频配置"):
        all_checks_passed = False
    
    # AudioSessionManager.swift关键方法检查
    audio_manager_required = [
        "speakInBackground",
        "activateAudioSession",
        "checkBackgroundAudioPermission",
        "setupNowPlayingInfo",
        "AVAudioSession.Category.playback"
    ]
    
    if not check_file_content("ios/Runner/AudioSessionManager.swift", audio_manager_required, "AudioSessionManager关键方法"):
        all_checks_passed = False
    
    # AppDelegate.swift方法通道检查
    app_delegate_required = [
        "setupMethodChannels",
        "voiceflow/audio_session",
        "voiceflow/voice",
        "voiceflow/notifications",
        "handleAudioSessionMethodCall",
        "handleVoiceMethodCall"
    ]
    
    if not check_file_content("ios/Runner/AppDelegate.swift", app_delegate_required, "AppDelegate方法通道"):
        all_checks_passed = False
    
    # voice_service_mobile.dart锁屏功能检查
    voice_service_required = [
        "speakInLockscreen",
        "_activateAudioSession",
        "isBackgroundPlaybackSupported",
        "IosTextToSpeechAudioCategory.playback",
        "MethodChannel('voiceflow/audio_session')"
    ]
    
    if not check_file_content("lib/core/services/voice_service_mobile.dart", voice_service_required, "移动端语音服务锁屏功能"):
        all_checks_passed = False
    
    # notification_service_mobile.dart语音通知检查
    notification_service_required = [
        "showVoiceNotification",
        "_playVoiceInBackground",
        "scheduleVoiceNotification",
        "MethodChannel('voiceflow/voice')",
        "speakInBackground"
    ]
    
    if not check_file_content("lib/core/services/notification_service_mobile.dart", notification_service_required, "移动端通知服务语音功能"):
        all_checks_passed = False
    
    # 5. 检查项目配置文件
    print("\n📦 检查项目配置文件...")
    config_files = [
        ("pubspec.yaml", "Flutter项目配置"),
        ("analysis_options.yaml", "代码分析配置")
    ]
    
    for file_path, description in config_files:
        if not check_file_exists(file_path, description):
            all_checks_passed = False
    
    # pubspec.yaml依赖检查
    pubspec_required = [
        "flutter_tts:",
        "flutter_local_notifications:",
        "permission_handler:",
        "audioplayers:"
    ]
    
    if not check_file_content("pubspec.yaml", pubspec_required, "pubspec.yaml必要依赖"):
        all_checks_passed = False
    
    # 6. 生成验证报告
    print("\n" + "=" * 50)
    if all_checks_passed:
        print("✅ 所有检查通过！iOS锁屏语音播放功能配置完整")
        print("\n🚀 下一步操作:")
        print("1. 连接真实iOS设备")
        print("2. 运行测试: flutter run -d ios test_ios_lockscreen_voice.dart")
        print("3. 测试锁屏语音播放功能")
        
        # 创建快速测试脚本
        test_script = """#!/bin/bash
echo "Starting iOS lockscreen voice test..."
echo "Please ensure iOS device is connected"
flutter run -d ios test_ios_lockscreen_voice.dart
"""
        with open("quick_test_ios_lockscreen.sh", "w", encoding='utf-8') as f:
            f.write(test_script)
        os.chmod("quick_test_ios_lockscreen.sh", 0o755)
        print("4. 或运行快速测试脚本: ./quick_test_ios_lockscreen.sh")
        
    else:
        print("❌ 检查发现问题，请修复后重新验证")
        print("\n🔧 修复建议:")
        print("1. 确保所有必要文件存在")
        print("2. 检查配置文件内容完整性")
        print("3. 重新运行此验证脚本")
        sys.exit(1)

if __name__ == "__main__":
    main()