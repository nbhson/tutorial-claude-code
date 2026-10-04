# /bug — Gói bug report gửi Anthropic: khi lỗi là của tool, không phải của bạn

> Loại Workflow (thu thập + đóng gói) · Nhóm Tri thức & Hệ thống · Nguy hiểm Có nếu ẩu (gói conversation gửi đi có thể chứa secret/code nội bộ — luôn review trước khi Send)

`/bug` thu thập mọi thứ cần để báo lỗi Claude Code: mô tả, bước tái hiện, log, version, transcript rút gọn — đóng thành 1 gói, bạn review rồi mới gửi (GitHub issue hoặc Anthropic support). Dùng khi `/debug` xong kết luận "tôi làm đúng, tool sai". Hiểu 1 câu: `/debug` tự xem, `/bug` gửi người ta xem.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/bug` | _(không có)_ | Mở wizard: mô tả → tái hiện → gói log → review → gửi |
| `/bug --anonymize` | flag | Tự che email/đường dẫn tuyệt đối/API key trong gói |
| `/bug --dry-run` | flag | Chỉ tạo gói local, không gửi (tự review/gửi tay) |

```bash
# Dạng 1: báo lỗi thường (wizard dẫn từng bước)
/bug

# Dạng 2: báo lỗi có che thông tin nhạy cảm (khuyên dùng)
/bug --anonymize

# Dạng 3: chỉ gói, tự gửi tay (repo nội bộ không gửi ra ngoài được)
/bug --dry-run
# → ra file /tmp/claude-bug-<ngày>.zip, tự đính kèm issue tay
```

---

## Cách nó hoạt động

### Cơ chế sâu: gói bug gồm gì, đi đâu?

1. **Wizard 4 bước:**
   - B1 — Mô tả: bạn gõ "lỗi gì, mong đợi gì" (1-3 câu) + bước tái hiện (1. mở X, 2. gõ Y, 3. thấy Z).
   - B2 — Thu thập: tool tự kéo version CLI, OS, model, 50 dòng log gần nhất, transcript RÚT GỌN (chỉ tool-call + lỗi, không full chat).
   - B3 — Review: hiện gói cho bạn đọc — ĐÂY LÀ BƯỚC QUAN TRỌNG NHẤT. Xoá secret/code nội bộ trước khi gửi.
   - B4 — Gửi: tạo GitHub issue (repo `anthropics/claude-code`) hoặc file zip `--dry-run`.
2. **Anonymize làm gì?** Quét `sk-ant-...`, `AKIA...`, email, `/Users/tên-thật` → thay bằng `***`. Không hoàn hảo — vẫn phải mắt thường bước review.
3. **Khi nào DÙNG / KHÔNG dùng `/bug`?**
   - DÙNG: crash, treo cứng tái hiện được, tool báo lỗi sai (permissions chặn dù đã allow), regression sau update.
   - KHÔNG dùng: model trả lời dở (đó là prompt/context — dùng `/debug`, `/doctor`), hỏi cách dùng (đọc docs/bài 04), lỗi code bạn viết (tự fix).
4. **Gói đi đâu?** Public GitHub issue = ai cũng đọc được. Code nội bộ/secret thì `--dry-run` + gửi kênh support riêng, đừng public.

---

## Ví dụ thực tế

### Kịch bản 1: Treo cứng tái hiện được — báo chuẩn 5 phút

```bash
# /debug xong: cứ gọi mcp__db__query là treo 180s, reconnect không hết, bản cũ không bị.
/bug --anonymize
# B1 mô tả: "mcp__db__query treo sau update 2.1.210, bản 2.1.205 OK. Tái hiện: /mcp add db ... rồi query bất kỳ."
# B3 review: kiểm tra không còn DSN/pass → Send
# → có link issue, dán vào PR nội bộ để team né bản lỗi
```

### Kịch bản 2: Lỗi nhạy cảm — dry-run gửi kênh riêng

```bash
# Lỗi lộ khi làm repo nội bộ, transcript dính tên khách hàng.
/bug --dry-run --anonymize
# → /tmp/claude-bug-2026-10-04.zip
# → mở zip kiểm tra tay, xoá file dính tên KH, rồi gửi support riêng (không public GitHub)
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Send mà không review (gói chứa secret) | CỰC NGUY HIỂM: key/code nội bộ public trên GitHub | LUÔN review B3; `--anonymize`; `git grep sk-` trước khi gửi |
| Báo "model dở" thành bug | Mất công, bị close issue | Phân biệt: tool sai (crash/treo/regression) mới `/bug`; model dở thì `/debug` + sửa prompt |
| Gói thiếu bước tái hiện | Maintainer không repro được → issue chết | Ghi 3 bước cụ thể (mở gì, gõ gì, thấy gì) + version CLI |

- **Tốn token?** Thu thập + anonymize ≈ 2-5k token/lần. Rẻ, nhưng đừng spam 10 issue/ngày.
- **Version:** `/bug` v2.x. Bản cũ báo tay qua GitHub (copy version từ `/stats` hoặc `claude --version`).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/debug` → `/bug` | Debug kết luận lỗi tool | Gói transcript từ debug gửi đi |
| `/doctor --json` + `/bug` | Kèm config khi báo | Đính kèm doctor JSON để maintainer thấy context |
| `/stats` + `/bug` | Kèm version/env | Copy version vào issue |

```bash
# Quy trình chuẩn: /debug (xác định lỗi tool) → /bug --anonymize (gói + review) → dán link issue vào ghi chú team
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/bug` báo unknown | CLI cũ | Update CLI; hoặc báo tay qua GitHub |
| Anonymize sót secret lạ (format riêng cty) | Pattern không biết | Review tay B3; thêm pattern vào `.claude/bug-ignore` nếu có |
| Issue bị close "need repro" | Thiếu bước tái hiện | Bổ sung 3 bước + clip/log, mở lại |
| Không gửi được (mạng cty chặn) | Firewall | `--dry-run` lấy zip, gửi từ máy khác |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../debug/README.md](../debug/README.md) — chẩn đoán trước khi báo
  - [../doctor/README.md](../doctor/README.md) — kèm doctor JSON vào issue
  - [../stats/README.md](../stats/README.md) — lấy version/env
  - [../mcp/README.md](../mcp/README.md) — lỗi MCP hay phải báo nhất
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../03-claude-md-memory-rules.md)
  - [../../05-skills-custom-commands.md](../../05-skills-custom-commands.md)
  - [../../06-subagents-agent-teams-parallel.md](../../06-subagents-agent-teams-parallel.md)
  - [../../07-hooks-tu-dong-hoa.md](../../07-hooks-tu-dong-hoa.md)
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../08-mcp-ket-noi-cong-cu-ngoai.md)
  - [../../09-plugins-marketplaces.md](../../09-plugins-marketplaces.md)

> Mẹo 1 dòng: _debug trước bug sau, anonymize rồi review bằng mắt rồi mới Send._
