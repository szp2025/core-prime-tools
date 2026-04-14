#!/data/data/com.termux/files/usr/bin/bash

# Прямые пути
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_HOME="/data/data/com.termux/files/home"
ROOTFS="$T_HOME/kali/rootfs"

echo "[*] ФОРСИРОВАННАЯ УСТАНОВКА (ФИКС ПРАВ)..."

# 1. Настройка окружения
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:$PATH"

# 2. Создаем структуру папок
mkdir -p "$ROOTFS"

# 3. БЕЗОПАСНАЯ СМЕНА ПРАВ (Убираем "bad mode")
echo "[*] Настройка инструментов..."
cd "$T_BIN"
# Используем максимально простой формат для каждого файла
for tool in tar xz gzip curl proot; do
    if [ -f "$tool" ]; then
        chmod 755 "$tool" || chmod +x "$tool"
    fi
done

# 4. Загрузка через CURL (если архива нет)
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка образа через CURL..."
    $T_BIN/curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
fi

# 5. РАСПАКОВКА (С прямым вызовом xz)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] НАЧАЛО РАСПАКОВКИ..."
    echo "[*] Если видишь список файлов - значит всё заработало!"
    
    # Принудительно заставляем систему видеть xz через переменную
    export XZ_OPT="--decompress"
    
    # Прямая команда распаковки (самая надежная для Android 5.1)
    $T_BIN/tar -xJf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
    
    if [ $? -ne 0 ]; then
        echo "[!] Первый метод упал, пробуем через конвейер..."
        cat "kali.tar.xz" | $T_BIN/xz -d | $T_BIN/tar -x -C "$ROOTFS"
    fi
fi

# 6. Фикс DNS и создание пускового файла
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

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

chmod 755 "$T_HOME/g_kali"

echo "---------------------------------------"
echo "[✔] ГОТОВО! Запускай: bash ~/g_kali"
