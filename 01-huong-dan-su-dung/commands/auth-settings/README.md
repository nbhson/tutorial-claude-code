# /auth-settings — nhóm 20 lệnh về tài khoản, môi trường và cài đặt

> **Loại:** index nhóm lệnh · **Nhóm:** Auth, Remote & Settings · **Mức rủi ro:** thấp (đụng account/config, không đụng code)
> **Nói nôm na:** nhóm này là nơi bạn "đăng nhập, hiệu chỉnh, thử an toàn" — login/logout, IDE, config, remote, sandbox. Sai 1 dòng config có thể làm mọi lệnh khác trong session chạy sai, nên coi rủi ro là thật.

## Khi nào dùng

- Bạn cần vào/ra (login/logout), đổi môi trường (remote-env, setup-bedrock, setup-vertex), hay nối IDE/mobile/teleport.
- Bạn muốn dò nhanh tài khoản/quota/version hiện tại bằng `/status`, hoặc thử đồ lạ trong sandbox an toàn.
- Bạn chưa sửa code gì cả mà session đã chạy sai/không đăng nhập được → nhóm này xử lý trước, không cần group khác.

## Cách gọi

```bash
# gõ / trong session, gõ chữ đầu lệnh để lọc
/login
/status
/sandbox
```

Kiểm tra lệnh có ở máy bạn không: mở session, gõ `/` rồi gõ tiếp chữ đầu lệnh — version/provider khác nhau hiện lệnh khác nhau.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Bạn mới clone repo, chưa login:

```bash
/login
```

- Mong đợi: trình duyệt mở, bạn xác thực xong, token lưu local, session chạy được lệnh cần account.
- Kiểm tra (≤30 giây): gõ `/status` → thấy tên account + version hiện; không còn thông báo "not logged in".

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Gõ `/login` mà không ra trình duyệt, hoặc login xong vẫn báo sai provider | Máy bạn cấu hình bằng API key/Bedrock/Vertex chứ không phải OAuth claude.ai | Dùng `/setup-bedrock`, `/setup-vertex` hoặc `/config` để chọn đúng provider |
| Version của bạn thấp hơn version tối thiểu của 1 lệnh trong nhóm (vd /cd cần ≥2.1.169) | Lệnh chưa có trên bản cũ | Chạy `claude --version`, update bằng `claude update`, rồi thử lại |
| `/status` hiện quota về 0, lệnh bị chặn giữa chừng | Hết hạn mức gói trong phiên 5 giờ | Chờ reset, nâng gói, hoặc bật usage credits |

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

## Tham khảo

- [← Về index tất cả lệnh](../README.md)
- [04 — slash commands toàn tập](../../04-slash-commands-toan-tap.md)
- [Nhóm model-mode](../model-mode/README.md) · [Nhóm code-repo](../code-repo/README.md)

> Mẹo 1 dòng: _chạm vào login/config xong luôn gõ /status kiểm tra, đừng đi tiếp khi chưa chắc account đang đúng._
