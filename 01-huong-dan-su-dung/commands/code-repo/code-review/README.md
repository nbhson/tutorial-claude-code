# /code-review — Skill review bằng subagent mới (fresh eyes) soi diff/PR

> Loại Skill/Workflow · Nhóm Code & Repo · Nguy hiểm Không (mặc định chỉ đọc + báo cáo; chỉ nguy hiểm nếu bạn bật auto-fix + bypass — luôn review trước khi apply)

> Nói nôm na: `/code-review` là skill gọi 1 subagent HOÀN TOÀN MỚI (không biết lịch sử chat, không bênh code cũ) để soi diff hoặc PR: đọc từng hunk, check bug/logic/bảo mật/test, trả báo cáo critical/high/low. Khác `/review` (cùng agent tự chấm) ở chỗ mắt mới nên bắt được lỗi tư duy mà tác giả + agent cũ cùng mù.

## Khi nào dùng

- Dùng /code-review khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /code-review **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /code-review thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/code-review`
`/code-review --max-findings <n\
`/code-review ultra`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: gọi skill
/code-review 128
```

Kết quả mong đợi:

- Claude trả đúng việc của /code-review (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/code-review` báo `skill not found` | Bản cũ chưa có skills, hoặc skill chưa cài | Update CLI; kiểm tra `/skills` list; dùng `gh pr diff \| claude --print` thủ công |
| Review PR báo `gh: not authenticated` | Chưa `gh auth login` | `gh auth login` rồi chạy lại |
| Báo cáo chung chung, không có file:dòng | Diff quá lớn (>2000 dòng) hoặc effort thấp | Chia PR nhỏ; `/effort high`; chỉ định thư mục cụ thể |

## Tham khảo

- [../review/README.md](../../code-repo/review/README.md)
- [../ultrareview/README.md](../../code-repo/ultrareview/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /code-review sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
