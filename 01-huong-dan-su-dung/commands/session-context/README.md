# /session-context — nhóm 18 lệnh mở, dọn, lưu và chia nhánh phiên

> **Loại:** index nhóm lệnh · **Nhóm:** Phiên làm việc & Context · **Mức rủi ro:** thấp (chỉ /rewind là mức "Có", còn lại đụng context phiên)
> **Nói nôm na:** nhóm này là nơi bạn "quản lý bộ nhớ tạm" của phiên — dọn context, lưu/bàn giao, thử nhánh, quay checkpoint — mà không đụng code trên đĩa. /rewind là lệnh duy nhất "có" rủi ro thật (xóa + revert).

## Khi nào dùng

- Bạn muốn dọn context: /clear (đổi task), /compact (cùng task, phình), /context (xem đang tốn gì).
- Bạn muốn lưu/thử nhánh: /export (bàn giao), /fork (thử hướng B giữ bản gốc), /rewind (quay checkpoint khi sai hướng).
- Bạn cần quản lý phiên: /restart (treo/lag), /resume (nạp lại transcript cũ), /tasks (job nền), /background (chạy task dài ở nền).

## Cách gọi

```bash
# go / trong session, go chu dau lenh de loc
/compact
/rewind
/fork
```

Kiểm tra lệnh có ở máy bạn không: mở session, gõ `/` rồi gõ tiếp chữ đầu lệnh — version/provider khác nhau hiện lệnh khác nhau.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Bạn sai hướng sau vài bước, muốn quay về mốc an toàn:

```bash
/rewind
# chon checkpoint can quay ve (co sau khi da co /diff hoac moc)
```

- Mong đợi: chọn checkpoint → hội thoại sau checkpoint bị xóa, file revert về trạng thái checkpoint.
- Kiểm tra (≤30 giây): xem `git status`, file đã revert chưa; nếu chưa có checkpoint, /rewind sẽ báo lỗi (xem "Lỗi thường gặp").

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Session treo/lag, không phản hồi | Context phình quá, hoặc job nền /tasks kẹt | /restart để khởi động lại (giữ transcript); /tasks để kill job kẹt |
| /fork / /branch "thiếu" context — bản sao không đủ như gốc, việc phụ sai hướng | Fork không sao lưu đủ context, hoặc tắt fork mode (CLAUDE_CODE_FORK_SUBAGENT=0) | Kiểm tra fork mode đang bật (≥2.1.232), /context trước khi fork để chắc đủ context |
| /rewind báo lỗi "không có checkpoint", không quay được | Phiên chưa tạo checkpoint nào (chưa chạy /diff, chưa có mốc) | Tạo checkpoint trước (chạy /diff sau mỗi bước), sau đó /rewind mới quay được |

## Bộ 3 phải nhớ

> /clear trắng context khi đổi task | /compact nén khi cùng task | /rewind quay checkpoint khi sai hướng | /fork thử hướng B giữ bản gốc

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

## Sơ đồ quyết định (30 giây)

```text
Cần gì? -> Nhóm này cho gì? -> Lệnh nào?
Đọc 3 lệnh trong "Bộ 3" trước, còn lại tra khi cần.
Gõ / trong session để xem lệnh nào hiện ở máy bạn.
```

## Cách dùng nhóm này cho đúng

```bash
# 1. Hoc 3 lenh tru truoc (xem "Bo 3 phai nho" o tren)
# 2. Con lai tra khi gap viec that, dung hoc het 1 luc
# 3. Loi la trong nhom nay -> /status -> /doctor -> doc lenh tuong ung
```

## Tham khảo

- [← Về index tất cả lệnh](../README.md)
- [04 — slash commands toàn tập](../../04-slash-commands-toan-tap.md)
- [Nhóm model-mode](../model-mode/README.md) · [Nhóm knowledge-system](../knowledge-system/README.md)

> Mẹo 1 dòng: _/rewind chỉ "cứu" được khi đã có checkpoint — luôn /diff sau mỗi bước để tạo mốc._
