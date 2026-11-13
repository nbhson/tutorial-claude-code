# /skill-doctor — Báo cáo skill nào ngốn context, skill nào chết lâm sàng

> Loại Built-in (v2.1.252+, terminal-only) · Nhóm Tri thức & Tối ưu · Mức rủi ro Không (chỉ đọc + báo cáo, không sửa/xoá gì)
> **Nói nôm na:** `/skill-doctor` (từ bản ≥2.1.252, chỉ chạy trong terminal — không qua Remote Control) khám toàn bộ skills: skill nào ngốn bao nhiêu context/token, skill nào "không bao giờ được gọi" (mô tả mờ nên model chẳng trigger), skill nào trùng nhau. KHÔNG gồm skills bundled theo máy và enterprise. Hiểu `/skill-doctor` là hiểu "bác sĩ riêng cho tủ skill", còn `/doctor` là bác sĩ tổng quát cả repo.

## Khi nào dùng

- Dùng khi tủ skill nhiều mà không rõ cái nào tốn context / không bao giờ được gọi.
- Dùng **trước khi** context phình vì skill: mỗi skill tốn context mọi turn.
- Không dùng thay dọn tay: báo cáo gợi ý, bạn vẫn quyết sửa/xoá SKILL.md.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated). Cần ≥2.1.252 và chạy trong terminal.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Bảng xếp hạng token từng skill + danh sách skill không bao giờ trigger.
- KHÔNG gồm skill bundled theo máy và enterprise.

**Kiểm tra nhanh:** chữa xong chạy lại `/skill-doctor --cost`, token của skill đó phải giảm.

> **Tóm gọn 1 câu:** `/skill-doctor` là bác sĩ riêng của tủ skill: đo cân nặng (token), tìm bệnh nhân bỏ nằm (skill không bao giờ được gọi) — còn điều trị hay cho ra đi thì bạn quyết.

## Lỗi thường gặp

Bảng dưới là mấy tình huống "bác sĩ từ chối khám" hoặc báo cáo thiếu — so với cột triệu chứng rồi xử theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/skill-doctor` báo unknown command | CLI <2.1.252 | Update (`/restart` offer bản mới); tạm rà tay từng SKILL.md |
| Chạy từ mobile remote không ra gì | Terminal-only, không qua Remote Control | Ngồi đúng terminal máy có skills |
| Báo cáo thiếu skills công ty | Enterprise skills bị loại trừ theo thiết kế | Quản enterprise qua admin/org settings, không phải đây |

> **Cách đọc bảng này:** mỗi dòng là một hiện tượng lạ khi chạy lệnh; cột "Vì sao" giải thích do bản CLI, do chạy sai chỗ hay do thiết kế, cột "Cách sửa" là hành động cụ thể.

## Tham khảo

- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../stats/README.md](../../knowledge-system/stats/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _skill "chết" thường do mô tả mờ — viết lại description trước khi xoá._
