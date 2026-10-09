# /goal — Đặt điều kiện hoàn thành, evaluator tự check mỗi turn cho tới khi xong

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (không sửa file; chỉ đặt tiêu chí dừng + vòng check; tốn thêm tokens evaluator — cần ≥2.1.139)
>
> **Nói nôm na:** `/goal` biến câu "làm cho xong" mơ hồ thành hợp đồng rõ ràng: bạn viết điều kiện hoàn thành ("tests pass + không lint error"), một evaluator (model phụ) check sau mỗi turn, task chỉ dừng khi đạt — hoặc khi bạn ngắt. Chống bệnh "model bảo xong nhưng thực ra chưa".

## Khi nào dùng

- Dùng /goal khi task có tiêu chí hoàn thành đo được (test pass, lint sạch, file tồn tại) để evaluator tự check tới khi xong.
- Dùng /goal **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /goal thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/goal <điều kiện>`
`/goal`
`/goal clear`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: đặt goal trước khi cho làm
/goal Refactor src/auth/ xong khi: pytest tests/auth/ pass toàn bộ (không skip),
ruff + mypy sạch, và grep "old_login" không còn kết quả trong src/.
```

Kết quả mong đợi:

- Claude trả đúng việc của /goal (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/goal` báo `unknown command` | Bản < 2.1.139 | Update CLI ≥2.1.139 |
| Evaluator PASS ẩu dù còn lỗi | Goal mơ hồ ("làm cho xong") | Viết lại goal có số đo (pass, <, file tồn tại) |
| Loop mãi không PASS (20+ turns) | Goal bất khả thi hoặc thiếu tools test | Hạ goal khả thi; kiểm tra Bash/pytest có bị chặn không; ngắt tay |

## Tham khảo

- [../plan/README.md](../../model-mode/plan/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../loop/README.md](../../code-repo/loop/README.md)
- [../effort/README.md](../../model-mode/effort/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /goal sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
