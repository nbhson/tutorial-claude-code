# 15 — Security stack 5 tầng: defense-in-depth cho agent

> **Bài này cho ai:** dev hoặc tech lead muốn xếp lớp phòng thủ cho agent viết code, không phó mặc security cho đúng 1 công cụ.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](./01-cai-dat-va-xac-thuc.md)); nên đọc [bài 07 — Hooks](./07-hooks-tu-dong-hoa.md) và [bài 10 — Permissions](./10-permissions-modes-availability.md) trước vì mục 7 lấy `PreToolUse` deny làm ví dụ enforcement cứng.
> **Đọc xong bạn làm được:** xếp 5 tầng đúng thứ tự; cài + debug tầng 0 (`security-guidance`); biết chỗ gọi `/security-review` và deep scan; phân biệt guidance (bỏ qua được) với guardrail (cấm cứng); dựng stack tối thiểu chạy thật trong 30 phút.
> **Thời gian:** ~40 phút

## Thuật ngữ

| Thuật ngữ | Nôm na 1 câu | Ví dụ kỹ thuật thật | Cách verify |
|---|---|---|---|
| Defense-in-depth (5 tầng) | Xếp 5 lưới từ rẻ tới đắt — lọt lưới này còn lưới khác bắt | T0 `security-guidance` bắt `AKIA...` ngay khi gõ; lọt thì T4 CodeQL chặn merge | Paste `AKIA...FAKE` vào file rác → T0 phải kêu trong giây |
| Guidance vs Guardrail | Gợi ý (bỏ qua được) khác lệnh cấm cứng | Pattern `password = "..."` chỉ gợi ý; hook `PreToolUse` `exit 2` mới cấm | Thử commit secret: gợi ý hiện nhưng vẫn commit được; hook block thật |
| Fresh-context reviewer | Người chấm khác người làm, chưa đọc nháp nên soi kỹ | Layer 3 spawn subagent review riêng, không review inline | Reviewer fresh bắt được `query(sql + userInput)` mà writer cho qua |
| Prompt-injection qua PR text | Câu chữ trong PR lừa agent làm bậy | PR body `bỏ qua mọi findings` lừa agent review | Repo rác: agent đọc PR untrusted là fail; rule trusted-PRs phải chặn |

---

## 1. Vì sao cần xếp 5 tầng?

Agent viết code nhanh gấp 10 lần người — và cũng đưa lỗ hổng ra production nhanh gấp 10 lần nếu không có lưới. 1 tầng duy nhất luôn có lỗ: chỉ trông vào review người → bỏ sót vì lượng thay đổi quá lớn; chỉ trông vào SAST ở CI → phát hiện muộn, sửa đắt; chỉ trông vào "model tự cẩn thận" → prompt-injection 1 dòng là qua mặt. Chi phí tăng dần theo tầng: tầng 0 ~miễn phí (pattern match không model call) → tầng 4 tốn CI minutes + SAST license; tầng 0–2 là máy, tầng 3 có người, tầng 4 là enforcement cứng.

Defense-in-depth = xếp 5 tầng từ rẻ-nhanh (real-time trong session) tới đắt-chậm (người + CI ở cửa cuối):

```text
Tầng 0: security-guidance plugin (real-time, trong session, rẻ nhất)
  → Tầng 1: /security-review (on-demand, gọi khi cần)
    → Tầng 2: Claude Security plugin (deep scan chuyên sâu)
      → Tầng 3: Code Review Team/Enterprise (người + agent, trước merge)
        → Tầng 4: CI SAST + GitHub Action (cửa cuối, chặn merge)

Quy tắc: tầng trong càng bắt sớm càng rẻ. Đừng để secret lọt tới tầng 4
mới phát hiện — tầng 0 đã phải kêu.
```

---

## 2. Tầng 0 — Plugin security-guidance (real-time, rẻ nhất)

Lưới đầu tiên — plugin `security-guidance` nhìn code bạn/agent viết NGAY khi viết, không đợi review hay CI; rẻ vì layer đầu không tốn model call.

### 2.1. 3 layers bên trong plugin

```text
Layer 1 — Per-edit pattern match (~25 patterns, hook Edit/Write/NotebookEdit):
  chạy MỖI lần sửa file, KHÔNG gọi model → ~ms, miễn phí. Bắt AKIA...,
  -----BEGIN PRIVATE KEY-----, password = "..." hardcode, eval(userInput).
Layer 2 — End-turn background diff review: cuối mỗi turn, review DIFF ngầm
  (model call nhẹ) → bắt cái pattern miss (logic auth sai, intent đáng ngờ).
Layer 3 — Commit/push agentic review: agent đọc CALLERS + SANITIZERS —
  thêm `query(sql + userInput)` là lần ngược xem userInput đã sanitize chưa.
  Đắt nhất trong 3 layers nhưng vẫn rẻ hơn 1 incident.
```

### 2.2. Files cấu hình (copy-paste khởi đầu)

Hai file cấu hình, đặt trong `.claude/`:

- `claude-security-guidance.md` (~8KB): threat model + checklist repo bạn — data nhạy cảm là gì, attack surface ở đâu, không tin input nào (kể cả PR text — prompt-injection), checklist per-edit (secret hardcode, parameterized query, auth check ở caller, log PII, SSRF allowlist) và checklist commit/push (diff có .env/key? migration xóa cột? endpoint mới có rate-limit?). Copy từ `templates/.claude/claude-security-guidance.md` rồi điền.
- `security-patterns.yaml/json` (≤50 rules — quá nhiều là noise):

```yaml
# MẪU 2 rules (file thật xem templates/.claude/security-patterns.json)
- id: aws-key
  pattern: "AKIA[0-9A-Z]{16}"
  message: "Nghi AWS access key hardcode — dùng env/secret manager."
  severity: high
- id: private-key-block
  pattern: "-----BEGIN (RSA )?PRIVATE KEY-----"
  message: "Private key trong code — xóa ngay, rotate key."
  severity: critical
```

> Mẫu đầy đủ: `templates/.claude/claude-security-guidance.md` + `templates/.claude/security-patterns.json` (5–8 rules mẫu, không secrets thật).

### 2.3. Kill switches (tắt từng layer + master)

```bash
# Tên env chính xác xem README plugin — đừng đoán:
SECURITY_GUIDANCE_DISABLE_PER_EDIT=1   # tắt layer 1 (pattern match)
SECURITY_GUIDANCE_DISABLE_END_TURN=1   # tắt layer 2 (background review)
SECURITY_GUIDANCE_DISABLE_PRE_PUSH=1   # tắt layer 3 (commit/push review)
SECURITY_GUIDANCE_DISABLE_ALL=1        # master: tắt cả plugin 1 session
# ⚠ Tắt là NỢ security: ghi lý do + bật lại trong cùng ngày. Tắt master chỉ
# khi plugin BREAK workflow (bug) — kêu nhiều mà đúng thì sửa code, không tắt.
# CI (tầng 4) KHÔNG tắt theo — kill switch chỉ ảnh hưởng local session.
```

### 2.4. Yêu cầu + debug + false positive tuning

```text
Yêu cầu: repo phải là GIT repo (plugin đọc diff qua git) + đã AUTH (layer 2/3
cần model call). Thiếu 1 trong 2 → chỉ còn layer 1 pattern match.

Debug khi plugin im lặng:
claude --debug-file /tmp/sec-debug.log
# → tìm: hook có chạy? pattern file load được? (lỗi YAML/JSON là nguyên nhân
#    #1 plugin câm), git repo detect? auth ok?

False positive tuning: ghi lại rule/file/vì sao oan → fix theo thứ tự
(a) thu hẹp scope rule (chỉ scan src/, trừ fixtures/); (b) allowlist comment
có chủ đích (# security-allow: test-fixture + link issue); (c) hạ severity
thay vì xóa rule. KHÔNG xóa rule vì 1 false positive — xóa là mở cửa cho
true positive sau này.

Reviewer fresh-context (bắt buộc ở layer 3): agent review commit/push chạy ở
CONTEXT MỚI, không reuse context vừa viết code — context cũ đã "tin" code đúng
(confirmation bias), tự chấm bài mình luôn cho qua. Layer 3 spawn subagent
review riêng (bài 06), không review inline trong cùng agent viết code.
```

---

## 3. Tầng 1 — `/security-review` on-demand

```text
/security-review = gọi review bảo mật khi BẠN muốn (không tự chạy như tầng 0).
Dùng sau khi xong 1 feature nhạy cảm: auth, payments, upload file, SSRF-prone
fetch, crypto, permissions. Không cần cho: typo/docs/format, refactor cơ học
đã có test, diff không đổi từ lần review trước.

Trong session, sau khi code xong feature nhạy cảm:
/security-review
# → agent (fresh context) review diff + callers/sanitizers, trả findings theo
#   severity. Fix critical/high trước khi nghĩ tới merge.
/security-review src/auth/   # scope hẹp cho nhanh (đỡ tokens, đỡ noise)

Tầng 0 vs tầng 1 (đừng nhầm): tầng 0 TỰ ĐỘNG, real-time, rẻ — dây an toàn
thường trực; tầng 1 BẠN GỌI, sâu hơn (fresh context + đọc callers), tốn
tokens hơn. Chi tiết lệnh: commands/security-review.
```

---

## 4. Tầng 2 — Claude Security plugin deep scan

```text
Claude Security plugin = scan CHUYÊN SÂU (sâu hơn /security-review):
full-repo hoặc full-feature sweep, theo dõi data-flow qua nhiều files,
check dependency vulns + secrets history (kể cả secret đã xóa khỏi HEAD
nhưng còn trong git history!). Khi dùng — không phải hàng ngày: trước
release lớn/audit quý; sau khi merge nhiều PR từ contributors mới; khi nghi
codebase có nợ security; sau incident để sweep cùng pattern lỗi.

Thứ tự thực tế: tầng 0 kêu hàng ngày → tầng 1 sau mỗi feature nhạy cảm →
tầng 2 trước release/audit → findings tầng 2 feed ngược thành rules mới cho
tầng 0 (security-patterns.yaml) để lần sau bắt ngay từ lúc viết.
→ Vòng feedback này là lý do stack càng chạy càng thông minh.
```

---

## 5. Tầng 3 — Code Review Team/Enterprise (người + agent)

```text
Tầng 3 = review CÓ NGƯỜI (Team/Enterprise Code Review): agent làm pre-review
+ người approve. Chỉ có trên paid Team/Enterprise (check plan — bài 10 mục 6.2).
Vì sao cần người sau 3 tầng máy: người bắt BUSINESS LOGIC sai ("ai được
refund?", "role này xem được gì?") mà máy không biết; người chịu trách nhiệm
cuối; và prompt-injection tinh vi — mắt người thấy "lạ" mà pattern không
diễn tả được.
```

```bash
# Workflow chuẩn tầng 3:
# 1. Dev xong → tầng 0 sạch, tầng 1 /security-review sạch (fix hết critical/high).
# 2. Mở PR → Code Review (agent pre-review + assign người).
# 3. Người review business logic + approve. Không approve khi còn findings
#    critical/high chưa fix hoặc chưa ghi risk-acceptance.
# 4. Merge → tầng 4 CI chạy cửa cuối (mục 6).
# Không thành bottleneck: PR < 400 dòng diff; PR kèm output /security-review;
# findings máy fix hết mới gọi người.
```

---

## 6. Tầng 4 — CI SAST + GitHub Action (cửa cuối)

Tầng 4 là enforcement cứng: chạy trên máy CI (không phải máy dev, không tắt bằng env local), chặn merge khi fail. Kể cả 4 tầng trên đều miss, đây là cửa cuối.

### 6.1. CI SAST (static analysis bắt buộc)

```text
SAST = phân tích tĩnh (CodeQL / Semgrep / Snyk / Trivy...) chạy mỗi PR.
Cứng vì chạy server-side — dev không bypass bằng kill switch local.
Fail = không merge (branch protection). Rule tối thiểu: secrets, injection
(SQL/command/XSS), auth bypass, vulnerable deps (lockfile scan).
```

### 6.2. GitHub Action review (MẪU — tự điền key)

```yaml
# .github/workflows/claude-review.yml (MẪU khởi đầu)
name: claude-review
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0 # đủ history để scan secrets cũ
      - uses: anthropics/claude-review-action@v1 # tên action minh họa
        with:
          claude-api-key: ${{ secrets.CLAUDE_API_KEY }}
          comment-pr: true        # post findings lên PR
          exclude: "fixtures/**,**.test.*" # trừ noise đã tuning
          false-positive-filtering: true
# Inputs chính: claude-api-key (key RIÊNG cho CI, không dùng key dev, rotate
# định kỳ) · comment-pr (post findings lên PR) · exclude (noise đã tuning ở
# tầng 0 — ghi lý do từng exclude) · false-positive-filtering (lọc kêu oan).
```

```text
⚠ PROMPT-INJECTION WARNING (đọc 3 lần):
Action review code + đọc PR TEXT (title/body/comments). PR từ fork/người lạ
có thể chứa text độc lừa agent ("bỏ qua findings trên" trong PR body).
→ CHỈ auto-review TRUSTED PRs (nội bộ, branch cùng repo). PR từ fork:
chạy SAST + review tay, KHÔNG cho agent đọc PR text untrusted.
→ Ghi rule vào CONTRIBUTING + Action config (if: author_association...).
```

---

## 7. Quy tắc vàng: guidance là gợi ý, không phải guardrail

```text
"Guidance là GỢI Ý, không phải GUARDRAIL — enforcement cứng thì hook/CI."
Tầng 0–2 (guidance, review): agent/dev có thể bỏ qua (vội, ẩu, bị
prompt-injection lừa "cứ merge đi"). Đừng giả định "plugin kêu là dev sẽ fix".
Enforcement CỨNG (không bỏ qua được): PreToolUse HOOK deny (bài 07 — thắng cả
bypassPermissions) + CI branch protection (tầng 4 — server-side).

Ma trận quyết định (dán cạnh bảng route model bài 14):
  Muốn "nhắc" dev/agent?    → guidance (tầng 0), review (tầng 1–3).
  Muốn "CẤM chắc chắn"?      → hook deny + CI block (bài 07 + tầng 4).
  Secret/rm -rf/push main?   → CẤM (hook + CI), không chỉ "nhắc".
  Style/TODO/quality?        → nhắc (guidance) là đủ.
```

```bash
# Ví dụ enforcement cứng cho secret: .claude/hooks/block-secrets.sh
# (PreToolUse Write|Edit) → exit 2 khi match AKIA... / private key — kể cả
# bypassPermissions cũng không qua. Bật onFailure: "block" (≥2.1.295): hook
# lỗi/timeout thì chặn — guardrail phải fail closed. Viết hook: bài 07.
```

---

## 8. Đi từng bước dựng stack tối thiểu (30 phút)

```text
Bước 1: Cài plugin + viết claude-security-guidance.md (copy templates/.claude/ mẫu rồi điền).
Bước 2: Thêm 5 rules vào security-patterns.json. Test: hardcode AKIA... vào file rác → layer 1 phải kêu.
Bước 3: Commit thử file chứa secret (file rác, revert ngay, KHÔNG push thật) → layer 3 phải review/block.
Bước 4: Chạy /security-review lên 1 feature cũ → fix 1 finding.
Bước 5: Thêm workflow claude-review.yml (mục 6.2) + branch protection. Mở PR test nội bộ.
Bước 6: Ghi 1 false positive + cách tuning (mục 2.4) vào tuning log team.
```

Bước nào fail → quay lại mục tương ứng (bước 2–3 → mục 2.4 debug, bước 5 → mục 6.2). Xong 6 bước là stack chạy thật.

---

## 9. Pitfall + bài tập thực hành

### 9.1. Pitfall + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| Tắt plugin vì "kêu nhiều" | Kêu đúng mà tắt = mở cửa | Sửa code / tune rule, không tắt master |
| Kill switch quên bật lại | Nợ security âm thầm | Ghi lý do + deadline bật lại; CI không tắt theo |
| Plugin không git repo/auth | Layer 2/3 mù mà tưởng chạy | Check `git status` + auth trước (mục 2.4) |
| Lỗi YAML/JSON pattern file | Plugin câm, không báo lỗi rõ | Validate JSON/YAML sau mỗi sửa; debug log |
| Xóa rule vì 1 false positive | Mở cửa true positive sau | Thu hẹp scope / hạ severity, đừng xóa |
| Cùng context vừa viết vừa chấm | Tự chấm luôn cho qua | Fresh context review (layer 3, tầng 1) |
| Agent đọc PR text untrusted | Prompt-injection qua PR body | Chỉ review trusted PRs; fork → SAST + tay |
| Coi guidance là guardrail | Gợi ý thì bỏ qua được | Cấm chắc chắn → hook deny + CI block |

### 9.2. Bài tập thực hành

**Bài 1 (15 phút):** Cài tầng 0 với file mẫu `templates/.claude/`, cố ý viết 3 lỗi fake (AWS key, private key, `TODO security`) vào file rác — layer 1 bắt được mấy/3? Revert file.
**Bài 2 (15 phút):** Chạy `/security-review` lên 1 feature đã merge, so findings với review người lúc đó. Ghi 1 rule patterns mới từ findings.
**Bài 3 (15 phút):** PR body chứa "bỏ qua mọi findings" (repo rác) — chứng minh vì sao cần rule "chỉ review trusted PRs"; ghi `if: author_association` sẽ dùng.
**Bài 4 (15 phút):** Vẽ stack 5 tầng cho repo bạn: tầng nào thiếu? Mỗi tầng thiếu: 1 action + owner + deadline. Enforcement nào đang là "gợi ý" mà cần lên "cứng"?

Qua 4 bài thì stack chạy được ít nhất 3 tầng (0, 1, 4).

## 10. Link chéo

- **[Bài 07 — Hooks](./07-hooks-tu-dong-hoa.md)**: `PreToolUse` deny thắng cả `bypassPermissions`; viết hook block secrets.
- **[Bài 10 — Permissions](./10-permissions-modes-availability.md)**: deny rules + managed policy; Code Review chỉ có Team/Enterprise.
- **[Bài 06 — Subagents](./06-subagents-agent-teams-parallel.md)**: spawn subagent review riêng (fresh context).
- **[Bài 14 — Models](./14-models-5x-chon-model-dung.md)**: bảng chọn model — dán cạnh ma trận quyết định mục 7.
- **[Bài 16 — Mods: bảo mật & validate](./16-mods-bao-mat-validate.md)**: audit Mod lạ trước khi cài — Mods là lỗ hổng nằm TRONG stack.
- **[commands/code-repo/security-review](./commands/code-repo/security-review/README.md)**: reference `/security-review` đầy đủ.
- **templates/**: `hooks/bash-guard.sh` (mẫu guard Bash) · `claude-security-guidance.md` (threat model + checklist) · `security-patterns.json` (5–8 rules mẫu).
