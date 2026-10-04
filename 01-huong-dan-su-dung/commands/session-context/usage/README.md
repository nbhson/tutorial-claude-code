# /usage — Breakdown tiêu thụ: skill, subagent, plugin, MCP nào đốt token + quota còn bao nhiêu

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ đọc thống kê, không xóa/sửa gì)

`/usage` là "camera giám sát chi tiết": không chỉ cho biết tốn bao nhiêu (như `/cost`), mà cho biết **tốn vào việc gì** — skill nào, subagent nào, plugin nào, MCP server nào — kèm rate limits / quota còn lại.

> Từ v2.1.118: `/usage` gộp từ `/cost` + `/stats` — 1 lệnh xem cả tiền lẫn breakdown, khỏi gõ 3 lệnh.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/usage` | _(không có)_ | Hiện breakdown theo component + rate limits hiện tại |

Không có flag `--by-skill`, `--json`. Muốn tổng tiền thì xem `/cost`.

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem breakdown khi thấy chậm/đắt
/usage
```

```bash
# Dạng 2: cặp với cost để chẩn đoán
/cost
/usage
# → cost cao + usage chỉ vào 1 MCP → thủ phạm là MCP đó
```

```bash
# Dạng 3: kiểm tra quota trước task lớn
/usage
# → thấy weekly quota còn 15% → chia task nhỏ, dùng Sonnet thay vì Opus
```

```bash
# Dạng 4: sau khi chạy agent teams song song
/usage
# → xem 5 subagents mỗi đứa tốn bao nhiêu
```

Output mẫu (minh họa):

```text
Usage breakdown (session):
  Main agent:        320K in / 18K out
  Subagents (3):     410K in / 22K out
    - Explore (2 runs): 250K in
    - Plan (1 run):     160K in
  Skills: frontend-guidelines 45K
  MCP: github 38K (12 calls), postgres 5K (4 calls)
  Plugins: code-review 12K
Rate limits:
  5h session: 62% used, resets 14:30
  Weekly: 38% used
```

---

## Cách nó hoạt động

### Under-the-hood

1. **Gắn tag từng request:**
   - Mỗi lần Claude Code gọi model, nó gắn metadata: request này từ main agent hay subagent nào (`Explore`, `Plan`, custom agent), skill nào đang active, MCP server nào vừa trả output, plugin nào inject context.
2. **Cộng dồn theo tag:**
   - Counters cộng dồn riêng từng tag → bảng breakdown. Nhờ đó bạn thấy "Explore ngốn 250K" chứ không chỉ "tổng 800K".
3. **Hỏi quota từ server:**
   - Với subscription (Pro/Team), client hỏi API quota endpoint để lấy `% 5h / weekly đã dùng + giờ reset`. Với API key pay-as-you-go, phần rate limits có thể trống hoặc hiện HTTP 429 limits.
4. **Không can thiệp:**
   - Read-only, ~0 token. Số liệu từ counters local + 1 call quota nhẹ.

### Đọc bảng thế nào?

- **Subagents >> Main:** bình thường nếu vừa chạy Explore/Plan song song. Bất thường nếu Explore chạy 10 lần vì prompt mơ hồ.
- **1 MCP áp đảo:** ví dụ `github 38K` trong khi `postgres 5K` → GitHub MCP đang trả quá nhiều. Hỏi hẹp hơn.
- **Skills nặng:** skill inject 20K context mỗi lần trigger. Nếu skill trigger nhầm (ví dụ skill frontend kích hoạt khi đang làm backend) → tắt/đổi mô tả skill.
- **5h session 90%:** sắp bị chặn. Dừng task nặng, làm việc nhẹ hoặc chờ reset.

### Khác gì với lệnh dễ nhầm?

| Lệnh | Hỏi gì | Khi nào dùng |
|---|---|---|
| `/usage` | Ai đốt? Còn quota không? | Chẩn đoán + canh quota |
| `/cost` | Tốn bao nhiêu tiền? | Ngân sách, báo cáo |
| `/context` | RAM còn bao nhiêu? | Quyết compact/clear |

> Bộ 3 chẩn đoán: `/context` (RAM) → `/cost` (tiền) → `/usage` (thủ phạm). Gõ cả 3 mất 10 giây mà rõ bệnh.

---

## Ví dụ thực tế

### Kịch bản 1: Explore chạy 5 lần, đốt 500K — do prompt mơ hồ

```bash
# Bạn bảo: "Tìm hiểu codebase giúp tôi" (quá chung chung)
/usage
# → Explore 5 runs, 500K in. Mỗi run đọc cả repo vì không biết trọng tâm.

# Fix: hỏi hẹp + giới hạn
Hãy chỉ explore thư mục src/payments/, trả về tối đa 10 file quan trọng nhất, không đọc tests.
# → /usage lần sau: Explore 1 run, 60K. Tiết kiệm 88%.
```

### Kịch bản 2: GitHub MCP ngốn 40K/call — bóp output

```bash
/usage
# → MCP github: 40K/call (12 calls = 480K!). postgres chỉ 5K.

# Nguyên nhân: mỗi lần hỏi issues, MCP trả cả comments dài
# Fix: giới hạn fields
Hãy lấy 5 issues mới nhất, chỉ title + labels, không lấy comments/body.
# Hoặc tạm tắt MCP khi không cần (xem bài MCP).
```

```bash
# Kiểm tra lại sau fix
/usage
# → github còn 4K/call. Thành công.
```

### Kịch bản 3: Canh quota 5h trước khi chạy migration lớn

```bash
# Sắp chạy migration 2 tiếng, sợ giữa chừng bị rate limit
/usage
# → 5h session: 82% used, resets 16:00 (còn 40 phút nữa)
# → Quyết định: làm việc nhẹ (viết docs) tới 16:00 rồi mới migration

# Sau 16:00
/usage
# → 5h session: 5% used → bắt đầu migration yên tâm
```

### Kịch bản 4: Soi plugin code-review có đáng tiền không

```bash
# Bật plugin review, thấy cost tăng
/usage
# → Plugins: code-review 80K/session (inject cả style guide dài mỗi lần)
# → Quyết định: chỉ bật khi review PR, tắt khi code feature (xem bài plugins)
```

---

## Rủi ro & lưu ý

### Mất gì? Tốn gì?

- Không mất gì, tốn ~0 token.
- Rủi ro duy nhất: **hiểu nhầm số session thành số toàn account.** `/usage` mặc định hiện session hiện tại + rate limits account. Đừng lấy số session đi đối soát hóa đơn tháng.

### Version tối thiểu & provider

- Breakdown skills/subagents/plugins/per-MCP + rate limits hoàn thiện trên v2.1.x. Bản cũ hơn có thể chỉ hiện tổng đơn giản.
- **Subscription (Pro/Team):** có đủ rate limits (5h/weekly). Đây là nơi `/usage` hữu ích nhất.
- **API pay-as-you-go:** có breakdown tokens nhưng rate limits hiển thị khác (theo HTTP headers, không có weekly). Ý nghĩa quota khác hẳn.
- Một số provider thứ 3 / proxy có thể không trả quota → phần limits trống. Không phải lỗi.

### Cloud vs Local

| Môi trường | Khác biệt |
|---|---|
| CLI | Bảng text đầy đủ nhất |
| IDE | Thêm biểu đồ cột theo subagent/MCP |
| Web/Desktop | Thêm view theo ngày/tuần, gợi ý tắt MCP nặng |

> Tên skill/subagent trong bảng là tên runtime (ví dụ `Explore`, `frontend-guidelines`). Nếu thấy tên lạ → mở bài skills/subagents để biết nó từ đâu ra.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/usage` + `/cost` | Tìm thủ phạm đốt tiền |
| `/usage` + `/context` | Ai ngốn RAM? (MCP/skill nào phình) |
| `/usage` + tắt MCP | Phát hiện MCP nặng → tắt/bóp output |
| `/usage` + sửa prompt Explore | Subagents ngốn → viết prompt hẹp hơn |
| `/usage` trước task lớn | Canh quota rồi mới chạy |
| `/export` + `/usage` | Gửi đồng đội cả transcript lẫn breakdown để review hiệu năng |

Checklist tối ưu khi `/usage` báo đỏ:

```bash
# 1. Subagents cao? → Hỏi hẹp hơn, giảm số runs
# 2. 1 MCP cao? → Giới hạn fields, giảm calls
# 3. Skill trigger nhầm? → Sửa mô tả skill / tắt tạm
# 4. Quota 5h >85%? → Làm việc nhẹ tới giờ reset
# 5. Plugin nặng? → Chỉ bật khi cần
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/usage` trống / chỉ có tổng | Bản CLI cũ chưa có breakdown per-MCP | Update `npm i -g @anthropic-ai/claude-code` |
| Rate limits trống khi dùng API key | Pay-as-you-go không có quota 5h/weekly kiểu subscription | Đúng hành vi; xem dashboard billing thay vì quota |
| Subagent tên lạ ngốn nhiều | Plugin/agent-teams tự spawn agent phụ | Xem bài subagents/agent-teams để nhận diện; tắt plugin nếu không cần |
| MCP ngốn cao dù hỏi ít | MCP trả default payload lớn (cả thread/file) | Hỏi giới hạn fields/số lượng; xem bài MCP để chỉnh config |
| Skill trigger liên tục dù không liên quan | Mô tả skill quá chung → auto-trigger nhầm | Sửa `description` skill cho hẹp, hoặc tắt skill session này |
| % quota không giảm sau reset giờ | Nhìn nhầm đồng hồ (reset theo UTC, không phải giờ local) | Đổi sang UTC kiểm tra; gõ lại `/usage` sau 5 phút |
| Muốn breakdown theo từng prompt | `/usage` chỉ cộng dồn session, không tách từng prompt | Soi transcript `.jsonl` nếu cần chi tiết từng request |
| Thấy `cache read` thấp bất thường | Hay `/clear` hoặc đổi task liên tục làm mất cache | Hạn chế clear giữa cùng task; dùng `/compact` để giữ cache ấm |
| Breakdown hiện plugin không nhớ đã cài | Plugin từ marketplace tự active theo project | Xem `../09-plugins-marketplaces.md` để liệt kê và gỡ plugin thừa |

---

## Tham khảo

- Lệnh liên quan:
  - [../cost/README.md](../../session-context/cost/README.md) — tổng tiền session
  - [../context/README.md](../../session-context/context/README.md) — RAM hiện tại
  - [../compact/README.md](../../session-context/compact/README.md) — nén sau khi tìm ra rác
  - [../clear/README.md](../../session-context/clear/README.md) — reset khi đổi task
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../05-skills-custom-commands.md` — vì sao skills ngốn context
  - `../06-subagents-agent-teams-parallel.md` — subagents ngốn thế nào, cách bóp
  - `../08-mcp-ket-noi-cong-cu-ngoai.md` — bóp MCP output
  - `../09-plugins-marketplaces.md` — plugins nặng/nhẹ
  - `../10-permissions-modes-availability.md` — modes ảnh hưởng số lượt tool

> Mẹo 1 dòng: _cost cao mà không biết tại sao → `/usage` trước, đừng đoán — thủ phạm thường là 1 MCP hoặc 5 lần Explore vô tội vạ._

### Ví dụ đọc nhanh 10 giây

```text
Main 20% + Subagents 50% + MCP github 25% → bệnh là Explore + github.
→ Fix: bóp Explore (hỏi hẹp) + bóp github (giới hạn fields).
Main 70% + còn lại 5% → code chính tốn, không phải tool.
→ Fix: rút gọn prompt, chia task nhỏ, tránh output dài 1 lần.
Quota 5h 90% → đừng chạy task lớn, làm việc nhẹ tới giờ reset.
```

### Khi nào nên chụp `/usage` gửi đồng đội?

- Khi review hiệu năng prompt/agent: kèm cả `/cost` + `/usage` để người khác thấy tiền đi đâu.
- Khi báo bug "chậm/đắt": nhà phát triển cần breakdown, không chỉ câu "nó chậm".
- Khi viết ADR về MCP/plugin mới: đo trước/sau khi bật để quyết định giữ hay gỡ.

> Lưu ý pricing: breakdown tokens ≠ hóa đơn cuối (cache/chiết khấu/thuế tính riêng — xem [../cost/README.md](../../session-context/cost/README.md)).
>
> Checklist hàng tuần: mở `/usage` 1 lần, gỡ 1 MCP/plugin nặng nhất không còn cần.
>
> Ghi nhớ: _`/usage` không thay `/cost` hay `/context` — bộ 3 đi cùng nhau mới đủ bức tranh._
