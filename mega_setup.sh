#!/data/data/com.termux/files/usr/bin/bash

# 1. ЖЕСТКАЯ ПРИВЯЗКА ПЕРЕМЕННЫХ ОКРУЖЕНИЯ
export T_PREFIX="/data/data/com.termux/files/usr"
export T_BIN="$T_PREFIX/bin"
export T_LIB="$T_PREFIX/lib"
export T_ETC="$T_PREFIX/etc"
export T_HOME="/data/data/com.termux/files/home"

# Форсируем пути для библиотек, иначе получим "not found"
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:$PATH"

echo "[*] СТАРТ: ГАМБИТ ЭВРИСТИЧЕСКАЯ РЕАНИМАЦИЯ"

# 2. ЭВРИСТИЧЕСКАЯ КОРРЕКЦИЯ ПРАВ (CHMOD 755 везде, где это критично)
echo "[*] Эвристическая настройка прав..."
# Права на основные бинарники
$T_BIN/chmod 755 $T_BIN/proot $T_BIN/apt $T_BIN/wget $T_BIN/curl $T_BIN/tar $T_BIN/chmod 2>/dev/null

# Права на системные библиотеки (иногда они помечаются как неисполняемые)
$T_BIN/chmod 644 $T_LIB/*.so 2>/dev/null

# Права на методы APT (твой затык с HTTPS был именно здесь)
$T_BIN/chmod 755 $T_LIB/apt/methods/* 2>/dev/null

# Права на временные папки (чтобы apt мог создавать кэш)
$T_BIN/chmod 1777 /data/data/com.termux/files/usr/var/lib/apt/lists/partial 2>/dev/null

# 3. ФИКС РЕПОЗИТОРИЕВ (Переход на HTTP для стабильности на старом Android)
echo "[*] Настройка источников (Fallback HTTP)..."
echo "deb http://packages.termux.org/termux-main-21 stable main" > $T_ETC/apt/sources.list

# 4. ОБНОВЛЕНИЕ СИСТЕМЫ С ПОДАВЛЕНИЕМ SSL-ОШИБОК
echo "[*] Обновление базы пакетов..."
LD_LIBRARY_PATH=$T_LIB $T_BIN/apt update -y -o "Acquire::https::Verify-Peer=false" -o "Acquire::AllowInsecureRepositories=true"

echo "[*] Установка зависимостей (wget, tar, xz)..."
LD_LIBRARY_PATH=$T_LIB $T_BIN/apt install wget tar xz-utils -y --force-yes -o "Acquire::https::Verify-Peer=false"

# 5. ПОДГОТОВКА СРЕДЫ KALI
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"

$T_BIN/mkdir -p "$ROOTFS"
cd "$T_HOME"

# 6. ЗАГРУЗКА ОБРАЗА (с обходом проверки сертификатов)
if [ ! -f "$T_HOME/kali.tar.xz" ]; then
    echo "[*] ЗАГРУЗКА ОБРАЗА KALI ARMHF..."
    LD_LIBRARY_PATH=$T_LIB $T_BIN/wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O "$T_HOME/kali.tar.xz"
fi

# 7. РАСПАКОВКА ЧЕРЕЗ PROOT (Force Link2Symlink)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] РАСПАКОВКА... ЖДИ (может занять до 15 минут)..."
    # Даем права на сам архив перед распаковкой
    $T_BIN/chmod 644 "$T_HOME/kali.tar.xz"
    LD_LIBRARY_PATH=$T_LIB $T_BIN/proot --link2symlink $T_BIN/tar -xJf "$T_HOME/kali.tar.xz" -C "$ROOTFS" || { echo "[!] Сбой распаковки"; exit 1; }
fi

# 8. ИСПРАВЛЕНИЕ СЕТИ И СОЗДАНИЕ ЗАПУСКА
$T_BIN/mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

echo "[*] Финализация пускового скрипта g_kali..."
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

$T_BIN/chmod 755 "$T_HOME/g_kali"

echo "---------------------------------------"
echo "[✔] ГАМБИТ ЗАВЕРШЕН УСПЕШНО!"
echo "[*] Для входа в Kali: bash ~/g_kali"
echo "---------------------------------------"
