#!/data/data/com.termux/files/usr/bin/bash

# Пути
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_ETC="/data/data/com.termux/files/usr/etc"
T_HOME="/data/data/com.termux/files/home"
ROOTFS="$T_HOME/kali/rootfs"

echo "[*] СТАРТ РЕАНИМАЦИИ (FINAL FIX)..."

# 1. Создаем структуру (чтобы chmod не ругался на отсутствие папок)
mkdir -p "$ROOTFS"
mkdir -p "$T_LIB/apt/methods"

# 2. ФИКС: Устанавливаем права 755 по одному (избегаем bad mode)
# Если файл есть - даем права. Если нет - молча идем дальше.
[ -f "$T_BIN/apt" ] && chmod 755 "$T_BIN/apt"
[ -f "$T_BIN/curl" ] && chmod 755 "$T_BIN/curl"
[ -f "$T_BIN/tar" ] && chmod 755 "$T_BIN/tar"
[ -f "$T_LIB/apt/methods/http" ] && chmod 755 "$T_LIB/apt/methods/http"
[ -f "$T_LIB/apt/methods/https" ] && chmod 755 "$T_LIB/apt/methods/https"

# 3. Настройка репозитория (строго HTTP)
echo "deb http://packages.termux.org/termux-main-21 stable main" > "$T_ETC/apt/sources.list"

# 4. Переменные окружения (чтобы либы виделись всегда)
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:$PATH"

# 5. Обновление APT (теперь методы http/https должны ожить)
echo "[*] Обновление источников..."
$T_BIN/apt update -o "Acquire::https::Verify-Peer=false"

# 6. Загрузка Kali (ссылка с твоего скриншота)
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка Kali Minimal ARMHF..."
    $T_BIN/curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
fi

# 7. Распаковка НАПРЯМУЮ (Обход proot execve)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] Распаковка... Это займет около 10 минут."
    $T_BIN/tar -xJf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
fi

# 8. Фикс DNS и создание скрипта запуска
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

cat > "$T_HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
export LD_LIBRARY_PATH=$T_LIB
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

chmod 755 "$T_HOME/g_kali"

echo "---------------------------------------"
echo "[✔] ГОТОВО! Теперь запускай:"
echo "bash ~/g_kali"
