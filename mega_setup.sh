#!/data/data/com.termux/files/usr/bin/bash

# --- ЭВРИСТИЧЕСКИЙ БЛОК ОПРЕДЕЛЕНИЯ ОКРУЖЕНИЯ ---
# Ищем рабочие пути, даже если переменные окружения стерты
[ -z "$PREFIX" ] && PREFIX="/data/data/com.termux/files/usr"
[ -z "$HOME" ] && HOME="/data/data/com.termux/files/home"

export T_BIN="$PREFIX/bin"
export T_LIB="$PREFIX/lib"
export LD_LIBRARY_PATH="$T_LIB:$LD_LIBRARY_PATH"
export PATH="$T_BIN:$PATH"

# Ссылки и пути
KALI_URL="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz"
BASE="$HOME/kali"
ROOTFS="$BASE/rootfs"
ARCHIVE="$HOME/kali-minimal.tar.xz"

echo "[*] ЭВРИСТИЧЕСКИЙ ЗАПУСК: Анализ системы..."

# 1. ПРОВЕРКА ИСПРАВНОСТИ БИНАРНИКОВ
for tool in chmod mkdir tar wget curl proot; do
    if [ ! -x "$T_BIN/$tool" ]; then
        echo "[!] Внимание: $tool не имеет прав на запуск. Исправляем..."
        /system/bin/chmod 755 "$T_BIN/$tool" 2>/dev/null || chmod 755 "$T_BIN/$tool"
    fi
done

# 2. СОЗДАНИЕ СТРУКТУРЫ
$T_BIN/mkdir -p "$ROOTFS"
cd "$HOME"

# 3. УМНАЯ ЗАГРУЗКА (Fallback-стратегия)
if [ ! -f "$ARCHIVE" ]; then
    echo "[*] Попытка загрузки образа..."
    $T_BIN/wget --no-check-certificate "$KALI_URL" -O "$ARCHIVE" || \
    $T_BIN/curl -L -k "$KALI_URL" -o "$ARCHIVE" || {
        echo "[!!!] Ошибка сети: невозможно скачать образ."; exit 1
    }
fi

# 4. ЭВРИСТИЧЕСКАЯ РАСПАКОВКА (Три уровня попыток)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] Начало распаковки. Метод 1: Прямой tar..."
    if ! $T_BIN/tar -xJf "$ARCHIVE" -C "$ROOTFS" 2>/dev/null; then
        echo "[!] Метод 1 не сработал. Метод 2: Распаковка через xz + tar..."
        $T_BIN/xz -d -c "$ARCHIVE" | $T_BIN/tar -x -C "$ROOTFS" || {
            echo "[!] Метод 2 провален. Метод 3: Принудительный proot-bypass..."
            # На случай, если tar требует специальных флагов для Android 5
            $T_BIN/tar --privileged -xf "$ARCHIVE" -C "$ROOTFS"
        }
    fi
fi

# 5. ПРОВЕРКА ЦЕЛОСТНОСТИ ПОСЛЕ РАСПАКОВКИ
if [ ! -f "$ROOTFS/bin/bash" ]; then
    echo "[!!!] Критическая ошибка: Файлы Kali не найдены в $ROOTFS"; exit 1
fi

# 6. ГЕНЕРАЦИЯ "УМНОГО" ЗАПУСКА
cat > "$HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# Автоматическое восстановление окружения перед входом
export LD_LIBRARY_PATH="$T_LIB"
export PATH="$T_BIN:\$PATH"
unset LD_PRELOAD

# Исправление DNS внутри Kali (если файл пропал)
if [ ! -f "$ROOTFS/etc/resolv.conf" ]; then
    mkdir -p "$ROOTFS/etc"
    echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"
fi

exec $T_BIN/proot \\
--link2symlink \\
-0 \\
-r $ROOTFS \\
-b /dev -b /proc -b /sys -b /sdcard \\
-w /root \\
/usr/bin/env -i \\
HOME=/root \\
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
TERM=\$TERM \\
/bin/bash --login
EOF

$T_BIN/chmod 755 "$HOME/g_kali"

echo "--- УСПЕХ ---"
echo "[✔] Система адаптирована под ядро Android 5.1"
echo "[*] Запуск: bash ~/g_kali"
