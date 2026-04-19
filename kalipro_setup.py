#!/usr/bin/env python3
import os
import sys
import subprocess

# Обновленная версия с исправленной логикой терминала
VERSION = "8.5.5"

def show_menu():
    os.system('clear')
    print(f"\033[1;32m[+] v{VERSION} Ultra-Precision развернута!\033[0m")
    print("\033[1;36m--- Core Prime Tools Infrastructure ---\033[0m")
    print("\033[1;33mДоступные модули фильтрации:\033[0m")
    print("1. [88] Network Core (Protocol Control)")
    print("2. [90] Active City Protection ('Ghost' Mode)")
    print("3. [95] Sterile Channel (Money Operations)")
    print("4. Обновить арсенал (Nmap, Nikto, Sherlock)")
    print("18. Terminal (Root Shell)")
    print("5. Выход")
    
    choice = input("\n\033[1;32mВвод > \033[0m")
    return choice

def main():
    while True:
        choice = show_menu()
        
        if choice == '1':
            print("[*] Запуск Network Core [88]...")
            # Твоя логика модуля 88 остается здесь
            input("\nНажмите Enter для возврата...")
            
        elif choice == '2':
            print("[*] Активация Ghost Mode [90]...")
            # Твоя логика модуля 90 остается здесь
            input("\nНажмите Enter для возврата...")
            
        elif choice == '3':
            print("[*] Открытие Sterile Channel [95]...")
            # Твоя логика модуля 95 остается здесь
            input("\nНажмите Enter для возврата...")
            
        elif choice == '4':
            print("[*] Обновление инструментов...")
            os.system('apt update && apt upgrade -y')
            input("\nОбновление завершено. Нажмите Enter...")
            
        elif choice == '18':
            # Исправлено: открываем чистый root shell без мгновенного возврата
            os.system('clear')
            print("\033[1;34m[*] Вход в Root Shell (root@kali).")
            print("[*] Введите 'exit' для возврата в меню Core Prime.\033[0m\n")
            # Используем bash --login для полной среды root
            subprocess.call(['/bin/bash', '--login'])
            
        elif choice == '5' or choice == '0':
            # Исправлено: чистый выход в root@localhost
            os.system('clear')
            print("\033[1;31m[!] Завершение сессии Core Prime. Возврат в Kali (root@localhost)...\033[0m")
            sys.exit(0)
            
        else:
            print("\033[1;31m[!] Неверный ввод. Попробуйте снова.\033[0m")
            import time
            time.sleep(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        # Тихий выход при Ctrl+C
        print("\n\033[1;31m[!] Принудительная остановка. Возврат в консоль.\033[0m")
        sys.exit(0)
