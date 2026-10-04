# /debug — Chẩn đoán session đang bệnh: treo, chậm, trả lời lạ

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ đọc + chẩn đoán, không sửa gì — muốn sửa thì sang `/doctor --fix`)

`/debug` bật chế độ chẩn đoán cho session HIỆN TẠI: vì sao model trả lời lạ, tool treo, context đầy nhanh, MCP rớt... Nó thu thập log, transcript, token, latency rồi chỉ ra nghi phạm + hướng xử lý — nhưng không tự sửa (sửa là việc của bạn hoặc `/doctor`). Hiểu 1 câu: `/doctor` khám config, `/debug` khám session đang chạy, `/bug` báo lỗi tool cho Anthropic.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/debug` | _(không có)_ | Bật/tắt panel chẩn đoán session hiện tại |
| `/debug --verbose` | flag | Log chi tiết từng tool-call (latency, token) |
| `/debug transcript` | — | Mở transcript `.jsonl` session này |
| `Ctrl+O` (IDE) | — | Xem log nhanh không cần lệnh |

```bash
# Dạng 1: bật debug khi thấy lạ
/debug
# → hiện: context đã dùng, tool đang treo, MCP status, lỗi gần nhất

# Dạng 2: log chi tiết khi tool chậm
/debug --verbose
# → mỗi tool-call hiện latency + token, thấy ngay con nào ngốn

# Dạng 3: moi transcript khi cần bằng chứng
/debug transcript
# → đường dẫn ~/.claude/projects/<repo>/<session>.jsonl
```

---

## Cách nó hoạt động

### Cơ chế sâu: debug vs doctor vs bug khác gì?

1. **Ba lệnh — ba tầng khác nhau:**
   - `/debug` = SESSION (cái đang chạy): context bao nhiêu %, tool nào treo, MCP nào rớt, lỗi gần nhất là gì. Chỉ ĐỌC, không sửa. Tắt khi hết bệnh.
   - `/doctor` = CONFIG (cái lưu trên disk): CLAUDE.md dài không, permissions thủng không... Có SỬA (bạn duyệt).
   - `/bug` = UPSTREAM (lỗi của chính Claude Code): gói transcript + log gửi Anthropic. Dùng khi debug xong kết luận "đây là bug của tool, không phải do tôi".
   - Thứ tự chuẩn khi gặp sự cố: `/debug` (xem bệnh gì) → tự xử hoặc `/doctor` (vá config) → vẫn không hết → `/bug` (báo lên).
2. **Debug thu thập gì?**
   - Context meter: đã dùng bao nhiêu % (VD 78%), mảnh nào ngốn (file X 20k, MCP tools 5k...).
   - Toolcalls đang pending: con nào treo quá 60s, input gì.
   - Lỗi gần nhất: 5 lỗi tool/MCP/hook mới nhất + stack rút gọn.
   - MCP + hooks status: server nào rớt giữa session, hook nào crash.
3. **`--verbose` thêm gì?** Mỗi tool-call log 1 dòng: `Read a.py — 200ms — 1.2k tok`. Chạy 10 phút là thấy pattern (VD cứ gọi `mcp__db__query` là 30s → DB chậm, không phải model chậm).
4. **Debug không làm gì?** Không sửa file, không reconnect MCP, không clear context. Nó là đèn pin, không phải thuốc. Muốn thuốc: `/mcp reconnect`, `/clear`, `/compact`, `/doctor --fix`.

---

## Ví dụ thực tế

### Kịch bản 1: Model trả lời lạc đề — soi context đầy

```bash
# Triệu chứng: model quên chỉ thị đầu session, nói linh tinh.
/debug
# → "Context 92% — file legacy/dump.sql 40k token đang chiếm nửa."
# Nguyên nhân: bạn Read nhầm file dump vào context.

# Fix: /clear rồi làm tiếp, đừng Read file dump nữa (dùng head/Grep thay).
```

### Kịch bản 2: Tool treo sau sleep — tìm con treo

```bash
/debug --verbose
# → "mcp__db__query pending 180s (DB sleep cùng laptop)."
# → /mcp reconnect db → chạy lại query → xong.
/debug   # tắt về chế độ thường
```

### Kịch bản 3: Hook crash lặp — moi transcript làm bằng chứng

```bash
/debug transcript
# → mở file .jsonl, grep "hook.*exit 1" thấy guard.sh crash do thiếu python3.
# Fix: sửa guard.sh, không phải lỗi model.
# Vẫn không hết → /bug gửi kèm đoạn transcript này.
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Bật `--verbose` cả ngày | Log phình, tốn disk, rối mắt | Bật khi bệnh, tắt ngay khi xong (`/debug` lần nữa) |
| Đọc transcript chứa secret | Secret bạn paste vào chat nằm trong `.jsonl` | Đừng paste secret vào chat; transcript chỉ mở local, đừng upload bừa |
| Nhầm debug với fix | Tưởng bật debug là tự khỏi | Debug chỉ chỉ bệnh — chữa bằng `/clear`, `/mcp reconnect`, `/doctor` |

- **Tốn token?** Bản thân debug tốn ~0 (đọc local). Nhưng `--verbose` đưa thêm log vào context → tốn nhẹ. Tắt khi xong.
- **Version:** `/debug` v2.x. Bản cũ dùng `--debug` flag CLI hoặc `Ctrl+O` trong IDE.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/debug` → `/clear` | Context đầy/rác | Soi xong, clear làm tiếp |
| `/debug` → `/mcp reconnect` | MCP rớt giữa session | Thấy pending MCP → reconnect |
| `/debug` → `/doctor` | Bệnh do config | Debug chỉ config thủng → doctor vá |
| `/debug` → `/bug` | Kết luận bug tool | Gói bằng chứng gửi Anthropic |

```bash
# Quy trình xử sự cố chuẩn:
# 1. /debug (bệnh gì?) → 2. fix thử (reconnect/clear) → 3. còn bệnh? /doctor
# → 4. vẫn bệnh? /bug kèm transcript
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/debug` báo unknown | Bản CLI cũ | Update CLI; thử `Ctrl+O` trong IDE |
| Verbose không hiện latency | Tool chạy local quá nhanh (<10ms) | Bình thường — chỉ tool mạng/MCP mới có latency đáng kể |
| Transcript file quá to (>50MB) | Session dài 1 tuần không clear | Dùng `rg` grep thay vì mở hết; `/clear` thường xuyên hơn |
| Debug xong không tắt | Quên toggle | Gõ `/debug` lần nữa để tắt |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../doctor/README.md](../doctor/README.md) — vá config sau khi debug chỉ bệnh
  - [../bug/README.md](../bug/README.md) — gói bug gửi Anthropic
  - [../mcp/README.md](../mcp/README.md) — reconnect server rớt
  - [../clear/README.md](../clear/README.md) — clear khi context đầy
  - [../compact/README.md](../compact/README.md) — gọn thay vì clear hẳn
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../03-claude-md-memory-rules.md)
  - [../../05-skills-custom-commands.md](../../05-skills-custom-commands.md)
  - [../../06-subagents-agent-teams-parallel.md](../../06-subagents-agent-teams-parallel.md)
  - [../../07-hooks-tu-dong-hoa.md](../../07-hooks-tu-dong-hoa.md)
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../08-mcp-ket-noi-cong-cu-ngoai.md)
  - [../../09-plugins-marketplaces.md](../../09-plugins-marketplaces.md)

> Mẹo 1 dòng: _thấy lạ thì `/debug` trước, chữa sau — và verbose bật khi bệnh, tắt khi khỏi._
