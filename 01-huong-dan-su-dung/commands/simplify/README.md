# /simplify — Làm code đơn giản lại: bớt phức tạp, giữ nguyên tính năng

> Loại Skill (refactor) · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ refactor; nhưng Có nhẹ nếu simplify đụng logic tinh vi — luôn chạy test sau)

`/simplify`要求 model đọc 1 hàm/file bạn chỉ định, đo độ phức tạp (lồng nhau, nhánh, dài), rồi đề xuất bản gọn hơn mà test vẫn xanh: tách hàm, gộp nhánh, bỏ code chết, đặt tên rõ. Khác `/review` (tìm lỗi) và `/refactor` chung chung (đổi cấu trúc) — simplify chỉ theo 1 hướng: đơn giản hơn.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/simplify <file>` | đường dẫn | Đơn giản hoá 1 file |
| `/simplify <file>:<hàm>` | file + tên hàm | Chỉ xử lý 1 hàm (khuyên dùng) |
| `/simplify --aggressive` | flag | Gộp/tách mạnh tay (review kỹ hơn) |

```bash
# Dạng 1: gọn 1 hàm cụ thể (khuyên dùng, ít rủi ro)
/simplify api/auth.py:login

# Dạng 2: gọn cả file
/simplify api/auth.py

# Dạng 3: mạnh tay (hàm 200 dòng muốn còn 60)
/simplify legacy/parser.py --aggressive
```

---

## Cách nó hoạt động

1. **Đo trước:** đếm độ sâu lồng (`if` trong `for` trong `try`...), số nhánh, số dòng/hàm. Báo con số (VD "độ sâu 5, 12 nhánh") để bạn thấy đáng simplify không.
2. **4 chiêu chuẩn:** tách hàm (1 hàm >30 dòng → 3 hàm nhỏ), gộp nhánh (early-return thay lồng `if`), bỏ code chết (flag không ai bật, `except: pass`), đặt tên rõ (`x2` → `retry_count`).
3. **Giữ hành vi:** sau mỗi bản gọn, chạy test file đó (hoặc so output trước/sau nếu chưa có test). Test đỏ → hoàn tác chiêu vừa làm, không cố.
4. **Không làm gì?** Không đổi API public, không đổi framework, không "tối ưu performance" (gọn ≠ nhanh). Muốn nhanh thì nói rõ riêng.
   Từ v2.1.154: `/simplify` **chỉ fix over-engineering** (phức tạp thừa) — **không tìm bugs**.
   Muốn tìm bugs → `/review` hoặc `/code-review`.

---

## Ví dụ thực tế

### Kịch bản 1: Hàm login lồng 5 tầng → early-return

```bash
/simplify api/auth.py:login
# Trước: if user: → if pw: → if not locked: → try: ... (sâu 5)
# Sau: 4 early-return (không user → raise; sai pw → raise...) + thân chính 10 dòng phẳng
# → test auth xanh → commit
```

```python
# Mẫu early-return sau simplify (copy-paste ý tưởng):
def login(user, pw):
    if not user: raise AuthError("thiếu user")
    if not check_pw(user, pw): raise AuthError("sai pass")
    if user.locked: raise AuthError("đang khóa")
    return make_token(user)  # thân chính phẳng, 1 đường
```

### Kịch bản 2: File 400 dòng có 100 dòng chết

```bash
/simplify legacy/parser.py
# → phát hiện: hàm parse_v1 không ai gọi (grep 0 kết quả), flag --old-bỏ từ 2024
# → xoá 100 dòng + test còn lại xanh → file còn 300 dòng sống
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Gọn nhầm logic tinh vi (retry/backoff) | Bỏ nhánh "hiếm" mà thật ra cứu production | Hàm có `retry/lock/timeout` thì review dòng-dòng, chạy test tải trước khi nhận |
| `--aggressive` đổi API public | Caller khác vỡ | Cấm đổi signature public; chỉ gọn thân hàm |
| Không có test mà simplify | Không lưới an toàn | Viết 3-5 testйл trước (input/output chính), rồi mới simplify |

- **Tốn token?** 1 hàm ≈ 2-4k. Rẻ. `--aggressive` cả file lớn ≈ 8-15k — vẫn rẻ hơn debug bug do code rối.
- **Version:** skill `simplify` v2.x.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/simplify` + `/verify` | Gọn xong test ngay | Simplify → verify file đó |
| `/simplify` + `/review` | Review phát hiện rối → simplify | Review báo "hàm này phức tạp" → simplify |
| `/simplify` + `/pr-comments` | Reviewer chê rối | Comment "khó đọc" → simplify rồi reply |

```bash
# Workflow: /review (phát hiện rối) → /simplify api/auth.py:login → /verify → commit
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Simplify xong test đỏ | Đổi hành vi (bỏ nhánh cần thiết) | Hoàn tác, simplify từng chiêu nhỏ thay vì 1 lần lớn |
| Model chỉ format, không gọn | Hàm đã gọn hoặc prompt chung quá | Chỉ hàm cụ thể + `--aggressive`; đo số trước (độ sâu/nhánh) |
| Gọn xong khó đọc hơn (golf-code) | Model lạm dụng one-liner | Quy tắc: tên rõ > ngắn; từ chối bản lạm dụng comprehension 3 tầng |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../verify/README.md](../verify/README.md) — test sau simplify
  - [../review/README.md](../review/README.md) — phát hiện chỗ rối (nếu có)
  - [../diff/README.md](../diff/README.md) — soi diff gọn có đổi hành vi không
  - [../compact/README.md](../compact/README.md) — gọn code vs gọn context (khác nhau)
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../03-claude-md-memory-rules.md)
  - [../../05-skills-custom-commands.md](../../05-skills-custom-commands.md)
  - [../../06-subagents-agent-teams-parallel.md](../../06-subagents-agent-teams-parallel.md)
  - [../../07-hooks-tu-dong-hoa.md](../../07-hooks-tu-dong-hoa.md)
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../08-mcp-ket-noi-cong-cu-ngoai.md)
  - [../../09-plugins-marketplaces.md](../../09-plugins-marketplaces.md)

> Mẹo 1 dòng: _1 hàm 1 lần, test xanh mới nhận, tên rõ hơn code ngắn._
