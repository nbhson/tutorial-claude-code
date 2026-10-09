# /extra-usage — Mua thêm quota khi hết giới hạn gói, không ngắt việc giữa chừng

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (chỉ liên quan billing/quota; không sửa code; có thể tốn tiền thật — đọc kỹ giá trước khi bật)
>
> **Nói nôm na:** `/extra-usage` cho phép vượt trần quota của gói (Pro/Max/Team) bằng cách trả thêm pay-as-you-go, để Opus/effort cao không bị ngắt giữa task dài. Không phải "hack miễn phí" — là công tắc billing có kiểm soát.

## Khi nào dùng

- Dùng /extra-usage khi task dài sắp hoặc đã chạm trần quota gói (Pro/Max/Team) mà bạn không muốn dừng giữa chừng.
- Dùng /extra-usage **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /extra-usage thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/extra-usage`
`/extra-usage on`
`/extra-usage off`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Đang ở file 18/30 thì báo limit
/extra-usage
# → bật, chạy tiếp 12 file còn lại trong cùng session

# Xong → tắt + về rẻ
/extra-usage
# → off
/model sonnet
```

Kết quả mong đợi:

- Claude trả đúng việc của /extra-usage (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/extra-usage` báo không khả dụng | Gói Free / admin tắt / bản cũ | Nâng gói, liên hệ admin, update CLI |
| Bật rồi vẫn báo limit | Rate-limit cứng (chống abuse), không phải quota tiền | Đợi vài phút, giảm song song (`/batch` ít worktree hơn) |
| Bill tăng bất ngờ | Quên tắt + để max/opus | Tắt extra, về sonnet+medium, đặt cap trên dashboard |

## Tham khảo

- [../fast/README.md](../../model-mode/fast/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../effort/README.md](../../model-mode/effort/README.md)
- [../batch/README.md](../../code-repo/batch/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /extra-usage sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
