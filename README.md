# Khóa học Claude Code

Một bạn dev mới nghe tên Claude Code. Bạn hiểu terminal, nhưng chưa biết AI agent là gì. Đây là nơi bắt đầu — và kết thúc.

Bài học này không phải là tài liệu tham khảo để dò tìm. Nó là một khóa học: bạn đọc theo thứ tự, làm theo bài tập, và sau 5 ngày bạn dùng Claude Code như một đồng nghiệp.

## Bạn có nên đọc khóa học này không?

Nếu câu trả lời là có với ít nhất 1 trong 4 điều dưới đây, hãy đọc tiếp:

- Bạn chưa từng mở Claude Code.
- Bạn đã dùng nhưng hay bị lỗi, và không biết cách chẩn đoán.
- Bạn muốn dùng Claude Code để làm việc thật, không phải để hỏi hỏi.
- Bạn là tech lead, muốn chuẩn hóa cách dùng cho team.

Nếu bạn đã dùng Claude Code ổn định hàng ngày và không bị lỗi, có thể nhảy tới [`02-tips-thuc-chien/`](./02-tips-thuc-chien/) — phần dành cho người đã có nền tảng.

## Khóa học gồm 4 phần

Mỗi phần là một folder. Đọc theo thứ tự.

| Folder | Giống một | Có trong đó |
|---|---|---|
| [`01-huong-dan-su-dung/`](./01-huong-dan-su-dung/) | Sổ tay thao tác | 18 bài từ cài đặt tới output styles + 84 lệnh, mỗi lệnh 1 trang nhỏ |
| [`02-tips-thuc-chien/`](./02-tips-thuc-chien/) | Bài học sâu | 11 bài: giữ context sạch, viết prompt, plan, kiểm chứng, làm song song |
| [`03-cau-hoi-thuong-gap/`](./03-cau-hoi-thuong-gap/) | Sổ tay chữa bệnh | 10 bài Q&A, tra khi gặp lỗi |
| [`templates/`](./templates/) | File mẫu | Copy vào repo thật, sửa 20% là chạy |

## Lộ trình 5 ngày

Mỗi ngày khoảng 1 giờ. Không cần đọc hết một lần.

```text
Ngày 1: 01 bài 00 → 04 (tổng quan, cài đặt, surface, CLAUDE.md)
Ngày 2: 01 bài 05 → 07 (commands, skills, subagents, hooks)
Ngày 3: 01 bài 08 → 12 (MCP, plugins, permissions, worktrees, SDK/CI)
Ngày 4: 02 tips 01 → 05 (context, prompt, plan, verify, parallel)
Ngày 5: 02 tips 06 → 10 + 03 FAQ tra cứu khi gặp lỗi
```

Nếu không có 5 ngày: đọc [`01-huong-dan-su-dung/00-tong-quan-claude-code.md`](./01-huong-dan-su-dung/00-tong-quan-claude-code.md) trước — bài này giải thích toàn bộ khái niệm trong 25 phút.

## 4 quy tắc vàng

Nhớ 4 câu này là đủ 80% sức mạnh:

1. **Context là bottleneck, không phải model.** [`02-tips-thuc-chien/01`](./02-tips-thuc-chien/01-context-hygiene.md)
2. **Explore → Plan → Implement → Verify.** Không bao giờ code ngay task phức tạp.
3. **CLAUDE.md là gợi ý, hooks là luật.** Rule nào hay bị quên thì viết thành hook.
4. **Việc ồn ào đẩy sang subagent.** Main thread chỉ giữ quyết định.

## Phiên bản & nguồn

Claude Code **v2.1.x**, bản mới nhất tại thời điểm viết: **v2.1.296** (09/10/2026).

Kiểm tra máy bạn: `claude doctor` hoặc trong session gõ `/doctor` / `/status`.

> **Update 2026-10-28:** version data below was last pinned at v2.1.296 (09/10/2026). Before
> relying on any version-gated command, re-check the current release:
> `npm view @anthropic-ai/claude-code dist-tags` + `claude --version`, and the release notes at
> https://support.claude.com/en/articles/12138966-release-notes . Version-sensitive 2026 facts already
> covered in this repo: MCP protocol `2026-07-28` default negotiation (≥2.1.292), 4,096-char tool
> descriptions via tool search (≥2.1.295), auto mode as default permission mode for new sessions on
> Pro/Max/Team since w34/2026, and computer use / Remote Control (March 2026).
> New in this update: advanced MCP content (now in Vietnamese) in
> [`tool-use/mcp-advanced/README.md`](./tool-use/mcp-advanced/README.md), and a new lesson
> [`01-huong-dan-su-dung/17-output-styles-doi-vai-tro-va-giong-tra-loi.md`](./01-huong-dan-su-dung/17-output-styles-doi-vai-tro-va-giong-tra-loi.md)
> covering `/output-style`, built-in/custom styles and how they compare with CLAUDE.md/skills/hooks.

Tất cả số liệu version/model/giá trong repo được tập hợp tại [`WRITING-STYLE.md`](./WRITING-STYLE.md).

## Cách dùng repo này

- Đọc theo thứ tự file `00-*` → `NN-*` trong mỗi folder.
- Mọi code block đều copy-paste được.
- Gõ `/` trong Claude Code session để xem lệnh nào có ở máy bạn.
- Muốn đóng góp: đọc [`CONTRIBUTING.md`](./CONTRIBUTING.md) trước khi mở PR.

---

*Cập nhật lần cuối: 28/10/2026.*