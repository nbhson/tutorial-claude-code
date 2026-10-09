# /fewer-permission-prompts — quét transcripts, đề xuất allowlist read-only cho đỡ hỏi

> Loại Built-in · Nhóm Quyền & Ma sát · Mức rủi ro Thấp
> **Nói nôm na:** `/fewer-permission-prompts` (tên cũ `less-permission-prompts` ở bản v2.1.111) quét transcripts rồi đề xuất allowlist READ-ONLY để máy đỡ hỏi lặp. Nó không tự mở quyền ghi/chạy — chỉ gợi ý, bạn duyệt từng cái.

## Khi nào dùng

- Dùng `/fewer-permission-prompts` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/fewer-permission-prompts` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/fewer-permission-prompts` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/fewer-permission-prompts`
`/less-permission-prompts`
`/permissions`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/fewer-permission-prompts
# → "3 đề xuất (read-only):
#    [1] Read src/** (47 lần/7d) [Yes/No]
#    [2] Glob docs/** (19 lần/7d) [Yes/No]
#    [3] Grep tests/** (12 lần/7d) [Yes/No]"
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/fewer-permission-prompts` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Quét báo "no patterns" dù bị hỏi nhiều | Transcripts bị xóa (`/clear` nhiều) hoặc mới dùng 1–2 ngày, chưa đủ mẫu | Dùng 1 tuần rồi quét lại; đừng clear liên tục nếu muốn máy học |
| Tên cũ chạy, tên mới không | Bản quá cũ chưa có tên mới | Update CLI; dùng tên nào máy nhận |
| Yes rồi mà vẫn hỏi y hệt | Duyệt vào scope khác (local vs project) | `/permissions` xem scope; chuyển scope đúng |

## Tham khảo

- [../../model-mode/permissions/README.md](../../model-mode/permissions/README.md)
- [../../knowledge-system/doctor/README.md](../../knowledge-system/doctor/README.md)
- [../../auth-settings/sandbox/README.md](../../auth-settings/sandbox/README.md)
- [../../auth-settings/status/README.md](../../auth-settings/status/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/fewer-permission-prompts` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
