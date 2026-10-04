# /login — Đăng nhập tài khoản: OAuth trình duyệt, chọn plan, lưu token máy local

> Loại Built-in · Nhóm Auth · Nguy hiểm Không (chỉ mở flow xác thực; nhưng Có nhẹ nếu login nhầm tài khoản cá nhân trên máy công ty — token lưu local ai cầm máy cũng dùng được)

`/login` mở quy trình đăng nhập Claude Code: sinh URL OAuth (hoặc mở sẵn trình duyệt), bạn duyệt quyền trên web, CLI nhận token và lưu vào máy local, từ đó mọi session dùng quota của tài khoản đó. Hiểu `/login` là hiểu "cắm chìa khoá" — làm 1 lần, dùng nhiều tháng cho tới khi token hết hạn hoặc `/logout`.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/login` | _(không có)_ | Mở flow đăng nhập mặc định (OAuth trình duyệt) |
| `/login --sso` | flag | Đăng nhập qua SSO doanh nghiệp (Okta, Google Workspace...) |
| `/login --api-key` | flag | Nhập API key tay thay vì OAuth (cho máy headless/CI) |
| `/login --account <tên>` | tên profile | Đăng nhập thêm 1 tài khoản, lưu dưới tên riêng (đa tài khoản) |
| `/login --status` | flag | Chỉ xem đang đăng nhập ai, không mở flow mới |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: đăng nhập thông thường (mở trình duyệt)
# Gõ trong Claude Code:
/login
```

```bash
# Dạng 2: máy chủ headless (SSH, không có trình duyệt)
# Copy URL hiện ra, mở trên laptop, dán code xác nhận về:
/login
# → "Visit https://claude.ai/oauth/authorize?code=XXXX — paste code here:"
# (trên máy headless flow tự chuyển sang device-code, không cần --api-key)
```

```bash
# Dạng 3: đăng nhập SSO công ty
/login --sso
```

```bash
# Dạng 4: thêm tài khoản thứ hai (cá nhân + công ty)
/login --account work
/login --account personal
```

```bash
# Dạng 5: kiểm tra đang là ai (không login lại)
/login --status
# → "Signed in as nguyenvana@congty.vn (Pro) · token expires in 27 days"
```

---

## Cách nó hoạt động

### Cơ chế sâu: OAuth + accounts + token lưu ở đâu?

1. **OAuth device/browser flow (mặc định):**
   - CLI sinh `code_verifier` + `code_challenge` (PKCE), mở URL `https://claude.ai/oauth/authorize?...` trên trình duyệt mặc định.
   - Bạn bấm "Authorize" trên web → trang web trả `code` → CLI đổi `code` lấy `access_token` + `refresh_token` qua token endpoint.
   - Không có trình duyệt (SSH/headless)? CLI tự rơi về **device-code flow**: hiện URL + mã 8 ký tự, bạn mở URL trên điện thoại/laptop, nhập mã, CLI poll tới khi xác thực xong.
2. **Token lưu ở đâu (máy local)?**
   - Token + thông tin tài khoản lưu trong thư mục cấu hình user: `~/.claude/` (file accounts/credentials — quyền `600`, chỉ user đọc được).
   - Mỗi session Claude Code đọc token này để gắn header `Authorization: Bearer ...` khi gọi API. Không có token = không gọi được model.
   - Token có hạn (thường ~30 ngày). CLI tự dùng `refresh_token` để gia hạn ngầm — bạn không phải login lại trừ khi refresh cũng hết hạn.
3. **Đa tài khoản (`--account`):**
   - Mỗi `--account <tên>` là 1 profile token riêng trong `~/.claude/accounts/`. Chuyển qua lại bằng `/login --account <tên>` hoặc biến môi trường (xem `/status`).
   - Hữu ích khi 1 máy 2 vai: `work` (Pro công ty, quota chung) và `personal` (Pro cá nhân). Không lẫn quota, không lẫn billing.
4. **SSO doanh nghiệp (`--sso`):**
   - Thay vì OAuth Claude trực tiếp, flow đi qua IdP công ty (Okta/Google Workspace/Entra ID). Sau khi IdP xác thực, token trả về vẫn là token Claude nhưng gắn `org_id` của workspace.
   - Org có thể ép policy: managed permissions, chặn MCP ngoài, audit log — xem bài 10. Login SSO xong vẫn phải tuân policy đó.
5. **API key (`--api-key`) — khi nào dùng?**
   - Dành cho CI/automation hoặc máy không mở được trình duyệt lẫn device-code. Key nhập tay lưu như token thường nhưng **không tự refresh** — hết hạn là phải nhập lại.
   - Không nên dùng API key cá nhân trên máy share: ai `cat` được file credentials là lấy được key.
6. **Mối quan hệ với `/logout`, `/status`, `/config`:**
   - `/logout` = xoá token profile hiện tại (hoặc `--all`). `/status` = đọc token hiện tại và hiện "là ai + model + quota". `/config` tab Account = xem/đổi account mặc định mà không cần login lại.

### Sơ đồ 1 lần login

```text
/login
  ├─ Sinh PKCE → mở trình duyệt (hoặc hiện device-code nếu headless)
  ├─ Bạn bấm Authorize trên web (hoặc SSO công ty)
  ├─ CLI đổi code → access_token + refresh_token
  ├─ Lưu ~/.claude/accounts/<profile> (chmod 600)
  └─ Session hiện tại + session sau dùng luôn, không cần restart
  ↓ Hết hạn? → tự refresh ngầm → refresh chết? → báo "Re-authenticate" → /login lại
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Làm gì? | Khi nào dùng? |
|---|---|---|
| `/login` | Đăng nhập, lấy token mới | Lần đầu, hết hạn, thêm tài khoản |
| `/logout` | Xoá token, đăng xuất | Đổi máy, nhầm tài khoản, máy share |
| `/status` | Xem "đang là ai + model + quota" | Kiểm tra nhanh, không đổi gì |
| `/config` (tab Account) | Xem/đổi account mặc định | Đã có 2 account, muốn đổi default |
| `/remote-env` | Cấu hình môi trường remote (không đụng auth local) | Dùng cloud session |

> Quy tắc ngón tay cái:
>
> - **Chưa vào được → `/login`. Vào rồi muốn xem là ai → `/status`. Muốn ra → `/logout`. Muốn đổi default trong nhiều account → `/config`.**

---

## Ví dụ thực tế

### Kịch bản 1: Cài mới tinh trên laptop cá nhân (5 phút)

```bash
# Vừa cài xong theo bài 01, mở terminal:
claude

# Trong session gõ:
/login
# → Trình duyệt tự mở, bấm "Authorize Claude Code"
# → Terminal báo: "✓ Signed in as ban@gmail.com (Pro)"

# Kiểm tra:
/status
# → "Account: ban@gmail.com · Plan: Pro · Model: default"
```

> Kết quả: xong 1 lần, 1 tháng sau mới phải đụng lại (tự refresh ngầm).

### Kịch bản 2: SSH vào VPS headless (không có trình duyệt)

```bash
# SSH vào server:
ssh root@192.168.1.50

# Mở Claude Code, gõ:
/login
# → "No browser detected. Visit on your laptop:"
# → "https://claude.ai/oauth/device?code=ABCD-1234"

# Trên laptop: mở URL, nhập ABCD-1234, bấm Authorize
# Về terminal VPS: "✓ Signed in (device flow)"

# Mẹo: nếu mạng VPS chặn OAuth, dùng API key thay thế:
/login --api-key
# → "Paste API key:" (lấy key từ console.web, dán vào)
```

> Kết quả: VPS có token riêng, không phải copy file credentials từ laptop (mất an toàn).

### Kịch bản 3: 1 máy 2 tài khoản — công ty + cá nhân

```bash
# Login tài khoản công ty (SSO):
/login --account work --sso
# → "✓ Signed in as ban@congty.vn (Team) [profile: work]"

# Login tài khoản cá nhân:
/login --account personal
# → "✓ Signed in as ban@gmail.com (Pro) [profile: personal]"

# Sáng làm dự án công ty:
# /login --account work  → quota Team, policy công ty áp dụng

# Tối vọc side-project:
# /login --account personal → quota Pro cá nhân, không dính audit công ty
```

> Cảnh báo: trước khi `git push` code công ty, `/status` kiểm tra đang ở profile nào — push nhầm quota cá nhân thì tốn tiền túi.

### Kịch bản 4: CI runner — login không tương tác

```bash
# Trên GitHub Actions (không có người bấm Authorize):
# Không dùng /login tương tác. Dùng API key qua env:
```

```yaml
# .github/workflows/claude.yml
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
run: claude --print "/status"
```

> Kết quả: CI không cần `/login`, mỗi run đọc key từ secret. Hết key thì xoay trong console, không đụng code.

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào?

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Login tài khoản cá nhân trên máy công ty/share | Token lưu local, ai cầm máy cũng dùng quota bạn; nghỉ việc máy thu hồi mà token còn | Dùng `--account`, xong việc `/logout`; máy share thì dùng device-flow + logout ngay sau session |
| Copy file `~/.claude/` sang máy khác cho "tiện" | Lộ cả access + refresh token (tương đương mật khẩu) | Không copy credentials; máy mới thì `/login` lại từ đầu |
| Dùng `--api-key` rồi commit nhầm | Key vào git history, bot quét 5 phút là bị dùng chùa | Key chỉ qua env/secret manager; `git grep -i "sk-ant"` kiểm tra trước push |
| Login SSO nhưng tưởng quota cá nhân | Org policy giới hạn model/MCP, tưởng "lag" hoá ra bị chặn | `/status` xem org + policy; đọc bài 10 về managed permissions |
| Nhiều profile mà quên đang ở profile nào | Code công ty chạy bằng quota cá nhân (tốn tiền) hoặc ngược lại (lộ code vào audit sai org) | Đầu session luôn `/status`; đặt `statusline` hiện account (xem `/statusline`) |

### Tốn token?

- `/login` không tốn token model (chỉ gọi OAuth endpoint, không gọi LLM).
- Device-flow poll mỗi 5s trong lúc chờ — không đáng kể.

### Version / provider

- Đa profile `--account`: bản v2.x. Bản cũ chỉ 1 tài khoản — login mới ghi đè cũ.
- SSO (`--sso`): cần org bật SSO trên console; tài khoản free không có.
- Bedrock/Vertex: không dùng `/login` OAuth — auth qua AWS/GCP credentials (xem bài 01, mục provider).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/login` + `/status` | Login xong kiểm tra ngay | Login → status xem đúng mail + plan chưa |
| `/login` + `/config` | Có 2 account, đặt default | Login 2 profile → config chọn default |
| `/login` + `/logout` | Đổi ca công ty/cá nhân | Logout profile cũ → login profile mới |
| `/login` + `/teleport` | Login trên máy A, mang session sang máy B | Login cả 2 máy cùng account → teleport |
| `/login` + `/mobile` | Login desktop rồi pair điện thoại | Desktop login → mobile quét QR (cùng account) |

Workflow chuẩn "máy mới nhập team (10 phút)":

```bash
# 1. Cài theo bài 01, mở claude
# 2. Login SSO công ty
/login --account work --sso
# 3. Kiểm tra
/status
# → đúng mail công ty + org? Nếu sai: /logout rồi login lại
# 4. Xem policy áp dụng
# Đọc bài 10: managed permissions của org là gì
# 5. Cấu hình tiếp: /config, /ide, /terminal-setup
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Trình duyệt mở nhưng bấm Authorize xong CLI vẫn chờ | Callback localhost bị chặn (firewall/VPN) hoặc mở nhầm profile trình duyệt | Copy URL sang trình duyệt khác; tắt VPN thử; dùng device-code (mở trên máy khác, nhập mã) |
| `No browser detected` trên máy có GUI | Biến `BROWSER` unset hoặc chạy qua tmux/SSH | Set `export BROWSER=open` (macOS) rồi `/login` lại; hoặc dùng device-code |
| `Token expired, please re-authenticate` liên tục | Refresh token bị thu hồi (đổi pass, admin revoke) hoặc đồng hồ máy lệch | `/logout` rồi `/login` lại từ đầu; `sudo ntpdate` đồng bộ giờ |
| Login SSO báo `org not found` | Mail chưa được mời vào org, hoặc sai IdP | Nhờ admin mời đúng mail; kiểm tra đang login IdP nào trên trình duyệt |
| `--api-key` báo `invalid key` | Copy thiếu ký tự, key bị xoay, hoặc key Bedrock đem dùng cho Claude trực tiếp | Lấy key mới từ console, dán đủ; phân biệt provider (bài 01) |
| 2 profile nhưng `/status` vẫn hiện cũ | Quên chuyển profile sau login | `/login --account <tên>` lại để activate; xem default trong `/config` |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../logout/README.md](../logout/README.md) — đăng xuất, xoá token (ngược với login)
  - [../status/README.md](../status/README.md) — xem đang là ai, model gì, quota nào
  - [../config/README.md](../config/README.md) — tab Account: đổi default giữa nhiều profile
  - [../teleport/README.md](../teleport/README.md) — mang session đã login sang máy khác
  - [../mobile/README.md](../mobile/README.md) — pair điện thoại cùng tài khoản
  - [../remote-env/README.md](../remote-env/README.md) — auth trên cloud session khác gì local
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — cài đặt + xác thực lần đầu (đọc trước)
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — login khác nhau trên terminal/IDE/web ra sao
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — SSO org policy ảnh hưởng gì sau login

> Mẹo 1 dòng: _login 1 lần dùng cả tháng — nhưng đầu mỗi session `/status` 3 giây để chắc mình là đúng người, đúng quota._
