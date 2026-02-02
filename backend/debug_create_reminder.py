#!/usr/bin/env python3
"""
调试创建提醒的问题
"""
from menu_system.db import SessionLocal
from menu_system.models import VoiceReminder
from menu_system.services import create_voice_reminder
from datetime import datetime, timedelta

def test_direct_db_insert():
    """直接测试数据库插入"""
    print("1. 测试直接数据库插入...")
    
    try:
        with SessionLocal() as s:
            reminder = VoiceReminder(
                time='23:58',
                content='直接数据库测试提醒',
                enabled=True,
                reminder_type='ai_voice',
                voice_model='tts-1'
            )
            s.add(reminder)
            s.commit()
            s.refresh(reminder)
            print(f"✅ 直接数据库插入成功: ID={reminder.id}")
            
            # 清理测试数据
            s.delete(reminder)
            s.commit()
            print("✅ 测试数据已清理")
            
    except Exception as e:
        print(f"❌ 直接数据库插入失败: {e}")
        import traceback
        traceback.print_exc()

def test_service_function():
    """测试服务函数"""
    print("\n2. 测试服务函数...")
    
    try:
        now = datetime.now()
        test_time = now + timedelta(minutes=1)
        time_str = test_time.strftime('%H:%M')
        
        reminder = create_voice_reminder(
            time=time_str,
            content='服务函数测试提醒',
            reminder_type='ai_voice',
            voice_model='tts-1'
        )
        
        print(f"✅ 服务函数调用成功: ID={reminder.id}")
        
        # 清理测试数据
        with SessionLocal() as s:
            s.delete(reminder)
            s.commit()
            print("✅ 测试数据已清理")
            
    except Exception as e:
        print(f"❌ 服务函数调用失败: {e}")
        import traceback
        traceback.print_exc()

def test_api_endpoint():
    """测试API端点"""
    print("\n3. 测试API端点...")
    
    try:
        from app import app
        
        with app.test_client() as client:
            now = datetime.now()
            test_time = now + timedelta(minutes=1)
            time_str = test_time.strftime('%H:%M')
            
            data = {
                'time': time_str,
                'content': 'API端点测试提醒',
                'reminder_type': 'ai_voice',
                'voice_model': 'tts-1'
            }
            
            response = client.post('/api/v1/voice-reminders', json=data)
            
            print(f"响应状态码: {response.status_code}")
            print(f"响应内容: {response.get_data(as_text=True)}")
            
            if response.status_code == 201:
                print("✅ API端点调用成功")
            else:
                print("❌ API端点调用失败")
                
    except Exception as e:
        print(f"❌ API端点测试失败: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    print("=" * 60)
    print("调试创建提醒问题")
    print("=" * 60)
    
    test_direct_db_insert()
    test_service_function()
    test_api_endpoint()
    
    print("\n" + "=" * 60)