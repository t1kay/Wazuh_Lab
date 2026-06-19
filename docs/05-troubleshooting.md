# 🛠️ Troubleshooting — Tổng Hợp Lỗi Đã Gặp & Cách Khắc Phục

Nhật ký các lỗi **thực tế** đã gặp khi dựng lab này và cách xử lý dứt điểm. Sắp xếp theo giai đoạn: Mạng/SSH → Cài Server → Kết nối Agent → Chạy Lab → Script/VM.

> 💡 Nguyên tắc xuyên suốt (xem skill `security-mindset`): **soi nền tảng trước khi nghi config**. Khi lỗi lạ, chạy ngay `df -h /; df -i /; free -h; ss -tlnp` — một lệnh tổng quan tiết kiệm hàng giờ đoán mò. Nhiều lỗi dưới đây thực ra là **một gốc (đĩa 20G quá nhỏ)** hiện ra qua nhiều lớp triệu chứng khác nhau.

## 📋 Bảng tra nhanh

| # | Triệu chứng (thông báo lỗi) | Gốc rễ | Mục |
|---|------------------------------|--------|-----|
| 1 | `Connection timed out` / `refused` khi SSH vào VM | SSH server chưa chạy / IP host-only sai | [A.1](#a1) |
| 2 | `Error in network definition` / `unknown key 'dhcp04'` | Sai cú pháp YAML netplan | [A.2](#a2) |
| 3 | `permission denied` khi lưu file trong `/var/ossec/` qua Remote-SSH | Editor lưu bằng user thường | [A.3](#a3) |
| 4 | `dpkg: error ... pre-installation script ... exit status 127` | Lần cài trước dở dang → dpkg half-installed | [B.1](#b1) |
| 5 | `Port 1515/55000 is being used` / `already installed` | Tàn dư lần cài trước chưa dọn | [B.2](#b2) |
| 6 | `No space left on device` lúc giải nén `wazuh-dashboard` | **Hết đĩa HOẶC hết inode** (ổ 20G quá nhỏ) | [B.3](#b3) |
| 7 | `wazuh-manager could not be started` / install xong trong 2 giây | Xóa `/var/lib/dpkg/info/*` làm hỏng metadata | [B.4](#b4) |
| 8 | VM `aborted` / `VERR_UNRESOLVED_ERROR` lúc power-on | Xung đột VirtualBox ↔ Hyper-V hoặc OOM | [B.5](#b5) |
| 9 | `Agent version must be lower or equal to manager` + `Unable to add agent` | Agent > manager (repo 4.x kéo bản mới) | [C.1](#c1) |
| 10 | `No such tag 'users/groups/services' at module 'syscollector'` | `ossec.conf` bản mới còn sót sau downgrade | [C.2](#c2) |
| 11 | `Invalid element ... 'directories'` → `No client configured` | Đặt sai chỗ block `<directories>` (FIM) trong `ossec.conf` | [C.3](#c3) |
| 12 | `Connection refused` `[192.168.56.10]:1514` (thoáng qua) | Manager chưa sẵn sàng lúc agent thử — tự hết | [C.4](#c4) |
| 13 | `File for passwords not found: rockyou.txt` (hydra) | Chưa cài wordlist | [D.1](#d1) |
| 14 | `MissingEndCurlyBrace` / `AmpersandNotAllowed` khi chạy `.ps1` | File `.ps1` lưu UTF-8 **không BOM** | [E.1](#e1) |
| 15 | Lệnh dán vào terminal bị **tách dòng** → chạy nhầm | Paste multi-line lỗi (sed đứt dòng) | [E.2](#e2) |

---

## Phần A — Mạng & SSH

### <a id="a1"></a>A.1 — SSH vào VM báo `Connection refused` / `timed out`

**Triệu chứng:**

```
ssh: connect to host 192.168.56.20 port 22: Connection timed out
ssh: connect to host 192.168.56.20 port 22: Connection refused
```

**Gốc rễ:** `refused` = SSH server chưa chạy trên VM; `timed out` = sai IP host-only hoặc firewall chặn.

**Khắc phục — chạy trên VM (qua console VirtualBox):**

```bash
sudo systemctl enable --now ssh
sudo systemctl status ssh
ip addr show enp0s8
```

✅ **Verify:** `enp0s8` phải có `inet 192.168.56.10/24` (VM1) hoặc `.20/24` (VM2); `ss -tlnp | grep :22` thấy sshd lắng nghe.

### <a id="a2"></a>A.2 — Netplan báo lỗi cú pháp YAML

**Triệu chứng:**

```
01-lab-network.yaml:8:9: Error in network definition: 192.168.56.10/24
01-lab-network.yaml:5:7: Error in network definition: unknown key 'dhcp04'
```

**Gốc rễ:** YAML sai indent / gõ nhầm key (`dhcp04` thay vì `dhcp4`). Netplan cực kỳ nhạy với khoảng trắng.

**Khắc phục:** netplan dùng **2 space**, không tab; địa chỉ phải nằm dưới `addresses:` dạng list:

```yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.56.10/24
```

```bash
sudo netplan try   # áp tạm, tự rollback sau 120s nếu mất mạng
sudo netplan apply
```

### <a id="a3"></a>A.3 — `permission denied` khi sửa file trong `/var/ossec/` qua VSCode Remote-SSH

**Triệu chứng:** Mở `ossec.conf`/`local_rules.xml` bằng Remote-SSH rồi Save → `permission denied`.

**Gốc rễ:** Remote-SSH mở file bằng quyền **user thường**, nhưng `/var/ossec/` thuộc root/`wazuh`.

**Khắc phục:** sửa các file trong `/var/ossec/` bằng `sudo` trên terminal (`sudo nano`/`sudo vim`), **không** dùng editor GUI. Nếu cần dùng VSCode, cài extension cho phép save-as-sudo, hoặc sửa ở thư mục có quyền rồi `sudo cp` đè vào.

---

## Phần B — Cài Wazuh Server (VM1)

> Đây là khu vực tốn nhiều thời gian nhất. **Gốc rễ chung: VM tạo 20GB trong khi doc yêu cầu ≥ 40GB** → cạn đĩa/inode đúng bước `wazuh-dashboard`, kéo theo dpkg half-installed và một chuỗi lỗi phái sinh.

### <a id="b1"></a>B.1 — dpkg pre-install script fail (exit 127)

**Triệu chứng:**

```
dpkg: error processing archive .../wazuh-manager_4.14.5-1_amd64.deb (--unpack):
 new wazuh-manager package pre-installation script subprocess returned error exit status 127
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

**Gốc rễ:** lần cài trước đứt giữa chừng → package ở trạng thái half-installed; exit 127 = command not found trong maintainer script.

**Khắc phục:**

```bash
sudo dpkg --configure -a
sudo apt-get -f install
```

Nếu vẫn fail → chuyển sang [B.4](#b4) (dọn sạch dpkg bằng stub script, **không** xóa `/var/lib/dpkg/info/*`).

### <a id="b2"></a>B.2 — `Port 1515/55000 in use` hoặc `already installed`

**Triệu chứng:**

```
ERROR: Port 1515 is being used by another process.
ERROR: Wazuh manager already installed.
```

**Gốc rễ:** `wazuh-install.sh` chỉ check package qua dpkg — tàn dư lần cài trước khiến nó tưởng đã cài / port còn bị giữ.

**Khắc phục — kiểm tra thực trạng rồi dọn:**

```bash
dpkg -l | grep -i wazuh
sudo ss -tlnp | grep -E ':1515|:55000'
```

Nếu là lab mới chưa có dữ liệu quý → dọn sạch ([B.4](#b4)) rồi cài lại với cờ `-o` (overwrite).

### <a id="b3"></a>B.3 — ⭐ `No space left on device` khi giải nén `wazuh-dashboard`

**Triệu chứng:**

```
E: Write error - write (28: No space left on device)
cannot copy extracted data for '.../wazuh-dashboard/.../lodash/fp/wrapperReverse.js' ...
15/06/2026 13:36:14 ERROR: Wazuh dashboard installation failed.
```

…**dù `df -h` báo vẫn còn vài GB trống.**

**Gốc rễ:** Đây là lỗi **nền tảng quan trọng nhất**. `wazuh-dashboard` chứa `node_modules` với **hàng trăm nghìn file tí hon** → cạn **cả byte lẫn inode**. Ổ ext4 có số inode cố định lúc format → còn byte vẫn fail nếu hết inode. VM tạo 20GB là quá nhỏ.

**Chẩn đoán đúng (làm NGAY khi thấy "No space" lần đầu):**

```bash
df -h /        # byte
df -i /        # inode — chú ý cột IUse% (gần 100% = cạn inode)
lsblk
sudo vgs       # xem VFree
```

**Khắc phục dứt điểm — nới LV root (thường KHÔNG cần đụng VirtualBox/reboot):**

```bash
# Nếu vgs cho thấy VFree > 0 (Ubuntu installer hay chỉ cấp ~1/2 đĩa cho LV root):
sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
```

Cờ `-r` chạy `resize2fs` luôn → **tăng cả dung lượng lẫn inode**.

✅ **Verify:** `df -h /` Size ~38–39G, Avail ~28G; `df -i /` IUse% chỉ vài %.

> Nếu `VFree = 0` (đĩa vật lý thật cũng đầy) → mới phải tăng VDI trong VirtualBox rồi `growpart` + `lvextend` + `resize2fs`. Đừng tạo thêm `/swapfile` để "lấy chỗ" — Ubuntu 22.04 đã có sẵn `/swap.img` ~3.8G, swap thừa chỉ phí đĩa.

### <a id="b4"></a>B.4 — Manager không start / install "xong" trong 2 giây

**Triệu chứng:**

```
15/06/2026 13:12:12 ERROR: wazuh-manager could not be started.
WARNING: The Wazuh manager package could not be removed
```

Manager báo "install finished" chỉ sau **2 giây** (bình thường ~6 phút).

**Gốc rễ:** Đây là **hậu quả của việc xóa `/var/lib/dpkg/info/wazuh-manager.*`** ở lần purge ép trước → hỏng metadata dpkg → dpkg tưởng đã cài nên **không giải nén file**, đồng thời cũng không gỡ được.

**Khắc phục — tạo lại maintainer script rỗng để dpkg purge trót lọt (KHÔNG xóa info):**

```bash
# 1. Đảm bảo không có apt/dpkg đang chạy
ps aux | grep -E "apt|dpkg" | grep -v grep

# 2. Gỡ lock sót
sudo rm -f /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock

# 3. Tạo stub script (exit 0) cho mọi package wazuh để dpkg có cái để chạy
for p in wazuh-manager wazuh-indexer wazuh-dashboard filebeat; do
  for s in preinst postinst prerm postrm; do
    printf '#!/bin/sh\nexit 0\n' | sudo tee /var/lib/dpkg/info/$p.$s >/dev/null
    sudo chmod 755 /var/lib/dpkg/info/$p.$s
  done
done

# 4. Purge ép
sudo dpkg --remove --force-remove-reinstreq wazuh-manager wazuh-indexer wazuh-dashboard filebeat 2>/dev/null
sudo dpkg --purge --force-all wazuh-manager wazuh-indexer wazuh-dashboard filebeat
```

✅ **Verify:** `dpkg -l | grep -i wazuh` **không in gì** và `sudo dpkg -s wazuh-manager` báo `not-installed`. Sạch hẳn rồi mới cài lại.

> ⚠️ **Bài học:** purge package wazuh hỏng thì dùng **stub script `exit 0`**, **tuyệt đối không** `rm /var/lib/dpkg/info/<pkg>.*` — làm hỏng metadata, sinh lỗi mới (`wazuh-keystore: No such file`), tốn thêm nhiều turn.

### <a id="b5"></a>B.5 — VM `aborted` / crash lúc power-on hoặc đang cài

**Triệu chứng:**

```
VERR_UNRESOLVED_ERROR / E_FAIL (0x80004005)
NEM: Destroying partition
```

VM ở trạng thái `aborted`; hoặc crash đúng lúc cài.

**Gốc rễ:** (a) xung đột **VirtualBox ↔ Hyper-V** (`NEM`), hoặc (b) **OOM** — all-in-one trên VM 4GB (indexer JVM ~1.5–2GB + manager + build dashboard) ngốn RAM đỉnh.

**Khắc phục:**

```bash
# Trong guest sau khi bật lại VM — kiểm tra có bị OOM-killer không:
journalctl -k -b -1 | grep -iE "out of memory|oom|killed process" | tail -n 20
```

- Trạng thái `aborted` + `VERR_UNRESOLVED_ERROR` thường **tự hết sau khi khởi động lại máy Windows** (giải phóng RAM, reset driver VBox).
- Nếu là OOM: tăng RAM VM1 tạm lên **5–6GB** (host 8GB, đóng browser/IDE), đảm bảo swap bật, rồi cài lại.
- Nếu crash do Hyper-V: tắt Hyper-V/WSL2/Hyper-V Platform trong "Turn Windows features on/off" rồi reboot.

---

## Phần C — Kết Nối Agent (Ubuntu VM2 & Windows)

### <a id="c1"></a>C.1 — ⭐ `Agent version must be lower or equal to manager version`

**Triệu chứng (`/var/ossec/logs/ossec.log`):**

```
wazuh-agentd: ERROR: Agent version must be lower or equal to manager version (from manager)
wazuh-agentd: ERROR: Unable to add agent (from manager)
```

Agent **không bao giờ Active**, dù mạng/enroll tới được manager.

**Gốc rễ:** repo `4.x` mặc định kéo bản **mới nhất** (vd 4.14) trong khi manager ghim `4.9.2`. Wazuh từ chối agent có version **> manager**.

**Khắc phục — cài đúng version rồi giữ (hold):**

```bash
sudo apt-get install -y wazuh-agent=4.9.2-1
sudo apt-mark hold wazuh-agent
dpkg -l wazuh-agent | grep ^ii   # xác nhận đúng 4.9.2
```

✅ **Verify:** log hết dòng version mismatch, xuất hiện `Connected to the server`; agent hiện **Active** trên Dashboard.

### <a id="c2"></a>C.2 — `No such tag 'users/groups/services' at module 'syscollector'`

**Triệu chứng (sau khi downgrade agent về 4.9.2):**

```
wazuh-modulesd: ERROR: No such tag 'users' at module 'syscollector'.
wazuh-modulesd: ERROR: (1202): Configuration error at 'etc/ossec.conf'.
wazuh-modulesd: Configuration error. Exiting
Job for wazuh-agent.service failed ...
```

**Gốc rễ:** khi hạ version, `ossec.conf` của bản mới (4.14) **còn sót** lại (dpkg giữ conffile bạn đã sửa). Trong block `<syscollector>` có các tag mới (`users`/`groups`/`services`/`browser_extensions`) mà 4.9.2 **không hiểu** → modulesd từ chối start.

**Khắc phục — backup rồi gỡ sạch các tag con của syscollector trong một phát:**

```bash
sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak-414
sudo sed -i -E '/<(users|groups|services|browser_extensions|hotfixes|ports|processes|packages|os|hardware|network)>/d' /var/ossec/etc/ossec.conf
sudo systemctl restart wazuh-agent
```

> Đây chỉ là các công tắc thu thập inventory — bỏ đi nghĩa là dùng mặc định, **không ảnh hưởng lab**. Cách sạch hơn: reset về `ossec.conf` mặc định của 4.9.2.

✅ **Verify:** `sudo grep -nE 'syscollector' /var/ossec/logs/ossec.log | tail` chỉ thấy `Evaluation finished` (INFO), không còn `No such tag`.

### <a id="c3"></a>C.3 — `Invalid element in the configuration: 'directories'` → `No client configured`

**Triệu chứng:**

```
wazuh-agentd: ERROR: (1230): Invalid element in the configuration: 'directories'.
wazuh-agentd: ERROR: (1202): Configuration error at 'etc/ossec.conf'.
wazuh-agentd: ERROR: (1215): No client configured. Exiting.
```

**Gốc rễ:** block `<directories>` của FIM bị đặt **sai chỗ** — phải nằm trong `<syscheck>`, không phải trực tiếp dưới `<ossec_config>`. Cấu hình lỗi khiến agent bỏ luôn cả block `<client>` → "No client configured".

**Khắc phục — đặt `<directories>` đúng trong `<syscheck>`:**

```xml
<syscheck>
  <directories realtime="yes" check_all="yes">/root/test-fim</directories>
</syscheck>
```

```bash
sudo systemctl restart wazuh-agent
sudo grep -iE "error" /var/ossec/logs/ossec.log | tail -n 10
```

✅ **Verify:** không còn dòng ERROR; log có `Connected to the server`.

### <a id="c4"></a>C.4 — `Connection refused [192.168.56.10]:1514` (thoáng qua)

**Triệu chứng:**

```
wazuh-agentd: ERROR: (1216): Unable to connect to '[192.168.56.10]:1514/tcp': 'Connection refused'.
```

…rồi vài chục giây sau lại `Connected to the server`.

**Gốc rễ:** manager chưa sẵn sàng (đang khởi động) đúng lúc agent thử kết nối. **Tự hết**, không phải lỗi cấu hình.

**Khi nào cần lo:** nếu `Connection refused` **kéo dài liên tục** → kiểm tra manager thật sự nghe port:

```bash
# Trên VM1 (manager):
sudo ss -tlnp | grep -E ':1514|:1515'
sudo systemctl status wazuh-manager
```

---

## Phần D — Chạy Lab

### <a id="d1"></a>D.1 — hydra báo `File for passwords not found: rockyou.txt`

**Triệu chứng:**

```
[ERROR] File for passwords not found: /usr/share/wordlists/rockyou.txt
```

**Gốc rễ:** rockyou chưa được cài/giải nén. Lab brute-force **không cần** wordlist khủng — mục tiêu chỉ là sinh chuỗi SSH failed login cho Wazuh bắt.

**Khắc phục — tạo wordlist nhỏ tại chỗ (dòng cuối là pass đúng để hydra báo "found"):**

```bash
cat > /tmp/lab-wordlist.txt <<'EOF'
123456
password
admin
letmein
qwerty
labpassword123
EOF

hydra -l testuser -P /tmp/lab-wordlist.txt ssh://192.168.56.20 -t 4
```

✅ **Verify:** hydra tìm ra `testuser:labpassword123`; trên manager sinh alert SSH failed login.

**Rule sinh ra (đối chiếu khi xem alert):** MITRE **T1110 — Brute Force**

| rule_id | Mô tả | Level |
|---------|-------|-------|
| `5710` | sshd: attempt to login using a non-existent / invalid user | 5 |
| `5760` | sshd: authentication failed (từng lần thử sai) | 5 |
| `5503` | PAM: User login failed | 5 |
| `5712` | sshd: brute force (nhiều fail trong timeframe) | 10 |

```bash
# Đối chiếu log gốc trên VM2:
sudo grep "Failed password" /var/log/auth.log | tail -n 10
```

---

## Phần E — Script & Môi Trường

### <a id="e1"></a>E.1 — `MissingEndCurlyBrace` / `AmpersandNotAllowed` khi chạy `.ps1`

**Triệu chứng:**

```
Missing closing '}' in statement block or type definition.
FullyQualifiedErrorId : MissingEndCurlyBrace
FullyQualifiedErrorId : AmpersandNotAllowed
```

…dù mắt thường thấy `{` `}` khớp nhau hoàn toàn.

**Gốc rễ:** file `.ps1` có emoji/tiếng Việt lưu **UTF-8 không BOM**. PowerShell 5.1 đọc file không BOM theo codepage ANSI → ký tự multibyte hỏng, lệch dấu nháy → lỗi parser **giả**.

**Khắc phục — thêm BOM cho file `.ps1`:**

```bash
printf '\xEF\xBB\xBF' | cat - setup-win-agent.ps1 > t && mv t setup-win-agent.ps1
```

> ⚠️ Ngược lại: file `.sh` **không** được có BOM (bash sẽ lỗi shebang). `&` là call operator chỉ đặt **đầu** lệnh (`& "path.ps1"`); nối 2 lệnh dùng `;`, không phải `&`.

### <a id="e2"></a>E.2 — Lệnh dán vào terminal bị tách dòng, chạy nhầm

**Triệu chứng:** dán lệnh `sed ... /var/ossec/etc/ossec.conf` nhưng terminal cắt thành 2 dòng → `/var/ossec/etc/ossec.conf` chạy thành lệnh riêng → `Permission denied`, còn `sed` chưa hề chạy.

**Gốc rễ:** paste multi-line bị xuống dòng giữa lệnh (hay gặp với lệnh dài qua SSH/console).

**Khắc phục:** với lệnh quan trọng, **gõ trên 1 dòng** hoặc bọc trong heredoc/script file. Sau khi chạy, **verify bằng grep** xem lệnh đã ăn chưa thay vì tin là xong:

```bash
# Ví dụ kiểm tra sed đã gỡ tag chưa:
grep -E '<users>|<groups>' /var/ossec/etc/ossec.conf || echo "OK - đã gỡ sạch"
```

---

## ❓ Khi gặp lỗi mới — quy trình chuẩn

1. **Soi nền tảng trước:** `df -h /; df -i /; free -h; ss -tlnp`
2. **Đọc log gốc, không đoán:**
   - Cài server: `sudo tail -100 /var/log/wazuh-install.log | grep -iE "error|fail|no space"`
   - Agent: `sudo tail -50 /var/ossec/logs/ossec.log`
   - VM crash: `journalctl -k -b -1 | grep -i oom`
3. **Tìm gốc, không vá triệu chứng** — một gốc thường hiện qua nhiều lớp lỗi khác nhau.
4. **Backup trước khi sửa config**, verify bằng số liệu sau khi sửa.
