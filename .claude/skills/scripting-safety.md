# Skill: Scripting Safety

Quy tắc cho script trong `scripts/` (bash cho VM Ubuntu, PowerShell cho Host Windows).

## Chung

- **Không hardcode đường dẫn tuyệt đối theo máy cá nhân** (vd `C:\Users\<tên>\...`). Dùng đường dẫn tương đối, biến, hoặc `$env:`/`$HOME`. Trong docs hướng dẫn `scp`, viết placeholder `<path-to-repo>` hoặc đường dẫn repo thực tế.
- Tham số hóa giá trị hay đổi (IP, version) thành biến ở đầu file — xem hằng số trong [[wazuh-lab]].
- In thông báo tiến độ rõ ràng (`[1/4] ...`) và bước verify cuối.

## Bash (Ubuntu VM)

- Mở đầu `#!/bin/bash` + `set -e`.
- **Idempotent**: kiểm tra trước khi tạo (`if [ -f ... ]`, `if id user`), tránh tạo trùng/append lặp vào `/etc/fstab`, `sources.list.d`.
- Quote biến: `"${VAR}"`. Ưu tiên `tee` + here-doc cho file config cần sudo.

## PowerShell (Host Windows)

- Kiểm tra quyền Administrator đầu script, thoát sớm nếu thiếu.
- `try/catch` quanh `Invoke-WebRequest`/network, có thông báo lỗi hữu ích.
- Idempotent: check `Test-Path` trước khi tải; check `Get-Service` để xác nhận kết quả.
- Lưu ý môi trường: PowerShell 5.1, `$null` không phải `/dev/null`, dùng backtick để nối dòng.
- **Encoding: lưu `.ps1` có emoji/tiếng Việt dạng UTF-8 _có BOM_** (hoặc UTF-16 LE). PS 5.1 đọc file không BOM theo codepage ANSI → ký tự multibyte hỏng, lệch dấu nháy → lỗi giả `Missing closing '}'`/`MissingEndCurlyBrace`. Ngược lại, file `.sh` **không** được có BOM (bash sẽ lỗi shebang). Thêm BOM nhanh: `printf '\xEF\xBB\xBF' | cat - file.ps1 > t && mv t file.ps1`.
- Chạy script: `&` là call operator, chỉ đặt _đầu_ lệnh (`& "path.ps1"`); nối 2 lệnh dùng `;` không phải `&`. Đặt `&` giữa dòng → `AmpersandNotAllowed`.

## An toàn

- Lab dùng attack tools (hydra/nmap...) — chỉ trỏ vào dải `192.168.56.0/24`. Xem [[wazuh-lab]].
- Không nhúng password thật; password lab để rõ là dùng cho môi trường isolated.
