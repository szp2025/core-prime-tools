#!/system/bin/sh

# =========================================================
# KALI FULL ROOT (CHROOT VERSION)
# =========================================================

BASE="/data/local/kali"
ROOTFS="$BASE/rootfs"
LOG="$BASE/install.log"

mkdir -p "$BASE"

echo "[*] Kali chroot install..." | tee -a "$LOG"

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
"https://kali.download/nethunter-images/current/rootfs/kalifs-armhf-full.tar.xz" \
"kali.tar.xz"

echo "[*] extracting..."
mkdir -p "$ROOTFS"
tar -xJf kali.tar.xz -C "$ROOTFS"

# =========================================================
# 2. DNS
# =========================================================
echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"

# =========================================================
# 3. MOUNT SCRIPT
# =========================================================
cat > "$BASE/mount.sh" << 'EOF'
#!/system/bin/sh

ROOTFS="/data/local/kali/rootfs"

mount -o bind /dev $ROOTFS/dev
mount -t proc proc $ROOTFS/proc
mount -t sysfs sys $ROOTFS/sys
mount -o bind /sdcard $ROOTFS/sdcard
EOF

chmod 755 "$BASE/mount.sh"

# =========================================================
# 4. START SCRIPT
# =========================================================
cat > "$BASE/start.sh" << 'EOF'
#!/system/bin/sh

BASE="/data/local/kali"
ROOTFS="$BASE/rootfs"

su -c "$BASE/mount.sh"

su -c "chroot $ROOTFS /bin/bash"
EOF

chmod 755 "$BASE/start.sh"

# =========================================================
# 5. INIT INSIDE KALI
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
net-tools \
wireless-tools \
iw \
tcpdump

echo "[✔] Kali FULL ready"
EOF

chmod +x "$ROOTFS/root/init.sh"

echo "[✔] INSTALL DONE"
echo "Run: su -c sh $BASE/start.sh"
