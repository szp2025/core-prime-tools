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

# 2. СОЗДАНИЕ/ОБНОВЛЕНИЕ start_kali.sh (Цветная версия)
echo "[*] Обновление ярлыка с цветовой схемой..."

cat <<EOF > "$START_KALI"
#!/system/bin/sh

# Цветовые коды
G='\033[0;32m' # Green (Успех)
R='\033[0;31m' # Red (Ошибка)
Y='\033[1;33m' # Yellow (Процесс)
NC='\033[0m'    # No Color (Сброс)

echo "\${Y}[*] Запуск Kali Linux через SuperUser...\${NC}"

# Запуск через su
su -c "
    # Проверка монтирования
    if ! \$BB_STATIC mount | grep -q '$KALI_PATH/proc'; then
        echo "\${Y}[*] Монтирование ресурсов...\${NC}"
        \$BB_STATIC mount -o bind /dev $KALI_PATH/dev
        \$BB_STATIC mount -o bind /proc $KALI_PATH/proc
        \$BB_STATIC mount -o bind /sys $KALI_PATH/sys
    fi

    echo "\${G}[+] Окружение готово. Вход в chroot...\${NC}"
    
    # Попытка входа
    if ! \$BB_STATIC chroot $KALI_PATH /bin/bash --login; then
        echo "\${R}[!] КРИТИЧЕСКАЯ ОШИБКА: chroot не смог запустить оболочку.\${NC}"
        echo "\${Y}[?] Проверь: whoami должен быть root внутри su.\${NC}"
    fi
"
EOF

# Права и владелец
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
