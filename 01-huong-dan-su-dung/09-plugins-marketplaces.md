# 09 — Plugins & Marketplaces (Đóng Gói Cho Team)

## 1. Plugin là gì

1 unit cài được, bundle: **skills + hooks + subagents + MCP servers (+ LSP/code-intelligence servers)**
→ thay vì mỗi teammate setup tay 4 thứ, cài 1 phát đồng bộ.

- Skills của plugin **namespaced**: `/my-plugin:review` → nhiều plugin cùng tồn tại.
- Thêm `.claude-plugin/plugin.json` vào folder skill → nó load như plugin tên `@skills-dir`
  (trong project `.claude/skills/` cần accept workspace trust dialog trước).

## 2. Dùng plugin manager

```
/plugin   → Discover / Browse / Manage
```

Màn hình Browse/Discover hiện trước: commands, agents, skills, hooks, MCP/LSP servers của plugin —
đọc kỹ trước khi cài (nhất là hooks: nó sẽ chạy code trên máy bạn).

## 3. Khi nào build plugin vs chỉ share dotfiles?

| Tình huống | Chọn |
|---|---|
| 1–2 skills nội bộ, 1 repo | `.claude/skills/` commit thẳng |
| Bộ setup chuẩn (skills+hooks+agents+MCP) dùng nhiều repo | Plugin |
| Share công khai / cross-org | Plugin + marketplace |

Ví dụ plugin hay gặp: `security-review` (skill review + subagent + hook guard), code-intelligence
plugins cho typed languages (symbol navigation + error detection sau edit), frontend-polish
(vd Impeccable: `/audit /polish /distill /critique...` chống "AI slop").

## 4. Lưu ý quyền & trust

- Plugin subagents **bị bỏ qua** `hooks`/`mcpServers`/`permissionMode` → cần thì copy agent ra
  `.claude/agents/` hoặc `~/.claude/agents/`.
- Hooks của plugin chạy trên máy bạn → chỉ cài nguồn tin cậy, review `plugin.json` + scripts.
- Org có thể quản lý qua managed/server policy settings (Team/Enterprise).
