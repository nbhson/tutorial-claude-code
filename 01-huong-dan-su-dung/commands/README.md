# Index 64 lệnh `/...` — tra cứu chi tiết từng lệnh

> Quy ước: mỗi dòng là `/slug` — 1 dòng mô tả — link tới `./<slug>/README.md`.
> Tổng **64 slugs** = 64 thư mục con trong `commands/`
> (`ls -F ... | grep -c '/$'`; `ls ... | wc -l` trả 65 vì tính cả file README.md này).

## Cách tra cứu

- Biết tên lệnh → mở trực tiếp `./<slug>/README.md` (vd `./plan/README.md`).
- Không nhớ tên → tìm theo 1 trong 4 nhóm bên dưới.
- Từ repo root: `01-huong-dan-su-dung/commands/<slug>/README.md`.

## 1. Session & Context — phiên làm việc, ngữ cảnh, chi phí (21)

| Lệnh | Mô tả | Link |
|------|-------|------|
| `/clear` | Xóa hội thoại, bắt đầu task mới sạch | [README](./clear/README.md) |
| `/compact` | Nén ngữ cảnh dài để tiếp tục làm việc | [README](./compact/README.md) |
| `/context` | Xem dung lượng/chi tiết context hiện tại | [README](./context/README.md) |
| `/cost` | Xem chi phí token ước tính của phiên | [README](./cost/README.md) |
| `/usage` | Xem mức dùng quota/subscription | [README](./usage/README.md) |
| `/extra-usage` | Bật/tắt dùng thêm ngoài quota (với `/fast`) | [README](./extra-usage/README.md) |
| `/stats` | Thống kê hoạt động phiên | [README](./stats/README.md) |
| `/insights` | Phân tích insight về cách dùng | [README](./insights/README.md) |
| `/export` | Xuất hội thoại/phiên ra file | [README](./export/README.md) |
| `/resume` | Tiếp tục phiên cũ theo ID | [README](./resume/README.md) |
| `/fork` | Rẽ nhánh phiên để thử hướng khác | [README](./fork/README.md) |
| `/branch` | Quản lý nhánh hội thoại | [README](./branch/README.md) |
| `/rename` | Đổi tên phiên hiện tại | [README](./rename/README.md) |
| `/rewind` | Quay lui về checkpoint trước (menu double-Esc) | [README](./rewind/README.md) |
| `/todos` | Quản lý checklist việc đang làm | [README](./todos/README.md) |
| `/tasks` | Quản lý task nền/background | [README](./tasks/README.md) |
| `/copy` | Sao chép nội dung hội thoại | [README](./copy/README.md) |
| `/btw` | Hỏi nhanh, không ghi vào history | [README](./btw/README.md) |
| `/help` | Trợ giúp, liệt kê lệnh | [README](./help/README.md) |
| `/exit` | Thoát phiên/CLI | [README](./exit/README.md) |
| `/status` | Xem trạng thái phiên và môi trường | [README](./status/README.md) |

## 2. Model–Mode–Code — model, chế độ chạy, viết & kiểm chứng code (20)

| Lệnh | Mô tả | Link |
|------|-------|------|
| `/model` | Chọn model (opus / sonnet / haiku) | [README](./model/README.md) |
| `/effort` | Mức nỗ lực suy luận (low…max, auto) | [README](./effort/README.md) |
| `/fast` | Chế độ nhanh (kèm `/extra-usage`) | [README](./fast/README.md) |
| `/permissions` | Xem/sửa phân quyền tool | [README](./permissions/README.md) |
| `/sandbox` | Chạy trong sandbox cách ly | [README](./sandbox/README.md) |
| `/plan` | Lập kế hoạch trước khi code (plan-first) | [README](./plan/README.md) |
| `/goal` | Đặt mục tiêu/điều kiện hoàn thành (`clear` để xóa) | [README](./goal/README.md) |
| `/loop` | Lặp lại tác vụ tới khi đạt điều kiện | [README](./loop/README.md) |
| `/batch` | Chạy hàng loạt tác vụ | [README](./batch/README.md) |
| `/verify` | Kiểm chứng kết quả (≥2.1.145) | [README](./verify/README.md) |
| `/review` | Review code hiện tại | [README](./review/README.md) |
| `/code-review` | Review code theo PR/branch | [README](./code-review/README.md) |
| `/ultrareview` | Review sâu nhiều vòng | [README](./ultrareview/README.md) |
| `/pr_comments` | Xem/bình luận PR | [README](./pr_comments/README.md) |
| `/diff` | Xem diff thay đổi | [README](./diff/README.md) |
| `/simplify` | Đơn giản hóa code | [README](./simplify/README.md) |
| `/design-sync` | Đồng bộ thiết kế ↔ code | [README](./design-sync/README.md) |
| `/claude-api` | Gọi Claude API trực tiếp | [README](./claude-api/README.md) |
| `/radio` | Kênh/tín hiệu điều phối (theo provider) | [README](./radio/README.md) |
| `/cd` | Đổi thư mục làm việc (≥2.1.169) | [README](./cd/README.md) |

## 3. Tri thức & Hệ thống — agents, hooks, MCP, cấu hình (16)

| Lệnh | Mô tả | Link |
|------|-------|------|
| `/agents` | Quản lý subagents | [README](./agents/README.md) |
| `/hooks` | Xem/sửa hooks tự động hóa | [README](./hooks/README.md) |
| `/mcp` | Quản lý MCP servers (reconnect/enable/disable) | [README](./mcp/README.md) |
| `/plugin` | Quản lý plugins | [README](./plugin/README.md) |
| `/memory` | Quản lý bộ nhớ dài hạn | [README](./memory/README.md) |
| `/rules` | Xem/sửa rules dự án | [README](./rules/README.md) |
| `/config` | Cấu hình chung | [README](./config/README.md) |
| `/doctor` | Chẩn đoán môi trường (`/checkup`) | [README](./doctor/README.md) |
| `/debug` | Chế độ gỡ lỗi chi tiết | [README](./debug/README.md) |
| `/bug` | Báo lỗi về Claude Code | [README](./bug/README.md) |
| `/ide` | Tích hợp IDE | [README](./ide/README.md) |
| `/theme` | Đổi theme giao diện | [README](./theme/README.md) |
| `/keybindings` | Xem/sửa phím tắt | [README](./keybindings/README.md) |
| `/vim` | Chế độ/chỉnh sửa kiểu Vim | [README](./vim/README.md) |
| `/statusline` | Tùy biến dòng trạng thái | [README](./statusline/README.md) |
| `/terminal-setup` | Thiết lập terminal tối ưu | [README](./terminal-setup/README.md) |

## 4. Auth–Remote–Settings — xác thực, thiết bị, thư mục (7)

| Lệnh | Mô tả | Link |
|------|-------|------|
| `/login` | Đăng nhập tài khoản | [README](./login/README.md) |
| `/logout` | Đăng xuất | [README](./logout/README.md) |
| `/mobile` | Liên kết/điều khiển qua mobile | [README](./mobile/README.md) |
| `/remote-env` | Quản lý môi trường remote | [README](./remote-env/README.md) |
| `/teleport` | Chuyển phiên giữa máy/thiết bị | [README](./teleport/README.md) |
| `/add-dir` | Thêm thư mục vào workspace (`--add-dir`) | [README](./add-dir/README.md) |
| `/init` | Khởi tạo dự án (tạo CLAUDE.md, settings ban đầu) | [README](./init/README.md) |

## Ghi chú version / provider

- Một số lệnh yêu cầu version tối thiểu: `/verify` (≥2.1.145), `/cd` (≥2.1.169).
  Kiểm tra version bằng `claude --version` và chạy `/doctor` khi lệnh không khả dụng.
- Hành vi có thể khác theo provider/subscription (quota, `/extra-usage`, `/fast`):
  đối chiếu `/usage`, `/cost` và tài liệu gói đang dùng.
