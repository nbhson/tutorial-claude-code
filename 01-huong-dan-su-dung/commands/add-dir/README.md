# /add-dir — Mở thêm thư mục vào session: đa root, so sánh chéo, mở rộng attack surface

> Loại Built-in · Nhóm Settings · Nguy hiểm Có (mỗi dir thêm vào là thêm CLAUDE.md + hooks + MCP lạ vào context — càng nhiều dir, attack surface càng rộng; trust từng cái như `/cd`)

`/add-dir` gắn thêm 1 (hoặc nhiều) thư mục vào session hiện tại mà KHÔNG bỏ dir cũ: làm ở `api` nhưng vẫn đọc được `shared`, so sánh 2 repo cạnh nhau, sửa bug xuyên package. Hiểu `/add-dir` là hiểu "mở thêm phòng" — nhà cũ vẫn giữ, nhà mới thêm vào. Khác `/cd` (dọn sang phòng mới, bỏ phòng cũ).

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/add-dir <path>` | 1 đường dẫn | Thêm 1 thư mục vào session (có trust prompt nếu lạ) |
| `/add-dir <p1> <p2>...` | nhiều path | Thêm nhiều thư mục 1 lần |
| `/add-dir --list` | flag | Liệt kê các dir đang gắn (root + đã thêm) |
| `/add-dir --remove <path>` | path | Gỡ 1 dir đã thêm (unload config của nó) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: đang ở api, mở thêm shared để đọc lib
/add-dir ../shared
# → "Added /repo/packages/shared · loaded its CLAUDE.md + rules"
```

```bash
# Dạng 2: so sánh 2 repo cạnh nhau
/add-dir ~/repo-cu ~/repo-moi
```

```bash
# Dạng 3: xem đang gắn những gì
/add-dir --list
# → "Roots: /repo/packages/api (main) · /repo/packages/shared (added)"
```

```bash
# Dạng 4: xong việc, gỡ cho nhẹ context
/add-dir --remove /repo/packages/shared
# → "Removed. Its rules unloaded."
```

---

## Cách nó hoạt động

### Cơ chế sâu: thêm dirs + CLAUDE.md trong đó khi nào load?

1. **Multi-root là gì?**
   - Session bình thường single-root (1 cwd). `/add-dir` biến nó thành multi-root: tools (Read/Edit/Glob/Grep/Bash) được phép chạm vào TẤT CẢ roots đã gắn. Đường dẫn hiện tuyệt đối hoặc prefix theo root để không lẫn.
   - Dir chính (cwd từ `/cd`) vẫn là "nhà chính": lệnh Bash không path chạy ở đó; dir thêm là "nhà phụ": chỉ chạm tới khi gọi explicit.
2. **CLAUDE.md trong dir thêm — KHI NÀO load? (điểm hay bị hiểu sai)**
   - Mặc định: CLAUDE.md/rules của dir được add-dir **CÓ load** vào context (như `/cd` nhưng cộng thêm, không thay thế).
   - Ngoại lệ quan trọng: ở một số bản/cấu hình, CLAUDE.md của dir phụ chỉ load khi có **env flag** bật (ví dụ `CLAUDE_MULTI_ROOT_MD=1` hoặc flag tương tự tuỳ bản). Không thấy rules dir phụ áp? Kiểm tra 2 chỗ: (a) env flag đã bật chưa, (b) `/status` xem roots nào đã load config.
   - Vì sao phải có flag? Để tránh "ô nhiễm context": add 5 dir là 5 CLAUDE.md đổ vào prompt, tốn token + mâu thuẫn luật. Flag = bạn xác nhận "tôi chấp nhận tốn thêm".
   - Thực hành: add-dir xong `/status` kiểm tra config nào đã load. Chưa load mà cần? Bật env flag rồi add lại (hoặc restart session).
3. **Trust từng dir (không trust gộp):**
   - Mỗi dir thêm đều qua trust prompt + Cd permission rules riêng (giống `/cd`, bản ≥2.1.169). Dir lạ trong 3 dir add cùng lúc? 1 cái Skip là 1 cái làm chay, 2 cái còn lại vẫn nạp — trust tính theo từng dir.
4. **Attack surface mở rộng thế nào?**
   - 1 dir = 1 bộ CLAUDE.md + hooks + MCP + settings có thể độc. Add 4 dir lạ = nhân 4 nguy cơ injection. Hooks của dir phụ CÓ chạy (khi matcher khớp file trong dir đó) — không phải "thêm cho vui".
   - Quy tắc: chỉ add dir mình hiểu (repo team, lib dùng chung). Dir tải từ internet: đọc chay trước như `/cd`, đừng add mù.
5. **Token/context cost:**
   - Mỗi dir thêm ≈ +CLAUDE.md của nó vào mọi request (cho tới khi remove). Add 3 dir mỗi cái 100 dòng = +300 dòng/request. Xong việc `--remove` ngay — đừng để "cho tiện".
6. **Xung đột config giữa các roots?**
   - Cùng key settings ở 2 roots: dir chính (cwd) thắng dir phụ. Rules mâu thuẫn ("dùng npm" vs "dùng pnpm"): cả 2 cùng load, model bối rối — tự resolve bằng rule scoped hẹp hơn (file trong dir nào theo luật dir đó).

### Sơ đồ add-dir vs /cd

```text
/cd packages/api          → roots: [api] (chuyển hẳn, shared mất)
/add-dir ../shared        → roots: [api (main), shared (added)]
  ├─ Read ../shared/lib.ts ✓ (chạm được)
  ├─ Bash vẫn chạy ở api (main)
  ├─ Context: CLAUDE.md api + CLAUDE.md shared (tốn hơn, biết nhiều hơn)
  └─ /add-dir --remove ../shared → về [api], nhẹ lại
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Dir cũ? | Số root | Tốn context | Dùng khi nào? |
|---|---|---|---|---|
| `/add-dir` | Giữ | Nhiều | + theo mỗi dir | Cần 2+ chỗ cùng lúc |
| `/cd` | Bỏ | 1 | Đổi (không cộng) | Sang hẳn chỗ mới |
| Symlink dir phụ vào main | Giữ (giả) | 1 (lừa) | Không rõ ràng | Đừng — tool confuse, trust bypass |
| Mở 2 session | Mỗi session 1 | 1+1 | ×2 session | Muốn cách ly hẳn (an toàn nhất với dir lạ) |

> Quy tắc ngón tay cái:
>
> - **2 dir tin tưởng cần nhau → `add-dir`. 1 dir lạ cần xem → session riêng (đừng add vào session chính).**

---

## Ví dụ thực tế

### Kịch bản 1: Sửa bug xuyên api ↔ shared (kinh điển monorepo)

```bash
# Đang ở api, stack trace chỉ vào shared/lib.ts:
/add-dir ../shared
# → "Added shared · CLAUDE.md loaded (env flag on)"

# Đọc chéo:
# Read packages/shared/src/lib.ts → thấy hàm sai
# Edit ở shared, test ở api (Bash vẫn chạy main=api)
npm test
# → pass. Xong gỡ cho nhẹ:
/add-dir --remove ../shared
```

> Kết quả: 1 session sửa 2 package, không mất context bên nào. Quên `--remove` là mọi request sau tốn thêm ~2k token vô ích.

### Kịch bản 2: So sánh repo cũ vs mới khi migrate

```bash
# Đang ở repo mới, muốn đối chiếu cách repo cũ làm:
/add-dir ~/repo-cu
# → Glob 2 bên cùng pattern, diff cách tổ chức
# Hỏi Claude: "so sánh auth flow repo-cu vs hiện tại, cái nào an toàn hơn?"
# → trả lời được vì đọc cả 2 roots

# Xong migrate: --remove ngay (repo-cu to, giữ lâu tốn context)
/add-dir --remove ~/repo-cu
```

> Kết quả: migrate có đối chiếu, không phải mở 2 cửa sổ copy-paste.

### Kịch bản 3: Dir phụ không load CLAUDE.md — bật env flag

```bash
/add-dir ../lib-chung
# → "Added." Nhưng hỏi luật của lib-chung, Claude bảo "không biết"?

# Kiểm tra:
/status
# → "Roots: api (config loaded) · lib-chung (files only, CLAUDE.md NOT loaded — needs env flag)"

# Fix: bật flag rồi add lại (tên flag tuỳ bản, xem release notes):
export CLAUDE_MULTI_ROOT_MD=1
# restart session hoặc:
/add-dir --remove ../lib-chung
/add-dir ../lib-chung
# → "CLAUDE.md loaded ✓" — giờ hỏi luật mới trả lời được
```

> Kết quả: hiểu đúng "added ≠ loaded". Luôn `/status` sau add-dir để biết config nào thực sự vào context.

### Kịch bản 4: Add dir lạ 1 cách an toàn (cách ly thay vì tin)

```bash
# Đồng nghiệp gửi lib lạ nhờ review:
# CÁCH SAI: /add-dir ~/lib-la  (luật lạ đổ vào session chính đang làm dự án thật)

# CÁCH ĐÚNG: session riêng
# Mở terminal mới → claude → /cd ~/lib-la → Skip trust → đọc chay
# Review xong, quay lại session chính, chỉ add khi đã tin:
# /add-dir ~/lib-la  (giờ đã trust & remember)
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (mở rộng attack surface)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Add 3-4 dir lạ cùng lúc, Yes trust hết | 1 trong 4 có CLAUDE.md injection là cả session nhiễm (mọi câu trả lời sau đều lệch) | Trust từng cái; dir lạ review ở session riêng trước |
| Hooks dir phụ tự chạy mà không biết | Hook `on-Edit` của lib lạ chạy script độc mỗi lần bạn sửa file trong đó | Trust prompt đọc kỹ mục hooks; `--list` + xem settings từng root |
| Quên `--remove`, session ngày càng nặng | Context phình (5 CLAUDE.md), tốn token, luật mâu thuẫn nhau | Xong việc remove ngay; `/status` định kỳ xem roots đang gắn |
| Add dir chứa secret (`~/.aws`, data khách hàng) | Session đọc + có thể trích dẫn secret vào câu trả lời/share log | Không add dir nhạy cảm; Cd deny rules chặn trước (≥2.1.169) |
| Tưởng added là loaded (env flag) | Luật dir phụ không áp, model làm sai mà tưởng đã "đọc rồi" | `/status` xác minh loaded; bật flag nếu cần |

### Tốn token?

- Có, và cộng dồn: mỗi dir thêm ≈ +CLAUDE.md của nó mỗi request. 3 dir × 100 dòng ≈ +300 dòng/request ≈ vài k token.
- `--remove` là cách tiết kiệm duy nhất (không có "tạm ẩn").

### Version / provider

- Multi-root add-dir: v2.x. Bản cũ không có — phải mở nhiều session.
- Env flag cho CLAUDE.md dir phụ: tuỳ bản (check release notes bản bạn dùng; tên flag có thể khác).
- Cd rules + Tab badges áp cho add-dir như `/cd` (≥2.1.169 / ≥2.1.206).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `add-dir` + `--remove` | Mọi lần dùng | Add → việc xong → remove (không để qua đêm) |
| `add-dir` + `/status` | Xác minh loaded gì | Add → status (files only hay config loaded?) |
| `add-dir` + `/cd -` | 2 dir tin tưởng nhảy qua lại | Cd chính + add phụ, toggle khi cần |
| `add-dir` + `/doctor` | Dir mới thêm có bệnh gì | Add → doctor xem permissions/hooks nó |
| Session riêng thay vì add | Dir lạ | Đừng add — mở session mới cách ly |

Workflow chuẩn "sửa bug xuyên package (15 phút)":

```bash
# 1. Đang ở api, mở thêm shared
/add-dir ../shared
# 2. Xác minh
# /status → cả 2 loaded? (flag nếu thiếu)
# 3. Sửa chéo (Edit shared, test ở api)
# 4. Dọn
/add-dir --remove ../shared
# 5. Commit
git add -A && git commit -m "fix: shared lib + api caller"
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Add rồi mà luật dir phụ không áp | CLAUDE.md chưa load (thiếu env flag) | `/status` kiểm tra → bật flag → remove + add lại |
| `Blocked by Cd deny rule` khi add | Dir nằm trong deny | Đúng thiết kế; cần thật thì sửa settings (chịu trách nhiệm) |
| Trust prompt lặp lại mỗi session | Mới `Trust once`, chưa remember | Trust & remember; hoặc session mới ở máy khác chưa có trust store |
| Context phình sau khi add 3 dir | Cộng dồn CLAUDE.md như thiết kế | `--remove` cái xong việc; giữ tối đa 2 roots cùng lúc |
| Edit nhầm file trùng tên 2 roots | `utils.ts` có ở cả api lẫn shared, gọi tương đối | Dùng đường dẫn tuyệt đối/prefix root; Glob xác định trước khi Edit |
| Hook dir phụ chạy script lạ | Đã trust cả hooks của nó | Xem settings root đó, disable hook; untrust nếu nghi |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../cd/README.md](../cd/README.md) — chuyển hẳn thay vì mở thêm
  - [../status/README.md](../status/README.md) — xem roots nào loaded config, roots nào files-only
  - [../config/README.md](../config/README.md) — trust store + Cd rules + env flag
  - [../teleport/README.md](../teleport/README.md) — đổi máy (add-dir là thêm dir trên cùng máy)
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — working dir và roots là gì
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — roots trên IDE hiển thị ra sao
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — Cd rules, trust model, attack surface

> Mẹo 1 dòng: _add-dir xong `/status` ngay (added ≠ loaded) — và xong việc `--remove` ngay (đừng nuôi context béo)._
