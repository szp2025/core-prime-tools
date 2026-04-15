#!/system/bin/sh

# Пути
KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
TERMUX_BIN="/data/data/com.termux/files/usr/bin"

echo "[*] Инициализация окружения Kali Linux..."

# 1. Проверка и монтирование (только если еще не смонтировано)
# Используем проверку через grep, чтобы не плодить дубликаты монтирований
if ! mount | grep -q "$KALI_PATH/proc"; then
    echo "[*] Монтирование системных разделов..."
    su -c "mount -o bind /dev $KALI_PATH/dev && \
           mount -o bind /proc $KALI_PATH/proc && \
           mount -o bind /sys $KALI_PATH/sys"
    echo "[+] Разделы готовы."
else
    echo "[i] Разделы уже смонтированы."
fi

# 2. Поиск рабочего бинарника chroot
echo "[*] Поиск chroot..."
CHROOT_CMD=""
if [ -f "/system/bin/chroot" ]; then
    CHROOT_CMD="/system/bin/chroot"
elif [ -f "/system/xbin/chroot" ]; then
    CHROOT_CMD="/system/xbin/chroot"
elif [ -f "/system/xbin/busybox" ]; then
    CHROOT_CMD="/system/xbin/busybox chroot"
else
    CHROOT_CMD="chroot"
fi

echo "[+] Используем: $CHROOT_CMD"

# 3. ФИНАЛЬНЫЙ ЗАПУСК
# Мы передаем PATH внутрь su, чтобы chroot точно нашелся
echo "[!] ВХОД В KALI..."
su -c "export PATH=$TERMUX_BIN:/system/bin:/system/xbin; $CHROOT_CMD $KALI_PATH /bin/bash"
