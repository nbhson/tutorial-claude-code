# /subtask — giao việc phụ cho subagent tách nhánh, báo về ngay đây

> Loại Built-in (≥2.1.212) · Nhóm Song song & Ủy thác · Mức rủi ro Thấp
> **Nói nôm na:** `/subtask` (từ bản v2.1.212+) fork một subagent làm side task nhỏ rồi báo kết quả về ngay trong session này: tra 1 hàm, đọc 3 file, thử 1 hướng... Bạn không phải rời terminal, không detach như `/background`.

## Khi nào dùng

- Dùng `/subtask` khi cần một subagent làm việc phụ ngắn (tra hàm, đọc 3 file, thử 1 hướng) rồi báo về ngay session này.
- Giao subtask **giữa lúc đang code** để không phải rời mạch chính hay mở terminal khác.
- Không dùng nó cho việc quá rộng ("tóm tắt cả module"): càng rộng càng chậm và dễ lệch scope.

## Cách gọi

```bash
`/subtask <việc>`
`/subtask <việc> --readonly`
`/subtask <việc> --model <tên>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
# Đang viết middleware, quên verifyJWT trả về gì:
/subtask tìm hàm verifyJWT trong src/, cho signature + file:dòng --readonly --model haiku
# → 1 phút sau: "src/auth/jwt.ts:12 — verifyJWT(token: string): JWTPayload { sub, exp }"
# → bạn viết tiếp luôn, không mất mạch
```

**Kết quả mong đợi:**

- Trả kết quả việc phụ ngay trong session, gọn 1–2 dòng, bạn viết tiếp luôn không mất bối cảnh.
- Subagent tự compact sớm nếu frontmatter có `autoCompactWindow` (≥2.1.296); ép mọi workflow agent chạy 1 model bằng biến `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` (≥2.1.296).

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/subtask` báo unknown command | CLI < 2.1.212 | Update CLI mới nhất; tạm dùng `/background` hoặc tra tay |
| Subtask sửa luôn file chính | Quên `--readonly`, dặn "thử" mơ hồ | Rollback (`git checkout <file>`); lần sau readonly + file scratch rõ ràng |
| Kết quả về chậm (10 phút việc 2 phút) | Giao việc quá rộng ("tóm tắt cả module") | Chia nhỏ ("chỉ 3 file X, 5 dòng"); rộng → background |

## Tham khảo

- [../../session-context/background/README.md](../../session-context/background/README.md)
- [../../session-context/fork/README.md](../../session-context/fork/README.md)
- [../../knowledge-system/agents/README.md](../../knowledge-system/agents/README.md)
- [../../session-context/tasks/README.md](../../session-context/tasks/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/subtask` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
