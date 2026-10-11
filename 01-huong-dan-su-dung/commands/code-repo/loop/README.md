# /loop — lặp 1 task nhiều vòng tới khi đạt (kết hợp /schedule cho routines)

> Loại Built-in/Workflow · Nhóm Code & Repo · Mức rủi ro Trung bình
> **Nói nôm na:** `/loop` bảo Claude Code "làm đi làm lại task này cho tới khi đạt chuẩn": mỗi vòng làm → check → chưa đạt thì sửa tiếp.

## Khi nào dùng

- Dùng `/loop` khi task cần chạy đi chạy lại tới khi đạt một tiêu chí rõ ràng (pass lint, hết flake...).
- Đặt `/loop` **kèm điều kiện dừng và `--max`** trước khi rời máy, để tránh loop vô hạn.
- Không dùng `/loop` khi chưa viết được tiêu chí "xong là gì" — không có đích thì không biết dừng ở đâu.

## Cách gọi

```bash
`/loop <task>`
`/loop <task> --max <n>`
`/schedule <cron> <task>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/loop Toàn bộ src/legacy/ pass ruff check + mypy (0 errors), không đổi logic
# (verify bằng pytest legacy/ vẫn pass sau mỗi 10 file)
```

**Kết quả mong đợi:**

- Mỗi vòng: làm → check → chưa đạt thì sửa tiếp; dừng khi đạt hoặc chạm `--max`.
- Bạn xem được log từng vòng để biết vì sao dừng.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Loop 20 vòng không dừng | Không goal / goal bất khả thi / thiếu --max | Ngắt (Ctrl+C); đặt goal khả thi + `--max`; chia task nhỏ |
| Loop càng sửa càng hỏng | Scope quá rộng, model quên đã sửa gì | Thu scope (3 file/vòng); ghi progress ra file; `/compact` + tóm tắt |
| Bill nổ sau loop qua đêm | Quên trần + effort max + opus | Luôn --max + sonnet+medium cho loop; đặt cap extra-usage |

## Tham khảo

- [../../model-mode/goal/README.md](../../model-mode/goal/README.md)
- [../batch/README.md](../../code-repo/batch/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../model-mode/extra-usage/README.md](../../model-mode/extra-usage/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/loop` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
