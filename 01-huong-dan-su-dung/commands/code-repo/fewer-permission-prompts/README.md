# /fewer-permission-prompts — Quét transcripts, đề xuất allowlist read-only cho đỡ hỏi

> Loại Built-in · Nhóm Quyền & Ma sát · Nguy hiểm Thấp (chỉ ĐỀ XUẤT allowlist read-only; nhưng Có nếu bạn Yes mù cả suggest ghi/xoá — chỉ Yes cái đọc)

> Nói nôm na: `/fewer-permission-prompts` (tên cũ `less-permission-prompts` ở bản v2.1.111) quét transcripts (lịch sử hỏi quyền) rồi đề xuất allowlist READ-ONLY (Read/Glob/Grep trên path an toàn) để máy đỡ hỏi lặp. Nó không tự mở quyền ghi/chạy — chỉ gợi ý, bạn duyệt từng cái. Hiểu nó là hiểu "máy học thói quen bạn để bớt hỏi, nhưng phanh vẫn còn".

## Khi nào dùng

- Dùng /fewer-permission-prompts khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /fewer-permission-prompts **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /fewer-permission-prompts thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/fewer-permission-prompts`
`/less-permission-prompts`
`/permissions`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Triệu chứng: mỗi lần hỏi "đọc file X?" bạn đều Allow:
/fewer-permission-prompts
# → "3 đề xuất (read-only):
#    [1] Read src/** (47 lần/7d) [Yes/No]
#    [2] Glob docs/** (19 lần/7d) [Yes/No]
#    [3] Grep tests/** (12 lần/7d) [Yes/No]"
# → Yes cả 3 → từ nay đọc 3 chỗ này khỏi hỏi

```

Kết quả mong đợi:

- Claude trả đúng việc của /fewer-permission-prompts (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Quét báo "no patterns" dù bị hỏi nhiều | Transcripts bị xóa (`/clear` nhiều) hoặc mới dùng 1-2 ngày, chưa đủ mẫu | Dùng 1 tuần rồi quét lại; đừng clear liên tục nếu muốn máy học |
| Tên cũ chạy, tên mới không (bản kẹt giữa) | Bản quá cũ chưa có tên mới | Update CLI (`/restart` offer); dùng tên nào máy nhận |
| Yes rồi mà vẫn hỏi y hệt | Duyệt vào scope local nhưng session đọc scope project (hoặc ngược) | `/permissions` xem suggest vào scope nào; chuyển sang scope session đang dùng |

## Tham khảo

- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../sandbox/README.md](../../auth-settings/sandbox/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /fewer-permission-prompts sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
