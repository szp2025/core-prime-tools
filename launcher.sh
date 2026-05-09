#!/bin/bash

# --- [ CONFIG & COLORS ] ---
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; B='\033[1;34m'
P='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; NC='\033[0m'
CURRENT_VERSION="34.8"

# --- [ СЛУЖЕБНЫЕ ФУНКЦИИ ] ---
smart_cat() { cat << EOF > "$1"
$2
EOF
}

pause() { echo -e "\n${Y}[ PRESS ENTER TO RETURN ]${NC}"; read _; }

draw_header() {
    clear
    echo -e "${R}  ━━━━━━━━━━━━━ [ ${W}$1 ${R}] ━━━━━━━━━━━━━${NC}"
    echo -e "${G} RAM: $(free -m | awk '/Mem:/ {print $3 "/" $2 "MB"}') | ROM: $(df -h / | awk 'NR==2 {print $3 "/" $2}') | NET: ONLINE${NC}"
    echo -e "${W} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- [ ТВОИ ШАБЛОНЫ ДИЗАЙНА (WEB UI) ] ---
generate_core_template() {
    echo '
def render_prime_page(title, content):
    style = """
    <style>
        body { background: #050505; color: #00ff41; font-family: "Courier New", monospace; margin: 0; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; }
        .container { border: 1px solid #00ff41; padding: 30px; background: #111; box-shadow: 0 0 20px rgba(0,255,65,0.1); border-radius: 5px; width: 90%; max-width: 900px; text-align: center; }
        h2 { border-bottom: 1px solid #00ff41; padding-bottom: 10px; text-transform: uppercase; letter-spacing: 2px; margin-top: 0; color: #00ff41; }
        .btn, button { background: #00ff41; color: #000; border: none; padding: 12px 24px; cursor: pointer; font-weight: bold; text-transform: uppercase; text-decoration: none; display: inline-block; width: 100%; transition: 0.3s; margin-top: 20px; font-family: inherit; }
        .btn:hover, button:hover { background: #008f25; box-shadow: 0 0 15px #00ff41; }
        pre { white-space: pre-wrap; font-size: 0.85em; color: #0cf; background: #000; padding: 15px; border: 1px solid #222; text-align: left; max-height: 300px; overflow-y: auto; }
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 15px; margin-top: 20px; }
        .file-card { background: #1a1a1a; border: 1px solid #333; padding: 15px; color: #00ff41; text-decoration: none; font-size: 0.8em; word-break: break-all; transition: 0.2s; }
        .file-card:hover { border-color: #00ff41; background: #00ff4111; }
        .status-box { padding: 15px; margin-bottom: 15px; font-weight: bold; border: 1px solid; text-transform: uppercase; }
        .clean { color: #00ff41; border-color: #00ff41; }
        .infected { color: #ff3e3e; border-color: #ff3e3e; }
    </style>
    """
    return f"{style}<div class='container'><h2>> {title}</h2><div class='content-area'>{content}</div></div>"
'
}

generate_core_form_template() {
    echo '
def render_prime_form(action_url, fields=None, btn_text="EXECUTE"):
    if fields is None: fields = [{"type": "file", "name": "file"}]
    inputs_html = "".join([f"<div style='\''margin-bottom: 15px;'\'''>" + (f"<label style='\''display:block; font-size:0.7em; color:#888;'\'''>{f.get('\''label'\'')}</label>" if f.get('\''label'\'') else "") + f"<input type='\''{f.get('\''type'\'', '\''text'\'')}'\'' name='\''{f.get('\''name'\'')}'\'' placeholder='\''{f.get('\''placeholder'\'', '\'''\'')}'\'' required style='\''background:#111; color:#00ff41; border:1px dashed #333; padding:10px; width:80%; font-family:inherit;'\''></div>" for f in fields])
    return f"""<form method="post" action="{action_url}" enctype="multipart/form-data" style="margin-top:20px;">{inputs_html}<button type="submit">{btn_text}</button></form>"""
'
}

# --- [ ГЕНЕРАТОРЫ WEB-МОДУЛЕЙ ] ---
generate_av_server_code() {
    local t="$(generate_core_template)$(generate_core_form_template)"
    local code=$(cat << EOF
from flask import Flask, request, render_template_string
import subprocess, os, shutil
app = Flask(__name__)
$t
@app.route('/')
def index():
    return render_template_string(render_prime_page("SECURE_GATEWAY", render_prime_form("/scan", [{"type": "file", "name": "file", "label": "TARGET"}], "SCAN")))
@app.route('/scan', methods=['POST'])
def scan():
    f = request.files['file']; p = os.path.join('/tmp', f.filename); f.save(p)
    res = subprocess.run(['clamscan', '--no-summary', p], capture_output=True, text=True)
    inf = "FOUND" in res.stdout or "Infected" in res.stdout
    c = f'<div class="status-box {"infected" if inf else "clean"}">{"THREAT" if inf else "OK"}</div><pre>{res.stdout}</pre><a href="/" class="btn">BACK</a>'
    os.remove(p)
    return render_template_string(render_prime_page("RESULTS", c))
if __name__ == "__main__":
    os.system('fuser -k 5000/tcp 2>/dev/null')
    app.run(host="0.0.0.0", port=5000, ssl_context=("/root/cert.pem", "/root/key.pem"))
EOF
)
    smart_cat "/root/av_server.py" "$code"
}

generate_share_server_code() {
    local t=$(generate_core_template)
    local code=$(cat << EOF
from flask import Flask, render_template_string, send_from_directory
import os
app = Flask(__name__)
SHARE_DIR = '/root/share'
if not os.path.exists(SHARE_DIR): os.makedirs(SHARE_DIR)
$t
@app.route('/')
def index():
    files = os.listdir(SHARE_DIR)
    grid = '<div class="grid">' + "".join([f'<a href="/get/{f}" class="file-card">📄<br>{f}</a>' for f in files]) + '</div>'
    return render_template_string(render_prime_page("FILE_DISTRIBUTION", grid))
@app.route('/get/<f>')
def get_file(f): return send_from_directory(SHARE_DIR, f)
if __name__ == "__main__":
    os.system('fuser -k 5002/tcp 2>/dev/null')
    app.run(host="0.0.0.0", port=5002)
EOF
)
    smart_cat "/root/share_server.py" "$code"
}

# --- [ ВСЕ ФУНКЦИИ ИНСТРУМЕНТОВ ] ---

run_ghost() { draw_header "GHOST SCAN"; read -p "Target IP: " t; [ -z "$t" ] && python3 /root/Ghost/ghost.py || python3 /root/Ghost/ghost.py --connect "$t"; pause; }
run_sqlmap() { draw_header "SQLMAP ENGINE"; read -p "Target URL: " u; [ -n "$u" ] && sqlmap -u "$u" --batch --random-agent; pause; }
run_osint() { draw_header "SMART OSINT"; read -p "Input: " i; socialscan "$i"; maigret "$i"; pause; }
run_iban() { draw_header "IBAN VALIDATOR"; read -p "IBAN: " i; [[ "$i" =~ ^[A-Z]{2}[0-9]{2} ]] && echo -e "${G}[+] VALID${NC}" || echo -e "${R}[-] INVALID${NC}"; pause; }
run_pwd_gen() { draw_header "PWD GEN"; echo -e "${G}Pass: ${W}$(date +%s%N | md5sum | head -c 16)${NC}"; pause; }

run_exploit_hub() {
    while true; do
        draw_header "EXPLOIT HUB"
        echo -e " 1) PhoneSploit Pro   2) SQLmap\n 3) Nmap Network      4) Metasploit\n B) BACK"
        read -p " » " c
        case $c in
            1) cd /root/PhoneSploit-Pro && python3 phonesploitpro.py ;;
            2) run_sqlmap ;;
            3) nmap -T4 192.168.1.0/24; pause ;;
            4) msfconsole ;;
            [Bb]*) break ;;
        esac
    done
}

run_repair_hub() {
    while true; do
        draw_header "SECURITY & DATA HUB"
        echo -e " 1) AV-Scanner (5000)  2) Share-File (5002)\n 3) Upload-Inbound      B) BACK"
        read -p " » " c
        case $c in
            1) generate_av_server_code; python3 /root/av_server.py ;;
            2) generate_share_server_code; python3 /root/share_server.py ;;
            3) python3 -m http.server 5001 ;; # Упрощенный аплоад
            [Bb]*) break ;;
        esac
    done
}

# --- [ ГЛАВНОЕ МЕНЮ (14+ ФУНКЦИЙ) ] ---
run_main_menu() {
    while true; do
        draw_header "PRIME MASTER v$CURRENT_VERSION"
        echo -e "  ${G}1) GHOST SCAN          2) SOCIAL ENG"
        echo -e "  3) SQLMAP              4) SMART OSINT"
        echo -e "  5) DEVICE HACK         6) EXPLOIT HUB"
        echo -e "  7) AIO OSINT AUTO      8) IBAN SCAN"
        echo -e "  9) PWD GENERATOR      10) REPAIR / SEC"
        echo -e " 11) UPDATE CORE        12) SERVICE HUB"
        echo -e " 13) SYSTEM INFO        14) CERT FORGE"
        echo -e "\n  15) EXIT${NC}"
        echo -e "${W} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        read -p " » " m
        case $m in
            1) run_ghost ;;
            2) cd /root/zphisher && bash zphisher.sh ;;
            3) run_sqlmap ;;
            4) run_osint ;;
            5) msfconsole ;;
            6) run_exploit_hub ;;
            7) cd /root/seeker && python3 seeker.py ;;
            8) run_iban ;;
            9) run_pwd_gen ;;
            10) run_repair_hub ;;
            11) bash /root/updlauncher.sh ;;
            12) systemctl list-units --type=service --state=running | head -n 15; pause ;;
            13) uname -a; uptime; pause ;;
            14) echo "Forging..."; openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes; pause ;;
            15) exit 0 ;;
            *) echo "Invalid Option"; sleep 1 ;;
        esac
    done
}

run_main_menu
