# /restart — Khởi động lại CLI giữ nguyên session (kèm offer bản mới)

> Loại Built-in · Nhóm Session & Hệ thống · Nguy hiểm Không (giữ session; nhưng Có nhẹ nếu bạn restart giữa lúc tool đang ghi file — chờ nó xong hẳn rồi hẵng restart)

`/restart` (bí danh `/update` ở một số bản) khởi động lại tiến trình Claude Code mà KHÔNG mất hội thoại: update bản mới, nạp lại config/MCP/hooks, sửa treo lag — xong quay lại đúng chỗ đang làm. Bản mới còn offer nâng cấp version nếu có. Hiểu `/restart` là hiểu "khởi động lại máy mà không mất tab đang mở".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/restart` | _(không có)_ | Restart giữ session + offer update nếu có bản mới |
| `/update` | _(bí danh)_ | Tương đương `/restart` ở bản hỗ trợ (không có thì dùng `/restart`) |
| `/exit` + mở lại | thoát hẳn | Thoát hoàn toàn (mất session trừ khi đã lưu) — KHÁC restart |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: restart thường (lag, MCP chết, vừa sửa settings)
/restart
# → "Restarting… session giữ nguyên (42 messages). Update 2.1.250 → 2.1.252? [Yes/No]"
```

```bash
# Dạng 2: sau khi sửa settings.json / .mcp.json tay
# → lưu file xong gọi:
/restart
# → config mới có hiệu lực (khỏi thoát mở lại)
```

```bash
# Dạng 3: kiểm tra có bản mới không (máy bạn có thể hiện nút check ở /)
# → gõ /restart, đọc dòng offer version. Không có offer = đang mới nhất
```

---

## Cách nó hoạt động

### Cơ chế sâu: restart giữ gì, mất gì?

1. **Giữ:** toàn bộ hội thoại (messages), todos, file đã đọc trong context, branch/session ID — xong quay lại đúng chỗ.
2. **Nạp lại:** `settings.json` (user/project/local), `.mcp.json`, hooks, plugins, skills mới cài — thứ mà trước đó phải thoát hẳn mới ăn.
3. **Update:** nếu có bản mới, hiện offer `2.1.x → 2.1.y? [Yes/No]`. Yes = tải + restart 1 thể; No = restart giữ bản cũ (lần sau hỏi lại).
4. **Sửa bệnh:** tiến trình treo (MCP stdio zombie, hook kẹt, memory leak sau session dài) — restart là "tắt đi bật lại" nhanh nhất.
5. **KHÔNG phải:** `/clear` (xoá hội thoại), `/exit` (thoát hẳn), `/rewind` (quay checkpoint). Restart = giữ hết, chỉ thay "động cơ".

```text
/restart
├─ snapshot session (42 messages, todos, context)
├─ kill tiến trình cũ (MCP stdio, hook worker cũng kill theo)
├─ (nếu Yes update) tải bản mới
├─ boot lại + nạp config mới
└─ restore đúng chỗ đang làm → "Back. 42 messages restored."
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Giữ session? | Dùng khi nào? |
|---|---|---|
| `/restart` | CÓ (giữ hết) | Lag/treo, vừa sửa config, muốn lên bản mới |
| `/clear` | KHÔNG (xoá trắng) | Xong task, bắt task mới sạch |
| `/exit` | KHÔNG (thoát hẳn) | Nghỉ, không làm nữa |
| `/rewind` | CÓ (quay checkpoint cũ) | Code hỏng muốn quay lại, không phải treo máy |
| `/doctor` | Không liên quan tiến trình | Config bệnh — khám trước, restart sau |

> Quy tắc ngón tay cái:
>
> - **Máy lag/treo/config mới không ăn → `/restart`. Task xong muốn sạch → `/clear`. Code hỏng muốn quay lại → `/rewind`. Đừng `/clear` chỉ vì lag — mất oan cả buổi.**

---

## Ví dụ thực tế

### Kịch bản 1: Session dài 3 tiếng bắt đầu lag — restart phát hết (2 phút)

```bash
# Gõ mãi mới ra chữ, MCP timeout liên tục:
# 1. Chờ tool đang chạy xong (không restart giữa chừng!)

# 2. Restart
/restart
# → "Session saved (58 messages). Restarting… Back in 4s. 58 messages restored."

# 3. Kiểm tra còn lag không: hỏi 1 câu ngắn
# → nhanh lại. (Memory leak tiến trình cũ đã được dọn.)
```

> Kết quả: 4 giây lấy lại tốc độ, không mất chữ nào. Session >2h lag là bình thường — restart định kỳ.

### Kịch bản 2: Vừa sửa settings/MCP tay — nạp lại không cần thoát (3 phút)

```bash
# Vừa thêm MCP github vào .mcp.json, nhưng /mcp list chưa thấy:
# 1. Lưu file, check JSON không vỡ
cat .mcp.json | python3 -m json.tool

# 2. Restart để nạp
/restart
# → boot lại, "MCP github: connected (12 tools)"

# 3. Có bản mới thì tiện update luôn:
# → "Update 2.1.250 → 2.1.252? [Yes]" → Yes, xong làm tiếp
```

### Kịch bản 3: Phân biệt restart vs clear vs exit (người mới hay nhầm)

```bash
# Sáng: đang làm feature dở, máy lag
/restart   # ← đúng: giữ feature đang làm

# Trưa: xong feature, chuyển sang bug khác
/clear     # ← đúng: xoá sạch, bắt đầu mới

# Tối: nghỉ
/exit      # ← đúng: thoát hẳn
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (restart giữa việc dở)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Restart khi tool đang ghi file | HAY GẶP: file ghi dở, hook kẹt nửa chừng | Nhìn spinner đứng yên + log xong hẳn mới `/restart` |
| Yes update giữa deadline gấp | Bản mới đổi hành vi/flag, recipe cũ fail | Giờ gấp → chọn No, update sau giờ; đọc changelog trước khi Yes |
| Tưởng restart mất tiền/token | Không mất thêm — session restore không re-run tool cũ | Yên tâm restart khi lag, đừng cố chịu đựng |
| Restart mà MCP vẫn dead | Bệnh ở server ngoài (token hết hạn), không phải tiến trình local | Restart xong vẫn đỏ → `/mcp reconnect` hoặc refresh token |

### Tốn token?

- Restart ≈ 0 token thêm (restore từ snapshot, không đọc lại file). Rẻ nhất trong mọi "cách sửa lag".

### Version / provider

- `/restart` giữ session: v2.x. Bí danh `/update`: chỉ một số bản — không có thì dùng `/restart` (bản mới offer update ngay trong restart).
- Dòng "check `/` ở máy bạn": một số bản hiện nút kiểm tra update ngay trong menu `/` — máy bạn có thì dùng, không có thì `/restart` cũng thấy offer.
- Bedrock/Vertex: restart giữ luôn provider session (không phải login lại).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/restart` + `/doctor` | Khám ra bệnh config, sửa xong nạp lại | Doctor → sửa → restart |
| `/restart` + `/mcp` | MCP chết, restart không cứu | Restart trước, reconnect sau |
| `/restart` + `/status` | Restart xong kiểm tra bản + session | Restart → `/status` xem version mới |
| `/restart` + `/resume` | Restart xong mất hút (hiếm) | Restart → `/resume` tìm session ID |

Workflow chuẩn "máy dở chứng (5 phút)":

```bash
# 1. Chờ việc đang chạy xong
# 2. Khám nhanh (biết bệnh gì)
/doctor --quick
# 3. Sửa config (nếu có) rồi restart
/restart
# 4. Kiểm tra lại
/status
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/update` báo unknown command | Bản bạn không có bí danh này | Dùng `/restart` (offer update nằm trong đó) |
| Restart xong session trống | Snapshot fail (disk đầy / crash đúng lúc ghi) | `/resume` tìm session ID gần nhất; dọn disk; đừng restart khi máy báo disk full |
| Restart xong vẫn lag | Bệnh ở model/provider mạng, không phải tiến trình local | Đổi model nhẹ (`/model haiku`), check mạng; `/status` xem provider |
| Update Yes rồi fail giữa chừng | Mạng chập chờn khi tải bản mới | Chạy lại `/restart`, chọn Yes lại; hoặc update bằng package manager (`npm i -g`) |
| Config mới vẫn không ăn sau restart | Sửa nhầm file (local vs project) hoặc JSON vỡ | `python3 -m json.tool` check từng file; `/doctor` xem tool đang đọc file nào |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../status/README.md](../../auth-settings/status/README.md) — xem version + session sau restart
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — khám trước khi restart (biết bệnh gì)
  - [../clear/README.md](../../session-context/clear/README.md) — xoá session khi task xong (khác restart)
  - [../resume/README.md](../../session-context/resume/README.md) — tìm lại session nếu restart sự cố
  - [../rewind/README.md](../../session-context/rewind/README.md) — quay checkpoint (khác restart máy)
  - [../mcp/README.md](../../knowledge-system/mcp/README.md) — reconnect server sau restart
- Bài tổng quan:
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — vòng đời session

> Mẹo 1 dòng: _lag thì restart, xong việc thì clear, hỏng code thì rewind — đừng dùng lộn._
