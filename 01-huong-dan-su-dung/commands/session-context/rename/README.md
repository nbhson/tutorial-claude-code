# /rename — Đặt tên dễ nhớ cho session hiện tại để mai resume 1 phát trúng

> Loại Built-in · Nhóm Session & Context · Mức rủi ro Không (chỉ đổi tên hiển thị trong index, không xóa/sửa code hay history)
> **Nói nôm na:** `/rename` là "dán nhãn hộp đồ": đặt tên gợi nhớ (`payments-fix`, `migration-ca-dem`) cho session ID khô khan, để `/resume` / picker tìm thấy trong 3 giây.

## Khi nào dùng

- Dùng `/rename` khi bạn muốn đặt tên gợi nhớ cho session ID khô khan để `/resume` tìm trúng sau.
- Dùng `/rename` ngay trước khi nghỉ/đóng máy — một tên tốt tiết kiệm cả phút lướt picker.
- Không dùng `/rename` như cách lưu nội dung — đổi tên chỉ đổi nhãn, không đổi lịch sử hội thoại.

## Cách gọi

```bash
`/rename <tên>`
`/rename`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# 18h00, đang dở bước webhook
/todos
/rename payments-webhook-dang-do-mai-fix-tiep

# Sáng mai trong cùng thư mục:
/resume payments-webhook-dang-do-mai-fix-tiep
# → trúng ngay, khỏi lướt picker
```

Kết quả mong đợi:

- Claude trả đúng việc của /rename (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/resume <tên>` báo not found | Sai chính tả, sai dấu, khác hoa/thường | `/resume` (picker) để copy tên chính xác; dùng kebab-case không dấu |
| 2 sessions cùng tên | Đặt tên chung chung (`fix`, `test`) | Đặt tên duy nhất có ngày/phạm vi; rename lại 1 trong 2 |
| Tên có khoảng trắng bị cắt | Shell/parse tách từ | Quote: `/rename "my session"` hoặc dùng gạch ngang |

## Tham khảo

- [../resume/README.md](../../session-context/resume/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- [../branch/README.md](../../session-context/branch/README.md)
- [../todos/README.md](../../session-context/todos/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /rename sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
