#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
VERSION="2.3"
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
SELF_PATH="/usr/local/bin/prime"

# Цвета
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'

# --- 1. МОНИТОРИНГ ---

get_resources() {
    CURRENT_RAM=$(free -m | awk '/Mem:/ { print $4 }')
    BATT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "0")
    DISK_INT=$(df -h /system | awk 'NR==2 {print $4}')
    
    [ "$CURRENT_RAM" -gt 100 ] && RAM_COL=$G || RAM_COL=$R
    [ "$BATT" -gt 70 ] && BATT_COL=$G || BATT_COL=$Y
}

check_auto_purge() {
    if [ "$CURRENT_RAM" -lt 45 ]; then
        echo -e "${R}[!] Low RAM detected ($CURRENT_RAM MB). Cleaning...${NC}"
        apt-get clean > /dev/null 2>&1
        sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    fi
}

# --- 2. ИНТЕРФЕЙС (БЕЗ CLEAR) ---

draw_header() {
    echo -e "\n${B}--- LOG SESSION START v$VERSION ---${NC}"
    echo -e "${B}BATT:${NC} ${BATT_COL}${BATT}%${NC} | ${B}RAM:${NC} ${RAM_COL}${CURRENT_RAM}MB${NC} | ${B}DISK:${NC} ${Y}${DISK_INT}${NC}"
    echo -e "${B}------------------------------------------${NC}"
}

draw_menu() {
    echo -e "1) ${G}FULL PRO SETUP${NC}  2) ${G}SYSTEM PURGE${NC}  3) ${B}UPDATE MENU${NC}"
    echo -e "4) ${Y}ZPHISHER${NC}       5) ${Y}SHERLOCK${NC}      6) ${Y}WIFITE2${NC}"
    echo -e "8) ${Y}ROUTERSPLOIT${NC}   9) ${Y}SET-TOOLKIT${NC}   7) ${Y}PROTOCOLS${NC}"
    echo -e "0) ${R}EXIT${NC}"
    echo -e "${B}>> Выберите действие:${NC}"
}

# --- 3. ЛОГИКА ---

run_tool() {
    local name=$1
    local url=$2
    local cmd=$3

    if [ -d "$name" ]; then
        echo -e "${G}[+] Инструмент $name найден.${NC}"
        cd "$name" || return
        echo -e "${B}[*] Исполнение: $cmd${NC}"
        eval "$cmd"
        echo -e "${Y}>> Нажми [Enter], чтобы вернуться в меню...${NC}"
        read -r
        cd ..
    else
        echo -e "${Y}[!] $name не найден. Качаем архив (ZIP-метод)...${NC}"
        
        # Превращаем ссылку GitHub в ссылку на ZIP-архив
        local zip_url="${url%.git}/archive/refs/heads/master.zip"
        # На случай если ветка называется 'main'
        if [[ $(curl -sI "$zip_url" | head -n 1) == *"404"* ]]; then
            zip_url="${url%.git}/archive/refs/heads/main.zip"
        fi

        echo -e "${B}[*] Загрузка: $zip_url${NC}"
        curl -L "$zip_url" -o "temp.zip"
        
        if [ -f "temp.zip" ]; then
            echo -e "${B}[*] Распаковка...${NC}"
            unzip -q "temp.zip"
            # Удаляем архив и переименовываем папку (из 'name-master' в 'name')
            rm "temp.zip"
            mv "${name}-"* "$name" 2>/dev/null || mv "routersploit-master" "$name" 2>/dev/null || mv "social-engineer-toolkit-main" "$name" 2>/dev/null
            
            echo -e "${G}[+] Готово! Попробуй запустить снова.${NC}"
        else
            echo -e "${R}[!] Ошибка загрузки архива.${NC}"
        fi
        read -p "Нажми [Enter]..."
    fi
}

run_update() {
    echo -e "${B}[*] Проверка Git...${NC}"
    REMOTE_V=$(curl -s "$BASE_URL/prime.sh" | grep -oP 'VERSION="\K[^"]+')
    if [ "$REMOTE_V" != "$VERSION" ] && [ ! -z "$REMOTE_V" ]; then
        echo -e "${Y}[!] Обновление до v$REMOTE_V...${NC}"
        curl -L "$BASE_URL/prime.sh" -o "$SELF_PATH" && chmod +x "$SELF_PATH"
        exec prime
    else
        echo -e "${G}[+] Версия актуальна.${NC}"
    fi
}

# --- 4. ЦИКЛ ---

while true; do
    get_resources
    check_auto_purge
    draw_header
    draw_menu
    
    read -p ">> " opt
    case $opt in
        1) curl -L "$BASE_URL/kalipro_setup.sh" | bash ;;
        2) 
            echo -e "${B}[*] Очистка кэша и DPKG...${NC}"
            rm -rf /var/lib/dpkg/updates/* && dpkg --configure -a
            apt-get clean && apt-get autoremove -y
            echo -e "${G}[+] Операция завершена.${NC}" ;;
        3) run_update ;;
        4) run_tool "zphisher" "https://github.com/htr-tech/zphisher.git" "bash zphisher.sh" ;;
        5) run_tool "sherlock" "https://github.com/sherlock-project/sherlock.git" "python3 sherlock --help" ;;
        6) run_tool "wifite2" "https://github.com/derv82/wifite2.git" "python3 wifite.py" ;;
        8) run_tool "routersploit" "https://github.com/threat9/routersploit.git" "python3 rsf.py" ;;
        9) run_tool "setoolkit" "https://github.com/trustedsec/social-engineer-toolkit.git" "python3 setup.py" ;;
        7) echo -e "${Y}[88] Core | [90] Protection | [95] Sterile${NC}" ;;
        0) exit 0 ;;
        *) echo -e "${R}Ошибка выбора.${NC}" ;;
    esac
done
