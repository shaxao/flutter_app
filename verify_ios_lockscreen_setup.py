#!/usr/bin/env python3
"""
iOS锁屏语音播放配置验证脚本
检查所有必要的文件和配置是否正确
"""

import os
import json
import xml.etree.ElementTree as ET
from pathlib import Path

def print_status(message, status="INFO"):
    """打印状态信息"""
    colors = {
        "INFO": "\033[94m",
        "SUCCESS": "\033[92m", 
        "WARNING": "\033[93m",
        "ERROR": "\033[91m",
        "RESET": "\033[0m"
    }
    
    color = colors.get(status, colors["INFO"])
    reset = colors["RESET"]
    print(f"{color}[{status}]{reset} {message}")

def check_file_exists(file_path, description):
    """检查文件是否存在"""
    if os.path.exists(file_path):
        print_status(f"✅ {description}: {file_path}", "SUCCESS")
        return True
    else:
        print_status(f"❌ {description}不存在: {file_path}", "ERROR")
        return False

def check_ios_info_plist():
    """检查iOS Info.plist配置"""
    print_status("检查iOS Info.plist配置...", "INFO")
    
    plist_path = "ios/Runner/Info.plist"
    if not check_file_exists(plist_path, "Info.plist文件"):
        return False
    
    try:
        with open(plist_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 简单的字符串检查方法，更可靠
        background_modes_found = '<key>UIBackgroundModes</key>' in content
        audio_background_found = '<string>audio</string>' in content
        
        if background_modes_found and audio_background_found:
            print_status("✅ 后台音频模式已配置", "SUCCESS")
        else:
            print_status("❌ 后台音频模式未配置", "ERROR")
            return False
        
        # 检查权限说明
        permissions = [
            ('NSMicrophoneUsageDescription', '麦克风权限说明'),
            ('NSSpeechRecognitionUsageDescription', '语音识别权限说明'), 
            ('NSUserNotificationsUsageDescription', '通知权限说明')
        ]
        
        for permission, desc in permissions:
            if f'<key>{permission}</key>' in content:
                print_status(f"✅ {desc} 已配置", "SUCCESS")
            else:
                print_status(f"⚠️ {desc} 未配置", "WARNING")
        
        return True
        
    except Exception as e:
        print_status(f"❌ 解析Info.plist失败: {e}", "ERROR")
        return False

def check_ios_entitlements():
    """检查iOS entitlements配置"""
    print_status("检查iOS entitlements配置...", "INFO")
    
    entitlements_path = "ios/Runner/Runner.entitlements"
    if not check_file_exists(entitlements_path, "Runner.entitlements文件"):
        return False
    
    try:
        tree = ET.parse(entitlements_path)
        root = tree.getroot()
        
        dict_elem = root.find('dict')
        if dict_elem is None:
            print_status("❌ entitlements格式错误", "ERROR")
            return False
        
        # 检查后台处理权限
        keys = dict_elem.findall('key')
        background_processing_found = False
        audio_found = False
        
        for i, key in enumerate(keys):
            if key.text == 'com.apple.developer.background-processing':
                background_processing_found = True
            elif key.text == 'com.apple.developer.audio':
                audio_found = True
        
        if background_processing_found:
            print_status("✅ 后台处理权限已配置", "SUCCESS")
        else:
            print_status("⚠️ 后台处理权限未配置", "WARNING")
        
        if audio_found:
            print_status("✅ 音频权限已配置", "SUCCESS")
        else:
            print_status("⚠️ 音频权限未配置", "WARNING")
        
        return True
        
    except Exception as e:
        print_status(f"❌ 解析entitlements失败: {e}", "ERROR")
        return False

def check_ios_native_files():
    """检查iOS原生文件"""
    print_status("检查iOS原生文件...", "INFO")
    
    files_to_check = [
        ("ios/Runner/AudioSessionManager.swift", "音频会话管理器"),
        ("ios/Runner/AppDelegate.swift", "应用代理"),
    ]
    
    all_exist = True
    for file_path, description in files_to_check:
        if not check_file_exists(file_path, description):
            all_exist = False
    
    # 检查AppDelegate.swift是否包含必要的导入
    appdelegate_path = "ios/Runner/AppDelegate.swift"
    if os.path.exists(appdelegate_path):
        try:
            with open(appdelegate_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            required_imports = [
                'import UserNotifications',
                'import AVFoundation',
                'AudioSessionManager'
            ]
            
            for import_stmt in required_imports:
                if import_stmt in content:
                    print_status(f"✅ AppDelegate包含: {import_stmt}", "SUCCESS")
                else:
                    print_status(f"❌ AppDelegate缺少: {import_stmt}", "ERROR")
                    all_exist = False
                    
        except Exception as e:
            print_status(f"❌ 读取AppDelegate.swift失败: {e}", "ERROR")
            all_exist = False
    
    return all_exist

def check_flutter_services():
    """检查Flutter服务文件"""
    print_status("检查Flutter服务文件...", "INFO")
    
    files_to_check = [
        ("lib/core/services/voice_service_mobile.dart", "移动端语音服务"),
        ("lib/core/services/notification_service_mobile.dart", "移动端通知服务"),
        ("lib/core/services/hybrid_notification_service.dart", "混合通知服务"),
    ]
    
    all_exist = True
    for file_path, description in files_to_check:
        if not check_file_exists(file_path, description):
            all_exist = False
    
    # 检查voice_service_mobile.dart是否包含锁屏播放功能
    voice_service_path = "lib/core/services/voice_service_mobile.dart"
    if os.path.exists(voice_service_path):
        try:
            with open(voice_service_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            required_features = [
                'speakInLockscreen',
                'AudioPlayer',
                'MethodChannel',
                'activateAudioSession'
            ]
            
            for feature in required_features:
                if feature in content:
                    print_status(f"✅ 语音服务包含: {feature}", "SUCCESS")
                else:
                    print_status(f"❌ 语音服务缺少: {feature}", "ERROR")
                    all_exist = False
                    
        except Exception as e:
            print_status(f"❌ 读取语音服务文件失败: {e}", "ERROR")
            all_exist = False
    
    return all_exist

def check_pubspec_dependencies():
    """检查pubspec.yaml依赖"""
    print_status("检查pubspec.yaml依赖...", "INFO")
    
    pubspec_path = "pubspec.yaml"
    if not check_file_exists(pubspec_path, "pubspec.yaml文件"):
        return False
    
    try:
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        required_deps = [
            'flutter_tts:',
            'audioplayers:',
            'flutter_local_notifications:',
            'permission_handler:',
        ]
        
        all_deps_found = True
        for dep in required_deps:
            if dep in content:
                print_status(f"✅ 依赖已添加: {dep.rstrip(':')}", "SUCCESS")
            else:
                print_status(f"❌ 依赖缺失: {dep.rstrip(':')}", "ERROR")
                all_deps_found = False
        
        return all_deps_found
        
    except Exception as e:
        print_status(f"❌ 读取pubspec.yaml失败: {e}", "ERROR")
        return False

def generate_test_commands():
    """生成测试命令"""
    print_status("生成测试命令...", "INFO")
    
    commands = [
        "# 清理并获取依赖",
        "flutter clean",
        "flutter pub get",
        "",
        "# 运行iOS锁屏语音测试",
        "flutter run test_ios_lockscreen_voice.dart --target=test_ios_lockscreen_voice.dart",
        "",
        "# 或者运行主应用",
        "flutter run",
        "",
        "# 构建iOS应用",
        "flutter build ios --release",
    ]
    
    with open("ios_test_commands.sh", "w", encoding="utf-8") as f:
        f.write("#!/bin/bash\n")
        f.write("# iOS锁屏语音播放测试命令\n\n")
        for cmd in commands:
            f.write(cmd + "\n")
    
    os.chmod("ios_test_commands.sh", 0o755)
    print_status("✅ 测试命令已生成: ios_test_commands.sh", "SUCCESS")

def main():
    """主函数"""
    print_status("=== iOS锁屏语音播放配置验证 ===", "INFO")
    print()
    
    # 检查当前目录
    if not os.path.exists("ios") or not os.path.exists("lib"):
        print_status("请在Flutter项目根目录运行此脚本", "ERROR")
        return
    
    all_checks_passed = True
    
    # 执行各项检查
    checks = [
        ("iOS Info.plist配置", check_ios_info_plist),
        ("iOS entitlements配置", check_ios_entitlements),
        ("iOS原生文件", check_ios_native_files),
        ("Flutter服务文件", check_flutter_services),
        ("pubspec.yaml依赖", check_pubspec_dependencies),
    ]
    
    for check_name, check_func in checks:
        print()
        if not check_func():
            all_checks_passed = False
    
    print()
    
    # 生成测试命令
    generate_test_commands()
    
    print()
    
    # 总结
    if all_checks_passed:
        print_status("=== ✅ 所有检查通过！ ===", "SUCCESS")
        print_status("你的iOS应用已配置好锁屏语音播放功能", "SUCCESS")
        print_status("运行 ./ios_test_commands.sh 开始测试", "INFO")
    else:
        print_status("=== ❌ 部分检查失败 ===", "ERROR")
        print_status("请根据上述错误信息修复配置", "ERROR")
    
    print()
    print_status("测试步骤:", "INFO")
    print_status("1. 在真实iOS设备上运行应用", "INFO")
    print_status("2. 测试前台语音播放", "INFO")
    print_status("3. 测试后台语音播放（按Home键）", "INFO")
    print_status("4. 测试锁屏语音播放（锁屏后等待）", "INFO")
    print_status("5. 测试通知点击语音播放", "INFO")

if __name__ == "__main__":
    main()