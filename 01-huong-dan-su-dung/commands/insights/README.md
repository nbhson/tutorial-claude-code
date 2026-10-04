# /insights — Nhìn lại cách bạn làm việc: token đi đâu, thói quen nào tốn kém

> Loại Skill (phân tích) · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ đọc log local, không sửa, không gửi đi)

`/insights` phân tích lịch sử dùng Claude Code của bạn (từ log/transcript local): token đốt vào việc gì, giờ nào hiệu quả, lệnh nào dùng nhiều, thói quen nào phung phí (clear ít, Read file to, batch ẩu) — rồi gợi ý 3-5 thay đổi cụ thể tiết kiệm nhất. Khác `/stats` (con số thô) — insights là "bác sĩ đọc kết quả xét nghiệm rồi kê đơn".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/insights` | _(không có)_ | Báo cáo tuần: token, top lệnh, top lãng phí + gợi ý |
| `/insights --month` | flag | Nhìn 30 ngày (cho lead/team) |
| `/insights --team` | flag | Gộp nhiều máy (cần share log) |

```bash
# Dạng 1: xem tuần của mình
/insights

# Dạng 2: nhìn tháng (chuẩn bị retro)
/insights --month

# Dạng 3: so cả team (mỗi người export log, gộp lại)
/insights --team
```

---

## Cách nó hoạt động

1. **Đọc gì?** Quét transcript `.jsonl` local (số tool-call, token in/out, lệnh dùng, giờ hoạt động). Không đọc nội dung code, không gửi ra ngoài.
2. **Tính gì?** Token theo việc (code/review/chat), top 5 lệnh, tỷ lệ cache-hit (dùng lại context tốt không), số lần `/clear` vs session dài lê thê, token/template (task lặp mà không dùng skill).
3. **Kê đơn:** xếp 3-5 gợi ý theo TIẾT KIỆM (VD "dùng skill X cho task lặp → tiết kiệm 30k/tuần", "clear mỗi 2h → giảm 20% input trùng").
4. **Không làm gì?** Không chấm code đúng/sai (việc của `/verify`), không audit config (việc của `/doctor`).

---

## Ví dụ thực tế

### Kịch bản 1: Dev thấy bill cao — tìm vòi rỉ

```bash
/insights
# → "Tuần này 1.2M token. 40% vào Read file dump.sql lặp 12 lần.
#    Đơn: thay Read dump bằng Grep + head, dùng /compact mỗi 2h.
#    Tiết kiệm ước tính 400k/tuần (~30%)."
```

### Kịch bản 2: Lead retro tháng — ai cần coaching gì

```bash
/insights --month
# → "Bạn A: batch 30 con general (đắt) → coaching dùng Explore.
#    Bạn B: không dùng skill team (0 lần) → nhắc.
#    Cả team: cache-hit 40% (thấp) → giữ CLAUDE.md ổn định, đừng sửa mỗi ngày."
```

### Kịch bản 3: Phát hiện task lặp chưa thành skill

```bash
/insights
# → "Viết commit message lặp 15 lần/tuần (mỗi lần 2k) → làm skill commit-team 1 lần,
#    từ tuần sau mỗi lần chỉ 300 token. Hoàn vốn sau 1 tuần."
# → Soạn SKILL.md theo đơn, tuần sau insights xác nhận tiết kiệm thật.
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Share log team dính secret | Transcript có key bạn paste vào chat | `--anonymize` trước khi gộp; đừng paste secret vào chat ngay từ đầu |
| Tin số mù (tuần nghỉ lễ token thấp) | Kết luận sai "hiệu quả tăng" | So cùng bối cảnh (tuần làm việc vs tuần làm việc) |
| Tối ưu số mà quên chất | Ép token thấp → trả lời cụt, làm lại nhiều | Mục tiêu: token/VIỆC XONG, không phải token thấp nhất |

- **Tốn token?** 1 báo cáo ≈ 3-8k (đọc log local). 1 lần/tuần là đủ.
- **Version:** skill `insights` v2.x. `--team` bản mới 2026.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/insights` + `/stats` | Số thô + đơn thuốc | Stats xem bao nhiêu, insights xem vì sao |
| `/insights` + `/doctor` | Thói quen xấu do config xấu | Insights chỉ Read lặp → doctor tách rules |
| `/insights` + `/memory` | Biến gợi ý thành luật | "Luôn Grep dump thay vì Read" → memory |

```bash
# Ritual thứ 2 hàng tuần (10 phút): /stats (bao nhiêu) → /insights (vì sao + sửa gì) → 1 thay đổi nhỏ
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Báo cáo trống/không có dữ liệu | Log bị xoá hoặc profile khác | Kiểm tra `~/.claude/projects/`; đúng user/profile |
| Số token lệch với bill | Bill tính cả API trực tiếp, insights chỉ CLI local | So với `/stats` cùng nguồn; bill cloud xem console riêng |
| `--team` thiếu người | Ai đó chưa export log | Quy ước: mỗi người export thứ 2 đầu tuần |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../stats/README.md](../stats/README.md) — con số thô (insights diễn giải)
  - [../doctor/README.md](../doctor/README.md) — vá config theo đơn
  - [../compact/README.md](../compact/README.md) — thói quen compact tốt
  - [../cost/README.md](../cost/README.md) — tiền (nếu có lệnh cost)
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../03-claude-md-memory-rules.md)
  - [../../05-skills-custom-commands.md](../../05-skills-custom-commands.md)
  - [../../06-subagents-agent-teams-parallel.md](../../06-subagents-agent-teams-parallel.md)
  - [../../07-hooks-tu-dong-hoa.md](../../07-hooks-tu-dong-hoa.md)
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../08-mcp-ket-noi-cong-cu-ngoai.md)
  - [../../09-plugins-marketplaces.md](../../09-plugins-marketplaces.md)

> Mẹo 1 dòng: _stats cho số, insights cho đơn — uống 1 viên mỗi tuần._
