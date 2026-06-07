# CLAUDE.md

Project guide cho Claude Code và mọi sub-agent trong repo này.
Mọi agent (main + sub-agents qua Task tool) đều phải tuân thủ các skill được import bên dưới.

## Bối cảnh dự án

Lab SIEM Wazuh phục vụ học tập/nghiên cứu bảo mật — gồm **tài liệu** (`docs/`) và **script tự động hóa** (`scripts/`), không phải dự án phần mềm.
Các sự thật cố định (IP, version, đường dẫn, credentials lab) nằm trong skill `wazuh-lab.md` — dùng làm nguồn chuẩn, không bịa.

## Skills luôn áp dụng

Các file dưới đây được nạp vào context của **mọi** phiên làm việc và **mọi** agent:

@.claude/skills/token.md
@.claude/skills/wazuh-lab.md
@.claude/skills/docs-style.md
@.claude/skills/scripting-safety.md

> Khi thêm skill mới vào `.claude/skills/`, hãy thêm một dòng `@.claude/skills/<tên>.md` vào danh sách trên để nó được tự động import.

## Quy tắc chung

- Tuân thủ nghiêm các skill đã import ở trên trước khi trả lời (chi tiết token/docs/script đã nằm trong skill tương ứng).
- Khi viết/sửa **tài liệu** → bám `docs-style.md`. Khi viết/sửa **script** → bám `scripting-safety.md`.
- Khi spawn sub-agent qua Task tool, nhắc rõ trong prompt: "Tuân thủ CLAUDE.md và mọi skill được import trong đó."

## Git

- **Không thêm trailer `Co-Authored-By: Claude ...`** (hay bất kỳ co-author Claude/Anthropic nào) vào commit message. Tác giả commit chỉ là người dùng.

## Ngôn ngữ

- Trả lời người dùng bằng tiếng Việt trừ khi được yêu cầu khác.
- Code, commit message, tên biến: giữ tiếng Anh theo chuẩn.
