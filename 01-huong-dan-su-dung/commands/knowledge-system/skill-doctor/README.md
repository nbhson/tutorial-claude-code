# /skill-doctor — Báo cáo skill nào ngốn context, skill nào chết lâm sàng

> Loại Built-in (v2.1.252+, terminal-only) · Nhóm Tri thức & Tối ưu · Nguy hiểm Không (chỉ đọc + báo cáo, không sửa/xoá gì)

> Nói nôm na: `/skill-doctor` (từ bản v2.1.252+, chỉ chạy trong terminal — không qua Remote Control) khám toàn bộ skills: skill nào ngốn bao nhiêu context/token, skill nào "không bao giờ được gọi" (mô tả mờ nên model chẳng trigger), skill nào trùng nhau. KHÔNG gồm skills bundled theo máy và enterprise. Hiểu `/skill-doctor` là hiểu "bác sĩ riêng cho tủ skill", còn `/doctor` là bác sĩ tổng quát cả repo.

## Khi nào dùng

- Dùng /skill-doctor khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /skill-doctor **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /skill-doctor thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/skill-doctor`
`/skill-doctor --cost`
`/skill-doctor --unused`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

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

- Claude trả đúng việc của /skill-doctor (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
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

> Mẹo 1 dòng: _chưa chắc thì gọi /skill-doctor sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
