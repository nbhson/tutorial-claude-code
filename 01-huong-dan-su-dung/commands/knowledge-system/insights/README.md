# /insights — Nhìn lại cách bạn làm việc: token đi đâu, thói quen nào tốn kém

> Loại Skill (phân tích) · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ đọc log local, không sửa, không gửi đi)

> Nói nôm na: `/insights` phân tích lịch sử dùng Claude Code của bạn (từ log/transcript local): token đốt vào việc gì, giờ nào hiệu quả, lệnh nào dùng nhiều, thói quen nào phung phí (clear ít, Read file to, batch ẩu) — rồi gợi ý 3-5 thay đổi cụ thể tiết kiệm nhất. Khác `/stats` (con số thô) — insights là "bác sĩ đọc kết quả xét nghiệm rồi kê đơn".

## Khi nào dùng

- Dùng /insights khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /insights **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /insights thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/insights`
`/insights --month`
`/insights --team`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/insights
# → "Tuần này 1.2M token. 40% vào Read file dump.sql lặp 12 lần.
#    Đơn: thay Read dump bằng Grep + head, dùng /compact mỗi 2h.
#    Tiết kiệm ước tính 400k/tuần (~30%)."
```

Kết quả mong đợi:

- Claude trả đúng việc của /insights (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
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

> Mẹo 1 dòng: _chưa chắc thì gọi /insights sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
