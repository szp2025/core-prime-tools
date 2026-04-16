#!/bin/bash

# VERSION 3.3 (Ultra-Precision)
CURRENT_VERSION="3.3"

TARGET_FILE="/usr/local/bin/kali_pro"
UPDATE_SCRIPT="/usr/local/bin/update_kali"
REPO_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/kalipro_setup.sh"

create_files() {
    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=3.3
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOOT_DIR="$HOME/arsenal_loot"
mkdir -p "$LOOT_DIR"

# Конфигурация APT для конвейерной очистки (удаляет .deb сразу после установки пакета)
CLEAN_OPTS="-o DPkg::Post-Invoke={'apt-get clean';} -o APT::Keep-Downloaded-Packages=false"
PROGRESS_OPTS="-o Dpkg::Progress-Fancy=1 -o APT::Color=1"

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

# --- SMART INSTALLER v3.3 (СТЕРИЛЬНЫЙ КОНВЕЙЕР) ---
smart_installer() {
    read -p "Пакет для установки: " pkg
    [[ -z "$pkg" ]] && return
    
    echo -e "${CYAN}[*] Установка с конвейерной зачисткой: $pkg...${NC}"
    dpkg --configure -a >/dev/null 2>&1
    
    # Установка с хуком на мгновенную очистку после каждого шага dpkg
    apt-get install -y $PROGRESS_OPTS $CLEAN_OPTS "$pkg"
    
    # Финальная полировка
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}[+] Пакет установлен. Хвосты зачищены.${NC}"
    sleep 1
}

# --- AUTO-MAINTENANCE v3.3 (ЭВРИСТИЧЕСКОЕ ОБНОВЛЕНИЕ) ---
clean_system() {
    echo -e "${CYAN}=== ГЛУБОКОЕ ОБСЛУЖИВАНИЕ (PRECISION MODE) ===${NC}"
    
    echo -e "${YELLOW}[*] Проверка наличия обновлений...${NC}"
    apt-get update >/dev/null
    UPGRADES=$(apt-get upgrade -s | grep -P '^\d+ upgraded' | cut -d' ' -f1)
    
    if [ "$UPGRADES" -gt 0 ]; then
        echo -e "${BLUE}[!] Найдено обновлений: $UPGRADES. Запуск конвейера...${NC}"
        # Обновляем каждый пакет и сразу стираем его архив
        apt-get full-upgrade -y $PROGRESS_OPTS $CLEAN_OPTS
    else
        echo -e "${GREEN}[+] Все пакеты актуальны. Обновление не требуется.${NC}"
    fi

    echo -e "${YELLOW}[*] Тотальная дезинфекция системы...${NC}"
    apt-get autoremove --purge -y >/dev/null
    rm -rf /tmp/* /var/tmp/*
    find $HOME -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    find $HOME -name "*.log" -type f -delete 2>/dev/null
    
    # Сверхбыстрая очистка трофеев
    rm -rf "$LOOT_DIR"/*
    history -c
    
    echo -e "${GREEN}[+] Система стерильна и оптимизирована!${NC}"
    sleep 2
}

show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v3.3     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}-------------------------------------------${NC}"
    echo -e "${BLUE}1.${NC} КОНВЕЙЕРНЫЙ РЕМОНТ И ЧИСТКА"
    echo -e "${BLUE}2.${NC} SMART NMAP"
    echo -e "${BLUE}3.${NC} SEARCHSPLOIT"
    echo -e "${BLUE}4.${NC} HYDRA"
    echo -e "${BLUE}5.${NC} SQLMAP"
    echo -e "${BLUE}6.${NC} BETTERCAP"
    echo -e "${BLUE}7.${NC} SMART INSTALLER (Sterile Flow)"
    echo -e "${RED}0.${NC} ВЫХОД"
    echo -e "${CYAN}===========================================${NC}"
}

# --- CASE LOOP ---
while true; do
    show_menu
    read -p "Опция: " opt
    case $opt in
        1) clean_system ;;
        2) read -p "IP: " t; [[ -n "$t" ]] && nmap -sV --open "$t" | grep "open" | tee "$LOOT_DIR/nmap_$t.txt"; read -p ".." ;;
        3) read -p "Q: " q; searchsploit "$q"; read -p "ID: " id; [[ -n "$id" ]] && { cd "$LOOT_DIR"; searchsploit -m "$id"; }; read -p ".." ;;
        4) read -p "IP: " t; read -p "U: " u; read -p "P: " p; hydra -l $u -P /usr/share/wordlists/rockyou.txt $t $p -V; read -p ".." ;;
        5) read -p "URL: " u; [[ -n "$u" ]] && sqlmap -u "$u" --batch --random-agent --output-dir="$LOOT_DIR/sqlmap"; read -p ".." ;;
        6) LFILE="$LOOT_DIR/bettercap_loot.txt"
           bettercap -eval "set net.sniff.output $LFILE; net.probe on; net.sniff on" ;;
        7) smart_installer ;;
        0) exit 0 ;;
        *) sleep 1 ;;
    esac
done
EOF

    chmod +x "$TARGET_FILE"
    echo -e "\033[0;32m[+] v$CURRENT_VERSION Ultra-Precision развернута!${NC}"
}

# Логика обновления файлов самого скрипта
if [ ! -f "$TARGET_FILE" ]; then
    create_files
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        create_files
    else
        echo -e "\033[0;32m[+] Файлы арсенала актуальны ($INSTALLED_VERSION).${NC}"
    fi
fi
