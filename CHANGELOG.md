# Changelog — Khóa Học Claude Code (tiếng Việt)

## [Unreleased]

- `01/05-skills`: frontmatter mới (`user-invocable`, `argument-hint`/`arguments` + `$0`/`$1`/`$ARGUMENTS[0]`
  breaking v2.1.19 thay `$ARGUMENTS.0`, `paths` glob, `background: false` — fork background mặc định từ v2.1.218),
  `disableBundledSkills`, nested discovery monorepo, budget 1% context cho descriptions,
  `/skills` menu + `skillOverrides`, ma trận `disable-model-invocation` × `user-invocable`.
- `01/06-subagents`: nest depth 3 mặc định (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` để về 1),
  `--forward-subagent-text` + env, Agent Teams bật bằng `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (≥2.1.32),
  fork skill background mặc định (`background: false` để chờ).
- `01/10-permissions`: deny-bypass fix v2.1.288/289 (compound, env-prefix, bare assignment, symlink realpath,
  nested mod approval chỉ managed machines); phòng thủ (deny interpreter `Bash(bash -c:*)`, nghi allow rules,
  negative test từ changelog); npm stable 2.1.285 vs latest 2.1.289 + `npm view dist-tags`;
  mod-override Pro/Max không managed + mitigations (safe-mode/`disableAllHooks`/`--bare`).
- Commands: `code-review` (`--max-findings all|default`, `ultra` = alias `/code-review ultra`);
  `simplify` (từ v2.1.154 chỉ fix over-engineering, không tìm bugs);
  `usage` (gộp từ `/cost`+`/stats` từ v2.1.118);
  `model` (giá Opus 5.5 $4/$20, Sonnet 5.5 $2/$10, Fable $10/$50, Haiku $1/$5 + alias `opusplan` + Fable không default + IDs).
- Indexes: thêm 14 slugs (`security-review`, `run`, `run-skill-generator`, `restart`, `background`, `voice`,
  `recap`, `subtask`, `skill-doctor`, `setup-bedrock`, `setup-vertex`, `fewer-permission-prompts`,
  `mcp-serve`, `plugin-validate`) vào `commands/README.md` (64→78), `04-slash-commands-toan-tap.md` (62→76),
  `01/README.md` (14→17 bài, commands 64→78); gốc `README.md` (01: 17 bài, commands 78; 02: 11 bài);
  `CHEATSHEET.md` (bảng giá model 5.5 + `/security-review` `/run` `/background`).
- Không đụng `templates/.claude/hooks/bash-guard.sh` (người khác vừa tạo).

## [v1.0.0] — 2026-10-04

Bản đầu tiên hoàn chỉnh theo Claude Code v2.1.x.

- `01-huong-dan-su-dung/`: 13 bài (01–13, chưa tính `00-tong-quan`) + `commands/` 64 folders
  (mỗi lệnh 1 `README.md` 8 mục: cú pháp, cơ chế, ví dụ, rủi ro, workflow, lỗi, tham khảo).
  Mới nhất: bài 13 code intelligence LSP + OpenTelemetry; lệnh `design-sync`, `radio`
  (version-gated, vắng mặt Bedrock/AWS/GCP, có workflow thay thế).
- `02-tips-thuc-chien/`: 11 bài (01–11). Mới nhất: tips 11 desktop & web
  (Chrome extension, computer use Pro/Max + guardrails, artifacts publish private,
  Remote Control vs Web sessions, voice dictation).
- `03-cau-hoi-thuong-gap/`: 10 bài (01–10) tài khoản/pricing, model/context,
  permissions, MCP, hooks, skills, subagents, troubleshooting, bảo mật, CI/SDK.
- `templates/`: `CLAUDE.md`, `.claude/` (3 skills, 3 agents, rules, settings, 5 hooks),
  `.mcp.json` + `.github/workflows/` (claude-review: review PR bằng `claude -p`
  guardrailed; claude-ci-triage: phân tích CI failure overnight mở issue).
- Gốc: `README.md` lộ trình 5 ngày, `CHEATSHEET.md` 1 trang, `LICENSE` MIT,
  `CONTRIBUTING.md` quy ước đóng góp.
