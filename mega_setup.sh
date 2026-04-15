#!/system/bin/sh

# Полные пути к файлам
KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
CHROOT="$T_BIN/chroot"

echo "[*] Попытка прорыва через LD_PRELOAD..."

# 1. Срочное монтирование
mount -o bind /dev "$KALI_PATH/dev" 2>/dev/null
mount -o bind /proc "$KALI_PATH/proc" 2>/dev/null
mount -o bind /sys "$KALI_PATH/sys" 2>/dev/null

# 2. Исправление прав (на случай если su их заблокировал)
chmod 755 "$CHROOT"
chmod 755 "$T_LIB/libandroid-support.so"

# 3. ЗАПУСК С ПРИНУДИТЕЛЬНОЙ ПОДГРУЗКОЙ БИБЛИОТЕК
echo "[!] ВХОД В KALI..."

# Это одна длинная команда, которая говорит руту: "Сначала возьми эту библиотеку, а потом запускай"
LD_PRELOAD="$T_LIB/libandroid-support.so" \
LD_LIBRARY_PATH="$T_LIB" \
PATH="$T_BIN:/system/bin:/system/xbin" \
"$CHROOT" "$KALI_PATH" /usr/bin/env -i \
    HOME=/root \
    TERM=xterm-256color \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /bin/bash --login
