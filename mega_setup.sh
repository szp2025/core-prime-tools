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
    "$HOME_DIR/wget" --no-check-certificate "https://github.com/zoobab/busybox-static-for-android/raw/master/busybox" -O "$BB_STATIC"
    chmod 777 "$BB_STATIC"
fi

cat <<EOF > start_kali.sh
#!/system/bin/sh
# Параметры путей
HOME_PATH="/data/data/com.termux/files/home"
K_PATH="\$HOME_PATH/kali-system/kali-armhf"
BB_ORIGIN="\$HOME_PATH/busybox-static"
BB_DEV="/dev/busybox-kali"

echo "[*] Инициализация окружения..."

# 1. Восстановление BusyBox в /dev (после перезагрузки он пропадает)
su -c "cp \$BB_ORIGIN \$BB_DEV && chmod 755 \$BB_DEV"

# 2. Снятие защиты noexec с раздела /data (чтобы Kali могла запускаться)
su -c "mount -o remount,exec /data"

# 3. Монтирование ресурсов (с проверкой, чтобы не дублировать)
su -c "
    if ! grep -q '\$K_PATH/proc' /proc/mounts; then
        \$BB_DEV mount -o bind /dev \$K_PATH/dev
        \$BB_DEV mount -o bind /proc \$K_PATH/proc
        \$BB_DEV mount -o bind /sys \$K_PATH/sys
        \$BB_DEV mount -t devpts devpts \$K_PATH/dev/pts
    fi
    # Настройка интернета внутри Kali
    echo 'nameserver 8.8.8.8' > \$K_PATH/etc/resolv.conf
"

echo "[+] ПОПЫТКА ВХОДА В KALI (SH MODE)..."
# Мы используем /bin/sh -i, так как это самый стабильный режим для Android 5.1
su -c "\$BB_DEV chroot \$K_PATH /bin/sh -i"

# 4. Авто-размонтирование после выхода из Kali (для чистоты)
echo "[*] Размонтирование ресурсов..."
su -c "umount -l \$K_PATH/dev/pts; umount -l \$K_PATH/dev; umount -l \$K_PATH/proc; umount -l \$K_PATH/sys"
EOF

chmod +x start_kali.sh
