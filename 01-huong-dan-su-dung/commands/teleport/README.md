# /teleport — Chuyển session đang chạy giữa terminal local và cloud (hoặc máy ↔ máy)

> Loại Built-in · Nhóm Remote · Nguy hiểm Có nhẹ (session + file context di chuyển qua mạng — mạng lạ/VPN công ty có thể nhìn thấy metadata; nhưng Không mất code nếu làm đúng)

`/teleport` "dịch chuyển tức thời" session đang chạy: đang làm trên terminal công ty, teleport sang cloud (hoặc sang laptop ở nhà) là tiếp tục đúng chỗ — history, todos, file đang sửa đi theo. Hiểu `/teleport` là hiểu "bê cả bàn làm việc sang phòng khác" — khác `/mobile` (điều khiển từ điện thoại) và `/remote-env` (cấu hình môi trường remote).

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/teleport` | _(không có)_ | Mở menu chọn đích (cloud / thiết bị đã pair) |
| `/teleport cloud` | đích | Chuyển session hiện tại lên cloud session |
| `/teleport local` | đích | Kéo session cloud về terminal local |
| `/teleport <device>` | tên thiết bị | Chuyển sang thiết bị đã pair (laptop-nha, pc-congty) |
| `/teleport --list` | flag | Liệt kê đích khả dụng (cloud region, devices) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: đang ở terminal, đẩy lên cloud để về nhà làm tiếp
/teleport cloud
# → "Session moved to cloud (eu-west). Open https://claude.ai/s/abc123 to continue."
```

```bash
# Dạng 2: ở nhà, kéo session cloud về laptop
/teleport local
# → transcript tải về, tiếp tục trong terminal như chưa từng đi xa
```

```bash
# Dạng 3: chuyển thẳng sang thiết bị đã pair
/teleport laptop-nha
```

```bash
# Dạng 4: xem có những đích nào
/teleport --list
# → "Available: cloud (eu-west, us-east) · laptop-nha (online) · pc-congty (offline)"
```

---

## Cách nó hoạt động

### Cơ chế sâu: teleport chuyển session terminal ↔ cloud thế nào?

1. **Session là gì (để biết cái gì được chuyển)?**
   - 1 session = transcript JSONL (`~/.claude/history/<id>.jsonl`) + working-dir snapshot + todos + model/config + file đính kèm trong context. Teleport phải chuyển TẤT CẢ chỗ này, không chỉ text chat.
2. **Local → cloud (đẩy lên):**
   - CLI serialize transcript + nén diff file chưa commit (working tree) → upload qua HTTPS/WSS lên cloud endpoint (region bạn chọn).
   - Cloud spawn 1 container/session mới, bung transcript + apply diff → session cloud tiếp tục đúng dòng cuối.
   - Terminal local chuyển sang chế độ "mirror": mọi input/output đồng bộ 2 chiều cho tới khi bạn detach. Đóng terminal local lúc này KHÔNG kill cloud.
3. **Cloud → local (kéo về):**
   - Ngược lại: cloud serialize transcript mới nhất (gồm cả phần chạy trên cloud lúc bạn vắng) → local tải về, ghi đè history file, checkout/apply diff file.
   - Xung đột file? Nếu local có sửa trong lúc cloud cũng sửa: teleport dừng và hiện diff 2 bên, bạn chọn giữ bên nào (giống rebase conflict) — không tự ghi đè mù.
4. **Máy ↔ máy (qua cloud relay):**
   - 2 thiết bị không cần cùng mạng: máy A đẩy lên cloud relay, máy B kéo về. Cùng account (`/login` cùng mail) là pair được, không cần cấu hình mạng.
   - Offline? Thiết bị offline hiện `(offline)` trong `--list` — không teleport tới được, phải đợi online hoặc đi qua cloud.
5. **Auth và permissions trên cloud:**
   - Cloud session chạy bằng token account của bạn (quota của bạn) + policy của org (nếu SSO). Permissions local (`settings.json` máy A) KHÔNG tự sang máy B — mỗi máy giữ phanh riêng (xem bài 10).
   - Secret trong `.env` KHÔNG tự upload (bị deny mặc định) — sang cloud phải cấp lại env qua `/remote-env`.
6. **Khác gì `/mobile` và web thuần?**
   - `/teleport` = chuyển NƠI CHẠY (execution moves). `/mobile` = thêm ĐIỀU KHIỂN từ xa (execution ở yên, điện thoại chỉ là remote). Web thuần = mở session mới, không mang context đi.

### Sơ đồ teleport đi — về

```text
Terminal công ty (session abc, 47 msg, 3 file sửa dở)
  │ /teleport cloud
  ├─ Serialize transcript + diff chưa commit → upload
  ├─ Cloud eu-west spawn session abc' (transcript + diff bung ra)
  └─ Terminal → mirror mode (gõ đâu cũng chạy trên cloud)
      ... về nhà ...
Laptop nhà: mở link / gõ /teleport local
  ├─ Tải transcript mới nhất (gồm phần cloud chạy lúc bạn đi đường)
  ├─ Apply diff (conflict → hiện diff chọn tay)
  └─ Tiếp tục trong terminal nhà như chưa từng rời đi
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Chuyển gì? | Nơi chạy sau đó? | Dùng khi nào? |
|---|---|---|---|
| `/teleport` | Cả session (context + file dở) | Đổi nơi chạy | Đổi máy/đổi mạng |
| `/mobile` | Không chuyển (chỉ thêm remote) | Vẫn máy cũ | Ra ngoài, canh bằng điện thoại |
| `/remote-env` | Config môi trường remote | Remote | Cloud thiếu env/tool |
| Mở web mới | Không gì cả | Cloud mới tinh | Việc mới, không cần context cũ |

> Quy tắc ngón tay cái:
>
> - **Đổi chỗ ngồi → `/teleport`. Ngồi yên nhưng muốn ngó từ xa → `/mobile`. Sang chỗ mới mà thiếu đồ → `/remote-env`.**

---

## Ví dụ thực tế

### Kịch bản 1: Chiều ở công ty, tối về nhà làm tiếp (kinh điển)

```bash
# 17h55 ở công ty, task còn nửa:
git add -A && git commit -m "WIP: teleport checkpoint"
/teleport cloud
# → "Session live on cloud. Link: https://claude.ai/s/abc123"

# Về nhà, mở laptop:
/teleport local
# → "Pulled 12 new messages (cloud ran tests while you commuted)."
# → đọc kết quả test cloud chạy hộ lúc đi đường, làm tiếp
```

> Kết quả: 40 phút đi đường cloud chạy test hộ, về nhà chỉ đọc kết quả. Commit WIP trước teleport là để có phao nếu conflict diff.

### Kịch bản 2: Máy công ty yếu, đẩy task nặng lên cloud

```bash
# Refactor repo 2GB, laptop công ty quạt rú:
/teleport cloud
# → build/test chạy trên cloud (CPU/RAM khoẻ), terminal chỉ mirror log

# Xong việc, kéo code về:
/teleport local
git status  # → file đã về đủ, review diff rồi push
```

> Kết quả: laptop mát, task vẫn xong. Nhớ `/remote-env` cấp env trước nếu cloud build cần biến môi trường.

### Kịch bản 3: Demo cho sếp trên máy khác mà không setup lại

```bash
# Session đang chạy ngon trên máy mình:
/teleport pc-phong-hop
# → máy phòng họp (đã pair, online) mở đúng session, đúng context
# → demo luôn, không clone repo, không login lại, không giải thích context
```

> Cảnh báo: máy phòng họp là máy share — demo xong `/logout` (hoặc revoke device trên console) kẻo token ở lại.

### Kịch bản 4: Mạng công ty chặn — đi vòng qua cloud relay

```bash
# PC công ty và laptop cá nhân khác mạng, không thấy nhau:
/teleport --list
# → "laptop-nha (offline — different network)" — đừng cố trực tiếp

# Đi vòng:
# Trên PC công ty: /teleport cloud
# Trên laptop: mở link cloud / /teleport local
# → relay qua cloud, không cần cùng LAN/VPN
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào?

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Teleport qua WiFi công cộng không VPN | Transcript (có thể chứa secret/code nội bộ) đi qua mạng lạ | Dùng VPN; kiểm tra không có secret trong context trước khi teleport (`git grep -i password`) |
| Conflict diff local↔cloud, chọn bừa | Mất code 1 bên (ghi đè mù) | Commit WIP trước mọi teleport; khi conflict đọc diff từng file rồi mới chọn |
| Tưởng teleport mang cả `.env`/secret sang | Secret bị deny không upload → cloud build fail lạ | Cấp lại env phía cloud bằng `/remote-env`; không bao giờ paste secret vào chat để "mang sang" |
| Teleport sang máy share rồi quên | Token/device còn pair, người sau vào được session | Teleport xong việc thì unpair/revoke device trên console.web |
| Cloud region sai (data residency) | Code công ty EU chạy trên region US, vi phạm policy | `/teleport --list` xem region; org SSO thường ép region — hỏi admin trước |

### Tốn token/quota?

- Teleport tự thân không tốn token model (chỉ serialize + upload). Nhưng cloud session chạy tiếp thì tốn quota như thường + có thể phí compute cloud tuỳ plan.
- Upload diff lớn (repo GB) tốn băng thông + thời gian — commit + push git thay vì để teleport bê diff khổng lồ.

### Version / provider

- Teleport terminal↔cloud: v2.x. Bản cũ chỉ mirror read-only, không chuyển execution.
- Device pair nhiều máy: cần cùng account `/login`. Bedrock/Vertex: cloud relay có thể không khả dụng (tuỳ vendor) — check bài 02.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/teleport` + git WIP commit | Mọi lần teleport | Commit → teleport (có phao rollback) |
| `/teleport` + `/remote-env` | Sang cloud thiếu env | Teleport → remote-env cấp env → chạy |
| `/teleport` + `/mobile` | Đẩy lên cloud rồi canh bằng điện thoại | Teleport cloud → mobile pair → ra ngoài |
| `/teleport` + `/status` | Sang máy mới kiểm tra | Teleport → status (đúng acc? đúng model?) |
| `/teleport` + `/ide` | Về máy có IDE, gắn lại integration | Teleport local → ide connect lại |

Workflow chuẩn "tan làm không mất việc (3 phút)":

```bash
# 1. Checkpoint code
git add -A && git commit -m "WIP: before teleport"
# 2. Đẩy session lên cloud
/teleport cloud
# → copy link vào note điện thoại
# 3. Về nhà: mở link hoặc /teleport local
# 4. Kiểm tra
/status
git status
# 5. Làm tiếp
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/teleport cloud` treo ở `Uploading...` | Diff quá lớn (node_modules/build lọt vào) hoặc mạng yếu | `git status` xem diff; thêm `.gitignore` đúng; commit bớt rồi teleport lại; thử region gần hơn |
| Kéo về báo `conflict: 3 files` | Cả 2 bên cùng sửa lúc xa nhau | Đọc diff từng file (`git diff`), chọn tay; đừng `--force` mù |
| `--list` thấy device `(offline)` | Máy kia sleep/tắt/mất mạng | Bật máy kia hoặc đi vòng qua cloud relay |
| Sang cloud báo `missing env` hàng loạt | `.env` không được mang theo (đúng thiết kế) | `/remote-env` cấp lại; so `env diff` 2 bên |
| Mirror lag, gõ 5s mới hiện | Region xa hoặc VPN chậm | Chọn region gần (`--list` xem); tắt VPN thử; detach về local nếu lag quá |
| Teleport xong `/status` hiện sai account | Máy đích login acc khác | `/login` đúng acc trên máy đích trước khi teleport tới |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../mobile/README.md](../mobile/README.md) — điều khiển từ xa (không chuyển nơi chạy)
  - [../remote-env/README.md](../remote-env/README.md) — cấp env cho phía cloud sau teleport
  - [../login/README.md](../login/README.md) — 2 máy phải cùng account mới pair được
  - [../status/README.md](../status/README.md) — kiểm tra sau khi sang máy mới
  - [../exit/README.md](../exit/README.md) — exit máy cũ sau khi teleport xong
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — auth đa thiết bị
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — terminal/cloud/web khác nhau ra sao
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — permissions không đi theo teleport

> Mẹo 1 dòng: _commit WIP trước mọi teleport — 10 giây commit cứu cả buổi khi diff conflict._
