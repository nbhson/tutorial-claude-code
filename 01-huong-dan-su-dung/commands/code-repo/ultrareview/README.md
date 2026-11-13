# /ultrareview — audit sâu multi-agent trong cloud sandbox (kỹ nhất, chậm nhất)

> Loại Skill/Workflow · Nhóm Code & Repo · Mức rủi ro Không
> **Nói nôm na:** `/ultrareview` là "hội đồng thanh tra": nhiều subagents chuyên môn (security, correctness, perf) soi song song + chạy code thật trong cloud sandbox cách ly, rồi tổng hợp 1 báo cáo audit. Dành cho release lớn, tiền thật, bảo mật — không phải cho PR nhỏ hàng ngày.

**Ghi chú:** `/ultraplan` đã bị gỡ (w32/2026, 03–07/08/2026) — nếu bạn từng thấy nhắc đến `/ultraplan`, hãy dùng plan mode hoặc Claude Code trên web thay thế.

## Khi nào dùng

- Dùng `/ultrareview` cho release lớn, code tiền thật hoặc phần bảo mật — cần audit đa agent trong sandbox cách ly.
- Gọi khi một lượt `/review` + `/code-review` vẫn chưa đủ yên tâm.
- Không dùng cho PR nhỏ hàng ngày: đây là lệnh chậm nhất và tốn quota nhất trong nhóm.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Một báo cáo audit tổng hợp từ nhiều subagent, kèm các phát hiện critical/high.
- Có bằng chứng chạy race/repro trong sandbox khi tình huống cần mới thấy.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này là "sổ bệnh án" của `/ultrareview`: vì sao chậm, vì sao tốn, và khi nào không nên gọi.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/ultrareview` báo không khả dụng | Bản cũ / gói không có sandbox | Update CLI; dùng `/code-review` + `/verify` thay thế |
| Chạy 15 phút chưa xong | Diff khổng lồ | Thu hẹp phạm vi (`src/payments/` thay vì cả repo) |
| Bill tăng mạnh | Gọi nhiều lần cho PR nhỏ | Chỉ gọi cho release/audit; PR nhỏ dùng `/review`/`/code-review` |

> **Cách đọc bảng này:** đọc từ "Triệu chứng" sang "Vì sao" rồi "Cách sửa"; dòng nào nói về bill/quota thì đọc kỹ — đây là lệnh tốn quota nhất nhóm.

> **Tóm gọn 1 câu:** `/ultrareview` là mời hẳn hội đồng kiểm định vào nhà — kỹ nhất nhưng đắt nhất, chỉ mời khi tài sản thật sự lớn.

## Tham khảo

- [../review/README.md](../../code-repo/review/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../model-mode/effort/README.md](../../model-mode/effort/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/ultrareview` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
