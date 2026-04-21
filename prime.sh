#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
VERSION="2.9"
BASE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main"
SELF_PATH="/usr/local/bin/prime"

# Цвета
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'

# --- 1. МОНИТОРИНГ ---

get_resources() {
    CURRENT_RAM=$(free -m | awk '/Mem:/ { print $4 }')
    BATT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "0")
    DISK_INT=$(df -h /system | awk 'NR==2 {print $4}')
    
    [ "$CURRENT_RAM" -gt 100 ] && RAM_COL=$G || RAM_COL=$R
    [ "$BATT" -gt 70 ] && BATT_COL=$G || BATT_COL=$Y
}

check_auto_purge() {
    if [ "$CURRENT_RAM" -lt 45 ]; then
        echo -e "${R}[!] Low RAM detected ($CURRENT_RAM MB). Cleaning...${NC}"
        apt-get clean > /dev/null 2>&1
        sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    fi
}

# --- 2. ИНТЕРФЕЙС (БЕЗ CLEAR) ---

draw_header() {
    echo -e "\n${B}--- LOG SESSION START v$VERSION ---${NC}"
    echo -e "${B}BATT:${NC} ${BATT_COL}${BATT}%${NC} | ${B}RAM:${NC} ${RAM_COL}${CURRENT_RAM}MB${NC} | ${B}DISK:${NC} ${Y}${DISK_INT}${NC}"
    echo -e "${B}------------------------------------------${NC}"
}

draw_menu() {
    echo -e "1) ${G}FULL PRO SETUP${NC}  2) ${G}SYSTEM PURGE${NC}  3) ${B}UPDATE MENU${NC}"
    echo -e "4) ${Y}ZPHISHER${NC}       5) ${Y}SHERLOCK${NC}      6) ${Y}WIFITE2${NC}"
    echo -e "8) ${Y}ROUTERSPLOIT${NC}   9) ${Y}SET-TOOLKIT${NC}   7) ${Y}PROTOCOLS${NC}"
    echo -e "R) ${R}RESET TOOLS${NC}     - Удалить Routersploit и SET"
    echo -e "0) ${R}EXIT${NC}"
    echo -e "${B}>> Выберите действие:${NC}"
}

# --- 3. ЛОГИКА ---

run_tool() {
    local name=$1
    local url=$2
    local cmd=$3

    if [ -d "$name" ]; then
        cd "$name" || return
        
        # ЛЕЧИМ МАТРЕШКУ: Если внутри папки есть папка с тем же именем
        if [ -d "$name" ]; then
             echo -e "${Y}[!] Исправление вложенности папок...${NC}"
             mv "$name"/* . 2>/dev/null
             rm -rf "$name"
        fi

        echo -e "${B}[*] Запуск $name...${NC}"
        
        # Попытка запуска (перенаправляем ошибки в переменную для анализа)
        error_log=$(eval "$cmd" 2>&1 | tee /dev/tty)

        # Если упало или не хватает модулей
        if [[ $? -ne 0 || "$error_log" == *"ModuleNotFoundError"* || "$error_log" == *"pkg_resources"* ]]; then
            echo -e "${Y}[!] Проблема с запуском или модулями. Лечим...${NC}"
            # Ставим базу с обходом защиты PEP 668
            python3 -m pip install --no-cache-dir --break-system-packages setuptools requests future pyelftools
            
            if [ -f "requirements.txt" ]; then
                echo -e "${B}[*] Доставляем пакеты из requirements...${NC}"
                python3 -m pip install --no-cache-dir --break-system-packages -r requirements.txt
            fi
            echo -e "${G}[+] Готово. Попробуй нажать кнопку еще раз.${NC}"
        fi

        echo -e "${Y}>> [Enter] для возврата...${NC}"
        read -r
        cd ..
    else
        echo -e "${Y}[!] $name не найден. Качаем архив...${NC}"
        
        # Пробуем master, если упадет - попробуем main
        local zip_url="${url%.git}/archive/refs/heads/master.zip"
        curl -L "$zip_url" -o "temp.zip"
        
        if [ ! -s "temp.zip" ]; then
            zip_url="${url%.git}/archive/refs/heads/main.zip"
            curl -L "$zip_url" -o "temp.zip"
        fi

        if [ -f "temp.zip" ]; then
            echo -e "${B}[*] Распаковка...${NC}"
            unzip -q "temp.zip"
            
            # Ищем любую новую папку, которая появилась после unzip
            local extracted_dir=$(ls -d */ | grep -E "${name}|master|main" | head -n 1)
            
            if [ -n "$extracted_dir" ]; then
                mv "$extracted_dir" "$name" 2>/dev/null
                rm "temp.zip"
                cd "$name" || return
                
                # Установка зависимостей СРАЗУ с флагом обхода
                echo -e "${B}[*] Настройка окружения (PEP 668 Bypass)...${NC}"
                python3 -m pip install --no-cache-dir --break-system-packages setuptools requests future
                
                if [ -f "requirements.txt" ]; then
                    python3 -m pip install --no-cache-dir --break-system-packages -r requirements.txt
                fi
                
                cd ..
                echo -e "${G}[+] Инструмент $name готов к работе!${NC}"
            else
                echo -e "${R}[!] Ошибка структуры архива.${NC}"
                rm "temp.zip"
            fi
        fi
        read -p ">> [Enter]..."
    fi
}

manage_files() {
    echo -e "\n${R}--- [ УПРАВЛЕНИЕ РЕСУРСАМИ ] ---${NC}"
    echo -e "${B}Текущие инструменты в директории:${NC}"
    
    # Считаем количество папок и выводим их списком с размером
    local folders=$(ls -d */ 2>/dev/null)
    if [ -z "$folders" ]; then
        echo -e "${Y}[!] Папки инструментов не найдены.${NC}"
    else
        # Выводим список папок с их размером в человекочитаемом виде
        du -sh */ 2>/dev/null | sed 's/\///'
    fi

    echo -e "\n${Y}Введите имя папки для УДАЛЕНИЯ (например: routersploit)${NC}"
    echo -e "${Y}Введите 'ALL' для полной очистки или 'Enter' для отмены:${NC}"
    read -p ">> " target

    if [[ "$target" == "ALL" ]]; then
        echo -e "${R}[!] ВНИМАНИЕ: Удаление всех инструментов...${NC}"
        rm -rf routersploit setoolkit zphisher sherlock wifite2
        echo -e "${G}[+] Система очищена.${NC}"
    elif [[ -d "$target" ]]; then
        echo -e "${R}[!] Удаление папки $target...${NC}"
        rm -rf "$target"
        echo -e "${G}[+] Объект $target стерт.${NC}"
    elif [[ -z "$target" ]]; then
        echo -e "${B}[*] Отмена операции.${NC}"
    else
        echo -e "${R}[!] Ошибка: Папка '$target' не существует.${NC}"
    fi
    read -p "Нажми [Enter] для возврата в меню..."
}

# --- 4. ЦИКЛ ---

while true; do
    get_resources
    check_auto_purge
    draw_header
    draw_menu
    
    read -p ">> " opt
    case $opt in
        1) curl -L "$BASE_URL/kalipro_setup.sh" | bash ;;
        2) 
            echo -e "${B}[*] Очистка кэша и DPKG...${NC}"
            rm -rf /var/lib/dpkg/updates/* && dpkg --configure -a
            apt-get clean && apt-get autoremove -y
            echo -e "${G}[+] Операция завершена.${NC}" ;;
        3) run_update ;;
        4) run_tool "zphisher" "https://github.com/htr-tech/zphisher.git" "bash zphisher.sh" ;;
        5) run_tool "sherlock" "https://github.com/sherlock-project/sherlock.git" "python3 sherlock --help" ;;
        6) run_tool "wifite2" "https://github.com/derv82/wifite2.git" "python3 wifite.py" ;;
        8) run_tool "routersploit" "https://github.com/threat9/routersploit.git" "python3 rsf.py" ;;
        9) run_tool "setoolkit" "https://github.com/trustedsec/social-engineer-toolkit.git" "python3 setup.py" ;;
        10) manage_files ;;
        7) echo -e "${Y}[88] Core | [90] Protection | [95] Sterile${NC}" ;;
        0) exit 0 ;;
        *) echo -e "${R}Ошибка выбора.${NC}" ;;
    esac
done
