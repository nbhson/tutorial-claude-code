# MCP nâng cao — cấu hình server, tự viết tool, resource template & orchestration

> **Bài này cho ai:** dev đã chạy xong bộ MCP ngày đầu (GitHub/Playwright/Postgres/Notion) và muốn đi sâu hơn — tự viết server, dùng resource template, phối hợp nhiều server.
> **Cần gì trước:** đọc xong [bài 08 — MCP](../../01-huong-dan-su-dung/08-mcp-ket-noi-cong-cu-ngoai.md) (scopes, transports, hướng dẫn prune).
> **Đọc xong bạn làm được:**
> - Bật/tắt server đúng chỗ, biết protocol `2026-07-28` negotiation và cách quay lại bản cũ.
> - Tự viết 1 MCP server tối thiểu (TypeScript), đăng ký vào Claude Code và kiểm tra.
> - Dùng resource template thay tool call cho dữ liệu read-only, biết khi nào chọn loại nào.
> - Giữ ngân sách tool ≤ 10 với 3–6 servers và biết 4 pattern orchestration.
> **Thời gian:** ~30 phút
>
> **Last verified:** 2026-10-28 · Claude Code v2.1.x · MCP spec `2026-07-28`

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| MCP server | Chương trình bên ngoài cho Claude Code mượn tool/resource qua protocol MCP | server `github` cung cấp tool tạo PR |
| Protocol negotiation | 2 bên thống nhất phiên bản "ngôn ngữ" giao tiếp khi bắt tay | ≥2.1.292 mặc định chọn `2026-07-28` |
| Resource template | URI có chỗ trống `{var}` — 1 khai báo phủ hàng nghìn thực thể | `github://repos/{owner}/{repo}/issues/{id}` |
| Tool search | Claude Code hoãn nạp schema của tool, cần thì mới load — để giữ tool nhiều mà không phình context | mô tả tool dài tới 16.384 ký tự |
| Scope (`project`/`local`/`user`) | Cấu hình server sống ở tầng nào | `.mcp.json` commit lên repo = `project` |

## Mục lục

1. [Cấu hình MCP server nâng cao](#1-cấu-hình-mcp-server-nâng-cao)
2. [Tự viết MCP tool](#2-tự-viết-mcp-tool)
3. [Resource template](#3-resource-template)
4. [Orchestration nhiều MCP server](#4-orchestration-nhiều-mcp-server)
5. [Best practices MCP trong Claude Code](#5-best-practices-mcp-trong-claude-code)
6. [Nguồn tham khảo](#6-nguồn-tham-khảo)

---

## 1. Cấu hình MCP server nâng cao

Mục này trả lời câu: ngoài thêm/xóa server cơ bản, bạn tinh chỉnh gì được ở tầng config — protocol, mô tả tool, secrets, và các knob theo server.

### 1.1. Protocol negotiation (≥ v2.1.292)

Từ Claude Code **v2.1.292** (06/10/2026), MCP mặc định negotiate **protocol version `2026-07-28`** — áp cho cả server local `stdio` lẫn remote `sse`/`http`, và cả connector claude.ai. Muốn quay lại cách bắt tay cũ:

```bash
export MCP_PROTOCOL_NEGOTIATION=legacy   # quay lại handshake bản cũ
```

Spec `2026-07-28` chuyển kết nối tool sang mô hình **stateless**: server không cần giữ session dài nữa, nên remote MCP server dễ scale sau load balancer hơn.

### 1.2. Mô tả tool dài hơn nhờ tool search (≥ v2.1.295)

Mô tả MCP tool giờ cho phép tới **4.096 ký tự mặc định** (trước là 2.048), và tới **16.384 ký tự khi bật tool search**. Mô tả giàu hơn → model chọn đúng tool thường xuyên hơn, nhất là khi cài nhiều server.

### 1.3. Mở rộng biến môi trường trong `.mcp.json`

Mở rộng `${VAR}` chạy được ở **command args, env blocks, URLs và headers** — dùng ở mọi nơi, không hardcode secret:

```json
{
  "mcpServers": {
    "internal-api": {
      "type": "http",
      "url": "${INTERNAL_API_URL}/mcp",
      "headers": { "Authorization": "Bearer ${INTERNAL_API_TOKEN}" }
    }
  }
}
```

### 1.4. Các nút bấm cấu hình theo server

Bảng này tra khi bạn cần bật/tắt 1 server hoặc soi config đã merge:

| Cần làm | Cơ chế |
|---|---|
| Bật/tắt từng server | `/mcp` → `enable <name>` / `disable <name>` |
| Reset lựa chọn approve theo project | `claude mcp reset-project-choices` |
| Biến chính Claude Code thành 1 MCP server | `claude mcp serve` |
| Import hàng loạt config từ Claude Desktop | `claude mcp add-from-claude-desktop` |
| Xem config merged của 1 server | `claude mcp get <name>` |

---

## 2. Tự viết MCP tool

Mục này trả lời câu: khi không server nào có sẵn hợp nhu cầu, viết server riêng tối thiểu thế nào và thiết kế tool ra sao cho model dùng đúng.

Một MCP server tối thiểu chỉ cần implement `tools/list` và `tools/call` qua stdio.

### 2.1. Server TypeScript tối thiểu

```typescript
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
```

### 2.2. Đăng ký vào Claude Code

```bash
claude mcp add --transport stdio build-status --scope project -- \
  node /path/to/hello-mcp/dist/index.js
# Kiểm tra:
claude mcp list
```

### 2.3. Quy tắc thiết kế tool tự viết

- **1 tool = 1 ý đồ.** Tool nhận enum "mode" làm 5 việc khác nhau làm model rối; tách ra.
- **Mô tả input như onboarding nhân viên mới.** Các field `description` là chỉ dẫn duy nhất của model — mô tả tool giờ chứa được tới 4.096 ký tự (16.384 qua tool search, ≥2.1.295), tận dụng hết.
- **Trả output có cấu trúc, có chặn trên.** Giới hạn kích thước kết quả (vd 20 dòng đầu + đường dẫn file dump đầy đủ) để context của agent không phình.
- **Bắt lỗi phải hành động được.** Trả thông báo model xử lý được ("branch 'foo' not found; try `list_branches` first"), không trả stack trace.
- **Viết kèm 1 skill** chứa convention cho tool của bạn (xem bài 08, mục 5).

---

## 3. Resource template

Resource phơi dữ liệu read-only theo URI. **Resource template** tham số hóa URI đó — 1 khai báo phủ hàng nghìn thực thể:

```text
# Resource tĩnh (1 thực thể):
github://repos/acme/api/issues/123

# Resource template (URI template RFC 6570):
github://repos/{owner}/{repo}/issues/{id}
```

Chúng hoạt động thế nào trong Claude Code:

```text
1. Server khai báo template: issues://{owner}/{repo}/{id}
2. Bạn hỏi: "đọc issue #123 của acme/api"
3. Claude điền biến → resolve thành github://repos/acme/api/issues/123
4. Client gọi resources/read với URI đã resolve
```

- Template xuất hiện qua `resources/templates/list`; bản instance cụ thể qua `resources/list`.
- **Ưu tiên resource thay vì tool call** khi dữ liệu đánh địa chỉ được và read-only — rẻ hơn, cache được, không phải đàm phán arguments.
- **Chặn lộ diện:** template dạng `file:///{path}` thực chất là primitive đọc filesystem — chặn root phía server và dựa vào permission rules (bài 10).

---

## 4. Orchestration nhiều MCP server

### 4.1. Giữ ngân sách tool thấp

Ngưỡng cộng đồng đo được vẫn đứng: **≤ ~10 tool hiển thị, 3–6 servers**. Thêm server → nhiều lỗi chọn tool hơn. Claude Code giảm nhẹ vấn đề này bằng **tool search** (hoãn nạp schema tool), nhưng prune vẫn rẻ hơn retrieve.

### 4.2. Đặt tên server theo domain, không theo vendor

```text
Tốt:   github, jira, db-dev, docs-internal
Xấu:   mcp-server-1, test2, github-2-backup
```

Tool xuất hiện dạng `mcp__<server>__<tool>` — prefix ổn định, có nghĩa là thứ model dựa vào để suy luận.

### 4.3. Pattern cấu hình phân tầng

```text
.mcp.json (project)   → server dùng chung, 0 secret (github, playwright, fetch)
local scope           → credential theo máy (postgres dev)
user scope            → remote cá nhân (notion, linear)
```

Ưu tiên khi trùng tên: **user > local > project**. Kiểm chứng bằng `claude mcp get <name>`.

### 4.4. Các pattern orchestration

| Pattern | Cách làm | Use case |
|---|---|---|
| **Hub + spoke** | 1 server rộng (github) + vài chuyên gia hẹp (postgres, playwright) | Đa số team — 1 server tác động cao, vài chuyên gia |
| **Gated fan-out** | Server hẹp tắt mặc định; bật theo task qua `/mcp` | Server ít dùng, rủi ro cao (prod DB) |
| **Compose qua hooks** | Hook `mcp_tool` gọi server B sau tool từ server A | PostToolUse: sau `Edit`, log thay đổi lên linear |
| **Chained agents** | Subagent A (mang bộ MCP A) báo cáo → main agent gọi server B | Explore bằng server read-only, rồi act bằng server write |

### 4.5. Bảo trì sức khỏe (2 tuần 1 lần)

```bash
/usage        # số call theo server — server nào 0 call?
/mcp          # trạng thái kết nối
claude mcp remove <name>   # sau 1 tuần thử tắt mà không ai notice
```

---

## 5. Best practices MCP trong Claude Code (2025 → 2026)

1. **Bắt đầu với 3–6 servers, cắt định kỳ.** Độ chính xác chọn tool giảm sau ~10 tool hiển thị; dùng `/usage` tìm server ế.
2. **Secret chỉ nằm trong env expansion (`${VAR}`), không bao giờ trong config commit lên.** Audit bằng `grep -riE "sk-|token|password" .mcp.json` — phải trả về rỗng.
3. **Dùng scope `project` cho server team, `user` cho token cá nhân.** Không bao giờ đặt OAuth token cá nhân vào `.mcp.json` commit chung.
4. **Server remote mới chọn transport `http`.** `sse` là legacy; `http` + OAuth chạy được trên cloud session, còn `stdio` không theo bạn lên cloud.
5. **Mỗi server sâu ghép 1 skill.** MCP cho tầm với; skill mã hóa schema, format và rule an toàn (chỉ SELECT, LIMIT 100...).
6. **Chốt kỳ vọng protocol.** Từ ≥2.1.292 spec `2026-07-28` là mặc định; chỉ đặt `MCP_PROTOCOL_NEGOTIATION=legacy` khi server cũ hành xử sai.
7. **Thử mô tả tool bằng prompt thật.** Với hạn mức 4.096 ký tự (16.384 qua tool search), mô tả chính xác cải thiện đo được việc chọn tool.
8. **Audit sau mỗi lần thêm server:** số tool hiển thị ≤ 10, grep secret sạch, 1 skill cho mỗi server sâu, cloud session cấu hình lại (stdio local không theo lên cloud).

---

## 6. Nguồn tham khảo

- MCP overview & spec: https://modelcontextprotocol.io/docs/2026-07-28/getting-started/intro
- Phân tích thay đổi spec MCP (stateless connections): https://apito.ai/en/blog/tools/mcp-stateless-architecture-apito/
- Docs MCP của Claude Code: https://code.claude.com/docs/en/mcp
- Release notes Claude Code: https://support.claude.com/en/articles/12138966-release-notes
- MCP SDK (TypeScript): https://github.com/modelcontextprotocol/typescript-sdk
- Tổng quan các MCP server tốt (2026): https://www.totalum.app/blog/best-mcp-servers-2026
- Link chéo nội bộ: [bài 08 — MCP](../../01-huong-dan-su-dung/08-mcp-ket-noi-cong-cu-ngoai.md) · [bài 09 — Plugins](../../01-huong-dan-su-dung/09-plugins-marketplaces.md) · [bài 10 — Permissions](../../01-huong-dan-su-dung/10-permissions-modes-availability.md)

---

*Thêm 2026-10-27 trong đợt soát version-sensitivity; dịch sang tiếng Việt 2026-10-28. Bài song hành (tiếng Việt): `01-huong-dan-su-dung/08-mcp-ket-noi-cong-cu-ngoai.md`.*
