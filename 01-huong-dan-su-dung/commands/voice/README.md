# /voice — Nói thay vì gõ (giữ Space để nói, thả để gửi)

> Loại Built-in · Nhóm Nhập liệu & Trợ năng · Nguy hiểm Không (chỉ đổi cách nhập; nhưng Có nhẹ nếu bạn đọc to secret/mã OTP nơi đông người)

`/voice` bật/tắt voice dictation trong terminal: giữ `Space` để nói, thả ra là transcript thành prompt gửi đi. Sinh ra cho lúc mỏi tay, đang đi bộ với mobile, hoặc ý dài nói nhanh hơn gõ. Hiểu `/voice` là hiểu "nhắn voice như chat app, nhưng nó biến thành chữ trước khi gửi".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/voice` | _(không có)_ | Bật/tắt (toggle) voice dictation |
| Giữ `Space` | phím (khi đã bật) | Nhấn-giữ để thu âm, thả ra để transcript + gửi |
| `/terminal-setup` | _(lệnh setup)_ | Sửa mic/quyền khi voice không thu được |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: bật (lần đầu hỏi quyền mic OS — Allow)
/voice
# → "Voice ON. Hold Space to talk, release to send."
```

```bash
# Dạng 2: dùng — giữ Space, nói, thả
# (nhấn-giữ Space) "tìm mọi chỗ gọi Stripe mà không có try catch" (thả)
# → transcript hiện để bạn duyệt → Enter gửi / sửa trước khi gửi
```

```bash
# Dạng 3: tắt khi vào chỗ ồn / cần gõ chính xác
/voice
# → "Voice OFF."
```

---

## Cách nó hoạt động

### Cơ chế sâu: từ tiếng nói tới prompt

1. **Thu âm:** giữ `Space` → thu từ mic mặc định của OS. Thả → dừng, gửi audio đi transcript.
2. **Transcript → text:** model speech-to-text biến thành chữ, HIỆN RA cho bạn đọc lại trước khi gửi (không gửi mù).
3. **Bạn duyệt rồi mới gửi:** sai từ chuyên môn (`Stripe` nghe thành `strike`) → sửa tay rồi Enter. Luôn có bước duyệt — đừng thả Space xong Enter mù.
4. **Toggle, không phải mode riêng:** `/voice` chỉ bật/tắt thu âm; mọi thứ khác (permissions, model, session) giữ nguyên.
5. **Giới hạn nhận diện:**
   - Ồn nền to (quán cà phê, công trường) → transcript sai nhiều, sửa còn lâu hơn gõ.
   - Từ chuyên môn/ký hiệu (`src/auth-v2`, regex, tên biến camelCase) → nói dễ sai, gõ nhanh hơn.
   - Ngôn ngữ: nói tiếng Việt ra tiếng Việt OK, nhưng prompt code tiếng Anh thì nên nói tiếng Anh từ đầu (khỏi dịch lại).

```text
/voice ON → giữ Space → nói → thả → transcript hiện → bạn sửa → Enter gửi
```

### Khác gì với lệnh dễ nhầm?

| Cách nhập | Phù hợp | Không phù hợp |
|---|---|---|
| `/voice` (nói) | Ý dài, đang đi/mobile, mỏi tay | Code chính xác, chỗ ồn, secret |
| Gõ tay | Tên file, regex, câu lệnh, secret | Ý dài 5 câu (gõ mỏi) |
| `/btw` (hỏi nhanh) | Hỏi phụ không ghi history | Việc chính (vẫn nên voice/gõ vào luồng chính) |

> Quy tắc ngón tay cái:
>
> - **Ý dài, từ thường → nói. Tên file, code, secret → gõ. Chỗ ồn → tắt voice, gõ cho lành.**

---

## Ví dụ thực tế

### Kịch bản 1: Đang đi bộ với mobile — giao task bằng miệng (3 phút)

```bash
/voice
# → Voice ON
# (giữ Space) "đọc file src/auth/login.ts, tóm tắt nó làm gì, có verify JWT không" (thả)
# → transcript: "đọc file src/auth/login.ts, tóm tắt nó làm gì, có verify JWT không" ✓
# → Enter → model làm, bạn vừa đi vừa nghe kết quả
/voice
# → Voice OFF khi về bàn
```

> Kết quả: giao task không cần dừng lại mở laptop gõ. Kiểm tra transcript 5 giây trước khi gửi.

### Kịch bản 2: Ý dài 5 câu — nói 30 giây thay vì gõ 5 phút

```bash
# Muốn dặn kỹ 1 task refactor, gõ mỏi tay:
/voice
# (giữ Space) "refactor module payments nhưng giữ nguyên public API,
#  tách Stripe ra file riêng, mọi chỗ gọi tiền phải có try catch và log,
#  xong chạy verify, đừng đụng file test cũ" (thả)
# → đọc lại transcript, sửa "Stripe" nếu bị nghe nhầm → Enter
```

> Mẹo: nói chậm, ngắt câu rõ. Nói 1 hơi 10 ý dễ transcript rối — chia 2-3 lần Space cho ý dài.

### Kịch bản 3: Chỗ ồn / đọc secret — tắt voice, gõ tay

```bash
# Vào quán ồn / cần dán API key:
/voice   # tắt
# → gõ tay API key, tên file chính xác từng ký tự
# → xong việc riêng tư rồi hẵng bật lại
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (đọc to + transcript sai)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Đọc to secret/OTP/token nơi đông người | HAY GẶP: mic thu + người xung quanh nghe | Secret KHÔNG BAO GIỜ nói — gõ tay hoặc dán |
| Transcript sai tên file/hàm mà Enter mù | Model đọc/sửa nhầm file (`auth-old` vs `auth`) | Đọc transcript 5 giây, sửa tên riêng trước khi gửi |
| Quên đang bật voice, giữ Space nhầm | Thu âm linh tinh thành prompt rác | Xong việc nói thì `/voice` tắt ngay; kiểm tra trước Enter |
| Họp online vừa share mic vừa voice | Thu luôn tiếng đồng nghiệp → prompt lẫn tạp âm | Tắt voice khi đang call/share màn hình |

### Tốn token?

- Voice ≈ 0 token thêm (audio transcript riêng, prompt text như gõ thường). Thoải mái bật/tắt.

### Version / provider

- `/voice` (giữ Space): v2.x bản terminal/mobile hỗ trợ mic. Lần đầu OS hỏi quyền mic — Allow mới dùng được.
- Mic lỗi → `/terminal-setup` kiểm tra lại thiết bị/quyền.
- Bedrock/Vertex: dùng được (transcript độc lập provider).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/voice` + `/btw` | Hỏi nhanh bằng miệng, không bẩn history | Voice ON → `/btw` + nói |
| `/voice` + `/background` | Giao việc dài bằng miệng rồi thả nền | Nói task → `/background` |
| `/voice` + `/recap` | Quay lại sau break, hỏi miệng "tới đâu rồi" | Voice ON → `/recap` |
| `/voice` + `/terminal-setup` | Mic không thu | Voice fail → terminal-setup sửa |

Workflow chuẩn "đi đường vẫn làm việc (mobile)":

```bash
# 1. Bật voice
/voice
# 2. Giao việc bằng miệng (đọc transcript trước khi gửi!)
# 3. Việc dài → đẩy nền cho nó tự làm
/background
# 4. Về bàn → tắt voice, resume lấy kết quả
/voice
/resume <id>
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Giữ Space không thu, thả ra trống | OS chưa cấp quyền mic (lần đầu Deny) | Settings OS → cho terminal quyền mic; `/terminal-setup` kiểm tra lại |
| Transcript toàn sai từ chuyên môn | Nói nhanh + từ lạ (`webhook`, `idempotency`) | Nói chậm, đánh vần tên riêng; hoặc gõ tay đoạn có từ chuyên môn |
| Thu cả tiếng quạt/đồng nghiệp | Mic mặc định là mic xa/kém chống ồn | Đổi mic gần (tai nghe) trong settings OS; vào chỗ yên |
| Nói tiếng Việt ra prompt Việt, muốn Anh | Nói ngôn ngữ nào ra ngôn ngữ đó | Muốn prompt Anh thì nói Anh từ đầu; hoặc dặn thêm "trả lời bằng tiếng Anh" |
| Space giữ để scroll mà thành thu âm | Quen tay terminal cũ (Space = scroll/pager) | Dùng `/voice` tắt khi cần Space cuộn; bật lại khi cần nói |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../terminal-setup/README.md](../terminal-setup/README.md) — sửa mic/quyền khi voice không thu
  - [../mobile/README.md](../mobile/README.md) — dùng voice khi đi đường với mobile
  - [../btw/README.md](../btw/README.md) — hỏi nhanh không ghi history (nói cũng được)
  - [../background/README.md](../background/README.md) — giao miệng xong thả nền
  - [../recap/README.md](../recap/README.md) — hỏi miệng "hôm qua tới đâu" sau break
- Bài tổng quan:
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — các kiểu tương tác session

> Mẹo 1 dòng: _nói ý dài, gõ từ chuẩn, và đừng bao giờ đọc to secret._
