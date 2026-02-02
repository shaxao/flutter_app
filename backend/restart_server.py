#!/usr/bin/env python3
"""
重启服务器脚本
"""
import os
import signal
import subprocess
import time

def kill_existing_server():
    """杀死现有的Flask服务器进程"""
    try:
        # 查找Flask进程
        result = subprocess.run(['pgrep', '-f', 'flask run'], capture_output=True, text=True)
        if result.returncode == 0:
            pids = result.stdout.strip().split('\n')
            for pid in pids:
                if pid:
                    print(f"杀死进程 {pid}")
                    os.kill(int(pid), signal.SIGTERM)
                    time.sleep(1)
        
        # 也查找Python进程
        result = subprocess.run(['pgrep', '-f', 'python.*app.py'], capture_output=True, text=True)
        if result.returncode == 0:
            pids = result.stdout.strip().split('\n')
            for pid in pids:
                if pid:
                    print(f"杀死Python进程 {pid}")
                    os.kill(int(pid), signal.SIGTERM)
                    time.sleep(1)
                    
        print("✅ 现有服务器进程已停止")
        
    except Exception as e:
        print(f"停止服务器进程时出错: {e}")

def start_server():
    """启动新的服务器"""
    try:
        print("启动新的服务器...")
        # 使用app.py直接启动，这样会包含提醒调度器
        subprocess.Popen(['nohup', 'python3', 'app.py'], 
                        stdout=open('run.log', 'w'), 
                        stderr=subprocess.STDOUT)
        print("✅ 服务器已启动")
        print("日志文件: run.log")
        
    except Exception as e:
        print(f"启动服务器时出错: {e}")

if __name__ == '__main__':
    print("=" * 50)
    print("重启服务器")
    print("=" * 50)
    print()
    
    kill_existing_server()
    time.sleep(2)
    start_server()
    
    print()
    print("等待服务器启动...")
    time.sleep(3)
    
    print("检查服务器状态...")
    try:
        import requests
        response = requests.get('https://service.muhuo.site/api/v1/voice-reminders', timeout=5)
        if response.status_code == 200:
            print("✅ 服务器启动成功！")
        else:
            print(f"⚠️ 服务器响应异常: {response.status_code}")
    except Exception as e:
        print(f"⚠️ 服务器连接测试失败: {e}")
        print("请等待几秒钟后手动测试")
    
    print("=" * 50)