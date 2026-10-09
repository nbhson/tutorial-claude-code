# /status — Bảng đồng hồ: là ai, model gì, ở đâu, tốn bao nhiêu

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chỉ đọc — lệnh an toàn nhất, gõ bao nhiêu lần cũng được)
> **Nói nôm na:** `/status` hiện snapshot 1 màn hình: account + plan, model đang chạy, working dir + roots, cache hit, session dài bao nhiêu, token/quota đã dùng, version CLI. Hiểu `/status` là hiểu "nhìn đồng hồ taplo" — đầu session 3 giây, sau mỗi `/cd`/`teleport`/`login` 1 lần, khỏi lái mù.

## Khi nào dùng

- Dùng khi muốn biết 1 màn hình: account/plan, model đang chạy, cwd + roots, cache hit, quota đã dùng, version CLI — đầu session hoặc sau mỗi `/cd`/`/login`/`/teleport`.
- Dùng **trước khi** làm việc trên máy/repo lạ hoặc nghi đang chạy nhầm account — check 3 giây khỏi dùng nhầm quota.
- Không dùng `/status` thay cho việc tự quyết định account/model đúng — nó cho bạn thấy, nhưng việc chọn vẫn là của bạn.

## Cách gọi

```bash
`/status`
`/status --short`
`/status --quota`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/status
# → Account: personal?! (tưởng work)
# → Hôm qua vọc side-project quên đổi. Đổi ngay trước khi động vào code công ty:
# /login --account work  (hoặc /config account → switch default)
# /status → "work ✓" mới bắt đầu
```

Kết quả mong đợi:

- Claude trả đúng việc của /status (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Kiểm tra nhanh:**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Status hiện acc cũ sau khi login mới | Session giữ auth snapshot, chưa reload | Session mới (hoặc `/clear`) để nhận acc mới; kiểm tra `/config account` default |
| `Roots: X (files only)` dù đã add-dir | Thiếu env flag cho CLAUDE.md dir phụ | Xem `/add-dir` (bật flag → remove + add lại) |
| Cache hit thấp kéo dài 1 chỗ | CLAUDE.md phình/mâu thuẫn, context loạn | `/doctor claude-md` rồi tách/trim |

## Tham khảo

- [../config/README.md](../../auth-settings/config/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../cd/README.md](../../auth-settings/cd/README.md)
- [../add-dir/README.md](../../auth-settings/add-dir/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /status sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
