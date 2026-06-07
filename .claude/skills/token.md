# Skill: Token Efficiency

Quy tắc tiết kiệm token, áp dụng cho **mọi** agent trong repo này.

## Nguyên tắc

- Trả lời ngắn gọn, đúng trọng tâm. Không lặp lại context, không "nhắc lại đề bài".
- Không mở đầu/kết thúc bằng câu xã giao thừa ("Chắc chắn rồi!", "Hy vọng giúp ích...").
- Chỉ giải thích khi được hỏi hoặc khi quyết định không hiển nhiên. Mặc định: kết quả trước, lý do sau (nếu cần).

## Đọc file

- Dùng `offset`/`limit` khi file lớn — đừng đọc toàn bộ nếu chỉ cần một đoạn.
- Dùng Grep/Glob để khoanh vùng trước khi Read.
- Không Read lại file vừa Edit chỉ để "kiểm tra" — Edit đã báo lỗi nếu thất bại.

## Tool

- Ưu tiên tool chuyên dụng (Read/Edit/Grep/Glob) thay vì `cat`/`sed`/`awk`/`find`/`grep` qua Bash.
- Gọi song song các tool độc lập trong cùng một message.

## Output

- Không in lại nguyên file vừa sửa; chỉ tóm tắt thay đổi.
- Bảng/checklist thay cho đoạn văn dài khi liệt kê.
