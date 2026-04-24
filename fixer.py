import os
import re

def heavy_fix(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        code = f.read()

    # --- 1. СИНТАКСИС ПРИНТА ---
    # Исправляет 'print "text"' -> 'print("text")'
    code = re.sub(r'print\s+(.*)', r'print(\1)', code)
    
    # --- 2. ИМПОРТЫ (БИБЛИОТЕКИ) ---
    replacements = {
        'import urllib2': 'import urllib.request as urllib2',
        'import urllib': 'import urllib.request as urllib',
        'import urlparse': 'from urllib.parse import urlparse',
        'import httplib': 'import http.client as httplib',
        'import cookielib': 'import http.cookiejar as cookielib',
        'import HTMLParser': 'import html.parser as HTMLParser',
        'import Queue': 'import queue as Queue',
        'import ConfigParser': 'import configparser as ConfigParser'
    }
    for old, new in replacements.items():
        code = code.replace(old, new)

    # --- 3. ИСКЛЮЧЕНИЯ (EXCEPTIONS) ---
    # Исправляет 'except Exception, e:' -> 'except Exception as e:'
    code = re.sub(r'except\s+([\w\.]+),\s*(\w+):', r'except \1 as \2:', code)

    # --- 4. РЕГУЛЯРНЫЕ ВЫРАЖЕНИЯ (Python 3.13 Fix) ---
    # Добавляет 'r' перед строками в re.compile
    code = code.replace('re.compile("', 're.compile(r"')
    code = code.replace("re.compile('", "re.compile(r'")

    # --- 5. ДЕЛЕНИЕ И ТИПЫ ДАННЫХ ---
    code = code.replace('raw_input(', 'input(')
    code = code.replace('.xrange(', '.range(')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(code)
    print(f"✅ [CLEANED] {filepath}")

# Глобальный поиск по всем папкам (core, lib, recon и т.д.)
base_path = os.getcwd()
for root, dirs, files in os.walk(base_path):
    for file in files:
        if file.endswith('.py') and file != 'fixer.py':
            heavy_fix(os.path.join(root, file))

print("\n🔥 Infoga полностью адаптирована под Python 3.13!")
