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

prime_dynamic_controller() {
    local title=$1; local names=$2; local funcs=$3
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
        [ -z "$func" ] && continue
        $func
    done
}

# --- [ МОДУЛЬ: OSINT ] ---
run_smart_osint() {
    clear
    echo -e "${C}>>> [ SMART OSINT ENGINE 2026 ] <<<${NC}"
    read -p "Input (Nick/Phone/Email): " INPUT
    [ -z "$INPUT" ] && return
    
    echo -e "${B}[*] Rapid Check...${NC}"
    socialscan "$INPUT"
    
    if [[ "$INPUT" =~ @ ]]; then
        python3 /root/infoga/infoga.py --target "$INPUT"
    elif [[ "$INPUT" =~ ^[0-9+] ]]; then
        echo -e "${G}[+] Phone detected. Running lookup...${NC}"
    else
        maigret "$INPUT" --parse --timeout 15
        python3 /root/blackbird/blackbird.py -u "$INPUT"
    fi
    pause
}

# --- [ МОДУЛЬ: GHOST COMMANDER ] ---
run_ghost_commander() {
    clear
    echo -e "${R}>>> [ GHOST COMMANDER ] <<<${NC}"
    read -p "Target IP (Leave empty for Manual): " T_IP
    if [ -z "$T_IP" ]; then
        cd /root/Ghost && python3 -m ghost
    else
        cd /root/Ghost && python3 -m ghost --execute "connect $T_IP"
    fi
    pause
}

# --- [ МОДУЛЬ: RECOVERY & FORENSIC ] ---
run_pc_recovery() {
    clear
    echo -e "${P}>>> [ RECOVERY & FORENSIC ] <<<${NC}"
    echo "1. Passwords Extraction (LaZagne)"
    echo "2. Reset OS Password (Smart Mode)"
    read -p "Choice: " r_choice
    
    if [ "$r_choice" = "1" ]; then
        python3 /root/lazagne/lazagne.py all -oN /root/passwords.txt
    elif [ "$r_choice" = "2" ]; then
        # Наша "умная" логика сброса (Linux/macOS/Windows)
        WIN_SAM=$(find /mnt /media -type f -name "SAM" -path "*/System32/config/*" 2>/dev/null | head -n 1)
        if [ -n "$WIN_SAM" ]; then
            chntpw -i "$WIN_SAM"
        else
            # Linux/macOS эвристика (упрощенно для стабильности)
            read -p "Username to reset: " U_NAME
            [ -n "$U_NAME" ] && sed -i "s/^$U_NAME:[^:]*:/$U_NAME::/" /etc/shadow
        fi
    fi
    pause
}

# --- [ МОДУЛЬ: UTILS ] ---
run_pwd_gen() {
    clear
    RESULT=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9!#%^*' | head -c 16)
    echo -e "${G}[+] Pass:${NC} $RESULT"; pause
}

run_cert_forge() {
    clear
    read -p "Domain: " S_DOM
    [ -z "$S_DOM" ] && return
    timeout 5 openssl s_client -connect "${S_DOM}:443" </dev/null 2>/dev/null | openssl x509 -noout -subject > /tmp/c.tmp
    [ -s /tmp/c.tmp ] && openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "$(cat /tmp/c.tmp | sed 's/subject=//')" -keyout "/root/$S_DOM.key" -out "/root/$S_DOM.crt"
    pause
}

update_prime() {
    echo -e "${Y}[*] Jumping to update script...${NC}"
    bash /root/updlauncher.sh
    exit 0
}

exit_script() { clear; exit 0; }

# --- [ ГЛАВНОЕ МЕНЮ ] ---
run_main_menu() {
    local names="GHOST_SCAN TOTAL_OSINT PC_RECOVERY PWD_GEN CERT_FORGE UPDATE_CORE EXIT"
    local funcs="run_ghost_commander run_smart_osint run_pc_recovery run_pwd_gen run_cert_forge update_prime exit_script"
    prime_dynamic_controller "PRIME MASTER v$CURRENT_VERSION" "$names" "$funcs"
}

run_main_menu
