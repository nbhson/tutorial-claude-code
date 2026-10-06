# /hooks — Tự động hoá: việc máy làm được thì đừng bắt AI làm

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Có (hooks chạy shell code trên máy bạn mỗi khi trigger — hook độc/sai là mất file, lộ secret, hoặc vòng lặp tốn tiền)

> Nói nôm na: `/hooks` mở trung tâm quản lý hooks: những script tự chạy khi sự kiện xảy ra — trước/sau tool-call, khi session bắt đầu/kết thúc, khi model dừng... Dùng hooks để ép luật máy kiểm được (format, chặn `rm -rf`, log) thay vì năn nỉ model bằng lời. Hiểu `/hooks` là hiểu "phản xạ tự động" của Claude Code.

## Khi nào dùng

- Dùng /hooks khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /hooks **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /hooks thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/hooks`
File config
File local
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
#!/bin/bash
# lint-stop.sh — model báo xong thì kiểm, fail bắt làm tiếp (tối đa 3 vòng)
COUNT_FILE=/tmp/lint-loop-count
COUNT=$(cat $COUNT_FILE 2>/dev/null || echo 0)
if [ "$COUNT" -ge 3 ]; then echo 0 > $COUNT_FILE; exit 0; fi
if ! uvx ruff check . 2>/dev/null; then
  echo $((COUNT+1)) > $COUNT_FILE
  echo "LINT FAIL — sửa các lỗi trên rồi mới được dừng" >&2
```

Kết quả mong đợi:

- Claude trả đúng việc của /hooks (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Hook không chạy bao giờ | Matcher sai (`Edit,Write` thay vì `Edit\|Write`) | Sửa thành regex `Edit\|Write`; test bằng echo JSON pipe tay |
| Hook báo permission denied | Quên `chmod +x` | `chmod +x .claude/hooks/*.sh` |
| PreToolUse chặn cả lệnh lành | Regex quá rộng (`*rm*`) | Thu hẹp (`rm -rf`, `rm -rf /`); test với lệnh lành |

## Tham khảo

- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../plugin/README.md](../../knowledge-system/plugin/README.md)
- [../rules/README.md](../../knowledge-system/rules/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /hooks sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
