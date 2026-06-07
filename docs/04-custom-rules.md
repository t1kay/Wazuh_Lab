# 📅 Ngày 3 — Custom Rules & Báo Cáo

> Thời gian ước tính: **4–5 tiếng**
> Điều kiện: đã chạy xong 4 lab [Ngày 2](03-lab-exercises.md).

---

## Phần A — Viết Custom Rule

### Bước 1: Hiểu cơ chế

- Decoder (`/var/ossec/etc/decoders/local_decoder.xml`) tách field từ log thô.
- Rule (`/var/ossec/etc/rules/local_rules.xml`) khớp field → sinh alert + level.
- Custom rule dùng ID từ **100000 trở lên** (vùng dành cho user).

### Bước 2: Viết rule cảnh báo brute force nâng cao

```xml
<!-- /var/ossec/etc/rules/local_rules.xml (trên VM1) -->
<group name="local,syslog,sshd,">
  <rule id="100001" level="12" frequency="8" timeframe="60">
    <if_matched_sid>5710</if_matched_sid>
    <description>Custom: SSH brute force - 8 lần thất bại trong 60s</description>
    <mitre>
      <id>T1110</id>
    </mitre>
  </rule>
</group>
```

```bash
sudo systemctl restart wazuh-manager
```

✅ **Verify:** Dùng `wazuh-logtest` để kiểm tra rule khớp:
```bash
sudo /var/ossec/bin/wazuh-logtest
# Dán một dòng log auth.log "Failed password ... invalid user"
# Output phải hiện Rule id: 100001 (sau khi đủ frequency)
```

---

### Bước 3: Custom decoder (tùy chọn — cho app log riêng)

```xml
<!-- /var/ossec/etc/decoders/local_decoder.xml -->
<decoder name="myapp">
  <program_name>myapp</program_name>
</decoder>
<decoder name="myapp-login">
  <parent>myapp</parent>
  <regex>user (\S+) failed from (\d+.\d+.\d+.\d+)</regex>
  <order>user,srcip</order>
</decoder>
```

✅ **Verify:** `wazuh-logtest` tách đúng field `user` và `srcip`.

---

## Phần B — Tài Liệu Báo Cáo

### Bước 4: Cấu trúc báo cáo

| Mục | Nội dung |
|-----|----------|
| 1. Tổng quan | Mục tiêu lab, kiến trúc (kèm sơ đồ từ README) |
| 2. Hạ tầng | Tóm tắt Ngày 1 — VM, network, agent status |
| 3. Kết quả 4 lab | Mỗi lab: mô tả + rule ID + screenshot alert |
| 4. Custom rule | Rule/decoder đã viết + kết quả `wazuh-logtest` |
| 5. Kết luận | Bài học, hạn chế, hướng mở rộng |

### Bước 5: Thu thập bằng chứng

- Lưu screenshot vào `screenshots/` đặt tên theo lab: `lab1-bruteforce.png`...
- Backup config đã chỉnh vào `configs/` (ossec.conf, local_rules.xml, local_decoder.xml).

✅ **Verify:** Mỗi lab có ít nhất 1 screenshot + 1 rule ID tương ứng.

---

## ✅ Checklist Cuối Ngày 3

- [ ] Custom rule `100001` khớp qua `wazuh-logtest`
- [ ] (Tùy chọn) Custom decoder tách đúng field
- [ ] Backup config vào `configs/`
- [ ] Screenshot đầy đủ trong `screenshots/`
- [ ] Báo cáo hoàn chỉnh 5 mục

**Hoàn thành → kết thúc lab Wazuh SIEM 3 ngày! 🎉**

---

## ❓ Troubleshooting

### Rule không khớp
```bash
# Test trực tiếp, xem rule nào bắt
sudo /var/ossec/bin/wazuh-logtest -v
# Kiểm tra lỗi cú pháp XML khi khởi động manager
sudo tail -f /var/ossec/logs/ossec.log | grep -i error
```

### Manager không start sau khi sửa rule
```bash
# Thường do XML sai cú pháp — kiểm tra lại thẻ đóng/mở
sudo /var/ossec/bin/wazuh-control restart
```
