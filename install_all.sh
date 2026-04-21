#!/bin/bash

# --- ПРОВЕРКА ПРАВ ---
if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[0;31m[!] Ошибка: Запустите от имени root\033[0m"
  exit
fi

# --- КОНФИГУРАЦИЯ ЦВЕТОВ ---
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

# --- СИСТЕМНОЕ ЯДРО (Survival Mode) ---
repair_and_clean() {
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || echo -e "${Y}[!] Пропуск очистки ядра (нет доступа)${NC}"

    rm -f /root/*.zip /root/*.tmp /root/*.log /root/pip-log.txt 2>/dev/null
    apt-get clean && rm -rf ~/.cache/pip
}

safe_pip() {
    python3 -m pip install --no-cache-dir --break-system-packages "$@" >/dev/null 2>&1
    repair_and_clean
}

install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4
    if [ -f "$name/$exec_file" ] || command -v "$name" &> /dev/null; then return 0; fi
    [ -d "$name" ] && rm -rf "$name"
    curl -L -f "$url" -o "temp.zip" >/dev/null 2>&1
    if [ -s "temp.zip" ]; then
        unzip -q "temp.zip"
        local extracted_dir=$(ls -d */ 2>/dev/null | grep -E "${name}|master|main" | head -n 1)
        if [ -n "$extracted_dir" ]; then
            mv "$extracted_dir" "$name"
            rm -f "temp.zip"
            [ -n "$extra_cmd" ] && (cd "$name" && eval "$extra_cmd" >/dev/null 2>&1)
            [ -f "$name/$exec_file" ] && chmod +x "$name/$exec_file"
        fi
    fi
    repair_and_clean
}

# --- СПИСОК ИНСТРУМЕНТОВ ---
TOOLS=(
    "zphisher;https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip;zphisher.sh;"
    "seeker;https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip;seeker.py;safe_pip -r requirements.txt"
    "wifite2;https://github.com/derv82/wifite2/archive/refs/heads/master.zip;wifite.py;python3 setup.py install --break-system-packages"
    "sqlmap;https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip;sqlmap.py;"
    "routersploit;https://github.com/threat9/routersploit/archive/refs/heads/master.zip;rsf.py;safe_pip -r requirements.txt"
    "sherlock;https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip;sherlock/sherlock.py;safe_pip -r requirements.txt"
    "phoneinfoga;https://github.com/sundowndev/phoneinfoga/archive/refs/heads/master.zip;phoneinfoga.py;safe_pip -r requirements.txt"
    "infoga;https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip;infoga.py;safe_pip -r requirements.txt"
    "phonesploit;https://github.com/Zucccs/PhoneSploit-Python/archive/refs/heads/main.zip;phonesploitpython.py;safe_pip -r requirements.txt"
    "cupp;https://github.com/Mebus/cupp/archive/refs/heads/master.zip;cupp.py;"
    "anonym8;https://github.com/HiroshiSama/anonym8/archive/refs/heads/master.zip;anonym8;chmod +x install.sh && ./install.sh"
)

# --- СТАРТ УСТАНОВКИ ---
clear
echo -e "${R}[*] PRIME v15.3: СБОРКА ПОЛНОГО КОМПЛЕКСА...${NC}"
mkdir -p /root/share
repair_and_clean
apt-get update >/dev/null 2>&1
apt-get install -y php curl unzip python3-pip python3-flask nmap foremost tshark aircrack-ng chkrootkit whatweb htop bluez clamav tor >/dev/null 2>&1

for entry in "${TOOLS[@]}"; do
    IFS=";" read -r t_name t_url t_exec t_extra <<< "$entry"
    install_tool "$t_name" "$t_url" "$t_exec" "$t_extra"
done

# --- ГЕНЕРАЦИЯ ВСЕХ СЕРВЕРОВ ---

# 1. AV-Server
cat << 'EOF' > /root/av_server.py
from flask import Flask, request, render_template_string
import subprocess, os
app = Flask(__name__)
HTML = '<body style="background:#000;color:#0f0;font-family:monospace;padding:20px;"><h2>>>> AV-SCAN <<<</h2><form method="post" action="/scan" enctype="multipart/form-data"><input type="file" name="file"><br><br><button type="submit">SCAN</button></form></body>'
@app.route('/')
def index(): return render_template_string(HTML)
@app.route('/scan', methods=['POST'])
def scan():
    f = request.files['file']
    path = os.path.join('/tmp', f.filename)
    f.save(path)
    res = subprocess.run(['clamscan', '--no-summary', path], capture_output=True, text=True)
    os.remove(path)
    return f"<body style='background:#000;color:#0f0;font-family:monospace;'><pre>{res.stdout}</pre><br><a href='/' style='color:#fff'>Назад</a></body>"
if __name__ == '__main__': app.run(host='0.0.0.0', port=5000)
EOF

# 2. Share-Server
cat << 'EOF' > /root/share_server.py
from flask import Flask, render_template_string, send_from_directory
import os
app = Flask(__name__)
SHARE_DIR = '/root/share'
HTML = '<body style="background:#1a1a1a;color:#eee;text-align:center;padding:20px;"><h2>📁 Files</h2>{% for f in files %}<div style="background:#333;margin:10px;padding:10px;"><a href="/get/{{f}}" style="color:#0f0;">{{f}}</a></div>{% endfor %}</body>'
@app.route('/')
def index(): return render_template_string(HTML, files=os.listdir(SHARE_DIR))
@app.route('/get/<filename>')
def get_file(filename): return send_from_directory(SHARE_DIR, filename)
if __name__ == '__main__': app.run(host='0.0.0.0', port=5000)
EOF

# 3. Upload-Server
cat << 'EOF' > /root/upload_server.py
from flask import Flask, request, render_template_string
import os
app = Flask(__name__)
EXT_SD = next((os.path.join('/storage', d) for d in os.listdir('/storage') if d not in ['self', 'emulated', 'knox']), '/storage/emulated/0')
UPLOAD_DIR = os.path.join(EXT_SD, 'PRIME_INBOX')
if not os.path.exists(UPLOAD_DIR): os.makedirs(UPLOAD_DIR)
HTML = '<body style="background:#0a0a0a;color:#0f0;font-family:monospace;text-align:center;padding:50px;"><h2>>>> DROP BOX <<<</h2><form method="post" action="/upload" enctype="multipart/form-data"><input type="file" name="file" required><br><br><button type="submit">UPLOAD</button></form></body>'
@app.route('/')
def index(): return render_template_string(HTML)
@app.route('/upload', methods=['POST'])
def upload():
    f = request.files['file']
    f.save(os.path.join(UPLOAD_DIR, f.filename))
    return "<h2>FILE RECEIVED</h2><br><a href='/'>Back</a>"
if __name__ == '__main__': app.run(host='0.0.0.0', port=5001)
EOF

# --- ГЕНЕРАЦИЯ LAUNCHER ---
cat << 'EOF' > /root/launcher.sh
#!/bin/bash
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'
repair() { sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true; }
pause() { echo -ne "\n${B}[Enter]...${NC}"; read; }

run_ghost_scan() {
    repair; clear; echo -e "${R}>>> [ GHOST SCAN ] <<<${NC}"
    echo -ne "Target: "; read t; [ -z "$t" ] && return
    if [[ "$t" =~ [a-zA-Z] ]]; then
        whatweb -a 1 "$t" --color=never | grep -E "HTTPS?|Direct"
        nmap -sV -T4 -p80,443 "$t" | grep -vE "Starting|Raw"
    else
        nmap -sV -T4 -Pn --top-ports 100 "$t" | grep -E "PORT|STATE|SERVICE|VERSION|^[0-9]"
    fi
    pause
}

mod_osint() {
    clear; echo -e "${Y}>>> [ SMART OSINT ] <<<${NC}"
    echo -ne "Input: "; read i; [ -z "$i" ] && return
    repair
    if [[ "$i" =~ @ ]]; then cd /root/infoga && python3 infoga.py --target "$i"
    elif [[ "$i" =~ ^\+ ]]; then cd /root/phoneinfoga && python3 phoneinfoga.py -n "$i"
    else python3 /root/sherlock/sherlock/sherlock.py "$i" --timeout 1 --print-found; fi
    pause
}

mod_device_hack() {
    clear; echo -e "${R}>>> [ DEVICE HACK ] <<<${NC}"
    echo -e "1) BT Scan\n2) ADB PhoneSploit\n3) Deep Grep (Secrets)\n0) Back"
    read -p ">> " m4
    case $m4 in
        1) hcitool scan; pause ;;
        2) cd /root/phonesploit && python3 phonesploitpython.py ;;
        3) read -p "Path: " p; grep -rnE "password|token|secret" "$p" 2>/dev/null | head -n 20; pause ;;
    esac
}

mod_security() {
    clear; echo -e "${G}>>> [ SECURITY HUB ] <<<${NC}"
    echo -e "1) VPN/TOR\n2) AV-HUB\n3) SHARE-HUB\n4) UPLOAD-HUB\n5) My IP\n0) Back"
    read -p ">> " m5
    case $m5 in
        1) a8 status; echo "a)Start b)Stop"; read x; [[ $x == "a" ]] && a8 start || a8 stop; pause ;;
        2) python3 /root/av_server.py ;;
        3) 
            EXT_SD=$(ls -d /storage/* 2>/dev/null | grep -vE "self|emulated" | head -n 1)
            BASE=${EXT_SD:-"/storage/emulated/0"}
            cp -r "$BASE/shared"/. /root/share/ 2>/dev/null
            ip=$(hostname -I | awk '{print $1}')
            echo "http://$ip:5000"; python3 /root/share_server.py
            rm -rf /root/share/*; pause ;;
        4) ip=$(hostname -I | awk '{print $1}')
           echo "http://$ip:5001"; python3 /root/upload_server.py; pause ;;
        5) curl -s https://ifconfig.me; echo; pause ;;
    esac
}

while true; do
    repair; clear
    echo -e "${R}========== [ PRIME MASTER v15.3 ] ==========${NC}"
    echo -e "G) [ GHOST SCAN ]  1) [ SOCIAL ENG ]"
    echo -e "2) [ SQLMAP ]      3) [ SMART OSINT ]"
    echo -e "4) [ DEVICE HACK ] 5) [ SECURITY HUB ]"
    echo -e "s) MONITOR (HTOP)  0) EXIT"
    echo -ne "\n${Y}>> Vector: ${NC}"
    read opt
    case $opt in
        g|G) run_ghost_scan ;; 1) cd /root/zphisher && ./zphisher.sh ;;
        2) cd /root/sqlmap && python3 sqlmap.py --wizard ;;
        3) mod_osint ;; 4) mod_device_hack ;; 5) mod_security ;;
        s) htop ;; 0) exit 0 ;;
    esac
done
EOF

chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
repair_and_clean
echo -e "\n${G}[✔] PRIME v15.3 ПОЛНЫЙ КОМПЛЕКС ГОТОВ. Введи: launcher${NC}"
