import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Исправляем print (добавляем скобки)
    content = re.sub(r'print\s+(.*)', r'print(\1)', content)
    
    # 2. Исправляем импорты urllib
    content = content.replace('import urllib2', 'import urllib.request as urllib2')
    content = content.replace('import urlparse', 'from urllib.parse import urlparse')
    
    # 3. Фиксим регулярные выражения (добавляем префикс r)
    content = content.replace('re.compile("', 're.compile(r"')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Файл {filepath} исправлен")

# Проходим по всем файлам в папке infoga и core
path = '/root/infoga'
for root, dirs, files in os.walk(path):
    for file in files:
        if file.endswith('.py') and file != 'fixer.py':
            fix_file(os.path.join(root, file))
