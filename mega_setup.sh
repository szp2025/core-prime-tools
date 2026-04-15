#!/system/bin/sh

KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
TERMUX_BIN="/data/data/com.termux/files/usr/bin"

echo "[*] Внутри mega_setup.sh: Настройка Kali..."

# 1. Монтирование
if ! mount | grep -q "$KALI_PATH/proc"; then
    mount -o bind /dev $KALI_PATH/dev
    mount -o bind /proc $KALI_PATH/proc
    mount -o bind /sys $KALI_PATH/sys
    echo "[+] Системные разделы смонтированы."
fi

# 2. Поиск chroot
CHROOT_CMD=""
[ -f "/system/bin/chroot" ] && CHROOT_CMD="/system/bin/chroot"
[ -z "$CHROOT_CMD" ] && [ -f "/system/xbin/chroot" ] && CHROOT_CMD="/system/xbin/chroot"
[ -z "$CHROOT_CMD" ] && [ -f "/system/xbin/busybox" ] && CHROOT_CMD="/system/xbin/busybox chroot"

# 3. Вход (Исправленная версия)
echo "[!] ВХОД В СИСТЕМУ KALI..."
export PATH=$TERMUX_BIN:/system/bin:/system/xbin

# Важно: сначала идет команда chroot, потом ПУТЬ к системе, потом ПРОГРАММА (/bin/bash)
$CHROOT_CMD $KALI_PATH /usr/bin/env -i HOME=/root TERM=xterm-256color /bin/bash --login
