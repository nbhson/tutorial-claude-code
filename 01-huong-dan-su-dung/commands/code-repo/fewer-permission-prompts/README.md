# /fewer-permission-prompts — quét transcripts, đề xuất allowlist read-only cho đỡ hỏi

> Loại Built-in · Nhóm Quyền & Ma sát · Mức rủi ro Thấp
> **Nói nôm na:** `/fewer-permission-prompts` (tên cũ `less-permission-prompts` ở bản v2.1.111) quét transcripts rồi đề xuất allowlist READ-ONLY để máy đỡ hỏi lặp. Nó không tự mở quyền ghi/chạy — chỉ gợi ý, bạn duyệt từng cái.

## Khi nào dùng

- Dùng `/fewer-permission-prompts` khi bạn thấy bị hỏi xin quyền lặp lại nhiều lần cho cùng loại lệnh read-only.
- Quét **sau vài ngày dùng thật** để đủ mẫu transcript — quét ngay ngày đầu sẽ ít đề xuất.
- Không dùng nó để mở quyền ghi/chạy: nó chỉ đề xuất allowlist read-only, bạn vẫn duyệt từng cái.

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

- Danh sách đề xuất allowlist read-only kèm số lần bị hỏi, mỗi mục là một lựa chọn Yes/No.
- Không quyền ghi hay chạy nào được tự thêm vào cấu hình.

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
