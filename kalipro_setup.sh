#!/bin/bash

# Текущая версия инструментов в репозитории
CURRENT_VERSION="1.1"

# Пути к системным командам
TARGET_FILE="/usr/local/bin/kali_pro"
UPDATE_SCRIPT="/usr/local/bin/update_kali"

echo -e "\033[0;36m[*] Проверка версии Kali Pro Arsenal...\033[0m"

create_files() {
    echo -e "\033[0;33m[*] Установка/Обновление компонентов до версии $CURRENT_VERSION...\033[0m"

    # 1. Создаем основное меню
    cat << EOF > "$TARGET_FILE"
#!/bin/bash
# VERSION=$CURRENT_VERSION
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "\${CYAN}===========================================\${NC}"
    echo -e "\${GREEN}      KALI SAMSUNG ARSENAL - MENU          \${NC}"
    echo -e "\${CYAN}===========================================\${NC}"
    echo -e "\${BLUE}1.\${NC} БЫСТРАЯ ОЧИСТКА (Free Space)"
    echo -e "\${BLUE}2.\${NC} СЕТЕВОЙ СКАНЕР (Nmap)"
    echo -e "\${BLUE}3.\${NC} ПОИСК ЭКСПЛОЙТОВ (Searchsploit)"
    echo -e "\${BLUE}4.\${NC} ВЗЛОМ ПАРОЛЕЙ (John / Hydra)"
    echo -e "\${BLUE}5.\${NC} ВЕБ-АНАЛИЗ (Sqlmap / Commix)"
    echo -e "\${BLUE}6.\${NC} ПЕРЕХВАТ (Bettercap)"
    echo -e "\${BLUE}7.\${NC} ПРОВЕРИТЬ МЕСТО (df -h)"
    echo -e "\${RED}0.\${NC} ВЫХОД"
    echo -e "\${CYAN}===========================================\${NC}"
}

clean_system() {
    echo -e "\${GREEN}[*] Глубокая очистка...\${NC}"
    apt-get clean && apt-get autoclean && apt-get autoremove -y
    rm -rf /var/cache/apt/archives/* /tmp/* /var/tmp/*
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/*
    echo -e "\${GREEN}[+] Готово! Свободное место:\${NC}"
    df -h /
    echo -e "\${CYAN}Пауза 20 секунд...\${NC}"
    sleep 20
}

while true; do
    show_menu
    read -p "Опция: " opt
    case \$opt in
        1) clean_system ;;
        2) nmap ;;
        3) read -p "Поиск: " s; searchsploit \$s ;;
        4) echo "Инструменты: john, hydra, hashcat"; sleep 2 ;;
        5) echo "Инструменты: sqlmap, nikto, commix"; sleep 2 ;;
        6) bettercap ;;
        7) df -h / ; read -p "Enter..." ;;
        0) exit 0 ;;
        *) sleep 1 ;;
    esac
done
EOF

    # 2. Создаем скрипт обновления самого себя
    cat << EOF > "$UPDATE_SCRIPT"
#!/bin/bash
echo -e "\033[0;34m[*] Обновление арсенала из GitHub...\033[0m"
curl -L https://raw.githubusercontent.com/szp2025/core-prime-tools/main/kalipro_setup.sh | bash
EOF

    # Выставляем права на исполнение
    chmod +x "$TARGET_FILE"
    chmod +x "$UPDATE_SCRIPT"
    
    echo -e "\033[0;32m[+] Обновление до v$CURRENT_VERSION завершено успешно.\033[0m"
}

# --- ОСНОВНАЯ ЛОГИКА ПРОВЕРКИ ---

if [ ! -f "$TARGET_FILE" ]; then
    echo -e "\033[0;33m[!] Арсенал не обнаружен. Начинаю установку...\033[0m"
    create_files
else
    # Извлекаем версию из установленного файла
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        echo -e "\033[0;34m[*] Обнаружена новая версия ($CURRENT_VERSION). У вас установлена ($INSTALLED_VERSION).\033[0m"
        create_files
    else
        echo -e "\033[0;32m[+] У вас уже установлена актуальная версия ($INSTALLED_VERSION). Обновление не требуется.\033[0m"
    fi
fi
