# 02 — Tips thực chiến (11 bài)

> **Bài này cho ai:** bạn đã biết chạy Claude Code cơ bản nhưng muốn kết quả ổn định, ít lỗi, tiết kiệm token.
> **Cần gì trước:** đã cài và đăng nhập Claude Code, tốt nhất đã đọc xong folder [`01-huong-dan-su-dung/`](../01-huong-dan-su-dung/).
> **Đọc xong bạn làm được:**
> - Giữ context sạch, viết prompt rõ, plan trước khi code — 3 thói quen nền.
> - Chốt định nghĩa "xong việc" và bắt Claude chứng minh trước khi bạn gật đầu.
> - Chia việc cho nhiều agent song song, bật hooks/skills tái dùng, tiết kiệm cost.
>
> **Thời gian:** ~5 phút đọc mục lục, mỗi bài ~40 phút

## Thuật ngữ dùng ở trang này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Context | Bộ nhớ tạm của model trong 1 phiên, hết là model dở | dán 500 dòng log vào chat → model bắt đầu quên đầu file |
| Prompt | Lời bạn gõ cho Claude, gồm cả câu lệnh `/...` | "Sửa bug này nhưng đừng đổi API công khai" |
| Plan | Bản nháp việc cần làm Claude viết ra để bạn duyệt trước | `/plan` rồi gõ `yes` mới cho code |
| Parallel agent | Nhiều trợ lý con chạy cùng lúc, mỗi con một việc | 1 con test, 1 con viết docs, 1 con refactor |
| Hook | Script tự chạy khi tới một sự kiện, không qua model | chạy ESLint sau mỗi lần Claude sửa file |

## Mục lục

- [Mục tiêu folder](#mục-tiêu-folder)
- [Danh sách 11 bài](#danh-sách-11-bài)
- [Thứ tự đọc đề xuất](#thứ-tự-đọc-đề-xuất)
- [Link tra cứu](#link-tra-cứu)

## Mục tiêu folder

Section này trả lời câu: 11 bài trong folder gộp lại giúp bạn điều gì?

Folder này là phần "áp dụng" của khóa: folder `01` dạy bạn thao tác gì, folder này dạy **việc đó
đưa ra kết quả tốt hay không**. Mỗi bài theo cùng khung: lý thuyết gọn → ≥3 ví dụ copy-paste →
walkthrough theo phút → bảng so sánh → bài tập. Đọc hết 11 bài là bạn có đủ thói quen làm việc
hiệu quả với Claude Code hằng ngày.

## Danh sách 11 bài

Cần chọn nhanh bài hợp với việc đang làm → dùng bảng này: mỗi dòng là 1 bài, có mô tả 1 dòng và link.

| # | Bài | Mô tả 1 dòng | Link |
|---|-----|--------------|------|
| 01 | Vệ sinh context: kỹ năng quyết định 80% kết quả | Giữ ngữ cảnh sạch để model không "loạn" | [01-context-hygiene.md](./01-context-hygiene.md) |
| 02 | Prompt engineering: viết sao, ra vậy | Viết prompt rõ, cụ thể, kiểm chứng được | [02-prompt-engineering.md](./02-prompt-engineering.md) |
| 03 | Plan trước khi code: Explore → Plan → Implement | Lập kế hoạch, duyệt rồi mới implement | [03-plan-first-workflow.md](./03-plan-first-workflow.md) |
| 04 | Verification: bắt Claude chứng minh "done thật" | Định nghĩa xong-việc và kiểm chứng sau mỗi bước | [04-verification-done-that.md](./04-verification-done-that.md) |
| 05 | Parallel agents: nhân 3 sức mạnh mà không loạn | Chia việc cho nhiều agent chạy song song | [05-parallel-agents.md](./05-parallel-agents.md) |
| 06 | Hooks recipes: biến mọi rule hay quên thành luật | Công thức hooks dùng ngay cho dự án | [06-hooks-recipes.md](./06-hooks-recipes.md) |
| 07 | Thiết kế skills đáng tiền: chuẩn SOP, không phải ghi chép | Thiết kế skills tái dùng, đúng độ lớn | [07-thiet-ke-skills.md](./07-thiet-ke-skills.md) |
| 08 | Tiết kiệm cost & token (dùng Opus khi đáng, Haiku khi đủ) | Giảm token, giảm chi phí mà vẫn hiệu quả | [08-tiet-kiem-cost-token.md](./08-tiet-kiem-cost-token.md) |
| 09 | Teamwork: chuẩn hóa Claude Code cho cả team | Chuẩn hóa cách cả team dùng Claude Code | [09-teamwork-chuan-hoa.md](./09-teamwork-chuan-hoa.md) |
| 10 | Debug Claude Code theo 4 lớp từ ngoài vào trong + phím tắt ít người biết | Chiêu gỡ lỗi nâng cao với Claude Code | [10-debugging-power-moves.md](./10-debugging-power-moves.md) |
| 11 | Nâng cao Desktop & Web: extension, computer use, artifacts, remote, voice | Khai thác bản Desktop/Web cho workflow nặng | [11-nang-cao-desktop-web.md](./11-nang-cao-desktop-web.md) |

> Tên cột "Bài" lấy đúng tiêu đề H1 của từng file — bấm link vào là thấy ngay.

## Thứ tự đọc đề xuất

Chưa biết bắt đầu từ đâu → đọc theo thứ tự 4 nhóm dưới đây, mỗi nhóm 1 mục tiêu.

1. **Nền tảng (đọc trước):** 02 → 01 → 03 — viết prompt tốt, giữ context sạch, làm việc theo plan.
2. **Chất lượng:** 04 → 10 — định nghĩa "xong", rồi học chiêu debug.
3. **Mở rộng:** 05 → 06 → 07 — parallel agents, hooks, skills.
4. **Tối ưu & team:** 08 → 09 → 11 — tiết kiệm cost, chuẩn hóa team, nâng cao Desktop/Web.

Gói theo lộ trình 5 ngày của [`README.md` gốc](../README.md): ngày 4 đọc tips 01 → 05, ngày 5 đọc tips 06 → 10.

## Link tra cứu

Cần tra nhanh mà không muốn đọc bài dài → dùng các đường dẫn này:

- **Tra 1 lệnh bất kỳ:** [`01-huong-dan-su-dung/commands/`](../01-huong-dan-su-dung/commands/) — 78 lệnh, mỗi lệnh 1 folder.
- **Tổng quan thao tác:** [`01-huong-dan-su-dung/README.md`](../01-huong-dan-su-dung/README.md).
- **Gặp lỗi lạ:** [`03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md`](../03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md), rồi gõ `/doctor`.
- **Bảng tra 1 trang:** [`CHEATSHEET.md`](../CHEATSHEET.md) — in ra dán cạnh màn hình.
- **File mẫu copy-paste:** [`templates/`](../templates/) — `CLAUDE.md`, skills, agents, hooks, `.mcp.json`.
- **Số version/model/giá chuẩn:** [`WRITING-STYLE.md` — Phần B](../WRITING-STYLE.md#phần-b--dữ-kiện-chuẩn-làm-tròn-thời-gian-07102026).

**Kiểm tra nhanh:** mở được bảng 11 bài và 1 link chéo về `commands/`; chỉ ra được 3 bài nền tảng phải đọc trước; biết ngày 4–5 của lộ trình đọc tips nào.

> Mẹo 1 dòng: gặp lỗi lạ thì mở [`03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md`](../03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md) trước, rồi gõ `/doctor`.
