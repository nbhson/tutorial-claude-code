# FAQ 03 — Permissions & Modes

> Nhóm Phanh & Chế độ · 10 câu hỏi deep-dive · Đọc xong dựng phanh 3 lớp, xoay modes không sợ, headless không kẹt deny

Mỗi câu có giải thích + config/lệnh copy-paste + ví dụ + khi nào áp dụng.

---

## Bảng tổng hợp: allow / ask / deny + 3 files + 5 modes

| Khái niệm | Tóm tắt 1 dòng | Xem ở đâu |
|---|---|---|
| `allow` | Được chạy luôn, không hỏi | `/permissions` |
| `ask` | Hỏi từng lần (mặc định cho sửa/xoá/chạy) | `/permissions` |
| `deny` | Cấm luôn, hook allow cũng không nới được | `/permissions` merged |
| Project settings `.claude/settings.json` | Share team, commit git | Team baseline |
| Local settings `.claude/settings.local.json` | Cá nhân, không commit | Sở thích + allowlist riêng |
| Managed policy (org) | Admin ép, thắng mọi cái local | Team/Enterprise |
| `default` | Hỏi như thường | Shift+Tab lần 1 |
| `acceptEdits` | Tự sửa file, lệnh vẫn hỏi | Việc sửa nhiều, chạy ít |
| `plan` | Chỉ đọc + trình plan, không sửa | Task lớn, duyệt trước |
| `auto` | Tự chạy nhiều hơn (tùy bản) | Cloud + task tin cậy |
| `bypassPermissions` | Bỏ hỏi (chỉ CI sandbox) | Không dùng máy dev |

Thứ tự merge (thắng dần): **defaults < project < local < managed**. Managed deny mà local allow → allow vô ích.

---

## 1. allow / ask / deny viết ở đâu? (`/permissions` alias `/allowed-tools`)

**Giải thích.** Đừng đoán file nào đang thắng — mở `/permissions` xem merged view. Alias cũ `/allowed-tools` vẫn chạy.

3 files:

- `.claude/settings.json` — team baseline, commit git (VD: deny `rm -rf`, deny `.env`).
- `.claude/settings.local.json` — cá nhân (VD: bạn hay dùng `pnpm`, allow thêm), không commit.
- Managed policy — org ép từ xa (VD: cấm `curl ... | bash`), local không gỡ được.

**Config copy-paste (baseline Node, team dùng chung):**

```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(npm test:*)", "Bash(npm run lint:*)", "Bash(git status:*)", "Bash(git diff:*)"],
    "ask": ["Edit", "Write", "Bash(npm install:*)", "Bash(git push:*)"],
    "deny": ["Bash(rm -rf:*)", "Bash(sudo:*)", "Read(.env)", "Read(.env.*)", "Bash(curl * | bash:*)"]
  }
}
```

**Ví dụ:** PR nào xóa mất `deny rm -rf` → `/doctor permissions` báo đỏ + CI chặn merge (xem FAQ 01 câu 8).

**Khi nào áp dụng:** setup repo mới + mỗi khi permission deny liên tục mà không hiểu vì sao → `/permissions` trước.

---

## 2. Shift+Tab xoay modes thế nào? (5 modes: default → acceptEdits → plan → auto → bypass)

**Giải thích.** Bấm Shift+Tab để xoay vòng, không cần nhớ lệnh. Mỗi mode là 1 "mức tin tưởng":

```text
default ── hỏi như thường (làm task lạ)
acceptEdits ── tự sửa file, lệnh nguy hiểm vẫn hỏi (refactor nhiều file)
plan ── chỉ đọc + trình plan, KHÔNG sửa (task lớn, muốn duyệt trước)
auto ── tự chạy nhiều hơn (task tin cậy; cloud hay dùng)
bypassPermissions ── bỏ hỏi TẤT CẢ (CHỈ CI sandbox, KHÔNG máy dev)
```

**Lệnh copy-paste:**

```bash
# Trong session: bấm Shift+Tab để xoay, hoặc gõ:
/plan    # vào plan mode (đọc + trình plan)
```

**Ví dụ:** task "refactor auth 20 files" → vào `plan` trước, duyệt plan 5 phút, rồi sang `acceptEdits` cho chạy. Đừng vào `acceptEdits` ngay với task chưa hiểu.

**Khi nào áp dụng:** task càng lớn/càng lạ → mode càng chặt (plan). Task nhỏ/quen → nới dần.

---

## 3. Cloud có Bypass không? (Không — chỉ Accept edits / Plan, Auto tùy bản)

**Giải thích.** Cloud session KHÔNG có `bypassPermissions`. Chỉ có Accept edits (tự sửa + push branch) và Plan (chờ duyệt), `/Auto` tùy bản. Đây là thiết kế an toàn: cloud chạy xa tay bạn, bypass là tự sát.

```text
Máy dev:  default → acceptEdits → plan → auto → bypass (đủ 5)
Cloud:    acceptEdits / plan (/auto tùy bản). KHÔNG bypass.
```

**Khi nào áp dụng:** viết CI/cloud script mà định dùng `--permission-mode bypassPermissions` → đổi sang `dontAsk` + allowlist rõ (xem FAQ 10). Đừng cố bypass trên cloud, không có đâu.

---

## 4. Hook vs permission rule — ai thắng? (`PreToolUse` deny thắng cả bypass)

**Giải thích.** Đây là câu quan trọng nhất file này:

- **`PreToolUse` hook deny THẮNG TẤT CẢ**, kể cả `bypassPermissions`. Hook là phanh tay độc lập.
- **Hook allow KHÔNG nới được** deny của settings hay `ask` của org. Hooks chỉ siết thêm, không nới lỏng.
- Permission rule deny cũng thắng bypass? Không — bypass bỏ qua permission hỏi, nhưng KHÔNG bỏ qua hook deny và org `ask` cho connectors/MCP nhạy cảm.

Bảng ai thắng ai:

| Cặp đấu | Ai thắng? |
|---|---|
| Hook deny vs `bypassPermissions` | Hook deny thắng |
| Hook allow vs settings deny | Settings deny thắng (allow vô ích) |
| Hook allow vs org `ask` | Org `ask` thắng |
| Managed deny vs local allow | Managed thắng |
| Permission allow vs `ask` mặc định | Allow thắng (trong cùng level) |

**Config copy-paste (phanh không bypass được):**

```bash
# scripts/guard-no-push-main.sh — chặn push main dù bypass
#!/bin/bash
input=$(cat)
echo "$input" | grep -q '"command": *"git push.*main' && echo '{"decision":"block","reason":"Cấm push main"}' && exit 0
echo '{"decision":"approve"}'
```

```json
{ "hooks": { "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "./scripts/guard-no-push-main.sh" }] }] } }
```

**Khi nào áp dụng:** việc critical (push main, xóa DB, gửi tiền) → hook deny + settings deny cả hai. Đừng tin mỗi permission rule.

---

## 5. Rules (permission strings) có chặn được lệnh lách (binary khác,绕行) không?

**Giải thích.** Không chắc. Permission rules là match chuỗi lệnh, không phải shell security parser. Kẻ cố tình (hoặc model ngáo) có thể lách bằng binary khác, đường dẫn khác, encode khác:

```text
deny "Bash(rm -rf:*)"  →  lách bằng `rm -R -f`, `python -c 'shutil.rmtree(...)'`, `./my-rm.sh`
deny "Read(.env)"      →  lách bằng `cat .env` qua Bash, `cp .env /tmp/x`
```

**Fix:** việc critical → hook kiểm tra sâu + OS sandbox (container, user riêng, filesystem read-only), không trông chờ mỗi rule chuỗi.

**Config copy-paste:**

```json
{
  "permissions": {
    "deny": ["Bash(rm -rf:*)", "Bash(sudo:*)", "Read(.env)", "Read(.env.*)", "Read(*secret*)", "Read(*credential*)"]
  }
}
```

```bash
# + sandbox OS cho CI (song song với rules):
# chạy agent trong container không có quyền sudo, mount secrets read-only-off
```

**Khi nào áp dụng:** rule chặn "người ngay" (model làm đúng nhưng hỏi cho chắc). Chặn "kẻ gian" (lách cố ý) → hook + sandbox.

---

## 6. Background subagent bị deny trong `-p` (headless) — vì sao và fix?

**Giải thích.** `-p` (non-interactive) không hiện prompt hỏi → mọi `ask` thành deny. Hooks vẫn chạy cho tool calls của nó, nhưng không có "hook decision" thay người bấm Yes. Kết quả: subagent kẹt deny hàng loạt.

**Fix — thiết kế hooks + allowlist headless-friendly:**

```bash
# Chạy CI: pre-approve read-only + lệnh窄, mode dontAsk
claude -p "review PR" --permission-mode dontAsk \
  --allowedTools "Read,Grep,Glob,Bash" \
  --output-format json
```

```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(git status:*)", "Bash(git diff:*)", "Bash(npm test:*)"],
    "deny": ["Bash(rm -rf:*)", "Bash(sudo:*)", "Read(.env)"]
  }
}
```

**Ví dụ:** background agent cần `git push` → headless deny (vì `ask`). Fix: hoặc allow rõ `Bash(git push origin feat/*:*)`, hoặc tách bước push ra cho người bấm tay.

**Khi nào áp dụng:** mọi `-p` / background / CI — luôn chạy thử với allowlist rõ trước khi schedule.

---

## 7. Frontmatter hooks của project subagent không chạy — vì sao? (trust)

**Giải thích.** Subagent file trong project (`.claude/agents/x.md`) có thể kèm frontmatter hooks. Nhưng hooks đó chỉ chạy khi **workspace được trust** (dialog "trust this folder" lúc mở). `-p` không tính là trusted → skip + log, không báo ầm ĩ nên dễ tưởng "hook hỏng".

Ngoại lệ chạy luôn:

- User-level agents (`~/.claude/agents/`) — máy bạn, tin sẵn.
- `--agents` inline JSON — bạn gõ tay, tin luôn.

**Lệnh copy-paste:**

```bash
/agents        # xem agents + hooks kèm theo
# Mở lại folder trong IDE/terminal → hiện dialog trust → Accept
# Chạy lại, check log xem hook đã lửa chưa
```

**Ví dụ:** hook format của agent `reviewer` chạy ngon trên máy bạn (đã trust) nhưng im re trên CI (`-p`) → đúng thiết kế. CI thì viết hook ở settings CI, đừng trông chờ frontmatter hooks project.

**Khi nào áp dụng:** hook agent "lúc chạy lúc không" → check trust đầu tiên (xem thêm FAQ 05).

---

## 8. Thiết kế allowlist cho headless (`-p`) thế nào cho không kẹt?

**Giải thích.** Nguyên tắc: allow RÕ từng lệnh cần, deny RÕ từng cái cấm, còn lại để hỏi (mà headless = deny). Đừng `allow Bash(*)` cho gọn — đó là mở toang.

**Config copy-paste (CI review an toàn):**

```bash
claude -p "review diff" \
  --permission-mode dontAsk \
  --allowedTools "Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(npm test:*)" \
  --output-format json
```

```bash
# Background subagent research (read-only tuyệt đối):
claude -p "quét auth flow" \
  --permission-mode dontAsk \
  --allowedTools "Read Grep Glob" \
  --output-format json
```

**Khi nào áp dụng:** mọi script `-p`. Test tay 1 lần với đúng allowlist đó trước khi gắn vào cron/CI.

---

## 9. 3 settings files merge thế nào? (xem merged, đừng đoán)

**Giải thích.** Thứ tự merge: defaults → project (`settings.json`) → local (`settings.local.json`) → managed (org). Cùng 1 key thì sau thắng trước, NHƯNG managed deny/org ask luôn thắng local allow.

**Lệnh copy-paste:**

```bash
/permissions    # XEM MERGED TẠI ĐÂY, đừng mở từng file đoán
cat .claude/settings.json
cat .claude/settings.local.json 2>/dev/null
```

**Ví dụ:** local bạn `allow Bash(curl:*)` nhưng managed deny → `/permissions` hiện deny → đừng mất 30 phút debug "sao allow rồi vẫn hỏi". Hỏi admin org.

**Khi nào áp dụng:** mỗi khi "allow rồi mà vẫn deny" — 90% là managed/org thắng.

---

## 10. Khi nào dùng `--dangerously-skip-permissions`? (gần như không)

**Giải thích.** Chỉ CI sandbox cô lập (container dùng 1 lần, không secrets thật, không network ra ngoài). Trên máy dev và cloud session bình thường: KHÔNG. Hook deny vẫn thắng flag này, nhưng permission hỏi thì bỏ hết — 1 lệnh `rm -rf` ngáo là đi cả máy.

```bash
# ✅ CI sandbox dùng 1 lần:
claude -p "migrate test" --dangerously-skip-permissions

# ❌ Máy dev / cloud session: KHÔNG BAO GIỜ
```

Chi tiết xem [FAQ 09](09-bao-mat-quyen-rieng-tu.md).

---

## Vẫn lỗi thì sao? (permissions/modes)

1. `/permissions` — xem merged rules (deny ẩn? managed thắng?).
2. `/hooks` — có hook deny nào chặn không (hook thắng bypass).
3. `/status` — version cũ? provider nào? (mode Auto có tùy bản).
4. Trust dialog — frontmatter hooks project cần trust folder.
5. `/debug` — session vẫn lạ → chẩn đoán sâu.

```bash
/permissions
/hooks
/debug
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/permissions/README.md](../01-huong-dan-su-dung/commands/permissions/README.md) — xem/sửa merged rules
  - [../01-huong-dan-su-dung/commands/hooks/README.md](../01-huong-dan-su-dung/commands/hooks/README.md) — xem hooks đang chặn gì
  - [../01-huong-dan-su-dung/commands/plan/README.md](../01-huong-dan-su-dung/commands/plan/README.md) — vào plan mode
  - [../01-huong-dan-su-dung/commands/status/README.md](../01-huong-dan-su-dung/commands/status/README.md) — xem version/provider
  - [../01-huong-dan-su-dung/commands/debug/README.md](../01-huong-dan-su-dung/commands/debug/README.md) — chẩn đoán session lạ
  - [../01-huong-dan-su-dung/commands/sandbox/README.md](../01-huong-dan-su-dung/commands/sandbox/README.md) — sandbox OS cho việc nguy hiểm
- Bài tổng quan:
  - [../01-huong-dan-su-dung/10-permissions-modes-availability.md](../01-huong-dan-su-dung/10-permissions-modes-availability.md) — modes + availability theo provider
  - [../01-huong-dan-su-dung/07-hooks-tu-dong-hoa.md](../01-huong-dan-su-dung/07-hooks-tu-dong-hoa.md) — hook deny thắng bypass
  - [../02-tips-thuc-chien/06-hooks-recipes.md](../02-tips-thuc-chien/06-hooks-recipes.md) — công thức guard thực tế
- FAQ liên quan: [FAQ 05](05-hooks-faq.md) (hooks debug), [FAQ 09](09-bao-mat-quyen-rieng-tu.md) (bảo mật), [FAQ 10](10-ci-sdk-routines-web.md) (CI headless).

> Mẹo 1 dòng: _merged xem ở /permissions, hook deny thắng bypass, và bypass chỉ sống trong CI sandbox._
