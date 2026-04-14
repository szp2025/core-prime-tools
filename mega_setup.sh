#!/data/data/com.termux/files/usr/bin/bash

# Прямые пути
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_HOME="/data/data/com.termux/files/home"
ROOTFS="$T_HOME/kali/rootfs"

echo "[*] РЕЖИМ ПРЯМОЙ УСТАНОВКИ (ОБХОД APT)..."

# 1. Настройка окружения (библиотеки)
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:$PATH"

# 2. Создаем папки
mkdir -p "$ROOTFS"

# 3. Настройка прав для curl и tar (на всякий случай)
[ -f "$T_BIN/curl" ] && chmod 755 "$T_BIN/curl"
[ -f "$T_BIN/tar" ] && chmod 755 "$T_BIN/tar"

# 4. Загрузка образа (Строго по ссылке со скрина)
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка Kali Minimal ARMHF через curl..."
    $T_BIN/curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
else
    echo "[✔] Архив уже скачан, пропускаем загрузку."
fi

# 5. Распаковка (Прямой tar)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] Распаковка образа... Это займет время (5-15 минут)."
    echo "[*] Если экран погаснет, процесс может прерваться!"
    $T_BIN/tar -xJf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
    
    if [ $? -eq 0 ]; then
        echo "[✔] Распаковка завершена!"
    else
        echo "[!] Ошибка распаковки. Возможно, мало места."
        exit 1
    fi
fi

# 6. Фикс DNS
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# 7. Создание скрипта запуска g_kali
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
echo "[✔] ВСЁ ГОТОВО!"
echo "[*] Запускай Kali командой: bash ~/g_kali"
echo "---------------------------------------"
