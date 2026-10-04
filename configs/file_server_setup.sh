#!/bin/bash
# ============================================================
# Summit Ridge Engineering — File Server Setup Script
# Device: File-Server  |  Static IP: 10.0.30.10 (VLAN 30)
# OS: Ubuntu 22.04 LTS (Docker-based QEMU VM in GNS3)
# Run as root after first boot.
# ============================================================

set -e

echo "[1/6] Setting static IP 10.0.30.10/24 on eth0..."
# For persistent config, write a netplan file.
cat > /etc/netplan/01-static.yaml << 'EOF'
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 10.0.30.10/24
      routes:
        - to: default
          via: 10.0.30.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
netplan apply
echo "   Static IP applied."

echo "[2/6] Installing Samba (SMB file share)..."
apt-get update -qq
apt-get install -y samba > /dev/null

echo "[3/6] Creating shared directory /srv/summit_ridge..."
mkdir -p /srv/summit_ridge
chmod 0775 /srv/summit_ridge
chown nobody:nogroup /srv/summit_ridge

echo "[4/6] Writing smb.conf..."
cat >> /etc/samba/smb.conf << 'EOF'

[SummitRidgeShare]
   comment = Summit Ridge Engineering Shared Files
   path = /srv/summit_ridge
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0664
   directory mask = 0775
EOF

echo "[5/6] Restarting Samba..."
systemctl restart smbd nmbd
systemctl enable smbd nmbd

echo "[6/6] Creating test file for TC verification..."
echo "Summit Ridge Engineering — File Server Test File" > /srv/summit_ridge/test.txt
echo "Created: $(date)" >> /srv/summit_ridge/test.txt

echo ""
echo "=== File Server Setup Complete ==="
echo "IP:           10.0.30.10"
echo "Share path:   /srv/summit_ridge"
echo "SMB share:    \\\\10.0.30.10\\SummitRidgeShare"
echo "Verify with:  smbclient -L //10.0.30.10 -N"
echo ""
echo "Screenshot check: ping 10.0.30.10 from VPCS should succeed."
