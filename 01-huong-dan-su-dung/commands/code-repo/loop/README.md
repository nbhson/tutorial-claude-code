# /loop — Lặp 1 task nhiều vòng tới khi đạt (kết hợp /schedule cho routines)

> Loại Built-in/Workflow · Nhóm Code & Repo · Nguy hiểm Trung bình (loop + auto/bypass = chạy hàng chục vòng không hỏi — tốn quota + có thể sửa lan; luôn loop với goal + acceptEdits)

> Nói nôm na: `/loop` bảo Claude Code "làm đi làm lại task này cho tới khi đạt chuẩn": mỗi vòng làm → check (thường qua `/goal` evaluator) → chưa đạt thì sửa tiếp. Biến thể `/schedule` đặt loop theo giờ (routine đêm/định kỳ). Dùng cho hardening, migration batch, quét lỗi lặp — không dùng cho task 1 lần là xong.

## Khi nào dùng

- Dùng /loop khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /loop **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /loop thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/loop <task>`
`/loop <task> --max <n>`
`/schedule <cron> <task>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: đặt goal đo được
/goal Toàn bộ src/legacy/ pass ruff check + mypy (0 errors), không đổi logic
(verify bằng pytest legacy/ vẫn pass sau mỗi 10 file).
```

Kết quả mong đợi:

- Claude trả đúng việc của /loop (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Loop 20 vòng không dừng | Không goal / goal bất khả thi / thiếu --max | Ngắt (Ctrl+C); đặt goal khả thi + `--max`; chia task nhỏ |
| Loop càng sửa càng hỏng (vòng sau phá vòng trước) | Scope quá rộng, model quên đã sửa gì | Thu scope (3 file/vòng); ghi progress ra file; `/compact` + tóm tắt |
| Bill nổ sau loop qua đêm | Quên trần + effort max + opus | Luôn --max + sonnet+medium cho loop; đặt cap extra-usage |

## Tham khảo

- [../goal/README.md](../../model-mode/goal/README.md)
- [../batch/README.md](../../code-repo/batch/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../extra-usage/README.md](../../model-mode/extra-usage/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /loop sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
