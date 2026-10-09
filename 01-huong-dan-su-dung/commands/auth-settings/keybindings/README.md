# /keybindings — Xem và đổi phím tắt: Ctrl, Alt, Esc, vim-style

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chỉ đổi phím — nhưng Có nhẹ nếu remap đè phím huỷ lệnh quen tay rồi bấm nhầm lúc nguy hiểm)
> **Nói nôm na:** `/keybindings` liệt kê và remap phím tắt CLI: gửi prompt, huỷ lệnh, duyệt permission, lịch sử, multi-line... Hiểu `/keybindings` là hiểu "sắp lại bàn phím cho vừa tay" — tay vim, tay Emacs, tay IDE đều có chỗ.

## Khi nào dùng

- Dùng khi phím mặc định không vừa tay (quen vim/Emacs/IDE) hoặc muốn xem/đổi/huỷ remap phím.
- Dùng **trước khi** quen tay với phím rồi bấm nhầm trong việc nguy hiểm: remap phím huỷ lệnh / phím duyệt permission cho gần tay, test kỹ trước khi vào task thật.
- Không dùng `/keybindings` thay cho việc tự remap ở terminal bên ngoài: phím bị terminal ăn mất thì phải sửa ở terminal, không phải trong CLI.

## Cách gọi

```bash
`/keybindings`
`/keybindings set <hành-động> <phím>`
`/keybindings reset`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Gõ prompt 2 dòng, Shift+Enter lại gửi mất:
/keybindings
# → Multiline: Shift+Enter (đúng rồi — vậy là terminal ăn mất, không phải CLI sai)
# → sang /terminal-setup fix theo terminal đang dùng (iTerm2/VSCode/Kitty...)
# → quay lại test: Shift+Enter xuống dòng ✓
```

Kết quả mong đợi:

- Claude trả đúng việc của /keybindings (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Kiểm tra nhanh:**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Remap xong bấm không ăn | Terminal/compositor ăn phím trước | `/terminal-setup` fix terminal; chọn phím khác ít đụng (Ctrl+G, Alt+...) |
| `Ctrl+C` không huỷ được nữa | Remap đè mất | `/keybindings reset cancel`; luôn giữ 1 cách huỷ quen |
| Sang máy mới phím khác | Local scope không đi theo | Sync `~/.claude/settings.json` tay hoặc cấu lại |

## Tham khảo

- [../vim/README.md](../../auth-settings/vim/README.md)
- [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md)
- [../statusline/README.md](../../auth-settings/statusline/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /keybindings sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
