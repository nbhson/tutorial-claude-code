# /export — Xuất toàn bộ hội thoại ra file text để lưu trữ, bàn giao, đối soát

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ đọc + ghi 1 file export mới, không xóa/sửa code hay history)

> Nói nôm na: `/export` là "nút in báo cáo": gom transcript hiện tại thành 1 file text/markdown gọn gàng để gửi đồng đội, lưu docs, hoặc đọc lại sau khi `/clear`.

## Khi nào dùng

- Dùng /export khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /export **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /export thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/export`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Cuối ca, session 80 turns, người sau không thể đọc hết
/compact Tóm tắt để bàn giao: đã xong auth, đang dở payments bước webhook, file cần đọc src/payments/*.
/export
# → "Lưu vào docs/handover-2026-10-04.md"
# → gửi file cho ca sau, họ đọc 2 phút là vào việc
```

Kết quả mong đợi:

- Claude trả đúng việc của /export (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Không biết file export nằm đâu | Mỗi bản gợi ý đường dẫn khác nhau, dễ bỏ qua | Đọc kỹ câu trả lời sau `/export`, hoặc dặn trước "lưu vào docs/handover.md" |
| File export quá dài (5000+ dòng) | Xuất nguyên session 100+ turns chưa compact | `/compact` trước rồi export; hoặc dặn "chỉ xuất quyết định + bước tiếp theo" |
| Export thiếu đoạn trước compact | Đúng thiết kế: đoạn cũ đã nén thành summary | Muốn full thì soi `.jsonl` gốc, hoặc export thường xuyên hơn |

## Tham khảo

- [../copy/README.md](../../session-context/copy/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /export sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
