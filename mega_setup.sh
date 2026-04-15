#!/system/bin/sh

# Полные пути
HOME_DIR="/data/data/com.termux/files/home"
KALI_PATH="$HOME_DIR/kali-system/kali-armhf"
BB_STATIC="$HOME_DIR/busybox-static"
START_KALI="$HOME_DIR/start_kali.sh"

echo "[*] Контекст: Глобальная оптимизация и проверка монтирования..."

# 1. МОДУЛЬ ЧИСТОТЫ (Удаляем всё лишнее)
echo "[*] Уборка мусора..."
rm -rf "$HOME_DIR/kali-armhf" "$HOME_DIR/bin" "$HOME_DIR/downloads"
rm -rf "$HOME_DIR/g_kali" "$HOME_DIR/tools" "$HOME_DIR/bind" "$HOME_DIR/-o"
rm -f "$HOME_DIR"/*.tar.xz "$HOME_DIR"/*.tar.gz "$HOME_DIR"/nmap "$HOME_DIR"/strace

# 2. Проверка BusyBox
if [ ! -s "$BB_STATIC" ]; then
    echo "[*] Загрузка BusyBox..."
    "$HOME_DIR/wget" --no-check-certificate "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox-armv7l" -O "$BB_STATIC"
    chmod 777 "$BB_STATIC"
fi

# 3. СОЗДАНИЕ УМНОГО start_kali.sh
cat <<EOF > start_kali.sh
#!/system/bin/sh
K_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
BB="/data/data/com.termux/files/home/busybox-static"

# Монтирование системных ресурсов
su -c "
    \$BB mount -o bind /dev \$K_PATH/dev
    \$BB mount -o bind /proc \$K_PATH/proc
    \$BB mount -o bind /sys \$K_PATH/sys
    \$BB mount -t devpts devpts \$K_PATH/dev/pts
"

echo "[+] ВХОД В KALI..."
# Используем прямой проброс интерактивной оболочки
su -c "\$BB chroot \$K_PATH /bin/bash -i"
EOF

chmod 777 start_kali.sh
