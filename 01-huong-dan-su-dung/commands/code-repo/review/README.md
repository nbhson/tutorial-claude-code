# /review — xin nhận xét nhanh từ model hiện tại (không tạo subagent mới)

> Loại Built-in · Nhóm Code & Repo · Mức rủi ro Không
> **Nói nôm na:** `/review` là "ê xem giúp code này ổn không": model hiện tại (cùng context) đọc diff/code bạn chỉ định và cho nhận xét nhanh — bug, style, thiếu test.

## Khi nào dùng

- Dùng `/review` khi bạn muốn ý kiến nhanh ngay tại chỗ từ model đang chạy, cùng context (không spawn subagent mới).
- Gọi `/review` **sau mỗi thay đổi vừa viết** để bắt lỗi sớm — model còn nhớ mạch nên nhận xét sát hơn.
- Không dùng `/review` làm chốt cuối: đây là cùng một agent tự chấm, dễ "khen" code của chính mình.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Danh sách nhận xét theo file:dòng: bug, style, chỗ thiếu test.
- Không file nào bị sửa (review chỉ đọc rồi nhận xét).

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này là "sổ bệnh án" của `/review`: vì sao đôi khi nhận xét "khen suông", vì sao soi cả file không liên quan — và cách xử lý.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/review` khen hết lời nhưng code vẫn bug | Cùng agent tự chấm, mù cùng chỗ | Thêm `/code-review` (mắt mới) + `/verify` (chạy thật) |
| Review chung chung ("code ổn, nên thêm test") | Không chỉ rõ file/phạm vi, effort thấp | `/review src/x.ts` cụ thể + `/effort high` |
| `/review` soi cả file không liên quan | Mặc định đọc cả diff lớn | Chỉ định file: `/review src/payments/stripe.ts` |

> **Cách đọc bảng này:** mỗi dòng là một tình huống; bắt đầu từ cột "Triệu chứng", hiểu nguyên nhân ở cột giữa rồi áp "Cách sửa" ngay.

> **Tóm gọn 1 câu:** `/review` là nhờ chính thợ dựng bài xem lại bài của thợ đó — nhanh và sát, nhưng muốn mắt thứ hai hãy thêm `/code-review` và chạy thật bằng `/verify`.

## Tham khảo

- [../diff/README.md](../../code-repo/diff/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../ultrareview/README.md](../../code-repo/ultrareview/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/review` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
