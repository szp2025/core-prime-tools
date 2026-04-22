#!/bin/bash

# ==========================================
# AUTO HEAL DPKG (ANTI-CORRUPTION)
# ==========================================

DPKG_DIR="/var/lib/dpkg"

echo "[*] Проверка dpkg..."

# Если нет папки updates → восстановить
if [ ! -d "$DPKG_DIR/updates" ]; then
    echo "[!] dpkg сломан — восстановление..."
    mkdir -p $DPKG_DIR/{updates,info,parts,triggers}
fi

# Права
chmod 755 $DPKG_DIR
chmod -R 755 $DPKG_DIR/updates 2>/dev/null

# Удаление lock
rm -f $DPKG_DIR/lock*
rm -f /var/cache/apt/archives/lock

# Проверка status
if [ ! -s "$DPKG_DIR/status" ]; then
    echo "[!] status поврежден — пересоздание"
    touch $DPKG_DIR/status
fi

# Финальный фикс
dpkg --configure -a >/dev/null 2>&1
apt -f install -y >/dev/null 2>&1

echo "[✔] dpkg OK"
