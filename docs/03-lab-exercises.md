# 🧪 4 Bài Lab Thực Hành

> Thời gian ước tính: **5–6 tiếng**
> Điều kiện: đã hoàn thành phần [Xây dựng hạ tầng](02-installation.md) — 2 agent Active, dashboard truy cập được.

---

## Lab 1 — Brute Force SSH (Detection)

**Mục tiêu:** Phát hiện tấn công brute force SSH bằng Hydra, xem alert trên Dashboard.

```bash
# Trên VM2 (Ubuntu Agent) — tấn công chính nó qua SSH
hydra -l testuser -P /usr/share/wordlists/rockyou.txt ssh://192.168.56.20 -t 4
# Nếu chưa có wordlist, tạo tạm:
printf 'wrong1\nwrong2\nlabpassword123\n' > ~/pw.txt
hydra -l testuser -P ~/pw.txt ssh://192.168.56.20
```

✅ **Verify:** Dashboard → *Threat Hunting*, lọc agent `ubuntu-agent` — rule thực tế quan sát được trong lab này:

| Rule | Ý nghĩa | Level |
|------|---------|-------|
| `5760` | sshd: authentication failed (từng lần fail lẻ) | 5 |
| `5763` | **sshd: brute force** (đã chạm ngưỡng) | 10 |
| `40112` | Multiple auth failures **followed by a success** (brute force thành công) | 12 |

> 💡 Ghi lại rule ID + screenshot để dùng cho [báo cáo](04-custom-rules.md). Rule chính của lab là **`5763`** (map MITRE **T1110 — Brute Force**); `40112` báo brute force thành công vì wordlist chứa đúng `labpassword123`.

---

## Lab 2 — File Integrity Monitoring (FIM)

**Mục tiêu:** Theo dõi thay đổi file trong thư mục nhạy cảm.

```bash
# Trên VM2 — bật syscheck realtime cho /etc và /root
sudo nano /var/ossec/etc/ossec.conf
# Trong <syscheck> thêm:
#   <directories realtime="yes" check_all="yes">/root/test-fim</directories>
sudo mkdir -p /root/test-fim
sudo systemctl restart wazuh-agent

# Tạo / sửa / xóa file để sinh sự kiện
sudo touch /root/test-fim/secret.conf
echo "changed" | sudo tee -a /root/test-fim/secret.conf
sudo rm /root/test-fim/secret.conf
```

✅ **Verify:** Dashboard → *Integrity Monitoring* (module FIM):
- Sự kiện `added` / `modified` / `deleted` ứng với 3 thao tác trên.
- Rule `550` (modified), `554` (added), `553` (deleted).

---

## Lab 3 — Active Response (Auto-block)

**Mục tiêu:** Tự động chặn IP tấn công bằng Active Response.

> ⚠️ **Gotcha 1:** `ossec.conf` mặc định đã có sẵn block `<active-response>` **nằm trong comment** `<!-- ... -->`. Sửa `rules_id` bên trong comment → manager bỏ qua hoàn toàn (rule fire nhưng AR không chạy). Phải **bỏ dấu `<!--` / `-->`** quanh block.
>
> ⚠️ **Gotcha 2:** dùng đúng `rules_id` thực tế là **`5763`** (không phải 5712). Sai rule_id = không bao giờ trigger.
>
> ⚠️ **Gotcha 3:** AR `firewall-drop` thực thi bằng `iptables`. Nếu VM2 thiếu (`iptables: command not found`) → `sudo apt install -y iptables` trên agent.

```xml
<!-- Trên VM1 (Manager): /var/ossec/etc/ossec.conf — block phải nằm NGOÀI comment -->
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5763</rules_id>
  <timeout>120</timeout>
</active-response>
```

```bash
# Trên VM1: KIỂM TRA cú pháp trước khi restart (tránh manager fail không start)
sudo /var/ossec/bin/wazuh-analysisd -t && echo "CONFIG OK"
sudo systemctl restart wazuh-manager && sudo systemctl is-active wazuh-manager
# Trên VM2: lặp lại brute force như Lab 1 (chạy 2 lần cho chắc) để kích hoạt
```

✅ **Verify:**
- Dashboard hiện rule `651` (host blocked by firewall-drop) trên Manager.
- Trên agent: `sudo tail /var/ossec/logs/active-responses.log` có dòng `firewall-drop ... add ... 192.168.56.20`.
- `sudo iptables -L -n | grep 192.168.56.20` thấy IP attacker bị DROP (tự gỡ sau timeout 120s).

---

## Lab 4 — Vulnerability Scan

**Mục tiêu:** Bật Vulnerability Detection và đọc kết quả CVE.

```xml
<!-- Trên VM1 (Manager): /var/ossec/etc/ossec.conf -->
<vulnerability-detection>
  <enabled>yes</enabled>
</vulnerability-detection>
```

```bash
sudo systemctl restart wazuh-manager
# (tùy chọn) quét mạng từ VM2 để sinh thêm dữ liệu
nmap -sV 192.168.56.10
```

✅ **Verify:** Dashboard → *Vulnerability Detection*:
- Danh sách CVE theo agent, có severity (Critical/High/...).
- Lọc được theo package và CVE ID.

---

## ✅ Checklist Bài Lab

- [x] Lab 1: alert brute force SSH xuất hiện (rule **5763**, kèm 40112 success)
- [x] Lab 2: sự kiện FIM added/deleted (rule 554/553)
- [x] Lab 3: Active Response chặn được IP attacker (rule 5763 → firewall-drop → iptables DROP)
- [x] Lab 4: Vulnerability Detection liệt kê CVE (kernel linux-image, severity High/Medium)
- [ ] Đã chụp screenshot từng lab cho báo cáo

---

## ❓ Troubleshooting

### Không thấy alert SSH
```bash
# Kiểm tra agent có gửi log auth không
sudo tail -f /var/ossec/logs/ossec.log
# Đảm bảo sshd ghi log vào /var/log/auth.log và được localfile theo dõi
```

### Active Response không chặn
Chẩn đoán theo chuỗi (rule fire → AR dispatch → agent execute):
```bash
# 1. Block AR có nằm trong comment <!-- --> không? (gotcha hay gặp)
sudo grep -n -A6 "<active-response>" /var/ossec/etc/ossec.conf
# 2. Manager có kích AR không? (rule 651 = host blocked)
sudo grep -a "Rule: 651" /var/ossec/logs/alerts/alerts.log | tail
# 3. Agent có nhận lệnh không?
sudo tail /var/ossec/logs/active-responses.log            # trên agent
sudo /var/ossec/bin/wazuh-control status | grep execd      # execd phải running
```
> ⚠️ Test cấu hình manager dùng `wazuh-analysisd -t`, **không** phải `wazuh-logtest -t` (version 4.9 không có cờ `-t` cho logtest).
