# Đóng góp cho Khóa Học Claude Code

Cảm ơn bạn muốn đóng góp! Repo này là tài liệu tiếng Việt, mọi code block copy-paste được.
Đọc 5 phút file này trước khi mở PR để bài mới "khớp format, không phải sửa lại".

## Cách thêm bài mới đúng format

### Bài trong `01-huong-dan-su-dung/` (deep-dive `NN-ten-bai.md`)

- Đặt tên: số tiếp theo + slug tiếng Việt không dấu, vd `13-code-intelligence-lsp-opentelemetry.md`.
- Độ dài: 300–450 dòng. Bắt buộc có: mục lục, `##` theo mạch why → how → ví dụ copy-paste →
  walkthrough → pitfalls (bảng 3 cột) → bài tập (có thời gian từng bài) → link chéo.
- Code block phải chạy được (đã thử tay ít nhất 1 lần). Secrets luôn qua env, không hardcode.
- Link chéo: ít nhất 3 links tới bài/commands liên quan (đường dẫn tương đối).

### Bài trong `02-tips-thuc-chien/` (tips `NN-ten-tips.md`)

- Đặt tên: số tiếp theo, vd `11-nang-cao-desktop-web.md`. Độ dài 300–450 dòng.
- Bắt buộc: lý thuyết gọn + ≥3 ví dụ copy-paste + walkthrough theo phút + 1 bảng tra nhanh +
  pitfalls + bài tập + tham khảo chéo.
- Mỗi tính năng phải ghi: cần plan gì, bật ở đâu, rủi ro & giới hạn (1 dòng bảng).

### Bài trong `03-cau-hoi-thuong-gap/` (FAQ `NN-ten.md`)

- Mỗi câu hỏi bắt buộc đủ 5 khối theo thứ tự:
  1. `> **Hỏi ngắn gọn:** ...` (1 dòng, đúng thứ người mới sẽ hỏi)
  2. `> **Trả lời 1 câu:** ...` (không giải thích dài ở đây)
  3. `**Giải thích chi tiết + ví dụ:**` (bảng + ví dụ thật)
  4. `**Làm thế nào (steps copy-paste):**` (code block chạy được ngay)
  5. `**Nếu vẫn lỗi thì:** ...` (trỏ sang `/status` → `doctor` → FAQ 08)
- Mỗi file phải có ít nhất 1 sơ đồ `mermaid` tổng quan + 1 bảng tổng hợp đầu file.
- Ví dụ chuẩn: xem `03-cau-hoi-thuong-gap/04-mcp-faq.md` mục `## 0.`.

### Lệnh mới trong `01-huong-dan-su-dung/commands/<slug>/README.md`

- 1 folder = 1 lệnh, chỉ 1 file `README.md`. Độ dài **tối thiểu 30–50 dòng súc tích** (~60 dòng tối đa).
- Format 7 mục cố định (xem `commands/model-mode/plan/README.md` sau đợt rewrite):
  1. `# /tên-lệnh — mô tả 1 dòng` + quote loại/nhóm/nguy hiểm + `> Nói nôm na:` 1–2 câu.
  2. `## Khi nào dùng` (3 bullets: đúng việc + trước khi phình to + không thay review tay).
  3. `## Cách gọi (copy-paste)` (code block 2–3 dạng gọi + ghi chú `/` discover/version-gated).
  4. `## Ví dụ prompt thật + kết quả mong đợi + verify` (prompt paste được + kết quả + verify 30 giây).
  5. `## Lỗi thường gặp` (bảng 3 cột Triệu chứng → Vì sao → Fix, 2–3 dòng).
  6. `## Tham khảo` (3–4 link lệnh liên quan + 1 bài tổng quan).
  7. `> Mẹo 1 dòng` kết file.
- Lệnh version-gated/provider-gated: ghi rõ bản tối thiểu, vắng mặt ở provider nào
  (vd Bedrock/AWS/GCP), cách kiểm tra bằng `/` trong session + workflow thay thế.

## Quy ước đặt tên & văn phong

- File/kebab-case không dấu: `NN-ten-tieng-viet.md`, folder lệnh 1 từ: `design-sync/`.
- Tiếng Việt, xưng "bạn", code comments tiếng Việt không dấu (tránh lỗi encoding CI).
- Tiêu đề bài 01: `# NN — Tên Bài (...)`. Tips 02: `# Tips NN — Tên (...)`.
- FAQ: giữ nguyên nội dung lệnh đã verify, chỉ thêm khung 5 bước + mermaid, không rút gọn ý.
- Không sửa nội dung file `.md` hiện có khi thêm bài mới (trừ link index ở lượt dọn riêng).

## PR checklist (tick hết mới merge)

- [ ] Tên file/số thứ tự đúng (không trùng, không nhảy số).
- [ ] Đủ số dòng: bài 300–450, lệnh 30–50+, FAQ mỗi câu đủ 5 khối + file có mermaid.
- [ ] Code block đã chạy thử (ghi rõ đã verify ở đâu trong PR mô tả).
- [ ] Có pitfalls (bảng) + bài tập (có thời gian) + link chéo (≥3, không 404).
- [ ] Lệnh mới: đủ 7 mục + version/provider + cách kiểm tra `/`.
- [ ] Workflow YAML mới: parse được (`python -c "import yaml..."`), secrets qua env,
      không `dangerously-skip-permissions`.
- [ ] Không sửa file `.md` cũ (diff chỉ chứa file mới, trừ khi PR ghi rõ lý do).
