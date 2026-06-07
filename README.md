# 🛡️ Wazuh SIEM Lab

Dự án lab SIEM (Security Information and Event Management) sử dụng Wazuh — nền tảng bảo mật mã nguồn mở, phục vụ học tập và nghiên cứu bảo mật.

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

## 📅 Kế Hoạch 3 Ngày

| Ngày | Nội dung | File hướng dẫn |
|------|----------|----------------|
| **Ngày 1** | Xây dựng hạ tầng: VMs, Wazuh Server, Agents | [02-installation.md](docs/02-installation.md) |
| **Ngày 2** | 4 bài lab: Brute Force, FIM, Active Response, Vuln Scan | [03-lab-exercises.md](docs/03-lab-exercises.md) |
| **Ngày 3** | Custom Rules + Tài liệu báo cáo | [04-custom-rules.md](docs/04-custom-rules.md) |

## 🗂️ Cấu Trúc Thư Mục

```
├── docs/               # Tài liệu chi tiết
├── configs/            # File config backup
├── scripts/            # Scripts tự động hóa
│   ├── setup-server.sh         # Setup Wazuh Server (VM1)
│   ├── setup-agent.sh          # Setup Agent + tools (VM2)
│   └── setup-win-agent.ps1    # Setup Windows Agent (Host)
└── screenshots/        # Screenshots lab results
```

## 🚀 Bắt Đầu Nhanh

1. Đọc [02-installation.md](docs/02-installation.md) — hướng dẫn Ngày 1
2. Copy scripts vào VMs qua SCP
3. Chạy scripts và theo dõi hướng dẫn

## 📋 Yêu Cầu

- Windows 10/11 (8GB RAM)
- VirtualBox 7.x
- Ubuntu 22.04 Server ISO (~2GB)
- ~60GB disk trống
