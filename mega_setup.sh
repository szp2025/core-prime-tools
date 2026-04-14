#!/data/data/com.termux/files/usr/bin/bash

# Прямые пути для стабильности
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_ETC="/data/data/com.termux/files/usr/etc"
T_HOME="/data/data/com.termux/files/home"

echo "[*] СТАРТ РЕАНИМАЦИИ ГАМБИТА..."

# 1. Исправляем репозитории
echo "deb http://packages.termux.org/termux-main-21 stable main" > $T_ETC/apt/sources.list

# 2. ПРИНУДИТЕЛЬНАЯ НАСТРОЙКА ПРАВ (Твой запрос)
echo "[*] Настройка прав доступа к методам APT..."
chmod +x $T_BIN/apt
chmod +x $T_BIN/gpg
chmod +x $T_LIB/apt/methods/http
chmod +x $T_LIB/apt/methods/https
chmod +x $T_BIN/curl
chmod +x $T_BIN/tar

# 3. Обновление (с подавлением ошибок SSL и использованием прямых либ)
export LD_LIBRARY_PATH=$T_LIB
$T_BIN/apt update -o "Acquire::https::Verify-Peer=false"

# 4. Подготовка папок для Kali
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"
mkdir -p "$ROOTFS"
cd "$T_HOME"

# Новое имя файла согласно скриншоту
#FILE_NAME="kali-nethunter-rootfs-minimal-armhf.tar.xz"
#URL="https://kali.download/nethunter-images/current/rootfs/$FILE_NAME"

# 5. Загрузка (если вдруг файл удалили или он битый)
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка образа Kali..."
    $T_BIN/curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
fi

# 6. РАСПАКОВКА НАПРЯМУЮ (Обходим ошибку proot execve)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] Распаковка образа... Это займет 5-10 минут."
    $T_BIN/tar -xJf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
fi

# 7. Настройка интернета внутри Kali
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# 8. Создание скрипта запуска
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
echo "[✔] ГОТОВО! Теперь просто напиши:"
echo "bash ~/g_kali"
echo "---------------------------------------"
