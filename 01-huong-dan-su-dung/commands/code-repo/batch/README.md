# /batch — Chia task lớn thành 5–30 worktree-subagents song song, mỗi đứa 1 PR

> Loại Skill/Workflow · Nhóm Code & Repo · Nguy hiểm Có nếu ẩu (30 đứa cùng sửa + cùng push = conflict/loạn branch; tốn quota mạnh — luôn giới hạn scope + số lượng + verify từng đứa)

> Nói nôm na: `/batch` là "chia để trị" ở quy mô lớn: tách 1 epic thành N task độc lập, mỗi task chạy trong 1 git worktree riêng + 1 subagent riêng, cuối cùng mỗi đứa mở 1 PR. Thay vì 1 agent làm 3 ngày, 10 agents làm 1 buổi — với giá là công sức điều phối + quota.

## Khi nào dùng

- Dùng /batch khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /batch **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /batch thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/batch <mô tả epic>`
`/batch <epic> --n <số>`
`/batch <epic> --scope <path>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: batch 10 đứa, mỗi đứa 2 file
/batch Viết unit test (vitest) cho src/utils/*.ts, mỗi subagent đúng 2 file,
goal: "vitest file đó pass, coverage lines ≥ 80%". Mỗi đứa 1 branch + 1 PR.
Tối đa 10 song song.
```

Kết quả mong đợi:

- Claude trả đúng việc của /batch (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| 2 subagents sửa cùng file → conflict | Chia scope giao nhau / không cấm rõ | Chia lại không giao nhau; branch riêng; merge tay chỗ conflict |
| Worktree báo `already exists` / detached | Worktree cũ chưa xóa / branch trùng | `git worktree list` + `remove` cái cũ; đặt tên branch duy nhất |
| Subagent kẹt `permission denied` git push | Permissions thiếu `Bash(git push)` / `gh` chưa auth | Allow push trong session batch; `gh auth login` trước |

## Tham khảo

- [../plan/README.md](../../model-mode/plan/README.md)
- [../goal/README.md](../../model-mode/goal/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /batch sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
