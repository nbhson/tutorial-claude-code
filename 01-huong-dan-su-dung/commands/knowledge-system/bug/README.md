# /bug — Gói bug report gửi Anthropic: khi lỗi là của tool, không phải của bạn

> Loại Workflow (thu thập + đóng gói) · Nhóm Tri thức & Hệ thống · Nguy hiểm Có nếu ẩu (gói conversation gửi đi có thể chứa secret/code nội bộ — luôn review trước khi Send)

> Nói nôm na: `/bug` thu thập mọi thứ cần để báo lỗi Claude Code: mô tả, bước tái hiện, log, version, transcript rút gọn — đóng thành 1 gói, bạn review rồi mới gửi (GitHub issue hoặc Anthropic support). Dùng khi `/debug` xong kết luận "tôi làm đúng, tool sai". Hiểu 1 câu: `/debug` tự xem, `/bug` gửi người ta xem.

## Khi nào dùng

- Dùng /bug khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /bug **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /bug thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/bug`
`/bug --anonymize`
`/bug --dry-run`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# /debug xong: cứ gọi mcp__db__query là treo 180s, reconnect không hết, bản cũ không bị.
/bug --anonymize
# B1 mô tả: "mcp__db__query treo sau update 2.1.210, bản 2.1.205 OK. Tái hiện: /mcp add db ... rồi query bất kỳ."
# B3 review: kiểm tra không còn DSN/pass → Send
# → có link issue, dán vào PR nội bộ để team né bản lỗi
```

Kết quả mong đợi:

- Claude trả đúng việc của /bug (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/bug` báo unknown | CLI cũ | Update CLI; hoặc báo tay qua GitHub |
| Anonymize sót secret lạ (format riêng cty) | Pattern không biết | Review tay B3; thêm pattern vào `.claude/bug-ignore` nếu có |
| Issue bị close "need repro" | Thiếu bước tái hiện | Bổ sung 3 bước + clip/log, mở lại |

## Tham khảo

- [../debug/README.md](../../knowledge-system/debug/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../stats/README.md](../../knowledge-system/stats/README.md)
- [../mcp/README.md](../../knowledge-system/mcp/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /bug sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
