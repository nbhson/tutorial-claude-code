# /rules — Quản lý quy ước modular: luật nào áp dụng cho file/thư mục nào

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (nhưng Có nếu rules mâu thuẫn nhau — model làm lúc đúng lúc sai khó debug)

`/rules` quản lý các file quy ước nhỏ (rules files) thay vì nhồi tất cả vào 1 file CLAUDE.md khổng lồ. Mỗi rule có `paths` (áp dụng cho đâu) + `frontmatter` (mô tả, độ ưu tiên), và chỉ được lazy-load khi bạn chạm vào file khớp pattern. Hiểu `/rules` là hiểu "luật giao thông theo khu vực" — vào khu nào thì tuân luật khu đó.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/rules` | _(không có)_ | Mở UI liệt kê/quản lý tất cả rules |
| `/rules show` | — | Liệt kê rules + paths + trạng thái |
| `/rules add <file>` | đường dẫn | Tạo rule mới (mở editor) |
| `/rules edit <tên>` | tên rule | Sửa rule |
| `/rules delete <tên>` | tên rule | Xoá rule (hỏi xác nhận) |
| File trực tiếp | `.claude/rules/*.md` | Sửa bằng Edit/Write như file thường |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở UI quản lý
/rules
```

```bash
# Dạng 2: liệt kê nhanh
/rules show
```

```bash
# Dạng 3: tạo rule mới cho thư mục API
/rules add api-conventions
```

```bash
# Dạng 4: sửa file rule trực tiếp (copy-paste)
# File: .claude/rules/python.md
```

```markdown
---
paths: ["**/*.py"]
priority: high
description: Quy ước Python toàn repo
---

- Chạy bằng `uv run`, không dùng pip trực tiếp.
- Format bằng `ruff`, dòng tối đa 100 ký tự.
- Mọi hàm public phải có docstring tiếng Việt.
```

```bash
# Dạng 5: rule chỉ cho 1 thư mục
# File: .claude/rules/api-only.md
```

```markdown
---
paths: ["api/**/*.py"]
description: Riêng thư mục api dùng FastAPI
---

- Dùng FastAPI + Pydantic v2, không dùng Flask.
- Mọi endpoint phải có response_model.
- Test đặt cạnh code: test_<tên>.py.
```

---

## Cách nó hoạt động

### Cơ chế sâu: rules paths + frontmatter + lazy-load ra sao?

1. **Cấu trúc 1 rule file:**
   - `frontmatter` (YAML đầu file giữa 2 dòng `---`): chứa `paths`, `priority`, `description`.
   - `body` (markdown bên dưới): nội dung luật, càng cụ thể càng tốt ("dùng `uv run`" hơn "viết code sạch").
   - Ví dụ frontmatter đầy đủ:
     ```yaml
     ---
     paths: ["src/**/*.ts", "tests/**/*.ts"]
     priority: high       # low | normal | high — khi 2 rules mâu thuẫn, high thắng
     description: Quy ước TypeScript
     ---
     ```
2. **Paths matching (glob):**
   - `"**/*.py"` = mọi file Python trong repo.
   - `"api/**/*.py"` = chỉ file Python dưới `api/`.
   - `"*.md"` = chỉ file Markdown ở root (không gồm subfolder).
   - `"src/**/*.{ts,tsx}"` = TypeScript trong `src/`.
   - Một file có thể khớp NHIỀU rules cùng lúc → merge tất cả (xem mục 4).
3. **Lazy-load (nạp lười) — điểm ăn tiền so với CLAUDE.md:**
   - Khởi động session: Claude chỉ đọc DANH SÁCH rules (tên + description + paths, ~10-20 token/rule), KHÔNG đọc body.
   - Khi bạn mở/sửa file `api/users.py`: engine kiểm tra paths → thấy khớp `python.md` + `api-only.md` → mới nạp body 2 rules đó vào context.
   - Mở file `README.md`: không khớp rule Python → không nạp → tiết kiệm token.
   - Kết quả: repo 20 rules nhưng mỗi task chỉ nạp 1-2 rules liên quan. CLAUDE.md nhồi 20 luật thì task nào cũng trả tiền cho cả 20.
4. **Merge khi nhiều rules cùng khớp:**
   - Nối body các rules theo thứ tự `priority` (low → high), high xuống cuối (thắng khi mâu thuẫn diễn giải).
   - Nếu 2 rules mâu thuẫn trực tiếp ("dùng jest" vs "dùng vitest"): model ưu tiên rule có `paths` cụ thể hơn (dài hơn, sâu hơn). `api/**/*.py` thắng `**/*.py`.
   - Nếu vẫn hoà: model hỏi bạn thay vì đoán.
5. **Thứ tự ưu tiên tổng (từ thấp tới cao):**
   - `CLAUDE.md root` < `rules (priority low → high)` < `memory project` < `chỉ thị trực tiếp trong chat`.
   - Nghĩa là câu bạn gõ trong chat luôn thắng mọi rule. Rule chỉ là mặc định khi bạn không nói gì.
6. **Lưu ở đâu?**
   - Project: `.claude/rules/*.md` (commit git → team cùng hưởng).
   - User: `~/.claude/rules/*.md` (riêng bạn, mọi repo).
   - Enterprise: policy rules (IT đẩy, bạn chỉ đọc).
7. **Vòng đời:**
   - `tạo` (`/rules add` hoặc Write file) → `khớp paths` → `lazy-load khi chạm file` → `cũ` → `sửa/xoá`.
   - Đổi paths mà không test → rule "chết" (không bao giờ khớp). Dùng `/rules show` kiểm tra.

### Sơ đồ lazy-load

```text
Session start: chỉ nạp [tên + paths] 20 rules (~300 token)
  ↓
Bạn mở api/users.py
  ↓
Engine match paths:
  python.md (paths **/*.py)       → KHỚP → nạp body (200 token)
  api-only.md (paths api/**)      → KHỚP → nạp body (150 token)
  frontend.md (paths web/**)      → KHÔNG khớp → bỏ qua (0 token)
  ↓
Context task này: 350 token rules (thay vì 4000 token nếu nhồi hết vào CLAUDE.md)
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Phạm vi | Nạp khi nào? | Dùng khi nào? |
|---|---|---|---|
| `/rules` | Theo paths, modular | Lazy (khi chạm file khớp) | Quy ước theo thư mục/ngôn ngữ |
| `CLAUDE.md` | Toàn repo, 1 file | Luôn (mỗi session) | Kiến trúc, lệnh build/test chung |
| `/memory` | User/project, từng mục | Luôn (nếu active) | Sở thích cá nhân |
| Skill | Theo tác vụ (mô tả trigger) | Khi model thấy khớp việc | Quy trình nhiều bước |

> Quy tắc ngón tay cái:
>
> - **Luật chung toàn repo → CLAUDE.md. Luật theo khu vực/ngôn ngữ → `/rules`. Sở thích cá nhân → `/memory`.**

---

## Ví dụ thực tế

### Kịch bản 1: Tách CLAUDE.md 300 dòng thành 4 rules gọn

CLAUDE.md cũ nhồi Python + API + frontend + SQL vào 1 file (mỗi session tốn 3k token):

```bash
# Bước 1: tạo 4 file rules
/rules add python
/rules add api
/rules add frontend
/rules add sql
```

```markdown
<!-- File: .claude/rules/python.md -->
---
paths: ["**/*.py"]
priority: normal
---

- Dùng `uv run`, format `ruff` (dòng 100).
```

```markdown
<!-- File: .claude/rules/api.md -->
---
paths: ["api/**/*.py"]
priority: high
---

- FastAPI + Pydantic v2, endpoint nào cũng có response_model.
```

```markdown
<!-- File: .claude/rules/frontend.md -->
---
paths: ["web/**/*.{ts,tsx}"]
priority: normal
---

- React + Tailwind, component < 150 dòng, tách hook riêng.
```

```markdown
<!-- File: .claude/rules/sql.md -->
---
paths: ["**/*.sql", "migrations/**"]
priority: high
---

- Không DELETE không WHERE. Migration nào cũng có down script.
```

> Kết quả: CLAUDE.md rút còn ~30 dòng (kiến trúc + lệnh chung). Task frontend chỉ nạp rule frontend, không trả tiền cho luật SQL.

### Kịch bản 2: Rule chặn lỗi nguy hiểm theo thư mục (migrations)

```markdown
---
paths: ["migrations/**", "**/*.sql"]
priority: high
description: Luật an toàn DB — vi phạm là từ chối
---

- CẤM `DROP TABLE` / `TRUNCATE` khi chưa có xác nhận chữ "ĐỒNG Ý" của user trong chat.
- Mọi migration phải có cả up + down, test rollback trên DB rỗng trước.
- Không hardcode connection string, đọc từ env.
```

> Kết quả: model tự từ chối viết migration thiếu down script, dù bạn quên dặn.

### Kịch bản 3: Rule paths cụ thể thắng rule chung (monorepo)

```markdown
<!-- .claude/rules/all-ts.md — paths: ["**/*.ts"], priority: normal -->
- Dùng vitest cho mọi test TypeScript.
```

```markdown
<!-- .claude/rules/legacy.md — paths: ["legacy/**/*.ts"], priority: high -->
- Thư mục legacy/ vẫn dùng jest (đừng migrate, đang đóng băng).
- Chỉ sửa khi fix bug, không refactor.
```

> Kết quả: mở `src/a.ts` → nạp vitest. Mở `legacy/b.ts` → nạp cả 2, legacy thắng → dùng jest. Không cần nhắc tay từng lần.

### Kịch bản 4: Debug rule không ăn (paths sai)

Triệu chứng: tạo rule `docs.md` paths `["docs/*"]` nhưng sửa `docs/api/auth.md` model không tuân.

```bash
# Bước 1: kiểm tra
/rules show
# → docs.md paths ["docs/*"] — chỉ khớp file trực tiếp dưới docs/, KHÔNG khớp subfolder!

# Bước 2: sửa paths
# docs/* → docs/**/*
```

```markdown
---
paths: ["docs/**/*"]
description: Quy ước docs (đã fix khớp subfolder)
---

- Mọi bài tiếng Việt, code copy-paste được, mỗi README đủ 8 mục.
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào?

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Hai rules mâu thuẫn (jest vs vitest) | Model làm lúc này lúc kia, test vỡ ngẫu nhiên | Đặt `priority`, paths cụ thể cho ngoại lệ; `/rules show` rà soát định kỳ |
| Paths quá rộng (`**/*`) | Rule nào cũng nạp → mất tác dụng lazy-load, tốn token như CLAUDE.md | Paths càng hẹp càng tốt; rule chung để vào CLAUDE.md thay vì rules |
| Paths quá hẹp/sai glob | Rule "chết", không bao giờ kích hoạt | Test ngay sau khi tạo: mở 1 file đáng lẽ khớp, hỏi model "em thấy rule gì?" |
| Rule viết chung chung ("viết code sạch") | Model diễn giải tuỳ hứng, không kiểm chứng được | Viết cụ thể, đo được: tên tool, lệnh, số dòng, ví dụ đúng/sai |
| Commit rule chứa đường dẫn nội bộ nhạy cảm | Lộ cấu trúc hệ thống nội bộ nếu repo public | Chỉ commit quy ước chung; paths nhạy cảm để ở user rules local |

### Tốn token?

- Danh sách rules: ~10-20 token/rule — 20 rules ≈ 300 token cố định. Rẻ.
- Body chỉ nạp khi khớp: mỗi body 100-300 token. Task thường nạp 1-2 bodies.
- So với nhồi 300 dòng vào CLAUDE.md (3k token/session): rules tiết kiệm 70-90% cho repo lớn.

### Version / provider

- `/rules` + `.claude/rules/`: bản v1.0.80+ (đầu 2025). Bản cũ hơn chỉ có CLAUDE.md.
- Frontmatter `priority`: bản v2.x. Bản cũ không có → mâu thuẫn thì model hỏi tay.
- Bedrock/Vertex: rules vẫn local, nạp vào prompt như thường.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/rules` + `CLAUDE.md` | Chung + riêng | CLAUDE.md giữ kiến trúc; rules giữ luật từng khu vực |
| `/rules` + `/memory` | Team + cá nhân | Rules commit cho team; memory giữ sở thích riêng |
| `/rules` + `/doctor` | Audit phình | `/doctor` báo CLAUDE.md dài → tách thành rules |
| `/rules` + `/agents` | Subagent tuân luật khu vực | Agent sửa `api/` tự nạp rule api |
| `/rules` + `/verify` | Verify theo luật khu vực | Verify check test đúng framework của từng thư mục |

Workflow chuẩn "tách CLAUDE.md phình":

```bash
# 1. Audit
/doctor
# → báo CLAUDE.md 320 dòng, gợi ý tách

# 2. Tách thành rules theo khu vực
/rules add python
/rules add api
/rules add frontend

# 3. Rút CLAUDE.md còn kiến trúc + lệnh chung (~30 dòng)

# 4. Kiểm tra
/rules show
# Mở thử 1 file api/ → hỏi model "em đang áp dụng rules nào?"
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Tạo rule mà model không tuân | Paths sai/không khớp file đang sửa | `/rules show` kiểm tra glob; test `docs/*` vs `docs/**/*` |
| Hai rules đánh nhau | Mâu thuẫn nội dung, không priority | Thêm `priority: high` cho ngoại lệ; paths cụ thể hơn thắng |
| Rule nạp chậm/không ổn định | Body quá dài (>500 dòng), model bỏ qua phần cuối | Tách rule lớn thành 2-3 rules nhỏ, mỗi cái <200 dòng |
| `/rules` báo unknown command | Bản CLI quá cũ | Update lên v2.x mới nhất |
| Rule local đè nhầm rule team | User rules trùng paths với project rules | Đặt user rules paths hẹp hơn, hoặc tắt tạm khi làm team task |
| Xoá file rule mà model vẫn tuân | Session cũ đã nạp, chưa `/clear` | `/clear` để nạp lại danh sách rules |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../memory/README.md](../../knowledge-system/memory/README.md) — bộ nhớ dài hạn, nạp luôn (không lazy)
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — audit và tách CLAUDE.md thành rules
  - [../init/README.md](../../code-repo/init/README.md) — sinh CLAUDE.md ban đầu
  - [../agents/README.md](../../knowledge-system/agents/README.md) — subagent có thấy rules không
  - [../verify/README.md](../../code-repo/verify/README.md) — kiểm tra tuân thủ rules
  - [../compact/README.md](../../session-context/compact/README.md) — rules có bị compact mất không (không)
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md) — bài gốc về 3 tầng tri thức
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — rules vs skills khác gì
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md) — rules trong multi-agent
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md) — enforce rules bằng hooks
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md) — MCP tools có tuân rules không
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md) — plugin mang rules riêng

> Mẹo 1 dòng: _luật chung nhét CLAUDE.md, luật theo khu vực tách `/rules` paths hẹp, paths sai là rule chết._
