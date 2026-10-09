# /pr-comments — xử lý comment review PR: kéo về, sửa từng cái, resolve

> Loại Skill (quy trình PR) · Nhóm Tri thức & Hệ thống · Mức rủi ro Không
> **Nói nôm na:** `/pr-comments` (alias `/pr_comments`) kéo toàn bộ review comments của 1 PR về local, liệt kê từng thread, cùng bạn sửa từng cái rồi resolve/reply hàng loạt. Cần MCP GitHub hoặc `gh` CLI.

## Khi nào dùng

- Dùng `/pr-comments` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/pr-comments` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/pr-comments` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/pr-comments`
`/pr-comments <số>`
`/pr-comments --unresolved`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/pr-comments --address
# → 8 threads gom theo 3 file.
# Fix từng thread → git diff review → push → resolve hàng loạt.
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/pr-comments` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Không kéo được comments | Chưa login `gh` / MCP github auth expired | `gh auth login` hoặc `/mcp reconnect github` |
| Hiện PR sai | Nhánh local không link PR nào | Truyền số rõ `/pr-comments 248` |
| Fix xong test fail | Sửa 1 chỗ vỡ chỗ khác | Chạy test file đó ngay sau mỗi fix, đừng dồn cuối |

## Tham khảo

- [../verify/README.md](../../code-repo/verify/README.md)
- [../../knowledge-system/agents/README.md](../../knowledge-system/agents/README.md)
- [../../knowledge-system/mcp/README.md](../../knowledge-system/mcp/README.md)
- [../../knowledge-system/plugin/README.md](../../knowledge-system/plugin/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/pr-comments` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
