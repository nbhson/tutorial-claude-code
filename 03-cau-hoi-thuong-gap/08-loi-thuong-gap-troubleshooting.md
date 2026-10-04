# FAQ 08 — Lỗi Thường Gặp & Troubleshooting

> Nhóm Debug & Sự cố · 14 lỗi bảng full + thứ tự debug 6 bước · Đọc xong fix 90% lỗi trong 5 phút không cần hỏi ai

Mỗi lỗi có triệu chứng → check → fix copy-paste + khi nào áp dụng. Cuối file là thứ tự debug chuẩn phải thuộc lòng.

---

## Bảng full: 14 lỗi hay gặp nhất

| # | Triệu chứng | Check → Fix (1 dòng) | Chi tiết |
|---|---|---|---|
| 1 | `Unknown command: /cd` (lệnh mới vắng) | `/status` version cũ → `claude update` | Câu 1 |
| 2 | Hook không chạy | `/hooks`: event? matcher case? trusted? | Câu 2, FAQ 05 |
| 3 | MCP disconnected | `/mcp reconnect <name>`; token/URL/OAuth | Câu 3, FAQ 04 |
| 4 | Permission deny liên tục | `/permissions` merged + auto-mode denials | Câu 4, FAQ 03 |
| 5 | Context đầy, quên rule | `/context` → `/compact [focus]` / `/clear` + plan | Câu 5, FAQ 02 |
| 6 | Đọc hàng trăm file | Scope hẹp / subagent; "chỉ files mày sửa" | Câu 6 |
| 7 | Sửa 2 lần vẫn sai | Dừng argue → double-Esc rewind → re-prompt | Câu 7 |
| 8 | Reviewer dễ dãi/khắt khe | Calibration 3 diffs + finding explicit | Câu 8 |
| 9 | Flaky test đoán sai | "Flaky thì ghi flaky"; human verify | Câu 9 |
| 10 | 2 bản Claude / PATH / settings parse lỗi | `claude doctor` → gỡ thừa, sửa JSON | Câu 10, FAQ 01 |
| 11 | Cloud thiếu config local | Cấu hình lại MCP/vars/setup trong environment | Câu 11, FAQ 10 |
| 12 | Rate limit / usage trần | `/usage` xem + đợi / đổi key / Haiku | Câu 12 |
| 13 | Session treo / chậm lạ | `/debug` → rewind / `/clear` / restart | Câu 13 |
| 14 | Nghi bug của core | `/bug` + `/status` + `claude doctor` | Câu 14, FAQ 01 |

---

## 1. `Unknown command: /cd` (hoặc lệnh mới vắng)

**Giải thích.** 90% là version cũ. `/cd` cần ≥2.1.169, `/verify` ≥2.1.145, `/goal` ≥2.1.139, trim ≥2.1.206 (bảng full FAQ 01 câu 7).

```bash
# Trong session:
/status    # xem version
# Ngoài terminal:
claude update && claude --version
# Mở session MỚI rồi gõ lại (session cũ giữ bản cũ)
```

**Khi nào áp dụng:** luôn là check đầu tiên với mọi "lệnh không tồn tại". Đừng sửa config gì trước khi update.

---

## 2. Hook không chạy

**Giải thích.** Đi đúng 5 check FAQ 05: (1) event Pre vs Post vs Stop, (2) matcher case (`Edit` ≠ `edit`), (3) folder trusted, (4) headless có prompt không, (5) version drift.

```bash
/hooks
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | ./scripts/guard-no-push-main.sh
/status    # version đổi schema?
```

**Ví dụ:** hook guard chạy tay ngon mà trong session im → 90% matcher `bash` thường thay vì `Bash`.

**Khi nào áp dụng:** hook im re → 5 check này, đừng viết lại script vội.

---

## 3. MCP disconnected

**Giải thích.** Thứ tự: token hết hạn → URL sai → OAuth chưa xong → sleep kill stdio (FAQ 04 câu 5).

```bash
echo ${GITHUB_TOKEN:+token-set}
/mcp
/mcp reconnect github
claude mcp get github
```

**Ví dụ:** sáng mở máy 3 servers vàng → sleep đêm qua kill stdio → reconnect all, không phải config sai.

**Khi nào áp dụng:** disconnected → reconnect trước, xóa server sau cùng.

---

## 4. Permission deny liên tục

**Giải thích.** 3 thủ phạm: (a) deny ẩn trong merged (managed thắng local), (b) auto-mode denials (headless `ask` = deny), (c) thiếu pre-approve read-only hay dùng.

```bash
/permissions    # XEM MERGED, đừng đoán
# Pre-approve read-only hay dùng:
/permissions
# → allow: Read, Glob, Grep, Bash(git status:*), Bash(git diff:*)
```

**Ví dụ:** allow `Bash(curl:*)` ở local mà vẫn deny → managed org chặn → hỏi admin, đừng sửa local nữa.

**Khi nào áp dụng:** deny 3 lần liên tiếp cùng 1 lệnh → `/permissions` ngay.

---

## 5. Context đầy, Claude quên rule / lan man / sửa A hỏng B

**Giải thích.** Dấu hiệu context đầy (FAQ 02 câu 3). 4 cách cứu nhẹ → nặng: `/compact [focus]` → `/clear` + paste plan → rewind → đẩy research sang subagent.

```bash
/context            # xác nhận đầy bao nhiêu %
/compact auth-flow  # giữ focus, vứt còn lại
# Nặng hơn:
/clear              # + paste plan đã xuất trước đó
```

**Khi nào áp dụng:** thấy 1 trong 3 dấu hiệu trên → `/context` ngay, đừng "nói thêm cho nó nhớ".

---

## 6. Claude đọc hàng trăm file (quét loãng)

**Giải thích.** Prompt quá rộng ("xem giúp codebase") → model quét hết. Fix: scope hẹp + dặn rõ + ném sang subagent.

```text
❌ "xem giúp codebase có vấn đề gì"
✅ "Chỉ đọc 5 files mày sẽ sửa: liệt kê trước, đọc sau. Không đọc node_modules, dist, docs."
✅ "Dùng subagent Explore quét auth, trả 10 dòng + 5 file chính"
```

**Khi nào áp dụng:** thấy nó `Read` file thứ 20 mà chưa làm gì → dừng, scope lại.

---

## 7. Sửa 2 lần vẫn sai (argue loop)

**Giải thích.** Quy tắc: **sửa 2 lần không xong thì dừng argue**. Càng argue trong context bẩn càng lún. Double-Esc rewind về checkpoint sạch → re-prompt gọn (mô tả đúng + sai + mong muốn + 1 ví dụ).

```bash
# Bấm Esc 2 lần → chọn checkpoint trước khi sai
# Re-prompt mẫu:
# "Hàm X phải trả A khi input B (hiện trả C). Chỉ sửa file Y, giữ signature. VD: input B → A."
```

**Khi nào áp dụng:** đếm "lần sửa thứ 2 vẫn sai" → rewind ngay, không lần 3.

---

## 8. Reviewer dễ dãi / khắt khe (calibration)

**Giải thích.** Reviewer AI mặc định theo "gu chung", không theo gu team. Fix: calibration — đưa 3 diffs lịch sử (1 approve, 1 request-changes, 1 borderline) + định nghĩa finding explicit (bỏ qua style, chỉ security/correctness/perf...).

```text
"Review theo chuẩn này: [paste 3 diffs + quyết định của team].
Chỉ báo: security, sai logic, perf >2x. Bỏ qua: style, naming trừ khi gây hiểu nhầm."
```

**Khi nào áp dụng:** reviewer mới / đổi team / review 3 PR liên tiếp lệch gu.

---

## 9. Flaky test đoán sai (model đoán thay vì ghi flaky)

**Giải thích.** Model ghét "không biết" nên hay đoán nguyên nhân cho test đỏ dù là flaky. Dặn rõ + human verify failures thật.

```text
"Test đỏ: chạy lại 3 lần. Vẫn đỏ cả 3 → mới debug. Đỏ 1/3 → ghi FLAKY + tên test, DỪNG đoán nguyên nhân."
```

```bash
npm test -- --retries 3  # hoặc loop tay 3 lần
```

**Khi nào áp dụng:** mọi session có test đỏ. Không tin kết luận "do X" khi chỉ chạy 1 lần.

---

## 10. 2 bản Claude / PATH lỗi / settings parse lỗi

**Giải thích.** Triệu chứng: update không lên, version báo khác nhau, settings sửa hoài không ăn. Chạy `claude doctor` — nó phát hiện duplicate install + JSON parse lỗi + PATH.

```bash
which -a claude
claude doctor
npm uninstall -g @anthropic-ai/claude-code  # nếu duplicate (giữ native)
python3 -c "import json; json.load(open('.claude/settings.json'))"  # check JSON
```

**Khi nào áp dụng:** lỗi "ma" (lúc được lúc không, version nhảy) → doctor trước.

---

## 11. Cloud thiếu config local (MCP/vars/setup mất)

**Giải thích.** Cloud không thấy local (FAQ 04 câu 9, FAQ 10). Phải cấu hình lại trong environment: servers + vars + setup script.

```bash
/web-setup    # dựng environment từ repo
claude --cloud "task thử"   # chạy thử trước task thật
```

**Khi nào áp dụng:** lần `--cloud` đầu tiên của repo + mỗi khi cloud báo "thiếu X" mà local có.

---

## 12. Rate limit / usage trần

**Giải thích.** `/usage` hiện rate limits + breakdown. Gặp trần thì: (a) đợi reset, (b) đổi key/provider, (c) chuyển việc rẻ sang Haiku, (d) cắt MCP/subagents ngốn.

```bash
/usage     # xem trần gì + cái gì ngốn
/model haiku   # việc rẻ chuyển hết sang Haiku
```

**Khi nào áp dụng:** báo limit → `/usage` trước để biết trần gì (per-model? per-day?), đừng đoán.

---

## 13. Session treo / chậm lạ

**Giải thích.** Checklist: context đầy? hook treo (>5s)? MCP treo? Hỏi `/debug` — nó chẩn đoán session hiện tại (khác `/doctor` khám config).

```bash
/debug
# Thử nhẹ → nặng: rewind → /compact → /clear → thoát mở session mới
```

**Khi nào áp dụng:** đang làm mà "sai sai, chậm, lạ" → `/debug`, không phải `/doctor`.

---

## 14. Muốn gửi bug cho Anthropic (`/bug` + kèm gì)

**Giải thích.** `/bug` gói conversation. Kèm thêm `/status` (version/provider/model) + `claude doctor` output để tái hiện được.

```bash
/status
/bug
claude doctor   # ngoài terminal, paste kèm
```

**Khi nào áp dụng:** đã đi hết 6 bước dưới mà vẫn lỗi + nghi core.

---

## Thứ tự debug chuẩn (6 bước — thuộc lòng)

```text
1. /status ......... version? account? provider? (cũ → claude update)
2. claude doctor ... duplicate? settings lỗi? PATH? MCP/secret?
3. /context+/cost+/usage ... đầy? tốn ở đâu? trần gì?
4. /hooks+/mcp+/permissions ... hook im? server chết? deny ẩn?
5. /debug ........... session hiện tại bệnh gì? (rewind/compact/clear)
6. /bug ............. gói report + /status + doctor → Anthropic
```

```bash
/status
claude doctor
/context
/debug
```

> Quy tắc ngón tay cái: **lệnh lạ → update; hook im → 5 check; deny → merged; loãng → compact; sai 2 lần → rewind; hết cách → /bug.**

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/auth-settings/status/README.md](../01-huong-dan-su-dung/commands/auth-settings/status/README.md) — bước 1 mọi debug
  - [../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) — bước 2 khám config
  - [../01-huong-dan-su-dung/commands/knowledge-system/debug/README.md](../01-huong-dan-su-dung/commands/knowledge-system/debug/README.md) — bước 5 chẩn đoán session
  - [../01-huong-dan-su-dung/commands/knowledge-system/bug/README.md](../01-huong-dan-su-dung/commands/knowledge-system/bug/README.md) — bước 6 gửi report
  - [../01-huong-dan-su-dung/commands/session-context/context/README.md](../01-huong-dan-su-dung/commands/session-context/context/README.md) — context đầy?
  - [../01-huong-dan-su-dung/commands/session-context/rewind/README.md](../01-huong-dan-su-dung/commands/session-context/rewind/README.md) — argue loop thì rewind
  - [../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md) — hook im?
  - [../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) — server chết?
  - [../01-huong-dan-su-dung/commands/model-mode/permissions/README.md](../01-huong-dan-su-dung/commands/model-mode/permissions/README.md) — deny ẩn?
- Bài tổng quan:
  - [../02-tips-thuc-chien/10-debugging-power-moves.md](../02-tips-thuc-chien/10-debugging-power-moves.md) — debug nâng cao
  - [../02-tips-thuc-chien/01-context-hygiene.md](../02-tips-thuc-chien/01-context-hygiene.md) — phòng context đầy
  - [../02-tips-thuc-chien/03-plan-first-workflow.md](../02-tips-thuc-chien/03-plan-first-workflow.md) — re-prompt sạch sau rewind
- FAQ liên quan: tất cả FAQ 01–07, 09–10 (bảng trên dẫn đúng câu).

> Mẹo 1 dòng: _status → doctor → context/cost/usage → hooks/mcp/permissions → debug → bug — đừng nhảy cóc._
