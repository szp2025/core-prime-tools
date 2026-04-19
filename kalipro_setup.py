cat << 'EOF' > /usr/local/bin/kali_pro
#!/usr/bin/env python3
# VERSION=8.5.8
import os, subprocess, shutil

def run_smart_check():
    # Выполнение системных команд через subprocess
    subprocess.run("pgrep cron > /dev/null || cron &>/dev/null", shell=True)
    
    total, used, free = shutil.disk_usage("/")
    fmt = lambda b: f'{b/1024**3:.1f}G'
    status = '\033[0;32mOK' if free > (350*1024*1024) else '\033[0;31mLOW'
    print(f'   \033[0;34m[ СИСТЕМА ]:\033[0m {fmt(free)} / {fmt(total)} ({status}\033[0m)')

def show_menu():
    os.system('clear')
    print("\033[0;36m┌───────────────────────────────────────────┐\033[0m")
    print("\033[0;36m│\033[0m \033[0;32m    AUTONOMOUS SAMSUNG CORE v8.5.8    \033[0m \033[0;36m│\033[0m")
    print("\033[0;36m└───────────────────────────────────────────┘\033[0m")
    run_smart_check()
    print("\n\033[1;33m [ AUTONOMOUS OPERATIONS ]\033[0m")
    print(" \033[0;36mA.\033[0m TOTAL RECON")
    print(" \033[0;36mB.\033[0m WEB ATTACK")
    print(" \033[0;36mC.\033[0m NET GUARDIAN")
    print("\n \033[0;32m18. TERMINAL\033[0m    \033[0;31m0. EXIT\033[0m")

while True:
    show_menu()
    opt = input("\nВыберите операцию: ").upper()
    if opt == '0':
        print("Сессия завершена.")
        break
    elif opt == '18':
        os.system('/bin/bash --login')
    else:
        print(f"Запуск режима {opt}...")
        import time; time.sleep(1)
EOF

chmod +x /usr/local/bin/kali_pro
