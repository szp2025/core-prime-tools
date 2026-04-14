#!/data/data/com.termux/files/usr/bin/bash

# 1. ПУТИ И БИБЛИОТЕКИ
export T_PREFIX="/data/data/com.termux/files/usr"
export T_BIN="$T_PREFIX/bin"
export T_LIB="$T_PREFIX/lib"
export T_HOME="/data/data/com.termux/files/home"
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:$PATH"

# Новая актуальная ссылка со скриншота
KALI_URL="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz"

echo "[*] ОБХОД APT И ЗАГРУЗКА НОВОГО ОБРАЗА"

# 2. ОЖИВЛЯЕМ ПРАВА (на всякий случай еще раз)
$T_BIN/chmod 755 $T_BIN/* 2>/dev/null

# 3. ПОДГОТОВКА ПАПОК
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"
$T_BIN/mkdir -p "$ROOTFS"
cd "$T_HOME"

# 4. ЗАГРУЗКА (используем новое имя файла)
if [ ! -f "kali-minimal.tar.xz" ]; then
    echo "[*] СКАЧИВАНИЕ: kali-nethunter-rootfs-minimal-armhf.tar.xz"
    # Пытаемся wget, если нет - curl
    $T_BIN/wget --no-check-certificate "$KALI_URL" -O kali-minimal.tar.xz || \
    $T_BIN/curl -L -k "$KALI_URL" -o kali-minimal.tar.xz
fi

# 5. РАСПАКОВКА (БЕЗ PROOT - напрямую)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] РАСПАКОВКА НАПРЯМУЮ (ОБХОД ОШИБКИ EXECVE)..."
    # Распаковываем обычным tar, который лежит в Termux
    $T_BIN/tar -xJf "$T_HOME/kali.tar.xz" -C "$ROOTFS" || { echo "[!] ОШИБКА РАСПАКОВКИ"; exit 1; }
    
    # После прямой распаковки на Android 5.1 могут слететь права внутри
    # Мы их поправим позже внутри самого proot
fi

# 6. Создание скрипта запуска (упрощенный вход)
cat > "$T_HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
export LD_LIBRARY_PATH=$T_LIB
unset LD_PRELOAD
# Запускаем proot только для входа, а не для распаковки
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
echo "[✔] ГОТОВО! Новая ссылка сработала."
echo "[*] Запуск: bash ~/g_kali"
echo "---------------------------------------"
