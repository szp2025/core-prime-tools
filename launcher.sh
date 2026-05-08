#!/bin/bash

# --- [ CONFIG & COLORS ] ---
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; B='\033[1;34m'
P='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; NC='\033[0m'
CURRENT_VERSION="33.8"

# --- [ SYSTEM CORE ] ---
pause() { echo -e "\n${Y}[ PRESS ENTER TO BACK ]${NC}"; read _; }

draw_header() {
    clear
    local title=$1
    echo -e "${R}  ━━━━━━━ [ ${W}$title ${R}] ━━━━━━━${NC}"
    echo -e "${G} RAM: $(free -m | awk '/Mem:/ {print $3 "/" $2 "MB"}') | ROM: $(df -h / | awk 'NR==2 {print $3 "/" $2}') | SD: N/A${NC}"
    echo -e "${G} NET: ONLINE | ACTIVE SRV:${R}NONE${NC}"
    echo -e "${W} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- [ ХАБЫ ИЗ СКРИНШОТОВ ] ---

# 6) EXPLOIT HUB (Скриншот 1000054712)
run_exploit_hub() {
    while true; do
        draw_header "EXPLOIT HUB"
        echo -e "  ${G}1) PhoneSploit Pro     2) SQLmap/Web"
        echo -e "  3) PC/Network Scan     4) PC Control${NC}"
        echo -e "\n  ${W}B) BACK / EXIT${NC}"
        echo -e "${W} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        read -p " » " choice
        case $choice in
            1) cd /root/PhoneSploit-Pro && python3 phonesploitpro.py ;;
            2) run_sqlmap ;;
            3) nmap -T4 -A 192.168.1.0/24 ;;
            4) msfconsole ;;
            [Bb]*) break ;;
        esac
    done
}

# 10) REPAIR / SECURITY HUB (Скриншот 1000054711)
run_repair_hub() {
    while true; do
        draw_header "SECURITY & DATA HUB"
        echo -e "  ${G}1) AV-Scanner          2) Share-File"
        echo -e "  3) Upload-Inbound${NC}"
        echo -e "\n  ${W}B) BACK / EXIT${NC}"
        echo -e "${W} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        read -p " » " choice
        case $choice in
            1) clamscan -r /root ;;
            2) python3 -m http.server 8080 ;;
            3) read -p "URL: " u; wget "$u" ;;
            [Bb]*) break ;;
        esac
    done
}

# --- [ ОСНОВНЫЕ ФУНКЦИИ ] ---

run_ghost_scan() { draw_header "GHOST SCAN"; read -p "Target: " t; ghost -connect "$t"; pause; }
run_social_eng() { cd /root/zphisher && bash zphisher.sh; }
run_sqlmap() { read -p "URL: " u; sqlmap -u "$u" --batch --random-agent; pause; }
run_smart_osint() { read -p "Nick/Mail: " i; socialscan "$i"; maigret "$i"; pause; }
run_device_hack() { msfconsole -q; }
run_aio_osint() { cd /root/seeker && python3 seeker.py; }
run_iban_scan() { read -p "IBAN: " i; [[ "$i" =~ ^[A-Z]{2}[0-9]{2} ]] && echo "Valid format" || echo "Invalid"; pause; }
run_sys_info() { draw_header "SYS INFO"; uname -a; uptime; pause; }
run_service_hub() { systemctl list-units --type=service --state=running; pause; }
update_core() { bash /root/updlauncher.sh; }

# --- [ ГЛАВНЫЙ КОНТРОЛЛЕР (Скриншот 1000054710) ] ---

run_main_menu() {
    while true; do
        draw_header "PRIME MASTER v$CURRENT_VERSION"
        echo -e "  ${G}1) GHOST SCAN          2) SOCIAL ENG"
        echo -e "  3) SQLMAP              4) SMART OSINT"
        echo -e "  5) DEVICE HACK         6) EXPLOIT HUB"
        echo -e "  7) AIO OSINT AUTO      8) IBAN/RIB SCAN"
        echo -e "  9) MANUAL INSTALL     10) REPAIR"
        echo -e " 11) UPDATE CORE        12) SERVICE HUB"
        echo -e " 13) SYSTEM INFO        14) EXIT${NC}"
        echo -e "\n  ${W}B) BACK / EXIT${NC}"
        echo -e "${W} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        read -p " » " m_choice
        case $m_choice in
            1) run_ghost_scan ;;
            2) run_social_eng ;;
            3) run_sqlmap ;;
            4) run_smart_osint ;;
            5) run_device_hack ;;
            6) run_exploit_hub ;;
            7) run_aio_osint ;;
            8) run_iban_scan ;;
            9) echo "Manual mode..."; sleep 1 ;;
            10) run_repair_hub ;;
            11) update_core ;;
            12) run_service_hub ;;
            13) run_sys_info ;;
            14|[Bb]*) exit 0 ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

run_main_menu
