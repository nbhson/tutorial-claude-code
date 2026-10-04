# 00 — Tổng Quan Claude Code: Tư Duy Agent, Không Phải Chatbot

## 1. Claude Code là gì?

**Claude Code** là coding agent của Anthropic: một CLI (và IDE/Desktop/Web app) chạy model Claude
với quyền truy cập trực tiếp filesystem + terminal. Khác chatbot ở chỗ:

| Chatbot (claude.ai chat) | Claude Code (agentic loop) |
|---|---|
| Bạn paste code vào, nó trả lời text | Nó tự đọc file, sửa file, chạy lệnh, xem kết quả, lặp lại tới khi xong |
| 1 lượt request → 1 response | 1 task → N vòng: reasoning → tool_use → observation → reasoning tiếp |
| Không làm gì ngoài text | Có tools: Read, Edit, Write, Glob, Grep, Bash, WebSearch, WebFetch, Task (spawn subagent), MCP tools |

Vòng lặp agentic cốt lõi (giống nhau trên mọi surface — terminal, IDE, desktop, web):

```
Bạn prompt → Claude reasoning → gọi tools (đọc/sửa/chạy) → đọc kết quả trả về
→ reasoning tiếp → ... → khi đạt mục tiêu thì dừng, báo cáo + diff
```

## 2. Claude Code làm được gì (thực tế)

- **Build feature / fix bug đa file**: mô tả ý định, nó tự tìm file liên quan, sửa, chạy test.
- **Việc nhàm chán**: viết test cho code chưa có test, fix lint toàn repo, resolve merge conflict,
  upgrade dependency, viết release notes.
- **Git/GitHub**: stage, commit message, tạo branch, mở PR, đọc PR comments (`/pr_comments`).
- **Kết nối công cụ ngoài qua MCP**: đọc Google Drive, Jira, Slack, DB, browser (Playwright).
- **Tự động hóa**: hooks (chạy eslint sau mỗi edit), routines (`/schedule` chạy định kỳ),
  CI/CD (GitHub Actions), Agent SDK (build agent riêng).

## 3. Các bề mặt sử dụng (surfaces) — chọn cái nào?

| Surface | Code chạy ở đâu | Dùng local config? | Khi nào dùng |
|---|---|---|---|
| **Terminal CLI** (`claude`) | Máy bạn | Có | Mặc định, mạnh nhất, hỗ trợ mọi provider |
| **VS Code / JetBrains extension** | Máy bạn | Có | Cần inline diff, @-mention, plan review trong editor |
| **Desktop app** | Máy bạn hoặc cloud VM | Local: có / Cloud: không | Muốn review diff trực quan, multi-session side-by-side, lên lịch task |
| **Web** (`claude.ai/code`) | Anthropic cloud VM | Không (chỉ repo) | Task dài, không cần local setup, chạy song song, check từ điện thoại |
| **Mobile (iOS/Android) + Remote Control** | Máy bạn (qua remote) / cloud | Tùy loại session | Monitor session từ điện thoại, `/mobile` hiện QR |
| **Slack, CI/CD** | Cloud/CI runner | Tùy cấu hình | Team workflow, auto-fix PR |

> Hành vi agent **giống nhau mọi nơi** — chỉ khác nơi code chạy và config nào được dùng.

So sánh nhanh Web vs Remote vs CLI vs Desktop:

| | Web | Remote Control | Terminal CLI | Desktop |
|---|---|---|---|---|
| Chạy trên | Cloud VM | Máy bạn | Máy bạn | Máy bạn hoặc cloud |
| Chat từ | Browser/mobile app | claude.ai/mobile | Terminal | Desktop UI |
| Cần GitHub | Có | Không | Không | Chỉ với cloud session |
| Chạy tiếp khi disconnect | Có | Khi terminal còn mở | Không | Tùy loại session |

## 4. Bản đồ extension: CLAUDE.md / Skills / Subagents / Hooks / MCP / Plugins

Đây là lớp mở rộng trên vòng lặp agentic. Học thuộc bảng này:

| Feature | Nó là gì | Khi nào dùng | Ví dụ |
|---|---|---|---|
| **CLAUDE.md** | Context nạp mỗi session | Quy ước "luôn luôn làm X" | "Dùng pnpm, không dùng npm. Chạy test trước khi commit." |
| **Skill** | Kiến thức + workflow tái dùng, gọi bằng `/ten` hoặc Claude tự load | Việc lặp lại, tài liệu tham khảo | `/deploy` chạy checklist deploy; skill API style-guide |
| **Subagent** | Worker chạy context riêng, trả về tóm tắt | Task ồn ào, task song song, chuyên gia hẹp | Research đọc 50 file nhưng chỉ trả về 10 dòng kết luận |
| **Agent teams** | Nhiều session phối hợp (lead + teammates) | Nghiên cứu song song, review đa góc | Reviewers check security + perf + tests cùng lúc |
| **Code intelligence** | Language-server: jump-to-def, type errors live | Ngôn ngữ typed, repo lớn grep chậm | Nhảy tới definition thay vì đọc cả file |
| **MCP** | Kết nối dịch vụ ngoài | Dữ liệu/hành động ngoài repo | Query DB, post Slack, điều khiển browser |
| **Hook** | Script chạy khi tới lifecycle event | Việc **phải** chạy mỗi lần, không được quên | Chạy ESLint sau mỗi lần edit file |
| **Plugin / Marketplace** | Đóng gói skills+hooks+subagents+MCP thành 1 unit cài được | Tái dùng cross-repo, share cho team | Plugin `security-review` cài 1 phát cho mọi repo |

Quy tắc chọn nhanh:

- Fact cần **mọi session** → `CLAUDE.md`.
- Quy tắc cho **1 subtree** → `.claude/rules/` (có `paths` frontmatter).
- Kiến thức/workflow **tái dùng, load khi cần** → Skill.
- Việc **cô lập context** → Subagent.
- Hệ thống ngoài / tool custom → MCP.
- Hành động **deterministic theo event** → Hook.
- Phân phối cho team/nhiều repo → Plugin.

### Chi phí context của từng thứ (quy hoạch token)

| Feature | Load khi nào | Chi phí |
|---|---|---|
| CLAUDE.md | Đầu session, giữ suốt | Cao (nạp lại mỗi turn/compaction) → giữ <200 dòng |
| Skills | Chỉ tên+description (~100 tokens) lúc start; full body khi trigger | Thấp tới khi dùng |
| MCP servers | Lazy, khi tool được gọi | Thấp tới khi dùng (nhưng >10 tools visible làm giảm accuracy chọn tool) |
| Subagents | Khi spawn | ~20k overhead mỗi lần spawn (số liệu cộng đồng) — chỉ dùng khi xứng đáng |
| Hooks | Tại event | **0 model tokens** (chạy ngoài model) |

> Hệ quả: CLAUDE.md phình = trả tiền mọi turn. Skill để không = rẻ. Subagent spawn bừa = đắt gấp 3–4x.
> Hooks là thứ duy nhất "miễn phí token + bắt buộc thực thi" — rule nào quan trọng thì nâng thành hook.

## 5. CLAUDE.md vs Skill vs Hook vs Subagent (tránh nhầm)

- **CLAUDE.md vs Skill**: CLAUDE.md = "luôn biết"; Skill = "khi cần mới load + gọi được bằng `/`".
  Custom slash commands nay đã merge vào skills (`.claude/commands/deploy.md` ≡ `.claude/skills/deploy/SKILL.md`).
- **MCP vs Skill**: MCP = *kết nối* tới dịch vụ ngoài; Skill = *cách dùng* kết nối đó cho đúng
  (ví dụ: skill chứa message-format rules của Slack + schema DB).
- **Hook vs Skill**: Hook = harness **chạy hộ, chắc chắn chạy** khi tới event; Skill = đưa vào context
  để Claude **tự áp dụng** (có thể quên). Cần determinism → hook.
- Thứ tự thắng khi xung đột: **Hook (luật) > CLAUDE.md/Skill (gợi ý)**. Subagent là worker có scope riêng.

## 6. Workflow chuẩn cho mọi task (khung xuyên suốt khóa học)

```
Explore (đọc code liên quan, subagent nếu rộng)
  → Plan (viết plan, chờ duyệt — plan mode)
  → Implement (sửa theo phase, mỗi phase có gate)
  → Verify (test/lint/build + reviewer fresh-context)
```

Chi tiết ở `02-tips-thuc-chien/`. Còn giờ, học tiếp:

- Bài 01: cài đặt + xác thực + `claude doctor`.
- Bài 02: từng surface dùng sao cho đúng.
- Bài 03: CLAUDE.md + memory + rules (file quan trọng nhất).
