#!/system/bin/sh

# Пути (используем полные пути для надежности)
KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
TERMUX_BIN="/data/data/com.termux/files/usr/bin"

echo "[*] Контекст: /data/local/tmp/mega_setup.sh запущен."

# 1. Проверка и монтирование
if ! mount | grep -q "$KALI_PATH/proc"; then
    echo "[*] Монтирование системных ресурсов..."
    mount -o bind /dev "$KALI_PATH/dev"
    mount -o bind /proc "$KALI_PATH/proc"
    mount -o bind /sys "$KALI_PATH/sys"
fi

# 2. Поиск рабочего chroot в системе Android
CHROOT_CMD=""
[ -f "/system/bin/chroot" ] && CHROOT_CMD="/system/bin/chroot"
[ -z "$CHROOT_CMD" ] && [ -f "/system/xbin/chroot" ] && CHROOT_CMD="/system/xbin/chroot"
[ -z "$CHROOT_CMD" ] && [ -f "/system/xbin/busybox" ] && CHROOT_CMD="/system/xbin/busybox chroot"

if [ -z "$CHROOT_CMD" ]; then
    echo "[!] Ошибка: chroot не найден в /system. Пробую прямой вызов..."
    CHROOT_CMD="chroot"
fi

# 3. ФИНАЛЬНЫЙ ВХОД
echo "[!] ВХОД В KALI LINUX..."

# Устанавливаем PATH, чтобы chroot нашел свои библиотеки
export PATH="$TERMUX_BIN:/system/bin:/system/xbin"

# ВАЖНО: Мы запускаем оболочку /bin/bash, которая находится ВНУТРИ $KALI_PATH
$CHROOT_CMD "$KALI_PATH" /usr/bin/env -i HOME=/root TERM=xterm-256color /bin/bash --login
