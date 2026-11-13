# 13 — Code intelligence (LSP) + OpenTelemetry metrics — tìm hooks chậm, skills ngốn context

> **Bài này cho ai:** dev làm typed languages (TypeScript/Python/Go/Rust...) muốn Claude hiểu code sâu hơn grep, hoặc team muốn đo session bằng metrics thay vì đoán.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](./01-cai-dat-va-xac-thuc.md)); repo có type config (`tsconfig.json`/`go.mod`/`pyrightconfig.json`...) thì LSP mới có việc để làm.
> **Đọc xong bạn làm được:** cài + bật LSP, dùng jump-to-definition / find references / rename / diagnostics thay grep mù; bật OpenTelemetry (console trước, collector team sau); dùng metrics bắt hook chậm + skill ngốn context, fix xong đo lại trước/sau để có bằng chứng.
> **Thời gian:** ~45 phút

## Thuật ngữ

| Thuật ngữ | Nôm na 1 câu | Ví dụ kỹ thuật thật | Cách verify |
|---|---|---|---|
| LSP (Language Server Protocol) | Từ điển sống của code: hỏi hàm ở đâu là chỉ đúng file:dòng — như Google Maps cho code | `npm i -g typescript typescript-language-server`, hỏi Claude "jump to definition hàm login trong src/auth.ts" | Trả về 1 `file:dòng` chính xác thay vì 20 kết quả grep; rename không sót refs |
| Diagnostics (live type errors) | Máy soi lỗi type ngay khi gõ — như chính tả đỏ trong Word | Hỏi "get live type errors file apps/api/auth.ts" sau khi sửa | Liệt kê đúng dòng lỗi mới; sửa xong hỏi lại phải hết đỏ |
| OpenTelemetry (OTel) | Hộp đen ghi ai chậm, ai ngốn tokens mỗi turn — như đồng hồ điện từng phòng | `export OTEL_TRACES_EXPORTER="console"` rồi grep `hook.*duration` | Thấy `hook test-gate p99 240s`; fix xong p99 còn ~20s |
| Code intelligence plugin | Cầu nối LSP ↔ Claude Code: bật lên là Claude có tool jump/refs/diagnostics | `/plugin` → enable code-intelligence | `/doctor` hiện mục code-intelligence: `enabled` + servers đang chạy |
| OTel collector | Nhà kho tổng nhận spans/metrics OTLP từ máy dev, gom về 1 chỗ cho team | `docker run -p 4317:4317 -p 4318:4318 otel/opentelemetry-collector` | Collector log có dòng spans về sau 1 task nhỏ |

---

## 1. Vì sao cần code intelligence + metrics?

Mục này trả lời câu "tại sao phải thêm 2 lớp công cụ nữa" trước khi vào cài đặt — đọc xong bạn biết mình đang thiếu gì.

Claude đọc code bằng `Read/Grep/Glob` là đọc text — không hiểu symbol nào định nghĩa ở đâu, type nào sai ở dòng nào. Hậu quả: rename 1 hàm phải grep 20 chỗ, sửa type xong không biết còn đỏ ở đâu, subagent explore đọc 300 files vì không biết jump tới definition. LSP cho Claude đúng cái IDE có; OTel cho bạn đúng cái backend có — metrics/traces mỗi turn: hook nào chậm, skill nào ngốn context, MCP nào treo. Ví von: LSP là cho Claude đôi mắt sáng (nhìn thẳng vào định nghĩa thay vì lục lại cả kho), còn OTel là hộp đen của máy bay — có sự cố thì nghe lại bản ghi, không ngồi phán đoán.

```text
Không LSP:  grep "login" → 200 kết quả → đọc 30 files → bill vọt
Có LSP:     go-to-definition(login) → 1 def + 8 refs → đọc 3 files

Không OTel: "sao session chậm?" → đoán (model dở? mạng lag?)
Có OTel:    hook test-gate p99 240s + skill deploy 45K tokens → biết chính xác kẻ ngốn
```

> Quy tắc: **typed language mà chưa bật LSP là tự handicap. Session chậm mà chưa nhìn metrics là đoán mò.**

> **Tóm gọn 1 câu:** LSP giúp Claude "nhìn thấy" code như IDE, OTel giúp bạn "nghe được" session đang làm gì — thiếu cả hai là grep mù cộng đoán mò.

---

## 2. LSP là gì, khi nào thắng grep?

Mục này phân biệt 2 công cụ tìm kiếm: grep soi chữ, LSP soi cấu trúc. Đọc để biết task nào nên dùng cái nào — đừng bật LSP rồi vẫn grep như cũ.

- **LSP**: protocol chuẩn, mọi editor dùng. Mỗi ngôn ngữ có 1 language server (`typescript-language-server`, `pyright`, `rust-analyzer`, `gopls`...). Server hiểu AST/types, trả về definition/references/diagnostics qua JSON-RPC.
- **Code intelligence plugin trong Claude Code**: cầu nối LSP ↔ Claude. Khi bật, Claude có thêm tools kiểu `goToDefinition`, `findReferences`, `getDiagnostics` (tên tool tùy bản) thay vì chỉ grep text.
- **Typed languages được lợi nhất**: TypeScript, Python (có types), Go, Rust, Java. JS thuần/dynamic-heavy thì lợi ít.

| Nhu cầu | Grep | LSP |
|---|---|---|
| Tìm chuỗi text ("TODO", log) | ✓ nhanh | Không cần |
| Hàm này định nghĩa ở đâu, ai gọi? | Grep 200 kết quả nhiễu | ✓ definition + references chính xác |
| Sửa xong còn lỗi type ở đâu? | Chạy `tsc` tay cả repo | ✓ live diagnostics theo file |
| Rename an toàn | Sửa tay từng chỗ, sót | ✓ rename symbol (server lo) |
| Repo dynamic (JS thuần, Python không types) | ✓ đủ | LSP yếu (không type info) — khỏi bật |

> **Cách đọc bảng này:** quét cột "Nhu cầu" tìm đúng việc bạn đang làm, rồi so 2 cột Grep vs LSP — dấu ✓ là người thắng; dòng cuối là ngoại lệ quan trọng nhất (repo không types thì LSP không có đất diễn).

---

## 3. Cài LSP cho typed languages (copy-paste)

Mục này là 2 bước cài đặt: cài language server cho ngôn ngữ của repo, rồi bật plugin cầu nối trong Claude Code. Làm đúng thứ tự thì chạy được ngay.

### 3.1. Cài server theo ngôn ngữ (máy dev cần có trước)

> 📄 **Code ví dụ:** [`examples/01-3-1-cai-server-theo-ngon-ngu-may.sh`](examples/01-3-1-cai-server-theo-ngon-ngu-may.sh)

> 📄 **Code ví dụ:** [`examples/02-3-1-cai-server-theo-ngon-ngu-may.sh`](examples/02-3-1-cai-server-theo-ngon-ngu-may.sh)

### 3.2. Bật plugin trong Claude Code

> 📄 **Code ví dụ:** [`examples/03-3-2-bat-plugin-trong-claude-code.sh`](examples/03-3-2-bat-plugin-trong-claude-code.sh)

> 📄 **Code ví dụ:** [`examples/04-3-2-bat-plugin-trong-claude-code.json`](examples/04-3-2-bat-plugin-trong-claude-code.json)

> 📄 **Code ví dụ:** [`examples/05-3-2-bat-plugin-trong-claude-code.sh`](examples/05-3-2-bat-plugin-trong-claude-code.sh)

> **Tóm gọn 1 câu:** Cài server cho đúng ngôn ngữ + bật plugin cầu nối — 2 bước xong là Claude có tool jump/refs/diagnostics thay grep.

---

## 4. Symbol navigation + live type errors trong workflow

Mục này đưa LSP vào việc hằng ngày: explore code bằng nhảy định nghĩa, và sửa lỗi type tới đâu xanh tới đó — thay vì chạy `tsc` cả repo mỗi lần.

### 4.1. Symbol navigation: explore gọn 10x

> 📄 **Code ví dụ:** [`examples/06-4-1-symbol-navigation-explore-gon-10x.sh`](examples/06-4-1-symbol-navigation-explore-gon-10x.sh)

### 4.2. Live type errors: sửa tới đâu xanh tới đó

> 📄 **Code ví dụ:** [`examples/07-4-2-live-type-errors-sua-toi-au.sh`](examples/07-4-2-live-type-errors-sua-toi-au.sh)

```text
Workflow chuẩn typed task (5 bước):
1. LSP jump (def + refs) → 2. Plan (files sẽ sửa) → 3. Edit →
4. Diagnostics file đổi (xanh?) → 5. Focused test file đổi
Full tsc + full suite để CI, không chạy mỗi turn local.
```

> **Tóm gọn 1 câu:** Đi theo đúng 5 bước (jump → plan → edit → diagnostics → focused test) là bạn sửa code như có IDE kèm theo, không đốt context chạy full suite mỗi turn.

---

## 5. OpenTelemetry: bật thế nào, endpoint ở đâu

Mục này hướng dẫn bật "hộp đen ghi chép" cho session: từ mức nhẹ nhất (in ra console) tới mức đầy đủ (collector cả team). Bật trước, đọc metrics sau.

Claude Code phát ra spans/metrics OTel mỗi turn: thời gian tool chạy, tokens per skill/MCP/hook, latency per hook, số subagents spawn. Dùng để tìm hooks chậm (p99 cao), skills ngốn context (tokens lớn), MCP treo (span timeout), fan-out sai (spawn lồng). Cần 1 collector/backend nhận OTLP (local stdout, Jaeger, Grafana, Honeycomb...) — không có backend thì export ra stdout/file vẫn debug được.

### 5.1. Bật OTel (3 mức từ nhẹ tới full)

> 📄 **Code ví dụ:** [`examples/08-5-1-bat-otel-3-muc-tu-nhe.sh`](examples/08-5-1-bat-otel-3-muc-tu-nhe.sh)

### 5.2. Collector local (docker) + verify

> 📄 **Code ví dụ:** [`examples/09-5-2-collector-local-docker-verify.yaml`](examples/09-5-2-collector-local-docker-verify.yaml)

> 📄 **Code ví dụ:** [`examples/10-5-2-collector-local-docker-verify.sh`](examples/10-5-2-collector-local-docker-verify.sh)

> **Tóm gọn 1 câu:** Bật OTel 3 mức từ nhẹ tới full — không có backend thì console cũng đủ để bắt kẻ chậm, kẻ ngốn.

---

## 6. Metrics nào hữu ích + ví dụ query

Mục này là bảng "đọc kết quả khám": mỗi metric trả lời một câu hỏi nghi vấn về session, kèm ngưỡng khi nào đáng lo. Đọc bảng trước, lấy query mẫu sau.

| Metric/span | Câu hỏi | Ngưỡng cảnh báo |
|---|---|---|
| `hook.duration_ms` (per hook, p50/p99) | Hook nào chậm? | p99 >5s → focus scope hoặc cache |
| `skill.tokens_total` (per skill) | Skill nào ngốn context? | 1 skill >20K/turn → hẹp description/trigger |
| `mcp.tool_latency_ms` (per server) | MCP nào treo? | timeout liên tục → disable/tắt server |
| `subagent.spawn_count` + depth | Fan-out sai? | depth >2 (lồng) → cấm spawn lồng |
| `turn.tokens_in/out` + `turn.duration` | Turn nào phình? | tokens vọt sau 1 tool → tool đó dump quá nhiều |
| `diagnostics.count` (per file) | File nào đỏ mãn tính? | 1 file đỏ hoài → tách file, fix types gốc |

> **Cách đọc bảng này:** cột "Câu hỏi" là nghi vấn bạn đang có (hook chậm? skill ngốn?), cột "Ngưỡng cảnh báo" là lúc nào mới đáng động tay — chưa chạm ngưỡng thì đừng tối ưu sớm.

> Không phải mọi tín hiệu đều đi qua OTel: từ bản ≥2.1.295 terminal dùng Program Status Protocol (OSC 7501) để hiện đang làm / chờ bạn / xong — hữu ích để phân biệt session treo với session đang chạy trước khi kết luận cần OTel.

> 📄 **Code ví dụ:** [`examples/11-6-metrics-nao-huu-ich-vi-du-query.sh`](examples/11-6-metrics-nao-huu-ich-vi-du-query.sh)

```text
# Có Grafana (team dashboard — 3 panels đủ):
# Panel 1: hook.duration p99 by hook (bar) — hook nào cột cao nhất?
# Panel 2: skill.tokens_total by skill (timeseries) — skill nào leo dốc?
# Panel 3: subagent.spawn depth (heatmap) — có spawn lồng không?
```

> **Tóm gọn 1 câu:** Chỉ theo dõi 6 metric với ngưỡng rõ ràng — metrics là kính hiển vi, không phải bộ sưu tập.

---

## 7. Ba ca thật: bắt lỗi bằng metrics rồi fix + verify

Mục này là 3 câu chuyện có thật được metrics tố cáo và fix thành công — đọc để thấy quy trình "đo → fix → đo lại" chạy ra sao trong thực tế.

### 7.1. Ca A — hook test-gate chậm (4 phút → 20 giây)

> 📄 **Code ví dụ:** [`examples/12-7-1-ca-a-hook-test-gate-cham.sh`](examples/12-7-1-ca-a-hook-test-gate-cham.sh)

### 7.2. Ca B — skill deploy ngốn 45K mỗi turn

> 📄 **Code ví dụ:** [`examples/13-7-2-ca-b-skill-deploy-ngon-45k.sh`](examples/13-7-2-ca-b-skill-deploy-ngon-45k.sh)

### 7.3. Ca C — MCP github treo (span timeout hàng loạt)

> 📄 **Code ví dụ:** [`examples/14-7-3-ca-c-mcp-github-treo-span.sh`](examples/14-7-3-ca-c-mcp-github-treo-span.sh)

> **Tóm gọn 1 câu:** Quy trình 3 ca đều như nhau: metrics chỉ tay vào thủ phạm → fix đúng chỗ → đo lại lấy bằng chứng trước/sau.

---

## 8. Pitfalls + fix

Mục này là danh sách vấp đã gặp khi dùng LSP và OTel — đọc trước khi cài để đỡ mắc, hoặc tra khi có hiện tượng lạ.

| Pitfall | Vì sao | Fix |
|---|---|---|
| Bật LSP cho repo JS thuần không types | Server không có type info, jump sai | Chỉ bật cho typed languages; JS thuần grep đủ |
| Thiếu tsconfig/pyrightconfig/go.mod | Server mù project, diagnostics rỗng | Tạo config tối thiểu, verify jump đúng trước khi tin |
| Server chặn cả repo monorepo lớn | Index chậm, RAM phình | Scope server theo package (`apps/api`), không index cả monorepo |
| OTel exporter sai endpoint | Không có spans về, tưởng OTel hỏng | Chạy collector local trước (mục 5.2), thấy log về mới lên team backend |
| Metrics nhiều nhưng không action | Dashboard đẹp, hook vẫn chậm | Mỗi tuần fix top 1 hook + top 1 skill (mục 7), không sưu tầm metrics |
| Tin diagnostics thay test | Types xanh mà runtime sai vẫn xảy ra | Diagnostics + focused test + `/verify` — 3 lớp, thiếu 1 là mù 1 mắt |
| OTel token hardcode trong config | Lộ credential collector | Token qua env (`${OTEL_TOKEN}`), config file không chứa secret |
| Hardcode xong quên rotate | Token cũ còn trong git history | Secret manager + rotate định kỳ |

> **Cách đọc bảng này:** cột "Vì sao" giải thích gốc rễ, cột "Fix" là liều thuốc — 3 dòng đầu về LSP, 5 dòng sau về OTel; tìm đúng nhóm lỗi của mình trước khi đọc chéo.

> **Tóm gọn 1 câu:** LSP chỉ cho repo có types, OTel chỉ hữu ích khi metrics được fix — thiếu config, thiếu hành động, hay tin diagnostics thay test đều là mù một mắt.

---

## 9. Bài tập thực hành

**Bài 1 (20 phút — LSP):** Cài 1 server đúng stack repo bạn (mục 3.1), verify jump-to-definition đúng 3 hàm. Dùng LSP find references cho 1 hàm core, so số kết quả với grep (kỳ vọng ít hơn 5–10x). Rename 1 symbol bằng LSP, `git diff --stat` xem đổi đúng files không.

**Bài 2 (15 phút — diagnostics):** Cố tình chèn 1 lỗi type, hỏi diagnostics file đó — có bắt đúng dòng không? Viết hook test-gate focused cho 1 package, `time` so với full suite.

**Bài 3 (20 phút — OTel):** Bật console exporter, làm 1 task 3 turns, grep top hook chậm + top skill ngốn (mục 6). Fix 1 cái (focused scope hoặc hẹp description), đo lại — ghi % giảm. (Team) Dựng collector local (mục 5.2), đề xuất 3 panels Grafana.

---

## 10. Link chéo

- **[Bài 04 — Slash commands toàn tập](./04-slash-commands-toan-tap.md)**: `/plugin` (bật code-intel), `/doctor` (khám servers + skills pile-up), `/mcp` (MCP treo).
- **[Bài 05 — Skills](./05-skills-custom-commands.md)**: hẹp description skill ngốn ([Tips 07](../02-tips-thuc-chien/07-thiet-ke-skills.md) sâu hơn).
- **[Bài 06 — Subagents, agent teams](./06-subagents-agent-teams-parallel.md)**: explorer đi theo LSP graph (scope hẹp + output contract).
- **[Bài 07 — Hooks](./07-hooks-tu-dong-hoa.md)**: test-gate focused; hook chậm thì OTel bắt.
- **[Bài 10 — Permissions & availability](./10-permissions-modes-availability.md)**: availability LSP/OTel theo provider; `dontAsk` vs `bypass` trong CI.
- **[Bài 12 — Agent SDK & CI/CD](./12-agent-sdk-ci-cd-automation.md)**: `settingSources: ["project"]` gọn skills CI; `claude -p` warmup + review JSON.
- **[Tips 01 — Context hygiene](../02-tips-thuc-chien/01-context-hygiene.md)**: LSP là cách rẻ nhất giữ context sạch ở typed repos.
- **[Tips 04 — Verification](../02-tips-thuc-chien/04-verification-done-that.md)**: diagnostics ≠ test ≠ `/verify` — cần cả 3.
- **[Tips 05 — Parallel agents](../02-tips-thuc-chien/05-parallel-agents.md)**: fan-out sai thì OTel spawn depth tố cáo.
- **[Tips 06 — Hooks recipes](../02-tips-thuc-chien/06-hooks-recipes.md)**: sửa hook chặn nhầm + hook chậm (ca A).
- **[Tips 07 — Thiết kế skills](../02-tips-thuc-chien/07-thiet-ke-skills.md)**: hẹp trigger skill ngốn (ca B).
- **[Tips 10 — Debugging & phím tắt](../02-tips-thuc-chien/10-debugging-power-moves.md)**: L1→L4; OTel là evidence cho L2/L3.
- Commands: [plugin](./commands/knowledge-system/plugin/README.md) (bật code-intel) · [doctor](./commands/knowledge-system/doctor/README.md) (khám servers + cost) · [usage](./commands/session-context/usage/README.md) (ai ngốn, bản không OTel) · [mcp](./commands/knowledge-system/mcp/README.md) (MCP treo thì disable).
