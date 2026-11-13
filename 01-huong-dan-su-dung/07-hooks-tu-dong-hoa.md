# 07 — Hooks: tự động hóa tất định (luật, không phải gợi ý)

> **Bài này cho ai:** dev đã dùng CLAUDE.md/skills mà rule vẫn bị Claude quên, muốn nâng rule thành luật chạy thật.
> **Cần gì trước:** đã cài và đăng nhập (bài 01); nên đọc [bài 03](./03-claude-md-memory-rules.md) để phân biệt "gợi ý" với "luật".
> **Đọc xong bạn làm được:** giải thích vì sao hook chạy 0 token model + chặn được cả khi bật `--dangerously-skip-permissions`; copy full `settings.json` mẫu + 5 hooks hoàn chỉnh; chọn đúng event/matcher/type; debug hook không chạy bằng flowchart 7 bước.
> **Thời gian:** ~40 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Hook | Aptomat tự nhảy: harness tự chạy lệnh, không hỏi model | Sau mỗi `Edit` tự chạy `eslint` |
| Event | Tín hiệu 1 việc vừa xảy ra | `PreToolUse`, `PostToolUse`, `SessionStart`, `Stop` |
| Matcher | Lọc "hook này áp cho tool nào" (nhiều tool nối `\|`) | `Bash`, `Edit\|Write` — **case-sensitive** |
| Exit code | 0 = cho qua, 2 = chặn | `exit 2` kèm `permissionDecision: deny` |
| stdin/stdout | Ống dẫn JSON đưa vào hook + kết quả trả ra | `INPUT="$(cat)"` |
| Type của hook | `command` (shell), `http`, `mcp_tool`, `prompt`, `agent` | 95% việc dùng `command` |
| Advisory vs law | Gợi ý thì Claude có thể quên; luật bắt buộc chạy | CLAUDE.md = gợi ý, hook = luật |

## Mục lục

1. [Hook là gì và vì sao luật thắng gợi ý](#1-hook-là-gì-và-vì-sao-luật-thắng-gợi-ý)
2. [Các event + type](#2-các-event--type)
3. [Cấu hình settings.json + hợp đồng stdin/stdout](#3-cấu-hình-settingsjson--hợp-đồng-stdinstdout)
4. [Full settings.json mẫu + 5 hooks hoàn chỉnh](#4-full-settingsjson-mẫu--5-hooks-hoàn-chỉnh)
5. [Walkthrough + debug khi hook không chạy](#5-walkthrough--debug-khi-hook-không-chạy)
6. [Bẫy, bài tập, link](#6-bẫy-bài-tập-link)

---

## 1. Hook là gì và vì sao luật thắng gợi ý

Mục này trả lời câu hỏi nền tảng: hook là gì, và vì sao rule quan trọng phải viết thành hook thay vì để trong CLAUDE.md. Đọc để hiểu "luật" khác "gợi ý" ở chỗ nào — đó là ý duy nhất bạn cần nhớ cả bài.

**Nôm na 1 câu:** Hook là *khóa cửa tự động* — tới giờ là khóa, không cần hỏi chủ nhà (model) có muốn khóa không. Hãy hình dung CLAUDE.md là tấm biển "vui lòng tắt đèn" còn hook là công tắc cảm ứng: biển thì ai đọc cũng được nhưng có người quên, cảm ứng thì tắt dù bạn có đọc hay không.

> 📄 **Code ví dụ:** [`examples/01-1-hook-la-gi-va-vi-sao-luat.sh`](examples/01-1-hook-la-gi-va-vi-sao-luat.sh)

**Vì sao hook chắc chắn hơn CLAUDE.md:** hook chạy **ngoài model** (harness chạy shell, không qua LLM — trừ type `prompt`/`agent`) → 0 model tokens, không bị prompt-injection thuyết phục, chạy trước cả `bypassPermissions`/`--dangerously-skip-permissions`, và **chỉ siết không nới** (hook allow không thắng được deny rules hay `ask` của org — sửa deny gốc ở bài 10). Như bảo vệ tòa nhà: có được lệnh "hãy để xe vào" từ ai đó đi nữa, vẫn phải quét thẻ gốc.

```text
CLAUDE.md "NEVER push main"   → Claude đọc, gật gù, đôi khi vẫn push (quên/misread)
PreToolUse hook match push    → block 100%, kể cả --dangerously-skip-permissions
```

> Công thức cả bài: **CLAUDE.md/skills = gợi ý (advisory) — hook = luật (law, chạy chắc)**. Rule bị Claude miss ≥2 lần → nâng thành hook. Mọi team cần ít nhất hook block-push-main + lint-on-write.

> **Tóm gọn 1 câu:** CLAUDE.md là tấm biển dán tường, hook là công tắc cảm ứng — rule mà Claude quên từ 2 lần trở lên thì đừng dán biển nữa, lắp công tắc.

---

## 2. Các event + type

Mục này là "bản đồ hệ nhị phân" của hook: event nào lửa lúc nào, và type nào dùng cho việc nào. Đọc để chọn đúng thời điểm và đúng loại súng trước khi viết hook đầu tiên.

Bảng event như bảng lịch trình của một ngày làm việc: mỗi dòng là một thời điểm trong vòng đời session/tool, và hook của bạn đeo vào đúng thời điểm đó.

| Event | Khi lửa | Dùng cho |
|---|---|---|
| `SessionStart` | Session bắt đầu/resume | Inject context (branch, ticket, env check) |
| `Setup` | `claude --init-only` / `--init` trong `-p` | CI warmup (bài 12) |
| `UserPromptSubmit` | User submit prompt | Block/redirect prompt nguy hiểm, log |
| `PreToolUse` | Trước tool call (**block được**), chạy trước mọi permission check | Guard rails (branch-protect, migration-guard) |
| `PermissionRequest` / `PermissionDenied` | Tool cần quyết định quyền / auto mode deny | Custom permission UI; `retry: true` gợi ý lệnh đúng |
| `PostToolUse` / `PostToolUseFailure` | Sau tool thành công/thất bại | Lint-on-write, format, log |
| `PostToolBatch` | Sau cả batch parallel tool calls | Tổng hợp batch (check tổng files đổi) |
| `Notification` | Claude gửi notification | Ping Slack/osascript |
| `SubagentStart`/`SubagentStop` | Subagent spawn/finish (matcher = tên agent) | Log cost, inject context |
| `TaskCreated`/`TaskCompleted` | Task lifecycle | Tracking, ledger |
| `Stop` / `StopFailure` | Turn kết thúc (không lửa khi user interrupt) | Cost ledger; gate block turn-end tới khi pass (tối đa 8 blocks) |
| `TeammateIdle` | Teammate agent-team sắp idle | Giao việc tiếp (teams) |
| `InstructionsLoaded` | 1 file CLAUDE.md/rules vừa load | Validate/audit memory load |
| `PreCompact`/`PostCompact`, `ConfigChange` | Compaction/config | Backup context trước compact |

> **Cách đọc bảng này:** cột "Khi lửa" là thời điểm hook được gọi, cột "Dùng cho" là việc hay làm lúc đó — muốn chặn chuyện gì xảy ra thì tìm event đứng *trước* chuyện đó (vd chặn push → `PreToolUse`).

| Type | Khi nào | Ví dụ |
|---|---|---|
| `command` | 95% cases — deterministic, nhanh, 0 token | Lint, block push, guard migrations |
| `prompt` | Cần judgment ngôn ngữ (regex không được) | "Commit message có leak secret không?" |
| `agent` | Verify cần đọc code multi-turn (experimental) | Review diff trước khi cho push |
| `http` / `mcp_tool` | Đẩy event ra hệ ngoài / gọi tool MCP đã connect | Log sang ticketing; PostToolUse → tạo ticket Linear |

> **Cách đọc bảng này:** chọn type như chọn dụng cụ: `command` là búa — đủ cho 95% việc; 3 dòng còn lại là dụng cụ đặc biệt, chỉ lấy khi búa không đóng được.

> Hooks nhận được cả **effort level** hiện tại trong event JSON (w19/2026) — có thể siết chặt hơn khi effort thấp.

> **Tóm gọn 1 câu:** Chọn event theo *thời điểm* muốn can thiệp, chọn type theo *loại việc* — 95% là `command` chạy shell, 0 token.

---

## 3. Cấu hình settings.json + hợp đồng stdin/stdout

Mục này nói về 2 mảng: hook ghi vào file nào, và "hợp đồng" trao đổi dữ liệu giữa harness và hook ra sao. Đọc để biết hook sống ở đâu và nói chuyện với harness bằng ngôn ngữ gì.

Thứ tự ưu tiên giống hệ thống phân cấp công ty: chính sách công ty (org) thắng bản local cá nhân, bản cá nhân thắng bản team, bản team thắng bản máy — tầng nào trên ghi đè tầng dưới.

Thứ tự ưu tiên: `managed policy (org) > .claude/settings.local.json (personal, không commit) > .claude/settings.json (team, commit) > ~/.claude/settings.json`. Xem merged result bằng `/permissions` — đừng đoán.

```text
1. Harness gửi event JSON qua STDIN: {"tool":"Bash","input":{"command":"git push origin main"},"cwd":"..."}
2. Hook đọc stdin (jq/python), quyết định:
   - Exit 0 (+ optional {"permissionDecision":"allow"})   → cho qua
   - Exit 2 / {"permissionDecision":"deny","reason":"..."} → block, reason hiện cho Claude + user
   - {"updatedInput":{...}}                                → rewrite input (vd thêm --dry-run)
   - Stop gate: {"decision":"block","reason":"tests fail"} → Claude fix tiếp (tối đa 8 blocks)
```

- Matcher **case-sensitive** (`Edit` ≠ `edit`). Nhiều hooks cùng event chạy song song; 2 hook cùng rewrite `updatedInput` → thằng finish cuối thắng (non-deterministic — tránh overlap).
- Hook lỗi/timeout mặc định **thả qua**; đặt `onFailure: "block"` (≥2.1.295) để chặn khi hook lỗi — dùng cho guard bảo mật.

> **Tóm gọn 1 câu:** Hook sống ở 4 tầng settings (org thắng tất) và nói chuyện với harness qua stdin/stdout JSON — exit 2 là chặn, và hook chỉ có quyền siết chứ không nới.

---

## 4. Full settings.json mẫu + 5 hooks hoàn chỉnh

Mục này giao cho bạn 5 hook "đi kèm pin": settings.json đầy đủ + từng hook một, cài là chạy. Đọc phần mô tả từng hook để biết mỗi cái gác cửa chỗ nào trước khi dán vào repo.

> 📄 **Code ví dụ:** [`examples/02-4-full-settings-json-mau-5-hooks-hoan.json`](examples/02-4-full-settings-json-mau-5-hooks-hoan.json)

Hãy hình dung 5 hook này như 5 bảo vệ phân ca: một người soát từng file vừa sửa (lint), một người đứng cửa push, một người canh phòng migration, một người ghi sổ chi tiêu, một người mở cửa phòng họp đầu giờ.

**Hook 1 — lint-on-write (PostToolUse Edit|Write)** — format/lint file vừa sửa, lỗi trả lại cho agent fix ngay:

> 📄 **Code ví dụ:** [`examples/03-4-full-settings-json-mau-5-hooks-hoan.sh`](examples/03-4-full-settings-json-mau-5-hooks-hoan.sh)

**Hook 2 — branch-protect (PreToolUse Bash)** — match theo INTENT, không substring "main":

> 📄 **Code ví dụ:** [`examples/04-4-full-settings-json-mau-5-hooks-hoan.sh`](examples/04-4-full-settings-json-mau-5-hooks-hoan.sh)

**Hook 3 — guard-migrations (PreToolUse Write)** — block sửa migration đã merge:

> 📄 **Code ví dụ:** [`examples/05-4-full-settings-json-mau-5-hooks-hoan.sh`](examples/05-4-full-settings-json-mau-5-hooks-hoan.sh)

**Hook 4 — cost-ledger (Stop)** — append token usage vào CSV hàng ngày:

> 📄 **Code ví dụ:** [`examples/06-4-full-settings-json-mau-5-hooks-hoan.sh`](examples/06-4-full-settings-json-mau-5-hooks-hoan.sh)

**Hook 5 — session-context (SessionStart)** — inject branch + git status vào context:

> 📄 **Code ví dụ:** [`examples/07-4-full-settings-json-mau-5-hooks-hoan.sh`](examples/07-4-full-settings-json-mau-5-hooks-hoan.sh)

Cài: `chmod +x .claude/hooks/*.sh` → `/hooks` xác nhận → mở session MỚI (hooks load lúc start). Ngoài 5 hook trên: Stop gate (script check, block turn-end tới khi pass), prompt-hook (judgment câu chữ), agent-hook (verify multi-turn — production ưu tiên command hooks).

> **Tóm gọn 1 câu:** Cài xong nhớ 3 nhịp: chmod, `/hooks` xác nhận, mở session mới — hook không load lại giữa session như điện không có lại nguồn.

---

## 5. Walkthrough + debug khi hook không chạy

Mục này là "lần đầu tiên đặt tay": cài hook đầu tiên trong 10 phút, rồi flowchart 7 bước để cứu hook im lặng. Đọc khi hook vừa cài mà không thấy nó chạy — chuyện gần như chắc chắn xảy ra ít nhất một lần.

**Thêm hook đầu tiên (10 phút):**

```text
1. mkdir -p .claude/hooks + copy hook 2 (block-main-push.sh)
2. chmod +x .claude/hooks/block-main-push.sh
3. Thêm vào .claude/settings.json (mục 4, PreToolUse Bash)
4. /hooks → xác nhận hiện; mở session MỚI
5. Test: prompt "chạy git push origin main" → phải BLOCKED
6. Test lọt: "git push -f", "--force", "--force-with-lease", "git push origin HEAD:main" → cả 4 phải block
```

**Debug flowchart — hook không chạy:**

```text
Hook không chạy?
├─ 1. /hooks có hiện hook?          Không → settings.json sai path/JSON parse lỗi → claude doctor, sửa, mở session mới
├─ 2. Event đúng?                   Muốn block phải PreToolUse, không phải Post
├─ 3. Matcher đúng case?            "edit" ≠ "Edit", "bash" ≠ "Bash"
├─ 4. Folder đã trust?              Frontmatter hooks project-level cần trust dialog; -p session không trusted → bị skip
├─ 5. Script +x + shebang?          chmod +x; test tay: echo '<json>' | ./hook.sh
├─ 6. Nhiều hooks overlap?          2 hook cùng rewrite updatedInput → finish cuối thắng. Tách matcher
└─ 7. Muốn nới nhưng vẫn deny?      Hook allow KHÔNG nới được deny/org ask — hooks chỉ siết (bài 10)
```

> 📄 **Code ví dụ:** [`examples/08-5-walkthrough-debug-khi-hook-khong-chay.sh`](examples/08-5-walkthrough-debug-khi-hook-khong-chay.sh)

Nhờ Claude viết hook: "Viết hook chạy eslint sau mỗi lần edit file .ts" — Claude sửa settings.json, bạn `/hooks` duyệt lại. Đối xử hooks như production code (chạy với quyền của bạn, đọc FS + network + ghi disk) — coi như giao chìa khóa nhà cho người lạ: phải biết rõ người đó là ai.

> **Tóm gọn 1 câu:** Cài hook xong mà nó im lặng thì đi từng bước flowchart 7 bước từ trên xuống — 90% là sai path, sai event hoặc sai chữ hoa chữ thường của matcher.

---

## 6. Bẫy, bài tập, link

Mục này là kho "vết thương đã lành": mấy hiểu nhầm và bẫy cấu hình mà người trước đã dẫm. Đọc để không phải tự va một lần nữa.

### Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật |
|---|---|
| "Hook tốn tokens như gọi LLM" | `command` hooks chạy shell ngoài model → 0 tokens. Chỉ `prompt`/`agent` hooks tốn |
| "Hook allow nới được deny" | Không — hooks chỉ siết, không nới (bài 10) |
| "Rules settings.json đủ chặn, khỏi hook" | Rules prefix-match lọt `HEAD:main`, `-f` chen giữa, binary khác. Chắc chắn → hook match theo intent |
| "Matcher không phân biệt hoa thường" | Có phân biệt — sai case là hook im lặng |
| "Hook thay được OS sandbox" | Hook vẫn bypass được qua binary lạ. Critical → hook + sandbox + deny rules (bài 10) |

> **Cách đọc bảng này:** cột trái là lời đồn trong team, cột phải là sự thật đã kiểm chứng — nếu bạn đang tin cột trái, hãy đọc kỹ bản fix ở cột phải trước khi viết hook tiếp.

### Bẫy cấu hình + fix

| Bẫy | Fix |
|---|---|
| Hook `.sh` báo permission denied | `chmod +x .claude/hooks/*.sh` (file từ Windows mất +x) |
| Chạy local nhưng không chạy cloud | Commit `.claude/hooks/` + dùng `${CLAUDE_PROJECT_DIR}` |
| Lint hook chậm 8s mỗi edit | Scope hẹp: chỉ file từ stdin, chỉ ext liên quan |
| 2 hooks cùng rewrite → non-deterministic | Mỗi rewrite 1 owner; còn lại chỉ read/block |
| Stop gate block mãi không thoát | Tối đa 8 blocks rồi override — nhưng fix script gốc |
| Prompt-hook tốn token bất ngờ | Chỉ dùng `prompt` khi regex không làm được |

> **Cách đọc bảng này:** cột "Bẫy" là hiện tượng gặp trên máy, cột "Fix" là việc xử lý — tra đúng dòng đang dính như tra mã lỗi, không cần đọc hết.

### Bài tập

1. (15') Cài hook 2 (branch-protect); test 4 lệnh push, ghi lại cái nào lọt.
2. (15') Cài hook 1 (lint-on-write); sửa 1 file `.ts` sai lint, xem Claude tự fix; >2s → thu hẹp scope.
3. (15') Cài hook 5 (session-context); session mới kiểm tra context có branch.
4. (20') Viết 1 prompt-hook ("commit message có leak secret?"); so token cost vs command-hook.
5. (15') Chạy debug flowchart cho 1 hook cấu hình sai cố ý (matcher thường); ghi lại bước bắt được lỗi.

> **Tóm gọn 1 câu:** Học hook bằng tay: cài branch-protect, cài lint-on-write, rồi cố ý làm hỏng một hook để flowchart 7 bước bắt lỗi cho bạn.

### Link chéo

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: hooks 0 token; **[03 — CLAUDE.md](./03-claude-md-memory-rules.md)**: advisory vs law.
- **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: `/hooks`, `/doctor` audit hooks chậm; **[05 — Skills](./05-skills-custom-commands.md)**: skill dạy "làm thế nào", hook bắt "phải làm".
- **[06 — Subagents](./06-subagents-agent-teams-parallel.md)**: SubagentStart/Stop hooks; **[10 — Permissions](./10-permissions-modes-availability.md)**: hook deny thắng bypass, hook allow không nới org; **[12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md)**: Setup hook cho CI warmup.
