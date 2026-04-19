#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import time
import shutil

# --- CONFIGURATION (ORIGINAL .SH LOGIC) ---
VERSION = "8.5.1 (Autonomous Samsung Core)"
LOOT_DIR = os.path.expanduser("~/arsenal_loot")
TARGET_FILE = "/usr/local/bin/kali_pro"

class Style:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    YELLOW = '\033[1;33m'
    MAGENTA = '\033[0;35m'
    WHITE = '\033[1;37m'
    BOLD = '\033[1m'
    NC = '\033[0m'

# --- CORE UTILS ---

def run_smart_check():
    """Фоновая проверка cron и ресурсов (как в твоем run_smart_check)"""
    subprocess.run("pgrep cron > /dev/null || cron &>/dev/null", shell=True)
    subprocess.run("apt-get clean >/dev/null 2>&1", shell=True)
    
    # Индикатор ресурсов
    total, used, free = shutil.disk_usage("/")
    fmt = lambda b: f"{b/1024**3:.1f}G" if b >= 1024**3 else f"{b//1024**2}MB"
    status = f"{Style.GREEN}OK" if free > (350*1024**2) else f"{Style.RED}LOW"
    print(f"   {Style.BLUE}[ СИСТЕМА ]:{Style.NC} {fmt(free)} / {fmt(total)} ({status}{Style.NC})")

def ghost_purge():
    """Модуль глубокой стерилизации (Deep Purge v6.9)"""
    print(f"{Style.RED}[!] Initiating Ghost Purge Protocol...{Style.NC}")
    cmds = [
        "apt-get autoremove --purge -y -qq",
        "apt-get clean -y -qq",
        "rm -rf /var/lib/apt/lists/*",
        "find /var/log -type f -exec truncate -s 0 {} \\;",
        "truncate -s 0 ~/.bash_history ~/.zsh_history ~/.python_history",
        "history -c"
    ]
    for cmd in cmds:
        subprocess.run(cmd, shell=True, capture_output=True)
    print(f"{Style.GREEN}[V] System is sterile.{Style.NC}")

# --- FLOWS (ТВОИ УМНЫЕ СВЯЗКИ) ---

def flow_total_recon():
    """FLOW A: OSINT & Analytic"""
    print(f"{Style.BLUE}=== [ TOTAL RECON 360 MODE ] ==={Style.NC}")
    target = input(f"{Style.YELLOW}Введите цель (Email/Nick/Domain): {Style.NC}")
    if not target: return
    
    # 1. Trust Analyzer (Эмуляция v8.3)
    print(f"{Style.CYAN}[*] Запуск Trust Analyzer v8.3...{Style.NC}")
    if "@" in target:
        print(f"{Style.GREEN}[+] Тип: EMAIL. Глубокая валидация...{Style.NC}")
    
    # 2. Sherlock
    nick = target.split('@')[0]
    print(f"{Style.MAGENTA}[*] Поиск цифрового следа для: {nick}{Style.NC}")
    os.system(f"sherlock {nick} --timeout 3 --print-found")
    input(f"\n{Style.WHITE}Нажмите Enter...{Style.NC}")

def flow_web_stack():
    """FLOW B: Scan & Exploit"""
    print(f"{Style.RED}=== [ WEB ATTACK STACK ] ==={Style.NC}")
    target = input(f"{Style.YELLOW}Введите URL/IP: {Style.NC}")
    if not target: return
    
    print(f"{Style.CYAN}[*] Smart Nmap Scan...{Style.NC}")
    os.system(f"nmap -v -A -T4 {target}")
    
    print(f"{Style.MAGENTA}[*] Launching Nikto Audit...{Style.NC}")
    os.system(f"nikto -h {target} -Tuning 12345bc -maxtime 180s")
    input("\nReturn to Menu...")

def flow_network_guardian():
    """FLOW C: Sniff & Conn"""
    # Вызов настроек Android (как в оригинале)
    os.system("am start -n com.android.settings/.Settings\\$TetherSettingsActivity >/dev/null 2>&1")
    print(f"{Style.BLUE}=== [ NETWORK SNIFFER SUITE ] ==={Style.NC}")
    os.system("bettercap -eval 'net.probe on; net.sniff on'")

def flow_system_care():
    """FLOW D: Ghost & Clean"""
    ghost_purge()
    print(f"{Style.CYAN}[*] Updating Repository...{Style.NC}")
    os.system("apt-get update && apt-get upgrade -y")

def flow_wireless():
    """FLOW E: WiFi & BT-HID"""
    print(f"{Style.RED}=== [ WIRELESS DOMINANCE ] ==={Style.NC}")
    print(f"{Style.CYAN}[1] Wifite (Handshake Capture){Style.NC}")
    os.system("wifite --kill --mac")
    input("\nReturn...")

# --- MENU SYSTEM ---

def show_menu():
    os.system('clear')
    print(f"{Style.CYAN}┌───────────────────────────────────────────┐{Style.NC}")
    print(f"{Style.CYAN}│{Style.NC} {Style.GREEN}    AUTONOMOUS SAMSUNG CORE v8.5.1    {Style.NC} {Style.CYAN}│{Style.NC}")
    print(f"{Style.CYAN}└───────────────────────────────────────────┘{Style.NC}")
    run_smart_check()
    
    print(f"\n{Style.YELLOW} [ AUTONOMOUS OPERATIONS ]{Style.NC}")
    print(f" {Style.CYAN}A.{Style.NC} TOTAL RECON   {Style.NC}- OSINT & Analyt")
    print(f" {Style.CYAN}B.{Style.NC} WEB ATTACK    {Style.NC}- Scan & Exploit")
    print(f" {Style.CYAN}C.{Style.NC} NET GUARDIAN  {Style.NC}- Sniff & Conn")
    print(f" {Style.CYAN}D.{Style.NC} STERILIZER    {Style.NC}- Ghost & Clean")
    print(f" {Style.CYAN}E.{Style.NC} WIRELESS      {Style.NC}- WiFi & BT-HID")
    
    print(f"\n{Style.GREEN} [ INTERFACE ]{Style.NC}")
    print(f"  18. TERMINAL       0. EXIT")
    print(f"\n{Style.CYAN}─────────────────────────────────────────────{Style.NC}")

def main():
    if not os.path.exists(LOOT_DIR):
        os.makedirs(LOOT_DIR)

    while True:
        show_menu()
        choice = input(f"{Style.WHITE}Выберите операцию: {Style.NC}").upper()
        
        if choice == 'A': flow_total_recon()
        elif choice == 'B': flow_web_stack()
        elif choice == 'C': flow_network_guardian()
        elif choice == 'D': flow_system_care()
        elif choice == 'E': flow_wireless()
        elif choice == '18':
            print(f"{Style.YELLOW}[!] Shell Mode. Type 'exit' to return.{Style.NC}")
            os.system("bash") # Вызов полноценного bash внутри
        elif choice == '0':
            print(f"{Style.YELLOW}Returning to Kali...{Style.NC}")
            break # Просто выходим из цикла, и ты в консоли
        else:
            print(f"{Style.RED}[!] Ошибка. Режимы A-E.{Style.NC}")
            time.sleep(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
