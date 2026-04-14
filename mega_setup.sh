#!/data/data/com.termux/files/usr/bin/bash

# Определяем базовые пути
BIN="/data/data/com.termux/files/usr/bin"
HOME_DIR="/data/data/com.termux/files/home"
BASE="$HOME_DIR/kali"
ROOTFS="$BASE/rootfs"

echo "[*] ФИКСАЦИЯ РЕПОЗИТОРИЕВ..."
# Прямая запись в конфиг apt
echo "deb https://packages.termux.org/termux-main-21 stable main" > /data/data/com.termux/files/usr/etc/apt/sources.list

echo "[*] ОБНОВЛЕНИЕ СИСТЕМЫ (ПРЯМЫЕ ПУТИ)..."
# Используем полный путь к apt
$BIN/apt update -o "Acquire::https::Verify-Peer=false"
$BIN/apt install wget proot tar xz-utils -y -o "Acquire::https::Verify-Peer=false"

echo "[*] ПОДГОТОВКА ДИРЕКТОРИЙ..."
$BIN/mkdir -p "$ROOTFS"
cd "$BASE"

# Загрузка Kali
if [ ! -f kali.tar.xz ]; then
    echo "[*] ЗАГРУЗКА ОБРАЗА..."
    $BIN/wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O kali.tar.xz
fi

# Распаковка через proot
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] РАСПАКОВКА (ЭТО ЗАЙМЕТ ВРЕМЯ)..."
    $BIN/proot --link2symlink $BIN/tar -xJf kali.tar.xz -C "$ROOTFS" || { echo "[!] ОШИБКА РАСПАКОВКИ"; exit 1; }
fi

# Настройка DNS для интернета внутри Kali
$BIN/mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# Создание пускового файла
cat > "$HOME_DIR/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
unset LD_PRELOAD
exec $BIN/proot \\
--link2symlink \\
-0 \\
-r $ROOTFS \\
-b /dev -b /proc -b /sys -b /sdcard \\
-w /root \\
/usr/bin/env -i \\
HOME=/root \\
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
TERM=\$TERM \\
/bin/bash --login
EOF

$BIN/chmod 755 "$HOME_DIR/g_kali"

echo "---------------------------------------"
echo "[✔] ГОТОВО! БАЗА УСТАНОВЛЕНА."
echo "[*] Запуск Kali: bash ~/g_kali"
echo "---------------------------------------"
