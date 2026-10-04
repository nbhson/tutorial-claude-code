# FAQ 05 — Hooks: Vì Sao Không Chạy?

> Nhóm Hooks & Tự động hóa · 11 câu hỏi deep-dive · Đọc xong tự debug 7 bệnh hook hay gặp, phân biệt 4 loại hook, viết hook sống được qua update version

Mỗi câu có giải thích + config/lệnh copy-paste + ví dụ + khi nào áp dụng.

---

## Bảng tổng hợp: 4 loại hook + debug nhanh

| Loại hook | Chạy ở đâu | Tốn gì | Dùng khi nào |
|---|---|---|---|
| Command (shell script) | Máy bạn, deterministic | 0 model tokens, vài ms–s | Production ưu tiên (lint, guard, format) |
| Prompt (LLM 1-turn, Haiku default) | Model chấm 1 lượt | Ít tokens (Haiku) | Cần judgment từ input (prompt có risky?) |
| Agent (experimental, 60s/50 turns) | Subagent verify | Nhiều tokens | Verify cần đọc code/chạy lệnh |
| HTTP / MCP-tool | Ngoài (webhook/service) | Network | Tích hợp hệ ngoài (ticket, audit log) |

| Hook không lửa → check | Lệnh |
|---|---|
| Đúng event chưa? | `/hooks` xem theo tool events |
| Matcher đúng case chưa? | `Edit` ≠ `edit`, `Bash` ≠ `bash` |
| Folder trusted chưa? | Mở lại folder → trust dialog |
| Headless (`-p`) có cần prompt? | Thiết kế headless, không prompt |
| Version đổi schema? | `/status` + release notes |

---

## 1. Xem hooks đang có ở đâu? (`/hooks` theo tool events)

**Giải thích.** `/hooks` liệt kê hooks theo từng tool event (PreToolUse, PostToolUse, Stop, SessionStart, UserPromptSubmit...), kèm matcher + command. Đây là "bảng điện" — hook không lửa thì nhìn đây đầu tiên.

```bash
/hooks    # xem tất cả hooks theo events
```

**Ví dụ:** tưởng đã có guard push-main nhưng `/hooks` không hiện PreToolUse/Bash nào → config sai file (VD: viết vào `settings.local.json` mẫu khác) hoặc JSON parse lỗi.

**Khi nào áp dụng:** luôn là bước 1 khi debug hook.

---

## 2. Hook không lửa — check event đúng chưa? (Pre vs Post vs Stop...)

**Giải thích.** Bệnh #1: gắn nhầm event. Bản đồ nhanh:

| Muốn | Event đúng | Gắn nhầm hay gặp |
|---|---|---|
| Chặn trước khi chạy | `PreToolUse` | Gắn `PostToolUse` (chạy xong mới check = muộn) |
| Check/sửa sau khi chạy | `PostToolUse` | Gắn `PreToolUse` (chưa có output để check) |
| Gate khi Claude xong | `Stop` | Tưởng lửa khi user interrupt (không lửa) |
| Chạy đầu session | `SessionStart` | Tưởng lửa mỗi prompt (chỉ 1 lần) |
| Check prompt user | `UserPromptSubmit` | Tưởng chặn được tool (chỉ thấy prompt) |

**Config copy-paste (chặn push main — phải PreToolUse):**

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "./scripts/guard-no-push-main.sh" }] }]
  }
}
```

**Khi nào áp dụng:** hook "chạy nhưng không kịp chặn" → 90% nhầm Pre/Post.

---

## 3. Matcher đúng case chưa? (`Edit` ≠ `edit`, `Bash` ≠ `bash`)

**Giải thích.** Bệnh #2, nhỏ mà hay gặp nhất. Matcher phải đúng tên tool viết hoa: `Edit`, `Write`, `Bash`, `Read`... Ghi `edit`, `bash` thường → không khớp → im re, không báo lỗi.

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "./scripts/guard-secret.sh" }] },
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "./scripts/guard-shell.sh" }] }
    ]
  }
}
```

**Test copy-paste:**

```bash
# Dry-run hook tay với stdin mẫu:
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | ./scripts/guard-no-push-main.sh
# → phải ra {"decision":"block",...}. Không ra → script hỏng, không phải matcher.
```

**Khi nào áp dụng:** hook im re tuyệt đối (không log, không lỗi) → soi matcher trước.

---

## 4. Folder trusted chưa? (frontmatter hooks cần trust dialog)

**Giải thích.** Bệnh #3. Hooks kèm trong project files (frontmatter của subagent/skill) chỉ chạy khi workspace được **trust** (dialog lúc mở folder). Chưa trust → skip + log mờ, dễ tưởng hỏng. `-p` headless không tính trusted (xem FAQ 03 câu 7).

```bash
/agents    # xem agents + hooks kèm
# Mở folder trong terminal/IDE → hiện "trust this folder?" → Accept → chạy lại
```

**Ví dụ:** hook format của agent chạy trên máy bạn (đã trust) nhưng im trên máy đồng nghiệp (bấm Deny trust lúc mở) → đúng 1 nguyên nhân này.

**Khi nào áp dụng:** hook "máy tôi chạy, máy khác không" → hỏi trust trước khi sửa code.

---

## 5. Chạy headless (`-p`/background) có gì cần prompt không?

**Giải thích.** Bệnh #4. Headless không có người bấm Yes/No. Hook nào `read -p`, mở editor, gọi OAuth browser → treo tới timeout rồi fail mờ.

Quy tắc hook headless-safe:

```bash
#!/bin/bash
# ✅ Đọc stdin, in JSON, thoát. Không prompt, không mở UI.
input=$(cat)
echo "$input" | grep -q 'rm -rf' && echo '{"decision":"block","reason":"deny rm-rf"}' && exit 0
echo '{"decision":"approve"}'
```

```bash
# ❌ TRONG HOOK: read -p "chắc không?"; vim file; open browser...
```

**Khi nào áp dụng:** mọi hook sẽ chạy trong `-p`/background/CI → test bằng pipe stdin tay (câu 3), không test bằng tay gõ.

---

## 6. 2 hooks cùng sửa `updatedInput` — ai thắng? (thằng finish cuối, non-deterministic)

**Giải thích.** Bệnh #5. `PreToolUse` hooks có thể trả `updatedInput` (sửa input tool trước khi chạy). 2 hooks cùng sửa → thằng finish CUỐI thắng, mà thứ tự finish không đảm bảo → non-deterministic. Hôm nay sửa đúng, mai sửa sai.

**Fix:** đừng để overlap. 1 matcher → 1 hook sửa input. Các hooks còn lại chỉ approve/block, không sửa.

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit", "hooks": [{ "type": "command", "command": "./scripts/normalize-edit.sh" }] }
    ]
  }
}
```

```text
✅ 1 hook sửa Edit-input + 1 hook block Bash-nguy-hiểm (khác matcher, không clash)
❌ 2 hooks cùng rewrite Bash command (clash, thắng thua hên xui)
```

**Khi nào áp dụng:** thiết kế hook rewrite input — luôn đếm "mỗi matcher mấy thằng sửa".

---

## 7. Stop hook có lửa khi user interrupt? (Không — interrupt không lửa, API error lửa `StopFailure`)

**Giải thích.** Bệnh #6 (hiểu nhầm lifecycle):

- `Stop` = Claude tự xong response → lửa.
- User bấm Esc/Ctrl-C (interrupt) → **không lửa** Stop. Muốn bắt interrupt thì dùng cơ chế khác (session-end/cleanup ngoài).
- API error giữa chừng → lửa `StopFailure` (event riêng), không phải `Stop`.

```json
{
  "hooks": {
    "Stop": [{ "hooks": [{ "type": "command", "command": "./scripts/verify-done.sh" }] }],
    "StopFailure": [{ "hooks": [{ "type": "command", "command": "./scripts/report-failure.sh" }] }]
  }
}
```

**Ví dụ:** Stop-gate "chưa test xanh không được dừng" bị qua mặt bằng Esc → đúng thiết kế. Đừng trông chờ Stop-hook chống interrupt.

**Khi nào áp dụng:** viết gate "xong việc" — luôn handle cả `StopFailure` + chấp nhận interrupt là đường thoát của user.

---

## 8. Stop-gate bị override sau 8 blocks liên tiếp — thiết kế sao cho hội tụ?

**Giải thích.** Bệnh #7. Sau **8 blocks liên tiếp**, Claude được override để thoát (chống treo vô hạn). Nên gate "không bao giờ cho dừng trừ khi X" mà X không bao giờ đạt được → tới block thứ 8 là tuột.

Thiết kế gate HỘI TỤ (fix được) thay vì gate VÔ HẠN:

```bash
#!/bin/bash
# ✅ verify-done.sh: mỗi block kèm hướng fix cụ thể, đếm lần
# Lần 1-3: "test đỏ file X → chạy npm test -- X"
# Lần 4+: nới điều kiện (VD: cho dừng nếu chỉ còn style warnings)
```

```text
❌ "Chưa hoàn hảo thì block" (không bao giờ đạt → override ở block 8)
✅ "Test đỏ thì block + chỉ rõ file; quá 5 lần thì cho qua với warning" (hội tụ)
```

**Khi nào áp dụng:** mọi Stop-gate chặn CI push/merge — luôn có đường "cho qua có điều kiện" trước block 8.

---

## 9. Prompt-hook vs agent-hook vs command-hook — chọn sao? (command trước)

**Giải thích.** 4 loại, thứ tự ưu tiên production:

1. **Command (shell) — ưu tiên #1:** deterministic, nhanh, 0 tokens, test được bằng pipe. Mọi guard/lint/format dùng loại này.
2. **Prompt (LLM 1-turn, Haiku default):** khi cần *judgment* từ input mà regex không viết nổi (VD: "prompt này có ý định xóa DB không?"). Tốn ít tokens.
3. **Agent (experimental, 60s/50 turns trần):** verify cần đọc code + chạy lệnh (VD: "đọc diff, chạy test liên quan, kết luận"). Đắt, chỉ gate quan trọng.
4. **HTTP/MCP-tool:** tích hợp ngoài (ghi audit log, gọi policy service).

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "./scripts/guard.sh" }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "prompt", "prompt": "Prompt này có yêu cầu xóa/ghi đè không backup? Trả lời block/approve." }] }]
  }
}
```

**Khi nào áp dụng:** viết được bằng shell → command. Không viết nổi bằng regex → prompt. Cần đọc code/chạy lệnh → agent.

---

## 10. Hook chạy với quyền gì? (quyền của bạn — review như production code)

**Giải thích.** Hook shell chạy với quyền user của bạn: đọc FS, gọi network, ghi disk. Hook độc = RCE trá hình. Chỉ cài từ nguồn tin cậy, đọc script trước khi enable, nhất là plugin community (bundle cả hooks + MCP + skills).

```bash
# Trước khi cài plugin/skill lạ có hooks:
# 1. Đọc scripts hooks
ls .claude/hooks/ && cat .claude/hooks/*.sh
# 2. Check hook làm gì: curl? rm? ghi ngoài repo?
git grep -E 'curl|rm -rf|sudo|chmod \+x' -- .claude/hooks/
# 3. Chỉ trust nguồn quen
```

**Khi nào áp dụng:** mọi lần cài plugin/skill/agent lạ. Xem thêm [FAQ 09](09-bao-mat-quyen-rieng-tu.md).

---

## 11. Hook API đổi theo version (2025–2026) — chống drift sao?

**Giải thích.** Hook API từng đổi: `tools` frontmatter, PreToolUse stdin schema... Hook chặn CI push mà viết theo schema cũ → fail mờ sau update. Quy tắc: trước khi đặt hook chặn việc quan trọng, đối chiếu release notes với version đang chạy.

```bash
# Trong session:
/status          # version đang chạy
/hooks           # hooks còn lửa không sau update
```

```bash
# Sau mỗi claude update:
claude update && claude --version
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./scripts/guard-shell.sh
```

**Ví dụ:** update lên bản đổi stdin schema → guard cũ parse sai → approve hết (mở toang) hoặc block hết (kẹt). Test dry-run sau update bắt được ngay.

**Khi nào áp dụng:** sau MỖI `claude update` + trước khi gắn hook vào CI gate.

---

## Vẫn lỗi thì sao? (hooks)

1. `/hooks` — hooks có listed không (config load chưa?).
2. Dry-run pipe stdin mẫu (câu 3) — script sống không.
3. Check matcher case + event (câu 2–3).
4. Check trust folder (câu 4) + headless-safe (câu 5).
5. `/status` + release notes — version drift (câu 11).
6. `/debug` — session vẫn lạ → chẩn đoán sâu.

```bash
/hooks
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | ./scripts/guard-no-push-main.sh
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md) — xem/sửa hooks theo events
  - [../01-huong-dan-su-dung/commands/auth-settings/status/README.md](../01-huong-dan-su-dung/commands/auth-settings/status/README.md) — version đang chạy (drift?)
  - [../01-huong-dan-su-dung/commands/model-mode/permissions/README.md](../01-huong-dan-su-dung/commands/model-mode/permissions/README.md) — hook deny vs permission ai thắng
  - [../01-huong-dan-su-dung/commands/knowledge-system/debug/README.md](../01-huong-dan-su-dung/commands/knowledge-system/debug/README.md) — chẩn đoán hook im re
  - [../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md](../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md) — frontmatter hooks của agents
- Bài tổng quan:
  - [../01-huong-dan-su-dung/07-hooks-tu-dong-hoa.md](../01-huong-dan-su-dung/07-hooks-tu-dong-hoa.md) — events + schema chi tiết
  - [../01-huong-dan-su-dung/10-permissions-modes-availability.md](../01-huong-dan-su-dung/10-permissions-modes-availability.md) — hook vs rule vs bypass
  - [../02-tips-thuc-chien/06-hooks-recipes.md](../02-tips-thuc-chien/06-hooks-recipes.md) — công thức guard/format/verify
- FAQ liên quan: [FAQ 03](03-permissions-modes.md) (hook vs rule), [FAQ 09](09-bao-mat-quyen-rieng-tu.md) (review hooks lạ).

> Mẹo 1 dòng: _không lửa thì check event → matcher case → trust → headless → version, và Stop-gate luôn thiết kế để hội tụ trước block 8._
