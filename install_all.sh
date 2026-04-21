#!/bin/bash

# --- КОНФИГУРАЦИЯ ЦВЕТОВ ---
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

# --- СИСТЕМНОЕ ЯДРО ---
# Survival Mode: агрессивная очистка кэша для 51MB RAM
repair_and_clean() {
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    rm -f /root/*.zip /root/*.tmp
    apt-get clean && rm -rf ~/.cache/pip
}

safe_pip() {
    echo -e "${B}[*] PIP: Установка зависимостей...${NC}"
    python3 -m pip install --no-cache-dir --break-system-packages "$@"
    repair_and_clean
}

# Универсальный установщик
install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4
    echo -e "${B}[*] Проверка: $name...${NC}"
    
    if [ -f "$name/$exec_file" ] || command -v "$name" &> /dev/null; then
        echo -e "${G}[✔] $name уже в системе.${NC}"; return 0
    fi

    [ -d "$name" ] && rm -rf "$name"
    echo -e "${Y}[+] Установка $name...${NC}"
    curl -L -f "$url" -o "temp.zip"
    
    if [ -s "temp.zip" ]; then
        unzip -q "temp.zip"
        local extracted_dir=$(ls -d */ 2>/dev/null | grep -E "${name}|master|main" | head -n 1)
        if [ -n "$extracted_dir" ]; then
            mv "$extracted_dir" "$name"
            rm -f "temp.zip"
            [ -n "$extra_cmd" ] && (cd "$name" && eval "$extra_cmd")
            [ -f "$name/$exec_file" ] && chmod +x "$name/$exec_file"
        fi
    fi
    repair_and_clean
}

# --- ПОДГОТОВКА СПИСКА ИНСТРУМЕНТОВ ---
# Формат: "Имя ; URL ; Исполняемый_файл ; Доп_команда"
TOOLS=(
    "zphisher;https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip;zphisher.sh;"
    "seeker;https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip;seeker.py;safe_pip -r requirements.txt"
    "wifite2;https://github.com/derv82/wifite2/archive/refs/heads/master.zip;wifite.py;python3 setup.py install --break-system-packages"
    "sqlmap;https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip;sqlmap.py;"
    "routersploit;https://github.com/threat9/routersploit/archive/refs/heads/master.zip;rsf.py;safe_pip -r requirements.txt"
    "sherlock;https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip;sherlock/sherlock.py;safe_pip -r requirements.txt"
    "phoneinfoga;https://github.com/sundowndev/phoneinfoga/archive/refs/heads/master.zip;phoneinfoga.py;safe_pip -r requirements.txt"
    "infoga;https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip;infoga.py;safe_pip -r requirements.txt"
    "phonesploit;https://github.com/Zucccs/PhoneSploit-Python/archive/refs/heads/main.zip;phonesploitpython.py;safe_pip -r requirements.txt"
    "cupp;https://github.com/Mebus/cupp/archive/refs/heads/master.zip;cupp.py;"
)

# --- СТАРТ ---
clear
echo -e "${R}=========================================="
echo -e "    PRIME v14.0 MASTER (ARRAY EDITION)"
echo -e "==========================================${NC}"

repair_and_clean

echo -e "${B}[*] Обновление APT репозиториев...${NC}"
apt-get update
apt-get install -y php curl unzip python3-pip nmap foremost tshark aircrack-ng chkrootkit whatweb htop bluez clamav

# Автоматический цикл установки
echo -e "${B}[*] Запуск массовой эвристической установки...${NC}"
for entry in "${TOOLS[@]}"; do
    IFS=";" read -r t_name t_url t_exec t_extra <<< "$entry"
    install_tool "$t_name" "$t_url" "$t_exec" "$t_extra"
done

# --- ГЕНЕРАЦИЯ LAUNCHER.SH ---
echo -e "${B}[*] Сборка интерфейса управления...${NC}"

cat << 'EOF' > /root/launcher.sh
#!/bin/bash
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

repair() { sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true; }
pause() { echo -e "\n${B}------------------------------------${NC}"; read -p "Нажми [Enter]..."; }

run_ghost_scan() {
    repair; clear; echo -e "${R}>>> [ GHOST SCAN ] <<<${NC}"
    echo -ne "Цель (domain.com): "; read target
    [ -z "$target" ] && return
    whatweb -a 1 "$target" --color=never
    nmap -sV -p80,443 --script http-enum,http-title --script-args http.useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$target"
    pause
}

mod_device_hack() {
    clear; echo -e "${R}>>> [ DEVICE EXPLOIT ] <<<${NC}"
    echo -e "1) Bluetooth Scan\n2) Android Hack (PhoneSploit)\n3) Поиск паролей (grep)\n0) Назад"
    read -p ">> " m4
    case $m4 in
        1) hcitool scan; pause ;;
        2) cd /root/phonesploit && python3 phonesploitpython.py ;;
        3) echo -n "Путь: "; read p; grep -rnE "pass|pwd|login|cred" "$p" 2>/dev/null | head -n 20; pause ;;
    esac
}

mod_osint() {
    clear; echo -e "${Y}>>> [ SMART OSINT ] <<<${NC}"
    echo -e "1) Sherlock (Nick)\n2) PhoneInfoga (Phone)\n3) Infoga (Email)\n4) IP-Tracer\n0) Назад"
    read -p ">> " m3
    case $m3 in
        1) echo -n "Ник: "; read n; python3 /root/sherlock/sherlock/sherlock.py "$n" --timeout 1; pause ;;
        2) echo -n "Номер: "; read p; cd /root/phoneinfoga && python3 phoneinfoga.py -n "$p"; pause ;;
        3) echo -n "Email: "; read e; cd /root/infoga && python3 infoga.py --domain all --target "$e"; pause ;;
        4) trace -h; pause ;;
    esac
}

mod_security() {
    clear; echo -e "${G}>>> [ SECURITY & AUDIT ] <<<${NC}"
    echo -e "1) Антивирус ClamAV\n2) Rootkit Hunter\n0) Назад"
    read -p ">> " m5
    case $m5 in
        1) clamscan -r /root --bell -i; pause ;;
        2) chkrootkit; pause ;;
    esac
}

while true; do
    repair; clear
    echo -e "${R}========== [ PRIME MASTER v14.0 ] ==========${NC}"
    echo -e "G) ${R}[ GHOST SCAN ]${NC}  1) ${G}[ SOCIAL ENG ]${NC}"
    echo -e "2) ${G}[ AUTO-EXPLOIT ]${NC} 3) ${Y}[ SMART OSINT ]${NC}"
    echo -e "4) ${B}[ DEVICE HACK ]${NC}  5) ${B}[ SECURITY ]${NC}"
    echo -e "--------------------------------------------"
    echo -e "s) MONITOR (HTOP)    0) EXIT"
    echo -ne "\n${Y}>> Вектор: ${NC}"
    read opt
    case $opt in
        g|G) run_ghost_scan ;;
        1) cd /root/zphisher && ./zphisher.sh ;;
        2) cd /root/sqlmap && python3 sqlmap.py --wizard ;;
        3) mod_osint ;;
        4) mod_device_hack ;;
        5) mod_security ;;
        s) htop ;;
        0) clear; exit 0 ;;
    esac
done
EOF

chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
repair_and_clean

echo -e "\n${G}[✔] PRIME v14.0 УСПЕШНО РАЗВЕРНУТ.${NC}"
echo -e "${Y}Для работы введи: launcher${NC}"
