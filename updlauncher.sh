#!/bin/bash

# --- [ КОНФИГУРАЦИЯ ] ---
# Ссылка на основной боевой скрипт
REPO_URL="https://raw.githubusercontent.com/szp2025/core-prime-tools/refs/heads/main/launcher.sh"
# Куда сохраняем основной скрипт
TARGET_FILE="/root/launcher.sh"
# Имя команды для быстрого запуска
ALIAS_NAME="launcher"

# Цвета для логов
G='\033[1;32m'
R='\033[1;31m'
Y='\033[1;33m'
B='\033[1;34m'
NC='\033[0m'

clear
echo -e "${Y}>>> PRIME MASTER: UPDATE SYSTEM <<<${NC}"
echo "------------------------------------------------"

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

# 3. Удаление старой версии перед обновлением
if [ -f "$TARGET_FILE" ]; then
    echo -e "${Y}[*] Removing old launcher...${NC}"
    rm -f "$TARGET_FILE"
fi

# 4. Скачивание новой версии из GitHub
echo -e "${Y}[*] Downloading new version...${NC}"
curl -s -L "$REPO_URL" -o "$TARGET_FILE"

# 5. Проверка результата и настройка доступа
if [ -f "$TARGET_FILE" ]; then
    chmod +x "$TARGET_FILE"
    
    # Создаем алиас, если его еще нет, чтобы команда 'launcher' работала всегда
    if ! grep -q "alias $ALIAS_NAME=" ~/.bashrc; then
        echo -e "${B}[*] Adding alias '$ALIAS_NAME' to ~/.bashrc...${NC}"
        echo "alias $ALIAS_NAME='bash $TARGET_FILE'" >> ~/.bashrc
    fi
    
    # Создаем прямую ссылку в системную папку (для надежности)
    ln -sf "$TARGET_FILE" /usr/local/bin/$ALIAS_NAME
    
    echo -e "${G}[SUCCESS] Launcher updated successfully!${NC}"
    echo "------------------------------------------------"
    echo -e "${G}[>] Launch command: ${Y}$ALIAS_NAME${NC}"
else
    echo -e "${R}[!] Update failed. Check REPO_URL.${NC}"
    exit 1
fi

# Выход без удаления этого файла (updlauncher.sh)
echo -e "${B}[i] Updater preserved for future use.${NC}"
exit 0
