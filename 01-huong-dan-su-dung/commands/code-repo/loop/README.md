# /loop — Lặp 1 task nhiều vòng tới khi đạt (kết hợp /schedule cho routines)

> Loại Built-in/Workflow · Nhóm Code & Repo · Nguy hiểm Trung bình (loop + auto/bypass = chạy hàng chục vòng không hỏi — tốn quota + có thể sửa lan; luôn loop với goal + acceptEdits)

`/loop` bảo Claude Code "làm đi làm lại task này cho tới khi đạt chuẩn": mỗi vòng làm → check (thường qua `/goal` evaluator) → chưa đạt thì sửa tiếp. Biến thể `/schedule` đặt loop theo giờ (routine đêm/định kỳ). Dùng cho hardening, migration batch, quét lỗi lặp — không dùng cho task 1 lần là xong.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/loop <task>` | text | Lặp task tới khi goal đạt / bạn ngắt |
| `/loop <task> --max <n>` | số vòng | Giới hạn vòng (chống loop vô hạn) |
| `/schedule <cron> <task>` | cron + text | Routine định kỳ (đêm/hàng tuần) |
| `/goal` + `/loop` | combo chuẩn | Loop có tiêu chí dừng đo được |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: loop cơ bản + goal (chuẩn)
/goal Mọi file trong src/legacy/ đều pass ruff + mypy.
/loop Sửa từng file trong src/legacy/ cho sạch lint, mỗi vòng 3 file, báo tiến độ.
```

```bash
# Dạng 2: loop có giới hạn vòng (khuyên dùng)
/goal Coverage payments/ ≥ 85%.
/loop Thêm test cho payments/, mỗi vòng 1 file, tối đa 10 vòng thì dừng báo cáo.
```

```bash
# Dạng 3: loop hardening bảo mật
/goal Không còn secret hardcode (gitleaks sạch) + bandit không báo high.
/loop Quét + sửa secret hardcode toàn repo, mỗi vòng 5 file.
```

```bash
# Dạng 4: schedule routine đêm (tùy bản hỗ trợ)
/schedule 0 2 * * * Chạy pytest full + gửi báo cáo failures vào Slack channel #ci.
```

```bash
# Dạng 5: schedule dọn rác định kỳ
/schedule 0 9 * * 1 Quét TODO quá 30 ngày trong src/, mở issue nhắc owner.
```

```bash
# Dạng 6: ngắt loop (làm tay)
# Ctrl+C trong CLI, hoặc gõ: Dừng loop, báo cáo đã làm tới đâu.
```

---

## Cách nó hoạt động

### Cơ chế sâu: loop/schedule thế nào?

1. **Loop = worker + checker lặp:**
   - Mỗi vòng: worker làm 1 đơn vị (3 file / 1 endpoint) → checker (goal evaluator hoặc script bạn chỉ: `ruff`, `pytest`, `gitleaks`) chấm → chưa đạt: feedback vào vòng sau; đạt: dừng.
   - Có trần an toàn: `--max` vòng hoặc timeout session. Không đặt trần = có thể chạy tới hết quota.
2. **Schedule = loop + cron:**
   - `/schedule` đăng 1 routine: cron trigger (VD 2h sáng) → spawn session headless (thường `--print` + agent SDK) → làm task → báo cáo (file/Slack/PR).
   - Chạy nền, không cần bạn online. Cần quyền + secrets đã cấu hình trước (CI token, Slack webhook).
   - Khác loop tay: schedule lặp theo THỜI GIAN (mỗi đêm), loop lặp theo TIÊU CHÍ (tới khi đạt).
3. **State giữa các vòng:**
   - Loop tay: cùng session → giữ context (nhớ đã sửa file nào). Context phình dần → sau ~10 vòng nên `/compact`.
   - Schedule: mỗi lần chạy là session mới (không nhớ lần trước) → phải đọc state từ file (VD `progress.md`, issues) để tiếp nối.
4. **Loop vs batch:**
   - `/loop`: 1 task, lặp TUẦN TỰ tới đạt (sửa file 1→2→3).
   - `/batch`: N task ĐỘC LẬP, chạy SONG SONG (10 đứa 10 file cùng lúc).
   - Có thể lồng: batch chia 10 worktrees, trong mỗi worktree loop tới khi goal đứa đó đạt.
5. **Scheduler ở đâu?**
   - Tùy bản: local cron (CLI), server routines (Web/Team), hoặc CI cron (GitHub Actions gọi `claude --print`). Kiểm tra `/schedule` list để biết routine nào đang chạy.

### Sơ đồ loop

```text
[/loop + /goal] → vòng 1: sửa 3 file → checker: còn 2 lỗi
               → vòng 2: sửa tiếp → checker: còn 0 lỗi
               → GOAL PASS → dừng + báo cáo
               → (quá --max mà chưa đạt → dừng + báo cáo dở dang)
```

### Sơ đồ schedule

```text
[/schedule 0 2 * * *] → mỗi 2h sáng: spawn session mới
  → đọc progress.md → làm batch đêm (test full)
  → ghi báo cáo + mở issue nếu đỏ → ngủ tới hôm sau
```

### Khác gì lệnh dễ nhầm?

| Cơ chế | Lặp theo gì? | Song song? | Dùng khi nào? |
|---|---|---|---|
| `/loop` | Tiêu chí (tới khi đạt) | Không | Hardening, sửa dần |
| `/schedule` | Thời gian (cron) | Không | Routine đêm/tuần |
| `/batch` | Không lặp (chia 1 lần) | Có | Epic độc lập nhiều phần |
| `/goal` đơn | 1 task dài | Không | Task 5–20 turns |

> Quy tắc ngón tay cái:
>
> - **1 việc chưa đạt, sửa dần → `/loop`. Nhiều việc độc lập, chia ra → `/batch`. Việc lặp theo giờ → `/schedule`.**

---

## Ví dụ thực tế

### Kịch bản 1: Dọn 50 file legacy khỏi lint (loop kinh điển)

50 file cũ đầy lint errors. Làm tay 2 ngày; loop 2 giờ có giám sát.

```bash
# Bước 1: đặt goal đo được
/goal Toàn bộ src/legacy/ pass ruff check + mypy (0 errors), không đổi logic
(verify bằng pytest legacy/ vẫn pass sau mỗi 10 file).
```

```bash
# Bước 2: loop từng cụm nhỏ, có trần
/loop Sửa lint src/legacy/, mỗi vòng đúng 3 file theo thứ tự alphabet,
cuối mỗi vòng chạy ruff + pytest legacy/ và báo số lỗi còn lại. Tối đa 17 vòng.
```

> Diễn biến: vòng 1–5 ngon, vòng 6 model sửa sai logic (pytest đỏ) → checker báo → vòng 7 tự revert + sửa đúng. Bạn chỉ can thiệp 1 lần ở vòng 6.

### Kịch bản 2: Nâng coverage payments lên 85% (loop + verify)

```bash
/goal Coverage src/payments/ ≥ 85% (đo bằng vitest --coverage), mọi test mới phải pass.
/loop Mỗi vòng thêm test cho 1 file chưa đủ cover trong payments/,
chạy coverage file đó và báo %. Tối đa 10 vòng.
```

```bash
# Sau loop PASS → verify tổng
/verify payments
```

### Kịch bản 3: Schedule quét secret mỗi đêm (routine team)

```bash
# Đăng 1 lần, chạy mãi:
/schedule 0 2 * * * Chạy gitleaks detect + bandit -r src/,
nếu có findings mới so với hôm qua thì mở GitHub issue gắn label security.
```

> Sáng ra team chỉ đọc issue (nếu có). Không issue = đêm qua sạch.

### Kịch bản 4: Loop sai — không goal, không trần (bài học)

```bash
# SAI: loop mù
/loop Làm code tốt hơn đi.
# → 15 vòng, model refactor lan 20 file, không biết khi nào dừng, tốn $2.

# ĐÚNG: goal + trần + scope
/goal 3 file src/cart/ pass ruff + pytest cart/ xanh.
/loop Sửa 3 file src/cart/ cho sạch lint, tối đa 5 vòng.
```

---

## Rủi ro & lưu ý

### Tốn token? (loop là lò đốt nếu không trần)

| Loop | Chi phí | Ghi chú |
|---|---|---|
| 5 vòng nhỏ (sonnet+medium) | ~$0.30–0.50 | Chuẩn, nên dùng |
| 15 vòng không trần | ~$1–3 | Bắt đầu đắt, cần ngắt |
| Loop qua đêm quên tắt | $5–20+ | Thảm họa — luôn đặt --max |

- Luôn đặt `--max` + `/goal` đo được. Loop mù ("làm tốt hơn") = đốt tiền không đáy.
- Sau ~10 vòng cùng session: `/compact` để khỏi phình context (mỗi vòng thêm diff+log).

### Destructive? (loop + bypass = cấm)

- Loop chạy NHIỀU vòng tự động → nếu ở `bypassPermissions`, vòng 8 có thể `rm`/`force-push` mà bạn đang uống cà phê. KHÔNG BAO GIỜ loop ở bypass.
- Loop chạm DB/migration: mỗi vòng phải verify trên staging, deny `*prod*`.
- Schedule chạy đêm không người canh: chỉ cho quyền ĐỌC + mở issue; CẤM schedule tự push main/migrate production.

### Version / provider

- `/loop`: quy ước workflow phổ biến, bản nào cũng làm được (bằng prompt + goal). Lệnh `/loop` native tùy bản mới.
- `/schedule` routines: cần bản hỗ trợ (CLI mới / Team/Web). Bản thiếu → dùng cron hệ thống + `claude --print` (xem bài 12).
- Bedrock/managed khóa spawn background → schedule không chạy. Dùng GitHub Actions cron thay thế.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/goal` + `/loop` | Bắt buộc — loop nào cũng cần goal | `/goal ...` + `/loop ...` |
| `/loop` + `--max` | Chống vô hạn | Mọi loop đều có trần |
| `/loop` + `/verify` | Verify cụm sau mỗi vài vòng | Loop 5 vòng → `/verify` 1 lần |
| `/loop` + `/compact` | Loop dài phình context | Sau 10 vòng `/compact` rồi loop tiếp |
| `/batch` + `/loop` con | Mỗi worktree loop riêng | Batch chia, mỗi đứa loop tới goal mình |
| `/schedule` + CI | Routine đêm báo cáo | Schedule chạy, sáng đọc issue |

Workflow chuẩn "loop an toàn":

```bash
# 1. Goal đo được
/goal src/legacy/ ruff + mypy sạch, pytest xanh.

# 2. Phanh
# Shift+Tab → acceptEdits (không bypass)

# 3. Loop có trần, cụm nhỏ
/loop Mỗi vòng 3 file, tối đa 10 vòng, báo tiến độ mỗi vòng.

# 4. Giữa chừng verify + compact
/verify
# (nếu dài) /compact

# 5. Xong → diff tổng → merge
/diff
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Loop 20 vòng không dừng | Không goal / goal bất khả thi / thiếu --max | Ngắt (Ctrl+C); đặt goal khả thi + `--max`; chia task nhỏ |
| Loop càng sửa càng hỏng (vòng sau phá vòng trước) | Scope quá rộng, model quên đã sửa gì | Thu scope (3 file/vòng); ghi progress ra file; `/compact` + tóm tắt |
| Bill nổ sau loop qua đêm | Quên trần + effort max + opus | Luôn --max + sonnet+medium cho loop; đặt cap extra-usage |
| Schedule không chạy giờ đã đặt | Bản không hỗ trợ / managed chặn / cron sai múi giờ | Kiểm tra `/schedule` list; dùng GitHub Actions cron + `claude --print` thay thế |
| Schedule chạy nhưng không nhớ hôm qua | Mỗi lần là session mới | Đọc/ghi state qua file (`progress.md`) hoặc issues |
| Loop ở bypass xóa nhầm file | Combo cấm: loop + bypass | Không bao giờ bypass khi loop/schedule; schedule chỉ quyền đọc + mở issue |
| Checker (evaluator) PASS ẩu | Goal mơ hồ | Viết goal có số đo (0 errors, ≥85%, count khớp) |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../goal/README.md](../../model-mode/goal/README.md) — loop nào cũng cần goal làm checker
  - [../batch/README.md](../../code-repo/batch/README.md) — chia song song (khác loop tuần tự)
  - [../verify/README.md](../../code-repo/verify/README.md) — verify cụm sau mỗi vài vòng
  - [../extra-usage/README.md](../../model-mode/extra-usage/README.md) — loop dài cần canh quota
  - [../permissions/README.md](../../model-mode/permissions/README.md) — không bypass khi loop
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md` — schedule qua CI cron

> Mẹo 1 dòng: _loop không goal như lái xe không phanh — luôn có tiêu chí dừng và trần vòng._
