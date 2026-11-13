# /agents — Quản lý subagent: đội quân AI chạy song song việc nặng

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Có nếu batch ẩu (30 subagent cùng ghi 1 file = xung đột; subagent kế thừa permissions nên bypass ở mẹ là bypass cả đàn)
> **Nói nôm na:** `/agents` mở trung tâm quản lý subagent: xem danh sách đang chạy (Running), thư viện có sẵn (Library), tạo/sửa agent custom. Subagent là 1 phiên Claude độc lập với context riêng, nhận việc từ agent mẹ, làm xong trả kết quả về — mẹ không bị ngập context. Hiểu `/agents` là hiểu cách "thuê đệ" đúng cách.

## Khi nào dùng

- Dùng khi có nhiều việc đọc/tìm hiểu **độc lập** cần chạy song song mà không muốn nhồi hết vào 1 context.
- Dùng **trước khi** context phình to: fan-out cho subagent đọc repo thay vì bạn tự Read từng file.
- Không dùng thay đọc/review tay phần kết luận — bạn vẫn phải kiểm chứng output và tự chịu trách nhiệm cuối.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```text
# Gõ 1 câu, model tự fan-out 3 đứa:
# "Song song tìm hiểu repo này: đứa 1 đọc api/ (stack + entry point),
#  đứa 2 đọc web/ (framework + state), đứa 3 đọc migrations/ + README (schema + cách chạy).
#  Mỗi đứa trả về ≤15 dòng."
```

Kết quả mong đợi:

- Running hiện 3 subagent; mỗi đứa trả báo cáo ≤15 dòng đúng thư mục được giao.
- Agent mẹ gộp kết quả, context chính không phình vì thân file chỉ nằm ở context của đứa con.

**Kiểm tra nhanh:** `/agents` xem cột Running rồi sang Library; `/status` hoặc `/context` xác nhận mode/context mẹ còn sạch.

## Lỗi thường gặp

Mục này là "sổ bệnh án" của `/agents`: khi đội quân chạy song song gặp trục trặc, tra đây trước.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Con trả về chung chung, không dùng được | Prompt mơ hồ, không format output | Ghi rõ: "trả về danh sách file:dòng, ≤15 dòng, dạng bảng" |
| Con chạy 15 phút không xong | Ôm việc quá to (đọc cả repo) | Kill trong Running, chia nhỏ prompt (1 thư mục/con) |
| Hai con ghi đè nhau | Cùng ghi 1 file | Đổi sang mỗi con 1 file, mẹ gộp; hoặc chạy tuần tự |

> **Cách đọc bảng này:** mỗi dòng một bệnh hay gặp của subagent; "Triệu chứng" nhận diện, "Vì sao" thường là prompt hoặc scope, "Cách sửa" áp dụng cho lần spawn sau.

> **Tóm gọn 1 câu:** `/agents` là thuê đệ đông mà không nhàu nát chính mình — mỗi đứa một việc nhỏ rõ đầu ra, agent mẹ chỉ gộp và kiểm tra.

## Tham khảo

- [../batch/README.md](../../code-repo/batch/README.md)
- [../loop/README.md](../../code-repo/loop/README.md)
- [../tasks/README.md](../../session-context/tasks/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _trước khi mở 30 đứa, thử 2–3 đứa trước; thấy ổn hãy tăng đội._
