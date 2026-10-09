# /hooks — Tự động hoá: việc máy làm được thì đừng bắt AI làm

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Có (hooks chạy shell code trên máy bạn mỗi khi trigger — hook độc/sai là mất file, lộ secret, hoặc vòng lặp tốn tiền)
> **Nói nôm na:** `/hooks` mở trung tâm quản lý hooks: những script tự chạy khi sự kiện xảy ra — trước/sau tool-call, khi session bắt đầu/kết thúc, khi model dừng... Dùng hooks để ép luật máy kiểm được (format, chặn `rm -rf`, log) thay vì năn nỉ model bằng lời. Hiểu `/hooks` là hiểu "phản xạ tự động" của Claude Code.

## Khi nào dùng

- Dùng khi có luật máy kiểm được mà bạn muốn bắt buộc: format, chặn `rm -rf`, log, lint trước khi dừng.
- Dùng **trước khi** rule phình to trong CLAUDE.md: rule quan trọng nâng thành hook, chạy ngoài model 0 token.
- Không dùng thay việc hiểu shell — hook chạy code thật trên máy bạn, viết ẩu là mất file.

## Cách gọi

```bash
/hooks    # mở trung tâm quản lý hooks
# Hook định nghĩa trong settings.json (project) hoặc settings.local.json (máy)
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

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

- Hook được đăng ký đúng event + matcher và chạy khi trigger.
- Lint fail ở Stop hook → model bị bắt làm tiếp, tối đa 3 vòng rồi thả.

**Kiểm tra nhanh:** pipe JSON test tay vào script, và `ls -l .claude/hooks/*.sh` phải thấy quyền `+x`.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
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

> Mẹo 1 dòng: _test hook bằng JSON pipe tay trước khi tin — hook sai im lặng còn nguy hơn không có._
