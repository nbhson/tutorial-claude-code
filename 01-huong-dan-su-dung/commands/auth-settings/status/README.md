# /status — Bảng đồng hồ: là ai, model gì, ở đâu, tốn bao nhiêu

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chỉ đọc — lệnh an toàn nhất, gõ bao nhiêu lần cũng được)
> **Nói nôm na:** `/status` hiện snapshot 1 màn hình: account + plan, model đang chạy, working dir + roots, cache hit, session dài bao nhiêu, token/quota đã dùng, version CLI. Hiểu `/status` là hiểu "nhìn đồng hồ taplo" — đầu session 3 giây, sau mỗi `/cd`/`teleport`/`login` 1 lần, khỏi lái mù.

## Khi nào dùng

- Dùng khi muốn biết 1 màn hình: account/plan, model đang chạy, cwd + roots, cache hit, quota đã dùng, version CLI — đầu session hoặc sau mỗi `/cd`/`/login`/`/teleport`.
- Dùng **trước khi** làm việc trên máy/repo lạ hoặc nghi đang chạy nhầm account — check 3 giây khỏi dùng nhầm quota.
- Không dùng `/status` thay cho việc tự quyết định account/model đúng — nó cho bạn thấy, nhưng việc chọn vẫn là của bạn.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Một màn hình đầy đủ: account + plan, model đang chạy, cwd + roots, cache hit, token/quota, version CLI.
- Không sửa file, không gọi model — gõ bao nhiêu lần cũng được.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các tình huống `/status` hiển thị thứ khiến bạn nghi ngờ — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Status hiện acc cũ sau khi login mới | Session giữ auth snapshot, chưa reload | Session mới (hoặc `/clear`) để nhận acc mới; kiểm tra `/config account` default |
| `Roots: X (files only)` dù đã add-dir | Thiếu env flag cho CLAUDE.md dir phụ | Xem `/add-dir` (bật flag → remove + add lại) |
| Cache hit thấp kéo dài 1 chỗ | CLAUDE.md phình/mâu thuẫn, context loạn | `/doctor claude-md` rồi tách/trim |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là thứ bảng `/status` đang hiện, "Vì sao" giải thích bóng sau con số, "Cách sửa" là việc cần làm ngay.

> **Tóm gọn 1 câu:** `/status` như nhìn bảng đồng hồ trước khi lên xe: đang cầm account nào, chạy model gì, còn bao nhiêu quota — 3 giây là biết mình có đi nhầm đường không.

## Tham khảo

- [../config/README.md](../../auth-settings/config/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../cd/README.md](../../auth-settings/cd/README.md)
- [../add-dir/README.md](../../auth-settings/add-dir/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /status sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
