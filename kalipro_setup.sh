#!/bin/bash

# VERSION 3.6 (Rescue & Sterile Edition)
CURRENT_VERSION="3.6"

TARGET_FILE="/usr/local/bin/kali_pro"
# Глобальные параметры стерильности
INSTALL_FLAGS="-y --no-install-recommends"
PROGRESS_OPTS="-o Dpkg::Progress-Fancy=1 -o APT::Color=1"
CLEAN_OPTS="-o DPkg::Post-Invoke={'apt-get clean';} -o APT::Keep-Downloaded-Packages=false"

create_files() {
    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=3.6
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOOT_DIR="$HOME/arsenal_loot"
mkdir -p "$LOOT_DIR"

# Локальные переменные внутри арсенала
INSTALL_FLAGS="-y --no-install-recommends"
PROGRESS_OPTS="-o Dpkg::Progress-Fancy=1 -o APT::Color=1"
CLEAN_OPTS="-o DPkg::Post-Invoke={'apt-get clean';} -o APT::Keep-Downloaded-Packages=false"

run_smart_check() {
    python3 -c "
import shutil
def get_status(path, label):
    try:
        total, used, free = shutil.disk_usage(path)
        def fmt(b):
            if b >= 1024**3: return f'{b/1024**3:.1f}G'
            return f'{b//1024**2}MB'
        status = '\033[0;32mOK' if free > (400*1024**2) else '\033[0;31mLOW'
        print(f'   \033[0;34m[ {label} ]:\033[0m {fmt(free)} / {fmt(total)} ({status}\033[0m)')
    except: pass
get_status('/', 'СИСТЕМА')
"
}

# --- FUNCTIONS v3.6 ---

smart_nmap() {
    read -p "IP: " t
    [[ -z "$t" ]] && return
    echo -e "${BLUE}[*] Эвристический скан: $t${NC}"
    nmap -sV --open "$t" | grep "open" | tee "$LOOT_DIR/nmap_$t.txt"
    read -p "Нажми Enter..."
}

smart_searchsploit() {
    read -p "Поиск: " q
    [[ -z "$q" ]] && return
    searchsploit "$q"
    read -p "ID для копирования (пусто - выход): " id
    if [[ -n "$id" ]]; then
        cd "$LOOT_DIR" && searchsploit -m "$id"
        echo -e "${GREEN}[+] Сохранено в трофеи.${NC}"
    fi
    read -p "Нажми Enter..."
}

smart_hydra() {
    read -p "IP: " t; read -p "User: " u; read -p "Proto: " p
    [[ -z "$t" || -z "$u" || -z "$p" ]] && return
    hydra -l "$u" -P /usr/share/wordlists/rockyou.txt "$t" "$p" -V | tee -a "$LOOT_DIR/brute.txt"
    read -p "Нажми Enter..."
}

smart_sqlmap() {
    read -p "URL: " u
    [[ -z "$u" ]] && return
    sqlmap -u "$u" --batch --random-agent --output-dir="$LOOT_DIR/sqlmap"
    read -p "Нажми Enter..."
}

smart_nikto() {
    read -p "Target URL/IP: " t
    [[ -z "$t" ]] && return
    echo -e "${BLUE}[*] Запуск Nikto Scan: $t${NC}"
    nikto -h "$t" | tee "$LOOT_DIR/nikto_$t.txt"
    read -p "Enter..."
}

smart_installer() {
    read -p "Пакет для установки: " pkg
    [[ -z "$pkg" ]] && return
    echo -e "${CYAN}[*] Стерильная установка: $pkg...${NC}"
    apt-get update -y >/dev/null 2>&1
    apt-get install $INSTALL_FLAGS $PROGRESS_OPTS $CLEAN_OPTS "$pkg"
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}[+] Готово.${NC}"
    sleep 1
}

clean_system() {
    echo -e "${CYAN}=== ГЛУБОКОЕ ОБСЛУЖИВАНИЕ (UPGRADE MODE) ===${NC}"
    apt-get update >/dev/null
    UPGRADES=$(apt-get upgrade -s | grep -P '^\d+ upgraded' | awk '{print $1}')
    if [[ "$UPGRADES" =~ ^[0-9]+$ ]] && [ "$UPGRADES" -gt 0 ]; then
        echo -e "${BLUE}[!] Обновлений: $UPGRADES. Запуск...${NC}"
        apt-get full-upgrade -y $PROGRESS_OPTS $CLEAN_OPTS
    else
        echo -e "${GREEN}[+] Обновления не требуются.${NC}"
    fi
    apt-get autoremove --purge -y >/dev/null
    apt-get clean
    echo -e "${GREEN}[+] Система оптимизирована.${NC}"
    sleep 2
}

deep_purge() {
    echo -e "${RED}=== ТОТАЛЬНАЯ ДЕЗИНФЕКЦИЯ (MAX-FORCE) ===${NC}"
    
    # 1. Жёсткая зачистка APT
    echo -e "${YELLOW}[*] Вычищаю индексы и архивы...${NC}"
    apt-get clean
    apt-get autoclean -y
    # Удаляем сами списки доступных пакетов (они скачаются заново при apt update)
    # Это может освободить 100-300 МБ
    rm -rf /var/lib/apt/lists/*
    
    # 2. Удаление кэша мануалов и документации
    echo -e "${YELLOW}[*] Удаляю документацию и кэш манов...${NC}"
    rm -rf /var/cache/man/*
    rm -rf /usr/share/doc/*
    rm -rf /usr/share/man/*
    
    # 3. Глубокая зачистка логов (включая скрытые)
    echo -e "${YELLOW}[*] Стираю все системные логи...${NC}"
    find /var/log -type f -delete 2>/dev/null
    find /var/cache -type f -delete 2>/dev/null
    
    # 4. Очистка кэша Python/Pip и локальных временных файлов
    echo -e "${YELLOW}[*] Удаляю кэш Python и временные файлы...${NC}"
    rm -rf ~/.cache/pip/*
    rm -rf ~/.cache/fontconfig/*
    rm -rf /tmp/*
    rm -rf /var/tmp/*
    
    # 5. Очистка твоих "Трофеев" (если они не нужны)
    rm -rf "$LOOT_DIR"/*
    
    # Финальный аккорд: принудительная очистка неиспользуемых библиотек
    apt-get autoremove --purge -y >/dev/null 2>&1

    echo -e "${GREEN}[+] DEEP PURGE завершен!${NC}"
    echo -ne "${BLUE}[!] Свободно сейчас: ${NC}"
    df -h / | awk 'NR==2 {print $4}'
    sleep 3
}

show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v3.6     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}-------------------------------------------${NC}"
    echo -e " ${BLUE}1.${NC} РЕМОНТ И ОБНОВЛЕНИЕ"
    echo -e " ${BLUE}2.${NC} NMAP          ${BLUE}3.${NC} SEARCHSPLOIT"
    echo -e " ${BLUE}4.${NC} HYDRA         ${BLUE}5.${NC} SQLMAP"
    echo -e " ${BLUE}6.${NC} BETTERCAP     ${BLUE}7.${NC} NIKTO"
    echo -e " ${BLUE}8.${NC} SMART INSTALLER"
    echo -e " ${RED}9. DEEP PURGE (СРОЧНАЯ ОЧИСТКА)${NC}"
    echo -e " ${RED}0.${NC} ВЫХОД"
    echo -e "${CYAN}===========================================${NC}"
}

# --- MAIN LOOP ---
while true; do
    show_menu
    read -p "Опция: " opt
    case $opt in
        1) clean_system ;;
        2) smart_nmap ;;
        3) smart_searchsploit ;;
        4) smart_hydra ;;
        5) smart_sqlmap ;;
        6) bettercap -eval "net.probe on; net.sniff on" ;;
        7) smart_nikto ;;
        8) smart_installer ;;
        9) deep_purge ;;
        0) exit 0 ;;
        *) sleep 1 ;;
    esac
done
EOF

    chmod +x "$TARGET_FILE"
    echo -e "\033[0;32m[+] v$CURRENT_VERSION Ultra-Precision развернута!${NC}"
}

# Логика обновления
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
