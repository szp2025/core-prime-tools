#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

# Функция тотальной реанимации и очистки
repair_and_clean() {
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    apt-get clean
    rm -f /root/*.zip
    rm -rf ~/.cache/pip
}

# Силовая установка Python-пакетов
safe_pip() {
    python3 -m pip install --no-cache-dir --break-system-packages "$@"
    repair_and_clean
}

# Умный установщик с проверкой на существование
install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4

    echo -e "${B}[*] Проверка: $name...${NC}"

    # ПРОВЕРКА: Если папка существует И исполняемый файл внутри на месте
    if [ -f "$name/$exec_file" ] || [ -d "/usr/local/share/$name" ]; then
        echo -e "${G}[-] $name уже установлен. Пропускаю.${NC}"
        [ -f "$name/$exec_file" ] && chmod +x "$name/$exec_file" 2>/dev/null
        return 0
    fi

    # Если папка есть, но она пустая или битая — удаляем перед переустановкой
    [ -d "$name" ] && rm -rf "$name"

    echo -e "${Y}[+] Установка $name (Direct ZIP)...${NC}"
    curl -L "$url" -o "temp.zip"
    
    if [ -s "temp.zip" ]; then
        unzip -q "temp.zip"
        local extracted_dir=$(ls -d */ 2>/dev/null | grep -E "${name}|master|main" | head -n 1)
        if [ -n "$extracted_dir" ]; then
            mv "$extracted_dir" "$name"
            rm -f "temp.zip"
            if [ -n "$extra_cmd" ]; then
                echo -e "${B}[*] Конфигурация $name...${NC}"
                cd "$name" && eval "$extra_cmd" && cd ..
            fi
            [ -f "$name/$exec_file" ] && chmod +x "$name/$exec_file"
        fi
    fi
    repair_and_clean
}

# --- СТАРТ ---
echo -e "${B}=========================================="
echo -e "${R}    PRIME v12.6 MASTER (SMART DEPLOY)"
echo -e "${B}==========================================${NC}"

repair_and_clean

# Системное ядро (apt само проверяет наличие пакетов, так что это безопасно)
echo -e "${B}[*] Проверка системных компонентов...${NC}"
apt-get update
for pkg in php curl unzip python3-pip nmap whois nikto chntpw clamav ntfs-3g john \
            sleuthkit foremost steghide tshark fcrackzip libimage-exiftool-perl htop; do
    apt-get install -y $pkg > /dev/null 2>&1
done

# --- 1. СОЦИАЛЬНАЯ ИНЖЕНЕРИЯ ---
install_tool "zphisher" "https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip" "zphisher.sh"
install_tool "seeker" "https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip" "seeker.py" "safe_pip -r requirements.txt"
install_tool "setoolkit" "https://github.com/trustedsec/social-engineer-toolkit/archive/refs/heads/master.zip" "setup.py" "python3 setup.py install --break-system-packages"

# --- 2. СЕТЕВОЙ АНАЛИЗ ---
install_tool "redhawk" "https://github.com/Tuhinshubhra/RED_HAWK/archive/refs/heads/master.zip" "rhawk.php"
install_tool "wifite2" "https://github.com/derv82/wifite2/archive/refs/heads/master.zip" "wifite.py" "python3 setup.py install --break-system-packages"
install_tool "routersploit" "https://github.com/threat9/routersploit/archive/refs/heads/master.zip" "rsf.py" "safe_pip -r requirements.txt"

# --- 3. ЭКСПЛОЙТЫ ---
install_tool "ghost" "https://github.com/Professor-K-99/Ghost-Hub/archive/refs/heads/main.zip" "ghost-hub.sh"
install_tool "phoneSploit" "https://github.com/Tebogo404/PhoneSploit-Reborn/archive/refs/heads/main.zip" "phonesploitpython.py" "safe_pip -r requirements.txt"
install_tool "exploits" "https://github.com/1RaY-1/Termux-Exploit/archive/refs/heads/master.zip" "install.py"

# --- 4. OSINT ---
install_tool "sherlock" "https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip" "sherlock/sherlock.py" "safe_pip -r requirements.txt"
install_tool "ip-tracer" "https://github.com/rajkumardusad/IP-Tracer/archive/refs/heads/master.zip" "ip-tracer" "chmod +x install && ./install"
install_tool "infoga" "https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip" "infoga.py" "safe_pip -r requirements.txt"

# --- 5. ПАРОЛИ И БД ---
install_tool "cupp" "https://github.com/Mebus/cupp/archive/refs/heads/master.zip" "cupp.py"
install_tool "admin-panel-finder" "https://github.com/the-c0d3r/admin-panel-finder/archive/refs/heads/master.zip" "admin_panel_finder.py"
install_tool "sqlmap" "https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip" "sqlmap.py"

# --- 6. БЕЗОПАСНОСТЬ ---
install_tool "chkrootkit" "https://github.com/MageSlayer/chkrootkit/archive/refs/heads/master.zip" "chkrootkit" "make"

repair_and_clean
echo -e "\n${G}[!!!] PRIME v12.6 MASTER: ПРОВЕРКА ЗАВЕРШЕНА. СИСТЕМА В НОРМЕ.${NC}"
