# /help — Trợ giúp tại chỗ: tra cứu lệnh, cú pháp, phím tắt trong 5 giây

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ hiển thị tài liệu, không thay đổi gì)

`/help` là "bảng chỉ dẫn dán tường": liệt kê slash commands khả dụng, cú pháp ngắn, phím tắt (như double-Esc), để tra ngay trong terminal mà không cần mở docs web.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/help` | _(không có)_ | Hiện danh sách lệnh + mô tả ngắn |
| `/help <lệnh>` | tên lệnh (tùy bản) | Hiện chi tiết lệnh đó (nếu bản bạn hỗ trợ) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở bảng tổng
/help
```

```bash
# Dạng 2: hỏi chi tiết 1 lệnh (nếu hỗ trợ, không thì hỏi trực tiếp)
/help rewind
# → nếu không ra, hỏi: "Giải thích /rewind và khác gì /clear?"
```

```bash
# Dạng 3: tra phím tắt
/help
# → tìm dòng "Esc Esc: mở checkpoint picker (rewind)"
```

```bash
# Dạng 4: người mới — đọc help rồi thử 3 lệnh an toàn
/help
/context
/todos
/cost
```

---

## Cách nó hoạt động

1. **Đọc registry local:** `/help` liệt kê lệnh built-in + skills/custom commands + plugins đang active trong session này (mỗi project/list khác nhau chút).
2. **Không gọi model:** render local, ~0 token, hiện ngay.
3. **Nội dung rút gọn:** mỗi lệnh 1-2 dòng. Muốn deep-dive thì đọc thư mục `commands/<slug>/README.md` này hoặc bài tổng quan.
4. **Phím tắt đi kèm:** các bản mới kèm `Esc Esc (rewind)`, `Ctrl+C (ngắt)`, `/` (gợi ý lệnh) trong cùng bảng.

| Kênh tra cứu | Khi nào dùng |
|---|---|
| `/help` | Tra nhanh trong lúc làm (5 giây) |
| `commands/<slug>/README.md` | Deep-dive từng lệnh (bộ này) |
| Bài `04-slash-commands-toan-tap.md` | Bản đồ toàn bộ + so sánh |

---

## Ví dụ thực tế

### Kịch bản 1: Người mới ngày đầu — biết 3 nút sinh tử trong 1 phút

```bash
/help
# → đọc thấy: /clear (xóa), /compact (nén), /rewind (quay lại), Esc Esc
# → thử ngay lệnh an toàn:
/context
# → hiểu % RAM, tự tin làm tiếp
```

### Kịch bản 2: Quên cú pháp resume/fork giữa ca

```bash
/help
# → thấy /resume, /fork, /branch trong list
# → khỏi mở browser, gõ tiếp luôn:
/resume payments-fix
```

---

## Rủi ro & lưu ý

- **Mất gì:** không có. An toàn tuyệt đối.
- **Tốn token:** 0.
- **Version:** mọi bản đều có, nhưng list trên bản cũ thiếu lệnh mới (rewind/branch/fork). Thấy thiếu → update CLI.
- **Hiểu nhầm:** `/help` chỉ vắn tắt — đừng dùng 2 dòng mô tả để quyết định ca risky (rewind/clear). Đọc deep-dive trước khi bấm.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/help` → `/context` | Mới vào: đọc help rồi đo RAM |
| `/help` → deep-dive | Tra nhanh rồi mở `commands/<slug>/README.md` khi cần chắc |
| Onboarding team | Ngày 1: `/help` + đọc 3 file clear/compact/rewind |

```bash
/help
# → rồi đọc:
/clear  → commands/session-context/clear/README.md
/compact → commands/session-context/compact/README.md
/rewind  → commands/session-context/rewind/README.md
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/help` thiếu lệnh mới (branch/fork) | CLI cũ | `npm i -g @anthropic-ai/claude-code` rồi `/help` lại |
| `/help <lệnh>` không ra chi tiết | Bản bạn chỉ hỗ trợ `/help` tổng | Hỏi trực tiếp: "Giải thích /<lệnh> + ví dụ" hoặc mở file deep-dive |
| Lệnh trong help gõ báo unknown | Lệnh của plugin/MCP đã tắt | Bật lại plugin/MCP hoặc xem bài plugins/MCP |
| Muốn docs tiếng Việt | Help built-in tiếng Anh | Đọc bộ `commands/*/README.md` (bộ này, tiếng Việt) |

---

## Tham khảo

- Lệnh liên quan (mở deep-dive sau khi tra help):
  - [../clear/README.md](../../session-context/clear/README.md) — xóa trắng
  - [../compact/README.md](../../session-context/compact/README.md) — nén giữ đà
  - [../rewind/README.md](../../session-context/rewind/README.md) — quay checkpoint (Esc Esc)
  - [../resume/README.md](../../session-context/resume/README.md) — mở lại phiên cũ
  - [../context/README.md](../../session-context/context/README.md) — đo RAM
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ đầy đủ (đọc sau help)
  - `../10-permissions-modes-availability.md` — quyền/modes cũng tra trong help
  - `../11-git-worktrees-checkpoints.md` — checkpoints mà help chỉ nhắc 1 dòng

> Mẹo 1 dòng: _quên gì gõ `/help` trước, Google sau — đáp án nằm sẵn trong terminal._
