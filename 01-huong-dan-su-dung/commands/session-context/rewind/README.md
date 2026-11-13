# /rewind — Quay ngược conversation + code về checkpoint an toàn (nút undo của cả não lẫn tay)

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Có — có thể xóa đoạn hội thoại sau checkpoint và revert file code về trạng thái checkpoint (mất việc sau checkpoint nếu không sao lưu; checkpoint sau bị bỏ)
> **Nói nôm na:** `/rewind` (kết hợp phím **Esc × 2 / double-Esc** mở checkpoint picker) là "cỗ máy thời gian toàn diện": quay cả **trí nhớ hội thoại** lẫn **file code** về 1 điểm checkpoint trước đó, khi bạn nhận ra 30 phút vừa rồi đi sai hướng.

## Khi nào dùng

- Dùng `/rewind` khi bạn nhận ra 30 phút vừa rồi đi sai hướng và muốn quay lại checkpoint trước.
- Dùng `/rewind` (hoặc Esc ×2) **trước khi** cố sửa tiếp một hướng đã rối — lui sớm rẻ hơn đập đi làm lại.
- Không dùng `/rewind` thay cho `git commit`/stash — file untracked/rename ngoài tầm backup có thể không về như cũ.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Hội thoại sau checkpoint bị cắt; file code revert về trạng thái của checkpoint đã chọn.
- Việc sau checkpoint mất nếu bạn không sao lưu (file untracked/rename có thể không về như cũ).

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Picker checkpoints trống / ít | Session mới, chưa có edit rủi ro nào; hoặc project không git nên ít snapshot | Làm tiếp để có checkpoints; `git init + commit` để snapshot tin cậy hơn |
| Rewind xong file không về như cũ | File untracked/rename ngoài tầm backup; hoặc edits sau checkpoint có bước manual ngoài Claude | Kiểm tra `git status`/`git stash list`, phục hồi tay; lần sau stash trước |
| Rewind nhầm checkpoint quá cũ (mất 1 tiếng) | Chọn vội, không đọc mô tả/preview | Đọc preview diff + thời gian kỹ; export trước luôn để có đường lui |

> **Cách đọc bảng này:** đây là bảng của lệnh rủi ro nhất nhóm — **Triệu chứng** là chuyện xảy ra sau khi rewind, **Vì sao** cho biết mất gì và vì sao, **Cách sửa** là cách cứu hoặc phòng trước bằng checkpoint đều đặn.

## Tham khảo

- [../clear/README.md](../../session-context/clear/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- [../branch/README.md](../../session-context/branch/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _/rewind chỉ "cứu" được khi đã có checkpoint — chạy `/diff` sau mỗi bước để tạo mốc._

> **Tóm gọn 1 câu:** `/rewind` là nút undo cho cả trí nhớ lẫn bàn tay: hội thoại và file code cùng quay về mốc checkpoint — và chỉ "cứu" được khi bạn đã tạo mốc.
