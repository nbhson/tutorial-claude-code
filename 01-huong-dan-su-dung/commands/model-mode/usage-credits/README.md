# /usage-credits — Mua thêm quota khi hết giới hạn gói, không ngắt việc giữa chừng

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (chỉ liên quan billing/quota; không sửa code; có thể tốn tiền thật — đọc kỹ giá trước khi bật)
>
> **Nói nôm na:** `/usage-credits` (trước đây tên `/extra-usage`) cho phép vượt trần quota của gói (Pro/Max/Team) bằng cách trả thêm pay-as-you-go, để Opus/effort cao không bị ngắt giữa task dài. Không phải "hack miễn phí" — là công tắc billing có kiểm soát.

## Khi nào dùng

- Dùng `/usage-credits` khi task dài sắp hoặc đã chạm trần quota gói (Pro/Max/Team) mà bạn không muốn dừng giữa chừng.
- Dùng `/usage-credits` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/usage-credits` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Trần quota được nới trong session; task dài chạy tiếp thay vì bị chặn giữa chừng.
- Phần vượt hạn mức tính pay-as-you-go theo giá API — nhớ tắt khi xong việc để về lại quota gói.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

> **Tóm gọn 1 câu:** `/usage-credits` là cây xăng bán lẻ khi đồng hồ xăng gói cạn giữa đường: đổ thêm là chạy tiếp, nhưng giá lít lẻ đắt hơn gói — xong việc nhớ khóa vòi.

## Lỗi thường gặp

Bảng dưới là những sự cố liên quan "cây xăng bán lẻ" này — đối chiếu triệu chứng rồi làm theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/usage-credits` báo không khả dụng | Gói Free / admin tắt / bản cũ | Nâng gói, liên hệ admin, update CLI |
| Bật rồi vẫn báo limit | Rate-limit cứng (chống abuse), không phải quota tiền | Đợi vài phút, giảm song song (`/batch` ít worktree hơn) |
| Bill tăng bất ngờ | Quên tắt + để max/opus | Tắt extra, về sonnet+medium, đặt cap trên dashboard |

> **Cách đọc bảng này:** mỗi dòng là một tình huống billing/quota; cột "Vì sao" cho biết trở ngại thuộc loại nào (gói, rate-limit hay quên tắt), cột "Cách sửa" là bước xử lý kèm lệnh.

## Tham khảo

- [../fast/README.md](../../model-mode/fast/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../effort/README.md](../../model-mode/effort/README.md)
- [../batch/README.md](../../code-repo/batch/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /usage-credits sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
