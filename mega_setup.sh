#!/system/bin/sh

KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
BB_STATIC="/data/data/com.termux/files/home/busybox-static"

echo "[*] Контекст: Режим выживания (Static BusyBox)..."

# 1. Скачиваем статический BusyBox (если его еще нет или он пустой)
if [ ! -s "$BB_STATIC" ]; then
    echo "[*] Загрузка статического инструментария (Проверенная ссылка)..."
    # Используем проверенный источник скомпилированных бинарников
    /data/data/com.termux/files/home/wget --no-check-certificate "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox-armv7l" -O "$BB_STATIC"
    
    # Если ссылка выше тоже даст 404 (мало ли), вот запасная от meefik:
    if [ ! -s "$BB_STATIC" ]; then
         /data/data/com.termux/files/home/wget --no-check-certificate "https://github.com/meefik/busybox/releases/download/1.34.1/busybox-armhf" -O "$BB_STATIC"
    fi
    
    chmod 777 "$BB_STATIC"
fi

# 2. Проверка, что файл не пустой
if [ ! -s "$BB_STATIC" ]; then
    echo "[!] Ошибка: Не удалось скачать BusyBox. Проверь интернет."
    exit 1
fi

# 3. Монтирование через статический BB
echo "[*] Подготовка файловой системы..."
$BB_STATIC mount -o bind /dev "$KALI_PATH/dev" 2>/dev/null
$BB_STATIC mount -o bind /proc "$KALI_PATH/proc" 2>/dev/null
$BB_STATIC mount -o bind /sys "$KALI_PATH/sys" 2>/dev/null

# 4. ВХОД
echo "[!] ГАМБИТ СРАБОТАЛ. ВХОДИМ В KALI..."
$BB_STATIC chroot "$KALI_PATH" /bin/bash --login
