# /setup-vertex — Wizard cắm Claude Code vào Google Vertex AI

> Loại Built-in · Nhóm Provider & Cloud · Nguy hiểm Thấp (chỉ ghi config + test kết nối; nhưng Có nếu bạn dán service-account JSON vào repo — để ngoài repo + gitignore)

`/setup-vertex` là wizard cấu hình Claude Code chạy qua Google Vertex AI: hỏi project, region, auth (`gcloud` ADC/service-account), ghi config rồi test 1 câu chào. Sinh ra cho team đã ở GCP (billing chung, IAM org, data residency EU...) muốn xài Claude qua hạ tầng Google. Hiểu `/setup-vertex` là hiểu "anh em song sinh của `/setup-bedrock`, nhưng đấu vào ổ điện Google".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/setup-vertex` | _(không có)_ | Wizard: project → region → auth → model → test kết nối |
| `/setup-vertex --check` | flag | Chỉ kiểm tra config hiện tại còn sống không (không ghi lại) |
| `/status` | _(lệnh xem)_ | Xem provider đang dùng (vertex? project? model?) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: setup mới (lần đầu xài Vertex)
/setup-vertex
# → project [my-team-123] → region [asia-southeast1]
# → auth gcloud ADC [Yes] → model sonnet → test "hello" → OK
```

```bash
# Dạng 2: kiểm tra sau 1 tháng
/setup-vertex --check
# → "project OK, auth OK, model ENABLED. Sống."
```

```bash
# Dạng 3: xác nhận đang chạy Vertex
/status
# → "provider: vertex, project: my-team-123, model: sonnet"
```

---

## Cách nó hoạt động

### Cơ chế sâu: wizard đấu dây 4 bước

1. **Project:** GCP project đã bật Vertex AI API (`aiplatform.googleapis.com`) — chưa bật thì wizard báo link bật, không bật hộ.
2. **Region:** region đã có Claude trên Vertex (không phải region nào cũng có — `asia-southeast1` thường có; check docs trước). Sai region = "model not found" dù auth đúng.
3. **Auth (theo thứ tự nên dùng):**
   - `gcloud auth application-default login` (ADC, laptop cá nhân) — tốt nhất cho dev.
   - Workload Identity (máy GCE/GKE trong org) — tốt nhất cho máy cloud.
   - Service-account JSON — cuối cùng; để ở `~/.config/gcloud/`, KHÔNG bỏ vào repo.
4. **Test + ghi config:** 1 prompt "hello" qua Vertex endpoint, 200 OK → ghi provider vào settings (user scope).

```text
/setup-vertex
├─ project: my-team-123 (đã bật Vertex AI API?)
├─ region:  asia-southeast1 (có Claude? check docs trước)
├─ auth:    ADC > workload-identity > service-account JSON (ngoài repo!)
└─ test:    "hello" → 200 → ghi settings → /status xác nhận
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Cấu hình gì? | Dùng khi nào? |
|---|---|---|
| `/setup-vertex` | Chạy qua Google Vertex AI | Team ở GCP |
| `/setup-bedrock` | Chạy qua AWS Bedrock | Team ở AWS |
| `/login` | Login Anthropic trực tiếp | Không qua vendor |
| `/model` | ĐỔI model trong provider hiện tại | Đã setup xong, chỉ đổi model |
| `/status` | XEM đang dùng provider gì | Kiểm tra, không cấu hình |

> Quy tắc ngón tay cái:
>
> - **Team GCP → `/setup-vertex`. Team AWS → `/setup-bedrock`. Còn lại → `/login`.**

---

## Ví dụ thực tế

### Kịch bản 1: Dev mới vào team GCP — setup từ zero (15 phút)

```bash
# Login ADC trước:
gcloud auth application-default login --project my-team-123
# → browser OK

/setup-vertex
# → project my-team-123 [Yes] → region asia-southeast1 [Yes]
# → auth ADC [Yes] → model sonnet [Yes]
# → test "hello" → "Hello! (via Vertex, 1.4s)" ✓

/status
# → provider vertex. Xong.
```

> Kết quả: 15 phút 1 lần. Session sau tự chạy Vertex.

### Kịch bản 2: Lỗi "API not enabled / model not found" — 90% chưa bật API

```bash
/setup-vertex --check
# → "auth OK, project OK, Vertex AI API: DISABLED"

/setup-vertex
# → wizard đưa link console bật aiplatform.googleapis.com
# → bật xong chạy lại wizard → test OK
```

> Đừng sửa auth khi lỗi này — auth OK rồi, bệnh ở API chưa bật. Bật 1 lần trong console là hết.

### Kịch bản 3: Service-account JSON lọt vào repo — dọn khẩn

```bash
# Phát hiện file sa.json trong repo:
git grep -l "private_key" .
# → services/api/sa.json (!!)

# Dọn:
# 1. Thu hồi key trong IAM console NGAY (key đã lộ coi như mất)
# 2. Xóa file khỏi repo + history (BFG/git-filter-repo)
# 3. Chuyển sang ADC: gcloud auth application-default login
/setup-vertex --check
# → auth ADC OK. Từ nay key JSON không vào repo nữa.
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (key JSON + quota chung)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Service-account JSON trong repo | HAY GẶP NHẤT: key lên GitHub = mất project | JSON ở `~/.config/gcloud/` (ngoài repo); `git grep private_key` trước push |
| Quyền Editor/Owner cho service-account dev | Key lộ là attacker chiếm cả project | Role tối thiểu: `aiplatform.user` (gọi model) — không Editor |
| Cả team 1 project 1 quota | 1 người chạy opus nặng là hết quota team | Tách quota/dev-project; việc nhẹ dùng haiku (`/model`) |
| Region sai data residency | Dữ liệu EU chạy qua region US, vi phạm policy | Hỏi compliance team region trước khi setup |

### Tốn token?

- Setup + test hello ≈ vài trăm token. Bill Vertex tính theo dùng thật sau đó.

### Version / provider

- `/setup-vertex`: v2.x. Bản cũ config tay (env `GOOGLE_CLOUD_PROJECT` + ADC).
- Xài Vertex rồi thì `/doctor`, `/run`, `/verify` chạy bình thường.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/setup-vertex` + `/status` | Setup xong xác nhận | Setup → status |
| `/setup-vertex` + `/model` | Đổi model trong Vertex | Vertex OK → `/model haiku` việc nhẹ |
| `/setup-vertex` + `/doctor` | Khám sau setup | Doctor check provider + config |

Workflow chuẩn "onboard team GCP (20 phút)":

```bash
# 1. ADC trước
gcloud auth application-default login --project my-team-123
# 2. Wizard
/setup-vertex
# 3. Xác nhận
/status
# 4. Khám tổng
/doctor --quick
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| "API aiplatform.googleapis.com not enabled" | Project chưa bật Vertex AI API | Console bật API (link wizard đưa); đợi 2-3 phút propagation rồi chạy lại |
| "Model not found in region" dù auth OK | Sai region (region đó chưa có Claude) | Đổi region có Claude (`asia-southeast1`/`us-central1`... check docs); đừng sửa auth |
| "Permission denied aiplatform.endpoints.predict" | Thiếu role `aiplatform.user` | Xin role tối thiểu; test `gcloud ai models list --region=...` |
| ADC hết hạn sau 1-2 tháng | Refresh token hết hạn/không persistent | `gcloud auth application-default login` lại; máy cloud thì workload identity cho bền |
| Bill/quota team tăng đột biến | Ai đó chạy opus loop dài trên quota chung | `/model` về sonnet/haiku việc nhẹ; tách project dev riêng |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../setup-bedrock/README.md](../../auth-settings/setup-bedrock/README.md) — team AWS thì dùng cái này
  - [../login/README.md](../../auth-settings/login/README.md) — login Anthropic thẳng
  - [../model/README.md](../../model-mode/model/README.md) — đổi model trong provider hiện tại
  - [../status/README.md](../../auth-settings/status/README.md) — xem provider đang dùng
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — khám sau khi setup
- Bài tổng quan:
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — providers và môi trường chạy

> Mẹo 1 dòng: _ADC cho laptop, workload identity cho máy cloud, key JSON là phương án cuối — và đừng bao giờ commit nó._
