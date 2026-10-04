# Tips 03 — Plan-First: Explore → Plan → Implement (Không Code Ngay)

## 1. Vì sao plan-first thắng

Nguyên nhân #1 của output sprawling/sai: **nhảy thẳng vào implement ở task phức tạp**.
Plan mode rẻ (chỉ tokens suy nghĩ), code sai đắt (sửa + test + rewind).

## 2. Vào plan mode (3 cách)

1. `Shift+Tab` đến khi thấy `plan` (xoay: default → acceptEdits → plan → auto → bypass).
2. Gõ `/plan` trong session.
3. Dặn bằng lời: *"Trước khi làm gì, trình plan chi tiết và chờ duyệt."*

Trong plan mode Claude **read-only**: đọc, outline thay đổi, không sửa.

## 3. Plan tốt gồm gì

- Files sẽ đọc/sửa (đường dẫn cụ thể) + thứ tự steps.
- Dependencies, risks/edge cases, cái gì **không** đụng.
- Cách verify từng phase (lệnh test/lint/log nào).
- Cửa chia phase + gate (“xong phase 1 + test xanh mới sang phase 2”).

Mẫu:

```text
Tôi muốn <mục tiêu>. Trước khi code, trình plan gồm:
- Code nào sẽ đọc, files nào sẽ sửa
- Steps + risks
- Output format + cách verify chính xác
Chờ tôi duyệt mới implement.
```

## 4. Plan-then-execute 2 sessions (task lớn)

```
Session A (plan): plan mode → refine plan cùng Claude → save plan.md (commit hoặc clipboard)
Session B (fresh): paste plan.md + "thực hiện step-by-step, verify từng phase, dừng khi phase đỏ"
```

→ Tránh context degradation: session implement sạch, không mang rác research.

## 5. Phase-gate (chống drift)

Đừng duyệt 1 plan khổng lồ. Chia phases, mỗi phase có test/verify gate.
Claude xong + verify phase N mới được đụng phase N+1 → bắt drift sớm, rewind rẻ.

## 6. Khi nào KHÔNG cần plan

Task 1 file, 1 bước, rõ ràng (đổi text, thêm log...) → làm trực tiếp nhanh hơn.
Quy tắc ngón tay: **>1 file hoặc >2 steps → plan mode reflex.**
