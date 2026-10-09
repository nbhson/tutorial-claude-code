# /batch — chạy song song nhiều task trong worktree tách, không đụng main

> Loại Built-in · Nhóm Song song & Ủy thác · Mức rủi ro Trung bình
> **Nói nôm na:** `/batch` tạo nhiều worktree + spawn subagent chạy song song các task độc lập (refactor A, fix test B, viết doc C). Giữ main sạch, dễ xem diff riêng.

## Khi nào dùng

- Dùng `/batch` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/batch` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/batch` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/batch "<task1>" "<task2>"`
`/batch --plan`
`/batch --keep`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/batch "Refactor src/auth → typesafe (không đổi API)" "Fix flake tests/payments" "Thêm doc usage CLI"
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/batch` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Tạo worktree fail (branch đã tồn tại) | Dùng tên branch trùng | Dùng tên duy nhất hoặc `git worktree remove` nhánh cũ |
| Agent chạm nhầm file chung | Task không thật sự độc lập | Chia task rõ ràng; tránh sửa config chung cùng lúc |
| Dọn worktree quên → rác | Không dùng `--keep` rồi quên xóa | Sau khi merge, xóa worktree + branch; dùng `--keep` chỉ khi debug |

## Tham khảo

- [../diff/README.md](../../code-repo/diff/README.md)
- [../subtask/README.md](../../code-repo/subtask/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/batch` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
