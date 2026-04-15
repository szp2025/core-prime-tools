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
echo "[*] Обновление ярлыка: Фикс ошибок chroot и цветов..."

cat <<'EOF' > "$START_KALI"
#!/system/bin/sh

# Цвета (используем printf для надежности)
G='\033[0;32m'
Y='\033[1;33m'
R='\033[0;31m'
NC='\033[0m'

# Жесткие пути, чтобы su их не потерял
KALI="/data/data/com.termux/files/home/kali-system/kali-armhf"
BB="/data/data/com.termux/files/home/busybox-static"

printf "${Y}[*] Запуск Kali Linux через SuperUser...${NC}\n"

# Запуск одной строкой без переменных, которые могут потеряться
su -c "
    if [ ! -d $KALI/proc/1 ]; then
        $BB mount -o bind /dev $KALI/dev
        $BB mount -o bind /proc $KALI/proc
        $BB mount -o bind /sys $KALI/sys
        $BB mount -o bind /dev/pts $KALI/dev/pts
    fi
    
    # Фикс DNS
    echo 'nameserver 8.8.8.8' > $KALI/etc/resolv.conf
    
    printf '${G}[+] Вход в систему...${NC}\n'
    
    # Прямой вызов chroot через полный путь к BusyBox
    $BB chroot $KALI /usr/bin/env -i \
        HOME=/root \
        TERM=xterm-256color \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        /bin/bash --login
"
EOF

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
