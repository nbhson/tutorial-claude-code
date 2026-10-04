# /verify — Build + chạy app thật, quan sát output — khác test ở chỗ có bằng chứng sống

> Loại Skill/Workflow · Nhóm Code & Repo · Nguy hiểm Thấp (có chạy code — nhưng chỉ build/test/dev, không deploy; nguy hiểm nếu verify script chạm production DB — luôn verify trên staging/test)

`/verify` không tin lời model nói ("em fix xong rồi") mà bắt nó build + chạy thật: `npm run build`, `pytest`, boot app, curl endpoint, paste output/log lên màn hình. Có output xanh mới gọi là xong. Đây là khác biệt cốt lõi với "chạy test" qua loa: verify đòi bằng chứng quan sát được.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/verify` | _(không có)_ | Build + test + boot theo CLAUDE.md, báo output |
| `/verify <phạm vi>` | `payments`, `auth`, `e2e`... | Chỉ verify module đó |
| `/verify --e2e` | (quy ước) | Verify end-to-end (boot + curl + DB check) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: verify chuẩn sau mọi task
/verify
```

```bash
# Dạng 2: verify 1 module vừa sửa
/verify payments
```

```bash
# Dạng 3: verify e2e trước release
/verify --e2e
```

```bash
# Dạng 4: workflow merge chuẩn (copy-paste)
/diff
/review
/verify
# → xanh hết → git push
```

```bash
# Dạng 5: verify sau fix từ code-review
# Sửa CR-1, CR-2 xong →
/verify auth
```

```bash
# Dạng 6: verify migration (đòi query thật)
/verify
# → yêu cầu paste SELECT COUNT(*) trước/sau + log boot staging
```

---

## Cách nó hoạt động

### Cơ chế sâu: verify khác test thế nào?

1. **Test = 1 lát cắt. Verify = cả mâm:**
   - `npm test` thường chỉ chạy unit (mock DB, mock API).
   - `/verify` chạy chuỗi: `lint → typecheck → unit → build → boot staging/dev → smoke curl → (tùy) e2e`. Mock ít nhất có thể.
2. **Quan sát, không nghe kể:**
   - Verify bắt paste OUTPUT THẬT (log build, test summary, curl response, screenshot nếu UI) vào chat.
   - Evaluator/người đọc output đó để kết luận — không chấp nhận "chắc là được".
3. **Đọc lệnh từ CLAUDE.md:**
   - Verify skill đọc `CLAUDE.md` để biết `pnpm build` hay `npm run build`, `vitest` hay `jest` — khỏi hỏi lại.
   - Repo chưa có CLAUDE.md (`/init` chưa chạy) → verify phải hỏi/đoán, dễ chạy sai lệnh.
4. **Môi trường verify:**
   - Mặc định: máy bạn (dev/staging). KHÔNG chạm production (DB thật, tiền thật).
   - Phân biệt với `/ultrareview` sandbox: verify chạy máy bạn (nhanh, thấy log local); ultrareview chạy cloud (cách ly, tốn tiền).
5. **Verify vs goal evaluator:**
   - `/goal` check mỗi turn (tự động, nhẹ). `/verify` check 1 lần cuối (nặng, chạy thật). Chuẩn là goal giữa + verify cuối.
6. **Batch verify:**
   - Mỗi worktree `/batch` verify độc lập (port/DB riêng) để không dẫm nhau.

### Sơ đồ pipeline verify chuẩn

```text
[/verify] → lint (eslint/ruff)
         → typecheck (tsc/mypy)
         → unit tests (vitest/pytest)
         → build (next build / docker build)
         → boot (dev/staging) + đọc log
         → smoke (curl 3 endpoints chính)
         → (nếu --e2e) playwright/cypress + DB check
         → báo cáo PASS/FAIL + paste output
```

### Khác gì lệnh dễ nhầm?

| Lệnh | Chạy code? | Bằng chứng? | Dùng khi nào? |
|---|---|---|---|
| `/verify` | Có (full pipeline) | Output thật paste lên | Sau mọi task trước khi nhận |
| `npm test` tay | Có (1 lát) | Có nhưng hẹp | Lúc dev nhanh |
| `/review` | Không (đọc giấy) | Không | Soi logic/style |
| `/goal` PASS | Có thể (qua evaluator) | Gián tiếp | Giám sát loop dài |
| `/ultrareview` | Có (sandbox cloud) | Có (cách ly) | Audit lớn |

> Quy tắc ngón tay cái:
>
> - **Chưa `/verify` thì chưa xong — dù model nói gì.**

---

## Ví dụ thực tế

### Kịch bản 1: Fix API login — từ "em nghĩ là được" tới bằng chứng

Không verify: model sửa 2 dòng, bảo "xong". Bạn merge, production 500.

```bash
# Có verify:
/verify auth
```

> Output verify đòi xem:

```text
[1] ruff check src/auth/ ............ OK
[2] mypy src/auth/ .................. OK
[3] pytest tests/auth/ .............. 12 passed
[4] boot staging .................... listening :8000 (log 5 dòng)
[5] curl POST /login (user đúng) ..... 200 + Set-Cookie
[6] curl POST /login (sai pass) ...... 401
→ VERIFY PASS
```

> Giá trị: 6 dòng output này đáng hơn 100 câu "em chắc là được".

### Kịch bản 2: Frontend Next.js — build + boot + curl

```bash
/verify
```

> Chuỗi chạy:

```bash
pnpm eslint . --max-warnings=0
pnpm tsc --noEmit
pnpm vitest run
pnpm build
pnpm start -p 3100 &
curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/login
# → 200 mới PASS
curl -s http://localhost:3100/api/health
# → {"status":"ok"} mới PASS
```

### Kịch bản 3: Migration DB — verify bằng query, không bằng niềm tin

```bash
/verify
# Skill chạy (staging):
```

```sql
-- trước migrate
SELECT COUNT(*), COUNT(phone_verified) FROM users;
-- → 1000000 | 0
-- chạy migrate + backfill batch
-- sau migrate
SELECT COUNT(*), COUNT(phone_verified) FROM users;
-- → 1000000 | 1000000
-- app staging boot ok, rollback.sql tồn tại
```

> Không có 2 con số COUNT này = chưa verify, dù model nói gì.

### Kịch bản 4: E2E trước release (playwright)

```bash
/verify --e2e
# → boot preview + chạy playwright 10 spec chính
# → paste video/screenshot failures (nếu có)
# → PASS mới tag release
```

---

## Rủi ro & lưu ý

### Tốn token / thời gian?

- Verify chạy build/test thật → 1–5 phút + tokens đọc log (~3–10K). Rẻ hơn hotfix production đêm Chủ nhật.
- E2E full có thể 10–20 phút — chỉ chạy trước release, không chạy sau mỗi bước nhỏ (bước nhỏ chỉ unit+lint).

### Destructive? (verify chạm gì?)

- Verify CHẠY code → có rủi ro thật: migration test chạm nhầm production DB, seed xóa dữ liệu, gửi SMS/email thật từ staging.
- Quy tắc an toàn:
  1. Verify trên staging/test DB, KHÔNG BAO GIỜ production connection string.
  2. `.env` verify dùng `.env.test` / `.env.staging`.
  3. Deny trong permissions: `Bash(*prod*)`, `Bash(*migrate*prod*)`.
  4. E2E gửi tiền/SMS: dùng sandbox key (Stripe test, MoMo sandbox).

### Version floor: /verify ≥2.1.145

- Bản cũ hơn không có skill verify → gõ báo `unknown`. Update: `npm i -g @anthropic-ai/claude-code`, xác nhận `claude --version` ≥2.1.145.
- Hành vi skill (pipeline steps) khác nhau theo bản + CLAUDE.md repo — đọc output nó chạy gì, đừng giả định.

### Provider thiếu gì?

- Bedrock/Vertex khóa Bash chạy build/test → verify không chạy được, chỉ đọc giấy. Fix: mở quyền Bash test trong `/permissions`, hoặc verify tay paste output cho evaluator đọc.
- Máy yếu (RAM 4GB): `next build` + `docker` cùng lúc có thể OOM — verify từng bước thay vì full pipeline.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/diff` → `/verify` | Duyệt mắt rồi chạy thật | `/diff` → `/verify` |
| `/goal` + `/verify` | Giám sát loop + chốt bằng chứng | `/goal ...` → làm → `/verify` |
| `/code-review` → `/verify` | Soi giấy rồi chạy thật | Review → sửa → `/verify` |
| `/plan` từng bước + `/verify` | Mỗi bước đều verify | Bước 1 → `/diff` → `/verify` → bước 2 |
| `/batch` + verify/worktree | Mỗi worktree tự verify | Mỗi batch prompt kèm "xong thì /verify" |

Workflow chuẩn "task nào cũng phải qua":

```bash
# 1. Làm (có plan/goal nếu lớn)
/plan ... (nếu lớn)
/goal ... (nếu dài)

# 2. Tự xem
/diff

# 3. Soi (nếu PR đáng kể)
/review
# hoặc /code-review

# 4. Chạy thật — BẮT BUỘC
/verify

# 5. Xanh mới push/merge
# git push / gh pr merge
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/verify` báo `skill not found` / unknown | Bản < 2.1.145 | Update CLI ≥2.1.145 |
| Verify chạy sai lệnh test (`npm` trong khi `pnpm`) | Chưa `/init`, CLAUDE.md thiếu/sai | `/init` lại hoặc sửa CLAUDE.md lệnh đúng rồi `/verify` lại |
| Verify FAIL vì port đã dùng (EADDRINUSE) | App dev cũ còn chạy nền | Kill process cũ (`lsof -ti:3000 \| xargs kill`), verify lại với port riêng |
| Verify chạm nhầm production DB | `.env` sai / connection string prod trong staging | Dừng ngay; kiểm tra DB prod có bị ghi không; từ nay `.env.test` riêng + deny `*prod*` |
| Verify xanh local nhưng CI đỏ | Khác Node/Python version, khác OS | Đồng bộ version (`.nvmrc`, Dockerfile); CI chạy `verify` tương đương |
| Verify 20 phút chưa xong (e2e nặng) | Chạy full e2e cho thay đổi nhỏ | Bước nhỏ chỉ unit+lint; e2e để trước release |
| Bash build bị `permission denied` | Permissions chặn Bash build | `/permissions` allow `Bash(npm run build:*)`, `Bash(docker:*)`... |
| Model bảo "verify pass" nhưng không paste output | Skill cũ / prompt tắt | Bắt paste: "paste toàn bộ output build+test+curl, không tóm tắt" |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../diff/README.md](../../code-repo/diff/README.md) — duyệt mắt trước khi chạy
  - [../review/README.md](../../code-repo/review/README.md) — soi nhanh trước verify
  - [../code-review/README.md](../../code-repo/code-review/README.md) — soi kỹ trước verify release
  - [../goal/README.md](../../model-mode/goal/README.md) — evaluator giữa + verify cuối
  - [../init/README.md](../../code-repo/init/README.md) — CLAUDE.md chuẩn thì verify mới chạy đúng lệnh
  - [../batch/README.md](../../code-repo/batch/README.md) — mỗi worktree verify riêng
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _không có output paste lên màn hình thì chưa gọi là verify — chỉ là lời hứa._
