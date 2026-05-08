#!/bin/bash

# --- [ CONFIG & COLORS ] ---
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; B='\033[1;34m'
P='\033[1;35m'; C='\033[1;36m'; NC='\033[0m'
CURRENT_VERSION="31.6"

# --- [ SYSTEM CORE ] ---
pause() { echo -e "\n${Y}[ PRESS ENTER ]${NC}"; read _; }

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
        [ -z "$func" ] && break
        $func
    done
}

# --- [ МОДУЛИ: EXPLOITATION ] ---

run_ghost_scan() {
    clear; echo -e "${R}>>> [ GHOST COMMANDER ] <<<${NC}"
    read -p "Target IP (Leave empty for console): " t
    if [ -z "$t" ]; then cd /root/Ghost && python3 -m ghost
    else cd /root/Ghost && python3 -m ghost --execute "connect $t"; fi
    pause
}

run_phishing() {
    clear; echo -e "${C}>>> [ SOCIAL ENGINEERING ] <<<${NC}"
    cd /root/zphisher && bash zphisher.sh
}

run_sqlmap() {
    clear; echo -e "${Y}>>> [ SQLMAP ENGINE ] <<<${NC}"
    read -p "Target URL: " u; [ -z "$u" ] && return
    sqlmap -u "$u" --batch --random-agent --level=3
    pause
}

run_device_hack() {
    clear; echo -e "${R}>>> [ DEVICE HACK ENGINE ] <<<${NC}"
    # Интеграция PhoneSploit или Metasploit
    msfconsole -q -x "help"
    pause
}

run_exploit_hub() {
    clear; echo -e "${P}>>> [ EXPLOIT HUB ] <<<${NC}"
    searchsploit --update
    read -p "Search Term: " s
    searchsploit "$s"
    pause
}

# --- [ МОДУЛИ: OSINT & RECOVERY ] ---

run_smart_osint() {
    clear; echo -e "${C}>>> [ SMART OSINT 2026 ] <<<${NC}"
    read -p "Input: " i; [ -z "$i" ] && return
    socialscan "$i"
    if [[ "$i" =~ @ ]]; then python3 /root/infoga/infoga.py --target "$i"
    else maigret "$i" --parse --timeout 15; fi
    pause
}

run_pc_recovery_ultimate() {
    clear; echo -e "${B}>>> [ PC RECOVERY & FORENSIC ] <<<${NC}"
    echo -e "1. Extract Passwords (LaZagne)\n2. Reset OS Password"
    read -p "> " c
    if [ "$c" = "1" ]; then python3 /root/lazagne/lazagne.py all -oN /root/pass.txt
    elif [ "$c" = "2" ]; then
        # Эвристика: ищем SAM для Windows или работаем с Linux Shadow
        sam=$(find /mnt /media -type f -name "SAM" -path "*/System32/config/*" 2>/dev/null | head -n 1)
        if [ -n "$sam" ]; then chntpw -i "$sam"
        else 
            read -p "Linux Username: " u
            [ -n "$u" ] && sed -i "s/^$u:[^:]*:/$u::/" /etc/shadow && echo "Pass cleared."
        fi
    fi
    pause
}

# --- [ МОДУЛИ: UTILS ] ---

run_pwd_gen() {
    clear; echo -e "${Y}>>> [ PASSWORD GENERATOR ] <<<${NC}"
    read -p "Length: " l; [ -z "$l" ] && l=16
    res=$(openssl rand -base64 64 | tr -dc 'A-Za-z0-9!#%^*' | head -c "$l")
    echo -e "${G}[+] Pass:${NC} $res"; pause
}

run_cert_forge() {
    clear; read -p "Domain: " d; [ -z "$d" ] && return
    timeout 5 openssl s_client -connect "${d}:443" </dev/null 2>/dev/null | openssl x509 -noout -subject > /tmp/c.tmp
    [ -s /tmp/c.tmp ] && openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "$(cat /tmp/c.tmp | sed 's/subject=//')" -keyout "/root/$d.key" -out "/root/$d.crt"
    echo "Done: /root/$d.crt"; rm /tmp/c.tmp; pause
}

# --- [ CORE CONTROL ] ---

update_core() { bash /root/updlauncher.sh; exit 0; }
exit_script() { clear; echo "Exiting..."; exit 0; }

run_main_menu() {
    local names="GHOST_SCAN SOCIAL_ENG SQLMAP DEVICE_HACK EXPLOIT_HUB TOTAL_OSINT PC_RECOVERY PWD_GEN CERT_FORGE UPDATE EXIT"
    local funcs="run_ghost_scan run_phishing run_sqlmap run_device_hack run_exploit_hub run_smart_osint run_pc_recovery_ultimate run_pwd_gen run_cert_forge update_core exit_script"
    prime_dynamic_controller "PRIME MASTER v$CURRENT_VERSION" "$names" "$funcs"
}

run_main_menu
