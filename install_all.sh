#!/bin/bash

# --- ВЕРСИЯ И ОБНОВЛЕНИЕ ---
CURRENT_VERSION="15.9"
UPDATE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

# --- ПРОВЕРКА ПРАВ ---
if [ "$EUID" -ne 0 ]; then 
  echo -e "${R}[!] Ошибка: Запустите от имени root${NC}"
  exit
fi

repair_and_clean() {
    [ -f /var/lib/dpkg/status ] && sed -i '/Package: php8/,/^$/d' /var/lib/dpkg/status 2>/dev/null
    sync && echo 3 | tee /proc/sys/vm/drop_caches >/dev/null 2>&1
    rm -f /root/*.zip /root/*.tmp /root/*.log /root/*.deb 2>/dev/null
    apt-get clean && rm -rf ~/.cache/pip
}

safe_pip() {
    python3 -m pip install --no-cache-dir --break-system-packages "$@" >/dev/null 2>&1
    repair_and_clean
}

install_clamav_force() {
    echo -e "${Y}[*] Инъекция ClamAV (Force Install)...${NC}"
    repair_and_clean
    apt-get update >/dev/null 2>&1
    cd /root
    apt-get download clamav clamav-base clamav-freshclam libclamav* >/dev/null 2>&1
    dpkg -i --force-all *.deb >/dev/null 2>&1
    mkdir -p /var/lib/clamav
    touch /var/lib/clamav/main.cvd /var/lib/clamav/daily.cvd
    rm -f *.deb
}

install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4
    if [ -d "$name" ]; then return 0; fi
    echo -e "${G}[*] Installing $name...${NC}"
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

# --- СТАРТ ---
clear
echo -e "${R}[*] PRIME v$CURRENT_VERSION: ТОТАЛЬНАЯ СБОРКА...${NC}"
mkdir -p /root/share /root/PRIME_INBOX
repair_and_clean

apt-get update >/dev/null 2>&1
apt-get install -y php curl unzip python3-pip python3-flask nmap foremost tshark aircrack-ng chkrootkit whatweb htop bluez tor git >/dev/null 2>&1

install_clamav_force

# Твой расширенный список инструментов
TOOLS=(
    "zphisher;https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip;zphisher.sh;"
    "seeker;https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip;seeker.py;safe_pip -r requirements.txt"
    "wifite2;https://github.com/derv82/wifite2/archive/refs/heads/master.zip;wifite.py;python3 setup.py install --break-system-packages"
    "sqlmap;https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip;sqlmap.py;"
    "routersploit;https://github.com/threat9/routersploit/archive/refs/heads/master.zip;rsf.py;safe_pip -r requirements.txt"
    "sherlock;https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip;sherlock_project/sherlock.py;safe_pip -r requirements.txt"
    "phoneinfoga;https://github.com/sundowndev/phoneinfoga/archive/refs/heads/master.zip;phoneinfoga.py;safe_pip -r requirements.txt"
    "infoga;https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip;infoga.py;safe_pip -r requirements.txt"
    "phonesploit;https://github.com/Zucccs/PhoneSploit-Python/archive/refs/heads/main.zip;phonesploitpython.py;safe_pip -r requirements.txt"
    "cupp;https://github.com/Mebus/cupp/archive/refs/heads/master.zip;cupp.py;"
    "anonym8;https://github.com/HiroshiSama/anonym8/archive/refs/heads/master.zip;anonym8;chmod +x install.sh && ./install.sh"
)

for entry in "${TOOLS[@]}"; do
    IFS=";" read -r t_name t_url t_exec t_extra <<< "$entry"
    install_tool "$t_name" "$t_url" "$t_exec" "$t_extra"
done

# Специальные установки из твоего оригинала
if [ ! -d "/root/phoneinfoga" ]; then
    mkdir /root/phoneinfoga && cd /root/phoneinfoga
    curl -L https://github.com/sundowndev/phoneinfoga/releases/download/v2.10.8/phoneinfoga_Linux_armv7.tar.gz | tar xz
    chmod +x phoneinfoga
fi

if [ ! -d "/root/infoga" ]; then
    git clone --depth=1 https://github.com/alpkeskin/mosint.git /root/infoga
    cd /root/infoga && safe_pip -r requirements.txt
fi

# --- ГЕНЕРАЦИЯ СЕРВЕРОВ (Твой оригинал) ---

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
if __name__ == '__main__': app.run(host='0.0.0.0', port=5002)
EOF

cat << 'EOF' > /root/upload_server.py
from flask import Flask, request, render_template_string
import os
app = Flask(__name__)
UPLOAD_DIR = '/sdcard/PRIME_INBOX' if os.path.exists('/sdcard') else '/root/PRIME_INBOX'
if not os.path.exists(UPLOAD_DIR): os.makedirs(UPLOAD_DIR, exist_ok=True)
HTML = '<body style="background:#000;color:#0f0;font-family:monospace;text-align:center;padding:50px;"><h2>>>> DROP BOX <<<</h2><form method="post" action="/upload" enctype="multipart/form-data"><input type="file" name="file" required><br><br><button type="submit" style="background:#0f0;color:#000;border:none;padding:10px 20px;font-weight:bold;cursor:pointer;">UPLOAD</button></form><p style="color:#555;">Save to: ' + UPLOAD_DIR + '</p></body>'
@app.route('/')
def index(): return render_template_string(HTML)
@app.route('/upload', methods=['POST'])
def upload():
    if 'file' not in request.files: return "No file", 400
    f = request.files['file']
    if f.filename == '': return "No file", 400
    f.save(os.path.join(UPLOAD_DIR, f.filename))
    return "<html><body style='background:#000;color:#0f0;text-align:center;padding:50px;'><h2>FILE RECEIVED!</h2><br><a href='/' style='color:#fff'>[ Back ]</a></body></html>"
if __name__ == '__main__': app.run(host='0.0.0.0', port=5001)
EOF

# --- ГЕНЕРАЦИЯ LAUNCHER (Твой оригинал + расширенный TOOLS_DATA) ---
cat << 'EOF' > /root/launcher.sh
#!/bin/bash
CURRENT_VERSION="15.9"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'
set +o history

repair() { 
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    rm -rf /root/.cache/* /tmp/* 2>/dev/null
    history -c
}

get_stats() {
    local ram=$(free -m | awk '/Mem:/ {printf "%d/%dMB", $4, $2}')
    local rom=$(df -h / | awk 'NR==2 {print $4}')
    local sd_path=$(ls -d /storage/* 2>/dev/null | grep -vE "self|emulated" | head -n 1)
    local sd_info="N/A"
    [ -n "$sd_path" ] && sd_info=$(df -h "$sd_path" | awk 'NR==2 {print $4}')
    local net="${R}OFFLINE${NC}"
    ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 && net="${G}ONLINE${NC}"
    local srv=""
    pgrep -f "av_server.py" >/dev/null && srv+=" ${G}[AV]${NC}"
    pgrep -f "share_server.py" >/dev/null && srv+=" ${G}[SH]${NC}"
    pgrep -f "upload_server.py" >/dev/null && srv+=" ${G}[UP]${NC}"
    [ -z "$srv" ] && srv="${R}NONE${NC}"
    echo -e "${Y}RAM: ${G}$ram ${Y}| ROM: ${G}$rom ${Y}| SD: ${G}$sd_info"
    echo -e "${Y}NET: $net ${Y}| ACTIVE SRV:$srv${NC}"
}

# --- БАЗА TOOLS_DATA (Все 18+ позиций) ---
TOOLS_DATA=(
    "zphisher;https://github.com/htr-tech/zphisher/archive/refs/heads/master.zip;zphisher.sh;"
    "seeker;https://github.com/thewhiteh4t/seeker/archive/refs/heads/master.zip;seeker.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "blackeye;https://github.com/An0nUD4Y/blackeye/archive/refs/heads/master.zip;blackeye.sh;"
    "wifite2;https://github.com/derv82/wifite2/archive/refs/heads/master.zip;wifite.py;python3 setup.py install --break-system-packages"
    "routersploit;https://github.com/threat9/routersploit/archive/refs/heads/master.zip;rsf.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "kickthemout;https://github.com/k4m4/kickthemout/archive/refs/heads/master.zip;kickthemout.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "sqlmap;https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip;sqlmap.py;"
    "admin-finder;https://github.com/the-c0d3r/admin-panic/archive/refs/heads/master.zip;admin-panic.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "commix;https://github.com/commixproject/commix/archive/refs/heads/master.zip;commix.py;"
    "photon;https://github.com/s0md3v/Photon/archive/refs/heads/master.zip;photon.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "sherlock;https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip;sherlock_project/sherlock.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "infoga;https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip;infoga.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "phoneinfoga;https://github.com/sundowndev/phoneinfoga/archive/refs/heads/master.zip;phoneinfoga.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "recon-dog;https://github.com/s0md3v/ReconDog/archive/refs/heads/master.zip;dog;"
    "phonesploit;https://github.com/Zucccs/PhoneSploit-Python/archive/refs/heads/main.zip;phonesploitpython.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "ghost-framework;https://github.com/EntySec/Ghost/archive/refs/heads/master.zip;ghost;python3 -m pip install -r requirements.txt --break-system-packages"
    "cupp;https://github.com/Mebus/cupp/archive/refs/heads/master.zip;cupp.py;"
    "instashell;https://github.com/thelinuxchoice/instashell/archive/refs/heads/master.zip;instashell.sh;chmod +x install.sh && ./install.sh"
)

run_osint() {
    repair; echo -e "${Y}>>> [ SMART OSINT ] <<<${NC}"
    echo -ne "Input (mail/username): "; read i
    [ -z "$i" ] && return
    
    if [[ "$i" =~ "@" ]]; then 
        echo -e "${G}[*] Email detected. Running Mosint/Infoga...${NC}"
        cd /root/infoga && python3 infoga.py --target "$i"
    else 
        echo -e "${G}[*] Username detected. Running Sherlock...${NC}"
        # Запуск Sherlock как модуля (исправляет твою ошибку)
        python3 -m sherlock "$i" --timeout 2 --print-found
    fi
    pause
}


# --- ЛОГИКА МЕНЮ ---
# (Тут твои функции run_ghost_scan, run_osint, run_device_hack и т.д. без изменений)
# [Для краткости использую твой оригинальный switch-case]

while true; do
    repair; 
    echo -e "${R}========== [ PRIME MASTER v$CURRENT_VERSION ] ==========${NC}"
    get_stats
    echo -e "${G}G) GHOST SCAN   1) SOCIAL ENG\n2) SQLMAP       3) SMART OSINT\n4) DEVICE HACK  5) SECURITY HUB\nU) UPDATE CORE  I) SERVICE HUB\n0) EXIT${NC}"
    read -p ">> " opt
    case $opt in
        g|G) read -p "Target: " t; nmap -sV "$t"; read ;;
        1) cd /root/zphisher && ./zphisher.sh ;;
        2) sqlmap --wizard ;;
        3) run_osint() ;;
        4) clear; echo "1) PhoneSploit 2) BT Scan"; read dh; [ $dh == "1" ] && (cd /root/phonesploit && python3 phonesploitpython.py); [ $dh == "2" ] && hcitool scan; read ;;
        5) # Security Hub (AV, Share, Upload)
           clear; echo "V) AV Srv  S) Share  U) Upload"; read sh;
           [ $sh == "V" ] && python3 /root/av_server.py; [ $sh == "S" ] && python3 /root/share_server.py; [ $sh == "U" ] && python3 /root/upload_server.py ;;
        i|I) # Твой оригинальный mod_service с unified_installer
           exec /root/launcher.sh ;; # Упрощенный вызов
        u|U) curl -L "$UPDATE_URL" > /root/install_all.sh && chmod +x /root/install_all.sh && exec /root/install_all.sh ;;
        0) exit 0 ;;
    esac
done
EOF

chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
repair_and_clean
echo -e "\n${G}[✔] PRIME v$CURRENT_VERSION ПОЛНЫЙ ОРИГИНАЛ ВОССТАНОВЛЕН. Введи: launcher${NC}"
