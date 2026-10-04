# /config — Trung tâm cài đặt: alias /settings, tabs Account/Permissions/MCP/Env

> Loại Built-in · Nhóm Settings · Nguy hiểm Có (sửa sai settings.json là mất phanh (permissions), mất tools (MCP), hoặc khoá luôn session — backup trước khi sửa tay)

`/config` (alias `/settings` — gõ cái nào cũng ra cùng 1 màn hình) là bảng điều khiển toàn bộ Claude Code: xem/sửa model, permissions, MCP servers, hooks, env, account mặc định... theo từng scope (project/local/managed). Hiểu `/config` là hiểu "phòng máy" — mọi lệnh khác (`/permissions`, `/mcp`, `/hooks`...) chỉ là cửa tắt vào từng tab của phòng này.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/config` | _(không có)_ | Mở UI cài đặt (tabs, điều hướng bằng phím) |
| `/settings` | alias | Y hệt `/config` (cùng 1 màn hình, không phải 2 lệnh) |
| `/config <tab>` | account, permissions, mcp, hooks, env, model, advanced | Mở thẳng tab cần (khỏi lật từng trang) |
| `/config --json` | flag | In config gộp ra JSON (debug, không mở UI) |
| `/config --scope <s>` | project, local, managed | Chỉ xem/sửa 1 scope |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở bảng điều khiển
/config
# → Tabs: Account · Model · Permissions · MCP · Hooks · Env · Advanced
```

```bash
# Dạng 2: alias — ai quen tay nào gõ tay đó
/settings
# → ra Y HỆT /config (không phải màn hình thứ hai)
```

```bash
# Dạng 3: nhảy thẳng vào tab permissions (vá phanh)
/config permissions
```

```bash
# Dạng 4: xem default account khi có nhiều profile
/config account
# → "Default: work (ban@congty.vn) · Available: work, personal"
```

```bash
# Dạng 5: in JSON để debug (config nào đang thắng?)
/config --json
# → {"model": "...", "permissions": {...}, "mcp": {...}, "scope_wins": "managed > local > project"}
```

---

## Cách nó hoạt động

### Cơ chế sâu: config/settings tabs + scopes + alias

1. **Alias `/config` = `/settings` (gộp chung, không phải 2 lệnh):**
   - Lịch sử: bản cũ gọi là `/settings`; bản mới đổi tên `/config` cho giống CLI (`claude config`). Cả 2 tên cùng trỏ 1 handler — bài này đặt ở folder `config` và ghi rõ alias để khỏi tìm 2 nơi.
   - File dưới đĩa cũng 2 tên 1 ruột: `.claude/settings.json` (project scope) và `~/.claude/settings.json` (local scope). Sửa ở UI hay sửa file tay đều như nhau (UI chỉ là editor có validate).
2. **Các tabs (mỗi tab là 1 mảng):**
   - **Account:** đang là ai (`/login` profile nào), default profile, plan/quota, nút Switch (đổi default không cần login lại).
   - **Model:** model mặc định, fallback khi quá tải, max tokens, thinking budget. Đổi ở đây áp cho session mới (session đang chạy giữ model cũ tới khi `/clear`).
   - **Permissions:** allow/ask/deny cho tools + Cd rules (≥2.1.169). Đây là tab đụng nhiều nhất — mọi "sao nó cứ hỏi / sao nó chạy luôn không hỏi" đều trả lời ở đây.
   - **MCP:** servers nào enabled, env của từng server, reconnect/kill. Tắt server nặng ở đây nhẹ context ngay.
   - **Hooks:** matcher → command, timeout, max-vòng. Hook crash xem log ở đây.
   - **Env:** biến môi trường default cho session mới (khác `/remote-env` là cho session remote đang chạy).
   - **Advanced:** prompt cache on/off, statusline command, vim mode default, telemetry, auto-update.
3. **Scopes: project vs local vs managed (ai thắng ai?):**
   - `project` (`.claude/settings.json` trong repo): đi theo git, cả team hưởng. Để baseline team (deny rm-rf, MCP chuẩn).
   - `local` (`~/.claude/` máy bạn): chỉ bạn hưởng, không commit. Để sở thích cá nhân + secret.
   - `managed` (org SSO đẩy xuống): admin công ty ép, bạn KHÔNG sửa được (UI hiện ổ khoá). Managed **thắng** local thắng project ở key xung đột (deny managed luôn thắng allow local — phanh công ty không gỡ được).
   - `/config --scope managed` để xem org đang ép gì (khỏi thắc mắc "sao allow rồi vẫn bị chặn").
4. **Cloud vs local config (sau teleport):**
   - Teleport KHÔNG mang settings máy A sang máy B. Cloud có config riêng (default + org policy). Sang máy mới thấy "phanh khác, MCP khác" là bình thường — cấu lại hoặc version hoá `.claude/settings.json` trong git để team đồng bộ phần project scope.
   - Secret KHÔNG bao giờ để trong project scope (vào git là lộ). Secret local → `local` scope hoặc env; secret team → secret manager, không phải settings.
5. **Validate + backup:**
   - UI `/config` validate JSON trước khi lưu (sửa tay không có lưới an toàn này). Sửa tay: `cp settings.json settings.json.bak` trước, sửa xong `/config --json` kiểm tra parse được.
   - Sửa sai khoá session (deny hết tools)? Xoá/rename file settings scope đó là về mặc định — đừng reinstall cả CLI.

### Sơ đồ scopes ai thắng

```text
managed (org ép, ổ khoá)   ─┐
local (~/.claude, của bạn) ─┼─► merge: managed thắng local thắng project
project (.claude/, cả team) ┘     (deny managed > allow local: phanh công ty gỡ không được)
Cloud sau teleport: config riêng (default + org), KHÔNG copy từ máy A.
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Phạm vi | Dùng khi nào? |
|---|---|---|
| `/config` = `/settings` | Tất cả tabs + scopes | Muốn 1 chỗ xem/sửa hết |
| `/permissions` | Cửa tắt vào tab Permissions | Chỉ vá phanh, lười mở full UI |
| `/mcp` | Cửa tắt vào tab MCP | Chỉ đụng server ngoài |
| `/hooks` | Cửa tắt vào tab Hooks | Chỉ đụng phản xạ tự động |
| Sửa `settings.json` tay | Cùng ruột với UI | Bulk edit, script hoá, review diff git |

> Quy tắc ngón tay cái:
>
> - **Biết rõ tab nào → lệnh tắt (`/permissions`, `/mcp`). Không biết bệnh ở đâu → `/config` xem hết. Sửa hàng loạt/review git → sửa file tay + backup.**

---

## Ví dụ thực tế

### Kịch bản 1: Mới vào team — xem org ép gì trước khi kêu "sao bị chặn"

```bash
/config --scope managed
# → {"deny": ["Bash(sudo:*)", "MCP(external-*赤)"], "region": "eu-west", ...}
# → À, công ty cấm sudo + MCP ngoài. Khỏi thắc mắc, khỏi tìm cách gỡ (gỡ không được).

/config --scope project
# → baseline team: deny rm-rf, allow test/lint (đi theo git, đã có sẵn)
```

> Kết quả: 2 phút hiểu luật chơi, không mất buổi sáng "sao em allow rồi vẫn bị chặn".

### Kịch bản 2: Alias — chứng minh /config và /settings là một

```bash
/config permissions
# → mở tab Permissions...

/settings permissions
# → ...ra Y HỆT màn hình trên (cùng handler, cùng file dưới đĩa)
```

> Kết quả: nhớ 1 là đủ. Bài này gộp chung để bạn không tìm 2 folder.

### Kịch bản 3: Đổi default account khi có 2 profile

```bash
# Sáng làm công ty, tối vọc cá nhân — đổi default khỏi login lại:
/config account
# → "Default: personal · Available: work, personal"
# → chọn work → "Default switched to work. New sessions use work."
# → session đang chạy giữ acc cũ (đổi áp cho session mới)
```

> Cảnh báo: đổi default không đá session đang chạy sang acc mới — muốn session này đổi luôn thì `/logout` + `/login` lại.

### Kịch bản 4: Sửa tay settings.json an toàn (bulk edit + review git)

```bash
# Backup trước (luật sắt):
cp .claude/settings.json .claude/settings.json.bak
cp ~/.claude/settings.json ~/.claude/settings.json.bak

# Sửa (ví dụ thêm Cd deny):
```

```json
{
  "permissions": {
    "Cd": { "deny": ["~/.ssh", "~/.aws"] },
    "deny": ["Bash(rm -rf:*)", "Bash(sudo:*)", "Read(.env*)"]
  }
}
```

```bash
# Kiểm tra parse + hiệu lực:
/config --json
# → JSON hiện ra = parse OK. Sai thì restore .bak rồi mở /config UI sửa.

# Team: review diff trước khi push baseline
git diff .claude/settings.json
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào?

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Sửa tay sai 1 dấu phẩy JSON | Cả scope đó fail parse → về default (mất phanh mình đặt mà không biết) | Backup `.bak`; sửa xong `/config --json` kiểm tra; hoặc sửa bằng UI có validate |
| `allow: ["Bash(*)"]` cho "đỡ bị hỏi" | Mở toang shell — Claude (hoặc injection từ CLAUDE.md lạ) chạy gì cũng được | allow hẹp từng lệnh (`Bash(npm test:*)`); lệnh lạ để ask; đọc bài 10 |
| Commit secret vào project scope settings | Key vào git history, lộ vĩnh viễn | Project scope chỉ baseline không secret; secret ở local scope/env/vault |
| Cố gỡ deny của managed | Không gỡ được (thiết kế) + admin thấy audit log sửa config | Đọc `--scope managed` để biết giới hạn; xin admin nếu cần thật |
| Đổi model giữa session tưởng áp ngay | Session đang chạy giữ model cũ → tưởng "đổi rồi mà vẫn dở" | Đổi model áp cho session mới (hoặc `/clear` để session hiện tại nhận) |
| Cloud vs local config lẫn lộn | Teleport sang máy mới, phanh/MCP khác, tưởng "mất config" | Version hoá project scope trong git; local scope cấu lại tay mỗi máy |

### Tốn token?

- `/config` không tốn token model (UI local + đọc file). Đổi model sang loại đắt thì session sau tốn hơn — đó là chi phí dùng, không phải chi phí sửa.

### Version / provider

- Tên `/config` + alias `/settings`: bản v2.x (cũ chỉ `/settings`). Folder bài này là `config`, `/settings` không có folder riêng.
- Cd rules tab: ≥2.1.169. Tab picker đẹp + Tab gợi ý: ≥2.1.206.
- Bedrock/Vertex: tab Account hiện IAM/provider thay vì OAuth; model list theo vendor.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/config` + `/doctor` | Khám xong vá ở đây | Doctor chỉ bệnh → config sửa |
| `/config` + git | Version hoá baseline team | Sửa project scope → diff → push |
| `/config account` + `/login` | Quản trị đa acc | Login 2 profile → config chọn default |
| `/config --json` + CI | Kiểm tra config trong pipeline | Parse JSON, assert có deny rm-rf |
| `/config` + `/status` | Sửa xong kiểm tra | Config → status xem hiệu lực chưa |

Workflow chuẩn "setup máy mới nhập team (15 phút)":

```bash
# 1. Login SSO
# /login --account work --sso
# 2. Xem org ép gì
/config --scope managed
# 3. Pull baseline team (đi theo git, có sẵn)
/config --scope project
# 4. Thêm sở thích cá nhân ở local scope (vim? theme? statusline?)
/config
# 5. Kiểm tra hiệu lực
/config --json
# /status
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Sửa settings tay xong config "bay về default" | JSON sai cú pháp, fail parse | Restore `.bak`; dùng UI sửa; `python3 -m json.tool settings.json` check |
| Allow rồi mà vẫn bị chặn | Managed deny đè (thiết kế) | `/config --scope managed` xem ai chặn; xin admin, đừng cố gỡ |
| `/settings` tưởng lệnh khác `/config` | Không — cùng 1 handler | Nhớ 1 là đủ; bài này gộp chung |
| Đổi model không thấy khác | Session cũ giữ model | `/clear` hoặc session mới mới nhận model mới |
| Tab MCP trống dù `.mcp.json` có server | File sai scope (để local nhưng xem project) hoặc JSON lỗi | `--scope` đúng; `--json` kiểm tra parse; xem `/mcp` reconnect |
| Teleport sang máy mới "mất hết config" | Local scope không đi theo | Cấu lại local scope; project scope pull từ git là có |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../status/README.md](../../auth-settings/status/README.md) — xem config đang hiệu lực (acc, model, cwd, cache)
  - [../login/README.md](../../auth-settings/login/README.md) — thêm profile cho tab Account
  - [../logout/README.md](../../auth-settings/logout/README.md) — đá profile khỏi máy
  - [../cd/README.md](../../auth-settings/cd/README.md) — Cd rules đặt trong tab Permissions
  - [../add-dir/README.md](../../auth-settings/add-dir/README.md) — trust store xem ở đây
  - [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md) — fix Shift+Enter nằm ở tab Advanced
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md) — setup và scopes lần đầu
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — config khác nhau mỗi bề mặt
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — permissions + scopes + managed chi tiết (đọc kỹ)

> Mẹo 1 dòng: _`/config` và `/settings` là một — và trước khi sửa tay, `cp ... .bak` 3 giây cứu 3 tiếng._
