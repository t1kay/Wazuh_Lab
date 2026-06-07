#!/bin/bash
# ============================================================
# Wazuh SIEM Lab — Setup Ubuntu Agent + Attacker Tools (VM2)
# Chạy script này trên VM2 (Ubuntu Agent - Ubuntu 22.04)
# ============================================================

set -e

WAZUH_SERVER_IP="192.168.56.10"
AGENT_IP="192.168.56.20"

echo "=========================================="
echo "  🖥️  Ubuntu Agent + Attacker Setup"
echo "=========================================="
echo ""

# --- Bước 1: Cấu hình static IP ---
echo "[1/4] Cấu hình network..."
cat <<EOF | sudo tee /etc/netplan/01-lab-network.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses:
        - ${AGENT_IP}/24
EOF
sudo netplan apply
echo "  → Static IP ${AGENT_IP} đã được set."
echo ""

# --- Bước 2: Cập nhật & cài SSH ---
echo "[2/4] Cập nhật hệ thống & cài SSH..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y openssh-server curl wget net-tools vim
sudo systemctl enable --now ssh
echo ""

# --- Bước 3: Cài Wazuh Agent ---
echo "[3/4] Cài đặt Wazuh Agent..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
  chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  | sudo tee /etc/apt/sources.list.d/wazuh.list

sudo apt update
sudo WAZUH_MANAGER="${WAZUH_SERVER_IP}" apt install wazuh-agent -y
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent
echo "  → Wazuh Agent đã được cài và kết nối tới ${WAZUH_SERVER_IP}"
echo ""

# --- Bước 4: Cài Attack Tools (thay thế Kali Linux) ---
echo "[4/4] Cài đặt Attack Tools..."
sudo apt install -y hydra nmap nikto netcat-openbsd john dirb
echo ""

# --- Tạo user test cho brute force lab ---
echo "Tạo user 'testuser' cho bài lab brute force..."
if id "testuser" &>/dev/null; then
    echo "  → User testuser đã tồn tại."
else
    sudo useradd -m -s /bin/bash testuser
    echo "testuser:labpassword123" | sudo chpasswd
    echo "  → User testuser đã được tạo (password: labpassword123)"
fi
echo ""

echo "=========================================="
echo "  ✅  Ubuntu Agent setup hoàn tất!"
echo "=========================================="
echo ""
echo "  📋 Thông tin:"
echo "    Agent IP:    ${AGENT_IP}"
echo "    Server IP:   ${WAZUH_SERVER_IP}"
echo "    Test user:   testuser / labpassword123"
echo ""
echo "  Kiểm tra agent:"
echo "    sudo systemctl status wazuh-agent"
echo ""
echo "  Attack tools đã cài:"
echo "    hydra, nmap, nikto, netcat, john, dirb"
echo ""
