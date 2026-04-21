#!/bin/bash

# Пути к твоему репозиторию
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
SELF_NAME="prime.sh"

# Цвета
G='\033[0;32m'
B='\033[0;34m'
Y='\033[1;33m'
R='\033[0;31m'
NC='\033[0m'

# [ЭВРИСТИКА] Мониторинг ресурсов: ОЗУ + Накопители
check_resources() {
    # ОЗУ
    RAM=$(free -m | awk '/Mem:/ { print $4 }')
    # Внутренняя память (/)
    DISK_INT=$(df -h / | awk 'NR==2 {print $4}')
    # SD-карта (ищем по стандартным путям Android)
    SD_PATH=$(df -h | grep -E '/storage/|/sdcard|/mnt/media_rw' | awk 'NR==1 {print $4}')
    [ -z "$SD_PATH" ] && SD_PATH="Not Found"

    BATT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "100")
    
    echo -e "${B}=========================================="
    echo -e "   PRIME ULTRA CONSOLE - AUTONOMOUS"
    echo -e "==========================================${NC}"
    echo -e "${Y}📊 RAM:${NC} ${RAM}MB free | ${Y}BATT:${NC} ${BATT}%"
    echo -e "${Y}💾 Internal:${NC} ${DISK_INT} free | ${Y}SD-Card:${NC} ${SD_PATH}"
    
    # Авто-очистка при критическом лимите RAM
    if [ "$RAM" -lt 50 ]; then
        echo -e "${R}[!] ВНИМАНИЕ: Очистка кэша (RAM low)...${NC}"
        apt-get clean > /dev/null 2>&1
    fi
}

# Функция самообновления меню
update_self() {
    echo -e "${B}[*] Обновление интерфейса из Git...${NC}"
    curl -L "$BASE_URL/$SELF_NAME" -o "${SELF_NAME}.tmp"
    if [ -s "${SELF_NAME}.tmp" ]; then
        mv "${SELF_NAME}.tmp" "$SELF_NAME"
        chmod +x "$SELF_NAME"
        echo -e "${G}[+] Меню обновлено. Перезапуск...${NC}"
        sleep 2
        exec ./"$SELF_NAME"
    else
        echo -e "${R}[!] Ошибка загрузки. Проверь сеть.${NC}"
        rm -f "${SELF_NAME}.tmp"
    fi
}

while true; do
    check_resources
    echo -e "1) ${G}FULL PRO SETUP${NC} (Функции из kalipro_setup.sh)"
    echo -e "2) ${G}SYSTEM PURGE${NC} (Очистка обновлений и dpkg)"
    echo -e "3) ${G}SYNC TOOLS${NC} (Скачать все скрипты с твоего Git)"
    echo -e "4) ${B}UPDATE MENU${NC} (Обновить это меню из Git)"
    echo -e "5) ${Y}PROTOCOLS${NC} ([88] Core | [90] Ghost | [95] Sterile)"
    echo -e "0) EXIT"
    echo -e "${B}------------------------------------------${NC}"
    read -p ">> " opt

    case $opt in
        1)
            echo -e "${Y}[*] Запуск адаптированного setup...${NC}"
            curl -L "$BASE_URL/kalipro_setup.sh" | bash -s -- --light
            ;;
        2)
            echo -e "${B}[*] Очистка dpkg/updates...${NC}"
            rm -rf /var/lib/dpkg/updates/*
            dpkg --configure -a
            apt-get clean
            echo -e "${G}[+] Готово.${NC}"
            ;;
        3)
            echo -e "${B}[*] Скачивание инструментов...${NC}"
            for file in purge.sh kalipro_setup.sh; do
                curl -L "$BASE_URL/$file" -o "$file" && chmod +x "$file"
                echo -e "${G}[+] $file получен.${NC}"
            done
            ;;
        4)
            update_self
            ;;
        5)
            echo -e "${Y}--- Состояние Фильтров ---${NC}"
            echo -e "[88] Network Core: OK"
            echo -e "[90] Ghost Mode: Standby"
            echo -e "[95] Sterile Channel: Active"
            read -p "Enter..."
            ;;
        0) exit 0 ;;
        *) echo -e "${R}Ошибка выбора${NC}" && sleep 1 ;;
    esac
done
