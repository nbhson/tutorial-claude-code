// tools/hello-mcp/src/index.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({ name: "hello-mcp", version: "1.0.0" });

server.tool(
  "get_build_status",
  "Return CI status for a branch",
  { branch: z.string().describe("Branch name, e.g. main") },
  async ({ branch }) => {
    const res = await fetch(`https://ci.internal/api/status?branch=${branch}`);
    return { content: [{ type: "text", text: JSON.stringify(await res.json()) }] };
  }
);

await server.connect(new StdioServerTransport());
