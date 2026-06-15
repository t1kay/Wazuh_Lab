#!/bin/bash
# ============================================================
# Wazuh SIEM Lab — Setup Server (VM1)
# Chạy script này trên VM1 (Wazuh Server - Ubuntu 22.04)
# ============================================================

set -e

echo "=========================================="
echo "  🛡️  Wazuh Server Setup Script"
echo "=========================================="
echo ""

# --- Bước 1: Tạo swap file (chống OOM với 4GB RAM) ---
echo "[1/4] Tạo swap file 2GB..."
if [ -f /swapfile ]; then
    echo "  → Swap file đã tồn tại, bỏ qua."
else
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "  → Swap file 2GB đã được tạo."
fi
echo ""

# --- Bước 2: Cập nhật hệ thống ---
echo "[2/4] Cập nhật hệ thống..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget net-tools vim htop
echo ""

# --- Bước 3: Cấu hình static IP (Host-Only) ---
echo "[3/4] Cấu hình network..."
cat <<'EOF' | sudo tee /etc/netplan/01-lab-network.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses:
        - 192.168.56.10/24
EOF
sudo netplan apply
echo "  → Static IP 192.168.56.10 đã được set."
echo ""

# --- Bước 4: Cài đặt Wazuh All-in-One ---
echo "[4/4] Cài đặt Wazuh Server All-in-One..."
echo "  ⏳ Quá trình này mất khoảng 15-30 phút..."
echo ""
# -f: fail (không lưu trang lỗi); -L: theo redirect; -S: hiện lỗi; --retry: thử lại khi mạng chập chờn
if ! curl -fSL --retry 3 --retry-delay 5 -o wazuh-install.sh \
    https://packages.wazuh.com/4.9/wazuh-install.sh; then
    echo "  ❌ Tải wazuh-install.sh thất bại. Kiểm tra internet trong VM:"
    echo "     ping -c2 8.8.8.8   (mạng)   |   ping -c2 packages.wazuh.com   (DNS)"
    exit 1
fi

# Xác minh file là script thật, không phải trang HTML lỗi
if ! head -n1 wazuh-install.sh | grep -q '^#!/'; then
    echo "  ❌ File tải về không phải shell script (có thể bị 404/redirect lỗi)."
    exit 1
fi

sudo bash wazuh-install.sh -a

echo ""
echo "=========================================="
echo "  ✅  Wazuh Server cài đặt thành công!"
echo "=========================================="
echo ""
echo "  📋 QUAN TRỌNG: Ghi lại thông tin đăng nhập ở trên!"
echo "  🌐 Dashboard: https://192.168.56.10"
echo ""
echo "  Kiểm tra services:"
echo "    sudo systemctl status wazuh-manager"
echo "    sudo systemctl status wazuh-indexer"
echo "    sudo systemctl status wazuh-dashboard"
echo ""
