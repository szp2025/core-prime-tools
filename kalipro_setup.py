cat << 'EOF' > /usr/local/bin/kali_pro
#!/bin/bash
# VERSION=8.5.6

# --- ЦВЕТА И НАСТРОЙКИ ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m'

LOOT_DIR="$HOME/arsenal_loot"
mkdir -p "$LOOT_DIR"

# --- СИСТЕМНЫЕ ФУНКЦИИ ---
run_smart_check() {
    pgrep cron > /dev/null || cron &>/dev/null
    apt-get clean >/dev/null 2>&1
    python3 << 'EOF'
import shutil
def get_status(path, label):
    try:
        total, used, free = shutil.disk_usage(path)
        fmt = lambda b: f'{b/1024**3:.1f}G'
        status = '\033[0;32mOK' if free > (350*1024*1024) else '\033[0;31mLOW'
        print(f'   \033[0;34m[ {label} ]:\033[0m {fmt(free)} / {fmt(total)} ({status}\033[0m)')
    except: pass
get_status('/', 'СИСТЕМА')
EOF
}


# --- ВКЛЮЧАЕМ ВСЕ ТВОИ МОДУЛИ (OSINT, WEB, WIFI и т.д.) ---
# [Здесь подразумеваются все твои функции: flow_total_recon, flow_web_stack, smart_nmap и т.д.]
# Ниже приведен исправленный цикл управления:

show_menu() {
    clear
    echo -e "${CYAN}┌───────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}    AUTONOMOUS SAMSUNG CORE v8.5.5    ${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────┘${NC}"
    
    run_smart_check

    echo -e "${YELLOW} [ AUTONOMOUS OPERATIONS ]${NC}"
    echo -e " ${CYAN}A.${NC} TOTAL RECON   ${GRAY}- OSINT & Analyt${NC}"
    echo -e " ${CYAN}B.${NC} WEB ATTACK    ${GRAY}- Scan & Exploit${NC}"
    echo -e " ${CYAN}C.${NC} NET GUARDIAN  ${GRAY}- Sniff & Conn${NC}"
    echo -e " ${CYAN}D.${NC} STERILIZER    ${GRAY}- Ghost & Clean${NC}"
    echo -e " ${CYAN}E.${NC} WIRELESS      ${GRAY}- WiFi & BT-HID${NC}"

    echo -e "\n${GREEN} [ INTERFACE ]${NC}"
    printf "  %-18s %-18s\n" "18. TERMINAL" "0. EXIT"
    echo -e "\n${CYAN}─────────────────────────────────────────────${NC}"
}

# Вставь сюда все остальные функции из своего Bash-скрипта (trust_analyzer_unified, flow_antivirus_scan и т.д.)
# Я сокращаю для краткости, но при запуске используй свой полный набор функций.

# --- ГЛАВНЫЙ ЦИКЛ ---
while true; do
    show_menu
    read -p "Выберите операцию: " opt
    case $opt in
        A|a) 
             echo "Запуск Recon..." ; sleep 1 ;;
        B|b) 
             echo "Запуск Web Attack..." ; sleep 1 ;;
        C|c) # <--- Здесь добавлена пропущенная скобка
             echo "Запуск Sniffer..." ; sleep 1 ;;
        D|d) 
             echo "Запуск Sterilizer..." ; sleep 1 ;;
        E|e) 
             echo "Запуск Wireless..." ; sleep 1 ;;
        18) 
            clear
            echo -e "${BLUE}[*] Вход в Root Shell. Введите 'exit' для возврата в Арсенал.${NC}"
            /bin/bash --login
            ;;
        0) 
            clear
            echo -e "${RED}[!] Сессия завершена. Возврат в root@kali.${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}[!] Ошибка. Доступны только режимы A, B, C, D, E, 18 или 0.${NC}"
            sleep 1 
            ;;
    esac
done

EOF

chmod +x /usr/local/bin/kali_pro
echo "Готово. Напиши 'kali_pro' для запуска."
