# /fewer-permission-prompts — Quét transcripts, đề xuất allowlist read-only cho đỡ hỏi

> Loại Built-in · Nhóm Quyền & Ma sát · Nguy hiểm Thấp (chỉ ĐỀ XUẤT allowlist read-only; nhưng Có nếu bạn Yes mù cả suggest ghi/xoá — chỉ Yes cái đọc)

`/fewer-permission-prompts` (tên cũ `less-permission-prompts` ở bản v2.1.111) quét transcripts (lịch sử hỏi quyền) rồi đề xuất allowlist READ-ONLY (Read/Glob/Grep trên path an toàn) để máy đỡ hỏi lặp. Nó không tự mở quyền ghi/chạy — chỉ gợi ý, bạn duyệt từng cái. Hiểu nó là hiểu "máy học thói quen bạn để bớt hỏi, nhưng phanh vẫn còn".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/fewer-permission-prompts` | _(không có)_ | Quét transcripts + đề xuất allowlist read-only (duyệt từng cái) |
| `/less-permission-prompts` | _(tên cũ, v2.1.111)_ | Bí danh cũ — bản mới đã đổi thành `fewer-...`, dùng tên mới |
| `/permissions` | _(lệnh sửa tay)_ | Xem/sửa quyền trực tiếp sau khi có đề xuất |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: máy hỏi lặp 20 lần/ngày — cho nó học thói quen
/fewer-permission-prompts
# → "Bạn cho phép Read src/** 47 lần/7 ngày. Thêm vào allow? [Yes/No từng cái]"
```

```bash
# Dạng 2: bản cũ gõ tên cũ (vẫn chạy ở bản hỗ trợ bí danh)
/less-permission-prompts
# → (bản mới) "Đã đổi tên thành /fewer-permission-prompts. Dùng tên mới."
```

```bash
# Dạng 3: duyệt xong kiểm tra quyền hiện tại
/permissions
# → xem allow mới đã vào settings chưa
```

---

## Cách nó hoạt động

### Cơ chế sâu: từ "hỏi 47 lần" tới 1 dòng allow

1. **Quét transcripts:** đọc lịch sử prompt hỏi quyền 7-30 ngày: lệnh nào bạn `Allow` lặp đi lặp lại (Read src/**, Glob docs/**...).
2. **Chỉ đề xuất READ-ONLY:** Read/Glob/Grep trên path code/docs — KHÔNG đề xuất Bash ghi/xoá, Edit/Write. Thấy bạn Allow `rm` 10 lần nó cũng KHÔNG gợi (đúng vậy — đừng hỏi sao không gợi).
3. **Bạn duyệt từng cái:** mỗi suggest hiện tần suất ("47 lần/7 ngày") + phạm vi. Yes cái nào vào allow cái đó (ghi settings project hoặc local — bạn chọn).
4. **Đổi tên v2.1.111:** `less-permission-prompts` → `fewer-permission-prompts` (sửa ngữ pháp: prompts đếm được). Bản mới dùng tên mới; tên cũ còn chạy tùy bản (bí danh tương thích).

```text
transcripts 7 ngày: Read src/auth/*.ts → Allow 47 lần
  │  /fewer-permission-prompts
  ▼
suggest: allow Read src/**  (read-only, an toàn)
  │  bạn Yes → ghi settings → từ nay khỏi hỏi 47 lần nữa
  │  bạn No → giữ nguyên (vẫn hỏi, nhưng an toàn tuyệt đối)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Làm gì? | Dùng khi nào? |
|---|---|---|
| `/fewer-permission-prompts` | GỢI Ý allow read-only từ thói quen | Bị hỏi lặp tới bực |
| `/permissions` | SỬA quyền tay (allow/ask/deny bất kỳ) | Muốn kiểm soát chi tiết |
| `/sandbox` | CHẠY cách ly hẳn | Code lạ, không tin tưởng |
| `/doctor` | KHÁM quyền có mở toang không | Nghi settings bệnh |

> Quy tắc ngón tay cái:
>
> - **Bực vì hỏi lặp → `/fewer-permission-prompts` (Yes cái đọc). Muốn sửa tay → `/permissions`. Code lạ → `/sandbox`.**

---

## Ví dụ thực tế

### Kịch bản 1: Ngày bị hỏi 30 lần Read — dọn 1 phát (5 phút)

```bash
# Triệu chứng: mỗi lần hỏi "đọc file X?" bạn đều Allow:
/fewer-permission-prompts
# → "3 đề xuất (read-only):
#    [1] Read src/** (47 lần/7d) [Yes/No]
#    [2] Glob docs/** (19 lần/7d) [Yes/No]
#    [3] Grep tests/** (12 lần/7d) [Yes/No]"
# → Yes cả 3 → từ nay đọc 3 chỗ này khỏi hỏi

/permissions
# → xác nhận 3 dòng đã vào allow (scope project)
```

> Kết quả: 30 prompt/ngày còn ~5 (chỉ còn hỏi ghi/chạy — đúng cái ĐÁNG hỏi).

### Kịch bản 2: Gõ tên cũ ở bản mới — đừng hoảng

```bash
/less-permission-prompts
# → bản ≥v2.1.111: "Lệnh đã đổi tên thành /fewer-permission-prompts."
# → gõ lại tên mới, mọi thứ như cũ (transcripts + suggest giữ nguyên)
```

### Kịch bản 3: Suggest có mùi ghi/xoá — từ chối (đọc kỹ!)

```bash
/fewer-permission-prompts
# → "... [4] Bash(npm run dev:*) (22 lần/7d) [Yes/No]"
# → Đây KHÔNG phải read-only. Hỏi: "dev server có chạy migration kèm không?"
# → package.json có "dev": "migrate && next dev" (!!) → bấm No.
# → giữ hỏi tay lệnh này — phiền 1 chút nhưng an toàn.
```

> Nguyên tắc: suggest nào chạm CHẠY/GHI/XOÁ thì mặc định No, trừ khi bạn đọc kỹ lệnh đó và chắc nó lành.

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (Yes mù)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Yes hết không đọc | HAY GẶP: allow cả path chứa `.env`/key (`Read secrets/**`) | Chỉ Yes path code/docs; path có secret → No + thêm deny |
| Allow `Read **` toàn repo | Tool đọc được cả `.env`, key, backup | Hẹp path (`src/**`, `docs/**`); deny `.env*` đè lên |
| Tưởng xong là hết hỏi hẳn | Vẫn hỏi ghi/chạy (đúng thiết kế) | Muốn hết hẳn thì sang `/permissions` mở thêm — nhưng cân nhắc kỹ |
| Dùng tên cũ trong script/alias | Script gọi `less-...` fail ở bản bỏ bí danh | Đổi script sang `fewer-permission-prompts` từ giờ |

### Tốn token?

- 1 lần quét ≈ 2-4k token (đọc transcripts). Tuần 1 lần hoặc khi bực — rẻ.

### Version / provider

- Tên cũ `less-permission-prompts` → tên mới `fewer-permission-prompts` từ **v2.1.111**. Bản mới dùng tên mới.
- Chỉ suggest read-only: mọi bản. Bedrock/Vertex: dùng được (đọc transcripts local).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| suggest + `/permissions` | Duyệt gợi ý rồi kiểm tra tay | Fewer → permissions xác nhận |
| suggest + `/doctor` | Khám xem allow mới có mở toang không | Duyệt xong → doctor permissions |
| suggest + `/sandbox` | Code lạ: đừng allow, sandbox luôn | Repo lạ → sandbox, khỏi fewer |

Workflow chuẩn "đỡ bực mà vẫn an toàn (10 phút)":

```bash
# 1. Quét thói quen
/fewer-permission-prompts
# 2. Yes cái đọc (src/docs/tests), No cái chạy/ghi
# 3. Khám lại quyền
/doctor permissions
# 4. Kiểm tra tay
/permissions
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Quét báo "no patterns" dù bị hỏi nhiều | Transcripts bị xóa (`/clear` nhiều) hoặc mới dùng 1-2 ngày, chưa đủ mẫu | Dùng 1 tuần rồi quét lại; đừng clear liên tục nếu muốn máy học |
| Tên cũ chạy, tên mới không (bản kẹt giữa) | Bản quá cũ chưa có tên mới | Update CLI (`/restart` offer); dùng tên nào máy nhận |
| Yes rồi mà vẫn hỏi y hệt | Duyệt vào scope local nhưng session đọc scope project (hoặc ngược) | `/permissions` xem suggest vào scope nào; chuyển sang scope session đang dùng |
| Suggest path chứa secret | Transcripts có lần bạn Allow đọc `.env` debug | No suggest đó; thêm `deny: Read(.env*)` tay trong `/permissions` |
| Muốn hoàn tác 1 allow đã Yes | Yes nhầm path rộng | `/permissions` xóa dòng đó; chạy lại fewer để gợi hẹp hơn |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../permissions/README.md](../../model-mode/permissions/README.md) — sửa quyền tay sau khi duyệt gợi ý
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — khám quyền có mở toang không
  - [../sandbox/README.md](../../auth-settings/sandbox/README.md) — code lạ thì cách ly thay vì allow
  - [../status/README.md](../../auth-settings/status/README.md) — xem scope/settings đang dùng
- Bài tổng quan:
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — mô hình quyền allow/ask/deny

> Mẹo 1 dòng: _Yes cái đọc cho đỡ bực, No cái chạy/ghi cho còn phanh._
