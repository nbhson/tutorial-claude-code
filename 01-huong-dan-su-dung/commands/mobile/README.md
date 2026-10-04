# /mobile — Pair điện thoại: quét QR, điều khiển session từ xa, persist cross-device

> Loại Built-in · Nhóm Remote · Nguy hiểm Có nhẹ (điện thoại thành remote full-quyền của session — mất điện thoại = mất điều khiển; nhưng Không chuyển nơi chạy, code vẫn ở máy cũ)

`/mobile` ghép điện thoại với session đang chạy trên desktop: hiện QR, quét bằng app là điện thoại thành "điều khiển từ xa" — xem log, gõ prompt, duyệt permission (`Yes/No`) từ quán cà phê. Execution vẫn ở máy desktop (khác `/teleport` là bê cả session đi). Hiểu `/mobile` là hiểu "cầm remote TV ra sân" — TV vẫn trong nhà, bạn chỉ mang remote đi.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/mobile` | _(không có)_ | Hiện QR pair thiết bị mới (flow mặc định) |
| `/mobile --list` | flag | Liệt kê thiết bị đã pair (online/offline) |
| `/mobile --revoke <device>` | tên thiết bị | Huỷ pair 1 thiết bị (mất máy, đổi điện thoại) |
| `/mobile --revoke-all` | flag | Huỷ tất cả thiết bị đã pair |
| `/mobile --qr` | flag | Hiện lại QR khi màn hình trôi mất (không pair lại từ đầu) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: pair điện thoại mới (đang ngồi trước desktop)
/mobile
# → Hiện QR lớn trên terminal. Mở app trên điện thoại → Scan → "Paired ✓"
```

```bash
# Dạng 2: xem điện thoại nào đang gắn
/mobile --list
# → "iphone-15 (online) · ipad-cu (offline 12 days)"
```

```bash
# Dạng 3: mất điện thoại — đá nó ra ngay
/mobile --revoke iphone-15
```

```bash
# Dạng 4: QR trôi mất sau 100 dòng log
/mobile --qr
# → hiện lại QR của pairing hiện tại
```

```bash
# Dạng 5: dọn sạch khi đổi đợt thiết bị
/mobile --revoke-all
```

---

## Cách nó hoạt động

### Cơ chế sâu: QR pairing + cross-device persist thế nào?

1. **QR pairing (ghép 1 lần, dùng nhiều tháng):**
   - `/mobile` sinh 1 pairing token dùng 1 lần (hết hạn 5-10 phút) + mã hoá thành QR trên terminal.
   - App điện thoại (đã `/login` cùng account) quét QR → gửi pairing token + device ID + public key lên server → server nối device với account của bạn.
   - Từ đó device được cấp 1 device credential riêng (không phải copy token desktop) — revoke được từng cái độc lập.
2. **Điều khiển từ xa (remote control, không phải mirror video):**
   - Điện thoại không SSH vào máy bạn. Cả 2 cùng nối lên cloud relay qua WebSocket: desktop push transcript/log lên, điện thoại push input (prompt, Yes/No permission) xuống.
   - Cái bạn thấy trên điện thoại là transcript render lại native, không phải ảnh chụp terminal — nhẹ pin, đọc được khi mạng yếu.
   - Duyệt permission từ xa: dialog `Allow `rm -rf`? [Yes/No]` hiện push notification — bấm Yes trên điện thoại là desktop chạy tiếp. Tiện nhưng cũng là điểm nguy hiểm nhất (bấm Yes mù ngoài đường).
3. **Cross-device persist (đổi điện thoại không mất gì):**
   - Pairing gắn với ACCOUNT, không gắn với session đơn lẻ. Đổi điện thoại mới: login cùng account → pair lại → thấy lại danh sách session đang chạy trên desktop.
   - Session state (transcript, todos) nằm trên desktop + relay — điện thoại chỉ là view. Mất điện thoại không mất việc (revoke rồi pair cái mới).
   - Nhiều device cùng lúc được: vừa iPhone vừa iPad cùng điều khiển 1 session (last-write-wins khi gõ cùng lúc).
4. **Offline thì sao?**
   - Desktop mất mạng: điện thoại hiện "host offline", chỉ đọc được transcript cache tới lúc mất mạng, không gõ được.
   - Điện thoại mất mạng: desktop chạy tiếp bình thường; điện thoại online lại thì sync phần thiếu (gap-fill).
5. **Khác `/teleport` và web ở điểm nào?**
   - `/teleport` = execution đổi chỗ (máy cũ hết việc). `/mobile` = execution ở yên (desktop vẫn gánh CPU/RAM), điện thoại chỉ remote.
   - Web = session mới trên cloud. Mobile = điều khiển đúng session desktop đang chạy (thấy cả tiến trình local, file local).

### Sơ đồ pair — điều khiển — revoke

```text
Desktop: /mobile → QR (pairing token, TTL 5-10')
  │ quét bằng app (cùng account)
  ├─ Server: pairing token ✓ → cấp device credential (riêng, revoke được)
  ├─ WebSocket 2 chiều qua relay:
  │    desktop ──transcript/log──▶ điện thoại (render native)
  │    điện thoại ──prompt/Yes-No──▶ desktop (chạy tiếp)
  └─ Mất máy? /mobile --revoke <device> → device credential chết ngay
     Đổi máy mới? login cùng acc → /mobile quét lại → thấy session cũ
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Execution ở đâu? | Điện thoại làm gì? | Dùng khi nào? |
|---|---|---|---|
| `/mobile` | Ở yên (desktop) | Remote điều khiển | Ra ngoài, canh task dài |
| `/teleport` | Chuyển đi (sang cloud/máy khác) | Không liên quan | Đổi máy làm việc |
| Web (claude.ai) | Cloud | Chạy độc lập | Việc mới, không cần máy nhà |
| `/remote-env` | Remote | Cấu hình env | Cloud thiếu biến môi trường |

> Quy tắc ngón tay cái:
>
> - **Task 2 tiếng đang chạy, phải ra ngoài → `/mobile` (mang remote). Về nhà muốn làm tiếp trên laptop → `/teleport` (bê cả bàn).**

---

## Ví dụ thực tế

### Kịch bản 1: Pair lần đầu + canh test dài từ quán cà phê (kinh điển)

```bash
# Ở nhà, trước khi ra ngoài:
# Task refactor đang chạy test 45 phút, không muốn ngồi chờ:
/mobile
# → QR hiện lên. Mở app → quét → "Paired: iphone-15 ✓"
# → Ra ngoài. Test chạy tới bước cần duyệt:
#   Điện thoại rung: "Allow Bash(npm run migrate)? [Yes/No]"
# → Đọc kỹ lệnh rồi bấm Yes. Về nhà task xong.
```

> Kết quả: 45 phút ngoài đường vẫn kiểm soát được, không phải Yes mù cũng không phải ngồi chờ. Quy tắc: chỉ Yes khi đọc được lệnh — không đọc được (đang lái xe) thì để đó, về nhà duyệt sau.

### Kịch bản 2: 2 thiết bị cùng canh 1 session deploy đêm

```bash
# Tối deploy, iPhone + iPad cùng pair:
/mobile --list
# → "iphone-15 (online) · ipad-nha (online)"

# 2h sáng deploy hỏi migration nguy hiểm:
# → Cả 2 máy cùng rung. Vợ cầm iPad bấm nhầm Yes?
# → Last-write-wins: bạn bấm No ngay sau đó trên iPhone là ghi đè.
# → Sáng mai: /mobile --list kiểm tra không có device lạ
```

> Cảnh báo: device nào cũng full-quyền Yes/No — chỉ pair device của mình, không pair máy người khác "xem cho vui".

### Kịch bản 3: Mất điện thoại — revoke trong 30 giây

```bash
# Rớt điện thoại ngoài đường, sợ người nhặt bấm Yes lung tung:
# Mở laptop (hoặc máy khác cùng account):
/mobile --revoke iphone-15
# → "Revoked iphone-15. Its device credential no longer works."

# Mua máy mới: login cùng account → /mobile → quét QR mới → tiếp tục
# → session cũ trên desktop còn nguyên (persist theo account, không theo máy)
```

> Kết quả: mất remote, không mất việc. Revoke device ≠ logout desktop — desktop chạy tiếp bình thường.

### Kịch bản 4: QR trôi mất giữa đống log

```bash
# /mobile xong quay sang đọc log, 200 dòng sau muốn pair mà QR trôi tuốt lên trên:
/mobile --qr
# → hiện lại QR (cùng pairing token nếu còn hạn; hết hạn thì sinh mới)

# Mẹo team: chụp ảnh QR gửi đồng nghiệp? KHÔNG — pairing token gắn account bạn,
# người khác quét cũng không vào được acc họ, mà lộ token thì rủi ro.
# Muốn share session cho người khác: dùng link share, không share QR.
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào?

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Bấm Yes permission mù ngoài đường (đang đi xe, notification hiện nửa dòng) | Duyệt nhầm `rm -rf`/migration phá DB | Chỉ Yes khi mở app đọc đủ lệnh; đang bận thì kệ — về nhà duyệt sau, task đợi được |
| Mất điện thoại chưa revoke | Người nhặt được remote full-quyền session đang chạy | Revoke ngay từ máy khác; bật khoá màn hình + FaceID cho app |
| Pair máy người khác "xem cho vui" | Họ có quyền gõ prompt + Yes/No như bạn | Không pair device không phải của mình; xong demo thì `--revoke` ngay |
| Push notification hiện nội dung prompt nhạy cảm | Người bên cạnh đọc được code/secret trên màn hình khoá | Tắt preview notification cho app (Settings → Notifications → Show Previews: When Unlocked) |
| Tưởng revoke device là đăng xuất desktop | Desktop vẫn login, token còn — revoke chỉ đá điện thoại | Muốn thoát hẳn: `/logout` riêng |

### Tốn token/pin?

- `/mobile` không tốn token model (chỉ relay transcript). Điện thoại render text nên nhẹ pin hơn mirror video rất nhiều.
- Push notification qua relay — mạng yếu vẫn nhận được (text vài KB).

### Version / provider

- QR pairing + multi-device: v2.x. Bản cũ chỉ 1 device, pair mới đá cũ.
- App mobile cần cùng version major với CLI desktop (lệch quá xa relay từ chối, báo update).
- Bedrock/Vertex: mobile relay có thể không khả dụng tuỳ vendor — xem bài 02.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/mobile` + `/teleport` | Đẩy lên cloud rồi canh bằng điện thoại | Teleport cloud → mobile pair → tắt desktop đi chơi |
| `/mobile` + `/status` | Ra ngoài kiểm tra session còn sống không | Mở app xem status + transcript mới nhất |
| `/mobile` + permission `ask` | Canh task nguy hiểm từ xa | Để lệnh nguy hiểm ở ask → điện thoại duyệt từng cái |
| `/mobile --revoke` + `/login` | Đổi điện thoại | Revoke cũ → login acc trên máy mới → pair lại |

Workflow chuẩn "chạy task dài qua đêm (5 phút setup)"./mobile --list

```bash
# 1. Chiều: cho task chạy (test/build/migrate)
/mobile
# → quét QR, xác nhận điều khiển được từ điện thoại
# 2. Đặt lệnh nguy hiểm ở chế độ ask (xem /permissions + bài 10)
# 3. Đi ngủ. Nửa đêm notification rung → mở app đọc kỹ → Yes/No
# 4. Sáng: /mobile --list (không có device lạ là yên tâm)
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Quét QR báo `expired` | Pairing token TTL 5-10 phút, để lâu quá | `/mobile --qr` sinh mới rồi quét ngay |
| Quét QR báo `account mismatch` | App login mail khác với desktop | Đăng xuất app, login đúng mail desktop rồi quét lại |
| App hiện `host offline` | Desktop sleep/mất mạng/tắt | Bật desktop, tắt sleep (`caffeinate` macOS); desktop tắt là remote chịu |
| Notification không rung khi cần Yes | Tắt thông báo app hoặc chế độ Focus | Bật Notifications cho app; cho phép Time Sensitive; test bằng 1 lệnh ask thử |
| 2 device gõ cùng lúc, lệnh lộn xộn | Last-write-wins, không lock | Quy ước 1 người gõ; người còn lại chỉ xem |
| Relay lag, log chậm 30s | Mạng desktop yếu (upload kém) | Kiểm tra mạng desktop; task nặng log nhiều thì lag là bình thường |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../teleport/README.md](../teleport/README.md) — chuyển nơi chạy (mobile thì nơi chạy ở yên)
  - [../login/README.md](../login/README.md) — 2 đầu phải cùng account mới pair được
  - [../status/README.md](../status/README.md) — xem session từ xa còn sống không
  - [../remote-env/README.md](../remote-env/README.md) — session remote thiếu env thì cấu ở đây
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — auth đa thiết bị
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — mobile là 1 bề mặt chính thức
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — để ask để duyệt từ xa an toàn

> Mẹo 1 dòng: _pair 1 lần dùng cả năm — nhưng Yes từ xa thì mỗi lần đều như lần đầu: đọc kỹ rồi mới bấm._
