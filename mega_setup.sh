#!/data/data/com.termux/files/usr/bin/bash

# Прямое указание путей и библиотек (Реанимация)
export T_BIN="/data/data/com.termux/files/usr/bin"
export T_LIB="/data/data/com.termux/files/usr/lib"
export T_ETC="/data/data/com.termux/files/usr/etc"
export T_HOME="/data/data/com.termux/files/home"
export LD_LIBRARY_PATH=$T_LIB
export PATH=$T_BIN:$PATH

echo "[*] СТАРТ: ГАМБИТ РЕАНИМАЦИЯ (Core Prime Edition)"

# 1. ПРИНУДИТЕЛЬНАЯ УСТАНОВКА ПРАВ (на случай ручной заливки)
echo "[*] Фиксация прав доступа (755)..."
$T_BIN/chmod 755 $T_BIN/proot 2>/dev/null
$T_BIN/chmod 755 $T_BIN/apt 2>/dev/null
$T_BIN/chmod 755 $T_LIB/apt/methods/* 2>/dev/null

# 2. ФИКС РЕПОЗИТОРИЕВ (Переход на HTTP, если HTTPS хромает)
echo "[*] Настройка источников (HTTP Mode)..."
echo "deb http://packages.termux.org/termux-main-21 stable main" > $T_ETC/apt/sources.list

# 3. ОБНОВЛЕНИЕ APT С УКАЗАНИЕМ БИБЛИОТЕК
echo "[*] Обновление пакетов..."
LD_LIBRARY_PATH=$T_LIB $T_BIN/apt update -o "Acquire::https::Verify-Peer=false"
LD_LIBRARY_PATH=$T_LIB $T_BIN/apt install wget tar xz-utils -y -o "Acquire::https::Verify-Peer=false"

# 4. ПОДГОТОВКА СРЕДЫ KALI
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"

$T_BIN/mkdir -p "$ROOTFS"
cd "$T_HOME"

# 5. ЗАГРУЗКА ОБРАЗА (если не скачан)
if [ ! -f "$T_HOME/kali.tar.xz" ]; then
    echo "[*] ЗАГРУЗКА ОБРАЗА KALI..."
    LD_LIBRARY_PATH=$T_LIB $T_BIN/wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O "$T_HOME/kali.tar.xz"
fi

# 6. РАСПАКОВКА ЧЕРЕЗ PROOT (Force Mode)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] РАСПАКОВКА (ЭТО ЗАЙМЕТ ВРЕМЯ)..."
    LD_LIBRARY_PATH=$T_LIB $T_BIN/proot --link2symlink $T_BIN/tar -xJf "$T_HOME/kali.tar.xz" -C "$ROOTFS"
fi

# 7. ИСПРАВЛЕНИЕ DNS ВНУТРИ KALI
$T_BIN/mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# 8. СОЗДАНИЕ ПУСКОВОГО ФАЙЛА G_KALI
echo "[*] Создание скрипта запуска g_kali..."
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
echo "[✔] ГОТОВО! БАЗА ВОССТАНОВЛЕНА."
echo "[*] ВХОД В KALI: bash ~/g_kali"
echo "---------------------------------------"
