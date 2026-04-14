#!/data/data/com.termux/files/usr/bin/bash

# --- ПАРАМЕТРЫ ПУТЕЙ ---
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_ETC="/data/data/com.termux/files/usr/etc"
T_HOME="/data/data/com.termux/files/home"
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"

# Новое имя файла согласно скриншоту
FILE_NAME="kali-nethunter-rootfs-minimal-armhf.tar.xz"
URL="https://kali.download/nethunter-images/current/rootfs/$FILE_NAME"

echo "[*] СТАРТ ПОЛНОЙ УСТАНОВКИ (FIXED URL)..."

# 1. ПРИНУДИТЕЛЬНАЯ РЕАНИМАЦИЯ ПРАВ
echo "[*] Восстановление прав доступа к инструментам..."
chmod 755 $T_BIN/* 2>/dev/null
chmod 755 $T_LIB/apt/methods/* 2>/dev/null

# 2. ОЧИСТКА СТАРОГО МУСОРА
if [ -d "$ROOTFS" ]; then
    echo "[!] Найдена старая папка установки. Удаляю для очистки места..."
    rm -rf "$ROOTFS"
fi

# 3. НАСТРОЙКА РЕПОЗИТОРИЕВ (HTTP-FIX)
echo "[*] Настройка репозиториев (HTTP mode)..."
echo "deb http://packages.termux.org/termux-main-21 stable main" > $T_ETC/apt/sources.list
echo "deb http://packages.termux.dev/termux-main-21/ stable main" >> $T_ETC/apt/sources.list

# 4. ОБНОВЛЕНИЕ APT И ЗАВИСИМОСТЕЙ
export LD_LIBRARY_PATH=$T_LIB
echo "[*] Обновление базы пакетов..."
$T_BIN/apt update -y -o "Acquire::https::Verify-Peer=false" || echo "[!] Репозитории недоступны, попробуем продолжить..."
$T_BIN/apt install xz-utils wget proot tar -y -o "Acquire::https::Verify-Peer=false"

# 5. ЗАГРУЗКА ОБРАЗА (ПО ПРЯМОЙ ССЫЛКЕ СО СКРИНШОТА)
cd "$T_HOME"
if [ ! -f "$FILE_NAME" ]; then
    echo "[*] Загрузка актуального образа: $FILE_NAME"
    # Очищаем старые битые закачки если есть
    rm -f *.tar.xz.tmp 
    $T_BIN/wget --no-check-certificate "$URL" -O "$FILE_NAME"
else
    echo "[✔] Образ $FILE_NAME уже скачан."
fi

# 6. ПРЯМАЯ РАСПАКОВКА (ОБХОД ОШИБОК PROOT)
mkdir -p "$ROOTFS"
echo "[*] НАЧИНАЮ РАСПАКОВКУ (5-10 МИНУТ)..."
# Используем tar напрямую из Termux
$T_BIN/tar -xJf "$FILE_NAME" -C "$ROOTFS" --exclude='dev'

if [ $? -eq 0 ]; then
    echo "[✔] УСПЕХ! Распаковка завершена."
else
    echo "[!] ОШИБКА РАСПАКОВКИ! Проверь свободное место на телефоне."
    exit 1
fi

# 7. ФИКС DNS И СЕТИ
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# 8. ФИНАЛЬНЫЙ СКРИПТ ЗАПУСКА (G_KALI)
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
echo "[✔] УСТАНОВКА ПОЛНОСТЬЮ ЗАВЕРШЕНА!"
echo "[*] Теперь просто напиши:"
echo "bash ~/g_kali"
echo "---------------------------------------"
