# /ultrareview — Audit sâu multi-agent trong cloud sandbox (kỹ nhất, chậm nhất)

> Loại Skill/Workflow · Nhóm Code & Repo · Nguy hiểm Không (chỉ đọc + chạy trong sandbox cách ly; không chạm máy bạn; tốn nhiều quota/$$ nhất)

`/ultrareview` là "hội đồng thanh tra": nhiều subagents chuyên môn (security, correctness, perf) soi song song + chạy code thật trong cloud sandbox cách ly, rồi tổng hợp 1 báo cáo audit. Dành cho release lớn, tiền thật, bảo mật — không phải cho PR nhỏ hàng ngày.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/ultrareview` | _(không có)_ | Audit diff hiện tại (deep) |
| `/ultrareview <PR/phạm vi>` | PR số / đường dẫn | Audit mục tiêu cụ thể |
| `/ultrareview --focus security` | trọng tâm | Ép hội đồng tập trung 1 mảng |

Ví dụ:

```bash
# Dạng 1: audit diff trước release lớn
/ultrareview
```

```bash
# Dạng 2: audit PR tiền thật
/ultrareview 130
```

```bash
# Dạng 3: ép trọng tâm bảo mật
/ultrareview --focus security src/payments/ src/auth/
```

```bash
# Dạng 4: leo thang đủ 3 cấp (copy-paste)
/review
/code-review 130
/ultrareview 130
```

---

## Cách nó hoạt động

### Cơ chế sâu

1. **Multi-agent song song:** 3–5 subagents (security / logic / tests / perf) cùng soi 1 diff, mỗi đứa 1 checklist — bao phủ hơn 1 reviewer đơn.
2. **Cloud sandbox:** code được chạy thử (build + test + PoC tấn công đơn giản) trong môi trường cách ly, không chạm máy bạn — khác `/verify` (chạy máy bạn) và `/code-review` (không chạy).
3. **Tổng hợp:** 1 agent hợp nhất các báo cáo, loại trùng, xếp hạng CRITICAL→LOW.
4. **Giá:** chậm (5–15 phút) + đắt (gấp 5–10x `/code-review`). Chỉ xứng đáng cho audit lớn.

### Phân biệt 3 cấp (nhắc lại)

| Cấp | Agents | Chạy thật? | Thời gian | Dùng khi nào? |
|---|---|---|---|---|
| `/review` | 1 (cùng đứa) | Không | 15s | Bước nhỏ |
| `/code-review` | 1 fresh | Không | 1–2 phút | PR thường |
| `/ultrareview` | Nhiều + sandbox | Có (sandbox) | 5–15 phút | Release/audit |

---

## Ví dụ thực tế

### Kịch bản 1: Release hệ thanh toán — audit trước khi chạm tiền thật

```bash
/ultrareview 130
# → hội đồng phát hiện double-spend khi retry webhook (critical)
# mà review thường bỏ sót vì cần chạy race thật trong sandbox mới thấy.
```

### Kịch bản 2: Audit bảo mật định kỳ quý

```bash
/ultrareview --focus security src/auth/ src/api/
# → báo cáo 1 CRITICAL (JWT không verify audience) + 3 HIGH.
# → fix → /verify lại máy local → merge.
```

---

## Rủi ro & lưu ý

- **Đắt + chậm:** đừng gọi cho PR 20 dòng. Ngưỡng: release lớn / tiền / auth / infra.
- **Version floor:** skill mới, cần bản CLI mới + hỗ trợ cloud sandbox. Không thấy thì dùng `/code-review` + `/verify` ghép lại (tương đương 80%).
- **Secret:** diff có secret mà đưa lên sandbox cloud = lộ. Gỡ secret khỏi diff trước.

---

## Kết hợp trong workflow

| Combo | Khi nào | Mẫu |
|---|---|---|
| `/code-review` → `/ultrareview` | PR ok rồi, release cần sâu hơn | code-review trước, ultrareview trước release |
| `/ultrareview` → `/verify` | Sandbox xong, chạy lại máy mình | ultrareview → fix → `/verify` local |

```bash
# Workflow release lớn:
/code-review 130
# → sửa CR/HIGH
/ultrareview 130
# → sửa nốt
/verify
# → merge + tag release
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/ultrareview` báo không khả dụng | Bản cũ / gói không có sandbox | Update CLI; dùng `/code-review` + `/verify` thay thế |
| Chạy 15 phút chưa xong | Diff khổng lồ | Thu hẹp phạm vi (`src/payments/` thay vì cả repo) |
| Bill tăng mạnh | Gọi nhiều lần cho PR nhỏ | Chỉ gọi cho release/audit; PR nhỏ dùng `/review`/`/code-review` |
| Sandbox báo thiếu env/secret | Code cần DB/API key thật | Cấp secret test-only cho sandbox, không bao giờ secret production |

---

## Tham khảo

- Lệnh liên quan:
  - [../review/README.md](../review/README.md) — cấp 1 nhanh
  - [../code-review/README.md](../code-review/README.md) — cấp 2 trước merge
  - [../verify/README.md](../verify/README.md) — chạy lại máy local sau sandbox
  - [../effort/README.md](../effort/README.md) — high cho audit
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _tiền thật và bảo mật thì xứng đáng 15 phút `/ultrareview` — còn lại đừng lãng phí._
