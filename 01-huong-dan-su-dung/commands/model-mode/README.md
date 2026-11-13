# /model-mode — nhóm 7 lệnh đổi cách model suy nghĩ và chạy

> **Loại:** index nhóm lệnh · **Nhóm:** Model & Permission Modes · **Mức rủi ro:** thấp (đụng mode/quota, /permissions cấu hình ẩu là rủi ro)
> **Nói nôm na:** nhóm này là nơi bạn "vặn não và dựng phanh" cho model — đổi model, độ sâu suy luận, chế độ nhanh, đặt mục tiêu, khóa quyền. Mặc định tài khoản là Opus 5.5 (≥2.1.280); Fable 5.1 mạnh nhất nhưng không bao giờ là default. /usage-credits tốn tiền thật, nên coi quota là thật.

## Khi nào dùng

- Bạn muốn đổi "não" model giữa phiên: /model (Haiku 5.5/Sonnet/Opus 5.5, thêm alias `best`), /effort (độ sâu suy luận), /fast (việc dễ).
- Bạn cần khóa "chỉ đọc + viết plan" trước task lớn bằng /plan, và dựng phanh allow/ask/deny bằng /permissions.
- Bạn muốn đặt tiêu chí "xong là gì" để agent tự chạy tiếp bằng /goal (cần ≥2.1.139), hoặc mua thêm quota bằng /usage-credits (trước đây tên /extra-usage) khi trần hạn mức.

> **Tóm gọn 1 câu:** Nhóm này là "vô lăng của Claude Code": /model đổi não, /effort và /fast vặn tốc độ suy nghĩ, /plan và /permissions là hệ thống phanh, /goal là hành trình tự lái tới đích, /usage-credits là đổ thêm xăng.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

Kiểm tra lệnh có ở máy bạn không: mở session, gõ `/` rồi gõ tiếp chữ đầu lệnh — version/provider khác nhau hiện lệnh khác nhau.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Bạn muốn đổi sang model mạnh hơn giữa phiên:

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

- Mong đợi: picker hiện danh sách model (Haiku 5.5/Sonnet/Opus 5.5, fable), bạn chọn model mới, phiên chuyển sang model đó.
- Kiểm tra (≤30 giây): /status xem "Model" đã đổi chưa; model không hiện thì `claude --version` kiểm tra version floor.

> **Tóm gọn 1 câu:** Đổi model giữa phiên như thay pin đang chạy: câu chuyện và file đã đọc giữ nguyên, chỉ "nguồn suy nghĩ" từ lượt sau là khác — xong thì /status kiểm tra là biết.

## Lỗi thường gặp

Mục này gom ba trục trặc hay gặp nhất khi "vặn vô lăng": model thiếu trong picker, quota chạm trần, goal chạy mãi không dừng — đối chiếu triệu chứng của bạn với cột đầu, rồi làm theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| /model hiện trong picker nhưng thiếu model bạn muốn (vd fable, Opus 5.5) | Version Claude Code máy bạn thấp hơn version tối thiểu (fable cần ≥2.1.257, Opus 5.5 cần ≥2.1.280) | Chạy `claude --version`, update bằng `claude update`, rồi thử lại |
| Lệnh bị chặn giữa chừng, quota về 0, /usage-credits không dùng được | Hết hạn mức gói trong phiên 5 giờ (rate limit) | Chờ reset, nâng gói (Max 5x/20x), hoặc bật usage credits trả theo giá API |
| /goal "chạy không dừng" — agent không nhận đã đạt điều kiện, chạy tiếp ngốn quota | Tiêu chí "xong là gì" viết mơ hồ, evaluator không check được | Viết /goal với điều kiện đo được (vd "tất cả test xanh"), không để mơ hồ |

> **Cách đọc bảng này:** mỗi dòng là một "sự cố lái xe"; cột "Vì sao" cho biết gốc rễ nằm ở bản CLI, ở hạn mức hay ở cách cấu hình, cột "Cách sửa" là lệnh/bước xử lý cụ thể.

## Bộ 3 phải nhớ

> /plan khóa ghi trước task lớn | /model đổi não (Opus 5.5/Sonnet/Haiku 5.5) | /permissions dựng phanh allow/ask/deny

## Các lệnh (7)

Bảng dưới là toàn bộ 7 lệnh của nhóm, xếp theo tên A→Z — mỗi dòng một "núm vặn" trên vô lăng.

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/effort](./effort/README.md) | Không | Vặn độ sâu suy luận, không cần đổi model |
| [/usage-credits](./usage-credits/README.md) | Không (tốn tiền thật) | Mua thêm quota khi hết hạn mức gói |
| [/fast](./fast/README.md) | Không | Chế độ nhanh cho việc dễ, không chờ suy luận sâu |
| [/goal](./goal/README.md) | Không (cần ≥2.1.139) | Đặt điều kiện hoàn thành, evaluator check mỗi turn |
| [/model](./model/README.md) | Không | Đổi model giữa phiên (Haiku 5.5/Sonnet/Opus 5.5) |
| [/permissions](./permissions/README.md) | Có nếu cấu hình ẩu | Dựng phanh allow/ask/deny cho tool |
| [/plan](./plan/README.md) | Không | Chỉ đọc + viết plan, cấm sửa code tới khi duyệt |

> **Cách đọc bảng này:** cột "Mức rủi ro" là đèn giao thông (Không = gõ được ngay, "Có" = dừng đọc cấu hình trước), cột "Một dòng" đủ để quyết định có cần mở trang chi tiết hay không — cần chi tiết mới bấm vào tên lệnh.

## Sơ đồ quyết định (30 giây)

```text
Cần gì? -> Nhóm này cho gì? -> Lệnh nào?
Đọc 3 lệnh trong "Bộ 3" trước, còn lại tra khi cần.
Gõ / trong session để xem lệnh nào hiện ở máy bạn.
```

## Cách dùng nhóm này cho đúng

> 📄 **Code ví dụ:** [`examples/03-cach-dung-nhom-nay-cho-ung.sh`](examples/03-cach-dung-nhom-nay-cho-ung.sh)

## Tham khảo

- [← Về index tất cả lệnh](../README.md)
- [04 — slash commands toàn tập](../../04-slash-commands-toan-tap.md)
- [Nhóm session-context](../session-context/README.md) · [Nhóm code-repo](../code-repo/README.md)

> Mẹo 1 dòng: _trần quota thì /status xem trước, nâng gói hay bật usage credits — đừng để lệnh bị chặn giữa task._
