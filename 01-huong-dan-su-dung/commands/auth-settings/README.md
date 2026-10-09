# Nhóm: Auth, Remote & Settings (20 lệnh)

> Tài khoản, môi trường, cài đặt: login, IDE, config, remote, sandbox.

## Bộ 3 phải nhớ

> /login cắm chìa khóa 1 lần dùng nhiều tháng | /status soi account/provider/version | /sandbox thử đồ lạ trong cát

## Các lệnh (20)

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/add-dir](./add-dir/README.md) | Có | Mở thêm thư mục vào session, không bỏ dir cũ (đa root, so sánh chéo) |
| [/cd](./cd/README.md) | Có | Đổi working dir giữa session, giữ history + prompt cache (≥2.1.169) |
| [/config](./config/README.md) | Có | Trung tâm cài đặt (alias /settings): permissions, MCP, hooks, env, account |
| [/exit](./exit/README.md) | Không | Thoát CLI, giữ auth + history (mai `--resume` vào lại) |
| [/ide](./ide/README.md) | Không | Kết nối VS Code/JetBrains: diff inline, jump-to-file |
| [/keybindings](./keybindings/README.md) | Không | Xem/remap phím tắt CLI (Ctrl, Alt, Esc, vim-style) |
| [/login](./login/README.md) | Không | Đăng nhập OAuth trình duyệt, lưu token local |
| [/logout](./logout/README.md) | Có nhẹ | Xoá token local, cắt session khỏi tài khoản |
| [/mobile](./mobile/README.md) | Có nhẹ | Pair điện thoại, điều khiển session từ xa |
| [/remote-env](./remote-env/README.md) | Có nhẹ | Cấu hình env + runtime phía remote/cloud |
| [/sandbox](./sandbox/README.md) | Không | Hộp cát: chạy thử cách ly, dependency status |
| [/setup-bedrock](./setup-bedrock/README.md) | Thấp | Wizard cắm Claude Code vào AWS Bedrock |
| [/setup-vertex](./setup-vertex/README.md) | Thấp | Wizard cắm Claude Code vào Google Vertex AI |
| [/status](./status/README.md) | Không | Bảng đồng hồ: acc, model, cwd, cache, quota, version |
| [/statusline](./statusline/README.md) | Không | Thanh trạng thái tuỳ biến hiện thường trực |
| [/teleport](./teleport/README.md) | Có nhẹ | Chuyển session giữa local ↔ cloud ↔ máy khác |
| [/terminal-setup](./terminal-setup/README.md) | Không | Fix terminal: Shift+Enter, truecolor, font theo từng app |
| [/theme](./theme/README.md) | Không | Đổi bảng màu CLI: sáng/tối, tương phản cao, mù màu |
| [/vim](./vim/README.md) | Không | Soạn prompt kiểu vim: normal/insert, hjkl |
| [/voice](./voice/README.md) | Không | Nói thay vì gõ: giữ Space để nói, thả để gửi |

## Sơ đồ quyết định (30 giây)

```text
Cần gì? -> Nhóm này cho gì? -> Lệnh nào?
Đọc 3 lệnh trong "Bộ 3" trước, còn lại tra khi cần.
Gõ / trong session để xem lệnh nào hiện ở máy bạn.
```

## Cách dùng nhóm này cho đúng

```bash
# 1. Học 3 lệnh trụ trước (xem "Bộ 3 phải nhớ" ở trên)
# 2. Còn lại tra khi gặp việc thật, đừng học hết 1 lúc
# 3. Lỗi lạ trong nhóm này -> /status -> /doctor -> đọc lệnh tương ứng
```

[← Về index tất cả lệnh](../README.md)
