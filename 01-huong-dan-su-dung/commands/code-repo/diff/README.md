# /diff — xem diff tương tác: model sửa gì, từng dòng, duyệt trước khi nhận

> Loại Built-in · Nhóm Code & Repo · Mức rủi ro Không
> **Nói nôm na:** `/diff` mở interactive diff viewer: liệt kê mọi file model vừa sửa, từng hunk thêm/xóa, cho bạn duyệt/chỉnh/revert trước khi nhận. Không có `/diff` sau bước code = nhận hàng mù.

## Khi nào dùng

- Dùng `/diff` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/diff` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/diff` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/diff`
`/diff <file>`
`/diff --staged`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/diff
# → hunk 1–3: rename đúng. hunk 4: đổi if (x > 0) thành if (x >= 0) — KHÔNG yêu cầu.
# → bỏ hunk 4, giữ 1–3.
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/diff` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/diff` trống dù model bảo đã sửa | Sửa ở worktree khác (`/batch`) hoặc file chưa flush | Kiểm tra worktree path; bảo model paste đường dẫn tuyệt đối |
| Diff quá lớn (50 file) đọc nản | Task quá to, model sửa lan | Bảo "tóm tắt 10 bullet + chỉ hiện file quan trọng"; chia task nhỏ |
| `/diff` hiện cả file bạn sửa tay | Gộp chung thay đổi người + model | Dùng `git diff` tay để phân biệt, hoặc commit phần bạn trước |

## Tham khảo

- [../review/README.md](../../code-repo/review/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/diff` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
