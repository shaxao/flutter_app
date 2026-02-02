#!/usr/bin/env python3
"""
简单修复updated_at字段问题
"""
import sqlite3
import os
from datetime import datetime

DB_PATH = './menu.db'

def fix_updated_at():
    if not os.path.exists(DB_PATH):
        print(f"❌ 数据库文件不存在: {DB_PATH}")
        return False
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # 检查字段是否已存在
        cursor.execute("PRAGMA table_info(voice_reminders)")
        columns = [col[1] for col in cursor.fetchall()]
        
        if 'updated_at' not in columns:
            print("添加updated_at字段（无默认值）...")
            cursor.execute('ALTER TABLE voice_reminders ADD COLUMN updated_at DATETIME')
            
            # 为现有记录设置updated_at值
            current_time = datetime.utcnow().isoformat()
            cursor.execute('UPDATE voice_reminders SET updated_at = ? WHERE updated_at IS NULL', (current_time,))
            
            conn.commit()
            print("✅ updated_at字段已添加并初始化")
        else:
            print("⚠️ updated_at字段已存在")
        
        # 测试插入一条记录
        print("\n测试插入记录...")
        test_time = datetime.utcnow().isoformat()
        cursor.execute('''
            INSERT INTO voice_reminders (time, content, enabled, reminder_type, voice_model, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', ('23:59', '测试提醒', True, 'ai_voice', 'tts-1', test_time, test_time))
        
        conn.commit()
        
        # 获取插入的记录ID
        test_id = cursor.lastrowid
        print(f"✅ 测试记录插入成功，ID: {test_id}")
        
        # 删除测试记录
        cursor.execute('DELETE FROM voice_reminders WHERE id = ?', (test_id,))
        conn.commit()
        print("✅ 测试记录已清理")
        
        return True
        
    except Exception as e:
        print(f"❌ 修复失败: {e}")
        import traceback
        traceback.print_exc()
        conn.rollback()
        return False
    finally:
        conn.close()

if __name__ == '__main__':
    print("=" * 50)
    print("简单修复updated_at字段")
    print("=" * 50)
    print()
    
    success = fix_updated_at()
    
    print()
    if success:
        print("修复成功！现在可以正常创建提醒了。")
    else:
        print("修复失败，请检查错误信息。")