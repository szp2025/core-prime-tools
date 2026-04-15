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

# 3. СОЗДАНИЕ УМНОГО start_kali.sh С ПРОВЕРКОЙ MOUNT
echo "[*] Обновление ярлыка запуска..."

cat <<EOF > "$START_KALI"
#!/system/bin/sh
K_PATH="$KALI_PATH"
BB="$BB_STATIC"

# Основная логика под SU
su -c "
    # ПРОВЕРКА: Смонтирован ли proc? (Признак живого монтирования)
    if ! grep -q '\$K_PATH/proc' /proc/mounts; then
        echo '[!] Ресурсы не смонтированы. Запуск mount...'
        \$BB mount -o bind /dev \$K_PATH/dev
        \$BB mount -o bind /proc \$K_PATH/proc
        \$BB mount -o bind /sys \$K_PATH/sys
        \$BB mount -t devpts devpts \$K_PATH/dev/pts
        echo '[+] Монтирование успешно.'
    else
        echo '[i] Ресурсы уже активны.'
    fi
    
    # Фикс интернета
    echo 'nameserver 8.8.8.8' > \$K_PATH/etc/resolv.conf
    
    echo '[+] ВХОД В KALI (Official Root)...'
    # Вход через внутренний su для получения '#'
    \$BB chroot \$K_PATH /bin/su - root
"
EOF

chmod 777 "$START_KALI"

# 4. ПЕРВЫЙ ВХОД
echo "[!] ВСЁ ГОТОВО. ЗАПУСКАЕМ..."
sh "$START_KALI"
