#!/data/data/com.termux/files/usr/bin/bash

T_HOME="/data/data/com.termux/files/home"
T_BIN="/data/data/com.termux/files/usr/bin"
T_LIB="/data/data/com.termux/files/usr/lib"
ROOTFS="$T_HOME/kali/rootfs"

# Временная папка для наших новых инструментов
MY_TOOLS="$T_HOME/tools"
mkdir -p "$MY_TOOLS"
mkdir -p "$ROOTFS"

echo "[*] ЗАГРУЗКА СТАТИЧЕСКИХ БИНАРНИКОВ (ARMHF)..."

# 1. Скачиваем рабочий tar и xz (используем curl, он у тебя живой)
# Ссылки на RAW файлы из указанного тобой репозитория
cd "$MY_TOOLS"
[ ! -f "tar" ] && curl -L -k "https://github.com/Inknyto/arm-binaries/raw/master/tar" -o "tar"
[ ! -f "xz" ] && curl -L -k "https://github.com/Inknyto/arm-binaries/raw/master/xz" -o "xz"

# Даем им права (здесь не должно быть bad mode, файлы в home)
chmod 755 tar xz

echo "[✔] Инструменты готовы."

# 2. Загрузка образа Kali (если его нет)
cd "$T_HOME"
if [ ! -s "kali.tar.xz" ]; then
    echo "[*] Загрузка Kali..."
    curl -L -k "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz" -o "kali.tar.xz"
fi

# 3. РАСПАКОВКА через новые инструменты
if [ ! -d "$ROOTFS/bin" ]; then
    echo "[*] НАЧАЛО РАСПАКОВКИ (через статический tar)..."
    
    # Добавляем нашу папку с инструментами в PATH в начало
    export PATH="$MY_TOOLS:$PATH"
    export LD_LIBRARY_PATH="$T_LIB"

    # Распаковываем
    "$MY_TOOLS/tar" -xJf "kali.tar.xz" -C "$ROOTFS" --exclude='dev'
    
    if [ $? -eq 0 ]; then
        echo "[✔] Успешно распаковано!"
    else
        echo "[!] Ошибка. Пробуем прямой конвейер..."
        cat "kali.tar.xz" | "$MY_TOOLS/xz" -d | "$MY_TOOLS/tar" -x -C "$ROOTFS"
    fi
fi

# 4. Создание скрипта запуска
cat > "$T_HOME/g_kali" << EOF
#!/data/data/com.termux/files/usr/bin/bash
export LD_LIBRARY_PATH=$T_LIB
unset LD_PRELOAD
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

chmod 755 "$T_HOME/g_kali"

echo "---------------------------------------"
echo "[✔] ГОТОВО! Инструменты из GitHub помогли."
echo "[*] Запуск: bash ~/g_kali"
