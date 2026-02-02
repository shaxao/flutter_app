#!/usr/bin/env python3
"""
锁屏语音播放部署脚本
用于将必要的文件部署到服务器
"""

import os
import shutil
import subprocess
import sys
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

def check_file_exists(file_path):
    """检查文件是否存在"""
    if os.path.exists(file_path):
        print_status(f"✅ 找到文件: {file_path}", "SUCCESS")
        return True
    else:
        print_status(f"❌ 文件不存在: {file_path}", "ERROR")
        return False

def deploy_web_files():
    """部署Web文件"""
    print_status("开始部署Web文件...", "INFO")
    
    # 需要部署的文件列表
    web_files = [
        "web/lockscreen-voice-service.js",
        "web/background-voice-service.js", 
        "web/sw.js",
        "web/reminder-manager.js",
        "web/voice-service.js",
        "web/push-manager.js",
        "web/timer.worker.js",
        "web/test_background_voice.html"
    ]
    
    # 检查所有文件是否存在
    missing_files = []
    for file_path in web_files:
        if not check_file_exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        print_status(f"缺少 {len(missing_files)} 个文件，无法继续部署", "ERROR")
        for file_path in missing_files:
            print_status(f"  - {file_path}", "ERROR")
        return False
    
    print_status("所有Web文件检查通过", "SUCCESS")
    
    # 创建部署目录
    deploy_dir = "deploy_web"
    os.makedirs(deploy_dir, exist_ok=True)
    
    # 复制文件到部署目录
    for file_path in web_files:
        dest_path = os.path.join(deploy_dir, os.path.basename(file_path))
        shutil.copy2(file_path, dest_path)
        print_status(f"复制: {file_path} -> {dest_path}", "SUCCESS")
    
    print_status(f"Web文件已复制到 {deploy_dir} 目录", "SUCCESS")
    print_status("请将该目录中的文件上传到服务器的web根目录", "WARNING")
    
    return True

def check_backend_dependencies():
    """检查后端依赖"""
    print_status("检查后端TTS依赖...", "INFO")
    
    # 检查Python TTS库
    try:
        import pyttsx3
        print_status("✅ pyttsx3 已安装", "SUCCESS")
    except ImportError:
        print_status("❌ pyttsx3 未安装", "WARNING")
        print_status("运行: pip install pyttsx3", "INFO")
    
    # 检查espeak
    try:
        result = subprocess.run(['espeak', '--version'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print_status("✅ espeak 已安装", "SUCCESS")
        else:
            raise subprocess.CalledProcessError(result.returncode, 'espeak')
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        print_status("❌ espeak 未安装", "WARNING")
        print_status("Ubuntu/Debian: sudo apt-get install espeak espeak-data", "INFO")
        print_status("CentOS/RHEL: sudo yum install espeak espeak-devel", "INFO")

def create_test_script():
    """创建测试脚本"""
    print_status("创建测试脚本...", "INFO")
    
    test_script = """#!/usr/bin/env python3
\"\"\"
锁屏语音播放测试脚本
\"\"\"

import requests
import json
import time

def test_tts_api():
    \"\"\"测试TTS API\"\"\"
    print("测试TTS API...")
    
    url = "https://service.muhuo.site/api/v1/tts"
    data = {
        "text": "这是锁屏语音播放测试",
        "voice_model": "tts-1",
        "format": "wav"
    }
    
    try:
        response = requests.post(url, json=data, timeout=30)
        
        if response.status_code == 200:
            print(f"✅ TTS API测试成功，音频大小: {len(response.content)} bytes")
            
            # 保存测试音频
            with open("test_tts_output.wav", "wb") as f:
                f.write(response.content)
            print("✅ 测试音频已保存为 test_tts_output.wav")
            
        else:
            print(f"❌ TTS API测试失败: {response.status_code}")
            print(f"响应: {response.text}")
            
    except Exception as e:
        print(f"❌ TTS API测试异常: {e}")

def test_reminder_creation():
    \"\"\"测试提醒创建\"\"\"
    print("测试提醒创建...")
    
    url = "https://service.muhuo.site/api/v1/voice-reminders"
    
    # 获取当前时间+1分钟
    import datetime
    now = datetime.datetime.now()
    test_time = (now + datetime.timedelta(minutes=1)).strftime("%H:%M")
    
    data = {
        "time": test_time,
        "content": f"锁屏语音测试提醒 - {now.strftime('%H:%M:%S')} 创建",
        "reminder_type": "ai_voice",
        "voice_model": "tts-1"
    }
    
    try:
        response = requests.post(url, json=data, timeout=10)
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ 提醒创建成功，ID: {result.get('id')}")
            print(f"⏰ 提醒时间: {test_time}")
            print("请等待1分钟测试语音播放...")
            
        else:
            print(f"❌ 提醒创建失败: {response.status_code}")
            print(f"响应: {response.text}")
            
    except Exception as e:
        print(f"❌ 提醒创建异常: {e}")

if __name__ == "__main__":
    print("=== 锁屏语音播放测试 ===")
    test_tts_api()
    print()
    test_reminder_creation()
    print()
    print("测试完成！")
    print("如果TTS API正常，请在手机上测试锁屏语音播放功能。")
"""
    
    with open("test_lockscreen_voice.py", "w", encoding="utf-8") as f:
        f.write(test_script)
    
    # 设置执行权限
    os.chmod("test_lockscreen_voice.py", 0o755)
    
    print_status("测试脚本已创建: test_lockscreen_voice.py", "SUCCESS")

def create_installation_guide():
    """创建安装指南"""
    print_status("创建安装指南...", "INFO")
    
    guide = """# 锁屏语音播放安装指南

## 1. 服务器端部署

### 安装TTS依赖

```bash
# 安装Python TTS库
pip install pyttsx3

# 安装espeak (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install espeak espeak-data

# 安装espeak (CentOS/RHEL)
sudo yum install espeak espeak-devel
```

### 部署Web文件

将 `deploy_web/` 目录中的所有文件上传到服务器的web根目录：

```bash
# 示例：使用scp上传
scp deploy_web/* user@server:/path/to/web/root/

# 或使用rsync
rsync -av deploy_web/ user@server:/path/to/web/root/
```

### 重启后端服务

```bash
# 重启Flask应用
sudo systemctl restart your-flask-app

# 或者如果使用PM2
pm2 restart app
```

## 2. 测试部署

### 运行测试脚本

```bash
python3 test_lockscreen_voice.py
```

### 访问测试页面

打开浏览器访问：
`https://service.muhuo.site/test_background_voice.html`

### 手机端测试

1. 在手机上打开应用
2. 设置一个1分钟后的提醒
3. 锁屏等待
4. 检查是否有语音播放或通知

## 3. 故障排除

### TTS API不工作

- 检查espeak是否安装：`espeak --version`
- 检查pyttsx3是否安装：`python3 -c "import pyttsx3"`
- 查看服务器日志中的TTS错误信息

### 锁屏语音不播放

- 确认通知权限已授予
- 检查浏览器是否支持Service Worker
- 尝试点击通知播放语音
- 查看浏览器控制台错误信息

### Service Worker问题

- 清除浏览器缓存
- 重新注册Service Worker
- 检查HTTPS证书是否有效

## 4. 浏览器兼容性

- **iOS Safari**: 锁屏语音受限，主要依靠通知
- **Android Chrome**: 后台语音有时间限制
- **桌面浏览器**: 相对宽松的限制

## 5. 预期效果

部署成功后应该实现：

- ✅ 前台状态正常语音播放
- ✅ 后台状态语音播放（部分浏览器）
- ✅ 锁屏状态通知+振动提醒
- ✅ 解锁后立即播放待播语音
- ✅ 通知点击触发语音播放
"""
    
    with open("INSTALLATION_GUIDE.md", "w", encoding="utf-8") as f:
        f.write(guide)
    
    print_status("安装指南已创建: INSTALLATION_GUIDE.md", "SUCCESS")

def main():
    """主函数"""
    print_status("=== 锁屏语音播放部署工具 ===", "INFO")
    print()
    
    # 检查当前目录
    if not os.path.exists("web") or not os.path.exists("backend"):
        print_status("请在项目根目录运行此脚本", "ERROR")
        sys.exit(1)
    
    # 部署Web文件
    if not deploy_web_files():
        print_status("Web文件部署失败", "ERROR")
        sys.exit(1)
    
    print()
    
    # 检查后端依赖
    check_backend_dependencies()
    
    print()
    
    # 创建测试脚本
    create_test_script()
    
    print()
    
    # 创建安装指南
    create_installation_guide()
    
    print()
    print_status("=== 部署准备完成 ===", "SUCCESS")
    print_status("请按照 INSTALLATION_GUIDE.md 中的说明完成部署", "INFO")
    print_status("然后运行 python3 test_lockscreen_voice.py 进行测试", "INFO")

if __name__ == "__main__":
    main()