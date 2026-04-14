#!/data/data/com.termux/files/usr/bin/bash

# =========================================================
# KALI NETHUNTER PRO (TERMUX + ROOT)
# =========================================================

BASE="/data/data/com.termux/files/usr/var/kali"
ROOTFS="$BASE/rootfs"
SCRIPTS="$BASE/scripts"
LOGS="$BASE/logs"

mkdir -p "$BASE" "$SCRIPTS" "$LOGS"

echo "[*] Kali PRO install..."

# =========================================================
# FUNCTION: download
# =========================================================
/**
 * Télécharge un fichier si inexistant
 * @param {string} url
 * @param {string} file
 */
download() {
    URL="$1"
    FILE="$2"

    if [ -f "$FILE" ]; then
        echo "[v] already exists"
        return
    fi

    wget --no-check-certificate "$URL" -O "$FILE"
}

cd "$BASE"

# =========================================================
# 1. ROOTFS
# =========================================================
download \
"https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-minimal.tar.xz" \
"kali.tar.xz"

echo "[*] extract..."
mkdir -p "$ROOTFS"
proot --link2symlink tar -xJf kali.tar.xz -C "$ROOTFS"

# =========================================================
# 2. DNS FIX
# =========================================================
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# =========================================================
# 3. MOUNT SCRIPT
# =========================================================
cat > "$SCRIPTS/mount.sh" << 'EOF'
#!/system/bin/sh

ROOTFS="/data/data/com.termux/files/usr/var/kali/rootfs"

/**
 * Monte les systèmes nécessaires pour chroot
 */
mount -o bind /dev $ROOTFS/dev
mount -t proc proc $ROOTFS/proc
mount -t sysfs sys $ROOTFS/sys
mount -o bind /sdcard $ROOTFS/sdcard
EOF

chmod 755 "$SCRIPTS/mount.sh"

# =========================================================
# 4. START SCRIPT
# =========================================================
cat > "$SCRIPTS/start.sh" << 'EOF'
#!/system/bin/sh

BASE="/data/data/com.termux/files/usr/var/kali"
ROOTFS="$BASE/rootfs"

/**
 * Lance Kali en chroot avec root
 */
su -c "$BASE/scripts/mount.sh"
su -c "chroot $ROOTFS /bin/bash"
EOF

chmod 755 "$SCRIPTS/start.sh"

# =========================================================
# 5. WIFI SCRIPT
# =========================================================
cat > "$SCRIPTS/wifi.sh" << 'EOF'
#!/bin/bash

/**
 * Script de gestion WiFi pentest
 */

echo "[*] Interfaces:"
ip link

echo "[*] Switching to monitor mode..."
airmon-ng check kill
airmon-ng start wlan1

echo "[+] Done"
EOF

chmod 755 "$SCRIPTS/wifi.sh"

# =========================================================
# 6. MENU (WIFISLAX STYLE)
# =========================================================
cat > "$SCRIPTS/nethunter-menu.sh" << 'EOF'
#!/bin/bash

/**
 * Menu interactif Kali NetHunter style
 */

while true; do
    clear
    echo "==== KALI PRO MENU ===="
    echo "1) Nmap scan"
    echo "2) WiFi attack"
    echo "3) SQLMap"
    echo "4) Hydra brute"
    echo "5) Exit"
    read -p "Choice: " c

    case $c in
        1)
            read -p "Target: " t
            nmap -A $t
        ;;
        2)
            bash /scripts/wifi.sh
        ;;
        3)
            read -p "URL: " u
            sqlmap -u "$u" --batch
        ;;
        4)
            read -p "Target: " t
            hydra -l admin -P rockyou.txt $t http-get
        ;;
        5)
            exit
        ;;
    esac
done
EOF

chmod 755 "$SCRIPTS/nethunter-menu.sh"

# =========================================================
# 7. INIT KALI
# =========================================================
cat > "$ROOTFS/root/init.sh" << 'EOF'
#!/bin/bash

apt update

apt install -y kali-linux-core

apt install -y \
nmap \
aircrack-ng \
hydra \
sqlmap \
nikto \
wireless-tools \
iw \
tcpdump \
net-tools

echo "[✔] Kali PRO ready"
EOF

chmod +x "$ROOTFS/root/init.sh"

echo "[✔] INSTALL DONE"
echo ""
echo "RUN:"
echo "su -c sh $SCRIPTS/start.sh"
echo ""
echo "INSIDE KALI:"
echo "./init.sh"
echo "bash /scripts/nethunter-menu.sh"
