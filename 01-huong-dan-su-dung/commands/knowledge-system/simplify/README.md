# /simplify — Làm code đơn giản lại: bớt phức tạp, giữ nguyên tính năng

> Loại Skill (refactor) · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (chỉ refactor; nhưng Có nhẹ nếu simplify đụng logic tinh vi — luôn chạy test sau)
> **Nói nôm na:** `/simplify` yêu cầu model đọc 1 hàm/file bạn chỉ định, đo độ phức tạp (lồng nhau, nhánh, dài), rồi đề xuất bản gọn hơn mà test vẫn xanh: tách hàm, gộp nhánh, bỏ code chết, đặt tên rõ. Khác `/review` (tìm lỗi) và `/refactor` chung chung (đổi cấu trúc) — simplify chỉ theo 1 hướng: đơn giản hơn.

## Khi nào dùng

- Dùng khi 1 hàm/file khó đọc: lồng sâu, nhiều nhánh, dài dòng, code chết.
- Dùng **trước khi** thêm tính năng lên code rối: dọn trước cho dễ mở rộng.
- Không dùng thay chạy test: simplify xong phải để test xanh chứng minh không đổi hành vi.

## Cách gọi

```bash
/simplify <file>          # simplify cả file
/simplify <file>:<hàm>    # chỉ 1 hàm
/simplify --aggressive    # gọn tay hơn
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/simplify api/auth.py:login
# Trước: if user: → if pw: → if not locked: → try: ... (sâu 5)
# Sau: 4 early-return (không user → raise; sai pw → raise...) + thân chính 10 dòng phẳng
# → test auth xanh → commit
```

Kết quả mong đợi:

- Diff gọn hơn (early-return, tách hàm, bỏ code chết), test vẫn xanh.
- Không đổi tính năng; nếu hành vi đổi là fail.

**Kiểm tra nhanh:** chạy test suite (hoặc nhóm test của hàm) sau khi duyệt diff.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Simplify xong test đỏ | Đổi hành vi (bỏ nhánh cần thiết) | Hoàn tác, simplify từng chiêu nhỏ thay vì 1 lần lớn |
| Model chỉ format, không gọn | Hàm đã gọn hoặc prompt chung quá | Chỉ hàm cụ thể + `--aggressive`; đo số trước (độ sâu/nhánh) |
| Gọn xong khó đọc hơn (golf-code) | Model lạm dụng one-liner | Quy tắc: tên rõ > ngắn; từ chối bản lạm dụng comprehension 3 tầng |

## Tham khảo

- [../verify/README.md](../../code-repo/verify/README.md)
- [../review/README.md](../../code-repo/review/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _simplify từng hàm một, đừng 1 lượt cả module rồi mới test._
