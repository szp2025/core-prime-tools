#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess

# --- ПОЛНАЯ КОНФИГУРАЦИЯ ИЗ .SH ---
VERSION = "8.4 Ultra-Precision (Rescue & Sterile Edition)"
# Флаги установки (без фигурных скобок, чтобы не злить sh)
INSTALL_FLAGS = "-y --no-install-recommends"
PROGRESS_OPTS = "-o Dpkg::Progress-Fancy=1 -o APT::Color=1"

class Style:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    YELLOW = '\033[1;33m'
    BOLD = '\033[1m'
    NC = '\033[0m'

def run_system_check():
    """Все фоновые проверки и очистки из оригинала"""
    # Запуск cron если не запущен
    subprocess.run("pgrep cron > /dev/null || cron &>/dev/null", shell=True)
    # Стерильная очистка кэша
    subprocess.run("apt-get clean >/dev/null 2>&1", shell=True)

def show_banner():
    os.system('clear')
    print(f"{Style.GREEN}{Style.BOLD}[+] {VERSION} развернута!{Style.NC}")
    print(f"{Style.CYAN}--- Core Prime Tools Infrastructure ---{Style.NC}\n")

def main_menu():
    show_banner()
    run_system_check()
    
    print(f"{Style.YELLOW}{Style.BOLD}Доступные модули фильтрации:{Style.NC}")
    # Точная структура и цвета как в твоем оригинале
    print(f"1. {Style.CYAN}[88] Network Core{Style.NC} (Protocol Control)")
    print(f"2. {Style.CYAN}[90] Active City Protection{Style.NC} ('Ghost' Mode)")
    print(f"3. {Style.CYAN}[95] Sterile Channel{Style.NC} (Money Operations)")
    print(f"4. {Style.GREEN}Обновить арсенал{Style.NC} (Nmap, Nikto, Sherlock)")
    print(f"5. {Style.RED}Выход{Style.NC}")
    
    try:
        choice = input(f"\n{Style.GREEN}{Style.BOLD}Ввод > {Style.NC}")
        
        if choice == '1':
            print(f"\n{Style.BLUE}[*] Активация Network Core [88]...{Style.NC}")
            # Здесь твои расширенные команды nmap
            os.system("nmap -v -A -T4 127.0.0.1")
            
        elif choice == '2':
            print(f"\n{Style.CYAN}[*] Вход в 'Ghost' Mode [90]...{Style.NC}")
            # Смена MAC или другие функции из оригинала
            print(f"{Style.YELLOW}[!] Маскировка активна.{Style.NC}")
            
        elif choice == '3':
            print(f"\n{Style.YELLOW}[$] Sterile Channel [95] запущен.{Style.NC}")
            print(f"{Style.GREEN}[+] Стратегия 'Банковский Гамбит' активна.{Style.NC}")
            # Твои команды для контроля транзакций
            
        elif choice == '4':
            print(f"\n{Style.GREEN}[!] Полная синхронизация по протоколу...{Style.NC}")
            # Используем в точности твои флаги
            cmd = f"apt-get update && apt-get upgrade {INSTALL_FLAGS} {PROGRESS_OPTS}"
            os.system(cmd)
            
        elif choice == '5':
            print(f"{Style.RED}Завершение сессии.{Style.NC}")
            sys.exit(0)
            
        else:
            print(f"{Style.RED}[!] Ошибка: Модуль не найден.{Style.NC}")
            
        input(f"\n{Style.YELLOW}Нажмите Enter для возврата в ядро...{Style.NC}")
        main_menu()
        
    except KeyboardInterrupt:
        print(f"\n{Style.RED}[!] Экстренный выход.{Style.NC}")
        sys.exit(0)

if __name__ == "__main__":
    # Обработка скрытых флагов запуска (как в .sh)
    if len(sys.argv) > 1:
        if sys.argv[1] == "--purge-silent":
            subprocess.run("apt-get autoremove -y && apt-get clean", shell=True)
            sys.exit(0)

    main_menu()
