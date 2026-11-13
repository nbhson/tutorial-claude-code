# Cheatsheet Claude Code v2.1.296 (1 trang — in ra dán cạnh màn hình)

> Mọi dòng đều copy-paste được. Gõ `/` trong session để xem lệnh nào hiện ở máy bạn (version/provider khác nhau hiện khác nhau).
> Cập nhật 10/2026: Opus 5.5 là mặc định tài khoản, Fable 5.1 cho việc khó nhất, Haiku 5.5 (1M context) thay Haiku 4.5, MCP protocol `2026-07-28`.

> **Tóm gọn 1 câu:** Đây là "mặt sau thẻ ATM" của Claude Code — mọi lệnh gõ được ngay, mỗi section trỏ tới file script chạy được trong `examples/`.

## CLI (ngoài terminal)

> 📄 **Code ví dụ:** [`examples/01-cli-ngoai-terminal.sh`](examples/01-cli-ngoai-terminal.sh)

## Session / context (trong session)

> 📄 **Code ví dụ:** [`examples/02-session-context-trong-session.sh`](examples/02-session-context-trong-session.sh)

## Model / mode

> 📄 **Code ví dụ:** [`examples/03-model-mode.sh`](examples/03-model-mode.sh)

## Code / repo

> 📄 **Code ví dụ:** [`examples/04-code-repo.sh`](examples/04-code-repo.sh)

## System / tri thức

> 📄 **Code ví dụ:** [`examples/05-system-tri-thuc.sh`](examples/05-system-tri-thuc.sh)

## Hooks events (nhớ 6 cái hay dùng nhất)

> 📄 **Code ví dụ:** [`examples/06-hooks-events-nho-6-cai-hay-dung-nhat.sh`](examples/06-hooks-events-nho-6-cai-hay-dung-nhat.sh)

## MCP day-one (3–6 servers là đủ)

> 📄 **Code ví dụ:** [`examples/07-mcp-day-one-3-6-servers-la-u.sh`](examples/07-mcp-day-one-3-6-servers-la-u.sh)

## Vòng chuẩn (thuộc lòng)

```text
Explore -> /plan (duyệt) -> Implement từng bước (/diff sau mỗi bước) -> /verify + reviewer fresh
Rule miss 2 lần -> viết hook. Việc ồn -> đẩy subagent. Context bẩn -> /compact hoặc /clear.
```

## Tra cứu chi tiết từng lệnh (84 lệnh)

- Index: [01-huong-dan-su-dung/commands/README.md](01-huong-dan-su-dung/commands/README.md)
- Hay dùng: `/plan` → [commands/model-mode/plan/README.md](01-huong-dan-su-dung/commands/model-mode/plan/README.md) · `/compact` → [commands/session-context/compact/README.md](01-huong-dan-su-dung/commands/session-context/compact/README.md) · `/verify` → [commands/code-repo/verify/README.md](01-huong-dan-su-dung/commands/code-repo/verify/README.md) · `/mcp` → [commands/knowledge-system/mcp/README.md](01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) · `/doctor` → [commands/knowledge-system/doctor/README.md](01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md)
