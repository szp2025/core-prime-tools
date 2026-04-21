#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
VERSION="1.5"  # Текущая версия
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
SELF_PATH="/usr/local/bin/prime"
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'

check_resources() {
    RAM=$(free -m | awk '/Mem:/ { print $4 }')
    BATT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "100")
    
    # Эвристика: если памяти критически мало, чистим не дожидаясь выбора пользователя
    if [ "$RAM" -lt 50 ]; then
        # Тихая очистка кэша пакетов и временных файлов
        apt-get clean > /dev/null 2>&1
        sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    fi

    DISK_INT=$(df -h /system | awk 'NR==2 {print $4}')
    
    # Упрощаем вывод для экономии места на экране Wiko
    echo -e "${B}=========================================="
    echo -e "   PRIME ULTRA CONSOLE v$VERSION - ADAPTED"
    echo -e "==========================================${NC}"
    echo -e "📊 ${Y}RAM:${NC} ${RAM}MB (Low) | ${Y}BATT:${NC} ${BATT}%"
    echo -e "💾 ${Y}Sys:${NC} ${DISK_INT} free | ${Y}SD:${NC} ${R}Hidden${NC}"
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
    # Обновляем данные ОЗУ перед каждым циклом
    CURRENT_RAM=$(free -m | awk '/Mem:/ { print $4 }')
    
    # Цвет индикатора памяти (Зеленый > 100, Желтый > 60, Красный < 60)
    if [ "$CURRENT_RAM" -gt 100 ]; then RAM_COL=$G; elif [ "$CURRENT_RAM" -gt 60 ]; then RAM_COL=$Y; else RAM_COL=$R; fi

    clear
    echo -e "${B}=========================================="
    echo -e "   PRIME ULTRA v$VERSION | RAM: ${RAM_COL}${CURRENT_RAM}MB${NC}"
    echo -e "==========================================${NC}"
    echo -e "1) ${G}PRO SETUP${NC}  2) ${G}PURGE${NC}  3) ${B}UPDATE${NC}"
    echo -e "4) ${Y}PROTOCOLS${NC} ([88]|[90]|[95])"
    echo -e "0) EXIT"
    echo -e "${B}------------------------------------------${NC}"
    
    # Эвристика: Авто-очистка если совсем мало памяти
    if [ "$CURRENT_RAM" -lt 45 ]; then
        apt-get clean > /dev/null 2>&1
        echo -e "${R}[!] RAM CRITICAL: Auto-cleaned cache.${NC}"
    fi

    read -p ">> " opt
    # ... остальная логика кейсов ...
done
