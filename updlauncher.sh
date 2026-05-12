#!/bin/bash

# --- [ КОНФИГУРАЦИЯ ] ---
REPO_URL="https://raw.githubusercontent.com/szp2025/>
TARGET_FILE="/root/launcher.sh"

# Цвета для логов
G='\033[1;32m'
R='\033[1;31m'
Y='\033[1;33m'
NC='\033[0m'

clear
echo -e "${Y}>>> PRIME MASTER: UPDATE SYSTEM <<<${NC>
echo "---------------------------------------------->

# 1. Проверка прав (Root)
if [ "$EUID" -ne 0 ]; then
    echo -e "${R}[!] Error: Run as root!${NC}"
    exit 1
fi


# 2. Проверка соединения
echo -e "${Y}[*] Checking connection...${NC}"
if ! ping -c 1 google.com > /dev/null 2>&1; then
    echo -e "${R}[!] No internet connection.${NC}"
    exit 1
fi

# 3. Удаление старого файла
if [ -f "$TARGET_FILE" ]; then
    echo -e "${Y}[*] Removing old launcher...${NC}"
    rm -f "$TARGET_FILE"
fi


# 4. Скачивание новой версии
echo -e "${Y}[*] Downloading new version from GitHub>
curl -s -L "$REPO_URL" -o "$TARGET_FILE"

# 5. Проверка успешности скачивания
if [ -f "$TARGET_FILE" ]; then
    chmod +x "$TARGET_FILE"
    echo -e "${G}[SUCCESS] Launcher updated successf>
    echo "------------------------------------------>
    echo -e "${G}[>] Run it with: ./launcher.sh${NC}"
else
    echo -e "${R}[!] Update failed. File not found a>
fi

# 6. Самоудаление (опционально) или просто выход
exit 0
