# /permissions — Quản lý quyền tools: ai được đọc/ghi/chạy gì, hỏi khi nào

> Loại Built-in (alias /allowed-tools) · Nhóm Model & Mode · Mức rủi ro Có nếu cấu hình ẩu (allow-all / bypass trên máy thật = mất phanh; deny sai = kẹt việc)
>
> **Nói nôm na:** `/permissions` (alias `/allowed-tools`) là trung tâm phân quyền: quy định tool nào được chạy thẳng (allow), tool nào phải hỏi (ask), tool nào cấm hẳn (deny). Mọi mode Shift+Tab (default/acceptEdits/plan/auto/bypass) thực chất chỉ là preset đè lên bảng này. Hiểu bảng này là hiểu phanh của Claude Code.

## Khi nào dùng

- Dùng /permissions khi cần định hình allow/ask/deny — tool nào chạy thẳng, tool nào phải hỏi, tool nào cấm hẳn.
- Dùng /permissions **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /permissions thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/permissions`
`/allowed-tools`
`Shift+Tab`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: mở UI phân quyền
/permissions

# Bước 2 (không dùng UI): sửa .claude/settings.local.json
```

```json
{"permissions": {"allow": ["Bash(python:*)", "Bash(pytest:*)"]}}
```

Kết quả mong đợi:

- Claude trả đúng việc của /permissions (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Model báo `permission denied` khi chạy test | Thiếu allow `Bash(pytest/npm test:*)` | Thêm vào `settings.local.json` allow |
| Thêm allow ở local mà vẫn bị chặn | Managed policy deny ở trên (ổ khóa 🔒) | Không vượt được — ticket IT hoặc đi đường vòng an toàn |
| Bị hỏi Yes/No liên tục, mỏi tay | Bảng ask quá rộng / đang ở default với task lặp | Shift+Tab sang `acceptEdits`, hoặc allow các lệnh lặp |

## Tham khảo

- [../plan/README.md](../../model-mode/plan/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../effort/README.md](../../model-mode/effort/README.md)
- [../init/README.md](../../code-repo/init/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /permissions sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
