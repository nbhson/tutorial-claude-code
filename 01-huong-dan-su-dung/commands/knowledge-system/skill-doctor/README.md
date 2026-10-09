# /skill-doctor — Báo cáo skill nào ngốn context, skill nào chết lâm sàng

> Loại Built-in (v2.1.252+, terminal-only) · Nhóm Tri thức & Tối ưu · Mức rủi ro Không (chỉ đọc + báo cáo, không sửa/xoá gì)
> **Nói nôm na:** `/skill-doctor` (từ bản ≥2.1.252, chỉ chạy trong terminal — không qua Remote Control) khám toàn bộ skills: skill nào ngốn bao nhiêu context/token, skill nào "không bao giờ được gọi" (mô tả mờ nên model chẳng trigger), skill nào trùng nhau. KHÔNG gồm skills bundled theo máy và enterprise. Hiểu `/skill-doctor` là hiểu "bác sĩ riêng cho tủ skill", còn `/doctor` là bác sĩ tổng quát cả repo.

## Khi nào dùng

- Dùng khi tủ skill nhiều mà không rõ cái nào tốn context / không bao giờ được gọi.
- Dùng **trước khi** context phình vì skill: mỗi skill tốn context mọi turn.
- Không dùng thay dọn tay: báo cáo gợi ý, bạn vẫn quyết sửa/xoá SKILL.md.

## Cách gọi

```bash
/skill-doctor          # báo cáo skill đang tốn / chết
/skill-doctor --cost   # xếp theo token
/skill-doctor --unused # chỉ skill không được gọi
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated). Cần ≥2.1.252 và chạy trong terminal.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/skill-doctor --cost
# → "run-e2e 4.2k (SKILL.md 180 dòng + 6 ví dụ thừa)
#    pdf-read 3.8k (nhúng cả spec 90 dòng vào SKILL)
#    10 skills còn lại <800 mỗi cái"

# Chữa:
# 1. pdf-read: chuyển spec sang file riêng, SKILL chỉ giữ cách gọi
# 2. run-e2e: cắt 6 ví dụ còn 2
```

Kết quả mong đợi:

- Bảng xếp hạng token từng skill + danh sách skill không bao giờ trigger.
- KHÔNG gồm skill bundled theo máy và enterprise.

**Kiểm tra nhanh:** chữa xong chạy lại `/skill-doctor --cost`, token của skill đó phải giảm.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/skill-doctor` báo unknown command | CLI <2.1.252 | Update (`/restart` offer bản mới); tạm rà tay từng SKILL.md |
| Chạy từ mobile remote không ra gì | Terminal-only, không qua Remote Control | Ngồi đúng terminal máy có skills |
| Báo cáo thiếu skills công ty | Enterprise skills bị loại trừ theo thiết kế | Quản enterprise qua admin/org settings, không phải đây |

## Tham khảo

- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../stats/README.md](../../knowledge-system/stats/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _skill "chết" thường do mô tả mờ — viết lại description trước khi xoá._
