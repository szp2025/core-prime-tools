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
