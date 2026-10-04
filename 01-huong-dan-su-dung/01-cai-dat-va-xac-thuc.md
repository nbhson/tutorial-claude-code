# 01 — Cài Đặt, Xác Thực & Kiểm Tra Sức Khỏe

## 1. Cài đặt

### Native binary (khuyến nghị 2026)

```bash
# macOS / Linux — cài native binary
curl -fsSL https://claude.ai/install.sh | bash

# Hoặc Homebrew (macOS)
brew install --cask claude-code

# Kiểm tra
claude --version
```

> Trước đây có `npm i -g @anthropic-ai/claude-code`. Nay native binary là đường chính;
> nếu máy còn 2 bản song song, `/doctor` sẽ phát hiện duplicate install.

### IDE extensions

- **VS Code**: cài extension "Claude Code" → có inline diff, @-mention file, plan review, history.
- **JetBrains**: extension tương đương.
- IDE và CLI dùng chung config (`~/.claude/`, `.claude/` của repo).

### Điều kiện tài khoản

- Hầu hết surfaces cần **Claude subscription** (Pro/Max/Team/Enterprise) hoặc **Anthropic Console API key**.
- Terminal CLI + VS Code còn hỗ trợ **third-party providers** (Bedrock, Google Agent Platform, Microsoft Foundry...).
- Web/Mobile/Desktop-cloud/Slack/Routines/Remote Control/Chrome extension... **bắt buộc** sign-in `claude.ai`
  (xem bảng phân biệt theo provider ở bài 10 & FAQ).

## 2. Đăng nhập / đổi tài khoản

```bash
claude login     # đăng nhập (mở browser OAuth)
claude logout    # đăng xuất
```

Trong session: `/login` (đổi account / re-auth), `/logout`, `/status` (xem version, model, account),
`/exit` thoát REPL.

## 3. Session đầu tiên trong 1 repo

```bash
cd /path/to/repo
claude            # mở session
```

Rồi trong session chạy tuần tự (lần đầu duy nhất):

```
/init        → sinh CLAUDE.md nháp từ codebase (set CLAUDE_CODE_NEW_INIT=1 để có flow interactive hỏi cả skills/hooks/memory)
/memory      → tinh chỉnh memory files, bật/tắt auto-memory
/mcp         → setup server cần thiết (GitHub, DB...), xem bài 08
/permissions → đặt approval rules (xem bài 10), alias /allowed-tools
```

> `/init` cho project có sẵn (Claude tự phân tích conventions). Project mới thì dùng template trong
> `templates/CLAUDE.md` của repo này rồi sửa.

## 4. `claude doctor` và `/doctor` — bác sĩ của mọi lỗi setup

```bash
claude doctor     # ngoài terminal: in read-only diagnostics, không mở session
```

Trong session: `/doctor` (alias `/checkup`) — skill chẩn đoán + **có thể sửa** (luôn hỏi trước khi đổi):

- Sức khỏe cài đặt: duplicate install, lỗi `PATH`, settings file parse lỗi, version mới trên release channel.
- Context cost audit: skills/MCP servers/plugins **cài mà không dùng** vs chi phí context; hooks chạy chậm.
- CLAUDE.md audit (≥v2.1.206): dedupe `CLAUDE.md` local vs checked-in; cắt nội dung Claude tự suy ra được
  (directory layout, dependency list, architecture overview) — giữ lại pitfalls, rationale, conventions khác default;
  migrate guidance always-loaded còn lại thành skills + nested `CLAUDE.md` load-on-demand.
- Đề xuất: đặt auto mode làm default, pre-approve các read-only commands hay bị deny.

Khi báo lỗi cho người khác/Anthropic: dùng `/bug` (gửi conversation cho Anthropic), `/status`, `/doctor`.

## 5. Update & biến môi trường hữu ích

```bash
claude update     # lên bản mới nhất
```

```bash
# Load CLAUDE.md từ --add-dir paths (mặc định không load)
export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1
# Minimal mode: tắt MCP tools, attachments, hooks, CLAUDE.md, skills (debug)
export CLAUDE_CODE_SIMPLE=1
# Interactive init flow đầy đủ
export CLAUDE_CODE_NEW_INIT=1
```

## 6. Checklist sau cài đặt (copy-paste)

- [ ] `claude --version` ≥ 2.1.x, `claude doctor` không báo đỏ.
- [ ] Đã `/init` + `/memory` cho repo chính.
- [ ] Đã `/permissions` đặt allow/ask/deny (đặc biệt `Bash`, `Write` ngoài repo).
- [ ] Đã `/mcp` thêm 3–6 servers thực dùng (đừng quá 10 tools visible).
- [ ] Đã test 1 task nhỏ end-to-end: prompt → edit → test → commit.
- [ ] Đã đọc bài 02 (chọn surface) và bài 03 (viết CLAUDE.md tốt).

## 7. Lỗi cài đặt hay gặp (bản rút gọn — chi tiết ở 03-FAQ)

| Triệu chứng | Nguyên nhân likely | Fix |
|---|---|---|
| `Unknown command: /cd` | Version < 2.1.169 | `claude update` |
| Hook không chạy | Sai matcher case-sensitive / sai event / folder chưa trust | `/hooks` kiểm tra, xem bài 07 |
| MCP server disconnected | Token hết hạn / URL sai / chưa OAuth | `/mcp reconnect <name>` |
| 2 bản Claude xung đột | Còn cả npm + native | Gỡ 1 bản, `claude doctor` xác nhận |
| Settings parse error | JSON/JSONC sai dấu phẩy | `claude doctor` chỉ file lỗi, sửa tay |
