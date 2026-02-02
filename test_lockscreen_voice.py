#!/usr/bin/env python3
"""
锁屏语音播放测试脚本
"""

import requests
import json
import time

def test_tts_api():
    """测试TTS API"""
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
    """测试提醒创建"""
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
