# 13 — Code Intelligence (LSP) + OpenTelemetry Metrics (Tìm Hooks Chậm, Skills Ngốn Context)

> Bài 13 series 01. Đọc xong bạn bật được LSP cho typed languages (symbol navigation, live type errors),
> bật được OpenTelemetry metrics (endpoint config, metrics nào đáng nhìn), và dùng metrics để bắt hooks chậm
> + skills ngốn context. Thời gian: ~45 phút.

## Mục lục

1. [Vì sao cần code intelligence + metrics? (why)](#1-vì-sao-cần-code-intelligence--metrics-why)
2. [Code intelligence plugins: LSP là gì](#2-code-intelligence-pluginslsp-là-gì)
3. [Cài LSP cho typed languages (copy-paste)](#3-cài-lsp-cho-typed-languages-copy-paste)
4. [Symbol navigation + live type errors trong workflow](#4-symbol-navigation--live-type-errors-trong-workflow)
5. [OpenTelemetry: bật thế nào, endpoint ở đâu](#5-opentelemetry-bật-thế-nào-endpoint-ở-đâu)
6. [Metrics nào hữu ích + ví dụ config endpoint](#6-metrics-nào-hữu-ích--ví-dụ-config-endpoint)
7. [Dùng metrics tìm hooks chậm + skills ngốn context](#7-dùng-metrics-tìm-hooks-chậm--skills-ngốn-context)
8. [Walkthrough end-to-end (20 phút)](#8-walkthrough-end-to-end-20-phút)
9. [Pitfalls + fix](#9-pitfalls--fix)
10. [Bài tập](#10-bài-tập)
11. [Link chéo](#11-link-chéo)

---

## 1. Vì sao cần code intelligence + metrics? (why)

Claude đọc code bằng `Read/Grep/Glob` là đọc text — không hiểu symbol nào định nghĩa ở đâu, type nào sai ở dòng nào.
Hậu quả: rename 1 hàm phải grep 20 chỗ, sửa type xong không biết còn đỏ ở đâu, subagent explore đọc 300 files vì không biết jump tới definition.

LSP (Language Server Protocol) cho Claude đúng cái IDE có: jump-to-definition, find references, live type errors.
OpenTelemetry (OTel) cho bạn đúng cái backend có: metrics/traces mỗi turn — hook nào chậm, skill nào ngốn context, MCP nào treo.

```
Không LSP:  grep "login" → 200 kết quả → đọc 30 files → bill vọt
Có LSP:     go-to-definition(login) → 1 def + 8 refs → đọc 3 files

Không OTel: "sao session chậm?" → đoán (model dở? mạng lag?)
Có OTel:    hook test-gate p99 240s + skill deploy 45K tokens → biết chính xác kẻ ngốn
```

> Quy tắc: **typed language mà chưa bật LSP là tự handicap. Session chậm mà chưa nhìn metrics là đoán mò.**

---

## 2. Code intelligence plugins/LSP là gì

- **LSP**: protocol chuẩn (Microsoft đề xuất, mọi editor dùng). Mỗi ngôn ngữ có 1 language server
  (`typescript-language-server`, `pyright`, `rust-analyzer`, `gopls`...). Server hiểu AST/types, trả về
  definition/references/diagnostics qua protocol JSON-RPC.
- **Code intelligence plugin trong Claude Code**: cầu nối LSP ↔ Claude. Khi bật, Claude có thêm tools
  kiểu `goToDefinition`, `findReferences`, `getDiagnostics` (tên tool tùy bản) thay vì chỉ grep text.
- **Khi nào LSP thắng grep?**

| Nhu cầu | Grep | LSP |
|---|---|---|
| Tìm chuỗi text ("TODO", log) | ✓ nhanh | Không cần |
| Hàm này định nghĩa ở đâu, ai gọi? | Grep 200 kết quả nhiễu | ✓ definition + references chính xác |
| Sửa xong còn lỗi type ở đâu? | Chạy `tsc` tay cả repo | ✓ live diagnostics theo file |
| Rename an toàn | Sửa tay từng chỗ, sót | ✓ rename symbol (server lo) |
| Repo dynamic (JS thuần, Python không types) | ✓ đủ | LSP yếu (không type info) — khỏi bật cũng được |

- **Typed languages được lợi nhất**: TypeScript, Python (có types), Go, Rust, Java. JS thuần/dynamic-heavy thì lợi ít.

---

## 3. Cài LSP cho typed languages (copy-paste)

### 3.1. Nguyên tắc: 1 ngôn ngữ = 1 server + plugin bật

```bash
# 1. Kiểm tra Claude Code có thấy code-intel không (tên mục tùy bản):
/plugin
# → tìm mục code-intelligence / lsp / language-server. Không thấy → update bản mới.

# 2. Kiểm tra trong session:
/doctor
# → mục code-intelligence: enabled/disabled + servers nào chạy
```

### 3.2. Cài server theo ngôn ngữ (máy dev cần có trước)

```bash
# TypeScript (node ≥18):
npm i -g typescript typescript-language-server
# Kiểm tra: typescript-language-server --version

# Python (typed — cần pyright hoặc pylsp):
npm i -g pyright
# hoặc: pip install python-lsp-server
# Kiểm tra: pyright --version

# Go:
go install golang.org/x/tools/gopls@latest
# Kiểm tra: gopls version

# Rust:
rustup component add rust-analyzer
# Kiểm tra: rust-analyzer --version
```

```bash
# 3. Mở repo và xác nhận server nhận project:
# TypeScript: cần tsconfig.json ở root (npx tsc --init nếu chưa có)
# Python: cần pyrightconfig.json hoặc pyproject.toml
# Go: cần go.mod · Rust: cần Cargo.toml
ls tsconfig.json pyrightconfig.json go.mod Cargo.toml 2>/dev/null
# → file nào có thì server đó mới hiểu project (không có là LSP mù)
```

### 3.3. Bật plugin trong Claude Code

```bash
# Cách 1 — trong session (nhanh, thử trước):
/plugin
# → Enable code-intelligence → chọn servers (typescript, pyright...)

# Cách 2 — settings.json team (share cả team, khuyến nghị):
# .claude/settings.json
```

```json
// .claude/settings.json — bật code-intel cho team (copy-paste khung):
{
  "codeIntelligence": {
    "enabled": true,
    "servers": ["typescript", "pyright"]
  }
}
```

```bash
# 4. Verify sau khi bật (làm 1 lần):
# Hỏi Claude: "jump to definition hàm login trong src/auth.ts"
# → phải trả về file:dòng chính xác, không phải 20 kết quả grep
# Hỏi: "file này còn lỗi type nào?" → phải liệt kê diagnostics theo dòng
```

---

## 4. Symbol navigation + live type errors trong workflow

### 4.1. Symbol navigation: explore gọn 10x

```bash
# Trước (grep mù):
# "tìm mọi chỗ gọi refreshToken" → grep → 60 kết quả (cả comment, log, test cũ)

# Sau (LSP):
# Prompt mẫu copy-paste:
"find references của refreshToken (dùng LSP), chỉ liệt kê call sites thật trong src/, bỏ test snapshot và comment."
# → 8 refs thật → đọc 3 files là đủ
```

```bash
# Prompt rename an toàn (copy-paste):
"rename symbol loginWithSSO thành loginWithOIDC (dùng LSP rename), liệt kê files đổi, không chạm test snapshot."
# → server rename đúng def + refs, không sót, không sửa nhầm chuỗi "login" trong log
```

```bash
# Prompt explore multi-file (gọn, rẻ):
"Từ handler POST /login trong apps/api, jump qua domain + db layers (LSP definition), trả về ≤10 files sẽ sửa + 1 dòng/file vì sao."
# → explorer đi theo graph thật, không đọc 300 files
```

### 4.2. Live type errors: sửa tới đâu xanh tới đó

```bash
# Sau mỗi change, hỏi thay vì chạy full tsc:
"get live type errors file apps/api/auth.ts (LSP diagnostics), chỉ lỗi mới do change vừa rồi."

# Gate trong hook Stop (khung — xem Tips 06):
# hooks/test-gate.sh gọi tsc --noEmit --pretty false cho file đổi (nhanh)
# thay vì full suite 4 phút mỗi turn-end
TEST_SCOPE=auth ./hooks/test-gate.sh
```

```text
# Workflow chuẩn typed task (5 bước):
# 1. LSP jump (def + refs) → 2. Plan (files sẽ sửa) → 3. Edit →
# 4. Diagnostics file đổi (xanh?) → 5. Focused test file đổi
# Full tsc + full suite để CI, không chạy mỗi turn local
```

---

## 5. OpenTelemetry: bật thế nào, endpoint ở đâu

- **OTel trong Claude Code là gì?** Chuẩn observability (metrics + traces + logs). Claude Code phát ra
  spans/metrics mỗi turn: thời gian tool chạy, tokens per skill/MCP/hook, latency per hook, số subagents spawn.
- **Dùng để làm gì?** Tìm hooks chậm (hook nào p99 cao), skills ngốn context (skill nào tokens lớn),
  MCP treo (span timeout), fan-out sai (spawn lồng).
- **Cần gì?** 1 collector/backend nhận OTLP (local stdout, Jaeger, Grafana, Honeycomb...). Không có backend
  thì export ra stdout/file vẫn debug được.

### 5.1. Bật OTel (3 mức từ nhẹ tới full)

```bash
# Mức 1 — log ra stdout/file local (debug 1 session, không cần infra):
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_METRICS_EXPORTER="otlp"
export OTEL_TRACES_EXPORTER="otlp"
# Chạy Claude Code từ terminal này → spans/metrics chảy về endpoint local

# Mức 2 — file local khi chưa có collector:
export OTEL_TRACES_EXPORTER="console"
export OTEL_METRICS_EXPORTER="console"
# → in ra terminal/file, grep được ngay (xem mục 7)

# Mức 3 — team collector (share, xem chung Grafana/Jaeger):
# endpoint team cung cấp, secrets qua env (không hardcode):
export OTEL_EXPORTER_OTLP_ENDPOINT="https://otel.team.internal:4318"
export OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer ${OTEL_TOKEN}"
```

### 5.2. Config endpoint mẫu (copy-paste khung)

```yaml
# otel-collector-config.yaml — collector local team (khung tối thiểu):
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
# Chạy collector local (docker) + verify:
docker run -p 4317:4317 -p 4318:4318 -v ./otel-collector-config.yaml:/etc/otel.yaml \
  otel/opentelemetry-collector --config=/etc/otel.yaml
# → mở Claude Code session, làm 1 task nhỏ, xem collector log có spans về không
```

---

## 6. Metrics nào hữu ích + ví dụ config endpoint

### 6.1. Bảng metrics đáng nhìn (và câu hỏi nó trả lời)

| Metric/span | Câu hỏi | Ngưỡng cảnh báo |
|---|---|---|
| `hook.duration_ms` (per hook, p50/p99) | Hook nào chậm? | p99 >5s → focus scope hoặc cache |
| `skill.tokens_total` (per skill) | Skill nào ngốn context? | 1 skill >20K/turn → hẹp description/trigger |
| `mcp.tool_latency_ms` (per server) | MCP nào treo? | timeout liên tục → disable/tắt server |
| `subagent.spawn_count` + depth | Fan-out sai? | depth >2 (lồng) → cấm spawn lồng |
| `turn.tokens_in/out` + `turn.duration` | Turn nào phình? | tokens vọt sau 1 tool → tool đó dump quá nhiều |
| `diagnostics.count` (per file) | File nào đỏ mãn tính? | 1 file đỏ hoài → tách file, fix types gốc |

### 6.2. Ví dụ query khi có backend (Grafana/Jaeger khung)

```bash
# Không có Grafana? Grep console exporter vẫn ra (mức 2):
# Tìm hook chậm:
OTEL_TRACES_EXPORTER=console claude "làm task X" 2>&1 | grep -i "hook.*duration" | sort -k2 -n | tail -5

# Tìm skill ngốn:
OTEL_METRICS_EXPORTER=console claude "làm task X" 2>&1 | grep -i "skill.*tokens" | sort -k2 -n | tail -5
```

```text
# Khi có Grafana (team dashboard gợi ý — 3 panels đủ):
# Panel 1: hook.duration p99 by hook (bar) — hook nào cột cao nhất?
# Panel 2: skill.tokens_total by skill (timeseries) — skill nào leo dốc?
# Panel 3: subagent.spawn depth (heatmap) — có spawn lồng không?
```

---

## 7. Dùng metrics tìm hooks chậm + skills ngốn context

### 7.1. Ca A — hook test-gate chậm (từ 4 phút → 20 giây)

```bash
# Triệu chứng: mọi turn-end đều "treo" vài phút
# Metrics: hook test-gate p99 240s, các hook khác <2s → thủ phạm rõ

# Fix (copy-paste):
# Trước: hooks/test-gate.sh chạy full suite mỗi turn
# Sau: focused scope (env TEST_SCOPE), full suite để CI:
TEST_SCOPE=auth ./hooks/test-gate.sh
time TEST_SCOPE=auth ./hooks/test-gate.sh
# → p99 240s → 20s. Verify: metrics turn sau hook <30s
```

### 7.2. Ca B — skill deploy ngốn 45K mỗi turn

```bash
# Triệu chứng: /context 80% sau 3 turns dù task nhỏ
# Metrics: skill.tokens_total: deploy 45K, các skill khác <3K → description quá rộng, fire nhầm

# Fix:
# 1. Hẹp description skill (chỉ fire khi user nói "deploy staging/prod"):
# 2. skillOverrides tắt auto-fire ở repo không deploy (xem Tips 07):
/doctor
# → "skill deploy fires 5/10 turns (unnecessary 4)" → hẹp xong còn 1/10
# Verify: metrics skill deploy <5K/turn ở repo này
```

### 7.3. Ca C — MCP github treo (span timeout hàng loạt)

```bash
# Triệu chứng: tool github gọi mãi không về
# Metrics: mcp.tool_latency timeout 100% server github, các server khác ok → token hết hạn, không phải model dở

/mcp
# → github-mcp đỏ → reconnect hoặc disable tạm, task tiếp tục bằng Read/Grep local
# Verify: span latency về <2s hoặc server disabled, turn hết treo
```

---

## 8. Walkthrough end-to-end (20 phút)

**Phút 0–5 (bật LSP):**

```bash
npm i -g typescript typescript-language-server
ls tsconfig.json
/plugin   # enable code-intelligence
# Hỏi thử: "jump to definition hàm login" → phải ra file:dòng chính xác
```

**Phút 5–10 (rename + diagnostics bằng LSP):**

```bash
# "find references refreshToken trong src/, bỏ comment/log"
# "get diagnostics file vừa sửa — còn lỗi type nào mới?"
# → explore 3 files thay vì 30, sửa tới đâu xanh tới đó
```

**Phút 10–15 (bật OTel console):**

```bash
export OTEL_TRACES_EXPORTER="console" OTEL_METRICS_EXPORTER="console"
# Làm 1 task nhỏ, grep hook duration + skill tokens (mục 6.2)
# → ghi lại top 1 hook chậm + top 1 skill ngốn
```

**Phút 15–20 (fix 1 cái rồi verify bằng metrics):**

```bash
# Chọn 1: hook focused scope (ca A) hoặc hẹp skill description (ca B)
# Làm lại task tương tự, so metrics trước/sau → phải giảm rõ
# Ghi 1 dòng team log: "test-gate 240s→20s (TEST_SCOPE)" hoặc "deploy 45K→5K (hẹp desc)"
```

---

## 9. Pitfalls + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| Bật LSP cho repo JS thuần không types | Server không có type info, jump sai | Chỉ bật cho typed languages; JS thuần grep đủ |
| Thiếu tsconfig/pyrightconfig/go.mod | Server mù project, diagnostics rỗng | Tạo config tối thiểu, verify jump đúng trước khi tin |
| Server chặn cả repo monorepo lớn | Index chậm, RAM phình | Scope server theo package (`apps/api`), không index cả monorepo |
| OTel exporter sai endpoint | Không có spans về, tưởng OTel hỏng | Chạy collector local trước (mục 5.2), thấy log về mới lên team backend |
| Metrics nhiều nhưng không action | Dashboard đẹp, hook vẫn chậm | Mỗi tuần fix top 1 hook + top 1 skill (mục 7), không sưu tầm metrics |
| Tin diagnostics thay test | Types xanh mà runtime sai | Diagnostics + focused test + `/verify` (3 lớp, thiếu 1 là mù 1 mắt) |
| OTel token hardcode trong config | Lộ credential collector | Token qua env (`${OTEL_TOKEN}`), config file không chứa secret |

---

## 10. Bài tập

**Bài 1 (20 phút — LSP):**

1. Cài 1 server đúng stack repo bạn (mục 3.2). Verify jump-to-definition đúng 3 hàm.
2. Dùng LSP find references cho 1 hàm core, so số kết quả với grep thường (kỳ vọng ít hơn 5–10x).
3. Rename 1 symbol bằng LSP, `git diff --stat` xem đổi đúng files không.

**Bài 2 (15 phút — diagnostics):**

1. Cố tình chèn 1 lỗi type, hỏi diagnostics file đó — có bắt đúng dòng không?
2. Viết hook/test-gate focused cho 1 package, `time` so với full suite.

**Bài 3 (20 phút — OTel):**

1. Bật console exporter, làm 1 task 3 turns, grep top hook chậm + top skill ngốn (mục 6.2).
2. Fix 1 cái (focused scope hoặc hẹp description), đo lại — ghi % giảm.
3. (Team) Dựng collector local (mục 5.2), đề xuất 3 panels Grafana cho team.

> Đạt: explore task typed chỉ đọc ≤10 files (nhờ LSP) + chỉ ra được top hook/skill ngốn bằng metrics, không đoán.

---

## 11. Link chéo

- **Bài 04 — Slash commands**: `/plugin` (bật code-intel), `/doctor` (khám servers + skills pile-up), `/mcp` (MCP treo).
- **Bài 05 — Skills**: hẹp description skill ngốn (Tips 07 sâu hơn); skill tái dùng cho CI jobs.
- **Bài 06 — Subagents**: explorer đi theo LSP graph (scope hẹp + output contract).
- **Bài 07 — Hooks**: test-gate focused, PreToolUse automate permissions; hook chậm thì OTel bắt.
- **Bài 10 — Permissions**: availability LSP/OTel theo provider; `dontAsk` vs `bypass` trong CI.
- **Bài 12 — SDK/CI**: `settingSources: ["project"]` gọn skills CI; `claude -p` warmup + review JSON.
- **Tips 01 — Context hygiene**: LSP là cách rẻ nhất giữ context sạch ở typed repos.
- **Tips 04 — Verification**: diagnostics ≠ test ≠ `/verify` — cần cả 3.
- **Tips 05 — Parallel agents**: fan-out sai thì OTel spawn depth tố cáo.
- **Tips 06 — Hooks recipes**: sửa hook chặn nhầm + hook chậm (ca A).
- **Tips 07 — Thiết kế skills**: hẹp trigger skill ngốn (ca B).
- **Tips 10 — Debugging**: L1→L4; OTel là evidence cho L2/L3.
- Commands:
  - [commands/plugin/README.md](./commands/plugin/README.md) — bật code-intel plugin
  - [commands/doctor/README.md](./commands/doctor/README.md) — khám servers + cost
  - [commands/usage/README.md](./commands/usage/README.md) — ai ngốn (bản không OTel)
  - [commands/mcp/README.md](./commands/mcp/README.md) — MCP treo thì disable
