# /verify — Build + chạy app thật, quan sát output — khác test ở chỗ có bằng chứng sống

> Loại Skill/Workflow · Nhóm Code & Repo · Nguy hiểm Thấp (có chạy code — nhưng chỉ build/test/dev, không deploy; nguy hiểm nếu verify script chạm production DB — luôn verify trên staging/test)

> Nói nôm na: `/verify` không tin lời model nói ("em fix xong rồi") mà bắt nó build + chạy thật: `npm run build`, `pytest`, boot app, curl endpoint, paste output/log lên màn hình. Có output xanh mới gọi là xong. Đây là khác biệt cốt lõi với "chạy test" qua loa: verify đòi bằng chứng quan sát được.

## Khi nào dùng

- Dùng /verify khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /verify **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /verify thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/verify`
`/verify <phạm vi>`
`/verify --e2e`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Có verify:
/verify auth
```

Kết quả mong đợi:

- Claude trả đúng việc của /verify (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/verify` báo `skill not found` / unknown | Bản < 2.1.145 | Update CLI ≥2.1.145 |
| Verify chạy sai lệnh test (`npm` trong khi `pnpm`) | Chưa `/init`, CLAUDE.md thiếu/sai | `/init` lại hoặc sửa CLAUDE.md lệnh đúng rồi `/verify` lại |
| Verify FAIL vì port đã dùng (EADDRINUSE) | App dev cũ còn chạy nền | Kill process cũ (`lsof -ti:3000 \| xargs kill`), verify lại với port riêng |

## Tham khảo

- [../diff/README.md](../../code-repo/diff/README.md)
- [../review/README.md](../../code-repo/review/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../goal/README.md](../../model-mode/goal/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /verify sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
