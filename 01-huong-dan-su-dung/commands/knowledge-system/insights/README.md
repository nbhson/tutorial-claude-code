# /insights — Nhìn lại cách bạn làm việc: token đi đâu, thói quen nào tốn kém

> Loại Skill (phân tích) · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (chỉ đọc log local, không sửa, không gửi đi)
> **Nói nôm na:** `/insights` phân tích lịch sử dùng Claude Code của bạn (từ log/transcript local): token đốt vào việc gì, giờ nào hiệu quả, lệnh nào dùng nhiều, thói quen nào phung phí (clear ít, Read file to, batch ẩu) — rồi gợi ý 3-5 thay đổi cụ thể tiết kiệm nhất. Khác `/stats` (con số thô) — insights là "bác sĩ đọc kết quả xét nghiệm rồi kê đơn".

## Khi nào dùng

- Dùng cuối tuần để hiểu token/thời gian đổ vào đâu và nhận 3–5 gợi ý tiết kiệm.
- Dùng **trước khi** hoá đơn phình: phát hiện sớm thói quen đốt token (Read file to, clear ít).
- Không dùng thay `/stats`: `/stats` là số thô, `/insights` là bác sĩ đọc số rồi kê đơn.

## Cách gọi

```bash
/insights          # phân tích log local gần đây
/insights --month  # gộp cả tháng
/insights --team   # gộp log nhiều người
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/insights
# → "Tuần này 1.2M token. 40% vào Read file dump.sql lặp 12 lần.
#    Đơn: thay Read dump bằng Grep + head, dùng /compact mỗi 2h.
#    Tiết kiệm ước tính 400k/tuần (~30%)."
```

Kết quả mong đợi:

- Báo cáo token theo việc + 3–5 gợi ý cụ thể kèm ước tính tiết kiệm.
- Chỉ đọc log local, không gửi đi đâu.

**Kiểm tra nhanh:** đối chiếu số token với `/stats` cùng nguồn; xem `~/.claude/projects/` để chắc đúng profile.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Báo cáo trống/không có dữ liệu | Log bị xoá hoặc profile khác | Kiểm tra `~/.claude/projects/`; đúng user/profile |
| Số token lệch với bill | Bill tính cả API trực tiếp, insights chỉ CLI local | So với `/stats` cùng nguồn; bill cloud xem console riêng |
| `--team` thiếu người | Ai đó chưa export log | Quy ước: mỗi người export thứ 2 đầu tuần |

## Tham khảo

- [../stats/README.md](../../knowledge-system/stats/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../cost/README.md](../../session-context/cost/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _áp dụng 1 gợi ý trước, đừng đổi hết 5 cái một lúc._
