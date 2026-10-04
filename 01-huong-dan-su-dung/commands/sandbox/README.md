# /sandbox — Hộp cát: dependency status, chạy thử cách ly, nổ thì không sao

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chính nó là phanh — chạy trong cát thì nổ cũng không văng ra ngoài; nhưng Có nếu bạn tin "đã sandbox" rồi chạy bừa lệnh phá hoại mà sandbox cấu sai)

`/sandbox` quản lý môi trường chạy cách ly: kiểm tra dependency status (cái gì thiếu/hỏng trong cát), chạy lệnh thử trong cát trước khi chạy thật, xoá cát làm lại khi bẩn. Hiểu `/sandbox` là hiểu "phòng thí nghiệm có kính chống nổ" — thuốc mới thử trong này, nổ thì lau kính chứ không sập nhà.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/sandbox` | _(không có)_ | Hiện trạng thái: bật/tắt, engine, dependency status |
| `/sandbox on` | flag | Bật chế độ chạy cách ly cho lệnh nguy hiểm |
| `/sandbox off` | flag | Tắt (chạy trực tiếp — chỉ khi đã tin) |
| `/sandbox status` | action | Kiểm tra dependencies trong cát (node? python? docker? network?) |
| `/sandbox reset` | action | Xoá cát làm lại từ sạch (khi nghi nhiễm bẩn) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem cát đang ra sao
/sandbox
# → "Enabled: on (engine: container) · Deps: node 20 ✓ · python 3.11 ✓ · network: blocked ✓"
```

```bash
# Dạng 2: kiểm tra sâu dependencies trước task lạ
/sandbox status
# → "node ✓ · npm ✓ · docker ✓ · git ✓ · network: blocked · mounts: /repo (ro)..."
```

```bash
# Dạng 3: cát bẩn (cài thử 10 lib lạ) — đập đi xây lại
/sandbox reset
# → "Sandbox reset to clean image."
```

---

## Cách nó hoạt động

### Cơ chế sâu: sandbox + dependency status là gì?

1. **Sandbox là gì (3 engine thường gặp)?**
   - **Container (docker/podman):** lệnh chạy trong container dùng chung kernel, filesystem riêng, network chặn/selective. Nặng nhất, cách ly tốt nhất.
   - **Userland (bubblewrap/firejail/macOS sandbox):** nhẹ, không cần docker — chặn ghi ngoài `/repo`, chặn network theo rule. Mặc định trên nhiều máy dev.
   - **Dry-run/log-only:** không cách ly thật, chỉ hiện "lệnh này SẼ làm gì" để duyệt. Yếu nhất — đừng nhầm với 2 cái trên.
   - `/sandbox` hiện đang dùng engine nào — tin engine nào thì phải biết mình đang ở engine nào.
2. **Dependency status kiểm tra gì?**
   - Toolchain trong cát: `node? npm? python? pip? git? docker? make?` — thiếu là lệnh fail với lỗi lạ ("command not found" trong cát dù ngoài máy có).
   - Mounts: thư mục nào của máy thật được gắn vào cát (`/repo` read-write? read-only? `/tmp` có không? home có bị gắn nhầm không?).
   - Network: blocked (an toàn nhất — lệnh không gọi ra ngoài được) / allowlist (chỉ npm registry...) / open (gần như không cát gì về mạng).
   - So sánh trong vs ngoài: `node 20 ngoài, node 18 trong` → test pass trong cát chưa chắc pass ngoài.
3. **Khi nào lệnh vào cát?**
   - Sandbox ON: lệnh Bash/File nguy hiểm (theo permissions) tự chạy trong cát. Lệnh đọc (Read/Glob/Grep) thường chạy thẳng (đọc thì sợ gì).
   - Kết quả trả về như thường — bạn không cảm nhận được trừ khi lệnh cần thứ cát không có (network, device, secret ngoài).
4. **Reset khi nào?**
   - Cát là stateful (cài lib, ghi file rác trong cát giữ lại). Thử 10 thứ lạ → cát bẩn → kết quả sau không còn đáng tin → `reset` về image sạch rồi thử lại cho công bằng.

### Sơ đồ sandbox on/off

```text
/sandbox on (engine: container, network: blocked, mounts: /repo rw)
  │ Bash(npm install lib-la) → chạy TRONG container
  ├─ lib độc ghi /etc/passwd? → ghi vào container, máy thật an toàn
  ├─ lib gọi về server lạ? → network blocked, fail ngay + log
  └─ xong: kết quả về, rác ở lại container (/sandbox reset khi bẩn)
OFF = chạy thẳng trên máy (nhanh, nhưng nổ là văng thật)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Cách ly? | Dùng khi nào? |
|---|---|---|
| `/sandbox` | Có (tuỳ engine) | Chạy thử đồ lạ, lib mới, script chưa đọc |
| Permissions deny/ask | Không cách ly (chỉ cho/chặn) | Luật cho/chặn chung (bài 10) |
| Docker tay | Có (tự quản) | Muốn kiểm soát image chi tiết |
| `/teleport` cloud | Môi trường khác (không phải cát) | Đổi máy, không phải thử nổ |

> Quy tắc ngón tay cái:
>
> - **Đồ lạ (lib mới, script tải về) → sandbox ON + đọc lướt trước. Đồ nhà (test repo mình) → OFF cho nhanh.**

---

## Ví dụ thực tế

### Kịch bản 1: Cài thử lib lạ không sợ bẩn máy

```bash
/sandbox status
# → "node 20 ✓ · network: blocked · mounts: /repo (rw)"
/sandbox on
# → chạy thử:
npm install lib-la-chua-ai-nghe
npm test
# → lib gọi về server lạ? network blocked → fail + log, máy thật an toàn
# → ưng thì tắt cát cài thật, không ưng thì /sandbox reset
```

> Kết quả: thử 5 lib lạ trong ngày mà máy vẫn sạch. Không cát mà `npm install` mù là rước mã độc tận cửa.

### Kịch bản 2: Cát bẩn — reset trước khi kết luận "test fail"

```bash
# Sáng cài 3 lib thử, chiều test fail lạ:
/sandbox status
# → "installed extra: lib-a, lib-b, lib-c (dirty since 9:41)"
/sandbox reset
npm test
# → pass ✓ — hoá ra fail do lib thử buổi sáng, không phải code mình
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Tin "đã sandbox" rồi chạy `rm -rf /` bừa | Mount `/repo` rw + engine yếu = vẫn mất code thật; dry-run thì không cản gì | Đọc `status`: engine gì? mounts nào? network nào? rồi mới tin |
| Network open mà tưởng blocked | Lệnh trong cát vẫn gọi ra ngoài (rò rỉ key, tải mã độc) | `status` xác minh network; đồ lạ phải blocked/allowlist |
| Toolchain trong/ngoài lệch (node 18 vs 20) | Pass trong cát, fail ngoài thật (hoặc ngược) | Đồng bộ version; ghi vào baseline team |
| Secret trong cát (mount cả `~/.aws`) | Lệnh độc trong cát đọc được key thật | Mount tối thiểu (chỉ `/repo`); secret không vào cát bao giờ |

### Tốn token?

- Không đáng kể. Container tốn RAM/disk máy (image GB) — dọn image cũ định kỳ.

### Version / provider

- Engine container cần docker/podman cài sẵn. Userland theo OS (macOS sandbox profile riêng). Không có engine? `status` báo và rơi về ask (hỏi tay từng lệnh).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/sandbox` + `/doctor` | Cát + khám | Doctor khám config, sandbox thử chạy |
| `/sandbox on` + lib mới | Mọi lib lạ | Bật → cài thử → ưng thì tắt cài thật |
| `/sandbox reset` + test fail lạ | Nghi nhiễm | Reset → test lại cho công bằng |
| `/sandbox` + permissions ask | 2 lớp phanh | Cát chặn nổ, ask chặn bấm nhầm |

Workflow chuẩn "thử đồ lạ (5 phút)": `status` (cát sạch? engine gì?) → `on` → chạy thử → ưng giữ/không ưng `reset`.

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `command not found` trong cát dù ngoài có | Toolchain cát thiếu | `status` xem thiếu gì; cài vào image cát hoặc chạy ngoài |
| Lệnh cần mạng fail trong cát | Network blocked (đúng thiết kế) | Allowlist registry cần thiết, hoặc chạy ngoài khi đã tin |
| File ghi trong cát "mất" sau reset | Reset xoá state cát | Copy kết quả ra `/repo` (mount chung) trước khi reset |
| Cát chậm gấp 5 lần | Engine container trên máy yếu + mount lớn | Chỉ cát lệnh lạ; lệnh nhà chạy thẳng (off) |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../config/README.md](../config/README.md) — bật/tắt default sandbox trong settings
  - [../remote-env/README.md](../remote-env/README.md) — env trong cát khác env remote
  - [../teleport/README.md](../teleport/README.md) — đổi môi trường (không phải cách ly)
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — cài engine sandbox (docker...)
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — sandbox mỗi bề mặt
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — permissions + sandbox: 2 lớp phanh (đọc kỹ)

> Mẹo 1 dòng: _đồ lạ vào cát trước khi vào máy — và đọc `/sandbox status` trước khi tin cái cát._
