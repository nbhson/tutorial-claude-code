# /branch — Tạo nhánh thử nghiệm what-if từ conversation hiện tại

> Loại Built-in · Nhóm Session & Context · Mức rủi ro Không (không xóa/sửa file; chỉ copy context sang nhánh thử nghiệm — an toàn nếu kết hợp git riêng)
> **Nói nôm na:** `/branch` giống `/fork` nhưng mang ngữ nghĩa "thử giả thuyết": tách 1 nhánh what-if để trả lời "nếu làm theo cách B thì sao?", trong khi nhánh chính vẫn đi cách A.

## Khi nào dùng

- Dùng `/branch` khi bạn muốn thử một giả thuyết "nếu làm cách B thì sao?" mà nhánh chính vẫn đi cách A.
- Dùng `/branch` cho câu hỏi what-if ngắn, chỉ đọc để có số liệu trước khi quyết định.
- Không dùng `/branch` như fork cho hướng dài — nhánh thử vẫn chung filesystem, muốn tách code phải dùng git riêng.

## Cách gọi

```bash
`/branch`
`/branch <giả-thuyết>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Nhánh chính đang dùng Zod lỏng, muốn biết strict thì vỡ bao nhiêu chỗ
/branch Nếu bật Zod strict cho packages/billing/, liệt kê số lỗi type và ước lượng giờ fix. Không sửa file, chỉ báo cáo.
# → 20 phút sau có con số để quyết định, nhánh chính không nhiễm
```

Kết quả mong đợi:

- Claude trả đúng việc của /branch (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Nhánh thử sửa hỏng code nhánh chính | Chung filesystem | Dùng `git worktree` riêng; hoặc chỉ cho nhánh thử quyền đọc (`--permission-mode plan`) |
| Không phân biệt branch/fork | Ngữ nghĩa gần nhau | What-if ngắn → branch; rẽ hướng dài → fork. Về kỹ thuật gần như nhau |
| Picker đầy nhánh thử cũ | Không dọn | Đặt tên ngày + bỏ resume nhánh thua; xóa `.jsonl` nếu nhạy cảm |

## Tham khảo

- [../fork/README.md](../../session-context/fork/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- [../rename/README.md](../../session-context/rename/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /branch sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
