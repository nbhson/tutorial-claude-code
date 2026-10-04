# /radio — Kênh dev trực tiếp: hỏi-đáp nhanh, tính khả dụng hạn chế theo provider

> Loại Built-in (version-gated) · Nhóm Session/Realtime · Nguy hiểm Thấp (chủ yếu hỏi-đáp + nghe; nhưng Trung bình nếu bạn đọc secrets lên kênh công cộng)

`/radio` mở kênh realtime với Claude trong session: hỏi nhanh bằng giọng/text, nghe giải thích, brainstorm mà không phá mạch code chính. Hiểu `/radio` là hiểu "đài nội bộ của session" — bật lên hỏi, tắt đi code tiếp, history chính vẫn sạch.

> Lưu ý trung thực: **thông tin công khai về `/radio` ít, tính khả dụng hạn chế theo provider.** File này ghi đúng những gì verified được + cách tự kiểm tra ở máy bạn. Không thấy lệnh thì dùng workflow thay thế ở mục 7.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/radio` | _(không có)_ | Bật/tắt kênh radio trong session hiện tại |
| `/radio status` | action | Xem kênh đang on/off, ai đang nghe, mode nào |
| `/radio ask <câu hỏi>` | text | Hỏi nhanh qua kênh, không chèn vào mạch implement |
| `/radio off` | flag | Tắt kênh, quay về session text thường |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: bật kênh rồi hỏi
/radio
# → "Radio: on · Mode: discuss (không ghi file, không chạy tool nặng)"
```

```bash
# Dạng 2: hỏi nhanh không bẩn history chính
/radio ask "giải thích vì sao hook này chặn push nhánh feat/my-main-fix?"
# → trả lời ngắn trong kênh, mạch code chính không bị chèn 20 dòng giải thích
```

```bash
# Dạng 3: xong việc tắt đi
/radio off
# → "Radio: off · quay về session thường"
```

---

## Cách nó hoạt động

### Cơ chế sâu: radio khác gì chat thường?

1. **Kênh phụ trong cùng session:**
   - Chat chính giữ implement (Edit/Write/Bash). Kênh radio giữ discuss (hỏi, giải thích, brainstorm).
   - `/radio ask` tương tự `/btw` (không pollute history) nhưng thiên realtime/voice — hợp khi bạn vừa code vừa hỏi.
2. **Không tự chạy tools nặng (kỳ vọng):**
   - Kênh discuss mặc định không ghi file, không push, không deploy — chỉ đọc + trả lời.
   - Muốn hành động thì nói rõ "ghi vào file X" hoặc tắt radio làm ở kênh chính (tránh bấm nhầm khi đang nghe).
3. **Version-gated, provider-gated:**
   - Lệnh mới, bản Claude Code cũ không có. Thấy hay không thấy phụ thuộc version + plan + provider.
   - **Tính khả dụng hạn chế theo provider:** Console/Pro/Max thấy nhiều nhất; Bedrock/AWS/GCP và một số enterprise build có thể vắng mặt (tương tự `/design-sync`).
   - Chân lý cuối là gõ `/` trong session của bạn (mục 7): hiện thì dùng, không hiện thì fallback.
4. **Privacy theo kênh:**
   - Kênh realtime có thể đi qua voice/audio pipeline (nếu bật voice). Đừng đọc secrets, key, dữ liệu khách hàng lên kênh khi chưa rõ pipeline.

### Sơ đồ bật → hỏi → tắt

```text
code mạch chính (implement)
/radio → kênh phụ on (mode: discuss, no-write)
  │ /radio ask "vì sao test đỏ?" → giải thích ngắn, không chèn history chính
  ├─ hiểu rồi → /radio off → code tiếp
  └─ cần hành động → nói rõ ở kênh chính ("sửa file X dòng Y")
Không dùng radio để ra lệnh nguy hiểm (push/deploy/sửa DB)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Kênh | Dùng khi nào? |
|---|---|---|
| `/radio` | Kênh phụ realtime | Vừa code vừa hỏi, brainstorm nhanh |
| `/btw` | 1 câu hỏi lẻ | Hỏi 1 câu, full context, không history |
| Voice dictation (Tips 11) | Nhập liệu | Nói để thành text prompt (không phải kênh discuss) |
| Session thường | Kênh chính | Task cần Edit/Write/Bash thật |

> Quy tắc ngón tay cái:
>
> - **Hỏi mà sợ loãng mạch code → `/radio ask` hoặc `/btw`. Cần sửa code thật → kênh chính.**

---

## Ví dụ thực tế

### Kịch bản 1: Đang implement kẹt, hỏi nhanh không mất mạch

```bash
# Mạch chính đang sửa auth, không muốn chèn 30 dòng thảo luận:
/radio ask "refresh token nên xoay ở đâu: middleware hay API route?"
# → kênh radio trả lời trade-off 5 bullets, mạch chính vẫn gọn

/radio off
# → áp quyết định vào code ở kênh chính
```

> Kết quả: quyết định xong trong 2 phút, history chính chỉ có code + quyết định cuối, không có 50 dòng cãi nhau.

### Kịch bản 2: Onboarding người mới — nghe giải thích repo khi đang đi bộ

```bash
/radio
/radio ask "giải thích luồng request từ apps/web tới Postgres trong 1 phút?"
# → nghe tóm tắt, hỏi tiếp "vẽ lại bằng 5 bullets?" nếu cần
/radio off
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Đọc secrets/PII lên kênh voice | Lọt qua audio pipeline, log khó kiểm soát | Kênh radio chỉ hỏi concept; secrets gõ ở kênh chính đã guard |
| Tưởng radio tự sửa code | Hỏi mà không ai ghi — việc trôi | Radio chỉ discuss; action phải nói rõ ở kênh chính + verify |
| Dùng ở chỗ ồn/mic mở | Lệnh nhầm, transcript sai | Kiểm tra transcript trước khi cho chạy tool gì |
| Tin radio có ở mọi provider | Ở Bedrock/GCP gõ không ra, tưởng lỗi | Gõ `/` kiểm tra trước (mục 7); vắng thì fallback `/btw` |

### Tốn token?

- Thấp–trung bình nếu chỉ discuss. Cao nếu hỏi cả codebase không scope (kênh phụ cũng tính context chung).

### Version / provider

- Version-gated: bản cũ không có `/radio`. Update bản mới nhất rồi gõ `/` xem có hiện không.
- Provider: **tính khả dụng hạn chế theo provider** — Console/Pro/Max thường thấy; Bedrock/AWS/GCP/enterprise build có thể vắng. Không có bảng version floor công khai đáng tin → tự kiểm tra ở máy bạn.
- Plan: một số tính năng realtime/voice cần plan cao hơn (xem Tips 11 voice dictation + computer use).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/radio ask` + `/btw` | Hỏi nhanh | Radio khi đang discuss dài, btw khi 1 câu lẻ |
| `/radio` + `/plan` | Brainstorm trước plan | Radio bóc trade-off → plan chốt thành steps |
| `/radio off` + `/verify` | Sau quyết định | Tắt kênh, code + verify bằng evidence |
| `/radio` + `/export` | Lưu quyết định hay | Export đoạn discuss hay trước khi `/clear` |

Workflow chuẩn "hỏi không bẩn mạch (3 phút)": `/radio` → `ask` 1 câu hẹp → hiểu → `off` → làm ở kênh chính + verify.

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `unknown command: /radio` | Bản cũ hoặc provider không hỗ trợ | Update mới nhất; gõ `/` kiểm tra; vắng thì dùng `/btw` |
| Hỏi mà trả lời chung chung | Câu hỏi quá rộng ("giải thích cả repo") | Hẹp scope: 1 file/1 luồng/1 quyết định |
| Transcript voice sai từ khóa | Mic/tiếng ồn/thuật ngữ | Gõ lại từ khóa (tên file/hàm) bằng text |
| Kênh on mà tưởng off | Quên `/radio off` | `/radio status` kiểm tra; off trước khi code thật |
| Muốn action mà radio chỉ nói | Kênh discuss mặc định no-write | Chuyển kênh chính, ra lệnh rõ + verify |

---

## Tham khảo

- Cách kiểm tra lệnh có tồn tại ở máy bạn (chân lý cuối):

```bash
# Trong Claude Code session, gõ:
/
# → list lệnh khả dụng ở version + plan + provider hiện tại
# → thấy /radio thì dùng file này; không thấy = provider/version bạn vắng lệnh
```

- Workflow thay thế khi vắng `/radio` (dùng được ở mọi provider):

```bash
# 1. Hỏi 1 câu không bẩn history:
/btw vì sao hook branch-protect chặn push này?

# 2. Brainstorm dài: mở session phụ hoặc /fork thử what-if
/fork

# 3. Nghe/giải thích khi di chuyển: voice dictation nhập prompt (Tips 11)
# 4. Lưu quyết định hay: /export trước khi /clear
```

- Lệnh liên quan trực tiếp:
  - [../btw/README.md](../btw/README.md) — hỏi 1 câu không history (fallback #1)
  - [../fork/README.md](../fork/README.md) — thử what-if không mất mạch
  - [../plan/README.md](../plan/README.md) — chốt discuss thành plan duyệt
  - [../export/README.md](../export/README.md) — lưu đoạn discuss hay
- Bài tổng quan:
  - [../../04-slash-commands-toan-tap.md](../../04-slash-commands-toan-tap.md) — index 64 lệnh + công thức khi lệnh vắng
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — availability theo provider/plan
  - [../../../02-tips-thuc-chien/11-nang-cao-desktop-web.md](../../../02-tips-thuc-chien/11-nang-cao-desktop-web.md) — voice + desktop/web sessions đi kèm radio

> Mẹo 1 dòng: _thấy `/radio` khi gõ `/` thì dùng, không thấy thì `/btw` + `/fork` là đủ — đừng cố gọi lệnh vắng mặt._
