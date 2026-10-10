# /model-mode — nhóm 7 lệnh đổi cách model suy nghĩ và chạy

> **Loại:** index nhóm lệnh · **Nhóm:** Model & Permission Modes · **Mức rủi ro:** thấp (đụng mode/quota, /permissions cấu hình ẩu là rủi ro)
> **Nói nôm na:** nhóm này là nơi bạn "vặn não và dựng phanh" cho model — đổi model, độ sâu suy luận, chế độ nhanh, đặt mục tiêu, khóa quyền. /extra-usage tốn tiền thật, nên coi quota là thật.

## Khi nào dùng

- Bạn muốn đổi "não" model giữa phiên: /model (Haiku/Sonnet/Opus 5.5), /effort (độ sâu suy luận), /fast (việc dễ).
- Bạn cần khóa "chỉ đọc + viết plan" trước task lớn bằng /plan, và dựng phanh allow/ask/deny bằng /permissions.
- Bạn muốn đặt tiêu chí "xong là gì" để agent tự chạy tiếp bằng /goal (cần ≥2.1.139), hoặc mua thêm quota bằng /extra-usage khi trần hạn mức.

## Cách gọi

```bash
# go / trong session, go chu dau lenh de loc
/model
/plan
/permissions
```

Kiểm tra lệnh có ở máy bạn không: mở session, gõ `/` rồi gõ tiếp chữ đầu lệnh — version/provider khác nhau hiện lệnh khác nhau.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Bạn muốn đổi sang model mạnh hơn giữa phiên:

```bash
/model
# chon "Opus 5.5" (can >=2.1.280) hoac "fable" (can >=2.1.257)
```

- Mong đợi: picker hiện danh sách model (Haiku/Sonnet/Opus 5.5, fable), bạn chọn model mới, phiên chuyển sang model đó.
- Kiểm tra (≤30 giây): /status xem "Model" đã đổi chưa; model không hiện thì `claude --version` kiểm tra version floor.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| /model hiện trong picker nhưng thiếu model bạn muốn (vd fable, Opus 5.5) | Version Claude Code máy bạn thấp hơn version tối thiểu (fable cần ≥2.1.257, Opus 5.5 cần ≥2.1.280) | Chạy `claude --version`, update bằng `claude update`, rồi thử lại |
| Lệnh bị chặn giữa chừng, quota về 0, /extra-usage không dùng được | Hết hạn mức gói trong phiên 5 giờ (rate limit) | Chờ reset, nâng gói (Max 5x/20x), hoặc bật usage credits trả theo giá API |
| /goal "chạy không dừng" — agent không nhận đã đạt điều kiện, chạy tiếp ngốn quota | Tiêu chí "xong là gì" viết mơ hồ, evaluator không check được | Viết /goal với điều kiện đo được (vd "tất cả test xanh"), không để mơ hồ |

## Bộ 3 phải nhớ

> /plan khóa ghi trước task lớn | /model đổi não (Opus 5.5/Sonnet/Haiku) | /permissions dựng phanh allow/ask/deny

## Các lệnh (7)

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/effort](./effort/README.md) | Không | Vặn độ sâu suy luận, không cần đổi model |
| [/extra-usage](./extra-usage/README.md) | Không (tốn tiền thật) | Mua thêm quota khi hết hạn mức gói |
| [/fast](./fast/README.md) | Không | Chế độ nhanh cho việc dễ, không chờ suy luận sâu |
| [/goal](./goal/README.md) | Không (cần ≥2.1.139) | Đặt điều kiện hoàn thành, evaluator check mỗi turn |
| [/model](./model/README.md) | Không | Đổi model giữa phiên (Haiku/Sonnet/Opus 5.5) |
| [/permissions](./permissions/README.md) | Có nếu cấu hình ẩu | Dựng phanh allow/ask/deny cho tool |
| [/plan](./plan/README.md) | Không | Chỉ đọc + viết plan, cấm sửa code tới khi duyệt |

## Sơ đồ quyết định (30 giây)

```text
Cần gì? -> Nhóm này cho gì? -> Lệnh nào?
Đọc 3 lệnh trong "Bộ 3" trước, còn lại tra khi cần.
Gõ / trong session để xem lệnh nào hiện ở máy bạn.
```

## Cách dùng nhóm này cho đúng

```bash
# 1. Hoc 3 lenh tru truoc (xem "Bo 3 phai nho" o tren)
# 2. Con lai tra khi gap viec that, dung hoc het 1 luc
# 3. Loi la trong nhom nay -> /status -> /doctor -> doc lenh tuong ung
```

## Tham khảo

- [← Về index tất cả lệnh](../README.md)
- [04 — slash commands toàn tập](../../04-slash-commands-toan-tap.md)
- [Nhóm session-context](../session-context/README.md) · [Nhóm code-repo](../code-repo/README.md)

> Mẹo 1 dòng: _trần quota thì /status xem trước, nâng gói hay bật usage credits — đừng để lệnh bị chặn giữa task._
