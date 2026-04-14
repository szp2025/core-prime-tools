#!/data/data/com.termux/files/usr/bin/bash

# Настройка путей
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_ETC="/data/data/com.termux/files/usr/etc"
T_HOME="/data/data/com.termux/files/home"
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"

# 1. ПРИНУДИТЕЛЬНАЯ РЕАНИМАЦИЯ ПРАВ
echo "[*] Исправляем права на методы APT и бинарники..."
chmod 755 $T_BIN/*
chmod 755 $T_LIB/apt/methods/* 2>/dev/null

# 2. ОЧИСТКА МЕСТА
if [ -d "$ROOTFS" ]; then
    echo "[!] Удаление старой папки rootfs..."
    rm -rf "$ROOTFS"
fi

# 3. НАСТРОЙКА РЕПОЗИТОРИЕВ (ПЕРЕХОД НА HTTP ДЛЯ ОБХОДА HTTPS ERROR)
echo "[*] Переключаемся на HTTP (обход ошибки Exec Method)..."
echo "deb http://packages.termux.org/termux-main-21 stable main" > $T_ETC/apt/sources.list
echo "deb http://packages.termux.dev/termux-main-21/ stable main" >> $T_ETC/apt/sources.list

# 4. ОБНОВЛЕНИЕ С ИГНОРИРОВАНИЕМ SSL
export LD_LIBRARY_PATH=$T_LIB
echo "[*] Обновление базы пакетов..."
$T_BIN/apt update -y -o "Acquire::https::Verify-Peer=false" || echo "[!] Пропускаем апдейт, пробуем так..."

# 5. ЗАГРУЗКА (ЕСЛИ НЕТ АРХИВА)
cd "$T_HOME"
if [ ! -f "kali.tar.xz" ]; then
    echo "[*] Загрузка образа Kali..."
    $T_BIN/wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O kali.tar.xz
fi

# 6. ПРЯМАЯ РАСПАКОВКА (ГЛАВНЫЙ ЭТАП)
mkdir -p "$ROOTFS"
echo "[*] НАЧИНАЮ ПРЯМУЮ РАСПАКОВКУ ТАРОМ..."
$T_BIN/tar -xJf kali.tar.xz -C "$ROOTFS" --exclude='dev'

if [ $? -eq 0 ]; then
    echo "[✔] УСПЕХ! Файловая система готова."
else
    echo "[!] Ошибка распаковки. Проверь место (нужно ~2ГБ)."
    exit 1
fi

# 7. ФИНАЛЬНЫЙ СКРИПТ ЗАПУСКА
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
echo "[✔] ГОТОВО! Входи в Kali:"
echo "bash ~/g_kali"
echo "---------------------------------------"
