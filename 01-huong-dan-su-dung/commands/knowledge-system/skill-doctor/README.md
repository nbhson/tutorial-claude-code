# /skill-doctor — Báo cáo skill nào ngốn context, skill nào chết lâm sàng

> Loại Built-in (v2.1.252+, terminal-only) · Nhóm Tri thức & Tối ưu · Nguy hiểm Không (chỉ đọc + báo cáo, không sửa/xoá gì)

`/skill-doctor` (từ bản v2.1.252+, chỉ chạy trong terminal — không qua Remote Control) khám toàn bộ skills: skill nào ngốn bao nhiêu context/token, skill nào "không bao giờ được gọi" (mô tả mờ nên model chẳng trigger), skill nào trùng nhau. KHÔNG gồm skills bundled theo máy và enterprise. Hiểu `/skill-doctor` là hiểu "bác sĩ riêng cho tủ skill", còn `/doctor` là bác sĩ tổng quát cả repo.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/skill-doctor` | _(không có)_ | Báo cáo full: cost từng skill + never-called + trùng lặp |
| `/skill-doctor --cost` | flag | Chỉ bảng context cost (token ước tính/skill, xếp cao trước) |
| `/skill-doctor --unused` | flag | Chỉ danh sách skills không bao giờ gọi + lý do (mô tả mờ?) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: khám full tủ skill (mỗi tháng 1 lần)
/skill-doctor
# → bảng cost 12 skills + 3 never-called + 1 cặp trùng
```

```bash
# Dạng 2: chỉ xem ai ngốn token nhất
/skill-doctor --cost
# → "run-e2e: ~4.2k/session (cao nhất). pdf-read: ~3.8k..."
```

```bash
# Dạng 3: chỉ tìm skill chết
/skill-doctor --unused
# → "deploy-staging: 0 trigger/90 ngày — description thiếu trigger word 'staging'?"
```

---

## Cách nó hoạt động

### Cơ chế sâu: đo cost và "never-called" kiểu gì?

1. **Context cost:** ước tính token mỗi skill nạp vào context (SKILL.md dài + file kèm theo). Skill 200 dòng + 5 ví dụ = ngốn mỗi session dù có dùng hay không (nếu auto-load).
2. **Never-called:** đối chiếu lịch sử trigger 90 ngày — skill 0 lần gọi bị gắn cờ, kèm chẩn đoán: description mờ ("hỗ trợ deploy" — deploy cái gì, khi nào?) hay trùng skill khác mạnh hơn.
3. **Trùng lặp:** 2 skills mô tả gần giống nhau (cùng "review code") → gợi ý gộp/sửa description phân biệt.
4. **Phạm vi LOẠI TRỪ (quan trọng):**
   - KHÔNG gồm skills **bundled** theo máy (mặc định hệ thống) và **enterprise** (tổ chức push) — chỉ khám skills của bạn (project/personal).
   - Muốn gọn bundled? Dùng settings disable, không phải skill-doctor.
5. **Terminal-only:** không chạy qua Remote Control (mobile/web remote) — phải ngồi đúng terminal máy có skills.

```text
/skill-doctor
├─ cost table:  run-e2e 4.2k | pdf-read 3.8k | ... (cao trước)
├─ never-called: deploy-staging (0/90d — thiếu trigger word)
├─ duplicate:   review-code ~ code-review (gộp?)
└─ đề xuất:      gọn pdf-read, sửa mô tả deploy-staging, gộp 2 review
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Khám gì? | Dùng khi nào? |
|---|---|---|
| `/skill-doctor` (v2.1.252+) | SKILLS: cost + never-called (trừ bundled/enterprise) | Tủ skill phình, nghi tốn token |
| `/doctor` | CONFIG repo (md, quyền, mcp, hooks...) | Khám tổng quát mỗi tháng |
| `/stats` | TIỀN/token đã tiêu | Cuối tuần nhìn chi tiêu |
| `/context` | CONTEXT phiên hiện tại | Đang đầy, muốn biết ai ngốn |

> Quy tắc ngón tay cái:
>
> - **Nghi skill ngốn token → `/skill-doctor`. Nghi config bệnh → `/doctor`. Hỏi tiêu bao nhiêu → `/stats`.**

---

## Ví dụ thực tế

### Kịch bản 1: Tủ 12 skills, context lúc nào cũng đầy — tìm thủ phạm (15 phút)

```bash
/skill-doctor --cost
# → "run-e2e 4.2k (SKILL.md 180 dòng + 6 ví dụ thừa)
#    pdf-read 3.8k (nhúng cả spec 90 dòng vào SKILL)
#    10 skills còn lại <800 mỗi cái"

# Chữa:
# 1. pdf-read: chuyển spec sang file riêng, SKILL chỉ giữ cách gọi
# 2. run-e2e: cắt 6 ví dụ còn 2
# → /skill-doctor --cost lại: "tổng 12k → 4k. Tiết kiệm 8k/session."
```

> Kết quả: 15 phút gọn, mọi session sau nhẹ 8k token. Skill to nhất thường là skill viết đầu tiên (nhồi hết vào 1 file).

### Kịch bản 2: Skill deploy-staging viết xong chẳng ai gọi (10 phút)

```bash
/skill-doctor --unused
# → "deploy-staging: 0 trigger/90 ngày.
#    Chẩn đoán: description 'hỗ trợ deploy' — thiếu trigger word.
#    Model không biết khi nào gọi nó vs deploy-prod."

# Chữa: sửa description cụ thể
# Trước: "hỗ trợ deploy"
# Sau: "Deploy lên staging — gọi khi user nói deploy staging, push staging, test staging"
# → tháng sau: 6 trigger. Khỏi bệnh.
```

### Kịch bản 3: Hai skill review giẫm nhau — gộp (10 phút)

```bash
/skill-doctor
# → "review-code ~ code-review: mô tả giống 80%. Cả hai đều trigger khi 'review PR'."
# → Quyết: giữ review-code (mô tả rõ hơn), xóa code-review
rm -rf .claude/skills/code-review
# → /skill-doctor lại: hết duplicate
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (xóa skill theo báo cáo mù)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Xóa skill "never-called" ngay | HAY GẶP: skill theo mùa (quyết toán quý, deploy lễ) — 90 ngày không gọi là bình thường | Never-called theo mùa thì giữ + ghi chú; chỉ xóa khi chắc hết nhu cầu |
| Gọn SKILL.md quá tay | Cắt mất ví dụ/bước quan trọng, skill gọi sai | Cắt từng phần, test trigger lại sau mỗi lần gọn |
| Tưởng gồm cả bundled/enterprise | Báo cáo "sạch" nhưng bundled vẫn ngốn | Bundled/enterprise quản bằng settings disable riêng, đừng trông chờ ở đây |
| Chạy qua Remote Control | Không hỗ trợ — báo lỗi/không ra gì | Ngồi đúng terminal máy có skills mà chạy |

### Tốn token?

- 1 lần khám ≈ 5-10k token (đọc hết SKILL.md + lịch sử). Mỗi tháng 1 lần — rẻ so với skill phình ngốn hàng k mỗi session.

### Version / provider

- `/skill-doctor`: bản **v2.1.252+**, **terminal-only** (không qua Remote Control). Cũ hơn chưa có — rà tay (đọc từng SKILL.md + đoán).
- Phạm vi: skills project/personal; **không gồm bundled/enterprise**.
- Bedrock/Vertex: chạy được (đọc file local).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/skill-doctor` + `/doctor` | Khám skill + khám tổng | Doctor tháng này → skill-doctor tháng sau (hoặc cùng ngày dọn) |
| `/skill-doctor` + `/context` | Biết skill nào ngốn phiên hiện tại | Doctor báo cost → context kiểm chứng |
| `/skill-doctor` + `/stats` | Đo tiền tiết kiệm sau khi gọn | Stats trước-sau 1 tuần |
| `/skill-doctor` + `/run-skill-generator` | Skill run-* phình | Doctor chỉ cost → generator gọn lại |

Workflow chuẩn "dọn tủ skill mỗi tháng (30 phút)":

```bash
# 1. Khám
/skill-doctor
# 2. Chữa cost cao (tách file, cắt ví dụ thừa)
# 3. Sửa description never-called (thêm trigger word) hoặc xóa
# 4. Gộp cặp trùng
# 5. Khám lại xác nhận gọn
/skill-doctor --cost
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/skill-doctor` báo unknown command | CLI <2.1.252 | Update (`/restart` offer bản mới); tạm rà tay từng SKILL.md |
| Chạy từ mobile remote không ra gì | Terminal-only, không qua Remote Control | Ngồi đúng terminal máy có skills |
| Báo cáo thiếu skills công ty | Enterprise skills bị loại trừ theo thiết kế | Quản enterprise qua admin/org settings, không phải đây |
| Sửa description xong vẫn never-called | Trigger word vẫn chung chung hoặc skill thật sự hết nhu cầu | Viết description kiểu "gọi khi user nói X, Y, Z" cụ thể; 1 tháng nữa không gọi thì xóa |
| Gọn xong skill gọi sai | Cắt mất bước/ví dụ then chốt | Rollback git từng phần; gọn dần + test trigger sau mỗi lần |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — bác sĩ tổng quát (skill-doctor là chuyên khoa skill)
  - [../context/README.md](../../session-context/context/README.md) — xem context phiên hiện tại
  - [../stats/README.md](../../knowledge-system/stats/README.md) — đo tiền tiết kiệm sau dọn
  - [../config/README.md](../../auth-settings/config/README.md) — disable bundled skills bằng settings
- Bài tổng quan:
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — viết/sửa SKILL.md và description trigger
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md) — gọn tri thức nạp vào context

> Mẹo 1 dòng: _skill nào 90 ngày không ai gọi thì hoặc sửa mô tả cho rõ, hoặc xóa cho nhẹ._
