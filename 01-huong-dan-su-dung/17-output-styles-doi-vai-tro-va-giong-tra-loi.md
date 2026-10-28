# 17 — Output styles: đổi vai trò và giọng trả lời của Claude Code

> **Bài này cho ai:** bạn đã dùng Claude Code thành thạo cơ bản và muốn đổi cách Claude trả lời — ngắn gọn hơn, giải thích nhiều hơn, hoặc biến thành trợ lý viết / phân tích dữ liệu thay vì chỉ dev.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](./01-cai-dat-va-xac-thuc.md)); nên đọc [bài 03 — CLAUDE.md, memory & rules](./03-claude-md-memory-rules.md) và [bài 05 — Skills](./05-skills-custom-commands.md) trước vì mục 5 so sánh output style với các cơ chế đó.
> **Đọc xong bạn làm được:**
> - Đổi output style bằng `/output-style`, `/config` hoặc settings file, và biết style nào hợp việc gì.
> - Viết 1 custom output style với frontmatter đúng (`name`, `description`, `keep-coding-instructions`).
> - Chọn đúng giữa output style / CLAUDE.md / skill / hook — không nhét sai chỗ.
> - Phân biệt memory tool (Messages API / SDK) với lệnh `/memory` của Claude Code.
> **Thời gian:** ~30 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Output style | Bộ chỉ dẫn áp cho **mọi câu trả lời** trong session: vai trò, giọng, format | `/output-style concise` → trả lời đi thẳng kết quả |
| System prompt | Chỉ dẫn nền Claude Code gửi kèm mỗi request | style custom thay phần chỉ dẫn "software engineering" của system prompt |
| `keep-coding-instructions` | Field frontmatter giữ lại chỉ dẫn code mặc định của Claude Code | style "Diagrams first" vẫn code bình thường, chỉ thêm sơ đồ |
| Insight block | Khối `★ Insight` giải thích lý do chọn cách làm (style Explanatory/Learning) | hiện trong hội thoại, không ghi vào file |
| Auto memory | Ghi chú Claude tự viết ra `~/.claude/projects/<project>/memory/` giữa các session | thấy "Saved 2 memories" trong giao diện |
| Memory tool | Tool kiểu `memory_20250818` của Messages API — bạn tự viết handler lưu/đọc `/memories` | dùng khi build agent bằng API/SDK, không phải CLI Claude Code |
| Hook | Script Claude Code tự chạy tại sự kiện lifecycle, không qua model | PostToolUse chạy eslint sau mỗi lần sửa file |

## Mục lục

1. [Output style là gì và thay đổi gì](#1-output-style-là-gì-và-thay-đổi-gì)
2. [4 style built-in: chọn cái nào khi nào](#2-4-style-built-in-chọn-cái-nào-khi-nào)
3. [Đổi style: 4 cách](#3-đổi-style-4-cách)
4. [Tự viết custom output style](#4-tự-viết-custom-output-style)
5. [Output style vs CLAUDE.md vs skill vs hook vs subagent](#5-output-style-vs-claude-md-vs-skill-vs-hook-vs-subagent)
6. [Lưu ý: memory tool (API/SDK) khác `/memory` của Claude Code](#6-lưu-ý-memory-tool-apisdk-khác-memory-của-claude-code)
7. [Khi nào KHÔNG dùng output style](#7-khi-nào-không-dùng-output-style)
8. [Hiểu nhầm thường gặp](#8-hiểu-nhầm-thường-gặp)
9. [Bài tập thực hành](#9-bài-tập-thực-hành)
10. [Link chéo](#10-link-chéo)

---

## 1. Output style là gì và thay đổi gì

Mục này trả lời câu: output style thực chất sửa cái gì bên trong Claude Code, và khác gì "nói trong prompt mỗi lần".

Output style là **bộ chỉ dẫn gửi kèm mọi request trong session** — style thay đổi cách Claude Code soạn instructions cho model: vai trò, giọng văn, format trả lời. Khác với việc bạn gõ "trả lời ngắn thôi" ở đầu session: style áp cho toàn session (kể cả câu trả lời sau `/compact`), không bị quên, và đổi bằng 1 lệnh.

Cơ chế (theo docs chính thức, tra 28/10/2026):

- Claude Code gửi chỉ dẫn của style đang bật kèm **mọi request**.
- Với **full system prompt**: style custom mặc định **bỏ phần chỉ dẫn software engineering** của Claude Code (cách scoped changes, viết comment, verify...) — trừ khi đặt `keep-coding-instructions: true`.
- Style áp cho hội thoại chính và **fork** (subagent hưởng nguyên context); **subagent thường chạy system prompt riêng** nên style không đổi cách subagent trả lời.
- Tốn token: chỉ dẫn style cộng vào input tokens (prompt caching giảm sau request đầu); style Explanatory/Learning chủ đích trả lời dài hơn → output tokens tăng, Concise thì ngược lại.

**Output style là chỉ dẫn, không phải luật.** Không gì đảm bảo "chưa bao giờ vi phạm" — cần đảm bảo tuyệt đối thì dùng hook (xem mục 5).

---

## 2. 4 style built-in: chọn cái nào khi nào

Mục này trả lời câu: ngoài Default, Claude Code có sẵn 4 style nào và hợp hoàn cảnh nào.

Claude Code khởi động ở style **Default** — không có style instruction nào thêm, model chạy với system prompt chuẩn cho việc dev. Bảng dưới đây là bản tóm tắt docs (tra 28/10/2026):

| Style | Thay đổi gì | Dùng khi |
|---|---|---|
| **Proactive** | Claude bắt tay làm ngay, tự quyết việc nhỏ thay vì hỏi lại; không tự chuyển plan mode trừ khi bạn yêu cầu | Bạn muốn Claude tự chạy qua các quyết định thường lệ, sẵn sàng chỉnh lại sau |
| **Concise** | Câu đầu nói ra kết quả; bỏ lời dẫn, kể chuyện hành trình, recap cuối (cần ≥2.1.237) | Câu trả lời mặc định dài hơn bạn cần |
| **Explanatory** | Thêm khối `★ Insight` ngắn giải thích vì sao chọn cách làm đó | Bạn đang làm quen codebase, muốn kèm lý do |
| **Learning** | Giống Explanatory + để lại vài dòng `TODO(human)` cho bạn tự viết | Bạn muốn thực hành tay trong khi task vẫn đi tới đích |

Ghi chú quan trọng:

- **Proactive không đổi permission mode.** Style chỉ là chỉ dẫn — prompt hỏi quyền vẫn hiện như cũ; việc nào xóa data hay đụng prod thì style bảo Claude hỏi lại trong hội thoại, nhưng đó là chỉ dẫn chứ không phải cơ chế permissions.
- **Concise vẫn viết đủ dài khi cần**: khi bạn yêu cầu giải thích, và với thứ bạn cần để hành động an toàn (error report, test fail, cảnh báo security, xác nhận hành động phá hủy).
- Style **Default** cũng xuất hiện trong danh sách `/output-style` — chọn lại để về mặc định.

**Kiểm tra nhanh:** chạy `/output-style` không tham số → danh sách style hiện ra và style hiện tại được đánh dấu. Đổi sang `concise` rồi hỏi 1 câu đơn giản → câu trả lời ngắn, không lời dẫn.

---

## 3. Đổi style: 4 cách

Mục này trả lời câu: bật style bằng công cụ nào, lưu vào đâu, và áp dụng từ khi nào.

| Cách | Thao tác | Ghi chú |
|---|---|---|
| Lệnh `/output-style <style>` | `/output-style concise` (chữ hoa/thường đều được) | Chạy được cả non-interactive (`-p`) và Agent SDK từ ≥2.1.269; qua Remote Control chỉ chọn được style built-in |
| Menu `/config` | `/config` → chọn **Output style** | Ghi lựa chọn vào `.claude/settings.local.json` |
| VS Code extension | Menu `/` → **Output styles** (≥2.1.257; tạo style từ menu cần ≥2.1.261) | Chọn được cả custom style |
| Settings file | Đặt field `outputStyle` trong `.claude/settings.local.json` hoặc `~/.claude/settings.json` | Giá trị **phân biệt hoa/thường**: `Explanatory` đúng, `explanatory` → rơi về Default |

```bash
# Trong session — đổi tới khi nào:
/output-style concise
/output-style            # không tham số: liệt kê + đánh dấu style hiện tại

# Đặt default cho mọi project (user scope):
# ~/.claude/settings.json
# { "outputStyle": "Explanatory" }

# Đặt cho 1 project (project scope, đè user):
# .claude/settings.local.json
# { "outputStyle": "Concise" }
```

Thời điểm áp dụng: đổi style giữa session → style mới áp từ **tin nhắn kế tiếp** của bạn. Trước v2.1.251, style mới chỉ áp sau `/clear` hoặc mở session mới. Đổi style có thể làm mất prompt cache của turn đó (turn đầu sau khi đổi chậm hơn — xem docs prompt caching).

**Kiểm tra nhanh:** đặt `"outputStyle": "explanatory"` (viết thường) trong settings → style không áp (rơi về Default); sửa thành `"Explanatory"` → áp từ tin nhắn tiếp theo.

---

## 4. Tự viết custom output style

Mục này trả lời câu: viết 1 style riêng dạng file Markdown như thế nào, đặt ở đâu, và frontmatter gồm field gì.

Custom output style là **file Markdown**: frontmatter ghi metadata, phần thân là chỉ dẫn cho Claude. Lưu ở 1 trong 3 tầng — tên file trở thành tên style, trừ khi frontmatter đặt `name`:

```text
~/.claude/output-styles/            # user: dùng cho mọi project trên máy
.claude/output-styles/              # project: commit theo repo, cả team dùng
.claude/output-styles/ (managed)    # trong managed settings directory — do org triển khai
```

- Project load style từ **mọi** `.claude/output-styles/` giữa working directory và repo root; trùng tên thì lấy file gần working directory nhất.
- [Plugin](./09-plugins-marketplaces.md) cũng ship được output styles trong thư mục `output-styles/` của plugin.
- Claude Code đọc file style lúc khởi động → tạo/sửa file giữa session thì **restart Claude Code** để thấy thay đổi.

### 4.1. Ví dụ copy-paste: style "Diagrams first"

```markdown
---
name: Diagrams first
description: Lead every explanation with a diagram
keep-coding-instructions: true
---

When explaining code, architecture, or data flow, start with a Mermaid diagram
showing the structure, then explain in prose.

## Diagram conventions

Use `flowchart TD` for control flow and `sequenceDiagram` for request paths.
Keep diagrams under 15 nodes.
```

```bash
# Lưu và bật:
mkdir -p .claude/output-styles
# (tạo file .claude/output-styles/diagrams-first.md với nội dung trên)
/output-style diagrams-first
```

### 4.2. Frontmatter reference

| Field | Bắt buộc | Ý nghĩa |
|---|---|---|
| `name` | Không | Tên style hiện trong picker. Mặc định: tên file |
| `description` | Không | Mô tả 1 dòng hiện trong picker |
| `keep-coding-instructions` | Không | `true` = giữ nguyên phần chỉ dẫn code của Claude Code. Mặc định `false` = bỏ phần đó (dành cho style biến Claude thành role không phải dev) |
| `force-for-plugin` | Không | Chỉ cho style của plugin: `true` → tự áp khi plugin bật, đè `outputStyle` của user |

Nếu YAML parse lỗi, style vẫn load dưới tên file với không field nào; chạy `claude --debug` để xem lỗi parse.

**Kiểm tra nhanh:** tạo style trên, restart Claude Code, chạy `/output-style diagrams-first` → hỏi "explain this function" → thấy Mermaid diagram trước lời giải thích, và Claude vẫn code đúng chuẩn cũ (nhờ `keep-coding-instructions: true`).

---

## 5. Output style vs CLAUDE.md vs skill vs hook vs subagent

Mục này trả lời câu: nhu cầu của bạn thuộc vào cơ chế nào — vì nhét sai chỗ vừa tốn token vừa không đạt ý muốn.

Nguyên tắc 1 dòng: **output style = mọi câu trả lời; CLAUDE.md = những gì Claude cần biết; skill = quy trình theo task; hook = thứ phải chắc chắn xảy ra.**

| Bạn muốn | Dùng | Vì sao hợp |
|---|---|---|
| Mọi câu trả lời theo 1 giọng/độ dài/format, hoặc Claude vào vai khác | Output style | Áp cả session, đổi bằng 1 lệnh |
| Claude biết convention, lệnh build, kiến trúc project | CLAUDE.md | Chứa kiến thức codebase, nạp bất kể style nào đang bật |
| Chỉ dẫn cho 1 loại việc (checklist release, quy trình review) | Skill | Chỉ load khi được gọi hoặc khớp task — không đè các câu trả lời khác |
| Việc phải xảy ra 100%, không ngoại lệ (format sau mỗi lần sửa, chặn lệnh) | Hook | Claude Code tự chạy script tại sự kiện lifecycle, không phụ thuộc Claude "nghe lời" |
| Trợ lý với instructions/model/tools riêng cho 1 việc hẹp | Subagent | Chạy context riêng, trả tóm tắt về hội thoại chính |
| Thêm chỉ dẫn khi khởi động qua CLI | `--append-system-prompt` | Nối thêm vào system prompt, không xóa gì |

Các cơ chế **kết hợp được**: CLAUDE.md cho "Claude cần biết gì", output style cho "trả lời thế nào", hook cho "nhất định phải xảy ra".

So sánh trực diện output style với 2 hàng xóm hay nhầm:

| Tiêu chí | Output style | CLAUDE.md | Skill |
|---|---|---|---|
| Phạm vi | Mọi câu trả lời trong session | Nạp lại mỗi session, mọi câu trả lời | Chỉ khi được gọi hoặc khớp mô tả |
| Nội dung điển hình | Giọng, format, vai trò | Convention, lệnh build, quy ước | Checklist, workflow 1 loại việc |
| Có đảm bảo tuân thủ không | Không (chỉ dẫn) | Không (context, không phải config) | Không |
| Chi phí context | Thêm instructions mỗi turn (cache giảm dần) | Nạp mỗi turn → giữ <200 dòng | ~100 tokens lúc start, load body khi gọi |

---

## 6. Lưu ý: memory tool (API/SDK) khác `/memory` của Claude Code

Mục này trả lời câu: khi nói "memory", có 2 thứ hoàn toàn khác nhau — lệnh `/memory` trong Claude Code và memory tool của Messages API. Nhầm 2 thứ này là hiểu sai kiến trúc.

**Lệnh `/memory` của Claude Code** (cùng hệ [knowledge system — bài 03](./03-claude-md-memory-rules.md)):

- Lệnh **trong CLI** để xem/sửa các file memory: CLAUDE.md, CLAUDE.local.md, rules, và thư mục auto memory.
- Cũng chứa **toggle bật/tắt auto memory** và nút mở thư mục memory.
- Auto memory: Claude tự ghi chú vào `~/.claude/projects/<project>/memory/` — index `MEMORY.md` (200 dòng / 25KB đầu được nạp mỗi session) + các topic file đọc theo nhu cầu. Chạy **máy local**, không chia máy khác.
- Khi bạn nói "remember that the API tests require a local Redis" → Claude lưu vào auto memory; muốn vào CLAUDE.md thì nói rõ "add this to CLAUDE.md" hoặc tự sửa qua `/memory`.

**Memory tool của Messages API** (`tools: [{"type": "memory_20250818", "name": "memory"}]`):

- Là **tool type do Anthropic cung cấp trong API** (dùng cho agent tự build bằng Messages API hoặc Agent SDK) — **không phải** lệnh `/memory` của CLI.
- Model gọi tool `memory` với các command (`view`, `create`, `str_replace`, `insert`, `delete`, `rename`) trên thư mục `/memories`; **ứng dụng của bạn implement handler** chạy các thao tác đó trên storage bạn kiểm soát (file, DB, object store) — tức tool chạy phía client của bạn, không phải do Anthropic giữ dữ liệu. Ghi chú (cần verify): một số tài liệu gọi đây là "server-side memory"; đúng ra phần **lưu trữ** nằm ở hạ tầng bạn, còn API chỉ định nghĩa giao thức tool.
- Model tự check thư mục `/memories` trước khi làm việc (API tự chèn memory protocol vào system prompt) — hợp agent chạy dài, nhiều session, không phải quản lý CLAUDE.md.
- Trong Claude Code CLI bạn **không bật tool này**: CLI có sẵn hệ thống riêng (CLAUDE.md + auto memory + `/memory`). Memory tool là chuyện của ai đó build agent riêng.

Tóm 1 dòng: **`/memory` = trình quản lý file nhớ của Claude Code trên máy bạn; memory tool = cơ chế cho dev tự build agent bằng API/SDK, dữ liệu nằm ở hạ tầng bạn kiểm soát.**

---

## 7. Khi nào KHÔNG dùng output style

Cần điều kiện "chưa bao giờ" hay "luôn luôn" → output style không phải công cụ:

- Format sau mỗi lần sửa file, chặn `git push` sai branch → **hook** (bài 07).
- Claude cần biết convention của project → **CLAUDE.md** (bài 03).
- Checklist deploy chỉ dùng khi release → **skill** (bài 05).
- Giám sát assistant cho 1 việc hẹp → **subagent** (bài 06).

---

## 8. Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật | Cách sửa |
|---|---|---|
| Output style thay được hook để format code sau mỗi edit | Style là chỉ dẫn model, không đảm bảo 100% | Việc bắt buộc → hook `PostToolUse` (bài 07) |
| Style custom làm Claude code kém đi | Mặc định style custom bỏ phần chỉ dẫn software engineering | Đặt `keep-coding-instructions: true` nếu vẫn cần Claude code như cũ |
| Đổi style áp dụng ngay cho câu trả lời vừa rồi | Áp từ **tin nhắn kế tiếp** | Không cần `/clear` (từ ≥2.1.251); trước bản đó cần `/clear` |
| Subagent cũng nghe theo style | Subagent thường chạy system prompt riêng | Style chỉ áp hội thoại chính + fork |
| `outputStyle: "concise"` trong settings | Field phân biệt hoa/thường, sai là rơi về Default | Viết đúng `Concise`, `Proactive`, `Explanatory`, `Learning` |
| Nhầm `/memory` với memory tool `memory_20250818` | Hai cơ chế khác nhau: CLI local vs tool type của Messages API | Xem mục 6 |

---

## 9. Bài tập thực hành

**Bài 1 (10 phút):** Chạy `/output-style` → liệt kê được các style trên máy. Đổi sang `concise`, hỏi "explain this repo in 3 bullets" → so sánh độ dài với Default. Đổi về Default.

**Bài 2 (15 phút):** Tạo custom style `.claude/output-styles/reviewer-mode.md` với `keep-coding-instructions: true`, chỉ dẫn: "Mọi câu trả lời bắt đầu bằng bảng rủi ro (risk + impact) trước khi đề xuất code". Restart Claude Code, bật bằng `/output-style reviewer-mode`, verify bảng xuất hiện.

**Bài 3 (10 phút):** Đặt `"outputStyle": "Learning"` trong `~/.claude/settings.json`, mở session mới, yêu cầu viết 1 hàm xử lý lỗi → thấy `TODO(human)` và Claude dừng chờ bạn viết. Chạy xong đặt lại Default.

**Bài 4 (10 phút):** Trả lời không nhìn tài liệu: task nào dùng style, task nào dùng hook, task nào dùng skill — kiểm tra lại bằng bảng mục 5.

---

## 10. Link chéo

- **[Bài 03 — CLAUDE.md, memory & rules](./03-claude-md-memory-rules.md)**: memory files nạp thế nào; `/memory` quản lý auto memory.
- **[Bài 05 — Skills](./05-skills-custom-commands.md)**: skill = quy trình theo task, style = giọng cả session.
- **[Bài 07 — Hooks](./07-hooks-tu-dong-hoa.md)**: thứ phải chắc chắn xảy ra → hook, không phải style.
- **[Bài 10 — Permissions & modes](./10-permissions-modes-availability.md)**: Proactive không đụng permission mode; đổi mode bằng Shift+Tab.
- **[Bài 12 — Agent SDK, CI/CD](./12-agent-sdk-ci-cd-automation.md)**: `/output-style` chạy được trong SDK session (≥2.1.269); memory tool dùng khi build agent bằng SDK.
- **[Lệnh `/memory`](./commands/knowledge-system/memory/README.md)**: quản lý bộ nhớ dài hạn bằng lệnh.
- **[tool-use/mcp-advanced](../tool-use/mcp-advanced/README.md)**: nội dung MCP nâng cao đi kèm đợt cập nhật này.

---

*Nguồn chính thức (tra 28/10/2026): [Output styles](https://code.claude.com/docs/en/output-styles) · [Memory — Claude Code](https://code.claude.com/docs/en/memory) · [Memory tool — Messages API](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool).*

