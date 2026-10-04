# FAQ 09 — Bảo Mật & Quyền Riêng Tư

> Nhóm Security & Privacy · 10 câu hỏi deep-dive · Đọc xong khóa working dirs, giấu secrets, hiểu ZDR, review supply-chain, không bao giờ bypass trên máy dev

Mỗi câu có giải thích + lệnh/config copy-paste + ví dụ + khi nào áp dụng.

---

## Bảng tổng hợp: 7 lớp phòng thủ

| Lớp | Chặn gì | Lệnh/config | Bypass được? |
|---|---|---|---|
| Working dirs (`--add-dir`) | Đọc ngoài thư mục cho phép | `/permissions` xem dirs | Không (không add thì không chạm) |
| Permission deny rules | Lệnh/file nguy hiểm | `deny` trong settings | Bypass bỏ qua (trừ org) |
| `PreToolUse` hook deny | Việc critical | Script guard | **KHÔNG — thắng cả bypass** |
| Org `ask` (connectors/MCP nhạy cảm) | Exfil qua MCP | Managed policy | **KHÔNG — hook allow không nới được** |
| Secrets qua env | Lộ token vào git | `${VAR}` + `git grep` check | — (kỷ luật + CI check) |
| ZDR / provider telemetry | Data gửi về vendor | Contract + provider docs | Hỏi admin, đừng đoán |
| Supply-chain (skills/plugins/hooks) | Code độc trá hình | Đọc trước khi cài | — (review tay) |
| Review AI code + tests | Code sai/độc lọt vào | fresh-reviewer + `/verify` + human | — (luôn làm) |

---

## 1. Claude Code có đọc hết máy tôi không? (working dirs + `--add-dir`)

**Giải thích.** Không — nó chỉ chạm **working dirs được phép** (+ thêm bằng `--add-dir`). Quản lý ở `/permissions` (mục working directories). Đừng `bypassPermissions` trên máy dev, đừng `add-dir` cả home khi không cần.

```bash
/permissions    # xem working dirs hiện tại
```

```bash
# Chỉ mở rộng khi cần, hẹp nhất có thể:
claude --add-dir ../shared-contracts
# ❌ claude --add-dir ~   (mở cả home cho 1 task nhỏ)
```

**Ví dụ:** task chỉ cần `api/` mà mở cả repo + home → 1 lệnh ngáo `grep -r` quét secrets khắp máy. Hẹp dirs = giảm blast radius.

**Khi nào áp dụng:** mỗi session lạ/repo lạ → `/permissions` check dirs trước khi cho chạy.

---

## 2. Deny nào không bypass được? (hook deny + deny rules + org ask)

**Giải thích.** 3 thứ sống sót qua `--dangerously-skip-permissions`:

1. **`PreToolUse` hook deny** — thắng cả bypass (FAQ 03 câu 4).
2. **Deny rules + org `ask` cho connectors/MCP nhạy cảm** — hooks/rules siết thêm, không nới được.
3. Managed policy của org — local không gỡ.

```bash
# Guard mẫu sống qua bypass:
#!/bin/bash
input=$(cat)
echo "$input" | grep -qE 'rm -rf|sudo ' && echo '{"decision":"block","reason":"critical blocked even with bypass"}' && exit 0
echo '{"decision":"approve"}'
```

**Ví dụ:** CI sandbox bypass mà vẫn muốn cấm `push main` → hook deny (sống) + settings deny (chết khi bypass). Luôn đặt hook cho việc critical.

**Khi nào áp dụng:** thiết kế phanh cho CI/cloud — critical thì hook, đừng tin mỗi rule.

---

## 3. Secrets trong MCP/settings: env vars + `reset-project-choices`?

**Giải thích.** Chỉ qua env vars (`${TOKEN}`), không commit token vào `.mcp.json`/settings. Khi đổi approvals/policy project → `reset-project-choices` để xóa lựa chọn cũ (tránh approvals cũ còn hiệu lực).

```json
{
  "mcpServers": {
    "github": { "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" } }
  }
}
```

```bash
export GITHUB_TOKEN="ghp_xxx"
git grep -E 'ghp_|sk-ant_|xoxb-|lin_' -- .mcp.json .claude/  # phải RỖNG
claude mcp reset-project-choices   # khi đổi approvals project
```

**Ví dụ:** onboard member → họ export env của họ, approvals project reset → không ai dùng ké token người cũ.

**Khi nào áp dụng:** mọi lần add server + rotate token + đổi policy. Gắn `git grep` vào CI (xem FAQ 10).

---

## 4. Zero Data Retention (ZDR) — ai được, hỏi ai?

**Giải thích.** ZDR có cho: **Enterprise qualified (Sub) / qualified Console accounts / AWS Platform qualified** — hỏi admin/contract của bạn, đừng đoán từ blog. Mặc định telemetry/error-reporting theo provider: Bedrock/GCP/Foundry/AWS-Platform **tắt gửi về Anthropic theo default** (xem provider docs để xác nhận — default có thể đổi theo version).

```bash
# Checklist trước khi cam kết với khách hàng:
# 1. Hỏi admin: contract có ZDR không? scope (prompts? outputs? errors?)
# 2. Đọc provider docs hiện tại (Bedrock/GCP/Foundry trang data-handling)
# 3. /status xem provider đang dùng thật là gì
/status
```

**Ví dụ:** team Bedrock mặc định không gửi về Anthropic — nhưng error-reporting bật ở client vẫn gửi crash log → tắt nếu contract yêu cầu.

**Khi nào áp dụng:** hợp đồng yêu cầu "không lưu data" → xác nhận bằng văn bản admin + docs, không tin trí nhớ.

---

## 5. Skills / plugins / hooks có nguy hiểm không? (supply-chain — có)

**Giải thích.** Có — chúng chạy code/quyết định trên máy bạn. Plugin community xin cùng lúc đọc file + chạy shell + gọi mạng = full access. Chỉ cài nguồn tin cậy, đọc **Browse** (commands/knowledge-system/agents/skills/hooks/MCP) trước khi cài plugin; review scripts hooks như production code.

```bash
# Trước khi cài plugin lạ:
/plugin    # mở Browse, đọc: commands? agents? skills? hooks? MCP? permissions xin gì?
# Plugin xin (Read + Bash(*) + network) mà việc chỉ là "format" → KHÔNG CÀI
```

```bash
# Sau khi cài, rà nhanh:
ls .claude/hooks/ && cat .claude/hooks/*.sh
git grep -E 'curl|rm -rf|sudo|exfil|ngrok' -- .claude/
```

**Ví dụ:** plugin "theme đẹp" kèm hook PostToolUse gửi file đã sửa về URL lạ → supply-chain exfil. Đọc Browse 2 phút bắt được.

**Khi nào áp dụng:** mọi lần cài plugin/skill/agent từ ngoài team.

---

## 6. Review code AI viết thế nào? (fresh-reviewer + `/code-review` + human + tests)

**Giải thích.** Đối xử output AI như code của **intern giỏi nhưng cần giám sát**. Pipeline 4 lớp:

1. **Fresh-reviewer subagent** (không thấy history → không bị "tự bênh").
2. **`/code-review`** (PR vừa) hoặc **`/ultrareview`** sandbox (PR lớn/security).
3. **Human** đọc diff cuối (nhất là auth, tiền, migrate).
4. **Tests xanh** (`/verify` chạy app thật, không tin model nói "xong").

```bash
# "Dùng fresh subagent review diff này, chỉ báo security + sai logic, bỏ qua style"
/code-review
/verify
npm test
```

**Khi nào áp dụng:** mọi code AI viết trước khi merge. PR càng critical → càng đủ 4 lớp.

---

## 7. `--dangerously-skip-permissions` khi nào? (chỉ CI sandbox cô lập)

**Giải thích.** Chỉ CI sandbox cô lập (container dùng 1 lần, không secrets thật, không network ra ngoài). Trên máy dev/cloud session bình thường: **không**. Hook deny vẫn thắng flag này, nhưng mọi permission hỏi thì bỏ hết.

```bash
# ✅ Sandbox dùng 1 lần, không secrets thật:
claude -p "migrate test" --dangerously-skip-permissions

# ❌ Máy dev / cloud / máy có .env thật: KHÔNG BAO GIỜ
# Thay bằng: --permission-mode dontAsk + allowlist hẹp (FAQ 10)
```

**Khi nào áp dụng:** gần như không. Nếu thấy mình gõ flag này trên máy dev → dừng, chuyển sang allowlist.

---

## 8. Telemetry / error-reporting tắt ở đâu? (theo provider)

**Giải thích.** Mặc định theo provider (Bedrock/GCP/Foundry/AWS-Platform tắt gửi về Anthropic theo default). Client vẫn có telemetry/error-reporting riêng — đọc provider docs + settings hiện tại, đừng đoán.

```bash
/status          # provider đang dùng?
/config          # xem telemetry/error-reporting settings
claude doctor    # có cảnh báo config lạ không
```

**Khi nào áp dụng:** onboard enterprise/compliance + sau mỗi `claude update` (default có thể đổi).

---

## 9. Lộ secret rồi — xử lý sao? (rotate + reset + rà git history)

**Giải thích.** Secret đã commit là coi như lộ (git history giữ mãi). Xử lý 4 bước:

```bash
# 1. Rotate NGAY (vô hiệu token cũ) — làm trước, dọn sau
# 2. Xóa approvals/project choices cũ:
claude mcp reset-project-choices
# 3. Rà còn sót:
git grep -E 'ghp_|sk-ant_|xoxb-|AKIA' -- .mcp.json .claude/ .
# 4. Dọn history (nếu đã push): BFG/filter-repo + force-push + báo team rotate tiếp
```

**Ví dụ:** commit nhầm `GITHUB_TOKEN` vào `.mcp.json` → rotate token trên GitHub trước (30s), rồi mới dọn git. Làm ngược (dọn git trước) → token sống thêm 10 phút trong tay crawler.

**Khi nào áp dụng:** ngay khi phát hiện. Rotate trước, dọn sau, luôn.

---

## 10. Checklist bảo mật repo mới (5 phút)?

**Giải thích.** Chạy checklist này cho mọi repo trước khi cho Claude động tay:

```bash
/permissions              # 1. dirs hẹp? deny rm-rf/sudo/.env có?
git grep -E 'ghp_|sk-ant_' -- .mcp.json .claude/   # 2. secrets sạch?
/mcp                     # 3. servers thừa? tắt cái không dùng
/hooks                   # 4. hooks lạ? đọc scripts
/doctor                  # 5. điểm security? đỏ thì vá trước
```

```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(npm test:*)", "Bash(npm run lint:*)", "Bash(git status:*)", "Bash(git diff:*)"],
    "ask": ["Edit", "Write", "Bash(npm install:*)", "Bash(git push:*)"],
    "deny": ["Bash(rm -rf:*)", "Bash(sudo:*)", "Read(.env)", "Read(.env.*)"]
  }
}
```

**Khi nào áp dụng:** setup repo mới + mỗi tháng 1 lần + trước khi onboard member.

---

## Vẫn lỗi thì sao? (bảo mật)

1. Nghi lộ secret → rotate trước, dọn sau (câu 9).
2. Deny không ăn → `/permissions` merged + `/hooks` (hook nào allow nhầm?).
3. Plugin/skill lạ → gỡ + rà `git grep` + `reset-project-choices`.
4. ZDR/compliance → hỏi admin + provider docs, đừng tự kết luận.
5. `/debug` → lạ thì chẩn đoán; `/bug` kèm `/status` + `doctor`.

```bash
git grep -E 'ghp_|sk-ant_|xoxb-|AKIA' -- . .
/permissions
/hooks
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/model-mode/permissions/README.md](../01-huong-dan-su-dung/commands/model-mode/permissions/README.md) — working dirs + allow/ask/deny
  - [../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md) — hook deny không bypass được
  - [../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) — secrets-env + reset-project-choices
  - [../01-huong-dan-su-dung/commands/knowledge-system/plugin/README.md](../01-huong-dan-su-dung/commands/knowledge-system/plugin/README.md) — Browse trước khi cài
  - [../01-huong-dan-su-dung/commands/code-repo/code-review/README.md](../01-huong-dan-su-dung/commands/code-repo/code-review/README.md) — review AI code
  - [../01-huong-dan-su-dung/commands/code-repo/verify/README.md](../01-huong-dan-su-dung/commands/code-repo/verify/README.md) — chạy app thật kiểm chứng
  - [../01-huong-dan-su-dung/commands/auth-settings/sandbox/README.md](../01-huong-dan-su-dung/commands/auth-settings/sandbox/README.md) — sandbox OS cho việc nguy hiểm
- Bài tổng quan:
  - [../01-huong-dan-su-dung/10-permissions-modes-availability.md](../01-huong-dan-su-dung/10-permissions-modes-availability.md) — modes + unbypassable
  - [../01-huong-dan-su-dung/09-plugins-marketplaces.md](../01-huong-dan-su-dung/09-plugins-marketplaces.md) — supply-chain plugins
  - [../02-tips-thuc-chien/04-verification-done-that.md](../02-tips-thuc-chien/04-verification-done-that.md) — verify như production
- FAQ liên quan: [FAQ 03](03-permissions-modes.md) (phanh), [FAQ 05](05-hooks-faq.md) (review hooks), [FAQ 10](10-ci-sdk-routines-web.md) (CI an toàn).

> Mẹo 1 dòng: _dirs hẹp, secrets qua env, critical thì hook deny, và bypass không bao giờ rời sandbox._
