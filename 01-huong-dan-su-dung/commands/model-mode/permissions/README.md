# /permissions — Quản lý quyền tools: ai được đọc/ghi/chạy gì, hỏi khi nào

> Loại Built-in (alias /allowed-tools) · Nhóm Model & Mode · Nguy hiểm Có nếu cấu hình ẩu (allow-all / bypass trên máy thật = mất phanh; deny sai = kẹt việc)

`/permissions` (alias `/allowed-tools`) là trung tâm phân quyền: quy định tool nào được chạy thẳng (allow), tool nào phải hỏi (ask), tool nào cấm hẳn (deny). Mọi mode Shift+Tab (default/acceptEdits/plan/auto/bypass) thực chất chỉ là preset đè lên bảng này. Hiểu bảng này là hiểu phanh của Claude Code.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/permissions` | _(không có)_ | Mở UI quản lý allow/ask/deny tương tác |
| `/allowed-tools` | _(alias)_ | Hoàn toàn tương đương `/permissions` |
| `Shift+Tab` | xoay mode | Đổi preset: `default` → `acceptEdits` → `plan` → `auto` → `bypassPermissions` |
| `settings.json` | file project | Quyền chung cho team (commit git) |
| `settings.local.json` | file máy cá nhân | Quyền riêng bạn (không commit, đè lên trên) |
| Managed policy | IT cài | Quyền cứng admin, bạn không sửa được |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở UI phân quyền
/permissions
```

```bash
# Dạng 2: alias tương đương
/allowed-tools
```

```bash
# Dạng 3: xoay mode nhanh không cần UI
# Nhấn Shift+Tab tới "acceptEdits"
```

```bash
# Dạng 4: xem file quyền project (copy-paste)
# Đọc file .claude/settings.json trong repo:
```

```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(npm test:*)", "Bash(git status:*)"],
    "ask": ["Edit", "Write", "Bash(rm:*)", "Bash(git push:*)"],
    "deny": ["Bash(rm -rf:*)", "Bash(sudo:*)", "Read(.env)"]
  }
}
```

```bash
# Dạng 5: file cá nhân đè lên (không commit)
# ~/.claude/settings.json hoặc .claude/settings.local.json:
```

```json
{
  "permissions": {
    "allow": ["Bash(npm run dev:*)"],
    "deny": ["Read(~/.ssh/id_rsa)"]
  }
}
```

```bash
# Dạng 6: kiểm tra mode hiện tại (nhìn status bar)
# status bar hiển thị: default | acceptEdits | plan | auto | bypassPermissions
```

---

## Cách nó hoạt động

### Cơ chế sâu: permissions scopes/merge ra sao?

1. **3 lớp scopes xếp chồng (thứ tự ưu tiên):**
   - Lớp 1 — `Managed policy` (IT/admin): cao nhất. Ghi `deny` ở đây thì bạn `allow` ở đâu cũng vô ích.
   - Lớp 2 — `Project settings` (`.claude/settings.json`, commit git): luật chung team. VD team JS allow `npm test`, deny `rm -rf`.
   - Lớp 3 — `Local/User settings` (`settings.local.json`, `~/.claude/settings.json`): riêng bạn, đè lên lớp 2.
   - Trong cùng 1 file: `deny` > `ask` > `allow`. Một tool vừa allow vừa deny → deny thắng.
2. **Merge rule cụ thể:**
   - `allow` cộng dồn qua các lớp (union): lớp nào allow là được, trừ khi lớp cao hơn deny.
   - `deny` ở lớp nào cũng lan xuống: managed deny `sudo` → mọi session đều cấm sudo.
   - Ví dụ: project allow `Bash(npm:*)`, bạn local deny `Bash(npm publish:*)` → được test nhưng cấm publish. Đây là pattern chuẩn "mở rộng nhưng chừa đường nguy hiểm".
3. **Pattern matching:**
   - `"Bash(npm test:*)"` = cho mọi lệnh bắt đầu `npm test`. `"Read(.env)"` = cấm đọc file `.env` chính xác.
   - `"Bash(rm -rf:*)"` chặn prefix nguy hiểm. Viết càng cụ thể càng an toàn; `allow: ["Bash(*)"]` = mở toang (đừng).
4. **5 modes là preset đè tạm (session-only):**
   - `default`: hỏi khi nhạy cảm (theo bảng).
   - `acceptEdits`: auto-allow Edit/Write file thường, vẫn hỏi khi xóa/chạy nguy hiểm.
   - `plan`: ép deny toàn bộ ghi (đè cứng, xem bài plan).
   - `auto`: ít hỏi hơn default (tự allow nhiều Bash đọc).
   - `bypassPermissions`: bỏ qua mọi `ask` (coi như allow-all, trừ managed deny cứng).
   - Đổi mode không sửa file settings — hết session là về mặc định file.
5. **Mỗi lần tool-call đi qua gate:**
   - Model xin gọi `Edit src/a.ts` → gate tra bảng (mode + 3 lớp) → allow: chạy; ask: hiện picker Yes/No; deny: báo lỗi, model phải tìm đường khác.
6. **Audit:**
   - Mọi allow/deny đều log vào transcript (`.jsonl`) để post-mortem khi sự cố.

### Sơ đồ merge

```text
Managed (IT):     deny [sudo, Read(~/.ssh/*)]
                        ↓ (thắng mọi lớp dưới)
Project (.claude/): allow [Read, Edit, Bash(npm test:*)] / ask [Bash(git push:*)]
                        ↓
Local (bạn):      allow [Bash(npm run dev:*)] / deny [Bash(npm publish:*)]
                        ↓
Session mode:     acceptEdits (auto file thường)
                        ↓
Kết quả: được test, được sửa file, hỏi khi push, cấm publish + sudo + đọc ssh key
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Phạm vi | Mất khi restart? | Dùng khi nào? |
|---|---|---|---|
| `/permissions` UI | Đổi bảng nền (ghi file) | Không (persistent) | Cài luật lâu dài |
| Shift+Tab mode | Preset đè tạm session | Có | Đổi nhanh theo task |
| `/plan` | Ép deny-ghi tạm | Có (thoát là hết) | Task lớn cần phanh cứng |
| Managed policy | Luật IT cứng | Không (bạn không sửa được) | Công ty khóa đường nguy hiểm |

> Quy tắc ngón tay cái:
>
> - **Luật lâu dài → sửa file settings. Đổi nhanh theo task → Shift+Tab. Task lớn → `/plan`.**

---

## Ví dụ thực tế

### Kịch bản 1: Setup chuẩn cho dự án Node.js (team 5 người)

File `.claude/settings.json` commit git để cả team cùng luật:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(npm test:*)",
      "Bash(npm run lint:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)"
    ],
    "ask": ["Edit", "Write", "Bash(git commit:*)", "Bash(git push:*)", "Bash(npm install:*)"],
    "deny": ["Bash(rm -rf:*)", "Bash(sudo:*)", "Read(.env)", "Read(.env.*)"]
  }
}
```

> Kết quả: thành viên mới clone về là có phanh chuẩn. Không ai vô tình `rm -rf` hay đọc `.env` chứa secret.

### Kịch bản 2: Cá nhân mở thêm cho workflow riêng (không ảnh hưởng team)

Bạn hay chạy dev server, không muốn bị hỏi mỗi lần:

```json
// File: .claude/settings.local.json (gitignore, không commit)
{
  "permissions": {
    "allow": ["Bash(npm run dev:*)", "Bash(docker compose up:*)"],
    "deny": ["Bash(npm publish:*)", "Bash(git push origin main:*)"]
  }
}
```

> Kết quả: bạn chạy dev mượt, nhưng publish/push main vẫn bị cấm — tự phanh mình khỏi lỗi tay lúc mệt.

### Kịch bản 3: Kẹt vì deny sai — gỡ trong 1 phút

Triệu chứng: model báo `permission denied` khi chạy `pytest` dù task cần test.

```bash
# Bước 1: mở UI
/permissions

# Bước 2: thêm Bash(python:*)/Bash(pytest:*) vào allow
# Hoặc sửa file trực tiếp:

# .claude/settings.local.json — thêm:
```

```json
{
  "permissions": {
    "allow": ["Bash(pytest:*)", "Bash(python -m pytest:*)", "Bash(python bench.py:*)"]
  }
}
```

### Kịch bản 4: Công ty khóa cứng (managed) — hiểu để không cố vượt

```bash
# IT đặt managed policy:
# deny: [Bash(sudo:*), Bash(curl:*|sh), Read(~/.aws/*)]
# Bạn gõ /permissions thấy ổ khóa 🔒 ở 3 dòng đó.

# Đừng cố allow lại ở local — vô ích (managed thắng).
# Cần thật thì ticket cho IT, hoặc làm đường vòng an toàn:
Bash(sudo docker ps)  # bị chặn
docker ps              # nếu docker socket đã phân quyền user thì không cần sudo
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (bypass/auto)

| Mode | Rủi ro | Khi nào được dùng |
|---|---|---|
| `bypassPermissions` tay trên máy thật | CỰC NGUY HIỂM: `rm -rf`, force-push, gửi secret — không hỏi | KHÔNG BAO GIỜ tay. Chỉ CI/sandbox vứt được |
| `auto` cho task lạ | Nguy hiểm vừa: ít hỏi, có thể chạy script lạ | Chỉ task bạn hiểu rõ |
| `allow: ["Bash(*)"]` trong settings | Mở toang: mọi lệnh shell đều chạy | KHÔNG BAO GIỜ. Liệt kê cụ thể từng prefix |
| `Read(.env)` không deny | Secret lọt vào context → có thể bị log/leak | Luôn deny `.env`, `*.pem`, `id_rsa` |
| Managed bị tắt (máy cá nhân) | Không có phanh cứng IT | Tự deny tay các đường nguy hiểm |

### Tốn token?

- Permissions tự thân tốn 0 token. Nhưng `ask` nhiều quá → bạn mỏi tay bấm Yes → có xu hướng bật bypass cho rảnh → tốn tiền + rủi ro. Cân bằng: allow việc lặp (test, lint), ask việc nguy hiểm (push, publish, rm).

### Version / provider

- `/permissions` + `/allowed-tools`: mọi bản v2.1.x.
- Managed policy: chỉ bản Team/Enterprise qua admin console. Cá nhân không thấy mục này là bình thường.
- Bedrock/Vertex: danh sách Bash cho phép có thể bị rút gọn sẵn từ phía cloud.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/permissions` + Shift+Tab | Luật nền + preset tạm | Cài settings chuẩn, xoay mode theo task |
| `/permissions` + `/plan` | Khóa ghi cho task lớn | Settings mở, nhưng `/plan` đè deny-ghi |
| `/permissions` + `/verify` | Cho chạy test/build khi verify | Allow `npm test`, `docker`, `pytest` |
| `/permissions` + `/batch` | Subagent kế thừa bảng | Kiểm tra bảng trước khi batch 30 đứa |
| `/permissions` + `/goal` | Evaluator cần đọc test output | Allow Bash test để evaluator có dữ liệu chấm |

Workflow chuẩn "setup repo mới":

```bash
# 1. Sinh CLAUDE.md
/init

# 2. Mở permissions, cài bảng chuẩn team
/permissions
# → allow đọc + test, ask ghi/push, deny rm/sudo/.env

# 3. Commit luật chung
# git add .claude/settings.json && git commit -m "chore: claude permissions baseline"

# 4. Mỗi người tự mở rộng local
# .claude/settings.local.json (gitignored)
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Model báo `permission denied` khi chạy test | Thiếu allow `Bash(pytest/npm test:*)` | Thêm vào `settings.local.json` allow |
| Thêm allow ở local mà vẫn bị chặn | Managed policy deny ở trên (ổ khóa 🔒) | Không vượt được — ticket IT hoặc đi đường vòng an toàn |
| Bị hỏi Yes/No liên tục, mỏi tay | Bảng ask quá rộng / đang ở default với task lặp | Shift+Tab sang `acceptEdits`, hoặc allow các lệnh lặp |
| `/allowed-tools` báo unknown | Bản rất cũ | Update CLI; dùng `/permissions` |
| Vô tình allow `Bash(*)` rồi model chạy `rm -rf` | Mở toang shell | Sửa ngay thành prefix cụ thể; dùng git + checkpoint để cứu; từ nay deny `rm -rf` |
| Secret lọt vào chat dù đã deny `.env` | Model đọc từ file khác import secret, hoặc bạn paste tay | Deny rộng hơn (`*.pem`, `credentials.json`); rotate key đã lộ; không paste secret vào chat |
| `settings.json` sửa không có tác dụng | Sửa nhầm file / JSON lỗi cú pháp / session cũ chưa reload | Kiểm tra đúng `.claude/settings.json` (project) vs `~/.claude/` (user); validate JSON; restart session hoặc `/clear` |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../plan/README.md](../../model-mode/plan/README.md) — plan mode là deny-ghi cứng tạm thời
  - [../model/README.md](../../model-mode/model/README.md) — đổi model không đổi quyền
  - [../effort/README.md](../../model-mode/effort/README.md) — effort cao + bypass = combo cấm
  - [../init/README.md](../../code-repo/init/README.md) — sinh CLAUDE.md + settings baseline cùng lúc
  - [../verify/README.md](../../code-repo/verify/README.md) — cần allow test/build để verify
  - [../batch/README.md](../../code-repo/batch/README.md) — kiểm tra bảng trước khi batch
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md` — đọc kỹ bài này, là bài gốc của permissions/modes
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _allow việc lặp, ask việc nguy hiểm, deny đường chết — và không bao giờ bypass tay trên máy thật._
