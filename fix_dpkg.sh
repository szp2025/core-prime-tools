#!/bin/bash

# ==========================================
# AUTO FIX DPKG LOCK & UPDATES (NetHunter)
# ==========================================

echo "[*] Проверка блокировок dpkg..."

# Удаление lock файлов
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/cache/apt/archives/lock

# Очистка битых updates
if [ -d "/var/lib/dpkg/updates" ]; then
    echo "[*] Очистка updates..."
    rm -rf /var/lib/dpkg/updates/*
fi

# Восстановление dpkg
echo "[*] Восстановление dpkg..."
dpkg --configure -a

# Исправление зависимостей
echo "[*] Исправление зависимостей..."
apt -f install -y

echo "[✔] Готово"
