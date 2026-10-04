# /review — Xin nhận xét nhanh từ model hiện tại (không tạo subagent mới)

> Loại Built-in · Nhóm Code & Repo · Nguy hiểm Không (chỉ đọc + nhận xét; không sửa file; dùng cùng context phiên hiện tại)

`/review` là "ê xem giúp code này ổn không": model hiện tại (cùng context, cùng lịch sử) đọc diff/code bạn chỉ định và cho nhận xét nhanh — bug, style, thiếu test. Nhanh gọn, nhưng cùng 1 bộ não nên dễ bỏ sót lỗi mà chính nó vừa gây ra. Muốn mắt mới thì dùng `/code-review`.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/review` | _(không có)_ | Review thay đổi hiện tại (diff chưa commit) |
| `/review <file/PR>` | đường dẫn / số PR | Review mục tiêu cụ thể |
| `/review --focus <mảng>` | `security`, `perf`, `style`... | Chỉ soi khía cạnh đó (quy ước, tùy bản) |

Ví dụ:

```bash
# Dạng 1: review diff vừa code
/review
```

```bash
# Dạng 2: review 1 file cụ thể
/review src/auth/login.ts
```

```bash
# Dạng 3: review có trọng tâm
/review --focus security src/payments/
```

```bash
# Dạng 4: tự xem trước rồi xin review (khuyên dùng)
/diff
/review
```

```bash
# Dạng 5: review trước khi đẩy PR
/review
# → sửa theo góp ý → /verify → mới git push
```

---

## Cách nó hoạt động

### Cơ chế sâu

1. **Cùng agent, cùng context:**
   - Không tạo subagent mới. Model dùng chính lịch sử hội thoại (biết bạn định làm gì) để chấm.
   - Ưu: nhanh (~15–30s), hiểu ý đồ, không tốn khởi tạo.
   - Nhược: "tự chấm bài mình" — lỗi tư duy ban đầu dễ bị bỏ qua cả 2 vòng.
2. **Đọc gì?**
   - Mặc định: diff chưa commit (`git diff` + edits session). Chỉ định file thì đọc file đó + lân cận import.
   - Output: danh sách issues theo mức (critical/major/minor) + gợi ý fix từng cái.
3. **Không sửa, không history mới:**
   - `/review` không ghi file, không tạo branch. Chỉ trả lời text.
4. **Phân biệt rõ 3 anh em:**
   - `/review`: thường, cùng agent, nhanh — check nhanh trước push.
   - `/code-review`: skill, subagent FRESH (không biết lịch sử) soi diff/PR — soi kỹ trước merge.
   - `/ultrareview`: deep multi-agent + cloud sandbox — audit lớn, tiền thật/bảo mật.

### Bảng phân biệt

| Lệnh | Agent | Context | Tốc độ | Độ kỹ | Dùng khi nào? |
|---|---|---|---|---|---|
| `/review` | Cùng đứa | Cùng history | Nhanh | Vừa | Check nhanh sau mỗi bước |
| `/code-review` | Subagent mới | Fresh (không nhiễm) | Vừa | Kỹ | Trước merge PR |
| `/ultrareview` | Nhiều agents + sandbox | Fresh + chạy thật | Chậm | Rất kỹ | Audit bảo mật/tiền thật |

---

## Ví dụ thực tế

### Kịch bản 1: Check nhanh trước khi push (3 phút)

```bash
# Vừa refactor login, muốn 1 vòng soi nhanh
/review
```

> Output: 2 minor (thiếu JSDoc, tên biến khó hiểu) + 0 critical → sửa 2 phút → push. Không cần gọi subagent nặng.

### Kịch bản 2: Soi bảo mật 1 file nhạy cảm (và biết giới hạn)

```bash
/review --focus security src/auth/refresh.ts
```

> Output: phát hiện refresh token không rotation. Nhưng nhớ: vì cùng agent vừa code file này, nên sau đó vẫn nên `/code-review` 1 lần trước merge để mắt mới soi lại.

---

## Rủi ro & lưu ý

- **Ảo tưởng "đã review":** `/review` PASS không có nghĩa code sạch — cùng bộ não dễ mù cùng chỗ. PR quan trọng phải thêm `/code-review`.
- Tốn ít tokens (1 review ~2–5K). Rẻ, cứ dùng sau mỗi bước.
- Không thay `/verify`: review chỉ đọc giấy, verify mới chạy thật.

---

## Kết hợp trong workflow

| Combo | Khi nào | Mẫu |
|---|---|---|
| `/diff` → `/review` | Tự xem rồi xin ý kiến | `/diff` → `/review` |
| `/review` → `/verify` | Ý kiến ok rồi chạy thật | `/review` → sửa → `/verify` |
| `/review` → `/code-review` | Nhanh trước, kỹ sau | `/review` (bước nhỏ) → `/code-review` (trước merge) |

```bash
# Workflow PR nhỏ:
/diff
/review
# → sửa minor
/verify
# git push
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/review` khen hết lời nhưng code vẫn bug | Cùng agent tự chấm, mù cùng chỗ | Thêm `/code-review` (mắt mới) + `/verify` (chạy thật) |
| Review chung chung ("code ổn, nên thêm test") | Không chỉ rõ file/phạm vi, effort thấp | `/review src/x.ts` cụ thể + `/effort high` |
| `/review` soi cả file không liên quan | Mặc định đọc cả diff lớn | Chỉ định file: `/review src/payments/stripe.ts` |
| Review xong model tự sửa luôn (không xin phép) | Đang auto/bypass | Về `acceptEdits`; dặn "chỉ nhận xét, chưa sửa" |

---

## Tham khảo

- Lệnh liên quan:
  - [../diff/README.md](../diff/README.md) — tự xem thô trước khi xin review
  - [../code-review/README.md](../code-review/README.md) — mắt mới soi trước merge (kỹ hơn)
  - [../ultrareview/README.md](../ultrareview/README.md) — audit sâu multi-agent
  - [../verify/README.md](../verify/README.md) — chạy thật sau review giấy
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _`/review` là hỏi bạn cùng phòng, `/code-review` là mời thanh tra — đừng nhầm 2 việc._
