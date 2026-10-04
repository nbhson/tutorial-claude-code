# Changelog — Khóa Học Claude Code (tiếng Việt)

## [Unreleased]

- Giữ chỗ cho bài/tips/lệnh mới theo quy ước trong `CONTRIBUTING.md`.
- Không sửa nội dung bài cũ trong PR thêm bài mới (chỉ thêm file mới).

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
