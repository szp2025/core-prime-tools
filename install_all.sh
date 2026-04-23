#!/bin/bash

# --- ВЕРСИЯ И ОБНОВЛЕНИЕ ---
CURRENT_VERSION="15.4"
UPDATE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh"

check_update() {
    echo -e "${B}[*] Проверка обновлений...${NC}"
    # Скачиваем только номер версии из удаленного файла
    REMOTE_VERSION=$(curl -s $UPDATE_URL | grep "CURRENT_VERSION=" | head -n 1 | cut -d'"' -f2)
    
    if [ "$REMOTE_VERSION" != "$CURRENT_VERSION" ] && [ -n "$REMOTE_VERSION" ]; then
        echo -e "${Y}[!] Доступна новая версия: $REMOTE_VERSION (У тебя $CURRENT_VERSION)${NC}"
        echo -ne "${G}>>> Обновить скрипт? (y/n): ${NC}"; read up_choice
        if [[ $up_choice == "y" ]]; then
            echo -e "${Y}[*] Обновляюсь...${NC}"
            curl -L -o "$0" "$UPDATE_URL"
            echo -e "${G}[✔] Обновлено! Перезапусти скрипт.${NC}"
            exit 0
        fi
    else
        echo -e "${G}[✔] У тебя актуальная версия ($CURRENT_VERSION)${NC}"
    fi
}

# --- ПРОВЕРКА ПРАВ ---
if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[0;31m[!] Ошибка: Запустите от имени root\033[0m"
  exit
fi

# --- КОНФИГУРАЦИЯ ЦВЕТОВ ---
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

repair_and_clean() {
    # Исправляем базу dpkg ( Error 1 PHP Fix)
    [ -f /var/lib/dpkg/status ] && sed -i '/Package: php8/,/^$/d' /var/lib/dpkg/status 2>/dev/null
    # Очистка кэша ОЗУ для 1GB RAM
    sync && echo 3 | tee /proc/sys/vm/drop_caches >/dev/null 2>&1
    # Удаление мусора
    rm -f /root/*.zip /root/*.tmp /root/*.log /root/*.deb 2>/dev/null
    apt-get clean && rm -rf ~/.cache/pip
}

safe_pip() {
    python3 -m pip install --no-cache-dir --break-system-packages "$@" >/dev/null 2>&1
    repair_and_clean
}

# --- ФУНКЦИЯ ПРИНУДИТЕЛЬНОЙ УСТАНОВКИ CLAMAV ---
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
echo -e "${R}[*] PRIME v15.4: ТОТАЛЬНАЯ СБОРКА...${NC}"
mkdir -p /root/share /root/PRIME_INBOX
repair_and_clean

# Системные пакеты (убрали clamav из списка apt, ставим отдельно)
apt-get update >/dev/null 2>&1
apt-get install -y php curl unzip python3-pip python3-flask nmap foremost tshark aircrack-ng chkrootkit whatweb htop bluez tor >/dev/null 2>&1

# Принудительный ClamAV
install_clamav_force


# --- СПИСОК ИНСТРУМЕНТОВ ---
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

# Специальная установка для PhoneInfoga (Binary ARM)
if [ ! -d "/root/phoneinfoga" ]; then
    mkdir /root/phoneinfoga && cd /root/phoneinfoga
    curl -L https://github.com/sundowndev/phoneinfoga/releases/download/v2.10.8/phoneinfoga_Linux_armv7.tar.gz | tar xz
    chmod +x phoneinfoga
fi

# Специальная установка для Mosint (Email OSINT)
if [ ! -d "/root/infoga" ]; then
    git clone --depth=1 https://github.com/alpkeskin/mosint.git /root/infoga
    cd /root/infoga && safe_pip -r requirements.txt
fi


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
if __name__ == '__main__': app.run(host='0.0.0.0', port=5002)
EOF

cat << 'EOF' > /root/upload_server.py
from flask import Flask, request, render_template_string
import os
app = Flask(__name__)

# Универсальный путь: пробуем /sdcard, иначе используем локальную папку
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF

# --- ГЕНЕРАЦИЯ LAUNCHER ---
cat << 'EOF' > /root/launcher.sh
#!/bin/bash
CURRENT_VERSION="15.4"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

repair() { sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true; }
pause() { echo -ne "\n${B}[Enter]...${NC}"; read; }

# Динамическая информация о системе
get_stats() {
    # RAM: Свободно / Всего
    local ram=$(free -m | awk '/Mem:/ {printf "%d/%dMB", $4, $2}')
    # ROM: Свободно на системном разделе
    local rom=$(df -h / | awk 'NR==2 {print $4}')
    # SD: Поиск внешней карты памяти
    local sd_path=$(ls -d /storage/* 2>/dev/null | grep -vE "self|emulated" | head -n 1)
    local sd_info="N/A"
    [ -n "$sd_path" ] && sd_info=$(df -h "$sd_path" | awk 'NR==2 {print $4}')
    
    echo -e "${Y}RAM: ${G}$ram ${Y}| ROM: ${G}$rom ${Y}| SD: ${G}$sd_info${NC}"
}

# Функция мгновенного обновления комплекса
update_prime() {
    clear
    echo -e "${Y}[*] Подготовка к обновлению системы...${NC}"
    local url="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh"
    # Скачиваем новый установщик и сразу передаем его интерпретатору bash
    # Это обновит все файлы, включая этот лаунчер
    curl -L "$url" > /root/install_all.sh
    chmod +x /root/install_all.sh
    echo -e "${G}[✔] Пакет обновления загружен. Перезапуск...${NC}"
    sleep 1
    exec /root/install_all.sh
}

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
    repair 
    echo -e "${Y}>>> [ SMART OSINT ] <<<${NC}"
    echo -ne "Input (mail,tel,username): "; read i
    [ -z "$i" ] && return
    if [[ "$i" =~ @ ]]; then 
        echo -e "${G}[*] Searching email...${NC}"
        [ -d "/root/infoga" ] && cd /root/infoga && python3 infoga.py --target "$i"
    elif [[ "$i" =~ ^\+ ]]; then 
        echo -e "${G}[*] Scanning phone...${NC}"
        [ -d "/root/phoneinfoga" ] && cd /root/phoneinfoga && ./phoneinfoga scan -n "$i"
    else 
        echo -e "${G}[*] Hunting username...${NC}"
        [ -f "/root/sherlock/sherlock_project/sherlock.py" ] && python3 /root/sherlock/sherlock_project/sherlock.py "$i" --timeout 2 --print-found
    fi
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

run_anonymity() { a8 status; echo -ne "${Y}a) Start  b) Stop  Any) Cancel: ${NC}"; read x; [[ $x == "a" ]] && a8 start; [[ $x == "b" ]] && a8 stop; pause; }

run_av_hub() {
    local ip=$(hostname -I | awk '{print $1}')
    echo -e "${G}[*] AV-Server: http://$ip:5000${NC}"
    python3 /root/av_server.py
    pause
}

run_share_hub() {
    repair; local ip=$(hostname -I | awk '{print $1}')
    echo -e "${G}[*] Share-Server: http://$ip:5002${NC}"
    python3 /root/share_server.py; pause
}

run_upload_hub() {
    local ip=$(hostname -I | awk '{print $1}')
    echo -e "${G}[*] Upload-Server: http://$ip:5001${NC}"
    python3 /root/upload_server.py; pause
}

run_my_ip() { echo -ne "${Y}External IP: ${NC}"; curl -s --connect-timeout 5 https://ifconfig.me || echo "Timeout"; echo; pause; }

mod_security() {
    while true; do
        repair; clear
        echo -e "${G}========== [ SECURITY HUB ] ==========${NC}"
        echo -e "A) [ ANONYMITY ]    V) [ AV-SCANNER ]"
        echo -e "S) [ SHARE-HUB ]    U) [ UPLOAD-HUB ]"
        echo -e "I) [ MY IP ]        0) [ BACK ]"
        echo -e "${G}--------------------------------------${NC}"
        get_stats
        echo -ne "\n${Y}>> Security Vector: ${NC}"
        read m5
        case $m5 in
            a|A) run_anonymity ;; v|V) run_av_hub ;; s|S) run_share_hub ;; u|U) run_upload_hub ;; i|I) run_my_ip ;; 0) break ;;
        esac
    done
}

# Функции-обертки для инструментов
run_zphisher() { repair; cd /root/zphisher && ./zphisher.sh; }
run_sqlmap() { repair; sqlmap --wizard; }
run_htop() { htop; }

# Основной цикл меню
while true; do
    repair; clear
    echo -e "${R}========== [ PRIME MASTER v$CURRENT_VERSION ] ==========${NC}"
    get_stats
    echo -e "${G}----------------------------------------------${NC}"
    echo -e "G) [ GHOST SCAN ]   1) [ SOCIAL ENG ]"
    echo -e "2) [ SQLMAP ]       3) [ SMART OSINT ]"
    echo -e "4) [ DEVICE HACK ]  5) [ SECURITY HUB ]"
    echo -e "U) [ UPDATE PRIME ] s) MONITOR (HTOP)  0) EXIT"
    echo -ne "\n${Y}>> Vector: ${NC}"
    read opt

    case $opt in
        g|G) run_ghost_scan ;;
        1)   run_zphisher ;;
        2)   run_sqlmap ;;
        3)   mod_osint ;;
        4)   mod_device_hack ;;
        5)   mod_security ;;
        u|U) update_prime ;;
        s|S) run_htop ;;
        0)   exit 0 ;;
        *)   echo -e "${R}[!] Неверный ввод${NC}"; sleep 1 ;;
    esac
done

chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
repair_and_clean
echo -e "\n${G}[✔] PRIME v15.4 ПОЛНЫЙ КОМПЛЕКС ГОТОВ. Введи: launcher${NC}"
