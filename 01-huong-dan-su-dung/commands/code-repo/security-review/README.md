# /security-review — Lượt quét bảo mật on-demand trên branch hiện tại

> Loại Built-in · Nhóm Review & Bảo mật · Nguy hiểm Không (chỉ đọc + báo cáo; nhưng Có nếu bạn auto-apply fix bảo mật mà không review — patch sai có thể mở lỗ hổng mới)

`/security-review` chạy một lượt kiểm tra bảo mật theo yêu cầu (on-demand) trên branch hiện tại: soi diff + file nhạy cảm, xếp hạng lỗ hổng theo mức độ, gợi ý patch từng chỗ (bạn duyệt mới sửa). Nó đi cặp với GitHub Action review PR tự động (comment inline từng dòng, lọc false-positive), nhưng lượt tay này sâu hơn vì bạn đối thoại được. Hiểu `/security-review` là hiểu "vòng check bảo mật trước khi gọi `/review` hay mở PR".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/security-review` | _(không có)_ | Quét full branch hiện tại vs base (main) + báo cáo + gợi ý fix |
| `/security-review --quick` | flag | Quét nhanh diff chưa commit (staged + unstaged, <1 phút) |
| `/security-review <path>` | đường dẫn file/thư mục | Chỉ quét 1 file hoặc 1 thư mục |
| `/security-review --sensitivity <mức>` | `low`, `medium`, `high` | Tune độ nhạy (ít báo ồn vs soi kỹ) |
| `/security-review --fix` | flag | Vừa quét vừa đề xuất patch áp dụng được (vẫn hỏi từng cái) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: quét full branch trước khi mở PR (khuyên dùng)
git push -u origin feat/payments
/security-review
```

```bash
# Dạng 2: quét nhanh code vừa sửa chưa commit
/security-review --quick
```

```bash
# Dạng 3: chỉ quét module nhạy cảm (auth, payments)
/security-review src/auth/
/security-review src/payments/stripe.ts
```

```bash
# Dạng 4: soi kỹ khi đụng tiền bạc / crypto / session
/security-review --sensitivity high
```

```bash
# Dạng 5: quét + xin patch áp dụng luôn
/security-review --fix
```

---

## Cách nó hoạt động

### Cơ chế sâu: một lượt security-review soi gì?

1. **Lấy phạm vi diff:**
   - Mặc định so branch hiện tại với base (`main`): `git diff main...HEAD` + file mới chưa track mà liên quan.
   - `--quick`: chỉ `git diff` (staged + unstaged), bỏ qua commit cũ — nhanh nhưng có thể sót lỗi từ commit trước đó trong cùng branch.
   - Chỉ quét `<path>`: giới hạn file, nhưng vẫn đọc lân cận (import của file đó) để hiểu ngữ cảnh.
2. **Checklist OWASP-ish theo stack:**
   - **Injection:** SQL string concat, `eval()`, `exec()`, template shell không escape, NoSQL `$where` từ input user.
   - **Auth/session:** JWT verify thiếu, cookie không `HttpOnly`/`Secure`/`SameSite`, reset-password token đoán được, phân quyền IDOR (`/orders/:id` không check owner).
   - **Secrets:** API key/token hardcode, `.env` lọt vào diff, private key trong repo, URL DB có password.
   - **XSS/CSRF:** `dangerouslySetInnerHTML` với data user, `innerHTML` trực tiếp, thiếu CSRF token ở mutation.
   - **Deps & config:** `npm install` package lạ, `curl | sh`, CORS `*`, debug endpoint còn mở ở production.
3. **Xếp hạng và lọc nhiễu:**
   - Mỗi finding có `CRITICAL / HIGH / MEDIUM / LOW` + file:dòng + lý do khai thác được (không báo chung chung "có thể không an toàn").
   - False-positive filtering: nếu code đã có guard (ví dụ dùng parameterised query, đã escape) thì hạ mức hoặc ghi rõ "đã mitigated — kiểm tra lại".
   - Tune sensitivity: `low` chỉ báo CRITICAL/HIGH; `medium` (mặc định) thêm MEDIUM; `high` báo cả LOW + pattern nghi ngờ (nhiều nhiễu hơn).
4. **Đề xuất fix kiểu áp dụng được:**
   - Mỗi finding kèm patch gợi ý (đoạn code thay thế), bạn duyệt từng cái — không tự sửa ngầm.
   - `--fix`: gom patch thành diff áp dụng 1 lần, vẫn hiện diff cho bạn review trước khi nhận.
5. **Khác gì GitHub Action review PR tự động?**

```text
/security-review (tay, trong session)          GitHub Action (tự động, trên PR)
├─ bạn đối thoại, hỏi sâu từng finding        ├─ comment inline từng dòng PR
├─ quét cả file chưa commit                   ├─ chỉ quét commit đã push
├─ tune sensitivity linh hoạt                 ├─ sensitivity cố định theo config repo
└─ dùng trước khi mở PR (chặn sớm)            └─ dùng sau khi mở PR (chặn muộn)
→ Quy trình chuẩn: /security-review trước → mở PR → Action quét lại lần 2
```

### Khác gì với lệnh review dễ nhầm?

| Lệnh | Soi gì? | Dùng khi nào? |
|---|---|---|
| `/security-review` | LỖ HỔNG bảo mật (injection, auth, secret) | Trước mỗi PR đụng auth/payment/PII |
| `/review` | ĐÚNG/SAI + chất lượng code chung | Sau khi code xong bất kỳ task nào |
| `/code-review` | Review theo PR/branch (góc team) | Khi đã có PR cần góc nhìn reviewer |
| `/ultrareview` | Review sâu nhiều vòng (tốn token) | Thay đổi kiến trúc lớn, cần soi kỹ |
| `/verify` | Chạy kiểm chứng code chạy đúng không | Sau khi sửa theo finding bảo mật |

> Quy tắc ngón tay cái:
>
> - **Sợ bị hack → `/security-review`. Sợ code xấu → `/review`. Sợ sai logic → `/verify`. Cả ba sợ → chạy cả ba theo thứ tự đó.**

---

## Ví dụ thực tế

### Kịch bản 1: Branch thêm thanh toán — quét full trước khi mở PR (15 phút)

```bash
# Vừa xong feature Stripe, chuẩn bị mở PR:
git status
# M  src/payments/stripe.ts
# M  src/auth/middleware.ts
# A  src/payments/webhook.ts

/security-review

# Báo cáo ví dụ:
# 🔴 CRITICAL src/payments/webhook.ts:42 — webhook không verify signature
#    (attacker giả event Stripe refund tiền tùy ý)
# 🟠 HIGH src/auth/middleware.ts:18 — JWT decode không verify (alg=none chấp nhận?)
# 🟡 MEDIUM src/payments/stripe.ts:87 — log full card number
# → [Yes] áp patch từng cái? [No] bỏ qua?
```

> Kết quả: bắt 3 lỗi trước khi reviewer nhìn thấy. Webhook không verify signature là lỗi kinh điển — lên production là mất tiền thật.

### Kịch bản 2: Quét nhanh trước khi commit (mỗi ngày)

```bash
# Sửa 2 file, chưa commit, muốn check nhanh:
git diff --stat
/security-review --quick
# → "2 file, 80 dòng. 1 MEDIUM: innerHTML với tên user (XSS nếu tên có <script>).
#    Patch: dùng textContent. Áp dụng? [Yes/No]"
```

> Kết quả: 1 phút chặn 1 XSS. `--quick` đủ cho vòng lặp hàng ngày; cuối branch vẫn chạy full 1 lần.

### Kịch bản 3: Chỉ quét module auth + tune high (audit quý)

```bash
# Audit quý, team quyết soi kỹ auth:
# Bước 1: quét sâu
/security-review src/auth/ --sensitivity high

# Bước 2: báo cáo có 2 HIGH + 5 LOW (3 LOW là nhiễu — đã có guard)
# Bước 3: fix HIGH ngay, LOW ghi ticket backlog

# Bước 4: quét lại xác nhận
/security-review src/auth/ --quick
# → "0 HIGH. Còn 2 LOW backlog. OK mở PR."
```

### Kịch bản 4: Kết hợp GitHub Action — chặn 2 lớp (team)

```yaml
# .github/workflows/claude-review.yml — quét tự động mỗi PR
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: anthropics/claude-code-action@v1
        with:
          # Action comment inline + lọc false-positive, config sensitivity trong repo
          prompt: "Security review this PR. Comment inline on real issues only."
```

```bash
# Flow của bạn (local) + Action (remote):
# 1. Local: /security-review --fix → sửa hết CRITICAL/HIGH
# 2. Mở PR → Action quét lại, comment inline dòng còn sót
# 3. Bạn reply từng comment của Action ngay trong PR
# → Lỗi local bắt sớm (rẻ), lỗi lọt lưới Action bắt lần 2 (đắt hơn nhưng còn hơn ra prod)
```

> Lưu ý: Action yêu cầu Claude Code bản mới nhất trong CI image — pin version mới, đừng để image cũ quét bằng rule cũ.

---

## Rủi ro & lưu ý

### `/security-review` KHÔNG thay thế review tay

| Hiểu lầm | Sự thật | Cách làm đúng |
|---|---|---|
| Quét xanh = an toàn tuyệt đối | Tool chỉ soi pattern + diff; logic nghiệp vụ (ai được refund bao nhiêu) chỉ người hiểu | Quét xong vẫn tự đọc lại flow tiền/quyền bằng mắt |
| Auto-apply hết patch là xong | Patch AI có thể sai ngữ cảnh (escape đúng chỗ sai, verify sai key) | Review từng diff patch như review code đồng nghiệp |
| Chỉ quét 1 lần đầu branch | Commit sau vẫn thêm lỗ hổng mới | Quét full 1 lần trước khi mở PR + `--quick` mỗi ngày |
| Sensitivity high luôn tốt | High báo nhiều nhiễu → bạn mệt → bỏ qua cả báo thật (alert fatigue) | Mặc định `medium`; `high` chỉ khi đụng tiền/auth/PII |

### Bổ sung: yêu cầu bản mới nhất

- Rule quét được cập nhật theo bản Claude Code. Bản cũ thiếu pattern mới (ví dụ rule cho framework mới, CVE mới).
- Trước khi quét branch quan trọng: kiểm tra đã update bản mới nhất (`/restart` sẽ offer version mới nếu có).
- Trong CI: pin image mới, đừng cache image 3 tháng rồi quét bằng rule cũ.

### Tốn token?

- 1 lượt full branch vừa (~500 dòng diff) ≈ 10-25k token. Branch to (2000+ dòng) có thể 40k+.
- Mẹo tiết kiệm: `--quick` hàng ngày (rẻ), full 1 lần cuối branch; tách PR nhỏ (<400 dòng) vừa dễ review tay vừa rẻ tiền quét.

### Version / provider

- `/security-review` on-demand: bản v2.x. Bản cũ chỉ có review chung (`/review`), không có pass bảo mật riêng.
- `--sensitivity`: v2.1+. Cũ hơn quét 1 mức cố định.
- Bedrock/Vertex: chạy được (quét local diff, không gửi code đi đâu ngoài model provider bạn đã cấu hình).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/security-review` + `/review` | Quét bảo mật trước, chất lượng sau | Security xanh → review chung |
| `/security-review` + `/verify` | Fix xong lỗ hổng, kiểm chứng chạy đúng | Áp patch → `/verify` build+test |
| `/security-review` + `/diff` | Đọc lại diff trước khi quét | `/diff` rà mắt → quét máy |
| `/security-review` + Action PR | Chặn 2 lớp local + remote | Local quét → mở PR → Action quét lại |
| `/security-review` + `/permissions` | Sợ tool quét làm bậy | Hẹp quyền shell trước khi `--fix` |

Workflow chuẩn "branch đụng auth/payment (30 phút)":

```bash
# 1. Đọc lại diff bằng mắt
/diff
# 2. Quét bảo mật + áp patch (duyệt từng cái)
/security-review --fix
# 3. Kiểm chứng patch không làm gãy app
/verify
# 4. Review chất lượng chung
/review
# 5. Mở PR → để Action quét lần 2
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Quét báo "no changes" dù vừa code | Branch chưa commit + không dùng `--quick`; mặc định so với base nên diff unstaged bị bỏ | Dùng `/security-review --quick` cho code chưa commit, hoặc commit rồi quét full |
| Toàn LOW nhiễu, không có gì thật | Sensitivity `high` trên code đã có guard đầy đủ | Về `medium`; đọc LOW lướt qua, chỉ fix khi chạm PII/tiền |
| Bỏ sót secret trong `.env` | `.env` trong `.gitignore` nên không nằm trong diff → tool không thấy | Tự `git grep -i "sk-\|api[_-]key" -- . ':!.git'` bằng mắt; thêm pre-commit hook quét secret |
| Patch `--fix` làm gãy test | Patch escape/verify sai ngữ cảnh framework bạn dùng | Rollback patch đó (`git checkout <file>`), sửa tay, chạy `/verify` lại |
| Action PR không comment | Workflow thiếu `fetch-depth: 0` (không lấy base) hoặc image CLI cũ | Sửa workflow lấy full history; pin CLI mới nhất |
| Quét branch to (3000 dòng) tốn quá nhiều token | PR quá lớn, tool phải đọc hết | Tách PR <400 dòng; quét từng module `/security-review <path>` |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../review/README.md](../../code-repo/review/README.md) — review chất lượng chung sau khi quét bảo mật xong
  - [../code-review/README.md](../../code-repo/code-review/README.md) — review góc PR/branch cho team
  - [../ultrareview/README.md](../../code-repo/ultrareview/README.md) — review sâu nhiều vòng khi thay đổi lớn
  - [../verify/README.md](../../code-repo/verify/README.md) — kiểm chứng patch bảo mật không gãy app
  - [../diff/README.md](../../code-repo/diff/README.md) — đọc diff bằng mắt trước khi quét máy
  - [../permissions/README.md](../../model-mode/permissions/README.md) — hẹp quyền trước khi cho `--fix` sửa code
- Bài tổng quan:
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — tự động hoá checklist bảo mật riêng
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md) — pre-commit hook quét secret bổ sung
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md) — MCP GitHub để Action đọc PR

> Mẹo 1 dòng: _quét máy trước mở PR, review mắt trước khi merge, và xanh máy không có nghĩa là xanh thật._
