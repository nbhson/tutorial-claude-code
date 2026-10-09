# Khóa học Claude Code — từ Zero tới Pro (2026)

> **Bộ tài liệu tiếng Việt** về **Claude Code v2.1.x**, đối chiếu với docs chính thức
> [`code.claude.com/docs`](https://code.claude.com/docs/en/).
> Mọi code block đều copy-paste được. Học xong bạn tự cài được, tự fix lỗi thường gặp, tự dạy lại cho team.

- **Bài này cho ai:** dev viết code, mới nghe tới Claude Code hoặc đã thử rồi hay bị lỗi.
- **Cần gì trước:** biết dùng terminal cơ bản (`cd`, `git clone`). Không cần biết AI.
- **Đọc xong bạn làm được:**
  - Cài sạch 1 bản Claude Code, đăng nhập, chạy `claude` trong repo đầu tiên trong 15 phút.
  - Tự chẩn đoán lỗi bằng `/status` → `claude doctor` → `/debug` → `/bug`.
  - Viết được skills, subagents, hooks, gắn MCP, chia việc bằng worktree, chạy CI headless.
  - Chuẩn hóa `CLAUDE.md` + `.claude/` + permission baseline cho cả team.

## Khóa này có hợp với bạn không?

| Nếu bạn là... | Sau khóa học bạn sẽ làm được |
|---|---|
| Dev mới nghe tên Claude Code | Cài sạch 1 bản duy nhất, `claude login`, `/init` repo đầu tiên trong 15 phút |
| Dev đã dùng nhưng hay bị lỗi vặt | Hết `Unknown command`, hết duplicate install, biết `/doctor` → `/debug` → `/bug` |
| Dev muốn lên pro | Viết skills, subagents, hooks, gắn MCP, chia batch/worktree, chạy CI headless |
| Tech lead | Chuẩn hóa `CLAUDE.md` + `.claude/` + permissions baseline cho cả team |

Điều kiện duy nhất: biết dùng terminal cơ bản (`cd`, `git clone`). Không cần biết AI.

## Khóa học gồm gì? (mỗi phần = 1 folder)

| Folder | Đây là gì? | Trong đó có gì |
|---|---|---|
| [`01-huong-dan-su-dung/`](./01-huong-dan-su-dung/) | **Sổ tay thao tác**: cài đặt, bề mặt dùng, cấu hình nền tảng | 17 bài (00→16) + `commands/` — 78 lệnh, mỗi lệnh 1 folder: làm gì → khi nào dùng → cách gọi → ví dụ thật → lỗi hay gặp |
| [`02-tips-thuc-chien/`](./02-tips-thuc-chien/) | **Cách dùng cho ra kết quả**: giữ context sạch, viết prompt, plan trước, kiểm chứng, làm việc song song | 11 bài deep-dive (lý thuyết gọn + ≥3 ví dụ + walkthrough + bẫy thường gặp) |
| [`03-cau-hoi-thuong-gap/`](./03-cau-hoi-thuong-gap/) | **Sổ tay chữa bệnh**: tra khi gặp lỗi hoặc chưa biết chọn gì | 10 bài Q&A — mỗi câu: hỏi → trả lời 1 câu → giải thích → lệnh copy-paste → vẫn lỗi thì làm gì |
| [`templates/`](./templates/) | **File mẫu copy-paste** | `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, hooks, `.mcp.json` — copy vào repo thật, sửa 20% là chạy |
| [`CHEATSHEET.md`](./CHEATSHEET.md) | **Bảng tra nhanh 1 trang** | Mỗi lệnh kèm ví dụ mini — in ra dán cạnh màn hình |

> Mới bắt đầu? Đọc theo thứ tự file `00-*` → `16-*` trong mỗi folder (đã đánh số sẵn).

## Lộ trình học 5 ngày (mỗi ngày ~1 giờ)

```text
Ngày 1: 01 bài 00 → 04 (tổng quan, cài đặt, bề mặt dùng, CLAUDE.md)
Ngày 2: 01 bài 05 → 07 (commands, skills, subagents, hooks)
Ngày 3: 01 bài 08 → 12 (MCP, plugins, permissions, worktrees, SDK/CI)
Ngày 4: 02 tips 01 → 05 (context, prompt, plan, verify, parallel)
Ngày 5: 02 tips 06 → 10 + 03 FAQ tra cứu khi gặp lỗi
```

Hai đường dẫn bạn sẽ dùng nhiều nhất:

- **Tra cứu 1 lệnh bất kỳ:** `01-huong-dan-su-dung/commands/<tên-lệnh>/`
  (vd [`commands/model-mode/plan/`](./01-huong-dan-su-dung/commands/model-mode/plan/)).
- **Gặp lỗi lạ:** mở [`03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md`](./03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md)
  trước, rồi gõ `/doctor`.

## 4 quy tắc vàng (nhớ 4 câu này là đủ 80% sức mạnh)

1. **Context là bottleneck, không phải model** — giữ context sạch ([`02-tips-thuc-chien/01`](./02-tips-thuc-chien/01-context-hygiene.md)).
2. **Explore → Plan → Implement → Verify** — không bao giờ code ngay task phức tạp.
3. **CLAUDE.md là gợi ý, hooks là luật** — rule nào hay bị quên thì viết thành hook.
4. **Việc ồn ào đẩy sang subagent** — main thread chỉ giữ quyết định.

## Phiên bản & nguồn

- Claude Code **v2.1.x**, bản mới nhất tra soát lúc viết: **v2.1.292** (06/10/2026).
  Kiểm tra máy bạn: `claude doctor` hoặc trong session gõ `/doctor` / `/status`.
- Docs gốc: https://code.claude.com/docs/en/ — file index: https://code.claude.com/docs/llms.txt
- Changelog đầy đủ: https://code.claude.com/docs/en/changelog
- Một số lệnh chỉ có ở bản mới hơn: `/verify` (≥2.1.145), `/cd` (≥2.1.169), `/goal` (≥2.1.139),
  `/skill-doctor` (≥2.1.252), trim CLAUDE.md trong `/doctor` (≥2.1.206).
  Gõ `/` trong session để xem lệnh nào hiện ở máy bạn — version và nhà cung cấp (provider) khác nhau thì thấy khác nhau.
- Toàn bộ số liệu version/model/giá dùng trong repo được tập hợp tại [`WRITING-STYLE.md` — Phần B](./WRITING-STYLE.md#phần-b--dữ-kiện-chuẩn-làm-tròn-thời-gian-07102026).

## Cách dùng repo này

- Đọc theo thứ tự file `00-*` → `NN-*` trong mỗi folder (đã đánh số).
- Mọi code block đều copy-paste được. Template trong `templates/` dùng được ngay.
- Gõ `/` trong Claude Code session để xem lệnh khả dụng ở môi trường của bạn.
- Muốn đóng góp: đọc [`CONTRIBUTING.md`](./CONTRIBUTING.md) 5 phút trước khi mở PR
  (và [`WRITING-STYLE.md`](./WRITING-STYLE.md) nếu sửa nội dung).
