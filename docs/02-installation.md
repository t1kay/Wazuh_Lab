# 📅 Ngày 1 — Hướng Dẫn Xây Dựng Hạ Tầng Lab

> Thời gian ước tính: **6–7 tiếng** (chia 2 buổi)

---

## Phần A — Chuẩn Bị Host Windows (30 phút)

### Bước 1: Tăng Virtual Memory (Swap)

Với 8GB RAM, Windows sẽ rất chật khi chạy 2 VMs. Tăng virtual memory giúp tránh treo máy.

```
1. Nhấn Win + R → gõ: sysdm.cpl → Enter
2. Tab "Advanced" → Performance > "Settings..."
3. Tab "Advanced" → Virtual Memory > "Change..."
4. Bỏ tick "Automatically manage paging file size for all drives"
5. Chọn ổ C: → Custom size:
     Initial size (MB): 8192
     Maximum size (MB): 8192
6. Nhấn "Set" → OK → OK → Restart máy
```

✅ **Verify:** Sau khi restart, mở Task Manager > Performance > Memory → Committed phải hiện `X.X / 16 GB` (8GB RAM + 8GB swap).

---

### Bước 2: Cài VirtualBox

**Cách 1 — Tải từ web:**
```
1. Vào https://www.virtualbox.org/wiki/Downloads
2. Tải "VirtualBox 7.x.x platform packages" → Windows hosts
3. Chạy installer → Next > Next > Install
4. (Tùy chọn) Tải Extension Pack từ cùng trang → double-click để cài
```

**Cách 2 — Dùng winget (nếu có):**
```powershell
winget install Oracle.VirtualBox
```

✅ **Verify:** Mở VirtualBox → Help > About → thấy version 7.x.x

---

### Bước 3: Tạo Host-Only Network

```
1. Mở VirtualBox
2. File > Host Network Manager (hoặc Ctrl+H)
3. Nhấn "Create" → tạo network mới
4. Chọn network vừa tạo, nhấn Properties:
     Adapter:
       IPv4 Address: 192.168.56.1
       IPv4 Network Mask: 255.255.255.0
     DHCP Server:
       ☐ Enable Server (TẮT DHCP — dùng static IP)
5. Apply → Close
```

> ⚠️ **VirtualBox 7.x:** Nếu không thấy "Host Network Manager", vào:
> `File > Tools > Network Manager > Host-only Networks tab`

✅ **Verify:** Mở CMD:
```cmd
ipconfig
```
Phải thấy adapter mới với IP `192.168.56.1`

---

### Bước 4: Tải Ubuntu 22.04 Server ISO

```
URL: https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso
Kích thước: ~2 GB
```

Hoặc dùng PowerShell:
```powershell
# Tải vào thư mục Downloads
Invoke-WebRequest -Uri "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso" `
  -OutFile "$env:USERPROFILE\Downloads\ubuntu-22.04-server.iso"
```

> 💡 Dùng chung 1 ISO cho cả 2 VMs.

---

## Phần B — Tạo & Cài Đặt VMs (2–3 tiếng)

### Bước 5: Tạo VM1 — Wazuh Server

**Trong VirtualBox:**
```
1. Nhấn "New"
2. Name: Wazuh-Server
   Folder: (để mặc định)
   ISO Image: chọn file ubuntu-22.04-server.iso vừa tải
   Type: Linux
   Version: Ubuntu (64-bit)
   ☑ Skip Unattended Installation

3. Hardware:
   Base Memory: 4096 MB
   Processors: 2

4. Virtual Hard Disk:
   Create a Virtual Hard Disk Now
   Disk Size: 40 GB
   ☑ Pre-allocate Full Size: KHÔNG tick (để dynamically allocated)

5. Nhấn Finish
```

**Cấu hình Network (trước khi bật VM):**
```
Chọn VM "Wazuh-Server" → Settings → Network:

  Adapter 1:
    ☑ Enable Network Adapter
    Attached to: NAT
    
  Adapter 2:
    ☑ Enable Network Adapter  
    Attached to: Host-only Adapter
    Name: VirtualBox Host-Only Ethernet Adapter
```

**Bật VM & cài Ubuntu:**
```
1. Nhấn Start → Boot từ ISO
2. Chọn ngôn ngữ: English
3. Keyboard: (giữ mặc định)
4. Install type: Ubuntu Server (minimized) ← chọn cái này tiết kiệm RAM
5. Network: để DHCP tự động (config static sau)
6. Storage: Use an entire disk (mặc định)
7. Profile:
     Your name: wazuh
     Server name: wazuh-server
     Username: wazuh
     Password: (đặt password, ví dụ: Wazuh@Lab2026)
8. SSH: ☑ Install OpenSSH server
9. Snaps: không chọn gì
10. Đợi cài xong → Reboot Now
```

**Sau khi reboot — Đăng nhập & cấu hình IP:**
```bash
# Đăng nhập với user: wazuh / password bạn đặt

# Kiểm tra tên network interfaces
ip a
# Sẽ thấy: enp0s3 (NAT) và enp0s8 (Host-Only)

# Cấu hình static IP cho enp0s8
sudo nano /etc/netplan/01-lab-network.yaml
```

Gõ nội dung sau:
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses:
        - 192.168.56.10/24
```

```bash
# Áp dụng
sudo netplan apply

# Verify
ip addr show enp0s8
# Phải thấy: inet 192.168.56.10/24
```

---

### Bước 6: Tạo VM2 — Ubuntu Agent

**Lặp lại tương tự Bước 5, nhưng thay đổi:**
```
Name: Ubuntu-Agent
Base Memory: 2048 MB
Processors: 1
Disk Size: 20 GB
Network: giống VM1 (NAT + Host-Only)

Khi cài Ubuntu:
  Server name: ubuntu-agent
  Username: agent
  Password: (ví dụ: Agent@Lab2026)
```

**Sau khi cài — cấu hình IP:**
```bash
sudo nano /etc/netplan/01-lab-network.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses:
        - 192.168.56.20/24
```

```bash
sudo netplan apply
ip addr show enp0s8
# Phải thấy: inet 192.168.56.20/24
```

---

### Bước 7: Verify Network

Chạy 3 bài test sau:

**Test 1 — Từ VM1 (Wazuh Server):**
```bash
ping -c 3 192.168.56.20    # → VM2
```

**Test 2 — Từ VM2 (Ubuntu Agent):**
```bash
ping -c 3 192.168.56.10    # → VM1
```

**Test 3 — Từ Host Windows (CMD hoặc PowerShell):**
```cmd
ping 192.168.56.10          REM → VM1
ping 192.168.56.20          REM → VM2
```

✅ Cả 3 test đều phải nhận được reply. Nếu không:
- Kiểm tra Host-Only adapter đã enable chưa
- Kiểm tra IP đã đúng chưa (`ip a` trên VM)
- Kiểm tra Windows Firewall không block ICMP

---

## Phần C — Cài Wazuh Server (1–2 tiếng)

### Bước 8: Tạo Swap & Cài Wazuh (trên VM1)

> 💡 Bạn có thể dùng script tự động hoặc chạy thủ công từng lệnh.

**Cách 1 — Dùng script (khuyến nghị):**

Copy file `scripts/setup-server.sh` vào VM1 qua SCP:
```powershell
# Từ Host Windows PowerShell:
scp d:\Lab\Wazuh_lab\scripts\setup-server.sh wazuh@192.168.56.10:~/
```

Trên VM1:
```bash
chmod +x ~/setup-server.sh
sudo bash ~/setup-server.sh
```

**Cách 2 — Chạy thủ công từng bước:**

```bash
# 8a. Tạo swap file 2GB
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify swap
free -h
# Phải thấy: Swap: 2.0Gi

# 8b. Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget net-tools vim htop

# 8c. Cài Wazuh All-in-One
curl -sO https://packages.wazuh.com/4.x/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

> ⏳ **Quá trình cài mất 15–30 phút.** Có thể làm việc khác trong lúc đợi.

> ⚠️ **QUAN TRỌNG:** Khi cài xong, terminal sẽ hiện thông tin đăng nhập:
> ```
> INFO: --- Summary ---
> INFO: You can access the web interface https://<wazuh-dashboard-ip>:443
>     User: admin
>     Password: <RANDOM_PASSWORD>
> ```
> **GHI LẠI PASSWORD NÀY!** Nếu quên, chạy:
> ```bash
> sudo tar -xvf /var/ossec/wazuh-install-files.tar -C /tmp ./wazuh-install-files/wazuh-passwords.txt
> cat /tmp/wazuh-install-files/wazuh-passwords.txt
> ```

### Bước 9: Verify Wazuh Server

```bash
# Kiểm tra 3 services
sudo systemctl status wazuh-manager    # ← phải Active (running)
sudo systemctl status wazuh-indexer    # ← phải Active (running)  
sudo systemctl status wazuh-dashboard  # ← phải Active (running)

# Kiểm tra RAM (với htop)
htop
# Wazuh Indexer thường chiếm ~1.5-2GB RAM
```

### Bước 10: Truy cập Dashboard

Mở browser **trên Host Windows:**
```
URL: https://192.168.56.10
User: admin
Password: <password ghi ở bước 8>
```

> ⚠️ Browser sẽ cảnh báo "Your connection is not private" → nhấn **Advanced** → **Proceed to 192.168.56.10 (unsafe)**. Đây là do self-signed certificate, hoàn toàn bình thường trong lab.

✅ **Verify:** Thấy Wazuh Dashboard login page → đăng nhập thành công → thấy Overview page.

---

## Phần D — Deploy Agents (1–1.5 tiếng)

### Bước 11: Cài Wazuh Agent trên VM2 (Linux)

**Cách 1 — Dùng script:**
```powershell
# Từ Host Windows:
scp d:\Lab\Wazuh_lab\scripts\setup-agent.sh agent@192.168.56.20:~/
```

Trên VM2:
```bash
chmod +x ~/setup-agent.sh
sudo bash ~/setup-agent.sh
```

**Cách 2 — Thủ công:**
```bash
# Trên VM2

# Thêm Wazuh repo
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
  chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  | sudo tee /etc/apt/sources.list.d/wazuh.list

# Cài agent
sudo apt update
sudo WAZUH_MANAGER="192.168.56.10" apt install wazuh-agent -y
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent

# Verify
sudo systemctl status wazuh-agent
# Phải thấy: Active (running)
```

**Cài attack tools:**
```bash
sudo apt install -y hydra nmap nikto netcat-openbsd john dirb

# Tạo user test cho bài lab ngày mai
sudo useradd -m -s /bin/bash testuser
echo "testuser:labpassword123" | sudo chpasswd
```

---

### Bước 12: Cài Wazuh Agent trên Host Windows

**Cách 1 — Qua Dashboard (dễ nhất):**
```
1. Mở Dashboard: https://192.168.56.10
2. Menu trái → Endpoints Summary
3. Nhấn "Deploy new agent"
4. Chọn:
     OS: Windows
     Server address: 192.168.56.10
     Agent name: (tùy chọn, ví dụ: windows-host)
5. Copy toàn bộ lệnh PowerShell được tạo
6. Mở PowerShell (Run as Administrator) trên Host
7. Paste & chạy
```

**Cách 2 — Dùng script:**
```powershell
# PowerShell (Run as Administrator)
# Chỉnh version nếu cần
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "d:\Lab\Wazuh_lab\scripts\setup-win-agent.ps1"
```

✅ **Verify:** Chạy lệnh sau:
```powershell
Get-Service -Name Wazuh
# Status phải là: Running
```

---

### Bước 13: Verify Tất Cả Agents

Mở Dashboard → **Endpoints Summary** (menu trái)

Phải thấy **2 agents** với status **Active**:

| Agent Name | OS | IP | Status |
|---|---|---|---|
| `ubuntu-agent` | Ubuntu 22.04 | 192.168.56.20 | ✅ Active |
| `<tên-máy-host>` | Windows 10/11 | 192.168.56.1 | ✅ Active |

> 💡 Nếu agent hiển thị **Disconnected**, đợi 1–2 phút rồi refresh. Nếu vẫn lỗi:
> - Kiểm tra firewall trên VM1: `sudo ufw status` → nên là `inactive`
> - Kiểm tra agent logs:
>   - Linux: `sudo cat /var/ossec/logs/ossec.log | tail -20`
>   - Windows: xem file `C:\Program Files (x86)\ossec-agent\ossec.log`

---

## Phần E — Snapshot & Kết Thúc Ngày 1 (15 phút)

### Bước 14: Snapshot VMs

```
VirtualBox → chọn VM → Snapshots tab (bên phải) → Take:
  VM1 (Wazuh-Server): Snapshot name = "Day1-Baseline"
  VM2 (Ubuntu-Agent): Snapshot name = "Day1-Baseline"
```

> 💡 Snapshot giúp bạn khôi phục lại trạng thái này nếu làm hỏng gì ở ngày 2, 3.

---

## ✅ Checklist Cuối Ngày 1

Đánh dấu tất cả đã hoàn thành:

- [ ] Virtual memory Windows = 8GB
- [ ] VirtualBox 7.x đã cài
- [ ] Host-Only network (192.168.56.1) hoạt động
- [ ] VM1 (Wazuh-Server) — IP 192.168.56.10 — chạy OK
- [ ] VM2 (Ubuntu-Agent) — IP 192.168.56.20 — chạy OK
- [ ] Ping giữa Host ↔ VM1 ↔ VM2 thành công
- [ ] Wazuh Dashboard truy cập được qua browser
- [ ] **Password admin đã ghi lại**
- [ ] Agent Linux (VM2) = Active
- [ ] Agent Windows (Host) = Active
- [ ] Attack tools (hydra, nmap) cài xong trên VM2
- [ ] Snapshot "Day1-Baseline" cho cả 2 VMs

**Nếu hoàn thành tất cả → bạn đã sẵn sàng cho Ngày 2! 🎉**

---

## ❓ Troubleshooting

### VM không ping được nhau
```bash
# Trên VM, kiểm tra IP
ip a show enp0s8

# Nếu không thấy enp0s8, kiểm tra VirtualBox → Settings → Network → Adapter 2
# Phải là "Host-only Adapter"

# Trên Host, kiểm tra VirtualBox adapter
ipconfig
# Phải thấy "VirtualBox Host-Only Ethernet Adapter" với IP 192.168.56.1
```

### Wazuh install bị lỗi OOM (Out of Memory)
```bash
# Kiểm tra swap đã bật chưa
free -h
# Nếu Swap = 0, tạo swap trước (xem Bước 8a)

# Chạy lại installer
sudo bash wazuh-install.sh -a
```

### Dashboard không load được
```bash
# Kiểm tra wazuh-dashboard đang chạy
sudo systemctl status wazuh-dashboard

# Nếu failed, restart
sudo systemctl restart wazuh-dashboard

# Kiểm tra port 443
sudo ss -tlnp | grep 443
```

### Agent không connect được Server
```bash
# Trên Agent — kiểm tra config
sudo cat /var/ossec/etc/ossec.conf | grep -A 3 "<server>"
# Phải thấy: <address>192.168.56.10</address>

# Nếu sai, sửa lại:
sudo nano /var/ossec/etc/ossec.conf
# Sửa <address> thành 192.168.56.10
sudo systemctl restart wazuh-agent

# Kiểm tra kết nối từ Agent → Server
nc -zv 192.168.56.10 1514
# Phải thấy: Connection succeeded
```
