#!/bin/bash
echo "[*] Глубокая чистка dpkg на Wiko..."

# Удаляем блокировки
rm -f /var/lib/dpkg/lock*
rm -f /var/cache/apt/archives/lock

# Очищаем ту самую папку updates
rm -rf /var/lib/dpkg/updates/*

# Пробуем починить структуру
apt-get update --fix-missing
dpkg --configure -a

echo "[+] Готово. Теперь попробуй снова запустить zphisher.sh"
