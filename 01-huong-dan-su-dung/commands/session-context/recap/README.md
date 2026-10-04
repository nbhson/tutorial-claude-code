# /recap — Tóm tắt context khi quay lại session sau break

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ đọc + tóm tắt, không sửa gì)

`/recap` sinh context summary khi bạn quay lại session sau giờ nghỉ/ngắt quãng: đang làm gì, tới đâu, quyết định gì đã chốt, việc dở nào còn lại. Sinh ra để khỏi cuộn 200 tin nhắn đọc lại từ đầu. Hiểu `/recap` là hiểu "đồng nghiệp trực thay tóm tắt ca cho bạn lúc quay lại".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/recap` | _(không có)_ | Tóm tắt full: mục tiêu + đã xong + đang dở + quyết định đã chốt |
| `/recap --short` | flag | Tóm tắt 5-10 dòng (đang vội, chỉ cần "tới đâu rồi") |
| `/recap --decisions` | flag | Chỉ liệt kê quyết định đã chốt (chống "sao lại làm thế này") |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: sáng quay lại sau tối qua (khuyên dùng)
/recap
# → "Hôm qua: refactor auth (xong login, dở refresh-token).
#    Chốt: giữ public API, tách Stripe riêng. Dở: viết test refresh + /verify."
```

```bash
# Dạng 2: vội, chỉ cần 1 đoạn
/recap --short
# → "Auth 70%: login xong, còn refresh-token + verify."
```

```bash
# Dạng 3: quên vì sao làm kiểu này
/recap --decisions
# → "1. Giữ public API (đừng breaking). 2. Stripe file riêng. 3. Không đụng test cũ."
```

---

## Cách nó hoạt động

### Cơ chế sâu: recap moi gì từ history?

1. **Mục tiêu (goal):** task ban đầu là gì (`/goal` nếu có, hoặc suy từ 10 tin đầu).
2. **Đã xong:** file đã sửa + test đã pass + kết quả tool (commit nào, PASS gì).
3. **Đang dở:** todos chưa tick, task nói "để mai", `/verify` chưa chạy.
4. **Quyết định đã chốt:** chọn A bỏ B ở đâu (giữ API, tách file...) — kèm lý do 1 dòng để bạn khỏi hỏi lại "sao không làm B".
5. **Không bịa:** chỉ tóm tắt cái có trong history; cái chưa làm ghi rõ "chưa làm", không ghi "đã xong".

```text
/recap
├─ goal:      refactor auth, giữ public API
├─ done:      login.ts xong + test PASS (tối qua 22:14)
├─ pending:   refresh-token.ts (dở) + /verify chưa chạy
├─ decisions: Stripe file riêng / không đụng test cũ (lý do kèm theo)
└─ next:      tiếp tục refresh-token → /verify → mở PR
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Tóm tắt gì? | Dùng khi nào? |
|---|---|---|
| `/recap` | SESSION NÀY đang tới đâu (ngắn, quay lại làm tiếp) | Sau break, nghỉ trưa, qua đêm |
| `/compact` | NÉN context để tiếp tục (xử lý tràn) | Context đầy, cần gọn để làm tiếp |
| `/export` | XUẤT full log ra file (dài, lưu trữ) | Cần lưu/báo cáo, không phải để đọc nhanh |
| `/resume` | TÌM LẠI session cũ theo ID | Mở nhầm session mới, cần quay về cũ |
| `/status` | TRẠNG THÁI máy (model, bản, provider) | Hỏi "máy sao", không phải "việc tới đâu" |

> Quy tắc ngón tay cái:
>
> - **Quay lại làm tiếp → `/recap`. Tràn context → `/compact`. Lưu báo cáo → `/export`. Lạc session → `/resume`.**

---

## Ví dụ thực tế

### Kịch bản 1: Sáng quay lại sau tối qua dở (5 phút)

```bash
# Tối qua 23h nghỉ giữa chừng, sáng mở máy:
/recap
# → "Tối qua: refactor payments.
#    Xong: tách stripe.ts riêng, test 12/12 PASS.
#    Dở: webhook verify signature (mới research, chưa code).
#    Chốt: giữ public API, không đụng test cũ.
#    Tiếp: code webhook verify → /verify → /security-review."

# → làm tiếp luôn, khỏi cuộn 150 tin tối qua
```

> Kết quả: 30 giây lấy lại toàn cảnh. Không recap mà làm là dễ code trùng/sửa ngược quyết định tối qua.

### Kịch bản 2: Nghỉ trưa 1 tiếng, quên đang debug tới đâu

```bash
/recap --short
# → "Bug #123: đã loại trừ DB (query OK) + API (200 đúng).
#    Nghi: frontend cache cũ. Tiếp: hard-refresh + check header."
# → chiều vào làm tiếp đúng chỗ, không debug lại từ DB
```

### Kịch bản 3: Đồng nghiệp hỏi "sao làm kiểu này" — lôi decisions ra

```bash
/recap --decisions
# → "1. Giữ public API vì 3 service khác đang dùng (breaking = sập).
#    2. Stripe file riêng vì tuần trước lẫn lộn gây bug refund.
#    3. Không đụng test cũ vì sẽ viết suite mới sprint sau."
# → paste 3 dòng này trả lời PR comment, khỏi giải thích lại
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (tin recap mù)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Recap gọn quá, mất chi tiết quan trọng | HAY GẶP: "test PASS" nhưng không ghi test nào, bạn tưởng full | Task quan trọng đọc full `/recap` (không `--short`); nghi thì cuộn kiểm tra |
| Session 500 tin, recap sót việc dở | Tóm tắt heuristic, có thể sót todo kẹt sâu | Đối chiếu `/todos` sau recap; todos mới là nguồn thật |
| Dùng recap thay ghi chú | Break 1 tuần, recap cũng không cứu được ngữ cảnh mất | Việc phức tạp: `/export` lưu file + ghi TODO trước khi nghỉ |

### Tốn token?

- 1 lần `/recap` ≈ 2-5k token (đọc history rồi nén). Rẻ hơn cuộn tay đọc 200 tin (tốn context + thời gian bạn).

### Version / provider

- `/recap`: v2.x. Bản cũ tự cuộn đọc tay.
- `--short` / `--decisions`: v2.1+. Cũ hơn chỉ tóm tắt 1 dạng.
- Bedrock/Vertex: dùng được (tóm tắt local history).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/recap` + `/todos` | Recap xong đối chiếu việc dở | Recap → todos tick lại |
| `/recap` + `/status` | Vừa biết việc tới đâu + máy sao | Recap việc, status máy |
| `/recap` + `/compact` | Recap xong thấy context đầy | Recap nhớ việc → compact gọn → làm tiếp |
| `/recap` + `/voice` | Đi đường hỏi miệng "tới đâu rồi" | Voice ON → `/recap --short` |

Workflow chuẩn "bắt đầu ngày mới (5 phút)":

```bash
# 1. Tóm tắt hôm qua
/recap
# 2. Đối chiếu todos (nguồn thật)
/todos
# 3. Kiểm tra máy
/status
# 4. Làm tiếp việc dở đầu tiên
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Recap chung chung ("đang refactor") | Session mới 5 tin, chưa có gì để tóm | Session ngắn thì khỏi recap; đọc trực tiếp 5 tin |
| Recap sót todo quan trọng | Todo tạo muộn, nằm sâu trong tool log | Luôn `/todos` sau recap; ghi todo ngay khi phát sinh, đừng để trong đầu |
| Recap ghi "đã xong" cái chưa xong | Model suy từ câu "OK để đó" nhầm thành done | Đọc kỹ mục done, gạch cái chưa xong; dặn rõ "chưa xong, mai làm" trước khi nghỉ |
| Mở nhầm session mới, recap trống | Đang ở session khác, không phải session hôm qua | `/resume` tìm session hôm qua rồi mới `/recap` |
| Break 1 tuần, recap không đủ | Ngữ cảnh mất quá nhiều (quyết định miệng ngoài chat) | Trước nghỉ dài: `/export` + ghi tóm tắt tay vào PR/ticket |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../todos/README.md](../../session-context/todos/README.md) — nguồn thật việc dở (đối chiếu sau recap)
  - [../compact/README.md](../../session-context/compact/README.md) — nén context khi recap xong thấy đầy
  - [../export/README.md](../../session-context/export/README.md) — xuất full log khi cần lưu trữ
  - [../resume/README.md](../../session-context/resume/README.md) — tìm lại session hôm qua
  - [../status/README.md](../../auth-settings/status/README.md) — trạng thái máy buổi sáng
- Bài tổng quan:
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — quản lý session qua ngày

> Mẹo 1 dòng: _trước khi nghỉ ghi todo, sau khi quay lại recap + todos rồi hẵng code._
