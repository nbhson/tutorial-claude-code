# /stats — Tiền đi đâu: token, chi phí, hạn mức hôm nay

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ xem số, không sửa, không gửi đi)

> Nói nôm na: `/stats` hiện bảng tiêu thụ: hôm nay/tuần này đốt bao nhiêu token (in/out, cache-hit), quy ra tiền, còn bao nhiêu quota, việc nào ngốn nhất. Mở mỗi sáng để biết "hôm nay còn bắn được bao nhiêu", cuối tuần để biết "tuần này đắt vì đâu". Hiểu 1 câu: `/stats` là đồng hồ xăng — `/insights` mới là bác sĩ.

## Khi nào dùng

- Dùng /stats khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /stats **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /stats thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/stats`
`/stats --week`
`/stats --month`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/stats
# → "Hôm nay đã dùng 50%, còn ~1M token. Cache-hit 70% (tốt)."
# → Quyết định: đủ xăng refactor module X hôm nay. Nếu còn 10% thì để mai.
```

Kết quả mong đợi:

- Claude trả đúng việc của /stats (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
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

> Mẹo 1 dòng: _chưa chắc thì gọi /stats sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
