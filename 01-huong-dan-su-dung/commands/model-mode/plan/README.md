# /plan — Chế độ lập kế hoạch: chỉ đọc + viết plan, cấm sửa code cho tới khi duyệt

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (bản thân plan mode an toàn — cấm ghi/sửa file; nguy hiểm chỉ khi bạn duyệt plan ẩu rồi cho chạy bypass sau đó)

> Nói nôm na: `/plan` (và mode `plan` trong vòng xoay Shift+Tab) khóa Claude Code ở trạng thái "chỉ được nhìn, không được chạm": đọc file, search, vẽ kiến trúc, viết plan từng bước — nhưng mọi Edit/Write/Bash ghi đều bị chặn. Bạn duyệt plan rồi mới cho thực thi. Đây là phanh an toàn số 1 cho task lớn.

## Khi nào dùng

- Dùng /plan khi bạn muốn đổi cách model suy nghĩ/chạy (model, effort, mode, mục tiêu, quyền) trước khi làm task khó.
- Dùng /plan **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /plan thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/plan`
`/plan <mô tả task>`
Shift+Tab
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: vào plan, ép đọc trước
/plan Thêm MoMo và VNPay vào module payments hiện chỉ có Stripe.
Yêu cầu: interface chung, idempotency, webhook verify, không phá API cũ.
Chỉ lập plan, chưa code.
```

Kết quả mong đợi:

- Claude trả đúng việc của /plan (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/plan` xong model vẫn sửa file | Chưa thật sự ở plan mode (mới gõ text, chưa Enter lệnh) | Kiểm tra status bar hiện `plan`; gõ lại `/plan` |
| Ở plan nhưng cần ghi 1 file plan ra đĩa | Plan chặn ghi là đúng | Bảo "hiển thị plan dạng markdown để tôi copy", hoặc tạm Shift+Tab về `acceptEdits` ghi 1 file rồi quay lại plan |
| Duyệt plan rồi model làm ẩu 10 bước | Duyệt cả cục + effort thấp | Duyệt 1–2 bước; `/effort high` cho bước khó |

## Tham khảo

- [../goal/README.md](../../model-mode/goal/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /plan sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
