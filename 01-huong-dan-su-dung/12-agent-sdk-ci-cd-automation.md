# 12 — Agent SDK, CI/CD & Tự Động Hóa (Print Mode, Routines, GitHub Actions)

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

## 2. Agent SDK — build agent riêng

- SDK bọc vòng lặp Claude (tools + permissions + orchestration) để bạn build workflow custom:
  full control tool access, orchestration, permission callbacks.
- Mặc định load `.claude/` từ CWD + `~/.claude/` (skills, commands, CLAUDE.md) — thu hẹp bằng `setting_sources`.
- Dùng khi: quy trình team quá đặc thù, cần UI riêng, cần nhúng vào hệ internal.

## 3. CI/CD: GitHub Actions & GitLab (không tắt guardrails)

- Có sẵn trên Sub/Console/Bedrock/AWS/GCP (Foundry ✗). Pattern: `claude -p` với scope hẹp + `dontAsk`
  + allowlist tools tối thiểu, secrets qua env của runner.
- Kịch bản hay: auto-review PR mới, phân tích CI failure overnight, weekly dep audit, sync docs sau merge.
- Setup chuẩn bị 1 lần (`Setup` hook event sinh ra cho mục đích này: `--init-only`/`--init`/`--maintenance` trong `-p`).

## 4. Routines (`/schedule`) — việc định kỳ trên cloud

```
Morning digest • Overnight CI failure analysis • Weekly dependency audit • Docs sync sau merge
```

- Cần subscription (không phải API-key-only provider, trừ note theo bảng bài 10).
- Viết prompt routine như viết skill: steps + verify + output format; gắn skill để tái dùng.
- Từ v2.1.196: skill `disable-model-invocation: true` cũng không chạy khi scheduled task fire với skill làm prompt.

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
