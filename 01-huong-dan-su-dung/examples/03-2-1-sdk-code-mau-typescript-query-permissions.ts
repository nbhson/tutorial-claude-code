// examples/agent-review.ts — chạy: npx tsx examples/agent-review.ts
import { query } from "@anthropic-ai/claude-agent-sdk";

const result = await query({
  prompt: "Review git diff main...HEAD, trả về tối đa 10 findings dạng checklist.",
  options: {
    model: "sonnet",
    permissionMode: "dontAsk",
    allowedTools: ["Read", "Grep", "Glob", "Bash"],
    settingSources: ["project"], // chỉ load .claude/ project, bỏ ~/.claude/ personal
    canUseTool: async (tool, input) => {
      if (tool === "Bash") {
        const cmd = (input as { command: string }).command ?? "";
        // Chỉ cho git read-only + test focused
        if (/^(git (diff|status|log) |pnpm (test|lint) )/.test(cmd)) return { behavior: "allow" };
        return { behavior: "deny", message: "CI agent chỉ được git-read + test/lint." };
      }
      return { behavior: "ask" };
    },
  },
});

for await (const msg of result) {
  if (msg.type === "text") process.stdout.write(msg.text);
  if (msg.type === "result" && msg.isError) process.exitCode = 1;
}
