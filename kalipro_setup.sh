#!/bin/bash

# Текущая версия инструментов в этом установщике
CURRENT_VERSION="1.0"
TARGET_FILE="$HOME/kali_pro.sh"

echo -e "\033[0;36m[*] Проверка компонентов Kali Pro Arsenal...\033[0m"

# Функция создания основного меню
create_kali_pro() {
    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=1.0

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU          ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${BLUE}1.${NC} БЫСТРАЯ ОЧИСТКА (Free Space)"
    echo -e "${BLUE}2.${NC} СЕТЕВОЙ СКАНЕР (Nmap)"
    echo -e "${BLUE}3.${NC} ПОИСК ЭКСПЛОЙТОВ (Searchsploit)"
    echo -e "${BLUE}4.${NC} ВЗЛОМ ПАРОЛЕЙ (John / Hydra)"
    echo -e "${BLUE}5.${NC} ВЕБ-АНАЛИЗ (Sqlmap / Commix)"
    echo -e "${BLUE}6.${NC} ПЕРЕХВАТ (Bettercap / Ettercap)"
    echo -e "${BLUE}7.${NC} ПРОВЕРИТЬ МЕСТО (df -h)"
    echo -e "${RED}0.${NC} ВЫХОД"
    echo -e "${CYAN}===========================================${NC}"
}

clean_system() {
    echo -e "${GREEN}[*] Начинаю глубокую очистку...${NC}"
    apt-get clean && apt-get autoclean && apt-get autoremove -y
    rm -rf /var/cache/apt/archives/* /tmp/* /var/tmp/*
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/*
    echo -e "${GREEN}[+] Очистка завершена! Состояние памяти:${NC}"
    
    # Твое добавление:
    df -h /
    echo -e "${CYAN}Пауза 20 секунд для анализа...${NC}"
    sleep 20
}

while true; do
    show_menu
    read -p "Выбери опцию: " opt
    case $opt in
        1) clean_system ;;
        2) nmap ;;
        3) read -p "Что ищем? " s; searchsploit $s ;;
        4) echo -e "${BLUE}Доступно: john, hydra, hashcat${NC}"; sleep 2 ;;
        5) echo -e "${BLUE}Доступно: sqlmap, nikto, commix${NC}"; sleep 2 ;;
        6) bettercap ;;
        7) df -h / ; read -p "Enter..." ;;
        0) exit 0 ;;
        *) echo -e "${RED}Ошибка!${NC}"; sleep 1 ;;
    esac
done
EOF
    chmod +x "$TARGET_FILE"
    echo -e "\033[0;32m[+] Файл $TARGET_FILE создан/обновлен.\033[0m"
}

# Логика обновления
if [ ! -f "$TARGET_FILE" ]; then
    echo -e "\033[0;33m[!] Файл не найден. Установка...\033[0m"
    create_kali_pro
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        echo -e "\033[0;34m[*] Найдена новая версия ($CURRENT_VERSION). Обновление...\033[0m"
        create_kali_pro
    else
        echo -e "\033[0;32m[+] У вас уже установлена актуальная версия ($INSTALLED_VERSION).\033[0m"
    fi
fi
