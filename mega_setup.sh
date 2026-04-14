#!/data/data/com.termux/files/usr/bin/bash

# Жесткие пути
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_ETC="/data/data/com.termux/files/usr/etc"
T_HOME="/data/data/com.termux/files/home"

echo "[*] СТАРТ РЕАНИМАЦИИ (FIXING BAD MODE)..."

# 1. Сначала создаем структуру папок, если её нет
mkdir -p $T_HOME/kali/rootfs
mkdir -p $T_LIB/apt/methods

# 2. Исправляем права (используем числовой формат 755)
# Это лечит ошибку "Failed to exec method"
chmod 755 $T_BIN/apt 2>/dev/null
chmod 755 $T_BIN/curl 2>/dev/null
chmod 755 $T_BIN/tar 2>/dev/null
chmod 755 $T_LIB/apt/methods/http 2>/dev/null
chmod 755 $T_LIB/apt/methods/https 2>/dev/null

# 3. Настройка репозитория (только HTTP для стабильности на Android 5.1)
echo "deb http://packages.termux.org/termux-main-21 stable main" > $T_ETC/apt/sources.list

# 4. Обновление через прямой путь к библиотекам
export LD_LIBRARY_PATH=$T_LIB
$T_BIN/apt update -o "Acquire::https::Verify-Peer=false"

# 5. Загрузка Kali (Ссылка строго со скриншота)
cd $T_HOME
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка Kali Minimal ARMHF..."
    $T_BIN/curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
fi

# 6. Распаковка (Напрямую через tar из Termux)
if [ ! -d "$T_HOME/kali/rootfs/bin" ]; then
    echo "[*] Распаковка... Не выключай экран."
    $T_BIN/tar -xJf "kali.tar.xz" -C "$T_HOME/kali/rootfs" --exclude='dev'
fi

# 7. Настройка DNS
echo "nameserver 8.8.8.8" > "$T_HOME/kali/rootfs/etc/resolv.conf"

# 8. Скрипт запуска g_kali
cat > "$T_HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
export LD_LIBRARY_PATH=$T_LIB
unset LD_PRELOAD
exec $T_BIN/proot \\
--link2symlink \\
-0 \\
-r $T_HOME/kali/rootfs \\
-b /dev -b /proc -b /sys -b /sdcard \\
-w /root \\
/usr/bin/env -i \\
HOME=/root \\
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
TERM=\$TERM \\
/bin/bash --login
EOF

chmod 755 "$T_HOME/g_kali"

echo "---------------------------------------"
echo "[✔] ГОТОВО! Запуск: bash ~/g_kali"
echo "---------------------------------------"
