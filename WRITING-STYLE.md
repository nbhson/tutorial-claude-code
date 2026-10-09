# Quy chuẩn viết cho repo Khóa Học Claude Code

> File này trả lời 2 câu hỏi: **(1) viết thế nào cho người đọc hiểu**, **(2) dữ kiện nào đang được coi là đúng**.
> Mọi file `.md` trong repo phải tuân file này. Trước khi sửa hoặc thêm nội dung, đọc hết phần A.
> Cần tra nhanh version/model/giá → nhảy thẳng [Phần B — Dữ kiện chuẩn](#phần-b--dữ-kiện-chuẩn-làm-tròn-thời-gian-07102026).

---

## Mục A — Quy chuẩn viết

### A0. Tài liệu này cho ai?

Bốn nhóm người đọc, ưu tiên theo thứ tự:

| Ưu tiên | Người đọc | Họ cần gì ở file |
|---|---|---|
| 1 | Dev mới nghe tên Claude Code | Vào file là biết **có nên đọc tiếp không**, đọc xong **làm được gì** |
| 2 | Dev đã dùng nhưng hay bị lỗi | Tra nhanh được **lệnh → cách gọi → lỗi thường gặp → cách fix** |
| 3 | Tech lead chuẩn hóa cho team | Copy được **quy tắc, template, checklist** về team ngay |
| 4 | Người Việt đọc tiếng Anh chưa giỏi | **Không phải đoán** thuật ngữ Anh giữa chừng |

Nguyên tắc chung: **viết cho người đọc nhóm 1, dày đủ cho nhóm 3.** Đừng viết cho tác giả.

---

### A1. Năm nguyên tắc nền

1. **Mỗi file phải có "lối vào".** Trong 10 dòng đầu, người đọc phải trả lời được 3 câu:
   *File này cho ai? Cần gì trước? Đọc xong làm được gì?*
2. **Mỗi section phải có mục tiêu.** Câu đầu của section phải nói section này trả lời câu gì.
   Không mở đầu bằng dữ kiện rồi mới để người đọc tự đoán chủ đề.
3. **Không mất nội dung.** Khi viết lại: mọi bảng, mọi ví dụ, mọi lệnh, mọi bài tập, mọi link
   trong bản cũ phải còn — trừ khi trùng lặp *nội dung y hệt* thì gộp và ghi rõ đã gộp.
4. **Không lặp cùng một nội dung 2 lần trong 1 file.** Bảng nào đã có ở mục A thì không hiện lại
   y hệt ở mục B; câu trả lời không được in ở cả "Trả lời 1 câu" và "Giải thích".
5. **Dữ kiện phải có nguồn + ngày.** Xem [A9](#a9-quy-tắc-chống-out-date).

---

### A2. Khung mở đầu file (bắt buộc)

Mọi bài viết (folder `01-`, `02-`, `03-`) mở đầu theo đúng khung này:

```markdown
# <Tên bài viết hoa thường, KHÔNG title-case từng chữ>

> **Bài này cho ai:** <1 dòng — ai nên đọc>
> **Cần gì trước:** <1 dòng — cài gì / đọc gì, hoặc "không có">
> **Đọc xong bạn làm được:** <2–4 gạch đầu dòng cụ thể, mỗi dòng là 1 việc làm được>
> **Thời gian:** ~<N> phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| <term> | <1 câu tiếng Việt, không thuật ngữ Anh chồng thuật ngữ Anh> | <lệnh/hình ảnh đời thường> |

## Mục lục
...
```

Quy tắc riêng:

- **Glossary ở đầu file, không ở cuối.** Người mới gặp thuật ngữ lạ ở dòng 30 thì phải tra
  ngay được ở dòng 5, không phải lội xuống mục 9.
- **Tiêu đề tiếng Việt viết thường** (trừ tên riêng): `Tổng quan Claude Code`, không
  `Tổng Quan Claude Code: Tư Duy Agent, Không Phải Chatbot`.
- Khối `> **Bài này cho ai:**` dùng blockquote `>` để tách khỏi nội dung.

---

### A3. Cấu trúc theo từng loại file

| Loại file | Cấu trúc bắt buộc | Ghi chú |
|---|---|---|
| Bài hướng dẫn `01-huong-dan-su-dung/NN-*.md` | Lối vào (A2) → Mục lục → Lý do/cơ chế → Cách làm + ví dụ copy-paste → Bảng tra → Hiểu nhầm → Bài tập → Link chéo | Section lý thuyết không dài quá 60 dòng phải có ví dụ |
| Tips `02-tips-thuc-chien/NN-*.md` | Lối vào (A2) → Mục lục → Vì sao quan tâm → ≥3 ví dụ copy-paste → Walkthrough theo phút → Bảng so sánh → Bài tập → Link chéo | Mọi claim "tiết kiệm/tốt hơn" phải kèm con số hoặc ví dụ |
| FAQ `03-cau-hoi-thuong-gap/NN-*.md` | Lối vào (A2) → Bảng chọn đường vào + 1 mermaid → Câu hỏi (khung 5 khối, xem A7) → "Vẫn lỗi thì sao" → Link chéo | Mỗi file ≥1 mermaid + ≥1 bảng tổng hợp |
| Lệnh `01-huong-dan-su-dung/commands/**/README.md` | Khung 7 mục (xem A6) | 30–60 dòng, không dài hơn |
| README index (root, folder) | Mục tiêu folder → Bảng danh sách file + 1 dòng mô tả → Lộ trình đọc → Link tra cứu | |
| Template `templates/` | Dùng được ngay → Giải thích 1 dòng mỗi phần → Cách sửa | |

**Không được** nhét nội dung không thuộc chủ đề vào một section chỉ vì "chưa có chỗ".
Ví dụ sai (đã từng có): mục `## Bài tập cuối bài` lại chứa bảng thuật ngữ, sơ đồ mermaid và
bảng hiểu nhầm. Nội dung đó phải là các mục riêng đứng ngang hàng.

---

### A4. Quy tắc section

- **Câu đầu section = mục tiêu section.** Đúng hay sai:
  - Đúng: `## 4. Vì sao CLAUDE.md phình làm bạn tốn tiền?` → mở đầu `Mỗi turn, model nạp lại toàn bộ CLAUDE.md...`
  - Sai: `## 4. Token economics — tiền của bạn đi đâu?` rồi vào ngay bảng số.
- **Section quá dài → chia mục con `###`.** Ngưỡng: >80 dòng hoặc >3 ý.
- **Mỗi section kết bằng thứ người đọc làm được** (lệnh chạy, checklist, hoặc ví dụ), không kết bằng lý thuyết suông.
- Số thứ tự mục phải liên tục, không nhảy, không có mục con "mồ côi" (11.5 nằm dưới 11.1... nhưng nội dung không liên quan bài tập).

---

### A5. Quy tắc từ ngữ & giọng chữ

**Giọng: xưng "bạn", thân thiện, trung tính.** Duy nhất 1 ngôi throughout file.

| Dùng | Không dùng | Lý do |
|---|---|---|
| `bạn` | `mày`, `tao`, `thằng em` | Giọng khẩu ngữ trộn trang trọng gây khó đọc |
| `Claude tự đọc file` | `nó tự đọc file` | `nó` thiếu chủ ngữ rõ ràng |
| Prompt mẫu bên trong code block giữ nguyên khẩu ngữ | — | Prompt là chuỗi lệnh, không phải văn viết |

**Tiếng Anh和技术词:**

- Lệnh, tên tool, tên file, tên config: giữ nguyên tiếng Anh — `claude`, `/clear`, `CLAUDE.md`, `PreToolUse`, `subagent`, `worktree`, `hook`, `MCP`.
- Thuật ngữ chuyên ngành lần đầu xuất hiện: **giải thích 1 câu ngay lần đầu**, sau đó dùng thoải mái.
  Ví dụ: `**Context window** (bộ nhớ tạm của model, hết chỗ là model dở) ...`
- Thuật ngữ chỉ để trang trí thì dịch hoặc bỏ: `context hygiene` → `vệ sinh context`;
  `surfaces` → `bề mặt sử dụng (surface)`; `front-load` → `đặt lên đầu`.
- **Không title-case tiếng Việt**: `Bài Tập Thực Hành` ❌ → `Bài tập thực hành` ✅.
- Câu hỏi tiếng Anh trộn trong tiêu đề: gộp lại cho hết câu, ví dụ
  `## 2. Agentic loop deep-dive (why, không chỉ what)` → `## 2. Vòng lặp agent hoạt động ra sao, vì sao phải hiểu?`

---

### A6. Quy tắc 7 mục của file lệnh `commands/`

Giữ nguyên khung hiện tại, chỉ viết lại cho dễ:

1. `# /tên-lệnh — mô tả 1 dòng bằng câu hoàn chỉnh`
2. `> Loại ... · Nhóm ... · Mức rủi ro ...` rồi `> **Nói nôm na:** 1–2 câu.` (không quote 2 đoạn rời rạc như bản cũ)
3. `## Khi nào dùng` — 3 gạch: đúng việc / dùng trước khi phình to / không thay thao tác tay.
4. `## Cách gọi` — code block 2–3 dạng + 1 dòng ghi chú kiểm tra lệnh có ở máy bạn không.
5. `## Ví dụ thật + kết quả mong đợi + cách kiểm tra` — prompt dán được + mong đợi + verify ≤30 giây.
6. `## Lỗi thường gặp` — bảng 3 cột `Triệu chứng | Vì sao | Cách sửa`, 2–3 dòng.
7. `## Tham khảo` — 3–4 link + kết thúc bằng `> Mẹo 1 dòng: _..._`.

---

### A7. Quy tắc FAQ (5 khối)

Khung 5 khối giữ nguyên, nhưng:

- **`Trả lời 1 câu` phải là câu trả lời thật, không phải nhãn dán chung với `Giải thích`.**
  Sai (đã từng có): cả 2 khối đều là `Có 2 đường vào chính, đừng nhầm:` rồi mới giải thích.
  Đúng:
  - `**Trả lời 1 câu:** Dùng tài khoản claude.ai (Pro/Max) hoặc API key — chọn 1 trong 2.`
  - `**Giải thích:** Hai đường vào khác nhau ở chỗ trả tiền và tính năng...`
- `**Hỏi ngắn gọn:**` không được copy nguyên văn tiêu đề `##` — viết lại theo cách người mới actually gõ.
- Không lặp cụm từ y hệt ở 2 khối liên tiếp.
- Sửa mọi bảng markdown hỏng (thiếu ô, `|---|` lẻ) trước khi ghi file.

---

### A8. Quy tắc Verify, ví dụ, bảng, code block

**Verify:** nội dung "kiểm tra xong thấy gì" là **bắt buộc giữ**, nhưng cách bày:

| Bắt buộc | Cách bày |
|---|---|
| Không chèn blockquote `> Kỳ vọng / Verify` giữa đoạn văn liên tục >2 lần liên tiếp | Gom thành **1 khối `**Kiểm tra nhanh:**`** ở cuối section, gộp các bước verify liên quan vào đó |
| Giữ nguyên mọi câu "làm xong thấy gì" | Có thể viết lại lời, không được bỏ thông tin |
| Code block | Giữ nguyên hành vi lệnh; comment trong codeblock tiếng Việt không dấu |

**Bảng:**
- Đảm bảo mọi dòng có cùng số cột (check bằng mắt trước khi ghi).
- Không lặp bảng identical trong 1 file → gộp, hoặc xóa bản thứ 2 và trỏ link `xem mục X`.
- Bảng lớn >8 dòng → thêm 1 dòng dẫn "đọc bảng này khi cần X".

**Code block:**
- Mõm đầu block ghi ngôn ngữ (`bash`, `text`, `json`, `mermaid`).
- Mọi lệnh phải copy-paste được; secret qua `${ENV}`, không hardcode.

---

### A9. Quy tắc link chéo

- Link nội bộ: đường dẫn **tương đối**, không hardcode tên miền.
- Mỗi bài ≥3 link chéo tới bài/commands liên quan (giữ yêu cầu hiện tại của `CONTRIBUTING.md`).
- Không được đổi tên file/mục mà không sửa toàn bộ link trỏ tới (grep toàn repo trước khi đổi).
- Anchor mục lục phải khớp heading sau khi đổi tiêu đề (kiểm tra lại TOC).

---

### A10. Quy tắc chống out-date

1. **Số version, model, giá, tính năng mới** → tra mục B trước khi viết. Nếu chưa có trong mục B,
   phải tự tra nguồn chính thức (liệt kê A10.1) và **bổ sung vào mục B kèm ngày**.
2. Mọi khẳng định theo version phải ghi **bản tối thiểu** (`cần ≥2.1.252`).
3. Nguồn chính thức, theo thứ tự tin cậy:
   1. https://code.claude.com/docs/en/changelog — lịch sử release chính chủ
   2. https://code.claude.com/docs/en/whats-new — tóm tắt theo tuần (2026-wNN)
   3. https://code.claude.com/docs/llms.txt — index toàn bộ docs
   4. https://platform.claude.com/docs/en/about-claude/pricing — giá model API
   5. https://claude.com/pricing — giá gói subscription
   6. https://github.com/anthropics/claude-code/releases — release notes GitHub
4. Nếu một tính năng **đã bị gỡ** (ví dụ `/ultraplan` bị gỡ tháng 8/2026) → ghi rõ "đã bị gỡ,
   thay bằng X" thay vì giữ hướng dẫn.
5. Không viết "sắp ra mắt" trừ khi có ngày công bố chính thức; viết `(tháng 9/2026)` cho mọi
   dự kiến.

---

### A11. Checklist bắt buộc trước khi ghi file (không mất nội dung)

Tick đủ trước khi kết thúc lượt sửa 1 file:

- [ ] Đủ khối **lối vào** (A2) đúng khung.
- [ ] Glossary (nếu file có thuật ngữ Anh mới) nằm **trước** chỗ dùng đầu tiên.
- [ ] Không còn mục gãy: mọi mục con đều thuộc chủ đề của mục cha.
- [ ] Không còn nội dung trùng lặp y hệt trong cùng file.
- [ ] Mọi bảng hợp lệ (số cột đều), mọi heading có anchor TOC khớp.
- [ ] Đếm lại trước/sau: số code block, số bảng, số link ≥ bản cũ (hoặc ghi rõ đã gộp ở đâu).
- [ ] Số/version/giá đối chiếu mục B, có ghi bản tối thiểu cho tính năng version-gated.
- [ ] Giọng "bạn" đồng nhất, không còn `mày/tao/nó` ngoài prompt mẫu.
- [ ] Tiếng Việt không title-case.

---

## Phần B — Dữ kiện chuẩn (làm tròn thời gian: 07/10/2026)

> Mục này là **nguồn sự thật chung** cho mọi file trong repo. Khi viết lại nội dung, đối chiếu vào đây.
> Cập nhật bằng cách thêm dòng mới **có ngày**, không xóa dòng cũ đang còn đúng.

### B1. Claude Code — phiên bản & tài liệu

| Hạng mục | Giá trị chuẩn (07/10/2026) |
|---|---|
| Phiên bản mới nhất | **v2.1.292** (phát hành 06/10/2026) |
| Docs chính thức | https://code.claude.com/docs/en/ |
| Changelog | https://code.claude.com/docs/en/changelog |
| What's new theo tuần | https://code.claude.com/docs/en/whats-new (vd `2026-w36`, `2026-w37`) |
| File index toàn docs | https://code.claude.com/docs/llms.txt |
| GitHub releases | https://github.com/anthropics/claude-code/releases |
| Kiểm tra bản đang cài | `claude --version` (ngoài terminal), `/status` hoặc `/doctor` (trong session) |
| Cách update | `claude update` — **update trước, debug sau** |

### B2. Model (giá API, USD / 1 triệu tokens)

| Model | Input | Output | Cache read | Context | API ID | Ghi chú |
|---|---|---|---|---|---|---|
| Claude Fable 5.1 | $10 | $50 | $0.25 | 1M | `claude-fable-5-1` | Alias `fable`; cần ≥2.1.257; mạnh nhất, chậm nhất |
| Claude Opus 5.5 | $4 | $20 | $0.20 | 1M | `claude-opus-5-5` | Cần ≥2.1.280; **mặc định ở hầu hết gói** (từ 22/09/2026); fast mode $8/$40 (~2.5× nhanh) |
| Claude Sonnet 5.5 | $2 | $10 | $0.20 | 1M | `claude-sonnet-5-5` | Mặc định Sonnet trên API; rẻ hơn tới 30%/task so Sonnet 5 |
| Claude Sonnet 5 | $2 | $10 | $0.20 | 1M | `claude-sonnet-5` | Mặc định ở Pro/Team Standard/Employment seat |
| Claude Haiku 4.5 | $1 | $5 | $0.10 | 200K | `claude-haiku-4-5-20251001` | Nhanh nhất, không hỗ trợ effort |
| Claude Haiku 5.5 | — | — | — | — | — | Anthropic công bố "trong vài tuần" (từ 22/09/2026) — **chưa có giá, chưa dùng** |

Nguồn: platform.claude.com/docs/en/about-claude/pricing + anthropic.com/claude-opus-5-5 +
anthropic.com/claude-sonnet-5-5 (tra 07/10/2026).

### B3. Gói subscription (claude.com/pricing, tra 07/10/2026)

| Gói | Giá | Claude Code? | Ghi chú |
|---|---|---|---|
| Free | $0 | ❌ | Không có Claude Code |
| Pro | $17/tháng (trả trước năm) hoặc $20/tháng | ✅ | Ít nhất 5× Free theo phiên 5 giờ |
| Max 5x | $100/tháng | ✅ | 5× Pro theo phiên 5 giờ |
| Max 20x | $200/tháng | ✅ | 20× Pro theo phiên 5 giờ |
| Team (Standard) | $20/tháng năm, $25/tháng | ✅ | Tối thiểu 2 ghế, tối đa 150 |
| Team (Premium) | $100/tháng năm, $125/tháng | ✅ | 5× Standard |

- Hạn mức tính theo **phiên 5 giờ cuộn** + **hạn tuần**; chat web + Claude Code dùng chung 1 hạn mức.
- Hết hạn mức → chờ reset, nâng gói, hoặc bật **usage credits** (trả theo giá API).
- (06/5/2026) Anthropic đã **nhân đôi** hạn mức 5 giờ của Claude Code cho Pro/Max/Team/Enterprise
  và bỏ giảm hạn mức giờ cao điểm.

### B4. Tính năng mới đáng cập nhật (2026)

| Tính năng | Bản cần có / thời điểm | Ý nghĩa với người học |
|---|---|---|
| `claude agents` — 1 màn hình cho mọi session | ≥2.1.139 (w20/2026) | Quản lý session nền, dạng bảng trạng thái |
| `/goal` — chạy tới khi điều kiện xong | ≥2.1.139 | Đặt tiêu chí "xong là gì", agent tự chạy tiếp |
| Auto mode — classifier duyệt quyền thay bạn | w13/2026 → server-side classifier (w34/2026) | Trung gian giữa "hỏi từng bước" và `--dangerously-skip-permissions` |
| `/cd` — đổi thư mục trong session | ≥2.1.169 | Không phải mở lại session |
| Subagent spawn subagent (tối đa 5 cấp) | w24/2026 | Chia việc lồng nhau |
| `/code-review` — review chạy nền | w21/2026 | Review PR/branch bằng subagent |
| `/skill-doctor` — tìm skill không dùng | ≥2.1.252 (w36/2026) | Mỗi skill đều tốn context mọi turn → dọn skill ế |
| `/diff` panel sống cạnh chat | ≥2.1.260 (w36/2026) | Xem thay đổi realtime, chọn dòng để prompt tiếp |
| Fork mode bật mặc định (subagent hưởng nguyên context) | ≥2.1.232 (w33/2026) | Việc phụ không phải giải thích lại từ đầu; tắt bằng `CLAUDE_CODE_FORK_SUBAGENT=0` |
| `/design` (nghiên cứu) — canvas artboard trong CLI | ≥2.1.234 | Mô tả ý tưởng → chọn layout → code |
| `TodoWrite`/`TaskCreate` bị gỡ khỏi model Opus 4.8, Sonnet 5, Fable 5... | w33/2026 | Bật lại bằng `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` |
| `AGENTS.md` đọc trực tiếp, không cần `CLAUDE.md` | w34/2026 | Chuẩn chéo công cụ (Cursor, Codex...) chạy song song |
| Skill tên đúng `verify` → tự chạy trước mỗi commit | w34/2026 | Viết 1 skill `verify` = có pre-commit check |
| `claude plugin eval`, `claude plugin install --marketplace` | ≥2.1.269 / ≥2.1.292 | Đánh giá plugin trước khi tin |
| Mods (plugin sửa giao diện Claude Code) | 2026 | Trust bar cao hơn plugin thường — chỉ cài đã audit |
| MCP mặc định negotiate protocol `2026-07-28` | ≥2.1.292 | Tương tác MCP mới hơn với mọi provider |
| **`/ultraplan` đã bị gỡ** | w32/2026 (03–07/8/2026) | Thay bằng plan mode hoặc Claude Code trên web |

### B5. Sự thật lâu dài (ít đổi, vẫn dùng)

- **Harness ≠ model.** Model sinh text + tool call; CLI (harness) mới là thứ đọc/ghi file, chạy
  lệnh, enforce permission, chạy hook, rồi đưa kết quả vào lại context.
- **CLAUDE.md nạp lại mỗi turn** → giữ <200 dòng. Quy tắc này là token economics, không phải thẩm mỹ.
- **Skill chỉ load tên+mô tả (~100 tokens) lúc start**, load body khi được gọi → checklist dài
  nên tách thành skill thay vì nhét CLAUDE.md.
- **Hook chạy ngoài model → 0 token model và bắt buộc thực thi** → rule quan trọng nên nâng thành hook.
- **Subagent có context riêng** → hợp việc nghiên cứu ồn; mỗi lần spawn tốn overhead (số liệu cộng
  đồng ~20K tokens — ghi rõ đây là số ước tính cộng đồng, không phải số chính thức).
- **Hạn mức MCP tools hiển thị ≈10, servers thực dùng 3–6** (ngưỡng thực nghiệm cộng đồng).
- **Quy tắc 15 turn**: task >15 turn không tiến triển → dừng, `/clear`, chia nhỏ (kinh nghiệm
  thực tế, không phải số chính thức của Anthropic).

### B6. Lệnh quen thuộc — bản tối thiểu (tra nhanh)

| Lệnh | Bản tối thiểu | Ghi chú |
|---|---|---|
| `/goal` | ≥2.1.139 | Điều kiện hoàn thành |
| `/verify` | ≥2.1.145 | Chạy app thật + paste kết quả |
| `/cd` | ≥2.1.169 | Đổi working dir trong session |
| `/subtask` | ≥2.1.212 | Việc phụ không làm hỏng mạch chính |
| `/skill-doctor` | ≥2.1.252 | Skill tốn context, skill ít dùng |
| `fable` → Fable 5.1 | ≥2.1.257 | |
| `/diff` panel | ≥2.1.260 | Cần terminal ≥110 cột + git repo |
| `claude plugin eval` | ≥2.1.269 | |
| Opus 5.5 (mặc định) | ≥2.1.280 | |
| Trim CLAUDE.md trong `/doctor` | ≥2.1.206 | |

> Mọi lệnh: gõ `/` trong session để xem máy bạn có không — version/provider khác nhau hiện khác nhau.
