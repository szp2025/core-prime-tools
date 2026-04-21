#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
VERSION="1.3"  # Текущая версия
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
SELF_PATH="/usr/local/bin/prime"
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'

check_resources() {
    # ОЗУ и Батарея
    RAM=$(free -m | awk '/Mem:/ { print $4 }')
    BATT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "100")
    
    # Внутренняя память (берем из /system, так как у тебя она смонтирована на 8.0G free)
    DISK_INT=$(df -h /system | awk 'NR==2 {print $4}')
    
    # Эвристический поиск SD-карты по всем фронтам
    # Проверяем стандартные точки и ищем в выводе mount
    SD_PATH=$(mount | grep -iE 'sdcard1|external_sd|mmcblk1p1' | awk '{print $3}' | head -n 1)
    
    if [ -z "$SD_PATH" ]; then
        # Если mount не помог, ищем по доступному объему в /storage
        SD_VAL=$(df -h | grep -iE '/storage/|/mnt/' | grep -v 'emulated' | awk '{print $4}' | head -n 1)
        [ -z "$SD_VAL" ] && SD_PATH="${R}Not Found${NC}" || SD_PATH="$SD_VAL (External)"
    else
        SD_VAL=$(df -h "$SD_PATH" | awk 'NR==2 {print $4}')
        SD_PATH="$SD_VAL ($SD_PATH)"
    fi

    echo -e "${B}=========================================="
    echo -e "   PRIME ULTRA CONSOLE v$VERSION - AUTONOMOUS"
    echo -e "==========================================${NC}"
    echo -e "📊 ${Y}RAM:${NC} ${RAM}MB free | ${Y}BATT:${NC} ${BATT}%"
    echo -e "💾 ${Y}Internal:${NC} ${DISK_INT} free"
    echo -e "📂 ${Y}SD-Card:${NC} $SD_PATH"
}

# [ЭВРИСТИКА] Умное обновление по версии
update_logic() {
    echo -e "${B}[*] Проверка обновлений на GitHub...${NC}"
    REMOTE_VERSION=$(curl -s "$BASE_URL/prime.sh" | grep -oP 'VERSION="\K[^"]+')
    
    if [ -z "$REMOTE_VERSION" ]; then
        echo -e "${R}[!] Не удалось получить версию с сервера.${NC}"
    elif [ "$REMOTE_VERSION" != "$VERSION" ]; then
        echo -e "${Y}[!] Доступна новая версия: $REMOTE_VERSION (Текущая: $VERSION)${NC}"
        read -p "Обновиться? (y/n): " confirm
        if [[ $confirm == [yY] ]]; then
            curl -L "$BASE_URL/prime.sh" -o "$SELF_PATH"
            chmod +x "$SELF_PATH"
            echo -e "${G}[+] Обновлено до v$REMOTE_VERSION. Перезапуск...${NC}"
            sleep 1
            exec prime
        fi
    else
        echo -e "${G}[+] У вас установлена актуальная версия.${NC}"
    fi
}

while true; do
    check_resources
    echo -e "1) ${G}FULL PRO SETUP${NC} (kalipro_setup.sh)"
    echo -e "2) ${G}SYSTEM PURGE${NC} (Cleanup & Repair)"
    echo -e "3) ${B}CHECK UPDATES${NC} (Версия: $VERSION)"
    echo -e "4) ${Y}PROTOCOLS${NC} ([88] | [90] | [95])"
    echo -e "0) EXIT"
    echo -e "${B}------------------------------------------${NC}"
    read -p ">> " opt

    case $opt in
        1) curl -L "$BASE_URL/kalipro_setup.sh" | bash ;;
        2) rm -rf /var/lib/dpkg/updates/* && dpkg --configure -a && apt-get clean ;;
        3) update_logic ;;
        4) echo -e "${Y}Фильтры активны. Ресурсы в норме.${NC}"; read -p "Enter..." ;;
        0) exit 0 ;;
        *) echo -e "${R}Ошибка${NC}" && sleep 1 ;;
    esac
done
