#!/data/data/com.termux/files/usr/bin/bash

echo "[*] ЭТАП 1: РЕАНИМАЦИЯ РЕПОЗИТОРИЕВ..."

# Чиним источники для Android 5.1
echo "deb https://packages.termux.org/termux-main-21 stable main" > $PREFIX/etc/apt/sources.list

# Обновляем базу и ставим инструменты (игнорируем SSL)
apt update -o "Acquire::https::Verify-Peer=false"
apt install python wget proot tar xz-utils -y -o "Acquire::https::Verify-Peer=false"

echo "[*] ЭТАП 2: ПОДГОТОВКА СРЕДЫ KALI..."

# ПУТЬ ВНУТРИ TERMUX
BASE="$HOME/kali"
ROOTFS="$BASE/rootfs"

mkdir -p "$ROOTFS"
cd "$BASE"

# Загрузка образа (если файла еще нет)
if [ ! -f kali.tar.xz ]; then
    echo "[*] Загрузка образа Kali armhf..."
    wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O kali.tar.xz
fi

# Распаковка
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] Распаковка... Это займет время, не выключай экран."
    proot --link2symlink tar -xJf kali.tar.xz -C "$ROOTFS" || { echo "[!] Ошибка!"; exit 1; }
fi

# Исправление DNS
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# Создание пускового файла
cat > "$HOME/kali_start.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash
unset LD_PRELOAD
exec proot \\
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

chmod 755 "$HOME/kali_start.sh"

echo "---------------------------------------"
echo "[✔] ВСЁ ГОТОВО!"
echo "[*] Запуск Kali командой: bash ~/kali_start.sh"
echo "---------------------------------------"
