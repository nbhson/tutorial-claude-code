# /claude-api — Vọc Anthropic API: migrate SDK, thử managed agents

> Loại Skill (tích hợp API) · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ sinh code; nhưng Có nhẹ khi code chạm API key/tiền thật — key vào env, test trên Haiku trước)

`/claude-api` là bộ subcommands giúp dev dùng Anthropic API/SDK: migrate code cũ sang SDK mới, onboard managed agents (Agent SDK chạy trên hạ tầng Anthropic), và tra cứu mẫu gọi API copy-paste được. Đặc biệt: khi bạn `import anthropic` trong code, skill này tự load (auto-load) để gợi ý đúng phiên bản SDK.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/claude-api` | _(không có)_ | Mở menu: migrate / onboard / samples |
| `/claude-api migrate` | đường dẫn file | Quét code SDK cũ → đề xuất bản migrate |
| `/claude-api managed-agents-onboard` | _(wizard)_ | Dẫn onboard agent lên managed runtime |
| Auto-load | `import anthropic` | Tự kích hoạt khi model thấy bạn dùng SDK |

```bash
# Dạng 1: mở menu
/claude-api

# Dạng 2: migrate 1 file SDK cũ
/claude-api migrate src/llm_client.py

# Dạng 3: onboard managed agents (wizard hỏi từng bước)
/claude-api managed-agents-onboard

# Dạng 4: không cần gọi — auto-load (copy-paste):
```

```python
import anthropic  # model tự load skill claude-api để gợi ý đúng SDK
client = anthropic.Anthropic()
```

---

## Cách nó hoạt động

### Cơ chế sâu: migrate / managed-agents-onboard / auto-load

1. **`migrate` (nâng SDK cũ):** quét `import anthropic`, version trong `requirements/pyproject` → đối chiếu breaking changes (VD `completion` → `messages`, `prompt` → `system+messages`, streaming API mới) → sinh diff từng file + lệnh `pip install -U anthropic`. Không tự ghi đè — bạn duyệt diff.
2. **`managed-agents-onboard` (lên managed runtime):** wizard 4 bước — (a) kiểm tra agent local (tools, permissions), (b) đóng gói (Dockerfile/env), (c) tạo resource trên console (API key scoped), (d) deploy thử + smoke test. Xong cho endpoint + lệnh rollback.
3. **Auto-load khi import SDK:** model thấy `import anthropic` / `from anthropic` trong file bạn mở → tự nạp skill vào context (như rules lazy-load) → gợi ý đúng signature bản mới, không hallucinate API cũ. Không cần gõ lệnh.
4. **Samples:** `messages.create`, streaming, tool use, vision/PDF — mẫu ngắn, chạy được, pinned theo SDK hiện tại.

---

## Ví dụ thực tế

### Kịch bản 1: Migrate file dùng API cũ 2023

```bash
/claude-api migrate src/llm_client.py
# → phát hiện: dùng client.completion (cũ) + max_tokens thiếu
# → diff: chuyển client.messages.create(model="claude-sonnet-4-6", max_tokens=1024, system=..., messages=[...])
# → duyệt diff → chạy pytest → xong
```

```python
# Mẫu mới copy-paste sau migrate:
import anthropic
client = anthropic.Anthropic()  # key từ ANTHROPIC_API_KEY trong env
msg = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    system="Trả lời bằng tiếng Việt, ngắn gọn.",
    messages=[{"role": "user", "content": "Tóm tắt file README này"}],
)
print(msg.content[0].text)
```

### Kịch bản 2: Onboard thử 1 agent đơn giản lên managed

```bash
/claude-api managed-agents-onboard
# → wizard: chọn agent (vd ./agent.py) → kiểm tra tools → tạo key scoped (chỉ messages, quota 5$) → deploy staging → smoke test OK → cho endpoint
# → test endpoint bằng curl trước khi giao team
```

### Kịch bản 3: Auto-load cứu 1 lần hallucinate

```python
# Bạn mở file có dòng:
import anthropic
# → model tự load skill → gợi ý streaming đúng bản mới (client.messages.stream), thay vì bịa .stream_old()
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Hardcode `api_key="sk-ant-..."` trong code mẫu | Lộ key khi commit/chụp màn hình | Key chỉ trong env (`ANTHROPIC_API_KEY`); code đọc `os.environ` |
| Migrate auto-apply mù | Đổi signature hàng loạt, test vỡ | Review diff từng file; chạy test sau mỗi file |
| Onboard thẳng production | Agent lỗi đốt quota/tiền | Đi staging trước, set quota + budget alert, giữ rollback |
| Dùng model đắt để thử | Opus cho hello-world | Thử bằng Haiku, chốt rồi mới lên Sonnet/Opus |

- **Tốn token?** Skill nhẹ (~500 token khi load). Tốn thật là tiền gọi API khi test — set `max_tokens` nhỏ + quota dev.
- **Version:** skill `claude-api` v2.x; subcommand `managed-agents-onboard` bản mới 2026. SDK Python `anthropic>=0.40`.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/claude-api` + `/verify` | Migrate xong test ngay | Migrate → pytest file đó |
| `/claude-api` + `/doctor` | Kiểm tra key/secret trước onboard | Doctor soi hardcode key |
| `/claude-api` + `/stats` | Theo dõi tiền test API | Xem chi tiêu sau onboard |

```bash
# Workflow migrate an toàn: /claude-api migrate (diff) → review → /verify → commit
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Skill không auto-load | File chưa mở trong context / bản cũ | Gõ tay `/claude-api`; update CLI |
| `migrate` báo SDK đã mới | Đúng là mới — hoặc pin version cũ trong requirements | Kiểm tra `pip show anthropic`; sửa pin rồi migrate |
| Onboard fail ở smoke test | Thiếu env trên managed (key, DB_DSN) | Khai env staging đầy đủ rồi deploy lại |
| `401 auth` khi chạy mẫu | Chưa export key / key sai | `export ANTHROPIC_API_KEY=...`; thử `curl` kiểm tra |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../verify/README.md](../../code-repo/verify/README.md) — test sau migrate
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — soi hardcode key
  - [../stats/README.md](../../knowledge-system/stats/README.md) — tiền gọi API
  - [../agents/README.md](../../knowledge-system/agents/README.md) — agent local trước khi onboard managed
  - [../mcp/README.md](../../knowledge-system/mcp/README.md) — MCP vs gọi API trực tiếp
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md)
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md)
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md)
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md)
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md)
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md)

> Mẹo 1 dòng: _key vào env, migrate review diff, onboard staging trước production._
