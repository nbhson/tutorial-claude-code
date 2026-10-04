# /doctor — Khám sức khoẻ repo: CLAUDE.md phình không, thiếu phanh ở đâu

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ đọc + báo cáo; nhưng Có nếu bạn Yes hết mọi đề xuất fix — nhất là trim CLAUDE.md từ bản ≥2.1.206 mà không review)

`/doctor` chạy audit tự động toàn diện: quét CLAUDE.md (dài quá không, mâu thuẫn không), permissions (mở toang không), MCP (server chết không), hooks (lỗi không), plugins (thừa không), skills/agents (rác không)... rồi chấm điểm + gợi ý fix từng cái (bạn duyệt mới sửa). Hiểu `/doctor` là hiểu "bác sĩ tổng quát" gọi mỗi tháng 1 lần.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/doctor` | _(không có)_ | Audit full (mọi hạng mục) + báo cáo + đề xuất fix |
| `/doctor --quick` | flag | Chỉ check nhanh (5 mục cốt lõi, <30s) |
| `/doctor --fix` | flag | Vừa audit vừa auto-fix lỗi an toàn (vẫn hỏi cái nguy hiểm) |
| `/doctor <mục>` | claude-md, permissions, mcp, hooks, plugins | Chỉ audit 1 hạng mục |
| `/doctor --json` | flag | Xuất báo cáo JSON (cho CI) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: khám tổng quát (khuyên dùng mỗi tháng)
/doctor
```

```bash
# Dạng 2: khám nhanh trước khi làm task lớn
/doctor --quick
```

```bash
# Dạng 3: khám + tự sửa lỗi an toàn
/doctor --fix
```

```bash
# Dạng 4: chỉ khám 1 mục (nghi CLAUDE.md phình)
/doctor claude-md
/doctor permissions
/doctor mcp
```

```bash
# Dạng 5: xuất JSON cho CI (chặn merge khi điểm thấp)
# Trong .github/workflows/claude-doctor.yml:
```

```yaml
- run: claude /doctor --json > doctor.json
- run: python3 -c "import json,sys; d=json.load(open('doctor.json')); sys.exit(1 if d['score']<70 else 0)"
```

---

## Cách nó hoạt động

### Cơ chế sâu: doctor audit từng hạng mục gì?

1. **`claude-md` (mục hay đỏ nhất):**
   - Đếm dòng/token: >150 dòng (vàng), >300 dòng (đỏ — tốn 3k+ token/session).
   - Tìm mâu thuẫn: "dùng npm" ở dòng 10 vs "dùng pnpm" ở dòng 200 → báo conflict.
   - Tìm trùng với rules/memory: luật theo thư mục nằm trong CLAUDE.md → gợi ý tách sang `/rules`; sở thích cá nhân → gợi ý chuyển sang `/memory`.
   - Từ bản **≥2.1.206**: có nút `trim` (tự rút gọn bằng AI). TIỆN NHƯNG NGUY HIỂM nếu Yes mù — AI có thể cắt mất luật quan trọng. Luôn review diff trước khi nhận.
2. **`permissions` (mục phanh):**
   - Báo đỏ nếu `allow: ["Bash(*)"]` (mở toang), thiếu deny `rm -rf`/`sudo`/`.env`.
   - So sánh project vs local vs managed: managed deny mà local allow → báo "vô ích, managed thắng".
   - Gợi ý baseline theo stack (Node: allow test/lint; deny publish/push main).
3. **`mcp` (mục kết nối):**
   - Ping từng server: `connected` (xanh) / `auth expired` (vàng) / `dead` (đỏ).
   - Soi `.mcp.json`: hardcode token? (đỏ), dùng `${ENV}`? (xanh).
   - Đếm tools: server 30+ tools mà ít dùng → gợi ý disable cho nhẹ context.
4. **`hooks` (mục phản xạ):**
   - Validate JSON config (sai matcher `Edit,Write` → báo), check file script có tồn tại + `+x` không.
   - Chạy thử khô (dry-run với stdin mẫu): hook crash → báo đỏ + log.
   - Cảnh báo hook không max-vòng (Stop-hook vô hạn) và hook chạy >5s.
5. **`plugins` (mục app store):**
   - Liệt kê enabled/disabled, version pin hay `latest`, có bản mới không.
   - Đếm token ước tính mỗi plugin; plugin 3 tháng không dùng → gợi ý remove/disable.
   - Cảnh báo plugin community xin quyền rộng (đọc file + chạy shell + gọi mạng cùng lúc).
6. **`skills` + `agents`:**
   - Skill không trigger 3 tháng (mô tả mờ) → gợi ý sửa description.
   - Agent custom tools quá rộng vs việc nó làm → gợi ý thu hẹp.
   - File rác (skill trùng nhau, agent 1 chữ) → gợi ý gộp/xoá.
7. **Chấm điểm và báo cáo:**
   - Mỗi mục PASS/WARN/FAIL → điểm tổng /100. ≥85 xanh (khoẻ), 70-84 vàng (có nợ), <70 đỏ (cần chữa).
   - Báo cáo liệt kê theo thứ tự NGUY HIỂM trước (security: secret, bypass) rồi mới tới TIẾT KIỆM (token, gọn).
   - `--fix`: tự sửa lỗi an toàn (thiếu `+x`, matcher sai cú pháp rõ ràng); lỗi cần quyết (trim CLAUDE.md, deny thêm) thì hỏi từng cái.

### Sơ đồ 1 lần khám

```text
/doctor
  ├─ claude-md:    320 dòng (ĐỎ) → gợi ý tách 4 rules + trim (review diff!)
  ├─ permissions:  thiếu deny .env (VÀNG) → gợi ý thêm
  ├─ mcp:          db connected (XANH), github auth expired (VÀNG) → reconnect
  ├─ hooks:       guard.sh OK, lint-stop thiếu max-vòng (VÀNG) → vá
  ├─ plugins:     7 enabled, 3 không dùng 3 tháng (VÀNG) → disable 2
  └─ skills/agents: 1 skill trùng (VÀNG) → gộp
  ↓ Điểm 72/100 (vàng) → duyệt từng fix → khám lại 88/100 (xanh)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Audit gì? | Sửa không? | Dùng khi nào? |
|---|---|---|---|
| `/doctor` | Sức khoẻ CONFIG (md, quyền, mcp, hooks...) | Có (bạn duyệt) | Mỗi tháng / trước task lớn |
| `/debug` | Bệnh SESSION hiện tại (treo, chậm, lạ) | Không (chỉ chẩn đoán + hướng) | Đang làm mà có gì sai sai |
| `/bug` | Gói BUG REPORT gửi Anthropic | Không (thu thập) | Lỗi của chính Claude Code |
| `/verify` | ĐÚNG/SAI của code vừa viết | Không (chỉ chấm) | Sau khi code xong |
| `/stats` | Tiêu bao nhiêu tiền/token | Không (chỉ thống kê) | Cuối tuần nhìn lại chi tiêu |

> Quy tắc ngón tay cái:
>
> - **Config có bệnh → `/doctor`. Session đang bệnh → `/debug`. Code vừa viết → `/verify`. Tool bị bệnh → `/bug`.**

---

## Ví dụ thực tế

### Kịch bản 1: Repo mới tiếp quản — khám tổng trước khi động tay (10 phút)

```bash
# Vừa clone repo người khác để lại, chưa biết gì:
/doctor

# Báo cáo ví dụ:
# 🔴 claude-md: không có CLAUDE.md (0 dòng) → /init tạo mới?
# 🟡 permissions: không có settings.json → dùng mặc định (hỏi nhiều)
# 🟢 mcp: không có server (sạch, khỏi lo)
# 🟡 hooks: không có (khuyên thêm guard + format)
# Điểm 65/100 → duyệt: [Yes] tạo CLAUDE.md, [Yes] thêm baseline permissions
```

> Kết quả: 10 phút có phanh + luật nền, rồi mới code. Không khám mà code là lái xe không phanh.

### Kịch bản 2: CLAUDE.md 320 dòng — tách + trim an toàn (bản ≥2.1.206)

```bash
# Khám riêng mục này:
/doctor claude-md
# → "320 dòng (~3.2k token/session). 4 khối theo thư mục (api/web/migrations/docs).
#    Đề xuất: [1] tách 4 rules [2] trim còn 40 dòng kiến trúc [review diff]"

# Làm theo thứ tự AN TOÀN:
# Bước 1: tách rules trước (không mất chữ nào, chỉ chuyển chỗ)
/rules add api
/rules add web
# → copy từng khối sang file rules tương ứng, XOÁ khỏi CLAUDE.md

# Bước 2: mới trim phần còn lại (review diff kỹ!)
# → doctor hiện diff: giữ/Xoá từng dòng → chỉ Yes khi chắc

# Bước 3: khám lại
/doctor claude-md
# → "45 dòng (XANH). Tiết kiệm ~2.7k token/session."
```

> Cảnh báo: ĐỪNG bấm trim ngay từ đầu khi chưa tách — AI trim cả file 320 dòng dễ cắt mất luật theo thư mục mà rules chưa kịp giữ.

### Kịch bản 3: Permissions mở toang do copy StackOverflow

```bash
/doctor permissions
# → "🔴 allow: ['Bash(*)'] — mở toang shell. 🔴 thiếu deny .env."
# → Đề xuất baseline Node, [Yes] áp dụng?

# Duyệt Yes → settings.json thành:
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

### Kịch bản 4: CI chặn merge khi điểm doctor thấp (team)

```yaml
# .github/workflows/claude-doctor.yml — chạy mỗi PR
- run: claude /doctor --json > doctor.json
- run: |
    python3 -c "
    import json, sys
    d = json.load(open('doctor.json'))
    print(f\"Score: {d['score']}/100\")
    sys.exit(1 if d['score'] < 70 else 0)
    "
# → PR nào xóa mất deny rm -rf là rớt CI, khỏi review tay
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (doctor trim CLAUDE.md ≥2.1.206)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Yes mù khi trim CLAUDE.md (≥2.1.206) | CỰC KỲ HAY GẶP: mất luật quan trọng, model làm sai hàng loạt sau đó | Luôn review diff từng dòng; tách rules TRƯỚC khi trim; git commit trước để rollback |
| `--fix` trong repo lạ | Auto-fix sửa settings bạn chưa hiểu (đổi matcher, thêm deny) | Chạy `/doctor` thường trước, đọc báo cáo; `--fix` chỉ khi đã hiểu |
| Điểm cao = chủ quan | 95/100 nhưng vẫn có secret trong `.mcp.json` (doctor không đọc được env) | Điểm chỉ là heuristic; secret/token tự rà bằng mắt + `git grep` |
| Chạy doctor giữa task dở | Đề xuất `/clear` nạp lại config làm mất context đang làm | Khám khi rảnh (đầu session mới), không khám giữa task gấp |

### Tốn token?

- 1 lần `/doctor` full ≈ 5-15k token (đọc CLAUDE.md + settings + list plugins...). Đắt hơn chat thường.
- Nhưng khám 1 lần/tháng, tiết kiệm hàng trăm k token từ CLAUDE.md gọn + ít vòng lặp sai. Đáng.

### Version / provider

- `/doctor` full 6 mục: bản v2.x. Bản cũ chỉ check CLAUDE.md + permissions.
- Nút `trim` AI: bản **≥2.1.206**. Cũ hơn chỉ báo dài, tự tách tay.
- `--json` cho CI: v2.1+. Bedrock/Vertex: doctor vẫn chạy (audit local, không gọi cloud vendor).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/doctor` + `/rules` | Tách CLAUDE.md phình | Doctor báo → tách rules → khám lại |
| `/doctor` + `/memory` | Chuyển sở thích ra khỏi CLAUDE.md | Doctor chỉ trùng → chuyển sang memory |
| `/doctor` + `/permissions` | Vá phanh mở toang | Doctor gợi baseline → duyệt |
| `/doctor` + `/init` | Repo chưa có gì | Doctor báo thiếu → `/init` sinh mới |
| `/doctor` + `/stats` | Khám xong xem tiết kiệm bao nhiêu | So token/session trước-sau trim |

Workflow chuẩn "dọn nhà mỗi tháng (30 phút)":

```bash
# 1. Khám tổng
/doctor
# 2. Chữa đỏ trước (security: secret, bypass, mở toang)
# 3. Tách rules + trim CLAUDE.md (review diff!)
# 4. Disable plugin/skill 3 tháng không dùng
# 5. Khám lại cho xanh, commit settings mới
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Trim xong model làm sai hàng loạt | Trim cắt mất luật quan trọng | `git checkout .claude/` rollback; tách rules tay rồi trim lại từng phần |
| `/doctor` báo MCP dead dù hôm qua còn chạy | Laptop sleep kill stdio | `/mcp reconnect <tên>` rồi `/doctor mcp` lại |
| Điểm thấp vì "thiếu CLAUDE.md" nhưng repo cố tình không cần | Repo 5 file, doctor heuristic quá đà | Bỏ qua mục đó (không phải lỗi); doctor là gợi ý, không phải luật |
| `--fix` sửa sai matcher hooks | Hiểu nhầm regex custom của bạn | Rollback git; sửa tay; báo issue (kèm `--json`) |
| `/doctor --json` vỡ trong CI | Bản CLI CI cũ, chưa có flag | Pin CLI mới nhất trong CI image |
| Khám mãi không lên điểm | Nợ tích lũy (10 vàng) | Chữa từng mục đỏ trước, vàng để sprint sau; 85+ là đủ sống |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../debug/README.md](../../knowledge-system/debug/README.md) — session đang bệnh (doctor là config bệnh)
  - [../permissions/README.md](../../model-mode/permissions/README.md) — vá phanh theo gợi ý doctor
  - [../rules/README.md](../../knowledge-system/rules/README.md) — nơi chứa phần tách từ CLAUDE.md
  - [../memory/README.md](../../knowledge-system/memory/README.md) — nơi chứa sở thích tách ra
  - [../init/README.md](../../code-repo/init/README.md) — sinh CLAUDE.md khi doctor báo thiếu
  - [../stats/README.md](../../knowledge-system/stats/README.md) — đo tiết kiệm sau khi dọn
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md) — trim/tách thế nào cho đúng
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — dọn skill rác
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md) — dọn agent rác
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md) — vá hooks theo gợi ý
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md) — vá MCP theo gợi ý
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md) — dọn plugin thừa

> Mẹo 1 dòng: _đỏ trước vàng sau, tách rules trước trim sau, và commit trước khi Yes bất kỳ fix nào._
