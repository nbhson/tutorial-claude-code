# /doctor — Khám sức khoẻ repo: CLAUDE.md phình không, thiếu phanh ở đâu

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (chỉ đọc + báo cáo; nhưng Có nếu bạn Yes hết mọi đề xuất fix — nhất là trim CLAUDE.md từ bản ≥2.1.206 mà không review)
> **Nói nôm na:** `/doctor` chạy audit tự động toàn diện: quét CLAUDE.md (dài quá không, mâu thuẫn không), permissions (mở toang không), MCP (server chết không), hooks (lỗi không), plugins (thừa không), skills/agents (rác không)... rồi chấm điểm + gợi ý fix từng cái (bạn duyệt mới sửa). Hiểu `/doctor` là hiểu "bác sĩ tổng quát" gọi mỗi tháng 1 lần.

## Khi nào dùng

- Dùng khi mới clone repo lạ, hoặc định kỳ mỗi tháng để audit toàn cục.
- Dùng **trước khi** repo/config phình to: bắt CLAUDE.md dài, permissions mở toang, MCP chết, hook lỗi.
- Không dùng thay review tay: doctor chấm điểm + gợi ý, bạn duyệt mới sửa.

## Cách gọi

```bash
/doctor          # audit đầy đủ
/doctor --quick  # quét nhanh các mục chính
/doctor --fix    # đề xuất fix, bạn duyệt từng cái
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Vừa clone repo người khác để lại, chưa biết gì:
/doctor

# Báo cáo ví dụ:
# 🔴 claude-md: không có CLAUDE.md (0 dòng) → /init tạo mới?
# 🟡 permissions: không có settings.json → dùng mặc định (hỏi nhiều)
# 🟢 mcp: không có server (sạch, khỏi lo)
# 🟡 hooks: không có (khuyên thêm guard + format)
```

Kết quả mong đợi:

- Bảng chấm điểm theo mục (🔴/🟡/🟢) + gợi ý fix từng cái.
- Với `--fix`: chỉ sửa mục bạn Yes; trim CLAUDE.md cần ≥2.1.206.

**Kiểm tra nhanh:** chạy lại `/doctor`, điểm không còn 🔴; `git status` xem đúng file được sửa.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Trim xong model làm sai hàng loạt | Trim cắt mất luật quan trọng | `git checkout .claude/` rollback; tách rules tay rồi trim lại từng phần |
| `/doctor` báo MCP dead dù hôm qua còn chạy | Laptop sleep kill stdio | `/mcp reconnect <tên>` rồi `/doctor mcp` lại |
| Điểm thấp vì "thiếu CLAUDE.md" nhưng repo cố tình không cần | Repo 5 file, doctor heuristic quá đà | Bỏ qua mục đó (không phải lỗi); doctor là gợi ý, không phải luật |

## Tham khảo

- [../debug/README.md](../../knowledge-system/debug/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../rules/README.md](../../knowledge-system/rules/README.md)
- [../memory/README.md](../../knowledge-system/memory/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _gọi /doctor sau mỗi lần cài plugin/MCP mới — cấu hình mới là chỗ hay lệch._
