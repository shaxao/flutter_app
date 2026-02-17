#!/usr/bin/env python3
"""
Add is_preset, use_fade_in, fade_in_duration fields to voice_reminders table
"""
import sqlite3
import os

DB_PATH = './menu.db'

def migrate_fields():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database file not found: {DB_PATH}")
        return False
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        print("Checking for new fields...")
        
        # Check existing columns
        cursor.execute("PRAGMA table_info(voice_reminders)")
        columns = [col[1] for col in cursor.fetchall()]
        
        # Add is_preset
        if 'is_preset' not in columns:
            print("Adding is_preset field...")
            cursor.execute('ALTER TABLE voice_reminders ADD COLUMN is_preset BOOLEAN DEFAULT 0')
            conn.commit()
            print("✅ is_preset added")
        else:
            print("⚠️ is_preset already exists")

        # Add use_fade_in
        if 'use_fade_in' not in columns:
            print("Adding use_fade_in field...")
            cursor.execute('ALTER TABLE voice_reminders ADD COLUMN use_fade_in BOOLEAN DEFAULT 0')
            conn.commit()
            print("✅ use_fade_in added")
        else:
            print("⚠️ use_fade_in already exists")

        # Add fade_in_duration
        if 'fade_in_duration' not in columns:
            print("Adding fade_in_duration field...")
            cursor.execute('ALTER TABLE voice_reminders ADD COLUMN fade_in_duration INTEGER DEFAULT 5')
            conn.commit()
            print("✅ fade_in_duration added")
        else:
            print("⚠️ fade_in_duration already exists")
        
        # Show updated schema
        print("\nCurrent table schema:")
        cursor.execute("PRAGMA table_info(voice_reminders)")
        for col in cursor.fetchall():
            print(f"  - {col[1]} ({col[2]})")
        
        return True
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()

if __name__ == '__main__':
    print("=" * 50)
    print("Migrating Voice Reminder Fields")
    print("=" * 50)
    print()
    
    success = migrate_fields()
    
    print()
    if success:
        print("Migration successful!")
    else:
        print("Migration failed.")
