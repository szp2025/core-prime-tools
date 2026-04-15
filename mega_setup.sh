#!/system/bin/sh

KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
BB_STATIC="/data/data/com.termux/files/home/busybox-static"

echo "[*] Контекст: Режим выживания (Static BusyBox)..."

# 1. Скачиваем статический BusyBox (если его еще нет)
if [ ! -f "$BB_STATIC" ]; then
    echo "[*] Загрузка статического инструментария..."
    /data/data/com.termux/files/home/wget --no-check-certificate https://github.com/busybox-static/busybox-static/raw/master/busybox-armv7l -O "$BB_STATIC"
    chmod 777 "$BB_STATIC"
fi

# 2. Монтирование через статический BB
echo "[*] Подготовка файловой системы..."
$BB_STATIC mount -o bind /dev "$KALI_PATH/dev" 2>/dev/null
$BB_STATIC mount -o bind /proc "$KALI_PATH/proc" 2>/dev/null
$BB_STATIC mount -o bind /sys "$KALI_PATH/sys" 2>/dev/null

# 3. ВХОД (Без внешних зависимостей)
echo "[!] ГАМБИТ СРАБОТАЛ. ВХОДИМ..."

# Используем chroot именно из статического busybox
$BB_STATIC chroot "$KALI_PATH" /bin/bash --login
