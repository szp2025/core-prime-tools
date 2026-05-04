#!/bin/bash
echo -e "\e[1;33m[!] ЗАПУСК ГЛОБАЛЬНОГО РЕМОНТА...\e[0m"

# Удаляем весь "мусор"
rm -f /usr/local/bin/launcher
rm -f /root/install_all.sh
rm -rf /root/.cache/zcompdump* 2>/dev/null

# Чистим систему (лечим dpkg и apt)
dpkg --configure -a 2>/dev/null
apt --fix-broken install -y 2>/dev/null

# Качаем свежий скрипт с твоего GitHub
echo "[*] Загрузка чистого установщика..."
curl -L -o /root/install_all.sh https://raw.githubusercontent.com/szp2025/core-prime-tools/main/install_all.sh
chmod +x /root/install_all.sh

echo -e "\e[1;32m[OK] Ремонт окончен. Теперь запускай: ./install_all.sh\e[0m"
EOF
chmod +x /root/repair.sh