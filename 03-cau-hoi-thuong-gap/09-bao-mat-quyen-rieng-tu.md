# FAQ 09 — Bảo Mật & Quyền Riêng Tư

**Claude Code có đọc hết máy tôi?** Nó chỉ chạm working dirs được phép (+ `--add-dir`). Quản lý ở `/permissions`
(working directories). Đừng `bypassPermissions` trên máy dev, đừng add-dir cả home khi không cần.

**Deny nào không bypass được?** `PreToolUse` hook deny + deny rules + org `ask` cho connectors/MCP nhạy cảm —
hooks/rules siết thêm, không nới được.

**Secrets trong MCP/settings?** Chỉ qua env vars (`${TOKEN}`), không commit token vào `.mcp.json`/`settings`.
`reset-project-choices` khi đổi approvals project.

**Zero Data Retention?** Có cho Enterprise qualified (Sub) / qualified Console accounts / AWS Platform qualified —
hỏi admin/contract của bạn; mặc định telemetry/error-reporting theo provider (Bedrock/GCP/Foundry/AWS-Platform
tắt gửi về Anthropic theo default, xem provider docs).

**Skills/plugins/hooks có nguy hiểm?** Có — chúng chạy code/quyết định trên máy bạn. Chỉ cài nguồn tin cậy,
đọc Browse (commands/agents/skills/hooks/MCP) trước khi cài plugin; review scripts hooks như production code.

**Review code AI viết?** Luôn: fresh-reviewer subagent + `/code-review` (lớn → `/ultrareview` sandbox) + human
+ tests xanh. Đối xử output AI như code của intern giỏi nhưng cần giám sát.

**`--dangerously-skip-permissions` khi nào?** Chỉ CI sandbox cô lập. Trên máy dev/cloud session bình thường: không.
