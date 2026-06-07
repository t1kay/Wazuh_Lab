# Skill: Wazuh Lab — Domain Facts

Sự thật cố định của lab này. Dùng làm nguồn chuẩn — **không bịa** IP/version/đường dẫn khác.

## Kiến trúc

| Thành phần | OS | IP | RAM |
|-----------|-----|-----|-----|
| VM1 — Wazuh Server (Manager + Indexer + Dashboard) | Ubuntu 22.04 | `192.168.56.10` | 4GB |
| VM2 — Ubuntu Agent (+ attack tools) | Ubuntu 22.04 | `192.168.56.20` | 2GB |
| Host Windows — Wazuh Agent | Windows 10/11 | `192.168.56.1` | 8GB |

- Network: VirtualBox **Host-Only** `192.168.56.0/24` (DHCP tắt, static IP), thêm NAT cho internet.
- Interface trong VM: `enp0s3` (NAT) + `enp0s8` (Host-Only).

## Phiên bản & cài đặt

- Wazuh: nhánh `4.x`, Windows agent đang ghim `4.9.2`.
- Server cài bằng `wazuh-install.sh -a` (all-in-one). Cần swap 2GB chống OOM.
- Dashboard: `https://192.168.56.10` (self-signed cert).

## Đường dẫn quan trọng

- Linux agent config: `/var/ossec/etc/ossec.conf` — log: `/var/ossec/logs/ossec.log`
- Windows agent: `C:\Program Files (x86)\ossec-agent\ossec.conf` (+ `ossec.log`)
- Custom rules (Manager): `/var/ossec/etc/rules/local_rules.xml`
- Custom decoders: `/var/ossec/etc/decoders/local_decoder.xml`

## Credentials lab (chỉ dùng trong lab isolated)

- Dashboard admin: password random sinh khi cài → lưu trong `wazuh-install-files.tar`.
- Test user brute-force (VM2): `testuser` / `labpassword123`.
- Port agent→manager: `1514/tcp` (events), `1515/tcp` (enrollment).

## Kế hoạch

- Ngày 1: hạ tầng → [docs/02-installation.md](../../docs/02-installation.md)
- Ngày 2: 4 lab (Brute Force, FIM, Active Response, Vuln Scan) → `docs/03-lab-exercises.md`
- Ngày 3: Custom Rules + báo cáo → `docs/04-custom-rules.md`
