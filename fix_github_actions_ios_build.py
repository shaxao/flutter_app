#!/usr/bin/env python3
"""
GitHub Actions iOS构建修复脚本
解决iOS构建中的Swift编译和部署目标问题
"""

import os
import subprocess
import sys

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

def clean_ios_build():
    """清理iOS构建缓存"""
    print("🧹 清理iOS构建缓存...")
    
    # 删除iOS构建目录
    ios_build_dirs = [
        "ios/build",
        "ios/Pods",
        "ios/.symlinks",
        "ios/Flutter/ephemeral",
        "build/ios"
    ]
    
    for build_dir in ios_build_dirs:
        if os.path.exists(build_dir):
            if os.name == 'nt':  # Windows
                run_command(f'rmdir /s /q "{build_dir}"', check=False)
            else:  # Unix/Linux/macOS
                run_command(f'rm -rf "{build_dir}"', check=False)
    
    # 删除Podfile.lock
    podfile_lock = "ios/Podfile.lock"
    if os.path.exists(podfile_lock):
        os.remove(podfile_lock)
    
    print("✅ iOS构建缓存清理完成")

def flutter_clean_and_get():
    """Flutter清理和获取依赖"""
    print("📦 Flutter清理和获取依赖...")
    
    run_command("flutter clean")
    run_command("flutter pub get")
    
    print("✅ Flutter依赖更新完成")

def install_ios_pods():
    """安装iOS CocoaPods依赖"""
    print("📱 安装iOS CocoaPods依赖...")
    
    if not os.path.exists("ios/Podfile"):
        print("❌ Podfile不存在，请先创建Podfile")
        return False
    
    # 更新CocoaPods仓库
    run_command("pod repo update", cwd="ios", check=False)
    
    # 安装依赖
    result = run_command("pod install --verbose", cwd="ios", check=False)
    if result.returncode != 0:
        print("⚠️ pod install失败，尝试清理后重新安装...")
        run_command("pod deintegrate", cwd="ios", check=False)
        run_command("pod install --repo-update", cwd="ios", check=False)
    
    print("✅ iOS CocoaPods依赖安装完成")
    return True

def verify_ios_configuration():
    """验证iOS配置"""
    print("🔍 验证iOS配置...")
    
    # 检查关键文件
    required_files = [
        "ios/Podfile",
        "ios/Runner/Info.plist",
        "ios/Runner/AppDelegate.swift",
        "ios/Flutter/Debug.xcconfig",
        "ios/Flutter/Release.xcconfig"
    ]
    
    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        print(f"❌ 缺少必要文件: {missing_files}")
        return False
    
    # 检查Podfile中的部署目标
    with open("ios/Podfile", "r") as f:
        podfile_content = f.read()
        if "platform :ios, '13.0'" not in podfile_content:
            print("⚠️ Podfile中的iOS部署目标可能不正确")
    
    # 检查Info.plist中的后台模式
    try:
        with open("ios/Runner/Info.plist", "r", encoding='utf-8') as f:
            info_plist_content = f.read()
            if "UIBackgroundModes" not in info_plist_content:
                print("⚠️ Info.plist中缺少后台模式配置")
    except UnicodeDecodeError:
        try:
            with open("ios/Runner/Info.plist", "r", encoding='utf-8', errors='ignore') as f:
                info_plist_content = f.read()
                if "UIBackgroundModes" not in info_plist_content:
                    print("⚠️ Info.plist中缺少后台模式配置")
        except:
            print("⚠️ 无法读取Info.plist文件")
    
    print("✅ iOS配置验证完成")
    return True

def test_ios_build():
    """测试iOS构建"""
    print("🔨 测试iOS构建...")
    
    # 尝试构建iOS应用
    result = run_command("flutter build ios --no-codesign --debug", check=False)
    if result.returncode == 0:
        print("✅ iOS构建测试成功")
        return True
    else:
        print("❌ iOS构建测试失败")
        return False

def create_github_actions_fix():
    """创建GitHub Actions修复配置"""
    print("📝 创建GitHub Actions修复配置...")
    
    github_workflow_fix = """
# GitHub Actions iOS构建修复步骤
# 在现有的iOS构建workflow中添加以下步骤

- name: Clean iOS build cache
  run: |
    rm -rf ios/build
    rm -rf ios/Pods
    rm -rf ios/.symlinks
    rm -f ios/Podfile.lock
    flutter clean

- name: Get Flutter dependencies
  run: flutter pub get

- name: Update CocoaPods repo
  run: |
    cd ios
    pod repo update
    pod install --repo-update

- name: Set iOS deployment target
  run: |
    # 确保所有配置文件都设置了正确的部署目标
    echo "IPHONEOS_DEPLOYMENT_TARGET = 13.0" >> ios/Flutter/Debug.xcconfig
    echo "IPHONEOS_DEPLOYMENT_TARGET = 13.0" >> ios/Flutter/Release.xcconfig

- name: Build iOS app
  run: flutter build ios --no-codesign --release
"""
    
    with open("github_actions_ios_fix.yml", "w") as f:
        f.write(github_workflow_fix)
    
    print("✅ GitHub Actions修复配置已创建: github_actions_ios_fix.yml")

def main():
    """主函数"""
    print("🚀 GitHub Actions iOS构建修复脚本")
    print("=" * 50)
    
    # 1. 清理构建缓存
    clean_ios_build()
    
    # 2. Flutter清理和获取依赖
    flutter_clean_and_get()
    
    # 3. 验证iOS配置
    if not verify_ios_configuration():
        print("❌ iOS配置验证失败")
        sys.exit(1)
    
    # 4. 安装iOS依赖
    if not install_ios_pods():
        print("❌ iOS依赖安装失败")
        sys.exit(1)
    
    # 5. 测试iOS构建
    if not test_ios_build():
        print("❌ iOS构建测试失败")
        print("\n🔧 可能的解决方案:")
        print("1. 检查Xcode版本是否兼容")
        print("2. 确认所有依赖的iOS部署目标设置正确")
        print("3. 检查Swift代码语法是否正确")
        print("4. 查看详细的构建日志")
    
    # 6. 创建GitHub Actions修复配置
    create_github_actions_fix()
    
    print("\n" + "=" * 50)
    print("✅ iOS构建修复脚本执行完成")
    print("\n📋 GitHub Actions修复建议:")
    print("1. 使用提供的github_actions_ios_fix.yml配置")
    print("2. 确保GitHub Actions使用Xcode 15+")
    print("3. 设置正确的iOS部署目标为13.0")
    print("4. 清理构建缓存后重新构建")

if __name__ == "__main__":
    main()