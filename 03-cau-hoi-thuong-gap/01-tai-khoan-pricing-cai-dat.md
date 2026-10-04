# FAQ 01 — Tài Khoản, Pricing & Cài Đặt

**Cần tài khoản gì để dùng?** Claude subscription (Pro/Max/Team/Enterprise) hoặc Anthropic Console API key.
Terminal CLI + VS Code thêm third-party providers (Bedrock, GCP Agent Platform, Foundry...).

**Web/Mobile/Desktop-cloud/Slack/Routines/Remote/Chrome extension/Computer use/Artifacts?**
Bắt buộc sign-in `claude.ai` (không dùng API-key-only). Chi tiết xem bài 10 phần 1.

**Cài đặt thế nào?** Native binary (`curl .../install.sh | bash`) hoặc Homebrew cask; IDE thì thêm extension.
Tránh song song npm + native (duplicate install — `/doctor` phát hiện).

**`claude login/logout`?** Ngoài terminal; trong session dùng `/login`, `/logout`, `/status` xem account.

**Update?** `claude update`. Lệnh lạ (`Unknown command: /cd`) 90% là version cũ (vd `/cd` cần ≥2.1.169,
`/verify` ≥2.1.145, `/goal` ≥2.1.139, CLAUDE.md trim ≥2.1.206) — update trước khi debug tiếp.

**Bắt đầu repo mới?** `cd repo && claude`, rồi `/init → /memory → /mcp → tạo subagents → /permissions`.
Project mới tinh thì copy `templates/CLAUDE.md` rồi sửa.

**Báo lỗi cho Anthropic?** `/bug` (gửi conversation), kèm `/status` + `claude doctor` output.
