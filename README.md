# 🛡️ Wazuh SIEM Lab

Lab SIEM (Security Information and Event Management) dựng trên **Wazuh 4.9.2** — nền tảng giám sát an ninh mã nguồn mở. Mục tiêu: tự tay xây một hệ thống phát hiện tấn công hoàn chỉnh (manager + indexer + dashboard + agent), chạy các kịch bản tấn công thật trong môi trường cô lập, rồi quan sát/điều chỉnh cách Wazuh phát hiện và phản ứng. Phục vụ học tập và nghiên cứu bảo mật.

## 📐 Kiến Trúc

```
┌──────────────────────────────────────────────────────────┐
│                Host Windows (8GB RAM)                    │
│                                                          │
│  ┌─────────────────────┐  ┌─────────────────────┐       │
│  │ VM1: Wazuh Server   │  │ VM2: Ubuntu Agent   │       │
│  │ Ubuntu 22.04        │  │ Ubuntu 22.04        │       │
│  │ RAM: 4GB            │  │ RAM: 2GB            │       │
│  │ IP: 192.168.56.10   │  │ IP: 192.168.56.20   │       │
│  │                     │  │                     │       │
│  │ • Wazuh Manager     │  │ • Wazuh Agent       │       │
│  │ • Wazuh Indexer     │  │ • SSH Server        │       │
│  │ • Wazuh Dashboard   │  │ • Hydra, Nmap, etc  │       │
│  └─────────────────────┘  └─────────────────────┘       │
│                                                          │
│  Wazuh Agent (Windows) ← monitor Host trực tiếp         │
└──────────────────────────────────────────────────────────┘
```

- **Network:** VirtualBox Host-Only `192.168.56.0/24` (static IP) + NAT cho internet. Mọi attack tool **chỉ trỏ trong dải này**.
- **Phiên bản:** Wazuh ghim `4.9.2` cho cả manager và agent (agent phải ≤ manager).

## 📚 Nội Dung Lab

| Chủ đề | Mô tả | File hướng dẫn |
|--------|-------|----------------|
| **Hạ tầng** | Dựng VM, network host-only, cài Wazuh Server all-in-one + 2 agent | [02-installation.md](docs/02-installation.md) |
| **4 bài lab** | Brute Force SSH, File Integrity Monitoring, Active Response, Vulnerability Scan | [03-lab-exercises.md](docs/03-lab-exercises.md) |
| **Custom Rules** | Viết rule riêng (override rule `100001`) + cấu trúc báo cáo | [04-custom-rules.md](docs/04-custom-rules.md) |
| **Troubleshooting** | Lỗi tiêu biểu khi dựng lab & cách khắc phục dứt điểm | [05-troubleshooting.md](docs/05-troubleshooting.md) |

## 🔍 Lab Demo Được Gì

- **Brute Force SSH** — Hydra tấn công → Wazuh gom chuỗi login thất bại thành alert (rule `5763`, MITRE **T1110**).
- **File Integrity Monitoring** — sửa/xóa file trong thư mục giám sát → alert `added`/`modified`/`deleted` realtime.
- **Active Response** — brute force vượt ngưỡng → manager ra lệnh agent tự chặn IP bằng `iptables` (rule `651`).
- **Vulnerability Detection** — đối chiếu package trên agent với CSDL CVE, liệt kê lỗ hổng theo severity.
- **Custom Rule** — override rule nâng severity brute force theo nguồn, minh họa khả năng tự định nghĩa cảnh báo.

## 🗂️ Cấu Trúc Thư Mục

```
├── docs/               # Tài liệu hướng dẫn chi tiết (02–05)
├── configs/            # Config mẫu / backup
│   └── local_rules.xml         # Custom rule 100001 (deploy lên VM1)
├── scripts/            # Scripts tự động hóa
│   ├── setup-server.sh         # Setup Wazuh Server (VM1)
│   ├── setup-agent.sh          # Setup Agent + attack tools (VM2)
│   └── setup-win-agent.ps1     # Setup Windows Agent (Host)
└── screenshots/        # Ảnh kết quả lab cho báo cáo
```

## 🚀 Bắt Đầu Nhanh

1. Đọc [02-installation.md](docs/02-installation.md) để dựng hạ tầng (VM, network, Wazuh Server, agent).
2. Copy scripts vào VM qua SCP rồi chạy theo hướng dẫn:
   ```bash
   scp scripts/setup-server.sh wazuh@192.168.56.10:~
   scp scripts/setup-agent.sh  user@192.168.56.20:~
   ```
3. Xác nhận 2 agent **Active** trên Dashboard, rồi làm lần lượt [4 bài lab](docs/03-lab-exercises.md).
4. Viết [custom rule + báo cáo](docs/04-custom-rules.md). Gặp lỗi → tra [05-troubleshooting.md](docs/05-troubleshooting.md).

## 🔑 Lấy Lại Password Admin Dashboard

Password admin (random lúc cài) lưu trong `wazuh-install-files.tar` trên **VM1**. In ra trực tiếp (không cần giải nén ra đĩa):

```bash
sudo tar -O -xf /home/wazuh/wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
```

> 💡 File nằm ở thư mục chạy `wazuh-install.sh` (`/home/wazuh/`), **không** phải `/var/ossec/`. Nếu không nhớ: `sudo find / -name 'wazuh-install-files.tar' 2>/dev/null`. Đăng nhập: `https://192.168.56.10` với user `admin`.

## 📋 Yêu Cầu

| Hạng mục | Tối thiểu |
|----------|-----------|
| Host | Windows 10/11, **8GB RAM** |
| Ảo hóa | VirtualBox 7.x |
| ISO | Ubuntu 22.04 Server (~2GB) |
| Đĩa trống | **~60GB** (VM1 cần ≥ 40GB để cài dashboard) |

> ⚠️ Đây là môi trường lab **cô lập**. Credentials và attack tools chỉ dùng trong dải `192.168.56.0/24`, không hướng ra ngoài.
