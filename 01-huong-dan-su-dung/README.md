# 01 — Hướng dẫn sử dụng Claude Code

> **Bài này cho ai:** bạn cần một sổ tay thao tác cho Claude Code — biết bài nào đọc khi nào, tra lệnh ở đâu.
> **Cần gì trước:** đã cài Claude Code (làm theo [01-cai-dat-va-xac-thuc.md](./01-cai-dat-va-xac-thuc.md)) và biết dùng terminal cơ bản (`cd`, `git clone`).
> **Đọc xong bạn làm được:**
> - Chọn đúng bài để đọc theo thứ tự 00 → 16, không phải đọc dàn trải 17 file.
> - Tra 1 lệnh bất kỳ trong `commands/` dưới 30 giây.
> - Biết file nào trả lời câu hỏi của bạn: cài đặt, CLAUDE.md, permissions, lỗi thường gặp.
> **Thời gian:** ~5 phút đọc mục lục + 15 phút chọn lộ trình

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Slash command | Lệnh gõ sau dấu `/` ngay trong session | `/clear`, `/init`, `/doctor` |
| Skill | Công thức tái dùng, chỉ load khi được gọi | skill `verify` tự chạy trước mỗi commit |
| Subagent | Trợ lý con có bộ nhớ riêng, làm xong trả tóm tắt | Explorer đọc 50 file, trả về 10 dòng kết luận |
| Hook | Script tự chạy khi tới một sự kiện | chạy ESLint sau mỗi lần sửa file |
| MCP | Cổng cắm dịch vụ ngoài vào agent | query DB, mở PR trên GitHub |
| CLAUDE.md | File ghi quy ước dự án, nạp lại mỗi session | "Dùng pnpm, chạy test trước khi commit" |
| Bề mặt sử dụng (surface) | Nơi bạn ngồi gõ Claude Code | terminal, VS Code, web, desktop |

## Mục lục

- [Mục tiêu folder](#mục-tiêu-folder)
- [Danh sách bài (17 bài)](#danh-sách-bài-17-bài)
- [Cách đọc nhanh và lộ trình](#cách-đọc-nhanh-và-lộ-trình)
- [Tra cứu lệnh chi tiết trong commands](#tra-cứu-lệnh-chi-tiết-trong-commands)

## Mục tiêu folder

Section này trả lời câu: 17 bài trong folder gộp lại dạy cho bạn điều gì, và nên đọc theo thứ tự nào?

Đọc theo thứ tự **00 → 16**: từ tổng quan, cài đặt, bề mặt sử dụng, cấu hình nền tảng
(`CLAUDE.md`, slash commands, skills, subagents, hooks, MCP, plugins, permissions),
tới worktrees/checkpoints, automation (Agent SDK/CI-CD), code intelligence,
models 5.x, security stack và mods bảo mật.

## Danh sách bài (17 bài)

Cần chọn nhanh bài hợp với hoàn cảnh của mình → dùng bảng này: mỗi dòng là 1 bài, có mô tả 1 dòng, thời gian ước tính và link.

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

## Cách đọc nhanh và lộ trình

Muốn đọc 17 bài mà không tốn cả tuần → bám nhịp đọc nhanh và lộ trình 5 ngày dưới đây.

> Cách đọc nhanh: mỗi bài ~30–40 phút (đọc 15' + chạy ví dụ 15' + làm bài tập 10').
> Bận thì đọc lướt mục lục + chạy code block, rảnh thì đi từng bước phần walkthrough cuối bài.

Lộ trình 5 ngày (mỗi ngày ~1 giờ, xem [`README.md` gốc](../README.md)):

```text
Ngày 1: 01 bài 00 → 04 (tổng quan, cài đặt, bề mặt dùng, CLAUDE.md)
Ngày 2: 01 bài 05 → 07 (commands, skills, subagents, hooks)
Ngày 3: 01 bài 08 → 12 (MCP, plugins, permissions, worktrees, SDK/CI)
Ngày 4: 02 tips 01 → 05 (context, prompt, plan, verify, parallel)
Ngày 5: 02 tips 06 → 10 + 03 FAQ tra cứu khi gặp lỗi
```

## Tra cứu lệnh chi tiết trong commands

Cần tra 1 lệnh cụ thể mà không muốn đọc bài dài → vào thẳng thư mục lệnh, mỗi lệnh 1 folder 60 dòng.

- Tổng số: **78** thư mục lệnh + 5 group index + 1 index tổng (`commands/README.md`).
- Index đầy đủ theo 4 nhóm: [commands/README.md](./commands/README.md)
- Mỗi lệnh 1 file ~60 dòng theo format 7 mục: nói nôm na → khi nào dùng → cách gọi → ví dụ thật + verify → lỗi hay gặp → tham khảo.
- Ví dụ tra cứu nhanh: [commands/model-mode/plan/README.md](./commands/model-mode/plan/README.md)
  (thay `plan` bằng slug bất kỳ, vd `./commands/session-context/compact/README.md`, `./commands/knowledge-system/mcp/README.md`).
- Trong session gõ `/` để xem lệnh nào hiện ở môi trường của bạn (version/provider khác nhau hiện khác nhau).

**Kiểm tra nhanh:** mở được [00-tong-quan-claude-code.md](./00-tong-quan-claude-code.md) và [commands/README.md](./commands/README.md); tra được 1 lệnh bất kỳ (vd `/plan` → `commands/model-mode/plan/README.md`) dưới 30 giây; chỉ ra được file nào trả lời câu hỏi của bạn trong bảng 17 bài.

> Mẹo 1 dòng: gặp lỗi lạ thì mở [`03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md`](../03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md) trước, rồi gõ `/doctor`.
