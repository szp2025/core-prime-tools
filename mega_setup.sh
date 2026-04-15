#!/system/bin/sh

# Полные пути - ПРОВЕРЬ ИХ ЕЩЕ РАЗ
KALI_PATH="/data/data/com.termux/files/home/kali-system/kali-armhf"
BB_STATIC="/data/data/com.termux/files/home/busybox-static"
WGET="/data/data/com.termux/files/home/wget"

echo "[*] Проверка наличия BusyBox по пути: $BB_STATIC"

# Посмотрим, что там на самом деле лежит
ls -l "$BB_STATIC" 2>/dev/null

# 1. Проверяем: если файл существует И его размер больше 100 Кб (защита от пустых файлов)
if [ -f "$BB_STATIC" ] && [ $(ls -l "$BB_STATIC" | awk '{print $4}') -gt 100000 ]; then
    echo "[+] BusyBox найден и весит достаточно. Пропускаем загрузку."
else
    echo "[!] BusyBox не найден, пуст или битый. Качаем..."
    
    # Удаляем старый мусор, если он есть
    rm -f "$BB_STATIC"
    
    # Качаем (пробуем сначала официальную ссылку)
    $WGET --no-check-certificate "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox-armv7l" -O "$BB_STATIC"
    
    # Если все еще 0 байт, пробуем запасную
    if [ ! -s "$BB_STATIC" ]; then
        echo "[!] Пробую запасное зеркало..."
        $WGET --no-check-certificate "https://github.com/meefik/busybox/releases/download/1.34.1/busybox-armhf" -O "$BB_STATIC"
    fi
    
    chmod 777 "$BB_STATIC"
fi

# 2. Финальная проверка
if [ ! -s "$BB_STATIC" ]; then
    echo "[!] Ошибка: Скачать не удалось. Проверь Wi-Fi."
    exit 1
fi

# 3. Монтирование
echo "[*] Настройка монтирования..."
$BB_STATIC mount -o bind /dev "$KALI_PATH/dev" 2>/dev/null
$BB_STATIC mount -o bind /proc "$KALI_PATH/proc" 2>/dev/null
$BB_STATIC mount -o bind /sys "$KALI_PATH/sys" 2>/dev/null

# 4. ВХОД
echo "[!] ВХОД В KALI..."
$BB_STATIC chroot "$KALI_PATH" /bin/bash --login
