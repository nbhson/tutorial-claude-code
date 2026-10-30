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

Claude đọc code bằng `Read/Grep/Glob` là đọc text — không hiểu symbol nào định nghĩa ở đâu, type nào sai ở dòng nào. Hậu quả: rename 1 hàm phải grep 20 chỗ, sửa type xong không biết còn đỏ ở đâu, subagent explore đọc 300 files vì không biết jump tới definition. LSP cho Claude đúng cái IDE có; OTel cho bạn đúng cái backend có — metrics/traces mỗi turn: hook nào chậm, skill nào ngốn context, MCP nào treo.

```text
Không LSP:  grep "login" → 200 kết quả → đọc 30 files → bill vọt
Có LSP:     go-to-definition(login) → 1 def + 8 refs → đọc 3 files

Không OTel: "sao session chậm?" → đoán (model dở? mạng lag?)
Có OTel:    hook test-gate p99 240s + skill deploy 45K tokens → biết chính xác kẻ ngốn
```

> Quy tắc: **typed language mà chưa bật LSP là tự handicap. Session chậm mà chưa nhìn metrics là đoán mò.**

---

## 2. LSP là gì, khi nào thắng grep?

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

---

## 3. Cài LSP cho typed languages (copy-paste)

### 3.1. Cài server theo ngôn ngữ (máy dev cần có trước)

```bash
# TypeScript (node ≥18):
npm i -g typescript typescript-language-server
# Python (typed — cần pyright hoặc pylsp):
npm i -g pyright        # hoặc: pip install python-lsp-server
# Go:
go install golang.org/x/tools/gopls@latest
# Rust:
rustup component add rust-analyzer
```

```bash
# Mở repo và xác nhận server nhận project — file nào có thì server đó mới hiểu project:
ls tsconfig.json pyrightconfig.json go.mod Cargo.toml 2>/dev/null
# TypeScript: cần tsconfig.json ở root (npx tsc --init nếu chưa có)
# Python: pyrightconfig.json hoặc pyproject.toml · Go: go.mod · Rust: Cargo.toml
```

### 3.2. Bật plugin trong Claude Code

```bash
# Cách 1 — trong session (nhanh, thử trước):
/plugin
# → tìm mục code-intelligence / lsp / language-server → Enable → chọn servers
# → không thấy mục này thì update Claude Code lên bản mới.

# Kiểm tra trong session:
/doctor
# → mục code-intelligence: enabled/disabled + servers nào chạy
```

```json
// Cách 2 — .claude/settings.json bật cho cả team (khuyến nghị):
{
  "codeIntelligence": {
    "enabled": true,
    "servers": ["typescript", "pyright"]
  }
}
```

```bash
# Verify sau khi bật (làm 1 lần):
# Hỏi: "jump to definition hàm login trong src/auth.ts"
# → phải trả về 1 file:dòng chính xác, không phải 20 kết quả grep
# Hỏi: "file này còn lỗi type nào?" → phải liệt kê diagnostics theo dòng
# Trả 20 kết quả grep là LSP chưa nhận project (thiếu tsconfig.json).
```

---

## 4. Symbol navigation + live type errors trong workflow

### 4.1. Symbol navigation: explore gọn 10x

```bash
# Prompt mẫu copy-paste (so với grep: 60 kết quả cả comment/log/test cũ → 8 refs thật):
"find references của refreshToken (dùng LSP), chỉ liệt kê call sites thật trong src/, bỏ test snapshot và comment."

# Rename an toàn — server rename đúng def + refs, không sót, không sửa nhầm chuỗi "login" trong log:
"rename symbol loginWithSSO thành loginWithOIDC (dùng LSP rename), liệt kê files đổi, không chạm test snapshot."

# Explore multi-file — explorer đi theo graph thật, không đọc 300 files:
"Từ handler POST /login trong apps/api, jump qua domain + db layers (LSP definition), trả về ≤10 files sẽ sửa + 1 dòng/file vì sao."
```

### 4.2. Live type errors: sửa tới đâu xanh tới đó

```bash
# Sau mỗi change, hỏi thay vì chạy full tsc:
"get live type errors file apps/api/auth.ts (LSP diagnostics), chỉ lỗi mới do change vừa rồi."

# Gate trong hook Stop (khung — xem Tips 06): gọi tsc --noEmit cho file đổi
# (nhanh) thay vì full suite 4 phút mỗi turn-end:
TEST_SCOPE=auth ./hooks/test-gate.sh
```

```text
Workflow chuẩn typed task (5 bước):
1. LSP jump (def + refs) → 2. Plan (files sẽ sửa) → 3. Edit →
4. Diagnostics file đổi (xanh?) → 5. Focused test file đổi
Full tsc + full suite để CI, không chạy mỗi turn local.
```

---

## 5. OpenTelemetry: bật thế nào, endpoint ở đâu

Claude Code phát ra spans/metrics OTel mỗi turn: thời gian tool chạy, tokens per skill/MCP/hook, latency per hook, số subagents spawn. Dùng để tìm hooks chậm (p99 cao), skills ngốn context (tokens lớn), MCP treo (span timeout), fan-out sai (spawn lồng). Cần 1 collector/backend nhận OTLP (local stdout, Jaeger, Grafana, Honeycomb...) — không có backend thì export ra stdout/file vẫn debug được.

### 5.1. Bật OTel (3 mức từ nhẹ tới full)

```bash
# Mức 1 — OTLP về collector local/team (xem 5.2):
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_METRICS_EXPORTER="otlp" OTEL_TRACES_EXPORTER="otlp"

# Mức 2 — in ra console/file khi chưa có collector (grep được ngay — mục 6):
export OTEL_TRACES_EXPORTER="console" OTEL_METRICS_EXPORTER="console"

# Mức 3 — team collector: endpoint team cung cấp, secrets qua env (không hardcode):
export OTEL_EXPORTER_OTLP_ENDPOINT="https://otel.team.internal:4318"
export OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer ${OTEL_TOKEN}"
```

### 5.2. Collector local (docker) + verify

```yaml
# otel-collector-config.yaml — khung tối thiểu:
receivers:
  otlp:
    protocols:
      grpc: { endpoint: "0.0.0.0:4317" }
      http: { endpoint: "0.0.0.0:4318" }
processors:
  batch: {}
exporters:
  debug: { verbosity: detailed }   # in ra log để kiểm tra trước
  # jaeger: {}  # bật khi team có Jaeger/Grafana
service:
  pipelines:
    traces: { receivers: [otlp], processors: [batch], exporters: [debug] }
    metrics: { receivers: [otlp], processors: [batch], exporters: [debug] }
```

```bash
docker run -p 4317:4317 -p 4318:4318 -v ./otel-collector-config.yaml:/etc/otel.yaml \
  otel/opentelemetry-collector --config=/etc/otel.yaml
# → mở Claude Code session, làm 1 task nhỏ, xem collector log có spans về không
```

---

## 6. Metrics nào hữu ích + ví dụ query

| Metric/span | Câu hỏi | Ngưỡng cảnh báo |
|---|---|---|
| `hook.duration_ms` (per hook, p50/p99) | Hook nào chậm? | p99 >5s → focus scope hoặc cache |
| `skill.tokens_total` (per skill) | Skill nào ngốn context? | 1 skill >20K/turn → hẹp description/trigger |
| `mcp.tool_latency_ms` (per server) | MCP nào treo? | timeout liên tục → disable/tắt server |
| `subagent.spawn_count` + depth | Fan-out sai? | depth >2 (lồng) → cấm spawn lồng |
| `turn.tokens_in/out` + `turn.duration` | Turn nào phình? | tokens vọt sau 1 tool → tool đó dump quá nhiều |
| `diagnostics.count` (per file) | File nào đỏ mãn tính? | 1 file đỏ hoài → tách file, fix types gốc |

> Không phải mọi tín hiệu đều đi qua OTel: từ bản ≥2.1.295 terminal dùng Program Status Protocol (OSC 7501) để hiện đang làm / chờ bạn / xong — hữu ích để phân biệt session treo với session đang chạy trước khi kết luận cần OTel.

```bash
# Không có Grafana? Grep console exporter vẫn ra (mức 2):
OTEL_TRACES_EXPORTER=console claude "làm task X" 2>&1 | grep -i "hook.*duration" | sort -k2 -n | tail -5
OTEL_METRICS_EXPORTER=console claude "làm task X" 2>&1 | grep -i "skill.*tokens" | sort -k2 -n | tail -5
```

```text
# Có Grafana (team dashboard — 3 panels đủ):
# Panel 1: hook.duration p99 by hook (bar) — hook nào cột cao nhất?
# Panel 2: skill.tokens_total by skill (timeseries) — skill nào leo dốc?
# Panel 3: subagent.spawn depth (heatmap) — có spawn lồng không?
```

---

## 7. Ba ca thật: bắt lỗi bằng metrics rồi fix + verify

### 7.1. Ca A — hook test-gate chậm (4 phút → 20 giây)

```bash
# Triệu chứng: mọi turn-end đều "treo" vài phút
# Metrics: hook test-gate p99 240s, các hook khác <2s → thủ phạm rõ
# Fix: focused scope (env TEST_SCOPE), full suite để CI:
TEST_SCOPE=auth ./hooks/test-gate.sh
time TEST_SCOPE=auth ./hooks/test-gate.sh
# → p99 240s → 20s. Verify: metrics turn sau hook <30s
```

### 7.2. Ca B — skill deploy ngốn 45K mỗi turn

```bash
# Triệu chứng: /context 80% sau 3 turns dù task nhỏ
# Metrics: skill.tokens_total: deploy 45K, các skill khác <3K → description quá rộng, fire nhầm
# Fix: hẹp description (chỉ fire khi user nói "deploy staging/prod")
#      + skillOverrides tắt auto-fire ở repo không deploy (xem Tips 07):
/doctor
# → "skill deploy fires 5/10 turns (unnecessary 4)" → hẹp xong còn 1/10
# Verify: metrics skill deploy <5K/turn ở repo này
```

### 7.3. Ca C — MCP github treo (span timeout hàng loạt)

```bash
# Triệu chứng: tool github gọi mãi không về
# Metrics: mcp.tool_latency timeout 100% server github, các server khác ok
# → token hết hạn, không phải model dở
/mcp
# → github-mcp đỏ → reconnect hoặc disable tạm, task tiếp tục bằng Read/Grep local
# Verify: span latency về <2s hoặc server disabled, turn hết treo
```

---

## 8. Pitfalls + fix

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
