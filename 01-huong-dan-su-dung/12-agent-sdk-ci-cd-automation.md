# 12 — Agent SDK, CI/CD & Tự Động Hóa (Print Mode, Routines, GitHub Actions)

> Bài cuối series 01. Đọc xong bạn có 2 GitHub Actions workflows hoàn chỉnh, SDK code mẫu,
> 3 routines mẫu, và setup maintainable cho team. Thời gian: ~45 phút.

## Mục lục

1. [Vì sao đưa agent vào pipeline? (why)](#1-print-mode--p--claude-cho-scriptsci)
2. [Print mode deep-dive](#1-print-mode--p--claude-cho-scriptsci)
3. [Agent SDK + code mẫu](#2-agent-sdk--build-agent-riêng)
4. [2 GitHub Actions workflows hoàn chỉnh](#3-cicd-github-actions--gitlab-không-tắt-guardrails)
5. [3 routines mẫu](#4-routines-schedule--việc-định-kỳ-trên-cloud)
6. [Setup maintainable + walkthrough + pitfalls + bài tập](#5-setup-maintainable-cho-team-tóm-tắt-cả-khóa)
7. [Link chéo](#6-link-chéo)

---

## 1. Print mode (`-p`) — Claude cho scripts/CI

```bash
# Non-interactive, output text/JSON — khóa guardrails, đừng nới lỏng
claude -p "review diff và in findings dạng JSON" \
  --output-format json \
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash"
```

- `PermissionRequest` hooks trong `-p` plain không có prompt (cần Agent SDK `canUseTool` callback
  hoặc `--permission-prompt-tool`); automate permission thì dùng **`PreToolUse`** hooks.
- Frontmatter hooks của project subagents: `-p` không tính là trusted → có thể bị skip (log sẽ ghi rõ).

### 1.1. Vì sao `-p` chứ không phải REPL trong CI? (why)

CI runner không có người ngồi approve/deny. REPL hỏi giữa chừng = treo job tới timeout.
`-p` + `dontAsk` + allowlist hẹp = deterministic: cho phép trước mọi thứ job cần, cấm rest,
log JSON để step sau parse.ACI pattern: `claude -p` với scope hẹp + `dontAsk`
  + allowlist tools tối thiểu, secrets qua env của runner.

### 1.2. 3 ví dụ `-p` copy-paste

```bash
# Ví dụ 1 — Summarize diff (text, nhanh):
claude -p "summarize git diff main...HEAD in 10 bullet points" \
  --output-format text \
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash"

# Ví dụ 2 — Review JSON (parse bằng jq cho step sau):
claude -p "review git diff main...HEAD, output JSON: {findings: [{severity, file, line, msg}]}" \
  --output-format json \
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash" | jq '.findings'

# Ví dụ 3 — Healthcheck MCP (text summary, ≥2.1.205):
claude -p "/mcp" --output-format text
# → in servers + status. Gắn vào CI warmup: MCP down → fail fast.
```

```bash
# Guardrails pattern (KHÔNG bao giờ nới trong CI):
# ✓ --permission-mode dontAsk (không phải bypassPermissions trừ sandbox ephemeral)
# ✓ --allowedTools hẹp (Read/Grep/Glob + Bash git-read-only)
# ✓ secrets qua env runner (${{ secrets.X }}), không hardcode prompt
# ✓ PreToolUse hooks cho automate permission (PermissionRequest không prompt trong -p plain)
```

---

## 2. Agent SDK — build agent riêng

- SDK bọc vòng lặp Claude (tools + permissions + orchestration) để bạn build workflow custom:
  full control tool access, orchestration, permission callbacks.
- Mặc định load `.claude/` từ CWD + `~/.claude/` (skills, commands, CLAUDE.md) — thu hẹp bằng `setting_sources`.
- Dùng khi: quy trình team quá đặc thù, cần UI riêng, cần nhúng vào hệ internal.

### 2.1. Khi nào SDK vs `claude -p`? (bảng)

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
    // Automate permission (thay PermissionRequest prompt trong -p plain):
    canUseTool: async (tool, input) => {
      if (tool === "Bash") {
        const cmd = (input as { command: string }).command ?? "";
        // Chỉ cho git read-only + test focused:
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
# examples/agent_review.py — Python tương đương (khung):
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
# Chạy SDK samples (copy-paste):
# TypeScript:
npx tsx examples/agent-review.ts
# Python:
python examples/agent_review.py
# Kiểm tra: findings in ra? canUseTool block đúng lệnh lạ? (thử prompt yêu cầu rm -rf → phải deny)
```

---

## 3. CI/CD: GitHub Actions & GitLab (không tắt guardrails)

- Có sẵn trên Sub/Console/Bedrock/AWS/GCP (Foundry ✗ — bài 10). Pattern: `claude -p` với scope hẹp + `dontAsk`
  + allowlist tools tối thiểu, secrets qua env của runner.
- Kịch bản hay: auto-review PR mới, phân tích CI failure overnight, weekly dep audit, sync docs sau merge.
- Setup chuẩn bị 1 lần (`Setup` hook event sinh ra cho mục đích này: `--init-only`/`--init`/`--maintenance` trong `-p`).

### 3.1. Workflow 1 — Auto-review PR mới (hoàn chỉnh, copy-paste)

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

### 3.2. Workflow 2 — Overnight CI failure analysis (hoàn chỉnh)

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
# GitLab CI tương đương (khung — .gitlab-ci.yml):
# claude_review:
#   image: node:22
#   script:
#     - curl -fsSL https://claude.ai/install.sh | bash
#     - export PATH="$HOME/.local/bin:$PATH"
#     - claude -p "review diff..." --output-format json --permission-mode dontAsk --allowedTools "Read, Grep, Glob, Bash"
#   rules: [{ if: '$CI_PIPELINE_SOURCE == "merge_request_event"' }]
# Secrets: ANTHROPIC_API_KEY via GitLab CI/CD variables (masked).
```

---

## 4. Routines (`/schedule`) — việc định kỳ trên cloud

```
Morning digest • Overnight CI failure analysis • Weekly dependency audit • Docs sync sau merge
```

- Cần subscription (không phải API-key-only provider, trừ note theo bảng bài 10).
- Viết prompt routine như viết skill: steps + verify + output format; gắn skill để tái dùng.
- Từ v2.1.196: skill `disable-model-invocation: true` cũng không chạy khi scheduled task fire với skill làm prompt.

### 4.1. 3 routines mẫu (copy-paste prompts)

```text
# Routine 1 — Morning digest (7:30 sáng weekdays):
# /schedule "7:30 weekdays":
"Đọc 10 PRs/issues mới nhất repo acme/api (qua github MCP).
Trả digest: mỗi item 1 dòng (PR/issue + trạng thái + cần ai action).
Post vào Slack #eng-standup (qua slack MCP, format skill slack-post)."

# Routine 2 — Weekly dependency audit (sáng thứ 2):
# /schedule "monday 8:00":
"Chạy pnpm outdated + npm audit (read-only). Liệt kê: major updates (risk cao),
security advisories (severity + CVE), đề xuất 3 PRs riêng (không gộp).
Không tự update — chỉ báo cáo."

# Routine 3 — Docs sync sau merge (mỗi tối):
# /schedule "daily 21:00":
"git log main --since='24 hours' --oneline. Với mỗi feat/fix:
check docs/ có cập nhật tương ứng? Liệt kê docs thiếu (file nào, thiếu gì).
Không tự viết docs — mở checklist để người viết."
```

```text
# Quy tắc viết routine prompt (như viết skill — bài 05):
# - Steps numbered + lệnh cụ thể (gh pr list, pnpm outdated...).
# - Verify: "chỉ báo cáo, không tự sửa/deploy" (routine chạy vắng người!).
# - Output format: digest 10 dòng / markdown table / Slack format.
# - Gắn skill: "dùng skill slack-post/db-query" để tái dùng knowledge.
```

---

## 5. Setup maintainable cho team (tóm tắt cả khóa)

```
.claude/
  CLAUDE.md (ngắn) + rules/ (path-scoped) + settings.json (team)
  skills/<workflow-lặp-lại>/  agents/<explorer|reviewer|tester>/  hooks/*.sh
.mcp.json (project servers, secrets qua env)
GitHub Actions: claude -p jobs (review/audit/sync)
Routines: /schedule cho việc định kỳ
```

Nguyên tắc: facts mỗi session → CLAUDE.md; việc lặp → skill; cô lập → subagent; ngoài repo → MCP;
phải-chạy-mỗi-lần → hook; share nhiều repo → plugin; lặp theo lịch → routine; nhúng hệ khác → SDK/CI.

### 5.1. Walkthrough setup team từ 0 (checklist 1 giờ)

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

### 5.2. Pitfalls + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| CI dùng `bypassPermissions` trên runner persistent | Copy mẫu sai context | `bypass` chỉ sandbox ephemeral; runner thường → `dontAsk` + allowlist |
| Secrets echo ra CI log | Debug quên redact | Secrets qua env, `set -x` off khi dùng secrets, GitHub masked vars |
| `-p` hooks bị skip lặng lẽ | Frontmatter project hooks untrusted trong `-p` | Log ghi rõ skip — chuyển sang settings.json hooks hoặc `--permission-prompt-tool` |
| Routine tự deploy khi vắng người | Prompt routine không giới hạn | Routine chỉ báo cáo/digest; deploy luôn cần người (`disable-model-invocation`) |
| SDK load cả `~/.claude/` personal vào CI | Default setting_sources rộng | `settingSources: ["project"]` trong CI |
| GitLab/Foundry thiếu integration | Provider không hỗ trợ (bài 10) | Check bảng availability trước khi hứa; fallback `claude -p` generic |

### 5.3. Bài tập thực hành (cuối khóa)

**Bài 1 (20 phút):** Chạy 3 lệnh `-p` mục 1.2 local. So sánh output text vs json. Viết 1 script
shell parse JSON bằng `jq` cho step CI tiếp theo.

**Bài 2 (30 phút):** Deploy workflow 1 (mục 3.1) lên 1 repo test. Mở PR test, xem comment review.
Tune prompt tới khi findings precision cao (ít false positive).

**Bài 3 (20 phút):** Chạy SDK sample (mục 2.2). Thử `canUseTool` block 1 lệnh nguy hiểm. Đổi
`settingSources` và quan sát khác biệt skills load.

**Bài 4 (15 phút):** Tạo 1 routine `/schedule` digest (mục 4.1) trên cloud. Check chạy đúng giờ?
Output format đúng? Gắn skill vào routine.

**Bài 5 (30 phút, tổng):** Làm checklist 1 giờ (mục 5.1) cho team bạn. Chạy `claude doctor` cuối.
Viết 1 trang retro: khóa này thay đổi workflow team bạn thế nào?

---

## 6. Link chéo

- **Bài 00 — Tổng quan**: agentic loop + token economics (CI cũng trả token như session).
- **Bài 01 — Cài đặt**: `claude update`, providers (API key vs subscription cho CI/routines).
- **Bài 02 — Surfaces**: `--cloud`, cloud env setup script cho routines.
- **Bài 04 — Slash commands**: `-p` text-mode (`/mcp` summary), `/schedule`, `/loop`.
- **Bài 05 — Skills**: routines viết như skills; skill tái dùng cho CI jobs.
- **Bài 06 — Subagents**: Agent SDK orchestration custom; `canUseTool` callbacks.
- **Bài 07 — Hooks**: Setup hooks (`--init-only`), PreToolUse cho `-p` automate permissions.
- **Bài 08 — MCP**: MCP trong CI runners (env secrets, `serve` mode).
- **Bài 09 — Plugins**: share SDK workflows + CI templates qua plugin.
- **Bài 10 — Permissions**: `dontAsk` vs `bypass` (chỉ sandbox); availability CI theo provider.
- **Bài 11 — Worktrees**: CI checkout sạch ≈ worktree ephemeral.
