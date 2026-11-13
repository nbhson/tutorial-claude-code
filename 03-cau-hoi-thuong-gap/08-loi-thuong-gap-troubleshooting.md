# FAQ 08 — Lỗi thường gặp & troubleshooting

> **Bài này cho ai:** bạn gặp lỗi khi dùng Claude Code và muốn tự fix nhanh, không cần hỏi ai.
> **Cần gì trước:** đã cài Claude Code, biết mở terminal, đã đọc qua [FAQ 01 — tài khoản, pricing & cài đặt](01-tai-khoan-pricing-cai-dat.md).
> **Đọc xong bạn làm được:** fix 90% lỗi trong 5 phút (lệnh lạ, hook im, MCP chết, deny, context đầy, argue loop); phân biệt `/debug` (session) với `claude doctor` (config); đi đúng thứ tự debug 6 bước; gói bug report đủ ngữ cảnh.
> **Thời gian:** ~12 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| version floor | Bản CLI tối thiểu để một lệnh xuất hiện | `/cd` cần ≥2.1.169 |
| matcher | Chuỗi khớp để hook kích hoạt, phân biệt hoa/thường | `Edit` ≠ `edit` |
| merged permissions | Quyền gộp từ managed/org + local | `/permissions` xem bản gộp |
| dontAsk | Chế độ không hỏi xác nhận (headless) | `--permission-mode dontAsk` |
| context window | Vùng nhớ hội thoại, đầy thì model quên | `/context` xem % |
| checkpoint | Mốc để quay lại | Double-Esc → `/rewind` |
| flaky test | Test lúc đỏ lúc xanh, không ổn định | Đỏ 1/3 lần chạy |
| calibration | Chỉnh reviewer theo gu team bằng ví dụ thật | Paste 3 diffs chuẩn |

## Mục lục

- [Sơ đồ nhanh](#sơ-đồ-nhanh)
- [Bảng full: 14 lỗi hay gặp nhất](#bảng-full-14-lỗi-hay-gặp-nhất)
- [1–5: lệnh lạ · hook im · MCP chết · deny · context đầy](#1-unknown-command-cd-hoặc-lệnh-mới-vắng)
- [6–10: quét loãng · argue loop · calibration · flaky · 2 bản/PATH](#6-claude-đọc-hàng-trăm-file-quét-loãng)
- [11–14: cloud · rate limit · session treo · gửi bug](#11-cloud-thiếu-config-local)
- [Thứ tự debug chuẩn (6 bước — thuộc lòng)](#thứ-tự-debug-chuẩn-6-bước--thuộc-lòng)

---

## Sơ đồ nhanh

```mermaid
flowchart TD
  A[Lỗi?] --> B[/status + claude update]
  B --> C[claude doctor]
  C --> D[/permissions merged?]
  D --> E[/mcp + /hooks?]
  E --> F[/debug -> /bug]
```

## Bảng full: 14 lỗi hay gặp nhất

Mục này là "sổ tay bệnh viện" của cả bài: 14 bệnh hay gặp nhất, mỗi bệnh một dòng — tra triệu chứng, lấy fix, chưa ổn mới đọc sâu.

| # | Triệu chứng | Check → Fix (1 dòng) | Chi tiết |
|---|---|---|---|
| 1 | `Unknown command: /cd` (lệnh mới vắng) | `/status` version cũ → `claude update` | Câu 1 |
| 2 | Hook không chạy | `/hooks`: event? matcher case? trusted? | [Câu 2](#2-hook-không-chạy), [FAQ 05](05-hooks-faq.md) |
| 3 | MCP disconnected | `/mcp reconnect <name>`; token/URL/OAuth | [Câu 3](#3-mcp-disconnected), [FAQ 04](04-mcp-faq.md) |
| 4 | Permission deny liên tục | `/permissions` merged + auto-mode denials | [Câu 4](#4-permission-deny-liên-tục), [FAQ 03](03-permissions-modes.md) |
| 5 | Context đầy, quên rule | `/context` → `/compact [focus]` / `/clear` + plan | [Câu 5](#5-context-đầy-claude-quên-rule--lan-man--sửa-a-hỏng-b), [FAQ 02](02-model-context-token.md) |
| 6 | Đọc hàng trăm file | Scope hẹp / subagent; "chỉ files bạn sửa" | [Câu 6](#6-claude-đọc-hàng-trăm-file-quét-loãng) |
| 7 | Sửa 2 lần vẫn sai | Dừng argue → double-Esc rewind → re-prompt | [Câu 7](#7-sửa-2-lần-vẫn-sai-argue-loop) |
| 8 | Reviewer dễ dãi/khắt khe | Calibration 3 diffs + finding explicit | [Câu 8](#8-reviewer-dễ-dãi--khắt-khe-calibration) |
| 9 | Flaky test đoán sai | "Flaky thì ghi flaky"; human verify | [Câu 9](#9-flaky-test-đoán-sai) |
| 10 | 2 bản Claude / PATH / settings parse lỗi | `claude doctor` → gỡ thừa, sửa JSON | [Câu 10](#10-2-bản-claude--path-lỗi--settings-parse-lỗi), [FAQ 01](01-tai-khoan-pricing-cai-dat.md) |
| 11 | Cloud thiếu config local | Cấu hình lại MCP/vars/setup trong environment | [Câu 11](#11-cloud-thiếu-config-local), [FAQ 10](10-ci-sdk-routines-web.md) |
| 12 | Rate limit / usage trần | `/usage` xem + đợi / đổi key / Haiku | [Câu 12](#12-rate-limit--usage-trần) |
| 13 | Session treo / chậm lạ | `/debug` → rewind / `/clear` / restart | [Câu 13](#13-session-treo--chậm-lạ) |
| 14 | Nghi bug của core | `/bug` + `/status` + `claude doctor` | [Câu 14](#14-muốn-gửi-bug-cho-anthropic), [FAQ 01](01-tai-khoan-pricing-cai-dat.md) |

> **Cách đọc bảng này:** quét cột "Triệu chứng" để tìm dòng khớp lỗi đang gặp, rồi làm theo "Check → Fix (1 dòng)" — chưa ổn mới bấm link ở cột "Chi tiết" để đọc câu đầy đủ; bảng này thay cho việc đọc lướt cả bài.

## 1. `Unknown command: /cd` (hoặc lệnh mới vắng)

> **Hỏi ngắn gọn:** gõ lệnh mới mà báo `Unknown command`?
> **Trả lời 1 câu:** 90% là version cũ.

`/cd` cần ≥2.1.169, `/verify` ≥2.1.145, `/goal` ≥2.1.139, trim CLAUDE.md ≥2.1.206, `/subtask` ≥2.1.212, `/skill-doctor` ≥2.1.252, `/diff` live panel ≥2.1.260 (bảng version chi tiết ở [FAQ 01 câu 5](01-tai-khoan-pricing-cai-dat.md#5-claude-update-và-version-floor-lệnh-lạ-90-là-version-cũ)).

> 📄 **Code ví dụ:** [`examples/01-1-unknown-command-cd-hoac-lenh-moi-vang.sh`](examples/01-1-unknown-command-cd-hoac-lenh-moi-vang.sh)

**Đào sâu:** [Bài 04 — slash commands toàn tập](../01-huong-dan-su-dung/04-slash-commands-toan-tap.md) · [WRITING-STYLE — B6 lệnh theo bản](../WRITING-STYLE.md#phần-b--dữ-kiện-chuẩn-làm-tròn-thời-gian-11102026)

## 2. Hook không chạy

> **Hỏi ngắn gọn:** hook đã viết mà không kích hoạt?
> **Trả lời 1 câu:** Đi đúng 5 check [FAQ 05](05-hooks-faq.md): (1) event Pre vs Post vs Stop, (2) matcher case (`Edit` ≠ `edit`), (3) folder trusted, (4) headless có prompt không, (5) version drift.

Lỗi hook gần như luôn nằm ở 1 trong 5 điểm trên, không phải script sai. Hook guard chạy tay ngon mà trong session im → 90% matcher `bash` thường thay vì `Bash`.

> 📄 **Code ví dụ:** [`examples/02-2-hook-khong-chay.sh`](examples/02-2-hook-khong-chay.sh)

**Đào sâu:** [FAQ 05 — hooks](05-hooks-faq.md) · [lệnh `hooks`](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md)

## 3. MCP disconnected

> **Hỏi ngắn gọn:** server MCP báo disconnected?
> **Trả lời 1 câu:** Thứ tự: token hết hạn → URL sai → OAuth chưa xong → sleep kill stdio. Thử reconnect trước, xóa server sau cùng.

Sáng mở máy thấy 3 servers vàng → sleep đêm qua kill stdio → reconnect all.

> 📄 **Code ví dụ:** [`examples/03-3-mcp-disconnected.sh`](examples/03-3-mcp-disconnected.sh)

**Đào sâu:** [FAQ 04 — MCP](04-mcp-faq.md) · [lệnh `mcp`](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md)

## 4. Permission deny liên tục

> **Hỏi ngắn gọn:** mãi bị deny dù đã allow?
> **Trả lời 1 câu:** 3 thủ phạm: (a) deny ẩn trong merged (managed thắng local), (b) auto-mode denials (headless `ask` = deny), (c) thiếu pre-approve read-only hay dùng.

Luôn xem bản gộp thực tế, đừng đoán theo file local — managed/org có thể chặn trên đầu. Allow `Bash(curl:*)` local mà vẫn deny → managed chặn → hỏi admin.

> 📄 **Code ví dụ:** [`examples/04-4-permission-deny-lien-tuc.sh`](examples/04-4-permission-deny-lien-tuc.sh)

**Đào sâu:** [FAQ 03 — permissions & modes](03-permissions-modes.md) · [lệnh `permissions`](../01-huong-dan-su-dung/commands/model-mode/permissions/README.md)

## 5. Context đầy, Claude quên rule / lan man / sửa A hỏng B

> **Hỏi ngắn gọn:** Claude bắt đầu quên rule, trả lời lan man, sửa chỗ này hỏng chỗ kia?
> **Trả lời 1 câu:** Dấu hiệu context đầy — 4 cách cứu nhẹ → nặng: `/compact [focus]` → `/clear` + paste plan → rewind → đẩy research sang subagent.

> 📄 **Code ví dụ:** [`examples/05-5-context-ay-claude-quen-rule-lan-man.sh`](examples/05-5-context-ay-claude-quen-rule-lan-man.sh)

**Đào sâu:** [FAQ 02 — model, context & token](02-model-context-token.md) · [Bài tips 01 — context hygiene](../02-tips-thuc-chien/01-context-hygiene.md)

## 6. Claude đọc hàng trăm file (quét loãng)

> **Hỏi ngắn gọn:** Claude Read quá nhiều file mà chưa làm gì?
> **Trả lời 1 câu:** Prompt quá rộng ("xem giúp codebase") → fix: scope hẹp + dặn rõ + ném sang subagent.

```text
❌ "xem giúp codebase có vấn đề gì"
✅ "Chỉ đọc 5 files mày sẽ sửa: liệt kê trước, đọc sau. Không đọc node_modules, dist, docs."
✅ "Dùng subagent Explore quét auth, trả 10 dòng + 5 file chính"
```

**Đào sâu:** [FAQ 07 — subagents & teams](07-subagents-teams-workflows.md) · [Bài tips 01 — context hygiene](../02-tips-thuc-chien/01-context-hygiene.md)

## 7. Sửa 2 lần vẫn sai (argue loop)

> **Hỏi ngắn gọn:** sửa mãi không xong, càng sửa càng lún?
> **Trả lời 1 câu:** Quy tắc: **sửa 2 lần không xong thì dừng argue** — càng argue trong context bẩn càng lún.

> 📄 **Code ví dụ:** [`examples/06-7-sua-2-lan-van-sai-argue-loop.sh`](examples/06-7-sua-2-lan-van-sai-argue-loop.sh)

**Đào sâu:** [Bài tips 03 — plan-first workflow](../02-tips-thuc-chien/03-plan-first-workflow.md) · [lệnh `rewind`](../01-huong-dan-su-dung/commands/session-context/rewind/README.md)

<!-- CHUNK2 -->

## 8. Reviewer dễ dãi / khắt khe (calibration)

> **Hỏi ngắn gọn:** reviewer AI nhận xét lệch gu team?
> **Trả lời 1 câu:** Reviewer AI mặc định theo "gu chung" — fix bằng calibration: 3 diffs lịch sử + định nghĩa finding explicit.

```text
"Review theo chuẩn này: [paste 3 diffs + quyết định của team].
Chỉ báo: security, sai logic, perf >2x. Bỏ qua: style, naming trừ khi gây hiểu nhầm."
```

**Đào sâu:** [FAQ 07 — subagents & teams](07-subagents-teams-workflows.md) · [lệnh `code-review`](../01-huong-dan-su-dung/commands/code-repo/code-review/README.md)

## 9. Flaky test đoán sai

> **Hỏi ngắn gọn:** model đoán nguyên nhân test đỏ dù test flaky?
> **Trả lời 1 câu:** Model ghét "không biết" nên hay đoán — dặn rõ: chạy lại nhiều lần, đỏ cả 3 mới debug, đỏ 1/3 ghi FLAKY + human verify.

```text
"Test đỏ: chạy lại 3 lần. Vẫn đỏ cả 3 → mới debug. Đỏ 1/3 → ghi FLAKY + tên test, DỪNG đoán nguyên nhân."
```

> 📄 **Code ví dụ:** [`examples/07-9-flaky-test-oan-sai.sh`](examples/07-9-flaky-test-oan-sai.sh)

**Đào sâu:** [Bài tips 04 — verification](../02-tips-thuc-chien/04-verification-done-that.md) · [lệnh `verify`](../01-huong-dan-su-dung/commands/code-repo/verify/README.md)

## 10. 2 bản Claude / PATH lỗi / settings parse lỗi

> **Hỏi ngắn gọn:** update không lên, version báo khác nhau, sửa settings hoài không ăn?
> **Trả lời 1 câu:** Chạy `claude doctor` (trong session: `/doctor` hoặc `/checkup`) — nó phát hiện duplicate install + JSON parse lỗi + PATH.

Nhóm lỗi "ma" (lúc được lúc không, version nhảy), nguyên nhân thường là môi trường chứ không phải code.

> 📄 **Code ví dụ:** [`examples/08-10-2-ban-claude-path-loi-settings-parse.sh`](examples/08-10-2-ban-claude-path-loi-settings-parse.sh)

**Đào sâu:** [FAQ 01 — câu 4](01-tai-khoan-pricing-cai-dat.md#4-cài-thế-nào-cho-sạch--dọn-duplicate-install) · [lệnh `doctor`](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md)

## 11. Cloud thiếu config local

> **Hỏi ngắn gọn:** lên cloud thì thiếu MCP/vars/setup?
> **Trả lời 1 câu:** Cloud không thấy local — phải cấu hình lại trong environment.

> 📄 **Code ví dụ:** [`examples/09-11-cloud-thieu-config-local.sh`](examples/09-11-cloud-thieu-config-local.sh)

**Đào sâu:** [FAQ 04 — MCP](04-mcp-faq.md) · [FAQ 10 — CI, SDK, routines, web](10-ci-sdk-routines-web.md)

## 12. Rate limit / usage trần

> **Hỏi ngắn gọn:** bị báo rate limit / chạm trần usage?
> **Trả lời 1 câu:** `/usage` hiện rate limits + breakdown; trần thì: đợi reset / đổi key / chuyển việc rẻ sang Haiku / cắt MCP-subagents ngốn.

> 📄 **Code ví dụ:** [`examples/10-12-rate-limit-usage-tran.sh`](examples/10-12-rate-limit-usage-tran.sh)

**Đào sâu:** [Bài tips 08 — tiết kiệm cost/token](../02-tips-thuc-chien/08-tiet-kiem-cost-token.md) · [lệnh `usage`](../01-huong-dan-su-dung/commands/session-context/usage/README.md)

## 13. Session treo / chậm lạ

> **Hỏi ngắn gọn:** đang làm thì session treo hoặc chậm lạ?
> **Trả lời 1 câu:** Checklist: context đầy? hook treo (>5s)? MCP treo? — hỏi `/debug`, nó chẩn đoán session hiện tại (khác `/doctor` khám config).

> 📄 **Code ví dụ:** [`examples/11-13-session-treo-cham-la.sh`](examples/11-13-session-treo-cham-la.sh)

**Đào sâu:** [Bài tips 10 — debugging power moves](../02-tips-thuc-chien/10-debugging-power-moves.md) · [lệnh `debug`](../01-huong-dan-su-dung/commands/knowledge-system/debug/README.md)

## 14. Muốn gửi bug cho Anthropic

> **Hỏi ngắn gọn:** nghi bug của core, gửi báo cáo thế nào?
> **Trả lời 1 câu:** `/bug` gói conversation; kèm `/status` (version/provider/model) + `claude doctor` output — chỉ gửi sau khi đi hết 6 bước debug bên dưới.

> 📄 **Code ví dụ:** [`examples/12-14-muon-gui-bug-cho-anthropic.sh`](examples/12-14-muon-gui-bug-cho-anthropic.sh)

**Đào sâu:** [lệnh `bug`](../01-huong-dan-su-dung/commands/knowledge-system/bug/README.md) · [FAQ 01 — tài khoản, pricing & cài đặt](01-tai-khoan-pricing-cai-dat.md)

## Thứ tự debug chuẩn (6 bước — thuộc lòng)

```text
1. /status ......... version? account? provider? (cũ → claude update)
2. claude doctor ... duplicate? settings lỗi? PATH? MCP/secret? (alias /checkup)
3. /context+/cost+/usage ... đầy? tốn ở đâu? trần gì?
4. /hooks+/mcp+/permissions ... hook im? server chết? deny ẩn?
5. /debug ........... session hiện tại bệnh gì? (rewind/compact/clear)
6. /bug ............. gói report + /status + doctor → Anthropic
```

> Quy tắc ngón tay cái: **lệnh lạ → update; hook im → 5 check; deny → merged; loãng → compact; sai 2 lần → rewind; hết cách → /bug.**

6 bước này giống quy trình cấp cứu: đo sinh hiệu (status), khám tổng quát (doctor), đo xét nghiệm (context/cost/usage), soi các ống dẫn (hooks/mcp/permissions), chụp sâu (debug), và chỉ nhập viện (bug report) khi hết phương án — đảo thứ tự là tốn tiền trước, tìm ra bệnh sau.

> **Tóm gọn 1 câu:** Thuộc lòng 6 bước `/status` → `doctor` → context/cost/usage → hooks/mcp/permissions → `/debug` → `/bug` — đi từ rẻ tới đắt, từ chung tới riêng, đừng nhảy cóc.

## Vẫn lỗi thì sao?

Đã đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` mà vẫn lỗi, thì:
- Đọc lại đúng câu ở trên tương ứng triệu chứng (bảng full dẫn tới câu).
- Đối chiếu [FAQ 05 — hooks](05-hooks-faq.md), [FAQ 04 — MCP](04-mcp-faq.md), [FAQ 03 — permissions](03-permissions-modes.md) nếu lỗi thuộc các mảng đó.
- Cuối cùng mới `/bug` kèm `/status` + `claude doctor`.

---

**Tham khảo chéo:** [Bài 04 — slash commands toàn tập](../01-huong-dan-su-dung/04-slash-commands-toan-tap.md) · [Bài tips 10 — debugging power moves](../02-tips-thuc-chien/10-debugging-power-moves.md) · [Bài tips 01 — context hygiene](../02-tips-thuc-chien/01-context-hygiene.md) · [Bài tips 03 — plan-first workflow](../02-tips-thuc-chien/03-plan-first-workflow.md) · [FAQ 01–07, 09, 10](README.md)

> Mẹo 1 dòng: _status → doctor → context/cost/usage → hooks/mcp/permissions → debug → bug — đừng nhảy cóc._
