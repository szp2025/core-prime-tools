#!/bin/bash

# --- [ CONFIG & COLORS ] ---
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; B='\033[1;34m'
P='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; NC='\033[0m'
CURRENT_VERSION="34.0"

# --- [ SYSTEM CORE ] ---
get_ram() { free -m | awk '/Mem:/ {print $3 "/" $2 "MB"}'; }
get_rom() { df -h / | awk 'NR==2 {print $3 "/" $2}'; }
pause() { echo -e "\n${Y}[ PRESS ENTER TO RETURN ]${NC}"; read _; }

draw_header() {
    clear
    echo -e "${R}  ━━━━━━━━━━━━━ [ ${W}$1 ${R}] ━━━━━━━━━━━━━${NC}"
    echo -e "${G} RAM: $(get_ram) | ROM: $(get_rom) | NET: ONLINE${NC}"
    echo -e "${W} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- [ ДИНАМИЧЕСКАЯ ГЕНЕРАЦИЯ СКРИПТОВ ] ---

generate_services() {
    # 1. IBAN CHECKER (Python logic)
    cat << 'EOF' > /root/iban_check.py
import sys, re
def check_iban(iban):
    iban = re.sub(r'\s+', '', iban).upper()
    if not re.match(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{4,30}$', iban): return False
    return True
if __name__ == "__main__":
    if len(sys.argv) > 1:
        print("VALID" if check_iban(sys.argv[1]) else "INVALID")
EOF

    # 2. AV SERVER (Security scan)
    cat << 'EOF' > /root/av_server.py
import os, subprocess
def run_scan():
    print("--- STARTING CLAMAV SCAN ---")
    subprocess.run(["clamscan", "-r", "/root"])
if __name__ == "__main__": run_scan()
EOF

    # 3. SHARE SERVER (File Sharing)
    cat << 'EOF' > /root/share_server.py
import http.server, socketserver
PORT = 8080
Handler = http.server.SimpleHTTPRequestHandler
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving at port {PORT}. Press Ctrl+C to stop.")
    httpd.serve_forever()
EOF

    # 4. UPLOAD SERVER (Inbound Receiver)
    cat << 'EOF' > /root/upload_server.py
import os
from flask import Flask, request
app = Flask(__name__)
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files: return 'No file'
    file = request.files['file']
    file.save(os.path.join('/root/uploads', file.filename))
    return 'Upload Success'
if __name__ == "__main__":
    if not os.path.exists('/root/uploads'): os.makedirs('/root/uploads')
    app.run(host='0.0.0.0', port=5000)
EOF
}

# Инициализация сервисов при старте
generate_services

# --- [ МОДУЛИ СЕРВИСОВ ] ---

run_iban_scan() {
    draw_header "IBAN SCANNER"
    read -p " Enter IBAN to check: " iban
    res=$(python3 /root/iban_check.py "$iban")
    [ "$res" == "VALID" ] && echo -e "${G}[+] $res${NC}" || echo -e "${R}[-] $res${NC}"
    pause
}

run_repair_hub() {
    while true; do
        draw_header "SECURITY & DATA HUB"
        echo -e "  ${G}1) Run AV-Server (ClamAV)    2) Start Share-Server (8080)"
        echo -e "  3) Start Upload-Server (5000) 4) Clear System Logs${NC}"
        echo -e "\n  ${W}B) BACK${NC}"
        read -p " » " c
        case $c in
            1) python3 /root/av_server.py; pause ;;
            2) python3 /root/share_server.py ;;
            3) python3 /root/upload_server.py ;;
            4) rm -rf /root/.bash_history && history -c; echo "Done"; pause ;;
            [Bb]*) break ;;
        esac
    done
}

# --- [ ОСТАЛЬНЫЕ ФУНКЦИИ (Сокращено для примера, оставь как в прошлом коде) ] ---

run_ghost_scan() { draw_header "GHOST SCAN"; read -p " Target: " t; [ -z "$t" ] && ghost || ghost -connect "$t"; pause; }
run_sqlmap() { read -p " URL: " u; [ -n "$u" ] && sqlmap -u "$u" --batch; pause; }
run_smart_osint() { read -p " Input: " i; socialscan "$i"; pause; }
run_exploit_hub() { 
    draw_header "EXPLOIT HUB"
    echo -e " 1) PhoneSploit Pro\n 2) SQLmap\n 3) Metasploit"
    read -p " » " c
    case $c in
        1) cd /root/PhoneSploit-Pro && python3 phonesploitpro.py ;;
        2) run_sqlmap ;;
        3) msfconsole ;;
    esac
}

# --- [ MAIN MENU ] ---

run_main_menu() {
    while true; do
        draw_header "PRIME MASTER v$CURRENT_VERSION"
        echo -e "  ${G}1) GHOST SCAN          2) SOCIAL ENG"
        echo -e "  3) SQLMAP              4) SMART OSINT"
        echo -e "  5) DEVICE HACK         6) EXPLOIT HUB"
        echo -e "  7) AIO OSINT AUTO      8) IBAN/RIB SCAN"
        echo -e "  9) PC RECOVERY        10) REPAIR / SEC"
        echo -e " 11) UPDATE CORE        12) SERVICE HUB"
        echo -e " 13) SYSTEM INFO        14) CERT FORGE"
        echo -e "\n  ${W}15) EXIT${NC}"
        echo -e "${W} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        read -p " » " m_choice
        case $m_choice in
            1) run_ghost_scan ;;
            2) cd /root/zphisher && bash zphisher.sh ;;
            3) run_sqlmap ;;
            4) run_smart_osint ;;
            5) msfconsole ;;
            6) run_exploit_hub ;;
            7) cd /root/seeker && python3 seeker.py ;;
            8) run_iban_scan ;;
            9) # Твоя логика PC RECOVERY
               echo "Recovery mode..."; pause ;;
            10) run_repair_hub ;;
            11) bash /root/updlauncher.sh ;;
            12) systemctl list-units --type=service --state=running | head -n 15; pause ;;
            13) uname -a; uptime; pause ;;
            14) # Твоя логика CERT FORGE
               echo "Cert forging..."; pause ;;
            15) exit 0 ;;
        esac
    done
}

run_main_menu