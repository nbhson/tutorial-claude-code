# /claude-api — Vọc Anthropic API: migrate SDK, thử managed agents

> Loại Skill (tích hợp API) · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ sinh code; nhưng Có nhẹ khi code chạm API key/tiền thật — key vào env, test trên Haiku trước)

> Nói nôm na: `/claude-api` là bộ subcommands giúp dev dùng Anthropic API/SDK: migrate code cũ sang SDK mới, onboard managed agents (Agent SDK chạy trên hạ tầng Anthropic), và tra cứu mẫu gọi API copy-paste được. Đặc biệt: khi bạn `import anthropic` trong code, skill này tự load (auto-load) để gợi ý đúng phiên bản SDK.

## Khi nào dùng

- Dùng /claude-api khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /claude-api **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /claude-api thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/claude-api`
`/claude-api migrate`
`/claude-api managed-agents-onboard`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/claude-api migrate src/llm_client.py
# → phát hiện: dùng client.completion (cũ) + max_tokens thiếu
# → diff: chuyển client.messages.create(model="claude-sonnet-4-6", max_tokens=1024, system=..., messages=[...])
# → duyệt diff → chạy pytest → xong
```

Kết quả mong đợi:

- Claude trả đúng việc của /claude-api (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Skill không auto-load | File chưa mở trong context / bản cũ | Gõ tay `/claude-api`; update CLI |
| `migrate` báo SDK đã mới | Đúng là mới — hoặc pin version cũ trong requirements | Kiểm tra `pip show anthropic`; sửa pin rồi migrate |
| Onboard fail ở smoke test | Thiếu env trên managed (key, DB_DSN) | Khai env staging đầy đủ rồi deploy lại |

## Tham khảo

- [../verify/README.md](../../code-repo/verify/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../stats/README.md](../../knowledge-system/stats/README.md)
- [../agents/README.md](../../knowledge-system/agents/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /claude-api sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
