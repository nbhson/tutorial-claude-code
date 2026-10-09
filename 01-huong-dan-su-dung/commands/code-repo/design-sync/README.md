# /design-sync — đồng bộ design → code: mockup thành UI thật, không lệch pixel

> Loại Built-in (version-gated) · Nhóm Code/UI · Mức rủi ro Thấp
> **Nói nôm na:** `/design-sync` kéo spec từ công cụ thiết kế (Figma và tương đương) về rồi sinh hoặc cập nhật code UI cho khớp: màu, spacing, typography, component mapping.

## Khi nào dùng

- Dùng `/design-sync` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/design-sync` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/design-sync` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/design-sync`
`/design-sync status`
`/design-sync <frame-url>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/design-sync status
# → "PricingCard: design v12 vs code v9 · Drift: price color, badge radius"
/design-sync https://figma.com/file/acme?node-id=45-67
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/design-sync` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `unknown command: /design-sync` | Bản cũ hoặc provider Bedrock/AWS/GCP | Update bản mới; ở Bedrock/GCP thì dùng fallback paste spec |
| `no sources connected` | Chưa nối Figma/design connector | Kết nối MCP/OAuth design trước, rồi chạy lại |
| Diff ghi đè logic click/submit | Component lẫn logic + UI | Tách container/presentational; sync chỉ chạm file UI |

## Tham khảo

- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../knowledge-system/mcp/README.md](../../knowledge-system/mcp/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/design-sync` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
