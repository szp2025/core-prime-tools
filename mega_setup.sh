#!/data/data/com.termux/files/usr/bin/bash

# Пути
T_HOME="/data/data/com.termux/files/home"
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
ROOTFS="$T_HOME/kali/rootfs"
MY_TOOLS="$T_HOME/tools"

mkdir -p "$MY_TOOLS"
mkdir -p "$ROOTFS"

echo "[*] ЗАГРУЗКА СУПЕР-БИНАРНИКОВ (BASH, TAR, XZ)..."

# 1. Скачиваем инструменты (curl — единственный, кому мы верим)
cd "$MY_TOOLS"
# Ссылки на статический Bash и инструменты распаковки
[ ! -f "bash" ] && curl -L -k "https://github.com/Inknyto/arm-binaries/raw/main/bash/system/xbin/bash" -o "bash"
[ ! -f "tar" ] && curl -L -k "https://github.com/Inknyto/arm-binaries/raw/master/tar" -o "tar"
[ ! -f "xz" ] && curl -L -k "https://github.com/Inknyto/arm-binaries/raw/master/xz" -o "xz"

# Выставляем права (в домашней папке chmod 755 работает без ошибок)
chmod 755 bash tar xz

echo "[✔] Инструменты подготовлены."

# 2. Загрузка Kali
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка Kali Minimal ARMHF..."
    curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
fi

# 3. РАСПАКОВКА (Используем только наши новые инструменты)
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] НАЧАЛО РАСПАКОВКИ..."
    export PATH="$MY_TOOLS:$PATH"
    
    # Прямой запуск через наш статический tar
    "$MY_TOOLS/tar" -xJf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
    
    if [ $? -eq 0 ]; then
        echo "[✔] Успешно распаковано!"
    else
        echo "[!] Ошибка. Пробуем конвейер через статический xz..."
        cat "kali.tar.xz" | "$MY_TOOLS/xz" -d | "$MY_TOOLS/tar" -x -C "$ROOTFS"
    fi
fi

# 4. Создание скрипта входа g_kali (используем наш статический bash)
cat > "$T_HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
export LD_LIBRARY_PATH=$T_LIB
unset LD_PRELOAD
# Запускаем через proot, используя наш надежный bash
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
echo "[✔] ПОЛНЫЙ ПРОРЫВ ЗАВЕРШЕН!"
echo "[*] Запускай Kali командой: bash ~/g_kali"
echo "---------------------------------------"
