# 🛡️ Custom Rules & Báo Cáo

> Thời gian ước tính: **4–5 tiếng**
> Điều kiện: đã chạy xong 4 [bài lab thực hành](03-lab-exercises.md).

---

## Phần A — Viết Custom Rule

### Bước 1: Hiểu cơ chế

- Decoder (`/var/ossec/etc/decoders/local_decoder.xml`) tách field từ log thô.
- Rule (`/var/ossec/etc/rules/local_rules.xml`) khớp field → sinh alert + level.
- Custom rule dùng ID từ **100000 trở lên** (vùng dành cho user).

### Bước 2: Viết rule override — nâng mức brute force theo nguồn

Thay vì lặp lại rule mặc định `5763`, ta viết một **override rule**: chạy sau `5763` và **nâng severity** khi nguồn tấn công là host lab đã biết. Đây là việc default **không** làm được.

```xml
<!-- /var/ossec/etc/rules/local_rules.xml (trên VM1) -->
<group name="local,syslog,sshd,">
  <rule id="100001" level="13">
    <if_sid>5763</if_sid>
    <srcip>192.168.56.20</srcip>
    <description>Custom: SSH brute force tu host lab da biet (192.168.56.20)</description>
    <mitre>
      <id>T1110</id>
    </mitre>
  </rule>
</group>
```

> 💡 **Khác default ở đâu:** `5763` (level 10) báo brute force cho **mọi** nguồn; `100001` chỉ kích thêm khi `srcip` khớp host quan tâm và nâng lên **level 13**. `if_sid 5763` = chạy *sau* khi 5763 đã fire → cả hai cùng hiện. Bản rule sẵn dùng: [`configs/local_rules.xml`](../configs/local_rules.xml).

```bash
sudo cp /var/ossec/etc/rules/local_rules.xml /var/ossec/etc/rules/local_rules.xml.bak
sudo /var/ossec/bin/wazuh-analysisd -t && echo "CONFIG OK"   # test cú pháp TRƯỚC khi restart
sudo systemctl restart wazuh-manager
```

✅ **Verify:** trigger brute force từ VM2 (`hydra` 2 lần cho đủ ngưỡng `5763`), rồi:
- Dashboard → *Threat Hunting*, search `rule.id : 100001` → thấy alert **level 13**, `srcip: 192.168.56.20`, `rule.mitre.id: T1110`.
- So sánh trực quan: search `rule.id : (5763 OR 100001)` → mỗi lần `5763` (level 10) kéo theo một `100001` (level 13).

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
| 2. Hạ tầng | Tóm tắt hạ tầng — VM, network, agent status |
| 3. Kết quả 4 lab | Mỗi lab: mô tả + rule ID + screenshot alert |
| 4. Custom rule | Rule/decoder đã viết + kết quả `wazuh-logtest` |
| 5. Kết luận | Bài học, hạn chế, hướng mở rộng |

### Bước 5: Thu thập bằng chứng

- Lưu screenshot vào `screenshots/` đặt tên theo lab: `lab1-bruteforce.png`...
- Backup config đã chỉnh vào `configs/` (ossec.conf, local_rules.xml, local_decoder.xml).

✅ **Verify:** Mỗi lab có ít nhất 1 screenshot + 1 rule ID tương ứng.

---

## ✅ Checklist Custom Rule & Báo Cáo

- [ ] Custom rule `100001` khớp qua `wazuh-logtest`
- [ ] (Tùy chọn) Custom decoder tách đúng field
- [ ] Backup config vào `configs/`
- [ ] Screenshot đầy đủ trong `screenshots/`
- [ ] Báo cáo hoàn chỉnh 5 mục

**Hoàn thành → kết thúc lab Wazuh SIEM! 🎉**

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
