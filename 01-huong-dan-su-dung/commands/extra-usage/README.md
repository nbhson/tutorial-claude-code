# /extra-usage — Mua thêm quota khi hết giới hạn gói, không ngắt việc giữa chừng

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (chỉ liên quan billing/quota; không sửa code; có thể tốn tiền thật — đọc kỹ giá trước khi bật)

`/extra-usage` cho phép vượt trần quota của gói (Pro/Max/Team) bằng cách trả thêm pay-as-you-go, để Opus/effort cao không bị ngắt giữa task dài. Không phải "hack miễn phí" — là công tắc billing có kiểm soát.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/extra-usage` | _(không có)_ | Xem trạng thái + bật/tắt mua thêm |
| `/extra-usage on` | `on` | Bật chi trả vượt trần (quy ước UI, tùy bản) |
| `/extra-usage off` | `off` | Tắt, về trần gói cứng |
| Dashboard web | billing settings | Cách chắc chắn nhất khi lệnh CLI không rõ |

Ví dụ:

```bash
# Dạng 1: kiểm tra trạng thái
/extra-usage
```

```bash
# Dạng 2: đang chạy /fast bị báo limit → bật thêm rồi chạy tiếp
/extra-usage
# → bật theo hướng dẫn picker, rồi:
/fast
Tiếp tục rename 10 file còn lại.
```

```bash
# Dạng 3: trước audit lớn bằng Opus max — chủ động bật trước
/extra-usage
/model opus
/effort max
Audit toàn bộ payments/ trước release.
```

```bash
# Dạng 4: xong việc đắt → tắt ngay để khỏi quên
/extra-usage
# → chọn off
/effort medium
/model sonnet
```

---

## Cách nó hoạt động

### Cơ chế sâu

1. **Quota 2 lớp:**
   - Lớp 1: quota gói (VD Pro 100 prompt Opus/tuần). Hết → báo `limit reached`, phải đợi reset.
   - Lớp 2 (extra-usage): trả thêm từng prompt vượt trần theo giá API. Bật là chạy tiếp ngay, không đợi reset.
2. **Tính tiền theo model × effort:**
   - Opus + max đốt extra nhanh nhất (~20x so với Haiku low). Extra không làm gì rẻ đi — chỉ cho phép tiêu tiếp.
3. **Scope theo account, không theo session:**
   - Bật extra trên CLI cũng ảnh hưởng IDE/Web cùng account. Tắt ở đâu cũng tắt chung.
4. **Không liên quan tools/history:**
   - Extra không đổi model, effort, permissions — chỉ mở van billing. Vẫn cần `/model`/`/effort` để chọn não.
5. **Sao /fast cần /extra-usage?**
   - Fast chạy nhiều prompt nhỏ liên tục → dễ chạm trần rate-limit ngày. Extra là cách duy nhất chạy tiếp mà không đợi.

### Khác gì với lệnh dễ nhầm?

| Khái niệm | Là gì? | Tốn tiền? |
|---|---|---|
| `/extra-usage` | Van cho tiêu vượt trần | Có (pay-as-you-go) |
| Nâng gói Pro→Max | Tăng trần cứng theo tháng | Có (subscription) |
| API key riêng | Trả 100% theo usage, không trần gói | Có (theo từng token) |
| `/model haiku` | Giảm chi phí để khỏi cần extra | Giảm |

---

## Ví dụ thực tế

### Kịch bản 1: Đang refactor 30 file bằng Opus thì hết quota

```bash
# Đang ở file 18/30 thì báo limit
/extra-usage
# → bật, chạy tiếp 12 file còn lại trong cùng session

# Xong → tắt + về rẻ
/extra-usage
# → off
/model sonnet
/effort medium
```

### Kịch bản 2: Cuối tháng, team lead audit bảo mật — chủ động bật trước

```bash
# Biết trước audit tốn ~$5-10 extra, xin duyệt trước rồi bật
/extra-usage
/model opus
/effort xhigh
Audit auth/ + payments/, output bảng critical/high/low.
```

> Kết quả: không bị ngắt giữa audit (ngắt giữa chừng là mất context suy luận dở).

---

## Rủi ro & lưu ý

### Tốn token? Tốn tiền thật!

- Extra tính tiền thật theo giá API công khai. Opus max có thể $1–2/giờ chạy liên tục.
- Luôn `off` sau việc đắt. Quên tắt + để `max` = bill bất ngờ cuối tháng.
- Mẹo: đặt budget cap trên dashboard web (VD $20/tháng) để không vượt tay.

### Version / provider

- Có trên Pro/Max/Team v2.1.x. Gói Free / API-only không có khái niệm extra (API đã là pay-as-you-go từ đầu).
- Bedrock/Vertex qua công ty: extra có thể bị admin tắt (managed policy) — liên hệ admin.

### Destructive?

- Không sửa code. Rủi ro duy nhất là ví tiền.

---

## Kết hợp trong workflow

| Combo | Khi nào | Mẫu |
|---|---|---|
| `/extra-usage` + `/model opus` | Bài khó đúng lúc hết quota | Bật extra → opus |
| `/extra-usage` + `/effort max` | Audit/cược lớn | Bật extra → max |
| `/extra-usage` + `/batch` | 30 subagents song song đốt quota nhanh | Bật trước khi batch |
| `/extra-usage` → off + `/model sonnet` | Xong việc đắt | Tắt + về rẻ |

```bash
# Workflow an toàn:
/extra-usage   # on
/model opus
/effort high
# ... làm việc đắt ...
/extra-usage   # off
/model sonnet
/effort medium
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/extra-usage` báo không khả dụng | Gói Free / admin tắt / bản cũ | Nâng gói, liên hệ admin, update CLI |
| Bật rồi vẫn báo limit | Rate-limit cứng (chống abuse), không phải quota tiền | Đợi vài phút, giảm song song (`/batch` ít worktree hơn) |
| Bill tăng bất ngờ | Quên tắt + để max/opus | Tắt extra, về sonnet+medium, đặt cap trên dashboard |
| Picker không thấy on/off | UI khác theo bản | Làm trên dashboard web → billing → extra usage |
| Extra bật ở CLI nhưng IDE vẫn báo limit | Cache session | Restart IDE panel / `/clear` rồi thử lại |

---

## Tham khảo

- Lệnh liên quan:
  - [../fast/README.md](../fast/README.md) — fast chạm trần thì cần extra
  - [../model/README.md](../model/README.md) — Opus là thứ đốt extra nhanh nhất
  - [../effort/README.md](../effort/README.md) — max đốt extra nhanh nhất
  - [../batch/README.md](../batch/README.md) — batch song song cần extra trước
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _bật extra khi cần, tắt ngay khi xong — đừng để van tiền mở qua đêm._
