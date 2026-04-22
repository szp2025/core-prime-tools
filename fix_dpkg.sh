#!/bin/bash

# ==========================================
# AUTO FIX & HEAL DPKG (Termux / NetHunter)
# ==========================================

DPKG_DIR="/var/lib/dpkg"
APT_CACHE="/var/cache/apt/archives"

echo "[*] ===== DPKG FULL FIX START ====="

# --------------------------------------------------
# 1. Проверка файловой системы (запись)
# --------------------------------------------------
echo "[*] Проверка записи..."

touch $DPKG_DIR/testfile 2>/dev/null

if [ $? -ne 0 ]; then
    echo "[ERROR] Файловая система только для чтения (READ-ONLY)"
    echo "[!] Попробуй: mount -o remount,rw /"
    exit 1
fi

rm -f $DPKG_DIR/testfile

# --------------------------------------------------
# 2. Восстановление структуры dpkg
# --------------------------------------------------
echo "[*] Проверка структуры dpkg..."

mkdir -p $DPKG_DIR/{updates,info,parts,triggers}

# обязательные файлы
touch $DPKG_DIR/status
touch $DPKG_DIR/available

# --------------------------------------------------
# 3. Исправление прав (CRITICAL)
# --------------------------------------------------
echo "[*] Исправление прав..."

chmod 755 $DPKG_DIR
chmod -R 755 $DPKG_DIR/updates 2>/dev/null
chmod -R 755 $DPKG_DIR/info 2>/dev/null

chmod 644 $DPKG_DIR/status 2>/dev/null
chmod 644 $DPKG_DIR/available 2>/dev/null

chown -R root:root $DPKG_DIR 2>/dev/null

# --------------------------------------------------
# 4. Очистка lock файлов
# --------------------------------------------------
echo "[*] Удаление lock файлов..."

rm -f $DPKG_DIR/lock
rm -f $DPKG_DIR/lock-frontend
rm -f $APT_CACHE/lock

# --------------------------------------------------
# 5. Очистка битых updates
# --------------------------------------------------
echo "[*] Очистка updates..."

rm -rf $DPKG_DIR/updates/* 2>/dev/null

# --------------------------------------------------
# 6. Проверка status (если сломан)
# --------------------------------------------------
echo "[*] Проверка status..."

if [ ! -s "$DPKG_DIR/status" ]; then
    echo "[!] status повреждён → восстановление"
    rm -f $DPKG_DIR/status
    touch $DPKG_DIR/status
    chmod 644 $DPKG_DIR/status
fi

# --------------------------------------------------
# 7. Настройка dpkg (главный этап)
# --------------------------------------------------
echo "[*] dpkg --configure -a ..."

dpkg --configure -a

if [ $? -ne 0 ]; then
    echo "[!] dpkg configure завершился с ошибкой"
fi

# --------------------------------------------------
# 8. Исправление зависимостей
# --------------------------------------------------
echo "[*] apt -f install ..."

apt -f install -y

# --------------------------------------------------
# 9. Финальная проверка
# --------------------------------------------------
echo "[*] Финальная проверка dpkg..."

dpkg --audit

echo "[✔] ===== DPKG FIX COMPLETED ====="
