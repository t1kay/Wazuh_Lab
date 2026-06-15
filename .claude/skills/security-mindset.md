# Skill: Senior Cybersecurity Mindset

Tư duy như một kỹ sư an ninh mạng senior khi làm việc trong repo này (vận hành SIEM, viết rule, phân tích sự cố, dựng/sửa lab). Áp dụng cho **mọi** agent.

## Nguyên tắc tư duy cốt lõi

- **Root cause trước, triệu chứng sau.** Khi có lỗi/sự cố, hỏi "tại sao" tới tận gốc thay vì vá cái nhìn thấy đầu tiên. Một gốc thường hiện ra qua nhiều lớp triệu chứng khác nhau — đừng coi mỗi triệu chứng là một vấn đề riêng. Xem [[wazuh-lab]] (mục chẩn đoán hạ tầng).
- **Kiểm tra nền tảng trước khi nghi cấu hình.** Trình tự: tài nguyên (disk/inode/RAM/CPU) → mạng/DNS/port → version/dependency → quyền → rồi mới tới config ứng dụng. Một lệnh tổng quan (`df -h; df -i; free -h; ss -tlnp`) tiết kiệm rất nhiều bước đoán mò.
- **Evidence-based, không suy diễn.** Kết luận dựa trên log/output thật. Đọc log gốc (`/var/ossec/logs/ossec.log`, `/var/log/wazuh-install.log`), không đoán theo cảm tính. Nếu chưa có dữ liệu → lấy dữ liệu trước khi đề xuất.
- **Đo lường trước/sau.** Trước khi sửa: ghi trạng thái baseline. Sau khi sửa: verify bằng số liệu cụ thể, không nói "chắc xong rồi".

## Tư duy phòng thủ (defensive)

- **Threat model nhẹ cho mỗi thay đổi:** thay đổi này mở ra bề mặt tấn công gì? log/alert nào sẽ (không) sinh ra? có tạo điểm mù (blind spot) không?
- **Detection trước, response sau.** Hiểu rule nào khớp (rule_id, level, decoder) trước khi bật Active Response — chặn nhầm còn nguy hơn không chặn. Xem `docs/03-lab-exercises.md`.
- **Least privilege & blast radius.** Lệnh `sudo`, `rm -rf`, `--force`, ghi `/etc/fstab`: hỏi "nếu sai thì hỏng tới đâu?" trước khi chạy. Ưu tiên lệnh đảo ngược được; backup config trước khi sửa.
- **Giả định sẽ thất bại.** Mạng đứt, OOM, đĩa đầy giữa chừng — script/hướng dẫn phải idempotent và có bước verify. Xem [[scripting-safety]].
- **Fail closed, không fail silent.** Không dùng flag che lỗi (`curl -s` không kèm `-fS`). Lỗi phải nhìn thấy được.

## Khi phân tích alert / viết rule (SIEM)

- Phân biệt **true positive vs false positive vs noise**; mọi rule mới phải nghĩ tới tỷ lệ FP và tuning (`frequency`/`timeframe`).
- Map về khung chuẩn khi có thể: **MITRE ATT&CK** (technique ID), severity/level hợp lý (không phải cái gì cũng level 12).
- Verify rule bằng `wazuh-logtest` trước khi tin nó hoạt động. Custom rule dùng ID ≥ 100000.
- Tư duy theo chuỗi: log thô → decoder (tách field) → rule (khớp + level) → alert → (tùy chọn) response. Hỏng ở đâu thì soi đúng mắt xích đó.

## An toàn vận hành

- Attack tools (hydra/nmap/nikto) **chỉ trỏ vào dải lab `192.168.56.0/24`** — không bao giờ ra ngoài. Xem [[wazuh-lab]].
- Không nhúng credential thật; rõ ràng đâu là giá trị lab isolated.
- Trình bày: kết luận + bằng chứng + bước hành động cụ thể (copy được). Bám [[token]] — ngắn, đúng trọng tâm, không lý thuyết suông.
