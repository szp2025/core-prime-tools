#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
VERSION="12.1"
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

# Функция реанимации (адаптирована под низкую RAM)
repair_and_clean() {
    # Сброс кэша ядра для освобождения памяти
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    # Очистка кэша пакетов
    apt-get clean
    # Исправление битых зависимостей
    dpkg --configure -a
    apt-get install -f -y > /dev/null 2>&1
    # Удаление временных файлов
    rm -f /root/*.zip /root/*.tmp
    rm -rf ~/.cache/pip
}

# Силовая установка Python-пакетов (PEP 668 Bypass)
safe_pip() {
    echo -e "${Y}[!] Pip: Установка зависимостей...${NC}"
    python3 -m pip install --no-cache-dir --break-system-packages "$@"
    repair_and_clean
}

# Универсальный установщик через ZIP (минимальная нагрузка на RAM)
install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4

    echo -e "${B}[*] Проверка $name...${NC}"
    
    # Если папка есть, но исполняемого файла нет — переустанавливаем
    if [ -d "$name" ] && [ ! -f "$name/$exec_file" ] && [[ "$exec_file" != "NONE" ]]; then
        rm -rf "$name"
    fi

    if [ -d "$name" ]; then
        echo -e "${G}[-] $name уже на месте.${NC}"
        [ -f "$name/$exec_file" ] && chmod +x "$name/$exec_file" 2>/dev/null
        return 0
    fi

    echo -e "${Y}[+] Загрузка $name (Direct ZIP)...${NC}"
    curl -L "$url" -o "temp.zip"
    
    if [ -s "temp.zip" ]; then
        unzip -q "temp.zip"
        # Поиск распакованной папки (убираем "матрешку")
        local extracted_dir=$(ls -d */ 2>/dev/null | grep -E "${name}|master|main" | head -n 1)
        if [ -n "$extracted_dir" ]; then
            mv "$extracted_dir" "$name"
            rm -f "temp.zip"
            if [ -n "$extra_cmd" ]; then
                echo -e "${B}[*] Настройка $name...${NC}"
                cd "$name" && eval "$extra_cmd" && cd ..
            fi
            [ -f "$name/$exec_file" ] && chmod +x "$name/$exec_file"
        fi
    fi
    repair_and_clean
}

# --- СТАРТ РАЗВЕРТЫВАНИЯ ---
echo -e "${B}=========================================="
echo -e "${R}    PRIME INTELLIGENCE v$VERSION (FINAL)"
echo -e "${B}==========================================${NC}"

# 0. СИСТЕМНОЕ ЯДРО
echo -e "${B}[*] Подготовка системы (RAM: $(free -m | awk '/Mem:/ {print $4}')MB)...${NC}"
apt-get update
# Установка Foremost и других утилит по одной для стабильности
for pkg in php curl unzip python3-pip nmap whois nikto chntpw clamav ntfs-3g john \
            sleuthkit foremost steghide tshark fcrackzip libimage-exiftool-perl htop; do
    echo -e "${Y}[+] Системный модуль: $pkg...${NC}"
    apt-get install -y $pkg > /dev/null 2>&1
    repair_and_clean
done

# 1. СОЦИАЛЬНАЯ ИНЖЕНЕРИЯ
install_tool "zphisher" "https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip" "zphisher.sh"
install_tool "seeker" "https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip" "seeker.py" "safe_pip -r requirements.txt"

# 2. СЕТЕВОЙ АНАЛИЗ И ЭКСПЛОЙТЫ
install_tool "routersploit" "https://github.com/threat9/routersploit/archive/refs/heads/master.zip" "rsf.py" "safe_pip -r requirements.txt"
install_tool "redhawk" "https://github.com/Tuhinshubhra/RED_HAWK/archive/refs/heads/master.zip" "rhawk.php"
install_tool "wifite2" "https://github.com/derv82/wifite2/archive/refs/heads/master.zip" "wifite.py" "python3 setup.py install --break-system-packages"

# 3. OSINT И РАЗВЕДКА
install_tool "sherlock" "https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip" "sherlock/sherlock.py" "safe_pip -r requirements.txt"
install_tool "ip-tracer" "https://github.com/rajkumardusad/IP-Tracer/archive/refs/heads/master.zip" "ip-tracer" "chmod +x install && ./install"
install_tool "infoga" "https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip" "infoga.py" "safe_pip -r requirements.txt"

# 4. ПАРОЛИ И БЕЗОПАСНОСТЬ
install_tool "cupp" "https://github.com/Mebus/cupp/archive/refs/heads/master.zip" "cupp.py"
install_tool "sqlmap" "https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip" "sqlmap.py"
install_tool "chkrootkit" "https://github.com/MageSlayer/chkrootkit/archive/refs/heads/master.zip" "chkrootkit" "make"

# 5. ОБНОВЛЕНИЕ МЕНЮ (prime.sh)
echo -e "${B}[*] Финализация меню...${NC}"
curl -L -s "${BASE_URL}/prime.sh" -o "/usr/local/bin/prime.tmp"
if [ -s "/usr/local/bin/prime.tmp" ]; then
    mv "/usr/local/bin/prime.tmp" "/usr/local/bin/prime"
    chmod +x "/usr/local/bin/prime"
fi

repair_and_clean
echo -e "\n${G}[!!!] PRIME v$VERSION MASTER РАЗВЕРНУТ. ВСЁ ПОД КОНТРОЛЕМ.${NC}"
