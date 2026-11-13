# /keybindings — Xem và đổi phím tắt: Ctrl, Alt, Esc, vim-style

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chỉ đổi phím — nhưng Có nhẹ nếu remap đè phím huỷ lệnh quen tay rồi bấm nhầm lúc nguy hiểm)
> **Nói nôm na:** `/keybindings` liệt kê và remap phím tắt CLI: gửi prompt, huỷ lệnh, duyệt permission, lịch sử, multi-line... Hiểu `/keybindings` là hiểu "sắp lại bàn phím cho vừa tay" — tay vim, tay Emacs, tay IDE đều có chỗ.

## Khi nào dùng

- Dùng khi phím mặc định không vừa tay (quen vim/Emacs/IDE) hoặc muốn xem/đổi/huỷ remap phím.
- Dùng **trước khi** quen tay với phím rồi bấm nhầm trong việc nguy hiểm: remap phím huỷ lệnh / phím duyệt permission cho gần tay, test kỹ trước khi vào task thật.
- Không dùng `/keybindings` thay cho việc tự remap ở terminal bên ngoài: phím bị terminal ăn mất thì phải sửa ở terminal, không phải trong CLI.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Danh sách phím tắt hiện ra; remap xong có hiệu lực ngay trong session.
- Phím huỷ lệnh (Ctrl+C) vẫn giữ 1 cách để không tự khoá đường thoát.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Remap xong bấm không ăn | Terminal/compositor ăn phím trước | `/terminal-setup` fix terminal; chọn phím khác ít đụng (Ctrl+G, Alt+...) |
| `Ctrl+C` không huỷ được nữa | Remap đè mất | `/keybindings reset cancel`; luôn giữ 1 cách huỷ quen |
| Sang máy mới phím khác | Local scope không đi theo | Sync `~/.claude/settings.json` tay hoặc cấu lại |

> **Cách đọc bảng này:** "Triệu chứng" là phím bấm không ăn hoặc ăn sai, "Vì sao" cho biết ai đã chặn trước, "Cách sửa" là bước gỡ kẹt — tra theo đúng hàng phím đang lỗi.

> **Tóm gọn 1 câu:** `/keybindings` là bẻ cong bàn phím theo tay mình — cứ thoải mái remap, miễn đừng đè mất lối thoát (phím huỷ lệnh).

## Tham khảo

- [../vim/README.md](../../auth-settings/vim/README.md)
- [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md)
- [../statusline/README.md](../../auth-settings/statusline/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /keybindings sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
