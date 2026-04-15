#!/system/bin/sh

# Полные пути
KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
BB_STATIC="/data/data/com.termux/files/home/busybox-static"
WGET="/data/data/com.termux/files/home/wget"

echo "[*] Контекст: Проверка окружения..."

# 1. Проверяем, существует ли уже статический BusyBox
if [ -s "$BB_STATIC" ]; then
    echo "[+] BusyBox найден локально. Пропускаем загрузку."
else
    echo "[*] BusyBox не найден или пуст. Начинаем загрузку..."
    # Пробуем основную ссылку
    $WGET --no-check-certificate "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox-armv7l" -O "$BB_STATIC"
    
    # Если не скачалось (файл остался пустым), пробуем запасную
    if [ ! -s "$BB_STATIC" ]; then
        echo "[!] Основной сервер недоступен, пробую зеркало..."
        $WGET --no-check-certificate "https://github.com/meefik/busybox/releases/download/1.34.1/busybox-armhf" -O "$BB_STATIC"
    fi
    
    chmod 777 "$BB_STATIC"
fi

# 2. Финальная проверка перед монтированием
if [ ! -s "$BB_STATIC" ]; then
    echo "[!] КРИТИЧЕСКАЯ ОШИБКА: Не удалось получить BusyBox."
    exit 1
fi

# 3. Монтирование (тихо, без лишнего вывода)
echo "[*] Настройка монтирования..."
$BB_STATIC mount -o bind /dev "$KALI_PATH/dev" 2>/dev/null
$BB_STATIC mount -o bind /proc "$KALI_PATH/proc" 2>/dev/null
$BB_STATIC mount -o bind /sys "$KALI_PATH/sys" 2>/dev/null

# 4. ВХОД В KALI
echo "[!] ВХОД В СИСТЕМУ KALI..."
$BB_STATIC chroot "$KALI_PATH" /bin/bash --login
