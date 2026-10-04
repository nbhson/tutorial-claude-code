# /btw — Hỏi nhanh full-context, không tools, không thêm history (by-the-way)

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (không gọi tools, không sửa file, không ghi history — hỏi xong là quên)

`/btw` (by the way) là câu hỏi xen ngang: tận dụng full context hiện tại để trả lời nhanh 1 thắc mắc nhỏ — nhưng KHÔNG gọi tools (không đọc thêm file, không chạy lệnh) và KHÔNG thêm vào history hội thoại. Hỏi xong, phiên chính tiếp tục như chưa có gì xảy ra. Tiện cho "nhân tiện hỏi..." mà không muốn pollute mạch làm việc.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/btw <câu hỏi>` | text | Hỏi nhanh, không tools, không history |
| `/btw` | _(không có)_ | Mở коротко hỏi (tùy bản) |

Ví dụ:

```bash
# Dạng 1: hỏi khái niệm giữa lúc đang code (copy-paste)
/btw idempotency key trong payments là gì, giải thích 3 dòng?
```

```bash
# Dạng 2: hỏi về code ĐÃ có trong context (không cần đọc thêm)
/btw hàm charge() vừa xem có mấy tham số, cái nào optional?
```

```bash
# Dạng 3: nhờ tóm tắt nhanh để quyết tiếp
/btw tóm tắt 3 bullet: plan payments vừa lập định làm gì?
```

```bash
# Dạng 4: so sánh nhanh 2 phương án (không cần search)
/btw so sánh mutex vs atomic CAS cho worker pool này, cái nào hợp hơn?
```

```bash
# Dạng 5: KHÔNG dùng btw khi cần tools (làm thẳng)
/* SAI: /btw đọc file src/x.ts giúp tôi (btw không đọc file mới) */
/* ĐÚNG: hỏi trực tiếp (có tools): Đọc src/x.ts và tóm tắt. */
```

---

## Cách nó hoạt động

### Cơ chế sâu: sao không pollute history?

1. **No-tools:** `/btw` chặn mọi tool-call (Read/Grep/Bash...). Model chỉ dùng context ĐÃ có (file đã đọc, chat trước đó) để trả lời.
2. **No-history:** turn hỏi-đáp btw được đánh dấu ephemeral — không append vào conversation turns chính, không tính vào evaluator/goal loop, không ảnh hưởng `/compact` tóm tắt.
3. **Full-context:** khác với chat mới (trắng), btw THẤY toàn bộ context hiện tại — nên trả lời trúng về code bạn đang làm mà không cần paste lại.
4. **Khi nào btw từ chối?**
   - Câu hỏi cần đọc file mới / chạy lệnh / search web → btw báo "cần tools, hỏi trực tiếp đi" (hoặc trả lời nửa vời từ context cũ — đừng tin mù).
5. **Btw vs /fast vs hỏi thường:**
   - `/btw`: không tools + không history — hỏi xen ngang.
   - `/fast`: có tools (ít) + có history — việc vặt cần làm thật.
   - Hỏi thường: có tools (đủ) + có history — việc chính.

### Bảng quyết định

| Muốn... | Dùng gì? |
|---|---|
| Hỏi khái niệm, tóm tắt từ context có sẵn | `/btw` |
| Đọc thêm file / chạy lệnh / search | Hỏi trực tiếp (không btw) |
| Làm việc vặt thật (rename, format) | `/fast` |
| Cần lưu lại để sau này nhớ | Hỏi trực tiếp (có history) |

---

## Ví dụ thực tế

### Kịch bản 1: Đang review plan 8 bước, nhân tiện hỏi thuật ngữ

Bạn đang duyệt plan payments, gặp từ "idempotency" mà ngại ngắt mạch.

```bash
/btw idempotency key là gì, vì sao webhook MoMo cần nó? 3 dòng thôi.
# → trả lời gọn từ context payments đang có.
# → mạch plan không bị xen 1 turn dài, history sạch.
```

### Kịch bản 2: Quên chi tiết file vừa đọc 5 phút trước

```bash
/btw hàm createCharge() trong stripe.ts vừa đọc có tham số retry không?
# → model nhớ từ context (đã đọc file trước đó) → trả lời ngay.
# → nếu file CHƯA đọc bao giờ: btw không đọc mới được — phải hỏi trực tiếp.
```

---

## Rủi ro & lưu ý

- **Btw không đọc file mới:** hỏi về thứ chưa trong context → đáp án đoán mò. Quy tắc: chỉ btw về thứ đã đọc/đang thấy.
- **Không lưu:** ý hay từ btw sẽ mất (không history). Thấy hay → bảo "ghi ý này vào docs/..." bằng câu hỏi thường.
- Tốn ít tokens (~0.5–1K). Rẻ nhất trong mọi lệnh hỏi.
- Version: bản mới có `/btw`; bản cũ chưa có → hỏi thường ngắn gọn là tương đương 90%.

---

## Kết hợp trong workflow

| Combo | Khi nào | Mẫu |
|---|---|---|
| `/plan` + `/btw` | Duyệt plan, hỏi xen ngang không bẩn history | Plan dài + btw thuật ngữ |
| `/code-review` + `/btw` | Đọc báo cáo, hỏi nhanh 1 điểm | btw "CR-2 nghĩa là gì?" |
| `/btw` → hỏi thường | Nháp bằng btw, chốt bằng hỏi thật | btw so sánh → hỏi thường "triển khai phương án A" |

```bash
# Workflow:
/plan Thêm MoMo vào payments. Chỉ plan.
/btw strangler-fig là pattern gì? (hỏi xen, không bẩn plan)
/goal Xong khi pytest pass...
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/btw` trả lời sai về file X | File X chưa trong context, btw không đọc mới | Hỏi trực tiếp (có tools) để model đọc file rồi trả lời |
| `/btw` báo unknown command | Bản cũ chưa có | Hỏi thường ngắn gọn thay thế |
| Ý hay từ btw bị mất | Không history by design | Hỏi lại bằng câu thường + bảo ghi ra file |
| Lạm dụng btw cho việc cần làm thật | Nhầm btw với fast | Cần làm (sửa/chạy) → `/fast` hoặc hỏi thường, không btw |

---

## Tham khảo

- Lệnh liên quan:
  - [../fast/README.md](../../model-mode/fast/README.md) — việc vặt cần tools (khác btw không tools)
  - [../plan/README.md](../../model-mode/plan/README.md) — btw khi duyệt plan không bẩn history
  - [../code-review/README.md](../../code-repo/code-review/README.md) — btw hỏi nhanh về báo cáo
  - [../model/README.md](../../model-mode/model/README.md) — btw dùng model hiện tại
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _nhân tiện hỏi thì `/btw`, cần làm thật thì đừng btw._
