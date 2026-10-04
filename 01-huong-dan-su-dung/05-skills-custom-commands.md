# 05 — Skills & Custom Commands (Nâng Cấp Lớn Nhất Cho Workflow Lặp Lại)

## 1. Skill là gì (định nghĩa sạch)

Skill = **know-how đóng gói**: 1 file `SKILL.md` (frontmatter YAML + markdown hướng dẫn) + file hỗ trợ
tùy chọn (templates, examples, scripts, reference docs). Claude load khi liên quan, hoặc bạn gọi `/ten-skill`.

- Không tự chạy, không kết nối ra ngoài (khác MCP/hook/subagent).
- Startup chỉ tốn ~100 tokens (tên + description); full body chỉ load khi trigger → rẻ.
- Theo **Agent Skills open standard** (Anthropic 12/2025): ~40 tools hỗ trợ (Codex CLI, Gemini CLI, Copilot...) — viết 1 lần, chạy nhiều nơi.

Vị trí:

```
~/.claude/skills/<ten>/SKILL.md        personal, mọi project
.claude/skills/<ten>/SKILL.md          project, commit git cho team
<plugin>/skills/<ten>/SKILL.md          theo plugin (namespaced /plugin:skill)
```

`.claude/commands/*.md` cũ vẫn chạy nhưng nên migrate sang skills.

## 2. Giải phẫu SKILL.md

```markdown
---
name: deploy              # plugin skill: segment cuối của /plugin:name; skill thường: label hiển thị (command lấy từ tên thư mục)
description: Deploy staging/prod với checklist migrate + smoke test. Dùng khi user nói deploy/release/ship.
disable-model-invocation: true   # true = chỉ chạy khi gõ tay /deploy (workflow muốn kiểm soát)
allowed-tools: Bash, Read        # pre-approve tools trong lượt gọi skill (hết lượt tự thu hồi)
context: fork                     # fork = chạy trong subagent cô lập (không thấy history)
agent: Explore                    # (kèm fork) chọn agent type thực thi
model: sonnet                     # ép model cho skill
---

# Deploy

Nhận `$ARGUMENTS` (vd `/deploy staging`).

## Steps
1. `git status --short` phải sạch, nếu không dừng và báo.
2. Chạy migration dry-run: `${CLAUDE_SKILL_DIR}/scripts/migrate.sh --dry-run $ARGUMENTS`
3. Deploy: `...` 4. Smoke test endpoints trong `references/endpoints.md`.
5. Ghi kết quả theo `examples/output.md`.

Tham khảo: `references/endpoints.md`, script `${CLAUDE_SKILL_DIR}/scripts/migrate.sh`.
Repo root: `${CLAUDE_PROJECT_DIR}`.
```

Biến dùng được trong content + `allowed-tools`: `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}`.

Frontmatter đầy đủ: `name`, `description` (khuyến nghị — câu đầu là use-case chính; listing truncate ~1536 ký tự),
`when_to_use`, `disable-model-invocation`, `allowed-tools`, `context: fork`, `agent:`, `model:`,
`skillOverrides` (settings-level, tắt auto cho skill của người khác), `hooks` (plugin skill: bỏ qua).

## 3. Patterns nâng cao

- **Dynamic context injection**: dòng `` !`command` `` trong SKILL.md — Claude chạy shell trước,
  thay output thật vào prompt (vd `` !`git branch --show-current` ``).
- **Support files**: `templates/`, `examples/output.md`, `scripts/*.sh`, `references/*.md` — nhớ **trỏ từ SKILL.md** kẻo Claude không load.
- **Fork skill** (`context: fork`): skill thành prompt của subagent (cô lập). Lưu ý agent `Explore`/`Plan`
  skip CLAUDE.md + git status để giữ context nhỏ. Ngược lại: custom subagent có thể preload skills làm reference.
- **Quyền**: `allowed-tools` chỉ nới trong lượt gọi; baseline vẫn theo permission settings.
  Plugin subagents không hỗ trợ `hooks`/`mcpServers`/`permissionMode` (copy ra `.claude/agents/` nếu cần).

## 4. Bundled skills có sẵn (dùng ngay, khỏi viết)

`/doctor` (khám setup), `/code-review` + `/ultrareview` (review), `/batch` (chia việc lớn),
`/debug` (tìm root cause), `/loop` (lặp), `/claude-api [migrate|managed-agents-onboard]` (ref Claude API
Python/TS/Java/Go/Ruby/C#/PHP/cURL; auto-load khi code import anthropic SDK; `migrate` nâng model version),
`/verify` (build+chạy app thật để xác nhận), `/simplify`, `/insights`...

## 5. Quy trình tạo skill tốt (5 bước)

1. Đặt tên = động từ + đối tượng (`deploy`, `review-pr`, `add-table`), description mở đầu bằng **khi nào dùng**.
2. Viết steps dạng checklist, mỗi step có lệnh/check cụ thể + output mẫu.
3. Mặc định cho Claude tự trigger; chỉ `disable-model-invocation: true` với workflow muốn gọi tay.
4. Thêm 1 example input/output + 1 script nếu có bước máy làm tốt hơn người.
5. Test: gọi `/ten-skill` 3 lần, sửa chỗ Claude hay hỏi lại thành nội dung explicit.

Ví dụ team: `/issues` (biến ý tưởng thành issue chuẩn), `/plan` (sinh implementation plan),
`/review` (multi-layer review), `/ship` (merge base → test → review diff → bump version → changelog → commit → push → PR).

Mẫu copy-paste: xem `templates/.claude/skills/deploy/SKILL.md` trong repo này.
