# Tips 06 — Hooks recipes: biến mọi rule hay quên thành luật

> **Bài này cho ai:** dev đang dặn Claude "nhớ chạy lint / đừng push main" tới lần thứ hai, hoặc tech lead chuẩn hóa hooks cho team.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [Tips 04 — Verification](./04-verification-done-that.md) trước vì recipe test-gate ở mục 3 nối tiếp vòng verify của Tips 04.
> **Đọc xong bạn làm được:**
> - Copy-paste 3 recipes bắt buộc (lint-on-write, branch-protect, cost-cap) + 3 recipes nâng cao, lắp cho repo mới trong 30 phút.
> - Tránh 7 bẫy hooks (matcher sai, chạy headless, hook chậm...).
> **Thời gian:** ~45 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Hook | Luật tự chạy ngoài model: 0 tokens, không bị thuyết phục, không mệt | `hooks/lint-on-write.sh` tự chạy sau mỗi lần sửa file |
| PreToolUse / PostToolUse | Hook chạy trước khi tool được phép chạy / chạy xong tool | `PreToolUse Bash` chặn `git push -f` trước khi lệnh chạy |
| Stop / SessionStart / SessionEnd | Hook chạy lúc sắp kết thúc turn / mở session / đóng session | `Stop` → test-gate, `SessionStart` → nạp branch + `git status` |
| Matcher | Chuỗi chọn tool nào bị áp luật — phân biệt hoa thường | `matcher: "Edit\|Write"` chỉ áp cho lệnh sửa/ghi file |
| exit code | Đèn tín hiệu: `0` cho qua, `2` chặn và hiện lý do cho agent | `branch-protect.sh` trả `exit 2` khi push thẳng main |

---

## 1. Triết lý + cơ chế hooks

Mục này trả lời 2 câu trước khi vào code: hook là gì trong đầu của Claude Code, và khi nào thì đáng viết hook thay vì cứ nhắc miệng.

### 1.1. Triết lý 1 dòng

**Rule bị miss 2 lần → viết thành hook.** Nhắc lần 1 quên, nhắc lần 2 vẫn quên khi vội; lần 3 đừng nhắc nữa — viết hook tự chạy lint sau mỗi edit. Hook giống cái khóa cửa tự động: không cần ai nhớ khóa, cửa tự khóa mỗi lần đóng.

### 1.2. Cơ chế: hooks chạy ở đâu?

Hook can thiệp 4 mốc: **PreToolUse** (định chạy tool — cho hay chặn?), **PostToolUse** (tool xong — lint/format/log?), **Stop** (turn định kết thúc — test xanh chưa?), **SessionStart/SessionEnd** (mở/đóng session — nạp branch, tóm tắt). Hãy tưởng tượng 4 mốc như 4 cửa kiểm soát của một tòa nhà: cửa vào trước khi làm, cửa ra sau khi làm, cửa lúc ra về, và cửa lúc mở/đóng tòa nhà.

- Hooks chạy **ngoài model** (shell script, LLM 1-turn, agent, HTTP, MCP) → 0 tokens cho rule lặp lại.
- Hook có thể: **cho qua**, **chặn + báo lý do**, **sửa input** (`updatedInput`), **ghi log**. Hook lỗi hoặc timeout mặc định **không chặn**; muốn lỗi cũng chặn thì đặt `"onFailure": "block"`.
- Hooks là production code (chạy với quyền của bạn): review như code, version như code.

### 1.3. Khi nào hook vs skill vs prompt?

| Dùng gì | Khi nào | Ví dụ |
|---|---|---|
| Prompt (1 câu) | Việc 1 lần, ít lặp | "Lần này nhớ chạy test X" |
| Skill (`/lint`, `/deploy`) | Quy trình cần judgment, gọi khi cần | Deploy checklist, review |
| Hook | Rule lặp lại, phải đúng 100%, không tin LLM | Lint sau edit, cấm push main, cost cap |

> **Cách đọc bảng này:** đọc theo cột "Khi nào" và tự hỏi việc của mình lặp lại không, có cần phán đoán không — dòng khớp nhất chính là công cụ nên dùng.

> Rule ngón tay: **việc làm 1 lần → prompt. Việc cần người quyết → skill. Việc máy check được + lặp lại → hook.**

> **Tóm gọn 1 câu:** Prompt là lời dặn, skill là sách tay công việc, hook là khóa cửa tự động — lặp lại nhiều thì khóa cửa, đừng dặn miệng.

---

## 2. Ba recipes bắt buộc (code đầy đủ)

Mục này là phần "công thức nấu" của bài: 3 recipe dùng cho gần như mọi repo. Cứ copy nguyên khung rồi đổi matcher/event cho dự án của bạn.

Cả 3 cùng khuôn `settings.json` — đổi `matcher`, event và `command` cho từng recipe:

> 📄 **Code ví dụ:** [`examples/01-2-ba-recipes-bat-buoc-code-ay-u.json`](examples/01-2-ba-recipes-bat-buoc-code-ay-u.json)

### 2a. Lint-on-write — `PostToolUse` match `Edit|Write`

**Mục tiêu:** sau mỗi edit, chạy prettier/eslint đúng file vừa đổi. Lỗi → trả cho agent fix ngay turn sau, không dồn thành cleanup 40 files cuối tuần.

**`hooks/lint-on-write.sh`:**

> 📄 **Code ví dụ:** [`examples/02-2a-lint-on-write-posttooluse-match-edit-write.sh`](examples/02-2a-lint-on-write-posttooluse-match-edit-write.sh)

**Kiểm tra nhanh:** `echo '{"tool_input":{"file_path":"src/a.ts"}}' | ./hooks/lint-on-write.sh` — sửa `src/a.ts` sai lint phải bị báo; file `.md` và `generated/foo.ts` phải được bỏ qua.

### 2b. Branch-protect — `PreToolUse` match `Bash`

**Mục tiêu:** block push lên `main`, mọi force-push, xóa branch, `push origin HEAD:main`. **Match theo intent, không substring.**

**`hooks/branch-protect.sh`:**

> 📄 **Code ví dụ:** [`examples/03-2b-branch-protect-pretooluse-match-bash.sh`](examples/03-2b-branch-protect-pretooluse-match-bash.sh)

**Kiểm tra nhanh:** 4 ca blocked + 2 ca đối chứng (copy-paste):

> 📄 **Code ví dụ:** [`examples/04-2b-branch-protect-pretooluse-match-bash.sh`](examples/04-2b-branch-protect-pretooluse-match-bash.sh)

### 2c. Cost-cap — `Stop`

**Mục tiêu:** đọc token usage từ hook input → quy $ theo pricing hiện tại → append daily ledger → quá cap cảnh báo. Bảo hiểm rẻ nhất, add sớm bất kể project lớn nhỏ.

**`hooks/cost-cap.sh` (điền giá per-token theo bảng pricing hiện tại của provider, đừng hardcode số cũ):**

> 📄 **Code ví dụ:** [`examples/05-2c-cost-cap-stop.sh`](examples/05-2c-cost-cap-stop.sh)

**Kiểm tra nhanh:** `DAILY_CAP_USD=0.01 ./hooks/cost-cap.sh < /dev/null` → ledger append + cảnh báo khi quá cap.

> **Tóm gọn 1 câu:** Ba recipe bắt buộc là ba chốt cửa: chốt sau khi sửa (lint), chốt trước khi đi ra (push), và chốt lúc đóng phiên (cost) — lắp đủ 3 là repo đã tự canh được phần lớn.

---

## 3. Ba recipes nâng cao

Mục này dành cho repo cần thêm 3 "cửa kiểm soát" chuyên biệt hơn: chặn ghi vào vùng nhạy cảm, gate test trước khi kết thúc turn, và tự nạp bối cảnh lúc mở session. Vẫn giữ nguyên khuôn recipe ở mục 2 — chỉ đổi event và nội dung script.

### 3.1. Guard sensitive paths — `PreToolUse` match `Write|Edit`

> 📄 **Code ví dụ:** [`examples/06-3-1-guard-sensitive-paths-pretooluse-match-write.sh`](examples/06-3-1-guard-sensitive-paths-pretooluse-match-write.sh)

### 3.2. Test-gate — `Stop`

> 📄 **Code ví dụ:** [`examples/07-3-2-test-gate-stop.sh`](examples/07-3-2-test-gate-stop.sh)

> Dùng kèm `/goal` + reviewer cuối (xem [Tips 04](./04-verification-done-that.md)). Gate đảm bảo "xanh", reviewer đảm bảo "đúng".

### 3.3. SessionStart inject

Tự nạp branch hiện tại, ticket, `git status` tóm tắt vào context lúc mở session: script in ra stdout vài dòng `git branch --show-current`, `git status --short | head -20`, `git log --oneline -5`, ticket parse từ tên branch, và rule "1 task 1 session, đổi task thì /clear". Biến thể dynamic line trong skill (data tươi mà không cần hook): `` `!`git branch --show-current`` ``.

> **Tóm gọn 1 câu:** Ba recipe nâng cao là 3 trợ lý lễ tân: một chặn đồ cấm khỏi cửa, một giữ cổng đến khi test xanh, một tóm tắt "nay đến vì việc gì" ngay khi bạn bước vào.

---

## 4. Năm loại hook: command/prompt/agent/http/mcp

Mục này giúp bạn chọn "loại nhiên liệu" cho hook: cùng một việc chặn, nhưng chạy bằng script, bằng model, hay gọi ra ngoài thì giá và độ tin cậy khác nhau.

| Loại | Chạy bằng gì | Khi dùng |
|---|---|---|
| `command` (shell, default) | Script bash/python | Mọi thứ deterministic — production ưu tiên (2a–3.2 ở trên) |
| `prompt` (LLM 1-turn, Haiku default) | Model 1 turn đọc input | Judgment từ input: commit msg có leak secret? |
| `agent` (experimental, ~60s/50 turns) | Subagent thật | Verify cần đọc code/chạy lệnh thật: pre-push smoke |
| `http` | POST ra ngoài | Ping Slack khi cost quá cap, ghi audit log |
| `mcp_tool` | Gọi MCP tool trong hook | SessionStart lấy ticket Jira/Linear gắn branch |

> **Cách đọc bảng này:** đọc theo cột "Chạy bằng gì" để thấy mỗi loại dùng nhiên liệu khác nhau (shell → model → ra ngoài), rồi tra cột "Khi dùng" — càng xuống dưới càng đắt và càng khó đoán, nên chỉ rời dòng đầu tiên khi shell không diễn đạt nổi việc của bạn.

> Rule: **production ưu tiên `command`.** `prompt`/`agent` để judgment, `http`/`mcp_tool` để tích hợp ngoài. Hook lỗi/timeout mặc định thả qua; thêm `"onFailure": "block"` để lỗi cũng chặn.

> **Tóm gọn 1 câu:** Càng gần shell càng rẻ và càng đáng tin — script trước, model sau, gọi ngoài chỉ khi phải "đàm phán" với hệ khác.

---

## 5. Lắp hooks cho repo mới trong 30 phút

Mục này là bản đồ 30 phút để đi từ repo trắng tới bộ hooks hoàn chỉnh — làm theo từng mốc thời gian là xong.

1. **0–5p:** `mkdir -p hooks .claude/ledger && chmod +x hooks/*.sh`, copy 4 scripts (2a, 2b, 2c, 3.1).
2. **5–15p:** ghép khuôn `settings.json` mục 2 → test 4 ca push + 3 ca lint → `/hooks` kiểm tra matcher/event.
3. **15–25p:** thêm `test-gate.sh` (sửa `TEST_SCOPE`) — làm đỏ 1 test, xác nhận Stop block.
4. **25–30p:** thêm `session-start.sh`, mở session mới xem branch/status → commit `settings.json` + `hooks/`, ghi 1 dòng vào `CLAUDE.md`.

> **Tóm gọn 1 câu:** 30 phút chia 4 mốc — copy scripts, ghép settings, test gate, thêm SessionStart — là repo mới có đủ luật tự chạy.

---

## 6. Bảy bẫy thường gặp

Mục này là danh sách "vết xe đổ" của người đi trước — đọc trước khi hook của bạn im lặng giữa production.

1. **Matcher case-sensitive, sai event.** `edit|write` không match `Edit|Write`; Pre vs Post ngược → chạy sai lúc. Fix: `/hooks` + test từng event.
2. **2 hooks cùng rewrite `updatedInput`.** Kết quả non-deterministic. Fix: mỗi hook 1 field riêng, hoặc gộp 1 script.
3. **Headless (`-p`) + background subagents không trả lời prompt được.** Hook chờ input là treo. Fix: không `read`, không mở editor, timeout rõ.
4. **Hooks là production code nhưng review như đồ chơi.** Hook chạy với quyền của bạn. Fix: review/test/version như code, không curl pipe bash lạ vào `hooks/`.
5. **Substring match (`main`).** `feat/my-main-fix` bị chặn oan, `HEAD:main` lọt. Fix: match intent bằng regex (2b) + test cả ca đối chứng.
6. **Bẫy version.** Schema stdin/hooks từng đổi qua các bản — hook viết năm ngoái có thể lặng lẽ không chạy năm nay. Fix: đối chiếu release notes trước khi tin hook chặn CI/push; pin version Claude trong team ([Tips 09](./09-teamwork-chuan-hoa.md)).
7. **Hook chậm làm mọi turn chậm.** Full suite 5 phút mỗi turn-end = tự DDoS mình. Fix: `TEST_SCOPE` + cache + timeout, chỉ gate ở Stop.

> **Tóm gọn 1 câu:** Hook là bảo vệ có quyền ngang bạn — viết sai matcher thì im, viết chậm thì mọi turn chậm, nên test kỹ như code production thật.

---

## 7. Bài tập

- **Bài 1 (20 phút):** copy 3 scripts mục 2 + khuôn `settings.json`, chạy 3 ca lint + 4 ca push + cost-cap (`DAILY_CAP_USD=0.01`). Sửa regex tới khi 4 blocked + 2 ca đối chứng pass.
- **Bài 2 (20 phút):** thêm `guard-paths.sh` (write `migrations/001.sql`, `.env` phải blocked) + `test-gate.sh` (làm đỏ 1 test → Stop exit 2; sửa xanh → exit 0).
- **Bài 3 (15 phút):** `/hooks` kiểm tra overlap `updatedInput`; `time` từng hook (>5s thì focus scope/cache); viết 1 `prompt` hook check secret cho `git commit`, test với `ghp_fake123`.

---

## 8. Tham khảo chéo

- [../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md) — xem/sửa hooks · [../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) — phát hiện hooks chậm
- [Tips 04](./04-verification-done-that.md) — Stop test-gate · [Tips 05](./05-parallel-agents.md) — hooks bound subagent · [Tips 08](./08-tiet-kiem-cost-token.md) — cost-cap + route model · [Tips 09](./09-teamwork-chuan-hoa.md) — commit hooks cho team

> Mẹo 1 dòng: _lần thứ hai phải nhắc cùng 1 rule bằng miệng là lần đáng lẽ đã viết hook._
