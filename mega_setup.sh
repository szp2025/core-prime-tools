#!/data/data/com.termux/files/usr/bin/bash

# Настройка путей и библиотек, чтобы всё работало напрямую
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:$PATH"

T_HOME="/data/data/com.termux/files/home"
ROOTFS="$T_HOME/kali/rootfs"

echo "[*] ФОРСИРОВАННЫЙ СТАРТ (ИГНОРИРУЕМ APT)..."

# 1. Создание структуры папок
mkdir -p "$ROOTFS"

# 2. Установка прав (числовой формат, чтобы не было "bad mode")
[ -f "$T_BIN/curl" ] && chmod 755 "$T_BIN/curl"
[ -f "$T_BIN/tar" ] && chmod 755 "$T_BIN/tar"

# 3. Загрузка Kali напрямую через CURL
# Мы используем ссылку на minimal-armhf из твоего списка
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка образа через CURL (это надежнее APT)..."
    # Флаг -k игнорирует проблемы с сертификатами SSL на старом Android
    $T_BIN/curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
else
    echo "[✔] Образ уже скачан, продолжаем..."
fi

# 4. РАСПАКОВКА НАПРЯМУЮ (Обход ошибки proot execve)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] НАЧАЛО РАСПАКОВКИ..."
    echo "[*] Это займет около 10-15 минут. НЕ ВЫКЛЮЧАЙ ЭКРАН."
    
    # Используем tar из Termux напрямую
    $T_BIN/tar -xJf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
    
    if [ $? -eq 0 ]; then
        echo "[✔] Успешно распаковано!"
    else
        echo "[!] Ошибка распаковки. Проверь память (нужно минимум 2 ГБ)."
        exit 1
    fi
fi

# 5. Настройка интернета (DNS) внутри Kali
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# 6. Создание скрипта запуска g_kali
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
echo "[*] Чтобы войти в Kali, напиши: bash ~/g_kali"
echo "---------------------------------------"
