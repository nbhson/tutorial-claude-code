# /plugin — Chợ ứng dụng của Claude: cài 1 lần được cả bộ skill + agent + MCP

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Có (plugin chạy code trên máy bạn: hooks + MCP server của plugin có thể đọc file, gọi mạng — chỉ cài nguồn tin cậy)

`/plugin` mở trình quản lý plugin (plugin manager): khám phá (Discover), duyệt (Browse) và quản lý (Manage) các gói mở rộng. Một plugin = bundle gồm `skills/` (quy trình), `agents/` (subagent chuyên), `hooks/` (tự động hoá), MCP config (tools mới) và `commands/` (slash command mới) — cài 1 lần là có cả bộ, khỏi lắp từng mảnh. Hiểu `/plugin` là hiểu "app store" của Claude Code.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/plugin` | _(không có)_ | Mở UI manager (3 tab: Discover/Browse/Manage) |
| `/plugin discover` | — | Gợi ý plugin theo việc bạn đang làm |
| `/plugin browse` | từ khoá | Duyệt marketplace (official + community) |
| `/plugin install <tên>` | tên plugin | Cài plugin (hỏi scope user/project) |
| `/plugin remove <tên>` | tên | Gỡ plugin |
| `/plugin update` | — | Cập nhật mọi plugin đã cài |
| `/plugin list` | — | Liệt kê đã cài + version |
| Marketplace file | `.claude/settings.json` | Khai báo `plugins:` + `marketplaces:` cho team |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở UI tổng
/plugin
```

```bash
# Dạng 2: tìm plugin theo nhu cầu
/plugin browse pdf
/plugin browse "code review"
```

```bash
# Dạng 3: cài plugin official (copy-paste)
/plugin install commit-commands
/plugin install pr-review-toolkit
```

```bash
# Dạng 4: cài từ GitHub trực tiếp
/plugin install gh:owner/repo
```

```bash
# Dạng 5: khai báo cho cả team (file .claude/settings.json)
```

```json
{
  "marketplaces": ["anthropics/official-plugins", "myteam/claude-plugins"],
  "plugins": ["commit-commands@1.2.0", "pr-review-toolkit@latest"]
}
```

```bash
# Dạng 6: cập nhật + dọn
/plugin update
/plugin remove plugin-cu-khong-dung-nua
```

---

## Cách nó hoạt động

### Cơ chế sâu: Discover / Browse / Manage + namespacing

1. **Một plugin chứa gì? (giải nén 1 plugin mẫu):**
   - `plugin.json` (manifest): tên, version, mô tả, marketplace. VD `{"name": "pr-review-toolkit", "version": "1.2.0"}`.
   - `commands/` (slash commands mới): sau khi cài, gõ `/` thấy thêm `/pr-review`, `/commit-smart`... Đây là mặt tiền bạn thấy đầu tiên.
   - `skills/` (SKILL.md): quy trình nhiều bước plugin mang theo (VD skill review 5 pha).
   - `agents/` (subagent chuyên): VD agent `security-reviewer` chỉ plugin này có.
   - `hooks/hooks.json`: tự động hoá plugin đăng ký (VD auto-format sau mỗi Edit).
   - `.mcp.json` (optional): MCP server kèm theo (VD server GitHub để tạo issue).
   - Cài plugin = nạp cả 5 mảnh vào session. Gỡ = rút cả 5.
2. **3 tab trong `/plugin` UI:**
   - `Discover`: Claude nhìn việc bạn đang làm (đọc repo, task gần đây) rồi gợi ý "repo Python này nên cài ruff-enforcer". Ít mà trúng.
   - `Browse`: chợ — official (Anthropic duy trì, audited) + community (ai cũng đăng được, hên xui). Mỗi plugin hiện star, downloads, quyền nó xin (đọc file? chạy mạng?).
   - `Manage`: đã cài gì, version nào, enable/disable từng cái, update. Disable là tắt tạm không gỡ (giữ config).
3. **Namespacing (chống đụng tên) — cơ chế quan trọng nhất:**
   - Lệnh/agent/skill của plugin được prefix bằng tên plugin: `/pr-review-toolkit:review` thay vì `/review` chung chung.
   - Hai plugin cùng có lệnh `review` → không đè nhau: `pluginA:review` vs `pluginB:review`.
   - Gọi tắt `/review` khi chỉ có 1 plugin cung cấp → Claude tự resolve. Có 2 → picker hỏi bạn chọn.
   - Agent cũng vậy: `pr-review-toolkit:security-reviewer`.
4. **Scopes cài đặt (cài cho ai?):**
   - `user` (`~/.claude/plugins/`): riêng bạn, mọi repo. Hợp cho sở thích (theme, alias).
   - `project` (`.claude/plugins/` hoặc khai báo trong settings commit git): team cùng dùng. Hợp cho chuẩn team (review toolkit, commit convention).
   - Project khai báo `plugins: [...]` trong settings → thành viên mới `clone` + mở Claude là tự cài (hoặc hỏi Yes 1 lần).
5. **Enable/disable vs install/remove:**
   - `disable`: tắt tạm (không nạp vào session, giữ file + config). Dùng khi debug xung đột ("tắt từng plugin xem lỗi hết không").
   - `remove`: xoá hẳn (file + config). Muốn dùng lại phải install lại.
6. **Update và version pin:**
   - `latest`: luôn mới nhất (tiện nhưng có thể vỡ khi plugin đổi behavior).
   - Pin `1.2.0`: ổn định cho team (khuyên dùng trong settings commit git).
   - `/plugin update`: kéo bản mới cho mọi plugin `latest`; plugin pin thì báo có bản mới nhưng không tự lên.
7. **Hooks của plugin (con dao 2 lưỡi):**
   - Plugin có thể đăng ký hooks (VD "sau mỗi Edit chạy formatter"). Hooks CHẠY CODE TRÊN MÁY BẠN mỗi khi trigger.
   - Trước khi install, UI hiện "plugin này xin: đọc file, chạy shell, gọi mạng" — đọc kỹ như đọc quyền app điện thoại.
   - Không tin thì cài xong `disable` hooks của nó trong `/hooks` UI, giữ lại skill/commands.

### Sơ đồ cài và nạp plugin

```text
/plugin install pr-review-toolkit
  ↓ tải từ marketplace → ~/.claude/plugins/ (user) hoặc .claude/plugins/ (project)
  ↓ đọc plugin.json (manifest)
  ↓ đăng ký:
  ├─ commands/ → /pr-review-toolkit:review, /pr-review-toolkit:fix-comments
  ├─ skills/   → skill review-5-pha (model tự trigger khi review PR)
  ├─ agents/   → agent security-reviewer
  ├─ hooks/    → PostToolUse(Edit) → chạy formatter kèm theo
  └─ .mcp.json → server github (tools mcp__github__*)
  ↓ session sau: cả 5 mảnh sẵn sàng, namespaced gọn
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Đóng gói | Cài 1 lần được gì? | Dùng khi nào? |
|---|---|---|---|
| Plugin | Bundle 5 mảnh | Skill + agent + hook + MCP + commands | Cần cả bộ cho 1 nhu cầu (review PR) |
| Skill (lẻ) | 1 quy trình | 1 SKILL.md | Chỉ cần quy trình, không cần tools mới |
| MCP (lẻ) | Tools mới | Server + tools | Chỉ cần tool (query DB) |
| Marketplace | Chợ chứa plugins | Nơi browse | Tìm plugin mới |

> Quy tắc ngón tay cái:
>
> - **Cần cả bộ (review PR: skill + agent + MCP github) → plugin. Chỉ cần 1 mảnh → cài mảnh đó, đừng vác cả plugin.**

---

## Ví dụ thực tế

### Kịch bản 1: Team chuẩn hoá commit + review (2 plugin official)

```bash
# Cài cho cả team (ghi vào settings commit git)
/plugin install commit-commands
/plugin install pr-review-toolkit

# File .claude/settings.json:
```

```json
{
  "plugins": ["commit-commands@1.2.0", "pr-review-toolkit@1.4.0"]
}
```

```bash
# Thành viên mới clone về → mở Claude → tự có:
/commit-smart    # commit đúng convention team
/pr-review-toolkit:review   # review 5 pha chuẩn team
```

> Kết quả: team 5 người cùng 1 chuẩn commit/review, không cần doc dài.

### Kịch bản 2: Discover gợi ý đúng lúc (không cần biết tên plugin)

```bash
# Bạn đang vật lộn với PDF trong repo:
/plugin discover
# → gợi ý: "pdf-tools (đọc/trích PDF, 12k downloads) — cài không? [Yes/No]"

# Cài xong:
/plugin list
# → pdf-tools@2.0.1 (enabled)
# Gõ / thấy thêm /pdf-tools:extract, /pdf-tools:summarize
```

### Kịch bản 3: Xung đột 2 plugin cùng lệnh `review` (namespacing cứu)

Triệu chứng: cài `pr-review-toolkit` + `quick-review`, gõ `/review` thấy picker lạ.

```bash
# Không lỗi — là namespacing hỏi bạn chọn:
/review
# → (?) 1. pr-review-toolkit:review (5 pha, kỹ)
# →     2. quick-review:review (1 pha, nhanh)

# Gọi rõ để khỏi hỏi lần sau:
/pr-review-toolkit:review
/quick-review:review
```

### Kịch bản 4: Plugin lạ xin quyền rộng — cài nhưng khóa hooks

```bash
# Plugin community "super-helper" xin: chạy shell + gọi mạng
/plugin install super-helper

# Khóa hooks của nó (giữ skill/commands, tắt code tự chạy):
# Mở /hooks → tìm hooks của super-helper → Disable

# Hoặc disable cả plugin khi không dùng:
/plugin
# → tab Manage → super-helper → Disable (giữ file, không nạp session sau)
```

> Kết quả: dùng được skill hay của nó mà không cho code lạ chạy nền.

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (plugin hooks chạy code trên máy)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Plugin community độc hại | Hooks/MCP đọc `~/.ssh`, `.env` gửi ra ngoài | Chỉ cài official hoặc repo nhiều star + đọc code `hooks/` trước; deny file nhạy cảm |
| Plugin pin `latest` trong team settings | Sáng còn chạy, chiều plugin update vỡ workflow | Pin version (`@1.2.0`) cho team; 1 người test bản mới trước |
| 10 plugin cùng bật | Context phình (mỗi plugin +500-1000 token), chậm + đắt | Chỉ enable cái đang dùng; `/plugin` Manage tắt bớt |
| Plugin đăng ký MCP server lạ | Dữ liệu repo đi ra server ngoài không biết | Xem manifest: plugin kèm MCP nào; firewall/block domain lạ |
| Gỡ plugin nhưng hooks còn sót | Code cũ vẫn chạy nền | Sau remove, mở `/hooks` kiểm tra còn entry của nó không |

### Tốn token?

- Mỗi plugin enabled ≈ 300-1000 token/session (mô tả commands + skills + agents). 5 plugin ≈ 2-5k — bằng 1 CLAUDE.md vừa.
- Plugin nhiều skill (10+) thì tốn hơn. Disable plugin theo mùa vụ.

### Version / provider

- `/plugin` manager + marketplace: bản v2.1+. Bản cũ cài tay bằng git clone vào `~/.claude/plugins/`.
- Namespacing `plugin:tên-lệnh`: v2.x. Bản cũ lệnh đè nhau thật.
- Bedrock/Vertex: plugin skill/agent chạy bình thường; MCP kèm theo chịu policy mạng cloud.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/plugin` + `/hooks` | Khóa hooks plugin lạ | Cài xong vào `/hooks` disable phần nguy hiểm |
| `/plugin` + `/permissions` | Phanh tools plugin mang theo | Allow skill, ask MCP ghi của plugin |
| `/plugin` + `/mcp` | Xem server plugin đã đăng ký | `/mcp` list thấy server của plugin |
| `/plugin` + `/agents` | Dùng agent chuyên của plugin | Gọi `plugin:agent-chuyên` |
| `/plugin` + `/doctor` | Doctor audit plugin thừa | Plugin nào 3 tháng không dùng → remove |

Workflow chuẩn "onboard team với plugin":

```bash
# 1. Lead chọn + pin version
/plugin install pr-review-toolkit@1.4.0

# 2. Ghi vào settings commit git (file .claude/settings.json)

# 3. Thêm permissions baseline cho tools của plugin

# 4. Member mới: clone → mở Claude → auto-install → /plugin list xác nhận
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Gõ lệnh plugin báo not found | Plugin disabled hoặc session cũ chưa nạp | `/plugin` Manage kiểm tra enabled; `/clear` nạp lại |
| `/review` hiện picker mỗi lần | 2 plugin cùng tên lệnh | Gọi đầy đủ `pluginA:review`; hoặc gỡ 1 plugin |
| Install báo marketplace not found | Sai tên marketplace hoặc mạng chặn | Kiểm tra `marketplaces:` trong settings; thử `gh:owner/repo` trực tiếp |
| Plugin update xong vỡ workflow | Bản mới đổi behavior/đổi tên lệnh | Pin version cũ trong settings; báo issue cho tác giả plugin |
| Cài plugin mà MCP kèm theo không chạy | Thiếu env/token plugin cần | Đọc README plugin xem cần env gì; export rồi `/mcp reconnect` |
| Gỡ rồi mà lệnh vẫn hiện | Session chưa reload | `/clear` hoặc restart session |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../hooks/README.md](../../knowledge-system/hooks/README.md) — hooks plugin đăng ký, cách khóa
  - [../mcp/README.md](../../knowledge-system/mcp/README.md) — MCP server kèm trong plugin
  - [../agents/README.md](../../knowledge-system/agents/README.md) — agent chuyên của plugin
  - [../permissions/README.md](../../model-mode/permissions/README.md) — phanh cho tools plugin
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — audit plugin thừa/thiếu
  - [../verify/README.md](../../code-repo/verify/README.md) — verify sau khi dùng skill plugin
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md) — plugin có đọc CLAUDE.md không (có)
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — skill lẻ vs skill trong plugin
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md) — agent plugin trong team
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md) — bài gốc về hooks
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md) — MCP lẻ vs MCP trong plugin
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md) — bài gốc: chợ plugin, tự đăng plugin

> Mẹo 1 dòng: _official trước community sau, pin version cho team, và đọc quyền plugin xin như đọc quyền app điện thoại._
