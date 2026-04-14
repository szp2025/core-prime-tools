#!/data/data/com.termux/files/usr/bin/bash

# --- КОНФИГУРАЦИЯ ПУТЕЙ ---
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
T_ETC="/data/data/com.termux/files/usr/etc"
T_HOME="/data/data/com.termux/files/home"
BASE="$T_HOME/kali"
ROOTFS="$BASE/rootfs"

echo "[*] СТАРТ РЕАНИМАЦИИ ГАМБИТА..."

# 1. ОЧИСТКА ПРЕДЫДУЩИХ ОШИБОК
# Если папка существует, значит прошлая распаковка прервалась — удаляем её
if [ -d "$ROOTFS" ]; then
    echo "[!] Найдена поврежденная установка. Очищаю место..."
    rm -rf "$ROOTFS"
fi

# 2. ФИКСАЦИЯ ПРАВ (БЕЗ ЭТОГО БУДЕТ PERMISSION DENIED)
echo "[*] Настройка прав доступа..."
chmod 755 $T_BIN/* 2>/dev/null

# 3. НАСТРОЙКА РЕПОЗИТОРИЕВ (ОСНОВНОЙ + РЕЗЕРВНЫЙ)
echo "[*] Обновление источников пакетов..."
# Пробуем основной архив
echo "deb https://packages.termux.dev/termux-main-21/ stable main" > $T_ETC/apt/sources.list
# Если основной упадет, добавим зеркало вторым приоритетом
echo "deb http://packages.termux.org/termux-main-21 stable main" >> $T_ETC/apt/sources.list

# 4. ОБНОВЛЕНИЕ APT (ИГНОРИРУЕМ ОШИБКИ SSL И HTTPS МЕТОДОВ)
export LD_LIBRARY_PATH=$T_LIB
$T_BIN/apt update -o "Acquire::https::Verify-Peer=false" -o "Acquire::AllowInsecureRepositories=true"

# Установка необходимых утилит, если они пропали
$T_BIN/apt install wget proot tar xz-utils curl -y -o "Acquire::https::Verify-Peer=false"

# 5. ПОДГОТОВКА ПАПОК
mkdir -p "$ROOTFS"
cd "$T_HOME"

# 6. ЗАГРУЗКА ОБРАЗА (ЕСЛИ НЕТ)
if [ ! -f "kali.tar.xz" ]; then
    echo "[*] Загрузка Kali (armhf)..."
    $T_BIN/wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O kali.tar.xz
else
    echo "[✔] Архив kali.tar.xz уже на месте."
fi

# 7. ПРЯМАЯ РАСПАКОВКА (ОБХОД ОШИБКИ 'INVALID ARGUMENT')
echo "[*] НАЧИНАЮ РАСПАКОВКУ В ОБХОД PROOT..."
echo "[*] Это займет около 10 минут. Не выключай телефон!"

# Распаковываем напрямую через системный tar
$T_BIN/tar -xJf kali.tar.xz -C "$ROOTFS" --exclude='dev'

if [ $? -eq 0 ]; then
    echo "[✔] РАСПАКОВКА ЗАВЕРШЕНА!"
else
    echo "[!] ОШИБКА: Недостаточно места или архив поврежден."
    exit 1
fi

# 8. ФИКС СЕТИ И ПУСКОГОЙ ФАЙЛ
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
echo "[✔] УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "[*] Вход в Kali: bash ~/g_kali"
echo "---------------------------------------"
