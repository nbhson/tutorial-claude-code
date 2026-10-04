# /statusline — Thanh trạng thái tuỳ biến: acc, model, dir, quota luôn trên màn hình

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ hiển thị — nhưng Có nhẹ nếu statusline chạy script ngoài lạ mà bạn paste mù từ internet)

`/statusline` cấu hình dòng thông tin nhỏ hiện thường trực (dưới prompt hoặc chân terminal): `work · default · /repo/api · 84% cache · 132k` — khỏi gõ `/status` 20 lần/ngày. Hiểu `/statusline` là hiểu "dán taplo lên kính lái" — `/status` là mở nắp capo xem, statusline là đồng hồ luôn trước mặt.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/statusline` | _(không có)_ | Xem + sửa cấu hình statusline (picker thành phần) |
| `/statusline set <mẫu>` | template string | Đặt mẫu hiển thị (ví dụ `{acc} · {model} · {cwd}`) |
| `/statusline exec <lệnh>` | shell command | Hiển thị output của lệnh ngoài (git branch, quota...) |
| `/statusline off` | flag | Tắt (về gõ `/status` tay) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: bật mẫu gọn khuyên dùng
/statusline set "{acc} · {model} · {cwd} · cache {cache} · {tokens}"
# → mỗi prompt xong hiện: "work · default · /repo/api · cache 84% · 132k"
```

```bash
# Dạng 2: thêm git branch (lệnh ngoài)
/statusline exec "git branch --show-current"
# → "work · default · /repo/api · ⎇ fix-auth · 132k"
```

```bash
# Dạng 3: xem cấu hình hiện tại
/statusline
# → "Template: ... · Exec: ... (0.2s) · Enabled: yes"
```

```bash
# Dạng 4: lag quá, tắt
/statusline off
```

---

## Cách nó hoạt động

### Cơ chế sâu: statusline render thế nào?

1. **Template + biến:** `{acc}`, `{model}`, `{cwd}`, `{cache}`, `{tokens}`, `{quota}`, `{roots}`, `{version}`... CLI thay biến bằng giá trị session hiện tại sau mỗi lệnh — rẻ vì đọc từ memory, không gọi API.
2. **`exec` — con dao 2 lưỡi:** cho chạy lệnh shell ngoài (git branch, số file đổi...) rồi nhét output vào. Mỗi prompt render 1 lần = mỗi lần chạy lệnh đó. Lệnh nặng (`git status` repo GB, `npm ...`) là mỗi Enter chậm thêm 1-2s.
3. **Timeout + cache:** exec có timeout (mặc định ~1-2s, quá là bỏ, hiện `…`). Lệnh chậm thì cache theo giây (ví dụ quota 60s refresh 1 lần) thay vì mỗi prompt.
4. **Hiện account — chống nhầm acc:** thành phần đáng tiền nhất là `{acc}`: nhìn 1 cái biết đang work hay personal, khỏi `/status`. Team nên để `{acc}` đầu tiên bắt buộc.
5. **Lưu ở đâu?** Local settings — theo máy, không commit (mẫu chứa thói quen cá nhân). Teleport không mang theo.

### Mẫu khuyên dùng (copy-paste)

```bash
# Gọn, đủ, rẻ (không exec ngoài — render tức thì):
/statusline set "{acc} · {model} · {cwd} · {cache} · {tokens}"

# Đủ hơn + git branch (exec nhẹ, <0.1s):
/statusline set "{acc} · {model} · {cwd} · ⎇ {exec:git-branch} · {tokens}"
/statusline exec "git-branch: git branch --show-current 2>/dev/null || echo -"

# Team: ép acc + quota lên đầu (chống chạy lố):
/statusline set "[{acc} {quota}] {model} · {cwd}"
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Hiện khi nào? | Dùng khi nào? |
|---|---|---|
| `/statusline` | Mọi prompt (thường trực) | Muốn taplo luôn trước mặt |
| `/status` | Khi gõ (chi tiết) | Cần full snapshot + quota chi tiết |
| `/theme` | Màu sắc | Nhìn không rõ |

> Quy tắc ngón tay cái:
>
> - **`/statusline` để liếc (5 biến rẻ). `/status` để khám (full chi tiết). Cả 2 cùng bật, không thay nhau.**

---

## Ví dụ thực tế

### Kịch bản 1: Chống chạy nhầm acc cả ngày (đáng tiền nhất)

```bash
/statusline set "[{acc}] {model} · {cwd}"
# Sáng: "[work] default · /repo" ✓
# Trưa vọc side-project xong quên đổi: "[personal] default · /repo" ← thấy ngay!
# → /login --account work trước khi push code công ty bằng quota túi
```

> Kết quả: 1 dòng statusline cứu nhiều tiền hơn mọi mẹo tiết kiệm token khác.

### Kịch bản 2: Statusline lag mỗi Enter 2s — tìm và diệt exec nặng

```bash
# Triệu chứng: Enter xong 2s mới hiện prompt
/statusline
# → "Exec: deploy-status (1.8s) ← THỦ PHẠM (gọi API ngoài mỗi prompt!)"

# Fix: bỏ exec nặng, cache lại hoặc xoá
/statusline exec "deploy-status: "
# → về render tức thì. Quy tắc: exec chỉ lệnh <0.2s (git branch, pwd...).
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Paste mẫu statusline từ internet có `exec curl ...` | Chạy lệnh lạ mỗi prompt (rò rỉ path/acc ra ngoài) | Đọc kỹ mọi `exec` trước khi set; chỉ exec lệnh mình viết |
| Exec nặng (API, build) mỗi prompt | Lag + tốn quota ngoài ý muốn | Exec <0.2s; cái nặng để script cron riêng |
| Statusline dài 200 ký tự | Chiếm màn hình, log khó đọc | Tối đa 5-6 biến; chi tiết để `/status` |

### Tốn token?

- Không. Statusline render local, không vào prompt gửi model.

### Version / provider

- Template cơ bản mọi bản v2. `exec` + biến quota/roots: bản mới hơn (thiếu biến nào thì nó hiện trống — update CLI).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/statusline` + `/status` | Liếc + khám | Liếc thấy lạ → status full |
| `/statusline` + `/theme` | Taplo dễ đọc | Theme tương phản + mẫu gọn |
| `/statusline {acc}` + đa acc | 2 profile | Acc luôn trước mặt, khỏi nhầm |

Workflow chuẩn "taplo 2 phút": set mẫu gọn (acc đầu) → thêm git branch → test 3 prompt → xong.

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Biến hiện trống (`{quota}` = rỗng) | Bản CLI cũ chưa có biến đó | Update CLI; bỏ biến đó khỏi mẫu tạm |
| Mỗi Enter chậm 1-2s | Exec nặng | `/statusline` xem exec nào chậm → xoá/cache |
| Sang máy mới mất statusline | Local scope không đi theo | Set lại (copy mẫu từ note cá nhân) |
| `exec` báo lỗi đỏ mỗi prompt | Lệnh fail ngoài repo git... | Thêm `2>/dev/null \|\| echo -` vào cuối lệnh |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../status/README.md](../../auth-settings/status/README.md) — bản full khi cần khám chi tiết
  - [../theme/README.md](../../auth-settings/theme/README.md) — màu cho taplo dễ đọc
  - [../config/README.md](../../auth-settings/config/README.md) — file settings chứa mẫu statusline
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md) — setup lần đầu
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — statusline mỗi bề mặt
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — hiện acc để khỏi chạy nhầm policy

> Mẹo 1 dòng: _`{acc}` để đầu statusline — dòng chữ nhỏ đó đáng giá hơn mọi cảnh báo._
