# /rewind — Quay ngược conversation + code về checkpoint an toàn (nút undo của cả não lẫn tay)

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Có — có thể xóa đoạn hội thoại sau checkpoint và revert file code về trạng thái checkpoint (mất việc sau checkpoint nếu không sao lưu; checkpoint sau bị bỏ)

> Nói nôm na: `/rewind` (kết hợp phím **Esc × 2 / double-Esc** mở checkpoint picker) là "cỗ máy thời gian toàn diện": quay cả **trí nhớ hội thoại** lẫn **file code** về 1 điểm checkpoint trước đó, khi bạn nhận ra 30 phút vừa rồi đi sai hướng.

## Khi nào dùng

- Dùng /rewind khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /rewind **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /rewind thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/rewind`
`Esc Esc` (nhấn Esc 2 lần)
`/rewind` + chọn checkpoint
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# 10:20 checkpoint tự tạo "trước khi refactor src/auth/ (8 files)"
# 10:20-11:10: sửa 8 files, test từ 2 fail lên 14 fail, càng fix càng rối

/rewind
# → picker: chọn "10:20 trước khi refactor src/auth/"
# → xác nhận "Revert 8 files + cắt 25 turns sau checkpoint? [Yes]"
# → về 10:20: test lại xanh như cũ, đầu óc nhẹ

```

Kết quả mong đợi:

- Claude trả đúng việc của /rewind (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Picker checkpoints trống / ít | Session mới, chưa có edit rủi ro nào; hoặc project không git nên ít snapshot | Làm tiếp để có checkpoints; `git init + commit` để snapshot tin cậy hơn |
| Rewind xong file không về như cũ | File untracked/rename ngoài tầm backup; hoặc edits sau checkpoint có bước manual ngoài Claude | Kiểm tra `git status`/`git stash list`, phục hồi tay; lần sau stash trước |
| Rewind nhầm checkpoint quá cũ (mất 1 tiếng) | Chọn vội, không đọc mô tả/preview | Đọc preview diff + thời gian kỹ; export trước luôn để có đường lui |

## Tham khảo

- [../clear/README.md](../../session-context/clear/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- [../branch/README.md](../../session-context/branch/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /rewind sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
