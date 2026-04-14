#!/data/data/com.termux/files/usr/bin/bash

# Настройка окружения, чтобы библиотеки нашлись
export LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib
export PATH=/data/data/com.termux/files/usr/bin:$PATH

T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_ETC="/data/data/com.termux/files/usr/etc"
T_HOME="/data/data/com.termux/files/home"

echo "[*] РЕАНИМАЦИЯ БИБЛИОТЕК И ПУТЕЙ..."

# 1. Исправляем репозитории внутри файла напрямую
echo "deb https://packages.termux.org/termux-main-21 stable main" > $T_ETC/apt/sources.list

# 2. Попытка восстановить пакеты (принудительно указывая путь к библиотекам)
LD_LIBRARY_PATH=$T_LIB $T_BIN/apt update -o "Acquire::https::Verify-Peer=false"
LD_LIBRARY_PATH=$T_LIB $T_BIN/apt install wget proot tar xz-utils -y -o "Acquire::https::Verify-Peer=false"

# 3. Пути для Kali
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"

$T_BIN/mkdir -p "$ROOTFS"
cd "$T_HOME"

# 4. Загрузка (используем wget с прописанной библиотекой)
if [ ! -f "$T_HOME/kali.tar.xz" ]; then
    echo "[*] ЗАГРУЗКА ОБРАЗА..."
    LD_LIBRARY_PATH=$T_LIB $T_BIN/wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O "$T_HOME/kali.tar.xz"
fi

# 5. Распаковка через proot
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] РАСПАКОВКА (FORCE MODE)..."
    LD_LIBRARY_PATH=$T_LIB $T_BIN/proot --link2symlink $T_BIN/tar -xJf "$T_HOME/kali.tar.xz" -C "$ROOTFS"
fi

# 6. Финальный скрипт запуска (теперь с LD_LIBRARY_PATH внутри)
cat > "$T_HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
export LD_LIBRARY_PATH=$T_LIB
export PATH=$T_BIN:\$PATH
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
echo "[✔] ГОТОВО! БАЗА ВОССТАНОВЛЕНА."
echo "[*] Запуск: bash ~/g_kali"
echo "---------------------------------------"
