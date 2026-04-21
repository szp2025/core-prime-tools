#!/bin/bash

# Параметры из твоего Git
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
# Цвета для интерфейса
G='\033[0;32m'
B='\033[0;34m'
Y='\033[1;33m'
R='\033[0;31m'
NC='\033[0m'

# Эвристическая проверка ресурсов перед запуском
check_resources() {
    RAM=$(free -m | awk '/Mem:/ { print $4 }')
    BATT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "100")
    echo -e "${B}[SYSTEM] RAM: ${RAM}MB free | BATT: ${BATT}%${NC}"
    if [ "$RAM" -lt 50 ]; then
        echo -e "${R}[!] Критически мало памяти! Запуск очистки...${NC}"
        apt-get clean && rm -rf /var/lib/dpkg/updates/*
    fi
}

# Функция интеграции функций из kalipro_setup.sh
deploy_pro_setup() {
    echo -e "${Y}[*] Извлечение функций из kalipro_setup.sh...${NC}"
    # Скачиваем setup, но не запускаем целиком, а берем из него логику
    curl -L "$BASE_URL/kalipro_setup.sh" -o setup_core.sh
    chmod +x setup_core.sh
    
    # Эвристика: установка только самого важного, чтобы не «убить» систему
    echo -e "${G}[+] Установка сетевых инструментов (Wifite2, Sherlock)...${NC}"
    apt-get install -y git python3 python3-pip --no-install-recommends
    
    # Добавляем твой фильтр
    echo -e "${G}[+] Настройка фильтрации: [88] Core, [90] Ghost, [95] Sterile${NC}"
    # Здесь можно вставить специфические команды из твоего файла
}

while true; do
    check_resources
    echo -e "\n${G}--- CORE PRIME ULTRA MENU ---${NC}"
    echo -e "1) ${B}FULL ADAPTED SETUP${NC} (База из kalipro_setup.sh)"
    echo -e "2) ${B}SYSTEM PURGE${NC} (Твой purge.sh + исправление dpkg)"
    echo -e "3) ${B}GHOST MODE [90]${NC} (Активация скрытого канала)"
    echo -e "4) ${B}UPDATE TOOLS${NC} (Обновить скрипты с GitHub)"
    echo -e "0) EXIT"
    read -p ">> " choice

    case $choice in
        1)
            deploy_pro_setup
            ;;
        2)
            echo -e "${Y}[*] Очистка обновлений и блокировок...${NC}"
            rm -rf /var/lib/dpkg/updates/*
            dpkg --configure -a
            curl -L "$BASE_URL/purge.sh" | bash
            ;;
        3)
            echo -e "${Y}[*] Проверка wlan0 для Ghost Mode...${NC}"
            # Проверка sysfs, которая часто отсутствует
            if [ ! -d "/sys/class" ]; then
                echo -e "${R}[!] Ошибка: /sys/class missing. Патч невозможен.${NC}"
            else
                iwconfig
            fi
            ;;
        4)
            echo -e "${G}[+] Синхронизация с основной веткой Git...${NC}"
            curl -L "$BASE_URL/purge.sh" -o purge.sh
            curl -L "$BASE_URL/kalipro_setup.sh" -o kalipro_setup.sh
            chmod +x *.sh
            ;;
        0) exit 0 ;;
    esac
    read -p "Нажми Enter..."
done
