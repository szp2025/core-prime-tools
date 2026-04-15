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

# 3. ФИНАЛЬНЫЙ ВХОД (Версия с фиксом библиотек)
echo "[!] ВХОД В KALI LINUX..."

# Прописываем пути к бинарникам И библиотекам Termux
export PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin"
export LD_LIBRARY_PATH="/data/data/com.termux/files/usr/lib"

# Находим chroot (системный или термуксовский)
CHROOT_EXE=$(command -v chroot || echo "/data/data/com.termux/files/usr/bin/chroot")

# Запуск с полной очисткой окружения внутри
$CHROOT_EXE "$KALI_PATH" /usr/bin/env -i \
    HOME=/root \
    TERM=xterm-256color \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /bin/bash --login
