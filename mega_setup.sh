#!/system/bin/sh

# Полные пути
HOME_DIR="/data/data/com.termux/files/home"
KALI_PATH="$HOME_DIR/kali-system/kali-armhf"
BB_STATIC="$HOME_DIR/busybox-static"
START_KALI="$HOME_DIR/start_kali.sh"

echo "[*] Контекст: Режим автоматизации..."

# 1. Проверка и загрузка BusyBox (если нужно)
if [ ! -s "$BB_STATIC" ]; then
    echo "[*] Загрузка BusyBox..."
    /data/data/com.termux/files/home/wget --no-check-certificate "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox-armv7l" -O "$BB_STATIC"
    chmod 777 "$BB_STATIC"
fi

# 2. СОЗДАНИЕ/ОБНОВЛЕНИЕ start_kali.sh
echo "[*] Обновление ярлыка: Убираем printf и исправляем пути..."

cat <<'EOF' > "$START_KALI"
#!/system/bin/sh

# Жесткие пути (БЕЗ ПЕРЕМЕННЫХ, ЧТОБЫ НЕ ТЕРЯЛИСЬ)
KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
BB="/data/data/com.termux/files/home/busybox-static"

echo "[*] Подготовка окружения..."

# Запуск одной командой
su -c "
    # Проверка монтирования через BusyBox
    $BB mount | grep -q '$KALI_PATH/proc' || (
        $BB mount -o bind /dev $KALI_PATH/dev
        $BB mount -o bind /proc $KALI_PATH/proc
        $BB mount -o bind /sys $KALI_PATH/sys
        $BB mount -o bind /dev/pts $KALI_PATH/dev/pts
    )
    
    # Фикс интернета
    echo 'nameserver 8.8.8.8' > $KALI_PATH/etc/resolv.conf
    
    echo '[+] Вход в Kali Linux...'
    
    # Запуск chroot через абсолютный путь к BusyBox
    $BB chroot $KALI_PATH /usr/bin/env -i \
        HOME=/root \
        TERM=xterm-256color \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        /bin/bash --login
"
EOF

# Исправляем права и владельца
chmod 777 "$START_KALI"
chown $(ls -ld $HOME_DIR | awk '{print $3}') "$START_KALI"

echo "[+] Ярлык готов: теперь можно запускать командой ./start_kali.sh"

# 3. МОНТИРОВАНИЕ (текущая сессия)
$BB_STATIC mount -o bind /dev "$KALI_PATH/dev" 2>/dev/null
$BB_STATIC mount -o bind /proc "$KALI_PATH/proc" 2>/dev/null
$BB_STATIC mount -o bind /sys "$KALI_PATH/sys" 2>/dev/null

# 4. ВХОД
echo "[!] ВХОД В KALI..."
$BB_STATIC chroot "$KALI_PATH" /bin/bash --login
