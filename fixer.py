import os
import re

def heuristic_fix(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()

        new_lines = []
        changed = False

        for line in lines:
            original = line
            
            # 1. Исправление print (только если нет скобок)
            if 'print ' in line and '(' not in line:
                # Исключаем строки, где print — часть слова или комментария
                line = re.sub(r'^\s*print\s+(.*)', r'print(\1)', line)

            # 2. Умные импорты (проверка на дубликаты)
            mapping = {
                r'\burllib2\b': 'urllib.request',
                r'\burlparse\b': 'urllib.parse',
                r'\bhttplib\b': 'http.client',
                r'\bcookielib\b': 'http.cookiejar',
                r'\bHTMLParser\b': 'html.parser',
                r'\bConfigParser\b': 'configparser'
            }

            for old, new in mapping.items():
                if re.search(old, line):
                    # Если строка уже содержит новый формат (напр. urllib.parse), не трогаем
                    if new not in line:
                        # Пример: import urlparse -> from urllib import parse as urlparse
                        if 'import' in line and 'from' not in line:
                            line = line.replace(f'import {old.strip("\\b")}', f'import {new} as {old.strip("\\b")}')
                        else:
                            line = re.sub(old, new, line)

            # 3. Исправление исключений (except Exception, e -> as e)
            line = re.sub(r'except\s+([\w\.]+),\s*(\w+):', r'except \1 as \2:', line)

            # 4. Python 3.13 Regex Fix (добавление префикса r)
            if 're.compile(' in line and 'r"' not in line and "r'" not in line:
                line = line.replace('re.compile("', 're.compile(r"')
                line = line.replace("re.compile('", "re.compile(r'")

            # 5. Очистка двойных импортов (защита от багов прошлых запусков)
            line = line.replace('from urllib.parse from urllib.parse', 'from urllib.parse')
            line = line.replace('import http.client as http.client', 'import http.client')

            if line != original:
                changed = True
            new_lines.append(line)

        if changed:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            print(f"✅ [FIXED] {filepath}")
        else:
            print(f"   [OK] {filepath}")

    except Exception as e:
        print(f"❌ [ERROR] {filepath}: {e}")

# Запуск по всей текущей директории
if __name__ == "__main__":
    print("🔥 Starting Heuristic Fixer v3.0...")
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.py') and file != 'fixer.py':
                heuristic_fix(os.path.join(root, file))
    print("\n⚡ Ремонт завершен. Попробуй запустить Infoga!")
