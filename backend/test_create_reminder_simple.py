#!/usr/bin/env python3
"""
简单测试创建提醒功能
"""
import requests
import json
from datetime import datetime, timedelta

BASE_URL = 'https://service.muhuo.site'

def test_create_reminder():
    """测试创建提醒"""
    try:
        # 创建一个2分钟后的提醒
        now = datetime.now()
        test_time = now + timedelta(minutes=2)
        time_str = test_time.strftime('%H:%M')
        
        data = {
            'time': time_str,
            'content': f'服务器测试提醒 - {now.strftime("%H:%M:%S")} 创建',
            'reminder_type': 'ai_voice',
            'voice_model': 'tts-1'
        }
        
        print(f"创建提醒: {time_str} - {data['content']}")
        
        response = requests.post(
            f'{BASE_URL}/api/v1/voice-reminders',
            json=data,
            timeout=10
        )
        
        print(f"响应状态码: {response.status_code}")
        print(f"响应内容: {response.text}")
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ 提醒创建成功!")
            print(f"   ID: {result.get('id')}")
            print(f"   时间: {result.get('time')}")
            print(f"   内容: {result.get('content')}")
            print(f"   类型: {result.get('reminder_type')}")
            return True
        else:
            print(f"❌ 创建提醒失败: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ 创建提醒异常: {e}")
        return False

def get_reminders():
    """获取所有提醒"""
    try:
        response = requests.get(f'{BASE_URL}/api/v1/voice-reminders', timeout=10)
        if response.status_code == 200:
            reminders = response.json()
            print(f"\n当前提醒列表 ({len(reminders)} 个):")
            for r in reminders:
                status = "启用" if r.get('enabled', False) else "禁用"
                print(f"  - {r.get('time', 'N/A')}: {r.get('content', 'N/A')} ({status})")
            return reminders
        else:
            print(f"❌ 获取提醒失败: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ 获取提醒异常: {e}")
        return []

if __name__ == '__main__':
    print("=" * 60)
    print("服务器提醒系统测试")
    print("=" * 60)
    print()
    
    # 1. 获取现有提醒
    print("1. 获取现有提醒")
    get_reminders()
    print()
    
    # 2. 测试创建新提醒
    print("2. 测试创建新提醒")
    success = test_create_reminder()
    print()
    
    if success:
        print("3. 验证提醒已创建")
        get_reminders()
        print()
        print("✅ 测试成功！提醒系统现在应该可以正常工作了。")
        print("⏰ 请等待2分钟，观察是否收到推送通知。")
    else:
        print("❌ 测试失败，请检查服务器日志。")
    
    print("=" * 60)