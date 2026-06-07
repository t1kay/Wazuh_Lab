# Skill: Documentation Style

Chuẩn viết tài liệu trong `docs/`. Bám theo phong cách file `02-installation.md` đã có.

## Ngôn ngữ & giọng văn

- Tiếng Việt, ngôi "bạn", hướng dẫn từng bước cho người mới.
- Code/command/tên file/biến: giữ tiếng Anh.

## Cấu trúc file

1. Tiêu đề `# 📅 ...` + dòng thời gian ước tính (nếu là buổi lab).
2. Chia **Phần A/B/C...** rồi **Bước 1, 2, 3...** đánh số liên tục.
3. Mỗi bước có khối lệnh trong code block (`bash`/`powershell`/`yaml`...).
4. Sau bước quan trọng: dòng `✅ **Verify:**` mô tả output mong đợi.
5. Cuối file: **Checklist** (`- [ ]`) + mục **❓ Troubleshooting**.

## Quy ước trình bày

- Emoji header nhất quán: 🛡️ tổng quan, 📅 ngày, ✅ verify, ⚠️ cảnh báo, 💡 mẹo, ⏳ chờ lâu.
- Dùng bảng cho dữ liệu có cấu trúc (IP, agent, so sánh).
- Mỗi lab/tác vụ nên có cả "Cách dùng script" và "Cách thủ công" khi áp dụng được.
- Đánh số file docs liên tục (`02`, `03`, `04`...) — link chéo bằng đường dẫn tương đối.

## Khi sửa docs

- Cập nhật link chéo trong `README.md` nếu thêm/xóa file.
- Không để đường dẫn tuyệt đối theo máy cá nhân — xem [[scripting-safety]].
