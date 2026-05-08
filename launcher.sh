#!/bin/bash

# --- [ КОНФИГУРАЦИЯ И ЦВЕТА ] ---
G='\033[1;32m'
R='\033[1;31m'
Y='\033[1;33m'
B='\033[1;34m'
P='\033[1;35m'
C='\033[1;36m'
NC='\033[0m'

CURRENT_VERSION="31.5"

# --- [ СИСТЕМНЫЕ ФУНКЦИИ ] ---
pause() {
    echo -e "\n${Y}[ PRESS ENTER TO CONTINUE ]${NC}"
    read _
}

# Твой динамический контроллер меню
prime_dynamic_controller() {
    local title=$1
    local names=$2
    local funcs=$3
    
    while true; do
        clear
        echo -e "${P}--------------------------------------------------${NC}"
        echo -e "   $title"
        echo -e "${P}--------------------------------------------------${NC}"
        
        local i=1
        for name in $names; do
            echo -e "  [${G}$i${NC}] $name"
            i=$((i+1))
        done
        
        echo -e "${P}--------------------------------------------------${NC}"
        read -p " Selection: " choice
        
        local func=$(echo $funcs | cut -d' ' -f$choice)
        if [ -z "$func" ]; then
            echo -e "${R}Invalid option${NC}"
            sleep 1
        else
            $func
        fi
    done
}

# --- [ МОДУЛИ: UTILS ] ---

run_pwd_gen() {
    clear
    echo -e "${Y}>>> [ PASSWORD GENERATOR ] <<<${NC}"
    read -p "Length (default 16): " P_LEN
    [ -z "$P_LEN" ] && P_LEN=16
    
    # Максимально безопасная генерация для любого терминала
    RESULT=$(openssl rand -base64 64 | tr -dc 'A-Za-z0-9!#%^*' | head -c "$P_LEN")
    
    echo -e "\n${G}[+] Generated:${NC} $RESULT"
    echo "--------------------------------------------------"
    read -p "Hash it with Bcrypt? (y/n): " h_choice
    if [ "$h_choice" = "y" ]; then
        if command -v mkpasswd >/dev/null; then
            echo -n "$RESULT" | mkpasswd -m bcrypt -s
        else
            echo -e "${R}[!] Error: whois package missing.${NC}"
        fi
    fi
    pause
}

run_cert_forge() {
    clear
    echo -e "${G}>>> [ CERTIFICATE FORGE ] <<<${NC}"
    read -p "Domain (google.com): " S_DOMAIN
    [ -z "$S_DOMAIN" ] && return

    echo -e "${B}[*] Fetching metadata...${NC}"
    # Используем временный файл, чтобы не ломать Bash кавычками
    timeout 5 openssl s_client -connect "${S_DOMAIN}:443" -servername "$S_DOMAIN" </dev/null 2>/dev/null | openssl x509 -noout -subject > /tmp/cert.tmp
    
    if [ -s /tmp/cert.tmp ]; then
        # Чистим данные без вложенных кавычек
        local ORIG_SUBJ=$(cat /tmp/cert.tmp | sed 's/subject=//; s/^[[:space:]]*//')
        echo -e "${G}[+] Metadata:${NC} $ORIG_SUBJ"
        
        openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
            -subj "$ORIG_SUBJ" \
            -keyout "/root/${S_DOMAIN}.key" \
            -out "/root/${S_DOMAIN}.crt" 2>/dev/null
            
        echo -e "${G}[DONE]${NC} Files saved in /root/"
    else
        echo -e "${R}[!] Failed to get info.${NC}"
    fi
    rm -f /tmp/cert.tmp
    pause
}

# Заглушки для функций, которые добавим позже
exit_script() { echo -e "${G}Goodbye!${NC}"; exit 0; }
not_implemented() { echo -e "${R}Module under construction...${NC}"; pause; }

# --- [ ГЛАВНОЕ МЕНЮ ] ---
run_main_menu() {
    local main_names="PWD_GEN CERT_FORGE EXIT"
    local main_funcs="run_pwd_gen run_cert_forge exit_script"
    
    prime_dynamic_controller "PRIME MASTER v$CURRENT_VERSION" "$main_names" "$main_funcs"
}

# Запуск
run_main_menu
