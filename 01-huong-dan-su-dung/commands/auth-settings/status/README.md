# /status — Bảng đồng hồ: là ai, model gì, ở đâu, tốn bao nhiêu

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ đọc — lệnh an toàn nhất, gõ bao nhiêu lần cũng được)

`/status` hiện snapshot 1 màn hình: account + plan, model đang chạy, working dir + roots, cache hit, session dài bao nhiêu, token/quota đã dùng, version CLI. Hiểu `/status` là hiểu "nhìn đồng hồ taplo" — đầu session 3 giây, sau mỗi `/cd`/`teleport`/`login` 1 lần, khỏi lái mù.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/status` | _(không có)_ | Hiện full snapshot (dạng mặc định, khuyên dùng) |
| `/status --short` | flag | 1 dòng gọn (để nhét vào prompt/script) |
| `/status --quota` | flag | Chỉ xem quota/billing (đã dùng bao nhiêu, còn bao nhiêu) |
| `/status --json` | flag | Xuất JSON (script/CI parse) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: đầu session — nhìn 1 phát biết hết
/status
# → Account: ban@congty.vn (Team) · Model: default · cwd: /repo/packages/api
# → Roots: api (loaded) · Cache: 84% hit · Session: 47 msg · Tokens: 132k/200k
```

```bash
# Dạng 2: gọn để kiểm tra nhanh giữa việc
/status --short
# → "work · default · /repo/api · cache 84% · 132k tokens"
```

```bash
# Dạng 3: cuối tháng xem tiền
/status --quota
# → "Plan Team · Used 78% (156/200M) · resets in 6 days"
```

```bash
# Dạng 4: cho script (báo động quota vào Slack)
/status --json
# → {"account": "...", "model": "...", "cwd": "...", "tokens_used": 132000, ...}
```

---

## Cách nó hoạt động

### Cơ chế sâu: status đọc và hiển thị những gì?

1. **Account (đang là ai?):**
   - Đọc token profile active (`~/.claude/accounts/`): mail, plan (Free/Pro/Team/Enterprise), org (nếu SSO). Sai acc ở đây là mọi việc sau sai quota/policy — nên đây là dòng đầu tiên phải đọc.
2. **Model (đang chạy gì?):**
   - Model session hiện tại + fallback + thinking budget. Đổi trong `/config` mà session cũ chưa nhận? Status hiện model THỰC TẾ của session (không phải config mới) — tin status, đừng tin trí nhớ.
3. **Working dir + roots (đang ở đâu?):**
   - `cwd` (từ `/cd`), danh sách roots (từ `/add-dir --list`) + trạng thái config mỗi root: `loaded` (CLAUDE.md đã vào context) hay `files only` (thiếu env flag — xem `/add-dir`).
   - Đây là cách rẻ nhất phát hiện "tưởng ở api hoá ra ở root" hoặc "add-dir rồi mà chưa loaded".
4. **Cache (tiết kiệm được bao nhiêu?):**
   - `cache hit %`: phần prompt tái dùng từ cache (không tính tiền full). Mới `/cd` sang repo lạ mà hit 20%? Bình thường 1 lần đầu. Làm 1 chỗ ổn định mà hit vẫn thấp? CLAUDE.md có thể phình/mâu thuẫn (gọi `/doctor`).
5. **Session (nặng bao nhiêu?):**
   - Số message, tokens tích luỹ, tuổi session. Session 200+ message + hit thấp = nên `/compact` hoặc `/clear` (context dài vừa đắt vừa loạn).
6. **Quota/billing (còn bao nhiêu?):**
   - Đã dùng/định mức theo plan, ngày reset. Team: còn hiện ai dùng nhiều (để khỏi "cuối tháng hết quota không biết tại ai").
7. **Version + runtime:**
   - CLI version (đủ mới để có Cd rules ≥2.1.169 / Tab ≥2.1.206 chưa?), provider (Claude trực tiếp hay Bedrock/Vertex), region (sau teleport), device pair (mobile gì đang gắn).

### Snapshot mẫu giải mã từng dòng

```text
Account:  ban@congty.vn (Team, org: congty)   ← đúng người đúng org? (sai → /login lại)
Model:    default (fallback: fast)             ← session thực tế (khác config mới? → /clear để nhận)
cwd:      /repo/packages/api                  ← đang đứng đâu (sai → /cd)
Roots:    api (loaded) · shared (files only!) ← shared chưa load luật (→ env flag, xem /add-dir)
Cache:    84% hit                             ← tốt. <50% kéo dài → /doctor xem CLAUDE.md
Session:  47 msg · 132k tokens · 2h12m        ← dài rồi, cân nhắc /compact
Quota:    78% (156/200M) · reset 6 days       ← cuối tháng co chừng
CLI:      v2.1.2xx · provider: claude · eu-west ← đủ mới? region đúng?
Devices:  iphone-15 (online)                  ← có device lạ không? (→ /mobile --revoke)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Hiện gì? | Đổi gì? | Dùng khi nào? |
|---|---|---|---|
| `/status` | Tất cả (snapshot) | Không đổi gì | Kiểm tra, tần suất cao |
| `/login --status` | Chỉ account | Không | Chỉ quan tâm là ai |
| `/config --json` | Config tĩnh (file) | Không (flag này) | Debug config nào thắng |
| `/statusline` | Thanh trạng thái thường trực | Đổi cách hiện | Muốn status ngắn luôn trên màn hình |

> Quy tắc ngón tay cái:
>
> - **`/status` là phản xạ: đầu session, sau teleport/cd/login, trước việc nguy hiểm. 3 giây nhìn taplo, khỏi lái mù.**

---

## Ví dụ thực tế

### Kịch bản 1: Đầu ngày — 3 giây biết hôm nay lái xe gì

```bash
/status
# → Account: personal?! (tưởng work)
# → Hôm qua vọc side-project quên đổi. Đổi ngay trước khi động vào code công ty:
# /login --account work  (hoặc /config account → switch default)
# /status → "work ✓" mới bắt đầu
```

> Kết quả: 2 lần status cứu cả ngày chạy nhầm quota/policy. Đắt nhất không phải token — là chạy lộn acc.

### Kịch bản 2: Sau teleport — máy mới có gì khác?

```bash
# Vừa /teleport local về laptop nhà:
/status
# → Account: work ✓ (cùng acc là pair được)
# → cwd: /repo/packages/api ✓ (giữ chỗ đứng)
# → Roots: api (loaded) · shared (files only!) ← shared chưa load luật!
# → CLI: v2.1.1xx (cũ hơn máy công ty — Tab gợi ý chưa có!)
# → Region: us-east (máy công ty eu-west — data residency? hỏi lead)

# Fix ngay: update CLI, bật env flag cho shared, xác nhận region với team
```

> Kết quả: status sau teleport là checklist "máy mới khác gì". Không status mà chạy ngay là đánh bạc.

### Kịch bản 3: Session ì ạch — status chỉ ra nên compact

```bash
# Claude trả lời ngày càng lan man, chậm:
/status
# → Session: 214 msg · 480k tokens · Cache: 31% hit
# → Chẩn đoán: context quá dài + hit thấp (lạc đề nhiều, cache vỡ)
/compact
# → gọn lại, hit lên 80%+, trả lời sắc lại
```

> Kết quả: đừng chịu đựng session béo — status cho số liệu để quyết compact/clear đúng lúc.

### Kịch bản 4: Cuối tháng — quota team ai ngốn?

```bash
/status --quota
# → "Team 96% (192/200M) · reset in 2 days · top: ban (41%), linh (22%)..."
# → 2 ngày cuối: chuyển task nặng sang Pro cá nhân hoặc chờ reset
# → Đặt cảnh báo: script cron /status --json → Slack khi >85%
```

```bash
# Script cảnh báo quota (cho vào cron mỗi sáng):
/status --json | python3 -c "import json,sys; d=json.load(sys.stdin); print('QUOTA WARNING' if d.get('quota_pct',0)>85 else 'OK')"
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Không bao giờ status, chạy mù cả ngày | Nhầm acc/nhầm dir/nhầm model — sai từ dòng đầu | Phản xạ: đầu session + sau mọi lệnh chuyển trạng thái |
| `--json` lộ vào log CI công khai | JSON chứa mail/org (metadata nhạy cảm) | Che khi share; CI private mới log full |
| Tin config mới mà không tin status | Đổi model/config tưởng áp ngay, hoá ra session cũ giữ cũ | Status hiện THỰC TẾ session — khác config mới thì `/clear`/session mới |
| Quota 95% vẫn cố chạy task nặng | Giữa chừng hết quota, task đứt | `--quota` trước task lớn cuối chu kỳ; dời hoặc đổi acc |

### Tốn token?

- Không. Status đọc file local + 1 API nhẹ (quota). Gõ 100 lần cũng không tốn tiền.

### Version / provider

- `--json`/`--quota`/`--short`: v2.x. Bản cũ chỉ snapshot text cơ bản.
- Bedrock/Vertex: mục quota hiện theo vendor (credits/requests thay vì tokens plan).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| Mọi lệnh chuyển trạng thái + `/status` | Sau login/teleport/cd/add-dir | Chuyển → status xác minh |
| `/status` + `/compact` | Session béo | Status chẩn đoán → compact chữa |
| `/status` + `/config` | Status thấy sai → config sửa | Hiện tượng → nguyên nhân |
| `/status --json` + cron/Slack | Cảnh báo quota team | Script hoá, khỏi canh tay |
| `/status` + `/statusline` | Muốn taplo thường trực | Status thủ công → statusline tự động |

Workflow chuẩn "phản xạ status (không tốn gì)":

```bash
# Đầu session:        /status        (3 giây: đúng acc? đúng dir? quota còn?)
# Sau /cd, /add-dir:  /status        (loaded chưa? cache bao nhiêu?)
# Sau /teleport:      /status        (máy mới khác gì?)
# Trước task nguy hiểm:/status --quota (hết quota giữa chừng thì dở)
# Session ì ạch:      /status        (béo? hit thấp? → compact/clear)
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Status hiện acc cũ sau khi login mới | Session giữ auth snapshot, chưa reload | Session mới (hoặc `/clear`) để nhận acc mới; kiểm tra `/config account` default |
| `Roots: X (files only)` dù đã add-dir | Thiếu env flag cho CLAUDE.md dir phụ | Xem `/add-dir` (bật flag → remove + add lại) |
| Cache hit thấp kéo dài 1 chỗ | CLAUDE.md phình/mâu thuẫn, context loạn | `/doctor claude-md` rồi tách/trim |
| `--quota` khác số trên web | Cache quota (delay vài phút) hoặc nhiều org | Đợi 5 phút; kiểm tra đúng org trên web chưa |
| Version cũ không có `--json` | CLI chưa update | Update CLI; tạm dùng snapshot text đọc mắt |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../config/README.md](../../auth-settings/config/README.md) — sửa cái status chỉ ra là sai
  - [../login/README.md](../../auth-settings/login/README.md) — sai acc thì login lại
  - [../cd/README.md](../../auth-settings/cd/README.md) — sai dir thì cd lại
  - [../add-dir/README.md](../../auth-settings/add-dir/README.md) — files-only thì xử ở đây
  - [../statusline/README.md](../../auth-settings/statusline/README.md) — taplo thường trực thay vì gõ tay
  - [../mobile/README.md](../../auth-settings/mobile/README.md) — xem status từ điện thoại
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md) — account và provider
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — status mỗi bề mặt khác gì
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — policy/org hiện trên status

> Mẹo 1 dòng: _`/status` rẻ nhất trong mọi lệnh — gõ nó nhiều hơn gõ bất kỳ lệnh nào khác._
