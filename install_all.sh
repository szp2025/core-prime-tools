#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

# Функция очистки памяти
repair_and_clean() {
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    rm -f /root/*.zip /root/*.tmp
    apt-get clean && rm -rf ~/.cache/pip
}

# Силовая установка Python
safe_pip() {
    python3 -m pip install --no-cache-dir --break-system-packages "$@"
    repair_and_clean
}

# Умный установщик
install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4
    echo -e "${B}[*] Проверка: $name...${NC}"

    if [ -f "$name/$exec_file" ] || command -v "$name" &> /dev/null; then
        echo -e "${G}[- ] $name уже в системе.${NC}"
        return 0
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

# --- СТАРТ РАЗВЕРТЫВАНИЯ ---
clear
echo -e "${B}=========================================="
echo -e "${R}    PRIME v12.9 MASTER (AUTO-INSTALLER)"
echo -e "${B}==========================================${NC}"

repair_and_clean

# Системное ядро
echo -e "${B}[*] Обновление системных компонентов...${NC}"
apt-get update
apt-get install -y php curl unzip python3-pip nmap foremost tshark aircrack-ng chkrootkit

# Установка инструментов
install_tool "zphisher" "https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip" "zphisher.sh"
install_tool "seeker" "https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip" "seeker.py" "safe_pip -r requirements.txt"
install_tool "wifite2" "https://github.com/derv82/wifite2/archive/refs/heads/master.zip" "wifite.py" "python3 setup.py install --break-system-packages"
install_tool "routersploit" "https://github.com/threat9/routersploit/archive/refs/heads/master.zip" "rsf.py" "safe_pip -r requirements.txt"
install_tool "sherlock" "https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip" "sherlock/sherlock.py" "safe_pip -r requirements.txt"
install_tool "ip-tracer" "https://github.com/rajkumardusad/IP-Tracer/archive/refs/heads/master.zip" "ip-tracer" "chmod +x install && ./install"
install_tool "sqlmap" "https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip" "sqlmap.py"
install_tool "cupp" "https://github.com/Mebus/cupp/archive/refs/heads/master.zip" "cupp.py"

# --- СОЗДАНИЕ / ОБНОВЛЕНИЕ LAUNCHER.SH С ФУНКЦИЯМИ ---
echo -e "${B}[*] Генерирую модульный launcher.sh...${NC}"

# --- ГЕНЕРАЦИЯ МОДУЛЬНОГО LAUNCHER v13.5 ---
cat << 'EOF' > /root/launcher.sh
#!/bin/bash
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

repair() { sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true; }
pause() { echo -e "\n${B}------------------------------------${NC}"; read -p "Нажми [Enter]..."; }

# --- ЭВРИСТИЧЕСКИЙ МОДУЛЬ "GHOST" ---
run_ghost_scan() {
    repair; clear
    echo -e "${R}>>> [ SMART GHOST SCAN ] <<<${NC}"
    echo -ne "${Y}Введите цель (example.com): ${NC}"
    read target
    [ -z "$target" ] && return

    echo -e "\n${B}[1/3] Пассивный эвристический анализ (WhatWeb)...${NC}"
    # WhatWeb определяет систему без агрессивного сканирования
    whatweb -a 1 "$target" --color=never

    echo -e "\n${B}[2/3] Поиск уязвимых конфигураций (Fingerprinting)...${NC}"
    # Nmap с подменой User-Agent под обычный Chrome, чтобы не спалиться
    nmap -sV -p80,443 --script http-title,http-headers,http-robots.txt \
    --script-args http.useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" "$target"

    echo -e "\n${B}[3/3] Автоматический поиск векторов (Smart Enum)...${NC}"
    # Сканируем только самые вероятные пути (эвристика)
    nmap -p80,443 --script http-enum --script-args http-enum.fingerprintfile="default" "$target"

    pause
}

# --- МОДУЛЬ 1: СОЦ. ИНЖЕНЕРИЯ (Автоматизация) ---
mod_social() {
    clear
    echo -e "${B}>>> СОЦИАЛЬНАЯ ИНЖЕНЕРИЯ${NC}"
    echo -e "1) Zphisher (Auto-Phish)"
    echo -e "2) Seeker (Smart Geo-Track)"
    echo -e "0) Назад"
    read -p ">> " m1
    case $m1 in
        1) repair && cd /root/zphisher && ./zphisher.sh ;;
        2) repair && cd /root/seeker && python3 seeker.py ;;
    esac
}

# --- МОДУЛЬ 2: АВТО-ВЗЛОМ (SQL & Wi-Fi) ---
mod_exploit() {
    clear
    echo -e "${B}>>> СЕТИ И ЭКСПЛОЙТЫ${NC}"
    echo -e "1) Wifite2 (Auto-Wifi)"
    echo -e "2) SQLMap (Smart DB Exploit)"
    echo -e "3) Routersploit (Auto-Router)"
    echo -e "0) Назад"
    read -p ">> " m2
    case $m2 in
        1) repair && wifite --kill --dict /root/cupp/passwords.txt ;;
        2) repair && cd /root/sqlmap && python3 sqlmap.py --wizard ;;
        3) repair && cd /root/routersploit && python3 rsf.py ;;
    esac
}

# --- ГЛАВНОЕ МЕНЮ ---
while true; do
    repair; clear
    echo -e "${R}========== [ PRIME MASTER v13.5 ] ==========${NC}"
    echo -e "G) ${R}[ GHOST SCAN ]${NC}  -> Тихое эвристическое сканирование"
    echo -e "--------------------------------------------"
    echo -e "1) ${G}[ СОЦ. ИНЖЕНЕРИЯ ]${NC}"
    echo -e "2) ${G}[ АВТО-ВЗЛОМ ]${NC}"
    echo -e "3) ${Y}[ OSINT РАЗВЕДКА ]${NC}"
    echo -e "4) ${Y}[ ПАРОЛИ / АУДИТ ]${NC}"
    echo -e "--------------------------------------------"
    echo -e "s) СИСТЕМА (HTOP)    0) ВЫХОД"
    echo -ne "\n${Y}>> Вектор: ${NC}"
    read opt
    case $opt in
        g|G) run_ghost_scan ;;
        1) mod_social ;;
        2) mod_exploit ;;
        s) htop ;;
        0) clear; break ;;
    esac
done
EOF

chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
