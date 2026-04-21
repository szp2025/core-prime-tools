#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

# Функция тотальной реанимации и очистки
repair_and_clean() {
    dpkg --configure -a 
    apt-get install -f -y 
    rm -f /root/*.zip
    rm -rf ~/.cache/pip
    apt-get clean
    sync && echo 3 > /proc/sys/vm/drop_caches
}

safe_pip() {
    python3 -m pip install --no-cache-dir --break-system-packages "$@"
    repair_and_clean
}

install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4

    echo -e "${B}[*] Анализ $name...${NC}"
    if [ -d "$name" ] && [ ! -f "$name/$exec_file" ]; then
        rm -rf "$name"
    fi

    if [ -d "$name" ]; then
        echo -e "${G}[-] $name активен.${NC}"
        chmod +x "$name/$exec_file" 2>/dev/null
        return 0
    fi

    echo -e "${Y}[+] Инсталляция $name...${NC}"
    curl -L "$url" -o "temp.zip"
    
    if [ -s "temp.zip" ]; then
        unzip -q "temp.zip"
        local extracted_dir=$(ls -d */ 2>/dev/null | grep -E "${name}|master|main" | head -n 1)
        if [ -n "$extracted_dir" ]; then
            mv "$extracted_dir" "$name"
            rm -f "temp.zip"
            if [ -n "$extra_cmd" ]; then
                cd "$name" && eval "$extra_cmd" && cd ..
            fi
            [ -f "$name/$exec_file" ] && chmod +x "$name/$exec_file"
        fi
    fi
    repair_and_clean
}

# --- НАЧАЛО ---
echo -e "${B}=========================================="
echo -e "${R}   PRIME INTELLIGENCE v12.0 (FINAL)"
echo -e "${B}==========================================${NC}"

repair_and_clean

# Установка системного ядра (Добавлены Fcrackzip, Exiftool, Htop)
echo -e "${B}[*] Развертывание системных модулей...${NC}"
apt-get update
for pkg in php curl unzip python3-pip nmap whois nikto chntpw clamav ntfs-3g john \
           sleuthkit foremost steghide tshark fcrackzip libimage-exiftool-perl htop; do
    echo -e "${Y}[+] Установка: $pkg...${NC}"
    apt-get install -y $pkg
    repair_and_clean
done

# 1. СОЦИАЛЬНАЯ ИНЖЕНЕРИЯ
install_tool "zphisher" "https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip" "zphisher.sh"
install_tool "seeker" "https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip" "seeker.py" "safe_pip -r requirements.txt"

# 2. СЕТЕВОЙ АНАЛИЗ
install_tool "redhawk" "https://github.com/Tuhinshubhra/RED_HAWK/archive/refs/heads/master.zip" "rhawk.php"
install_tool "wifite2" "https://github.com/derv82/wifite2/archive/refs/heads/master.zip" "wifite.py"

# 3. УДАЛЕННЫЙ ДОСТУП И ЭКСПЛОЙТЫ
install_tool "ghost" "https://github.com/Professor-K-99/Ghost-Hub/archive/refs/heads/main.zip" "ghost-hub.sh"
install_tool "phoneSploit" "https://github.com/Tebogo404/PhoneSploit-Reborn/archive/refs/heads/main.zip" "phonesploitpython.py" "safe_pip -r requirements.txt"
install_tool "exploits" "https://github.com/1RaY-1/Termux-Exploit/archive/refs/heads/master.zip" "install.py"

# 4. РАЗВЕДКА (OSINT)
install_tool "sherlock" "https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip" "sherlock/sherlock.py" "safe_pip -r requirements.txt"
install_tool "ip-tracer" "https://github.com/rajkumardusad/IP-Tracer/archive/refs/heads/master.zip" "ip-tracer" "chmod +x install && ./install"
install_tool "infoga" "https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip" "infoga.py" "safe_pip -r requirements.txt"

# 5. ПАРОЛИ И БД
install_tool "cupp" "https://github.com/Mebus/cupp/archive/refs/heads/master.zip" "cupp.py"
install_tool "admin-panel-finder" "https://github.com/the-c0d3r/admin-panel-finder/archive/refs/heads/master.zip" "admin_panel_finder.py"
install_tool "sqlmap" "https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip" "sqlmap.py"

# 6. БЕЗОПАСНОСТЬ
freshclam 2>/dev/null
install_tool "chkrootkit" "https://github.com/MageSlayer/chkrootkit/archive/refs/heads/master.zip" "chkrootkit" "make"

repair_and_clean
echo -e "\n${G}[!!!] PRIME v12.0 MASTER РАЗВЕРНУТ. ВСЁ ПОД КОНТРОЛЕМ.${NC}"
