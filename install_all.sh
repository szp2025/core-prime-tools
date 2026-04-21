#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

safe_pip() {
    python3 -m pip install --no-cache-dir --break-system-packages "$@"
}

install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4
    echo -e "${B}[*] Проверка $name...${NC}"
    if [ -d "$name" ] && [ ! -f "$name/$exec_file" ]; then
        echo -e "${R}[!] $name поврежден. Переустановка...${NC}"
        rm -rf "$name"
    fi
    if [ -d "$name" ]; then
        echo -e "${G}[-] $name исправен.${NC}"
        chmod +x "$name/$exec_file" 2>/dev/null
        return 0
    fi

    echo -e "${Y}[+] Спец-установка $name...${NC}"
    curl -L "$url" -o "temp.zip"
    if [ -s "temp.zip" ]; then
        unzip -q "temp.zip"
        local extracted_dir=$(ls -d */ 2>/dev/null | grep -E "${name}|master|main" | head -n 1)
        if [ -n "$extracted_dir" ]; then
            mv "$extracted_dir" "$name"
            rm "temp.zip"
            if [ -n "$extra_cmd" ]; then
                cd "$name" && eval "$extra_cmd" && cd ..
            fi
            [ -f "$name/$exec_file" ] && chmod +x "$name/$exec_file"
            echo -e "${G}[+] Готово.${NC}"
        fi
    else
        echo -e "${R}[!] Ошибка загрузки $name${NC}"
        rm -f "temp.zip"
    fi
}

# --- НАЧАЛО ---
echo -e "${B}=========================================="
echo -e "${R}   PRIME INTELLIGENCE v9.0 (Special Ops)"
echo -e "${B}==========================================${NC}"

# 0. СИСТЕМНЫЙ СТЕК (Криминалистика, Сети, Стеганография)
# sleuthkit - анализ дисков, foremost - восстановление файлов, steghide - скрытие данных, tshark - анализ пакетов
echo -e "${B}[*] Развертывание системных модулей разведки...${NC}"
apt-get update && apt-get install -y php curl unzip python3-pip nmap whois nikto chntpw clamav ntfs-3g john sleuthkit foremost steghide tshark

# 1. СОЦИАЛЬНАЯ ИНЖЕНЕРИЯ
install_tool "zphisher" "https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip" "zphisher.sh"
install_tool "seeker" "https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip" "seeker.py" "safe_pip -r requirements.txt"

# 2. АНАЛИЗ СЕТЕЙ И ТРАФИКА
install_tool "redhawk" "https://github.com/Tuhinshubhra/RED_HAWK/archive/refs/heads/master.zip" "rhawk.php"
install_tool "wifite2" "https://github.com/derv82/wifite2/archive/refs/heads/master.zip" "wifite.py"

# 3. ЭКСПЛОЙТЫ И УДАЛЕННЫЙ ДОСТУП (ПК/Android)
install_tool "ghost" "https://github.com/Professor-K-99/Ghost-Hub/archive/refs/heads/main.zip" "ghost-hub.sh"
install_tool "phoneSploit" "https://github.com/Tebogo404/PhoneSploit-Reborn/archive/refs/heads/main.zip" "phonesploitpython.py" "safe_pip -r requirements.txt"
install_tool "exploits" "https://github.com/1RaY-1/Termux-Exploit/archive/refs/heads/master.zip" "install.py"

# 4. OSINT (Глобальный поиск и разведка)
install_tool "sherlock" "https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip" "sherlock/sherlock.py" "safe_pip -r requirements.txt"
install_tool "ip-tracer" "https://github.com/rajkumardusad/IP-Tracer/archive/refs/heads/master.zip" "ip-tracer" "chmod +x install && ./install"
install_tool "infoga" "https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip" "infoga.py" "safe_pip -r requirements.txt"

# 5. КРИМИНАЛИСТИКА И ПАРОЛИ (Recovering & Cracking)
install_tool "cupp" "https://github.com/Mebus/cupp/archive/refs/heads/master.zip" "cupp.py"
install_tool "admin-panel-finder" "https://github.com/the-c0d3r/admin-panel-finder/archive/refs/heads/master.zip" "admin_panel_finder.py"
install_tool "sqlmap" "https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip" "sqlmap.py"

# 6. СПЕЦ-МОДУЛИ (Скрытая связь и восстановление)
echo -e "${G}[+] Steghide готов (скрытие данных в фото/аудио)${NC}"
echo -e "${G}[+] Foremost готов (восстановление удаленных файлов)${NC}"

# 7. АНТИВИРУС И ЗАЩИТА
freshclam 2>/dev/null
install_tool "chkrootkit" "https://github.com/MageSlayer/chkrootkit/archive/refs/heads/master.zip" "chkrootkit" "make"

# --- ФИНАЛЬНАЯ ОЧИСТКА ---
echo -e "${B}[*] Глубокая очистка кэша и ОЗУ...${NC}"
rm -f /root/*.zip
rm -rf ~/.cache/pip
apt-get clean
sync && echo 3 > /proc/sys/vm/drop_caches

echo -e "\n${R}[!!!] PRIME INTELLIGENCE v9.0 РАЗВЕРНУТ!${NC}"
echo -e "${Y}Арсенал: Сброс паролей, Восстановление файлов (Foremost), Криминалистика (SleuthKit), Стеганография (Steghide), Глубокий OSINT (Infoga).${NC}"
