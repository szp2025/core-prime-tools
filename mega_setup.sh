#!/system/bin/sh

# --- ГЛОБАЛЬНЫЕ ПУТИ ---
BASE_DIR="/data/local/tmp"
BIN_DIR="$BASE_DIR/bin"
SHARE_DIR="$BASE_DIR/share/nmap"

# Используем исправленный системный WGET
WGET="wget --no-check-certificate -q"

echo "[*] Запуск неубиваемого установщика [88/90/95/PKG]..."
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

# --- 0. ОЖИВЛЯЕМ PKG (РЕПОЗИТОРИИ) ---
echo "[*] Настройка репозиториев для Android 5.1..."
if [ -d "$PREFIX/etc/apt" ]; then
    echo "deb https://termux.pwn.net/termux-main-21 stable main" > "$PREFIX/etc/apt/sources.list"
    # Добавляем альтернативное зеркало Grimler
    echo "deb https://main.termux-mirror.ml stable main" >> "$PREFIX/etc/apt/sources.list"
fi

# --- 1. ЯДРО (БИНАРНИКИ ARM) ---
cd "$BIN_DIR"

# NMAP
download_smart "nmap" "Nmap" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/nmap-7.01-armel-static" \
    "https://github.com/vlad-s/static-binaries/raw/master/nmap-arm"

# SOCAT (Твой рабочий 1.7.3.2)
download_smart "socat" "Socat" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/socat-armel-static" \
    "https://github.com/m-p-h-c/static-binaries/raw/master/socat-armv7l"

# TCPDUMP
download_smart "tcpdump" "Tcpdump" \
    "https://github.com/therealsaumil/static-arm-bins/raw/master/tcpdump-4.7.4-armel-static" \
    "https://github.com/vlad-s/static-binaries/raw/master/tcpdump-arm"

# AIRCRACK-NG (Смешанные ссылки для пробива)
download_smart "aircrack-ng" "Aircrack" \
    "http://distro.ibiblio.org/fatdog/arm/packages/700/aircrack-ng-1.2-rc1-arm-1.txz" \
    "https://github.com/theMiddleBlue/static-binaries/raw/master/aircrack-ng-arm" \
    "https://github.com/JofreSastre/static-binaries/raw/master/aircrack-ng-arm" \
    "http://andpwn.com/binaries/aircrack-ng-arm"

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
echo "[УСПЕХ] Все ссылки добавлены. PKG настроен."
echo "Введи: source $BASE_DIR/env.sh"
