#!/system/bin/sh

# Полные пути
KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
TERMUX_BIN="/data/data/com.termux/files/usr/bin"
TERMUX_LIB="/data/data/com.termux/files/usr/lib"

echo "[*] Контекст: Запуск Kali через Termux-chroot..."

# 1. Монтирование (тихое, без лишних сообщений)
mount -o bind /dev "$KALI_PATH/dev" 2>/dev/null
mount -o bind /proc "$KALI_PATH/proc" 2>/dev/null
mount -o bind /sys "$KALI_PATH/sys" 2>/dev/null

# 2. Проверка наличия chroot в Termux
if [ ! -f "$TERMUX_BIN/chroot" ]; then
    echo "[!] Ошибка: chroot не найден даже в Termux ($TERMUX_BIN/chroot)"
    exit 1
fi

# 3. ФИНАЛЬНЫЙ ВХОД С ПРЯМЫМ УКАЗАНИЕМ БИБЛИОТЕК
echo "[!] ПРОРЫВ В KALI..."

# Мы используем LD_PRELOAD или LD_LIBRARY_PATH, чтобы chroot увидел свои зависимости
export LD_LIBRARY_PATH="$TERMUX_LIB"
export PATH="$TERMUX_BIN:/system/bin:/system/xbin"

# Запуск: КОМАНДА + ПУТЬ + ОБОЛОЧКА
"$TERMUX_BIN/chroot" "$KALI_PATH" /usr/bin/env -i \
    HOME=/root \
    TERM=xterm-256color \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /bin/bash --login
