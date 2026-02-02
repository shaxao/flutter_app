#!/usr/bin/env python3
"""
为voice_reminders表添加updated_at字段 - 修复版本
"""
import sqlite3
import os

DB_PATH = './menu.db'

def add_updated_at_field():
    if not os.path.exists(DB_PATH):
        print(f"❌ 数据库文件不存在: {DB_PATH}")
        return False
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        print("检查updated_at字段是否存在...")
        
        # 检查字段是否已存在
        cursor.execute("PRAGMA table_info(voice_reminders)")
        columns = [col[1] for col in cursor.fetchall()]
        
        if 'updated_at' not in columns:
            print("添加updated_at字段...")
            # 使用NULL作为默认值，然后更新现有记录
            cursor.execute('''
                ALTER TABLE voice_reminders 
                ADD COLUMN updated_at DATETIME
            ''')
            
            # 为现有记录设置updated_at值
            cursor.execute('''
                UPDATE voice_reminders 
                SET updated_at = created_at 
                WHERE updated_at IS NULL
            ''')
            
            conn.commit()
            print("✅ updated_at字段已添加")
        else:
            print("⚠️ updated_at字段已存在，跳过")
        
        # 显示更新后的表结构
        print("\n当前表结构:")
        cursor.execute("PRAGMA table_info(voice_reminders)")
        for col in cursor.fetchall():
            print(f"  - {col[1]} ({col[2]})")
        
        return True
        
    except Exception as e:
        print(f"❌ 添加字段失败: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()

if __name__ == '__main__':
    print("=" * 50)
    print("添加updated_at字段 - 修复版本")
    print("=" * 50)
    print()
    
    success = add_updated_at_field()
    
    print()
    if success:
        print("字段添加成功！")
    else:
        print("字段添加失败，请检查错误信息。")