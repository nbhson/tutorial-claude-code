# 01 — Hướng dẫn sử dụng Claude Code

Đọc theo thứ tự **00 → 16**: từ tổng quan, cài đặt, bề mặt sử dụng, cấu hình nền tảng
(`CLAUDE.md`, slash commands, skills, subagents, hooks, MCP, plugins, permissions),
tới worktrees/checkpoints, automation (Agent SDK/CI-CD), code intelligence,
models 5.x, security stack và mods bảo mật.

> Cách đọc nhanh: mỗi bài ~30–40 phút (đọc 15' + chạy ví dụ 15' + làm bài tập 10').
> Bận thì đọc lướt mục lục + chạy code block, rảnh thì làm walkthrough cuối bài.

## Danh sách bài (17 bài)

| # | Tên bài | Mô tả 1 dòng | Thời gian | Link |
|---|---------|--------------|-----------|------|
| 00 | Tổng quan Claude Code | Bức tranh toàn cảnh: Claude Code là gì, dùng khi nào | 20' | [00-tong-quan-claude-code.md](./00-tong-quan-claude-code.md) |
| 01 | Cài đặt và xác thực | Cài CLI, đăng nhập, kiểm tra môi trường lần đầu | 30' | [01-cai-dat-va-xac-thuc.md](./01-cai-dat-va-xac-thuc.md) |
| 02 | Các bề mặt: Terminal, IDE, Web, Desktop | So sánh 4 bề mặt sử dụng và khi nào dùng bề mặt nào | 30' | [02-cac-be-mat-terminal-ide-web-desktop.md](./02-cac-be-mat-terminal-ide-web-desktop.md) |
| 03 | CLAUDE.md, Memory, Rules | Ghi nhớ dự án: file cấu hình, memory và rules | 40' | [03-claude-md-memory-rules.md](./03-claude-md-memory-rules.md) |
| 04 | Slash commands toàn tập | Bản đồ đầy đủ các lệnh `/...` và cách dùng | 40' | [04-slash-commands-toan-tap.md](./04-slash-commands-toan-tap.md) |
| 05 | Skills & Custom commands | Đóng gói kiến thức tái dùng bằng skills | 40' | [05-skills-custom-commands.md](./05-skills-custom-commands.md) |
| 06 | Subagents & Agent Teams (parallel) | Chạy nhiều agent song song, chia việc theo team | 40' | [06-subagents-agent-teams-parallel.md](./06-subagents-agent-teams-parallel.md) |
| 07 | Hooks tự động hóa | Tự động chạy kiểm tra/hành động theo sự kiện | 40' | [07-hooks-tu-dong-hoa.md](./07-hooks-tu-dong-hoa.md) |
| 08 | MCP — kết nối công cụ ngoài | Mở rộng Claude Code bằng MCP servers | 40' | [08-mcp-ket-noi-cong-cu-ngoai.md](./08-mcp-ket-noi-cong-cu-ngoai.md) |
| 09 | Plugins & Marketplaces | Cài, chia sẻ và quản lý plugins | 30' | [09-plugins-marketplaces.md](./09-plugins-marketplaces.md) |
| 10 | Permissions, Modes, Availability | Phân quyền, chế độ chạy và kiểm soát an toàn | 40' | [10-permissions-modes-availability.md](./10-permissions-modes-availability.md) |
| 11 | Git worktrees & Checkpoints | Làm việc song song, quay lui an toàn | 30' | [11-git-worktrees-checkpoints.md](./11-git-worktrees-checkpoints.md) |
| 12 | Agent SDK, CI/CD, Automation | Tự động hóa bằng SDK và pipeline CI/CD | 40' | [12-agent-sdk-ci-cd-automation.md](./12-agent-sdk-ci-cd-automation.md) |
| 13 | Code intelligence, LSP, OpenTelemetry | Hiểu code sâu (LSP) và quan sát hành vi (OTel) | 30' | [13-code-intelligence-lsp-opentelemetry.md](./13-code-intelligence-lsp-opentelemetry.md) |
| 14 | Models 5.x: chọn model đúng | Fable / Opus 5.5 / Sonnet 5.5 / Haiku: giá, IDs, khi nào dùng | 20' | [14-models-5x-chon-model-dung.md](./14-models-5x-chon-model-dung.md) |
| 15 | Security stack 5 tầng | Defense-in-depth cho agent: xếp đúng thứ tự 5 tầng | 30' | [15-security-stack-5-tang.md](./15-security-stack-5-tang.md) |
| 16 | Mods: bảo mật & validate | Mod in-process JS/TS nguy hiểm tới đâu, validate trước khi cài | 30' | [16-mods-bao-mat-validate.md](./16-mods-bao-mat-validate.md) |

## Tra cứu lệnh chi tiết (`commands/`)

- Tổng số: **78** thư mục lệnh + 5 group index + 1 index tổng (`commands/README.md`).
- Index đầy đủ theo 4 nhóm: [commands/README.md](./commands/README.md)
- Mỗi lệnh 1 file ~60 dòng theo format 7 mục: nói nôm na → khi nào dùng → cách gọi → ví dụ thật + verify → lỗi hay gặp → tham khảo.
- Ví dụ tra cứu nhanh: [commands/model-mode/plan/README.md](./commands/model-mode/plan/README.md)
  (thay `plan` bằng slug bất kỳ, vd `./commands/session-context/compact/README.md`, `./commands/knowledge-system/mcp/README.md`).
- Trong session gõ `/` để xem lệnh nào hiện ở môi trường của bạn (version/provider khác nhau hiện khác nhau).
