# Nhóm: Code & Repo (17 lệnh)

> Làm việc với code: xem diff, review, verify chạy thật, batch song song, khởi tạo.

## Bộ 3 phải nhớ

> /diff duyệt từng hunk sau mỗi bước | /verify build + chạy thật lấy output | /batch chia worktree song song

## Các lệnh (17)

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/batch](./batch/README.md) | Có nếu ẩu | Chia nhiều worktree/subagent chạy song song; coi chừng conflict + tốn quota |
| [/btw](./btw/README.md) | Không | Hỏi nhanh một câu phụ, không sửa file, không ghi history |
| [/code-review](./code-review/README.md) | Không | Review tự động, mặc định chỉ đọc + báo cáo |
| [/design-sync](./design-sync/README.md) | Thấp | Đọc design rồi sinh/sửa code UI (version-gated) |
| [/diff](./diff/README.md) | Không | Xem diff thay đổi, kính lúp bắt buộc sau mỗi bước thực thi |
| [/fewer-permission-prompts](./fewer-permission-prompts/README.md) | Thấp | Đề xuất allowlist read-only để bớt bị hỏi quyền |
| [/init](./init/README.md) | Không | Đọc repo rồi sinh CLAUDE.md + docs/settings |
| [/loop](./loop/README.md) | Trung bình | Chạy lặp một task nhiều vòng; coi chừng tốn quota khi auto/bypass |
| [/pr_comments](./pr_comments/README.md) | Không | Xử lý comment PR: sửa code theo góp ý |
| [/radio](./radio/README.md) | Thấp | Hỏi-đáp + nghe realtime trong session (version-gated) |
| [/review](./review/README.md) | Không | Review code trong context phiên hiện tại, chỉ đọc + nhận xét |
| [/run](./run/README.md) | Thấp | Chạy app local theo recipe; tốn port/CPU, có thể ghi DB dev |
| [/run-skill-generator](./run-skill-generator/README.md) | Không | Sinh file SKILL.md hướng dẫn chạy app |
| [/security-review](./security-review/README.md) | Không | Quét bảo mật, chỉ đọc + báo cáo |
| [/subtask](./subtask/README.md) | Thấp | Giao việc phụ cho session con trong cùng session (≥2.1.212) |
| [/ultrareview](./ultrareview/README.md) | Không | Review sâu trong sandbox cách ly; tốn nhiều quota nhất |
| [/verify](./verify/README.md) | Thấp | Build + chạy thật lấy output làm bằng chứng |

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
