#!/usr/bin/env python3
import os
import re

def fix_with_opacity(file_path):
    """修复 withOpacity 为 withValues"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 替换 withOpacity(0.xx) 为 withValues(alpha: 0.xx)
    pattern = r'\.withOpacity\(([0-9.]+)\)'
    replacement = r'.withValues(alpha: \1)'
    
    new_content = re.sub(pattern, replacement, content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed: {file_path}")
        return True
    return False

def main():
    # 需要修复的文件
    files_to_fix = [
        'lib/features/reminder/presentation/pages/reminder_page.dart',
        'lib/features/schedule/presentation/pages/schedule_page.dart',
    ]
    
    fixed_count = 0
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if fix_with_opacity(file_path):
                fixed_count += 1
        else:
            print(f"File not found: {file_path}")
    
    print(f"Fixed {fixed_count} files")

if __name__ == '__main__':
    main()