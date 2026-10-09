# /cost — Xem tốn bao nhiêu token và bao nhiêu tiền trong phiên

> Loại Built-in · Nhóm Session & Context · Mức rủi ro Không (lệnh chỉ đọc báo cáo billing, không xóa/sửa gì, không phát sinh phí khi gọi)
> **Nói nôm na:** `/cost` là "hóa đơn tại bàn": cho biết session hiện tại đã đốt bao nhiêu input/output tokens (kể cả cache), quy ra tiền ước tính, để bạn quyết định có nên compact/clear/đổi model hay không.

## Khi nào dùng

- Dùng `/cost` khi bạn muốn biết session đang đốt bao nhiêu token/quy ra tiền để quyết định có nên tiếp.
- Dùng `/cost` sau khi đổi model hoặc trước khi tiếp tục task dài để ý thức ngân sách.
- Không dùng `/cost` như số billing chính thức — đây là ước tính client, dashboard mới là nguồn tin khi trả tiền.

## Cách gọi

```bash
`/cost`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Đầu task: đặt ngân sách miệng "$5 cho task này"
# Sau 45 phút:
/cost
# → $1.80, input 400K (cached 320K), output 25K
# → đang trong ngân sách, làm tiếp

# Sau 90 phút:
/context
```

Kết quả mong đợi:

- Claude trả đúng việc của /cost (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/cost` báo $0 dù hỏi nhiều | Đang dùng subscription quota, counters hiển thị khác / bản cũ chưa nhân giá | Không phải lỗi nghiêm trọng; xem `/usage` (quota) thay vì `/cost` |
| Số `/cost` khác dashboard | `/cost` ước tính client, dashboard tính giá chính thức + discount/thuế | Tin dashboard cho billing, tin `/cost` cho ra quyết định kỹ thuật |
| Cost vọt sau khi đổi sang Opus | Quên mình đang dùng Opus đắt gấp nhiều lần | Gõ `/cost` ngay sau khi đổi model để ý thức giá; đổi về Sonnet cho việc vặt |

## Tham khảo

- [../usage/README.md](../../session-context/usage/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /cost sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
