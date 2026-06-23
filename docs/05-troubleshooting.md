# 🛠️ Troubleshooting — Lỗi Tiêu Biểu & Cách Khắc Phục

Hai lỗi **đáng nhớ nhất** khi dựng lab này — một lỗi hạ tầng lúc cài server, một lỗi kết nối agent. Cả hai đều minh họa nguyên tắc: **soi nền tảng/đối chiếu version trước khi nghi config**.

> 💡 Nguyên tắc xuyên suốt (skill `security-mindset`): khi gặp lỗi lạ, chạy ngay `df -h /; df -i /; free -h; ss -tlnp` — một lệnh tổng quan tiết kiệm hàng giờ đoán mò.

## 📋 Bảng tra nhanh

| # | Triệu chứng (thông báo lỗi) | Gốc rễ | Mục |
|---|------------------------------|--------|-----|
| 1 | `No space left on device` lúc giải nén `wazuh-dashboard` | **Hết đĩa HOẶC hết inode** (ổ 20G quá nhỏ) | [1](#t1) |
| 2 | `Agent version must be lower or equal to manager` + `Unable to add agent` | Agent > manager (repo 4.x kéo bản mới) | [2](#t2) |

---

## <a id="t1"></a>1 — `No space left on device` khi giải nén `wazuh-dashboard`

**Triệu chứng:**

```
E: Write error - write (28: No space left on device)
cannot copy extracted data for '.../wazuh-dashboard/.../lodash/fp/wrapperReverse.js' ...
15/06/2026 13:36:14 ERROR: Wazuh dashboard installation failed.
```

…**dù `df -h` báo vẫn còn vài GB trống.**

**Gốc rễ:** `wazuh-dashboard` chứa `node_modules` với **hàng trăm nghìn file tí hon** → cạn **cả byte lẫn inode**. Ổ ext4 có số inode cố định lúc format → còn byte vẫn fail nếu hết inode. VM tạo 20GB là quá nhỏ (doc yêu cầu ≥ 40GB).

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

---

## <a id="t2"></a>2 — `Agent version must be lower or equal to manager version`

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

---

## ❓ Khi gặp lỗi mới — quy trình chuẩn

1. **Soi nền tảng trước:** `df -h /; df -i /; free -h; ss -tlnp`
2. **Đọc log gốc, không đoán:**
   - Cài server: `sudo tail -100 /var/log/wazuh-install.log | grep -iE "error|fail|no space"`
   - Agent: `sudo tail -50 /var/ossec/logs/ossec.log`
3. **Tìm gốc, không vá triệu chứng** — một gốc thường hiện qua nhiều lớp lỗi khác nhau.
4. **Backup trước khi sửa config**, verify bằng số liệu sau khi sửa.
