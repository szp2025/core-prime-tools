#!/data/data/com.termux/files/usr/bin/bash

# Путь в домашнюю директорию (самый надежный вариант)
BASE="$HOME/kali"
ROOTFS="$BASE/rootfs"

mkdir -p "$ROOTFS"
cd "$BASE"

echo "[*] Старт установки Kali NetHunter..."

# Установка системных инструментов
pkg install -y proot wget tar xz-utils

# Загрузка образа
if [ ! -f kali.tar.xz ]; then
    echo "[*] Загрузка образа (armhf)..."
    wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O kali.tar.xz
fi

# Распаковка (самый долгий этап)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] Распаковка... Наберись терпения."
    proot --link2symlink tar -xJf kali.tar.xz -C "$ROOTFS"
fi

# DNS
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# Создание скрипта запуска
cat > "$BASE/start.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash
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

chmod 755 "$BASE/start.sh"
echo "[✔] Готово! Запускай: bash $BASE/start.sh"
