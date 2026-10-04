# /logout — Đăng xuất: xoá token local, cắt session khỏi tài khoản

> Loại Built-in · Nhóm Auth · Nguy hiểm Có nhẹ (mất token local — session đang chạy đứt auth, cloud session pair cùng account cũng phải login lại; nhưng Không mất code/history trên máy)

`/logout` đăng xuất tài khoản hiện tại: xoá access + refresh token khỏi `~/.claude/`, session đang mở mất quyền gọi model ngay lập tức. Dùng khi đổi tài khoản, trả máy share, hoặc nghi token lộ. Hiểu `/logout` là hiểu "rút chìa khoá" — ngược hoàn toàn với `/login`.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/logout` | _(không có)_ | Đăng xuất profile đang active (xoá token của nó) |
| `/logout --all` | flag | Đăng xuất TẤT CẢ profiles trên máy (work + personal...) |
| `/logout --account <tên>` | tên profile | Chỉ đăng xuất 1 profile, giữ lại các profile khác |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: đăng xuất thông thường
/logout
# → "Signed out of ban@gmail.com. Run /login to sign in again."
```

```bash
# Dạng 2: máy có 2 profile, chỉ thoát cái công ty
/logout --account work
# → personal vẫn giữ, work phải /login lại mới dùng
```

```bash
# Dạng 3: trả laptop / nghi lộ token — thoát sạch
/logout --all
```

---

## Cách nó hoạt động

### Cơ chế sâu: logout xoá gì, giữ lại gì?

1. **Xoá gì?**
   - Xoá `access_token` + `refresh_token` của profile active khỏi `~/.claude/accounts/` (hoặc toàn bộ với `--all`).
   - Gọi API revoke (nếu còn mạng): báo server vô hiệu hoá refresh token để token cũ không dùng lại được.
   - Session đang mở: request kế tiếp trả `401` → CLI hiện "Not authenticated. Run /login".
2. **Giữ lại gì (quan trọng để đỡ sợ)?**
   - History chat trên máy (`~/.claude/history/`) KHÔNG xoá — login lại vẫn `/resume` được.
   - `settings.json`, `CLAUDE.md`, rules, memory, MCP config: giữ nguyên (đó là config, không phải auth).
   - Code trong repo: không đụng.
3. **Cloud/mobile pair thì sao?**
   - Session cloud (`/teleport`, web) dùng token riêng — logout local không đá cloud ra, và ngược lại. Muốn đá hết: logout từng nơi + revoke trên console.web (mục Sessions/Devices).
4. **Khác xoá tay file credentials không?**
   - `/logout` = xoá file + revoke server-side. Xoá tay chỉ xoá local, token cũ về lý thuyết vẫn sống tới hết hạn. Nên luôn `/logout` thay vì `rm`.

### Sơ đồ logout

```text
/logout [--account X | --all]
  ├─ Tìm token profile(s) trong ~/.claude/accounts/
  ├─ Gọi revoke lên server (best-effort, offline vẫn xoá local)
  ├─ Xoá file token local
  └─ Session hiện tại → 401 ở request kế → nhắc /login
  Giữ: history, settings, CLAUDE.md, rules, code
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Xoá gì? | Dùng khi nào? |
|---|---|---|
| `/logout` | Token auth | Đổi acc, trả máy, nghi lộ |
| `/clear` | Context chat hiện tại (không đụng auth) | Bắt đầu việc mới, vẫn là mình |
| `/exit` | Thoát CLI (giữ token, lần sau vào vẫn là mình) | Nghỉ làm, không cần đá auth |
| Xoá `~/.claude/` tay | Xoá cả auth + history + settings | Muốn reset trắng (nguy hiểm, backup trước) |

> Quy tắc ngón tay cái:
>
> - **Hết việc trong ngày → `/exit`. Hết vai (đổi acc/trả máy) → `/logout`. Muốn quên việc đang làm → `/clear`.**

---

## Ví dụ thực tế

### Kịch bản 1: Trả laptop mượn của đồng nghiệp

```bash
# Làm xong, trước khi trả máy:
/logout --all
# → "Signed out of all accounts (2 profiles)."

# Kiểm tra chắc chắn:
/status
# → "Not signed in."
```

> Kết quả: chủ máy login acc họ vào là sạch, không dính quota/history auth của bạn (history chat local vẫn còn — muốn sạch hẳn thì xoá `~/.claude/history/` tay).

### Kịch bản 2: Đổi từ acc cá nhân sang acc công ty

```bash
# Đang ở personal, cần sang work:
/logout
/login --account work --sso
/status
# → "ban@congty.vn (Team)" — đúng mới làm tiếp
```

> Kết quả: không lẫn quota. Sai lầm phổ biến là `/login` đè mà không `/logout` — máy 1 profile thì login mới ghi đè, nhưng explicit logout/login rõ ràng hơn khi audit.

---

## Rủi ro & lưu ý

### Logout mất gì, không mất gì?

| Tình huống | Thực tế | Cách tránh sốc |
|---|---|---|
| Session đang chạy dở task dài | Request kế tiếp 401, task đứt giữa chừng | Xong task (hoặc checkpoint) rồi hãy logout |
| Tưởng logout xoá luôn history nhạy cảm trên máy share | History `~/.claude/history/` vẫn còn, người sau `/resume` đọc được | Máy share: logout + xoá history tay (`rm -rf ~/.claude/history/*`) |
| Logout local nhưng cloud session còn sống | Token cloud riêng — kẻ cầm link session cloud vẫn dùng | Vào console.web revoke sessions/devices; đổi pass nếu nghi lộ nặng |
| `--all` trên máy có 3 profile | Cả 3 bay, mai login lại từng cái | Dùng `--account <tên>` khi chỉ muốn thoát 1 |

### Tốn token?

- Không tốn token model. Revoke call là 1 request HTTP nhẹ.

### Version / provider

- `--account`/`--all`: v2.x (đa profile). Bản cũ `/logout` là thoát tất cả (vì chỉ có 1).
- Bedrock/Vertex: `/logout` không ý nghĩa (auth qua IAM) — xoay credentials bên AWS/GCP.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/logout` + `/login` | Đổi tài khoản | Logout cũ → login mới → status kiểm tra |
| `/logout` + `/status` | Xác minh đã thoát sạch | Logout → status phải báo Not signed in |
| `/logout` + đổi pass console | Nghi lộ token | Logout local → revoke console → login lại |

Workflow chuẩn "nghỉ việc, bàn giao máy (5 phút)":

```bash
/logout --all
# + xoá history nếu máy có chat nhạy cảm:
# rm -rf ~/.claude/history/*
/status  # → Not signed in mới yên tâm trả máy
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/logout` xong `/status` vẫn hiện đã login | Có nhiều profile, mới logout 1 cái | `/logout --all` hoặc logout đúng `--account` đang active |
| Logout khi offline báo revoke failed | Không gọi được server để revoke | Không sao — token local đã xoá; có mạng thì login lại 1 lần rồi logout lại để revoke sạch |
| Login lại ngay mà báo `rate limited` | Logout/login liên tục触发 chống abuse | Đợi 2-5 phút rồi login lại |
| Cloud session vẫn chạy sau logout local | Token riêng như đã nói | Revoke trên console.web, không phải lỗi CLI |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../login/README.md](../login/README.md) — đăng nhập lại sau logout
  - [../status/README.md](../status/README.md) — xác minh đã thoát sạch chưa
  - [../exit/README.md](../exit/README.md) — thoát CLI nhưng giữ token (nhẹ hơn logout)
  - [../config/README.md](../config/README.md) — default account sau khi logout 1 profile
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — vòng đời xác thực
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — auth khác nhau mỗi bề mặt
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — policy org còn áp sau khi login lại

> Mẹo 1 dòng: _logout chỉ rút chìa — muốn đốt nhà (xoá history máy share) phải làm tay thêm._
