# 01 — Cài đặt, xác thực và kiểm tra sức khỏe

> **Bài này cho ai:** bạn sắp cài Claude Code lần đầu, hoặc đã cài rồi nhưng `claude doctor` cứ báo đỏ.
> **Cần gì trước:** mở được terminal, biết `cd` và `git clone`. Chưa cần tài khoản — đăng nhập làm ngay trong bài.
> **Đọc xong bạn làm được:** cài native binary không bị duplicate install; chọn đúng provider + login/đổi account; chạy `claude doctor` + `/doctor` và tự sửa 9 lỗi setup hay gặp; setup xong 1 repo (`/init → /memory → /mcp → /permissions`).
> **Thời gian:** ~25 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Native binary | File chạy độc lập, không cần Node đúng version | `curl .../install.sh \| bash` rồi `claude --version` ra `2.1.x` |
| PATH | Danh sách đường terminal đi tìm lệnh | `~/.local/bin` phải có trong `echo $PATH` |
| Duplicate install | Có 2 bản (brew + npm/native) | `which -a claude` ra 2 dòng |
| Provider | Nhà cung cấp model + tính tiền | Subscription → `claude login`; CI → `ANTHROPIC_API_KEY` |
| `claude doctor` | Phiếu khám sức khỏe chỉ đọc, không sửa | In `[✓] Auth`, `[!] MCP` |
| `/doctor` | Bác sĩ vừa khám vừa hỏi có cho sửa không (alias `/checkup`) | Hỏi `remove duplicate? [y/N]` |
| WSL | Linux chạy trong Windows | `wsl --install -d Ubuntu` |

## Mục lục

1. [Cài native binary, đừng dùng npm](#1-cài-native-binary-đừng-dùng-npm)
2. [Cài đặt từng OS](#2-cài-đặt-từng-os)
3. [Windows: PowerShell thuần hay WSL?](#3-windows-powershell-thuần-hay-wsl)
4. [Version channels + version floor](#4-version-channels--version-floor)
5. [Đăng nhập / đổi tài khoản / providers](#5-đăng-nhập--đổi-tài-khoản--providers)
6. [Session đầu tiên trong 1 repo](#6-session-đầu-tiên-trong-1-repo)
7. [`claude doctor` và `/doctor`](#7-claude-doctor-và-doctor)
8. [Update + biến môi trường debug](#8-update--biến-môi-trường-debug)
9. [Hiểu nhầm, bẫy, checklist, bài tập, link](#9-hiểu-nhầm-bẫy-checklist-bài-tập-link)

---

## 1. Cài native binary, đừng dùng npm

Trước 2025: `npm i -g @anthropic-ai/claude-code` là đường chính — phụ thuộc Node, xung đột version, update chậm. Từ 2025–2026: **native binary** là đường chính (install.sh, Homebrew cask, Windows installer). Lợi ích: bundle runtime riêng (không cần Node global), update atomic qua `claude update`, `claude doctor` phát hiện duplicate install, sandbox/OS integration tốt hơn.

> Máy còn cả 2 bản (`which -a claude` ra 2 dòng) → mọi version check rối. Gỡ npm, giữ native: `npm uninstall -g @anthropic-ai/claude-code`.

---

## 2. Cài đặt từng OS

### macOS

```bash
# Cách A — native (khuyến nghị):
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # installer thường tự thêm
claude --version && which -a claude

# Cách B — Homebrew:
brew install --cask claude-code
```

### Linux (Ubuntu/Debian/Fedora/Arch)

```bash
# Ubuntu/Debian (Fedora: dnf install curl git gh; Arch: pacman -S curl git github-cli):
sudo apt update && sudo apt install -y curl git gh
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
claude --version && claude doctor
```

### Verify chung

```bash
claude --version        # kỳ vọng: 2.1.x
claude doctor           # không báo đỏ (cách đọc: mục 7)
ls ~/.claude/           # phải có settings.json sau lần chạy đầu
```

### IDE extensions (làm thêm, không thay CLI)

VS Code (Extensions → "Claude Code") và JetBrains (Settings → Plugins) dùng chung config với CLI (`~/.claude/`, `.claude/` repo). Verify: mở repo → sidebar Claude hiện → trong session gõ `/ide` → "VS Code connected" → `@`-mention 1 file, Claude đọc đúng file đó.

---

## 3. Windows: PowerShell thuần hay WSL?

Từ w18/2026, Claude Code chạy native trên Windows bằng **PowerShell/CMD, không cần Git Bash**. Lệnh nào cũng dùng được.

| Cách | Khi nào |
|---|---|
| Native Windows installer | PowerShell/CMD thuần — tải từ `claude.ai/download`, chạy, `claude --version` |
| WSL2 | Repo cần shell scripts `.sh`, symlink, docker Linux, hooks viết cho bash |

Vẫn nên WSL khi team hooks viết bash (`\\wsl$\Ubuntu\home\...`, mở VS Code bằng `code .` từ WSL) — toàn bộ series này viết cho Linux/macOS shell.

```powershell
# PowerShell — cài WSL + Ubuntu nếu cần:
wsl --install -d Ubuntu    # restart khi được yêu cầu
# Trong Ubuntu: cài như Linux ở mục 2, clone repo VÀO ~/code (không /mnt/c — chậm 5-10x):
```

Bẫy WSL hay gặp:

| Triệu chứng | Fix |
|---|---|
| Repo trong `/mnt/c` chạy test chậm rì | Clone lại vào `~/code` trong WSL (I/O qua 9P bridge chậm 5–10x) |
| `gh auth login` không mở được browser | Chọn `Login with a web browser` → copy code → paste vào browser Windows |
| Hook `.sh` báo `permission denied` | `chmod +x .claude/hooks/*.sh` trong WSL |
| Line ending CRLF làm hook gãy | `git config --global core.autocrlf input` |

---

## 4. Version channels + version floor

```bash
claude --version    # version + channel hiện tại
/status             # trong session: version, model, account
claude update       # lên stable mới nhất (brew: brew upgrade --cask claude-code)
```

| Kênh | Lệnh | Khi dùng |
|---|---|---|
| Native stable | `curl -fsSL https://claude.ai/install.sh \| bash` | Mặc định mọi người |
| Homebrew cask (macOS) | `brew install --cask claude-code` | Máy quản lý bằng brew |
| npm legacy | `npm i -g @anthropic-ai/claude-code` | Chỉ khi cần pin version/CI đặc biệt — dễ duplicate |

Version floor đáng nhớ (v2.1.x) — không thấy lệnh → check floor trước khi kết luận bug:

| Feature cần | Version tối thiểu |
|---|---|
| `/goal` (điều kiện hoàn thành) | ≥ 2.1.139 |
| `/verify` (build + chạy app thật) | ≥ 2.1.145 |
| `/cd` (đổi working dir giữ prompt cache) | ≥ 2.1.169 |
| `/effort` (low→max) + `/mcp` text-mode | ≥ 2.1.205 |
| CLAUDE.md audit trong `/doctor` | ≥ 2.1.206 |
| `/verify` + `/code-review` chỉ chạy khi gọi tay | ≥ 2.1.215 |
| Fork skill background mặc định | ≥ 2.1.218 |

---

## 5. Đăng nhập / đổi tài khoản / providers

```bash
claude login     # đăng nhập (OAuth browser)
claude logout    # đăng xuất
```

Trong session: `/login` (đổi account/re-auth), `/logout`, `/status` (version, model, account), `/exit` thoát.

| Bạn có gì | Chọn | Lệnh/env | Mất gì? |
|---|---|---|---|
| Subscription Pro/Max/Team | Sign-in `claude.ai` | `claude login` | Không mất gì, full features |
| Console API key (pay-as-you-go) | API key | `export ANTHROPIC_API_KEY=sk-ant-...` | Mất Web/Routines/Remote/Slack (bài 10) |
| AWS Bedrock | Bedrock provider | AWS creds + model ARN | Mất web search, fast mode, vài slash (bài 10) |
| Vertex / Foundry | GCP/Azure provider | GCP/Azure creds | Tùy feature (bảng bài 10) |

```bash
# CI runner không có browser:
export ANTHROPIC_API_KEY="sk-ant-..."
claude -p "summarize git diff" --output-format text

# Đổi account cá nhân ↔ công ty: trong session gõ /login → chọn account → /status kiểm tra.
```

> Gặp "lệnh không tồn tại" → check provider + version floor (mục 4) trước khi kết luận bug. Full availability: bài 10.

---

## 6. Session đầu tiên trong 1 repo

```bash
cd /path/to/repo && claude
```

Chạy tuần tự (lần đầu duy nhất):

```text
/init        → sinh CLAUDE.md nháp (CLAUDE_CODE_NEW_INIT=1 để có flow interactive hỏi skills/hooks/memory)
/memory      → tinh chỉnh memory files, bật/tắt auto-memory (bài 03)
/mcp         → setup server cần thiết (GitHub trước — bài 08). Test: "liệt kê 5 PRs mở gần nhất"
/permissions → đặt allow/ask/deny (bài 10). Deny gợi ý: Bash(rm -rf:*), push main
```

Rồi 1 task end-to-end: "Chạy linter, fix 3 lỗi đầu, chạy lại để xác nhận. Báo cáo files đổi." Xong `/cost` xem tiền, `/export` lưu nếu cần. Kiểm tra: `/status` hiện working dir đúng; sai folder → `exit` rồi `cd` lại.

---

## 7. `claude doctor` và `/doctor`

- **`claude doctor`** (ngoài terminal): read-only diagnostics, KHÔNG sửa gì.
- **`/doctor`** (trong session, alias `/checkup`): chẩn đoán + **sửa khi được duyệt** — duplicate install, PATH, settings parse lỗi; context cost audit (skills/MCP/plugins cài mà không dùng, hooks chậm); CLAUDE.md audit (≥2.1.206): dedupe local vs checked-in, cắt nội dung Claude tự suy ra được, migrate guidance dài thành skills; đề xuất đặt `auto` làm default permission mode + pre-approve read-only commands hay bị deny.

```text
$ claude doctor
[✓] Version: 2.1.2xx (native, stable channel, up to date)
[✓] Install: single native binary at ~/.local/bin/claude (no npm duplicate)
[✓] PATH: ~/.local/bin in PATH (zsh)
[✓] Auth: signed in as you@example.com (Pro) — token valid
[✓] Settings: ~/.claude/settings.json valid JSONC
[!] CLAUDE.md: ./CLAUDE.md 342 lines — over budget, run /doctor for trim suggestions
[!] MCP: 2/4 servers connected (postgres: disconnected — token expired)
[!] Hooks: PostToolUse lint-on-write avg 8.2s — consider faster linter scope
```

| Dòng | Hành động khi `[!]` |
|---|---|
| Version/Install/PATH | Gỡ bản thừa, fix PATH, restart shell |
| Auth | Hết hạn → `/login`; sai account → `/login` đổi |
| CLAUDE.md lines | `/doctor` → trim theo gợi ý (bài 03) |
| MCP disconnected | `/mcp reconnect <name>` (bài 08) |
| Hooks slow | Thu hẹp scope lint (chỉ file vừa edit, không `lint .`) |

Báo lỗi cho Anthropic: `/bug` (gửi conversation) + `/status` + `/doctor`.

---

## 8. Update + biến môi trường debug

| Biến | Khi nào bật | Ví dụ |
|---|---|---|
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | Dùng `--add-dir ../shared`, muốn CLAUDE.md của folder đó cũng load | Monorepo/shared libs |
| `CLAUDE_CODE_SIMPLE=1` | Debug "MCP/hook/skill có phá không?" — tắt hết, test lại | Hook không chạy / MCP crash / lỗi lạ sau update |
| `CLAUDE_CODE_NEW_INIT=1` | Muốn `/init` hỏi interactive (skills/hooks/memory) | Repo mới, setup chuẩn team từ đầu |

```bash
# Debug minimal: nếu simple chạy được mà normal gãy → lỗi nằm ở MCP/hook/skill:
CLAUDE_CODE_SIMPLE=1 claude -p "đọc package.json và tóm tắt scripts"
```

---

## 9. Hiểu nhầm, bẫy, checklist, bài tập, link

### Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật |
|---|---|
| Cài npm cũng như native | npm phụ thuộc Node, dễ duplicate; `which -a claude` ra 2 dòng → gỡ npm, giữ native |
| Login rồi là full feature | API key/Bedrock/Vertex bị cắt Web/Routines/fast mode (bài 10) |
| `claude doctor` sẽ tự sửa | Lệnh ngoài terminal chỉ đọc; muốn sửa vào session gõ `/doctor` |
| Update là xong mọi lỗi lệnh | Còn bị chặn bởi provider + version floor → `/status` + gõ `/` xem list thực tế |

### Lỗi cài đặt hay gặp

| Triệu chứng | Fix |
|---|---|
| `command not found: claude` | `export PATH="$HOME/.local/bin:$PATH"` + restart shell |
| 2 bản Claude xung đột | `npm uninstall -g @anthropic-ai/claude-code`, giữ native |
| `Unknown command: /cd` | Version < 2.1.169 → `claude update` |
| Hook không chạy | Sai matcher case-sensitive / sai event / folder chưa trust → `/hooks` (bài 07) |
| MCP disconnected | `/mcp reconnect <name>` (bài 08) |
| Settings parse error | `claude doctor` chỉ đúng file lỗi, mở sửa tay |
| `/login` vòng lặp OAuth | `claude logout` → login lại, thử browser khác |

### Checklist sau cài đặt

- [ ] `claude --version` ≥ 2.1.x, `claude doctor` không đỏ, `which -a claude` chỉ 1 binary.
- [ ] `/init` + `/memory` cho repo chính; `/permissions` đặt allow/ask/deny; `/mcp` thêm 3–6 servers thực dùng.
- [ ] Test 1 task nhỏ end-to-end: prompt → edit → test → commit.

### Bài tập

1. **Verify cài đặt (10'):** `claude --version`, `which -a claude`, `claude doctor` — giải thích từng dòng `[✓]/[!]`, fix hết `[!]`.
2. **Multi-OS check (15'):** team có macOS + Linux + WSL → lập bảng cài đặt/PATH/verify cho từng OS, ghi vào wiki.
3. **Session đầu chuẩn (20'):** chạy đủ `/init → /memory → /mcp → /permissions` + 1 task end-to-end; lưu `/cost` + `/export`.
4. **Debug drill (15'):** `CLAUDE_CODE_SIMPLE=1` so với normal, kết luận 3 dòng; thử `CLAUDE_CODE_NEW_INIT=1 /init` trên repo test.

### Link chéo

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: vòng lặp agent, token economics.
- **[02 — Bề mặt sử dụng](./02-cac-be-mat-terminal-ide-web-desktop.md)**: CLI flags, cloud env (cần `gh auth login` + `/web-setup`).
- **[03 — CLAUDE.md](./03-claude-md-memory-rules.md)**: cắt file `/init` vừa sinh xuống <200 dòng.
- **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: `/memory /mcp /permissions /doctor /status...`.
- **[07 — Hooks](./07-hooks-tu-dong-hoa.md)** khi `/doctor` báo hook chậm; **[08 — MCP](./08-mcp-ket-noi-cong-cu-ngoai.md)** setup từng server; **[10 — Permissions](./10-permissions-modes-availability.md)** availability theo plan/provider; **[FAQ](../03-cau-hoi-thuong-gap/)** tra lỗi lạ.
