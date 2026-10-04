# /memory — Quản lý bộ nhớ dài hạn: xem/sửa/xoá những gì Claude nhớ giữa các session

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (nhưng Có nếu lưu secret/API key vào memory — sẽ bị nạp lại mọi session sau)

`/memory` mở trình quản lý bộ nhớ dài hạn (long-term memory): những sự thật, sở thích, quy ước dự án mà Claude tự ghi nhớ hoặc bạn dạy thủ công, để session sau tự động nạp lại mà không cần nhắc lại. Hiểu `/memory` là hiểu "não dài hạn" của Claude Code — khác với CLAUDE.md (file tĩnh trong repo) và khác context ngắn hạn (mất khi `/clear`).

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/memory` | _(không có)_ | Mở UI quản lý memory tương tác (xem/sửa/xoá từng mục) |
| `/memory show` | — | Liệt kê toàn bộ mục memory hiện có |
| `/memory add <nội dung>` | text tự do | Thêm 1 mục memory thủ công |
| `/memory delete <id>` | id mục | Xoá 1 mục memory |
| `/memory clear` | — | Xoá toàn bộ memory (hỏi xác nhận) |
| `#` (khi chat) | `# nhớ rằng...` | Gợi ý model ghi nhớ (auto-memory đề xuất, bạn duyệt) |
| `CLAUDE.md` | file repo | Bộ nhớ tĩnh theo repo (commit git, xem bài 03) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở UI quản lý
/memory
```

```bash
# Dạng 2: xem nhanh toàn bộ
/memory show
```

```bash
# Dạng 3: thêm thủ công (copy-paste)
/memory add Dự án dùng pnpm, không dùng npm. Test bằng vitest, không dùng jest.
```

```bash
# Dạng 4: thêm quy ước cá nhân
/memory add Tôi thích giải thích ngắn gọn, code trước chữ sau. Trả lời bằng tiếng Việt.
```

```bash
# Dạng 5: xoá 1 mục (lấy id từ /memory show)
/memory delete 3
```

```bash
# Dạng 6: gợi ý trong lúc chat (model đề xuất lưu, bạn duyệt)
# Tôi luôn dùng uv để chạy Python, nhớ giúp tôi nhé
```

---

## Cách nó hoạt động

### Cơ chế sâu: memory / auto-memory / CLAUDE.md merge ra sao?

1. **3 tầng tri thức xếp chồng (thứ tự nạp khi khởi động session):**
   - Tầng 1 — `System / Managed`: chính sách hệ thống, enterprise policy (bạn không sửa).
   - Tầng 2 — `CLAUDE.md + rules/` (tĩnh, theo repo): file `CLAUDE.md` ở root, `./.claude/CLAUDE.md`, `~/.claude/CLAUDE.md` merge lại. Nội dung này đi vào system prompt mỗi session, tốn token mỗi lần (xem bài 03).
   - Tầng 3 — `Memory` (động, theo user + project): các mục bạn dạy hoặc model tự đề xuất. Nạp sau CLAUDE.md, cũng vào system prompt nhưng có thể bật/tắt từng mục.
   - Tầng 4 — `Context ngắn hạn`: lịch sử chat session hiện tại. Mất khi `/clear`, `/compact`.
   - Thứ tự ưu tiên khi mâu thuẫn: memory mới > memory cũ; memory user > suy đoán model; nhưng CLAUDE.md trong repo thường được coi là "luật cứng dự án" và thắng memory cá nhân nếu xung đột trực tiếp.
2. **Auto-memory hoạt động thế nào?**
   - Khi bạn nói "nhớ rằng...", "từ nay luôn...", "tôi thích..." — model nhận diện đây là preference bền vững, không phải yêu cầu 1 lần.
   - Model hiện đề xuất: "Tôi có nên lưu điều này vào memory không? [Yes/No]". Bạn duyệt thì mới lưu — không tự lưu lén.
   - Ví dụ trigger: "đừng bao giờ dùng emoji trong commit", "repo này dùng ruff format dòng 100", "tôi bị dị ứng với callback hell, luôn dùng async/await".
   - Ví dụ KHÔNG trigger: "sửa file này giúp tôi" (task 1 lần), "hôm nay deploy lúc 3h" (sự kiện nhất thời).
3. **Lưu ở đâu? Scope user vs project:**
   - `User memory` (`~/.claude/memory/` hoặc DB local): theo bạn qua mọi repo. Hợp cho sở thích cá nhân (ngôn ngữ trả lời, style code).
   - `Project memory` (`.claude/memory/` trong repo, có thể gitignore hoặc commit tùy team): theo repo. Hợp cho quy ước dự án (lệnh test, cấu trúc thư mục).
   - Mở `/memory` bạn sẽ thấy tag `user` / `project` ở mỗi mục.
4. **Merge vào prompt ra sao?**
   - Mỗi session start (và sau `/clear`), Claude Code đọc toàn bộ memory còn active, nối thành 1 block `<memory>...</memory>` trong system prompt.
   - Mỗi mục ~1-3 dòng → 20 mục ≈ 300-600 token mỗi session. Ít hơn CLAUDE.md phình to nhiều.
   - Mục bị tắt (disabled) trong UI thì không nạp — nhưng vẫn lưu, bật lại được.
5. **Vòng đời 1 mục memory:**
   - `đề xuất` → `bạn duyệt` → `active` → (dùng mỗi session) → `cũ/lỗi thời` → `edit` hoặc `delete`.
   - Model không tự sửa memory cũ khi phát hiện mâu thuẫn — nó hỏi bạn. VD bạn đổi từ npm sang pnpm, model hỏi "Có cập nhật memory cũ không?".
6. **Khác gì CLAUDE.md và rules?**
   - `CLAUDE.md`: tĩnh, commit git, team cùng đọc. Sửa bằng Edit file.
   - `memory`: động, cá nhân hoá, sửa bằng `/memory` UI. Không cần commit.
   - `rules/` (xem bài `/rules`): file modular lazy-load theo đường dẫn — chỉ nạp khi chạm file khớp pattern. Memory thì nạp hết mỗi session.
7. **Audit:**
   - Mọi lần ghi/xoá memory đều log vào transcript `.jsonl` của session. Muốn xem ai dạy gì, grep transcript.

### Sơ đồ nạp tri thức khi mở session

```text
Session start
  ↓
[1] System prompt cứng
  ↓
[2] CLAUDE.md merge (root → .claude/ → ~/.claude/)
  ↓  (tĩnh, tốn token cố định)
[3] Memory active (user + project)
  ↓  (động, bật/tắt từng mục)
[4] Rules lazy-load (chỉ khi mở file khớp paths)
  ↓
[5] Lịch sử chat (trống nếu session mới)
  ↓
Model sẵn sàng (đã "nhớ" sở thích + quy ước của bạn)
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Phạm vi | Mất khi restart? | Dùng khi nào? |
|---|---|---|---|
| `/memory` | User/project dài hạn | Không | Sở thích, quy ước bền vững |
| `CLAUDE.md` | Repo tĩnh (commit) | Không | Luật team, kiến trúc, lệnh chuẩn |
| `/rules` | File modular lazy-load | Không | Quy ước theo thư mục/file |
| `/clear` | Xoá chat ngắn hạn | (nó là lệnh xoá) | Reset context, giữ memory |
| `/compact` | Tóm tắt chat dài | Không (giữ ý chính) | Context đầy, muốn gọn |

> Quy tắc ngón tay cái:
>
> - **Cả team cần biết → CLAUDE.md. Chỉ bạn cần nhớ → `/memory`. Quy ước theo thư mục → `/rules`.**

---

## Ví dụ thực tế

### Kịch bản 1: Dạy 1 lần, khỏi nhắc 100 lần (style cá nhân)

Bạn mệt vì mỗi session phải nhắc "đừng dùng emoji, trả lời tiếng Việt":

```bash
/memory add Trả lời bằng tiếng Việt. Code trước, giải thích sau, ngắn gọn. Commit message kiểu conventional commits, không emoji.
/memory add Tôi dùng macOS + zsh. Khi gợi ý lệnh shell, dùng cú pháp macOS.
```

> Kết quả: từ session sau, Claude tự trả lời tiếng Việt, commit không emoji — không cần nhắc lại.

### Kịch bản 2: Quy ước dự án Python (project memory)

```bash
/memory add Repo tutorial-claude-code: chạy Python bằng uv (uv run ...), không dùng pip trực tiếp. Format bằng ruff, dòng tối đa 100 ký tự.
/memory add Khi viết README tiếng Việt, mỗi lệnh có đủ 8 mục, code copy-paste được.
```

> Kết quả: mọi session mở trong repo này đều tự dùng `uv run`, gợi ý đúng format README.

### Kịch bản 3: Sửa memory lỗi thời (đổi stack)

Triệu chứng: Claude cứ gợi ý `npm` dù team đã chuyển sang `pnpm` 2 tháng trước.

```bash
# Bước 1: xem
/memory show
# → thấy mục [2] "Dự án dùng npm để quản lý package" (cũ)

# Bước 2: mở UI sửa
/memory
# → sửa mục [2] thành "Dự án dùng pnpm, không dùng npm"

# Hoặc xoá rồi thêm mới:
/memory delete 2
/memory add Dự án dùng pnpm. Cấm dùng npm để tránh lệch lockfile.
```

### Kịch bản 4: Dọn memory phình to (20+ mục, tốn token)

```bash
# Mở UI
/memory

# Tắt (disable) các mục theo mùa vụ, không xoá hẳn:
# [ ] "Đang làm tính năng Tết 2025" → tắt, hết mùa bật lại hoặc xoá
# [x] "Dùng pnpm" → giữ
# [x] "Trả lời tiếng Việt" → giữ

# Xoá hẳn nếu đã qua 6 tháng không dùng:
/memory clear
# (rồi thêm lại 3-5 mục cốt lõi — ít mà chất hơn nhiều mà rác)
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào?

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Lưu secret vào memory (`API key là sk-...`) | CỰC NGUY HIỂM: key bị nạp vào mọi session, có thể lọt vào log/transcript, sync | KHÔNG BAO GIỜ lưu secret. Key để trong `.env` + deny trong permissions |
| Memory mâu thuẫn (vừa "dùng npm" vừa "dùng pnpm") | Model bối rối, làm lúc này lúc kia | Dọn định kỳ: `/memory show` mỗi tháng, xoá mục cũ |
| Memory quá nhiều (50+ mục) | Tốn 1-2k token mỗi session, chậm + đắt | Giữ ≤15 mục. Cái gì theo thư mục thì chuyển sang `/rules` |
| Dạy nhầm (lúc đùa bảo "luôn dùng Comic Sans") | Mọi code sau đều bị ám | Mở `/memory` xoá ngay; kiểm tra sau mỗi lần dạy đùa |
| Project memory commit git có thông tin nhạy cảm | Lộ nội bộ (tên khách hàng, đường dẫn nội bộ) | `.gitignore` project memory nếu chứa info nhạy cảm; chỉ commit quy ước chung |

### Tốn token?

- Mỗi mục ~20-50 token. 10 mục ≈ 300-500 token/session — rẻ hơn CLAUDE.md dài 5k token nhiều.
- Nhưng memory rác (30+ mục cũ) ≈ 1.5k token chết mỗi session × 100 session = 150k token vứt đi. Dọn là tiết kiệm thật.

### Version / provider

- `/memory`: mọi bản v2.x trên Terminal/IDE.
- Auto-memory đề xuất (Yes/No): từ bản ~v1.0.100+, mặc định bật. Tắt được trong settings (`memoryAutoSave: false`) nếu không muốn bị hỏi.
- Bedrock/Vertex: memory lưu local, không gửi lên cloud vendor ngoài prompt như thường.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/memory` + `CLAUDE.md` | Tĩnh + động bổ sung nhau | CLAUDE.md giữ kiến trúc; memory giữ sở thích |
| `/memory` + `/rules` | Chung + riêng theo thư mục | Memory giữ "dùng pnpm"; rules giữ "riêng `api/` dùng FastAPI" |
| `/memory` + `/init` | Sinh CLAUDE.md rồi rút gọn bằng memory | `/init` xong, chuyển sở thích cá nhân từ CLAUDE.md sang memory cho gọn |
| `/memory` + `/doctor` | Doctor phát hiện CLAUDE.md phình → chuyển bớt sang memory/rules | Chạy `/doctor`, trim theo gợi ý |
| `/memory` + `/compact` | Compact giữ ý chính chat vào memory nếu bền vững | Sau compact, model hỏi "có lưu gì vào memory không?" |

Workflow chuẩn "onboard máy mới":

```bash
# 1. Xem memory máy cũ (nếu sync hoặc copy ~/.claude/)
/memory show

# 2. Thêm 3-5 mục cốt lõi cho máy mới
/memory add Trả lời tiếng Việt, ngắn gọn.
# 3. Mở repo, để CLAUDE.md lo phần dự án (không nhồi vào memory)
# 4. Làm việc 1 tuần, duyệt các đề xuất auto-memory khi model hỏi
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Dạy rồi mà session sau model quên | Lưu vào project memory repo A, đang mở repo B | Kiểm tra scope: chuyển mục đó sang user memory để theo mọi repo |
| Model cứ hỏi "có lưu không?" gây phiền | Auto-memory nhạy quá | Tắt đề xuất trong settings, chỉ thêm tay bằng `/memory add` |
| `/memory` báo empty dù đã dạy | Dạy trong session chưa duyệt Yes, hoặc nhầm profile `~/.claude` | Mở lại `/memory`, kiểm tra; đảm bảo đã bấm Yes khi model hỏi |
| Hai mục mâu thuẫn nhau | Đổi stack nhưng quên xoá mục cũ | `/memory show` → xoá/sửa mục cũ |
| Memory chứa secret cũ | Đã lỡ lưu key | Xoá ngay (`/memory delete`), rotate key đó, kiểm tra transcript `.jsonl` có chứa key không |
| Muốn share memory cho team | User memory không theo git | Chuyển nội dung chung sang `CLAUDE.md` hoặc project memory commit git; giữ sở thích ở user memory |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../rules/README.md](../../knowledge-system/rules/README.md) — quy ước modular lazy-load theo paths
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — audit CLAUDE.md phình, gợi ý chuyển sang memory/rules
  - [../agents/README.md](../../knowledge-system/agents/README.md) — subagent có thấy memory không?
  - [../compact/README.md](../../session-context/compact/README.md) — tóm tắt context, giữ memory dài hạn
  - [../clear/README.md](../../session-context/clear/README.md) — xoá chat ngắn hạn, không xoá memory
  - [../init/README.md](../../code-repo/init/README.md) — sinh CLAUDE.md, phân biệt với memory
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md) — bài gốc: CLAUDE.md + memory + rules merge ra sao
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — skill có đọc memory không
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md) — memory trong multi-agent
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md) — hook có thể đọc memory không
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md) — MCP vs memory
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md) — plugin mang memory riêng không

> Mẹo 1 dòng: _team cần biết thì ghi CLAUDE.md, chỉ bạn cần nhớ thì dạy `/memory`, và đừng bao giờ dạy secret._
