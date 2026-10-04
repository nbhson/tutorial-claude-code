# /design-sync — Đồng bộ design → code: mockup thành UI thật, không lệch pixel

> Loại Built-in (version-gated) · Nhóm Code/UI · Nguy hiểm Thấp (chỉ đọc design + sinh/sửa code UI; nhưng Trung bình nếu auto-apply vào codebase lớn mà không review diff)

`/design-sync` kéo spec từ công cụ thiết kế (Figma và tương đương) về rồi sinh hoặc cập nhật code UI cho khớp: màu, spacing, typography, component mapping. Hiểu `/design-sync` là hiểu "phiên dịch viên design → code" — design đổi 1 token màu, code đổi theo, không còn cảnh "nhìn hình đoán CSS".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/design-sync` | _(không có)_ | Liệt kê design sources đã kết nối + trạng thái đồng bộ |
| `/design-sync status` | action | Xem link design ↔ code: file nào map với frame nào, lệch ở đâu |
| `/design-sync <frame-url>` | frame/link | Sinh code UI từ 1 frame hoặc 1 node cụ thể |
| `/design-sync --apply` | flag | Áp thay đổi vào repo (mặc định chỉ hiện diff để duyệt) |
| `/design-sync --tokens` | flag | Chỉ đồng bộ design tokens (màu, font, spacing) về theme file |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem đang nối với design nào
/design-sync
# → "Sources: figma-acme (connected) · Mapped: 12 frames ↔ 8 components · Drift: 2"
```

```bash
# Dạng 2: kiểm tra lệch trước khi code
/design-sync status
# → "Button/Primary: radius 8px (design) vs 6px (code) · Color surface: #F5F5F5 vs #FAFAFA"
```

```bash
# Dạng 3: sinh component từ frame cụ thể (dry-run trước)
/design-sync https://figma.com/file/abc?node-id=12-34
# → diff: apps/web/components/PricingCard.tsx (+120, -40) — duyệt rồi mới --apply
```

---

## Cách nó hoạt động

### Cơ chế sâu: design-sync lấy gì, sinh ra gì?

1. **Nguồn design lấy từ đâu?**
   - Kết nối qua design MCP hoặc OAuth (Figma connector): đọc frame, node tree, tokens, assets (icons, ảnh).
   - Không phải "chụp màn hình đoán": đọc đúng spec số (hex màu, padding px, font weight, auto-layout).
   - Chưa kết nối source nào thì `/design-sync` báo `no sources` và hướng dẫn connect — không đoán mò.
2. **Mapping design ↔ code như thế nào?**
   - Lần đầu: gợi ý map `Frame PricingCard → apps/web/components/PricingCard.tsx` dựa trên tên + cấu trúc.
   - Bạn xác nhận map 1 lần, lần sau tự nhớ (lưu trong project config, team share được).
   - Tokens về 1 chỗ: `theme/tokens.json` hoặc `tailwind.config` — component chỉ tham chiếu token, không hardcode hex.
3. **Dry-run trước, apply sau:**
   - Mặc định chỉ hiện diff (file nào đổi, dòng nào đổi). Thêm `--apply` mới ghi file.
   - Flow chuẩn: `status` (lệch ở đâu?) → sinh 1 frame → duyệt diff → `--apply` → chạy lint + screenshot so sánh.
4. **Version-gated + vắng mặt theo provider:**
   - Lệnh xuất hiện muộn (sau các lệnh core như `/plan`, `/verify`), cần Claude Code bản mới mới thấy.
   - Vắng mặt trên Bedrock/AWS/GCP (self-hosted model gate): gõ `/design-sync` ở đó báo `unknown command`.
   - Lý do: phụ thuộc design connector cloud-side (Figma OAuth, asset fetch) mà Bedrock/GCP build không bật.

### Sơ đồ status → sinh → apply

```text
/design-sync status
  │ Drift: 2 (radius, surface color)
  ├─ /design-sync <frame-url> → diff preview (PricingCard.tsx +120/-40)
  ├─ duyệt diff (bạn): ok? → /design-sync --apply
  └─ sau apply: pnpm lint + screenshot → tokens khớp, pixel khớp
Không duyệt mà --apply thẳng = tự chịu khi UI vỡ layout
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Input | Dùng khi nào? |
|---|---|---|
| `/design-sync` | Design spec có thật | Có file Figma/link node, muốn code khớp số |
| Copy-paste ảnh vào prompt | Ảnh chụp màn hình | Không có connector, mockup nhanh 1 lần |
| `/verify` | App đang chạy | Kiểm tra hành vi sau khi sync (build + nhìn thật) |
| `/diff` | Diff hiện tại | Duyệt hunk trước commit (dùng sau `--apply`) |

> Quy tắc ngón tay cái:
>
> - **Có design source + làm UI thật → `/design-sync`. Chỉ có ảnh lẻ, việc 1 lần → paste ảnh là đủ.**

---

## Ví dụ thực tế

### Kịch bản 1: Landing đổi pricing — sync 1 frame, không rewrite cả trang

```bash
/design-sync status
# → "PricingCard: design v12 vs code v9 · Drift: price color, badge radius"

# Sinh thử 1 frame trước:
/design-sync https://figma.com/file/acme?node-id=45-67
# → diff preview: PricingCard.tsx đổi color token + radius, giữ logic giá

# Duyệt xong mới áp:
/design-sync --apply
pnpm --filter @acme/web lint && pnpm --filter @acme/web test
# → khớp design, test vẫn xanh
```

> Kết quả: đổi đúng 1 component, không sờ 20 file còn lại. Không sync mà sửa tay là lệch token dần.

### Kịch bản 2: Chỉ sync tokens sau rebrand (đổi palette cả hệ)

```bash
# Design team đổi palette v3 — code còn v2:
/design-sync --tokens
# → diff: theme/tokens.json (primary 12 màu, font scale, spacing)
# → duyệt → --apply → chạy storybook/screenshot toàn trang

# Kiểm tra drift còn lại:
/design-sync status
# → "Tokens: synced ✓ · Components: 2 còn hardcode hex cũ (fix tay)"
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| `--apply` thẳng vào codebase lớn | Ghi đè custom logic (handlers, a11y) trong component | Luôn dry-run trước; component logic tách khỏi presentational |
| Tin spec 100% (design sai spacing) | Code "khớp design sai" — pixel-perfect mà UX sai | Design sai thì flag lại cho designer, đừng sync mù |
| Token hardcode hex khắp nơi | Sync tokens xong vẫn lệch (code không dùng token) | Refactor về token 1 lần, hook/grep chặn hex mới |
| Chạy trên Bedrock/AWS/GCP | Lệnh không tồn tại, tưởng gõ sai | Check bảng provider (mục dưới); fallback paste ảnh + spec tay |
| Asset nặng (ảnh 4K, 50 icons) | Context phình, bill vọt | Sync từng frame, export asset size vừa, không kéo cả file |

### Tốn token?

- Trung bình–cao. Mỗi frame kéo node tree + tokens (vài K–chục K tokens). Sync cả file lớn thì chia frame nhỏ.

### Version / provider

- Cần Claude Code bản mới (version-gated — bản cũ gõ không ra). Update: `npm i -g @anthropic-ai/claude-code` rồi gõ `/` kiểm tra.
- Plan/provider: có trên Pro/Max/Console (kèm design connector). **Vắng mặt trên Bedrock/AWS/GCP** — ở đó dùng workflow thay thế (paste spec + ảnh, mục 7).
- Gõ `/` trong session là chân lý cuối: thấy `/design-sync` mới dùng, không thấy thì đừng cố.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/design-sync status` + `/plan` | UI task nhiều màn | Status tìm drift → plan chia phase theo frame |
| `/design-sync --apply` + `/diff` | Sau mỗi lần áp | Diff duyệt hunk trước commit |
| `/design-sync` + `/verify` | Sync xong | Verify build + nhìn app thật, không tin diff chữ |
| `/design-sync --tokens` + grep hex | Sau rebrand | Tokens sync rồi grep hex cũ còn sót |

Workflow chuẩn "sync 1 frame (10 phút)": `status` (lệch đâu?) → sinh 1 frame (dry-run) → duyệt diff → `--apply` → lint + `/verify` nhìn thật.

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `unknown command: /design-sync` | Bản cũ hoặc provider Bedrock/AWS/GCP | Update bản mới; ở Bedrock/GCP thì dùng fallback paste spec |
| `no sources connected` | Chưa nối Figma/design connector | Kết nối MCP/OAuth design trước, rồi chạy lại |
| Diff ghi đè logic click/submit | Component lẫn logic + UI | Tách container/presentational; sync chỉ chạm file UI |
| Sync xong vẫn lệch 2px | Design dùng auto-layout, code flex khác | So bằng screenshot `/verify`, chỉnh flex/gap tay |
| Tokens sync mà màu không đổi | Code hardcode hex, không đọc token | Grep hex cũ, thay bằng token, thêm lint chặn hex |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../plan/README.md](../plan/README.md) — plan theo frame trước khi sync hàng loạt
  - [../diff/README.md](../diff/README.md) — duyệt hunk sau `--apply`
  - [../verify/README.md](../verify/README.md) — build + nhìn app thật sau sync
  - [../mcp/README.md](../mcp/README.md) — nối design connector qua MCP
- Bài tổng quan:
  - [../../04-slash-commands-toan-tap.md](../../04-slash-commands-toan-tap.md) — index 64 lệnh + lưu ý version/provider
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — bảng availability theo provider (Bedrock/AWS/GCP vắng gì)
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — sync khác nhau mỗi bề mặt ra sao

> Mẹo 1 dòng: _status trước, dry-run 1 frame trước, `--apply` sau — và gõ `/` kiểm tra lệnh có tồn tại ở provider của bạn không._
