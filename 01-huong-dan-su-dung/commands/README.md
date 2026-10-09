# Index 78 lệnh Claude Code (theo nhóm)

> **Bài này cho ai:** bạn đã quen Claude Code và cần tra nhanh một lệnh slash cụ thể.
> **Cần gì trước:** đã đọc [04 — slash commands toàn tập](../04-slash-commands-toan-tap.md).
> **Đọc xong bạn làm được:** biết lệnh nào thuộc nhóm nào, mức rủi ro ra sao, và mở đúng file để đọc chi tiết.
> **Thời gian:** tra 1 lệnh ~10 giây.

Cách tra 10 giây: biết tên lệnh → `Ctrl+F` tìm `/tên` trong file này → mở `commands/<nhóm>/<lệnh>/`.
Chưa biết tên → đọc mô tả nhóm bên dưới → vào README nhóm → chọn lệnh.
Mỗi lệnh 1 file ~60 dòng theo 7 mục: nói nôm na → khi nào dùng → cách gọi → ví dụ thật + cách kiểm tra → lỗi hay gặp → tham khảo.
Trong session gõ `/` để xem lệnh nào hiện ở môi trường của bạn (version/provider khác nhau hiện khác nhau).

## Phiên làm việc & Context (18 lệnh) — [`session-context/`](./session-context/README.md)

> Mở, dọn, lưu, chia nhánh phiên mà không đụng code trên đĩa.

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/background](./session-context/background/README.md) | Thấp | Chạy task dài ở nền, trả terminal lại cho bạn |
| [/branch](./session-context/branch/README.md) | Không | Copy context sang nhánh thử nghiệm, bản chính giữ nguyên |
| [/clear](./session-context/clear/README.md) | Không | Xóa sạch hội thoại, bắt đầu phiên trắng |
| [/compact](./session-context/compact/README.md) | Không | Nén hội thoại dài thành bản tóm tắt cùng mạch task |
| [/context](./session-context/context/README.md) | Không | Xem context window đang đầy bao nhiêu, tốn gì |
| [/copy](./session-context/copy/README.md) | Không | Copy câu trả lời ra clipboard (Slack, PR, docs) |
| [/cost](./session-context/cost/README.md) | Không | Xem token/tiền đã dùng trong phiên |
| [/export](./session-context/export/README.md) | Không | Xuất hội thoại ra file để lưu trữ/bàn giao |
| [/fork](./session-context/fork/README.md) | Không | Copy context sang session mới, bản gốc giữ nguyên |
| [/help](./session-context/help/README.md) | Không | Tra cứu lệnh, cú pháp, phím tắt ngay trong session |
| [/recap](./session-context/recap/README.md) | Không | Tóm tắt nhanh việc đã làm khi quay lại sau break |
| [/rename](./session-context/rename/README.md) | Không | Đổi tên hiển thị session cho dễ nhớ |
| [/restart](./session-context/restart/README.md) | Không | Khởi động lại session khi treo/lag, giữ transcript |
| [/resume](./session-context/resume/README.md) | Không | Nạp lại transcript session cũ vào context |
| [/rewind](./session-context/rewind/README.md) | Có | Quay về checkpoint: xóa hội thoại sau đó + revert file |
| [/tasks](./session-context/tasks/README.md) | Không | Liệt kê/theo dõi job nền, kill job khi kẹt |
| [/todos](./session-context/todos/README.md) | Không | Xem/ghi todo list trong memory session |
| [/usage](./session-context/usage/README.md) | Không | Xem thống kê chi tiết token/chi phí theo phiên |

## Model & Permission Modes (7 lệnh) — [`model-mode/`](./model-mode/README.md)

> Đổi cách model suy nghĩ/chạy: model, effort, mode, mục tiêu, quyền.

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/effort](./model-mode/effort/README.md) | Không | Vặn độ sâu suy luận, không cần đổi model |
| [/extra-usage](./model-mode/extra-usage/README.md) | Không (tốn tiền thật) | Mua thêm quota khi hết hạn mức gói |
| [/fast](./model-mode/fast/README.md) | Không | Chế độ nhanh cho việc dễ, không chờ suy luận sâu |
| [/goal](./model-mode/goal/README.md) | Không (cần ≥2.1.139) | Đặt điều kiện hoàn thành, evaluator check mỗi turn |
| [/model](./model-mode/model/README.md) | Không | Đổi model giữa phiên (Haiku/Sonnet/Opus 5.5) |
| [/permissions](./model-mode/permissions/README.md) | Có nếu cấu hình ẩu | Dựng phanh allow/ask/deny cho tool |
| [/plan](./model-mode/plan/README.md) | Không | Chỉ đọc + viết plan, cấm sửa code tới khi duyệt |

## Code & Repo (17 lệnh) — [`code-repo/`](./code-repo/README.md)

> Làm việc với code: xem diff, review, verify chạy thật, batch song song, khởi tạo.

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/batch](./code-repo/batch/README.md) | Có nếu ẩu | Chia nhiều worktree/subagent chạy song song; coi chừng conflict + tốn quota |
| [/btw](./code-repo/btw/README.md) | Không | Hỏi nhanh một câu phụ, không sửa file, không ghi history |
| [/code-review](./code-repo/code-review/README.md) | Không | Review tự động, mặc định chỉ đọc + báo cáo |
| [/design-sync](./code-repo/design-sync/README.md) | Thấp | Đọc design rồi sinh/sửa code UI (version-gated) |
| [/diff](./code-repo/diff/README.md) | Không | Xem diff thay đổi, kính lúp bắt buộc sau mỗi bước thực thi |
| [/fewer-permission-prompts](./code-repo/fewer-permission-prompts/README.md) | Thấp | Đề xuất allowlist read-only để bớt bị hỏi quyền |
| [/init](./code-repo/init/README.md) | Không | Đọc repo rồi sinh CLAUDE.md + docs/settings |
| [/loop](./code-repo/loop/README.md) | Trung bình | Chạy lặp một task nhiều vòng; coi chừng tốn quota khi auto/bypass |
| [/pr_comments](./code-repo/pr_comments/README.md) | Không | Xử lý comment PR: sửa code theo góp ý |
| [/radio](./code-repo/radio/README.md) | Thấp | Hỏi-đáp + nghe realtime trong session (version-gated) |
| [/review](./code-repo/review/README.md) | Không | Review code trong context phiên hiện tại, chỉ đọc + nhận xét |
| [/run](./code-repo/run/README.md) | Thấp | Chạy app local theo recipe; tốn port/CPU, có thể ghi DB dev |
| [/run-skill-generator](./code-repo/run-skill-generator/README.md) | Không | Sinh file SKILL.md hướng dẫn chạy app |
| [/security-review](./code-repo/security-review/README.md) | Không | Quét bảo mật, chỉ đọc + báo cáo |
| [/subtask](./code-repo/subtask/README.md) | Thấp | Giao việc phụ cho session con trong cùng session (≥2.1.212) |
| [/ultrareview](./code-repo/ultrareview/README.md) | Không | Review sâu trong sandbox cách ly; tốn nhiều quota nhất |
| [/verify](./code-repo/verify/README.md) | Thấp | Build + chạy thật lấy output làm bằng chứng |

## Tri thức & Hệ thống (16 lệnh) — [`knowledge-system/`](./knowledge-system/README.md)

> Tra cứu, chẩn đoán, mở rộng: agents, MCP, hooks, skills, debug, doctor.

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/agents](./knowledge-system/agents/README.md) | Có nếu batch ẩu | Quản lý subagent chạy song song, context riêng |
| [/bug](./knowledge-system/bug/README.md) | Có nếu ẩu | Đóng gói bug report gửi Anthropic sau khi review |
| [/claude-api](./knowledge-system/claude-api/README.md) | Không | Migrate SDK, mẫu gọi Anthropic API, managed agents |
| [/debug](./knowledge-system/debug/README.md) | Không | Chẩn đoán session đang bệnh: treo, chậm, trả lời lạ |
| [/doctor](./knowledge-system/doctor/README.md) | Không | Audit repo: CLAUDE.md, permissions, MCP, hooks, plugin |
| [/hooks](./knowledge-system/hooks/README.md) | Có | Tự động hoá việc máy kiểm được, chạy shell ngoài model |
| [/insights](./knowledge-system/insights/README.md) | Không | Phân tích thói quen dùng, gợi ý tiết kiệm token |
| [/mcp](./knowledge-system/mcp/README.md) | Có nếu cấu hình ẩu | Kết nối tool ngoài: database, GitHub, browser... |
| [/mcp-serve](./knowledge-system/mcp-serve/README.md) | Trung bình | Biến Claude Code thành MCP server cho app khác |
| [/memory](./knowledge-system/memory/README.md) | Không | Quản lý bộ nhớ dài hạn giữa các session |
| [/plugin](./knowledge-system/plugin/README.md) | Có | Cài bundle skill + agent + hook + MCP một lần |
| [/plugin-validate](./knowledge-system/plugin-validate/README.md) | Không | Audit plugin/mod trước khi cài |
| [/rules](./knowledge-system/rules/README.md) | Không | Quy ước modular theo file/thư mục |
| [/simplify](./knowledge-system/simplify/README.md) | Không | Làm code gọn hơn, giữ nguyên tính năng |
| [/skill-doctor](./knowledge-system/skill-doctor/README.md) | Không | Báo cáo skill ngốn context / chết lâm sàng |
| [/stats](./knowledge-system/stats/README.md) | Không | Token, chi phí, hạn mức hôm nay |

## Auth, Remote & Settings (20 lệnh) — [`auth-settings/`](./auth-settings/README.md)

> Tài khoản, môi trường, cài đặt: login, IDE, config, remote, sandbox.

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/add-dir](./auth-settings/add-dir/README.md) | Có | Mở thêm thư mục vào session, không bỏ dir cũ (đa root, so sánh chéo) |
| [/cd](./auth-settings/cd/README.md) | Có | Đổi working dir giữa session, giữ history + prompt cache (≥2.1.169) |
| [/config](./auth-settings/config/README.md) | Có | Trung tâm cài đặt (alias /settings): permissions, MCP, hooks, env, account |
| [/exit](./auth-settings/exit/README.md) | Không | Thoát CLI, giữ auth + history (mai `--resume` vào lại) |
| [/ide](./auth-settings/ide/README.md) | Không | Kết nối VS Code/JetBrains: diff inline, jump-to-file |
| [/keybindings](./auth-settings/keybindings/README.md) | Không | Xem/remap phím tắt CLI (Ctrl, Alt, Esc, vim-style) |
| [/login](./auth-settings/login/README.md) | Không | Đăng nhập OAuth trình duyệt, lưu token local |
| [/logout](./auth-settings/logout/README.md) | Có nhẹ | Xoá token local, cắt session khỏi tài khoản |
| [/mobile](./auth-settings/mobile/README.md) | Có nhẹ | Pair điện thoại, điều khiển session từ xa |
| [/remote-env](./auth-settings/remote-env/README.md) | Có nhẹ | Cấu hình env + runtime phía remote/cloud |
| [/sandbox](./auth-settings/sandbox/README.md) | Không | Hộp cát: chạy thử cách ly, dependency status |
| [/setup-bedrock](./auth-settings/setup-bedrock/README.md) | Thấp | Wizard cắm Claude Code vào AWS Bedrock |
| [/setup-vertex](./auth-settings/setup-vertex/README.md) | Thấp | Wizard cắm Claude Code vào Google Vertex AI |
| [/status](./auth-settings/status/README.md) | Không | Bảng đồng hồ: acc, model, cwd, cache, quota, version |
| [/statusline](./auth-settings/statusline/README.md) | Không | Thanh trạng thái tuỳ biến hiện thường trực |
| [/teleport](./auth-settings/teleport/README.md) | Có nhẹ | Chuyển session giữa local ↔ cloud ↔ máy khác |
| [/terminal-setup](./auth-settings/terminal-setup/README.md) | Không | Fix terminal: Shift+Enter, truecolor, font theo từng app |
| [/theme](./auth-settings/theme/README.md) | Không | Đổi bảng màu CLI: sáng/tối, tương phản cao, mù màu |
| [/vim](./auth-settings/vim/README.md) | Không | Soạn prompt kiểu vim: normal/insert, hjkl |
| [/voice](./auth-settings/voice/README.md) | Không | Nói thay vì gõ: giữ Space để nói, thả để gửi |

[← Về 01-hướng dẫn sử dụng](../README.md)
