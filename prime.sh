#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
VERSION="1.7"
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
SELF_PATH="/usr/local/bin/prime"

# Цвета
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'

# --- ФУНКЦИИ МОНИТОРИНГА ---

get_resources() {
    CURRENT_RAM=$(free -m | awk '/Mem:/ { print $4 }')
    BATT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "0")
    
    # Цвет RAM
    if [ "$CURRENT_RAM" -gt 100 ]; then RAM_COL=$G; elif [ "$CURRENT_RAM" -gt 55 ]; then RAM_COL=$Y; else RAM_COL=$R; fi
    # Цвет Батареи
    if [ "$BATT" -gt 70 ]; then BATT_COL=$G; elif [ "$BATT" -gt 30 ]; then BATT_COL=$Y; else BATT_COL=$R; fi
}

check_auto_purge() {
    # Если RAM ниже 45, чистим молча
    if [ "$CURRENT_RAM" -lt 45 ]; then
        apt-get clean > /dev/null 2>&1
        sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    fi
}

# --- ФУНКЦИИ ИНТЕРФЕЙСА ---

draw_header() {
    clear
    echo -e "${B}=========================================="
    echo -e "   PRIME ULTRA v$VERSION | BATT: ${BATT_COL}${BATT}%${NC}"
    echo -e "   RAM: ${RAM_COL}${CURRENT_RAM}MB${NC} | STATUS: $([ "$CURRENT_RAM" -lt 50 ] && echo -e "${R}LOW${NC}" || echo -e "${G}OK${NC}")"
    echo -e "==========================================${NC}"
}

draw_menu() {
    echo -e "1) ${G}PRO SETUP${NC}  - Запуск kalipro_setup"
    echo -e "2) ${G}PURGE${NC}      - Глубокая очистка"
    echo -e "3) ${B}UPDATE${NC}     - Проверка версии Git"
    echo -e "4) ${Y}PROTOCOLS${NC}  - Состояние [88]|[90]|[95]"
    echo -e "0) ${R}EXIT${NC}"
    echo -e "${B}------------------------------------------${NC}"
}

# --- ЛОГИКА КОМАНД ---

run_setup() {
    echo -e "${Y}[*] Запуск адаптированного setup...${NC}"
    curl -L "$BASE_URL/kalipro_setup.sh" | bash
    read -p "Нажми Enter..."
}

run_purge() {
    echo -e "${B}[*] Очистка системы...${NC}"
    rm -rf /var/lib/dpkg/updates/* && dpkg --configure -a
    apt-get clean && apt-get autoremove -y
    echo -e "${G}[+] Чисто.${NC}"
    sleep 1
}

run_update() {
    echo -e "${B}[*] Проверка обновлений...${NC}"
    REMOTE_V=$(curl -s "$BASE_URL/prime.sh" | grep -oP 'VERSION="\K[^"]+')
    if [ "$REMOTE_V" != "$VERSION" ] && [ ! -z "$REMOTE_V" ]; then
        echo -e "${Y}[!] Доступна v$REMOTE_V. Обновляем...${NC}"
        curl -L "$BASE_URL/prime.sh" -o "$SELF_PATH" && chmod +x "$SELF_PATH"
        exec prime
    else
        echo -e "${G}[+] Актуально.${NC}"
        sleep 1
    fi
}

# --- ОСНОВНОЙ ЦИКЛ ---

while true; do
    get_resources
    check_auto_purge
    draw_header
    draw_menu
    
    read -p ">> " opt
    case $opt in
        1) run_setup ;;
        2) run_purge ;;
        3) run_update ;;
        4) echo "Протоколы активны."; sleep 1 ;;
        0) break ;;
        *) echo "Ошибка"; sleep 1 ;;
    esac
done
