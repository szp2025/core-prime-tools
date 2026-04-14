#!/data/data/com.termux/files/usr/bin/bash

# Пути
T_HOME="/data/data/com.termux/files/home"
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
ROOTFS="$T_HOME/kali/rootfs"
MY_TOOLS="$T_HOME/tools"

mkdir -p "$MY_TOOLS"
mkdir -p "$ROOTFS"

echo "[*] ЗАГРУЗКА АВТОНОМНОГО КОМПЛЕКТА (XZ + TAR + BASH)..."

# 1. Скачиваем статические бинарники (игнорируем системный мусор)
cd "$MY_TOOLS"
[ ! -f "bash" ] && curl -L -k "https://github.com/Inknyto/arm-binaries/raw/main/bash/system/xbin/bash" -o "bash"
[ ! -f "tar" ] && curl -L -k "https://github.com/Inknyto/arm-binaries/raw/master/tar" -o "tar"
[ ! -f "xz" ] && curl -L -k "https://github.com/Inknyto/arm-binaries/raw/master/xz" -o "xz"

# Выставляем права (в /home/tools это пройдет без ошибок)
chmod 755 bash tar xz

echo "[✔] Инструменты готовы к работе."

# 2. Загрузка Kali (если еще не скачана)
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка Kali Minimal ARMHF..."
    curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
fi

# 3. РАСПАКОВКА (Силовой метод через статический XZ)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] НАЧАЛО РАСПАКОВКИ..."
    
    # Мы принудительно заставляем tar использовать наш скачанный xz
    # Флаг --use-compress-program указывает прямой путь к декомпрессору
    "$MY_TOOLS/tar" --use-compress-program="$MY_TOOLS/xz" -xvf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
    
    if [ $? -eq 0 ]; then
        echo "[✔] Успешно распаковано!"
    else
        echo "[!] Прямой метод не пошел, пробуем конвейер..."
        cat "kali.tar.xz" | "$MY_TOOLS/xz" -d | "$MY_TOOLS/tar" -x -C "$ROOTFS"
    fi
fi

# 4. Создание скрипта входа g_kali
cat > "$T_HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
export LD_LIBRARY_PATH=$T_LIB
unset LD_PRELOAD
# Входим в Kali, используя наш статический bash для надежности
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
$MY_TOOLS/bash --login
EOF

chmod 755 "$T_HOME/g_kali"

echo "---------------------------------------"
echo "[✔] ВСЁ ГОТОВО! Мы обошли системные ограничения."
echo "[*] Запускай: bash ~/g_kali"
echo "---------------------------------------"
