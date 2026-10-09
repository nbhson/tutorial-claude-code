# 12 — Agent SDK, CI/CD & tự động hóa (print mode, routines, GitHub Actions)

> **Bài này cho ai:** dev muốn đưa Claude vào pipeline CI/CD, chạy non-interactive trong scripts, hoặc nhúng agent vào hệ thống nội bộ.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](./01-cai-dat-va-xac-thuc.md)); nên đọc [bài 05 — Skills](./05-skills-custom-commands.md) và [bài 07 — Hooks](./07-hooks-tu-dong-hoa.md) trước.
> **Đọc xong bạn làm được:**
> - Dùng print mode (`claude -p`) với guardrails hẹp cho scripts và CI.
> - Viết code mẫu Agent SDK (TypeScript/Python) với `canUseTool` và `settingSources`.
> - Deploy 2 GitHub Actions workflows (auto-review PR, overnight CI triage), biết khung GitLab.
> - Tạo 3 routines `/schedule` mẫu và thiết lập maintainable cho team.
> **Thời gian:** ~45 phút

## Thuật ngữ dùng trong bài này

Đọc bảng này trước khi vào mục 1 — mọi thuật ngữ Anh trong bài đều được giải thích ở đây.

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Print mode (`claude -p`) | Chạy Claude 1 câu không hỏi lại, in kết quả cho script đọc. | `claude -p "review diff" --output-format json --permission-mode dontAsk --allowedTools "Read, Grep, Glob, Bash"` |
| Agent SDK | Thư viện nhúng vòng lặp Claude vào app riêng (bot, backend, CLI nội bộ). | `query({prompt, options:{model:"sonnet", canUseTool}})` trong TypeScript mẫu |
| Routine (`/schedule`) | Việc Claude tự chạy theo giờ trên cloud khi vắng người. | `/schedule "7:30 weekdays"` gửi digest PRs vào Slack |
| CI/CD | Tích hợp liên tục & triển khai tự động (GitHub Actions, GitLab CI...). | Workflow auto-review PR mỗi khi mở/sync |
| Non-interactive | Chạy không cần người ngồi approve giữa chừng. | `-p` + `dontAsk` + allowlist hẹp |
| `canUseTool` | Callback trong Agent SDK quyết định cho phép/từ chối tool call. | Chỉ cho `Bash` chạy `git diff/log` hoặc `pnpm test/lint` |
| `settingSources` | Chọn nguồn config load (`project`, `user`, ...). | CI dùng `["project"]` để tránh load config cá nhân |
| Guardrails | Rào chắn bắt buộc: allowlist tools, permission mode, secrets qua env. | `--permission-mode dontAsk --allowedTools "Read,Grep,Glob,Bash"` |
| Harness | CLI Claude Code điều phối tools, hooks, permissions. | Chạy hook `PreToolUse` trong CI context |

## Mục lục

1. [Print mode (`-p`) — Claude cho scripts và CI](#1-print-mode--p--claude-cho-scripts-và-ci)
2. [Agent SDK — build agent riêng](#2-agent-sdk--build-agent-riêng)
3. [CI/CD: GitHub Actions & GitLab (không tắt guardrails)](#3-cicd-github-actions--gitlab-không-tắt-guardrails)
4. [Routines (`/schedule`) — việc định kỳ trên cloud](#4-routines-schedule--việc-định-kỳ-trên-cloud)
5. [Setup maintainable cho team + walkthrough + pitfalls + bài tập](#5-setup-maintainable-cho-team--walkthrough--pitfalls--bài-tập)
6. [Link chéo](#6-link-chéo)

---

## 1. Print mode (`-p`) — Claude cho scripts và CI

Mục này trả lời câu: khi nào dùng `claude -p` thay vì REPL trong pipeline, và làm sao để chạy non-interactive an toàn với guardrails hẹp.

CI runner không có người ngồi approve/deny. REPL hỏi giữa chừng = treo job tới timeout. `-p` + `dontAsk` + allowlist hẹp = deterministic: cho phép trước đúng thứ job cần, cấm phần còn lại, log JSON để step sau parse.

### 1.1. Vì sao `-p` chứ không phải REPL trong CI?

- **Non-interactive:** `-p` không mở dialog, output trực tiếp ra stdout.
- **Deterministic guardrails:** kết hợp `--permission-mode dontAsk` với `--allowedTools` tối thiểu.
- **Parse được:** dùng `--output-format json` hoặc `text` để step sau xử lý (`jq`, `sed`, ...).
- **An toàn:** secrets chỉ qua env runner, không hardcode trong prompt.

```bash
# Non-interactive, output text/JSON — giữ guardrails chặt chẽ
claude -p "review diff và in findings dạng JSON" \
  --output-format json \
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash"
```

- `PermissionRequest` hooks trong `-p` plain không có prompt (cần Agent SDK `canUseTool` callback hoặc `--permission-prompt-tool`); automate permission thì dùng **`PreToolUse`** hooks.
- Frontmatter hooks của project subagents: `-p` không tính là trusted → có thể bị skip (log sẽ ghi rõ).

### 1.2. 3 ví dụ `-p` copy-paste

```bash
# Ví dụ 1 — tóm tắt diff (text, nhanh)
claude -p "summarize git diff main...HEAD in 10 bullet points" \
  --output-format text \
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash"

# Ví dụ 2 — review JSON (parse bằng jq cho step sau)
claude -p "review git diff main...HEAD, output JSON: {findings: [{severity, file, line, msg, fix}]}" \
  --output-format json \
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash" | jq '.findings'

# Ví dụ 3 — healthcheck MCP (text summary, ≥2.1.205)
claude -p "/mcp" --output-format text
# → in servers + status. Gắn vào CI warmup: MCP down → fail fast.
```

**Kiểm tra nhanh:**

- Chạy ví dụ 2 local: pipe qua `jq '.findings | length'` → in ra số. Nếu `jq` báo `null`, prompt chưa ép đúng schema JSON (`severity,file,line,msg,fix`).
- Với allowlist hẹp (`Read,Grep,Glob,Bash` git-read-only), yêu cầu `rm -rf` → phải bị chặn (không thực thi).
- Nói được 3 khác biệt so với REPL: non-interactive, deterministic, parse được output.

---

## 2. Agent SDK — build agent riêng

Mục này trả lời câu: khi nào dùng Agent SDK thay vì `claude -p`, và cách dùng `canUseTool` + `settingSources` an toàn.

SDK bọc vòng lặp Claude (tools + permissions + orchestration) để bạn build workflow custom: full control tool access, orchestration, permission callbacks. Mặc định load `.claude/` từ CWD + `~/.claude/` (skills, commands, CLAUDE.md) — thu hẹp bằng `settingSources`.

### 2.1. Khi nào SDK vs `claude -p`?

| Nhu cầu | Chọn |
|---|---|
| 1 job review/audit trong CI | `claude -p` (đủ, ít code) |
| Multi-step orchestration custom (gọi tools riêng, UI riêng) | Agent SDK |
| Nhúng agent vào backend internal (Slack bot, dashboard) | Agent SDK |
| Việc định kỳ trên cloud | Routines `/schedule` (không cần code) |

### 2.2. SDK code mẫu (TypeScript — query + permissions callback)

```typescript
// examples/agent-review.ts — chạy: npx tsx examples/agent-review.ts
import { query } from "@anthropic-ai/claude-agent-sdk";

const result = await query({
  prompt: "Review git diff main...HEAD, trả về tối đa 10 findings dạng checklist.",
  options: {
    model: "sonnet",
    permissionMode: "dontAsk",
    allowedTools: ["Read", "Grep", "Glob", "Bash"],
    settingSources: ["project"], // chỉ load .claude/ project, bỏ ~/.claude/ personal
    // Automate permission (thay PermissionRequest prompt trong -p plain)
    canUseTool: async (tool, input) => {
      if (tool === "Bash") {
        const cmd = (input as { command: string }).command ?? "";
        // Chỉ cho git read-only + test focused
        if (/^(git (diff|status|log) |pnpm (test|lint) )/.test(cmd)) return { behavior: "allow" };
        return { behavior: "deny", message: "CI agent chỉ được git-read + test/lint." };
      }
      return { behavior: "ask" };
    },
  },
});

for await (const msg of result) {
  if (msg.type === "text") process.stdout.write(msg.text);
  if (msg.type === "result" && msg.isError) process.exitCode = 1;
}
```

```python
# examples/agent_review.py — Python tương đương (khung)
# pip install claude-agent-sdk
import asyncio
from claude_agent_sdk import query, Options

async def main():
    opts = Options(
        model="sonnet",
        permission_mode="dontAsk",
        allowed_tools=["Read", "Grep", "Glob", "Bash"],
        setting_sources=["project"],
    )
    async for msg in query("Review git diff main...HEAD, tối đa 10 findings.", opts):
        print(msg)

asyncio.run(main())
```

```bash
# Chạy SDK samples (copy-paste)
# TypeScript:
npx tsx examples/agent-review.ts
# Python:
python examples/agent_review.py
# Kiểm tra: findings in ra; canUseTool block đúng lệnh lạ (thử prompt yêu cầu rm -rf → phải deny)
```

**Kiểm tra nhanh:**

- Chạy TypeScript sample local → thấy findings in ra stdout. Thử prompt yêu cầu `rm -rf` → `canUseTool` trả deny, agent không chạy lệnh.
- Trong CI, set `settingSources: ["project"]` (tránh load `.claude/` cá nhân). Thử đổi sang `["project","user"]` chỉ để hiểu, không dùng trong CI.
- Chọn đúng: task multi-step UI/orchestration → SDK; 1 job audit → `claude -p`.

---

## 3. CI/CD: GitHub Actions & GitLab (không tắt guardrails)

Mục này trả lời câu: deploy 2 workflow an toàn cho GitHub Actions, biết khung GitLab tương đương, và tránh bẫy `bypassPermissions`.

Pattern: `claude -p` với scope hẹp + `dontAsk` + allowlist tools tối thiểu, secrets qua env runner. Có sẵn trên Sub/Console/Bedrock/AWS/GCP (Foundry ✗ — [bài 10](./10-permissions-modes-availability.md)). Setup chuẩn bị 1 lần (`Setup` hook event, `--init-only`/`--init`/`--maintenance` trong `-p`).

### 3.1. Workflow 1 — auto-review PR mới (hoàn chỉnh, copy-paste)

```yaml
# .github/workflows/claude-review.yml
name: claude-review
on:
  pull_request:
    types: [opened, synchronize]

permissions:
  contents: read
  pull-requests: write   # để post comment findings

jobs:
  review:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Setup Claude
        run: |
          curl -fsSL https://claude.ai/install.sh | bash
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"
        # Secrets: ANTHROPIC_API_KEY (Console) hoặc OAuth token (subscription).
        # Không bao giờ echo secrets ra log.

      - name: CI warmup (Setup hooks)
        run: claude --init-only
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Review diff (guardrailed)
        id: review
        run: |
          claude -p "Review git diff origin/${{ github.base_ref }}...HEAD. Output JSON: {findings: [{severity, file, line, msg, fix}]}. Tối đa 10 findings, chỉ lỗi thực sự." \
            --output-format json \
            --permission-mode dontAsk \
            --allowedTools "Read, Grep, Glob, Bash" > review.json
          cat review.json | jq '.findings'
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Post findings as PR comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const { findings = [] } = JSON.parse(fs.readFileSync('review.json', 'utf8'));
            const body = findings.length
              ? `## Claude Review (${findings.length})\n` + findings.map(f =>
                  `- **[${f.severity}]** \`${f.file}:${f.line}\` — ${f.msg}\n  Fix: ${f.fix}`).join('\n')
              : `## Claude Review\nKhông thấy issue.`;
            github.rest.issues.createComment({
              ...context.repo, issue_number: context.issue.number, body });
```

### 3.2. Workflow 2 — overnight CI failure analysis (hoàn chỉnh)

```yaml
# .github/workflows/claude-ci-triage.yml
name: claude-ci-triage
on:
  schedule:
    - cron: "0 22 * * *"   # nightly 22:00 UTC
  workflow_dispatch: {}     # + nút chạy tay

permissions:
  contents: read
  actions: read
  issues: write            # mở issue khi CI fail

jobs:
  triage:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Setup Claude
        run: |
          curl -fsSL https://claude.ai/install.sh | bash
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"

      - name: Analyze latest failures
        run: |
          gh run list --branch main --limit 5 --json conclusion,name,headSha > runs.json
          cat runs.json | jq '.'
          claude -p "Đọc runs.json (5 runs gần nhất main). Với runs failed: gh run view <id> --log-failed để lấy logs, tóm tắt root cause + đề xuất fix (tối đa 5 bullets/run). Output markdown." \
            --output-format text \
            --permission-mode dontAsk \
            --allowedTools "Read, Grep, Glob, Bash" > triage.md
          cat triage.md
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Open issue if failures found
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const body = fs.readFileSync('triage.md', 'utf8');
            if (/no failures|all passed/i.test(body)) { console.log('All green.'); return; }
            await github.rest.issues.create({
              ...context.repo, title: `CI triage ${new Date().toISOString().slice(0,10)}`, body, labels: ['ci'] });
```

```yaml
# GitLab CI tương đương (khung — .gitlab-ci.yml)
# claude_review:
#   image: node:22
#   script:
#     - curl -fsSL https://claude.ai/install.sh | bash
#     - export PATH="$HOME/.local/bin:$PATH"
#     - claude -p "review diff..." --output-format json --permission-mode dontAsk --allowedTools "Read, Grep, Glob, Bash"
#   rules: [{ if: '$CI_PIPELINE_SOURCE == "merge_request_event"' }]
# Secrets: ANTHROPIC_API_KEY via GitLab CI/CD variables (masked).
```

**Kiểm tra nhanh:**

- Deploy workflow 1 lên repo test, mở PR test → thấy comment review xuất hiện. Nếu comment trống, kiểm tra `review.json` đúng schema + `jq` đọc được.
- Với runner persistent, **không** dùng `bypassPermissions`. Luôn dùng `--permission-mode dontAsk --allowedTools "Read,Grep,Glob,Bash"`. `bypass` chỉ hợp sandbox ephemeral.
- Secrets: dùng `${{ secrets.ANTHROPIC_API_KEY }}` và GitHub masked vars; tuyệt đối không echo secrets ra log. GitLab dùng masked CI variables.
- GitLab/Foundry: check bảng availability trước khi hứa ([bài 10](./10-permissions-modes-availability.md)).

---

## 4. Routines (`/schedule`) — việc định kỳ trên cloud

Mục này trả lời câu: khi nào dùng routines thay vì CI, và viết prompt routine như skill để an toàn (chỉ báo cáo, không tự deploy).

Cần subscription (không phải API-key-only provider, trừ lưu ý theo [bài 10](./10-permissions-modes-availability.md)). Viết prompt routine như viết skill: steps + verify + output format; gắn skill để tái dùng. Từ v2.1.196: skill `disable-model-invocation: true` cũng không chạy khi scheduled task fire với skill làm prompt.

### 4.1. 3 routines mẫu (copy-paste prompts)

```text
# Routine 1 — Morning digest (7:30 sáng weekdays)
# /schedule "7:30 weekdays"
"Đọc 10 PRs/issues mới nhất repo acme/api (qua github MCP).
Trả digest: mỗi item 1 dòng (PR/issue + trạng thái + cần ai action).
Post vào Slack #eng-standup (qua slack MCP, format skill slack-post)."

# Routine 2 — Weekly dependency audit (sáng thứ 2)
# /schedule "monday 8:00"
"Chạy pnpm outdated + npm audit (read-only). Liệt kê: major updates (risk cao),
security advisories (severity + CVE), đề xuất 3 PRs riêng (không gộp).
Không tự update — chỉ báo cáo."

# Routine 3 — Docs sync sau merge (mỗi tối)
# /schedule "daily 21:00"
"git log main --since='24 hours' --oneline. Với mỗi feat/fix:
check docs/ có cập nhật tương ứng? Liệt kê docs thiếu (file nào, thiếu gì).
Không tự viết docs — mở checklist để người viết."
```

```text
# Quy tắc viết routine prompt (như viết skill — bài 05)
# - Steps numbered + lệnh cụ thể (gh pr list, pnpm outdated...).
# - Verify: "chỉ báo cáo, không tự sửa/deploy" (routine chạy vắng người!).
# - Output format: digest 10 dòng / markdown table / Slack format.
# - Gắn skill: "dùng skill slack-post/db-query" để tái dùng knowledge.
```

**Kiểm tra nhanh:**

- Tạo routine 1 trên cloud (nếu có access) → kiểm tra đúng giờ + format skill.
- Với routine có thể sửa code/deploy: prompt **phải** ghi rõ "chỉ báo cáo, không tự sửa/deploy". Routine vắng người → không được tự deploy.
- Chọn đúng: cần chạy trên cloud theo lịch + dùng MCP → routine; cần chạy trong repo runner + parse JSON → `claude -p` trong Actions.

---

## 5. Setup maintainable cho team + walkthrough + pitfalls + bài tập

Mục này trả lời câu: tổ chức `.claude/`, `.mcp.json`, CI, routines thế nào để maintain lâu dài; checklist 1 giờ; pitfalls; bài tập cuối khóa.

### 5.1. Cấu trúc đề xuất cho team

```text
.claude/
  CLAUDE.md (ngắn) + rules/ (path-scoped) + settings.json (team)
  skills/<workflow-lặp-lại>/  agents/<explorer|reviewer|tester>/  hooks/*.sh
.mcp.json (project servers, secrets qua env)
.github/workflows/claude-review.yml, claude-ci-triage.yml (hoặc GitLab)
Routines: /schedule cho việc định kỳ (cloud)
```

Nguyên tắc: facts mỗi session → CLAUDE.md; việc lặp → skill; cô lập → subagent; ngoài repo → MCP; phải-chạy-mỗi-lần → hook; share nhiều repo → plugin; lặp theo lịch → routine; nhúng hệ khác → SDK/CI.

### 5.2. Walkthrough setup team từ 0 (checklist 1 giờ)

```text
[ ] 1. /init + cắt CLAUDE.md <200 dòng (bài 03) — 15 phút
[ ] 2. settings.json team + personal (bài 10) — 10 phút
[ ] 3. 3 hooks: lint-on-write, block-main-push, session-context (bài 07) — 15 phút
[ ] 4. MCP GitHub + skill db-query nếu có DB (bài 08) — 10 phút
[ ] 5. 2 agents explorer/tester (bài 06) — 5 phút
[ ] 6. Workflow 1 CI review (mục 3.1) — 10 phút
[ ] 7. 1 routine morning digest (mục 4.1) — 5 phút
[ ] 8. claude doctor + /doctor verify hết xanh — 5 phút
```

### 5.3. Pitfalls + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| CI dùng `bypassPermissions` trên runner persistent | Copy mẫu sai context | `bypass` chỉ sandbox ephemeral; runner thường → `dontAsk` + allowlist hẹp |
| Secrets echo ra CI log | Debug quên redact | Secrets qua env, `set -x` off khi dùng secrets, GitHub masked vars |
| `-p` hooks bị skip lặng lẽ | Frontmatter project hooks untrusted trong `-p` | Log ghi rõ skip — chuyển sang settings.json hooks hoặc `--permission-prompt-tool` |
| Routine tự deploy khi vắng người | Prompt routine không giới hạn | Routine chỉ báo cáo/digest; deploy luôn cần người. Gắn `disable-model-invocation: true` nếu skill không nên chạy khi scheduled |
| SDK load cả `~/.claude/` personal vào CI | Default `settingSources` rộng | `settingSources: ["project"]` trong CI |
| GitLab/Foundry thiếu integration | Provider không hỗ trợ ([bài 10](./10-permissions-modes-availability.md)) | Check bảng availability trước khi hứa; fallback `claude -p` generic |

### 5.4. Bài tập thực hành (cuối khóa)

**Bài 1 (20 phút):** Chạy 3 lệnh `-p` mục 1.2 local. So sánh output text vs json. Viết 1 script shell parse JSON bằng `jq` cho step CI tiếp theo.

**Bài 2 (30 phút):** Deploy workflow 1 (mục 3.1) lên 1 repo test. Mở PR test, xem comment review. Tune prompt tới khi findings precision cao (ít false positive).

**Bài 3 (20 phút):** Chạy SDK sample (mục 2.2). Thử `canUseTool` block 1 lệnh nguy hiểm. Đổi `settingSources` và quan sát khác biệt skills load.

**Bài 4 (15 phút):** Tạo 1 routine `/schedule` digest (mục 4.1) trên cloud (nếu có access). Kiểm tra chạy đúng giờ, output format đúng, gắn skill vào routine.

**Bài 5 (30 phút, tổng):** Làm checklist 1 giờ (mục 5.2) cho team bạn. Chạy `claude doctor` cuối. Viết 1 trang retro ngắn: khóa này thay đổi workflow team bạn thế nào?

### 5.5. So sánh nhanh: lựa chọn đúng công cụ

| Lựa chọn | Hiểu nôm na | Ví dụ |
|---|---|---|
| `claude -p` | Sai vặt 1 lần cho script đọc | Review diff trong job GitHub Actions |
| Agent SDK | Nhúng vòng lặp Claude vào app riêng | Slack bot với `canUseTool` giới hạn |
| Routine `/schedule` | Việc tự chạy theo giờ trên cloud | Digest PRs 7:30 gửi Slack |
| GitHub Actions | Worker tự động gắn với repo | Auto-review PR mỗi `pull_request` |

### 5.6. Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật | Ví dụ sửa |
|---|---|---|
| CI dùng `bypassPermissions` cho nhanh | `bypass` chỉ sandbox ephemeral; runner thường phải `dontAsk` + allowlist hẹp | Dùng `--permission-mode dontAsk --allowedTools "Read, Grep, Glob, Bash"` |
| `PermissionRequest` sẽ hỏi người trong CI | `-p` plain không prompt; automate bằng `PreToolUse` hoặc `canUseTool` | Viết `PreToolUse` hook / `canUseTool` deny `rm -rf` |
| Routine tự deploy đêm cho tiện | Routine vắng người → chỉ báo cáo/digest, deploy cần người duyệt | Prompt ghi rõ "chỉ báo cáo, không tự sửa/deploy" |
| SDK tự load đúng config team | Mặc định load cả `~/.claude/` personal → CI phải `settingSources: ["project"]` | Set `settingSources: ["project"]` trong Options |

**Kiểm tra nhanh:**

- Chạy `claude -p` ví dụ JSON (mục 1.2) → parse được bằng `jq`, schema đúng như yêu cầu.
- Với SDK sample: thử block lệnh nguy hiểm bằng `canUseTool` → deny thành công; CI dùng `settingSources: ["project"]`.
- Chọn đúng tool theo case: "mỗi sáng gửi digest" → routine; "review PR trong Actions" → `claude -p`; "bot Slack custom UI" → SDK.
- Checklist 1 giờ (mục 5.2): tick đủ 8 bước, `claude doctor` xanh.

---

## 6. Link chéo

- **[Bài 00 — Tổng quan Claude Code](./00-tong-quan-claude-code.md)**: agentic loop + token economics (CI cũng trả token như session).
- **[Bài 01 — Cài đặt và xác thực](./01-cai-dat-va-xac-thuc.md)**: `claude update`, providers (API key vs subscription cho CI/routines).
- **[Bài 02 — Các bề mặt dùng (terminal/IDE/web/desktop)](./02-cac-be-mat-terminal-ide-web-desktop.md)**: `--cloud`, cloud env setup cho routines.
- **[Bài 03 — CLAUDE.md, memory & rules](./03-claude-md-memory-rules.md)**: facts vs rules, giữ CLAUDE.md < 200 dòng.
- **[Bài 04 — Slash commands toàn tập](./04-slash-commands-toan-tap.md)**: `-p` text-mode (`/mcp` summary), `/schedule`, `/loop`.
- **[Bài 05 — Skills](./05-skills-custom-commands.md)**: routines viết như skills; skill tái dùng cho CI jobs.
- **[Bài 06 — Subagents & agent teams](./06-subagents-agent-teams-parallel.md)**: Agent SDK orchestration custom; `canUseTool` callbacks.
- **[Bài 07 — Hooks](./07-hooks-tu-dong-hoa.md)**: Setup hooks (`--init-only`), PreToolUse cho `-p` automate permissions.
- **[Bài 08 — MCP: kết nối công cụ ngoài](./08-mcp-ket-noi-cong-cu-ngoai.md)**: MCP trong CI runners (env secrets, `serve` mode).
- **[Bài 09 — Plugins & marketplaces](./09-plugins-marketplaces.md)**: share SDK workflows + CI templates qua plugin.
- **[Bài 10 — Permissions & availability](./10-permissions-modes-availability.md)**: `dontAsk` vs `bypass` (chỉ sandbox); availability CI theo provider.
- **[Bài 11 — Git worktrees & checkpoints](./11-git-worktrees-checkpoints.md)**: CI checkout sạch tương đương worktree ephemeral.
- **[Bài 13 — Code intelligence, LSP & OpenTelemetry](./13-code-intelligence-lsp-opentelemetry.md)**: mở rộng giám sát cho agent trong pipeline.
- **[Bài 14 — Models: chọn model đúng](./14-models-5x-chon-model-dung.md)**: chọn model tiết kiệm/ổn định cho CI jobs.
- **[Bài 15 — Security stack 5 tầng](./15-security-stack-5-tang.md)**: guardrails CI ở tầng nào.
- **[Bài 16 — Mods & bảo mật validate](./16-mods-bao-mat-validate.md)**: validate CI configs trước merge.
