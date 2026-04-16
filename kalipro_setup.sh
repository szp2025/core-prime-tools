#!/bin/bash

# ТЕКУЩАЯ ВЕРСИЯ (v2.6)
CURRENT_VERSION="2.6"

TARGET_FILE="/usr/local/bin/kali_pro"
UPDATE_SCRIPT="/usr/local/bin/update_kali"

echo -e "\033[0;36m[*] Проверка системы Kali Pro Arsenal v$CURRENT_VERSION...\033[0m"

create_files() {
    echo -e "\033[0;33m[*] Установка компонентов версии $CURRENT_VERSION...\033[0m"

    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=2.6
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
        def fmt(b):
            if b >= 1024**3: return f'{b/1024**3:.1f}G'
            return f'{b//1024**2}MB'
        f_str, t_str = fmt(free), fmt(total)
        status = '\033[0;32mOK' if free > (500*1024**2) else '\033[0;31mLOW'
        print(f'   \033[0;34m[ {label} ]:\033[0m свободно {f_str} / {t_str} ({status}\033[0m)')
    except: pass
get_status('/', 'СИСТЕМА')
get_status('/sdcard', 'ПАМЯТЬ ТЕЛЕФОНА')
"
}

show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v2.6     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}------------------------------------------=${NC}"
    echo -e "${BLUE}1.${NC} БЫСТРАЯ ОЧИСТКА"
    echo -e "${BLUE}2.${NC} СЕТЕВОЙ СКАНЕР (Nmap)"
    echo -e "${BLUE}3.${NC} ПОИСК ЭКСПЛОЙТОВ (Searchsploit)"
    echo -e "${BLUE}4.${NC} ВЗЛОМ ПАРОЛЕЙ (Hydra)"
    echo -e "${BLUE}5.${NC} ВЕБ-АНАЛИЗ (SQLmap)"
    echo -e "${BLUE}6.${NC} ПЕРЕХВАТ (Bettercap)"
    echo -e "${RED}0.${NC} ВЫХОД"
    echo -e "${CYAN}===========================================${NC}"
}

# --- Функции инструментов ---
clean_system() {
    echo -e "${GREEN}[*] Очистка системы...${NC}"
    apt-get clean && apt-get autoclean -y
    rm -rf /tmp/* /var/tmp/*
    echo -e "${GREEN}[+] Готово.${NC}"
    sleep 2
}

smart_nmap() {
    read -p "Цель: " t
    [[ -z "$t" ]] && return
    echo -e "1.Быстрый 2.Глубокий 3.Уязвимости 4.ПОЛНЫЙ"
    read -p "Выбор: " o
    case $o in
        1) nmap -F --open "$t" ;;
        2) nmap -sV -sC -O --open "$t" ;;
        3) nmap -sV --script vulners --open "$t" ;;
        4) nmap -sV -sC -O --script vulners --open "$t" ;;
    esac
    read -p "Enter..."
}

smart_searchsploit() {
    read -p "Поиск: " q
    searchsploit "$q"
    read -p "ID для копирования: " id
    if [[ -n "$id" ]]; then
        mkdir -p ~/arsenal_exploits && cd ~/arsenal_exploits
        searchsploit -m "$id"
    fi
}

smart_brute() {
    read -p "IP: " t; read -p "User: " u; read -p "Proto: " p
    plist=${plist:-/usr/share/wordlists/rockyou.txt}
    hydra -l $u -P $plist $t $p -V
}

smart_web_scan() {
    read -p "URL: " u
    sqlmap -u "$u" --batch --random-agent
}

smart_bettercap() {
    echo -e "1.Сниффер 2.ARP-Spoof 3.Консоль"
    read -p "Выбор: " o
    case $o in
        1) bettercap -eval "net.probe on; net.sniff on" ;;
        2) read -p "Target IP: " bt; echo 1 > /proc/sys/net/ipv4/ip_forward; bettercap -eval "set arp.spoof.targets $bt; arp.spoof on; net.sniff on" ;;
        3) bettercap ;;
    esac
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

    # 2. Обновляем сам скрипт обновления
    cat << 'EOF' > "$UPDATE_SCRIPT"
#!/bin/bash
echo -e "\033[0;34m[*] Принудительное обновление до последней версии...\033[0m"
curl -L https://raw.githubusercontent.com/szp2025/core-prime-tools/main/kalipro_setup.sh | bash
EOF

    chmod +x "$TARGET_FILE"
    chmod +x "$UPDATE_SCRIPT"
    echo -e "\033[0;32m[+] Успешно обновлено до v$CURRENT_VERSION\033[0m"
}

# ЛОГИКА ПРОВЕРКИ: Если версии не совпадают, вызываем create_files
if [ ! -f "$TARGET_FILE" ]; then
    create_files
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        create_files
    else
        echo -e "\033[0;32m[+] У вас актуальная версия ($INSTALLED_VERSION).\033[0m"
    fi
fi
