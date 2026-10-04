# /run-skill-generator — Ghi recipe "cách chạy app" thành skill tái dùng

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ hỏi + ghi file SKILL.md; nhưng Có nếu bạn commit recipe chứa secret hardcode)

`/run-skill-generator` là wizard ghi lại "cách chạy app này" thành recipe chuẩn ở `.claude/skills/run-<tên>/SKILL.md`: lệnh start gì, port nào, check sống bằng gì, lái thử bước nào. Sinh ra để `/run` lần sau 1 lệnh là chạy, và đồng nghiệp pull về không phải hỏi "chạy kiểu gì". Hiểu generator là hiểu "quay video cách đề máy để lần sau ai cũng đề được".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/run-skill-generator` | _(không có)_ | Wizard hỏi từng bước rồi sinh recipe (hỏi tên app trước) |
| `/run-skill-generator <tên>` | tên recipe | Sinh/cập nhật thẳng recipe `run-<tên>` (bỏ qua hỏi tên) |
| `/run --record` | shortcut | Vừa `/run` vừa ghi recipe cùng lúc (gọi ngầm generator) |
| `/run <tên>` | tên recipe | Dùng recipe đã sinh (không sinh mới) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: wizard từ đầu (chưa biết đặt tên gì)
/run-skill-generator
# → hỏi: app gì? (web/api/mobile) → hỏi start/port/check → sinh file
```

```bash
# Dạng 2: đặt tên trước cho nhanh
/run-skill-generator web
/run-skill-generator api
```

```bash
# Dạng 3: vừa chạy vừa ghi (khuyên dùng lần đầu)
/run --record
```

```bash
# Dạng 4: kiểm tra recipe vừa sinh
cat .claude/skills/run-web/SKILL.md
/run web
```

---

## Cách nó hoạt động

### Cơ chế sâu: wizard hỏi gì, sinh file gì?

1. **Hỏi 4 nhóm (ngắn gọn, có gợi ý theo stack):**
   - `start`: lệnh mở app (`npm run dev`, `docker compose up`, `expo start`...). Tool đoán từ `package.json`/Dockerfile rồi hỏi xác nhận — bạn chỉ Yes/No.
   - `port + dấu hiệu sống`: port nào, chờ chữ gì ("Ready in", "listening on") hay GET endpoint nào 200.
   - `smoke steps`: lái thử gì (mở `/login`? POST `/orders`?). Tối thiểu 1 bước đúng chỗ hay sửa.
   - `stop/cleanup`: kill kiểu gì (`Ctrl+C`, `docker compose down`), có cần reset seed không.
2. **Chạy thử 1 lần ngay:**
   - Generator chạy thử recipe vừa hỏi để chắc nó PASS (không sinh recipe chết).
   - FAIL → hỏi lại (sai port? thiếu env?) rồi chạy lại tới PASS mới ghi file.
3. **Sinh file chuẩn SKILL.md:**

```markdown
<!-- .claude/skills/run-web/SKILL.md (ví dụ) -->
---
name: run-web
description: Run Next.js web locally and smoke-test homepage + login
---

1. Run `npm run dev` (port 3000, wait "Ready in").
2. Open http://localhost:3000, screenshot homepage.
3. Login test@test.com / test1234, expect /dashboard.
4. Kill with Ctrl+C. Never run migration.
```

4. **Phân biệt với verify (từ v2.1.200):**
   - `run-*`: recipe MỞ APP + LÁI (generator này sinh).
   - `verify`: recipe BUILD + TEST + SMOKE (từ v2.1.200 `/verify` lần đầu tự record vào `.claude/skills/verify/SKILL.md`; trước đó verify dùng bundled ở repo root, không record riêng).
   - Đừng nhồi build/test vào recipe run — mỗi cái một việc.

### Khác gì với lệnh dễ nhầm?

| Lệnh | Sinh gì? | Dùng khi nào? |
|---|---|---|
| `/run-skill-generator` | Recipe MỞ+LÁI app (`run-*`) | Lần đầu setup / app đổi cách chạy |
| `/verify` (≥2.1.200) | Recipe BUILD+TEST+SMOKE (`verify`) | Lần đầu chốt chuẩn kiểm chứng repo |
| `/run --record` | Vừa chạy vừa sinh `run-*` | Muốn vừa demo vừa lưu (1 công đôi việc) |
| `/init` | `CLAUDE.md` (luật repo) | Repo chưa có gì — sinh luật trước, recipe sau |

> Quy tắc ngón tay cái:
>
> - **Chưa ai biết chạy app kiểu gì → generator. Chạy được rồi nhưng mỗi người verify một kiểu → `/verify` record. Cả hai chưa có → generator trước, verify sau.**

---

## Ví dụ thực tế

### Kịch bản 1: Repo Next.js mới — sinh recipe web từ zero (10 phút)

```bash
/run-skill-generator web
# → đoán: "package.json có next dev → start = npm run dev? [Yes]"
# → hỏi port [3000] + dấu hiệu sống [Ready in] + smoke [mở / + screenshot]
# → chạy thử PASS → ghi .claude/skills/run-web/SKILL.md → commit cho team
git add .claude/skills/run-web/
git commit -m "chore: add run-web recipe"
```

> Kết quả: 10 phút 1 lần, cả team khỏi hỏi "chạy kiểu gì" mãi mãi.

### Kịch bản 2: Thêm recipe API cho repo fullstack (có sẵn web)

```bash
# Đã có run-web, giờ thêm run-api:
/run-skill-generator api
# → start: npm run dev:api? [Yes] port: [4000]
# → smoke: POST /healthz expect 200? [Yes] + GET /orders mẫu? [Yes]
# → PASS → ghi .claude/skills/run-api/SKILL.md → kiểm tra: /run web + /run api
```

### Kịch bản 3: App đổi cách chạy (docker hoá) — cập nhật recipe cũ

```bash
# Trước: npm run dev. Giờ: docker compose up. Chạy lại cùng tên để ghi đè:
/run-skill-generator web
# → "run-web đã tồn tại. Ghi đè? [Yes/No/Diff]" → Diff → Yes → PASS → lưu
# → SKILL.md mới phải có "stop: docker compose down" (kẻo container treo)
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (recipe ghi sai / lộ secret)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Record lúc gõ secret tay | HAY GẶP: SKILL.md chứa `API_KEY=sk-thật` rồi commit public | Sau sinh, mở file thay bằng `${API_KEY}`; `git grep "sk-" .claude/` trước push |
| Recipe chạy migration/seed destructive | Lần sau ai `/run` cũng mất data dev | Cấm migration trong recipe run (ghi rõ "Never run migration"); migration để verify/handler riêng |
| Recipe chỉ PASS ở máy bạn | Port/env cứng (3000, path `/Users/bạn/...`) | Dùng `${PORT:-3000}`, đường dẫn tương đối; test ở máy thứ 2 hoặc CI |
| Sinh 5 recipe cho 5 microservice rồi loạn | Không biết `/run` cái nào trước | 1 recipe `run-all` (docker compose) + recipe lẻ cho debug; README ghi thứ tự |

### Tốn token?

- 1 lần generator (hỏi + chạy thử 1-2 vòng) ≈ 8-15k token. Một lần duy nhất, tái dùng vô hạn — đáng.

### Version / provider

- Generator cho `run-*`: v2.1+. Verify tự record `.claude/skills/verify/SKILL.md`: **≥2.1.200** (cũ hơn verify dùng bundled ở repo root).
- Recipe lưu `.claude/skills/`, commit cùng repo. Bedrock/Vertex: dùng được (sinh file local).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| generator + `/run` | Sinh xong dùng ngay | Sinh → `/run web` kiểm tra |
| generator + `/verify` | Chuẩn chạy + chuẩn kiểm chứng | Recipe run trước, recipe verify sau |
| generator + `/init` | Repo mới toanh | `/init` sinh luật → generator sinh recipe |
| generator + `/doctor` | Recipe chạy fail mãi | Doctor khám env/MCP trước khi đổ lỗi recipe |

Workflow chuẩn "onboard repo mới (30 phút)":

```bash
# 1. Sinh luật repo (nếu chưa có)
/init
# 2. Sinh recipe chạy
/run-skill-generator web
# 3. Chạy thử bằng recipe mới
/run web
# 4. Chốt chuẩn kiểm chứng (≥2.1.200 tự record)
/verify
# 5. Commit cả luật + recipe
git add CLAUDE.md .claude/skills/ && git commit -m "chore: onboard run recipe"
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Generator đoán sai lệnh start | Monorepo nhiều `package.json`, tool đoán nhầm root | Trả lời tay đúng lệnh + `workingDir`; ghi rõ trong SKILL.md |
| Chạy thử PASS nhưng `/run` sau fail | Env đổi (hết hạn token test, DB seed bị xóa) | Recipe dùng seed/fixture cố định; smoke check báo rõ thiếu gì |
| Ghi đè nhầm recipe đang dùng tốt | Chạy generator cùng tên mà không Diff | Luôn chọn Diff trước Yes; `git checkout .claude/skills/run-<tên>/` để rollback |
| Recipe chứa path tuyệt đối máy bạn | Wizard ghi nguyên `/Users/bạn/...` | Sửa thành tương đối; review SKILL.md trước khi commit |
| Team không thấy recipe mới | Quên commit `.claude/` (đang gitignore) | Bỏ `.claude/skills/` ra khỏi ignore (chỉ ignore `.claude/settings.local.json` chứa secret máy cá nhân) |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../verify/README.md](../verify/README.md) — recipe verify (tự record từ v2.1.200)
  - [../init/README.md](../init/README.md) — sinh CLAUDE.md trước khi sinh recipe
  - [../doctor/README.md](../doctor/README.md) — khám khi recipe chạy mãi không lên
  - [../mcp/README.md](../mcp/README.md) — MCP browser để recipe lái app
- Bài tổng quan:
  - [../../05-skills-custom-commands.md](../../05-skills-custom-commands.md) — format SKILL.md chuẩn
  - [../../03-claude-md-memory-rules.md](../../03-claude-md-memory-rules.md) — luật repo đi kèm recipe

> Mẹo 1 dòng: _quay 1 lần cách đề máy cho chuẩn, cả team đề phát ăn ngay._
