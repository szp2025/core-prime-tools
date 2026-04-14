#!/data/data/com.termux/files/usr/bin/bash

# Прямые пути
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_HOME="/data/data/com.termux/files/home"
ROOTFS="$T_HOME/kali/rootfs"

echo "[*] ФИНАЛЬНЫЙ РЫВОК (БЕЗ APT И С ФИКСОМ ПРАВ TAR)..."

# 1. Окружение
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:$PATH"

# 2. Создаем папку
mkdir -p "$ROOTFS"

# 3. ЧИНИМ ПРАВА ДЛЯ ВСЕХ ИНСТРУМЕНТОВ РАСПАКОВКИ
# Это уберет ошибку "Cannot exec: Permission denied"
echo "[*] Настройка прав для бинарников..."
for tool in tar xz gzip curl proot; do
    [ -f "$T_BIN/$tool" ] && chmod 755 "$T_BIN/$tool"
done

# 4. Загрузка через CURL (если файла еще нет)
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка образа через CURL..."
    $T_BIN/curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
fi

# 5. РАСПАКОВКА (С ФИКСОМ PATH)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] НАЧАЛО РАСПАКОВКИ..."
    echo "[*] Если опять будет Permission Denied, мы попробуем другой метод."
    
    # Принудительно указываем tar, где искать xz
    $T_BIN/tar --xz -xvf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
    
    if [ $? -eq 0 ]; then
        echo "[✔] Успешно распаковано!"
    else
        echo "[!] Ошибка. Пробуем упрощенный метод..."
        # Запасной вариант если первый упал
        cat "kali.tar.xz" | $T_BIN/xz -d | $T_BIN/tar -x -C "$ROOTFS"
    fi
fi

# 6. DNS и запуск
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
echo "[✔] ГОТОВО! Запускай: bash ~/g_kali"
