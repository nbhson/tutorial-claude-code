# /ultrareview — audit sâu multi-agent trong cloud sandbox (kỹ nhất, chậm nhất)

> Loại Skill/Workflow · Nhóm Code & Repo · Mức rủi ro Không
> **Nói nôm na:** `/ultrareview` là "hội đồng thanh tra": nhiều subagents chuyên môn (security, correctness, perf) soi song song + chạy code thật trong cloud sandbox cách ly, rồi tổng hợp 1 báo cáo audit. Dành cho release lớn, tiền thật, bảo mật — không phải cho PR nhỏ hàng ngày.

**Ghi chú:** `/ultraplan` đã bị gỡ (w32/2026, 03–07/08/2026) — nếu bạn từng thấy nhắc đến `/ultraplan`, hãy dùng plan mode hoặc Claude Code trên web thay thế.

## Khi nào dùng

- Dùng `/ultrareview` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/ultrareview` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/ultrareview` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/ultrareview`
`/ultrareview <PR/phạm vi>`
`/ultrareview --focus security`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/ultrareview 130
# → hội đồng phát hiện double-spend khi retry webhook (critical)
# mà review thường bỏ sót vì cần chạy race thật trong sandbox mới thấy.
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/ultrareview` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/ultrareview` báo không khả dụng | Bản cũ / gói không có sandbox | Update CLI; dùng `/code-review` + `/verify` thay thế |
| Chạy 15 phút chưa xong | Diff khổng lồ | Thu hẹp phạm vi (`src/payments/` thay vì cả repo) |
| Bill tăng mạnh | Gọi nhiều lần cho PR nhỏ | Chỉ gọi cho release/audit; PR nhỏ dùng `/review`/`/code-review` |

## Tham khảo

- [../review/README.md](../../code-repo/review/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../model-mode/effort/README.md](../../model-mode/effort/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/ultrareview` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
