# Changelog — Khóa Học Claude Code (tiếng Việt)

## [Unreleased] — đợt biên tập hiểu-nhanh (10/2026)

- `03-cau-hoi-thuong-gap/01–10`: chuẩn hóa mỗi câu hỏi theo khung 5 bước
  (Hỏi ngắn gọn → Trả lời 1 câu → Giải thích chi tiết + ví dụ → Steps copy-paste → Nếu vẫn lỗi thì...);
  mỗi file thêm 1 sơ đồ mermaid tổng quan + giữ nguyên lệnh copy-paste đã verify.
- `03/04-mcp-faq`: đồng bộ bảng Tools/Resources/Prompts với bài 08
  (Tools = `github.create_pr`/`postgres.query`, Resources = `github://...` URI, Prompts = `/mcp__<server>__<prompt>`)
  + bảng scopes project/local/user kèm ví dụ từng loại.
- `CHEATSHEET.md`: giữ 1 trang, mỗi lệnh giờ có ví dụ mini `vd:` copy-paste bên cạnh
  (CLI, session, model, code, system, hooks events, MCP day-one, vòng chuẩn).
- `01-huong-dan-su-dung/commands/` (78 lệnh): rút gọn từ 120–340 dòng về ~60 dòng/file
  theo format 7 mục (Tên lệnh → Nói nôm na → Khi nào dùng → Cách gọi → Ví dụ thật + verify → Lỗi hay gặp → Tham khảo),
  giữ nguyên cú pháp, bảng lỗi và link tham khảo từ bản cũ.
- Gốc + indexes: `README.md` thêm bảng đối tượng + lộ trình 5 ngày;
  `01/README.md` thêm thời gian từng bài; `templates/README.md` làm rõ 3 bước copy + checklist 15 phút;
  `templates/CLAUDE.md` chỉ làm rõ comment (giữ nguyên copy-paste);
  `commands/README.md` + 5 group README bổ sung cách tra cứu + sơ đồ nhóm.


## [v1.0.0] — 2026-10-04

Bản đầu tiên hoàn chỉnh theo Claude Code v2.1.x.

- `01-huong-dan-su-dung/`: 13 bài (01–13, chưa tính `00-tong-quan`) + `commands/` 64 folders
  (mỗi lệnh 1 `README.md` 8 mục: cú pháp, cơ chế, ví dụ, rủi ro, workflow, lỗi, tham khảo).
  Mới nhất: bài 13 code intelligence LSP + OpenTelemetry; lệnh `design-sync`, `radio`
  (version-gated, vắng mặt Bedrock/AWS/GCP, có workflow thay thế).
- `02-tips-thuc-chien/`: 11 bài (01–11). Mới nhất: tips 11 desktop & web
  (Chrome extension, computer use Pro/Max + guardrails, artifacts publish private,
  Remote Control vs Web sessions, voice dictation).
- `03-cau-hoi-thuong-gap/`: 10 bài (01–10) tài khoản/pricing, model/context,
  permissions, MCP, hooks, skills, subagents, troubleshooting, bảo mật, CI/SDK.
- `templates/`: `CLAUDE.md`, `.claude/` (3 skills, 3 agents, rules, settings, 5 hooks),
  `.mcp.json` + `.github/workflows/` (claude-review: review PR bằng `claude -p`
  guardrailed; claude-ci-triage: phân tích CI failure overnight mở issue).
- Gốc: `README.md` lộ trình 5 ngày, `CHEATSHEET.md` 1 trang, `LICENSE` MIT,
  `CONTRIBUTING.md` quy ước đóng góp.
