#!/system/bin/sh

# --- ГЛОБАЛЬНЫЕ ПУТИ ---
BASE_DIR="/data/local/tmp"
BIN_DIR="$BASE_DIR/bin"
SHARE_DIR="$BASE_DIR/share/nmap"

# Используем исправленный системный WGET
WGET="wget --no-check-certificate -q"

echo "[*] Запуск неубиваемого установщика [88/90/95]..."
mkdir -p "$BIN_DIR" "$SHARE_DIR"

# --- УМНАЯ ФУНКЦИЯ СКАНЕРА ССЫЛОК ---
download_smart() {
    FILE_PATH="$1"
    NAME="$2"
    shift 2
    
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
        echo "[!] Ссылка не сработала..."
    done

    echo "[!!!] Ошибка: Ни одна ссылка для $NAME не доступна."
    return 1
}

# --- 1. ЯДРО (БИНАРНИКИ ARM) ---
cd "$BIN_DIR"

# NMAP (Используем armel версии как самые стабильные)
download_smart "nmap" "Nmap" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/nmap-7.01-armel-static" \
    "https://github.com/vlad-s/static-binaries/raw/master/nmap-arm" \
    "https://github.com/optiv/static-binaries/raw/master/nmap-arm"

# SOCAT (Версия 1.7.3.2)
download_smart "socat" "Socat" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/socat-armel-static" \
    "https://github.com/m-p-h-c/static-binaries/raw/master/socat-armv7l" \
    "https://github.com/3ndG4me/socat-static-binary/raw/master/socat-arm-static"

# TCPDUMP
download_smart "tcpdump" "Tcpdump" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/tcpdump-4.7.4-armel-static" \
    "https://github.com/vlad-s/static-binaries/raw/master/tcpdump-arm"

# AIRCRACK-NG (Добавил живые зеркала и HTTP-версии)
download_smart "aircrack-ng" "Aircrack" \
    "https://github.com/theMiddleBlue/static-binaries/raw/master/aircrack-ng-arm" \
    "https://github.com/JofreSastre/static-binaries/raw/master/aircrack-ng-arm" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/aircrack-ng-1.2-rc4-armel-static" \
    "http://distro.ibiblio.org/fatdog/arm/packages/700/aircrack-ng-1.2-rc1-arm-1.txz"

# --- 2. БАЗЫ ---
cd "$SHARE_DIR"
download_smart "nmap-services" "Nmap Services" \
    "https://raw.githubusercontent.com/nmap/nmap/master/nmap-services" \
    "http://svn.nmap.org/nmap/nmap-services"

# --- 3. ФИНАЛИЗАЦИЯ ---
echo "export PATH=\$PATH:$BIN_DIR" > "$BASE_DIR/env.sh"
echo "export NMAPDIR=$SHARE_DIR" >> "$BASE_DIR/env.sh"
echo "alias статус='echo \"Проверка...\"; [ -f $BIN_DIR/nmap ] && echo \"Nmap OK\"; [ -f $BIN_DIR/socat ] && echo \"Socat OK\"; [ -f $BIN_DIR/aircrack-ng ] && echo \"Aircrack OK\"'" >> "$BASE_DIR/env.sh"

chmod 755 "$BASE_DIR/env.sh"

echo " "
echo "[УСПЕХ] Арсенал проверен."
echo "Введи команду для активации:"
echo "source $BASE_DIR/env.sh"
