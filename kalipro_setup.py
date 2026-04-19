#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess

# --- ГЛОБАЛЬНЫЕ ПАРАМЕТРЫ СТЕРИЛЬНОСТИ (ИЗ ОРИГИНАЛА) ---
CURRENT_VERSION ="8.3"
VERSION = "CURRENT_VERSION (Rescue & Sterile Edition)"
TARGET_FILE = "/usr/local/bin/kali_pro"
INSTALL_FLAGS = "-y --no-install-recommends"
PROGRESS_OPTS = "-o Dpkg::Progress-Fancy=1 -o APT::Color=1"
CLEAN_OPTS = "-o Dpkg::Post-Invoke={'apt-get clean';}"

class Style:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'

def run_smart_check():
    """Фоновая мини-очистка при каждом обновлении меню (из оригинала)"""
    # pgrep cron > /dev/null || cron &>/dev/null
    subprocess.run("pgrep cron > /dev/null || cron &>/dev/null", shell=True)
    # apt-get clean >/dev/null 2>&1
    subprocess.run(f"apt-get clean {CLEAN_OPTS} >/dev/null 2>&1", shell=True)

def show_banner():
    os.system('clear')
    print(f"{Style.GREEN}[+] v8.1 Ultra-Precision развернута!{Style.NC}") #
    print(f"{Style.CYAN}--- Core Prime Tools Infrastructure ---{Style.NC}\n")

def main_menu():
    show_banner()
    run_smart_check()
    
    # СТРУКТУРА МЕНЮ (ПОЛНОЕ СООТВЕТСТВИЕ ОРИГИНАЛУ)
    print(f"{Style.YELLOW}Доступные модули фильтрации:{Style.NC}")
    print(f"1. {Style.CYAN}[88] Network Core{Style.NC} (Protocol Control)") #
    print(f"2. {Style.CYAN}[90] Active City Protection{Style.NC} ('Ghost' Mode)") #
    print(f"3. {Style.CYAN}[95] Sterile Channel{Style.NC} (Money Operations)") #
    print(f"4. Обновить арсенал (Nmap, Nikto, Sherlock)")
    print(f"5. Выход")
    
    try:
        choice = input(f"\n{Style.GREEN}Ввод > {Style.NC}")
        
        if choice == '1':
            print(f"\n{Style.BLUE}[*] Активация Network Core (88)...{Style.NC}")
            # Здесь будет твоя команда для протоколов
            os.system("nmap -sV 127.0.0.1")
            
        elif choice == '2':
            print(f"\n{Style.CYAN}[*] Вход в 'Ghost' Mode (90)...{Style.NC}")
            # Логика Active City Protection
            
        elif choice == '3':
            print(f"\n{Style.YELLOW}[$] Sterile Channel (95) активен.{Style.NC}")
            print(f"{Style.GREEN}[+] Стратегия 'Банковский Гамбит' включена.{Style.NC}") #
            
        elif choice == '4':
            print(f"\n{Style.GREEN}[!] Синхронизация репозиториев...{Style.NC}")
            # Использование оригинальных флагов установки
            os.system(f"apt update && apt upgrade {INSTALL_FLAGS} {PROGRESS_OPTS}")
            
        elif choice == '5':
            print(f"{Style.RED}Завершение сессии...{Style.NC}")
            sys.exit()
            
        else:
            print(f"{Style.RED}[!] Ошибка: Неверный модуль.{Style.NC}")
            
        input(f"\n{Style.YELLOW}Нажмите Enter для возврата...{Style.NC}")
        main_menu()
        
    except KeyboardInterrupt:
        print(f"\n{Style.RED}[!] Прервано.{Style.NC}")
        sys.exit()

# --- ОБРАБОТКА ФОНОВЫХ КОМАНД (ИЗ ОРИГИНАЛА) ---
if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "--purge-silent":
            # deep_purge > /dev/null 2>&1
            subprocess.run("apt-get autoremove -y && apt-get clean", shell=True)
            sys.exit(0)
            
        if sys.argv[1] == "--update-silent":
            # update_kali > /dev/null 2>&1
            os.system("apt update > /dev/null 2>&1")
            sys.exit(0)

    main_menu()
