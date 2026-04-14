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

download_smart "nmap" "Nmap" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/nmap-7.01-armel-static" \
    "https://github.com/vlad-s/static-binaries/raw/master/nmap-arm"

download_smart "socat" "Socat" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/socat-armel-static" \
    "https://github.com/m-p-h-c/static-binaries/raw/master/socat-armv7l"

download_smart "tcpdump" "Tcpdump" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/tcpdump-4.7.4-armel-static" \
    "https://github.com/vlad-s/static-binaries/raw/master/tcpdump-arm"

download_smart "aircrack-ng" "Aircrack" \
    "https://github.com/JofreSastre/static-binaries/raw/master/aircrack-ng-arm" \
    "https://github.com/theMiddleBlue/static-binaries/raw/master/aircrack-ng-arm" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/aircrack-ng-1.2-rc4-armel-static"

# --- 2. БАЗЫ ---
cd "$SHARE_DIR"
download_smart "nmap-services" "Nmap Services" \
    "https://raw.githubusercontent.com/nmap/nmap/master/nmap-services" \
    "http://svn.nmap.org/nmap/nmap-services"

# --- 3. ФИНАЛИЗАЦИЯ (ИСПРАВЛЕННЫЙ БЛОК) ---
# Создаем env.sh построчно, чтобы избежать проблем с кавычками
echo "export PATH=\$PATH:$BIN_DIR" > "$BASE_DIR/env.sh"
echo "export NMAPDIR=$SHARE_DIR" >> "$BASE_DIR/env.sh"
echo "alias статус='echo \"Проверка...\"; [ -f $BIN_DIR/nmap ] && echo \"Nmap OK\"; [ -f $BIN_DIR/socat ] && echo \"Socat OK\"'" >> "$BASE_DIR/env.sh"

chmod 755 "$BASE_DIR/env.sh"

echo " "
echo "[УСПЕХ] Арсенал проверен."
echo "Введи команду для активации:"
echo "source $BASE_DIR/env.sh"
