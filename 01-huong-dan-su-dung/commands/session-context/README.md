# Nhóm: Phiên làm việc & Context (18 lệnh)

> Mở, dọn, lưu, chia nhánh phiên mà không đụng code trên đĩa.

## Bộ 3 phải nhớ

> /clear trắng context khi đổi task | /compact nén khi cùng task | /rewind quay checkpoint khi sai hướng | /fork thử hướng B giữ bản gốc

## Sơ đồ quyết định (30 giây)

```text
Cần gì? -> Nhóm này cho gì? -> Lệnh nào?
Đọc 3 lệnh trong "Bộ 3" trước, còn lại tra khi cần.
Gõ / trong session để xem lệnh nào hiện ở máy bạn.
```

## Các lệnh (18)

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/background](./background/README.md) | Thấp | Chạy task dài ở nền, trả terminal lại cho bạn |
| [/branch](./branch/README.md) | Không | Copy context sang nhánh thử nghiệm, bản chính giữ nguyên |
| [/clear](./clear/README.md) | Không | Xóa sạch hội thoại, bắt đầu phiên trắng |
| [/compact](./compact/README.md) | Không | Nén hội thoại dài thành bản tóm tắt cùng mạch task |
| [/context](./context/README.md) | Không | Xem context window đang đầy bao nhiêu, tốn gì |
| [/copy](./copy/README.md) | Không | Copy câu trả lời ra clipboard (Slack, PR, docs) |
| [/cost](./cost/README.md) | Không | Xem token/tiền đã dùng trong phiên |
| [/export](./export/README.md) | Không | Xuất hội thoại ra file để lưu trữ/bàn giao |
| [/fork](./fork/README.md) | Không | Copy context sang session mới, bản gốc giữ nguyên |
| [/help](./help/README.md) | Không | Tra cứu lệnh, cú pháp, phím tắt ngay trong session |
| [/recap](./recap/README.md) | Không | Tóm tắt nhanh việc đã làm khi quay lại sau break |
| [/rename](./rename/README.md) | Không | Đổi tên hiển thị session cho dễ nhớ |
| [/restart](./restart/README.md) | Không | Khởi động lại session khi treo/lag, giữ transcript |
| [/resume](./resume/README.md) | Không | Nạp lại transcript session cũ vào context |
| [/rewind](./rewind/README.md) | Có | Quay về checkpoint: xóa hội thoại sau đó + revert file |
| [/tasks](./tasks/README.md) | Không | Liệt kê/theo dõi job nền, kill job khi kẹt |
| [/todos](./todos/README.md) | Không | Xem/ghi todo list trong memory session |
| [/usage](./usage/README.md) | Không | Xem thống kê chi tiết token/chi phí theo phiên |

## Cách dùng nhóm này cho đúng

```bash
# 1. Học 3 lệnh trụ trước (xem "Bộ 3 phải nhớ" ở trên)
# 2. Còn lại tra khi gặp việc thật, đừng học hết 1 lúc
# 3. Lỗi lạ trong nhóm này -> /status -> /doctor -> đọc lệnh tương ứng
```

[← Về index tất cả lệnh](../README.md)
