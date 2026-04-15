#!/system/bin/sh

# Полные пути
HOME_DIR="/data/data/com.termux/files/home"
KALI_PATH="$HOME_DIR/kali-system/kali-armhf"
BB_STATIC="$HOME_DIR/busybox-static"
START_KALI="$HOME_DIR/start_kali.sh"

echo "[*] Контекст: Режим автоматизации..."

# 1. Проверка и загрузка BusyBox
if [ ! -s "$BB_STATIC" ]; then
    echo "[*] Загрузка BusyBox..."
    /data/data/com.termux/files/home/wget --no-check-certificate "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox-armv7l" -O "$BB_STATIC"
    chmod 777 "$BB_STATIC"
fi

# 2. СОЗДАНИЕ/ОБНОВЛЕНИЕ start_kali.sh
echo "[*] Фикс прав: Принудительный ROOT вход..."

cat <<EOF > "$START_KALI"
#!/system/bin/sh
KALI_PATH="$KALI_PATH"
BB="$BB_STATIC"

echo "[*] Запрос SuperUser..."

su -c "
    if [ ! -e \$KALI_PATH/proc/1 ]; then
        echo '[*] Ресурсы не найдены. Авто-монтирование...'
        \$BB mount -o bind /dev \$KALI_PATH/dev
        \$BB mount -o bind /proc \$KALI_PATH/proc
        \$BB mount -o bind /sys \$KALI_PATH/sys
        \$BB mount -t devpts devpts \$KALI_PATH/dev/pts
        echo '[+] Монтирование завершено.'
    else
        echo '[i] Ресурсы уже в норме.'
    fi
    
    echo 'nameserver 8.8.8.8' > \$KALI_PATH/etc/resolv.conf
    echo '[+] Вход в Kali (Force Root)...'
    
    \$BB chroot \$KALI_PATH /usr/bin/env -i \\
        HOME=/root \\
        TERM=xterm-256color \\
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
        /bin/bash --login
"
EOF

chmod 777 "$START_KALI"
# Возвращаем владение текущему пользователю Termux для удобства
chown $(stat -c %u $HOME_DIR) "$START_KALI"

echo "[+] Ярлык готов: ./start_kali.sh"

# 3. МОНТИРОВАНИЕ (для текущей сессии запуска)
if [ ! -e "$KALI_PATH/proc/1" ]; then
    $BB_STATIC mount -o bind /dev "$KALI_PATH/dev"
    $BB_STATIC mount -o bind /proc "$KALI_PATH/proc"
    $BB_STATIC mount -o bind /sys "$KALI_PATH/sys"
fi

# 4. ВХОД
echo "[!] ВХОД В KALI..."
$BB_STATIC chroot "$KALI_PATH" /bin/bash --login
