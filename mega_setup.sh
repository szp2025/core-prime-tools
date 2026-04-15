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

# 2. СОЗДАНИЕ/ОБНОВЛЕНИЕ start_kali.sh (Максимальная комплектация)
echo "[*] Обновление ярлыка: Интернет + Память + Цвета..."

cat <<EOF > "$START_KALI"
#!/system/bin/sh

G='\033[0;32m'
R='\033[0;31m'
Y='\033[1;33m'
NC='\033[0m'

echo "\${Y}[*] Запуск Kali Linux через SuperUser...\${NC}"

su -c "
    # 1. МОНТИРОВАНИЕ
    if ! \$BB_STATIC mount | grep -q '$KALI_PATH/proc'; then
        echo "\${Y}[*] Монтирование ресурсов...\${NC}"
        \$BB_STATIC mount -o bind /dev $KALI_PATH/dev
        \$BB_STATIC mount -o bind /proc $KALI_PATH/proc
        \$BB_STATIC mount -o bind /sys $KALI_PATH/sys
        \$BB_STATIC mount -o bind /dev/pts $KALI_PATH/dev/pts
        # Монтируем внутреннюю память (SDCard) внутрь Kali
        mkdir -p $KALI_PATH/mnt/sdcard
        \$BB_STATIC mount -o bind /sdcard $KALI_PATH/mnt/sdcard
    fi

    # 2. ФИКС ИНТЕРНЕТА (DNS)
    echo 'nameserver 8.8.8.8' > $KALI_PATH/etc/resolv.conf
    echo 'nameserver 8.8.4.4' >> $KALI_PATH/etc/resolv.conf
    
    # 3. ФИКС ГРУПП (Чтобы не было Permission Denied на сокетах)
    # Группа 3003 (inet) в Android отвечает за интернет
    grep -q 'inet:x:3003' $KALI_PATH/etc/group || echo 'inet:x:3003:root' >> $KALI_PATH/etc/group

    echo "\${G}[+] Окружение готово. Вход...\${NC}"
    
    # 4. ВХОД С ПРАВИЛЬНЫМИ ПЕРЕМЕННЫМИ
    \$BB_STATIC chroot $KALI_PATH /usr/bin/env -i \
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
