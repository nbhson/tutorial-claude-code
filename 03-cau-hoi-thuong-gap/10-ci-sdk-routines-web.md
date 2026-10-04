# FAQ 10 — CI/CD, SDK, Routines & Web Nâng Cao

**Dùng Claude trong CI thế nào mà vẫn an toàn?** `claude -p "<task>" --output-format json --permission-mode dontAsk
--allowedTools "Read,Grep,Glob,Bash"` + scope hẹp + secrets từ runner env. Không `--dangerously-skip-permissions`
ngoài sandbox. Có trên Sub/Console/Bedrock/AWS/GCP (Foundry ✗).

**`Setup` hook event để làm gì?** Chuẩn bị 1 lần cho CI/scripts (`--init-only` / `--init` / `--maintenance` trong `-p`).

**Routines (`/schedule`) là gì?** Task chạy định kỳ/gọi API/GitHub-event trên cloud (morning digest, CI analysis,
dep audit, docs sync). Cần subscription; viết prompt như skill + gắn verify.

**Bắt đầu cloud session từ terminal?** `/web-setup` (cần `gh` CLI: sync token, tạo environment) rồi
`claude --cloud "<task>"`. Mode cloud: Accept edits (tự sửa+push branch) / Plan (chờ duyệt).

**Teleport là gì?** Chuyển session giữa terminal ↔ cloud (`/teleport` resume remote từ claude.ai; sessions persist cross-device).

**Agent SDK khi nào?** Quy trình quá đặc thù / cần UI riêng / nhúng internal → build agent với tools+permissions+orchestration
riêng. Mặc định load `.claude/` + `~/.claude/`; thu hẹp bằng `setting_sources`.

**`claude mcp serve`?** Biến chính Claude Code thành 1 MCP stdio server cho hệ khác gọi.

**Analytics cho team?** `/insights` (HTML habits), `/stats`, dashboard + contribution metrics (Team/Enterprise),
Enterprise Analytics API. Server-managed settings/SSO/SCIM theo plan (bài 10 phần 1).
