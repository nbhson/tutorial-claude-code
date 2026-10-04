# /run — Mở app thật và lái nó để thấy change chạy được

> Loại Built-in · Nhóm Model–Mode–Code · Nguy hiểm Thấp (chạy app local: tốn port/CPU, có thể ghi DB dev; nhưng Không nếu recipe chỉ đọc + chạy test)

`/run` (từ bản ≥2.1.145) không chỉ build cho có — nó mở app của bạn lên thật (dev server, mobile simulator, CLI...) rồi tự lái (click, gõ, gọi API) để bạn THẤY change chạy được bằng mắt. Đi cặp với `/verify` (kiểm chứng build+chạy+quan sát, không fallback sang "test xanh là xong") và `/run-skill-generator` (ghi recipe chạy app vào `.claude/skills/run-<tên>/` để lần sau 1 lệnh là chạy). Hiểu `/run` là hiểu "demo sống thay vì báo cáo mồm".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/run` | _(không có)_ | Đoán stack, mở app theo recipe (hoặc hỏi nếu chưa có recipe) |
| `/run <tên-app>` | tên recipe đã lưu | Chạy đúng recipe `run-<tên-app>` trong `.claude/skills/` |
| `/run --record` | flag | Vừa chạy vừa ghi lại các bước thành recipe mới (gọi generator) |
| `/run --headless` | flag | Chạy không mở UI (API/CLI/log), cho máy yếu hoặc CI |
| `/verify` | _(lệnh riêng, ≥2.1.145)_ | Build + chạy + quan sát thật, cấm fallback "test pass là đủ" |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: chạy app hiện tại (lần đầu: hỏi stack + port)
/run
```

```bash
# Dạng 2: chạy đúng recipe đã lưu (web, api, mobile...)
/run web
/run api
```

```bash
# Dạng 3: vừa chạy vừa ghi recipe cho lần sau
/run --record
```

```bash
# Dạng 4: máy yếu / SSH remote — chỉ log, không mở browser
/run --headless
```

```bash
# Dạng 5: kiểm chứng sau khi run thấy OK (cấm fallback test)
/verify
```

```yaml
# Ví dụ recipe đã record: .claude/skills/run-web/SKILL.md
# ---
# name: run-web
# description: Run Next.js web locally and smoke-test homepage + login
# ---
# 1. Run `npm run dev` (port 3000, wait "Ready in").
# 2. Open http://localhost:3000, screenshot homepage.
# 3. Fill login form (test@test.com / test1234), submit, expect /dashboard.
# 4. Report PASS/FAIL with screenshot path.
```

---

## Cách nó hoạt động

### Cơ chế sâu: 1 lần /run làm gì?

1. **Tìm recipe:**
   - Quét `.claude/skills/run-*/SKILL.md` (recipe của repo bạn) + bundled `run-*` ở repo root (mặc định chung).
   - Có 1 recipe khớp → chạy luôn. Nhiều recipe → hỏi chọn (`web` hay `api`?). Không có → hỏi 3 câu (lệnh start, port, check thế nào) rồi chạy tạm + gợi ý `--record` để lưu.
2. **Mở app thật:**
   - Chạy lệnh start (ví dụ `npm run dev`), đợi dấu hiệu sống ("Ready in", port mở, health-check 200).
   - Timeout ~60-90s: quá hạn không lên → báo log 20 dòng cuối + gợi ý fix (thiếu `.env`, port bận, deps chưa install).
3. **Lái app (drive):**
   - Web: mở browser headless/hiển thị, vào URL, chụp screenshot, click/gõ theo bước recipe (ví dụ điền form login, bấm checkout).
   - API: gọi endpoint (`curl`/fetch), check status + body khớp kỳ vọng.
   - CLI: chạy lệnh với input mẫu, so output.
4. **Báo cáo kiểu "thấy được":**
   - PASS/FAIL từng bước + screenshot/log đính kèm — không nói mồm "chắc chạy được".
   - FAIL ở bước nào → dừng, hiện log + gợi ý nguyên nhân (sai port, thiếu seed data, CORS...).
5. **Verify sau run (từ v2.1.200 recipe verify tự record):**
   - `/verify` (≥2.1.145): build + chạy + quan sát, CẤM fallback kiểu "unit test xanh nên chắc OK" — phải thấy app sống.
   - Từ bản v2.1.200: `/verify` lần đầu cũng tự record vào `.claude/skills/verify/SKILL.md` (trước đó chỉ `run-*` record, verify dùng bundled ở repo root).
6. **Record recipe (`--record` / generator):**

```text
/run --record (hoặc /run-skill-generator)
├─ hỏi: lệnh start? port? check sống bằng gì? (lần đầu)
├─ bạn lái tay 1 lần, tool ghi lại từng bước
├─ sinh .claude/skills/run-<tên>/SKILL.md
└─ lần sau: /run <tên> là chạy y hệt, khỏi hỏi lại
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Làm gì? | Khi nào? |
|---|---|---|
| `/run` | MỞ APP + LÁI thật, thấy bằng mắt | Sau khi code xong, muốn demo sống |
| `/verify` | BUILD + CHẠY + QUAN SÁT, cấm fallback test | Muốn khẳng định "chạy được" chắc nịch |
| `/run-skill-generator` | GHI RECIPE chạy app để tái dùng | Lần đầu setup, hoặc app đổi cách chạy |
| `/review` | ĐỌC code chấm đúng/sai | Trước khi run (code xấu thì khỏi mất công mở app) |
| `/test` (bash) | Chạy unit test mù (không mở app) | Vòng lặp nhanh trong lúc code |

> Quy tắc ngón tay cái:
>
> - **Muốn thấy app sống → `/run`. Muốn khẳng định chắc nịch → `/verify`. Muốn lần sau 1 lệnh là chạy → record recipe. Test xanh mà app trắng trang là chuyện thường — đừng tin test mù.**

---

## Ví dụ thực tế

### Kịch bản 1: Web Next.js — sửa trang login, mở lên lái thử (10 phút)

```bash
# Vừa sửa form login, muốn thấy chạy thật:
# Lần đầu chưa có recipe → tool hỏi 3 câu, bạn trả lời:
#   start: npm run dev | port: 3000 | check: mở /login, đăng nhập test@test.com

/run --record
# → dev server lên (Ready in 2.1s)
# → mở /login, screenshot login-before.png
# → điền test@test.com / test1234, bấm Đăng nhập
# → vào /dashboard, screenshot login-after.png
# → PASS 3/3. Recipe lưu vào .claude/skills/run-web/SKILL.md

# Lần sau (đồng nghiệp pull về): chỉ cần
/run web
# → chạy y hệt 4 bước, khỏi setup lại
```

> Kết quả: lần đầu 10 phút setup, lần sau 1 phút demo. Đồng nghiệp mới vào không cần hỏi "chạy app kiểu gì".

### Kịch bản 2: API Express — sửa endpoint, gọi thật check status (5 phút)

```bash
# Sửa POST /orders, muốn gọi thật:
/run api
# → npm run dev:api (port 4000, "listening on 4000")
# → POST /orders {item: "book", qty: 2} → 201 {id: "ord_9f2"}
# → GET /orders/ord_9f2 → 200 đúng item
# → PASS 2/2

# Khẳng định chắc nịch trước khi mở PR:
/verify
# → build OK, seed OK, 2 endpoint sống. Không fallback "test pass".
```

### Kịch bản 3: Mobile (Expo) — máy yếu thì headless + log

```bash
# Laptop yếu, mở simulator lag:
/run --headless
# → expo start, Metro bundler OK, log "Bundled 812ms"
# → không mở simulator, chỉ check bundle không lỗi + API reachable
# → PASS (headless). Ghi chú: "cần mở simulator tay để xem UI"

/run mobile
# → (máy khỏe) mở simulator, screenshot màn Home
```

### Kịch bản 4: Recipe verify tự record từ v2.1.200 (team)

```bash
# Trước v2.1.200: verify dùng bundled chung ở repo root (check chung chung).
# Từ v2.1.200: lần đầu chạy /verify, tool hỏi rồi tự ghi
#   .claude/skills/verify/SKILL.md riêng cho repo bạn:

# Lần đầu:
/verify
# → hỏi: build bằng gì? (npm run build) test gì? (npm test) smoke check gì? (/healthz)
# → record vào .claude/skills/verify/SKILL.md, commit cùng repo

# Lần sau (CI hoặc đồng nghiệp):
/verify
# → đọc SKILL.md của repo, chạy đúng 3 bước đã chốt. Không còn "mỗi người verify một kiểu".
```

```yaml
# .claude/skills/verify/SKILL.md (ví dụ sau khi record)
# ---
# name: verify
# description: Build + test + smoke-check this repo the standard way
# ---
# 1. Run `npm run build` — must exit 0.
# 2. Run `npm test` — must pass 100%.
# 3. Boot `npm start`, GET /healthz expect 200, then kill.
# 4. No fallback: if any step fails, report FAIL, do not claim "tests pass so OK".
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (chạy app local)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Recipe chạy migration thật | HAY GẶP: `npm run dev` kèm auto-migrate ghi đè DB dev, mất seed | Recipe chỉ dùng DB dev/docker; snapshot/dump trước khi `/run` lần đầu |
| Port bận (3000 đã có app khác) | Start fail, log rối, tưởng code hỏng | `lsof -i :3000` kill trước, hoặc recipe dùng port riêng (3001) |
| Record recipe chứa secret | `--record` ghi luôn `API_KEY=sk-...` bạn gõ tay vào SKILL.md rồi commit | Sau record, mở SKILL.md thay secret bằng `${ENV}`; `git grep sk-` trước khi push |
| Tin PASS mù quáng | Recipe check nông (`/healthz` 200 nhưng trang chính trắng) | Recipe phải check đúng chỗ vừa sửa (login/checkout), không chỉ ping `/` |
| Chạy app production config | `NODE_ENV=production` + DB thật → ghi bẩn dữ liệu thật | Recipe hardcode `NODE_ENV=development`; deny URL prod trong settings |

### Tốn token?

- 1 lần `/run` (mở + lái 3-5 bước + screenshot) ≈ 8-20k token. Đắt hơn chat thường.
- Tiết kiệm: `--headless` khi chỉ cần log; recipe càng cụ thể càng ít vòng hỏi-đáp. Đắt 1 lần setup, rẻ mọi lần sau.

### Version / provider

- `/run` + `/verify`: bản **≥2.1.145**. Cũ hơn chưa có — phải chạy tay (`npm run dev` + mở browser tay).
- Verify tự record `.claude/skills/verify/SKILL.md`: bản **≥2.1.200** (trước đó verify dùng bundled ở repo root, không record riêng).
- Recipe `run-*`: lưu `.claude/skills/run-<tên>/`, commit cùng repo để cả team dùng.
- Bedrock/Vertex: chạy được (mở app local, model chỉ đọc log/screenshot).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/run` + `/verify` | Mở lên thấy OK rồi khẳng định chắc | Run PASS → verify build+smoke |
| `/run` + `/review` | Review code trước khi mất công mở app | `/review` sạch → `/run` demo |
| `/run` + `/run-skill-generator` | Lần đầu setup recipe | `--record` 1 lần → tái dùng mãi |
| `/run` + `/security-review` | App sống rồi soi bảo mật flow vừa demo | Demo login OK → quét auth |
| `/run` + `/doctor` | App không lên, nghi config hỏng | Run FAIL → doctor khám MCP/env |

Workflow chuẩn "code xong 1 feature (20 phút)":

```bash
# 1. Review code trước (khỏi mở app với code xấu)
/review
# 2. Mở app + lái thử chỗ vừa sửa
/run web
# 3. Khẳng định chắc nịch (cấm fallback test)
/verify
# 4. Quét bảo mật nếu đụng auth/payment
/security-review --quick
# 5. Mở PR
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/run` báo "no recipe" rồi hỏi 3 câu mỗi lần | Chưa `--record` nên không có SKILL.md lưu | Chạy 1 lần `/run --record`, commit `.claude/skills/run-*/` |
| Dev server timeout 60s không lên | Thiếu `.env`, deps chưa install, hoặc port bận | Đọc 20 dòng log cuối; `cp .env.example .env`; `npm i`; `lsof -i :3000` kill |
| PASS nhưng mở tay thấy trang trắng | Recipe chỉ check `/healthz`, không check đúng trang vừa sửa | Sửa SKILL.md thêm bước vào đúng route + screenshot; chạy lại |
| Screenshot browser đen thui | Headless thiếu font/GPU trong docker/SSH | Dùng `/run --headless` (chỉ log/API) hoặc chạy ở máy có màn hình |
| `/verify` bản cũ không record SKILL.md | CLI <2.1.200 (verify còn bundled chung) | Update CLI mới nhất (`/restart` offer version mới), chạy `/verify` lại để record |
| Recipe của đồng nghiệp chạy fail ở máy mình | Port/env khác (bạn 3001, recipe 3000; thiếu ENV) | Sửa recipe dùng `${PORT:-3000}` + `.env.example`; mỗi người 1 port riêng |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../verify/README.md](../../code-repo/verify/README.md) — kiểm chứng build+chạy+quan sát, cấm fallback test
  - [../review/README.md](../../code-repo/review/README.md) — review code trước khi mất công mở app
  - [../security-review/README.md](../../code-repo/security-review/README.md) — quét bảo mật flow vừa demo sống
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — khám config khi app không lên
  - [../permissions/README.md](../../model-mode/permissions/README.md) — hẹp quyền shell trước khi cho run migration
  - [../mcp/README.md](../../knowledge-system/mcp/README.md) — MCP browser/playwright để lái app (nếu recipe dùng)
- Bài tổng quan:
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — recipe SKILL.md viết tay thế nào
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md) — cho subagent chạy app song song
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md) — plugin framework có sẵn recipe run

> Mẹo 1 dòng: _test xanh chưa chắc app sống — mở lên lái thử mới tin, và record lại để lần sau 1 lệnh._
