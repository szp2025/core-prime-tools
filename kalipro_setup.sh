#!/bin/bash

# VERSION 2.7
CURRENT_VERSION="2.7"

TARGET_FILE="/usr/local/bin/kali_pro"
UPDATE_SCRIPT="/usr/local/bin/update_kali"
REPO_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/kalipro_setup.sh"

echo -e "\033[0;36m[*] Kali Pro Arsenal v$CURRENT_VERSION\033[0m"

create_files() {
    echo -e "\033[0;33m[*] Обновление файлов...\033[0m"

    # Основной файл
    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=2.7
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

run_smart_check() {
    python3 -c "
import shutil
def get_status(path, label):
    try:
        total, used, free = shutil.disk_usage(path)
        def fmt(b):
            if b >= 1024**3: return f'{b/1024**3:.1f}G'
            return f'{b//1024**2}MB'
        status = '\033[0;32mOK' if free > (500*1024**2) else '\033[0;31mLOW'
        print(f'   \033[0;34m[ {label} ]:\033[0m {fmt(free)} / {fmt(total)} ({status}\033[0m)')
    except: pass
get_status('/', 'СИСТЕМА')
get_status('/sdcard', 'ПАМЯТЬ ТЕЛЕФОНА')
"
}

show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v2.7     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}-------------------------------------------${NC}"
    echo -e "${BLUE}1.${NC} БЫСТРАЯ ОЧИСТКА"
    echo -e "${BLUE}2.${NC} СЕТЕВОЙ СКАНЕР (Smart Nmap)"
    echo -e "${BLUE}3.${NC} ПОИСК ЭКСПЛОЙТОВ (Searchsploit)"
    echo -e "${BLUE}4.${NC} ВЗЛОМ ПАРОЛЕЙ (Hydra)"
    echo -e "${BLUE}5.${NC} ВЕБ-АНАЛИЗ (SQLmap)"
    echo -e "${BLUE}6.${NC} ПЕРЕХВАТ (Bettercap)"
    echo -e "${RED}0.${NC} ВЫХОД"
    echo -e "${CYAN}===========================================${NC}"
}

# --- ФУНКЦИИ ---
clean_system() { echo -e "${GREEN}[*] Очистка...${NC}"; apt-get clean && apt-get autoclean -y; sleep 1; }
smart_nmap() { read -p "Цель: " t; [[ -z "$t" ]] && return; nmap -sV -sC -O --script vulners --open "$t"; read -p "Enter..."; }
smart_searchsploit() { read -p "Поиск: " q; searchsploit "$q"; read -p "ID: " id; [[ -n "$id" ]] && { mkdir -p ~/arsenal_exploits; cd ~/arsenal_exploits; searchsploit -m "$id"; }; }
smart_brute() { read -p "IP: " t; read -p "User: " u; read -p "Proto: " p; hydra -l $u -P /usr/share/wordlists/rockyou.txt $t $p -V; }
smart_web_scan() { read -p "URL: " u; sqlmap -u "$u" --batch --random-agent; }
smart_bettercap() { bettercap; }

START_TIME=$(date +"%H:%M:%S")
while true; do
    show_menu
    read -p "[Start: $START_TIME] Опция: " opt
    case $opt in
        1) clean_system ;;
        2) smart_nmap ;;
        3) smart_searchsploit ;;
        4) smart_brute ;;
        5) smart_web_scan ;;
        6) smart_bettercap ;;
        0) exit 0 ;;
        *) sleep 1 ;;
    esac
done
EOF

    # ИСПРАВЛЕННЫЙ СКРИПТ ОБНОВЛЕНИЯ
    # Мы выносим URL в переменную, чтобы Bash не ломался при записи
    cat << EOF > "$UPDATE_SCRIPT"
#!/bin/bash
echo -e "\033[0;34m[*] Обновление арсенала...\033[0m"
curl -L "$REPO_URL" | bash
EOF

    chmod +x "$TARGET_FILE"
    chmod +x "$UPDATE_SCRIPT"
    echo -e "\033[0;32m[+] Успешно обновлено до v$CURRENT_VERSION\033[0m"
}

# Проверка версии
if [ ! -f "$TARGET_FILE" ]; then
    create_files
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        create_files
    else
        echo -e "\033[0;32m[+] Версия актуальна ($INSTALLED_VERSION).\033[0m"
    fi
fi
