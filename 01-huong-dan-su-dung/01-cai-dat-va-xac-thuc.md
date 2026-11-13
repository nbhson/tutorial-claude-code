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

Mục này nói về việc chọn "đường cài" nào cho Claude Code. Đọc xong bạn sẽ biết vì sao nên bỏ npm và đi đường native — quyết định ảnh hưởng đến mọi thứ phía sau.

Cài Claude Code giống chọn phương tiện đi làm: đường cũ (npm) vẫn chạy nhưng dòm dừa, đường mới (native binary) đi thẳng và ít kẹt.

Trước 2025: `npm i -g @anthropic-ai/claude-code` là đường chính — phụ thuộc Node, xung đột version, update chậm. Hãy hình dung npm như thuê xe ôm: mỗi lần đi phải nhờ thằng Node chở, Node khác version là hỏng chuyến. Từ 2025–2026: **native binary** là đường chính (install.sh, Homebrew cask, Windows installer) — như tự có xe máy, khỏi phụ thuộc ai. Lợi ích: bundle runtime riêng (không cần Node global), update atomic qua `claude update`, `claude doctor` phát hiện duplicate install, sandbox/OS integration tốt hơn.

> Máy còn cả 2 bản (`which -a claude` ra 2 dòng) → mọi version check rối. Giống như nhà có 2 cái remote cùng điều hòa, bấm cái nào cũng được nhưng chẳng biết cái nào "chính chủ". Gỡ npm, giữ native: `npm uninstall -g @anthropic-ai/claude-code`.

> **Tóm gọn 1 câu:** Cài native binary thay vì npm — khỏi nợ Node một version, update sạch, doctor dễ khám.

---

## 2. Cài đặt từng OS

Mục này là "trạm xăng từng vùng miền": chọn đúng OS của bạn, lấy lệnh, chạy. Đọc phần khớp máy mình, không cần đọc hết.

### macOS

> 📄 **Code ví dụ:** [`examples/01-macos.sh`](examples/01-macos.sh)

### Linux (Ubuntu/Debian/Fedora/Arch)

> 📄 **Code ví dụ:** [`examples/02-linux-ubuntu-debian-fedora-arch.sh`](examples/02-linux-ubuntu-debian-fedora-arch.sh)

### Verify chung

Cài xong không có nghĩa là xong — phải "nổ máy thử" như sau khi sửa xe:

> 📄 **Code ví dụ:** [`examples/03-verify-chung.sh`](examples/03-verify-chung.sh)

### IDE extensions (làm thêm, không thay CLI)

VS Code (Extensions → "Claude Code") và JetBrains (Settings → Plugins) dùng chung config với CLI (`~/.claude/`, `.claude/` repo) — coi như hai cửa cùng một nhà, đồ đạc chung kho. Verify: mở repo → sidebar Claude hiện → trong session gõ `/ide` → "VS Code connected" → `@`-mention 1 file, Claude đọc đúng file đó.

> **Tóm gọn 1 câu:** Chọn đúng lệnh cho OS của mình, chạy verify chung, và nhớ IDE extension chỉ là "cửa phụ" dùng chung config với CLI.

---

## 3. Windows: PowerShell thuần hay WSL?

Mục này trả lời câu hỏi của người Windows: cài kiểu nào? Đọc xong bạn biết chọn native Windows hay WSL2, và xử lý mấy bẫy WSL quen gặp.

Từ w18/2026, Claude Code chạy native trên Windows bằng **PowerShell/CMD, không cần Git Bash**. Lệnh nào cũng dùng được. Cứ nghĩ như hai căn hộ trong cùng tòa nhà: PowerShell là căn ở luôn sẵn, WSL là căn thuê thêm cho ai cần "nội thất" Linux.

| Cách | Khi nào |
|---|---|
| Native Windows installer | PowerShell/CMD thuần — tải từ `claude.ai/download`, chạy, `claude --version` |
| WSL2 | Repo cần shell scripts `.sh`, symlink, docker Linux, hooks viết cho bash |

Vẫn nên WSL khi team hooks viết bash (`\\wsl$\Ubuntu\home\...`, mở VS Code bằng `code .` từ WSL) — toàn bộ series này viết cho Linux/macOS shell.

> 📄 **Code ví dụ:** [`examples/04-3-windows-powershell-thuan-hay-wsl.ps1`](examples/04-3-windows-powershell-thuan-hay-wsl.ps1)

Bẫy WSL hay gặp:

| Triệu chứng | Fix |
|---|---|
| Repo trong `/mnt/c` chạy test chậm rì | Clone lại vào `~/code` trong WSL (I/O qua 9P bridge chậm 5–10x) |
| `gh auth login` không mở được browser | Chọn `Login with a web browser` → copy code → paste vào browser Windows |
| Hook `.sh` báo `permission denied` | `chmod +x .claude/hooks/*.sh` trong WSL |
| Line ending CRLF làm hook gãy | `git config --global core.autocrlf input` |

> **Cách đọc bảng này:** cột "Triệu chứng" là thứ bạn nhìn thấy trên máy, cột "Fix" là việc làm ngay. Bị gì tra nấy — như tra bệnh theo triệu chứng, không cần đọc từ đầu đến cuối.

> **Tóm gọn 1 câu:** Dùng native Windows cho đơn giản, chỉ xuống WSL2 khi repo cần bash/Linux — và nhớ repo đặt trong `/mnt/c` là chạy chậm.

---

## 4. Version channels + version floor

Mục này nói về "bản nào, kênh nào": kênh cài đặt nào cho ai, và lệnh nào cần Claude Code bản bao nhiêu. Đọc để không tưởng lệnh thiếu là bug — nhiều khi chỉ là máy đang chạy bản cũ.

| Kênh | Lệnh | Khi dùng |
|---|---|---|
| Native stable | `curl -fsSL https://claude.ai/install.sh \| bash` | Mặc định mọi người |
| Homebrew cask (macOS) | `brew install --cask claude-code` | Máy quản lý bằng brew |
| npm legacy | `npm i -g @anthropic-ai/claude-code` | Chỉ khi cần pin version/CI đặc biệt — dễ duplicate |

> **Cách đọc bảng này:** đọc từ trên xuống theo mức "nên dùng": dòng đầu là mặc định, hai dòng dưới là trường hợp đặc biệt. Không biết chọn gì thì chọn dòng đầu.

Version floor đáng nhớ (v2.1.x) — không thấy lệnh → check floor trước khi kết luận bug. Giống như app điện thoại: tính năng mới chỉ mở khi app đủ bản, máy cũ thì menu có sẵn mà không thấy đâu:

| Feature cần | Version tối thiểu |
|---|---|
| `/goal` (điều kiện hoàn thành) | ≥ 2.1.139 |
| `/verify` (build + chạy app thật) | ≥ 2.1.145 |
| `/cd` (đổi working dir giữ prompt cache) | ≥ 2.1.169 |
| `/effort` (low→max) + `/mcp` text-mode | ≥ 2.1.205 |
| CLAUDE.md audit trong `/doctor` | ≥ 2.1.206 |
| `/verify` + `/code-review` chỉ chạy khi gọi tay | ≥ 2.1.215 |
| Fork skill background mặc định | ≥ 2.1.218 |

> **Cách đọc bảng này:** mỗi dòng là một lệnh/tính năng và "đỉnh cửa" version tối thiểu của nó; lệnh không xuất hiện trong session → đối chiếu `claude --version` với cột phải.

> **Tóm gọn 1 câu:** Cài kênh stable là mặc định; lệnh "biến mất" thường không phải bug mà là máy chưa đủ version floor.

---

## 5. Đăng nhập / đổi tài khoản / providers

Mục này nói về chuyện "xác minh danh tính": bạn đang trả tiền bằng cách nào và Claude Code đi đường nào để hỏi model. Đọc để chọn đúng đường và biết cái giá ẩn của từng đường.

Đăng nhập giống chọn phương thức thanh toán ở quán: cùng một bữa ăn, trả bằng thẻ thành viên (subscription) hay trả lẻ (API key) thì được tặng kèm món khác nhau.

> 📄 **Code ví dụ:** [`examples/06-5-ang-nhap-oi-tai-khoan-providers.sh`](examples/06-5-ang-nhap-oi-tai-khoan-providers.sh)

Trong session: `/login` (đổi account/re-auth), `/logout`, `/status` (version, model, account), `/exit` thoát.

| Bạn có gì | Chọn | Lệnh/env | Mất gì? |
|---|---|---|---|
| Subscription Pro/Max/Team | Sign-in `claude.ai` | `claude login` | Không mất gì, full features |
| Console API key (pay-as-you-go) | API key | `export ANTHROPIC_API_KEY=sk-ant-...` | Mất Web/Routines/Remote/Slack (bài 10) |
| AWS Bedrock | Bedrock provider | AWS creds + model ARN | Mất web search, fast mode, vài slash (bài 10) |
| Vertex / Foundry | GCP/Azure provider | GCP/Azure creds | Tùy feature (bảng bài 10) |

> **Cách đọc bảng này:** cột "Bạn có gì" là giấy thông hành bạn đang cầm; đọc ngang sang phải để biết lệnh gì và đổi lại tính năng nào — cột "Mất gì?" là phần quan trọng nhất, đừng bỏ qua.

> 📄 **Code ví dụ:** [`examples/07-5-ang-nhap-oi-tai-khoan-providers.sh`](examples/07-5-ang-nhap-oi-tai-khoan-providers.sh)

> Gặp "lệnh không tồn tại" → check provider + version floor (mục 4) trước khi kết luận bug. Full availability: bài 10.

> **Tóm gọn 1 câu:** Subscription là đường full features, còn API key/Bedrock/Vertex là đổi tiện dụng lấy linh hoạt hạ tầng — biết mình mất gì trước khi chọn.

---

## 6. Session đầu tiên trong 1 repo

Mục này là "nghi thức khai trương" cho mỗi repo: 4 lệnh setup chạy một lần đầu tiên, rồi một task nhỏ để chạy thử toàn mạch. Đọc để biết thứ tự và vì sao thứ tự đó.

Cứ hình dung như dọn vào nhà mới: đi dây điện (`/permissions`), ghi sổ nội quy (`/memory`), kết nước (`/mcp`) trước rồi mới nấu món đầu tiên.

> 📄 **Code ví dụ:** [`examples/08-6-session-au-tien-trong-1-repo.sh`](examples/08-6-session-au-tien-trong-1-repo.sh)

Chạy tuần tự (lần đầu duy nhất):

```text
/init        → sinh CLAUDE.md nháp (CLAUDE_CODE_NEW_INIT=1 để có flow interactive hỏi skills/hooks/memory)
/memory      → tinh chỉnh memory files, bật/tắt auto-memory (bài 03)
/mcp         → setup server cần thiết (GitHub trước — bài 08). Test: "liệt kê 5 PRs mở gần nhất"
/permissions → đặt allow/ask/deny (bài 10). Deny gợi ý: Bash(rm -rf:*), push main
```

Rồi 1 task end-to-end: "Chạy linter, fix 3 lỗi đầu, chạy lại để xác nhận. Báo cáo files đổi." Xong `/cost` xem tiền, `/export` lưu nếu cần. Kiểm tra: `/status` hiện working dir đúng; sai folder → `exit` rồi `cd` lại.

> **Tóm gọn 1 câu:** Repo mới = setup 1 lần theo thứ tự `/init → /memory → /mcp → /permissions`, rồi chạy thử một task nhỏ end-to-end để nghiệm thu.

---

## 7. `claude doctor` và `/doctor`

Mục này phân biệt hai "bác sĩ" cùng họ: một bác chỉ khám và đọc kết quả, một bác khám kèm hỏi có cho thuốc không. Đọc để biết gọi ai lúc máy ốm và đọc được phiếu kết quả.

- **`claude doctor`** (ngoài terminal): read-only diagnostics, KHÔNG sửa gì — giống bác sĩ khám tổng quát: nói bệnh, không tự kê đơn.
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

> **Cách đọc bảng này:** cột "Dòng" là hạng mục trong phiếu khám, đọc theo thứ tự nó in ra; thấy `[!]` ở dòng nào thì tra "Hành động khi `[!]`" cùng hàng — đó là đơn thuốc.

| Dòng | Hành động khi `[!]` |
|---|---|
| Version/Install/PATH | Gỡ bản thừa, fix PATH, restart shell |
| Auth | Hết hạn → `/login`; sai account → `/login` đổi |
| CLAUDE.md lines | `/doctor` → trim theo gợi ý (bài 03) |
| MCP disconnected | `/mcp reconnect <name>` (bài 08) |
| Hooks slow | Thu hẹp scope lint (chỉ file vừa edit, không `lint .`) |

Báo lỗi cho Anthropic: `/bug` (gửi conversation) + `/status` + `/doctor`.

> **Tóm gọn 1 câu:** `claude doctor` chỉ đọc bệnh, `/doctor` mới là người được kê đơn — đọc phiếu khám từ trên xuống, thấy `[!]` tra ngay cột hành động.

---

## 8. Update + biến môi trường debug

Mục này nói về 2 việc "bảo trì": cập nhật lên bản mới (quy tắc vàng: update trước, debug sau) và mấy biến môi trường để bật/tắt từng mảng khi truy tìm lỗi. Đọc để có sẵn hộp công cụ lúc sự cố.

Cập nhật kiểu vá lỗi xe: trước khi tháo máy tìm ồn, xuống chợ dán lại đồng hồ trước đã — nửa số bug biến mất ngay bước đó.

| Biến | Khi nào bật | Ví dụ |
|---|---|---|
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | Dùng `--add-dir ../shared`, muốn CLAUDE.md của folder đó cũng load | Monorepo/shared libs |
| `CLAUDE_CODE_SIMPLE=1` | Debug "MCP/hook/skill có phá không?" — tắt hết, test lại | Hook không chạy / MCP crash / lỗi lạ sau update |
| `CLAUDE_CODE_NEW_INIT=1` | Muốn `/init` hỏi interactive (skills/hooks/memory) | Repo mới, setup chuẩn team từ đầu |

> **Cách đọc bảng này:** cột "Khi nào bật" là câu hỏi bạn đang gặp; tìm dòng khớp tình huống rồi lấy biến ở cột đầu gán vào môi trường.

> 📄 **Code ví dụ:** [`examples/09-8-update-bien-moi-truong-debug.sh`](examples/09-8-update-bien-moi-truong-debug.sh)

> **Tóm gọn 1 câu:** Lỗi lạ thì `claude update` trước, sau đó mới bật biến môi trường để khoanh vùng — `CLAUDE_CODE_SIMPLE=1` là nút "ngắt hết phụ tùng" để nghe máy chạy không.

---

## 9. Hiểu nhầm, bẫy, checklist, bài tập, link

Mục này là "phòng cấp cứu cuối bài": mấy tin sai phổ biến, bảng lỗi kèm fix, checklist nghiệm thu và bài tập tự luyện. Đọc lướt phần hiểu nhầm để khỏi mất thời gian đi đường vòng.

### Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật |
|---|---|
| Cài npm cũng như native | npm phụ thuộc Node, dễ duplicate; `which -a claude` ra 2 dòng → gỡ npm, giữ native |
| Login rồi là full feature | API key/Bedrock/Vertex bị cắt Web/Routines/fast mode (bài 10) |
| `claude doctor` sẽ tự sửa | Lệnh ngoài terminal chỉ đọc; muốn sửa vào session gõ `/doctor` |
| Update là xong mọi lỗi lệnh | Còn bị chặn bởi provider + version floor → `/status` + gõ `/` xem list thực tế |

> **Cách đọc bảng này:** cột trái là câu "tưởng thế" nghe rất hợp lý; đọc sang cột phải để xóa misconception — nếu thấy mình đang tin cột trái, dừng lại kiểm tra ngay.

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

> **Cách đọc bảng này:** bị lỗi gì tra đúng dòng đó lấy Fix dán vào terminal; bảng xếp lỗi từ phổ biến nhất lên xuống — đọc từ đầu nếu chưa tìm thấy triệu chứng của mình.

### Checklist sau cài đặt

Cài xong chưa đóng ván bài — tick đủ 3 ô này coi như nghiệm thu:

- [ ] `claude --version` ≥ 2.1.x, `claude doctor` không đỏ, `which -a claude` chỉ 1 binary.
- [ ] `/init` + `/memory` cho repo chính; `/permissions` đặt allow/ask/deny; `/mcp` thêm 3–6 servers thực dùng.
- [ ] Test 1 task nhỏ end-to-end: prompt → edit → test → commit.

> **Tóm gọn 1 câu:** Cài đặt xong là khi: 1 binary duy nhất, doctor không đỏ, và một task end-to-end chạy trọn prompt → edit → test → commit.

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
