# /setup-bedrock — Wizard cắm Claude Code vào AWS Bedrock

> Loại Built-in · Nhóm Provider & Cloud · Nguy hiểm Thấp (chỉ ghi config + test kết nối; nhưng Có nếu bạn dán access key vào file rồi commit — dùng IAM role/SSO thay vì key cứng)

`/setup-bedrock` là wizard cấu hình Claude Code chạy qua AWS Bedrock: hỏi region, model entitlement, auth (IAM role/SSO/keys), ghi config rồi test 1 câu chào. Sinh ra cho team đã ở AWS (quỹ tín dụng, compliance, VPC) muốn xài Claude qua hạ tầng nhà. Hiểu `/setup-bedrock` là hiểu "đấu dây từ Claude Code vào ổ điện AWS".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/setup-bedrock` | _(không có)_ | Wizard: region → auth → model → test kết nối |
| `/setup-bedrock --check` | flag | Chỉ kiểm tra config hiện tại còn sống không (không ghi lại) |
| `/status` | _(lệnh xem)_ | Xem provider đang dùng (bedrock? bản? model?) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: setup mới (lần đầu xài Bedrock)
/setup-bedrock
# → hỏi region [ap-southeast-1] → auth (IAM role/SSO/keys)
# → model (đã enable trong Bedrock?) → test "hello" → OK
```

```bash
# Dạng 2: kiểm tra sau 1 tháng (key hết hạn? model bị tắt?)
/setup-bedrock --check
# → "region OK, auth OK, model claude-sonnet: ENABLED. Sống."
```

```bash
# Dạng 3: xác nhận đang chạy Bedrock
/status
# → "provider: bedrock, region: ap-southeast-1, model: sonnet"
```

---

## Cách nó hoạt động

### Cơ chế sâu: wizard đấu dây 4 bước

1. **Region:** chọn region đã enable Claude trong Bedrock (không phải region nào cũng có Claude — check AWS console trước). Sai region = lỗi "model not available" dù auth đúng.
2. **Auth (theo thứ tự nên dùng):**
   - `IAM role` (máy EC2/ECS có role) — tốt nhất, khỏi key.
   - `SSO` (`aws sso login`) — tốt cho laptop cá nhân trong org.
   - `Access keys` — cuối cùng; wizard dặn để vào `~/.aws/credentials`, KHÔNG dán vào file repo.
3. **Model entitlement:** Bedrock yêu cầu enable model trong console (request access) TRƯỚC — wizard chỉ chọn trong list đã enable, không enable hộ.
4. **Test + ghi config:** gửi 1 prompt "hello", 200 OK → ghi provider vào settings (user scope) → từ nay session chạy qua Bedrock.

```text
/setup-bedrock
├─ region:  ap-southeast-1 (có Claude? check console trước)
├─ auth:    IAM role > SSO > keys (keys để ~/.aws, không commit)
├─ model:   chọn trong list đã enable (chưa enable → ra console bật)
└─ test:    "hello" → 200 → ghi settings → /status xác nhận
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Cấu hình gì? | Dùng khi nào? |
|---|---|---|
| `/setup-bedrock` | Chạy qua AWS Bedrock | Team ở AWS, cần compliance/VPC/quỹ |
| `/setup-vertex` | Chạy qua Google Vertex AI | Team ở GCP |
| `/login` | Login tài khoản Anthropic trực tiếp | Không qua cloud vendor, xài API thẳng |
| `/model` | ĐỔI model trong provider hiện tại | Đã setup xong, chỉ muốn đổi sonnet/opus |
| `/status` | XEM đang dùng provider gì | Kiểm tra, không cấu hình |

> Quy tắc ngón tay cái:
>
> - **Team AWS → `/setup-bedrock`. Team GCP → `/setup-vertex`. Cá nhân xài thẳng → `/login`. Chỉ đổi model → `/model`.**

---

## Ví dụ thực tế

### Kịch bản 1: Dev mới vào team AWS — setup từ zero (15 phút)

```bash
# Máy đã có AWS CLI + SSO org:
aws sso login --profile team-dev
# → browser SSO OK

/setup-bedrock
# → region: ap-southeast-1 [Yes]
# → auth: SSO profile team-dev [Yes]
# → model: sonnet (đã enable) [Yes]
# → test "hello" → "Hello! (via Bedrock, 1.2s)" ✓

/status
# → provider bedrock, region ap-southeast-1. Xong, code thôi.
```

> Kết quả: 15 phút 1 lần duy nhất. Các session sau tự chạy Bedrock, không setup lại.

### Kịch bản 2: Lỗi "model not available" — 90% sai region/chưa enable

```bash
/setup-bedrock --check
# → "auth OK, region ap-southeast-1 OK, model claude-opus: NOT ENABLED"

# Ra AWS console → Bedrock → Model access → Enable opus → quay lại:
/setup-bedrock --check
# → "opus: ENABLED. Sống."
```

> Đừng sửa auth khi lỗi này — auth OK rồi, bệnh ở entitlement. Vào console bật model là hết.

### Kịch bản 3: Key cứng hết hạn sau 90 ngày — chuyển sang SSO/role

```bash
/setup-bedrock --check
# → "auth FAILED: expired access key (90 days)"
# → đừng tạo key mới dán lại (vòng lặp 90 ngày nữa) — chuyển SSO 1 lần:

/setup-bedrock
# → auth: SSO [Yes] → test OK
# → xóa key cũ trong ~/.aws/credentials + IAM console (khỏi bị lộ)
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (key cứng + sai scope)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Dán access key vào file repo rồi commit | HAY GẶP NHẤT: key lên GitHub, bot quét 5 phút là mất tiền | Key chỉ ở `~/.aws/credentials` (đã gitignore toàn máy); `git grep -i "AKIA" .` trước push |
| IAM policy `bedrock:*` + `*` resource | Key lộ là attacker xài hết quỹ + tạo resource | Policy tối thiểu: chỉ `bedrock:InvokeModel` trên model ARN cần; role riêng cho dev |
| Dùng region không có log/audit | Mất vết khi cần truy sự cố/compliance | Chọn region team đã bật CloudTrail; hỏi platform team trước khi tự chọn |
| Quên đang chạy Bedrock, tưởng API thẳng | Bill về tài khoản AWS khác dự kiến | `/status` đầu tuần; tag/cost-allocation theo hướng dẫn platform team |

### Tốn token?

- Setup + test hello ≈ vài trăm token. Không đáng kể. Bill Bedrock tính theo dùng thật sau đó.

### Version / provider

- `/setup-bedrock`: v2.x. Bản cũ config tay (sửa settings JSON + env).
- Model list theo entitlement trong console — model mới (opus mới) phải enable tay mới chọn được.
- Xài Bedrock rồi thì `/doctor`, `/run`, `/verify` chạy bình thường (chỉ đổi đường gọi model).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/setup-bedrock` + `/status` | Setup xong xác nhận | Setup → status |
| `/setup-bedrock` + `/model` | Setup xong đổi model trong Bedrock | Bedrock OK → `/model opus` (nếu đã enable) |
| `/setup-bedrock` + `/doctor` | Setup xong khám tổng | Doctor check provider + config |
| `/setup-bedrock` + `/setup-vertex` | Team multi-cloud (hiếm) | Mỗi máy 1 provider, đừng trộn 1 máy |

Workflow chuẩn "onboard team AWS (20 phút)":

```bash
# 1. SSO trước
aws sso login --profile team-dev
# 2. Wizard
/setup-bedrock
# 3. Xác nhận
/status
# 4. Khám tổng
/doctor --quick
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| "Model not available in region" dù auth OK | Sai region hoặc model chưa enable trong console | Console → Bedrock → Model access → Enable; chọn region có Claude |
| "ExpiredToken / InvalidClientTokenId" | Key cũ 90 ngày / SSO session hết hạn | `aws sso login` lại; key cứng thì chuyển SSO/role cho bền |
| "AccessDenied: not authorized bedrock:InvokeModel" | IAM policy thiếu quyền | Xin policy `bedrock:InvokeModel` trên ARN model; test bằng `aws bedrock list-foundation-models` |
| Setup OK nhưng bill lạ | Session chạy model đắt (opus) hoặc region khác dự kiến | `/model` về sonnet/haiku khi việc nhẹ; `/status` kiểm tra region |
| Mạng công ty chặn bedrock endpoint | Proxy/firewall chưa allowlist AWS endpoint | Hỏi IT mở `bedrock-runtime.<region>.amazonaws.com`; test `curl` endpoint trước |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../setup-vertex/README.md](../../auth-settings/setup-vertex/README.md) — team GCP thì dùng cái này
  - [../login/README.md](../../auth-settings/login/README.md) — login Anthropic thẳng (không qua vendor)
  - [../model/README.md](../../model-mode/model/README.md) — đổi model trong provider hiện tại
  - [../status/README.md](../../auth-settings/status/README.md) — xem provider đang dùng
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — khám sau khi setup
- Bài tổng quan:
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — providers và môi trường chạy

> Mẹo 1 dòng: _role tốt hơn SSO, SSO tốt hơn key cứng, và model chưa enable thì đừng đổ lỗi cho auth._
