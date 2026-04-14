#!/data/data/com.termux/files/usr/bin/bash

# 1. Исправляем репозитории (используем найденную рабочую ссылку)
echo "deb https://packages.termux.org/termux-main-21 stable main" > $PREFIX/etc/apt/sources.list

# 2. Обновляем базу данных (игнорируем SSL из-за возраста Android 5.1)
apt update -o "Acquire::https::Verify-Peer=false"

# 3. Устанавливаем базу для Kali и Python для шаринга
apt install -y -o "Acquire::https::Verify-Peer=false" proot wget tar xz-utils python

# 4. Создаем структуру папок
mkdir -p $HOME/kali

echo "[✔] Репозитории исправлены, база установлена."
