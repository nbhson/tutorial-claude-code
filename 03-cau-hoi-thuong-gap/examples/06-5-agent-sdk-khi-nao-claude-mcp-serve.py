# pseudocode — đọc SDK docs cho API thật
agent = ClaudeAgent(
    tools=["Read", "Grep", "Glob"],       # hẹp nhất có thể
    permissions={...},                     # allowlist rõ
    setting_sources=["project"],           # chỉ .claude/, không ~/.claude/
)
result = agent.run("triage ticket X")
