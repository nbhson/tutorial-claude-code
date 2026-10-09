# /stats — Tiền đi đâu: token, chi phí, hạn mức hôm nay

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (chỉ xem số, không sửa, không gửi đi)
> **Nói nôm na:** `/stats` hiện bảng tiêu thụ: hôm nay/tuần này đốt bao nhiêu token (in/out, cache-hit), quy ra tiền, còn bao nhiêu quota, việc nào ngốn nhất. Mở mỗi sáng để biết "hôm nay còn bắn được bao nhiêu", cuối tuần để biết "tuần này đắt vì đâu". Hiểu 1 câu: `/stats` là đồng hồ xăng — `/insights` mới là bác sĩ.

## Khi nào dùng

- Dùng mỗi sáng để biết còn quota, cuối tuần để biết tuần này đắt vì đâu.
- Dùng **trước khi** nhận việc lớn: biết còn xăng mới dám nhận refactor dài.
- Không dùng thay `/insights`: `/stats` là đồng hồ xăng, `/insights` mới là bác sĩ.

## Cách gọi

```bash
/stats          # số hôm nay
/stats --week   # gộp tuần
/stats --month  # gộp tháng
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/stats
# → "Hôm nay đã dùng 50%, còn ~1M token. Cache-hit 70% (tốt)."
# → Quyết định: đủ xăng refactor module X hôm nay. Nếu còn 10% thì để mai.
```

Kết quả mong đợi:

- Bảng token in/out/cache + quy ra tiền/quota %.
- Cache-hit cao (70%) là dấu hiệu tốt.

**Kiểm tra nhanh:** đối chiếu với `/cost` cùng nguồn; nếu 0 token thì kiểm tra account đang login.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/stats` trống (0 token) | Nhầm profile/account, hoặc log mới xoá | Kiểm tra account đang login; đúng `~/.claude/` |
| Tiền hiển thị 0$ dù đã dùng | Plan unlimited/team tính khác | Xem quota % thay vì $; hỏi admin team |
| `--by-task` gom sai việc | Session đặt tên trùng/không tên | Đặt tên session rõ (`refactor-auth` thay vì `untitled-12`) |

## Tham khảo

- [../insights/README.md](../../knowledge-system/insights/README.md)
- [../cost/README.md](../../session-context/cost/README.md)
- [../usage/README.md](../../session-context/usage/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _xem % quota thay vì $ nếu dùng gói team/unlimited — số tiền có thể hiện 0._
