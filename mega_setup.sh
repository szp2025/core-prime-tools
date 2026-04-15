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
echo "[*] Создание локального ярлыка..."

# Определяем владельца (обычно это имя папки в /data/data/com.termux)
TERMUX_USER=$(ls -ld $HOME_DIR | awk '{print $3}')

cat <<EOF > "$START_KALI"
#!/system/bin/sh
# Переходим в корень Termux
cd $HOME_DIR
echo "[*] Запуск Kali Linux через SuperUser..."
# Используем полный путь к BusyBox
su -c "$BB_STATIC mount -o bind /dev $KALI_PATH/dev 2>/dev/null; \
       $BB_STATIC mount -o bind /proc $KALI_PATH/proc 2>/dev/null; \
       $BB_STATIC mount -o bind /sys $KALI_PATH/sys 2>/dev/null; \
       $BB_STATIC chroot $KALI_PATH /bin/bash --login"
EOF

# УСТАНОВКА ПРАВ
# 1. Даем полные права на исполнение
chmod 777 "$START_KALI"
# 2. Передаем владение пользователю Termux, чтобы он мог "открыть" файл
chown $TERMUX_USER:$TERMUX_USER "$START_KALI"

echo "[+] Ярлык готов. Владелец: $TERMUX_USER"

echo "[+] Ярлык готов: теперь можно запускать командой ./start_kali.sh"

# 3. МОНТИРОВАНИЕ (текущая сессия)
$BB_STATIC mount -o bind /dev "$KALI_PATH/dev" 2>/dev/null
$BB_STATIC mount -o bind /proc "$KALI_PATH/proc" 2>/dev/null
$BB_STATIC mount -o bind /sys "$KALI_PATH/sys" 2>/dev/null

# 4. ВХОД
echo "[!] ВХОД В KALI..."
$BB_STATIC chroot "$KALI_PATH" /bin/bash --login
