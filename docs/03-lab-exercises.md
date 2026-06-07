# 📅 Ngày 2 — 4 Bài Lab Thực Hành

> Thời gian ước tính: **5–6 tiếng**
> Điều kiện: đã hoàn thành [Ngày 1](02-installation.md) — 2 agent Active, dashboard truy cập được.

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

✅ **Verify:** Dashboard → *Threat Hunting* / *Security Events*, lọc agent `ubuntu-agent`:
- Rule `5710` (attempt to login using a non-existent user) / `5712` (sshd brute force) xuất hiện.
- Level ≥ 10 cho cụm nhiều lần thất bại liên tiếp.

> 💡 Ghi lại rule ID + screenshot để dùng cho báo cáo Ngày 3.

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

```xml
<!-- Trên VM1 (Manager): /var/ossec/etc/ossec.conf -->
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5712</rules_id>
  <timeout>180</timeout>
</active-response>
```

```bash
# Trên VM1 áp dụng
sudo systemctl restart wazuh-manager
# Trên VM2: lặp lại brute force như Lab 1 để kích hoạt
```

✅ **Verify:**
- Dashboard hiện alert `active-response` / rule `651` (host blocked).
- Trên agent bị block: `sudo iptables -L -n` thấy IP attacker bị DROP (tự gỡ sau timeout 180s).

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

## ✅ Checklist Cuối Ngày 2

- [ ] Lab 1: alert brute force SSH xuất hiện (rule 5710/5712)
- [ ] Lab 2: sự kiện FIM added/modified/deleted
- [ ] Lab 3: Active Response chặn được IP attacker
- [ ] Lab 4: Vulnerability Detection liệt kê CVE
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
```bash
sudo tail -f /var/ossec/logs/active-responses.log   # trên agent
# Kiểm tra rule_id khớp với rule thực tế đang khớp
```
