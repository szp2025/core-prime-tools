#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
VERSION="1.8"
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
SELF_PATH="/usr/local/bin/prime"

# Цвета для интерфейса
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'

# --- 1. МОНИТОРИНГ И ЭВРИСТИКА ---

get_resources() {
    # Получаем RAM и Батарею
    CURRENT_RAM=$(free -m | awk '/Mem:/ { print $4 }')
    BATT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "0")
    DISK_INT=$(df -h /system | awk 'NR==2 {print $4}')
    
    # Динамические цвета
    if [ "$CURRENT_RAM" -gt 100 ]; then RAM_COL=$G; elif [ "$CURRENT_RAM" -gt 55 ]; then RAM_COL=$Y; else RAM_COL=$R; fi
    if [ "$BATT" -gt 70 ]; then BATT_COL=$G; elif [ "$BATT" -gt 30 ]; then BATT_COL=$Y; else BATT_COL=$R; fi
}

check_auto_purge() {
    # Эвристика: если памяти критически мало (<45MB), принудительно сбрасываем кэш
    if [ "$CURRENT_RAM" -lt 45 ]; then
        apt-get clean > /dev/null 2>&1
        sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    fi
}

# --- 2. ИНТЕРФЕЙС ---

draw_header() {
    clear
    echo -e "${B}=========================================="
    echo -e "   PRIME ULTRA v$VERSION | BATT: ${BATT_COL}${BATT}%${NC}"
    echo -e "   RAM: ${RAM_COL}${CURRENT_RAM}MB${NC} | DISK: ${Y}${DISK_INT}${NC}"
    echo -e "==========================================${NC}"
}

draw_menu() {
    echo -e "1) ${G}FULL PRO SETUP${NC}  - Запуск kalipro_setup.sh"
    echo -e "2) ${G}SYSTEM PURGE${NC}    - Глубокая очистка RAM/DPKG"
    echo -e "3) ${B}UPDATE MENU${NC}     - Проверить обновление v$VERSION"
    echo -e "------------------------------------------"
    echo -e "4) ${Y}ZPHISHER${NC}       - Запуск/Установка фишинга"
    echo -e "5) ${Y}SHERLOCK${NC}       - Запуск/Установка OSINT"
    echo -e "6) ${Y}WIFITE2${NC}        - Запуск/Установка аудита"
    echo -e "7) ${Y}PROTOCOLS${NC}      - Статус [88]|[90]|[95]"
    echo -e "8) ${Y}ROUTERSPLOIT${NC}   - Эксплуатация роутеров"
    echo -e "9) ${Y}SET-TOOLKIT${NC}    - Social Engineering"
    echo -e "0) ${R}EXIT${NC}"
    echo -e "${B}------------------------------------------${NC}"
}

# --- 3. ЛОГИКА ИНСТРУМЕНТОВ ---

run_tool() {
    local name=$1
    local url=$2
    local cmd=$3

    if [ -d "$name" ]; then
        echo -e "${G}[+] Запуск $name...${NC}"
        cd "$name" || return
        eval "$cmd"
        cd ..
        echo -e "${B}[*] Возврат в меню...${NC}"
        sleep 2
    else
        echo -e "${Y}[!] $name не найден. Установить? (y/n)${NC}"
        read -p ">> " confirm
        if [[ $confirm == [yY] ]]; then
            echo -e "${B}[*] Клонирование (depth 1 для экономии RAM)...${NC}"
            git clone --depth 1 "$url" "$name"
            echo -e "${G}[+] Готово. Теперь запустите еще раз.${NC}"
            sleep 2
        fi
    fi
}

run_update() {
    echo -e "${B}[*] Проверка версии на GitHub...${NC}"
    REMOTE_V=$(curl -s "$BASE_URL/prime.sh" | grep -oP 'VERSION="\K[^"]+')
    
    if [ -z "$REMOTE_V" ]; then
        echo -e "${R}[!] Ошибка сети.${NC}"
    elif [ "$REMOTE_V" != "$VERSION" ]; then
        echo -e "${Y}[!] Найдена v$REMOTE_V. Обновляемся...${NC}"
        curl -L "$BASE_URL/prime.sh" -o "$SELF_PATH" && chmod +x "$SELF_PATH"
        echo -e "${G}[+] Перезапуск...${NC}"
        sleep 1
        exec prime
    else
        echo -e "${G}[+] У вас актуальная версия.${NC}"
    fi
    sleep 1
}

# --- 4. ГЛАВНЫЙ ЦИКЛ ---

while true; do
    get_resources
    check_auto_purge
    draw_header
    draw_menu
    
    read -p ">> " opt
    case $opt in
        1) curl -L "$BASE_URL/kalipro_setup.sh" | bash ;;
        2) 
            echo -e "${B}[*] Исправление DPKG и очистка...${NC}"
            rm -rf /var/lib/dpkg/updates/* && dpkg --configure -a
            apt-get clean && apt-get autoremove -y
            echo -e "${G}[+] Завершено.${NC}"
            sleep 1 ;;
        3) run_update ;;
        4) run_tool "zphisher" "https://github.com/htr-tech/zphisher.git" "bash zphisher.sh" ;;
        5) run_tool "sherlock" "https://github.com/sherlock-project/sherlock.git" "python3 sherlock --help" ;;
        6) run_tool "wifite2" "https://github.com/derv82/wifite2.git" "python3 wifite.py" ;;
        7) 
            echo -e "${Y}--- СТАТУС ФИЛЬТРОВ ---${NC}"
            echo -e "[88] Network Core: ACTIVE"
            echo -e "[90] Active City Protection: GHOST"
            echo -e "[95] Sterile Channel: READY"
            read -p "Нажми Enter..." ;;
      8) run_tool "routersploit" "https://github.com/threat9/routersploit.git" "python3 rsf.py" ;;
      9) run_tool "setoolkit" "https://github.com/trustedsec/social-engineer-toolkit.git" "python3 setup.py install && setoolkit" ;;
        0) echo "Выход из Prime Ultra..."; exit 0 ;;
        *) echo -e "${R}Неверный выбор${NC}"; sleep 1 ;;
    esac
done
