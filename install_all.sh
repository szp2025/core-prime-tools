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
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
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

# Список инструментов (добавлен Anonym8)
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
echo -e "${R}[*] PRIME v14.5: РАЗВЕРТЫВАНИЕ ПОЛНОГО КОМПЛЕКСА...${NC}"
repair_and_clean
apt-get update >/dev/null 2>&1
# Добавлены flask для AV-Hub и tor для анонимности
apt-get install -y php curl unzip python3-pip python3-flask nmap foremost tshark aircrack-ng chkrootkit whatweb htop bluez clamav tor >/dev/null 2>&1

for entry in "${TOOLS[@]}"; do
    IFS=";" read -r t_name t_url t_exec t_extra <<< "$entry"
    install_tool "$t_name" "$t_url" "$t_exec" "$t_extra"
done

# --- ГЕНЕРАЦИЯ СЕРВЕРА АНТИВИРУСА ---
cat << 'EOF' > /root/av_server.py
from flask import Flask, request, render_template_string
import subprocess, os

app = Flask(__name__)

# Легкий HTML-интерфейс прямо в коде (минимализм для 51MB RAM)
HTML_PAGE = '''
<!DOCTYPE html>
<html>
<head>
    <title>PRIME AV-HUB</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { background: #000; color: #0f0; font-family: monospace; padding: 20px; }
        input { background: #111; color: #0f0; border: 1px solid #0f0; padding: 10px; width: 100%; margin-bottom: 10px; }
        button { background: #0f0; color: #000; border: none; padding: 10px 20px; cursor: pointer; font-weight: bold; }
        .result { border: 1px dashed #0f0; padding: 15px; margin-top: 20px; white-space: pre-wrap; }
    </style>
</head>
<body>
    <h2>>>> PRIME AV-SCANNER <<<</h2>
    <form method="post" action="/scan" enctype="multipart/form-data">
        <input type="file" name="file">
        <button type="submit">ЗАПУСТИТЬ СКАН</button>
    </form>
</body>
</html>
'''

@app.route('/')
def index():
    return render_template_string(HTML_PAGE)

@app.route('/scan', methods=['POST'])
def scan():
    if 'file' not in request.files: return "Файл не выбран", 400
    f = request.files['file']
    if f.filename == '': return "Файл не выбран", 400
    
    save_path = os.path.join('/tmp', f.filename)
    f.save(save_path)
    
    # Запуск ClamAV
    res = subprocess.run(['clamscan', '--no-summary', save_path], capture_output=True, text=True)
    
    os.remove(save_path) # Удаление следа
    
    # Возвращаем результат в стиле терминала
    return f"<html><body style='background:#000;color:#0f0;font-family:monospace;'><pre>РЕЗУЛЬТАТ ДЛЯ {f.filename}:\n\n{res.stdout}\n\n<a href='/' style='color:#fff'>[ Назад ]</a></pre></body></html>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat << 'EOF' > /root/share_server.py
from flask import Flask, render_template_string, send_from_directory
import os

app = Flask(__name__)
SHARE_DIR = '/root/share'

HTML = '''
<!DOCTYPE html>
<html>
<head>
    <title>PRIME SHARE</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { background: #1a1a1a; color: #eee; font-family: sans-serif; text-align: center; padding: 20px; }
        .file-card { background: #333; border-radius: 8px; padding: 15px; margin: 10px auto; max-width: 400px; border-left: 5px solid #0f0; }
        a { color: #0f0; text-decoration: none; font-weight: bold; font-size: 1.2em; }
        .info { font-size: 0.8em; color: #888; margin-top: 5px; }
    </style>
</head>
<body>
    <h2>📁 Доступные файлы</h2>
    <p>Нажмите на файл для просмотра или загрузки</p>
    {% for f in files %}
        <div class="file-card">
            <a href="/get/{{ f }}">{{ f }}</a>
            <div class="info">Shared from Mobile Node</div>
        </div>
    {% endfor %}
    {% if not files %}<p>Список пуст</p>{% endif %}
</body>
</html>
'''

@app.route('/')
def index():
    files = os.listdir(SHARE_DIR)
    return render_template_string(HTML, files=files)

@app.route('/get/<filename>')
def get_file(filename):
    return send_from_directory(SHARE_DIR, filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# --- ГЕНЕРАЦИЯ LAUNCHER ---
cat << 'EOF' > /root/launcher.sh
#!/bin/bash
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'
repair() { sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true; rm -f /root/*.log 2>/dev/null; }
pause() { echo -ne "\n${B}[Enter] для возврата...${NC}"; read; }

mod_osint() {
    clear; echo -e "${Y}>>> [ SMART OSINT DETECTOR ] <<<${NC}"
    echo -ne "Ввод (Ник, Email, +Тел или IP): "; read input
    [ -z "$input" ] && return
    repair
    if [[ "$input" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
        cd /root/infoga && python3 infoga.py --domain all --source all --target "$input"
    elif [[ "$input" =~ ^\+[0-9]{10,15}$ ]]; then
        cd /root/phoneinfoga && python3 phoneinfoga.py -n "$input"
    elif [[ "$input" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        trace -t "$input"
    else
        python3 /root/sherlock/sherlock/sherlock.py "$input" --timeout 1 --print-found
    fi
    pause
}

run_ghost_scan() {
    repair; clear; echo -e "${R}>>> [ SMART GHOST SCAN ] <<<${NC}"
    echo -ne "Цель: "; read target; [ -z "$target" ] && return
    if [[ "$target" =~ [a-zA-Z] ]]; then
        whatweb -a 1 "$target" --color=never | grep -E "HTTPS?|Direct"
        nmap -sV -T4 -p80,443 --script http-enum --script-args http.useragent="Mozilla/5.0" "$target" | grep -vE "Starting|Raw|Read"
    else
        nmap -sV -T4 -Pn --top-ports 100 "$target" | grep -E "PORT|STATE|SERVICE|VERSION|^[0-9]"
    fi
    pause
}

mod_device_hack() {
    clear; echo -e "${R}>>> [ SMART DEVICE EXPLOIT ] <<<${NC}"
    echo -e "1) Bluetooth Scan\n2) Android ADB (PhoneSploit)\n3) Deep Grep (Пароли/Токены)\n0) Назад"
    read -p ">> " m4
    case $m4 in
        1) hciconfig hci0 up 2>/dev/null; hcitool scan; pause ;;
        2) cd /root/phonesploit && python3 phonesploitpython.py ;;
        3) echo -n "Путь: "; read p; grep -rnE "password|token|secret|login|pwd" "$p" 2>/dev/null | grep -vE "\.html|\.js" | head -n 20; pause ;;
    esac
}

mod_security() {
    clear
    echo -e "${G}>>> [ SECURITY & DATA HUB ] <<<${NC}"
    echo -e "1) VPN/TOR (On/Off)"
    echo -e "2) AV-HUB (Твой личный антивирус)"
    echo -e "3) SHARE-HUB (Раздать файлы по IP)"
    echo -e "4) Проверка текущего IP"
    echo -e "0) Назад"
    read -p ">> " m5
    case $m5 in
        1) # ... (код VPN из предыдущей версии) ... ;;
        2) 
            repair
            python3 /root/av_server.py ;;
        3)
            repair
            ip=$(hostname -I | awk '{print $1}')
            echo -e "${G}[!] SHARE-HUB ЗАПУЩЕН${NC}"
            echo -e "${Y}Передай эту ссылку: http://$ip:5000${NC}"
            echo -e "${B}[*] Положи файлы в /root/share чтобы они появились там.${NC}"
            python3 /root/share_server.py ;;
        4) curl -s https://ifconfig.me; pause ;;
    esac
}

while true; do
    repair; clear
    echo -e "${R}========== [ PRIME MASTER v14.5 ] ==========${NC}"
    echo -e "G) ${R}[ GHOST SCAN ]${NC}  1) ${G}[ SOCIAL ENG ]${NC}"
    echo -e "2) ${G}[ AUTO-EXPLOIT ]${NC} 3) ${Y}[ SMART OSINT ]${NC}"
    echo -e "4) ${B}[ DEVICE HACK ]${NC}  5) ${B}[ SECURITY ]${NC}"
    echo -e "--------------------------------------------"
    echo -e "s) MONITOR (HTOP)    0) EXIT"
    echo -ne "\n${Y}>> Вектор: ${NC}"
    read opt
    case $opt in
        g|G) run_ghost_scan ;;
        1) cd /root/zphisher && ./zphisher.sh ;;
        2) cd /root/sqlmap && python3 sqlmap.py --wizard ;;
        3) mod_osint ;;
        4) mod_device_hack ;;
        5) mod_security ;;
        s) htop ;;
        0) clear; exit 0 ;;
    esac
done
EOF

chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
repair_and_clean
echo -e "\n${G}[✔] PRIME v14.5 ПОЛНОСТЬЮ ЗАРЯЖЕН. Введи: launcher${NC}"
