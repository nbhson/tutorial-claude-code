# /clear — Xóa sạch lịch sử hội thoại, bắt đầu phiên mới trắng tinh

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file code, chỉ xóa conversation context trong bộ nhớ phiên hiện tại; không thể undo)

`/clear` là nút "reset não" của Claude Code: xóa toàn bộ lịch sử hội thoại khỏi context window, giữ nguyên file trên đĩa, giữ nguyên CLAUDE.md / memory, và cho bạn một phiên trắng để bắt đầu task mới.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/clear` | _(không có)_ | Xóa toàn bộ conversation history của session hiện tại |
| `clear` _(gõ nhanh)_ | _(không có)_ | Một số bản build chấp nhận không cần dấu `/` |
| `/clear` + prompt mới | text sau lệnh | Clear rồi hỏi tiếp trong 1 bước (quy ước workflow, không phải flag chính thức) |

Không có flag `--force`, `--keep`, `--id`. Lệnh chạy ngay khi Enter, không hỏi xác nhận.

Ví dụ gọi từng dạng:

```bash
# Dạng 1: cơ bản nhất — reset phiên
/clear
```

```bash
# Dạng 2: clear rồi bắt đầu task mới ngay (copy-paste)
/clear
Hãy giúp tôi refactor module auth/ theo cấu trúc mới trong docs/architecture.md
```

```bash
# Dạng 3: dọn rác sau khi xong việc lặt vặt
# Ví dụ: vừa debug xong CSS, giờ chuyển sang viết API — clear trước để khỏi nhiễm context
/clear
```

```bash
# Dạng 4: kết hợp kiểm tra trước khi clear (xem còn gì quan trọng không)
/context
# → thấy không còn gì cần giữ → mới clear
/clear
```

```bash
# Dạng 5: CLI / headless tương đương (khi chạy non-interactive, mỗi lần gọi là 1 phiên mới)
claude --print "Giải thích hàm main() trong main.py"
# → tương đương 1 session mới, không cần /clear
```

---

## Cách nó hoạt động

### Under-the-hood: chuyện gì xảy ra khi bạn Enter `/clear`?

1. **Snapshot bị loại bỏ khỏi RAM context:**
   - Toàn bộ `user` + `assistant` turns, tool calls, tool results, file attachments, hình ảnh, thinking summaries bị drop khỏi context window hiện tại.
   - Token count quay về ~0 (+ phần system prompt + CLAUDE.md được nạp lại).
2. **System prompt + CLAUDE.md được nạp lại:**
   - Sau clear, Claude Code đọc lại `CLAUDE.md` (project root, `~/.claude/CLAUDE.md`), `settings.json`, MCP servers, hooks, skills khả dụng.
   - Nghĩa là "luật chơi" vẫn còn, chỉ "ký ức cuộc trò chuyện" mất đi.
3. **Không đụng tới đĩa:**
   - Không xóa file code, không revert git, không xóa checkpoints, không xóa transcript log trên server (nếu dùng Claude Pro/Team, transcript vẫn lưu phía cloud để audit, nhưng không còn trong context).
   - `/todos` của session cũ cũng bị ẩn theo (todos gắn với session).
4. **Session ID giữ hay đổi?**
   - Trên Claude Code v2.1.x: `/clear` giữ nguyên terminal session nhưng tạo logical conversation mới. Muốn session vật lý mới hoàn toàn → mở terminal mới hoặc dùng `/fork` / `--resume` phân nhánh.
   - Transcript file local (`~/.claude/projects/<hash>/<session-id>.jsonl`) vẫn giữ đoạn cũ + thêm marker `clear` rồi nối tiếp — nên `/resume` đôi khi vẫn thấy được đoạn trước clear (tùy bản).
5. **Autocompact counter reset:**
   - Ngưỡng auto-compact (~80% context) được reset về 0. Bạn có thêm ~200K tokens (tùy model) để dùng tiếp.

### Sơ đồ trạng thái

```text
[Session đang đầy 65%] --/clear--> [Session 0-2%] + system prompt + CLAUDE.md
       |                                                        |
  nhớ: bug A, file X,                                    quên hết bug A,
  plan refactor, todos...                                chỉ nhớ luật trong CLAUDE.md
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Giữ context cũ? | Giữ code changes? | Dùng khi nào? |
|---|---|---|---|
| `/clear` | Không — xóa 100% hội thoại | Có — file trên đĩa giữ nguyên | Đổi task hoàn toàn khác, context nhiễm |
| `/compact` | Có (dạng tóm tắt nén) | Có | Cùng task nhưng context đầy >60% |
| `/rewind` | Quay về checkpoint cũ (xóa đoạn sau checkpoint) | Có thể revert code về checkpoint | Lỡ đi sai hướng, muốn quay lại |
| `/fork` | Copy context sang conversation mới | Có | Muốn thử hướng khác mà vẫn giữ bản gốc |
| `/branch` | Copy + gắn nhãn what-if | Có | Thử nghiệm giả thuyết song song |
| Mở terminal mới | Không | Có | Tương đương clear + session ID mới hoàn toàn |

> Quy tắc ngón tay cái:
>
> - **Cùng task, đầy RAM → `/compact`.**
> - **Khác task, RAM bẩn → `/clear`.**
> - **Sai hướng, muốn quay lại → `/rewind`.**
> - **Muốn thử 2 hướng cùng lúc → `/fork` hoặc `/branch`.**

### Khi nào `/clear` KHÔNG đủ?

- Đổi branch git + đổi task → nên `/clear` + `git checkout` riêng. `/clear` không đổi branch git giùm bạn.
- Nhiễm `CLAUDE.md` sai → phải sửa file `CLAUDE.md` rồi mới `/clear` để nạp lại. Clear mà không sửa file thì luật sai vẫn load lại.
- Muốn xóa transcript cloud → `/clear` không xóa log server. Phải xóa từ dashboard / settings nếu cần privacy tuyệt đối.

---

## Ví dụ thực tế

### Kịch bản 1: Xong bug nhỏ, chuyển sang feature lớn (tránh nhiễm context)

Bạn vừa mất 30 phút fix CSS button lệch 2px. Giờ chuyển sang viết API thanh toán — nếu không clear, model vẫn "ám ảnh" chuyện CSS và trả lời lạc đề.

```bash
# Bước 1: đang ở cuối cuộc fix CSS
# (context ~45%, toàn chuyện padding, margin, flexbox)

# Bước 2: reset
/clear

# Bước 3: bắt đầu task mới sạch sẽ, nạp đúng tài liệu cần
Hãy đọc docs/payment-spec.md và triển khai POST /api/payments theo spec.
Chỉ sửa trong src/payments/, không đụng tới CSS.
```

> Kết quả: context từ ~45% về ~3%, model không còn nhắc tới button nữa, tập trung 100% vào payments.

### Kịch bản 2: Dọn context nhiễm sau khi paste log khổng lồ

Bạn paste 1 stack trace 500 dòng + 3 file log để debug. Fix xong nhưng context phình to 70%, mọi câu hỏi sau đều chậm và tốn tiền.

```bash
# Bước 1: kiểm tra mức đầy
/context

# Bước 2: vì task đã xong, không cần tóm tắt → clear thẳng, khỏi compact
/clear

# Bước 3: tóm tắt kết quả cho đồng đội trước khi quên (tự ghi tay vì đã clear)
# Ví dụ ghi vào file:
# "Bug do race condition ở worker pool, fix bằng mutex ở src/queue/worker.ts:42"
```

```bash
# Biến thể: clear + lưu bài học vào memory để lần sau nhớ
/clear
# Sau clear, dặn model điều rút ra (để nó lưu vào CLAUDE.md nếu bạn cho phép):
Lần sau khi debug worker pool, nhớ kiểm tra mutex ở src/queue/worker.ts trước.
```

### Kịch bản 3: Trước demo / screenshare / gửi transcript cho người khác

```bash
# Bạn sắp share màn hình, không muốn lộ API keys / chuyện lương thưởng đã chat trước đó
/clear

# Bắt đầu cuộc hội thoại demo sạch
Hãy giải thích kiến trúc dự án này cho người mới trong 5 bullet.
```

### Kịch bản 4: Kết hợp `/export` để không mất kiến thức trước khi clear

```bash
# Task dài 2 tiếng, context 75%, muốn clear nhưng sợ mất quyết định quan trọng
/export
# → lưu transcript ra file text, đọc lại, copy quyết định quan trọng vào docs/decisions.md

/clear

# Nạp lại đúng cái cần, bỏ rác
Hãy đọc docs/decisions.md và tiếp tục implement bước 3.
```

---

## Rủi ro & lưu ý

### Mất gì? Có cứu được không?

| Mất gì | Cứu được không? | Cách cứu |
|---|---|---|
| Lịch sử hội thoại trong context | Không (trong phiên) | Chỉ còn nếu transcript `.jsonl` local chưa bị xoay vòng, hoặc dùng `/resume` / `--resume` |
| Todos (`/todos`) của session | Không | Phải tạo lại, hoặc đã `/export` trước |
| File đính kèm / ảnh đã paste | Không | Paste lại |
| Quyết định kiến trúc đã thảo luận | Không (model quên) | Ghi ra file trước khi clear |
| Code trên đĩa | Không mất — an toàn | — |
| CLAUDE.md / settings / hooks | Không mất — tự nạp lại | — |
| Checkpoints (rewind points) | Tùy bản — thường vẫn còn trên đĩa nhưng khó truy cập sau clear | Dùng `git log` / checkpoint UI trước khi clear |

> **Nguyên tắc vàng:** _Clear là một chiều._ Nếu cuộc trò chuyện có bất kỳ câu nào bạn sẽ tiếc khi mất (quyết định, snippet hay, plan), hãy `/export` hoặc ghi ra file trước.

### Tốn token?

- `/clear` tự nó tốn ~0 token (lệnh local).
- Nhưng sau clear, model phải đọc lại file từ đầu khi bạn hỏi tiếp → tốn lại vài nghìn tokens đọc file. Vẫn rẻ hơn nhiều so với kéo lê 150K tokens rác.
- Ví dụ số học:
  - Không clear, mỗi prompt gánh 100K tokens rác × 10 prompts = 1M tokens input lãng phí.
  - Clear 1 lần, đọc lại 5K tokens × 10 prompts = 50K tokens. Tiết kiệm ~95%.

### Version tối thiểu & provider

- Có mặt từ bản Claude Code đời đầu, ổn định trên v2.1.x (CLI, IDE extension, Web, Desktop đều có).
- Không yêu cầu plan đặc biệt: Free / Pro / Team / API (pay-as-you-go) đều dùng được.
- Không phụ thuộc MCP hay plugin nào.

### Cloud vs Local khác gì?

| Môi trường | Hành vi `/clear` |
|---|---|
| CLI local | Xóa context RAM, transcript `.jsonl` vẫn nằm ở `~/.claude/projects/` |
| IDE (VS Code / JetBrains) | Tương tự CLI + panel chat trắng lại, file mở trên editor giữ nguyên |
| Web (claude.ai / console) | Xóa view hiện tại, transcript cloud vẫn lưu theo retention policy |
| Desktop app | Giống Web + xóa panel phụ |

> Privacy: nếu đã paste secret (API key, token) rồi mới `/clear`, secret vẫn có thể nằm trong transcript log. Hãy rotate key đó, đừng tin rằng clear là xóa sạch dấu vết.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/context` → `/clear` | Kiểm tra rồi mới quyết clear hay compact | `/context` rồi `/clear` |
| `/export` → `/clear` | Lưu lại trước khi xóa | `/export` rồi `/clear` |
| `/compact` vs `/clear` | Cùng task → compact; khác task → clear | `/compact tập trung vào auth` hoặc `/clear` |
| `/clear` → `/resume` | Clear nhầm, muốn mò lại | `claude --resume` (CLI) để picker session cũ |
| `/clear` + CLAUDE.md | Đổi luật rồi nạp lại | Sửa `CLAUDE.md` → `/clear` → hỏi tiếp |
| `/clear` + git | Đổi task + đổi nhánh | `git checkout -b feat/x` + `/clear` |
| `/todos` → `/clear` | Chốt todos trước khi xóa | `/todos` kiểm tra xong → `/clear` |

Workflow chuẩn "sáng thứ Hai":

```bash
# 1. Xem phiên cuối tuần còn gì dang dở
/resume
# → thấy toàn task vặt đã xong

# 2. Bắt tuần mới sạch sẽ
/clear

# 3. Nạp đúng việc tuần này
Hãy đọc docs/sprint-12.md và liệt kê 3 task ưu tiên cao nhất.
```

Workflow "chốt ca trực":

```bash
# Cuối ngày, lưu lại rồi mới clear cho ca sau
/export
# → gửi file export cho ca sau
/clear
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/clear` xong model vẫn "nhớ" chuyện cũ | Nhớ từ `CLAUDE.md` / memory file, không phải từ conversation | Sửa `CLAUDE.md` / `~/.claude/CLAUDE.md`, không phải lỗi clear |
| Gõ `/clear` báo `unknown command` | Bản CLI quá cũ hoặc gõ trong `--print` non-interactive | Update `npm i -g @anthropic-ai/claude-code`, hoặc mỗi lần gọi CLI đã là session mới nên không cần clear |
| Clear xong `/resume` vẫn thấy đoạn cũ | Transcript `.jsonl` vẫn lưu, resume đọc từ đĩa | Đúng hành vi; muốn quên hẳn thì không resume session đó nữa, bắt session mới |
| Clear xong todos mất hết | Todos gắn với conversation đã xóa | Tạo lại todos, hoặc lần sau `/export` / ghi todos ra file trước |
| Clear xong model hỏi lại những file vừa đọc | Đương nhiên — context trắng, phải đọc lại | Paste lại đường dẫn file / để model đọc lại; đây là chi phí bình thường |
| Muốn undo `/clear` | Không có undo | Dùng `claude --resume` / `/resume` mò transcript cũ; phòng bệnh bằng `/export` trước khi clear |
| `/clear` trong IDE không xóa file đang mở | Hiểu nhầm — clear chỉ xóa chat, không đóng editor | Đóng file thủ công nếu muốn gọn màn hình |

---

## Tham khảo

- Lệnh thay thế / liên quan trực tiếp:
  - [../compact/README.md](../compact/README.md) — nén thay vì xóa khi cùng task
  - [../context/README.md](../context/README.md) — xem % đầy trước khi quyết clear hay compact
  - [../rewind/README.md](../rewind/README.md) — quay checkpoint thay vì xóa trắng
  - [../fork/README.md](../fork/README.md) — tách nhánh giữ bản gốc
  - [../branch/README.md](../branch/README.md) — thử what-if song song
  - [../resume/README.md](../resume/README.md) — cứu lại session sau khi clear nhầm
  - [../export/README.md](../export/README.md) — lưu transcript trước khi clear
  - [../copy/README.md](../copy/README.md) — copy đoạn hay ra clipboard trước khi clear
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ toàn bộ slash commands v2.1.x
  - `../10-permissions-modes-availability.md` — clear không ảnh hưởng permissions/modes
  - `../11-git-worktrees-checkpoints.md` — checkpoints & worktrees (clear không đụng git)
  - `../03-claude-md-memory-rules.md` — vì sao CLAUDE.md sống sót sau clear

> Mẹo 1 dòng: _trước mỗi `/clear`, tự hỏi "có câu nào đáng lưu không?" — nếu có, `/export` trước, clear sau._
