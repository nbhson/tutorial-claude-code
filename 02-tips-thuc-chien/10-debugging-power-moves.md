# Tips 10 — Debug Claude Code theo 4 lớp từ ngoài vào trong + phím tắt ít người biết

> **Bài này cho ai:** dev hay thấy Claude "tự dưng dở đi", prompt không chạy, hoặc đang thoát tình trạng "dở thì đổi model" mà vẫn đoán mò.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); đọc [Tips 06 — hooks](./06-hooks-recipes.md) và [Tips 08 — token/cost](./08-tiet-kiem-cost-token.md) trước thì vào L3/L2 nhanh hơn.
> **Đọc xong bạn làm được:**
> - Debug được "Claude dở" theo 4 lớp L1→L4 (setup → context/tiền → hooks/MCP/permissions → debug/bug) trong ~10 phút, không đoán mò.
> - Xử được các ca hỏng thật: push bị block oan, session chậm + lan man, subagent chạy mãi không về.
> - Dùng được phím tắt + thủ thuật đáng nhớ (`Shift+Tab`, Double-Esc, `Ctrl+X Ctrl+K`, `/btw`...) và tránh 9 cái bẫy người dùng nâng cao vẫn dính.
> **Thời gian:** ~30 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Debug theo lớp L1→L4 | Khám từ ngoài vào trong, rẻ trước đắt sau — như khám bệnh: hỏi triệu chứng → đo huyết áp → X-quang → hội chẩn | L1 `/status`+`/doctor`, L2 `/context`+`/cost`+`/usage`, L3 `/hooks`+`/mcp`+`/permissions`, L4 `/debug`+`/bug` |
| Kill switch subagents | Nút ngắt điện khi fan-out chập | `Ctrl+X Ctrl+K` ×2 trong 3s → `/agents` hết job nền |
| Statusline + `/btw` | Đồng hồ xăng (statusline) + hỏi thầm không ghi sổ (`/btw`) | `/statusline` hiện `sonnet · 42%`; `/btw hàm X làm gì?` |
| Hook | Script Claude tự chạy đúng thời điểm để chặn hoặc bắt buộc quy tắc | `PostToolUse` chặn `git push` sai branch — `/hooks` thấy nó |
| Context | Bộ nhớ tạm của phiên — hết chỗ là model lẫn, quên rule | `/context` chỉ 82% toàn log test cũ |

---

## 1. Vì sao quan tâm: debug theo 4 lớp, không đoán mò

Đừng hỏi "sao Claude ngu đi?" — hãy hỏi "tắc ở lớp nào?" Đi từ ngoài vào trong, rẻ trước đắt sau:

```text
L1: /status (version/model/account) → /doctor (setup) → claude doctor (ngoài terminal)
L2: /context + /cost + /usage (context? tiền? ai ngốn?)
L3: /hooks + /mcp + /permissions (hook/mcp/rule nào chặn?)
L4: /debug (troubleshoot session) → /bug (gửi Anthropic)
```

> Quy tắc: **chưa qua L1–L3 thì chưa được kết luận "model dở".** 80% ca "model dở" là context bẩn, hook chặn nhầm, hoặc nhầm model/effort. Giống khám bệnh: chưa đo huyết áp mà đã đòi chụp MRI là phí tiền của cả hai bên.

**Before:** đoán mò đổi model, cãi 5 turns — context 82% + hook chặn nhầm + MCP đỏ vẫn y nguyên, bill vọt. **After:** `/status` (haiku → `/model sonnet`) → `/context` (76% → `/compact` giữ plan, bỏ 2 logs) → `/hooks` (test-gate full 4p → `TEST_SCOPE=auth`) → `/mcp` (github đỏ → disable tạm).

> **Tóm gọn 1 câu:** Debug là đi 4 lớp từ rẻ tới đắt — qua hết L1–L3 mà vẫn lỗi thì mới được nghi model, đó là luật.

---

## 2. L1: setup (status/doctor)

Mục này là lớp khám đầu tiên: version, model, account — 3 thứ sai thì mọi thứ sau sai theo, mà check chỉ mất 10 giây.

### `/status`: mình đang là ai, ở đâu?

> 📄 **Code ví dụ:** [`examples/01-status-minh-ang-la-ai-o-au.sh`](examples/01-status-minh-ang-la-ai-o-au.sh)

- Version quá cũ → lệnh mới (`/batch`, `/ultrareview`) báo unknown. Update: `claude update` (nguyên tắc **update trước, debug sau**).
- Model nhầm (tưởng opus mà đang haiku) → chất lượng khác hẳn. Đổi: `/model`. Cwd/branch nhầm (tưởng repo A mà đang repo B) → mọi đọc file sai: `pwd` + `git branch --show-current`.

### `/doctor` + `claude doctor`: khám tổng quát

> 📄 **Code ví dụ:** [`examples/02-doctor-claude-doctor-kham-tong-quat.sh`](examples/02-doctor-claude-doctor-kham-tong-quat.sh)

Khám định kỳ: chụp output `/status` + `/doctor` + `claude doctor`, sửa theo thứ tự doctor báo (đỏ trước, vàng sau).

---

## 3. L2: context + tiền (context/cost/usage)

Mục này là lớp khám thứ hai: khi setup không có vấn đề, "Claude dở đi" hay bill vọt thường nằm ở context đầy hoặc một hạng mục nào đó đang ngốn — 3 lệnh dưới đây soi ra cả hai.

### `/context`: RAM còn bao nhiêu?

> 📄 **Code ví dụ:** [`examples/03-context-ram-con-bao-nhieu.sh`](examples/03-context-ram-con-bao-nhieu.sh)

- >70% → `/compact` có focus hoặc `/clear` + nạp `plan.md` ([Tips 01](./01-context-hygiene.md)).
- Ngốn vì 1 subagent explore 40 files → lần sau scope hẹp + output contract ([Tips 05](./05-parallel-agents.md)).

### `/cost` + `/usage`: tiền + kẻ ngốn

> 📄 **Code ví dụ:** [`examples/04-cost-usage-tien-ke-ngon.sh`](examples/04-cost-usage-tien-ke-ngon.sh)

- Bill vọt sau fan-out → kiểm tra spawn lồng (subagent spawn subagent).
- 1 MCP ngốn 20K mà tuần này không cần → `/mcp` tắt tạm ([Tips 08](./08-tiet-kiem-cost-token.md)).

---

## 4. L3: hooks + MCP + permissions (cái gì chặn?)

Khi tool "lặng lẽ không chạy" hoặc bị block oan, 90% ở lớp này.

> 📄 **Code ví dụ:** [`examples/05-4-l3-hooks-mcp-permissions-cai-gi-chan.sh`](examples/05-4-l3-hooks-mcp-permissions-cai-gi-chan.sh)

Debug sâu hơn: xem ca 1 mục 6 (chạy script tay với stdin JSON mẫu để thấy regex sai) và đo `time ./hooks/test-gate.sh` — >5s thì focus scope (`TEST_SCOPE`) hoặc cache. MCP: disable từng server đỏ rồi thử lại lệnh fail.

---

## 5. L4: debug session + gửi bug

Mục này là lớp cuối cùng của thang khám: khi L1–L3 đều sạch mà lỗi vẫn còn, mới tới lượt chẩn đoán session sâu (`/debug`) và gửi bug cho Anthropic (`/bug`).

> 📄 **Code ví dụ:** [`examples/06-5-l4-debug-session-gui-bug.sh`](examples/06-5-l4-debug-session-gui-bug.sh)

Khi nào lên L4: đã qua L1–L3 mà mọi thứ "trông đúng" vẫn fail → `/debug`; nghi bug của Claude Code (không phải repo bạn) → `/export` + `/bug` với repro tối thiểu (trước đó thử terminal mới + session mới để loại trừ context bẩn).

---

## 6. Ví dụ copy-paste: 3 ca cứu nhanh

Mục này là 3 "vụ án mẫu" đi đúng thang L1→L4 ở trên: push bị chặn oan (L3 hook), session chậm (L2 context), subagent mất tích (L3/L4) — mỗi ca dán được vào session là chạy.

### Ca 1 — Push bị block oan (`feat/my-main-fix` không push được)

> 📄 **Code ví dụ:** [`examples/07-ca-1-push-bi-block-oan-feat-my.sh`](examples/07-ca-1-push-bi-block-oan-feat-my.sh)

### Ca 2 — Session bỗng chậm + trả lời lan man

> 📄 **Code ví dụ:** [`examples/08-ca-2-session-bong-cham-tra-loi-lan.sh`](examples/08-ca-2-session-bong-cham-tra-loi-lan.sh)

### Ca 3 — Subagent chạy mãi không về

> 📄 **Code ví dụ:** [`examples/09-ca-3-subagent-chay-mai-khong-ve.sh`](examples/09-ca-3-subagent-chay-mai-khong-ve.sh)

> Ghi mỗi ca đã xử vào team log (1 dòng: nguyên nhân + fix) — lần sau 2 phút là ra.

> **Tóm gọn 1 câu:** Ba ca trên chứng minh cùng một điều: đi đúng lớp từ rẻ tới đắt thì ca nào cũng dừng ở "lỗi config của mình" trước khi kịp nghi model.

---

## 7. Phím tắt & thủ thuật nhỏ đáng tiền

Mục này là túi "công cụ đa năng" của người dùng lâu năm — mỗi phím một việc, thuộc được cái nào thì tiết kiệm được chừng đó giây mỗi ngày.

| Phím/lệnh | Tác dụng | Khi dùng |
|---|---|---|
| `Shift+Tab` | Xoay permission modes: `auto` → acceptEdits → plan → bypass (`auto` là mode mặc định cho session mới trên Pro/Max/Team từ w32/2026) | Vào plan mode không cần `/plan` |
| `Double-Esc` (prompt rỗng) | Rewind menu (code + conversation) | Correct 2 lần vẫn sai → rewind, đừng cãi |
| `Ctrl+X Ctrl+K` ×2/3s | Kill all background subagents | Fan-out sai, con nền loop |
| `/btw <q>` | Hỏi nhanh, full context + no tools, không pollute history | Thắc mắc giữa implement |
| `/teleport` | Resume remote (claude.ai) session | Chuyển máy/về nhà làm tiếp |
| `/export` | Xuất conversation ra text để share/debug | Trước `/clear`, trước `/bug` |
| `/resume` / `/rewind` | Mở lại session cũ (picker) / quay checkpoint | Clear nhầm, hôm sau làm tiếp |
| `/clear` / `/compact` | Reset trắng / nén giữ tóm tắt | Đổi task / cùng task đầy RAM |
| `/doctor` / `/debug` / `/bug` | Khám setup / troubleshoot / gửi Anthropic | L1/L4 |

> **Cách đọc bảng này:** cột "Tác dụng" nói phím này làm gì, cột "Khi dùng" là tình huống gợi nhớ — học thuộc theo cột phải (tình huống) thì lúc cần mới nhớ ra phím.

> 📄 **Code ví dụ:** [`examples/10-7-phim-tat-thu-thuat-nho-ang-tien.sh`](examples/10-7-phim-tat-thu-thuat-nho-ang-tien.sh)

> **Tóm gọn 1 câu:** 9 phím/lệnh này là dao đa năng của người dùng nâng cao — mỗi cái ít tiền, nhưng dùng thường xuyên là lời khủng.

---

## 8. Bảng tra nhanh: triệu chứng → lớp → lệnh

Mục này là "cuốn sổ bệnh án rút gọn": có triệu chứng, tra ra lớp và lệnh fix, không cần đọc lại cả bài.

| Triệu chứng | Lớp | Lệnh / fix |
|---|---|---|
| `unknown command` | L1 version | `claude --version`, update `claude update` |
| Model trả lời khác hẳn hôm qua | L1 model | `/status` xem model, `/model` đổi lại |
| Trả lời lan man, quên rule | L2 context | `/context` → `/compact` focus hoặc `/clear` + plan |
| Bill vọt 1 ngày | L2 cost | `/usage` tìm kẻ ngốn, `/cost` so baseline |
| Push/edit bị BLOCKED oan | L3 hooks | `/hooks` + chạy script tay (mục 6 ca 1) |
| Tool MCP treo/fail | L3 MCP | `/mcp` disable server đỏ, `/usage` per-server |
| Lệnh cần quyền bị từ chối | L3 permissions | `/permissions` xem rule, không skip-permissions trên dev |
| Subagent mất tích | L3/L4 agents | `/agents`, `/tasks`, kill `Ctrl+X Ctrl+K` |
| Shift+Tab/Enter không ăn | Terminal | `/terminal-setup` theo terminal (iTerm2/VSCode/Kitty...) |

> **Cách đọc bảng này:** cột "Triệu chứng" là chỗ bắt đầu — tìm dòng khớp rồi đi ngang sang "Lớp" (để biết lỗi ở tầng nào) và "Lệnh / fix" (để hành động); không nên nhảy thẳng cột fix mà bỏ qua lớp.

---

## 9. 9 cái bẫy người dùng nâng cao vẫn dính

Mục này là "hồ sơ vụ án" của 9 sai lầm kinh điển — càng rành công cụ, càng dễ dính bẫy dạng tinh vi.

1. **Explore vô hạn ("investigate" không scope).** Đọc 300 files, bill vọt. Fix: scope hẹp + subagent + output contract ([Tips 01](./01-context-hygiene.md)).
2. **Reviewer tự chấm bài mình.** Toàn PASS mù. Fix: luôn fresh reviewer ([Tips 04](./04-verification-done-that.md)).
3. **Hook chặn nhầm vì substring (`main`).** `feat/my-main-fix` oan. Fix: match intent + test 4 ca push ([Tips 06](./06-hooks-recipes.md)).
4. **Tin "should work".** Không log/diff/test. Fix: đòi evidence (L2 verify, [Tips 04](./04-verification-done-that.md)).
5. **Dùng subagent cho việc skill làm được.** Tốn 20K overhead cho việc 500 tokens. Fix: skill trước, subagent sau ([Tips 07](./07-thiet-ke-skills.md)).
6. **Dùng hook cho việc làm 1 lần.** Setup hook 30 phút cho việc nhắc 1 câu là xong. Fix: hook chỉ cho rule lặp + phải đúng 100%.
7. **Thêm MCP khi data đã ở local repo.** Nặng context, chậm. Fix: `Read`/`Grep` local trước, thiếu mới bật MCP.
8. **Skills pile-up: skill load sai lúc.** 20 skills trigger loạn. Fix: thu hẹp description + `/doctor` ([Tips 07](./07-thiet-ke-skills.md)).
9. **Quên cloud ≠ local.** Config/hooks/MCP local không lên cloud (claude.ai). Fix: cấu hình cloud-scope + test trên cloud trước khi tin. **Bonus:** `--dangerously-skip-permissions` chỉ dùng trong CI sandbox, máy dev dùng `/permissions` duyệt.

**Checklist người dùng nâng cao mỗi tuần:** `Shift+Tab` thuộc tay? Double-Esc thay vì cãi quá 2 turns? `Ctrl+X Ctrl+K` như reflex? `/btw` cho hỏi phụ? `/context` + `/cost` mỗi 30–45 phút? Hook nào chặn oan? MCP nào không dùng? Có gì test local mà tưởng cloud có?

> **Tóm gọn 1 câu:** 9 bẫy đều chung gốc: tin vào điều mình chưa kiểm chứng — "should work", cloud có đồ local, hook match được — mỗi tuần tự rà checklist một lần.

---

## 10. Bài tập

- **Bài 1 (15 phút — thuộc phím tắt):** xoay hết vòng `Shift+Tab`, nhớ vị trí `plan`; thử Double-Esc rewind ở session nháp; thử `Ctrl+X Ctrl+K` sau khi spawn 1 subagent test (chạy `/terminal-setup` nếu phím không ăn).
- **Bài 2 (20 phút — debug 4 lớp):** cố tình gây 3 lỗi (branch sai, context 70%+, hook block lệnh legit), debug theo L1→L4, ghi mỗi lỗi mất bao lâu + 1 dòng team log (nguyên nhân + fix).
- **Bài 3 (20 phút — audit 9 cái bẫy):** đối chiếu 9 bẫy với tuần vừa rồi, fix 2 cái dễ nhất (hẹp 1 skill description, sửa 1 hook substring), đặt statusline hiện model + % context.

> Đạt: sau 1 tháng, 80% "Claude dở" bạn tự debug L1–L3 trong 10 phút mà không cần hỏi ai.

---

## 11. Tham khảo chéo

- [../01-huong-dan-su-dung/commands/auth-settings/status/README.md](../01-huong-dan-su-dung/commands/auth-settings/status/README.md) — mình là ai, ở đâu · [../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) — khám setup · [../01-huong-dan-su-dung/commands/session-context/context/README.md](../01-huong-dan-su-dung/commands/session-context/context/README.md) — RAM còn bao nhiêu
- [../01-huong-dan-su-dung/commands/session-context/usage/README.md](../01-huong-dan-su-dung/commands/session-context/usage/README.md) — ai ngốn · [../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) — MCP nào fail · [../01-huong-dan-su-dung/commands/model-mode/permissions/README.md](../01-huong-dan-su-dung/commands/model-mode/permissions/README.md) — rule nào chặn
- [../01-huong-dan-su-dung/commands/knowledge-system/debug/README.md](../01-huong-dan-su-dung/commands/knowledge-system/debug/README.md) — troubleshoot session · [../01-huong-dan-su-dung/commands/session-context/rewind/README.md](../01-huong-dan-su-dung/commands/session-context/rewind/README.md) — quay checkpoint · [../01-huong-dan-su-dung/commands/auth-settings/teleport/README.md](../01-huong-dan-su-dung/commands/auth-settings/teleport/README.md) — resume remote
- [Tips 01](./01-context-hygiene.md) — context bẩn (L2) · [Tips 06](./06-hooks-recipes.md) — hooks chặn nhầm (L3) · [Tips 08](./08-tiet-kiem-cost-token.md) — bill vọt (L2)

> Mẹo 1 dòng: _kẹt thì đi L1→L4 (setup → context/tiền → hooks/MCP/permissions → debug/bug) — đừng đoán, đừng cãi, đừng tin "should work"._
