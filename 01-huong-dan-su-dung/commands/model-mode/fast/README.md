# /fast — Chế độ nhanh: trả lời gấp cho việc dễ, không chờ suy luận sâu

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (chỉ giảm độ sâu suy luận / về model nhẹ; không sửa file ngoài ý muốn)

`/fast` là nút "tăng tốc": ép phiên về chế độ nhanh (thường tương đương Sonnet + effort thấp, ít vòng tool-call). Dùng khi cần trả lời ngay — giải thích code, tra cứu, việc vặt — chứ không phải lúc cần suy luận sâu.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/fast` | _(không có)_ | Bật chế độ nhanh cho các turn tiếp theo |
| `/fast <câu hỏi>` | text sau lệnh | Bật fast + hỏi luôn trong 1 bước |
| `/model sonnet` + `/effort low` | _(tương đương thủ công)_ | Combo thủ công khi bản của bạn không có `/fast` |

Ví dụ:

```bash
# Dạng 1: bật fast rồi hỏi dồn
/fast
Giải thích hàm parseToken() trong src/auth/jwt.ts
```

```bash
# Dạng 2: fast + hỏi trong 1 dòng (copy-paste)
/fast Liệt kê tất cả API routes trong src/api/ dưới dạng bảng.
```

```bash
# Dạng 3: dùng fast cho loạt việc vặt
/fast
Rename biến tmp thành cartItems trong src/cart/*.ts, không đổi logic.
```

```bash
# Dạng 4: tắt fast (về bình thường) — tùy bản
/effort medium
# → tương đương tắt fast, về cân bằng
```

```bash
# Dạng 5: khi cần sâu lại → thoát fast bằng high
/effort high
Hãy phân tích race condition trong worker.ts
```

---

## Cách nó hoạt động

### Cơ chế sâu

1. **Fast = preset tốc độ:**
   - Thường map tới `model nhẹ (sonnet/haiku) + effort low + ít vòng tool-call (1–3)`.
   - Model ưu tiên trả lời trực tiếp từ context có sẵn, hạn chế đọc lan man 10 file.
2. **Đánh đổi rõ ràng:**
   - Nhanh (~5–10s) + rẻ, nhưng dễ bỏ sót edge case, không tự phản biện kỹ.
   - Chỉ hợp task có đáp án rõ ràng (giải thích, liệt kê, rename, format).
3. **Hiệu lực session, tắt bằng tay:**
   - Bật `/fast` rồi quên tắt → mọi bài khó sau cũng bị làm ẩu. Nhớ `/effort medium` khi xong.
4. **Cần /extra-usage khi hết quota nhanh:**
   - Fast vẫn tốn quota thường. Nếu fast báo `limit reached`, cần `/extra-usage` mua thêm (xem bài extra-usage).
5. **Sao không pollute workflow sâu?**
   - Fast không đổi mode (plan/bypass giữ nguyên), không xóa context — chỉ đổi tốc độ. Tắt là về bình thường, không di chứng.

### Khác gì với lệnh dễ nhầm?

| Lệnh | Tốc độ | Độ sâu | Dùng khi nào? |
|---|---|---|---|
| `/fast` | Nhanh | Cạn | Việc dễ, cần gấp |
| `/effort low` | Nhanh | Cạn (tương đương) | Muốn chỉnh tay thay vì preset |
| `/effort high` | Chậm | Sâu | Bài khó |
| `/model haiku` | Nhanh | Cạn (model nhỏ) | Việc vặt siêu rẻ |

---

## Ví dụ thực tế

### Kịch bản 1: Họp sắp bắt đầu, cần tóm tắt nhanh

Sếp hỏi "module payments làm gì?" trong 2 phút nữa họp.

```bash
/fast Tóm tắt module src/payments/ trong 5 bullet cho người không code.
```

> Kết quả ~8 giây: đủ đem vào họp. Không cần Opus/effort cao cho việc này.

### Kịch bản 2: Loạt việc vặt cuối ngày

```bash
/fast
1. Format toàn bộ src/utils/*.ts bằng prettier.
2. Thêm dấu chấm cuối mỗi JSDoc.
3. Liệt kê file nào chưa có test.
```

> Kết quả: 3 việc cơ học xong trong 1 phút, tốn vài cent.

### Kịch bản 3: Dùng sai chỗ rồi sửa (bài học)

```bash
# SAI: dùng fast cho bug khó
/fast Fix race condition trong worker.ts
# → model đoán ẩu, sai

# SỬA: thoát fast, nghĩ kỹ
/effort high
Hãy reproduce race condition bằng script trước khi fix.
```

---

## Rủi ro & lưu ý

### Tốn token?

- Fast rẻ nhất trong các mode (~1x). Nhưng lạm dụng fast cho bài khó → làm sai → phải làm lại 3 lần = đắt hơn 1 lần high.
- Quy tắc: việc < 2 phút suy nghĩ của người → fast. Còn lại → medium+.

### Version / provider

- Không phải bản nào cũng có `/fast` riêng; bản thiếu thì dùng `/effort low` + `/model sonnet` cho cùng hiệu quả.
- `/fast` cần quota thường; hết quota nhanh → xem `/extra-usage` để mua thêm, không có đường tắt miễn phí.

### Destructive?

- Không. Nhưng fast + `bypassPermissions` vẫn nguy hiểm: model làm ẩu + tự ghi file không hỏi. Giữ `acceptEdits` khi fast.

---

## Kết hợp trong workflow

| Combo | Khi nào | Mẫu |
|---|---|---|
| `/fast` → `/effort high` | Khởi động nhanh, đào sâu khi cần | Fast tóm tắt → high phân tích |
| `/fast` + `/diff` | Làm vặt nhanh rồi review | Fast rename → `/diff` kiểm tra |
| `/fast` + `/btw` | Hỏi nhanh không cần tools | Tương tự, nhưng `/btw` còn không chạm history |

```bash
# Workflow "sáng thứ Hai": fast quét, high làm
/fast
Liệt kê 10 TODO trong codebase, xếp theo độ ưu tiên.
/effort high
Làm TODO số 1 với đầy đủ test.
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/fast` báo `unknown command` | Bản không có lệnh riêng | Dùng `/effort low` thay thế |
| Fast trả lời ẩu, sai | Dùng fast cho bài khó | Lên `/effort medium`/`high` |
| Bật fast rồi quên, bài khó sau cũng ẩu | Fast còn hiệu lực session | `/effort medium` để về bình thường |
| Fast vẫn chậm | Context đầy 70%+ | `/compact` trước rồi fast |
| Fast báo limit/quota | Hết quota gói | Xem [../extra-usage/README.md](../../model-mode/extra-usage/README.md) |

---

## Tham khảo

- Lệnh liên quan:
  - [../effort/README.md](../../model-mode/effort/README.md) — chỉnh tay low/high thay vì preset
  - [../model/README.md](../../model-mode/model/README.md) — đổi model khi cần
  - [../extra-usage/README.md](../../model-mode/extra-usage/README.md) — hết quota khi fast nhiều
  - [../btw/README.md](../../code-repo/btw/README.md) — hỏi nhanh không tools, không history
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _việc 1 phút thì `/fast`, việc 1 giờ thì đừng fast._
