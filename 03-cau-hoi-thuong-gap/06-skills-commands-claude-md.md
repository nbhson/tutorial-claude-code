# FAQ 06 — Skills, Commands & CLAUDE.md

**Custom command vs skill?** Nay là một: `.claude/commands/x.md` ≡ `.claude/skills/x/SKILL.md` → cùng `/x`.
Đường skills thêm được frontmatter, support files, auto-trigger. File cũ vẫn chạy, mới thì viết skills.

**Skill đặt ở đâu?** `~/.claude/skills/<ten>/` (personal), `.claude/skills/<ten>/` (project, commit),
`<plugin>/skills/<ten>/` (namespaced `/plugin:skill`).

**Frontmatter gồm gì?** `name`, `description` (câu đầu = use case, truncate ~1536 ký tự),
`when_to_use`, `disable-model-invocation` (true = chỉ gọi tay; từ 2.1.196 cũng chặn scheduled fire),
`allowed-tools` (pre-approve trong lượt gọi), `context: fork` (+`agent:`/`model:` để chạy cô lập).

**`$ARGUMENTS`?** Input khi gọi (`/deploy staging`). `` !`cmd` `` = chạy shell trước, thay output thật vào prompt.
`${CLAUDE_SKILL_DIR}` / `${CLAUDE_PROJECT_DIR}` dùng trong content + allowed-tools.

**Skill không auto-trigger?** Sửa `description`/`when_to_use` cho khớp cách bạn diễn đạt task;
check `disable-model-invocation` có true không; `skillOverrides` có tắt không.

**Bundled skills nào đáng dùng?** `/doctor` (setup), `/code-review` + `/ultrareview` (review),
`/batch` (chia việc lớn), `/debug`, `/loop`, `/claude-api [migrate|managed-agents-onboard]`,
`/verify` (chạy app thật), `/simplify`, `/insights`.

**CLAUDE.md vs skill?** Always-on facts → CLAUDE.md (<200 dòng). Procedures/reference load-khi-cần → skill.
Rule path hẹp → `.claude/rules/` + `paths`. Rule hay miss → hook.

**`/init` vs viết tay?** Có sẵn codebase → `/init` (thử `CLAUDE_CODE_NEW_INIT=1` cho flow interactive),
rồi xóa 50% + thêm verified commands. Project mới → template trong `templates/`.
