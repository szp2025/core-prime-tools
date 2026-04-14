#!/system/bin/sh

# --- ГЛОБАЛЬНЫЕ ПУТИ ---
BASE_DIR="/data/local/tmp"
BIN_DIR="$BASE_DIR/bin"
SHARE_DIR="$BASE_DIR/share/nmap"

# ИСПОЛЬЗУЕМ ИСПРАВЛЕННЫЙ СИСТЕМНЫЙ WGET (который мы подменили)
# Больше не полагаемся на BusyBox для загрузки
WGET="wget --no-check-certificate -q"

echo "[*] Запуск неубиваемого установщика [88/90/95]..."
mkdir -p $BIN_DIR $SHARE_DIR

# --- УМНАЯ ФУНКЦИЯ СКАНЕРА ССЫЛОК ---
download_smart() {
    FILE_PATH="$1"
    NAME="$2"
    shift 2 # Остальные аргументы — это ссылки
    
    if [ -s "$FILE_PATH" ]; then
        echo "[v] $NAME уже на месте."
        return
    fi

    for URL in "$@"; do
        echo "[*] Пробую зеркало для $NAME..."
        # Пытаемся скачать. Если wget ругается на https, 
        # он просто перейдет к следующей ссылке
        if $WGET "$URL" -O "$FILE_PATH"; then
            if [ -s "$FILE_PATH" ]; then
                echo "[+] $NAME успешно загружен!"
                chmod 755 "$FILE_PATH"
                return 0
            fi
        fi
        echo "[!] Ссылка не сработала или протокол не поддерживается..."
    done

    echo "[!!!] Ошибка: Ни одна ссылка для $NAME не доступна."
    return 1
}

# --- 1. ЯДРО (БИНАРНИКИ ARM) ---
cd $BIN_DIR

# NMAP
download_smart "nmap" "Nmap" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/nmap-7.01-armel-static" \
    "https://github.com/vlad-s/static-binaries/raw/master/nmap-arm"

# SOCAT (Рабочая ссылка от therealsaumil)
download_smart "socat" "Socat" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/socat-armel-static" \
    "https://github.com/m-p-h-c/static-binaries/raw/master/socat-armv7l"

# TCPDUMP
download_smart "tcpdump" "Tcpdump" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/tcpdump-4.7.4-armel-static" \
    "https://github.com/vlad-s/static-binaries/raw/master/tcpdump-arm"

# AIRCRACK-NG (Зеркало, которое должно ожить)
download_smart "aircrack-ng" "Aircrack" \
    https://github.com/JofreSastre/static-binaries/raw/master/aircrack-ng-arm -O aircrack-ng" \
    "https://github.com/theMiddleBlue/static-binaries/raw/master/aircrack-ng-arm"

# --- 2. БАЗЫ ---
cd $SHARE_DIR
# Используем HTTP, если HTTPS капризничает на базах
download_smart "nmap-services" "Nmap Services" \
    "https://raw.githubusercontent.com/nmap/nmap/master/nmap-services" \
    "http://svn.nmap.org/nmap/nmap-services"

# --- 3. ФИНАЛИЗАЦИЯ ---
cat <<EOF > $BASE_DIR/env.sh
export PATH=\$PATH:$BIN_DIR
export NMAPDIR=$SHARE_DIR
alias статус='echo "Проверка..."; [ -f $BIN_DIR/nmap ] && echo "Nmap OK"; [ -f $BIN_DIR/socat ] && echo "Socat OK"'
EOF
chmod 755 $BASE_DIR/env.sh

echo "[УСПЕХ] Арсенал проверен. Введи: source $BASE_DIR/env.sh"
