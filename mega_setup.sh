#!/data/data/com.termux/files/usr/bin/bash

# Настройка путей и либ
export T_BIN="/data/data/com.termux/files/usr/bin"
export T_LIB="/data/data/com.termux/files/usr/lib"
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:$PATH"

T_HOME="/data/data/com.termux/files/home"
ROOTFS="$T_HOME/kali/rootfs"

echo "[*] ФОРСИРОВАННАЯ УСТАНОВКА (БЕЗ APT МЕТОДОВ)..."

# 1. Создание папок
mkdir -p "$ROOTFS"

# 2. Проверка и фикс прав для curl/tar
[ -f "$T_BIN/curl" ] && chmod 755 "$T_BIN/curl"
[ -f "$T_BIN/tar" ] && chmod 755 "$T_BIN/tar"

# 3. Загрузка напрямую через CURL (игнорируя методы apt)
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка образа через CURL (игнорируем ошибки http/https)..."
    # Флаг -k игнорирует проблемы с сертификатами SSL
    $T_BIN/curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
else
    echo "[✔] Образ найден в памяти, скачивание не требуется."
fi

# 4. Прямая распаковка (БЕЗ использования proot на этом этапе)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] НАЧАЛО РАСПАКОВКИ..."
    echo "[*] Это займет около 10-15 минут. Не закрывай терминал."
    
    # Используем tar напрямую, чтобы избежать execve ошибок
    $T_BIN/tar -xJf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
    
    if [ $? -eq 0 ]; then
        echo "[✔] Успешно распаковано!"
    else
        echo "[!] Критическая ошибка при распаковке. Проверь место (нужно ~2GB)."
        exit 1
    fi
fi

# 5. Настройка DNS внутри будущего Kali
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# 6. Создание скрипта входа g_kali
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
echo "[✔] УСТАНОВКА ЗАВЕРШЕНА!"
echo "[*] Теперь просто введи: bash ~/g_kali"
echo "---------------------------------------"
