# FAQ 10 — CI/CD, SDK, Routines & Web Nâng Cao

> Nhóm Automation & Cloud · 10 câu hỏi deep-dive · Đọc xong chạy CI an toàn, schedule routines, teleport lên cloud, build SDK khi cần

Mỗi câu có giải thích + lệnh/config copy-paste (kèm YAML ví dụ) + khi nào áp dụng.

---

## Bảng tổng hợp: chọn đường automation nào?

| Đường | Chạy ở đâu | Cần gì | Dùng khi nào |
|---|---|---|---|
| `claude -p` CI (dontAsk + allowlist) | Runner CI | Sub/Console/Bedrock/AWS/GCP (Foundry ✗) | Review, migrate, triage tự động |
| `Setup` hook event | CI/scripts 1 lần | `--init-only` / `--init` / `--maintenance` | Chuẩn bị môi trường trước task |
| Routines (`/schedule`) | Cloud Anthropic | Subscription (sign-in) | Digest sáng, dep audit, docs sync |
| `claude --cloud` + `/web-setup` | Cloud | `gh` CLI + environment | Task nặng, không muốn chạy local |
| Teleport (`/teleport`) | Terminal ↔ cloud | Subscription, sessions persist | Đổi máy giữa chừng |
| Agent SDK | App của bạn | Build agent riêng (tools+permissions+orchestration) | Quy trình đặc thù / UI riêng / nhúng internal |
| `claude mcp serve` | Máy bạn (stdio) | Expose Claude thành MCP server | Hệ khác gọi Claude như tool |
| Analytics (`/insights`, dashboard) | Team/Enterprise | Plan tương ứng | Đo habits, contribution theo plan |

---

## 1. Dùng Claude trong CI thế nào mà vẫn an toàn? (pattern + YAML)

**Giải thích.** Pattern an toàn 5 điểm: `-p` + `--output-format json` + `--permission-mode dontAsk` + `--allowedTools` hẹp + secrets từ runner env. Không `--dangerously-skip-permissions` ngoài sandbox. Provider hỗ trợ: Sub/Console/Bedrock/AWS/GCP — **Foundry ✗**.

**Lệnh copy-paste:**

```bash
claude -p "review diff" \
  --output-format json \
  --permission-mode dontAsk \
  --allowedTools "Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(npm test:*)"
```

**YAML ví dụ (GitHub Actions — review PR):**

```yaml
name: claude-review
on: [pull_request]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - run: curl -fsSL https://claude.ai/install.sh | bash
      - run: >
          claude -p "Review diff origin/main...HEAD, chỉ báo security + sai logic, bỏ qua style. Trả JSON."
          --output-format json
          --permission-mode dontAsk
          --allowedTools "Read Grep Glob Bash(git diff:*) Bash(git log:*)"
          > review.json
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      - run: python3 -c "import json; print(json.load(open('review.json'))['result'])"
```

**Khi nào áp dụng:** review/migrate/triage tự động. Secrets LUÔN từ runner env, không hardcode.

---

## 2. `Setup` hook event để làm gì? (`--init-only` / `--init` / `--maintenance`)

**Giải thích.** `Setup` chạy 1 lần để chuẩn bị môi trường cho CI/scripts — trước cả task chính. 3 flags trong `-p`:

| Flag | Việc | Dùng khi nào |
|---|---|---|
| `--init-only` | Chỉ chạy Setup rồi thoát (không làm task) | Warm cache, check env trước giờ G |
| `--init` | Chạy Setup rồi làm task luôn | CI job chuẩn |
| `--maintenance` | Bảo trì (dọn cache, update index...) | Cron đêm |

```bash
# CI job chuẩn: setup rồi review
claude -p "review diff" --init --output-format json --permission-mode dontAsk \
  --allowedTools "Read Grep Glob Bash(git diff:*)"

# Warm env đêm trước (không tốn task):
claude -p "" --init-only
```

**Ví dụ Setup script:** `npm ci` + `migrate test` + check `env` đủ → task chính chạy không kẹt thiếu đồ.

**Khi nào áp dụng:** CI nào cũng nên có Setup — task fail vì "thiếu npm ci" là lãng phí nhất.

---

## 3. Routines (`/schedule`) là gì? (task định kỳ trên cloud + verify)

**Giải thích.** Routines = task chạy định kỳ / gọi API / GitHub-event **trên cloud**: morning digest, CI analysis, dep audit, docs sync. Cần **subscription** (sign-in, không API-key-only). Viết prompt như skill + gắn verify (không thì nó "xong" mà không ai check).

```bash
# Trong session đã login Sub:
/schedule
# → tạo: morning digest 8h (tóm tắt PRs + CI đỏ + issues mới)
# → tạo: dep audit thứ 2 (list outdated + CVE, mở PR nếu patch)
# → tạo: docs sync (diff code vs docs, báo lệch)
```

**Mẫu routine prompt (copy-paste):**

```text
Mỗi sáng 8h: tóm tắt PRs mở + CI đỏ + issues mới (repo X).
Verify: mỗi mục kèm link. Không tự merge. Gửi digest về Slack #dev.
```

**Khi nào áp dụng:** việc lặp theo lịch mà hiện làm tay (digest, audit, sync). Không dùng routines cho việc 1 lần.

---

## 4. Bắt đầu cloud session từ terminal? (`/web-setup` + `claude --cloud`)

**Giải thích.** 2 bước: `/web-setup` (cần `gh` CLI: sync token, tạo environment) rồi `claude --cloud "<task>"`. Mode cloud: **Accept edits** (tự sửa + push branch) / **Plan** (chờ duyệt). Không có Bypass (xem FAQ 03 câu 3).

```bash
# 1. Chuẩn bị (1 lần/repo):
/web-setup
# → sync token qua gh, khai MCP servers + env vars + setup script cho cloud

# 2. Chạy:
claude --cloud "migrate endpoint X sang v2, mở PR"
# → cloud tự sửa + push branch (Accept edits) hoặc trình plan (Plan)
```

**Ví dụ:** laptop yếu, task nặng (migrate 30 files) → đẩy lên cloud Accept edits, cà phê xong về check PR.

**Khi nào áp dụng:** task nặng/máy yếu/cần chạy xa + đã cấu hình environment (FAQ 04 câu 9).

---

## 5. Teleport là gì? (chuyển session terminal ↔ cloud, persist cross-device)

**Giải thích.** `/teleport` chuyển session đang làm dở giữa terminal ↔ cloud (`/teleport` resume remote từ claude.ai). Sessions **persist cross-device** — bắt đầu ở công ty, tối về nhà resume tiếp.

```bash
# Đang làm ở terminal, muốn lên cloud:
/teleport
# → session lên cloud, tiếp tục y mạch

# Ở nhà mở claude.ai → resume session sáng nay
/teleport
```

**Ví dụ:** chiều review PR ở terminal (30 turns), tối teleport lên cloud cho nó chạy tests nặng qua đêm, sáng resume lấy kết quả.

**Khi nào áp dụng:** đổi máy/đổi mạng giữa task + task dài cần chạy qua đêm.

---

## 6. Agent SDK khi nào? (quy trình đặc thù / UI riêng / nhúng internal)

**Giải thích.** Mặc định Claude Code đã đủ (load `.claude/` + `~/.claude/`). Chỉ build SDK khi: quy trình quá đặc thù (pipeline riêng), cần UI riêng (dashboard nội bộ), nhúng internal (bot Slack/Teams riêng). Thu hẹp scope bằng `setting_sources` (không load hết config user).

```python
# Ý tưởng (pseudocode, đọc SDK docs cho API thật):
agent = ClaudeAgent(
    tools=["Read", "Grep", "Glob"],       # hẹp nhất có thể
    permissions={...},                     # allowlist rõ
    setting_sources=["project"],           # chỉ .claude/, không ~/.claude/
)
result = agent.run("triage ticket X")
```

**Khi nào KHÔNG dùng SDK:** chỉ cần automation đơn giản → `claude -p` trong CI là đủ (câu 1). SDK là khi `-p` không diễn tả nổi pipeline.

**Khi nào áp dụng:** team platform/internal-tools, nhu cầu nhúng thật. Còn lại → `-p` + routines.

---

## 7. `claude mcp serve` là gì? (biến Claude thành MCP server)

**Giải thích.** `claude mcp serve` expose chính Claude Code thành **1 MCP stdio server** cho hệ khác gọi — đảo vai: thường Claude gọi MCP, giờ hệ khác gọi Claude như tool.

```bash
# Expose Claude cho hệ khác (VD: IDE lạ, bot nội bộ):
claude mcp serve --transport stdio
# → hệ khác add như 1 MCP server stdio bình thường
```

**Ví dụ:** bot Slack nội bộ cần "hỏi codebase" → add `claude mcp serve` làm backend, bot gọi tools Claude expose.

**Khi nào áp dụng:** tích hợp chéo hệ (hiếm). Đa số chỉ cần Claude gọi MCP (FAQ 04), không cần chiều ngược.

---

## 8. Analytics cho team? (`/insights`, `/stats`, dashboard, API theo plan)

**Giải thích.** Đo theo plan (càng cao càng sâu):

| Công cụ | Ra gì | Plan |
|---|---|---|
| `/stats` | Token/tiền cá nhân | Mọi plan |
| `/insights` | HTML habits (giờ nào tốn, skill nào dùng) | Sub+ |
| Dashboard | Contribution metrics team | Team/Enterprise |
| Enterprise Analytics API | Pull metrics về BI nội bộ | Enterprise |
| Server-managed settings / SSO / SCIM | Quản lý tập trung | Theo plan (bài 10 phần 1 FAQ 01) |

```bash
/stats       # tôi tốn bao nhiêu
/insights    # thói quen team (HTML)
/extra-usage  # usage vượt gói?
```

**Khi nào áp dụng:** cuối sprint `/insights` 1 lần (skill nào không ai dùng → xóa; ai tốn 3x → coaching). Enterprise → cắm API về dashboard sẵn có.

---

## 9. CI YAML hoàn chỉnh: doctor-gate + secret-check + review?

**Giải thích.** Gộp 3 jobs vào 1 workflow: (1) secret-check (rẻ, chạy trước), (2) doctor-gate (điểm <70 chặn merge), (3) review (đắt nhất, chạy sau cùng).

```yaml
name: claude-ci
on: [pull_request]
jobs:
  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: git grep -E 'ghp_|sk-ant_|xoxb-|AKIA' -- .mcp.json .claude/ . && exit 1 || echo "secrets clean"
  doctor-gate:
    runs-on: ubuntu-latest
    needs: secrets
    steps:
      - uses: actions/checkout@v4
      - run: curl -fsSL https://claude.ai/install.sh | bash
      - run: claude /doctor --json > doctor.json
        env: { ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }} }
      - run: python3 -c "import json,sys; d=json.load(open('doctor.json')); print(d['score']); sys.exit(1 if d['score']<70 else 0)"
  review:
    runs-on: ubuntu-latest
    needs: doctor-gate
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - run: curl -fsSL https://claude.ai/install.sh | bash
      - run: >
          claude -p "Review diff, chỉ security + sai logic."
          --output-format json --permission-mode dontAsk
          --allowedTools "Read Grep Glob Bash(git diff:*)" > review.json
        env: { ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }} }
```

**Khi nào áp dụng:** team ≥3 người. Thứ tự rẻ-trước-đắt-sau để fail nhanh.

---

## 10. Checklist automation mới (CI/routine/cloud) trước khi bật?

**Giải thích.** Chạy checklist này trước khi schedule/bật bất kỳ automation nào:

```bash
# 1. Allowlist hẹp? (không bypass ngoài sandbox)
/permissions
# 2. Secrets từ env? (git grep rỗng?)
git grep -E 'ghp_|sk-ant_' -- .mcp.json .claude/ .
# 3. Chạy tay 1 lần xanh với đúng flags CI?
claude -p "<task>" --output-format json --permission-mode dontAsk --allowedTools "Read Grep Glob ..."
# 4. Headless-safe? (hooks không prompt — FAQ 05 câu 5)
/hooks
# 5. Verify gắn chưa? (ai check output? tests? human?)
/verify
```

**Khi nào áp dụng:** mọi routine/CI/cloud mới + mỗi quý rà lại automation cũ.

---

## Vẫn lỗi thì sao? (CI/SDK/web)

1. CI deny → allowlist hẹp-đúng + `dontAsk` (câu 1), không bypass.
2. Cloud thiếu đồ → `/web-setup` lại environment (câu 4, FAQ 04 câu 9).
3. Version lệnh lạ → `/status` + `claude update` (FAQ 01 câu 7).
4. Rate/provider → `/usage` + đổi key (Foundry không hỗ trợ `-p`).
5. `/debug` → chẩn đoán; `/bug` kèm `/status` + `doctor`.

```bash
claude -p "ping" --output-format json --permission-mode dontAsk --allowedTools "Read"
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/02-cac-be-mat-terminal-ide-web-desktop.md](../01-huong-dan-su-dung/02-cac-be-mat-terminal-ide-web-desktop.md) — dựng cloud environment
  - [../01-huong-dan-su-dung/commands/teleport/README.md](../01-huong-dan-su-dung/commands/teleport/README.md) — chuyển session terminal ↔ cloud
  - [../01-huong-dan-su-dung/commands/doctor/README.md](../01-huong-dan-su-dung/commands/doctor/README.md) — doctor-gate trong CI
  - [../01-huong-dan-su-dung/commands/insights/README.md](../01-huong-dan-su-dung/commands/insights/README.md) — analytics habits
  - [../01-huong-dan-su-dung/commands/stats/README.md](../01-huong-dan-su-dung/commands/stats/README.md) — đo tiêu thụ
  - [../01-huong-dan-su-dung/commands/status/README.md](../01-huong-dan-su-dung/commands/status/README.md) — provider/version cho CI
  - [../01-huong-dan-su-dung/commands/claude-api/README.md](../01-huong-dan-su-dung/commands/claude-api/README.md) — migrate/onboard API
- Bài tổng quan:
  - [../01-huong-dan-su-dung/12-agent-sdk-ci-cd-automation.md](../01-huong-dan-su-dung/12-agent-sdk-ci-cd-automation.md) — SDK + CI chi tiết
  - [../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md) — provider nào hỗ trợ CI
  - [../02-tips-thuc-chien/09-teamwork-chuan-hoa.md](../02-tips-thuc-chien/09-teamwork-chuan-hoa.md) — chuẩn hóa team + CI gates
- FAQ liên quan: [FAQ 01](01-tai-khoan-pricing-cai-dat.md) (provider), [FAQ 03](03-permissions-modes.md) (headless), [FAQ 09](09-bao-mat-quyen-rieng-tu.md) (CI an toàn).

> Mẹo 1 dòng: _CI thì dontAsk + allowlist hẹp + secrets từ env — và automation nào cũng phải có verify._
