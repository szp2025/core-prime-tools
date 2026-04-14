#!/data/data/com.termux/files/usr/bin/bash

# ПУТЬ ВНУТРИ TERMUX (Здесь всегда есть права на запись)
BASE="$HOME/kali"
ROOTFS="$BASE/rootfs"

mkdir -p "$ROOTFS"
cd "$BASE"

echo "[*] СТАРТ УСТАНОВКИ KALI (FIXED PATHS)"

# Установка инструментов прямо здесь
pkg update && pkg install -y proot wget tar xz-utils

# Загрузка (если файла еще нет)
if [ ! -f kali.tar.xz ]; then
    echo "[*] Загрузка образа..."
    wget --no-check-certificate "https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" -O kali.tar.xz
fi

# Распаковка (самое важное)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] Распаковка... Жди, телефон может греться."
    proot --link2symlink tar -xJf kali.tar.xz -C "$ROOTFS"
fi

# Исправление DNS
mkdir -p "$ROOTFS/etc"
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# Создание пускового файла
cat > "$BASE/start.sh" << EOF
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

chmod 755 "$BASE/start.sh"
echo "---------------------------------------"
echo "[✔] ГОТОВО! Теперь вводи:"
echo "bash $BASE/start.sh"
