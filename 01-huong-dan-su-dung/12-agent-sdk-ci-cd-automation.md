# 12 — Agent SDK, CI/CD & tự động hóa (print mode, routines, GitHub Actions)

> **Bài này cho ai:** dev muốn đưa Claude vào pipeline CI/CD, chạy non-interactive trong scripts, hoặc nhúng agent vào hệ thống nội bộ.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](./01-cai-dat-va-xac-thuc.md)); nên đọc [bài 05 — Skills](./05-skills-custom-commands.md) và [bài 07 — Hooks](./07-hooks-tu-dong-hoa.md) trước.
> **Đọc xong bạn làm được:** dùng `claude -p` với guardrails hẹp cho scripts/CI; viết code Agent SDK (TS/Python) với `canUseTool` + `settingSources`; deploy 2 GitHub Actions workflows; tạo routines `/schedule`; biết khi nào dùng `claude ultrareview` cho CI.
> **Thời gian:** ~45 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Print mode (`claude -p`) | Chạy Claude 1 câu không hỏi lại, in kết quả cho script đọc | `claude -p "review diff" --output-format json --permission-mode dontAsk` |
| Agent SDK | Thư viện nhúng vòng lặp Claude vào app riêng (bot, backend, CLI nội bộ) | `query({prompt, options:{canUseTool}})` trong TypeScript |
| Routine (`/schedule`) | Việc Claude tự chạy theo giờ trên cloud khi vắng người | `/schedule "7:30 weekdays"` gửi digest PRs vào Slack |
| `canUseTool` | Callback trong Agent SDK quyết định cho/từ chối tool call | Chỉ cho `Bash` chạy `git diff/log` hoặc `pnpm test/lint` |
| `settingSources` | Chọn nguồn config load (`project`, `user`, ...) | CI dùng `["project"]` để tránh load config cá nhân |
| Guardrails | Rào chắn bắt buộc: allowlist tools, permission mode, secrets qua env | `--permission-mode dontAsk --allowedTools "Read,Grep,Glob,Bash"` |

---

## 1. Print mode (`-p`) — Claude cho scripts và CI

CI runner không có người ngồi approve/deny. REPL hỏi giữa chừng = treo job tới timeout. `-p` + `dontAsk` + allowlist hẹp = deterministic: cho phép trước đúng thứ job cần, cấm phần còn lại, log JSON để step sau parse.

```bash
# Non-interactive, output text/JSON — giữ guardrails chặt chẽ
claude -p "review diff và in findings dạng JSON" \
  --output-format json \
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash"
```

- `PermissionRequest` hooks trong `-p` plain không có prompt (cần Agent SDK `canUseTool` hoặc `--permission-prompt-tool`); automate permission thì dùng **`PreToolUse`** hooks.
- Hook `onFailure: "block"` (≥2.1.295): hook lỗi/timeout thì **chặn** hành động thay vì thả qua — CI nên bật để lỗi hook không âm thầm bỏ qua guardrail.
- Frontmatter hooks của project subagents: `-p` không tính là trusted → có thể bị skip (log sẽ ghi rõ).

### 1.1. 3 ví dụ `-p` copy-paste

```bash
# Ví dụ 1 — review JSON (parse bằng jq cho step sau)
claude -p "review git diff main...HEAD, output JSON: {findings: [{severity, file, line, msg, fix}]}" \
  --output-format json --permission-mode dontAsk --allowedTools "Read, Grep, Glob, Bash" | jq '.findings'

# Ví dụ 2 — healthcheck MCP (≥2.1.205): gắn vào CI warmup, MCP down → fail fast
claude -p "/mcp" --output-format text
```

**Kiểm tra nhanh:** ví dụ 1 pipe qua `jq '.findings | length'` → in ra số (`null` = prompt chưa ép đúng schema). Yêu cầu `rm -rf` với allowlist hẹp → phải bị chặn.

---

## 2. Agent SDK — build agent riêng

SDK bọc vòng lặp Claude (tools + permissions + orchestration) để build workflow custom: full control tool access, permission callbacks. Mặc định load `.claude/` từ CWD + `~/.claude/` — thu hẹp bằng `settingSources`.

### 2.1. SDK code mẫu (TypeScript — query + permissions callback)

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

### 2.2. TypeScript vs Python SDK — cùng năng lực, khác cách viết

Python SDK **chính chủ**: package [`claude-agent-sdk`](https://pypi.org/project/claude-agent-sdk/) trên PyPI, do Anthropic phát hành (cần Python ≥3.10, license MIT, wheel bundle sẵn Claude Code CLI). Sample TS trên dịch sang Python gần như 1-1 với snake_case: `allowed_tools`, `permission_mode`, `setting_sources`.

| Khía cạnh | TypeScript | Python |
|---|---|---|
| Tên options | camelCase: `allowedTools`, `permissionMode` | snake_case: `allowed_tools`, `permission_mode` trong `ClaudeAgentOptions` |
| Gọi agent | `await query({prompt, options})` + `for await` qua message stream | `query()` là async generator (`async for msg in query(...)`) |
| Custom tools | In-process SDK MCP server | `@tool` decorator + `create_sdk_mcp_server` — in-process |
| Hooks | Config JSON schema trong options | Hàm Python thật, gắn bằng `HookMatcher` |
| Structured output | JSON Schema / Zod | JSON Schema / Pydantic |
| CLI đi kèm | Cần cài Claude Code riêng | Wheel **bundle sẵn Claude Code CLI** (override bằng `cli_path=...`) |

> Trong CI, muốn ép mọi workflow agent chạy cùng 1 model (ổn định chi phí) → đặt env `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` (≥2.1.296) ở job env, cạnh `ANTHROPIC_MODEL`.

---

## 3. CI/CD: GitHub Actions & GitLab (không tắt guardrails)

Pattern: `claude -p` với scope hẹp + `dontAsk` + allowlist tools tối thiểu, secrets qua env runner. Có sẵn trên Sub/Console/Bedrock/AWS/GCP (Foundry ✗ — [bài 10](./10-permissions-modes-availability.md)). Setup chuẩn bị 1 lần (`Setup` hook event, `--init-only`/`--maintenance` trong `-p`).

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

      # Setup Claude (1 lần): curl -fsSL https://claude.ai/install.sh | bash
      #   + echo "$HOME/.local/bin" >> "$GITHUB_PATH"
      # Warmup (Setup hooks): claude --init-only
      # Secrets: ANTHROPIC_API_KEY (Console) hoặc OAuth token (subscription) — không echo ra log.

      - name: Review diff (guardrailed)
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
            const { findings = [] } = JSON.parse(require('fs').readFileSync('review.json', 'utf8'));
            const body = findings.length
              ? `## Claude Review (${findings.length})\n` + findings.map(f =>
                  `- **[${f.severity}]** \`${f.file}:${f.line}\` — ${f.msg}\n  Fix: ${f.fix}`).join('\n')
              : `## Claude Review\nKhông thấy issue.`;
            await github.rest.issues.createComment({ ...context.repo, issue_number: context.issue.number, body });
```

### 3.2. Workflow 2 — overnight CI failure analysis

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
      # actions/checkout (fetch-depth: 0) + Setup Claude: y hệt workflow 1

      - name: Analyze latest failures
        run: |
          gh run list --branch main --limit 5 --json conclusion,name,headSha > runs.json
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
            const body = require('fs').readFileSync('triage.md', 'utf8');
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

> **Không dùng `bypassPermissions` trên runner persistent** — chỉ hợp sandbox ephemeral. Secrets luôn qua `${{ secrets.* }}` / masked vars, không echo ra log.

### 3.3. `/ultrareview` — fleet bug-hunting cho CI

Ngoài tự viết workflow `claude -p`, từ 2026 có 2 lựa chọn dựng sẵn:

- **`/ultrareview`** (trong session, public preview từ Week 17/2026): phóng đội bug-hunting agents chạy trên cloud, tổng hợp findings — dùng khi muốn soi kỹ 1 diff/branch lớn hơn khả năng 1 reviewer.
- **`claude ultrareview`** (CLI, từ Week 18/2026): cùng cơ chế chạy được trong CI job — thay/kèm workflow auto-review tự viết khi cần review sâu:

```yaml
# Thay step "Review diff" bằng:
      - name: Ultrapreview (fleet bug-hunting)
        run: claude ultrareview --output-format json > review.json
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

> Cả 2 đang là **public preview** — check `claude ultrareview --help` ở bản của bạn. Review nhẹ hàng ngày thì workflow `claude -p` mục 3.1 vẫn rẻ và ổn định hơn.

---

## 4. Routines (`/schedule`) — việc định kỳ trên cloud

Cần subscription (không phải API-key-only provider, trừ lưu ý theo [bài 10](./10-permissions-modes-availability.md)). Viết prompt routine như viết skill: steps + verify + output format; gắn skill để tái dùng. Từ v2.1.196: skill `disable-model-invocation: true` cũng không chạy khi scheduled task fire với skill làm prompt.

### 4.1. 3 routines mẫu (copy-paste prompts)

```text
# Routine 1 — Morning digest (7:30 sáng weekdays) — /schedule "7:30 weekdays"
"Đọc 10 PRs/issues mới nhất repo acme/api (qua github MCP).
Trả digest: mỗi item 1 dòng (PR/issue + trạng thái + cần ai action).
Post vào Slack #eng-standup (qua slack MCP, format skill slack-post)."

# Routine 2 — Weekly dependency audit (sáng thứ 2) — /schedule "monday 8:00"
"Chạy pnpm outdated + npm audit (read-only). Liệt kê: major updates (risk cao),
security advisories (severity + CVE), đề xuất 3 PRs riêng (không gộp).
Không tự update — chỉ báo cáo."

# Routine 3 — Docs sync sau merge (mỗi tối) — /schedule "daily 21:00"
"git log main --since='24 hours' --oneline. Với mỗi feat/fix:
check docs/ có cập nhật tương ứng? Liệt kê docs thiếu. Không tự viết docs — mở checklist."

# Quy tắc viết routine prompt (như viết skill — bài 05):
# steps numbered + lệnh cụ thể · verify "chỉ báo cáo, không tự sửa/deploy"
# (routine chạy vắng người!) · output format rõ · gắn skill để tái dùng.
```

Chọn đúng: cần chạy trên cloud theo lịch + dùng MCP → routine; cần chạy trong repo runner + parse JSON → `claude -p` trong Actions.

---

## 5. Setup maintainable cho team

### 5.1. Cấu trúc đề xuất

```text
.claude/  → CLAUDE.md (ngắn) + rules/ + settings.json (team) + skills/ + agents/ + hooks/
.mcp.json (project servers, secrets qua env)
.github/workflows/claude-review.yml, claude-ci-triage.yml (hoặc GitLab)
Routines: /schedule cho việc định kỳ (cloud)
```

Nguyên tắc: facts mỗi session → CLAUDE.md; việc lặp → skill; cô lập → subagent; ngoài repo → MCP; phải-chạy-mỗi-lần → hook; share nhiều repo → plugin; lặp theo lịch → routine; nhúng hệ khác → SDK/CI.

### 5.2. Walkthrough setup team từ 0 (checklist 1 giờ)

```text
[ ] /init + CLAUDE.md <200 dòng (bài 03) — 15 phút    [ ] settings.json team + personal (bài 10) — 10 phút
[ ] 3 hooks: lint/block-push/context (bài 07) — 15 phút   [ ] MCP GitHub + skill nếu có DB (bài 08) — 10 phút
[ ] 2 agents explorer/tester (bài 06) — 5 phút        [ ] Workflow 1 CI review (mục 3.1) — 10 phút
[ ] 1 routine morning digest (mục 4.1) — 5 phút       [ ] claude doctor + /doctor hết xanh — 5 phút
```

### 5.3. Pitfalls + fix

| Pitfall | Fix |
|---|---|
| CI dùng `bypassPermissions` trên runner persistent | `bypass` chỉ sandbox ephemeral; runner thường → `dontAsk` + allowlist hẹp |
| Secrets echo ra CI log | Secrets qua env, GitHub masked vars, `set -x` off khi dùng secrets |
| `-p` hooks bị skip lặng lẽ | Frontmatter project hooks untrusted trong `-p` — chuyển sang settings.json hooks |
| Routine tự deploy khi vắng người | Routine chỉ báo cáo/digest; deploy luôn cần người duyệt |
| SDK load cả `~/.claude/` personal vào CI | `settingSources: ["project"]` trong CI |
| GitLab/Foundry thiếu integration | Check bảng availability ([bài 10](./10-permissions-modes-availability.md)); fallback `claude -p` generic |

### 5.4. Bài tập + link chéo

**Bài 1 (20 phút):** Chạy các lệnh `-p` mục 1.1 local, so sánh output text vs json, viết script shell parse JSON bằng `jq`. Rồi deploy workflow 1 (mục 3.1) lên repo test — mở PR test, tune prompt tới khi findings precision cao. **Bài 2 (20 phút):** Chạy SDK sample (mục 2.1), thử `canUseTool` block 1 lệnh nguy hiểm. Đổi `settingSources` quan sát khác biệt skills load. Tạo 1 routine `/schedule` digest (mục 4.1) nếu có access cloud. **Bài 3 (30 phút, tổng):** Làm checklist 1 giờ (mục 5.2) cho team bạn. `claude doctor` cuối. Viết 1 trang retro ngắn.

**Link chéo:** [00 — Tổng quan](./00-tong-quan-claude-code.md) (agentic loop + token economics) · [07 — Hooks](./07-hooks-tu-dong-hoa.md) (PreToolUse cho `-p`) · [08 — MCP](./08-mcp-ket-noi-cong-cu-ngoai.md) (MCP trong CI runners) · [09 — Plugins](./09-plugins-marketplaces.md) (share CI templates qua plugin) · [10 — Permissions](./10-permissions-modes-availability.md) (`dontAsk` vs `bypass`) · [13 — LSP/OTel](./13-code-intelligence-lsp-opentelemetry.md) (giám sát agent trong pipeline) · [14 — Models](./14-models-5x-chon-model-dung.md) (chọn model cho CI jobs) · [15 — Security](./15-security-stack-5-tang.md) (guardrails CI ở tầng nào) · [16 — Mods](./16-mods-bao-mat-validate.md) (validate CI configs trước merge).
