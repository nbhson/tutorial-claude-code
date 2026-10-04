# FAQ 01 — Tài Khoản, Pricing & Cài Đặt

> Nhóm Tài khoản & Cài đặt · 10 câu hỏi deep-dive · Đọc xong tự cài, tự chọn provider, tự fix lỗi version trong 10 phút

File này trả lời mọi câu hỏi "dùng Claude Code thì cần tài khoản gì, tốn bao nhiêu, cài sao cho sạch". Mỗi câu có giải thích + lệnh copy-paste + ví dụ + khi nào áp dụng.

---

## Bảng tổng hợp: chọn đường vào nhanh

| Bạn là ai | Tài khoản cần | Cài thế nào | Lệnh đầu tiên |
|---|---|---|---|
| Dev cá nhân có Pro/Max | Subscription Claude (Pro/Max) | Native binary + `claude login` | `claude`, rồi `/status` |
| Dev công ty dùng API | Anthropic Console API key | Native binary + env `ANTHROPIC_API_KEY` | `claude -p "hi"` test |
| Team AWS (Bedrock) | AWS creds + model access | Native + config provider Bedrock | `/status` check provider |
| Team GCP (Vertex) | GCP project + Agent Platform | Native + config GCP | `/status` check provider |
| Dùng Web/Mobile/Slack/Routines/Remote/Chrome | Bắt buộc `claude.ai` sign-in | Không dùng API-key-only | `/web-setup` rồi `claude --cloud` |
| Repo mới tinh | Bất kỳ loại trên | `cd repo && claude` | `/init → /memory → /mcp → /permissions` |

---

## 1. Cần tài khoản gì để dùng Claude Code?

**Giải thích.** Có 2 đường vào chính, đừng nhầm:

- **Subscription (Pro / Max / Team / Enterprise):** đăng nhập bằng tài khoản `claude.ai`. Dùng chung quota subscription. Hợp cho dev cá nhân và team đã mua gói Claude.
- **API key (Anthropic Console):** `sk-ant-...` trả theo usage. Hợp cho CI, automation, team muốn tách bill theo key.

Terminal CLI + VS Code extension hỗ trợ thêm **third-party providers**: Bedrock, GCP Agent Platform (Vertex), Foundry... — tức là model chạy qua cloud của bạn thay vì Anthropic trực tiếp.

**Lệnh copy-paste:**

```bash
# Cách 1: subscription (khuyên dùng cho dev tay)
claude login
# → mở browser, sign-in claude.ai, quay lại terminal

# Cách 2: API key (khuyên dùng cho CI/máy phụ)
export ANTHROPIC_API_KEY="sk-ant-xxxx"
claude -p "ping" --output-format json
```

**Ví dụ:** bạn có Pro cá nhân + công ty cấp Bedrock. Máy dev dùng `claude login` (Pro), CI dùng Bedrock creds — tách 2 môi trường, không lẫn bill.

**Khi nào áp dụng:** luôn quyết định NGAY từ đầu, vì nó khóa luôn câu 3 (có dùng được Web/Routines không).

---

## 2. Provider matrix: Sub / Console / Bedrock / GCP / Foundry khác nhau gì?

**Giải thích.** Không phải provider nào cũng có đủ tính năng. Bảng dưới là bản đồ "đường nào đi được tới đâu":

| Tính năng | Sub (claude.ai) | Console API | Bedrock | GCP/Vertex | Foundry |
|---|---|---|---|---|---|
| Terminal + IDE cơ bản | ✅ | ✅ | ✅ | ✅ | ✅ (giới hạn) |
| Web / Mobile / Desktop-cloud | ✅ | ❌ (cần sign-in) | ❌ | ❌ | ❌ |
| Slack / Chrome ext / Computer use / Artifacts | ✅ | ❌ | ❌ | ❌ | ❌ |
| Routines (`/schedule`) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Remote (`--cloud`, teleport) | ✅ | ❌ | ❌ | ❌ | ❌ |
| CI `-p` headless | ✅ | ✅ | ✅ | ✅ | ❌ |
| ZDR (zero retention) | Enterprise qualified | Qualified accounts | Mặc định tắt gửi về Anthropic* | Mặc định tắt* | Theo MS contract |
| Telemetry gửi về Anthropic | Theo cài đặt | Theo cài đặt | Tắt mặc định | Tắt mặc định | Theo MS |

\* Xem provider docs của bạn để xác nhận; hỏi admin/contract trước khi cam kết với khách hàng (chi tiết FAQ 09).

**Khi nào áp dụng:** team enterprise chọn Bedrock/GCP vì compliance → chấp nhận mất Routines/Remote. Dev indie chọn Sub → được full tính năng cloud.

---

## 3. Web / Mobile / Desktop-cloud / Slack / Routines / Remote / Chrome / Computer use / Artifacts — vì sao bắt buộc `claude.ai` sign-in?

**Giải thích.** Các mặt này chạy trên hạ tầng cloud của Anthropic (session persist cross-device, push branch, schedule...), nên phải gắn với identity `claude.ai`, không thể chỉ cầm API key gọi vào. API-key-only = cục model trần, không có lớp "session cloud".

**Lệnh copy-paste:**

```bash
# Trong terminal đã login Sub:
claude login        # đảm bảo đã sign-in claude.ai
/status             # xem account hiện tại
/web-setup          # sync token + tạo cloud environment (cần gh CLI)
/teleport           # thử chuyển session lên cloud
```

**Ví dụ:** bạn dùng API key Console, gõ `/schedule` → báo thiếu quyền. Fix: `claude login` sang Sub rồi thử lại.

**Khi nào áp dụng:** ngay khi ai đó hỏi "sao em không thấy nút cloud" — 99% là đang dùng API-key-only. Chi tiết xem [FAQ 10](10-ci-sdk-routines-web.md).

---

## 4. Cài đặt thế nào cho sạch: native binary vs Homebrew vs npm?

**Giải thích.** Có 3 đường cài, nhưng chỉ nên giữ **1**:

- **Native binary (khuyên dùng):** `curl .../install.sh | bash` — binary chính chủ, update nhanh, ít lỗi PATH nhất.
- **Homebrew cask:** tiện cho macOS (`brew install --cask claude-code`), nhưng version có thể chậm hơn native nửa nhịp.
- **npm (`npm i -g @anthropic-ai/claude-code`):** chỉ khi bạn kẹt môi trường không cài được binary (VD container lạ). Dễ dính duplicate install nhất.

**Lệnh copy-paste:**

```bash
# Cách khuyên dùng (native):
curl -fsSL https://claude.ai/install.sh | bash
claude --version

# macOS brew (thay thế, không dùng song song với native):
brew install --cask claude-code

# IDE: cài extension "Claude Code" trong VS Code / JetBrains rồi login
```

**Khi nào áp dụng:** máy mới → native. Đừng bao giờ `npm install` thêm khi đã có native.

---

## 5. Duplicate install (2 bản Claude song song) — phát hiện và dọn?

**Giải thích.** Triệu chứng: `which -a claude` ra 2 đường, `/status` báo version khác `claude --version`, update hoài không lên. Nguyên nhân 90% là vừa cài native vừa `npm i -g`.

**Lệnh copy-paste:**

```bash
which -a claude
claude --version
npm ls -g @anthropic-ai/claude-code 2>/dev/null
claude doctor   # phát hiện duplicate install

# Dọn: giữ native, gỡ npm
npm uninstall -g @anthropic-ai/claude-code
hash -r
which claude    # giờ chỉ còn 1
claude update
```

**Ví dụ:** `which -a` ra `/opt/homebrew/bin/claude` + `~/.nvm/.../claude`. Gỡ bản npm, giữ brew/native, PATH sạch lại.

**Khi nào áp dụng:** mỗi khi update không có tác dụng hoặc lệnh mới (VD `/cd`) báo `Unknown command` dù đã update.

---

## 6. `claude login/logout` vs `/login`, `/logout`, `/status` — dùng cái nào?

**Giải thích.** Có 2 mặt trận:

- **Ngoài terminal (shell):** `claude login` / `claude logout` — xác thực account cho CLI.
- **Trong session (đang chat với Claude):** `/login` / `/logout` / `/status` — xem và đổi account ngay trong phiên, không cần thoát.

`/status` là lệnh "soi gương": hiện account, provider, model, version, working dirs.

**Lệnh copy-paste:**

```bash
# Ngoài terminal:
claude login
claude logout

# Trong session:
/status
/login
/logout
```

**Ví dụ:** đang làm mà nghi sai account (bill vào key công ty thay vì Pro cá nhân) → gõ `/status`, thấy sai thì `/logout` → `/login` lại, không mất session.

**Khi nào áp dụng:** đầu mỗi máy mới, đầu mỗi session lạ, và mỗi khi bill có gì sai sai.

---

## 7. `claude update` và version floor: lệnh lạ 90% là version cũ

**Giải thích.** Claude Code phát triển nhanh (2025–2026 đổi API liên tục). Gõ lệnh mới trên bản cũ → `Unknown command`. Quy tắc: **update trước, debug sau**.

Bảng version floor hay gặp (kiểm tra bằng `/status` + release notes):

| Lệnh / tính năng | Cần bản tối thiểu | Ghi chú |
|---|---|---|
| `/cd` | ≥2.1.169 | Bản cũ không có |
| `/verify` | ≥2.1.145 | Chạy app thật |
| `/goal` | ≥2.1.139 | Đặt mục tiêu session |
| Nút `trim` CLAUDE.md trong `/doctor` | ≥2.1.206 | Cũ hơn chỉ báo dài |
| `disable-model-invocation` chặn scheduled fire | ≥2.1.196 | Trước đó chỉ chặn tay |
| `/mcp` no-arg in text trong `-p` | ≥2.1.205 | Headless mới có |
| Full `/doctor` 6 mục | v2.x | Bản 1.x chỉ 2 mục |

**Lệnh copy-paste:**

```bash
claude update
claude --version
# Trong session:
/status    # xem version đang chạy
```

**Ví dụ:** gõ `/cd web` → `Unknown command: /cd`. Đừng sửa config gì cả: `claude update` lên ≥2.1.169, mở session mới, gõ lại → chạy.

**Khi nào áp dụng:** mọi lỗi "lệnh không tồn tại" — luôn là bước 1 trong thứ tự debug (xem FAQ 08).

---

## 8. Bắt đầu repo mới: 5 lệnh setup đầu repo là gì?

**Giải thích.** Thứ tự chuẩn cho repo vừa clone / vừa tạo (làm 1 lần, hưởng cả dự án):

1. `/init` — sinh CLAUDE.md từ codebase thật (đừng viết tay từ đầu).
2. `/memory` — tách sở thích cá nhân ra khỏi CLAUDE.md.
3. `/mcp` — gắn data ngoài repo (DB, tickets, docs...). Không có thì bỏ qua.
4. Tạo subagents — tách việc đọc ồn sang worker (xem FAQ 07).
5. `/permissions` — dựng phanh allow/ask/deny baseline (xem FAQ 03).

**Lệnh copy-paste:**

```bash
cd ~/code/my-repo && claude
```

```bash
# Trong session, theo thứ tự:
/init
/memory
/mcp
/permissions
/doctor   # khám lại xem còn đỏ gì
```

**Ví dụ repo mới tinh (chưa có code):** không có gì để `/init` quét → copy `templates/CLAUDE.md` trong tutorial này rồi sửa cho hợp stack, sau đó chạy 5 lệnh trên từ bước 2.

**Khi nào áp dụng:** mọi repo chưa từng dùng Claude Code. Team thì commit `.claude/` + `CLAUDE.md` sau bước 5 để người sau khỏi setup lại.

---

## 9. Project mới tinh thì copy `templates/CLAUDE.md` thế nào?

**Giải thích.** `/init` cần code để quét. Repo trống → nó sinh ra file chung chung. Cách ngon hơn: copy template theo stack rồi sửa 20%.

**Lệnh copy-paste:**

```bash
ls templates/
cp templates/CLAUDE.md ./CLAUDE.md
# Mở CLAUDE.md, sửa: stack, lệnh test/lint/build, cấu trúc thư mục, quy ước branch
```

**Ví dụ:** template Node ghi `npm test`; bạn dùng `pnpm` → sửa ngay dòng đó. Sai 1 dòng này, model chạy sai lệnh cả tháng.

**Khi nào áp dụng:** `git init` vừa xong, chưa có file nào. Sau khi code lên hình (vài trăm dòng), chạy `/init` lại để nó bổ sung kiến trúc thật.

---

## 10. Báo lỗi cho Anthropic thế nào (`/bug`)?

**Giải thích.** `/bug` gói conversation + context thành bug report gửi Anthropic. Nhưng gửi mỗi conversation thì team Anthropic khó tái hiện — phải kèm thêm 2 thứ: `/status` (account/provider/version/model) và `claude doctor` (sức khoẻ máy).

**Lệnh copy-paste:**

```bash
# Trong session đang lỗi:
/status
/bug
```

```bash
# Ngoài terminal (paste kèm vào issue):
claude doctor
claude --version
```

**Ví dụ report chuẩn:**

```text
Tiêu đề: /mcp reconnect treo sau sleep (macOS, v2.1.x)
Mô tả: reconnect GitHub server quay 60s rồi timeout, hôm qua còn chạy.
Kèm: /status output + claude doctor output + steps (sleep → wake → /mcp → treo).
```

**Khi nào áp dụng:** khi đã đi hết thứ tự debug (FAQ 08) mà vẫn lỗi, và nghi lỗi của chính Claude Code chứ không phải config của bạn.

---

## Vẫn lỗi thì sao? (thứ tự debug chuẩn)

1. `/status` — xem version + account + provider (cũ → `claude update`).
2. `claude doctor` — phát hiện duplicate install, settings parse lỗi, PATH lỗi.
3. `/permissions` — xem merged rules (lỗi lạ có thể do deny ẩn).
4. `/debug` — chẩn đoán session hiện tại.
5. `/bug` — gói report gửi Anthropic (kèm `/status` + `claude doctor`).

```bash
claude update && claude doctor
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/status/README.md](../01-huong-dan-su-dung/commands/status/README.md) — soi version/account/provider
  - [../01-huong-dan-su-dung/commands/doctor/README.md](../01-huong-dan-su-dung/commands/doctor/README.md) — khám duplicate install, settings lỗi
  - [../01-huong-dan-su-dung/commands/login/README.md](../01-huong-dan-su-dung/commands/login/README.md) — đăng nhập trong session
  - [../01-huong-dan-su-dung/commands/bug/README.md](../01-huong-dan-su-dung/commands/bug/README.md) — gửi bug report
  - [../01-huong-dan-su-dung/commands/init/README.md](../01-huong-dan-su-dung/commands/init/README.md) — setup repo mới
  - [../01-huong-dan-su-dung/commands/permissions/README.md](../01-huong-dan-su-dung/commands/permissions/README.md) — dựng phanh baseline
  - [../01-huong-dan-su-dung/02-cac-be-mat-terminal-ide-web-desktop.md](../01-huong-dan-su-dung/02-cac-be-mat-terminal-ide-web-desktop.md) — lên cloud (cần sign-in)
  - [../01-huong-dan-su-dung/commands/teleport/README.md](../01-huong-dan-su-dung/commands/teleport/README.md) — chuyển session lên cloud
- Bài tổng quan:
  - [../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md) — cài đặt + xác thực chi tiết
  - [../01-huong-dan-su-dung/04-slash-commands-toan-tap.md](../01-huong-dan-su-dung/04-slash-commands-toan-tap.md) — tra cứu lệnh theo version
  - [../02-tips-thuc-chien/10-debugging-power-moves.md](../02-tips-thuc-chien/10-debugging-power-moves.md) — thứ tự debug chuẩn
- FAQ tiếp theo: [02-model-context-token.md](02-model-context-token.md) (chọn model + giữ context), [FAQ 08](08-loi-thuong-gap-troubleshooting.md) (bảng lỗi full).

> Mẹo 1 dòng: _update trước debug sau, giữ đúng 1 bản cài, và 5 lệnh đầu repo là init → memory → mcp → subagents → permissions._
