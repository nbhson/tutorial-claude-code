# /code-review — Skill review bằng subagent mới (fresh eyes) soi diff/PR

> Loại Skill/Workflow · Nhóm Code & Repo · Nguy hiểm Không (mặc định chỉ đọc + báo cáo; chỉ nguy hiểm nếu bạn bật auto-fix + bypass — luôn review trước khi apply)

`/code-review` là skill gọi 1 subagent HOÀN TOÀN MỚI (không biết lịch sử chat, không bênh code cũ) để soi diff hoặc PR: đọc từng hunk, check bug/logic/bảo mật/test, trả báo cáo critical/high/low. Khác `/review` (cùng agent tự chấm) ở chỗ mắt mới nên bắt được lỗi tư duy mà tác giả + agent cũ cùng mù.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/code-review` | _(không có)_ | Review diff chưa commit bằng subagent mới |
| `/code-review <PR>` | số PR / URL | Review pull request (VD `123`, `gh pr 123`) |
| `/code-review <file>` | đường dẫn | Review 1 file / 1 thư mục |
| `/code-review --fix` | (quy ước skill) | Review + đề xuất patch (không auto-apply trừ khi bạn duyệt) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: review diff hiện tại (trước merge nhánh)
/code-review
```

```bash
# Dạng 2: review PR cụ thể (copy-paste)
/code-review 123
```

```bash
# Dạng 3: review 1 module nhạy cảm
/code-review src/payments/
```

```bash
# Dạng 4: review có trọng tâm
/code-review --focus security src/auth/
```

```bash
# Dạng 5: review xong → fix có kiểm soát
/code-review
# → đọc báo cáo → pick 2 critical →
Sửa 2 critical CR-1 và CR-2 thôi, xong /diff cho tôi xem.
```

```bash
# Dạng 6: review trong CI (headless)
/* gh pr diff 123 | claude --print "Review diff này theo checklist security+correctness" */
gh pr diff 123 | claude --print "Review diff: liệt kê critical/high/low + file:dòng."
```

---

## Cách nó hoạt động

### Cơ chế sâu: fresh subagent là gì?

1. **Spawn agent mới tinh:**
   - Skill `/code-review` tạo subagent với context TRẮNG (không có lịch sử chat, không biết "ý đồ tốt" của tác giả).
   - Subagent được cấp: diff (git diff / gh pr diff), checklist review (correctness, security, perf, tests, style), quyền ĐỌC (không ghi mặc định).
2. **Pipeline soi 4 vòng:**
   - Vòng 1 — Correctness: logic sai? off-by-one? null? race? transaction thiếu?
   - Vòng 2 — Security: injection? XSS? auth bypass? secret hardcode? SSRF? mass-assignment?
   - Vòng 3 — Tests & Perf: thiếu test? N+1? p95 tăng? migration nặng không batch?
   - Vòng 4 — Style/Convention: có khớp CLAUDE.md + eslint không?
3. **Output chuẩn:**
   - Bảng `CRITICAL / HIGH / LOW` + `file:dòng` + mô tả + gợi ý fix + (tùy bản) patch đề xuất.
   - Không tự sửa trừ khi bạn gọi `--fix` và duyệt.
4. **Sao fresh tốt hơn cùng-agent?**
   - Nghiên cứu nội bộ + kinh nghiệm: cùng-agent bỏ sót ~30–50% lỗi tư duy gốc (vì nó "tin" hướng cũ). Fresh agent không có niềm tin đó nên hỏi lại từ đầu.
   - Giá: tốn thêm 1 lần khởi tạo (~3–8K tokens đọc diff) + 30–90s. Đáng cho PR > 100 dòng hoặc chạm tiền/auth.
5. **Giới hạn:**
   - Subagent không chạy app thật (không thay `/verify`). Nó đọc giấy.
   - Không hiểu business strategy ("hướng này có đúng roadmap không") — cần người duyệt.
6. **/code-review vs /review vs /ultrareview:**
   - `/review`: cùng agent, 15s, vừa — check nhanh.
   - `/code-review`: 1 fresh subagent, 1–2 phút, kỹ — trước merge.
   - `/ultrareview`: nhiều agents + cloud sandbox chạy thật, 5–15 phút, rất kỹ — audit lớn.

### Sơ đồ pipeline

```text
[/code-review 123] → fetch diff (git/gh)
  → spawn fresh subagent (context trắng, chỉ đọc)
  → vòng 1 correctness → vòng 2 security → vòng 3 tests/perf → vòng 4 style
  → báo cáo CRITICAL/HIGH/LOW + file:dòng
  → bạn pick issues → fix có kiểm soát → /diff → /verify
```

### Khác gì lệnh dễ nhầm? (nhắc lại cho rõ)

| Lệnh | Agent | Chạy app thật? | Sửa file? | Dùng khi nào? |
|---|---|---|---|---|
| `/review` | Cùng đứa | Không | Không | Sau mỗi bước nhỏ |
| `/code-review` | Subagent mới | Không (đọc giấy) | Không (mặc định) | Trước merge mọi PR đáng kể |
| `/ultrareview` | Multi-agent + sandbox | Có (sandbox) | Không | Audit bảo mật / tiền thật |
| `/verify` | Cùng đứa (+tools) | Có (máy bạn) | Không (chỉ chạy) | Sau fix, trước push |

> Quy tắc ngón tay cái:
>
> - **PR < 50 dòng, không chạm auth/tiền → `/review` đủ.**
> - **PR ≥ 100 dòng hoặc chạm auth/payments/migration → `/code-review` bắt buộc.**
> - **Release lớn / audit → `/ultrareview` + `/verify`.**

---

## Ví dụ thực tế

### Kịch bản 1: PR refactor auth 300 dòng — bắt 2 critical trước merge

Nhân viên mới refactor `src/auth/`, bạn không có 1 giờ đọc từng dòng.

```bash
# Bước 1: gọi skill
/code-review 128
```

> Báo cáo trả về (rút gọn):

```text
CRITICAL CR-1: src/auth/refresh.ts:57 — refresh token không rotation.
  Kẻ cắp dùng lại token cũ sau khi victim refresh. Fix: xoay + blacklist cũ.
CRITICAL CR-2: src/auth/login.ts:112 — so sánh timing (== thay vì timingSafeEqual).
HIGH H-1: thiếu test cho expired-token path.
LOW L-1..L-4: JSDoc, tên biến...
```

```bash
# Bước 2: chỉ fix critical, có kiểm soát
Sửa CR-1 và CR-2 theo gợi ý, thêm test cho H-1. Xong /diff cho tôi xem.
```

```bash
# Bước 3: duyệt + verify rồi mới merge
/diff
/verify
# → xanh → merge
```

### Kịch bản 2: Tự review code mình viết bằng AI (chống mù tác giả)

Bạn vừa để agent viết 200 dòng payments, chính bạn cũng chưa đọc kỹ.

```bash
/code-review src/payments/momo.ts
```

> Fresh agent phát hiện: webhook verify thiếu check timestamp (replay attack) — thứ cả bạn và agent viết đều bỏ qua vì cùng "nghĩ là ổn".

### Kịch bản 3: Review có trọng tâm bảo mật trước release

```bash
# Ngày mai release, chỉ còn 30 phút
/code-review --focus security src/auth/ src/payments/
```

> Output chỉ security, không lan man style — đọc 5 phút xong.

### Kịch bản 4: Gắn vào CI — mọi PR đều được soi tự động

```yaml
# .github/workflows/review.yml (rút gọn)
# Mỗi PR mở → chạy code-review headless, comment kết quả vào PR
```

```bash
gh pr diff 123 | claude --print "Bạn là reviewer. Checklist: correctness, security, tests. Output bảng CRITICAL/HIGH/LOW + file:dòng."
```

> Kết quả: PR nào cũng có 1 comment review máy trong 2 phút, người chỉ cần đọc critical.

---

## Rủi ro & lưu ý

### Tốn token?

- Mỗi review: diff size + ~5–10K overhead subagent. PR 300 dòng ≈ 15–25K tokens (~$0.05–0.10 sonnet, ~$0.30 opus).
- Dùng `sonnet + medium` cho review thường; chỉ `opus + high` cho audit bảo mật.
- Review 10 PR nhỏ/ngày bằng sonnet ≈ $0.50–1.00 — rẻ hơn 1 giờ lương reviewer.

### Destructive?

- Mặc định KHÔNG sửa (read-only). Nguy hiểm chỉ khi:
  1. Bạn bật `--fix` + `bypassPermissions` → subagent tự sửa hàng loạt không hỏi. ĐỪNG.
  2. Bạn paste cả diff chứa secret vào tool cloud lạ (nếu skill gọi MCP ngoài). Kiểm tra skill config trước.
- Quy tắc: review và fix là 2 bước riêng. Review xong, bạn pick issues, fix ở session chính với `acceptEdits`.

### Version floor & provider

- `/code-review` là skill — cần bản CLI hỗ trợ skills (v2.1.x mới). Bản cũ không thấy skill → dùng `gh pr diff | claude --print "review..."` thủ công (tương đương).
- Cần `gh` CLI auth để review PR số (`gh auth login` trước).
- Bedrock/Vertex: subagent spawn vẫn được, nhưng tools Bash trong subagent chịu cùng managed policy.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/diff` → `/code-review` | Tự xem rồi mời thanh tra | `/diff` → `/code-review` |
| `/code-review` → fix → `/verify` | Quy trình merge chuẩn | Review → sửa pick → `/verify` |
| `/review` (nhanh) → `/code-review` (kỹ) | Leo thang | Bước nhỏ `/review`, trước merge `/code-review` |
| `/code-review` → `/ultrareview` | PR thường vs audit lớn | PR thường code-review; release lớn ultrareview |
| `/plan` + `/code-review` | Plan lớn, review từng milestone | Xong milestone → `/code-review` |

Workflow chuẩn "merge PR an toàn":

```bash
# 1. Tự xem
/diff

# 2. Mắt mới soi
/code-review 123

# 3. Fix có chọn lọc (không fix ồ ạt low)
/* Sửa CR + HIGH, LOW để sau */

# 4. Duyệt lại
/diff

# 5. Chạy thật
/verify

# 6. Merge
# gh pr merge 123 --squash
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/code-review` báo `skill not found` | Bản cũ chưa có skills, hoặc skill chưa cài | Update CLI; kiểm tra `/skills` list; dùng `gh pr diff \| claude --print` thủ công |
| Review PR báo `gh: not authenticated` | Chưa `gh auth login` | `gh auth login` rồi chạy lại |
| Báo cáo chung chung, không có file:dòng | Diff quá lớn (>2000 dòng) hoặc effort thấp | Chia PR nhỏ; `/effort high`; chỉ định thư mục cụ thể |
| Subagent tự sửa file luôn | Bật --fix + bypass, hoặc prompt skill cho phép ghi | Tắt bypass; dặn "chỉ báo cáo, không sửa"; review `/diff` sau |
| Review PASS nhưng merge xong bug | Chỉ đọc giấy, không chạy thật | Luôn thêm `/verify` sau review; review không thay test |
| Review 10 phút chưa xong | PR khổng lồ + opus + high | Thu PR < 500 dòng; dùng sonnet cho vòng đầu, opus chỉ khi cần |
| Skill đọc cả file chứa secret | Diff chứa `.env` commit nhầm | Gỡ secret khỏi git ngay (git filter-repo), rotate key; thêm deny + gitignore |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../review/README.md](../review/README.md) — check nhanh cùng-agent (trước khi gọi skill nặng)
  - [../ultrareview/README.md](../ultrareview/README.md) — audit sâu multi-agent + sandbox
  - [../diff/README.md](../diff/README.md) — tự xem trước khi mời review
  - [../verify/README.md](../verify/README.md) — chạy thật sau review giấy
  - [../effort/README.md](../effort/README.md) — high cho review bảo mật
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md` — subagent là gì, spawn ra sao
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md` — gắn review vào CI

> Mẹo 1 dòng: _tác giả không tự thanh tra — PR đáng kể nào cũng xứng đáng 1 `/code-review` mắt mới._
