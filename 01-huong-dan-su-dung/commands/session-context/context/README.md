# /context — Kính hiển vi context window: đang đầy bao nhiêu, nặng ở đâu

> Loại Built-in · Nhóm Session & Context · Mức rủi ro Không (lệnh chỉ đọc, không xóa/sửa gì cả — an toàn tuyệt đối)
> **Nói nôm na:** `/context` mở bảng "grid visualize": cho bạn thấy context window đã dùng bao nhiêu %, nặng ở chỗ nào (system, CLAUDE.md, history, tools, MCP), để quyết định nên `/compact`, `/clear` hay cứ làm tiếp.

## Khi nào dùng

- Dùng `/context` khi Claude trả lời chậm dần và bạn muốn biết context đang nặng ở chỗ nào.
- Dùng `/context` định kỳ (30–60 phút) để quyết định `/compact`, `/clear` hay cứ làm tiếp.
- Không dùng `/context` như số billing — nó đo dung lượng hội thoại hiện tại, không phải tiền tích lũy.

## Cách gọi

```bash
`/context`
`/context` _(gõ lại sau mỗi 30-60 phút)_
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Bạn làm task payments được 1 tiếng, thấy trả lời chậm dần
/context
# → Output: 74%, History 55%, Tool results 15%
# → Kết luận: cùng task, rác là log → compact, không clear

/compact Bỏ log test, giữ quyết định Postgres+Drizzle và file src/payments/route.ts, bước tiếp là fix webhook mock.
```

Kết quả mong đợi:

- Claude trả đúng việc của /context (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/context` báo % khác với `/cost` | `/context` đo RAM hiện tại, `/cost` đo tổng billing tích lũy | Không phải lỗi; đọc cả 2 với ý nghĩa khác nhau |
| % vọt từ 30% lên 75% sau 1 paste | Paste file log/ảnh lớn | `/compact bỏ log` hoặc đừng paste cả file, chỉ paste đoạn cần (`read` theo dòng) |
| Grid không hiện breakdown MCP | Bản CLI cũ hoặc MCP chưa trả output nào | Update CLI; breakdown chỉ hiện nhóm có số liệu >0 |

## Tham khảo

- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- [../cost/README.md](../../session-context/cost/README.md)
- [../usage/README.md](../../session-context/usage/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /context sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
