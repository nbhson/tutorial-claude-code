# /design-sync — đồng bộ design → code: mockup thành UI thật, không lệch pixel

> Loại Built-in (version-gated) · Nhóm Code/UI · Mức rủi ro Thấp
> **Nói nôm na:** `/design-sync` kéo spec từ công cụ thiết kế (Figma và tương đương) về rồi sinh hoặc cập nhật code UI cho khớp: màu, spacing, typography, component mapping. Cứ coi như thợ đối chiếu bản vẽ với công trình đang xây: lệch chỗ nào vá chỗ đó, không phá xây lại cả tòa.

## Khi nào dùng

- Dùng `/design-sync` khi design đã đổi và bạn muốn code UI khớp lại: màu, spacing, typography, component mapping.
- Chạy khi **bắt đầu task UI**, trước khi tự sửa CSS bằng tay cho khớp mockup.
- Không dùng nó cho logic: sync chỉ nên chạm file trình bày, đừng để nó ghi đè click/submit.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Danh sách drift (design phiên bản nào vs code phiên bản nào) kèm file cần sửa.
- Sinh/cập nhật code UI; không chạm logic nếu bạn không cho.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các sự cố hay gặp khi đồng bộ design — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `unknown command: /design-sync` | Bản cũ hoặc provider Bedrock/AWS/GCP | Update bản mới; ở Bedrock/GCP thì dùng fallback paste spec |
| `no sources connected` | Chưa nối Figma/design connector | Kết nối MCP/OAuth design trước, rồi chạy lại |
| Diff ghi đè logic click/submit | Component lẫn logic + UI | Tách container/presentational; sync chỉ chạm file UI |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là thông báo lỗi hoặc hành vi sai bạn thấy, "Vì sao" chỉ nguyên nhân (bản CLI, connector, component lẫn logic), "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/design-sync` là thợ soi bản vẽ đối chiếu công trình: drift hiện ra, code UI tự khớp — nhưng logic click/submit thì giữ ngoài tầm tay của nó.

## Tham khảo

- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../knowledge-system/mcp/README.md](../../knowledge-system/mcp/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/design-sync` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
