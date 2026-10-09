# /claude-api — Vọc Anthropic API: migrate SDK, thử managed agents

> Loại Skill (tích hợp API) · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (chỉ sinh code; nhưng Có nhẹ khi code chạm API key/tiền thật — key vào env, test trên Haiku trước)
> **Nói nôm na:** `/claude-api` là bộ subcommands giúp dev dùng Anthropic API/SDK: migrate code cũ sang SDK mới, onboard managed agents (Agent SDK chạy trên hạ tầng Anthropic), và tra cứu mẫu gọi API copy-paste được. Đặc biệt: khi bạn `import anthropic` trong code, skill này tự load (auto-load) để gợi ý đúng phiên bản SDK.

## Khi nào dùng

- Dùng khi bạn viết/sửa code gọi Anthropic API hoặc SDK và muốn mẫu đúng phiên bản.
- Dùng **trước khi** tự đọc changelog SDK: skill auto-load lúc bạn `import anthropic` để nhắc version.
- Không dùng thay việc hiểu luồng API của bạn — code sinh xong bạn vẫn phải test.

## Cách gọi

```bash
/claude-api                        # mở skill, xem subcommand
/claude-api migrate <file>         # migrate code cũ sang SDK mới
/claude-api managed-agents-onboard # onboard managed agents
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/claude-api migrate src/llm_client.py
# → phát hiện: dùng client.completion (cũ) + max_tokens thiếu
# → diff: chuyển client.messages.create(model="claude-sonnet-4-6", max_tokens=1024, system=..., messages=[...])
# → duyệt diff → chạy pytest → xong
```

Kết quả mong đợi:

- Diff migrate rõ ràng (API cũ → `client.messages.create(...)` đúng tham số), kèm cảnh báo method thiếu.
- Với onboard: checklist env + smoke test chạy được trên managed.

**Kiểm tra nhanh:** `pip show anthropic` xem version; chạy `pytest` xanh sau khi duyệt diff.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
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

> Mẹo 1 dòng: _dán API key qua env, không hardcode; test trên Haiku trước cho rẻ._
