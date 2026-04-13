#!/system/bin/sh

# --- ГЛОБАЛЬНЫЕ ПУТИ ---
BASE_DIR="/data/local/tmp"
BIN_DIR="$BASE_DIR/bin"
SHARE_DIR="$BASE_DIR/share/nmap"

# Находим BusyBox
[ -f "$BIN_DIR/busybox" ] && BB="$BIN_DIR/busybox" || BB="busybox"
WGET="$BB wget --no-check-certificate -q"

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
        if $WGET "$URL" -O "$FILE_PATH"; then
            if [ -s "$FILE_PATH" ]; then
                echo "[+] $NAME успешно загружен!"
                chmod 755 "$FILE_PATH"
                return 0
            fi
        fi
        echo "[!] Ссылка не сработала, ищу дальше..."
    done

    echo "[!!!] Ошибка: Ни одна ссылка для $NAME не доступна."
    return 1
}

# --- 1. ЯДРО (БИНАРНИКИ ARM) ---
cd $BIN_DIR

# NMAP (Зеркала: vlad-s, andrew-d, termux-bin)
download_smart "nmap" "Nmap" \
    "https://github.com/vlad-s/static-binaries/raw/master/nmap-arm" \
    "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/armel/nmap" \
    "https://raw.githubusercontent.com/optiv/static-binaries/master/nmap-arm"

# SOCAT (Сердце Модуля [95])
download_smart "socat" "Socat" \
    "https://github.com/vlad-s/static-binaries/raw/master/socat-arm" \
    "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/armel/socat"

# TCPDUMP (Модуль [88])
download_smart "tcpdump" "Tcpdump" \
    "https://github.com/vlad-s/static-binaries/raw/master/tcpdump-arm" \
    "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/armel/tcpdump"

# AIRCRACK-NG (Wifislax/Kali)
download_smart "aircrack-ng" "Aircrack" \
    "https://github.com/vlad-s/static-binaries/raw/master/aircrack-ng-arm" \
    "https://raw.githubusercontent.com/theMiddleBlue/static-binaries/master/aircrack-ng-arm"

# --- 2. БАЗЫ (ОФИЦИАЛЬНЫЕ + ЗЕРКАЛА) ---
cd $SHARE_DIR
download_smart "nmap-services" "Nmap Services" \
    "https://raw.githubusercontent.com/nmap/nmap/master/nmap-services" \
    "https://svn.nmap.org/nmap/nmap-services"

# --- 3. ФИНАЛИЗАЦИЯ ---
cat <<EOF > $BASE_DIR/env.sh
export PATH=\$PATH:$BIN_DIR
export NMAPDIR=$SHARE_DIR
alias статус='echo "Проверка..."; [ -f $BIN_DIR/nmap ] && echo "Nmap OK"; [ -f $BIN_DIR/socat ] && echo "Socat OK"'
EOF
chmod 755 $BASE_DIR/env.sh

echo "[УСПЕХ] Арсенал проверен. Введи: source $BASE_DIR/env.sh"

