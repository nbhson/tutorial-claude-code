# Changelog — Khóa Học Claude Code (tiếng Việt)

## [Unreleased] — 2026-10-28

- **Dịch** `tool-use/mcp-advanced/README.md` sang tiếng Việt (trước đây 100% tiếng Anh — vi phạm quy tắc A2/A5 của repo): thêm khung lối vào A2 + bảng thuật ngữ, giữ nguyên mọi dữ kiện kỹ thuật, comment code và link. Last verified: 2026-10-28.
- **Bài mới** `01-huong-dan-su-dung/17-output-styles-doi-vai-tro-va-giong-tra-loi.md` (~260 dòng):
  lệnh `/output-style`, 4 style built-in (Proactive/Concise/Explanatory/Learning), cách đổi style
  (lệnh, `/config`, VS Code, settings `outputStyle`), custom output style + frontmatter
  (`name`, `description`, `keep-coding-instructions`, `force-for-plugin`), bảng chọn output style
  vs CLAUDE.md/skill/hook/subagent. Verify theo docs chính thức 28/10/2026 — output styles
  **vẫn còn, không bị gỡ** trong v2.x.
- Mục 6 của bài 17: note phân biệt **memory tool** (`memory_20250818` của Messages API — bạn tự
  implement handler trên storage của mình, dùng khi build agent bằng API/SDK) với lệnh **`/memory`**
  của Claude Code (quản lý CLAUDE.md + auto memory local).
- `01-huong-dan-su-dung/12-agent-sdk-ci-cd-automation.md`: thêm mục 2.3 **TypeScript vs Python SDK**
  — xác nhận Python SDK chính chủ (`claude-agent-sdk` trên PyPI, 0.2.174 ngày 24/10/2026, Python
  ≥3.10, bundle sẵn CLI), bảng khác biệt naming/API (snake_case vs camelCase, `ClaudeSDKClient`,
  `@tool` + `create_sdk_mcp_server`, Pydantic vs Zod).
- Cập nhật index: `01-huong-dan-su-dung/README.md` và `README.md` gốc từ 17 bài → **18 bài**.
- Sửa ~6 chỗ đại từ "nó" ngoài prompt mẫu (bài 01, 07, 15, tips 01, README gốc) theo quy tắc A5.
- Vệ sinh repo: xóa `.DS_Store` (đã có trong `.gitignore`); sửa số file `.md` từ "141" thành
  **143** (đếm lại 28/10/2026).

## [v1.1.0] — 2026-10-28

Gộp 2 đợt [Unreleased] trước đó thành bản phát hành v1.1.0.

### Đợt soát dữ kiện & dễ đọc (11/10/2026)

- Toàn bộ **143 file `.md`** (đếm lại 28/10/2026; số gốc ghi 141): soát lại dữ kiện theo tài liệu
  chính thức và tinh chỉnh câu chữ cho dễ đọc, giữ nguyên cấu trúc (khung 7 mục của file lệnh,
  5 khối FAQ, khối "lối vào" A2), không mất bảng/ví dụ/lệnh/bài tập/link.
- Cập nhật dữ kiện phiên bản/model: bản mới nhất **v2.1.296** (09/10/2026); thêm **Haiku 5.5**
  (`claude-haiku-5-5`, ≥2.1.293, context 1M, $0.10/$0.50) thay Haiku 4.5 làm Haiku mặc định trên Anthropic API;
  sửa cache read **Sonnet 5.5 = $0.10**; nêu rõ **Opus 5.5 là model mặc định tài khoản** và **Fable không bao giờ mặc định**.
- Bổ sung tính năng mới: hook `onFailure: "block"` (≥2.1.295), Program Status Protocol OSC 7501 (≥2.1.295),
  `autoCompactWindow` và `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` (≥2.1.296).
- Sửa lỗi trình bày: bỏ backtick thừa trong code fence `bash` của nhóm lệnh, sửa anchor mục lục lệch heading,
  chuẩn hóa giọng "bạn" và tiêu đề tiếng Việt viết thường.

### Đợt biên tập hiểu-nhanh (10/2026)

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
