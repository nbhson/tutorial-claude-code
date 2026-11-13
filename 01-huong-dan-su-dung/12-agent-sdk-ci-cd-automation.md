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

Mục này nói về cách chạy Claude khi không có người ngồi bên màn hình: một câu hỏi, một kết quả, không ai phải bấm approve. Đọc để biết vì sao CI bắt buộc chạy kiểu này và bật guardrails ở đâu.

CI runner không có người ngồi approve/deny. REPL hỏi giữa chừng = treo job tới timeout. `-p` + `dontAsk` + allowlist hẹp = deterministic: cho phép trước đúng thứ job cần, cấm phần còn lại, log JSON để step sau parse. Ví von: máy bán vé tự động không được dừng giữa chừng hỏi "bạn có chắc muốn mua vé này không?" — mọi cửa đều phải chốt trước khi máy chạy.

> 📄 **Code ví dụ:** [`examples/01-1-print-mode-p-claude-cho-scripts-va.sh`](examples/01-1-print-mode-p-claude-cho-scripts-va.sh)

- `PermissionRequest` hooks trong `-p` plain không có prompt (cần Agent SDK `canUseTool` hoặc `--permission-prompt-tool`); automate permission thì dùng **`PreToolUse`** hooks.
- Hook `onFailure: "block"` (≥2.1.295): hook lỗi/timeout thì **chặn** hành động thay vì thả qua — CI nên bật để lỗi hook không âm thầm bỏ qua guardrail.
- Frontmatter hooks của project subagents: `-p` không tính là trusted → có thể bị skip (log sẽ ghi rõ).

### 1.1. 3 ví dụ `-p` copy-paste

> 📄 **Code ví dụ:** [`examples/02-1-1-3-vi-du-p-copy-paste.sh`](examples/02-1-1-3-vi-du-p-copy-paste.sh)

**Kiểm tra nhanh:** ví dụ 1 pipe qua `jq '.findings | length'` → in ra số (`null` = prompt chưa ép đúng schema). Yêu cầu `rm -rf` với allowlist hẹp → phải bị chặn.

> **Tóm gọn 1 câu:** `claude -p` là "Claude cho máy đọc": chốt quyền trước, chạy 1 mạch, xuất JSON — không bao giờ dừng hỏi người.

---

## 2. Agent SDK — build agent riêng

Mục này dành cho ai muốn đưa vòng lặp Claude vào app của chính mình (bot, backend, CLI nội bộ) thay vì dùng qua terminal — SDK bọc sẵn tools + permissions để bạn chỉ định hình khối workflow.

SDK bọc vòng lặp Claude (tools + permissions + orchestration) để build workflow custom: full control tool access, permission callbacks. Mặc định load `.claude/` từ CWD + `~/.claude/` — thu hẹp bằng `settingSources`. Hãy hình dung SDK như mua "bộ khung bếp thay cho nguyên căn nhà hàng": bạn vẫn có lửa và dao thớt (tools), nhưng tự bày cách nấu.

### 2.1. SDK code mẫu (TypeScript — query + permissions callback)

> 📄 **Code ví dụ:** [`examples/03-2-1-sdk-code-mau-typescript-query-permissions.ts`](examples/03-2-1-sdk-code-mau-typescript-query-permissions.ts)

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

> **Cách đọc bảng này:** chọn cột ngôn ngữ bạn định dùng, rồi đối chiếu từng dòng — cùng một năng lực, chỉ khác cách gọi; dòng "CLI đi kèm" là khác biệt thực dụng nhất khi setup máy mới.

> Trong CI, muốn ép mọi workflow agent chạy cùng 1 model (ổn định chi phí) → đặt env `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` (≥2.1.296) ở job env, cạnh `ANTHROPIC_MODEL`.

> **Tóm gọn 1 câu:** SDK cho bạn vòng lặp Claude trong app riêng — TS hay Python cùng một sức mạnh, chỉ khác camelCase và snake_case.

---

## 3. CI/CD: GitHub Actions & GitLab (không tắt guardrails)

Mục này là bản dựng thực tế trên pipeline: 2 workflow copy-paste được và bộ công cụ review sâu cho CI. Đọc để đem về repo và chạy ngay, không phải nghĩ từ đầu.

Pattern: `claude -p` với scope hẹp + `dontAsk` + allowlist tools tối thiểu, secrets qua env runner. Có sẵn trên Sub/Console/Bedrock/AWS/GCP (Foundry ✗ — [bài 10](./10-permissions-modes-availability.md)). Setup chuẩn bị 1 lần (`Setup` hook event, `--init-only`/`--maintenance` trong `-p`).

### 3.1. Workflow 1 — auto-review PR mới (hoàn chỉnh, copy-paste)

> 📄 **Code ví dụ:** [`examples/04-3-1-workflow-1-auto-review-pr-moi.yaml`](examples/04-3-1-workflow-1-auto-review-pr-moi.yaml)

### 3.2. Workflow 2 — overnight CI failure analysis

> 📄 **Code ví dụ:** [`examples/05-3-2-workflow-2-overnight-ci-failure-analysis.yaml`](examples/05-3-2-workflow-2-overnight-ci-failure-analysis.yaml)

> 📄 **Code ví dụ:** [`examples/06-3-2-workflow-2-overnight-ci-failure-analysis.yaml`](examples/06-3-2-workflow-2-overnight-ci-failure-analysis.yaml)

> **Không dùng `bypassPermissions` trên runner persistent** — chỉ hợp sandbox ephemeral. Secrets luôn qua `${{ secrets.* }}` / masked vars, không echo ra log.

### 3.3. `/ultrareview` — fleet bug-hunting cho CI

Ngoài tự viết workflow `claude -p`, từ 2026 có 2 lựa chọn dựng sẵn:

- **`/ultrareview`** (trong session, public preview từ Week 17/2026): phóng đội bug-hunting agents chạy trên cloud, tổng hợp findings — dùng khi muốn soi kỹ 1 diff/branch lớn hơn khả năng 1 reviewer.
- **`claude ultrareview`** (CLI, từ Week 18/2026): cùng cơ chế chạy được trong CI job — thay/kèm workflow auto-review tự viết khi cần review sâu:

> 📄 **Code ví dụ:** [`examples/07-3-3-ultrareview-fleet-bug-hunting-cho-ci.yaml`](examples/07-3-3-ultrareview-fleet-bug-hunting-cho-ci.yaml)

> Cả 2 đang là **public preview** — check `claude ultrareview --help` ở bản của bạn. Review nhẹ hàng ngày thì workflow `claude -p` mục 3.1 vẫn rẻ và ổn định hơn.

> **Tóm gọn 1 câu:** CI chạy Claude = `claude -p` scope hẹp là nền tảng, còn `/ultrareview` là "gọi đội đặc nhiệm" khi cần soi kỹ một diff lớn.

---

## 4. Routines (`/schedule`) — việc định kỳ trên cloud

Mục này nói về việc giao Claude những nhiệm vụ chạy theo giờ khi bạn vắng mặt — báo sáng, audit tuần, sync docs tối — giống thuê bảo vệ trực ca.

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

> **Tóm gọn 1 câu:** Routine là "ca trực theo lịch" trên cloud — nhớ viết prompt như giao việc cho ca đêm: chỉ báo cáo, không tự quyết khi vắng người.

---

## 5. Setup maintainable cho team

Mục này gom tất cả thành bản đồ setup tổng thể: thứ nào nằm ở đâu, ai giữ gì, và thứ tự dựng cho team từ con số 0.

### 5.1. Cấu trúc đề xuất

```text
.claude/  → CLAUDE.md (ngắn) + rules/ + settings.json (team) + skills/ + agents/ + hooks/
.mcp.json (project servers, secrets qua env)
.github/workflows/claude-review.yml, claude-ci-triage.yml (hoặc GitLab)
Routines: /schedule cho việc định kỳ (cloud)
```

Nguyên tắc: facts mỗi session → CLAUDE.md; việc lặp → skill; cô lập → subagent; ngoài repo → MCP; phải-chạy-mỗi-lần → hook; share nhiều repo → plugin; lặp theo lịch → routine; nhúng hệ khác → SDK/CI. Câu liệt kê này giống tủ phân loại đồ đạc: mỗi loại đồ một ngăn — tìm ra dễ, nhà không lộn xộn.

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

> **Cách đọc bảng này:** cột "Pitfall" là cảnh báo dạng "chuyện đã xảy ra", cột "Fix" là cách tránh ngay từ đầu — đọc kỹ trước khi dựng CI, rẻ hơn nhiều so với sự cố thật.

> **Tóm gọn 1 câu:** Setup bền cho team = mỗi thứ đúng ngăn của nó, secrets không bao giờ ra log, và runner thường không bao giờ được `bypassPermissions`.

### 5.4. Bài tập + link chéo

**Bài 1 (20 phút):** Chạy các lệnh `-p` mục 1.1 local, so sánh output text vs json, viết script shell parse JSON bằng `jq`. Rồi deploy workflow 1 (mục 3.1) lên repo test — mở PR test, tune prompt tới khi findings precision cao. **Bài 2 (20 phút):** Chạy SDK sample (mục 2.1), thử `canUseTool` block 1 lệnh nguy hiểm. Đổi `settingSources` quan sát khác biệt skills load. Tạo 1 routine `/schedule` digest (mục 4.1) nếu có access cloud. **Bài 3 (30 phút, tổng):** Làm checklist 1 giờ (mục 5.2) cho team bạn. `claude doctor` cuối. Viết 1 trang retro ngắn.

**Link chéo:** [00 — Tổng quan](./00-tong-quan-claude-code.md) (agentic loop + token economics) · [07 — Hooks](./07-hooks-tu-dong-hoa.md) (PreToolUse cho `-p`) · [08 — MCP](./08-mcp-ket-noi-cong-cu-ngoai.md) (MCP trong CI runners) · [09 — Plugins](./09-plugins-marketplaces.md) (share CI templates qua plugin) · [10 — Permissions](./10-permissions-modes-availability.md) (`dontAsk` vs `bypass`) · [13 — LSP/OTel](./13-code-intelligence-lsp-opentelemetry.md) (giám sát agent trong pipeline) · [14 — Models](./14-models-5x-chon-model-dung.md) (chọn model cho CI jobs) · [15 — Security](./15-security-stack-5-tang.md) (guardrails CI ở tầng nào) · [16 — Mods](./16-mods-bao-mat-validate.md) (validate CI configs trước merge).
