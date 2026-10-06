# /agents — Quản lý subagent: đội quân AI chạy song song việc nặng

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Có nếu batch ẩu (30 subagent cùng ghi 1 file = xung đột; subagent kế thừa permissions nên bypass ở mẹ là bypass cả đàn)

> Nói nôm na: `/agents` mở trung tâm quản lý subagent: xem danh sách đang chạy (Running), thư viện có sẵn (Library), tạo/sửa agent custom. Subagent là 1 phiên Claude độc lập với context riêng, nhận việc từ agent mẹ, làm xong trả kết quả về — mẹ không bị ngập context. Hiểu `/agents` là hiểu cách "thuê đệ" đúng cách.

## Khi nào dùng

- Dùng /agents khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /agents **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /agents thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/agents`
Task tool
`.claude/agents/*.md`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Gõ 1 câu, model tự fan-out 3 đứa:
# "Song song tìm hiểu repo này: đứa 1 đọc api/ (stack + entry point),
#  đứa 2 đọc web/ (framework + state), đứa 3 đọc migrations/ + README (schema + cách chạy).
#  Mỗi đứa trả về ≤15 dòng."
```

Kết quả mong đợi:

- Claude trả đúng việc của /agents (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Con trả về chung chung, không dùng được | Prompt mơ hồ, không format output | Ghi rõ: "trả về danh sách file:dòng, ≤15 dòng, dạng bảng" |
| Con chạy 15 phút không xong | Ôm việc quá to (đọc cả repo) | Kill trong Running, chia nhỏ prompt (1 thư mục/con) |
| Hai con ghi đè nhau | Cùng ghi 1 file | Đổi sang mỗi con 1 file, mẹ gộp; hoặc chạy tuần tự |

## Tham khảo

- [../batch/README.md](../../code-repo/batch/README.md)
- [../loop/README.md](../../code-repo/loop/README.md)
- [../tasks/README.md](../../session-context/tasks/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /agents sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
