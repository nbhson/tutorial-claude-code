# /copy — Copy đoạn hội thoại ra clipboard để paste nhanh sang Slack/PR/docs

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ đọc + ghi clipboard, không xóa/sửa code hay history)

> Nói nôm na: `/copy` là "chụp nhanh 1 đoạn": copy phần hội thoại (hoặc câu trả lời cuối) ra clipboard hệ điều hành để paste vào Slack, PR, docs mà không cần xuất cả file như `/export`.

## Khi nào dùng

- Dùng /copy khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /copy **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /copy thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/copy`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Model vừa đưa patch mutex 20 dòng, team đang hóng trong Slack
/copy
# → sang Slack paste: code + giải thích giữ nguyên format
# → nhanh hơn chụp màn hình, đồng đội copy code được luôn
```

Kết quả mong đợi:

- Claude trả đúng việc của /copy (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Paste ra trắng/không có gì | Clipboard qua SSH không khả dụng / quyền OS chặn | Copy tay từ output fallback; cấp quyền clipboard cho terminal/IDE |
| Copy cả đoạn dài 500 dòng | Không giới hạn phạm vi | Dặn rõ: "chỉ copy 20 dòng patch + 3 bullets giải thích" rồi `/copy` |
| Format vỡ khi paste vào Slack | Slack cần markdown/plain khác nhau | Paste dưới dạng code block hoặc dùng `/export` lấy file khi cần format chuẩn |

## Tham khảo

- [../export/README.md](../../session-context/export/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- [../todos/README.md](../../session-context/todos/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /copy sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
