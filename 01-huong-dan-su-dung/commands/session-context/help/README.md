# /help — Trợ giúp tại chỗ: tra cứu lệnh, cú pháp, phím tắt trong 5 giây

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (chỉ hiển thị tài liệu, không thay đổi gì)
> **Nói nôm na:** `/help` là "bảng chỉ dẫn dán tường": liệt kê slash commands khả dụng, cú pháp ngắn, phím tắt (như double-Esc), để tra ngay trong terminal mà không cần mở docs web.

## Khi nào dùng

- Dùng `/help` khi bạn quên tên/cú pháp lệnh hoặc phím tắt (như double-Esc) ngay trong terminal.
- Dùng `/help` ngay khi mới vào session để biết máy mình đang có những lệnh nào.
- Không dùng `/help` như tài liệu deep-dive — nó liệt kê nhanh vài dòng, chi tiết vẫn ở file chuyên đề/docs.

## Cách gọi

```bash
`/help`
`/help <lệnh>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/help
# → đọc thấy: /clear (xóa), /compact (nén), /rewind (quay lại), Esc Esc
# → thử ngay lệnh an toàn:
/context
# → hiểu % RAM, tự tin làm tiếp
```

Kết quả mong đợi:

- Danh sách slash commands + cú pháp ngắn + phím tắt (như Esc Esc) hiện ngay trong session.
- Biết máy bạn đang có những lệnh nào mà không phải mở docs web.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/help` thiếu lệnh mới (branch/fork) | CLI cũ | `npm i -g @anthropic-ai/claude-code` rồi `/help` lại |
| `/help <lệnh>` không ra chi tiết | Bản bạn chỉ hỗ trợ `/help` tổng | Hỏi trực tiếp: "Giải thích /<lệnh> + ví dụ" hoặc mở file deep-dive |
| Lệnh trong help gõ báo unknown | Lệnh của plugin/MCP đã tắt | Bật lại plugin/MCP hoặc xem bài plugins/MCP |

## Tham khảo

- [../clear/README.md](../../session-context/clear/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _mới vào session gõ `/help` một lần để biết máy mình có gì; lệnh không hiện thì update CLI._
