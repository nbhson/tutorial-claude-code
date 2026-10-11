# /verify — build + chạy app thật, quan sát output — khác test ở chỗ có bằng chứng sống

> Loại Skill/Workflow · Nhóm Code & Repo · Mức rủi ro Thấp
> **Nói nôm na:** `/verify` không tin lời model nói ("em fix xong rồi") mà bắt nó build + chạy thật: `npm run build`, `pytest`, boot app, curl endpoint, paste output/log lên màn hình. Có output xanh mới gọi là xong.

## Khi nào dùng

- Dùng `/verify` khi model khẳng định "xong rồi" và bạn muốn bằng chứng sống: build, chạy test, boot app, gọi endpoint.
- Verify **sau mỗi bước lớn**, đừng dồn tới cuối — lỗi ở 1 bước sẽ lây sang các bước sau.
- Không dùng `/verify` thay cho việc suy nghĩ về thiết kế: nó chứng minh code chạy được, không chứng minh code đúng ý bạn.

## Cách gọi

```bash
`/verify`
`/verify <phạm vi>`
`/verify --e2e`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/verify auth
```

**Kết quả mong đợi:**

- Output build + chạy thật hiện trên màn hình, kết quả PASS/FAIL rõ ràng.
- Model liệt kê lệnh nó sắp chạy (build/test/boot app) trước khi chạy, để bạn nắm được nó đã "chứng minh" bằng gì.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/verify` báo `skill not found` / unknown | Bản < 2.1.145 | Update CLI ≥ 2.1.145 |
| Verify chạy sai lệnh test (`npm` trong khi `pnpm`) | Chưa `/init`, CLAUDE.md thiếu/sai | `/init` lại hoặc sửa CLAUDE.md lệnh đúng rồi `/verify` lại |
| Verify FAIL vì port đã dùng (EADDRINUSE) | App dev cũ còn chạy nền | Kill process cũ (`lsof -ti:3000 \| xargs kill`), verify lại với port riêng |

## Tham khảo

- [../diff/README.md](../../code-repo/diff/README.md)
- [../review/README.md](../../code-repo/review/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../../model-mode/goal/README.md](../../model-mode/goal/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/verify` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
