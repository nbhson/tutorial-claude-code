# /mcp-serve — Biến Claude Code thành MCP server cho app khác gọi (claude mcp serve)

> Loại CLI (`claude mcp serve`) · Nhóm MCP & Tích hợp · Nguy hiểm Trung bình (mở stdio server cho tiến trình khác gọi; restricted mode chặn background agents + remote isolation — nhưng Có nếu bạn expose tools ghi/xoá cho client lạ)

`mcp-serve` (`claude mcp serve`) chạy Claude Code ở chế độ MCP stdio server: app khác (IDE, agent khác, script của bạn) gọi tools của Claude Code qua giao thức MCP thay vì chat. Chế độ restricted mặc định chặn background agents + cô lập remote (remote isolation) để client lạ không lái máy bạn đi lung tung. Hiểu `mcp-serve` là hiểu "lật mặt bàn: Claude Code từ người gọi tools thành người PHỤC VỤ tools".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `claude mcp serve` | _(không có)_ | Mở MCP stdio server với tools mặc định + restricted mode |
| `claude mcp serve --tools <list>` | `read,grep,glob...` | Chỉ expose đúng tools liệt kê (ít nhất = an toàn nhất) |
| `claude mcp serve --restricted` | flag | Bật/tăng restricted: block background agents + remote isolation |
| `claude mcp list` | _(lệnh xem)_ | Liệt kê MCP servers đang cấu hình (không phải serve) |
| `claude mcp add <tên> -- <lệnh>` | tên + lệnh | Thêm server ngoài vào Claude Code (chiều ngược lại) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở server cho script local gọi (mặc định restricted)
claude mcp serve
# → "MCP server on stdio. Tools: read, grep, glob. Restricted: on."
```

```bash
# Dạng 2: chỉ expose 3 tools đọc (an toàn nhất cho client lạ)
claude mcp serve --tools read,grep,glob
```

```bash
# Dạng 3: client là agent khác cần chạy shell giới hạn
claude mcp serve --tools read,grep,bash --restricted
# → bash bị giám sát, background agents bị block
```

```json
// Dạng 4: client MCP trỏ vào server này (.mcp.json phía client)
{
  "mcpServers": {
    "claude-code": { "command": "claude", "args": ["mcp", "serve", "--tools", "read,grep,glob"] }
  }
}
```

---

## Cách nó hoạt động

### Cơ chế sâu: stdio server + restricted mode là gì?

1. **MCP stdio server:** tiến trình `claude mcp serve` đọc JSON-RPC từ stdin, trả kết quả ra stdout — client (VSCode extension, agent Python, Claude Code khác...) spawn nó như 1 MCP server thường.
2. **Expose tools:** mặc định tập tools đọc (read/grep/glob...). Muốn thêm bash/edit thì `--tools` chỉ rõ — nguyên tắc least privilege: client cần gì cho đúng đó.
3. **Restricted mode (mặc định):**
   - **Block background agents:** client không được spawn background agent trên máy bạn (chặn "giao việc nền rồi biến mất" — client chỉ được gọi đồng bộ, xong là hết).
   - **Remote isolation:** calls từ xa bị cô lập — không truy cập env/credentials máy host ngoài phạm vi cho phép, không leo ra ngoài workspace.
4. **Khác chiều `mcp add`:** `mcp add` là Claude Code GỌI server ngoài; `mcp serve` là server ngoài GỌI Claude Code. Hai chiều ngược nhau, đừng nhầm config.

```text
client (IDE/agent/script)
  │  spawn: claude mcp serve --tools read,grep,glob
  ▼
stdio JSON-RPC: tools/list → tools/call(read src/a.ts)
  ├─ restricted: NO background agents, remote isolated
  └─ trả kết quả về client (đồng bộ, xong là hết)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Chiều | Dùng khi nào? |
|---|---|---|
| `claude mcp serve` | Claude Code PHỤC VỤ tools ra ngoài | App khác cần đọc/gọi vào workspace này |
| `claude mcp add` | Claude Code GỌI server ngoài vào | Cần thêm tools (github, db...) cho session |
| `/mcp` | QUẢN LÝ servers (list/reconnect) | Xem/sửa kết nối, không serve |
| `/background` | Agent nền TRONG session | Task dài rảnh tay (không liên quan MCP) |

> Quy tắc ngón tay cái:
>
> - **Cho app khác gọi vào → `serve`. Lấy tools ngoài vào → `add`. Xem kết nối → `/mcp`.**

---

## Ví dụ thực tế

### Kịch bản 1: Extension VSCode đọc code qua Claude Code (15 phút)

```bash
# Extension cần đọc file workspace qua MCP thay vì fs trực tiếp
# (để được grep thông minh + tôn trọng .gitignore):
# 1. Mở server chỉ-đọc:
claude mcp serve --tools read,grep,glob --restricted

# 2. Phía extension config MCP trỏ vào lệnh trên (.mcp.json như mẫu Dạng 5)
# 3. Test từ terminal:
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | claude mcp serve --tools read,grep,glob
# → {"tools": ["read", "grep", "glob"]} ✓
```

> Kết quả: extension đọc được code mà không có quyền ghi/xoá — client lạ thì chỉ cho đọc.

### Kịch bản 2: Script Python gọi grep hàng loạt qua MCP (10 phút)

```python
# audit.py — gọi Claude Code MCP thay vì rg thuần (được ranking + context)
import json, subprocess
proc = subprocess.Popen(
    ["claude", "mcp", "serve", "--tools", "read,grep,glob", "--restricted"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
)
req = {"jsonrpc": "2.0", "id": 1, "method": "tools/call",
       "params": {"name": "grep", "arguments": {"pattern": "TODO", "path": "src/"}}}
proc.stdin.write(json.dumps(req) + "\n"); proc.stdin.flush()
print(proc.stdout.readline())
```

### Kịch bản 3: Agent CI cần shell giới hạn + policy team (10 phút)

```bash
# Client là agent CI cần chạy lint trong workspace:
claude mcp serve --tools read,bash --restricted
# → bash calls bị log + giới hạn workspace; background agents: BLOCKED
# → agent CI chỉ chạy đồng bộ, không thả nền treo máy
# → xong việc Ctrl+C kill server; ps kiểm tra không còn tiến trình treo
# → policy team: serve ra ngoài mặc định chỉ read,grep,glob + restricted
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (expose thừa tools)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Expose `bash`+`edit` cho client lạ/mạng | HAY GẶP NHẤT: client ghi/xoá tuỳ ý qua MCP | Client lạ/mạng → chỉ `read,grep,glob`; bash/edit chỉ localhost + client mình viết |
| Tắt restricted cho "tiện" | Mất block background agents + remote isolation | Giữ `--restricted` mặc định; tắt chỉ khi debug local 5 phút rồi bật lại |
| Serve quên kill, treo cả ngày | Tiến trình stdio zombie giữ port/ram | Xong việc Ctrl+C + `ps` kiểm tra; script thì `try/finally` kill proc |
| Client spam 1000 calls/s | Tốn token/CPU (mỗi call chạy tool thật) | Rate-limit phía client; log calls; tools hẹp thì spam cũng ít hại |
| Ống stdio lẫn log | Log debug in ra stdout làm vỡ JSON-RPC | Log ra stderr/file, giữ stdout sạch cho protocol |

### Tốn token?

- Serve tự thân ≈ 0 (chờ calls). Tốn theo calls client gọi (mỗi read/grep tính như tool thường). Client lạ → giới hạn tools + giám sát log tuần đầu.

### Version / provider

- `claude mcp serve`: v2.x. Restricted (block background agents + remote isolation): bản mới v2.1.x — bản cũ serve "mở" hơn, update trước khi expose.
- Bedrock/Vertex: serve được (tools local, không qua provider trừ khi tool gọi model).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| serve + `mcp add` (chiều ngược) | Hai chiều 2 máy review chéo | A serve đọc, B add vào |
| serve + `/permissions` | Hẹp quyền trước khi serve | Permissions deny `.env` rồi mới serve |
| serve + `/mcp` | Kiểm tra servers trước khi mở thêm | `/mcp list` rồi serve |
| serve + `/doctor` | Khám sau khi cấu hình client | Doctor check MCP health |

Workflow chuẩn "mở serve an toàn (10 phút)":

```bash
# 1. Hẹp quyền trước (deny secret)
/permissions
# 2. Mở serve ít tools nhất + restricted
claude mcp serve --tools read,grep,glob --restricted
# 3. Test tools/list từ terminal (thấy đúng 3 tools)
# 4. Cho client kết nối, giám sát log tuần đầu
# 5. Xong việc kill + ps kiểm tra
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Client báo "tools not found" | `--tools` sai tên (viết hoa/thiếu) hoặc bản cũ chưa có tool đó | `tools/list` kiểm tra tên chính xác; update CLI cả 2 phía |
| JSON-RPC vỡ (parse error) | Log debug lẫn vào stdout | Chuyển log ra stderr/file; giữ stdout chỉ JSON |
| Background call bị từ chối | Restricted block background agents (đúng thiết kế) | Đổi client sang gọi đồng bộ; đừng tắt restricted chỉ vì lười |
| Remote client timeout | Remote isolation + firewall chặn / stdio không qua mạng trực tiếp | Serve local + SSH tunnel, không mở port thô; check firewall |
| Serve chạy nhưng client không spawn được | `claude` không trong PATH của client (service/IDE env khác) | Dùng đường dẫn tuyệt đối trong config client (`/usr/local/bin/claude ...`) |
| Hai serve cùng lúc loạn output | 2 tiến trình cùng stdout trong 1 script | Mỗi serve 1 pipe riêng; đặt tên/log riêng từng proc |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../mcp/README.md](../mcp/README.md) — quản lý MCP servers (list/add/reconnect)
  - [../permissions/README.md](../permissions/README.md) — hẹp quyền trước khi serve
  - [../doctor/README.md](../doctor/README.md) — khám MCP health sau cấu hình
  - [../background/README.md](../background/README.md) — background agents (bị restricted block phía serve)
  - [../sandbox/README.md](../sandbox/README.md) — cách ly khi client không tin cậy
- Bài tổng quan:
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../08-mcp-ket-noi-cong-cu-ngoai.md) — MCP toàn tập (serve + add + config)

> Mẹo 1 dòng: _cho đọc thì thoải mái, cho ghi/chạy thì restricted + localhost + giám sát log._
