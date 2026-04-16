#!/bin/bash

# Текущая версия инструментов
CURRENT_VERSION="2.6"

# Пути к системным командам
TARGET_FILE="/usr/local/bin/kali_pro"
UPDATE_SCRIPT="/usr/local/bin/update_kali"

echo -e "\033[0;36m[*] Проверка версии Kali Pro Arsenal...\033[0m"

create_files() {
    echo -e "\033[0;33m[*] Установка/Обновление компонентов до версии $CURRENT_VERSION...\033[0m"

    # 1. ЗАПИСЬ ОСНОВНОГО ФАЙЛА (Обрати внимание на 'EOF' в начале)
    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=2.4
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

run_smart_check() {
    python3 -c "
import shutil, os
def get_status(path, label):
    try:
        total, used, free = shutil.disk_usage(path)
        mb = 1024**2
        gb = 1024**3
        disp_free = f'{free/gb:.1f} GB' if free > gb else f'{free//mb} MB'
        status = '\033[0;32mOK' if free > (500*mb) else '\033[0;31mLOW'
        print(f'   \033[0;34m[ {label} ]:\033[0m {disp_free} свободно ({status}\033[0m)')
    except: pass
get_status('/', 'СИСТЕМА')
get_status('/sdcard', 'ПАМЯТЬ ТЕЛЕФОНА')
"
}

show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v2.4     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}------------------------------------------=${NC}"
    echo -e "${BLUE}1.${NC} БЫСТРАЯ ОЧИСТКА (Free Space)"
    echo -e "${BLUE}2.${NC} СЕТЕВОЙ СКАНЕР (Smart Nmap)"
    echo -e "${BLUE}3.${NC} ПОИСК ЭКСПЛОЙТОВ (Searchsploit)"
    echo -e "${BLUE}4.${NC} ВЗЛОМ ПАРОЛЕЙ (Smart Hydra)"
    echo -e "${BLUE}5.${NC} ВЕБ-АНАЛИЗ (Smart SQLmap)"
    echo -e "${BLUE}6.${NC} ПЕРЕХВАТ (Smart Bettercap)"
    echo -e "${RED}0.${NC} ВЫХОД"
    echo -e "${CYAN}===========================================${NC}"
}

clean_system() {
    echo -e "${GREEN}[*] Глубокая очистка...${NC}"
    apt-get clean && apt-get autoclean && apt-get autoremove -y
    rm -rf /var/cache/apt/archives/* /tmp/* /var/tmp/*
    echo -e "${GREEN}[+] Очистка завершена.${NC}"
    sleep 2
}

smart_web_scan() {
    read -p "Введите URL цели: " target
    if [[ -z "$target" ]]; then return; fi
    python3 -c "
import urllib.request, sys
try:
    req = urllib.request.Request('$target', headers={'User-Agent': 'Mozilla/5.0'})
    urllib.request.urlopen(req, timeout=5)
    print('\033[0;32m[+] Цель отвечает.\033[0m')
    sys.exit(0)
except Exception as e:
    print(f'\033[0;31m[-] Ошибка: {e}\033[0m')
    sys.exit(1)
"
    if [ $? -eq 0 ]; then
        sqlmap -u "$target" --batch --random-agent
        read -p "Нажмите Enter..."
    fi
}

smart_nmap() {
    read -p "Введите цель: " target
    if [[ -z "$target" ]]; then return; fi
    echo -e "1. Быстрый\n2. Глубокий\n3. Уязвимости\n4. ПОЛНЫЙ ЦИКЛ"
    read -p "Выбор: " n_opt
    case $n_opt in
        1) nmap -F --open "$target" ;;
        2) nmap -sV -sC -O --open "$target" ;;
        3) nmap -sV --script vulners --open "$target" ;;
        4) nmap -sV -sC -O --script vulners --open "$target" ;;
    esac
    read -p "Enter..."
}

smart_bettercap() {
    echo -e "1. Сниффер\n2. ARP-Spoof (Smart)\n3. Консоль"
    read -p "Выбор: " b_opt
    case $b_opt in
        1) bettercap -eval "net.probe on; net.sniff on" ;;
        2) 
            read -p "IP цели: " bt
            echo 1 > /proc/sys/net/ipv4/ip_forward
            bettercap -eval "set arp.spoof.targets $bt; arp.spoof on; net.sniff on"
            echo 0 > /proc/sys/net/ipv4/ip_forward
            ;;
        3) bettercap ;;
    esac
}

smart_brute() {
    read -p "IP: " target
    read -p "Login: " login
    read -p "Протокол (ssh/ftp): " proto
    read -p "Словарь (Enter для rockyou): " plist
    plist=${plist:-/usr/share/wordlists/rockyou.txt}
    hydra -l $login -P $plist $target $proto -V
    read -p "Enter..."
}

smart_searchsploit() {
    read -p "Поиск: " q
    searchsploit "$q"
    read -p "ID для копирования (или Enter): " id
    if [[ -n "$id" ]]; then
        mkdir -p ~/arsenal_exploits && cd ~/arsenal_exploits
        searchsploit -m "$id"
    fi
}

START_TIME=$(date +"%H:%M:%S")
while true; do
    show_menu
    read -p "[Start: $START_TIME] Опция: " opt
    case $opt in
        1) clean_system ;;
        2) smart_nmap ;;
        3) smart_searchsploit ;;
        4) smart_brute ;;
        5) smart_web_scan ;;
        6) smart_bettercap ;;
        0) exit 0 ;;
        *) sleep 1 ;;
    esac
done
EOF

    # 2. СКРИПТ ОБНОВЛЕНИЯ
    cat << 'EOF' > "$UPDATE_SCRIPT"
#!/bin/bash
echo -e "\033[0;34m[*] Обновление арсенала из GitHub...\033[0m"
curl -L https://raw.githubusercontent.com/szp2025/core-prime-tools/main/kalipro_setup.sh | bash
EOF

    chmod +x "$TARGET_FILE"
    chmod +x "$UPDATE_SCRIPT"
    echo -e "\033[0;32m[+] Обновление завершено.\033[0m"
}

# Логика проверки версии
if [ ! -f "$TARGET_FILE" ]; then
    create_files
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        create_files
    else
        echo -e "\033[0;32m[+] Актуальная версия ($INSTALLED_VERSION).\033[0m"
    fi
fi
