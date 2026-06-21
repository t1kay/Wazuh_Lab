# 🎬 Kịch Bản Quay Demo — Phần 1: Detection với Rule Mặc Định

> Thời lượng quay ước tính: **7–9 phút** (nên quay rời từng cảnh rồi ghép).
> Phạm vi: phần **TRƯỚC khi viết custom rule** — giới thiệu kiến trúc + chạy 4 lab Ngày 2 với ruleset mặc định.
> Phần custom rule (rule `100001`) sẽ là kịch bản riêng (Phần 2) → xem [04-custom-rules.md](04-custom-rules.md).

---

## 🎯 Mục tiêu video

Cho người xem thấy **Wazuh phát hiện tấn công ngay với rule mặc định** qua 4 kịch bản thật, tạo nền để Phần 2 chứng minh giá trị của custom rule.

## ⚙️ Chuẩn bị TRƯỚC khi bấm quay (không quay phần này)

Làm 1 lần, đảm bảo mọi thứ chạy được rồi mới quay — **không debug trên camera**.

```bash
# VM1 (Manager) — xác nhận 2 agent Active
sudo /var/ossec/bin/agent_control -l
# VM1 — manager đang chạy
sudo systemctl is-active wazuh-manager
# VM2 (Agent) — wordlist brute force sẵn sàng
ls ~/pw.txt || printf 'wrong1\nwrong2\nwrong3\nwrong4\nlabpassword123\n' > ~/pw.txt
```

✅ **Verify:** cả 2 agent `Active`, manager `active`, `~/pw.txt` tồn tại.

**Dọn trạng thái cho dashboard sạch (chạy ngay trước khi quay):**

```bash
# VM2 — xóa rule iptables DROP cũ còn sót từ lần test
sudo iptables -F
```

> 💡 Mẹo quay: mở sẵn **2 cửa sổ terminal** (VM1 và VM2) + **1 tab trình duyệt** dashboard `https://192.168.56.10` đã đăng nhập. Font terminal cỡ lớn cho dễ đọc khi quay.

---

## 🎬 Cảnh 1 — Giới thiệu kiến trúc (~1 phút)

**Hình ảnh:** sơ đồ 3 máy (lấy từ README) + màn hình dashboard tổng quan.

**Lời thoại gợi ý:**
> "Đây là lab SIEM Wazuh gồm 3 máy: VM1 là Wazuh Server (Manager + Indexer + Dashboard), VM2 là Ubuntu Agent kiêm máy tấn công, và một Windows Agent. Tất cả nằm trong mạng host-only `192.168.56.0/24`. Mình sẽ demo Wazuh phát hiện 4 loại tấn công khác nhau."

**Thao tác:** mở dashboard → trang **Agents**, chỉ cho thấy 2–3 agent đang **Active**.

---

## 🎬 Cảnh 2 — Lab 1: Phát hiện Brute Force SSH (~2 phút)

**Mục tiêu thể hiện:** tấn công đoán mật khẩu → Wazuh tự gom thành 1 alert brute force.

**Bước 1 — VM2: tấn công SSH:**

```bash
hydra -l testuser -P ~/pw.txt ssh://192.168.56.20 -t 4
```

**Lời thoại:**
> "Mình dùng Hydra brute force SSH vào chính VM2. Hydra thử lần lượt các mật khẩu sai rồi tới mật khẩu đúng."

**Bước 2 — Dashboard:** vào **Threat Hunting**, lọc agent `ubuntu-agent`, ô search gõ:

```
rule.id : 5763
```

✅ **Trỏ vào màn hình, nói rõ:**

| Rule | Ý nghĩa | Level |
|------|---------|-------|
| `5760` | Mỗi lần login thất bại | 5 |
| `5763` | **Brute force** — đủ ngưỡng nhiều lần fail | 10 |
| `40112` | Nhiều lần fail **rồi thành công** — tài khoản bị chiếm | 12 |

**Lời thoại:**
> "Wazuh không chỉ ghi từng lần fail, mà tự nhận ra chuỗi fail là brute force — rule 5763 level 10. Đáng chú ý nhất là rule 40112: nhiều lần thất bại rồi đăng nhập thành công, nghĩa là kẻ tấn công đã đoán đúng mật khẩu. Toàn bộ được gắn nhãn MITRE T1110."

---

## 🎬 Cảnh 3 — Lab 2: File Integrity Monitoring (~1.5 phút)

**Mục tiêu thể hiện:** thay đổi file nhạy cảm → Wazuh báo ngay.

**Bước 1 — VM2: tạo / sửa / xóa file trong thư mục đang giám sát:**

```bash
sudo touch /root/test-fim/secret.conf
echo "changed by attacker $(date)" | sudo tee -a /root/test-fim/secret.conf
sudo rm /root/test-fim/secret.conf
```

**Lời thoại:**
> "Mình giả lập kẻ tấn công tạo, sửa rồi xóa một file cấu hình trong thư mục được giám sát."

**Bước 2 — Dashboard:** **Threat Hunting**, lọc `ubuntu-agent`, ô search:

```
rule.id : (553 OR 554 OR 550)
```

✅ **Trỏ màn hình:** `554` (added) → `550` (modified) → `553` (deleted).

**Lời thoại:**
> "Mỗi thao tác trên file sinh đúng một sự kiện FIM tương ứng — thêm, sửa, xóa. Đây là cách phát hiện kẻ tấn công cài backdoor hoặc sửa file hệ thống."

---

## 🎬 Cảnh 4 — Lab 3: Active Response tự động chặn IP (~2 phút)

**Mục tiêu thể hiện:** không chỉ phát hiện — Wazuh **tự phản ứng**, chặn IP tấn công.

**Bước 1 — VM2: xác nhận chưa có chặn (cho người xem thấy "trước"):**

```bash
sudo iptables -L -n | grep 192.168.56.20
```

> Không in ra gì = chưa bị chặn. (Đã `iptables -F` ở bước chuẩn bị.)

**Bước 2 — VM2: tấn công để kích Active Response:**

```bash
hydra -l testuser -P ~/pw.txt ssh://192.168.56.20 -t 4
hydra -l testuser -P ~/pw.txt ssh://192.168.56.20 -t 4
```

**Bước 3 — VM2: cho thấy Wazuh đã tự chặn:**

```bash
sudo tail -n 5 /var/ossec/logs/active-responses.log
sudo iptables -L -n | grep 192.168.56.20
```

✅ **Trỏ màn hình:** `firewall-drop ... "command":"add"` + dòng `DROP ... 192.168.56.20`.

**Bước 4 — Dashboard:** **Threat Hunting**, ô search:

```
rule.id : 651
```

**Lời thoại:**
> "Khi brute force vượt ngưỡng, Manager ra lệnh cho agent tự chặn IP tấn công bằng iptables — đây là Active Response. Rule 651 trên dashboard xác nhận host đã bị chặn. IP sẽ tự được gỡ sau 120 giây, vừa đủ chặn đứng cuộc tấn công."

---

## 🎬 Cảnh 5 — Lab 4: Vulnerability Detection (~1.5 phút)

**Mục tiêu thể hiện:** Wazuh quét lỗ hổng CVE của phần mềm trên agent.

**Thao tác — Dashboard:** mở module **Vulnerability Detection**, chọn agent `ubuntu-agent`.

✅ **Trỏ màn hình:** danh sách CVE, lọc cột **Severity = High/Critical**, chỉ vào 1 CVE kernel (vd `CVE-2024-47673`, package `linux-image-5.15.0-181-generic`).

**Lời thoại:**
> "Wazuh tự đối chiếu danh sách package cài trên agent với cơ sở dữ liệu CVE. Ở đây nó phát hiện hàng loạt lỗ hổng kernel Linux, có cả mức High. Đội vận hành dựa vào danh sách này để ưu tiên vá theo mức độ nghiêm trọng."

---

## 🎬 Cảnh 6 — Chốt phần 1 & dẫn sang custom rule (~0.5 phút)

**Lời thoại gợi ý (cầu nối sang Phần 2):**
> "Vậy là chỉ với ruleset mặc định, Wazuh đã phát hiện brute force, thay đổi file, tự chặn tấn công và quét lỗ hổng. Nhưng trong thực tế, mỗi tổ chức có nhu cầu phát hiện riêng. Phần tiếp theo mình sẽ viết một custom rule để chứng minh có thể tự định nghĩa cảnh báo theo ý mình."

---

## ✅ Checklist trước khi bấm quay

- [ ] 2 agent `Active`, manager `active`
- [ ] `~/pw.txt` tồn tại trên VM2
- [ ] `sudo iptables -F` đã chạy (dashboard/iptables sạch)
- [ ] Thư mục `/root/test-fim` còn được giám sát (`grep test-fim /var/ossec/etc/ossec.conf`)
- [ ] Dashboard đã đăng nhập sẵn, terminal font lớn
- [ ] Vulnerability Detection đã tải xong feed (có CVE hiển thị)

---

## ❓ Sự cố hay gặp khi quay

| Tình huống | Xử lý nhanh |
|---|---|
| Alert chậm lên dashboard | Đợi 10–15s rồi bấm refresh; FIM realtime thường < 15s |
| `iptables` đã trống khi quay Cảnh 4 | Quá 120s timeout — chạy lại 2 lệnh `hydra` rồi quay ngay |
| Vuln Detection trống | Feed CVE chưa tải xong — xem `sudo grep -i vulnerability /var/ossec/logs/ossec.log \| tail`; chờ rồi quay sau |
| Brute force không đủ ngưỡng `5763` | Chạy `hydra` 2 lần liên tiếp cho đủ ≥8 fail/120s |

> Chi tiết khắc phục từng lỗi: xem [05-troubleshooting.md](05-troubleshooting.md).
