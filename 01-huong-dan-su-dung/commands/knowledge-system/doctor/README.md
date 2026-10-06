# /doctor — Khám sức khoẻ repo: CLAUDE.md phình không, thiếu phanh ở đâu

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ đọc + báo cáo; nhưng Có nếu bạn Yes hết mọi đề xuất fix — nhất là trim CLAUDE.md từ bản ≥2.1.206 mà không review)

> Nói nôm na: `/doctor` chạy audit tự động toàn diện: quét CLAUDE.md (dài quá không, mâu thuẫn không), permissions (mở toang không), MCP (server chết không), hooks (lỗi không), plugins (thừa không), skills/agents (rác không)... rồi chấm điểm + gợi ý fix từng cái (bạn duyệt mới sửa). Hiểu `/doctor` là hiểu "bác sĩ tổng quát" gọi mỗi tháng 1 lần.

## Khi nào dùng

- Dùng /doctor khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /doctor **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /doctor thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/doctor`
`/doctor --quick`
`/doctor --fix`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Vừa clone repo người khác để lại, chưa biết gì:
/doctor

# Báo cáo ví dụ:
# 🔴 claude-md: không có CLAUDE.md (0 dòng) → /init tạo mới?
# 🟡 permissions: không có settings.json → dùng mặc định (hỏi nhiều)
# 🟢 mcp: không có server (sạch, khỏi lo)
# 🟡 hooks: không có (khuyên thêm guard + format)
```

Kết quả mong đợi:

- Claude trả đúng việc của /doctor (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Trim xong model làm sai hàng loạt | Trim cắt mất luật quan trọng | `git checkout .claude/` rollback; tách rules tay rồi trim lại từng phần |
| `/doctor` báo MCP dead dù hôm qua còn chạy | Laptop sleep kill stdio | `/mcp reconnect <tên>` rồi `/doctor mcp` lại |
| Điểm thấp vì "thiếu CLAUDE.md" nhưng repo cố tình không cần | Repo 5 file, doctor heuristic quá đà | Bỏ qua mục đó (không phải lỗi); doctor là gợi ý, không phải luật |

## Tham khảo

- [../debug/README.md](../../knowledge-system/debug/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../rules/README.md](../../knowledge-system/rules/README.md)
- [../memory/README.md](../../knowledge-system/memory/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /doctor sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
