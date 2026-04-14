#!/data/data/com.termux/files/usr/bin/bash

# ОПРЕДЕЛЯЕМ ЖЕСТКИЕ ПУТИ (БЕЗ ПЕРЕМЕННЫХ, КОТОРЫЕ МОГУТ СЛЕТЕТЬ)
T_BIN="/data/data/com.termux/files/usr/bin"
T_ETC="/data/data/com.termux/files/usr/etc"
T_HOME="/data/data/com.termux/files/home"

echo "[*] ИСПРАВЛЕНИЕ READ-ONLY ОШИБОК..."

# 1. Записываем репозитории (этот путь внутри Termux всегда доступен на запись)
echo "deb https://packages.termux.org/termux-main-21 stable main" > $T_ETC/apt/sources.list

# 2. Установка инструментов
$T_BIN/apt update -o "Acquire::https::Verify-Peer=false"
$T_BIN/apt install wget proot tar xz-utils -y -o "Acquire::https::Verify-Peer=false"

# 3. Настройка папок для Kali (СТРОГО В HOME)
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"

# Удаляем старое, если оно мешает, и создаем заново
$T_BIN/rm -rf "$BASE"
$T_BIN/mkdir -p "$ROOTFS"
cd "$T_HOME"

# 4. Загрузка образа
if [ ! -f "$T_HOME/kali.tar.xz" ]; then
    echo "[*] ЗАГРУЗКА ОБРАЗА В $T_HOME..."
    $T_BIN/wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O "$T_HOME/kali.tar.xz"
fi

# 5. Распаковка (самый важный этап для обхода Read-only)
echo "[*] РАСПАКОВКА В $ROOTFS..."
$T_BIN/proot --link2symlink $T_BIN/tar -xJf "$T_HOME/kali.tar.xz" -C "$ROOTFS"

# 6. Создание скрипта запуска
cat > "$T_HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
unset LD_PRELOAD
exec $T_BIN/proot \\
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

$T_BIN/chmod 755 "$T_HOME/g_kali"

echo "---------------------------------------"
echo "[✔] УСТАНОВКА ЗАВЕРШЕНА!"
echo "[*] Запуск: bash ~/g_kali"
echo "---------------------------------------"
