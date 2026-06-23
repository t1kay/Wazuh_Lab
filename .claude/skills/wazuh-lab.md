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

- Wazuh: manager all-in-one ghim `4.9.2`. **Cả 2 agent (Ubuntu + Windows) phải ghim đúng `4.9.2`** — repo `4.x` mặc định kéo bản mới nhất.
- **Agent version PHẢI ≤ manager.** Nếu agent > manager → log agent báo `Agent version must be lower or equal to manager version` + `Unable to add agent`, không bao giờ Active. Cài agent: `apt install wazuh-agent=4.9.2-1` rồi `apt-mark hold wazuh-agent`.
- **Khi hạ version agent (downgrade):** `ossec.conf` của bản mới còn sót lại sẽ chứa tag syscollector mà bản cũ không hiểu (`users`/`groups`/`services`/`browser_extensions`) → modulesd báo `No such tag '...' at module 'syscollector'`, agent không start. Backup rồi gỡ các tag đó khỏi `ossec.conf`, hoặc reset về config mặc định.
- Server cài bằng `wazuh-install.sh -a` (all-in-one). Cần swap 2GB chống OOM.
- Dashboard: `https://192.168.56.10` (self-signed cert).

## Yêu cầu hạ tầng (kiểm tra TRƯỚC khi cài — nếu không sẽ fail giữa chừng)

> All-in-one tải/giải nén ~3GB; riêng `wazuh-dashboard` có hàng trăm nghìn file `node_modules` → dễ cạn **cả byte lẫn inode**. Lỗi `No space left on device` lúc cài dashboard = hết đĩa HOẶC hết inode.

- **VM1 đĩa ≥ 40GB.** Ubuntu installer mặc định chỉ cấp ~½ đĩa cho LV root → kiểm tra `lsblk`/`sudo vgs`; nếu `VFree > 0` thì nới ngay (không cần reboot/VirtualBox):
  `sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv` (cờ `-r` resize2fs luôn → cũng tăng inode).
- **Chẩn đoán nền tảng đầu tiên khi cài lỗi:** `df -h / && df -i / && lsblk && free -h` — đừng vá triệu chứng (xóa swap, đổi flag) trước khi loại trừ đĩa/inode/RAM.
- Ubuntu 22.04 đã có sẵn `/swap.img` (~3.8G) → **không tạo thêm `/swapfile`** nếu `swapon --show` cho thấy swap tổng ≥ 2G (tránh phí đĩa).
- Purge package wazuh hỏng: **đừng** `rm /var/lib/dpkg/info/<pkg>.*` (làm hỏng metadata → cài lại không giải nén file). Dùng script stub `exit 0` rồi `dpkg --purge --force-all`.

## Đường dẫn quan trọng

- Linux agent config: `/var/ossec/etc/ossec.conf` — log: `/var/ossec/logs/ossec.log`
- Windows agent: `C:\Program Files (x86)\ossec-agent\ossec.conf` (+ `ossec.log`)
- Custom rules (Manager): `/var/ossec/etc/rules/local_rules.xml`
- Custom decoders: `/var/ossec/etc/decoders/local_decoder.xml`

## Credentials lab (chỉ dùng trong lab isolated)

- Dashboard admin: password random sinh khi cài → lưu trong `wazuh-install-files.tar`.
- Test user brute-force (VM2): `testuser` / `labpassword123`.
- Port agent→manager: `1514/tcp` (events), `1515/tcp` (enrollment).

## Nội dung lab

- Hạ tầng → [docs/02-installation.md](../../docs/02-installation.md)
- 4 lab (Brute Force, FIM, Active Response, Vuln Scan) → `docs/03-lab-exercises.md`
- Custom Rules + báo cáo → `docs/04-custom-rules.md`
- Troubleshooting → `docs/05-troubleshooting.md`
