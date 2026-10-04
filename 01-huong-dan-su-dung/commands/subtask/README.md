# /subtask — Giao việc phụ cho subagent tách nhánh, báo về ngay đây

> Loại Built-in (v2.1.212+) · Nhóm Song song & Ủy thác · Nguy hiểm Thấp (chạy trong session, quyền kế thừa; nhưng Có nếu việc phụ có ghi/xoá mà bạn không dặn giới hạn)

`/subtask` (từ bản v2.1.212+) fork một subagent làm side task NHỎ rồi báo kết quả về NGAY TRONG session này: tra 1 hàm, đọc 3 file, thử 1 hướng... Bạn không phải rời terminal, không detach như `/background`. Hiểu `/subtask` là hiểu "nhờ đứa bên cạnh tra hộ 1 cái, 2 phút sau nó đưa giấy lại".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/subtask <việc>` | mô tả việc phụ 1-2 câu | Fork subagent làm rồi báo về đây |
| `/subtask <việc> --readonly` | flag | Subagent chỉ đọc, cấm ghi file (an toàn nhất) |
| `/subtask <việc> --model <tên>` | `haiku`, `sonnet`... | Chọn model cho việc phụ (việc dễ → haiku cho rẻ) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: tra cứu nhỏ trong lúc đang code (khuyên dùng readonly)
/subtask tìm hàm verifyJWT nằm ở file nào, signature ra sao --readonly
# → (1-2 phút) "nằm ở src/auth/jwt.ts:12, verifyJWT(token: string): Payload"
```

```bash
# Dạng 2: đọc hộ 3 file rồi tóm tắt
/subtask đọc 3 file src/payments/*.ts, tóm tắt flow refund 5 dòng --readonly
```

```bash
# Dạng 3: việc dễ → model rẻ
/subtask đếm có bao nhiêu chỗ gọi fetch( trong src/ --model haiku --readonly
```

```bash
# Dạng 4: thử 1 hướng nhỏ (cho ghi giới hạn)
/subtask thử viết regex parse log date, báo 3 mẫu test pass/fail
```

---

## Cách nó hoạt động

### Cơ chế sâu: fork nhỏ khác gì background?

1. **Fork trong session:** subagent con sống DƯỚI session hiện tại, xong báo về luồng chat này — bạn không detach, không cần `/resume`.
2. **Phạm vi nhỏ:** thiết kế cho việc 2-5 phút (tra, đọc, đếm, thử). Việc >15 phút → dùng `/background` thay vì subtask.
3. **Quyền kế thừa + giới hạn thêm:**
   - Mặc định kế thừa permissions session. `--readonly` khóa ghi hẳn — tra cứu thì luôn readonly.
   - Việc cho ghi: dặn rõ file nào được đụng ("chỉ sửa `scratch/regex-test.ts`"), cấm lan ra ngoài.
4. **Model riêng cho việc phụ:** việc đếm/tra → `haiku` (rẻ, nhanh); việc cần suy luận → để mặc định. Đừng lấy opus tra chính tả.

```text
đang code (không rời terminal)
  │  /subtask tra X --readonly
  ▼
subagent con chạy (1-2 phút, bạn code tiếp được)
  ▼
báo về ngay đây: "X ở file Y:12, signature Z" → bạn dùng luôn
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Quy mô | Báo về đâu? | Dùng khi nào? |
|---|---|---|---|
| `/subtask` (v2.1.212+) | NHỎ 2-5 phút | NGAY ĐÂY | Tra/đọc/đếm/thử 1 hướng |
| `/background` | LỚN 15+ phút | Phải `/resume` lấy | Research dài, test full |
| `/fork` | Hướng thử nghiệm | Nhánh mới foreground | Thử hướng B so với A |
| `/agents` | Quản lý agent team | — | Xem/điều phối nhiều agent |

> Quy tắc ngón tay cái:
>
> - **2 phút tra hộ → `/subtask --readonly`. 20 phút research → `/background`. Thử hướng khác → `/fork`.**

---

## Ví dụ thực tế

### Kịch bản 1: Đang code quên signature — nhờ tra hộ, tay không dừng (2 phút)

```bash
# Đang viết middleware, quên verifyJWT trả về gì:
# (không mở file khác, nhờ subagent tra)
/subtask tìm hàm verifyJWT trong src/, cho signature + file:dòng --readonly --model haiku
# → 1 phút sau: "src/auth/jwt.ts:12 — verifyJWT(token: string): JWTPayload { sub, exp }"
# → bạn viết tiếp luôn, không mất mạch
```

> Kết quả: không context-switch. Tự mở file tra cũng được nhưng mất mạch suy nghĩ — subtask giữ mạch cho bạn.

### Kịch bản 2: Review PR — nhờ đếm/đọc hộ pattern nghi ngờ (5 phút)

```bash
# PR 400 dòng, nghi nhiều chỗ fetch không try-catch:
/subtask đếm mọi chỗ gọi fetch( trong PR này thiếu try-catch, liệt kê file:dòng --readonly
# → "4 chỗ: api/orders.ts:31, api/refund.ts:58, ..."
# → bạn vào đúng 4 chỗ comment, khỏi đọc 400 dòng
```

### Kịch bản 3: Thử nhanh 1 hướng trước khi commit làm thật

```bash
# Phân vân regex nào parse được cả 2 format log:
/subtask thử 2 regex ứng viên trên 10 dòng log mẫu trong docs/sample.log, báo cái nào pass hết
# → "regex B pass 10/10, regex A fail 3 dòng format cũ. Dùng B."
# → bạn áp dụng B vào code chính, có bằng chứng
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (subtask ghi lan)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Subtask không readonly mà dặn mơ hồ | HAY GẶP: "thử" thành sửa luôn file chính | Tra/đọc luôn `--readonly`; cho ghi thì chỉ rõ file scratch |
| Giao việc to đội lốt subtask | "Research cả auth" 30 phút kẹt luồng chat | >15 phút → `/background`; subtask chỉ việc nhỏ |
| 3-4 subtask song song | Loạn kết quả báo về, tốn token | Tối đa 1-2 subtask cùng lúc; xong cái này mới giao cái khác |
| Tin kết quả mù (sai file:dòng) | Subagent đọc nhầm bản cũ/cache | Kết quả quan trọng tự mở file verify 10 giây trước khi dùng |

### Tốn token?

- 1 subtask nhỏ (haiku + readonly) ≈ 1-3k token. Rẻ — nhưng 10 subtask/ngày cũng thành 30k. Gộp việc tra cứu 1 lần thay vì 5 subtask lắt nhắt.

### Version / provider

- `/subtask`: bản **v2.1.212+**. Cũ hơn chưa có — dùng `/background` hoặc tra tay.
- `--readonly` / `--model`: cùng bản. Bản cũ không có flag thì dặn bằng lời ("chỉ đọc, không sửa").
- Bedrock/Vertex: dùng được (subagent cùng provider).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/subtask` + `/background` | Nhỏ ở đây, lớn đẩy nền | Subtask tra nhanh, background research sâu |
| `/subtask` + `/review` | Nhờ đọc hộ pattern rồi review | Subtask đếm lỗi → review đúng chỗ |
| `/subtask` + `/verify` | Thử hướng nhỏ trước khi verify lớn | Subtask thử regex → verify cả app |
| `/subtask` + `/goal` | Việc phụ phục vụ mục tiêu chính | Goal rõ → subtask không lạc đề |

Workflow chuẩn "đang code cần tra (không mất mạch)":

```bash
# 1. Giao tra cứu (tay vẫn gõ tiếp)
/subtask <câu hỏi cụ thể> --readonly --model haiku
# 2. Nhận kết quả, verify 10 giây nếu quan trọng
# 3. Dùng luôn vào code chính
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/subtask` báo unknown command | CLI <2.1.212 | Update CLI mới nhất (`/restart` offer); tạm dùng `/background` hoặc tra tay |
| Subtask sửa luôn file chính | Quên `--readonly`, dặn "thử" mơ hồ | Rollback (`git checkout <file>`); lần sau readonly + file scratch rõ ràng |
| Kết quả về chậm (10 phút việc 2 phút) | Giao việc quá rộng ("tóm tắt cả module") | Chia nhỏ ("chỉ 3 file X, 5 dòng"); rộng → background |
| Kết quả sai (file:dòng không tồn tại) | Subagent đọc bản cũ trước khi bạn save | Save file trước khi giao; verify lại 10 giây |
| Quên mình đã giao subtask gì | 3 subtask chồng nhau, kết quả lẫn | 1 subtask 1 lúc; đặt tên việc rõ ("tra JWT", "đếm fetch") |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../background/README.md](../background/README.md) — việc lớn đẩy nền (khác subtask nhỏ ở đây)
  - [../fork/README.md](../fork/README.md) — rẽ nhánh thử hướng khác
  - [../agents/README.md](../agents/README.md) — xem/quản lý agents đang chạy
  - [../tasks/README.md](../tasks/README.md) — theo dõi việc đã giao
  - [../goal/README.md](../goal/README.md) — giữ subtask không lạc mục tiêu
- Bài tổng quan:
  - [../../06-subagents-agent-teams-parallel.md](../../06-subagents-agent-teams-parallel.md) — subagent/agent-team nâng cao

> Mẹo 1 dòng: _nhỏ + readonly + haiku ở đây, lớn + lâu thì đẩy nền._
