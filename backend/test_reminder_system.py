#!/usr/bin/env python3
"""
提醒系统测试脚本
"""
import requests
import json
from datetime import datetime, timedelta

BASE_URL = 'https://service.muhuo.site'

def test_api_connection():
    """测试API连接"""
    try:
        response = requests.get(f'{BASE_URL}/api/v1/health', timeout=10)
        print(f"✅ API连接正常: {response.status_code}")
        return True
    except Exception as e:
        print(f"❌ API连接失败: {e}")
        return False

def get_voice_reminders():
    """获取语音提醒列表"""
    try:
        response = requests.get(f'{BASE_URL}/api/v1/voice-reminders', timeout=10)
        if response.status_code == 200:
            reminders = response.json()
            print(f"✅ 获取到 {len(reminders)} 个提醒:")
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

def get_push_subscriptions():
    """获取推送订阅列表"""
    try:
        response = requests.get(f'{BASE_URL}/api/v1/push-subscriptions', timeout=10)
        if response.status_code == 200:
            subs = response.json()
            print(f"✅ 获取到 {len(subs)} 个推送订阅:")
            for sub in subs:
                endpoint = sub.get('endpoint', 'N/A')
                print(f"  - {endpoint[:50]}...")
            return subs
        else:
            print(f"❌ 获取推送订阅失败: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ 获取推送订阅异常: {e}")
        return []

def get_vapid_public_key():
    """获取VAPID公钥"""
    try:
        response = requests.get(f'{BASE_URL}/api/v1/vapid-public-key', timeout=10)
        if response.status_code == 200:
            data = response.json()
            public_key = data.get('publicKey', 'N/A')
            print(f"✅ VAPID公钥: {public_key[:20]}...")
            return public_key
        else:
            print(f"❌ 获取VAPID公钥失败: {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ 获取VAPID公钥异常: {e}")
        return None

def create_test_reminder():
    """创建测试提醒"""
    try:
        # 创建一个1分钟后的提醒
        now = datetime.now()
        test_time = now + timedelta(minutes=1)
        time_str = test_time.strftime('%H:%M')
        
        data = {
            'time': time_str,
            'content': f'测试提醒 - {now.strftime("%Y-%m-%d %H:%M:%S")} 创建',
            'reminder_type': 'ai_voice',
            'voice_model': 'tts-1'
        }
        
        response = requests.post(
            f'{BASE_URL}/api/v1/voice-reminders',
            json=data,
            timeout=10
        )
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ 测试提醒创建成功: {time_str} - {data['content']}")
            return result
        else:
            print(f"❌ 创建测试提醒失败: {response.status_code}")
            print(f"响应内容: {response.text}")
            return None
    except Exception as e:
        print(f"❌ 创建测试提醒异常: {e}")
        return None

def test_push_notification():
    """测试推送通知"""
    try:
        response = requests.post(f'{BASE_URL}/api/v1/push/test', timeout=10)
        if response.status_code == 200:
            print("✅ 推送测试请求已发送")
            return True
        else:
            print(f"❌ 推送测试失败: {response.status_code}")
            print(f"响应内容: {response.text}")
            return False
    except Exception as e:
        print(f"❌ 推送测试异常: {e}")
        return False

def main():
    print("=" * 60)
    print("提醒系统测试")
    print("=" * 60)
    print()
    
    # 1. 测试API连接
    print("1. 测试API连接")
    if not test_api_connection():
        print("API连接失败，无法继续测试")
        return
    print()
    
    # 2. 获取VAPID公钥
    print("2. 检查VAPID配置")
    get_vapid_public_key()
    print()
    
    # 3. 获取推送订阅
    print("3. 检查推送订阅")
    subscriptions = get_push_subscriptions()
    print()
    
    # 4. 获取现有提醒
    print("4. 检查现有提醒")
    reminders = get_voice_reminders()
    print()
    
    # 5. 创建测试提醒
    print("5. 创建测试提醒")
    test_reminder = create_test_reminder()
    print()
    
    # 6. 测试推送通知
    print("6. 测试推送通知")
    if subscriptions:
        test_push_notification()
    else:
        print("⚠️ 没有推送订阅，跳过推送测试")
    print()
    
    # 总结
    print("=" * 60)
    print("测试总结:")
    print(f"- 提醒数量: {len(reminders)}")
    print(f"- 推送订阅: {len(subscriptions)}")
    print(f"- 测试提醒: {'已创建' if test_reminder else '创建失败'}")
    
    if test_reminder:
        print()
        print("⏰ 请等待1分钟，观察测试提醒是否正常触发")
        print("   如果系统正常，您应该会收到推送通知和语音播报")
    
    print("=" * 60)

if __name__ == '__main__':
    main()