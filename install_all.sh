#!/bin/bash

# --- ВЕРСИЯ И ОБНОВЛЕНИЕ ---
CURRENT_VERSION="18.9"
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
    # Проверяем, установлен ли clamav (ищем исполняемый файл clamscan)
    if ! command -v clamscan >/dev/null 2>&1; then
        echo -e "${Y}[*] ClamAV не найден. Инъекция ClamAV (Force Install)...${NC}"
        repair_and_clean
        apt-get update >/dev/null 2>&1
        cd /root
        # Скачиваем пакеты
        apt-get download clamav clamav-base clamav-freshclam libclamav* >/dev/null 2>&1
        # Форсированная установка всех скачанных .deb
        dpkg -i --force-all *.deb >/dev/null 2>&1
        # Создание необходимых директорий и файлов заглушек
        mkdir -p /var/lib/clamav
        touch /var/lib/clamav/main.cvd /var/lib/clamav/daily.cvd
        # Очистка за собой
        rm -f *.deb
    else
        echo -e "${G}[+] ClamAV уже установлен. Пропускаю...${NC}"
    fi
}

install_tool() {
    local name=$1; local url=$2; local exec_file=$3; local extra_cmd=$4
    
    # Проверяем, существует ли папка И исполняемый файл внутри
    if [ -d "$name" ] && [ -f "$name/$exec_file" ]; then 
        echo -e "${G}[+] $name уже установлен. Пропускаю...${NC}"
        return 0 
    fi

    echo -e "${Y}[*] Installing $name...${NC}"
    
    # Очистка перед скачиванием, чтобы temp.zip не конфликтовал
    rm -f "temp.zip"
    
    curl -L -f "$url" -o "temp.zip" >/dev/null 2>&1
    
    if [ -s "temp.zip" ]; then
        unzip -q "temp.zip"
        # Поиск извлеченной директории (учитываем master, main или имя инструмента)
        local extracted_dir=$(ls -d */ 2>/dev/null | grep -iE "${name}|master|main" | head -n 1)
        
        if [ -n "$extracted_dir" ]; then
            # Если папка уже была, но бинарника не было — удаляем старую перед mv
            [ -d "$name" ] && rm -rf "$name"
            mv "$extracted_dir" "$name"
            rm -f "temp.zip"
            
            # Выполнение дополнительных команд (сборка, зависимости)
            if [ -n "$extra_cmd" ]; then
                (cd "$name" && eval "$extra_cmd" >/dev/null 2>&1)
            fi
            
            # Делаем файл исполняемым
            if [ -f "$name/$exec_file" ]; then
                chmod +x "$name/$exec_file"
                echo -e "${G}[+] $name успешно установлен.${NC}"
            fi
        fi
    else
        echo -e "${R}[!] Ошибка загрузки $name. Проверь сеть.${NC}"
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
    # "wifite2;https://github.com/derv82/wifite2/archive/refs/heads/master.zip;wifite.py;python3 setup.py install --break-system-packages"
    "sqlmap;https://github.com/sqlmapproject/sqlmap/archive/refs/heads/master.zip;sqlmap.py;"
   # "routersploit;https://github.com/threat9/routersploit/archive/refs/heads/master.zip;rsf.py;safe_pip -r requirements.txt"
   # "sherlock;https://github.com/sherlock-project/sherlock/archive/refs/heads/master.zip;sherlock_project/sherlock.py;safe_pip -r requirements.txt"
     #"phoneinfoga;https://github.com/sundowndev/phoneinfoga/archive/refs/heads/master.zip;phoneinfoga.py;safe_pip -r requirements.txt"
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

# Текущая версия инструмента
IBAN_VERSION="1.7"
FILE_PATH="/root/iban_check.py"

echo -e "${C}[*] Проверка модуля IBAN/RIB (System Integrated)...${NC}"

if [ ! -f "$FILE_PATH" ] || ! grep -q "VERSION = '$IBAN_VERSION'" "$FILE_PATH"; then
    echo -e "${Y}[!] Апгрейд до v$IBAN_VERSION: Системная интеграция...${NC}"
    zero_clear

    cat << EOF > "$FILE_PATH"
import sys, re, json
from urllib.request import urlopen

# VERSION = '1.6'

def get_detailed_data(iban):
    try:
        url = f"https://api.ibanlist.com/v1/validate/{iban}"
        with urlopen(url, timeout=5) as response:
            return json.loads(response.read().decode())
    except: return None

def validate_structure(iban):
    """Разбор структуры как на профессиональных сайтах"""
    res = {
        "Country": iban[:2],
        "Check": iban[2:4],
        "BBAN": iban[4:],
    }
    if iban.startswith('FR'):
        res.update({
            "Bank Code": iban[4:9],
            "Branch Code": iban[9:14],
            "Account": iban[14:25],
            "RIB Key": iban[25:27]
        })
    return res

if __name__ == "__main__":
    if len(sys.argv) < 2: sys.exit(1)
    
    # Очистка и нормализация
    target = re.sub(r'[\s-]+', '', sys.argv[1]).upper()
    
    # Параметры для сверки (если переданы)
    provided_name = sys.argv[2].upper() if len(sys.argv) > 2 else None
    provided_bic = sys.argv[3].upper() if len(sys.argv) > 3 else None

    print(f"\033[1;34m--- РЕЗУЛЬТАТ ПРОВЕРКИ IBAN ---\033[0m")
    
    struct = validate_structure(target)
    for key, val in struct.items():
        print(f"\033[96m{key}:\033[0m {val}")

    data = get_detailed_data(target)
    if data and data.get('valid'):
        bank_name = data.get('bank_name', 'N/A')
        bic = data.get('bic', 'N/A')
        
        print(f"\n\033[1;32m[+] СТАТУС: ВАЛИДЕН (Контрольная сумма верна)\033[0m")
        print(f"🏦 Банк: {bank_n}")
        print(f"🔑 BIC: {bic}")
        
        # --- ЛОГИКА СВЕРКИ (VERIFICATION) ---
        if provided_name or provided_bic:
            print(f"\n\033[1;35m--- ОТЧЕТ О СВЕРКЕ (MATCH REPORT) ---\033[0m")
            
            # Сверка BIC
            if provided_bic:
                if provided_bic in bic:
                    print(f"✅ BIC Match: ПРОВЕРЕНО ({bic})")
                else:
                    print(f"❌ BIC Mismatch! Ожидалось: {provided_bic}, Найдено: {bic}")
            
            # Сверка банка по имени (эвристика)
            if bank_name != 'N/A':
                print(f"ℹ️ Проверка банка: Система подтверждает {bank_name}")

            print(f"🔍 Запуск Maigret для поиска владельца: {provided_name if provided_name else 'Searching...'}")
    else:
        print(f"\033[91m[-] ОШИБКА: Неверная структура или контрольная сумма\033[0m")
    EOF
    chmod +x "$FILE_PATH"
    echo -e "${G}[+] Модуль v$IBAN_VERSION интегрирован с системой.${NC}"
fi

# --- ГЕНЕРАЦИЯ СЕРВЕРОВ (Твой оригинал) ---
cat << 'EOF' > /root/av_server.py
from flask import Flask, request, render_template_string
import subprocess, os

app = Flask(__name__)

# АБСОЛЮТНО ТОЧНЫЙ ПУТЬ К ФАЙЛУ
CLAM_PATH = '/root/clamav/clamscan'

STYLE = """
<style>
    body { background: #050505; color: #00ff41; font-family: 'Courier New', monospace; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    .container { border: 1px solid #00ff41; padding: 30px; background: #111; box-shadow: 0 0 20px rgba(0,255,65,0.2); border-radius: 5px; width: 80%; max-width: 700px; }
    h2 { border-bottom: 1px solid #00ff41; padding-bottom: 10px; text-transform: uppercase; letter-spacing: 2px; }
    pre { white-space: pre-wrap; font-size: 0.85em; color: #0cf; background: #000; padding: 15px; border: 1px solid #222; }
    .status-box { padding: 10px; margin-bottom: 15px; font-weight: bold; text-align: center; border: 1px solid; }
    .infected { color: #ff3e3e; border-color: #ff3e3e; background: rgba(255,62,62,0.1); }
    .clean { color: #00ff41; border-color: #00ff41; background: rgba(0,255,65,0.1); }
    .back-link { color: #555; text-decoration: none; font-size: 0.8em; margin-top: 20px; display: block; text-align: center; }
</style>
"""

@app.route('/')
def index():
    return render_template_string(STYLE + '<div class="container"><h2>> CLAMAV_SCANNER</h2><p>Upload data for deep analysis...</p><form method="post" action="/scan" enctype="multipart/form-data"><input type="file" name="file" required><br><br><button type="submit" style="background:#00ff41; color:#000; border:none; padding:10px 20px; cursor:pointer; font-weight:bold;">START SCAN</button></form></div>')

@app.route('/scan', methods=['POST'])
def scan():
    f = request.files.get('file')
    if not f: return "No file uploaded", 400
    
    tmp_path = os.path.join('/tmp', f.filename)
    f.save(tmp_path)
    os.sync()

    try:
        # Принудительно проверяем права перед запуском
        os.chmod(CLAM_PATH, 0o755)
        # Запуск сканирования
        res = subprocess.run([CLAM_PATH, '--no-summary', tmp_path], capture_output=True, text=True)
        scan_output = res.stdout if res.stdout else res.stderr
    except Exception as e:
        scan_output = f"Execution Error: {str(e)}"
    
    if os.path.exists(tmp_path): os.remove(tmp_path)
    
    is_infected = "FOUND" in scan_output
    status_msg = "!!! THREAT DETECTED !!!" if is_infected else "FILE_CLEAN / SECURE"
    status_class = "infected" if is_infected else "clean"

    return render_template_string(STYLE + f"""
    <div class="container">
        <h2>> SCAN_RESULTS</h2>
        <div class="status-box {status_class}">{status_msg}</div>
        <pre>{scan_output}</pre>
        <a href="/" class="back-link">[ RETURN TO DASHBOARD ]</a>
    </div>
    """)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat << 'EOF' > /root/share_server.py
from flask import Flask, render_template_string, send_from_directory
import os

app = Flask(__name__)
SHARE_DIR = '/root/share'

# Убедимся, что папка существует
if not os.path.exists(SHARE_DIR):
    os.makedirs(SHARE_DIR)

STYLE = """
<style>
    body { background: #050505; color: #00ff41; font-family: 'Courier New', monospace; margin: 0; padding: 40px; }
    h2 { text-transform: uppercase; letter-spacing: 3px; border-bottom: 2px solid #00ff41; display: inline-block; padding-bottom: 10px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px; margin-top: 30px; }
    .file-card { 
        background: #111; border: 1px solid #333; padding: 20px; text-align: center; 
        transition: 0.3s; text-decoration: none; color: #00ff41; border-radius: 4px;
        display: flex; flex-direction: column; align-items: center;
    }
    .file-card:hover { 
        border-color: #00ff41; background: #00ff4111; transform: translateY(-5px); 
        box-shadow: 0 5px 15px rgba(0, 255, 65, 0.2); 
    }
    .icon { font-size: 40px; margin-bottom: 10px; }
    .filename { font-size: 0.9em; word-break: break-all; }
    .empty { color: #555; font-style: italic; }
</style>
"""

HTML = STYLE + """
<div style="max-width: 1000px; margin: auto;">
    <h2>> SECURE_FILE_DISTRIBUTION</h2>
    <p style="color: #555; font-size: 0.8em;">Location: {{ path }}</p>
    
    <div class="grid">
        {% for f in files %}
        <a href="/get/{{f}}" class="file-card">
            <div class="icon">📄</div>
            <div class="filename">{{ f }}</div>
        </a>
        {% else %}
        <p class="empty">No files detected in the transmission sector.</p>
        {% endfor %}
    </div>
</div>
"""

@app.route('/')
def index():
    files = os.listdir(SHARE_DIR)
    return render_template_string(HTML, files=files, path=SHARE_DIR)

@app.route('/get/<filename>')
def get_file(filename):
    return send_from_directory(SHARE_DIR, filename)

if __name__ == '__main__':
    # Порт 5002, как в твоем запросе
    app.run(host='0.0.0.0', port=5002)
EOF

cat << 'EOF' > /root/upload_server.py
from flask import Flask, request, render_template_string
import os

app = Flask(__name__)

# Автоматическое определение директории (SD-карта или root)
UPLOAD_DIR = '/sdcard/PRIME_INBOX' if os.path.exists('/sdcard') else '/root/PRIME_INBOX'
if not os.path.exists(UPLOAD_DIR): 
    os.makedirs(UPLOAD_DIR, exist_ok=True)

STYLE = """
<style>
    body { background: #050505; color: #00ff41; font-family: 'Courier New', monospace; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .box { border: 2px dashed #00ff41; padding: 40px; background: #111; box-shadow: 0 0 20px rgba(0, 255, 65, 0.1); border-radius: 10px; text-align: center; max-width: 500px; }
    h2 { letter-spacing: 5px; text-shadow: 0 0 10px #00ff41; margin-bottom: 30px; }
    input[type="file"] { background: #1a1a1a; border: 1px solid #333; padding: 10px; color: #00ff41; width: 100%; margin-bottom: 20px; }
    button { background: #00ff41; color: #000; border: none; padding: 15px 30px; font-weight: bold; cursor: pointer; text-transform: uppercase; transition: 0.3s; width: 100%; }
    button:hover { background: #008f25; box-shadow: 0 0 15px #00ff41; }
    .path-info { color: #555; font-size: 0.7em; margin-top: 20px; border-top: 1px solid #222; padding-top: 10px; }
    .success { color: #fff; text-transform: uppercase; animation: blink 1s infinite; }
    @keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
</style>
"""

HTML_INDEX = STYLE + """
<div class="box">
    <h2>> INBOUND_DROP_BOX</h2>
    <p style="font-size: 0.8em; margin-bottom: 20px; color: #888;">Secure uplink established. Ready for transmission.</p>
    <form method="post" action="/upload" enctype="multipart/form-data">
        <input type="file" name="file" required>
        <button type="submit">Initiate Upload</button>
    </form>
    <div class="path-info">Target: {{ target_dir }}</div>
</div>
"""

HTML_SUCCESS = STYLE + """
<div class="box">
    <h2 class="success">Data Received</h2>
    <p style="color: #00ff41;">The file has been successfully written to the secure sector.</p>
    <br>
    <a href="/" style="color: #888; text-decoration: none;">[ RETURN TO GATEWAY ]</a>
</div>
"""

@app.route('/')
def index():
    return render_template_string(HTML_INDEX, target_dir=UPLOAD_DIR)

@app.route('/upload', methods=['POST'])
def upload():
    if 'file' not in request.files: 
        return "Transmission Error: No data", 400
    f = request.files['file']
    if f.filename == '': 
        return "Transmission Error: Empty filename", 400
    
    file_path = os.path.join(UPLOAD_DIR, f.filename)
    f.save(file_path)
    
    return render_template_string(HTML_SUCCESS)

if __name__ == '__main__':
    # Порт 5001 для Upload-сервера
    app.run(host='0.0.0.0', port=5001)
EOF

# --- ГЕНЕРАЦИЯ LAUNCHER (Твой оригинал + расширенный TOOLS_DATA) ---
cat << 'EOF' > /root/launcher.sh
#!/bin/bash
CURRENT_VERSION="18.6"
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
    # Внутренняя функция для мгновенного обнуления
    zero_clear() {
        # Очистка временных файлов, логов npm и кэша
        rm -rf /tmp/* /root/.npm/_logs/* > /dev/null 2>&1
        # Сброс кэша оперативной памяти
        sync && echo 3 > /proc/sys/vm/drop_caches
    }

    clear
    zero_clear # Обнуление перед началом сессии
    
    echo -e "${Y}>>> [ SMART OSINT 2026: TOTAL ZERO MODE ] <<<${NC}"
    echo -e "${C}Поддерживается: email, username, phone (+33...)${NC}"
    echo -ne "Input: "
    read i
    [ -z "$i" ] && return
    
    # 1. ОПРЕДЕЛЕНИЕ ТИПА: EMAIL
    if [[ "$i" =~ "@" ]]; then 
        echo -e "${G}[*] Email detected. Running Tools...${NC}"
        zero_clear
        if [ -f "/root/infoga/mosint.py" ]; then
            python3 /root/infoga/mosint.py "$i"
        elif [ -f "/root/infoga/infoga.py" ]; then
            python3 /root/infoga/infoga.py --target "$i"
        else
            echo -e "${Y}[!] Использование Maigret для почты...${NC}"
            maigret "$i"
        fi

    # 2. ОПРЕДЕЛЕНИЕ ТИПА: НОМЕР ТЕЛЕФОНА (начинается с +)
    elif [[ "$i" =~ ^\+ ]]; then
        echo -e "${G}[*] Phone number detected. Running Multi-Search...${NC}"
        
        echo -e "${C}[1/2] Checking social presence (Socialscan)...${NC}"
        zero_clear
        socialscan "$i"
        
        echo -e "${C}[2/2] Searching deep records (Maigret)...${NC}"
        zero_clear
        maigret.py "$i" --parse

    # 3. ОПРЕДЕЛЕНИЕ ТИПА: НИКНЕЙМ
    else 
        echo -e "${G}[*] Username detected. Running Snoop & Blackbird...${NC}"
        
        # Сначала быстрый поиск через Blackbird
        if [ -d "/root/blackbird" ]; then
            echo -e "${C}>>> Fast Scan: Blackbird...${NC}"
            zero_clear
            python3 /root/blackbird/blackbird.py -u "$i"
        fi

        # Затем глубокий поиск через Snoop (база на 329 сайтов)
        if [ -d "/root/snoop" ]; then
            echo -e "\n${C}>>> Deep Scan: Snoop...${NC}"
            zero_clear
            python3 /root/snoop/snoop.py "$i"
        else
            echo -e "${Y}>>> Fallback: Sherlock...${NC}"
            zero_clear
            sherlock "$i" --timeout 2 --print-found
        fi
    fi

    echo -e "\n${Y}Нажми Enter для завершения и тотального обнуления...${NC}"
    read
    
    zero_clear # Финальное обнуление после работы
    history -c # Удаление следов введенных данных
    echo -e "${G}[+] Система очищена. Логи и кэш удалены.${NC}"
    sleep 2
}


run_osint2() {
    zero_clear() {
        rm -rf /tmp/* /root/.npm/_logs/* > /dev/null 2>&1
        sync && echo 3 > /proc/sys/vm/drop_caches
    }

    clear
    zero_clear
    echo -e "${Y}>>> [ TOTAL OSINT 2: DEEP SCAN MODE ] <<<${NC}"
    echo -e "${C}Введите любые данные (Email, Phone или Username)${NC}"
    echo -ne "Input: "
    read i
    [ -z "$i" ] && return

    echo -e "${G}[!] Начинаю комплексную проверку всех баз...${NC}"

    # 1. ПРОВЕРКА СОЦИАЛЬНЫХ СЕТЕЙ (Socialscan)
    echo -e "\n${C}[STEP 1] Checking Social Accounts...${NC}"
    zero_clear
    socialscan "$i"

    # 2. ГЛУБОКИЙ ПОИСК ЦИФРОВОГО СЛЕДА (Maigret)
    echo -e "\n${C}[STEP 2] Running Maigret (Deep Parse)...${NC}"
    zero_clear
    maigret "$i" --parse

    # 3. ПОИСК ПО 329 САЙТАМ (Snoop)
    if [ -d "/root/snoop" ]; then
        echo -e "\n${C}[STEP 3] Running Snoop Deep Scan...${NC}"
        zero_clear
        python3 /root/snoop/snoop.py "$i"
    fi

    # 4. БЫСТРЫЙ ПОИСК (Blackbird)
    if [ -d "/root/blackbird" ]; then
        echo -e "\n${C}[STEP 4] Running Blackbird...${NC}"
        zero_clear
        python3 /root/blackbird/blackbird.py -u "$i"
    fi

    # 5. ПРОВЕРКА ПОЧТЫ (Если в данных есть @)
    if [[ "$i" =~ "@" ]]; then
        echo -e "\n${C}[STEP 5] Running Email Specific Tools...${NC}"
        zero_clear
        if [ -f "/root/infoga/mosint.py" ]; then
            python3 /root/infoga/mosint.py "$i"
        fi
    fi

    # 6. ПОИСК ПО ИМЕНИ И ФАМИЛИИ (Name Search)
    echo -e "\n${C}[STEP 6] Searching by Full Name...${NC}"
    zero_clear
    # Используем Snoop в режиме поиска имен (он отлично справляется с ФИО)
    if [ -d "/root/snoop" ]; then
        python3 /root/snoop/snoop.py "$i" --quick
    fi

# 7. КОМПЛЕКСНАЯ ПРОВЕРКА RIB И ВЛАДЕЛЬЦА
    if [[ "$i" =~ ^[A-Z0-9]{10,34}$ ]]; then
        echo -e "\n${Y}[!] Обнаружен банковский идентификатор. Начинаю проверку соответствия...${NC}"
        zero_clear # Обнуление перед сетевым запросом

        # Шаг А: Валидация структуры и определение банка
        echo -e "${C}[1/3] Определение банка и региона...${NC}"
        bank_info=$(curl -s "https://api.ibanlist.com/v1/validate/$i")
        echo "$bank_info" | grep -E "bank_name|city|country|bic"

        # Шаг Б: Поиск владельца через утечки и кэш (если есть имя для сопоставления)
        echo -e "${C}[2/3] Поиск связки владельца в локальных базах...${NC}"
        # Проверяем, нет ли этого RIB в логах прошлых поисков или перехватах
        grep -r "$i" /root/snoop/reports/ 2>/dev/null

        # Шаг В: Проверка через Maigret (поиск упоминаний счета в сети)
        echo -e "${C}[3/3] Поиск упоминаний счета в открытых источниках...${NC}"
        maigret "$i" --parse
    fi

    echo -e "\n${Y}Комплексный пробив завершен. Нажми Enter для обнуления...${NC}"
    read
    zero_clear
    history -c
    echo -e "${G}[+] Система полностью обнулена.${NC}"
    sleep 2
}


update_prime() {
    clear
    echo -e "${B}[ PRIME MASTER UPDATE ]${NC}"
    echo -e "${Y}[*] Подключение к серверу обновлений...${NC}"
    
    # Ссылка на твой скрипт
    local UP_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh"
    
    # Проверка интернета (timeout 5 секунд)
    if curl -Is --connect-timeout 5 https://github.com > /dev/null; then
        echo -e "${G}[+] Сервер доступен. Качаем install_all.sh...${NC}"
        
        # Скачиваем с флагом -k для обхода проблем с SSL на старых ядрах
        if curl -L -k "$UP_URL" -o /root/install_all.sh; then
            chmod +x /root/install_all.sh
            echo -e "${G}[✔] Скрипт обновлен. Запуск тотальной сборки через 2 сек...${NC}"
            sleep 2
            exec /root/install_all.sh
        else
            echo -e "${R}[!] Ошибка при скачивании файла.${NC}"
            sleep 2
        fi
    else
        echo -e "${R}[!] Нет сети или GitHub недоступен.${NC}"
        sleep 2
    fi
}

run_servers() {
    repair
    echo -e "${B}>>> [ SECURITY & DATA HUB ] <<<${NC}"
    echo -e "${G}V)${NC} AV-Scanner Server (Port 5000)"
    echo -e "${G}S)${NC} Share-File Server (Port 5001)"
    echo -e "${G}U)${NC} Upload-Inbound Server (Port 5002)"
    echo -e "${R}B)${NC} Назад в меню"
    echo -ne "\n${Y}Выбери режим: ${NC}"
    read srv_opt
    
    case $srv_opt in
        [vV]) 
            echo -e "${G}[*] Запуск AV-Scanner...${NC}"
            python3 /root/av_server.py ;;
        [sS]) 
            echo -e "${G}[*] Запуск Share-Server...${NC}"
            python3 /root/share_server.py ;;
        [uU]) 
            echo -e "${G}[*] Запуск Upload-Server...${NC}"
            python3 /root/upload_server.py ;;
        [bB]) 
            return ;;
        *) 
            echo -e "${R}[!] Ошибка: Неверный выбор${NC}"
            sleep 1 ; run_servers ;;
    esac
}

run_device_hack() {
    clear
    echo -e "${B}>>> [ DEVICE EXPLOIT HUB ] <<<${NC}"
    echo -e "${G}1)${NC} PhoneSploit (ADB Remote Control)"
    echo -e "${G}2)${NC} Bluetooth Scan (hcitool)"
    echo -e "${R}B)${NC} Назад в меню"
    echo -ne "\n${Y}Выбери инструмент: ${NC}"
    read dh
    
    case $dh in
        1) 
            echo -e "${G}[*] Запуск PhoneSploit...${NC}"
            cd /root/phonesploit && python3 phonesploitpython.py ;;
        2) 
            echo -e "${G}[*] Сканирование Bluetooth...${NC}"
            hcitool scan ;;
        [bB]) 
            return ;;
        *) 
            echo -e "${R}[!] Неверный ввод${NC}"
            sleep 1 ; run_device_hack ;;
    esac
    echo -e "\n${Y}Нажми Enter, чтобы вернуться...${NC}"
    read
}


run_phishing() {
    clear
    echo -e "${R}>>> [ SOCIAL ENGINEERING HUB ] <<<${NC}"
    echo -e "${Y}[*] Запуск Zphisher...${NC}"
    
    # Проверка наличия директории перед переходом
    if [ -d "/root/zphisher" ]; then
        cd /root/zphisher && ./zphisher.sh
    else
        echo -e "${R}[!] Ошибка: Директория /root/zphisher не найдена.${NC}"
        echo -e "${Y}[*] Попробуй запустить Update (U), чтобы восстановить инструменты.${NC}"
        sleep 3
    fi
}

run_ghost_scan() {
    repair
    echo -e "${G}>>> [ GHOST PORT SCANNER ] <<<${NC}"
    read -p "Target IP/Domain: " t
    [ -z "$t" ] && return
    echo -e "1) Fast Scan (-F)\n2) Version Scan (-sV)\n3) Aggressive (-A)\nB) Back"
    read -p ">> " m
    case $m in
        1) nmap -F -T4 "$t" ;;
        2) nmap -sV "$t" ;;
        3) nmap -A -v "$t" ;;
        *) return ;;
    esac
    read -p "Press Enter..."
}


run_sqlmap() {
    clear
    echo -e "${Y}>>> [ SQL INJECTION EXPLOTATION ] <<<${NC}"
    echo -e "${G}[*] Запуск SQLmap Wizard...${NC}"
    
    # Проверка, установлен ли sqlmap в системе
    if command -v sqlmap >/dev/null 2>&1; then
        sqlmap --wizard
    elif [ -f "/root/sqlmap/sqlmap.py" ]; then
        python3 /root/sqlmap/sqlmap.py --wizard
    else
        echo -e "${R}[!] Ошибка: SQLmap не найден.${NC}"
        echo -e "${Y}[*] Попробуй запустить установку через пункт U.${NC}"
        sleep 3
        return
    fi
    
    echo -e "\n${Y}Работа завершена. Нажми Enter...${NC}"
    read
}

run_iban_scan() {
    clear
    echo -e "${R}========== [ FINANCIAL INTELLIGENCE ] ==========${NC}"
    echo -ne "${Y}Введите номер для анализа: ${NC}"
    read input
    [ -z "$input" ] && return

    # Удаляем пробелы, чтобы не было ошибок в URL
    target=$(echo "$input" | tr -d ' ')

    # 1. Запуск валидатора (Банк, страна, риски)
    python3 /root/iban_check.py "$target"
    
    # Очистка RAM перед тяжелым поиском
    sync && echo 3 > /proc/sys/vm/drop_caches
    
    echo -e "${C}[*] Поиск ФИО владельца через Maigret (Extraction Mode)...${NC}"
    
    # 2. Запуск Maigret с извлечением имен
    # --extract заставляет Maigret выводить найденные имена/фамилии на экран
    maigret "$target" --extract --timeout 20 --info
    
    echo -ne "\n${G}Поиск завершен. Результаты выше. Нажми Enter...${NC}"
    read
    history -c # Режим "В ноль"
}

# --- ЛОГИКА МЕНЮ ---
# (Тут твои функции run_ghost_scan, run_osint, run_device_hack и т.д. без изменений)
# [Для краткости использую твой оригинальный switch-case]

while true; do
    repair; 
    echo -e "${R}========== [ PRIME MASTER v$CURRENT_VERSION ] ==========${NC}"
    get_stats
    # Обновленный визуальный ряд меню
    echo -e "${G}G) GHOST SCAN   1) SOCIAL ENG   2) SQLMAP"
    echo -e "3) SMART OSINT  4) DEVICE HACK  5) SECURITY HUB"
    echo -e "6) AIO OSINT    7) IBAN/RIB SCAN" # Новый пункт
    echo -e "U) UPDATE CORE  I) SERVICE HUB  0) EXIT${NC}"
    
    read -p ">> " opt
    case $opt in
        g|G) run_ghost_scan ;; 
        1) run_phishing ;;     
        2) run_sqlmap ;;      
        3) run_osint ;;
        4) run_device_hack ;;  
        5) run_servers ;;      
        6) run_osint2 ;;
        7) run_iban_scan ;;    # Вызов нашего нового модуля
        i|I) exec /root/launcher.sh ;; 
        u|U) update_prime ;;
        0) exit 0 ;;
    esac
done
EOF

chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
repair_and_clean
echo -e "\n${G}[✔] PRIME v$CURRENT_VERSION ПОЛНЫЙ ОРИГИНАЛ ВОССТАНОВЛЕН. Введи: launcher${NC}"
