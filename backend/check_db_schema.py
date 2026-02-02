#!/usr/bin/env python3
"""
检查数据库结构
"""
import sqlite3
import os

DB_PATH = './menu.db'

def check_voice_reminders_table():
    """检查voice_reminders表结构"""
    if not os.path.exists(DB_PATH):
        print(f"❌ 数据库文件不存在: {DB_PATH}")
        return
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # 获取表结构
        cursor.execute("PRAGMA table_info(voice_reminders)")
        columns = cursor.fetchall()
        
        print("voice_reminders 表结构:")
        print("-" * 50)
        for col in columns:
            print(f"  {col[1]} ({col[2]}) - {'NOT NULL' if col[3] else 'NULL'} - Default: {col[4]}")
        
        print()
        
        # 获取现有数据
        cursor.execute("SELECT * FROM voice_reminders LIMIT 5")
        rows = cursor.fetchall()
        
        print(f"现有数据 (前5条):")
        print("-" * 50)
        for row in rows:
            print(f"  {row}")
        
        print()
        
        # 测试插入一条数据
        print("测试插入数据...")
        try:
            cursor.execute("""
                INSERT INTO voice_reminders (time, content, enabled, reminder_type, voice_model)
                VALUES (?, ?, ?, ?, ?)
            """, ('23:59', '测试提醒', True, 'ai_voice', 'tts-1'))
            
            conn.commit()
            print("✅ 数据插入成功")
            
            # 删除测试数据
            cursor.execute("DELETE FROM voice_reminders WHERE content = '测试提醒'")
            conn.commit()
            print("✅ 测试数据已清理")
            
        except Exception as e:
            print(f"❌ 数据插入失败: {e}")
            conn.rollback()
        
    except Exception as e:
        print(f"❌ 检查表结构失败: {e}")
    finally:
        conn.close()

def check_push_subscriptions_table():
    """检查push_subscriptions表结构"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # 检查表是否存在
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='push_subscriptions'
        """)
        
        if cursor.fetchone():
            print("push_subscriptions 表结构:")
            print("-" * 50)
            
            cursor.execute("PRAGMA table_info(push_subscriptions)")
            columns = cursor.fetchall()
            
            for col in columns:
                print(f"  {col[1]} ({col[2]}) - {'NOT NULL' if col[3] else 'NULL'} - Default: {col[4]}")
            
            # 获取现有数据
            cursor.execute("SELECT COUNT(*) FROM push_subscriptions")
            count = cursor.fetchone()[0]
            print(f"\n现有推送订阅数量: {count}")
            
        else:
            print("❌ push_subscriptions 表不存在，需要创建")
            
            # 创建表
            cursor.execute("""
                CREATE TABLE push_subscriptions (
                    id INTEGER PRIMARY KEY,
                    endpoint TEXT NOT NULL,
                    p256dh_key TEXT NOT NULL,
                    auth_key TEXT NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.commit()
            print("✅ push_subscriptions 表已创建")
        
    except Exception as e:
        print(f"❌ 检查push_subscriptions表失败: {e}")
    finally:
        conn.close()

if __name__ == '__main__':
    print("=" * 60)
    print("数据库结构检查")
    print("=" * 60)
    print()
    
    check_voice_reminders_table()
    print()
    check_push_subscriptions_table()
    print()
    print("=" * 60)