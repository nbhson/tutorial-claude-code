# /stats — Tiền đi đâu: token, chi phí, hạn mức hôm nay

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ xem số, không sửa, không gửi đi)

`/stats` hiện bảng tiêu thụ: hôm nay/tuần này đốt bao nhiêu token (in/out, cache-hit), quy ra tiền, còn bao nhiêu quota, việc nào ngốn nhất. Mở mỗi sáng để biết "hôm nay còn bắn được bao nhiêu", cuối tuần để biết "tuần này đắt vì đâu". Hiểu 1 câu: `/stats` là đồng hồ xăng — `/insights` mới là bác sĩ.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/stats` | _(không có)_ | Tổng quan hôm nay: token, tiền, quota còn lại |
| `/stats --week` | flag | 7 ngày qua (so từng ngày) |
| `/stats --month` | flag | 30 ngày (cho retro/báo cáo) |
| `/stats --by-task` | flag | Top việc ngốn token nhất |

```bash
# Dạng 1: đồng hồ xăng mỗi sáng
/stats
# → Hôm nay: 180k in / 40k out, cache-hit 65%, ~2.1$, quota còn 70%

# Dạng 2: so cả tuần
/stats --week

# Dạng 3: tìm vòi rỉ
/stats --by-task
# → top: "đọc dump.sql 12 lần: 400k", "batch 30 con: 300k"...
```

---

## Cách nó hoạt động

1. **Đọc ở đâu?** Cộng từ usage log local + API usage (plan/quota). Không cần mạng vẫn xem được phần local.
2. **3 con số cốt lõi:** `input` (vào — gồm cache-read rẻ), `output` (ra — đắt gấp 3-5×), `cache-hit %` (tận dụng context cũ tốt không; >60% là ngon, <40% là đang vứt context).
3. **Quy ra tiền:** theo giá model đang dùng (Haiku rẻ, Opus đắt) — đổi model giữa chừng thì bảng tách riêng từng model.
4. **Quota:** plan Free/Pro/Team còn bao nhiêu % hôm nay/tuần; gần cạn thì báo vàng/đỏ + gợi ý (đổi Haiku, clear, mai làm tiếp).
5. **Không làm gì?** Không phân tích NGUYÊN NHÂN (việc của `/insights`), không chặn bạn khi hết (tự bạn dừng).

---

## Ví dụ thực tế

### Kịch bản 1: Sáng check xăng trước task lớn

```bash
/stats
# → "Hôm nay đã dùng 50%, còn ~1M token. Cache-hit 70% (tốt)."
# → Quyết định: đủ xăng refactor module X hôm nay. Nếu còn 10% thì để mai.
```

### Kịch bản 2: Cuối tuần tìm vòi rỉ

```bash
/stats --week --by-task
# → "T3 spike 800k: batch 30 general-purpose đọc cả repo.
#    Bài học: lần sau 5 Explore + output ≤15 dòng."
# → ghi vào /memory: "batch lớn chỉ dùng Explore, output ngắn"
```

### Kịch bản 3: Retro team (lead)

```bash
/stats --month
# → "Team 12M token/tháng, 60% vào 2 repo legacy. Đề xuất: tách rules + skill cho 2 repo đó."
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Số local lệch bill cloud | Dùng thêm API ngoài CLI, hoặc 2 máy | Bill chuẩn xem console; stats để theo dõi xu hướng/ngày |
| Hết quota giữa task gấp | Dở việc, model dừng | Sáng check `/stats`; task lớn chia 2 ngày; fallback Haiku |
| So tháng lệch (nghỉ Tết) | Kết luận sai | So tuần-làm-việc vs tuần-làm-việc; ghi chú ngày nghỉ |

- **Tốn token?** ~0 (đọc log, không gọi model nhiều). Mở bao nhiêu lần cũng được.
- **Version:** `/stats` mọi bản v2.x. `--by-task` bản mới 2026. Plan quota hiện tùy loại subscription.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/stats` + `/insights` | Số + nguyên nhân | Stats thấy spike → insights tìm thói quen |
| `/stats` + `/model` | Hết xăng thì xuống model rẻ | Quota 10% → chuyển Haiku làm việc nhẹ |
| `/stats` + `/doctor` | Đắt vì config phình | Spike do CLAUDE.md 300 dòng → doctor trim |

```bash
# Ritual: sáng /stats (còn bao nhiêu) → tối /stats --by-task (đắt vì đâu) → thứ 2 /insights (sửa gì)
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/stats` trống (0 token) | Nhầm profile/account, hoặc log mới xoá | Kiểm tra account đang login; đúng `~/.claude/` |
| Tiền hiển thị 0$ dù đã dùng | Plan unlimited/team tính khác | Xem quota % thay vì $; hỏi admin team |
| `--by-task` gom sai việc | Session đặt tên trùng/không tên | Đặt tên session rõ (`refactor-auth` thay vì `untitled-12`) |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../insights/README.md](../insights/README.md) — diễn giải + kê đơn từ số stats
  - [../cost/README.md](../cost/README.md) — chi tiết tiền (nếu có)
  - [../usage/README.md](../usage/README.md) — quota plan chi tiết (nếu có)
  - [../model/README.md](../model/README.md) — đổi model rẻ khi sắp cạn
  - [../doctor/README.md](../doctor/README.md) — vá config gây tốn
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../03-claude-md-memory-rules.md)
  - [../../05-skills-custom-commands.md](../../05-skills-custom-commands.md)
  - [../../06-subagents-agent-teams-parallel.md](../../06-subagents-agent-teams-parallel.md)
  - [../../07-hooks-tu-dong-hoa.md](../../07-hooks-tu-dong-hoa.md)
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../08-mcp-ket-noi-cong-cu-ngoai.md)
  - [../../09-plugins-marketplaces.md](../../09-plugins-marketplaces.md)

> Mẹo 1 dòng: _sáng nhìn xăng, tối tìm vòi rỉ, cache-hit dưới 40% là đang vứt tiền._
