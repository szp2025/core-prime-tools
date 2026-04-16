#!/bin/bash

# Текущая версия инструментов в репозитории
CURRENT_VERSION="1.7"

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

run_smart_check() {
    python3 -c "
import shutil, os
total, used, free = shutil.disk_usage('/')
mb = 1024**2
status = '\033[0;32mOK' if free > (100*mb) else '\033[0;31mCRITICAL'
print(f'   \033[0;34m[ СТАТУС ПАМЯТИ ]:\033[0m {free//mb} MB свободно ({status}\033[0m)')
"
}

show_menu() {
    clear
    echo -e "\${CYAN}===========================================\${NC}"
    echo -e "\${GREEN}      KALI SAMSUNG ARSENAL - MENU v1.5     \${NC}"
    echo -e "\${CYAN}===========================================\${NC}"
    run_smart_check
    echo -e "\${CYAN}-------------------------------------------\${NC}"
    echo -e "\${BLUE}1.\${NC} БЫСТРАЯ ОЧИСТКА (Free Space)"
    echo -e "\${BLUE}2.\${NC} СЕТЕВОЙ СКАНЕР (Nmap)"
    echo -e "\${BLUE}3.\${NC} ПОИСК ЭКСПЛОЙТОВ (Searchsploit)"
    echo -e "\${BLUE}4.\${NC} ВЗЛОМ ПАРОЛЕЙ (John / Hydra)"
    echo -e "\${BLUE}5.\${NC} ВЕБ-АНАЛИЗ (Интеллектуальный SQLmap)"
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

smart_web_scan() {
    read -p "Введите URL цели: " target
    if [[ -z "\$target" ]]; then return; fi
    echo -e "\${BLUE}[*] Python проверяет доступность цели...\${NC}"
    
    python3 -c "
import urllib.request, sys
try:
    req = urllib.request.Request('\$target', headers={'User-Agent': 'Mozilla/5.0'})
    urllib.request.urlopen(req, timeout=5)
    print('\033[0;32m[+] Цель отвечает. Запуск SQLmap...\033[0m')
    sys.exit(0)
except Exception as e:
    print(f'\033[0;31m[-] Ошибка: Цель недоступна ({e}).\033[0m')
    sys.exit(1)
"
    if [ \$? -eq 0 ]; then
        sqlmap -u "\$target" --batch --random-agent
        echo -e "\${CYAN}-------------------------------------------\${NC}"
        read -p "Нажмите Enter для возврата в меню..."
  
    fi
}

# Функция для умного брутфорса
smart_brute() {
    read -p "Введите IP цели: " target
    read -p "Логин (например, root): " login
    echo -e "${BLUE}[1] SSH (port 22)${NC}"
    echo -e "${BLUE}[2] FTP (port 21)${NC}"
    read -p "Выберите протокол: " proto_choice

    case $proto_choice in
        1) proto="ssh"; port=22 ;;
        2) proto="ftp"; port=21 ;;
        *) return ;;
    esac

    # Проверка порта через Python
    python3 -c "
import socket, sys
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(3)
    s.connect(('$target', $port))
    sys.exit(0)
except:
    sys.exit(1)
"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] Порт $port открыт. Начинаю атаку...${NC}"
        # Используем стандартный rockyou или просим путь
        read -p "Путь к словарю (Enter для /usr/share/wordlists/rockyou.txt): " passlist
        passlist=${passlist:-/usr/share/wordlists/rockyou.txt}
        
        hydra -l $login -P $passlist $target $proto -t 4 -V
        
        echo -e "${CYAN}-------------------------------------------${NC}"
        read -p "Если пароль не найден, попробовать другой протокол? (y/n): " retry
        if [[ "$retry" == "y" ]]; then smart_brute; fi
    else
        echo -e "${RED}[-] Порт $port закрыт на этой цели!${NC}"
        read -p "Попробовать другой протокол на этой же цели? (y/n): " retry
        if [[ "$retry" == "y" ]]; then smart_brute; fi
    fi
}


while true; do
    show_menu
    read -p "Опция: " opt
    case \$opt in
        1) clean_system ;;
        2) 
            read -p "Цель для Nmap: " t
            if [[ -n "\$t" ]]; then
                nmap -F --open \$t
                echo -e "\${CYAN}--- Нажмите Enter для возврата ---\${NC}"
                read
            fi
            ;;
        3) 
            read -p "Поиск: " s
            if [[ -n "\$s" ]]; then
                searchsploit \$s
                echo -e "\${CYAN}--- Нажмите Enter для возврата ---\${NC}"
                read
            fi
            ;;
        4) smart_brute ;;
        5) smart_web_scan ;;
        6) bettercap ;;
        7) 
            df -h /
            echo -e "\${CYAN}--- Нажмите Enter для возврата ---\${NC}"
            read 
            ;;
        0) exit 0 ;;
        *) sleep 1 ;;
    esac
done
EOF

    # 2. Скрипт обновления
    cat << EOF > "$UPDATE_SCRIPT"
#!/bin/bash
echo -e "\033[0;34m[*] Обновление арсенала из GitHub...\033[0m"
curl -L https://raw.githubusercontent.com/szp2025/core-prime-tools/main/kalipro_setup.sh | bash
EOF

    chmod +x "$TARGET_FILE"
    chmod +x "$UPDATE_SCRIPT"
    echo -e "\033[0;32m[+] Обновление до v$CURRENT_VERSION завершено.\033[0m"
}

# --- ЛОГИКА ПРОВЕРКИ ---
if [ ! -f "$TARGET_FILE" ]; then
    echo -e "\033[0;33m[!] Арсенал не обнаружен. Начинаю установку...\033[0m"
    create_files
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        echo -e "\033[0;34m[*] Обнаружена новая версия ($CURRENT_VERSION). У вас ($INSTALLED_VERSION).\033[0m"
        create_files
    else
        echo -e "\033[0;32m[+] У вас уже установлена актуальная версия ($INSTALLED_VERSION).\033[0m"
    fi
fi
