# /loop — lặp 1 task nhiều vòng tới khi đạt (kết hợp /schedule cho routines)

> Loại Built-in/Workflow · Nhóm Code & Repo · Mức rủi ro Trung bình
> **Nói nôm na:** `/loop` bảo Claude Code "làm đi làm lại task này cho tới khi đạt chuẩn": mỗi vòng làm → check → chưa đạt thì sửa tiếp.

## Khi nào dùng

- Dùng `/loop` khi task cần chạy đi chạy lại tới khi đạt một tiêu chí rõ ràng (pass lint, hết flake...).
- Đặt `/loop` **kèm điều kiện dừng và `--max`** trước khi rời máy, để tránh loop vô hạn.
- Không dùng `/loop` khi chưa viết được tiêu chí "xong là gì" — không có đích thì không biết dừng ở đâu.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Mỗi vòng: làm → check → chưa đạt thì sửa tiếp; dừng khi đạt hoặc chạm `--max`.
- Bạn xem được log từng vòng để biết vì sao dừng.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này là "sổ bệnh án" của `/loop`: những triệu chứng hay gặp khi chạy lặp, nguyên nhân đằng sau và cách xử lý ngay.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Loop 20 vòng không dừng | Không goal / goal bất khả thi / thiếu --max | Ngắt (Ctrl+C); đặt goal khả thi + `--max`; chia task nhỏ |
| Loop càng sửa càng hỏng | Scope quá rộng, model quên đã sửa gì | Thu scope (3 file/vòng); ghi progress ra file; `/compact` + tóm tắt |
| Bill nổ sau loop qua đêm | Quên trần + effort max + opus | Luôn --max + sonnet+medium cho loop; đặt cap usage-credits |

> **Cách đọc bảng này:** tìm dòng khớp triệu chứng bạn đang gặp ở cột "Triệu chứng", đọc ngang sang "Vì sao" để hiểu gốc rễ, rồi áp cột "Cách sửa" — xử lý được trong vài phút.

> **Tóm gọn 1 câu:** `/loop` như máy chạy bộ có đồng hồ mục tiêu — đặt đích dừng và `--max` trước khi lên máy, chạy tới khi đạt chứ không chạy mù qua đêm.

## Tham khảo

- [../../model-mode/goal/README.md](../../model-mode/goal/README.md)
- [../batch/README.md](../../code-repo/batch/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../model-mode/usage-credits/README.md](../../model-mode/usage-credits/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/loop` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
