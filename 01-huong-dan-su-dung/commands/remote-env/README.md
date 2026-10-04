# /remote-env — Cấu hình môi trường cho session remote/cloud (env, region, runtime)

> Loại Built-in · Nhóm Remote · Nguy hiểm Có nhẹ (env chứa secret — set sai rò rỉ vào log/transcript; nhưng Không đụng code local)

`/remote-env` xem/sửa biến môi trường và cấu hình runtime của phía remote (cloud session sau `/teleport`, runner CI): `API_KEY`, `DATABASE_URL`, `NODE_ENV`, region... Local `.env` KHÔNG tự bay sang remote (bị deny) nên phải cấp lại ở đây. Hiểu `/remote-env` là hiểu "soạn vali cho chuyến đi" — teleport bê người, remote-env bê đồ.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/remote-env` | _(không có)_ | Liệt kê env remote hiện tại ( che secret: `sk-ant-****1234`) |
| `/remote-env set <K> <V>` | key, value | Đặt 1 biến remote |
| `/remote-env unset <K>` | key | Xoá 1 biến remote |
| `/remote-env diff` | flag | So sánh env local vs remote (thiếu/thừa gì) |
| `/remote-env region <tên>` | tên region | Đổi region cloud (eu-west, us-east...) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem remote đang có gì
/remote-env
# → "NODE_ENV=production · DATABASE_URL=****9f2c · REGION=eu-west"
```

```bash
# Dạng 2: cấp biến remote thiếu
/remote-env set DATABASE_URL "postgres://cloud-host/db?sslmode=require"
/remote-env set NODE_ENV production
```

```bash
# Dạng 3: so 2 bên xem lệch gì
/remote-env diff
# → "Missing on remote: STRIPE_KEY, SENTRY_DSN · Extra: DEBUG (chỉ local mới cần)"
```

```bash
# Dạng 4: xoá biến không cần + đổi region
/remote-env unset DEBUG
/remote-env region eu-west
```

---

## Cách nó hoạt động

### Cơ chế sâu: remote-env cấu hình remote thế nào?

1. **Vì sao phải cấu riêng? (local `.env` không bay sang)**
   - Teleport chỉ chuyển transcript + diff code. File `.env`/secret bị deny mặc định ( permissions `deny: Read(.env*)`) nên không bao giờ lọt vào gói upload.
   - Remote là môi trường MỚI (container/cloud mới): endpoint DB khác, key khác, region khác — copy y nguyên `.env` local sang có khi còn sai (trỏ nhầm DB local).
2. **Lưu ở đâu?**
   - Env remote lưu server-side, gắn với account + session/namespace (không nằm trong transcript, không vào git).
   - `set` ghi đè, `unset` xoá, có hiệu lực ngay cho lệnh kế tiếp trong session remote (không cần restart session, nhưng process đang chạy phải restart mới nhận env mới).
3. **`diff` so thế nào?**
   - Local: đọc `.env` + `env` hiện tại (che secret khi hiện). Remote: đọc store server-side. So key-by-key: thiếu (remote chưa có), thừa (remote có mà local không — có thể là rác cũ), khác value (cùng key khác value — thường là đúng vì endpoint khác nhau).
   - `diff` KHÔNG hiện full secret 2 bên — chỉ hiện `****đuôi` + trạng thái. Muốn xem full: mở file local tay (remote không cho xem full sau khi set — thiết kế chống lộ).
4. **Region để làm gì?**
   - Chọn nơi container cloud chạy: gần bạn thì nhanh, đúng jurisdiction công ty (EU data ở EU) thì hợp policy. Đổi region = session remote sau sẽ spawn ở đó (session đang chạy không tự nhảy — phải teleport lại).

### Sơ đồ teleport + remote-env

```text
Local (.env: DB=localhost, KEY=sk-test)
  │ /teleport cloud  (code + transcript đi, .env Ở LẠI — đúng!)
  └─▶ Cloud (trống env → build fail nếu không cấp)
        │ /remote-env diff   → "Missing: DATABASE_URL, STRIPE_KEY"
        │ /remote-env set ... → cấp endpoint CLOUD (không phải localhost!)
        └─▶ chạy ngon. Secret không bao giờ vào transcript/git.
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Env nào? | Dùng khi nào? |
|---|---|---|
| `/remote-env` | Phía remote/cloud | Sau teleport, trước khi chạy trên cloud |
| `.env` local + `export` | Máy local | Làm việc tại chỗ |
| `/config` (tab Env) | Default env cho session mới | Muốn template dùng lại nhiều lần |
| Secret manager (Vault/1Password) | Nguồn thật của secret | Production — remote-env chỉ trỏ tới, không paste key sống vào chat |

> Quy tắc ngón tay cái:
>
> - **Secret sống trong Vault. Local đọc qua `.env`. Remote cấp qua `/remote-env`. Không bao giờ paste key vào khung chat.**

---

## Ví dụ thực tế

### Kịch bản 1: Teleport lên cloud xong build fail vì thiếu env

```bash
# Vừa /teleport cloud, chạy build:
npm run build
# → "Error: DATABASE_URL is not defined"

# So rồi cấp:
/remote-env diff
# → "Missing on remote: DATABASE_URL, STRIPE_KEY"
# Lưu ý: endpoint CLOUD, đừng paste localhost sang:
/remote-env set DATABASE_URL "postgres://prod-cloud.internal/db?sslmode=require"
/remote-env set STRIPE_KEY "sk-live-**** (lấy từ Vault, xong xoá khỏi lịch sử shell)"
npm run build
# → ✓ pass
```

> Kết quả: cloud chạy bằng endpoint cloud. Sai lầm kinh điển là paste `.env` local sang — trỏ nhầm DB laptop từ cloud, fail lạ 30 phút mới ra.

### Kịch bản 2: Dọn rác env remote trước demo

```bash
/remote-env
# → "DEBUG=true · STRIPE_KEY=**** · OLD_API=**** (từ dự án cũ tháng trước)"
/remote-env unset DEBUG
/remote-env unset OLD_API
/remote-env diff
# → "In sync (2 keys). Clean ✓"
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| `set` secret rồi nó hiện trong transcript/log | Người xem lại session (share link) thấy key | Set xong `clear` màn hình; secret production lấy từ Vault thay vì paste tay; xoay key sau demo share |
| Paste nhầm endpoint local sang remote | Cloud trỏ về `localhost` của container → fail/confusion | `diff` trước; quy ước tên `*_LOCAL` vs `*_CLOUD` |
| Env remote cũ từ dự án trước còn sót | Chạy nhầm DB/key cũ | Đầu session remote: liệt kê + dọn trước khi chạy |

### Tốn token?

- Không. Quản trị env là thao tác control-plane.

### Version / provider

- `diff` + che secret: v2.x (bản cũ hiện full value — đừng share màn hình). Bedrock/Vertex: env lấy từ IAM/role.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/teleport` + `/remote-env diff` | Mọi lần lên cloud | Teleport → diff → set thiếu → chạy |
| `/remote-env` + `/status` | Kiểm tra region + runtime | Status xem region, remote-env xem env |

Workflow chuẩn "lên cloud không fail (2 phút)":

```bash
/teleport cloud
/remote-env diff
# → set cái Missing (endpoint CLOUD), unset rác
npm run build  # → mới chạy, đừng chạy mù trước khi diff
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `DATABASE_URL is not defined` trên cloud dù local có | `.env` không bay theo (đúng thiết kế) | `/remote-env set` lại phía remote |
| Set rồi mà process cũ không nhận | Process đang chạy giữ env cũ | Restart process/session remote sau khi set |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../teleport/README.md](../teleport/README.md) — bê session lên cloud trước rồi mới cấu env
  - [../mobile/README.md](../mobile/README.md) — canh session remote từ điện thoại
  - [../status/README.md](../status/README.md) — xem region/runtime remote hiện tại
  - [../config/README.md](../config/README.md) — template env mặc định cho session mới
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — auth và env theo provider
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — local vs cloud khác nhau chỗ nào
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — vì sao `.env` bị deny khi teleport

> Mẹo 1 dòng: _teleport xong việc đầu tiên là `/remote-env diff` — đừng chạy build mù khi chưa biết remote thiếu gì._
