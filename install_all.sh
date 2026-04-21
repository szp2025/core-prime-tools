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

# --- ГЕНЕРАЦИЯ МОДУЛЬНОГО LAUNCHER ---
cat << 'EOF' > /root/launcher.sh
#!/bin/bash
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

repair() { sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true; }
pause() { echo -e "\n${B}------------------------------------${NC}"; read -p "Нажми [Enter] для возврата..."; }

# --- МОДУЛЬ 1: СОЦИАЛЬНАЯ ИНЖЕНЕРИЯ ---
mod_social() {
    clear
    echo -e "${B}>>> МОДУЛЬ: СОЦИАЛЬНАЯ ИНЖЕНЕРИЯ${NC}"
    echo -e "1) Zphisher (Фишинг)"
    echo -e "2) Seeker (Геолокация)"
    echo -e "0) Назад"
    read -p ">> " m1
    case $m1 in
        1) repair && cd /root/zphisher && ./zphisher.sh ;;
        2) repair && cd /root/seeker && python3 seeker.py ;;
    esac
}

# --- МОДУЛЬ 2: СЕТИ И ЭКСПЛОЙТЫ ---
mod_net_exploit() {
    clear
    echo -e "${B}>>> МОДУЛЬ: СЕТИ И ЭКСПЛОЙТЫ${NC}"
    echo -e "1) Wifite2 (Wi-Fi аудит)"
    echo -e "2) Routersploit (Роутеры)"
    echo -e "3) SQLMap (Взлом БД)"
    echo -e "0) Назад"
    read -p ">> " m2
    case $m2 in
        1) repair && wifite ;;
        2) repair && cd /root/routersploit && python3 rsf.py ;;
        3) repair && cd /root/sqlmap && python3 sqlmap.py --wizard && pause ;;
    esac
}

# --- МОДУЛЬ 3: OSINT И РАЗВЕДКА ---
mod_osint() {
    clear
    echo -e "${B}>>> МОДУЛЬ: OSINT${NC}"
    echo -e "1) Sherlock (Поиск по нику)"
    echo -e "2) IP-Tracer (Данные по IP)"
    echo -e "0) Назад"
    read -p ">> " m3
    case $m3 in
        1) repair && echo -n "Ник: " && read n && python3 /root/sherlock/sherlock/sherlock.py "$n" && pause ;;
        2) repair && trace -h && pause ;;
    esac
}

# --- МОДУЛЬ 4: ПАРОЛИ И СИСТЕМА ---
mod_sys() {
    clear
    echo -e "${B}>>> МОДУЛЬ: СИСТЕМА И ПАРОЛИ${NC}"
    echo -e "1) CUPP (Генератор словарей)"
    echo -e "2) Chkrootkit (Аудит безопасности)"
    echo -e "0) Назад"
    read -p ">> " m4
    case $m4 in
        1) repair && cd /root/cupp && python3 cupp.py -i && pause ;;
        2) repair && chkrootkit && pause ;;
    esac
}

# --- ГЛАВНОЕ МЕНЮ ---
while true; do
    repair; clear
    echo -e "${B}========== [ PRIME MASTER v13.0 ] ==========${NC}"
    echo -e "1) ${G}[ СОЦ. ИНЖЕНЕРИЯ ]${NC} -> Zphisher, Seeker"
    echo -e "2) ${G}[ СЕТИ И ВЗЛОМ ]${NC}   -> Wifite, SQLMap, RSF"
    echo -e "3) ${Y}[ OSINT РАЗВЕДКА ]${NC} -> Sherlock, IP-Tracer"
    echo -e "4) ${Y}[ ПАРОЛИ И АУДИТ ]${NC} -> CUPP, Chkrootkit"
    echo -e "--------------------------------------------"
    echo -e "s) ${B}СИСТЕМНЫЙ HTOP${NC}    0) ${R}ВЫХОД${NC}"
    echo -ne "\n${Y}>> Вектор атаки: ${NC}"
    read opt
    case $opt in
        1) mod_social ;;
        2) mod_net_exploit ;;
        3) mod_osint ;;
        4) mod_sys ;;
        s) htop ;;
        0) clear; break ;;
    esac
done
EOF

chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
